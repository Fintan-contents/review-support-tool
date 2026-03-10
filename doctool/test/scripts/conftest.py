"""pytest共通設定とフィクスチャ定義"""
import pytest
import psutil
from pathlib import Path


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
