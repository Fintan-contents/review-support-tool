"""テストオーケストレーター

自動テストと手動テストをまとめて順に実行する。

実行方法:
  python scripts/test_runner.py                           # 全テスト実行
  python scripts/test_runner.py scenario07                # 指定シナリオのみ
  python scripts/test_runner.py scenario07 scenario08     # 複数シナリオ指定
"""
import subprocess
import sys
from pathlib import Path


SCRIPTS_DIR = Path(__file__).parent


def main():
    filters = sys.argv[1:]

    print("=" * 60)
    print("[1/2] 自動テスト実行中...")
    print("=" * 60)
    auto_cmd = [
        sys.executable, "-m", "pytest",
        str(SCRIPTS_DIR / "auto_test_runner.py"),
        "-v", "--tb=short",
    ]
    if filters:
        auto_cmd += ["-k", " or ".join(filters)]
    subprocess.run(auto_cmd, check=False)

    print()
    print("=" * 60)
    print("[2/2] 手動テスト実行中...")
    print("=" * 60)
    manual_cmd = [sys.executable, str(SCRIPTS_DIR / "manual_test_runner.py")] + filters
    subprocess.run(manual_cmd, check=False)


if __name__ == "__main__":
    main()
