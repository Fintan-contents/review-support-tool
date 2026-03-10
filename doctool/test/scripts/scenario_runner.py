"""シナリオ実行コアロジック

auto / manual 共通の VBA 実行・結果評価ロジックを提供する。

config.yaml の mode キーで実行モードを自動判定:
  - mode: manual → visible=True, testMode=False（ユーザーがダイアログを操作）
  - それ以外    → visible=False, testMode=True（自動実行）
"""
import gc
import re
import shutil
import time
from pathlib import Path

import openpyxl
import xlwings as xw

from helpers.config_loader import load_scenario_config, validate_step
from helpers.xlsx_diff import compare_workbooks


DOCTOOL_XLSM = (
    Path(__file__).parent.parent.parent
    / "Excel設計書レビュー指摘事項抽出ツール"
    / "Excel設計書レビュー指摘事項抽出ツール.xlsm"
)

TEMP_DIR = Path(__file__).parent.parent / "temp_dir"


def run_scenario(scenario_src_dir: Path) -> tuple[Path, dict]:
    """シナリオを実行し、(作業ディレクトリ, config) を返す。

    config.yaml の mode が "manual" の場合は visible=True / testMode=False、
    それ以外は visible=False / testMode=True で実行する。

    実行後の actual ファイルは TEMP_DIR/シナリオ名/ に残るので、
    差分確認やデバッグに利用できる。

    Args:
        scenario_src_dir: シナリオのソースディレクトリ（auto/ or manual/ 配下）

    Returns:
        tuple: (work_dir, config)
    """
    config = load_scenario_config(str(scenario_src_dir))
    is_manual = config.get("mode") == "manual"
    visible = is_manual
    test_mode = not is_manual
    scenario_name = scenario_src_dir.name

    # 作業ディレクトリ: temp_dir/scenarioXX/（実行のたびにクリア）
    work_dir = TEMP_DIR / scenario_name
    if work_dir.exists():
        shutil.rmtree(work_dir)
    work_dir.mkdir(parents=True)

    # シナリオのファイルを作業ディレクトリへコピー
    shutil.copytree(str(scenario_src_dir), str(work_dir), dirs_exist_ok=True)

    # doctool xlsm をコピー
    xlsm_dest = work_dir / "Excel設計書レビュー指摘事項抽出ツール.xlsm"
    shutil.copy2(DOCTOOL_XLSM, xlsm_dest)

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

    _execute_vba(scenario_name, xlsm_dest, open_files, config, visible, test_mode)
    return work_dir, config


def evaluate_scenario(work_dir: Path, scenario_src_dir: Path, config: dict) -> list[str]:
    """シナリオ結果を評価し、エラーメッセージのリストを返す。

    評価内容:
      1. file_expectations に指定されたファイル: assert_no_sheets などを評価
      2. それ以外のファイル: _expected.xlsx が存在すれば全シート Gold Master 比較

    Args:
        work_dir: VBA 実行後の actual ファイルが格納されたディレクトリ
        scenario_src_dir: シナリオのソースディレクトリ（_expected.xlsx の格納元）
        config: load_scenario_config で読み込んだ設定 dict

    Returns:
        list[str]: エラーメッセージのリスト（空なら全アサーション通過）
    """
    expectations = config.get("file_expectations", [])
    excluded_cells = config.get("excluded_cells", [])
    errors = []
    evaluated_files = set()

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

        # assert_no_sheets: 指定シートが存在しないことを確認
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

    # デフォルト: _expected.xlsx が存在する全ファイルを全シート Gold Master 比較
    all_input = sorted(
        f for f in work_dir.glob("*.xlsx")
        if "_expected" not in f.name
    )
    for actual_path in all_input:
        if actual_path.name in evaluated_files:
            continue  # file_expectations で処理済み

        expected_path = scenario_src_dir / f"{actual_path.stem}_expected{actual_path.suffix}"
        if not expected_path.exists():
            print(f"  - [{actual_path.name}] Gold Master なし → スキップ")
            continue

        result = compare_workbooks(
            str(actual_path),
            str(expected_path),
            excluded_cells=excluded_cells,
            max_diffs=20,
        )
        if result.matches:
            print(f"  ✓ [{actual_path.name}] Gold Master 比較 - OK")
        else:
            errors.append(
                f"[{actual_path.name}] Gold Master 比較 FAILED:\n" +
                "\n".join(f"  {d}" for d in result.diffs)
            )

    return errors


# ============================================================
# 内部ヘルパー
# ============================================================

def _execute_vba(
    scenario_name: str,
    xlsm_dest: Path,
    open_files: list[Path],
    config: dict,
    visible: bool,
    test_mode: bool,
) -> None:
    """VBA マクロを実行する。"""
    app = None
    open_wbs = []
    xlsm_wb = None

    try:
        print(f"[{scenario_name}] Excel を起動中... (visible={visible})")
        app = xw.App(visible=visible)

        for f in open_files:
            print(f"[{scenario_name}] ファイルを開く: {f.name}")
            wb = app.books.open(str(f))
            open_wbs.append((f.name, wb))

        print(f"[{scenario_name}] xlsm を開く...")
        xlsm_wb = app.books.open(str(xlsm_dest))
        macro = xlsm_wb.macro("Sheet1.CmdGen_Click_Core")

        for step_idx, step in enumerate(config["steps"], 1):
            validate_step(step)
            action = step["action"]

            if action == "extract":
                review_times = step["review_times"]
                repeat = step.get("repeat", 1)
                print(
                    f"[{scenario_name}] Step {step_idx}: extract"
                    f" (REVIEW_TIMES={review_times}, repeat={repeat})"
                )
                for run_num in range(repeat):
                    xlsm_wb.names["REVIEW_TIMES"].refers_to_range.value = review_times
                    print(f"[{scenario_name}]   マクロ実行中 (run {run_num + 1}/{repeat})...")
                    macro(test_mode)

            elif action == "delete_comments":
                print(f"[{scenario_name}] Step {step_idx}: delete_comments")
                _run_delete_macro(
                    scenario_name, xlsm_wb,
                    "Module2.DelAllReviewComments_Click_Core", test_mode,
                )

            elif action == "delete_sheets":
                print(f"[{scenario_name}] Step {step_idx}: delete_sheets")
                _run_delete_macro(
                    scenario_name, xlsm_wb,
                    "Module2.DelAllReviewResultSheets_Click_Core", test_mode,
                )

        print(f"[{scenario_name}] 全ステップ完了")

        print(f"[{scenario_name}] ファイルを保存中...")
        for _, wb in open_wbs:
            try:
                wb.save()
            except Exception as e:
                print(f"[{scenario_name}]   保存警告: {e}")
        xlsm_wb.save()
        print(f"[{scenario_name}] Saved → temp_dir/{scenario_name}/")

    except Exception as e:
        raise RuntimeError(f"[{scenario_name}] VBA 実行エラー: {e}") from e

    finally:
        _cleanup_excel(scenario_name, app, open_wbs, xlsm_wb)


def _run_delete_macro(
    scenario_name: str,
    xlsm_wb,
    macro_path: str,
    test_mode: bool,
) -> None:
    """削除系マクロを実行する。"""
    try:
        xlsm_wb.macro("Module2.ClearDialogLog")()
        xlsm_wb.macro(macro_path)(test_mode)
        dialog_log = xlsm_wb.macro("Module2.GetDialogLog")()
        if dialog_log:
            for line in dialog_log.split("\n"):
                print(f"[{scenario_name}]     {line}")
    except Exception as e:
        print(f"[{scenario_name}]   Warning: {e}")


def _cleanup_excel(
    scenario_name: str,
    app,
    open_wbs: list,
    xlsm_wb,
) -> None:
    """Excel プロセスをクリーンアップする。"""
    for _, wb in open_wbs:
        try:
            wb.close()
        except Exception:
            pass
    if xlsm_wb:
        try:
            xlsm_wb.close()
        except Exception:
            pass
    if app:
        try:
            app.quit()
        except Exception:
            pass
    gc.collect()

    try:
        import psutil
        for i in range(10):
            if not any(
                p.name().lower() == "excel.exe"
                for p in psutil.process_iter(["name"])
            ):
                print(f"[{scenario_name}] Excel 終了確認 ({i + 1}s)")
                break
            time.sleep(1)
        else:
            print(f"[{scenario_name}] 警告: Excel が 10秒後も残留中")
    except Exception:
        pass
