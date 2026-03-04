# VBA Text-Based Dev Configuration for prtool
# プルリクエストコメント抽出ツール

# プロジェクトディレクトリ
PRTOOL_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# xlsmファイルのパス
XLSM_FILE := $(PRTOOL_DIR)/プルリクエストコメント抽出ツール/プルリクエストコメント抽出ツール.xlsm

# VBA出力ディレクトリ
VBA_OUTPUT_DIR := $(PRTOOL_DIR)/vba_modules
