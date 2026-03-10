# ExecuteExcel4Macro 代替手段調査

**対象Finding**: M-04
**作成**: 2026-03-11
**作成者**: 足軽5号（subtask_280e_investigation）

---

## 1. 使用箇所の特定

### ファイル・行番号

| ファイル | 行 | 用途 |
|---------|-----|------|
| `vba_modules/Sheet1.cls` | 1212行 | ワークシートごとの印刷ページ数取得 |

### コード抜粋（Sheet1.cls 1205〜1220行）

```vba
'ページ数の取得
Dim reviewWs As Worksheet
volume = 0
On Error Resume Next
Application.ScreenUpdating = False
For Each reviewWs In book.Worksheets
    If Not reviewWs.Name Like OUTPUT_SHEETNAME_PREFIX & "*" & OUTPUT_SHEETNAME_SUFFIX Then
        If Not reviewWs.Name Like OUTPUT_ERR_SHEETNAME Then
            reviewWs.Activate
            volume = volume + Excel.Application.ExecuteExcel4Macro("GET.DOCUMENT(50, """ & reviewWs.Name & """)")
        End If
    End If
Next reviewWs
```

### 機能の説明

`GET.DOCUMENT(50, sheetName)` は Excel 4 マクロ（XLM）関数で、**指定シートの印刷ページ数**を返す。
doctool では「volume（ボリューム）」として各ワークシートのページ数を積算し、レビュー記録票に転記している。

---

## 2. 代替手段の評価

### 評価対象と結果

| 代替案 | 概要 | 適用可否 | 理由 |
|--------|------|---------|------|
| `HPageBreaks.Count × VPageBreaks.Count` | 改ページ数からページ数を近似 | **条件付き可能** | 精度は落ちるが XLM 非依存。後述参照 |
| `WorksheetFunction.*` | ページ数取得に相当する関数なし | **不可** | Excel のワークシート関数にページ数取得は存在しない |
| `Application.Worksheets().Evaluate()` | XLM 関数の実行に使用不可 | **不可** | `Evaluate` は数式評価用。XLM 呼び出しには使えない |
| `PrintOut` + 印刷プレビュー経由 | 一時印刷でページ数を取得 | **不可** | 実際に印刷処理が走り副作用がある |

### 詳細：HPageBreaks を用いた近似代替

```vba
Function GetPageCount(ws As Worksheet) As Long
    Dim hPages As Long, vPages As Long
    hPages = ws.HPageBreaks.Count + 1
    vPages = ws.VPageBreaks.Count + 1
    GetPageCount = hPages * vPages
End Function
```

**精度上の制限**:
- ページ設定（余白・用紙サイズ・縮小印刷）を自動考慮しない
- 手動改ページ（`.PageBreaks.Type = xlPageBreakManual`）との混在で誤差が出る可能性がある
- Excel 2007 以降で改ページのカウント動作に微差あり

**doctool への適合性**:
- `volume` は **「設計書のページ数（物量指標）」** として使用
- ±1 程度の誤差は業務上許容範囲内と考えられる
- ただし元実装と同じ計算結果を保証できないため、自動テストでの回帰確認が必須

---

## 3. 判断と対応方針

### 判断: **代替は慎重検討が必要（即時置換は非推奨）**

- VBA 標準では `GET.DOCUMENT(50)` に完全相当する関数が存在しない
- `HPageBreaks` 近似は動作するが、旧実装との出力差異が発生する可能性がある
- テストシナリオ（scenario11 がレビュー記録票のページ数確認を含む可能性）で回帰テストが必要

### 推奨対応

1. **短期（現状維持）**: 現コードに以下の警告コメントを追記する
2. **中長期（タスク別）**: HPageBreaks 版に差し替え、scenario11 の Gold Master を更新して回帰テストで確認

### コード追記内容（Sheet1.cls 1209行直前）

```vba
' 【警告】ExecuteExcel4Macro は Microsoft が段階的に無効化中（将来バージョンで動作不能になるリスクあり）
' GET.DOCUMENT(50) はVBAに直接相当する関数がないため現状維持。
' 代替候補: HPageBreaks.Count × VPageBreaks.Count（近似、回帰テスト要）
' 参照: docs/executexl4macro-investigation.md
```

---

## 4. 参考情報

- [Microsoft: Excel 4.0 macro functions reference](https://docs.microsoft.com/en-us/office/client-developer/excel/excel-recalculation)
- [Microsoft セキュリティアドバイザリ: Excel 4.0 マクロの無効化](https://support.microsoft.com/en-us/office/excel-4-0-xlm-macros)（管理者ポリシーによりデフォルト無効化可）
- olevba でも `ExecuteExcel4Macro` は `Suspicious` 判定される（malware 解析上の理由）

---

*調査完了。コードへのコメント追記は git 操作なしで実施済み（subtask_280e）。*
