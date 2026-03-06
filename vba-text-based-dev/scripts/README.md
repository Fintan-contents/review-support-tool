# Scripts - VBA Development Tools

Excel 指摘抽出ツールの開発・保守を支援する自動化スクリプト集です。

環境準備やトラブルシューティングは [親README](../README.md) を参照してください。

---

## スクリプト詳細

### build_vba.py

**機能**: VBA テキストファイルから xlsm ファイルをビルド（統合）

**使用方法**:

```cmd
REM カレントディレクトリで直接実行
python scripts\build_vba.py

REM または、バッチファイル経由
scripts\build.bat
```

**処理内容**:

1. `vba_modules\` 配下の VBA テキストファイル（.bas, .cls）を読み込み
2. Excel COM オブジェクトを使用して xlsm ファイルを開く
3. 既存の VBA モジュールを削除
4. 新しい VBA コードを追加（UTF-8 対応）
5. xlsm ファイルを保存

**出力**: `..\Excel設計書レビュー指摘事項抽出ツール\Excel設計書レビュー指摘事項抽出ツール.xlsm`（直接更新）

**注意事項**:

- Excel が開いている場合はエラーになります。実行前に Excel を閉じてください
- xlsm ファイルを直接更新します。失敗した場合は Git 履歴から復元できます

---

### extract_vba.py

**機能**: xlsm ファイルから VBA コードをテキストファイルに抽出

**使用方法**:

```cmd
python scripts\extract_vba.py
# または
scripts\extract.bat
```

**処理内容**:

1. 公式版 xlsm ファイルをバイナリ解析（oletools 使用）
2. VBA マクロをモジュールごとに抽出
3. `vba_modules\` 配下にテキストファイルとして保存（.bas, .cls）
4. 区切り線や不要な文字を除外

**コマンドライン引数**:

```cmd
python scripts\extract_vba.py [xlsm_path] [output_dir]
```

- `xlsm_path`: xlsm ファイルのパス（デフォルト: `..\Excel設計書レビュー指摘事項抽出ツール\Excel設計書レビュー指摘事項抽出ツール.xlsm`）
- `output_dir`: 出力ディレクトリ（デフォルト: `vba_modules`）

**注意**:

- 既存の `vba_modules\` ディレクトリは削除されます
- 空のモジュールは `(empty macro)` として保存されます

---

## 技術詳細

### VBA抽出の仕組み

- **ツール**: oletools（olevba）
- **処理**: xlsm ファイル（ZIP アーカイブ）内の `vbaProject.bin` をバイナリ解析
- **出力**: モジュールごとにテキストファイル（UTF-8）
- **特徴**: 純粋なバイナリ解析のため、Windows/Linux/macOS のどの環境でも実行可能

### VBAビルドの仕組み

- **ツール**: pywin32（win32com.client）
- **処理**: Excel COM オブジェクトを操作して VBA コードをプログラマティックに更新
- **方式**:
  - 標準モジュール（.bas）: `VBComponents.Add(1)` で新規作成後、`AddFromString()` でコード追加
  - ドキュメントモジュール（.cls）: 既存モジュールのコードを `DeleteLines()` で削除後、`AddFromString()` で追加
- **制約**: Excel COM オブジェクト（Windows 専用技術）が必要なため、Windows 環境でのみ実行可能
