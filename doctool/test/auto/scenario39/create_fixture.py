"""
S39 テストフィクスチャ生成スクリプト（エイリアス形式不正エラー検証）

S34 の設計書をベースに S39 用の入力ファイルを生成する。
エイリアスの形式不正は config.yaml で設定するため、設計書自体は通常のものを使用。

【実行方法】
    cd /path/to/review-support-tool/doctool/test
    source .venv/bin/activate
    python3 auto/scenario39/create_fixture.py
"""

import shutil
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
TEST_DIR = SCRIPT_DIR.parent.parent  # doctool/test
S34_DIR = TEST_DIR / "auto" / "scenario34"
S39_DIR = SCRIPT_DIR


def main():
    src = S34_DIR / "システム機能設計書_サンプル_S34.xlsx"
    dst = S39_DIR / "システム機能設計書_サンプル_S39.xlsx"

    print(f"Copying: {src} -> {dst}")
    shutil.copy2(src, dst)

    print("Done. Fixture file created:")
    print(f"  {dst.name}")
    print("\nNOTE: This scenario tests E15 (invalid alias format) error.")
    print("Invalid aliases ('A', 'abc') are configured in config.yaml, not in the xlsx.")


if __name__ == "__main__":
    main()
