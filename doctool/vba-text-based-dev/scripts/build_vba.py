#!/usr/bin/env python3
"""
VBAテキストファイルからxlsmファイルをビルドする（Windows専用）

このスクリプトはWindows環境で実行する必要があります。
WSL2からは以下のように呼び出します：
    python.exe /mnt/c/path/to/build_vba.py

依存関係:
    - pywin32 (Windows専用)
    - Excel (インストール済み)

使用方法:
    # Windows側で実行
    python build_vba.py

    # WSL2から実行
    python.exe $(wslpath -w /workspace/etc/Excel指摘抽出ツール/scripts/build_vba.py)
"""

import sys
import os
from pathlib import Path

# Windows環境でUTF-8出力を強制
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Windows環境チェック
if sys.platform != 'win32':
    print("❌ エラー: このスクリプトはWindows環境でのみ動作します")
    print("   WSL2から実行する場合は python.exe を使用してください")
    sys.exit(1)

try:
    import win32com.client
except ImportError:
    print("❌ エラー: pywin32がインストールされていません")
    print("   インストール方法: pip install pywin32")
    sys.exit(1)


def build_xlsm(
    vba_dir: str,
    xlsm_path: str
) -> bool:
    """
    VBAテキストファイルからxlsmファイルをビルド

    Args:
        vba_dir: VBAモジュールディレクトリ
        xlsm_path: 更新対象のxlsmファイル（直接更新される）

    Returns:
        成功した場合True
    """
    # パスを絶対パスに変換
    vba_dir = os.path.abspath(vba_dir)
    xlsm_path = os.path.abspath(xlsm_path)

    print(f"\n{'='*70}")
    print(f"VBA ビルドスクリプト")
    print(f"{'='*70}")
    print(f"VBAディレクトリ: {vba_dir}")
    print(f"XLSMファイル: {xlsm_path}")
    print(f"{'='*70}\n")

    # VBAモジュールファイルを取得
    if not os.path.exists(vba_dir):
        print(f"❌ エラー: VBAディレクトリが見つかりません: {vba_dir}")
        return False

    vba_files = []
    for ext in ['.cls', '.bas', '.frm']:
        vba_files.extend(Path(vba_dir).glob(f'*{ext}'))

    if not vba_files:
        print(f"❌ エラー: VBAモジュールファイルが見つかりません: {vba_dir}")
        return False

    print(f"VBAモジュール: {len(vba_files)}個")
    for vba_file in sorted(vba_files):
        print(f"  - {vba_file.name}")

    # XLSMファイルの存在確認
    if not os.path.exists(xlsm_path):
        print(f"\n❌ エラー: XLSMファイルが見つかりません: {xlsm_path}")
        return False

    # Excelアプリケーションを起動
    print(f"\n🚀 Excelアプリケーションを起動...")
    excel = None
    wb = None

    try:
        excel = win32com.client.Dispatch("Excel.Application")
        excel.Visible = False  # バックグラウンドで実行
        excel.DisplayAlerts = False  # 警告ダイアログを無効化
        excel.EnableEvents = False  # イベントを無効化
        excel.AutomationSecurity = 1  # msoAutomationSecurityLow

        print(f"✅ Excel起動完了\n")

        # xlsmファイルを開く
        print(f"📂 xlsmファイルを開く: {xlsm_path}")
        wb = excel.Workbooks.Open(xlsm_path)

        # 既存のVBAモジュールを削除（シートモジュールは除く）
        print(f"\n🗑️  既存のVBAモジュールを削除...")
        components_to_remove = []

        for component in wb.VBProject.VBComponents:
            # vbext_ct_StdModule (1) = 標準モジュール
            # vbext_ct_ClassModule (2) = クラスモジュール
            # vbext_ct_MSForm (3) = ユーザーフォーム
            # vbext_ct_Document (100) = ドキュメント（シート、ThisWorkbook）

            comp_type = component.Type
            comp_name = component.Name

            # ドキュメントモジュール（Sheet*, ThisWorkbook）は削除しない
            if comp_type == 100:  # vbext_ct_Document
                print(f"   ⏭️  スキップ: {comp_name} (ドキュメントモジュール)")
                continue

            # 標準モジュール・クラスモジュール・フォームは削除
            if comp_type in [1, 2, 3]:
                components_to_remove.append(component)
                print(f"   🗑️  削除予定: {comp_name}")

        # 削除実行
        for component in components_to_remove:
            comp_name = component.Name  # 削除前に名前を保存
            wb.VBProject.VBComponents.Remove(component)
            print(f"   ✅ 削除完了: {comp_name}")

        # 新しいVBAモジュールをインポート
        print(f"\n📥 新しいVBAモジュールをインポート...")
        imported_count = 0

        for vba_file in sorted(vba_files):
            vba_path = str(vba_file.absolute())

            # ファイルが空でないか確認
            if os.path.getsize(vba_path) < 20:  # "(empty macro)"のみの場合
                print(f"   ⏭️  スキップ: {vba_file.name} (空のモジュール)")
                continue

            try:
                # ドキュメントモジュール（Sheet*, ThisWorkbook）の場合は上書き
                is_document_module = False
                for component in wb.VBProject.VBComponents:
                    if component.Type == 100 and component.Name == vba_file.stem:
                        is_document_module = True
                        print(f"   📝 更新: {vba_file.name} → {component.Name} (ドキュメントモジュール)")

                        # コードを読み込んで上書き
                        with open(vba_path, 'r', encoding='utf-8') as f:
                            code = f.read()

                        # 区切り線を除外（olevbaが出力する "- - - - -" のような行）
                        code_lines = code.split('\n')
                        cleaned_lines = []
                        for line in code_lines:
                            # 区切り線パターン: ハイフンとスペースのみで構成される行
                            stripped = line.strip()
                            if stripped and not (stripped.replace('-', '').replace(' ', '') == ''):
                                cleaned_lines.append(line)
                            elif not stripped:  # 空行は保持
                                cleaned_lines.append(line)
                        code = '\n'.join(cleaned_lines)

                        # 既存のコードを削除（常に実行）
                        if component.CodeModule.CountOfLines > 0:
                            component.CodeModule.DeleteLines(1, component.CodeModule.CountOfLines)

                        # 空マクロの場合はコード追加をスキップ
                        if '(empty macro)' not in code:
                            # 新しいコードを追加
                            component.CodeModule.AddFromString(code)
                            imported_count += 1
                        break

                # 標準モジュール・クラスモジュールの場合は新規作成してコード追加
                if not is_document_module:
                    # ファイルサイズチェック（空モジュールはスキップ）
                    if os.path.getsize(vba_path) < 20:
                        print(f"   ⏭️  スキップ: {vba_file.name} (空のモジュール)")
                        continue

                    # コードを読み込む
                    with open(vba_path, 'r', encoding='utf-8') as f:
                        code = f.read()

                    # 区切り線を除外
                    code_lines = code.split('\n')
                    cleaned_lines = []
                    for line in code_lines:
                        stripped = line.strip()
                        if stripped and not (stripped.replace('-', '').replace(' ', '') == ''):
                            cleaned_lines.append(line)
                        elif not stripped:
                            cleaned_lines.append(line)
                    code = '\n'.join(cleaned_lines)

                    # 空マクロチェック
                    if '(empty macro)' in code:
                        print(f"   ⏭️  スキップ: {vba_file.name} (空のモジュール)")
                        continue

                    # 新しいモジュールを作成
                    # vbext_ct_StdModule = 1
                    module_name = vba_file.stem
                    new_module = wb.VBProject.VBComponents.Add(1)
                    new_module.Name = module_name

                    # コードを追加
                    new_module.CodeModule.AddFromString(code)
                    print(f"   ✅ インポート: {vba_file.name}")
                    imported_count += 1

            except Exception as e:
                print(f"   ❌ エラー: {vba_file.name} - {e}")

        print(f"\n✅ インポート完了: {imported_count}個のモジュール")

        # xlsmファイルとして保存
        print(f"\n💾 xlsmファイルとして保存...")
        wb.Save()
        print(f"✅ 保存完了: {output_xlsm}")

        # ファイルを閉じる
        wb.Close(SaveChanges=False)
        print(f"✅ ファイルを閉じました")

        print(f"\n{'='*70}")
        print(f"🎉 ビルド成功！")
        print(f"{'='*70}")
        print(f"出力ファイル: {output_xlsm}")
        print(f"{'='*70}\n")

        return True

    except Exception as e:
        print(f"\n❌ エラーが発生しました: {e}")
        import traceback
        traceback.print_exc()
        return False

    finally:
        # クリーンアップ
        if wb:
            try:
                wb.Close(SaveChanges=False)
            except:
                pass
        if excel:
            try:
                excel.Quit()
            except:
                pass


def main():
    """メイン処理"""
    # デフォルト設定
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    doctool_dir = os.path.dirname(project_dir)

    vba_dir = os.path.join(project_dir, 'vba_modules')
    xlsm_path = os.path.join(doctool_dir, 'Excel設計書レビュー指摘事項抽出ツール', 'Excel設計書レビュー指摘事項抽出ツール.xlsm')

    # コマンドライン引数から設定を上書き
    if len(sys.argv) > 1:
        vba_dir = sys.argv[1]
    if len(sys.argv) > 2:
        xlsm_path = sys.argv[2]

    # ビルド実行
    success = build_xlsm(vba_dir, xlsm_path)

    if success:
        print("✅ ビルドが完了しました")
        sys.exit(0)
    else:
        print("❌ ビルドに失敗しました")
        sys.exit(1)


if __name__ == '__main__':
    main()
