"""テストオーケストレーター

自動テストと手動テストをまとめて順に実行する。

実行方法:
  python scripts/test_runner.py
"""
import subprocess
import sys
from pathlib import Path


SCRIPTS_DIR = Path(__file__).parent


def main():
    print("=" * 60)
    print("[1/2] 自動テスト実行中...")
    print("=" * 60)
    subprocess.run(
        [
            sys.executable, "-m", "pytest",
            str(SCRIPTS_DIR / "auto_test_runner.py"),
            "-v", "--tb=short",
        ],
        check=False,
    )

    print()
    print("=" * 60)
    print("[2/2] 手動テスト実行中...")
    print("=" * 60)
    subprocess.run(
        [sys.executable, str(SCRIPTS_DIR / "manual_test_runner.py")],
        check=False,
    )


if __name__ == "__main__":
    main()
