#!/usr/bin/env python3
"""
VBAコードをxlsmファイルから抽出してテキストファイルに保存する

使用方法:
    python extract_vba.py [xlsm_path] [output_dir]

引数:
    xlsm_path: xlsmファイルのパス（デフォルト: tool/Excel設計書レビュー指摘事項抽出ツール.xlsm）
    output_dir: 出力ディレクトリ（デフォルト: vba_modules）

依存関係:
    - oletools (pip install oletools)

例:
    # デフォルト設定で実行
    python extract_vba.py

    # カスタムパスを指定
    python extract_vba.py path/to/file.xlsm path/to/output
"""

import subprocess
import re
import os
import shutil
import sys
from pathlib import Path

# Windows環境でUTF-8出力を強制
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')


def extract_vba(xlsm_path: str, output_dir: str) -> int:
    """
    xlsmファイルからVBAコードを抽出してテキストファイルに保存

    Args:
        xlsm_path: xlsmファイルのパス
        output_dir: 出力ディレクトリのパス

    Returns:
        抽出されたモジュール数
    """
    # ファイルの存在確認
    if not os.path.exists(xlsm_path):
        print(f'❌ エラー: ファイルが見つかりません: {xlsm_path}')
        sys.exit(1)

    # 出力ディレクトリをクリーンアップ
    if os.path.exists(output_dir):
        print(f'既存の出力ディレクトリを削除: {output_dir}')
        shutil.rmtree(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    print(f'\n=== VBAコードの抽出 ===')
    print(f'入力: {xlsm_path}')
    print(f'出力: {output_dir}/\n')

    # olevbaでVBAコードを抽出
    try:
        result = subprocess.run(
            ['olevba', xlsm_path, '--decode'],
            capture_output=True,
            text=True,
            encoding='utf-8',
            timeout=60
        )
    except FileNotFoundError:
        print('❌ エラー: olevbaコマンドが見つかりません')
        print('   インストール方法: pip install oletools')
        sys.exit(1)
    except subprocess.TimeoutExpired:
        print('❌ エラー: olevbaの実行がタイムアウトしました')
        sys.exit(1)

    if result.returncode != 0:
        print(f'❌ エラー: olevbaの実行に失敗しました')
        print(f'   {result.stderr}')
        sys.exit(1)

    content = result.stdout

    # モジュールごとに分割
    # パターン: "VBA MACRO <module_name>" から次の "VBA MACRO" または "---No suspicious" まで
    pattern = r'VBA MACRO (\S+)\s+in file:.*?- - - - - -(.*?)(?=VBA MACRO|\-\-\-No suspicious|$)'
    matches = re.findall(pattern, content, re.DOTALL)

    if not matches:
        print('⚠️  警告: VBAマクロが見つかりませんでした')
        return 0

    module_count = 0
    total_lines = 0

    for module_name, code in matches:
        # コードをクリーンアップ
        code_lines = code.strip().split('\n')
        cleaned_lines = []

        for line in code_lines:
            # olevba のセキュリティ解析レポート（テーブル）の開始行で打ち切る
            # 例: "+----------+--------------------+..." で始まる行
            if line.startswith('+---'):
                break
            # 空行や区切り線を除外
            if line.strip() and not line.startswith('---'):
                cleaned_lines.append(line)

        # ファイルに保存
        if cleaned_lines or module_name.endswith('.cls'):  # 空のclsファイルも保存
            module_path = os.path.join(output_dir, module_name)
            with open(module_path, 'w', encoding='utf-8') as f:
                if cleaned_lines:
                    f.write('\n'.join(cleaned_lines))
                    f.write('\n')  # 末尾に改行を追加
                else:
                    f.write('(empty macro)\n')

            module_count += 1
            line_count = len(cleaned_lines) if cleaned_lines else 0
            total_lines += line_count

            # 進捗表示
            if line_count > 0:
                print(f'✅ {module_name:30s} ({line_count:4d} lines)')
            else:
                print(f'✅ {module_name:30s} (empty)')

    # サマリー表示
    print(f'\n{"=" * 60}')
    print(f'総モジュール数: {module_count}個')
    print(f'総コード行数: {total_lines:,}行')
    print(f'出力先: {os.path.abspath(output_dir)}/')
    print(f'{"=" * 60}\n')

    # ファイル一覧を表示
    print('生成されたファイル:')
    for filename in sorted(os.listdir(output_dir)):
        filepath = os.path.join(output_dir, filename)
        size = os.path.getsize(filepath)
        print(f'  • {filename:30s} ({size:6,} bytes)')

    return module_count


def main():
    """メイン処理"""
    # デフォルト値
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    doctool_dir = os.path.dirname(project_dir)

    default_xlsm = os.path.join(doctool_dir, 'Excel設計書レビュー指摘事項抽出ツール', 'Excel設計書レビュー指摘事項抽出ツール.xlsm')
    default_output = os.path.join(project_dir, 'vba_modules')

    # コマンドライン引数の処理
    if len(sys.argv) > 1:
        xlsm_path = sys.argv[1]
    else:
        xlsm_path = default_xlsm

    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    else:
        output_dir = default_output

    # VBAコードを抽出
    try:
        module_count = extract_vba(xlsm_path, output_dir)

        if module_count > 0:
            print(f'\n✅ VBAコードの抽出が完了しました！')
            print(f'\n次のステップ:')
            print(f'  1. 抽出されたファイルを確認: ls -lh {output_dir}/')
            print(f'  2. VBAコードを編集: code {output_dir}/Sheet1.cls')
            print(f'  3. Gitに追加: git add {output_dir}/')
        else:
            print(f'\n⚠️  VBAマクロが見つかりませんでした')

    except KeyboardInterrupt:
        print('\n\n❌ 処理が中断されました')
        sys.exit(1)
    except Exception as e:
        print(f'\n❌ エラーが発生しました: {e}')
        sys.exit(1)


if __name__ == '__main__':
    main()
