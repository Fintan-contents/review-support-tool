"""pytest共通設定とフィクスチャ定義

xlwingsセットアップ、VBA実行ヘルパー、タイムアウト処理等を提供。
"""
import pytest
import xlwings as xw
import subprocess
import time
import psutil
from pathlib import Path
from typing import Optional


class VBAExecutionError(Exception):
    """VBA実行エラー"""
    pass


class VBATimeoutError(VBAExecutionError):
    """VBA実行タイムアウト"""
    pass


def kill_excel_processes():
    """全てのExcelプロセスを強制終了
    
    Note:
        テスト失敗時や異常終了時のクリーンアップに使用
    """
    for proc in psutil.process_iter(['name']):
        try:
            if proc.info['name'].upper() == 'EXCEL.EXE':
                proc.kill()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass


def run_vba_macro_with_timeout(
    xlsm_path: Path,
    macro_name: str = "Sheet1.CmdGen_Click_Core",
    timeout: int = 300,
    visible: bool = False
) -> None:
    """VBAマクロをタイムアウト付きで実行
    
    Args:
        xlsm_path: xlsmファイルパス
        macro_name: マクロ名（例: "Sheet1.CmdGen_Click_Core"）
        timeout: タイムアウト秒数（デフォルト: 300秒=5分）
        visible: Excelを表示するか（デバッグ用）
        
    Raises:
        FileNotFoundError: xlsmファイルが存在しない
        VBATimeoutError: タイムアウト発生
        VBAExecutionError: VBA実行エラー
    """
    if not xlsm_path.exists():
        raise FileNotFoundError(f"xlsm file not found: {xlsm_path}")
    
    app = None
    wb = None
    start_time = time.time()
    
    try:
        # Excel起動
        print(f"Starting Excel... (visible={visible})")
        app = xw.App(visible=visible)
        print(f"Opening workbook: {xlsm_path}")
        wb = app.books.open(str(xlsm_path))
        
        # マクロ実行
        print(f"Executing macro: {macro_name}")
        macro = wb.macro(macro_name)
        macro(True)  # testMode=True (位置引数で渡す)
        print("Macro execution completed")
        
        # タイムアウトチェック
        elapsed = time.time() - start_time
        if elapsed > timeout:
            raise VBATimeoutError(
                f"VBA execution timeout ({elapsed:.1f}s > {timeout}s)"
            )
        
        # 保存
        print("Saving workbook...")
        wb.save()
        print("Save completed")
        
    except Exception as e:
        print(f"Error during VBA execution: {type(e).__name__}: {e}")
        # タイムアウトエラーはそのまま送出
        if isinstance(e, VBATimeoutError):
            raise
        
        # その他のエラーはVBAExecutionErrorでラップ
        raise VBAExecutionError(f"VBA execution failed: {e}") from e
        
    finally:
        # クリーンアップ（正常終了の場合のみ丁寧に閉じる）
        try:
            if wb:
                print("Closing workbook...")
                wb.close()
            if app:
                print("Quitting Excel...")
                app.quit()
                # Excelが正常終了するまで少し待つ
                time.sleep(1)
        except Exception as cleanup_error:
            print(f"Cleanup error (non-fatal): {cleanup_error}")
            # クリーンアップエラー時のみプロセスをkill
            time.sleep(0.5)
            kill_excel_processes()


@pytest.fixture(scope="session")
def test_base_dir() -> Path:
    """テストベースディレクトリを返す"""
    return Path(__file__).parent


@pytest.fixture(scope="session")
def fixture_base_dir(test_base_dir: Path) -> Path:
    """フィクスチャベースディレクトリを返す"""
    return test_base_dir


@pytest.fixture
def temp_work_dir(tmp_path_factory):
    """一時作業ディレクトリを作成し、テスト終了後にクリーンアップ"""
    work_dir = tmp_path_factory.mktemp("vba_test_")
    yield work_dir
    # クリーンアップは不要（pytest-tmpディレクトリが自動削除される）


def pytest_configure(config):
    """pytest設定"""
    # カスタムマーカーの登録
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "vba: marks tests that execute VBA macros"
    )


def pytest_sessionfinish(session, exitstatus):
    """全テスト終了時のクリーンアップ"""
    # 念のため残存Excelプロセスをクリーンアップ
    kill_excel_processes()
