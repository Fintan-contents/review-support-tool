"""pytest共通設定とフィクスチャ定義"""
import os
import sys
import time
import pytest
import psutil
from pathlib import Path

from helpers.tee_logger import Tee, start_session_log, session_header


TEMP_DIR = Path(os.environ["TOOL_TEST_ROOT"]) / "temp_dir"

_session_log_file = None
_session_start_time: float = 0.0
_scenario_results: list[dict] = []


def _fmt_elapsed(seconds: float) -> str:
    """秒数を人間が読みやすい形式（例: 1m 23s）に変換する。"""
    s = int(seconds)
    if s < 60:
        return f"{s}s"
    m, s = divmod(s, 60)
    if m < 60:
        return f"{m}m {s:02d}s"
    h, m = divmod(m, 60)
    return f"{h}h {m:02d}m {s:02d}s"


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


def pytest_addoption(parser):
    """カスタムコマンドラインオプションを追加"""
    parser.addoption(
        "--include-heavy", "-H",
        action="store_true",
        default=False,
        help="Include scenarios tagged as 'heavy' (default: skip heavy scenarios)",
    )


def pytest_configure(config):
    """pytest設定"""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "vba: marks tests that execute VBA macros"
    )


@pytest.fixture(scope="session")
def timing_tracker():
    """各シナリオの実行結果と時刻を収集するセッションスコープのフィクスチャ。

    Returns:
        list[dict]: 各シナリオの結果を格納するリスト。
            要素の構造: {name, status, start_dt, end_dt, elapsed}
    """
    return _scenario_results


def pytest_sessionstart(session):
    """テストセッション開始時にセッションログを設定"""
    global _session_log_file, _session_start_time
    _session_start_time = time.time()
    log_path = TEMP_DIR / "test_result.log"
    start_session_log(log_path)  # 既存ログをバックアップ、マーカー作成
    _session_log_file = open(log_path, "w", encoding="utf-8")
    sys.stdout = Tee(sys.stdout, _session_log_file)
    print(session_header())
    print(f"Session log: {log_path}")


def pytest_sessionfinish(session, exitstatus):
    """全テスト終了時のクリーンアップとサマリー表示"""
    global _session_log_file
    kill_excel_processes()
    if _scenario_results:
        _print_session_summary(_scenario_results, _session_start_time)
    if _session_log_file:
        if isinstance(sys.stdout, Tee):
            sys.stdout = sys.stdout._console
        _session_log_file.close()
        _session_log_file = None


def _print_session_summary(results: list[dict], session_start: float) -> None:
    """全シナリオのPASS/FAILED一覧と全体時刻を表示する。"""
    from datetime import datetime
    session_end = time.time()
    session_start_dt = datetime.fromtimestamp(session_start)
    session_end_dt = datetime.fromtimestamp(session_end)
    session_elapsed = session_end - session_start

    # 列幅をシナリオ名の最大長に合わせる
    name_width = max(len(r["name"]) for r in results)
    name_width = max(name_width, 10)
    sep = "=" * (name_width + 46)
    row_sep = "-" * (name_width + 46)

    print(f"\n{sep}")
    print("テスト結果サマリー")
    print(sep)
    header = (
        f"{'シナリオ':<{name_width}}  {'状態':<6}  {'開始時刻':<8}  {'終了時刻':<8}  {'所要時間':>8}"
    )
    print(header)
    print(row_sep)

    pass_count = 0
    fail_count = 0
    for r in results:
        status = r["status"]
        start_str = r["start_dt"].strftime("%H:%M:%S")
        end_str = r["end_dt"].strftime("%H:%M:%S")
        elapsed_str = _fmt_elapsed(r["elapsed"])
        marker = "✓" if status == "PASS" else "✗"
        print(
            f"{r['name']:<{name_width}}  {marker} {status:<5}  {start_str:<8}  {end_str:<8}  {elapsed_str:>8}"
        )
        if status == "PASS":
            pass_count += 1
        else:
            fail_count += 1

    print(row_sep)
    overall_start = session_start_dt.strftime("%H:%M:%S")
    overall_end = session_end_dt.strftime("%H:%M:%S")
    overall_elapsed = _fmt_elapsed(session_elapsed)
    print(
        f"{'[全体]':<{name_width}}  {'':6}  {overall_start:<8}  {overall_end:<8}  {overall_elapsed:>8}"
    )
    print(row_sep)
    print(f"PASS: {pass_count}  FAILED: {fail_count}  合計: {pass_count + fail_count}")
    print(sep)
