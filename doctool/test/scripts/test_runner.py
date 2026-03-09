"""全シナリオ自動実行テスト

test/scenarioXX ディレクトリを自動検出し、Gold Master比較テストを動的に生成。
新しいシナリオは scenarioXX ディレクトリと Gold Master ファイル（_expected.xlsx）を
追加するだけで自動的にテスト対象となる。

シナリオディレクトリの命名規則:
- scenario01, scenario02, ... 
- 各ディレクトリには以下のファイルが必要:
  - *.xlsx (処理対象の設計書)
  - *_レビュー記録票.xlsx (レビュー記録票)
  - *_expected.xlsx (Gold Master: 期待される設計書出力)
  - *_レビュー記録票_expected.xlsx (Gold Master: 期待される記録票出力)
"""
import pytest
import shutil
import time
import xlwings as xw
from pathlib import Path
from helpers.fixture_manager import prepare_scenario, get_expected_file_path
from helpers.xlsx_diff import compare_workbooks
from helpers.config_loader import load_scenario_config, validate_step
from conftest import kill_excel_processes


# doctoolのxlsmファイルパス
DOCTOOL_XLSM = Path(__file__).parent.parent.parent / "Excel設計書レビュー指摘事項抽出ツール" / "Excel設計書レビュー指摘事項抽出ツール.xlsm"


def discover_scenarios():
    """test/auto/ 配下の scenarioXX ディレクトリを検出

    Returns:
        list[Path]: シナリオディレクトリのリスト
    """
    auto_dir = Path(__file__).parent.parent / "auto"  # test/auto/
    scenarios = [
        d for d in auto_dir.glob("scenario*")
        if d.is_dir() and d.name.startswith("scenario")
    ]
    return sorted(scenarios)


def find_files_in_scenario(scenario_dir):
    """シナリオディレクトリ内の設計書とレビュー記録票を検出
    
    Args:
        scenario_dir: シナリオディレクトリパス
        
    Returns:
        tuple: (design_doc_name, record_name) or (None, None) if not found
    """
    xlsx_files = list(scenario_dir.glob("*.xlsx"))
    
    # Gold Masterファイル（_expected.xlsx）を除外
    input_files = [f for f in xlsx_files if "_expected" not in f.name]
    
    # レビュー記録票を探す
    record_files = [f for f in input_files if "レビュー記録票" in f.name]
    record_name = record_files[0].name if record_files else None
    
    # 設計書を探す（レビュー記録票以外の.xlsx）
    design_files = [f for f in input_files if "レビュー記録票" not in f.name]
    design_name = design_files[0].name if design_files else None
    
    return design_name, record_name


def run_vba_for_scenario(scenario_name, tmp_path_factory):
    """指定シナリオでVBAを実行し、結果ディレクトリを返す
    
    config.yamlから読み込んだstepsに従って、VBAマクロを実行します。
    
    Args:
        scenario_name: シナリオ名（例: "scenario01"）
        tmp_path_factory: pytestのfactory
        
    Returns:
        tuple: (scenario_dir, design_doc_name, record_name)
    """
    # scenario config読み込み
    auto_dir = Path(__file__).parent.parent / "auto"  # test/auto/
    scenario_src_dir = auto_dir / scenario_name
    config = load_scenario_config(str(scenario_src_dir))
    
    # 一時作業ディレクトリ作成
    work_dir = tmp_path_factory.mktemp(f"{scenario_name}_")
    
    # シナリオをコピー
    scenario_dir = prepare_scenario(scenario_name, work_dir)
    
    # ファイル名を検出
    design_doc_name, record_name = find_files_in_scenario(scenario_src_dir)
    
    if not design_doc_name:
        pytest.skip(f"No design document found in {scenario_name}")
    
    # doctool xlsmをコピー
    xlsm_dest = scenario_dir / "Excel設計書レビュー指摘事項抽出ツール.xlsm"
    shutil.copy2(DOCTOOL_XLSM, xlsm_dest)
    
    # ファイルパス
    design_doc_path = scenario_dir / design_doc_name
    record_path = scenario_dir / record_name if record_name else None
    
    # VBA実行
    app = None
    design_wb = None
    record_wb = None
    xlsm_wb = None
    
    try:
        print(f"\n[{scenario_name}] Starting Excel application...")
        app = xw.App(visible=False)
        
        # 設計書を開く
        print(f"[{scenario_name}] Opening design document: {design_doc_name}")
        design_wb = app.books.open(str(design_doc_path))
        
        # レビュー記録票を開く（存在する場合）
        if record_path and record_path.exists():
            print(f"[{scenario_name}] Opening review record: {record_name}")
            record_wb = app.books.open(str(record_path))
        
        # xlsmを開いてマクロ実行
        print(f"[{scenario_name}] Opening xlsm and executing macro...")
        xlsm_wb = app.books.open(str(xlsm_dest))
        
        macro = xlsm_wb.macro("Sheet1.CmdGen_Click_Core")
        
        # config.yamlのstepsに従って実行
        for step_idx, step in enumerate(config["steps"], 1):
            validate_step(step)
            action = step["action"]
            
            if action == "extract":
                review_times = step["review_times"]
                repeat = step.get("repeat", 1)
                
                print(f"[{scenario_name}] Step {step_idx}: extract (REVIEW_TIMES={review_times}, repeat={repeat})")
                
                for run_num in range(repeat):
                    print(f"[{scenario_name}]   Setting REVIEW_TIMES={review_times}...")
                    xlsm_wb.names["REVIEW_TIMES"].refers_to_range.value = review_times
                    print(f"[{scenario_name}]   Executing macro (run {run_num + 1}/{repeat})...")
                    macro(True)  # testMode=True (位置引数で渡す)
                    
            elif action == "delete_comments":
                print(f"[{scenario_name}] Step {step_idx}: delete_comments")
                try:
                    # ダイアログログをクリア
                    clear_log = xlsm_wb.macro("Module2.ClearDialogLog")
                    clear_log()
                    
                    # 削除マクロ実行
                    delete_macro = xlsm_wb.macro("Module2.DelAllReviewComments_Click_Core")
                    delete_macro(True)  # testMode=True
                    
                    # ダイアログログを取得して確認
                    get_log = xlsm_wb.macro("Module2.GetDialogLog")
                    dialog_log = get_log()
                    if dialog_log:
                        print(f"[{scenario_name}]   Dialog logic verified:")
                        for line in dialog_log.split('\n'):
                            print(f"[{scenario_name}]     {line}")
                    else:
                        print(f"[{scenario_name}]   No dialogs encountered (no target files)")
                    
                    print(f"[{scenario_name}]   Comments deleted")
                except Exception as e:
                    print(f"[{scenario_name}]   Warning: {e}")
                
            elif action == "delete_sheets":
                print(f"[{scenario_name}] Step {step_idx}: delete_sheets")
                try:
                    # ダイアログログをクリア
                    clear_log = xlsm_wb.macro("Module2.ClearDialogLog")
                    clear_log()
                    
                    # 削除マクロ実行
                    delete_macro = xlsm_wb.macro("Module2.DelAllReviewResultSheets_Click_Core")
                    delete_macro(True)  # testMode=True
                    
                    # ダイアログログを取得して確認
                    get_log = xlsm_wb.macro("Module2.GetDialogLog")
                    dialog_log = get_log()
                    if dialog_log:
                        print(f"[{scenario_name}]   Dialog logic verified:")
                        for line in dialog_log.split('\n'):
                            print(f"[{scenario_name}]     {line}")
                    else:
                        print(f"[{scenario_name}]   No dialogs encountered (no target files)")
                    
                    print(f"[{scenario_name}]   Result sheets deleted")
                except Exception as e:
                    print(f"[{scenario_name}]   Warning: {e}")
        
        print(f"[{scenario_name}] All steps completed")
        
        # すべてのブックを保存
        print(f"[{scenario_name}] Saving workbooks...")
        design_wb.save()
        if record_wb:
            record_wb.save()
        xlsm_wb.save()
        print(f"[{scenario_name}] Save completed")
        
    except Exception as e:
        pytest.fail(f"[{scenario_name}] VBA execution failed: {e}")
    
    finally:
        # クリーンアップ：正常終了を優先してドキュメント回復を防ぐ
        print(f"[{scenario_name}] Cleaning up Excel (errors will be suppressed)...")
        try:
            # 1. すべてのブックを明示的に閉じる（保存済みなのでSaveChanges=False）
            if xlsm_wb:
                try:
                    xlsm_wb.close()
                except:
                    pass
                xlsm_wb = None
            if record_wb:
                try:
                    record_wb.close()
                except:
                    pass
                record_wb = None
            if design_wb:
                try:
                    design_wb.close()
                except:
                    pass
                design_wb = None
            
            # 2. Excelアプリケーションを正常終了
            if app:
                try:
                    app.quit()
                except:
                    pass
                app = None
            
            # 3. ガベージコレクションを強制実行してCOMオブジェクトを解放
            import gc
            gc.collect()
            
            # 4. プロセス終了を待つ（最大10秒）
            import psutil
            max_wait = 10
            for i in range(max_wait):
                excel_exists = any(p.name().lower() == "excel.exe" for p in psutil.process_iter(['name']))
                if not excel_exists:
                    print(f"[{scenario_name}] Excel process terminated successfully after {i+1}s")
                    break
                time.sleep(1)
            else:
                # 10秒待ってもプロセスが残っている場合のみ警告
                print(f"[{scenario_name}] Warning: Excel process still running after {max_wait}s")
                
        except Exception as cleanup_error:
            print(f"[{scenario_name}] Cleanup warning: {cleanup_error}")
            pass
    
    # デバッグ用: 生成されたファイルをdebug_output/{scenario_name}/にコピー
    debug_dir = Path(__file__).parent / "debug_output" / scenario_name
    debug_dir.mkdir(parents=True, exist_ok=True)
    try:
        if design_doc_name:
            shutil.copy2(scenario_dir / design_doc_name, debug_dir / design_doc_name)
        if record_name:
            shutil.copy2(scenario_dir / record_name, debug_dir / record_name)
        print(f"[{scenario_name}] Debug files saved to: {debug_dir}")
    except Exception as copy_err:
        print(f"[{scenario_name}] Failed to copy debug files: {copy_err}")
    
    return scenario_dir, design_doc_name, record_name


# ========================================
# 動的テスト生成
# ========================================

class TestScenarioGoldMaster:
    """全シナリオのGold Master比較テスト"""
    
    @pytest.fixture(scope="class")
    def all_scenarios(self):
        """利用可能な全シナリオのリストを返す"""
        scenarios = discover_scenarios()
        if not scenarios:
            pytest.skip("No scenario directories found")
        return scenarios
    
    @pytest.mark.parametrize("scenario_dir", discover_scenarios(), ids=lambda s: s.name)
    @pytest.mark.vba
    def test_scenario_gold_master(self, scenario_dir, tmp_path_factory):
        """シナリオのGold Master比較テスト（設計書・レビュー記録票）
        
        このテストは以下を検証:
        1. 設計書（レビュー結果シート含む）がGold Masterと一致
        2. レビュー記録票（存在する場合）がGold Masterと一致
        """
        scenario_name = scenario_dir.name
        print(f"\n{'='*60}")
        print(f"Testing scenario: {scenario_name}")
        print(f"{'='*60}")
        
        # config.yamlからresult_sheetsを取得
        auto_dir = Path(__file__).parent.parent / "auto"  # test/auto/
        scenario_src_dir = auto_dir / scenario_name
        config = load_scenario_config(str(scenario_src_dir))
        result_sheets = config.get("result_sheets", [])
        
        # VBA実行（config.yamlに基づいて実行）
        result_dir, design_doc_name, record_name = run_vba_for_scenario(
            scenario_name,
            tmp_path_factory
        )
        
        # 設計書のGold Master比較
        design_actual = result_dir / design_doc_name
        design_expected = get_expected_file_path(design_actual)
        
        if not design_expected.exists():
            pytest.skip(
                f"Gold Master not found: {design_expected.name}. "
                f"Create Gold Master: copy {design_actual.name} to {scenario_name} as {design_expected.name}"
            )
        
        design_errors = []
        
        # result_sheetsが空でない場合のみシート比較を実行（scenario09は空）
        if result_sheets:
            print(f"[{scenario_name}] Comparing design document with Gold Master...")
            design_result = compare_workbooks(
                str(design_actual),
                str(design_expected),
                sheets=result_sheets,
                max_diffs=20
            )
            
            if not design_result.matches:
                design_errors.append(
                    f"[Design Document] Output differs from Gold Master:\n" +
                    "\n".join(design_result.diffs)
                )
        else:
            print(f"[{scenario_name}] Skipping design document comparison (result_sheets is empty)")
        
        
        # レビュー記録票のGold Master比較（存在する場合）
        record_errors = []
        if record_name:
            record_actual = result_dir / record_name
            record_expected = get_expected_file_path(record_actual)
            
            if record_expected.exists():
                print(f"[{scenario_name}] Comparing review record with Gold Master...")
                record_result = compare_workbooks(
                    str(record_actual),
                    str(record_expected),
                    max_diffs=20
                )
                
                if not record_result.matches:
                    record_errors.append(
                        f"[Review Record] Output differs from Gold Master:\n" +
                        "\n".join(record_result.diffs)
                    )
        
        # エラー集計
        all_errors = design_errors + record_errors
        if all_errors:
            pytest.fail("\n\n".join(all_errors))
        
        print(f"[{scenario_name}] ✓ All Gold Master comparisons passed")


# ========================================
# サマリーレポート
# ========================================

@pytest.fixture(scope="session", autouse=True)
def print_scenario_summary():
    """テスト実行前にシナリオ一覧を表示"""
    scenarios = discover_scenarios()
    print("\n" + "="*60)
    print("Discovered Test Scenarios:")
    print("="*60)
    for s in scenarios:
        design, record = find_files_in_scenario(s)
        print(f"  {s.name}:")
        print(f"    - Design: {design or '(not found)'}")
        print(f"    - Record: {record or '(not found)'}")
    print("="*60 + "\n")
