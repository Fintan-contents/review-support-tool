# VBA Text-Based Development Environment

Excel VBAツールをテキストベースで開発するための環境です。

## 背景・課題

Excel VBAマクロには以下の課題があります：

- **バイナリ形式**: VBAコードはxlsmファイル内にバイナリ形式で埋め込まれる
- **差分が見えない**: Git等のバージョン管理システムで変更内容を追跡できない
- **レビューが困難**: コードレビュー時に差分を確認できないため、品質管理が難しい

## 解決策

この環境では、VBAコードを以下のワークフローで管理します：

1. **VBA抽出**: xlsmファイルからVBAコードをテキストファイルに抽出
2. **テキスト編集**: 通常のテキストエディタでVBAコードを編集
3. **VBAビルド**: 編集したテキストファイルをxlsmファイルにマージ
4. **Git管理**: テキストファイルをGitでバージョン管理（差分・レビューが可能）

## ディレクトリ構造

```text
vba-text-based-dev/
├── README.md                # このファイル
├── WSL2_SETUP.md            # WSL2環境での開発方法（アディショナル）
├── scripts/                 # Python スクリプト
│   ├── README.md            # スクリプト詳細ドキュメント
│   ├── extract.bat          # VBA抽出（バッチファイル）
│   ├── extract_vba.py       # VBA抽出スクリプト
│   ├── build.bat            # VBAビルド（バッチファイル）
│   └── build_vba.py         # VBAビルドスクリプト
└── vba_modules/             # VBAテキストファイル
    ├── Module1.bas
    ├── Sheet1.cls
    └── ...

※ xlsmファイルは ../Excel設計書レビュー指摘事項抽出ツール/ に配置（直接更新）
```

## 前提条件

- Python 3.x
- 必要なライブラリ：

  ```cmd
  pip install oletools pywin32
  ```

インストール確認：

```cmd
python -c "import oletools; print('oletools OK')"
python -c "import win32com.client; print('pywin32 OK')"
```

## 使い方

### 1. VBA抽出

xlsmファイルからVBAコードをテキストファイルに抽出します：

```cmd
cd review-support-tool\doctool\vba-text-based-dev
scripts\extract.bat
```

または：

```cmd
python scripts\extract_vba.py
```

**出力**: `vba_modules\` 配下に各VBAモジュールがテキストファイルとして保存されます。

### 2. VBA編集

`vba_modules\` 配下のテキストファイルを任意のエディタで編集します：

- Visual Studio Code
- Notepad++
- メモ帳
- など

### 3. VBAビルド

編集したテキストファイルをxlsmファイルにマージします：

```cmd
scripts\build.bat
```

または：

```cmd
python scripts\build_vba.py
```

**入力**: `vba_modules\` 配下のテキストファイル

**出力**: `..\Excel設計書レビュー指摘事項抽出ツール\Excel設計書レビュー指摘事項抽出ツール.xlsm` （直接更新）

### 4. テスト実行

ビルド後のxlsmファイルをExcelで開いて動作確認します：

1. エクスプローラーで `..\Excel設計書レビュー指摘事項抽出ツール\` フォルダを開く
2. `Excel設計書レビュー指摘事項抽出ツール.xlsm` をダブルクリック
3. マクロを有効化して動作確認

### 5. Git管理

VBAテキストファイルをコミットします：

```cmd
git add vba_modules\
git commit -m "feat: Update VBA code"
```

## トラブルシューティング

### oletoolsが見つからない

**エラー**: `ModuleNotFoundError: No module named 'oletools'`

**解決策**:

```cmd
pip install oletools
```

### pywin32が見つからない

**エラー**: `ModuleNotFoundError: No module named 'win32com'`

**解決策**:

```cmd
pip install pywin32
```

### xlsmファイルが壊れた

**症状**: ビルド後にExcelで開くとエラー、またはコンパイルエラー

**解決策**:

Git履歴から復元します：

```cmd
git restore ..\Excel設計書レビュー指摘事項抽出ツール\Excel設計書レビュー指摘事項抽出ツール.xlsm
```

### Excelが既に開いている

**エラー**: `'NoneType' object has no attribute 'VBProject'`

**解決策**:

1. Excelをすべて閉じる
2. タスクマネージャーで `EXCEL.EXE` プロセスを確認・終了
3. 再度ビルドを実行

## アディショナルな開発環境

WSL2環境でMakefileやLinuxコマンドを活用した、より効率的な開発も可能です。

詳細は [WSL2_SETUP.md](./WSL2_SETUP.md) を参照してください。

スクリプトの技術的な詳細は [scripts/README.md](./scripts/README.md) を参照してください。
