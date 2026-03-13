"""標準出力をコンソールとファイルの両方に書き出す Tee ユーティリティ"""
import sys
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path


class Tee:
    """sys.stdout をラップし、コンソールとファイルの両方に書き出す。

    Usage:
        with open("out.log", "w") as f:
            tee = Tee(sys.stdout, f)
            sys.stdout = tee
            print("goes to both console and file")
    """

    def __init__(self, console, logfile):
        self._console = console
        self._logfile = logfile

    def write(self, text):
        self._console.write(text)
        self._logfile.write(text)
        self._logfile.flush()

    def flush(self):
        self._console.flush()
        self._logfile.flush()

    def __getattr__(self, name):
        return getattr(self._console, name)


@contextmanager
def tee_to_file(log_path: Path, mode: str = "w", encoding: str = "utf-8"):
    """コンテキスト内の sys.stdout を log_path にも書き出す。

    既にTeeが設定されていてもネスト可能（外側のTeeが console として扱われる）。

    Usage:
        with tee_to_file(Path("output.log")):
            print("This goes to both console and file")
    """
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with open(log_path, mode, encoding=encoding) as f:
        tee = Tee(sys.stdout, f)
        old_stdout = sys.stdout
        sys.stdout = tee
        try:
            yield log_path
        finally:
            sys.stdout = old_stdout


def start_session_log(log_path: Path) -> None:
    """セッションログを開始する。

    既存ログが存在すれば YYYYMMDDHHMM サフィックスを付けてバックアップし、
    新規ログを作成できる状態にする。
    """
    log_path.parent.mkdir(parents=True, exist_ok=True)
    if log_path.exists():
        ts = datetime.now().strftime("%Y%m%d%H%M")
        backup = log_path.with_name(f"{log_path.stem}_{ts}{log_path.suffix}")
        log_path.rename(backup)


def session_header() -> str:
    """実行日時ヘッダー文字列を返す"""
    return f"=== テスト実行開始: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ==="
