#!/bin/bash
# VBAビルドスクリプト（WSL2用）
# xlsmファイルにVBAコードをマージします
#
# 使い方: build.sh [設定ファイルのパス]
# 例: build.sh ../../../doctool/wsl2-config.mk

set -e

echo "======================================================================"
echo "VBA ビルド"
echo "======================================================================"
echo ""

# 設定ファイルのパスを確認
if [ -z "$1" ]; then
    echo "❌ エラー: 設定ファイルのパスを指定してください"
    echo ""
    echo "使い方: build.sh [設定ファイルのパス]"
    echo ""
    echo "例:"
    echo "  build.sh ../../../doctool/wsl2-config.mk"
    echo "  build.sh ../../../prtool/wsl2-config.mk"
    echo ""
    exit 1
fi

CONFIG_FILE="$1"

# 設定ファイルが存在するか確認
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ エラー: 設定ファイルが見つかりません: $CONFIG_FILE"
    echo ""
    exit 1
fi

# 設定ファイルのパスを絶対パスに変換
CONFIG_FILE="$(cd "$(dirname "$CONFIG_FILE")" && pwd)/$(basename "$CONFIG_FILE")"

# scripts/wsl2ディレクトリから vba-text-based-dev ディレクトリに移動
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VBA_DEV_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

cd "$VBA_DEV_DIR"

# Makefileを実行
make CONFIG="$CONFIG_FILE" build

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ビルドが完了しました"
else
    echo ""
    echo "❌ ビルドに失敗しました"
    exit 1
fi
