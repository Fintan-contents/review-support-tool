"""手動テストランナー

手動操作が必要なシナリオを対話的に実行する。
ExcelをVisibleモードで起動し、VBAマクロを実行。
ユーザーがダイアログを操作し、完了後にGold Master比較または
シート存在確認を行う。

実行方法:
  python scripts/manual_test_runner.py              # 全シナリオ実行
  python scripts/manual_test_runner.py scenario05_no  # 特定シナリオのみ

manual/ 配下のシナリオ構成:
  - config.yaml               : テスト設定（mode, viewpoint, instructions, steps, file_expectations）
  - *.xlsx                    : 入力フィクスチャ（_expected なし）
  - *_expected.xlsx           : Gold Master（result_sheets 指定時のみ必要）
"""
import gc
import shutil
import sys
import tempfile
import time
from pathlib import Path

import openpyxl
import xlwings as xw
import yaml

from helpers.fixture_manager import get_expected_file_path
from helpers.xlsx_diff import compare_workbooks

# doctoolのxlsmファイルパス
DOCTOOL_XLSM = (
    Path(__file__).parent.parent.parent
    / "Excel設計書レビュー指摘事項抽出ツール"
    / "Excel設計書レビュー指摘事項抽出ツール.xlsm"
)

# 手動テストシナリオの格納先
MANUAL_BASE = Path(__file__).parent.parent / "manual"


# ============================================================
# シナリオ検出・設定読み込み
# ============================================================

def discover_manual_scenarios(filter_name: str = None) -> list[Path]:
    """manual/ 配下のシナリオディレクトリを検出"""
    scenarios = sorted(
        d for d in MANUAL_BASE.glob("scenario*") if d.is_dir()
    )
    if filter_name:
        scenarios = [s for s in scenarios if s.name == filter_name]
    return scenarios


def load_manual_config(scenario_dir: Path) -> dict:
    """manual用 config.yaml を読み込む"""
    config_path = scenario_dir / "config.yaml"
    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f)


# ============================================================
# 表示ヘルパー
# ============================================================

def print_separator(char: str = "=", width: int = 60):
    print(char * width)


def print_scenario_header(scenario_name: str, config: dict):
    print()
    print_separator()
    print(f"手動テスト: {scenario_name}")
    print(f"観点: {config.get('viewpoint', '(不明)')}")
    print_separator()
    instructions = config.get("instructions", [])
    if instructions:
        print("\n操作手順:")
        for i, step in enumerate(instructions, 1):
            print(f"  {i}. {step}")
    print()


# ============================================================
# VBA実行（visible=True, testMode=False）
# ============================================================

def run_vba_manual(scenario_name: str, work_dir: Path) -> tuple[Path, dict]:
    """手動シナリオのVBAを実行する

    全入力ファイル（_expected を除く xlsx）を開き、
    VBAマクロを testMode=False で実行する。
    ダイアログはユーザーが操作する（COM呼び出しがブロッキングのため自然に待機）。

    Returns:
        tuple: (作業ディレクトリ内のシナリオパス, config dict)
    """
    manual_src_dir = MANUAL_BASE / scenario_name
    config = load_manual_config(manual_src_dir)

    # 作業ディレクトリにシナリオをコピー（xlsxを直接編集するため）
    scenario_work_dir = work_dir / scenario_name
    shutil.copytree(str(manual_src_dir), str(scenario_work_dir), dirs_exist_ok=True)

    # xlsm をコピー
    xlsm_dest = scenario_work_dir / "Excel設計書レビュー指摘事項抽出ツール.xlsm"
    shutil.copy2(DOCTOOL_XLSM, xlsm_dest)

    # 入力ファイルを検出（_expected.xlsx を除く全 xlsx、設定ファイル除く）
    input_files = sorted(
        f for f in scenario_work_dir.glob("*.xlsx")
        if "_expected" not in f.name
    )

    app = None
    open_wbs = []
    xlsm_wb = None

    try:
        print(f"[{scenario_name}] Excelを起動中... (visible=True)")
        app = xw.App(visible=True)

        # 全入力ファイルを開く（開いた順に Application.Workbooks に登録される）
        for f in input_files:
            print(f"[{scenario_name}] ファイルを開く: {f.name}")
            wb = app.books.open(str(f))
            open_wbs.append((f.name, wb))

        # xlsm を開く
        print(f"[{scenario_name}] xlsm を開く...")
        xlsm_wb = app.books.open(str(xlsm_dest))

        # REVIEW_TIMES を設定
        for step in config.get("steps", []):
            if step.get("action") == "extract":
                review_times = step.get("review_times", 1)
                xlsm_wb.names["REVIEW_TIMES"].refers_to_range.value = review_times
                break

        # マクロ実行（testMode=False）
        # COM呼び出しはブロッキングのため、VBAがダイアログを表示している間
        # Pythonはここで待機する。ユーザーがダイアログを操作するとVBAが進む。
        macro = xlsm_wb.macro("Sheet1.CmdGen_Click_Core")
        print(f"[{scenario_name}] マクロ実行中（ダイアログを操作してください）...")
        macro(False)  # testMode=False
        print(f"[{scenario_name}] マクロ完了")

        # 全ブックを保存
        print(f"[{scenario_name}] ファイルを保存中...")
        for _, wb in open_wbs:
            try:
                wb.save()
            except Exception as e:
                print(f"[{scenario_name}]   保存警告: {e}")

    except Exception as e:
        print(f"[{scenario_name}] エラー: {e}")
        raise

    finally:
        # クリーンアップ
        print(f"[{scenario_name}] Excelを終了中...")
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

        # Excelプロセス終了を最大10秒待機
        try:
            import psutil
            for i in range(10):
                if not any(p.name().lower() == "excel.exe" for p in psutil.process_iter(["name"])):
                    break
                time.sleep(1)
        except Exception:
            pass

    return scenario_work_dir, config


# ============================================================
# 結果評価
# ============================================================

def evaluate_file_expectations(scenario_work_dir: Path, config: dict) -> list[str]:
    """file_expectations を評価し、エラーメッセージのリストを返す

    評価内容:
    - assert_no_sheets: 指定シートが存在しないことを確認
    - result_sheets:    Gold Master との比較（_expected.xlsx が必要）
    """
    expectations = config.get("file_expectations", [])
    if not expectations:
        print("  (file_expectations が未定義のためスキップ)")
        return []

    errors = []

    for expectation in expectations:
        pattern = expectation["pattern"]

        # パターンにマッチする入力ファイルを検索（_expected を除く）
        matched = sorted(
            f for f in scenario_work_dir.glob("*.xlsx")
            if pattern in f.name and "_expected" not in f.name
            and "レビュー記録票" not in f.name
        )
        if not matched:
            errors.append(f"パターン '{pattern}' にマッチする設計書ファイルが見つかりません")
            continue

        actual_path = matched[0]

        # --- assert_no_sheets ---
        for sheet_name in expectation.get("assert_no_sheets", []):
            wb = openpyxl.load_workbook(str(actual_path), data_only=True)
            if sheet_name in wb.sheetnames:
                errors.append(
                    f"[{actual_path.name}] シート '{sheet_name}' が存在してはいけませんが"
                    f"存在します（スキップされていない可能性）"
                )
            else:
                print(f"  ✓ [{actual_path.name}] '{sheet_name}' が存在しない - OK")
            wb.close()

        # --- result_sheets: Gold Master 比較 ---
        result_sheets = expectation.get("result_sheets", [])
        if result_sheets:
            # Gold Master は元シナリオフォルダ（MANUAL_BASE/scenario_name/）に置く
            scenario_src_dir = MANUAL_BASE / scenario_work_dir.name
            expected_path = scenario_src_dir / f"{actual_path.stem}_expected{actual_path.suffix}"

            if not expected_path.exists():
                errors.append(
                    f"[{actual_path.name}] Gold Master が見つかりません: {expected_path.name}\n"
                    f"  → Windows環境で手動実行して結果を保存し、\n"
                    f"     {expected_path} に配置してください"
                )
                continue

            result = compare_workbooks(
                str(actual_path),
                str(expected_path),
                sheets=result_sheets,
                max_diffs=20,
            )
            if result.matches:
                print(f"  ✓ [{actual_path.name}] Gold Master比較 ({', '.join(result_sheets)}) - OK")
            else:
                errors.append(
                    f"[{actual_path.name}] Gold Master比較 FAILED:\n"
                    + "\n".join(f"    {d}" for d in result.diffs)
                )

    return errors


# ============================================================
# メインループ
# ============================================================

def run_manual_tests(filter_name: str = None):
    """手動テストを順次実行する"""
    scenarios = discover_manual_scenarios(filter_name)

    if not scenarios:
        if filter_name:
            print(f"シナリオ '{filter_name}' が見つかりません")
            print(f"利用可能なシナリオ: {[s.name for s in discover_manual_scenarios()]}")
        else:
            print("手動テストシナリオが見つかりません")
        return

    print()
    print_separator()
    print(f"手動テストシナリオ: {len(scenarios)} 件")
    for s in scenarios:
        cfg = load_manual_config(s)
        print(f"  - {s.name}: {cfg.get('viewpoint', '')}")
    print_separator()

    work_dir = Path(tempfile.mkdtemp(prefix="manual_test_"))
    results = []

    for i, scenario_dir in enumerate(scenarios):
        scenario_name = scenario_dir.name
        config = load_manual_config(scenario_dir)

        print_scenario_header(scenario_name, config)
        input("準備ができたら Enter を押してください...")

        try:
            result_dir, config = run_vba_manual(scenario_name, work_dir)
            errors = evaluate_file_expectations(result_dir, config)

            if errors:
                print(f"\n[{scenario_name}] ✗ FAIL")
                for e in errors:
                    print(f"  {e}")
                results.append((scenario_name, False))
            else:
                print(f"\n[{scenario_name}] ✓ PASS")
                results.append((scenario_name, True))

        except Exception as e:
            print(f"\n[{scenario_name}] ✗ ERROR: {e}")
            results.append((scenario_name, False))

        # 最後のシナリオでなければ次へ進む確認
        if i < len(scenarios) - 1:
            print()
            input("Excelが完全に終了したことを確認して Enter を押してください（次のシナリオへ）...")

    # サマリー
    print()
    print_separator()
    print("テスト結果サマリー")
    print_separator()
    for name, passed in results:
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"  {status}: {name}")
    passed_count = sum(1 for _, p in results if p)
    print(f"\n合計: {passed_count}/{len(results)} PASS")
    print_separator()


if __name__ == "__main__":
    filter_name = sys.argv[1] if len(sys.argv) > 1 else None
    run_manual_tests(filter_name)
