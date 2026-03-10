"""pytest共通設定とフィクスチャ定義"""
import sys
import pytest
import psutil
from pathlib import Path

from helpers.tee_logger import Tee, start_session_log, session_header


TEMP_DIR = Path(__file__).parent.parent / "temp_dir"

_session_log_file = None


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


def pytest_configure(config):
    """pytest設定"""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "vba: marks tests that execute VBA macros"
    )


def pytest_sessionstart(session):
    """テストセッション開始時にセッションログを設定"""
    global _session_log_file
    log_path = TEMP_DIR / "test_result.log"
    start_session_log(log_path)  # 既存ログをバックアップ、マーカー作成
    _session_log_file = open(log_path, "w", encoding="utf-8")
    sys.stdout = Tee(sys.stdout, _session_log_file)
    print(session_header())
    print(f"Session log: {log_path}")


def pytest_sessionfinish(session, exitstatus):
    """全テスト終了時のクリーンアップ"""
    global _session_log_file
    kill_excel_processes()
    if _session_log_file:
        if isinstance(sys.stdout, Tee):
            sys.stdout = sys.stdout._console
        _session_log_file.close()
        _session_log_file = None
