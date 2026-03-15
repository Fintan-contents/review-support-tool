"""汎用テスト実行オーケストレーター

ExcelPlatform と ToolAdapter を組み合わせて、ツール非依存のシナリオ実行フローを提供する。

設計原則:
  - ツール固有ロジックは一切含まない（adapter 経由で委譲）
  - Excel COM 操作の順序は ExcelPlatform に委譲し、直接呼ばない
  - scenario_runner.py の _legacy_run_scenario() と並行して存在する（段階的移行用）

xlwings は Windows 専用ライブラリのため、メソッド内で遅延インポートする。
"""
from __future__ import annotations

import re
import shutil
from pathlib import Path
from typing import Optional

import openpyxl

from adapters import BaseToolAdapter
from adapters.excel_platform import ExcelPlatform
from helpers.config_loader import load_scenario_config
from helpers.xlsx_diff import compare_workbooks

DIALOG_LOG_FILENAME = "dialog_log.txt"


class ExecutionOrchestrator:
    """汎用シナリオ実行オーケストレーター。

    ExcelPlatform（Excel ライフサイクル管理）と ToolAdapter（ツール固有処理）を
    組み合わせて、ツール非依存のシナリオ実行フローを提供する。

    Args:
        xlsm_path: テスト対象 xlsm ファイルの絶対パス
        xlsm_name: xlsm ファイル名（例: "ツール名.xlsm"）
        temp_dir: テスト実行時の作業ディレクトリ（temp_dir/）
    """

    def __init__(self, xlsm_path: Path, xlsm_name: str, temp_dir: Path) -> None:
        self.xlsm_path = xlsm_path
        self.xlsm_name = xlsm_name
        self.temp_dir = temp_dir
        self.platform = ExcelPlatform()

    def run_scenario(
        self,
        scenario_src_dir: Path,
        adapter: BaseToolAdapter,
    ) -> tuple[Path, dict]:
        """シナリオを実行し、(作業ディレクトリ, config) を返す。

        config.yaml の mode が "manual" の場合は visible=True / testMode=False、
        それ以外は visible=False / testMode=True で実行する。

        Args:
            scenario_src_dir: シナリオのソースディレクトリ（auto/ or manual/ 配下）
            adapter: ツール固有処理を提供する ToolAdapter 実装

        Returns:
            tuple: (work_dir, config)
        """
        config = load_scenario_config(str(scenario_src_dir))
        is_manual = config.get("mode") == "manual"
        visible = is_manual
        test_mode = not is_manual
        scenario_name = scenario_src_dir.name

        # 作業ディレクトリ: temp_dir/scenarioXX/（実行のたびにクリア）
        work_dir = self.temp_dir / scenario_name
        if work_dir.exists():
            shutil.rmtree(work_dir)
        work_dir.mkdir(parents=True)

        # シナリオのファイルを作業ディレクトリへコピー
        shutil.copytree(str(scenario_src_dir), str(work_dir), dirs_exist_ok=True)

        # xlsm をコピー
        xlsm_dest = work_dir / self.xlsm_name
        shutil.copy2(self.xlsm_path, xlsm_dest)

        # skip_open_files に該当しないファイルだけ Excel で開く
        skip_patterns = config.get("skip_open_files", [])
        all_input_files = sorted(
            f for f in work_dir.glob("*.xlsx")
            if "_expected" not in f.name
        )
        open_files = [
            f for f in all_input_files
            if not any(re.fullmatch(pat, f.name) for pat in skip_patterns)
        ]
        skipped = [f.name for f in all_input_files if f not in open_files]
        if skipped:
            print(f"[{scenario_name}] skip_open_files により除外: {skipped}")

        self._execute_vba(
            scenario_name, xlsm_dest, open_files, config, visible, test_mode, work_dir, adapter
        )
        return work_dir, config

    def evaluate_scenario(
        self,
        work_dir: Path,
        scenario_src_dir: Path,
        config: dict,
        adapter: BaseToolAdapter,
    ) -> list[str]:
        """シナリオ結果を評価し、エラーメッセージのリストを返す。

        評価内容:
          1. file_expectations に指定されたファイル: assert_no_sheets などを評価
          2. それ以外のファイル: _expected.xlsx が存在すれば全シート Gold Master 比較
          3. template_assertions: adapter.evaluate_custom_assertions() で評価

        Args:
            work_dir: VBA 実行後の actual ファイルが格納されたディレクトリ
            scenario_src_dir: シナリオのソースディレクトリ（_expected.xlsx の格納元）
            config: load_scenario_config で読み込んだ設定 dict
            adapter: ツール固有処理を提供する ToolAdapter 実装

        Returns:
            エラーメッセージのリスト（空なら全アサーション通過）
        """
        # ComparisonConfig を解決（config.yaml の compare: セクション + adapter デフォルト）
        comparison_cfg = adapter.get_default_comparison()
        compare_override = config.get("compare", {})
        if compare_override:
            comparison_cfg = comparison_cfg.merge(compare_override)

        expectations = config.get("file_expectations", [])
        excluded_cells = config.get("excluded_cells", [])
        errors = []
        evaluated_files = set()
        assertion_count = 0

        # file_expectations で指定されたファイルを処理
        for expectation in expectations:
            pattern = expectation["pattern"]
            matched = sorted(
                f for f in work_dir.glob("*.xlsx")
                if re.search(pattern, f.name) and "_expected" not in f.name
            )
            if not matched:
                errors.append(f"パターン '{pattern}' にマッチするファイルが見つかりません")
                continue

            actual_path = matched[0]
            evaluated_files.add(actual_path.name)

            for sheet_name in expectation.get("assert_no_sheets", []):
                wb = openpyxl.load_workbook(str(actual_path), data_only=True)
                if sheet_name in wb.sheetnames:
                    errors.append(
                        f"[{actual_path.name}] シート '{sheet_name}' が"
                        f"存在してはいけませんが存在します"
                    )
                else:
                    print(f"  ✓ [{actual_path.name}] '{sheet_name}' が存在しない - OK")
                wb.close()
                assertion_count += 1

        # デフォルト: _expected.xlsx が存在する全ファイルを Gold Master 比較
        all_input = sorted(
            f for f in work_dir.glob("*.xlsx")
            if "_expected" not in f.name
        )
        for actual_path in all_input:
            if actual_path.name in evaluated_files:
                continue

            expected_path = scenario_src_dir / f"{actual_path.stem}_expected{actual_path.suffix}"
            if not expected_path.exists():
                print(f"  - [{actual_path.name}] Gold Master なし → スキップ")
                continue

            result = compare_workbooks(
                str(actual_path),
                str(expected_path),
                excluded_cells=excluded_cells,
                max_diffs=20,
                comparison_config=comparison_cfg,
            )
            if result.matches:
                print(f"  ✓ [{actual_path.name}] Gold Master 比較 - OK")
            else:
                errors.append(
                    f"[{actual_path.name}] Gold Master 比較 FAILED:\n" +
                    "\n".join(f"  {d}" for d in result.diffs)
                )
            assertion_count += 1

        # template_assertions: adapter.evaluate_custom_assertions() で評価
        template_assertions = config.get("template_assertions", [])
        if template_assertions:
            custom_errors = adapter.evaluate_custom_assertions(work_dir, template_assertions)
            errors.extend(custom_errors)
            assertion_count += len(template_assertions)

        # expected_messages の評価（双方向チェック）
        expected_messages = config.get("expected_messages")
        if expected_messages is not None:
            log_path = work_dir / DIALOG_LOG_FILENAME
            if not log_path.exists():
                if expected_messages:
                    errors.append(
                        "expected_messages: ダイアログログ（dialog_log.txt）が存在しません。"
                        " testMode で extract ステップが実行されていない可能性があります。"
                    )
            else:
                log_content = log_path.read_text(encoding="utf-8")
                found_ids = re.findall(r'\[MSG:([A-Z]\d+)\]', log_content)
                found_set = set(found_ids)
                expected_set = set(expected_messages)

                for expected_id in expected_messages:
                    if expected_id in found_set:
                        print(f"  ✓ expected_messages: '{expected_id}' を確認")
                    else:
                        errors.append(
                            f"expected_messages: '{expected_id}' がダイアログログに見つかりません"
                            f" (実際のログ: {sorted(found_set)})"
                        )

                unexpected = found_set - expected_set
                if unexpected:
                    errors.append(
                        f"expected_messages: 想定外のメッセージが出力されました: {sorted(unexpected)}"
                        f" (expected: {sorted(expected_set)})"
                    )
                else:
                    print(f"  ✓ expected_messages: 想定外メッセージなし")

        if assertion_count == 0:
            if "file_expectations" in config and config["file_expectations"] == []:
                pass
            else:
                errors.append(
                    "構造的アサーションが1件もありません。"
                    "_expected.xlsx を配置するか、file_expectations で assert_no_sheets を設定するか、"
                    "template_assertions を設定してください。"
                    "（expected_messages はダイアログ検証専用のため、この条件を満たしません）"
                    "出力ファイルが存在しない意図的なシナリオの場合は file_expectations: [] を設定してください。"
                )

        return errors

    # =========================================================================
    # 内部ヘルパー
    # =========================================================================

    def _execute_vba(
        self,
        scenario_name: str,
        xlsm_dest: Path,
        open_files: list,
        config: dict,
        visible: bool,
        test_mode: bool,
        work_dir: Path,
        adapter: BaseToolAdapter,
    ) -> None:
        """VBA マクロを実行する（アダプタ経由）。"""
        app = None
        open_wbs = []
        xlsm_wb = None

        try:
            app = self.platform.launch(scenario_name, visible)

            for f in open_files:
                import xlwings as xw  # Windows専用: メソッド内で遅延インポート
                print(f"[{scenario_name}] ファイルを開く: {f.name}")
                wb = app.books.open(str(f))
                open_wbs.append((f.name, wb))

            print(f"[{scenario_name}] xlsm を開く...")
            xlsm_wb = app.books.open(str(xlsm_dest))

            # setup キーによる xlsm 事前設定（adapter に委譲）
            setup = config.get("setup", {})
            if setup:
                adapter.apply_setup(scenario_name, xlsm_wb, setup, work_dir)

            # 全ステップ実行（adapter に委譲）
            adapter.execute_steps(
                scenario_name, xlsm_wb, config["steps"], test_mode, work_dir, self.platform
            )

            print(f"[{scenario_name}] 全ステップ完了")

            # ファイル保存
            self.platform.save_all(
                scenario_name, app, open_wbs, xlsm_wb, self.xlsm_name
            )

        except Exception as e:
            raise RuntimeError(f"[{scenario_name}] VBA 実行エラー: {e}") from e

        finally:
            self.platform.cleanup(scenario_name, app, open_wbs, xlsm_wb)


# ---------------------------------------------------------------------------
# モジュールレベルのシングルトン（scenario_runner.py から利用）
# ---------------------------------------------------------------------------

_orchestrator: Optional[ExecutionOrchestrator] = None


def get_orchestrator(xlsm_path: Path, xlsm_name: str, temp_dir: Path) -> ExecutionOrchestrator:
    """ExecutionOrchestrator のシングルトンを取得する。

    scenario_runner.py から呼び出し、モジュールグローバルの設定値を渡す。

    Args:
        xlsm_path: xlsm ファイルの絶対パス
        xlsm_name: xlsm ファイル名
        temp_dir: テスト作業ディレクトリ

    Returns:
        ExecutionOrchestrator インスタンス
    """
    global _orchestrator
    if _orchestrator is None:
        _orchestrator = ExecutionOrchestrator(xlsm_path, xlsm_name, temp_dir)
    return _orchestrator
