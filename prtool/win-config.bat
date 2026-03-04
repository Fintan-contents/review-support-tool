@echo off
REM VBA Text-Based Dev Configuration for prtool
REM プルリクエストコメント抽出ツール

REM xlsmファイルのパス
set XLSM_FILE=%~dp0プルリクエストコメント抽出ツール\プルリクエストコメント抽出ツール.xlsm

REM VBA出力ディレクトリ
set VBA_OUTPUT_DIR=%~dp0vba_modules
