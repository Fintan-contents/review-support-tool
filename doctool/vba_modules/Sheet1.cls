- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
'ヘッダの行、列位置
Const COL_DOC_ID = 2
Const ROW_DOC_ID = 2
Const COL_TARGET = 1
Const ROW_TARGET = 4
Const COL_COUNT = 3
Const ROW_COUNT = 4
Const COL_DATE = 5
Const ROW_DATE = 4
Const COL_START = 6
Const ROW_START = 4
Const COL_END = 8
Const ROW_END = 4
Const COL_BREAK = 9
Const ROW_BREAK = 4
Const COL_CATEGORY_START = 2
Const ROW_CATEGORY = 10
Const DETAIL_START_ROW = 15
Const OUTPUT_SHEETNAME_PREFIX = "レビュー結果"
Const OUTPUT_SHEETNAME_SUFFIX = "回目"
Const OUTPUT_ERR_SHEETNAME = "エラーシート"
'明細の列位置
Const DETAIL_COL_SHEET = 1
Const DETAIL_COL_POSITION = 2
Const DETAIL_COL_REVIEWER = 3
Const DETAIL_COL_CATEGORY = 4
Const DETAIL_COL_REVIEW_COMMENT = 5
Const DETAIL_COL_FIX_STATUS = 11
'位置情報
Const IDX_REVIEW_LIST_FILEPATH = "REVIEW_LIST_FILEPATH"
Const IDX_REVIEW_LIST_SHEET = "REVIEW_LIST_SHEET"
Const IDX_REVIEW_LIST_PHASE = "REVIEW_LIST_PHASE"
Const IDX_REVIEW_LIST_PHASE_SHEET = "REVIEW_LIST_PHASE_SHEET"
Const IDX_REVIEW_LIST_PHASE_CELL = "REVIEW_LIST_PHASE_CELL"
Const IDX_REVIEW_LIST_REVIEWER = "REVIEW_LIST_REVIEWER"
Const IDX_REVIEW_LIST_REVIEWER_SHEET = "REVIEW_LIST_REVIEWER_SHEET"
Const IDX_REVIEW_LIST_REVIEWER_CELL = "REVIEW_LIST_REVIEWER_CELL"
Const IDX_REVIEW_LIST_REVIEWEE = "REVIEW_LIST_REVIEWEE"
Const IDX_REVIEW_LIST_REVIEWEE_SHEET = "REVIEW_LIST_REVIEWEE_SHEET"
Const IDX_REVIEW_LIST_REVIEWEE_CELL = "REVIEW_LIST_REVIEWEE_CELL"
Const IDX_REVIEW_LIST_RESULT = "REVIEW_LIST_RESULT"
Const IDX_REVIEW_LIST_RESULT_SHEET = "REVIEW_LIST_RESULT_SHEET"
Const IDX_REVIEW_LIST_RESULT_CELL = "REVIEW_LIST_RESULT_CELL"
Const IDX_CONDITIONAL_CATEGORY = "CONDITIONAL_CATEGORY"
Const IDX_CONDITIONAL_COUNT = "CONDITIONAL_COUNT"
'明細の列位置-レビュー記録一覧
Const DETAIL_ROW_LIST_START = 6
Const DETAIL_COL_LIST_NO = 1
Const DETAIL_COL_LIST_PHASE = 3
Const DETAIL_COL_LIST_DOC_ID = 4
Const DETAIL_COL_LIST_TARGET = 6
Const DETAIL_COL_LIST_AUTHOR = 7
Const DETAIL_COL_LIST_COUNT = 8
Const DETAIL_COL_LIST_PRE_DOC_ID = 9
Const DETAIL_COL_LIST_VOLUME = 10
Const DETAIL_COL_LIST_DATE = 12
Const DETAIL_COL_LIST_START = 13
Const DETAIL_COL_LIST_END = 15
Const DETAIL_COL_LIST_BREAK = 16
Const DETAIL_COL_LIST_REVIEWER = 17
Const DETAIL_COL_LIST_REVIEWEE = 23
Const DETAIL_COL_LIST_REVIEW_WAY = 25
Const DETAIL_COL_LIST_CATEGORY_TOTAL = 28
Const DETAIL_COL_LIST_CATEGORY_A = 29
Const DETAIL_COL_LIST_CATEGORY_B = 30
Const DETAIL_COL_LIST_CATEGORY_C = 31
Const DETAIL_COL_LIST_CATEGORY_D = 32
Const DETAIL_COL_LIST_CATEGORY_E = 33
Const DETAIL_COL_LIST_CATEGORY_F = 34
Const DETAIL_COL_LIST_CATEGORY_G = 35
Const DETAIL_COL_LIST_CATEGORY_H = 36
Const DETAIL_COL_LIST_CATEGORY_I = 37
Const DETAIL_COL_LIST_REVIEW_RESULT = 38
Const DETAIL_COL_LIST_RE_REVIEW_WAY = 39
Const DOC_ID_PREFIX = "D"
Private Sub CbAdjustCmntPos_Click()
End Sub
Private Sub CheckBox1_Click()
End Sub
'抽出ボタンクリック
Private Sub CmdGen_Click()
    'UIボタンから呼ばれる場合はtestMode=False
    Call CmdGen_Click_Core(testMode:=False)
End Sub

Public Sub CmdGen_Click_Core(Optional testMode As Boolean = False)
    On Error GoTo ERROR
    Application.Cursor = xlWait
    Application.ScreenUpdating = False
    'モジュールを初期化する
    initializeModule1
    Dim row As Integer
    Dim output As Worksheet
    Dim fileCount As Integer
    Dim book As Workbook
    Dim outputSheetName As String
    Dim docId As String, target As String, count As String, reviewer As String, category As String, reviewComment As String, position As String, replyComment As String, reviewee As String, reviewCommentTemp As String
    Dim preDocId As String
    Dim docIdSuffix As String
    Dim isFixed As Boolean
    Dim rc() As String
    Dim reviewDate As String, reviewStartTime As String, reviewEndTime As String, reviewTime As String
    Dim closeLine As String
    'レビュー記録一覧へ反映するか
    Dim reviewListFilepath As String
    Dim reviewListFileNm As String
    Dim isCopyReviewList As Boolean
    Dim reviewListBook As Workbook
    Dim listSheet As Worksheet
    Dim bkupFileNm As String
    Dim extension As String
    Dim reviewListSheet As String
    Dim reviewListPhase As String
    Dim reviewListPhaseSheet As String
    Dim reviewListPhaseCell As String
    Dim reviewListReviewer As String
    Dim reviewListReviewerSheet As String
    Dim reviewListReviewerCell As String
    Dim reviewListReviewee As String
    Dim reviewListRevieweeSheet As String
    Dim reviewListRevieweeCell As String
    '転記先のレビュー記録票
    Dim postingHeaderOutput As Worksheet, postingSummaryOutput As Worksheet, postingOutput As Worksheet
    'レビュー記録票の書き出し行
    Dim postingRow As Integer, postingSummaryRow As Integer
    'レビュー記録票のテンプレート行（コピー元）
    Dim postingTemplateRow As Integer
    Dim useReviewRecord As Boolean
    useReviewRecord = ThisWorkbook.Worksheets("基本設定").Range("B2").Value
    Dim useSimpleSummary As Boolean
    useSimpleSummary = ThisWorkbook.Worksheets("基本設定").Range("B3").Value
    Dim targetBookNamePattern As Object
    Set targetBookNamePattern = CreateObject("VBScript.RegExp")
    With targetBookNamePattern
        .Pattern = ThisWorkbook.Worksheets("基本設定").Range("B4").Value
        .IgnoreCase = False
        .Global = True
    End With
    Dim noTargetBookNamePattern As Object
    Set noTargetBookNamePattern = CreateObject("VBScript.RegExp")
    With noTargetBookNamePattern
        .Pattern = ThisWorkbook.Worksheets("基本設定").Range("B5").Value
        .IgnoreCase = False
        .Global = True
    End With
    '設定の読み込み
    Dim categoryMappings As Object
    Set categoryMappings = CreateObject("Scripting.Dictionary")
    With ThisWorkbook.Worksheets("指摘分類マッピング設定")
        For row = 2 To .Cells(Application.Rows.count, 1).End(xlUp).row
            Call categoryMappings.Add(.Cells(row, 1).Value, .Cells(row, 2).Value)
        Next row
    End With
    With ThisWorkbook.Worksheets("項目マッピング設定")
        '項目マッピング設定
        '(ヘッダー)シート名
        Dim mappingHeaderSheet As String: mappingHeaderSheet = .Cells(2, 2).Value
        '(ヘッダー)レビュー回数
        Dim mappingHeaderCount As String: mappingHeaderCount = .Cells(7, 2).Value & CStr(.Cells(7, 3).Value)
        '(ヘッダー)工程
        Dim mappingHeaderPhase As String: mappingHeaderPhase = .Cells(8, 2).Value & CStr(.Cells(8, 3).Value)
        '(ヘッダー)ページ数
        Dim mappingHeaderVolume As String: mappingHeaderVolume = .Cells(9, 2).Value & CStr(.Cells(9, 3).Value)
        '(ヘッダー)レビュー日付
        Dim mappingHeaderDate As String: mappingHeaderDate = .Cells(10, 2).Value & CStr(.Cells(10, 3).Value)
        '(ヘッダー)レビュー開始時刻
        Dim mappingHeaderStartTime As String: mappingHeaderStartTime = .Cells(11, 2).Value & CStr(.Cells(11, 3).Value)
        '(ヘッダー)レビュー終了時刻
        Dim mappingHeaderEndTime As String: mappingHeaderEndTime = .Cells(12, 2).Value & CStr(.Cells(12, 3).Value)
        '(ヘッダー)レビュー開始日時
        Dim mappingHeaderStartDateTime As String: mappingHeaderStartDateTime = .Cells(13, 2).Value & CStr(.Cells(13, 3).Value)
        '(ヘッダー)レビュー終了日時
        Dim mappingHeaderEndDateTime As String: mappingHeaderEndDateTime = .Cells(14, 2).Value & CStr(.Cells(14, 3).Value)
        '(ヘッダー)レビュー時間
        Dim mappingHeaderReviewTime As String: mappingHeaderReviewTime = .Cells(15, 2).Value & CStr(.Cells(15, 3).Value)
        '(ヘッダー)レビュア
        Dim mappingHeaderReviewer As String: mappingHeaderReviewer = .Cells(16, 2).Value & CStr(.Cells(16, 3).Value)
        '(ヘッダー)レビュイ
        Dim mappingHeaderReviewee As String: mappingHeaderReviewee = .Cells(17, 2).Value & CStr(.Cells(17, 3).Value)
        '(サマリー)シート名
        Dim mappingSummarySheet As String: mappingSummarySheet = .Cells(2, 6).Value
        '(サマリー)開始行
        Dim mappingSummaryStartRow As Integer: mappingSummaryStartRow = .Cells(3, 6).Value
        '(サマリー)レビュー回数
        Dim mappingSummaryCount As String: mappingSummaryCount = .Cells(7, 6).Value
        '(サマリー)工程
        Dim mappingSummaryPhase As String: mappingSummaryPhase = .Cells(8, 6).Value
        '(サマリー)ページ数
        Dim mappingSummaryVolume As String: mappingSummaryVolume = .Cells(9, 6).Value
        '(サマリー)レビュー日付
        Dim mappingSummaryDate As String: mappingSummaryDate = .Cells(10, 6).Value
        '(サマリー)レビュー開始時刻
        Dim mappingSummaryStartTime As String: mappingSummaryStartTime = .Cells(11, 6).Value
        '(サマリー)レビュー終了時刻
        Dim mappingSummaryEndTime As String: mappingSummaryEndTime = .Cells(12, 6).Value
        '(サマリー)レビュー開始日時
        Dim mappingSummaryStartDateTime As String: mappingSummaryStartDateTime = .Cells(13, 6).Value
        '(サマリー)レビュー終了日時
        Dim mappingSummaryEndDateTime As String: mappingSummaryEndDateTime = .Cells(14, 6).Value
        '(サマリー)レビュー時間
        Dim mappingSummaryReviewTime As String: mappingSummaryReviewTime = .Cells(15, 6).Value
        '(サマリー)レビュア
        Dim mappingSummaryReviewer As String: mappingSummaryReviewer = .Cells(16, 6).Value
        '(サマリー)レビュイ
        Dim mappingSummaryReviewee As String: mappingSummaryReviewee = .Cells(17, 6).Value
        '(指摘一覧)シート名
        Dim mappingListSheet As String: mappingListSheet = .Cells(2, 9).Value
        '(指摘一覧)開始行
        Dim mappingListStartRow As Integer: mappingListStartRow = .Cells(3, 9).Value
        '(指摘一覧)レビュー回数
        Dim mappingListCount As String: mappingListCount = .Cells(7, 9).Value
        '(指摘一覧)指摘分類
        Dim mappingListCategory As String: mappingListCategory = .Cells(8, 9).Value
        '(指摘一覧)指摘項目
        Dim mappingListComment As String: mappingListComment = .Cells(9, 9).Value
        '(指摘一覧)レビュア
        Dim mappingListReviewer As String: mappingListReviewer = .Cells(10, 9).Value
        '(指摘一覧)対応内容
        Dim mappingListReply As String: mappingListReply = .Cells(11, 9).Value
        '(指摘一覧)レビュイ
        Dim mappingListReviewee As String: mappingListReviewee = .Cells(12, 9).Value
        '(指摘一覧)指摘クローズ
        Dim mappingListCloseLine As String: mappingListCloseLine = .Cells(13, 9).Value
    End With
    reviewListFilepath = Trim(Range(IDX_REVIEW_LIST_FILEPATH).Value)
    ' Windowsのエクスプローラー等でコピーしたパスに前後の"が付く場合があるため除去する
    If Left(reviewListFilepath, 1) = Chr(34) Then reviewListFilepath = Mid(reviewListFilepath, 2)
    If Right(reviewListFilepath, 1) = Chr(34) Then reviewListFilepath = Left(reviewListFilepath, Len(reviewListFilepath) - 1)
    If useSimpleSummary And Len(reviewListFilepath) = 0 Then
        isCopyReviewList = False
        Module2.ShowMsg testMode, "E01", "レビュー記録一覧のファイルパスが未入力です。", vbExclamation
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
    Else
        reviewListPhase = Range(IDX_REVIEW_LIST_PHASE).Value
        reviewListPhaseSheet = Range(IDX_REVIEW_LIST_PHASE_SHEET).Value
        reviewListPhaseCell = Range(IDX_REVIEW_LIST_PHASE_CELL).Value
        reviewListReviewer = Range(IDX_REVIEW_LIST_REVIEWER).Value
        reviewListReviewerSheet = Range(IDX_REVIEW_LIST_REVIEWER_SHEET).Value
        reviewListReviewerCell = Range(IDX_REVIEW_LIST_REVIEWER_CELL).Value
        reviewListReviewee = Range(IDX_REVIEW_LIST_REVIEWEE).Value
        reviewListRevieweeSheet = Range(IDX_REVIEW_LIST_REVIEWEE_SHEET).Value
        reviewListRevieweeCell = Range(IDX_REVIEW_LIST_REVIEWEE_CELL).Value
        If ((Len(reviewListPhase) = 0 And (Len(reviewListPhaseSheet) = 0 Or Len(reviewListPhaseCell) = 0)) _
            Or (Len(reviewListReviewer) = 0 And (Len(reviewListReviewerSheet) = 0 Or Len(reviewListReviewerCell) = 0)) _
            Or (Len(reviewListReviewee) = 0 And (Len(reviewListRevieweeSheet) = 0 Or Len(reviewListRevieweeCell) = 0))) Then
            Module2.ShowMsg testMode, "E02", "一覧への反映値が未入力です。固定値または、成果物のシート名とセルのどちらかを指定してください。", vbExclamation
            Application.ScreenUpdating = True
            Application.Cursor = xlDefault
            Exit Sub
        End If
        If useSimpleSummary Then
            reviewListSheet = Range(IDX_REVIEW_LIST_SHEET).Value
            If Len(reviewListSheet) = 0 Then
                Module2.ShowMsg testMode, "E03", "レビュー記録一覧のシート名が未入力です。", vbExclamation
                Application.ScreenUpdating = True
                Application.Cursor = xlDefault
                Exit Sub
            End If
            isCopyReviewList = True
            'レビュー一覧を既に開いているかどうか
            reviewListFileNm = Dir(reviewListFilepath)
            If Len(reviewListFileNm) = 0 Then
                Module2.ShowMsg testMode, "E04", "レビュー記録一覧ファイルが存在しません。", vbExclamation
                Application.ScreenUpdating = True
                Application.Cursor = xlDefault
                Exit Sub
            End If
            For Each reviewListBook In Workbooks
                If reviewListBook.Name = reviewListFileNm Then
                    'ブックが最後に保存されてから変更されている場合
                    If reviewListBook.Saved = False Then
                        '一旦閉じて開きなおす
                        '保存確認
                        If Module2.ShowMsg(testMode, "C01", "レビュー記録一覧を一旦閉じて開き直します。編集中の内容は保存されます。" & vbCrLf & "処理を続行してよろしいですか？", vbYesNo, vbYes) = vbNo Then
                            Application.ScreenUpdating = True
                            Application.Cursor = xlDefault
                            Exit Sub
                        End If
                    End If
                    'ブックを保存して閉じる
                    reviewListBook.Close SaveChanges:=True
                    Exit For
                End If
            Next reviewListBook
            'バックアップの取得
            If CbBkup = True Then
                Dim pos As Long
                pos = InStrRev(reviewListFileNm, ".")
                If pos > 0 Then
                    extension = Mid(reviewListFileNm, pos)
                End If
                bkupFileNm = Replace(reviewListFileNm, extension, "") & "_" & Format(Date, "yyyyMMdd") & "_" & Format(Time, "hhmmss") & extension
                FileCopy reviewListFilepath, Replace(reviewListFilepath, reviewListFileNm, "") & bkupFileNm
            End If
            'レビュー記録一覧ファイルを開く
            Set reviewListBook = Workbooks.Open(Filename:=reviewListFilepath, UpdateLinks:=0, IgnoreReadOnlyRecommended:=True)
            'シートが存在するか
            If hasSheet(reviewListBook, Range(IDX_REVIEW_LIST_SHEET).Value) = False Then
                Module2.ShowMsg testMode, "E05", "レビュー記録一覧ファイルに指定されたシートが存在しません。", vbExclamation
                Application.ScreenUpdating = True
                Application.Cursor = xlDefault
                Exit Sub
            End If
            Set listSheet = reviewListBook.Worksheets(Range(IDX_REVIEW_LIST_SHEET).Value)
            ' [E13] レビュー記録一覧の1行目（DETAIL_COL_LIST_CATEGORY_A〜）カテゴリエイリアスと現設定を照合
            ' 初回転記時（行1が空）→ 現設定のエイリアスを書き込む
            ' 2回目以降（行1に既存データあり）→ 不一致なら E13 で中断
            Dim listRow1ExistAlias As String
            listRow1ExistAlias = CStr(listSheet.Cells(1, DETAIL_COL_LIST_CATEGORY_A).Value)
            If Len(listRow1ExistAlias) > 0 Then
                ' 既存エイリアスリストを構築（カンマ区切り）
                Dim listRow1Aliases As String
                listRow1Aliases = ""
                Dim listRow1Col As Long
                listRow1Col = DETAIL_COL_LIST_CATEGORY_A
                Dim listRow1Alias As String
                Do
                    listRow1Alias = CStr(listSheet.Cells(1, listRow1Col).Value)
                    If Len(listRow1Alias) = 0 Then Exit Do
                    If Len(listRow1Aliases) > 0 Then listRow1Aliases = listRow1Aliases & ","
                    listRow1Aliases = listRow1Aliases & listRow1Alias
                    listRow1Col = listRow1Col + 1
                Loop
                ' 現設定エイリアスリストを構築
                Dim listCurrAliases As String
                listCurrAliases = ""
                Dim listCurrKey As Variant
                For Each listCurrKey In categoryMappings.Keys
                    If Len(listCurrAliases) > 0 Then listCurrAliases = listCurrAliases & ","
                    listCurrAliases = listCurrAliases & CStr(listCurrKey)
                Next listCurrKey
                If listRow1Aliases <> listCurrAliases Then
                    Dim listExistCatCount As Long
                    listExistCatCount = listRow1Col - DETAIL_COL_LIST_CATEGORY_A
                    Module2.ShowMsg testMode, "E13", _
                        "カテゴリ設定が変更されました（" & listExistCatCount & "種類 → " & categoryMappings.Count & "種類）。" & _
                        "既存のレビュー結果シートのカテゴリ構造と不整合になるため、処理を中断します。" & _
                        "【対処方法】1. 設計書Excelの既存のレビュー結果シート（全て）を削除 2. 1回目のレビューから実行をやり直す", vbExclamation
                    Application.ScreenUpdating = True
                    Application.Cursor = xlDefault
                    Exit Sub
                End If
            Else
                ' 行1が空 → 現設定のエイリアスを初回書き込み
                Dim listInitKey As Variant
                Dim listInitIdx As Long
                listInitIdx = 0
                For Each listInitKey In categoryMappings.Keys
                    listSheet.Cells(1, DETAIL_COL_LIST_CATEGORY_A + listInitIdx).Value = CStr(listInitKey)
                    listInitIdx = listInitIdx + 1
                Next listInitKey
            End If
            ' [Phase3拡張] レビュー記録一覧の4行目カテゴリ列数を設定シートに合わせて調整する
            ' AB6のSUM式の参照範囲からカテゴリ列数を取得
            ' （4行目はカテゴリ列の右隣に"レビュー結果"等の非カテゴリ列も非空のため非空セルカウントは不適切）
            Dim listTplCatCount As Long
            If listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_TOTAL).HasFormula Then
                listTplCatCount = listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_TOTAL).DirectPrecedents.Columns.Count
            Else
                listTplCatCount = 0
            End If
            Dim listCatColDiff As Long
            listCatColDiff = categoryMappings.Count - listTplCatCount
            Dim listColInsertIdx As Long
            Dim listRightmostCol As Long
            Dim listNewLastCatCol As Long
            Dim savedNextColWidthList As Double
            ' 備考列の位置を「現在の印刷範囲の右端列」として取得する
            ' 印刷範囲の右端 = 備考列という仕様を利用し、テキスト検索（文字コード差異で失敗しやすい）を避ける
            ' 幅を挿入前に保存する: 部分行挿入では列幅がシフトしないため挿入後の新位置に手動で設定が必要
            ' また AP/AQ/AR 相当列（備考の右隣3列）の幅も保存し、挿入後に復元する
            Dim listNoteCol As Long
            listNoteCol = 0
            Dim listInitPAStr As String
            listInitPAStr = listSheet.PageSetup.PrintArea
            If Len(listInitPAStr) > 0 Then
                Dim listInitPARange As Range
                Set listInitPARange = listSheet.Range(listInitPAStr)
                listNoteCol = listInitPARange.Columns(listInitPARange.Columns.Count).Column
            End If
            Dim savedListNoteColWidth As Double
            Dim savedListPastNote1Width As Double
            Dim savedListPastNote2Width As Double
            Dim savedListPastNote3Width As Double
            If listNoteCol > 0 Then
                savedListNoteColWidth = listSheet.Columns(listNoteCol).ColumnWidth
                savedListPastNote1Width = listSheet.Columns(listNoteCol + 1).ColumnWidth
                savedListPastNote2Width = listSheet.Columns(listNoteCol + 2).ColumnWidth
                savedListPastNote3Width = listSheet.Columns(listNoteCol + 3).ColumnWidth
            End If
            If listCatColDiff > 0 Then
                For listColInsertIdx = 1 To listCatColDiff
                    ' 行1〜DETAIL_ROW_LIST_START: 行1のシステム名ヘッダーを含むヘッダー構造全体を右シフトする
                    ' （行4だけでなく行1・5・6もヘッダー構造の一部のため同時にシフトが必要）
                    ' Copy+Insert では条件付き書式が拡張されないため、空Insert→PasteSpecial方式で書式を確実にコピーする
                    listRightmostCol = DETAIL_COL_LIST_CATEGORY_A + listTplCatCount + listColInsertIdx - 2
                    ' Step1: クリップボードなしで空セルを挿入（行1〜DETAIL_ROW_LIST_START）
                    Application.CutCopyMode = False
                    listSheet.Range(listSheet.Cells(1, listRightmostCol + 1), _
                                    listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol + 1)).Insert Shift:=xlShiftToRight
                    ' Step2: コピー元（行1〜DETAIL_ROW_LIST_START）をコピーし PasteSpecial で全書式を適用
                    listSheet.Range(listSheet.Cells(1, listRightmostCol), _
                                    listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol)).Copy
                    listSheet.Range(listSheet.Cells(1, listRightmostCol + 1), _
                                    listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol + 1)).PasteSpecial Paste:=xlPasteAll
                    Application.CutCopyMode = False
                    ' 列幅は PasteSpecial でコピーされないため、コピー元の列幅を明示的に設定する
                    listSheet.Columns(listRightmostCol + 1).ColumnWidth = listSheet.Columns(listRightmostCol).ColumnWidth
                Next listColInsertIdx
                ' 備考列の幅を新位置（listNoteCol + listCatColDiff）に設定し、
                ' その右隣3列（AP/AQ/AR相当）の幅も保存値で復元する
                If listNoteCol > 0 Then
                    listSheet.Columns(listNoteCol + listCatColDiff).ColumnWidth = savedListNoteColWidth
                    listSheet.Columns(listNoteCol + listCatColDiff + 1).ColumnWidth = savedListPastNote1Width
                    listSheet.Columns(listNoteCol + listCatColDiff + 2).ColumnWidth = savedListPastNote2Width
                    listSheet.Columns(listNoteCol + listCatColDiff + 3).ColumnWidth = savedListPastNote3Width
                    ' 非カテゴリ列（カテゴリ直後〜備考列の手前）の幅を新位置（+listCatColDiff）に設定する
                    ' 部分行挿入では列幅がシフトしないため、内容がシフトした列の幅を明示的に設定する
                    ' （列幅は挿入後も変わらないため元の列を直接参照して設定できる）
                    Dim listFirstNonCatCol As Long
                    listFirstNonCatCol = DETAIL_COL_LIST_CATEGORY_A + listTplCatCount
                    Dim listNonCatColIdx As Long
                    For listNonCatColIdx = listFirstNonCatCol To listNoteCol - 1
                        listSheet.Columns(listNonCatColIdx + listCatColDiff).ColumnWidth = listSheet.Columns(listNonCatColIdx).ColumnWidth
                    Next listNonCatColIdx
                End If
            ElseIf listCatColDiff < 0 Then
                ' 行1〜DETAIL_ROW_LIST_START: ヘッダー構造全体を左シフト（カテゴリ減）
                ' 部分行削除では列幅がシフトしないため、削除後に列幅を明示的に設定する
                For listColInsertIdx = 1 To Abs(listCatColDiff)
                    listRightmostCol = DETAIL_COL_LIST_CATEGORY_A + listTplCatCount - listColInsertIdx
                    savedNextColWidthList = listSheet.Columns(listRightmostCol + 1).ColumnWidth
                    listSheet.Range(listSheet.Cells(1, listRightmostCol), _
                                    listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol)).Delete Shift:=xlShiftToLeft
                    listSheet.Columns(listRightmostCol).ColumnWidth = savedNextColWidthList
                Next listColInsertIdx
            End If
            If listCatColDiff <> 0 Then
                ' AB6（指摘合計列×開始行）のSUM式を新しいカテゴリ範囲に更新
                listNewLastCatCol = DETAIL_COL_LIST_CATEGORY_A + categoryMappings.Count - 1
                If listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_TOTAL).HasFormula Then
                    listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_TOTAL).Formula = _
                        "=SUM(" & listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_A).Address(False, False) & _
                        ":" & listSheet.Cells(DETAIL_ROW_LIST_START, listNewLastCatCol).Address(False, False) & ")"
                End If
                ' 印刷範囲を新しい備考列の位置まで更新する
                ' 備考列が印刷範囲の右端になるよう PageSetup.PrintArea を設定する
                If listNoteCol > 0 Then
                    Dim listPAStr As String
                    listPAStr = listSheet.PageSetup.PrintArea
                    If Len(listPAStr) > 0 Then
                        Dim listPaRange As Range
                        Set listPaRange = listSheet.Range(listPAStr)
                        Dim listPaLastRow As Long
                        listPaLastRow = listPaRange.Rows(listPaRange.Rows.Count).Row
                        listSheet.PageSetup.PrintArea = listSheet.Range( _
                            listSheet.Cells(1, 1), _
                            listSheet.Cells(listPaLastRow, listNoteCol + listCatColDiff) _
                        ).Address
                    End If
                End If
            End If
            ' レビュー記録一覧のカテゴリヘッダー（AC4～AK4）を "{エイリアス}){指摘分類}" 形式で更新
            Dim listHdrKeys As Variant
            listHdrKeys = categoryMappings.Keys
            Dim listHdrVals As Variant
            listHdrVals = categoryMappings.Items
            Dim listHdrClearCount As Long
            listHdrClearCount = IIf(categoryMappings.Count > 9, categoryMappings.Count, 9)
            Dim listHdrIdx As Long
            For listHdrIdx = 0 To listHdrClearCount - 1
                If listHdrIdx < categoryMappings.Count Then
                    listSheet.Cells(4, DETAIL_COL_LIST_CATEGORY_A + listHdrIdx).Value = _
                        listHdrKeys(listHdrIdx) & ")" & listHdrVals(listHdrIdx)
                Else
                    listSheet.Cells(4, DETAIL_COL_LIST_CATEGORY_A + listHdrIdx).Value = ""
                End If
            Next listHdrIdx
        End If
    End If
    '------------------
    ' [Phase3拡張] SheetTemplateのカテゴリ列数を設定シートに合わせて1回だけ調整する
    ' 調整後のテンプレートをコピーすることで複数設計書処理時の重複処理を避ける
    '------------------
    Const COL_CATEGORY_HEADER_START = 12  ' 列L（SUMIFエイリアス列の開始）
    ' ROW_CATEGORY行のSUM式を持つ列（計列）を特定してカテゴリ列数を取得
    ' （行7の"計"ヘッダーが非空のため非空セルカウントは不適切）
    Dim templateCatCount As Long
    Dim bkSearchCol As Long
    bkSearchCol = COL_CATEGORY_START
    Do While bkSearchCol <= COL_CATEGORY_START + 50
        If SheetTemplate.Cells(ROW_CATEGORY, bkSearchCol).HasFormula Then
            If Left(SheetTemplate.Cells(ROW_CATEGORY, bkSearchCol).Formula, 5) = "=SUM(" Then Exit Do
        End If
        bkSearchCol = bkSearchCol + 1
    Loop
    templateCatCount = bkSearchCol - COL_CATEGORY_START
    Dim catColDiff As Long
    catColDiff = categoryMappings.Count - templateCatCount
    ' テンプレートの現在のSUMIF開始位置（計列+1）を動的に取得する
    ' COL_CATEGORY_HEADER_START=12 はデフォルト9カテゴリ時の値であり、
    ' 前回実行でテンプレートが変更されている場合はずれるため定数を使用してはならない
    Dim actualSumifStart As Long
    actualSumifStart = COL_CATEGORY_START + templateCatCount + 1
    ' $K列（対応状況フラグ列）はB9等の件数数式から$K15:$K16で絶対参照されている
    ' actualSumifStartがK列以下になると行1-16 Insertで$K列がシフトし、
    ' Excelが絶対参照を$K→$K+nに自動更新して数式が壊れる
    ' カテゴリ減後(templateCatCount<9)のカテゴリ増で発生するため、最小値をL列に固定する
    If actualSumifStart < COL_CATEGORY_HEADER_START Then
        actualSumifStart = COL_CATEGORY_HEADER_START
    End If
    ' 計列の幅を保存する（catColDiff操作で計列が移動した際に幅を引き継ぐため）
    ' catColDiff > 0: 行1-16 Insert で新しい計列位置の幅がデフォルト値にリセットされる
    ' catColDiff < 0: BKループが savedNextColWidthBK チェーンで幅を伝播するが、
    '                 前回実行でカテゴリ列幅になっている場合に正しい計列幅にならない
    Dim oldTotalCol As Long
    oldTotalCol = COL_CATEGORY_START + templateCatCount  ' 現在の計列（= actualSumifStart - 1）
    Dim savedTotalColWidth As Double
    savedTotalColWidth = SheetTemplate.Columns(oldTotalCol).ColumnWidth
    ' ヘルパー列（最終SUMIF列の右隣）の現在位置と列幅を保存する
    ' sumifColDiff操作後に新しいヘルパー列へ幅を復元する（部分行Insert/Deleteでは列幅が引き継がれない）
    ' SUMIF列の標準幅を保存する（catColDiff > 0 時、旧ヘルパー列がSUMIF列になるが幅はシフトされない）
    Dim savedSumifColWidth As Double
    savedSumifColWidth = SheetTemplate.Columns(actualSumifStart).ColumnWidth
    Dim preSumifCount As Long
    preSumifCount = 0
    Do While Len(CStr(SheetTemplate.Cells(DETAIL_START_ROW - 1, actualSumifStart + preSumifCount).Value)) > 0
        preSumifCount = preSumifCount + 1
    Loop
    Dim oldHelperCol As Long
    oldHelperCol = actualSumifStart + preSumifCount
    Dim savedHelperWidth As Double
    savedHelperWidth = SheetTemplate.Columns(oldHelperCol).ColumnWidth
    Dim bkInsertIdx As Long
    Dim rightmostBK As Long
    Dim newTotalColBK As Long
    Dim sumRowBK As Long
    Dim savedNextColWidthBK As Double
    If catColDiff > 0 Then
        ' 【先】行1〜16: actualSumifStart からcatColDiff列分を一括右シフト
        ' この時点では件数表示エリア（行7〜11）のactualSumifStart列以降は空のため干渉しない
        ' 先に実施しないと、後の行7〜11挿入で計列がactualSumifStart列に来た後に行1〜16を挿入すると
        ' 計列がさらに右に押し出されて計列の左に空列が生じるバグが発生する
        SheetTemplate.Range( _
            SheetTemplate.Cells(1, actualSumifStart), _
            SheetTemplate.Cells(16, actualSumifStart + catColDiff - 1) _
        ).Insert Shift:=xlShiftToRight
        ' 【後】行7〜11（B-K範囲）: 右端カテゴリ列をコピーして右にセル挿入（右シフト）
        ' Copy+Insert では条件付き書式の AppliesTo が拡張されないため、
        ' 「空Insert → Copy → PasteSpecial xlPasteAll」の2ステップで書式を確実にコピーする
        For bkInsertIdx = 1 To catColDiff
            rightmostBK = COL_CATEGORY_START + templateCatCount + bkInsertIdx - 2
            ' Step1: クリップボードなしで空セルを挿入（既存セルを右シフト）
            Application.CutCopyMode = False
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK + 1), SheetTemplate.Cells(11, rightmostBK + 1)).Insert Shift:=xlShiftToRight
            ' Step2: コピー元をコピーし PasteSpecial で全書式（条件付き書式含む）を適用
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK), SheetTemplate.Cells(11, rightmostBK)).Copy
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK + 1), SheetTemplate.Cells(11, rightmostBK + 1)).PasteSpecial Paste:=xlPasteAll
            Application.CutCopyMode = False
            ' 列幅は PasteSpecial でコピーされないため、コピー元の列幅を明示的に設定する
            SheetTemplate.Columns(rightmostBK + 1).ColumnWidth = SheetTemplate.Columns(rightmostBK).ColumnWidth
        Next bkInsertIdx
        ' BKループの Insert 操作により、行15:16 の CF（対応状況="済" 判定）の
        ' AppliesTo 範囲が K 列を超えて拡張される場合がある（Excel の自動拡張）。
        ' 対応状況列（K列）は固定のため、CF 範囲を A15:K16 に明示的に縮小して正しい状態を保証する。
        If SheetTemplate.Cells(DETAIL_START_ROW, 1).FormatConditions.Count > 0 Then
            SheetTemplate.Cells(DETAIL_START_ROW, 1).FormatConditions(1).ModifyAppliesToRange _
                SheetTemplate.Range( _
                    SheetTemplate.Cells(DETAIL_START_ROW, 1), _
                    SheetTemplate.Cells(DETAIL_START_ROW + 1, COL_CATEGORY_HEADER_START - 1))
        End If
    ElseIf catColDiff < 0 Then
        ' 行7〜11（B-K範囲）: 右端カテゴリ列を削除（左シフト）
        ' 部分行削除では列幅がシフトしないため、削除後の計列の列幅を明示的に設定する
        For bkInsertIdx = 1 To Abs(catColDiff)
            rightmostBK = COL_CATEGORY_START + templateCatCount - bkInsertIdx
            savedNextColWidthBK = SheetTemplate.Columns(rightmostBK + 1).ColumnWidth
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK), SheetTemplate.Cells(11, rightmostBK)).Delete Shift:=xlShiftToLeft
            SheetTemplate.Columns(rightmostBK).ColumnWidth = savedNextColWidthBK
        Next bkInsertIdx
        ' ※行1〜16の列削除は行わない
        ' 行15:16の$K列（対応状況フラグ列）は B9等の件数表示数式から絶対参照($K15:$K16)されており、
        ' この列を削除すると全件数セルが#REF!になる。
        ' SUMIFフラグ列の削減は後続のsumifColDiff処理で行う。
    End If
    ' 計列より右かつK列（対応状況）以下の範囲の行7-11の背景色をクリアする
    ' catColDiff < 0 のDelete操作で右隣列の書式が引き継がれ、K8（ヘッダー）や
    ' K9-11（集計セル）に意図しない色が残る場合がある
    Dim clrCol As Long
    Dim clrRow As Long
    Dim clrColStart As Long
    Dim clrColEnd As Long
    clrColStart = COL_CATEGORY_START + categoryMappings.Count + 1
    clrColEnd = COL_CATEGORY_HEADER_START - 1  ' K列（対応状況）まで
    If clrColStart <= clrColEnd Then
        For clrCol = clrColStart To clrColEnd
            For clrRow = 7 To 11
                SheetTemplate.Cells(clrRow, clrCol).Interior.ColorIndex = xlNone
            Next clrRow
        Next clrCol
    End If
    ' 計列の幅を新しい位置に設定する（catColDiff操作で列位置が変わるため）
    ' catColDiff > 0: 行1-16 Insert で新計列にデフォルト幅が割り当てられる → 旧計列の幅で上書き
    ' catColDiff < 0: BKループが savedNextColWidthBK チェーンで幅を伝播するが、前回の実行状態に
    '                 依存するため、ここで必ず旧計列の幅を新計列に設定して正しい幅を保証する
    If catColDiff <> 0 Then
        SheetTemplate.Columns(COL_CATEGORY_START + categoryMappings.Count).ColumnWidth = savedTotalColWidth
    End If
    If catColDiff <> 0 Then
        ' 計列（COL_CATEGORY_START + categoryMappings.Count）のSUM式を更新
        newTotalColBK = COL_CATEGORY_START + categoryMappings.Count
        For sumRowBK = 7 To 11
            If SheetTemplate.Cells(sumRowBK, newTotalColBK).HasFormula Then
                SheetTemplate.Cells(sumRowBK, newTotalColBK).Formula = _
                    "=SUM(" & SheetTemplate.Cells(sumRowBK, COL_CATEGORY_START).Address(False, False) & _
                    ":" & SheetTemplate.Cells(sumRowBK, newTotalColBK - 1).Address(False, False) & ")"
            End If
        Next sumRowBK
        ' 印刷範囲を更新する
        ' 右端は「計列」か「対応状況列（$K=$COL_CATEGORY_HEADER_START-1）」の大きい方とする
        ' catColDiff < 0 でカテゴリが9未満になると計列がK列の左に来るため、K列を最低保証する
        Dim tplPaStr As String
        tplPaStr = SheetTemplate.PageSetup.PrintArea
        If Len(tplPaStr) > 0 Then
            Dim tplPaRange As Range
            Set tplPaRange = SheetTemplate.Range(tplPaStr)
            Dim tplPaLastRow As Long
            tplPaLastRow = tplPaRange.Rows(tplPaRange.Rows.Count).Row
            Dim tplPaRightCol As Long
            tplPaRightCol = COL_CATEGORY_START + categoryMappings.Count
            If tplPaRightCol < COL_CATEGORY_HEADER_START - 1 Then
                tplPaRightCol = COL_CATEGORY_HEADER_START - 1  ' $K列（対応状況）を最低保証
            End If
            SheetTemplate.PageSetup.PrintArea = SheetTemplate.Range( _
                SheetTemplate.Cells(1, 1), _
                SheetTemplate.Cells(tplPaLastRow, tplPaRightCol) _
            ).Address
        End If
    End If
    ' 行14〜16（L列以降: SUMIFフラグ列）のカテゴリ列数を調整する
    ' catColDiff に応じて行13〜16がシフトされているため、シフト後の開始列からカウントする
    ' （catColDiff > 0 なら COL_CATEGORY_HEADER_START + catColDiff、< 0 なら同様にシフト済み）
    Dim templateSumifCount As Long
    templateSumifCount = 0
    Dim tplSumifStartCol As Long
    ' SUMIFエリア開始列を動的に計算する
    ' catColDiff > 0: 行1〜16 Insert でSUMIFが actualSumifStart + catColDiff に移動している
    ' catColDiff <= 0: 行1〜16 Delete なし（$K列破壊防止のため廃止）。SUMIFは actualSumifStart のまま
    tplSumifStartCol = actualSumifStart + IIf(catColDiff > 0, catColDiff, 0)
    Do While Len(CStr(SheetTemplate.Cells(DETAIL_START_ROW - 1, tplSumifStartCol + templateSumifCount).Value)) > 0
        templateSumifCount = templateSumifCount + 1
    Loop
    Dim sumifColDiff As Long
    sumifColDiff = categoryMappings.Count - templateSumifCount
    Dim ltInsertIdx As Long
    Dim rightmostLT As Long
    If sumifColDiff > 0 Then
        ' 行1・14〜16: 右端SUMIFフラグ列をコピーして右にセル挿入（右シフト）
        ' 行1（helper列テキスト「この列は削除しないでください」）も同時にシフトすることで、
        ' helper列テキストが常に最終SUMIF列の右（正しいhelper列）に位置するようになる
        ' Copy+Insert では条件付き書式の AppliesTo が拡張されないため、
        ' 「空Insert → Copy → PasteSpecial xlPasteAll」の2ステップで書式を確実にコピーする
        For ltInsertIdx = 1 To sumifColDiff
            rightmostLT = tplSumifStartCol + templateSumifCount + ltInsertIdx - 2
            ' Step1: 行1とSUMIF行（14〜16）にまたがる列に空セルを挿入（helper列テキストを含めて右シフト）
            ' 行2〜13はrightmostLT+1列が空のため影響なし
            Application.CutCopyMode = False
            SheetTemplate.Range(SheetTemplate.Cells(1, rightmostLT + 1), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT + 1)).Insert Shift:=xlShiftToRight
            ' Step2: SUMIF行（14〜16）のみコピー元をコピーし PasteSpecial で全書式を適用
            SheetTemplate.Range(SheetTemplate.Cells(DETAIL_START_ROW - 1, rightmostLT), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT)).Copy
            SheetTemplate.Range(SheetTemplate.Cells(DETAIL_START_ROW - 1, rightmostLT + 1), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT + 1)).PasteSpecial Paste:=xlPasteAll
            Application.CutCopyMode = False
        Next ltInsertIdx
    ElseIf sumifColDiff < 0 Then
        ' 行1・14〜16: 右端SUMIFフラグ列を削除（左シフト）
        ' 行1のhelper列テキストも同時にシフトする
        For ltInsertIdx = 1 To Abs(sumifColDiff)
            rightmostLT = tplSumifStartCol + templateSumifCount - ltInsertIdx
            SheetTemplate.Range(SheetTemplate.Cells(1, rightmostLT), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT)).Delete Shift:=xlShiftToLeft
        Next ltInsertIdx
    End If
    ' Phase1 Insert（行1-16, actualSumifStart〜+catColDiff-1列）の行14 背景色をクリアする
    ' Phase1 で挿入された空列は隣接する K14（黄色背景）の書式を継承するため、
    ' gap fix より先にクリアしておく。gap fix で列が削除されるケース（6→9等）では
    ' 先にクリアしても削除されるため無害。gap fix が実行されないケース（9→12等）では
    ' このクリアがなければ黄色背景が残ったまま出力に現れる。
    If catColDiff > 0 Then
        Dim clrRow14Col As Long
        For clrRow14Col = actualSumifStart To actualSumifStart + catColDiff - 1
            SheetTemplate.Cells(14, clrRow14Col).Interior.ColorIndex = xlNone
        Next clrRow14Col
    End If
    ' [Bug Fix] 集計用ワーク（SUMIFフラグ列）が対応状況列の直右から始まるよう整列する
    ' 「期待するSUMIF開始列」= max(計列+1, COL_CATEGORY_HEADER_START) と tplSumifStartCol の差が
    ' ギャップ列数。これにより catColDiff の正負を問わず正しいギャップを算出できる。
    '  例 9→12: 期待=max(15,12)=O(15), tpl=O(15), gap=0 → 削除なし（行7-11のcat11,12を保護）
    '  例 6→9 : 期待=max(12,12)=L(12), tpl=O(15), gap=3 → L,M,N削除（行7-11は9catで空）
    '  例 12→6: 期待=max( 9,12)=L(12), tpl=O(15), gap=3 → L,M,N削除（行7-11は6catで空）
    ' ※ gap fix を先に行い tplSumifStartCol を更新してから SUMIF formula fix を実行する。
    '   順序が逆だと SUMIF formula fix が削除前の列番号を使い再びズレが生じる。
    Dim expectedSumifStart As Long
    expectedSumifStart = COL_CATEGORY_START + categoryMappings.Count + 1
    If expectedSumifStart < COL_CATEGORY_HEADER_START Then expectedSumifStart = COL_CATEGORY_HEADER_START
    Dim gapColCount As Long
    gapColCount = tplSumifStartCol - expectedSumifStart
    If gapColCount > 0 Then
        Dim gapIdx As Long
        For gapIdx = 1 To gapColCount
            SheetTemplate.Range( _
                SheetTemplate.Cells(1, expectedSumifStart), _
                SheetTemplate.Cells(DETAIL_START_ROW + 1, expectedSumifStart)).Delete Shift:=xlShiftToLeft
        Next gapIdx
        tplSumifStartCol = expectedSumifStart
    End If
    ' [Bug Fix] catColDiff > 0 で追加した新カテゴリ列（行9/10）の SUMIF sum_range 列参照を修正する
    ' BKループ時点では対応する SUMIF フラグ列がまだ存在しないため、BK ループが生成する相対列参照は
    ' 「本来の SUMIF 列位置」を指す。しかし後続の sumifColDiff ループが同列に Insert を実行するたびに
    ' 参照が +1 ずつズレ、最終的にヘルパー列等の誤列を参照してしまう。
    ' gap fix 後の tplSumifStartCol（正しいSUMIF開始列）を使って上書き修正する。
    If catColDiff > 0 Then
        Dim fixCatIdx As Long
        Dim fixCatCol As Long
        Dim fixSumifCol As Long
        Dim fixRow As Long
        Dim fixColAddr As String
        For fixCatIdx = templateCatCount To categoryMappings.Count - 1
            fixCatCol = COL_CATEGORY_START + fixCatIdx
            fixSumifCol = tplSumifStartCol + fixCatIdx
            ' 列番号から列文字を取得（例: 24 → "X"、27 → "AA"）
            ' Cells(1, col).Address(False, False) = "X1" → 末尾の "1" を除去して列文字だけ取り出す
            fixColAddr = Left(SheetTemplate.Cells(1, fixSumifCol).Address(False, False), _
                              Len(SheetTemplate.Cells(1, fixSumifCol).Address(False, False)) - 1)
            For fixRow = ROW_CATEGORY - 1 To ROW_CATEGORY  ' 行9（未件数）・行10（済件数）
                SheetTemplate.Cells(fixRow, fixCatCol).Formula = _
                    "=IF(SUMIF($K15:$K16,$A" & fixRow & "," & _
                    fixColAddr & "15:" & fixColAddr & "16)=0," & _
                    Chr(34) & Chr(34) & ",SUMIF($K15:$K16,$A" & fixRow & "," & _
                    fixColAddr & "15:" & fixColAddr & "16))"
            Next fixRow
        Next fixCatIdx
    End If
    ' ヘルパー列の幅を新しい位置（tplSumifStartCol + categoryMappings.Count）に設定する
    ' 部分行Insert/Deleteでは列幅が引き継がれないため、保存した幅を明示的に復元する
    Dim newHelperCol As Long
    newHelperCol = tplSumifStartCol + categoryMappings.Count
    SheetTemplate.Columns(newHelperCol).ColumnWidth = savedHelperWidth
    ' 全SUMIF列の幅をSUMIF標準幅に統一する
    ' 行1-16 Insert/Deleteでは列幅がシフトされないため、以前のヘルパー列位置などに
    ' 旧ヘルパー幅（広い）が残り続ける場合がある。全SUMIF列を一括で標準幅に設定する。
    Dim sumifWidthIdx As Long
    For sumifWidthIdx = tplSumifStartCol To newHelperCol - 1
        SheetTemplate.Columns(sumifWidthIdx).ColumnWidth = savedSumifColWidth
    Next sumifWidthIdx
    ' [Phase3拡張] SheetTemplateのカテゴリヘッダーを設定シート順番通りに書き換える
    ' テンプレート調整フェーズで書き換えることで、コピー後のoutputシートは指摘詳細の更新のみでよくなる
    ' 行7: エイリアス、行8: 指摘分類名（B列〜）
    Dim tplCatHdrKeys As Variant
    tplCatHdrKeys = categoryMappings.Keys
    Dim tplCatHdrVals As Variant
    tplCatHdrVals = categoryMappings.Items
    Dim tplClearHdrCount As Long
    ' catColDiff < 0 では行7-11 Delete で超過カテゴリ列はすでに削除済み
    ' max(count, templateCount) にすると削除後の計列ヘッダーを "" で上書きしてしまうため
    ' ループ範囲は categoryMappings.Count のみとする
    tplClearHdrCount = categoryMappings.Count
    Dim tplCatDispIdx As Long
    For tplCatDispIdx = 0 To tplClearHdrCount - 1
        If tplCatDispIdx < categoryMappings.Count Then
            SheetTemplate.Cells(7, COL_CATEGORY_START + tplCatDispIdx).Value = tplCatHdrKeys(tplCatDispIdx)
            SheetTemplate.Cells(8, COL_CATEGORY_START + tplCatDispIdx).Value = tplCatHdrVals(tplCatDispIdx)
        Else
            SheetTemplate.Cells(7, COL_CATEGORY_START + tplCatDispIdx).Value = ""
            SheetTemplate.Cells(8, COL_CATEGORY_START + tplCatDispIdx).Value = ""
        End If
    Next tplCatDispIdx
    ' 行14（SUMIF開始列〜）のエイリアスヘッダーを書き換える
    Dim tplClearSumifCount As Long
    tplClearSumifCount = IIf(categoryMappings.Count > templateSumifCount, categoryMappings.Count, templateSumifCount)
    Dim tplCatHdrIdx As Long
    For tplCatHdrIdx = 0 To tplClearSumifCount - 1
        If tplCatHdrIdx < categoryMappings.Count Then
            SheetTemplate.Cells(DETAIL_START_ROW - 1, tplSumifStartCol + tplCatHdrIdx).Value = tplCatHdrKeys(tplCatHdrIdx)
        Else
            SheetTemplate.Cells(DETAIL_START_ROW - 1, tplSumifStartCol + tplCatHdrIdx).Value = ""
        End If
    Next tplCatHdrIdx
    '------------------
    ' 抽出処理
    '------------------
    '開いている全ブックを確認
    For Each book In Application.Workbooks
        'ファイル名に正規表現パターンマッチを行い対象ファイルを抽出
        If targetBookNamePattern.test(book.Name) And Not noTargetBookNamePattern.test(book.Name) Then
            '処理実施確認
            res = Module2.ShowMsg(testMode, "C02", book.Name & "のレビュー内容を抽出しますか？", vbYesNoCancel, vbYes)
            If res = vbCancel Then
                Module2.ShowMsg testMode, "C03", "以降の処理を中止します。", vbInformation 'それまでの処理をキャンセルはできないので「以降の処理を中止」
                Exit For
            ElseIf res = vbNo Then
                '処理スキップ
                GoTo NEXTBOOK
            End If
            If res = vbYes Then
                '基本情報
                target = Mid(book.Name, 1, InStrRev(book.Name, ".") - 1)
                count = Range("REVIEW_TIMES").Value
                If useReviewRecord Then
                    '転記先のレビュー記録票を取得する
                    '対象設計書名と"レビュー記録票"を含んでいれば対象設計書のレビュー記録票とみなす
                    Dim bookTemp As Workbook
                    Dim bookTempSelected As Boolean
                    bookTempSelected = False
                    For Each bookTemp In Application.Workbooks
                        If InStr(bookTemp.Name, target) > 0 And InStr(bookTemp.Name, "レビュー記録票") > 0 Then
                            bookTempSelected = True
                            Exit For
                        End If
                    Next bookTemp
                    If Not bookTempSelected Then
                        Module2.ShowMsg testMode, "W01", book.Name & " に対応するレビュー記録票が開いていません。", vbExclamation
                        Application.ScreenUpdating = True
                        Application.Cursor = xlDefault
                        GoTo NEXTBOOK
                    End If
                    '転記先シートの取得
                    If Not mappingHeaderSheet = "" Then
                        If Not hasSheet(bookTemp, mappingHeaderSheet) Then
                            Module2.ShowMsg testMode, "E06", "レビュー記録票に" & mappingHeaderSheet & " シートが存在しません。", vbExclamation
                            Application.ScreenUpdating = True
                            Application.Cursor = xlDefault
                            Exit Sub
                        End If
                        Set postingHeaderOutput = bookTemp.Worksheets(mappingHeaderSheet)
                    End If
                    If Not mappingSummarySheet = "" Then
                        If Not hasSheet(bookTemp, mappingSummarySheet) Then
                            Module2.ShowMsg testMode, "E06", "レビュー記録票に" & mappingSummarySheet & " シートが存在しません。", vbExclamation
                            Application.ScreenUpdating = True
                            Application.Cursor = xlDefault
                            Exit Sub
                        End If
                        Set postingSummaryOutput = bookTemp.Worksheets(mappingSummarySheet)
                    End If
                    If Not mappingListSheet = "" Then
                        If Not hasSheet(bookTemp, mappingListSheet) Then
                            Module2.ShowMsg testMode, "E06", "レビュー記録票に" & mappingListSheet & " シートが存在しません。", vbExclamation
                            Application.ScreenUpdating = True
                            Application.Cursor = xlDefault
                            Exit Sub
                        End If
                        Set postingOutput = bookTemp.Worksheets(mappingListSheet)
                    End If
                    If Not postingSummaryOutput Is Nothing Then
                        'レビュー回数のチェック
                        For postingSummaryRow = mappingSummaryStartRow To (mappingSummaryStartRow + 100)
                            If postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value = "" Or postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value = CStr(count) Then
                                If count > 1 And Not postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow - 1)).Value = CStr(count - 1) Then
                                    Module2.ShowMsg testMode, "E07", "指定されたレビュー回数が正しくありません。", vbExclamation
                                    Application.ScreenUpdating = True
                                    Application.Cursor = xlDefault
                                    Exit Sub
                                End If
                                If postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value = CStr(count) And Not postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow + 1)).Value = "" Then
                                    Module2.ShowMsg testMode, "E07", "指定されたレビュー回数が正しくありません。", vbExclamation
                                    Application.ScreenUpdating = True
                                    Application.Cursor = xlDefault
                                    Exit Sub
                                End If
                                Exit For
                            End If
                        Next postingSummaryRow
                        '転記先の開始行数を取得（サマリー）
                        For postingSummaryRow = mappingSummaryStartRow To (mappingSummaryStartRow + 100)
                            If postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value = "" Or postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value = CStr(count) Then
                                Exit For
                            End If
                        Next postingSummaryRow
                    End If
                    If Not postingOutput Is Nothing Then
                        '転記先の開始行数を取得（指摘一覧）
                        For postingRow = mappingListStartRow To (mappingListStartRow + 1000)
                            If postingOutput.Range(mappingListCount & CStr(postingRow)).Value = "" Or postingOutput.Range(mappingListCount & CStr(postingRow)).Value = CStr(count) Then
                                Exit For
                            End If
                        Next postingRow
                        '転記先のテンプレート行を取得（指摘一覧）
                        For postingTemplateRow = mappingListStartRow To (mappingListStartRow + 1000)
                            If postingOutput.Range(mappingListCount & CStr(postingTemplateRow)).Value = "" Then
                                Exit For
                            End If
                        Next postingTemplateRow
                    End If
                End If
                '出力シート名の決定
                outputSheetName = OUTPUT_SHEETNAME_PREFIX & CStr(count) & OUTPUT_SHEETNAME_SUFFIX
                ' [E13] 2回目以降: 既存の「レビュー結果1回目」シートのカテゴリ設定と現設定を照合
                ' （review_times=1 の場合は1回目の上書きなのでチェック不要）
                If CLng(count) >= 2 Then
                    Dim firstResultName As String
                    firstResultName = OUTPUT_SHEETNAME_PREFIX & "1" & OUTPUT_SHEETNAME_SUFFIX
                    If hasSheet(book, firstResultName) Then
                        Dim firstResultSheet As Worksheet
                        Set firstResultSheet = book.Worksheets(firstResultName)
                        ' ROW_CATEGORY行のSUM式を持つ計列を検索してカテゴリ数を取得
                        ' （row9はCOUNTIF式があるため使用せず、SUM式の位置からカテゴリ数を算出）
                        Dim existSumifCol As Long
                        existSumifCol = COL_CATEGORY_START
                        Do
                            If firstResultSheet.Cells(ROW_CATEGORY, existSumifCol).HasFormula Then
                                If Left(firstResultSheet.Cells(ROW_CATEGORY, existSumifCol).Formula, 5) = "=SUM(" Then Exit Do
                            End If
                            existSumifCol = existSumifCol + 1
                            If existSumifCol > COL_CATEGORY_START + 50 Then Exit Do  ' 安全上限
                        Loop
                        Dim existSheetCatCount As Long
                        existSheetCatCount = existSumifCol - COL_CATEGORY_START
                        ' 行7（Phase3が書き込んだエイリアス行）からエイリアスリストを構築
                        Dim existSheetAliases As String
                        existSheetAliases = ""
                        Dim existSheetCol As Long
                        Dim existSheetAlias As String
                        For existSheetCol = COL_CATEGORY_START To COL_CATEGORY_START + existSheetCatCount - 1
                            existSheetAlias = CStr(firstResultSheet.Cells(7, existSheetCol).Value)
                            If Len(existSheetAliases) > 0 Then existSheetAliases = existSheetAliases & ","
                            existSheetAliases = existSheetAliases & existSheetAlias
                        Next existSheetCol
                        ' 現設定エイリアスリストを構築
                        Dim currSheetAliases As String
                        currSheetAliases = ""
                        Dim currSheetKey As Variant
                        For Each currSheetKey In categoryMappings.Keys
                            If Len(currSheetAliases) > 0 Then currSheetAliases = currSheetAliases & ","
                            currSheetAliases = currSheetAliases & CStr(currSheetKey)
                        Next currSheetKey
                        If existSheetAliases <> currSheetAliases Then
                            Module2.ShowMsg testMode, "E13", _
                                "カテゴリ設定が変更されました（" & existSheetCatCount & "種類 → " & categoryMappings.Count & "種類）。" & _
                                "既存のレビュー結果シートのカテゴリ構造と不整合になるため、処理を中断します。" & _
                                "【対処方法】1. 設計書Excelの既存のレビュー結果シート（全て）を削除 2. 1回目のレビューから実行をやり直す", vbExclamation
                            Application.ScreenUpdating = True
                            Application.Cursor = xlDefault
                            Exit Sub
                        End If
                    End If
                End If
                '既存のシートを削除
                preDocId = ""
                If hasSheet(book, outputSheetName) = True Then
                    '文書IDを退避させておく
                    docId = book.Worksheets(outputSheetName).Cells(ROW_DOC_ID, COL_DOC_ID).Value
                    Application.DisplayAlerts = False
                    book.Worksheets(outputSheetName).Delete
                    Application.DisplayAlerts = True
                Else
                    '新規シート作成の場合、文書IDの採番
                    If count = 1 Then
                        '1回目の場合
                        If isCopyReviewList Then
                            Dim maxDocIdRbn As Long, docIdRow As Long
                            maxDocIdRbn = 0
                            docIdRow = DETAIL_ROW_LIST_START
                            Do Until listSheet.Cells(docIdRow, DETAIL_COL_LIST_TARGET).Value = ""
                                If CLng(Replace(listSheet.Cells(docIdRow, DETAIL_COL_LIST_DOC_ID).Value, DOC_ID_PREFIX, "")) > maxDocIdRbn Then
                                    maxDocIdRbn = CLng(Replace(listSheet.Cells(docIdRow, DETAIL_COL_LIST_DOC_ID).Value, DOC_ID_PREFIX, ""))
                                End If
                                docIdRow = docIdRow + 1
                            Loop
                            docId = Format(maxDocIdRbn + 1, """" & DOC_ID_PREFIX & """00000")
                        End If
                    Else
                        '2回目以降の場合
                        If hasSheet(book, OUTPUT_SHEETNAME_PREFIX & "1" & OUTPUT_SHEETNAME_SUFFIX) = True Then
                            docId = book.Worksheets(OUTPUT_SHEETNAME_PREFIX & "1" & OUTPUT_SHEETNAME_SUFFIX).Cells(ROW_DOC_ID, COL_DOC_ID).Value
                        End If
                    End If
                End If
                '対象ブックの先頭にテンプレートシートをコピー
                SheetTemplate.Copy before:=book.Worksheets(1)
                book.Worksheets(1).Name = outputSheetName
                Set output = book.Worksheets(outputSheetName)
                output.Cells(ROW_DOC_ID, COL_DOC_ID) = docId
                output.Cells(ROW_TARGET, COL_TARGET) = target
                output.Cells(ROW_COUNT, COL_COUNT) = count
                'エラーシートが既にある場合は削除
                If hasSheet(book, OUTPUT_ERR_SHEETNAME) = True Then
                    Application.DisplayAlerts = False
                    book.Worksheets(OUTPUT_ERR_SHEETNAME).Delete
                    Application.DisplayAlerts = True
                End If
                '----------------------------------------------------------------------------
                'レビュー指摘を抽出
                '----------------------------------------------------------------------------
                row = DETAIL_START_ROW
                Dim s As Worksheet
                Dim cmntCell As Range
                Dim workCommentCells As New Collection
                Dim workCommentCell(2) As String
                Dim errcount As Integer
                Dim err_row As Long
                'エラーカウント初期化
                errcount = 0
                Application.ScreenUpdating = False
                If useReviewRecord Then
                    '転記先のレビュー記録票（サマリー）のカレント行にレビュー回数が書かれていない場合は行を追加
                    If Not postingSummaryOutput Is Nothing Then
                        If postingSummaryOutput.Range("A" & CStr(postingSummaryRow)) = "" Then
                            postingSummaryOutput.Rows(postingSummaryRow).Copy
                            postingSummaryOutput.Rows(postingSummaryRow + 1).Insert
                        End If
                        'サマリーへレビュー回数を書き出す
                        If Len(mappingSummaryCount) > 0 Then
                            postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)) = CStr(count)
                        End If
                    End If
                    If Not postingHeaderOutput Is Nothing Then
                        'ヘッダーへレビュー回数を書き出す
                        If Len(mappingHeaderCount) > 0 Then
                            postingHeaderOutput.Range(mappingHeaderCount) = CStr(count)
                        End If
                    End If
                End If
                reviewee = Range(IDX_REVIEW_LIST_REVIEWEE).Value
                If Len(reviewee) = 0 Then
                    If checkReference(book, reviewListRevieweeSheet, reviewListRevieweeCell) Then
                        reviewee = book.Worksheets(reviewListRevieweeSheet).Range(reviewListRevieweeCell).Value
                    End If
                End If
                For Each s In book.Worksheets
                    '全コメントを抽出
                    For Each cmnt In s.comments
                        Dim commentText As String
                        commentText = cmnt.Text
                        'コメントに:が含まれ、改行があれば処理対象に
                        If InStr(1, StrConv(commentText, vbNarrow), ":") >= 1 And InStr(1, commentText, vbLf) >= 1 Then
                            'コメントの最初の:までの文字列がレビュア
                            reviewer = Left(commentText, InStr(1, StrConv(commentText, vbNarrow), ":") - 1)
                            'カテゴリを抽出（1-2文字対応）
                            category = ExtractCategory(commentText)
                            'カテゴリがない場合は処理しない
                            If category <> "" Then
                                'コメントの最後に"済"があれば対応済みと判断
                                If GetLastChar(commentText) = "済" Then
                                    isFixed = True
                                Else
                                    isFixed = False
                                End If
                                closeLine = extractCloseLine(commentText)
                                If category = "*" Then
                                    '*はレビュー日時情報のコメント。実施日、開始時刻、終了時刻、レビュー時間を抽出
                                    work = Split(commentText, vbLf)
                                    '要素数が5未満(名前、実施日、開始時刻、終了時刻、レビュー時間が入っていない)場合はエラーメッセージ出力。抽出処理は続行する。
                                    If UBound(work) - LBound(work) + 1 >= 5 Then
                                        If InStr(commentText, "実施日") >= 1 Then
                                            reviewDate = Mid(commentText, InStr(1, commentText, "実施日") + 4, InStr(InStr(1, commentText, "実施日"), commentText, vbLf) - InStr(1, commentText, "実施日") - 4)
                                            If InStr(commentText, "開始") >= 1 Then
                                                reviewStartTime = Mid(commentText, InStr(1, commentText, "開始") + 3, InStr(InStr(1, commentText, "開始"), commentText, vbLf) - InStr(1, commentText, "開始") - 3)
                                            Else
                                                reviewStartTime = ""
                                            End If
                                            If InStr(commentText, "終了") >= 1 Then
                                                reviewEndTime = Mid(commentText, InStr(1, commentText, "終了") + 3, InStr(InStr(1, commentText, "終了"), commentText, vbLf) - InStr(1, commentText, "終了") - 3)
                                            Else
                                                reviewEndTime = ""
                                            End If
                                            If InStr(commentText, "レビュー時間") >= 1 Then
                                                reviewTime = Mid(commentText, InStr(1, commentText, "レビュー時間") + 7)
                                            Else
                                                reviewTime = ""
                                            End If
                                        Else     ' コメント省略時
                                            reviewDate = work(1)
                                            reviewStartTime = work(2)
                                            reviewEndTime = work(3)
                                            reviewTime = work(4)
                                        End If
                                        output.Cells(ROW_DATE, COL_DATE) = reviewDate
                                        output.Cells(ROW_START, COL_START) = reviewStartTime
                                        output.Cells(ROW_END, COL_END) = reviewEndTime
                                        output.Cells(ROW_BREAK, COL_BREAK) = reviewTime
                                        If useReviewRecord Then
                                            'レビュー記録票（ヘッダー）へ転記する
                                            If Not postingHeaderOutput Is Nothing Then
                                                If Len(mappingHeaderDate) > 0 Then
                                                    postingHeaderOutput.Range(mappingHeaderDate) = reviewDate
                                                End If
                                                If Len(mappingHeaderStartTime) > 0 Then
                                                    postingHeaderOutput.Range(mappingHeaderStartTime) = reviewStartTime
                                                End If
                                                If Len(mappingHeaderEndTime) > 0 Then
                                                    postingHeaderOutput.Range(mappingHeaderEndTime) = reviewEndTime
                                                End If
                                                If Len(mappingHeaderStartDateTime) > 0 Then
                                                    postingHeaderOutput.Range(mappingHeaderStartDateTime) = reviewDate & " " & reviewStartTime
                                                End If
                                                If Len(mappingHeaderEndDateTime) > 0 Then
                                                    postingHeaderOutput.Range(mappingHeaderEndDateTime) = reviewDate & " " & reviewEndTime
                                                End If
                                                If Len(mappingHeaderReviewTime) > 0 Then
                                                    postingHeaderOutput.Range(mappingHeaderReviewTime) = reviewTime
                                                End If
                                            End If
                                            'レビュー記録票（サマリー）へ転記する
                                            If Not postingSummaryOutput Is Nothing Then
                                                If Len(mappingSummaryDate) > 0 Then
                                                    postingSummaryOutput.Range(mappingSummaryDate & CStr(postingSummaryRow)) = reviewDate
                                                End If
                                                If Len(mappingSummaryStartTime) > 0 Then
                                                    postingSummaryOutput.Range(mappingSummaryStartTime & CStr(postingSummaryRow)) = reviewStartTime
                                                End If
                                                If Len(mappingSummaryEndTime) > 0 Then
                                                    postingSummaryOutput.Range(mappingSummaryEndTime & CStr(postingSummaryRow)) = reviewEndTime
                                                End If
                                                If Len(mappingSummaryStartDateTime) > 0 Then
                                                    postingSummaryOutput.Range(mappingSummaryStartDateTime & CStr(postingSummaryRow)) = reviewDate & " " & reviewStartTime
                                                End If
                                                If Len(mappingSummaryEndDateTime) > 0 Then
                                                    postingSummaryOutput.Range(mappingSummaryEndDateTime & CStr(postingSummaryRow)) = reviewDate & " " & reviewEndTime
                                                End If
                                                If Len(mappingSummaryReviewTime) > 0 Then
                                                    postingSummaryOutput.Range(mappingSummaryReviewTime & CStr(postingSummaryRow)) = reviewTime
                                                End If
                                            End If
                                        End If
                                    Else
                                        '対象ブックの先頭にエラーシートテンプレートをコピー
                                        If errcount = 0 Then
                                            ErrorSheetTemplate.Copy before:=book.Worksheets(1)
                                            book.Worksheets(1).Name = OUTPUT_ERR_SHEETNAME
                                            Set err_output = book.Worksheets(OUTPUT_ERR_SHEETNAME)
                                        End If
                                        'エラーメッセージ出力
                                        err_row = err_output.Cells(Application.Rows.count, 1).End(xlUp).row + 1
                                        err_output.Cells(err_row, 1) = "レビュー日時コメントが正しく入力されていません｡実施日、開始時刻、終了時刻、レビュー時間を全て入力してください。"
                                        err_output.Hyperlinks.Add err_output.Cells(err_row, 2), "", "'" & s.Name & "'" & "!" & CStr(cmnt.Parent.Address)
                                        errcount = errcount + 1
                                    End If
                                ElseIf IsValidCategory(category, categoryMappings) Then
                                    '設定シートに登録済みのカテゴリであればレビューコメント
                                    'レビューコメントの位置補正
                                    If CbAdjustCmntPos.Value = True Then
                                        workCommentCell(1) = cmnt.Parent.Address
                                        workCommentCell(2) = commentText
                                        workCommentCells.Add workCommentCell
                                    End If
                                    '転記先のレビュー記録票の行特定列に値が書かれていない場合は行を追加
                                    If useReviewRecord And Not postingOutput Is Nothing Then
                                        If postingOutput.Range(mappingListCount & CStr(postingRow)).Value = "" Then
                                            postingOutput.Rows(postingTemplateRow).Copy
                                            postingOutput.Rows(postingRow + 1).Insert
                                            postingTemplateRow = postingTemplateRow + 1
                                        End If
                                    End If
                                    Application.CutCopyMode = False
                                    output.Range(CStr(row + 1) & ":" & CStr(row + 1)).Insert
                                    output.Range(CStr(row + 2) & ":" & CStr(row + 2)).Copy Destination:=output.Range(CStr(row + 1) & ":" & CStr(row + 1))
                                    reviewCommentTemp = Mid(commentText, InStr(1, commentText, vbLf) + 1)
                                    'レビューコメントと返信のパース
                                    rc() = splitComment(reviewCommentTemp)
                                    reviewComment = rc(1) & vbCrLf
                                    replyComment = rc(2) & vbCrLf
                                    position = CStr(cmnt.Parent.Address)
                                    output.Cells(row, DETAIL_COL_SHEET) = s.Name
                                    output.Cells(row, DETAIL_COL_POSITION) = Replace(position, "$", "")
                                    '指摘コメントが入ったセルへのリンクを相対パスにする
                                    output.Hyperlinks.Add output.Cells(row, DETAIL_COL_POSITION), "", "'" & s.Name & "'" & "!" & position
                                    output.Cells(row, DETAIL_COL_REVIEWER) = reviewer
                                    output.Cells(row, DETAIL_COL_CATEGORY) = category
                                    output.Cells(row, DETAIL_COL_REVIEW_COMMENT) = reviewCommentTemp
                                    If isFixed = True Then
                                        output.Cells(row, DETAIL_COL_FIX_STATUS) = "済"
                                    Else
                                        output.Cells(row, DETAIL_COL_FIX_STATUS) = "未"
                                    End If
                                    'レビュー記録票（指摘一覧）へ転記する
                                    If useReviewRecord And Not postingOutput Is Nothing Then
                                        If Len(mappingListCount) > 0 Then
                                            postingOutput.Range(mappingListCount & CStr(postingRow)).Value = CStr(count)
                                        End If
                                        If Len(mappingListReviewer) > 0 Then
                                            postingOutput.Range(mappingListReviewer & CStr(postingRow)).Value = reviewer
                                        End If
                                        If Len(mappingListCategory) > 0 Then
                                            postingOutput.Range(mappingListCategory & CStr(postingRow)).Value = categoryMappings.item(category)
                                        End If
                                        If Len(mappingListComment) > 0 Then
                                            postingOutput.Range(mappingListComment & CStr(postingRow)).Value = reviewComment
                                        End If
                                        If Len(mappingListReply) > 0 Then
                                            postingOutput.Range(mappingListReply & CStr(postingRow)).Value = replyComment
                                        End If
                                        If Len(mappingListReviewee) > 0 Then
                                            postingOutput.Range(mappingListReviewee & CStr(postingRow)).Value = reviewee
                                        End If
                                        If isFixed = True Then
                                            If Len(mappingListCloseLine) > 0 Then
                                                postingOutput.Range(mappingListCloseLine & CStr(postingRow)).Value = closeLine
                                            End If
                                        Else
                                            If Len(mappingListCloseLine) > 0 Then
                                                postingOutput.Range(mappingListCloseLine & CStr(postingRow)).Value = ""
                                            End If
                                        End If
                                        '行の高さを調整
                                        postingOutput.Rows(postingRow).AutoFit
                                    End If
                                    '行の高さを調整
                                    output.Rows(CStr(row) & ":" & CStr(row)).AutoFit
                                    row = row + 1
                                    postingRow = postingRow + 1
                                Else
                                    '対象ブックの先頭にエラーシートテンプレートをコピー
                                    If errcount = 0 Then
                                        ErrorSheetTemplate.Copy before:=book.Worksheets(1)
                                        book.Worksheets(1).Name = OUTPUT_ERR_SHEETNAME
                                        Set err_output = book.Worksheets(OUTPUT_ERR_SHEETNAME)
                                    End If
                                    'エラーメッセージ出力
                                    err_row = err_output.Cells(Application.Rows.count, 1).End(xlUp).row + 1
                                    err_output.Cells(err_row, 1) = "未登録の指摘分類エイリアスが記入されています: " & category
                                    err_output.Hyperlinks.Add err_output.Cells(err_row, 2), "", "'" & s.Name & "'" & "!" & CStr(cmnt.Parent.Address)
                                    errcount = errcount + 1
                                End If
                            End If
                        End If
                    Next cmnt
                    'レビューコメントの位置補正（コメントを再設定）
                    If CbAdjustCmntPos.Value = True Then
                        For Each cc In workCommentCells
                            s.Range(cc(1)).ClearComments
                            s.Range(cc(1)).AddComment cc(2)
                            s.Range(cc(1)).comment.Shape.TextFrame.AutoSize = True
                        Next cc
                        Set workCommentCells = New Collection
                    End If
                Next s
                'テンプレートの空行を削除
                output.Range(CStr(row + 1) & ":" & CStr(row + 1)).Delete
                Application.ScreenUpdating = True
                fileCount = fileCount + 1
            End If
            '----------------------------------------------------------------------------
            'レビュー記録一覧への反映
            '----------------------------------------------------------------------------
            Dim phase As String, autor As String, volume As Long, listReviewer As String, listReviewee As String, reviewWay As String, reviewResult As String
            Dim listRow As Long
            Dim existSameDocIdAndCount As Boolean
            '既に存在する文書ID・回数の場合、一覧に反映しない
            '前回記録No.もここで取得しておく
            Dim docIdRng As Range
            Dim firstAddress As String
            existSameDocIdAndCount = False
            If useSimpleSummary Then
                With listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_DOC_ID).EntireColumn
                    Set docIdRng = .Find(what:=docId)
                    If Not docIdRng Is Nothing Then
                        firstAddress = docIdRng.Address
                        Do
                            If listSheet.Cells(docIdRng.row, DETAIL_COL_LIST_COUNT).Value = count Then
                                existSameDocIdAndCount = True
                                listRow = docIdRng.row
                            End If
                            If listSheet.Cells(docIdRng.row, DETAIL_COL_LIST_COUNT).Value = (count - 1) Then
                                preDocId = listSheet.Cells(docIdRng.row, DETAIL_COL_LIST_NO).Value
                            End If
                            Set docIdRng = .FindNext(docIdRng)
                            If docIdRng Is Nothing Then Exit Do
                        Loop Until docIdRng.Address = firstAddress
                    End If
                End With
            End If
            If useSimpleSummary And existSameDocIdAndCount = False Then
                '最終行を取得
                'Application.Rowsを使用すると、xlsxファイルの時にエラーとなるため、一覧ファイルをアクティブにする
                listSheet.Activate
                listRow = listSheet.Cells(Application.Rows.count, 3).End(xlUp).row + 1
                If Len(listSheet.Cells(listRow, 1).Value) = 0 Then
                    '最終行まで埋まっている場合、既存行をコピー
                    listSheet.Cells(listRow - 1, 1).EntireRow.Copy
                    listSheet.Cells(listRow, 1).Insert
                    'コピー状態解除
                    Application.CutCopyMode = False
                    '値のクリア
                    listSheet.Cells(listRow, 18) = ""
                    listSheet.Cells(listRow, 19) = ""
                    listSheet.Cells(listRow, 20) = ""
                    listSheet.Cells(listRow, 21) = ""
                    listSheet.Cells(listRow, 22) = ""
                    listSheet.Cells(listRow, 24) = ""
                    listSheet.Cells(listRow, 25) = ""
                    listSheet.Cells(listRow, 40) = ""
                End If
            End If
            '値の取得
            '工程
            phase = Range(IDX_REVIEW_LIST_PHASE).Value
            If Len(phase) = 0 Then
                If checkReference(book, reviewListPhaseSheet, reviewListPhaseCell) Then
                    phase = book.Worksheets(reviewListPhaseSheet).Range(reviewListPhaseCell).Value
                Else
                    Module2.ShowMsg testMode, "W02", """工程""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
                    phase = "取得できませんでした"
                End If
            End If
            'レビュア
            listReviewer = Range(IDX_REVIEW_LIST_REVIEWER).Value
            If Len(listReviewer) = 0 Then
                If checkReference(book, reviewListReviewerSheet, reviewListReviewerCell) Then
                    listReviewer = book.Worksheets(reviewListReviewerSheet).Range(reviewListReviewerCell).Value
                Else
                    Module2.ShowMsg testMode, "W03", """レビュア""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
                    listReviewer = "取得できませんでした"
                End If
            End If
            'レビュイ
            listReviewee = Range(IDX_REVIEW_LIST_REVIEWEE).Value
            If Len(listReviewee) = 0 Then
                If checkReference(book, reviewListRevieweeSheet, reviewListRevieweeCell) Then
                    listReviewee = book.Worksheets(reviewListRevieweeSheet).Range(reviewListRevieweeCell).Value
                Else
                    Module2.ShowMsg testMode, "W04", """作成者・レビュイ""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
                    listReviewee = "取得できませんでした"
                End If
            End If
            'レビュー結果 - 条件付合格判定
            reviewResult = ""
            If CbConditional = True Then
                Dim categoryList As Variant
                Dim categoryIdx As Long
                Dim categoryCount As Long
                categoryList = categoryMappings.Keys
                '各カテゴリの摘出件数を取得し、条件付合格の判定を行う
                categoryCount = 0
                For categoryIdx = 0 To UBound(categoryList)
                    If nullToZero(output.Cells(ROW_CATEGORY, COL_CATEGORY_START + categoryIdx).Value) > 0 Then
                        '指摘がある場合、1インクリメント
                        categoryCount = categoryCount + 1
                        If Range(IDX_CONDITIONAL_CATEGORY).Value = categoryList(categoryIdx) Then
                            '条件付合格の条件として指定されているカテゴリの場合
                            If (nullToZero(output.Cells(ROW_CATEGORY, COL_CATEGORY_START + categoryIdx).Value) <= Range(IDX_CONDITIONAL_COUNT).Value And errcount = 0) Then
                                reviewResult = "条件付合格"
                            End If
                        Else
                            '条件付合格のカテゴリ以外に指摘がある場合、条件付合格にはならないので、処理終了
                            reviewResult = ""
                            Exit For
                        End If
                    End If
                Next categoryIdx
            End If
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
            book.Worksheets(1).Activate
            Application.ScreenUpdating = True
            If Err.Number <> 0 Then volume = 0
            On Error GoTo 0
            If useSimpleSummary Then
                '値のセット
                listSheet.Cells(listRow, DETAIL_COL_LIST_PHASE) = phase
                listSheet.Cells(listRow, DETAIL_COL_LIST_DOC_ID) = docId
                listSheet.Cells(listRow, DETAIL_COL_LIST_TARGET) = output.Cells(ROW_TARGET, COL_TARGET).Value
                listSheet.Cells(listRow, DETAIL_COL_LIST_AUTHOR) = listReviewee
                listSheet.Cells(listRow, DETAIL_COL_LIST_COUNT) = output.Cells(ROW_COUNT, COL_COUNT).Value
                listSheet.Cells(listRow, DETAIL_COL_LIST_PRE_DOC_ID) = preDocId
                listSheet.Cells(listRow, DETAIL_COL_LIST_VOLUME) = zeroToNull(volume)
                listSheet.Cells(listRow, DETAIL_COL_LIST_DATE) = output.Cells(ROW_DATE, COL_DATE).Value
                listSheet.Cells(listRow, DETAIL_COL_LIST_START) = output.Cells(ROW_START, COL_START).Value
                listSheet.Cells(listRow, DETAIL_COL_LIST_END) = output.Cells(ROW_END, COL_END).Value
                listSheet.Cells(listRow, DETAIL_COL_LIST_BREAK) = nullToZero(output.Cells(ROW_BREAK, COL_BREAK).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_REVIEWER) = listReviewer
                listSheet.Cells(listRow, DETAIL_COL_LIST_REVIEWEE) = listReviewee
                If listSheet.Cells(listRow, DETAIL_COL_LIST_REVIEW_WAY).Value = "" Then
                    listSheet.Cells(listRow, DETAIL_COL_LIST_REVIEW_WAY) = "回覧"
                End If
                Dim catIdx As Long
                For catIdx = 0 To categoryMappings.Count - 1
                    listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_A + catIdx) = zeroToNull(output.Cells(ROW_CATEGORY, COL_CATEGORY_START + catIdx).Value)
                Next catIdx
                If (listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_TOTAL).Value = 0 And errcount = 0) Then
                    reviewResult = "合格"
                End If
                listSheet.Cells(listRow, DETAIL_COL_LIST_REVIEW_RESULT) = reviewResult
                listSheet.Cells(listRow, DETAIL_COL_LIST_RE_REVIEW_WAY) = ""
            End If
            If useReviewRecord Then
                'ヘッダーの転記
                If Not postingHeaderOutput Is Nothing Then
                    If Len(mappingHeaderPhase) > 0 Then
                        postingHeaderOutput.Range(mappingHeaderPhase).Value = phase
                    End If
                    If Len(mappingHeaderVolume) > 0 Then
                        postingHeaderOutput.Range(mappingHeaderVolume).Value = zeroToNull(volume)
                    End If
                    If Len(mappingHeaderReviewer) > 0 Then
                        postingHeaderOutput.Range(mappingHeaderReviewer).Value = listReviewer
                    End If
                    If Len(mappingHeaderReviewee) > 0 Then
                        postingHeaderOutput.Range(mappingHeaderReviewee).Value = listReviewee
                    End If
                End If
                'サマリーの転記
                If Not postingSummaryOutput Is Nothing Then
                    If Len(mappingSummaryPhase) > 0 Then
                        postingSummaryOutput.Range(mappingSummaryPhase & CStr(postingSummaryRow)).Value = phase
                    End If
                    If Len(mappingSummaryVolume) > 0 Then
                        postingSummaryOutput.Range(mappingSummaryVolume & CStr(postingSummaryRow)).Value = zeroToNull(volume)
                    End If
                    If Len(mappingSummaryReviewer) > 0 Then
                        postingSummaryOutput.Range(mappingSummaryReviewer & CStr(postingSummaryRow)).Value = listReviewer
                    End If
                    If Len(mappingSummaryReviewee) > 0 Then
                        postingSummaryOutput.Range(mappingSummaryReviewee & CStr(postingSummaryRow)).Value = listReviewee
                    End If
                End If
            End If
        End If
NEXTBOOK:
    Next book
    Application.Cursor = xlDefault
    If fileCount = 0 Then
        Module2.ShowMsg testMode, "E08", "レビュー対象文書が見つかりません。", vbExclamation
    Else
        Module2.ShowMsg testMode, "I01", "レビュー結果の抽出が完了しました。" & vbCrLf & vbCrLf & "処理ファイル数:" & fileCount & "件", vbInformation
    End If
    Exit Sub
ERROR:
    Module2.ShowMsg testMode, "E11", "処理中にエラーが発生しました。" & Err.Number & vbCrLf & vbCrLf & Err.Description, vbError
    Application.ScreenUpdating = True
    Application.Cursor = xlDefault
End Sub
Function GetLastChar(str As String)
    Dim work As String
    work = Replace(str, " ", "")
    work = Replace(str, "　", "")
    work = Replace(str, vbTab, "")
    work = Replace(str, vbCr, "")
    work = Replace(str, vbLf, "")
    GetLastChar = Right(work, 1)
End Function
