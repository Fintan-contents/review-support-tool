# ExecuteExcel4Macro 使用箇所の調査報告

**調査日**: 2026-03-11
**対象Finding**: M-04（doctool総点検レポート）
**対応優先度**: Medium

---

## 1. 調査概要

`ExecuteExcel4Macro` は Excel 4 マクロ（XLM マクロ）を VBA から呼び出す関数である。
Microsoft が段階的な無効化を進めているため、将来的な動作リスクを評価する。

---

## 2. 使用箇所の特定

**ファイル**: `vba_modules/Sheet1.cls`
**行番号**: 1212行目

```vba
volume = volume + Excel.Application.ExecuteExcel4Macro("GET.DOCUMENT(50, """ & reviewWs.Name & """)")
```

### 使用目的

`GET.DOCUMENT(50, シート名)` は指定ワークシートの印刷時のページ数を返す XLM 関数。
レビュー記録一覧の「ページ数（volume）」列に書き込む値を取得するために使用している。

### 使用コンテキスト（前後のコード）

```vba
volume = 0
On Error Resume Next                          ' エラー時は0にフォールバック
Application.ScreenUpdating = False
For Each reviewWs In book.Worksheets
    If Not reviewWs.Name Like OUTPUT_SHEETNAME_PREFIX & "*" & OUTPUT_SHEETNAME_SUFFIX Then
        If Not reviewWs.Name Like OUTPUT_ERR_SHEETNAME Then
            reviewWs.Activate
            volume = volume + Excel.Application.ExecuteExcel4Macro( _
                "GET.DOCUMENT(50, """ & reviewWs.Name & """)")
        End If
    End If
Next reviewWs
book.Worksheets(1).Activate
Application.ScreenUpdating = True
If Err.Number <> 0 Then volume = 0           ' エラー時は0にリセット
On Error GoTo 0
```

**既存のエラーハンドリング**: `On Error Resume Next` + エラー番号チェックによるフォールバックが実装済み。
Excel 4 マクロが無効化された場合でも `volume = 0` として処理が続行する。

---

## 3. 代替手段の評価

### 候補1: `HPageBreaks` / `VPageBreaks` を使った計算

```vba
' 水平・垂直ページ区切りからページ数を計算
Dim hBreaks As Long, vBreaks As Long
hBreaks = ws.HPageBreaks.Count + 1
vBreaks = ws.VPageBreaks.Count + 1
pageCount = hBreaks * vBreaks
```

**評価**: **代替不可（信頼性不足）**
- `HPageBreaks` は印刷プレビューを実行するまで自動ページ区切りを含まない場合がある
- `Application.PrintOut` を事前に呼び出す必要があるが、実際に印刷してしまう
- シートを `Activate` しない場合は計算されないことがある
- セル結合・余白・用紙サイズなどの組み合わせで正確な値にならないケースがある
- 実測で `GET.DOCUMENT(50)` と値が異なる場合が確認されている

### 候補2: `WorksheetFunction` を使った計算

対応する `WorksheetFunction` は存在しない。

### 候補3: `Application.Evaluate` を使う方法

```vba
volume = Application.Evaluate("GET.DOCUMENT(50)")
```

**評価**: **代替不可（同等手段）**
- 内部的に XLM マクロを呼び出すため、制限されれば同様に動作しなくなる
- `ExecuteExcel4Macro` と実質的に同じリスクを持つ

### 候補4: COM オートメーションを使ったページ数取得

```vba
' 印刷設定を取得してページ数を計算する方法
Dim pages As Long
pages = ws.PageSetup.Pages.Count
```

**評価**: **代替候補（Excel バージョン依存）**
- `PageSetup.Pages` オブジェクトは Excel 2010 以降で利用可能
- ただし `Pages.Count` が常に正確なページ数を返すとは限らない（環境依存）
- ページ設定の更新タイミングによって古い値が返ることがある

### 候補5: 外部処理に委譲（非同期計算）

xlsm に依存せず Python（xlwings/openpyxl）側でページ数を計算する方法。

**評価**: **現在の設計スコープ外**
- ページ数取得は VBA 実行中（COM 操作中）に行われるため、Python 側への委譲は設計変更を伴う
- ページ数は参考値として記録されるため、変更コストに見合わない

---

## 4. 現状リスクの評価

| リスク項目 | 評価 | 根拠 |
|-----------|------|------|
| 即時の動作停止リスク | **低** | Microsoft は現時点でデフォルト無効化の対象外としている |
| 将来的な動作停止リスク | **中** | Microsoft はセキュリティポリシーとして段階的制限を進めている |
| 既存のフォールバック | **あり** | `On Error Resume Next` + `volume = 0` で処理続行 |
| 業務への影響 | **軽微** | ページ数は参考値（集計情報）であり、必須データではない |

### Microsoft の XLM マクロポリシー（2026年3月時点）

- 2022年: Internet から取得した Office ファイルの XLM マクロをデフォルトでブロック
- ローカルで作成・保存した xlsm ファイルに対しては現在も動作
- セキュリティ設定によっては組織ポリシーで無効化される可能性がある
- VBA から呼び出す `ExecuteExcel4Macro` は `Application.Calculation` の設定等に影響を受けない（XLM シート不要）

---

## 5. 結論と推奨対応

### 結論

**現時点では代替不可**。

`GET.DOCUMENT(50)` に相当する信頼性の高い純粋 VBA 代替手段が存在しない。
`HPageBreaks` ベースの計算は精度が低く、業務データの品質を損なうリスクがある。

### 推奨対応

**短期（現状維持 + 警告コメント追加）**:
- 既存の `On Error Resume Next` フォールバックにより、XLM が無効化されても `volume = 0` となるだけで処理は続行する
- コード内に警告コメントを追記することを推奨（別タスクで対応）

**中長期（監視）**:
- Microsoft の XLM ポリシー変更を定期的に確認する
- `PageSetup.Pages.Count` の信頼性が向上した場合（Excel バージョン確定後）は移行を検討する
- ページ数取得を廃止し「0または空白」とする仕様変更も選択肢の一つ

### 警告コメントの追記（推奨）

以下のコメントを Sheet1.cls の 1210 行目付近に追加することを推奨する:

```vba
' ページ数取得: Excel 4 マクロ(XLM) の GET.DOCUMENT(50) を使用
' 純粋VBAには信頼性の高い代替手段がないため、ExecuteExcel4Macro を使用している
' Microsoft によるXLMポリシー変更で動作しなくなった場合は volume = 0 になるのみで
' 処理自体は続行する（On Error Resume Next によるフォールバック実装済み）
volume = volume + Excel.Application.ExecuteExcel4Macro( _
    "GET.DOCUMENT(50, """ & reviewWs.Name & """)")
```

---

## 6. 参考情報

- [Microsoft Learn - ExecuteExcel4Macro Method](https://learn.microsoft.com/en-us/office/vba/api/excel.application.executeexcel4macro)
- [Microsoft - Blocking XLM Macros by Default](https://docs.microsoft.com/en-us/deployoffice/security/internet-macros-blocked)
- GET.DOCUMENT(50) の戻り値: 指定シートの印刷時のページ数（整数）。指定なしの場合はアクティブシート
