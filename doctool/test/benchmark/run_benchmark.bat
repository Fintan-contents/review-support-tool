@echo off
REM VBA マクロ パフォーマンスベンチマーク
REM
REM 使用方法:
REM   run_benchmark.bat                          - デフォルトカテゴリ数リストで計測
REM   run_benchmark.bat --categories 10 50 100   - 指定カテゴリ数のみ計測
REM   run_benchmark.bat --dry-run                - フィクスチャ生成のみ（VBA 実行なし）

cd /d %~dp0..
set TOOL_TEST_ROOT=%CD%

cd /d %~dp0
python run_benchmark.py %*
pause
