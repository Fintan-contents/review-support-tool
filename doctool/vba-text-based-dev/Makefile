# Makefile for Excel VBA Tool

# プロジェクトディレクトリ
PROJECT_DIR := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_DIR)/scripts
VBA_DIR := $(PROJECT_DIR)/vba_modules
DOCTOOL_DIR := $(shell dirname $(PROJECT_DIR))
XLSM_DIR := $(DOCTOOL_DIR)/Excel設計書レビュー指摘事項抽出ツール
XLSM_FILE := $(XLSM_DIR)/Excel設計書レビュー指摘事項抽出ツール.xlsm

# Windows側のPythonパス（環境に応じて調整）
# WSL2の場合、Windowsのpython.exeを使用
WINDOWS_PYTHON := python.exe

# Windows側のビルドスクリプトパス
# python.exeはWSL2パスを直接理解できるため、変換不要
BUILD_SCRIPT := $(SCRIPTS_DIR)/build_vba.py

# Linuxコマンド
PYTHON := python3

.PHONY: help build extract clean check-windows check-wsl

# デフォルトターゲット
help:
	@echo "Excel VBA Tool - Makefile"
	@echo ""
	@echo "使用方法:"
	@echo "  make build     - VBAテキストファイルからxlsmファイルをビルド（Windows環境が必要）"
	@echo "  make extract   - xlsmファイルからVBAテキストファイルを抽出"
	@echo "  make clean     - 一時ファイルを削除"
	@echo "  make check     - 環境チェック"
	@echo ""
	@echo "テスト実行:"
	@echo "  Windowsエクスプローラーから以下の形式のパスで直接開く:"
	@echo "  \\\\wsl.localhost\\<ディストリビューション名>$(XLSM_DIR)/Excel設計書レビュー指摘事項抽出ツール.xlsm"
	@echo ""
	@echo "現在の設定:"
	@echo "  プロジェクトディレクトリ: $(PROJECT_DIR)"
	@echo "  VBAディレクトリ: $(VBA_DIR)"
	@echo "  xlsmファイル: $(XLSM_FILE)"
	@echo "  ビルドスクリプト: $(BUILD_SCRIPT)"
	@echo ""

# VBAビルド（Windows環境が必要）
build: check-windows
	@echo "🚀 VBAビルドを開始します..."
	@echo ""
	$(WINDOWS_PYTHON) "$(BUILD_SCRIPT)"
	@echo ""
	@echo "✅ ビルド完了"

# VBA抽出（Linux環境で実行可能）
extract:
	@echo "📤 VBAコードを抽出します..."
	@echo ""
	$(PYTHON) $(SCRIPTS_DIR)/extract_vba.py
	@echo ""
	@echo "✅ 抽出完了"

# クリーンアップ
clean:
	@echo "🗑️  一時ファイルを削除します..."
	rm -f $(PROJECT_DIR)/vba_extracted_full.txt
	find $(VBA_DIR) -name "*.pyc" -delete
	@echo "✅ クリーンアップ完了"

# 環境チェック
check: check-wsl check-windows
	@echo ""
	@echo "✅ 環境チェック完了"

# WSL2環境チェック
check-wsl:
	@echo "📋 WSL2環境チェック:"
	@if uname -r | grep -qi microsoft; then \
		echo "  ✅ WSL2環境を検出"; \
	else \
		echo "  ⚠️  WSL2環境ではない可能性があります"; \
	fi
	@if [ -d "$(VBA_DIR)" ]; then \
		echo "  ✅ VBAディレクトリ: $(VBA_DIR)"; \
	else \
		echo "  ❌ VBAディレクトリが見つかりません: $(VBA_DIR)"; \
	fi
	@if [ -f "$(XLSM_FILE)" ]; then \
		echo "  ✅ xlsmファイル: $(XLSM_FILE)"; \
	else \
		echo "  ❌ xlsmファイルが見つかりません: $(XLSM_FILE)"; \
	fi

# Windows環境チェック
check-windows:
	@echo "📋 Windows環境チェック:"
	@if command -v python.exe >/dev/null 2>&1; then \
		echo "  ✅ python.exe が利用可能"; \
		python.exe --version 2>&1 | sed 's/^/     /'; \
	else \
		echo "  ❌ python.exe が見つかりません"; \
		echo "     Windows側にPythonをインストールしてください"; \
		exit 1; \
	fi
	@if python.exe -c "import win32com.client" 2>/dev/null; then \
		echo "  ✅ pywin32 がインストール済み"; \
	else \
		echo "  ❌ pywin32 がインストールされていません"; \
		echo "     Windows側で以下を実行してください:"; \
		echo "     pip install pywin32"; \
		exit 1; \
	fi
	@if command -v cmd.exe >/dev/null 2>&1; then \
		echo "  ✅ cmd.exe が利用可能"; \
	else \
		echo "  ⚠️  cmd.exe が見つかりません"; \
	fi
