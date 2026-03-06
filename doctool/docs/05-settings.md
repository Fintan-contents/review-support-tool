# 設定項目一覧・定数定義・補足情報

---

## 設定項目一覧

### 基本設定

| 設定項目 | セル | 型 | 説明 |
|---------|------|---|------|
| レビュー記録票の使用 | B2 | Boolean | TRUEの場合、レビュー記録票へ転記 |
| レビュー記録サマリの使用 | B3 | Boolean | TRUEの場合、レビュー記録一覧を使用 |
| 処理対象Excelブック名 | B4 | 正規表現 | 処理対象ファイル名のパターン |
| 処理対象外Excelブック名 | B5 | 正規表現 | 処理対象外ファイル名のパターン |

### 項目マッピング設定

#### ヘッダ

| 項目 | 列セル | 行セル | 説明 |
|------|-------|-------|------|
| シート名 | B2 | - | 転記先シート名 |
| レビュー回数 | B7 | C7 | レビュー回数の転記位置 |
| 工程 | B8 | C8 | 工程の転記位置 |
| ページ数 | B9 | C9 | ページ数の転記位置 |
| レビュー日付 | B10 | C10 | レビュー日付の転記位置 |
| レビュー開始時刻 | B11 | C11 | レビュー開始時刻の転記位置 |
| レビュー終了時刻 | B12 | C12 | レビュー終了時刻の転記位置 |
| レビュー開始日時 | B13 | C13 | レビュー開始日時の転記位置 |
| レビュー終了日時 | B14 | C14 | レビュー終了日時の転記位置 |
| レビュー時間 | B15 | C15 | レビュー時間の転記位置 |
| レビュア | B16 | C16 | レビュアの転記位置 |
| レビュイ | B17 | C17 | レビュイの転記位置 |

#### サマリ

| 項目 | 列セル | 説明 |
|------|-------|------|
| シート名 | F2 | 転記先シート名 |
| 開始行 | F3 | 転記開始行 |
| レビュー回数 | F7 | レビュー回数の転記列 |
| 工程 | F8 | 工程の転記列 |
| ページ数 | F9 | ページ数の転記列 |
| レビュー日付 | F10 | レビュー日付の転記列 |
| レビュー開始時刻 | F11 | レビュー開始時刻の転記列 |
| レビュー終了時刻 | F12 | レビュー終了時刻の転記列 |
| レビュー開始日時 | F13 | レビュー開始日時の転記列 |
| レビュー終了日時 | F14 | レビュー終了日時の転記列 |
| レビュー時間 | F15 | レビュー時間の転記列 |
| レビュア | F16 | レビュアの転記列 |
| レビュイ | F17 | レビュイの転記列 |

#### 指摘一覧

| 項目 | 列セル | 説明 |
|------|-------|------|
| シート名 | I2 | 転記先シート名 |
| 開始行 | I3 | 転記開始行 |
| レビュー回数 | I7 | レビュー回数の転記列 |
| 指摘分類 | I8 | 指摘分類の転記列 |
| 指摘事項 | I9 | 指摘事項の転記列 |
| レビュア | I10 | レビュアの転記列 |
| 対応内容 | I11 | 対応内容の転記列 |
| レビュイ | I12 | レビュイの転記列 |
| 指摘クローズ | I13 | 指摘クローズ行の転記列 |

### 指摘分類マッピング設定

| エイリアス（A列） | 指摘分類（B列） |
|----------------|---------------|
| a | 01_要件漏れ |
| b | 02_要件誤り |
| c | 11_機能・仕様漏れ |
| d | 12_機能・仕様誤り |
| e | 21_設計・ドキュメント規約違反 |
| f | 22_記述誤り |
| g | 91_疑問点、確認 |
| h | 92_改善要望 |
| i | 93_仕様変更 |

---

## 補足情報

### 定数定義

#### ヘッダの行・列位置

```vba
Const COL_DOC_ID = 2           ' 文書IDの列
Const ROW_DOC_ID = 2           ' 文書IDの行
Const COL_TARGET = 1           ' 対象ファイルの列
Const ROW_TARGET = 4           ' 対象ファイルの行
Const COL_COUNT = 3            ' レビュー回数の列
Const ROW_COUNT = 4            ' レビュー回数の行
Const COL_DATE = 5             ' 実施日の列
Const ROW_DATE = 4             ' 実施日の行
Const COL_START = 6            ' 開始時刻の列
Const ROW_START = 4            ' 開始時刻の行
Const COL_END = 8              ' 終了時刻の列
Const ROW_END = 4              ' 終了時刻の行
Const COL_BREAK = 9            ' レビュー時間の列
Const ROW_BREAK = 4            ' レビュー時間の行
Const COL_CATEGORY_START = 2   ' 指摘分類開始列
Const ROW_CATEGORY = 10        ' 指摘分類の行
```

#### 出力シート名

```vba
Const DETAIL_START_ROW = 15              ' 指摘詳細の開始行
Const OUTPUT_SHEETNAME_PREFIX = "レビュー結果"  ' 出力シート名のプレフィックス
Const OUTPUT_SHEETNAME_SUFFIX = "回目"          ' 出力シート名のサフィックス
Const OUTPUT_ERR_SHEETNAME = "エラーシート"      ' エラーシート名
```

#### 明細の列位置

```vba
Const DETAIL_COL_SHEET = 1          ' シート名の列
Const DETAIL_COL_POSITION = 2       ' 場所の列
Const DETAIL_COL_REVIEWER = 3       ' 指摘者の列
Const DETAIL_COL_CATEGORY = 4       ' 指摘種別の列
Const DETAIL_COL_REVIEW_COMMENT = 5 ' 指摘内容の列
Const DETAIL_COL_FIX_STATUS = 11    ' 対応状況の列
```

### レビュー記録一覧の列位置

```vba
Const DETAIL_ROW_LIST_START = 6      ' レビュー記録一覧の開始行
Const DETAIL_COL_LIST_NO = 1         ' No.の列
Const DETAIL_COL_LIST_PHASE = 3      ' 工程の列
Const DETAIL_COL_LIST_DOC_ID = 4     ' 文書IDの列
Const DETAIL_COL_LIST_TARGET = 6     ' 対象ファイルの列
Const DETAIL_COL_LIST_AUTHOR = 7     ' 作成者の列
Const DETAIL_COL_LIST_COUNT = 8      ' レビュー回数の列
Const DETAIL_COL_LIST_PRE_DOC_ID = 9     ' 前回文書IDの列
Const DETAIL_COL_LIST_VOLUME = 10        ' ページ数の列
Const DETAIL_COL_LIST_DATE = 12          ' 実施日の列
Const DETAIL_COL_LIST_START = 13         ' 開始時刻の列
Const DETAIL_COL_LIST_END = 15           ' 終了時刻の列
Const DETAIL_COL_LIST_BREAK = 16         ' レビュー時間の列
Const DETAIL_COL_LIST_REVIEWER = 17      ' レビュアの列
Const DETAIL_COL_LIST_REVIEWEE = 23      ' レビュイの列
Const DETAIL_COL_LIST_REVIEW_WAY = 25    ' レビュー方式の列
Const DETAIL_COL_LIST_CATEGORY_TOTAL = 28  ' 指摘合計の列
Const DETAIL_COL_LIST_CATEGORY_A = 29      ' 指摘分類aの列
Const DETAIL_COL_LIST_CATEGORY_B = 30      ' 指摘分類bの列
Const DETAIL_COL_LIST_CATEGORY_C = 31      ' 指摘分類cの列
Const DETAIL_COL_LIST_CATEGORY_D = 32      ' 指摘分類dの列
Const DETAIL_COL_LIST_CATEGORY_E = 33      ' 指摘分類eの列
Const DETAIL_COL_LIST_CATEGORY_F = 34      ' 指摘分類fの列
Const DETAIL_COL_LIST_CATEGORY_G = 35      ' 指摘分類gの列
Const DETAIL_COL_LIST_CATEGORY_H = 36      ' 指摘分類hの列
Const DETAIL_COL_LIST_CATEGORY_I = 37      ' 指摘分類iの列
Const DETAIL_COL_LIST_REVIEW_RESULT = 38   ' レビュー結果の列
Const DETAIL_COL_LIST_RE_REVIEW_WAY = 39   ' 再レビュー方式の列
```

### クリーンアップ処理

#### DelAllReviewComments_Click

**処理内容**:

1. 開いている全 Excel ブックをループ
2. ファイル名が処理対象パターンにマッチするブックを抽出
3. 各シートの全コメントをループ
4. コメントに `:` が含まれ、改行があるもののうち、カテゴリが `*` または登録済みカテゴリのものを削除

#### DelAllReviewResultSheets_Click

**処理内容**:

1. 開いている全 Excel ブックをループ
2. ファイル名が処理対象パターンにマッチするブックを抽出
3. シート名に「レビュー結果」と「回目」を含むシート、または「エラーシート」という名前のシートを削除

---

## 改版履歴

| No. | 改版日付 | バージョン | 担当 | 内容 |
|-----|---------|----------|------|------|
| 1 | 2026-03-04 | 1.0 | Claude Code | VBAコード解析により現状の詳細設計書を作成 |
| 2 | 2026-03-06 | 1.1 | Claude Code | docs/ へ分割・現行仕様（Phase1+Phase2実装済み）に整理 |

---

## 参考資料

- VBA 抽出元ファイル: `progress/20260304/vba_modules_extracted/`
- 対象 Excel ファイル: `review-support-tool/doctool/Excel設計書レビュー指摘事項抽出ツール/Excel設計書レビュー指摘事項抽出ツール.xlsm`
