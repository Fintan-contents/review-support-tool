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

カテゴリは設定シートに上から記入した順序で処理・出力される。コード修正なしに追加・削除が可能。

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

#### エイリアス体系

- エイリアスは英小文字 1 文字（a〜z）または 2 文字（aa〜zz）
- `ExtractCategory` 関数が 1〜2 文字のカテゴリを抽出する
- `IsValidCategory` 関数で設定シートの登録済みエイリアスと照合する

---

## 補足情報

### 定数定義

#### Module1.bas 公開定数（シート名）

```vba
Public Const SHT_KIHON_SETTINGS As String = "基本設定"
Public Const SHT_CATEGORY_MAPPINGS As String = "指摘分類マッピング設定"
Public Const SHT_ITEM_MAPPINGS As String = "項目マッピング設定"
Public Const SHT_REVIEW_RECORD As String = "レビュー記録票"
Public Const SHT_PERF_LOG As String = "パフォーマンス計測"
```

#### Module1.bas 型定義（User Defined Type）

```vba
Public Type BasicSettings
    useReviewRecord As Boolean    ' レビュー記録票の使用（基本設定シート B2）
    useSimpleSummary As Boolean   ' レビュー記録サマリの使用（基本設定シート B3）
End Type
```

`MappingConfig` 型は項目マッピング設定シートの転記先定義（34フィールド）を保持する。フィールドは `headerXxx`（ヘッダシート）・`summaryXxx`（サマリシート）・`listXxx`（指摘一覧シート）の3系統。

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

#### Sheet1.cls 追加定数（SheetTemplate・検索上限）

```vba
' SheetTemplateのSUMIFエイリアス列開始（列L=12）
' COL_CATEGORY_START(2) + カテゴリ列最大数(9) + 小計列(1) = 12
Const COL_CATEGORY_HEADER_START = 12

' カテゴリ表示エリア行範囲（行7〜11: ヘッダー・集計行）
Const CATEGORY_DISPLAY_ROW_START = 7
Const CATEGORY_DISPLAY_ROW_END = 11

' レビュー記録票シートの行検索上限オフセット
Const SUMMARY_ROW_SEARCH_LIMIT = 100    ' サマリシート行検索上限
Const LIST_ROW_SEARCH_LIMIT = 1000      ' 指摘一覧シート行検索上限
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
Const DETAIL_COL_LIST_CATEGORY_START = 29  ' 指摘分類の開始列（2026-03-31: 動的。設定シートのカテゴリ数に応じてN列分使用）
' 2026-03-31 以降は廃止し DETAIL_COL_LIST_CATEGORY_START + N で計算する:
'   DETAIL_COL_LIST_REVIEW_RESULT  = DETAIL_COL_LIST_CATEGORY_START + categoryCount
'   DETAIL_COL_LIST_RE_REVIEW_WAY  = DETAIL_COL_LIST_CATEGORY_START + categoryCount + 1
```

> **実装メモ**: 以前は `DETAIL_COL_LIST_CATEGORY_A`〜`DETAIL_COL_LIST_CATEGORY_I`（列 29〜37）を固定定数で定義していた。カテゴリ数が可変になったため、`DETAIL_COL_LIST_CATEGORY_START = 29` を基点とした動的オフセット計算に統一する。

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
| 3 | 2026-03-07 | 1.2 | Claude Code | 動的カテゴリ対応仕様を反映：エイリアス体系セクション追加、カテゴリ列定数を動的方式（CATEGORY_START）に更新 |
| 4 | 2026-03-15 | 1.3 | Claude Code | cmd_289 VBA改善を反映：SHT_*定数・BasicSettings型・MappingConfig型・SheetTemplate定数（CATEGORY_DISPLAY_ROW_START/END・SUMMARY/LIST_ROW_SEARCH_LIMIT）を追加 |

---

## 参考資料

- VBA 抽出元ファイル: `progress/20260304/vba_modules_extracted/`
- 対象 Excel ファイル: `review-support-tool/doctool/Excel設計書レビュー指摘事項抽出ツール/Excel設計書レビュー指摘事項抽出ツール.xlsm`
