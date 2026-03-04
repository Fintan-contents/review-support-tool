@echo off
REM VBA Text-Based Dev Configuration for doctool
REM Excel設計書レビュー指摘事項抽出ツール

REM xlsmファイルのパス
set XLSM_FILE=%~dp0Excel設計書レビュー指摘事項抽出ツール\Excel設計書レビュー指摘事項抽出ツール.xlsm

REM VBA出力ディレクトリ
set VBA_OUTPUT_DIR=%~dp0vba_modules
