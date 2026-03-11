# テストガイド

`Excel設計書レビュー指摘事項抽出ツール.xlsm` のテストガイド。

テスト観点・シナリオの詳細は以下を参照：

- [TEST_VIEWPOINTS.md](TEST_VIEWPOINTS.md) - テスト観点一覧（ID 01〜45）
- [TEST_SCENARIOS.md](TEST_SCENARIOS.md) - シナリオ一覧・フィクスチャ詳細・シナリオ手順

---

## セットアップ

### 前提条件

- Windows 環境（Excel が必要）
- Python 3.10 以上
- Microsoft Excel がインストールされていること

### Python 依存パッケージのインストール

```bat
cd doctool\test
pip install -r requirements.txt
```

依存パッケージ一覧（`requirements.txt`）:

| パッケージ | 用途 |
|-----------|------|
| `openpyxl` | Gold Master 比較（xlsx 読み込み・コメント比較） |
| `psutil` | テスト後の Excel プロセス終了確認 |
| `pytest` | 自動テストランナー |
| `pyyaml` | `config.yaml` の読み込み |
| `xlwings` | Excel COM 経由での VBA 実行 |

---

## テスト実行方法

### 自動テスト

```bash
# 全シナリオ実行
cd doctool/test
run_auto_tests.bat

# 特定シナリオのみ実行
run_auto_tests.bat scenario04

# 複数シナリオを指定して実行
run_auto_tests.bat scenario07 scenario08 scenario09
```

### 手動テスト

```bash
# 全手動シナリオ実行
run_manual_tests.bat

# 特定シナリオのみ実行
run_manual_tests.bat scenario05

# 複数シナリオを指定して実行
run_manual_tests.bat scenario05 scenario06
```

### 自動テスト → 手動テストをまとめて実行

```bash
# 全テスト実行
run_tests.bat

# シナリオを絞り込んで実行（自動・手動それぞれ該当するものが実行される）
run_tests.bat scenario07 scenario08
```

### テストの仕組み

- **config.yaml 駆動**: 各シナリオフォルダに `config.yaml` を配置し、テスト手順を定義
- **Gold Master 比較**: VBA 実行後の出力（`*_expected.xlsx`）と比較して検証
- **ダイアログ自動化**: testMode パラメータでダイアログをスキップし、ログで確認
- **バックグラウンド実行（自動テスト）**: Excel を非表示で実行（`visible=False`）
- **フォアグラウンド実行（手動テスト）**: Excel を表示して実行（`visible=True`）、ダイアログはユーザーが操作

### config.yaml の書き方

自動・手動テストで共通のスキーマを使用する。

#### 全キー一覧

```yaml
# ---------------------------------------------------------
# 必須キー
# ---------------------------------------------------------

viewpoint: "観点XX: 検証する観点の説明"
# ログ・テスト実行画面に表示される。自動・手動ともに必須。

instructions:
  - "手順1の説明"
  - "手順2の説明"
# 自動テスト: 入力条件・検証内容の説明
# 手動テスト: ユーザーが実行する操作手順

steps:
  - action: extract          # 抽出マクロ(CmdGen_Click_Core)を実行
    review_times: 1          # REVIEW_TIMES に設定する値（必須）
    repeat: 2                # 同じ review_times で繰り返す回数（省略時: 1）
  - action: delete_comments  # コメント削除マクロを実行
  - action: delete_sheets    # レビュー結果シート削除マクロを実行

# ---------------------------------------------------------
# オプションキー
# ---------------------------------------------------------

mode: manual
# 省略時は自動テスト（visible=False / testMode=True）
# "manual" を指定すると手動テスト（visible=True / testMode=False）

skip_open_files:
  - ".*レビュー記録票.*"
# Excel で開かずにスキップするファイルの正規表現パターン（Python re.fullmatch）
# 例: 記録票が未開封の状態を再現する

excluded_cells:
  - sheet: "レビュー結果1回目"
    cells: ["E4"]
# Gold Master 比較から除外するセル
# 例: 実施日時など毎回変わる値のセル

file_expectations:
  - pattern: "サンプルA"     # ファイル名に re.search でマッチ
    assert_no_sheets:
      - "レビュー結果1回目"  # 指定シートが存在しないことを確認
  - pattern: "サンプルB"
    assert_no_sheets: []     # アサーションなし（Gold Master 比較もスキップ）
# 指定パターンにマッチするファイルは Gold Master 比較の代わりにここで評価される
# 未指定ファイルは _expected.xlsx が存在すれば Gold Master 比較を実施

setup:
  use_review_record: true   # 基本設定 B2（レビュー記録票使用）を上書き（省略時は xlsm 初期値）
  use_summary: true         # 基本設定 B3（レビュー記録サマリ使用）を上書き（省略時は xlsm 初期値）
  review_list_file: "レビュー記録一覧.xlsx"
  # REVIEW_LIST_FILEPATH 名前付き範囲を work_dir 内ファイルの絶対パスで自動設定
  # レビュー記録サマリ使用時は use_summary: true と併せて指定する
  categories:
    - alias: "a"
      name: "01_要件漏れ"
    - alias: "b"
      name: "02_要件誤り"
  # 指摘分類マッピング設定シートを上書き（省略時は xlsm 保存済みの設定を使用）
  # extract ステップの categories キーで上書きするとステップ間でカテゴリを変更できる

# ---------------------------------------------------------
# テンプレートシートのアサーション（v2.0 カテゴリ動的調整の検証）
# ---------------------------------------------------------

template_assertions:
  - sheet: "レビュー結果シートテンプレート"   # 省略時はこのシート名
    category_count: 12       # 行7 B列以降の非空セル数（カテゴリ列数）
    cell_formula_contains:
      - cell: "B9"
        contains: "$K15"     # 指定セルの数式に文字列が含まれることを確認
```

#### 検証方式の選択ガイド

| 状況 | 使う設定 |
|------|---------|
| 出力ファイル全体を検証したい | `_expected.xlsx` を配置（デフォルト Gold Master 比較） |
| 特定セルを比較から除外したい | `excluded_cells` |
| シートが存在しないことを確認したい | `file_expectations` + `assert_no_sheets` |
| ファイルを Gold Master 比較もしたくない | `file_expectations` + `assert_no_sheets: []` |
| ファイルを Excel で開かずに実行したい | `skip_open_files` |
| xlsm の基本設定を上書きしたい（サマリー等） | `setup` |
| カテゴリマッピングを上書きしたい | `setup.categories` |
| ステップ間でカテゴリを変更したい | extract ステップの `categories` |
| テンプレートシートの列数・数式を検証したい | `template_assertions` |

### テスト対象範囲

| テスト方法 | 対象観点 | 備考 |
|----------|---------|-----|
| 自動テスト（`auto/`） | 01〜20, 23〜29 | Gold Master 比較＋ダイアログログ検証 |
| 手動テスト（`manual/`） | 21〜22, 30〜45 | ダイアログ操作・カテゴリ列動的調整（v2.0） |

**注**: 観点 21, 22（抽出前確認ダイアログの「いいえ」「キャンセル」動作）は、ユーザー選択による分岐が必要なため手動テストで実施。
自動テストでは testMode=True でダイアログをスキップし、全ファイル「はい」として処理する。

観点 30〜45（v2.0 カテゴリ列動的調整）は、テスト実行間でカテゴリ設定の変更が必要なため手動テストで実施。
将来的に `config.yaml` の `setup.categories` キーを追加することで自動化が可能。

---

## 注意事項

- 各シナリオを実施する前に、設計書ファイルを **初期状態にリセット** すること
  （ツールが生成した「レビュー結果N回目」シートが残っていると結果が変わる）
- S09 はレビュー記録票をファイルとして配置するが、**Excel では開かずに**実施する
- S05, S06 は A・B 両ファイルを同じフォルダに配置し、両方 Excel で開いて実行する
- S11 はレビュー記録一覧テンプレートファイルの配置が必要（`レビュー記録一覧_S11.xlsx`）

---

## フォルダ構成

```
test/
├── README.md
├── run_auto_tests.bat     # 自動テスト一括実行
├── run_manual_tests.bat   # 手動テスト実行
├── run_tests.bat          # 自動テスト → 手動テストをまとめて実行
├── auto/                  # 自動テストシナリオ（testMode=True）
│   ├── scenarioXX/        # 各シナリオフォルダ（scenario01〜scenario11）
│   │   ├── config.yaml           # テスト手順・観点定義
│   │   ├── *.xlsx                # 入力フィクスチャ（設計書・記録票・レビュー記録一覧等）
│   │   └── *_expected.xlsx       # Gold Master（期待出力）
│   └── ...
├── manual/                # 手動テストシナリオ（visible=True, testMode=False）
│   ├── scenarioXX/        # 各シナリオフォルダ（scenario05〜scenario06）
│   │   ├── config.yaml           # テスト手順・観点定義・file_expectations
│   │   ├── *.xlsx                # 入力フィクスチャ（_expected なし）
│   │   └── *_expected.xlsx       # Gold Master（手動実行後に別途作成）
│   └── ...
└── scripts/
    ├── test_runner.py          # オーケストレーター（自動テスト → 手動テストをまとめて実行）
    ├── auto_test_runner.py     # 自動テストランナー（pytest アダプタ）
    ├── manual_test_runner.py   # 手動テストランナー（対話型）
    ├── scenario_runner.py      # コアロジック（VBA 実行・結果評価の共通処理）
    ├── conftest.py
    └── helpers/
        ├── config_loader.py
        ├── fixture_manager.py
        ├── xlsx_diff.py
        └── xlsx_assertions.py
```
