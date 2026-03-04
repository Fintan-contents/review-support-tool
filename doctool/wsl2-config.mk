# VBA Text-Based Dev Configuration for doctool
# Excel設計書レビュー指摘事項抽出ツール

# プロジェクトディレクトリ
DOCTOOL_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# xlsmファイルのパス
XLSM_FILE := $(DOCTOOL_DIR)/Excel設計書レビュー指摘事項抽出ツール/Excel設計書レビュー指摘事項抽出ツール.xlsm

# VBA出力ディレクトリ
VBA_OUTPUT_DIR := $(DOCTOOL_DIR)/vba_modules
