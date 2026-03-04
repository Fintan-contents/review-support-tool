# Makefile for Excel VBA Tool (Generic Version)

# プロジェクトディレクトリ
PROJECT_DIR := $(shell pwd)
SCRIPTS_DIR := $(PROJECT_DIR)/scripts
VBA_DIR := $(PROJECT_DIR)/vba_modules

# プロジェクト固有の設定を読み込み
# 使い方: make -C /path/to/vba-text-based-dev CONFIG=/path/to/project/config.mk build
-include $(CONFIG)

# Windows側のPythonパス（環境に応じて調整）
# WSL2の場合、Windowsのpython.exeを使用
WINDOWS_PYTHON := python.exe

# Linuxコマンド
PYTHON := python3

.PHONY: help build extract clean check-windows check-wsl

# デフォルトターゲット
help:
	@echo "Excel VBA Tool - Makefile (Generic Version)"
	@echo ""
	@echo "使用方法:"
	@echo "  make CONFIG=path/to/config.mk build   - VBAテキストファイルからxlsmファイルをビルド"
	@echo "  make CONFIG=path/to/config.mk extract - xlsmファイルからVBAテキストファイルを抽出"
	@echo "  make clean                            - 一時ファイルを削除"
	@echo "  make check                            - 環境チェック"
	@echo ""
	@echo "設定ファイル (config.mk) の例:"
	@echo "  XLSM_FILE := /path/to/your/file.xlsm"
	@echo "  VBA_OUTPUT_DIR := /path/to/vba_modules"
	@echo ""
ifdef CONFIG
	@echo "現在の設定:"
	@echo "  設定ファイル: $(CONFIG)"
	@echo "  xlsmファイル: $(XLSM_FILE)"
	@echo "  VBA出力先: $(VBA_OUTPUT_DIR)"
	@echo ""
else
	@echo "⚠️  CONFIG変数が指定されていません"
	@echo "   例: make CONFIG=../doctool/config.mk build"
	@echo ""
endif

# VBAビルド（Windows環境が必要）
build: check-config check-windows
	@echo "🚀 VBAビルドを開始します..."
	@echo ""
	$(WINDOWS_PYTHON) "$(SCRIPTS_DIR)/build_vba.py" "$(VBA_OUTPUT_DIR)" "$(XLSM_FILE)"
	@echo ""
	@echo "✅ ビルド完了"

# VBA抽出（Linux環境で実行可能）
extract: check-config
	@echo "📤 VBAコードを抽出します..."
	@echo ""
	$(PYTHON) $(SCRIPTS_DIR)/extract_vba.py "$(XLSM_FILE)" "$(VBA_OUTPUT_DIR)"
	@echo ""
	@echo "✅ 抽出完了"

# クリーンアップ
clean:
	@echo "🗑️  一時ファイルを削除します..."
	rm -f $(PROJECT_DIR)/vba_extracted_full.txt
	find $(PROJECT_DIR) -name "*.pyc" -delete 2>/dev/null || true
	@echo "✅ クリーンアップ完了"

# 環境チェック
check: check-wsl check-windows
	@echo ""
	@echo "✅ 環境チェック完了"

# 設定ファイルチェック
check-config:
ifndef CONFIG
	@echo "❌ エラー: CONFIG変数が指定されていません"
	@echo "   使用方法: make CONFIG=path/to/config.mk <target>"
	@echo ""
	@echo "   例:"
	@echo "     make CONFIG=../doctool/config.mk build"
	@echo "     make CONFIG=../prtool/config.mk extract"
	@exit 1
endif
ifndef XLSM_FILE
	@echo "❌ エラー: XLSM_FILEが設定されていません"
	@echo "   config.mkに以下を記載してください:"
	@echo "   XLSM_FILE := /path/to/your/file.xlsm"
	@exit 1
endif
ifndef VBA_OUTPUT_DIR
	@echo "❌ エラー: VBA_OUTPUT_DIRが設定されていません"
	@echo "   config.mkに以下を記載してください:"
	@echo "   VBA_OUTPUT_DIR := /path/to/vba_modules"
	@exit 1
endif

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
		echo "  ⚠️  VBAディレクトリが見つかりません: $(VBA_DIR)"; \
		echo "     (初回実行時は作成されます)"; \
	fi
ifdef XLSM_FILE
	@if [ -f "$(XLSM_FILE)" ]; then \
		echo "  ✅ xlsmファイル: $(XLSM_FILE)"; \
	else \
		echo "  ❌ xlsmファイルが見つかりません: $(XLSM_FILE)"; \
	fi
endif

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
