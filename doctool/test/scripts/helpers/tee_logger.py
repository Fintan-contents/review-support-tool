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


# ============================================================
# セッションログ管理
# ============================================================

def _marker_path(log_path: Path) -> Path:
    """セッションマーカーファイルのパスを返す（ログと同じディレクトリ）"""
    return log_path.parent / ".session_marker"


def start_session_log(log_path: Path) -> None:
    """セッションログを開始する。

    1. 既存ログをタイムスタンプ付きでバックアップ
    2. セッションマーカーファイルを作成（同一セッション判定用）

    呼び出し後に tee_to_file(log_path, mode="w") でログを開始すること。
    """
    log_path.parent.mkdir(parents=True, exist_ok=True)
    if log_path.exists():
        ts = datetime.now().strftime("%Y%m%d%H%M")
        backup = log_path.with_name(f"{log_path.stem}_{ts}{log_path.suffix}")
        log_path.rename(backup)
    _marker_path(log_path).write_text(str(log_path.resolve()), encoding="utf-8")


def is_current_session(log_path: Path) -> bool:
    """log_path が現在のセッションで作成されたものかを確認する。

    conftest の pytest_sessionstart などで start_session_log() が呼ばれていれば True。
    """
    marker = _marker_path(log_path)
    if not marker.exists() or not log_path.exists():
        return False
    return marker.read_text(encoding="utf-8").strip() == str(log_path.resolve())


def session_header() -> str:
    """実行日時ヘッダー文字列を返す"""
    return f"=== テスト実行開始: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ==="
