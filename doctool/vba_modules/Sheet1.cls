- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Option Explicit

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
Const DETAIL_COL_LIST_REVIEW_RESULT = 38
Const DETAIL_COL_LIST_RE_REVIEW_WAY = 39
Const DOC_ID_PREFIX = "D"
' SheetTemplateのSUMIFエイリアス列開始（列L=12）
Const COL_CATEGORY_HEADER_START = 12

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
    initializeModule1

    ' Phase 1: 設定読み込み
    Dim targetBookNamePattern As Object
    Dim noTargetBookNamePattern As Object
    Dim settings As BasicSettings
    settings = LoadBasicSettings(targetBookNamePattern, noTargetBookNamePattern)

    Dim categoryMappings As Object
    Set categoryMappings = LoadCategoryMappings(testMode)
    If categoryMappings Is Nothing Then
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
    End If

    Dim mappings As MappingConfig
    mappings = LoadItemMappings()

    ' Phase 2: バリデーション・レビュー記録一覧変数の初期化
    Dim reviewListFilepath As String
    Dim reviewListSheet As String
    Dim reviewListPhase As String, reviewListPhaseSheet As String, reviewListPhaseCell As String
    Dim reviewListReviewer As String, reviewListReviewerSheet As String, reviewListReviewerCell As String
    Dim reviewListReviewee As String, reviewListRevieweeSheet As String, reviewListRevieweeCell As String
    Dim isCopyReviewList As Boolean
    If Not ValidateReviewListInputs(testMode, settings, _
        reviewListFilepath, isCopyReviewList, reviewListSheet, _
        reviewListPhase, reviewListPhaseSheet, reviewListPhaseCell, _
        reviewListReviewer, reviewListReviewerSheet, reviewListReviewerCell, _
        reviewListReviewee, reviewListRevieweeSheet, reviewListRevieweeCell) Then
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
    End If

    ' Phase 3: レビュー記録一覧ファイル操作
    Dim reviewListBook As Workbook
    Dim listSheet As Worksheet
    If isCopyReviewList Then
        Set reviewListBook = OpenReviewListFile(testMode, reviewListFilepath, reviewListSheet, listSheet)
        If reviewListBook Is Nothing Then
            Application.ScreenUpdating = True
            Application.Cursor = xlDefault
            Exit Sub
        End If
        If Not AdjustReviewListCategoryColumns(listSheet, categoryMappings, testMode) Then
            Application.ScreenUpdating = True
            Application.Cursor = xlDefault
            Exit Sub
        End If
    End If

    ' Phase 4: SheetTemplate調整
    Dim tplSumifStartCol As Long
    Dim catColDiff As Long
    Dim actualSumifStart As Long
    Dim templateCatCount As Long
    Dim savedHelperWidth As Double
    Dim savedSumifColWidth As Double
    Dim templateSumifCount As Long
    AdjustTemplateCategoryColumns categoryMappings, tplSumifStartCol, catColDiff, _
        actualSumifStart, templateCatCount, savedHelperWidth, savedSumifColWidth
    AdjustTemplateSumifColumns categoryMappings, tplSumifStartCol, templateSumifCount
    FixTemplateGapAndFormulas categoryMappings, tplSumifStartCol, catColDiff, _
        actualSumifStart, templateCatCount, savedHelperWidth, savedSumifColWidth
    UpdateTemplateHeaders categoryMappings, tplSumifStartCol, templateSumifCount

    ' Phase 5: 対象ブックへの抽出処理ループ
    Dim fileCount As Integer
    fileCount = 0
    Dim res As Long
    Dim book As Workbook
    For Each book In Application.Workbooks
        If targetBookNamePattern.test(book.Name) And Not noTargetBookNamePattern.test(book.Name) Then
            res = Module2.ShowMsg(testMode, "C02", book.Name & "のレビュー内容を抽出しますか？", vbYesNoCancel, vbYes)
            If res = vbCancel Then
                Module2.ShowMsg testMode, "C03", "以降の処理を中止します。", vbInformation
                Exit For
            ElseIf res = vbNo Then
                GoTo NEXTBOOK
            End If
            If res = vbYes Then
                Dim target As String, count As String
                target = Mid(book.Name, 1, InStrRev(book.Name, ".") - 1)
                count = Range("REVIEW_TIMES").Value

                Dim postingHeaderOutput As Worksheet
                Dim postingSummaryOutput As Worksheet
                Dim postingOutput As Worksheet
                Dim postingRow As Integer
                Dim postingSummaryRow As Integer
                Dim postingTemplateRow As Integer
                If settings.useReviewRecord Then
                    Dim rrResult As Integer
                    rrResult = GetReviewRecordSheets(book, target, count, mappings, testMode, _
                        postingHeaderOutput, postingSummaryOutput, postingOutput, _
                        postingRow, postingSummaryRow, postingTemplateRow)
                    If rrResult = 1 Then GoTo NEXTBOOK
                    If rrResult = 2 Then
                        Application.ScreenUpdating = True
                        Application.Cursor = xlDefault
                        Exit Sub
                    End If
                End If

                Dim output As Worksheet
                Dim docId As String, preDocId As String
                Dim isOverwrite As Boolean
                Set output = PrepareOutputSheet(book, count, categoryMappings, _
                    isCopyReviewList, listSheet, testMode, docId, preDocId, isOverwrite)
                If output Is Nothing Then
                    Application.ScreenUpdating = True
                    Application.Cursor = xlDefault
                    Exit Sub
                End If

                Dim errcount As Integer
                Dim reviewDate As String, reviewStartTime As String
                Dim reviewEndTime As String, reviewTime As String
                errcount = 0
                ExtractReviewComments book, output, categoryMappings, settings, mappings, _
                    count, testMode, isOverwrite, _
                    postingHeaderOutput, postingSummaryOutput, postingOutput, _
                    postingRow, postingSummaryRow, postingTemplateRow, _
                    errcount, reviewDate, reviewStartTime, reviewEndTime, reviewTime

                Dim volume As Long
                volume = CalcPageVolume(book)

                Dim reviewResult As String
                reviewResult = DetermineReviewResult(output, categoryMappings, errcount)

                Dim phase As String, listReviewer As String, listReviewee As String
                If isCopyReviewList Or settings.useReviewRecord Then
                    WriteToReviewList listSheet, output, count, docId, preDocId, _
                        settings.useSimpleSummary, volume, reviewResult, _
                        reviewListPhase, reviewListPhaseSheet, reviewListPhaseCell, _
                        reviewListReviewer, reviewListReviewerSheet, reviewListReviewerCell, _
                        reviewListReviewee, reviewListRevieweeSheet, reviewListRevieweeCell, _
                        categoryMappings, testMode, book, errcount, _
                        phase, listReviewer, listReviewee
                End If

                If settings.useReviewRecord Then
                    WriteToReviewRecordHeader postingHeaderOutput, mappings, count, _
                        phase, volume, listReviewer, listReviewee
                    WriteToReviewRecordSummary postingSummaryOutput, mappings, count, _
                        phase, volume, listReviewer, listReviewee, postingSummaryRow
                End If

                fileCount = fileCount + 1
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

'=====================================================
' 関数名: LoadBasicSettings
' 機能: 基本設定シートからuseReviewRecord/useSimpleSummaryを読み込み、
'       正規表現パターンを初期化する
' 引数: targetPattern        - 対象ブック名パターン（ByRef、呼び出し元に返す）
'       noTargetPattern      - 除外ブック名パターン（ByRef、呼び出し元に返す）
' 戻値: BasicSettings型（useReviewRecord, useSimpleSummaryを含む）
'=====================================================
Public Function LoadBasicSettings(ByRef targetPattern As Object, ByRef noTargetPattern As Object) As BasicSettings
    Dim settings As BasicSettings
    settings.useReviewRecord = ThisWorkbook.Worksheets(SHT_KIHON_SETTINGS).Range("B2").Value
    settings.useSimpleSummary = ThisWorkbook.Worksheets(SHT_KIHON_SETTINGS).Range("B3").Value
    InitRegexPatterns targetPattern, noTargetPattern
    LoadBasicSettings = settings
End Function

'=====================================================
' 関数名: LoadCategoryMappings
' 機能: 指摘分類マッピング設定シートからDictionaryを構築する
'       カテゴリが0件の場合はE12エラーを表示しNothingを返す
' 引数: testMode - テストモードフラグ
' 戻値: Object (Dictionary)、エラー時はNothing
'=====================================================
Public Function LoadCategoryMappings(testMode As Boolean) As Object
    Dim categoryMappings As Object
    Dim row As Long
    Set categoryMappings = CreateObject("Scripting.Dictionary")
    With ThisWorkbook.Worksheets(SHT_CATEGORY_MAPPINGS)
        For row = 2 To .Cells(Application.Rows.Count, 1).End(xlUp).Row
            Call categoryMappings.Add(.Cells(row, 1).Value, .Cells(row, 2).Value)
        Next row
    End With
    If categoryMappings.Count = 0 Then
        Module2.ShowMsg testMode, "E12", "カテゴリが1件も登録されていません。指摘分類マッピング設定シートにカテゴリを登録してください。", vbExclamation
        Set LoadCategoryMappings = Nothing
        Exit Function
    End If
    Set LoadCategoryMappings = categoryMappings
End Function

'=====================================================
' 関数名: LoadItemMappings
' 機能: 項目マッピング設定シートからMappingConfig型を構築する
' 戻値: MappingConfig型（ヘッダー/サマリー/指摘一覧のマッピング定義）
'=====================================================
Public Function LoadItemMappings() As MappingConfig
    Dim m As MappingConfig
    With ThisWorkbook.Worksheets(SHT_ITEM_MAPPINGS)
        m.headerSheet = .Cells(2, 2).Value
        m.headerCount = .Cells(7, 2).Value & CStr(.Cells(7, 3).Value)
        m.headerPhase = .Cells(8, 2).Value & CStr(.Cells(8, 3).Value)
        m.headerVolume = .Cells(9, 2).Value & CStr(.Cells(9, 3).Value)
        m.headerDate = .Cells(10, 2).Value & CStr(.Cells(10, 3).Value)
        m.headerStartTime = .Cells(11, 2).Value & CStr(.Cells(11, 3).Value)
        m.headerEndTime = .Cells(12, 2).Value & CStr(.Cells(12, 3).Value)
        m.headerStartDateTime = .Cells(13, 2).Value & CStr(.Cells(13, 3).Value)
        m.headerEndDateTime = .Cells(14, 2).Value & CStr(.Cells(14, 3).Value)
        m.headerReviewTime = .Cells(15, 2).Value & CStr(.Cells(15, 3).Value)
        m.headerReviewer = .Cells(16, 2).Value & CStr(.Cells(16, 3).Value)
        m.headerReviewee = .Cells(17, 2).Value & CStr(.Cells(17, 3).Value)
        m.summarySheet = .Cells(2, 6).Value
        m.summaryStartRow = .Cells(3, 6).Value
        m.summaryCount = .Cells(7, 6).Value
        m.summaryPhase = .Cells(8, 6).Value
        m.summaryVolume = .Cells(9, 6).Value
        m.summaryDate = .Cells(10, 6).Value
        m.summaryStartTime = .Cells(11, 6).Value
        m.summaryEndTime = .Cells(12, 6).Value
        m.summaryStartDateTime = .Cells(13, 6).Value
        m.summaryEndDateTime = .Cells(14, 6).Value
        m.summaryReviewTime = .Cells(15, 6).Value
        m.summaryReviewer = .Cells(16, 6).Value
        m.summaryReviewee = .Cells(17, 6).Value
        m.listSheet = .Cells(2, 9).Value
        m.listStartRow = .Cells(3, 9).Value
        m.listCount = .Cells(7, 9).Value
        m.listCategory = .Cells(8, 9).Value
        m.listComment = .Cells(9, 9).Value
        m.listReviewer = .Cells(10, 9).Value
        m.listReply = .Cells(11, 9).Value
        m.listReviewee = .Cells(12, 9).Value
        m.listCloseLine = .Cells(13, 9).Value
    End With
    LoadItemMappings = m
End Function

'=====================================================
' 関数名: ValidateReviewListInputs
' 機能: レビュー記録一覧関連の入力値を検証し、参照変数を初期化する
'       E01〜E04のエラーチェックを行う
' 引数: testMode              - テストモードフラグ
'       settings              - 基本設定（useSimpleSummaryを参照）
'       reviewListFilepath    - ファイルパス（クリーニング後を返す, ByRef）
'       isCopyReviewList      - 一覧反映フラグ（True=反映する, ByRef）
'       reviewListSheet       - シート名（ByRef）
'       reviewListPhase〜     - 参照フィールド各種（ByRef）
' 戻値: Boolean（True=検証OK・続行可、False=エラー・中断）
'=====================================================
Public Function ValidateReviewListInputs(testMode As Boolean, ByRef settings As BasicSettings, _
    ByRef reviewListFilepath As String, ByRef isCopyReviewList As Boolean, _
    ByRef reviewListSheet As String, _
    ByRef reviewListPhase As String, ByRef reviewListPhaseSheet As String, ByRef reviewListPhaseCell As String, _
    ByRef reviewListReviewer As String, ByRef reviewListReviewerSheet As String, ByRef reviewListReviewerCell As String, _
    ByRef reviewListReviewee As String, ByRef reviewListRevieweeSheet As String, ByRef reviewListRevieweeCell As String) As Boolean
    reviewListFilepath = Trim(Range(IDX_REVIEW_LIST_FILEPATH).Value)
    If Left(reviewListFilepath, 1) = Chr(34) Then reviewListFilepath = Mid(reviewListFilepath, 2)
    If Right(reviewListFilepath, 1) = Chr(34) Then reviewListFilepath = Left(reviewListFilepath, Len(reviewListFilepath) - 1)
    If settings.useSimpleSummary And Len(reviewListFilepath) = 0 Then
        isCopyReviewList = False
        Module2.ShowMsg testMode, "E01", "レビュー記録一覧のファイルパスが未入力です。", vbExclamation
        ValidateReviewListInputs = False
        Exit Function
    End If
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
        ValidateReviewListInputs = False
        Exit Function
    End If
    If settings.useSimpleSummary Then
        reviewListSheet = Range(IDX_REVIEW_LIST_SHEET).Value
        If Len(reviewListSheet) = 0 Then
            Module2.ShowMsg testMode, "E03", "レビュー記録一覧のシート名が未入力です。", vbExclamation
            ValidateReviewListInputs = False
            Exit Function
        End If
        Dim reviewListFileNm As String
        reviewListFileNm = Dir(reviewListFilepath)
        If Len(reviewListFileNm) = 0 Then
            Module2.ShowMsg testMode, "E04", "レビュー記録一覧ファイルが存在しません。", vbExclamation
            ValidateReviewListInputs = False
            Exit Function
        End If
        isCopyReviewList = True
    End If
    ValidateReviewListInputs = True
End Function

'=====================================================
' 関数名: OpenReviewListFile
' 機能: レビュー記録一覧ファイルを開く（バックアップ取得・既存ブック処理含む）
'       E05エラーチェック（指定シートの存在確認）を行う
' 引数: testMode          - テストモードフラグ
'       reviewListFilepath - ファイルパス
'       reviewListSheet    - 対象シート名
'       listSheet          - 取得したシート（ByRef）
' 戻値: Workbook（成功時）、Nothing（エラー時）
'=====================================================
Public Function OpenReviewListFile(testMode As Boolean, reviewListFilepath As String, _
    reviewListSheet As String, ByRef listSheet As Worksheet) As Workbook
    Dim reviewListFileNm As String
    reviewListFileNm = Dir(reviewListFilepath)
    Dim reviewListBook As Workbook
    For Each reviewListBook In Workbooks
        If reviewListBook.Name = reviewListFileNm Then
            If reviewListBook.Saved = False Then
                If Module2.ShowMsg(testMode, "C01", "レビュー記録一覧を一旦閉じて開き直します。編集中の内容は保存されます。" & vbCrLf & "処理を続行してよろしいですか？", vbYesNo, vbYes) = vbNo Then
                    Set OpenReviewListFile = Nothing
                    Exit Function
                End If
            End If
            reviewListBook.Close SaveChanges:=True
            Exit For
        End If
    Next reviewListBook
    If CbBkup = True Then
        Dim pos As Long
        Dim extension As String
        Dim bkupFileNm As String
        pos = InStrRev(reviewListFileNm, ".")
        If pos > 0 Then
            extension = Mid(reviewListFileNm, pos)
        End If
        bkupFileNm = Replace(reviewListFileNm, extension, "") & "_" & Format(Date, "yyyyMMdd") & "_" & Format(Time, "hhmmss") & extension
        FileCopy reviewListFilepath, Replace(reviewListFilepath, reviewListFileNm, "") & bkupFileNm
    End If
    Set reviewListBook = Workbooks.Open(Filename:=reviewListFilepath, UpdateLinks:=0, IgnoreReadOnlyRecommended:=True)
    If hasSheet(reviewListBook, Range(IDX_REVIEW_LIST_SHEET).Value) = False Then
        Module2.ShowMsg testMode, "E05", "レビュー記録一覧ファイルに指定されたシートが存在しません。", vbExclamation
        Set OpenReviewListFile = Nothing
        Exit Function
    End If
    Set listSheet = reviewListBook.Worksheets(Range(IDX_REVIEW_LIST_SHEET).Value)
    Set OpenReviewListFile = reviewListBook
End Function

'=====================================================
' 関数名: AdjustReviewListCategoryColumns
' 機能: レビュー記録一覧のカテゴリ列数を設定シートに合わせて調整する
'       E13照合（カテゴリ変更検知）、列挿入/削除、SUM式更新、印刷範囲更新を行う
' 引数: listSheet        - 対象シート
'       categoryMappings - 指摘分類マッピング（Dictionary）
'       testMode         - テストモードフラグ
' 戻値: Boolean（True=続行可、False=E13エラー・中断）
'=====================================================
Public Function AdjustReviewListCategoryColumns(listSheet As Worksheet, _
    categoryMappings As Object, testMode As Boolean) As Boolean
    Dim listRow1ExistAlias As String
    listRow1ExistAlias = CStr(listSheet.Cells(1, DETAIL_COL_LIST_CATEGORY_A).Value)
    If Len(listRow1ExistAlias) > 0 Then
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
            AdjustReviewListCategoryColumns = False
            Exit Function
        End If
    Else
        Dim listInitKey As Variant
        Dim listInitIdx As Long
        listInitIdx = 0
        For Each listInitKey In categoryMappings.Keys
            listSheet.Cells(1, DETAIL_COL_LIST_CATEGORY_A + listInitIdx).Value = CStr(listInitKey)
            listInitIdx = listInitIdx + 1
        Next listInitKey
    End If
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
            listRightmostCol = DETAIL_COL_LIST_CATEGORY_A + listTplCatCount + listColInsertIdx - 2
            Application.CutCopyMode = False
            listSheet.Range(listSheet.Cells(1, listRightmostCol + 1), _
                            listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol + 1)).Insert Shift:=xlShiftToRight
            listSheet.Range(listSheet.Cells(1, listRightmostCol), _
                            listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol)).Copy
            listSheet.Range(listSheet.Cells(1, listRightmostCol + 1), _
                            listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol + 1)).PasteSpecial Paste:=xlPasteAll
            Application.CutCopyMode = False
            listSheet.Columns(listRightmostCol + 1).ColumnWidth = listSheet.Columns(listRightmostCol).ColumnWidth
        Next listColInsertIdx
        If listNoteCol > 0 Then
            listSheet.Columns(listNoteCol + listCatColDiff).ColumnWidth = savedListNoteColWidth
            listSheet.Columns(listNoteCol + listCatColDiff + 1).ColumnWidth = savedListPastNote1Width
            listSheet.Columns(listNoteCol + listCatColDiff + 2).ColumnWidth = savedListPastNote2Width
            listSheet.Columns(listNoteCol + listCatColDiff + 3).ColumnWidth = savedListPastNote3Width
            Dim listFirstNonCatCol As Long
            listFirstNonCatCol = DETAIL_COL_LIST_CATEGORY_A + listTplCatCount
            Dim listNonCatColIdx As Long
            For listNonCatColIdx = listFirstNonCatCol To listNoteCol - 1
                listSheet.Columns(listNonCatColIdx + listCatColDiff).ColumnWidth = listSheet.Columns(listNonCatColIdx).ColumnWidth
            Next listNonCatColIdx
        End If
    ElseIf listCatColDiff < 0 Then
        For listColInsertIdx = 1 To Abs(listCatColDiff)
            listRightmostCol = DETAIL_COL_LIST_CATEGORY_A + listTplCatCount - listColInsertIdx
            savedNextColWidthList = listSheet.Columns(listRightmostCol + 1).ColumnWidth
            listSheet.Range(listSheet.Cells(1, listRightmostCol), _
                            listSheet.Cells(DETAIL_ROW_LIST_START, listRightmostCol)).Delete Shift:=xlShiftToLeft
            listSheet.Columns(listRightmostCol).ColumnWidth = savedNextColWidthList
        Next listColInsertIdx
    End If
    If listCatColDiff <> 0 Then
        listNewLastCatCol = DETAIL_COL_LIST_CATEGORY_A + categoryMappings.Count - 1
        If listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_TOTAL).HasFormula Then
            listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_TOTAL).Formula = _
                "=SUM(" & listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_CATEGORY_A).Address(False, False) & _
                ":" & listSheet.Cells(DETAIL_ROW_LIST_START, listNewLastCatCol).Address(False, False) & ")"
        End If
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
    AdjustReviewListCategoryColumns = True
End Function

'=====================================================
' 関数名: AdjustTemplateCategoryColumns
' 機能: SheetTemplateの行7〜11カテゴリ列数を設定シートに合わせて調整する
'       列幅・条件付き書式・SUM式・印刷範囲の更新を含む
' 引数: categoryMappings   - 指摘分類マッピング（Dictionary）
'       tplSumifStartCol   - SUMIF開始列（ByRef、後続処理で使用）
'       catColDiff         - カテゴリ列差分（ByRef、後続処理で使用）
'       actualSumifStart   - 実際のSUMIF開始列（ByRef、後続処理で使用）
'       templateCatCount   - テンプレートの現行カテゴリ列数（ByRef、後続処理で使用）
'       savedHelperWidth   - ヘルパー列幅の保存値（ByRef、後続で復元）
'       savedSumifColWidth - SUMIF列幅の標準値（ByRef、後続で復元）
'=====================================================
Public Sub AdjustTemplateCategoryColumns(categoryMappings As Object, _
    ByRef tplSumifStartCol As Long, ByRef catColDiff As Long, _
    ByRef actualSumifStart As Long, ByRef templateCatCount As Long, _
    ByRef savedHelperWidth As Double, ByRef savedSumifColWidth As Double)
    Dim bkSearchCol As Long
    bkSearchCol = COL_CATEGORY_START
    Do While bkSearchCol <= COL_CATEGORY_START + 50
        If SheetTemplate.Cells(ROW_CATEGORY, bkSearchCol).HasFormula Then
            If Left(SheetTemplate.Cells(ROW_CATEGORY, bkSearchCol).Formula, 5) = "=SUM(" Then Exit Do
        End If
        bkSearchCol = bkSearchCol + 1
    Loop
    templateCatCount = bkSearchCol - COL_CATEGORY_START
    catColDiff = categoryMappings.Count - templateCatCount
    actualSumifStart = COL_CATEGORY_START + templateCatCount + 1
    If actualSumifStart < COL_CATEGORY_HEADER_START Then
        actualSumifStart = COL_CATEGORY_HEADER_START
    End If
    Dim oldTotalCol As Long
    oldTotalCol = COL_CATEGORY_START + templateCatCount
    Dim savedTotalColWidth As Double
    savedTotalColWidth = SheetTemplate.Columns(oldTotalCol).ColumnWidth
    savedSumifColWidth = SheetTemplate.Columns(actualSumifStart).ColumnWidth
    Dim preSumifCount As Long
    preSumifCount = 0
    Do While Len(CStr(SheetTemplate.Cells(DETAIL_START_ROW - 1, actualSumifStart + preSumifCount).Value)) > 0
        preSumifCount = preSumifCount + 1
    Loop
    Dim oldHelperCol As Long
    oldHelperCol = actualSumifStart + preSumifCount
    savedHelperWidth = SheetTemplate.Columns(oldHelperCol).ColumnWidth
    Dim bkInsertIdx As Long
    Dim rightmostBK As Long
    Dim newTotalColBK As Long
    Dim sumRowBK As Long
    Dim savedNextColWidthBK As Double
    If catColDiff > 0 Then
        SheetTemplate.Range( _
            SheetTemplate.Cells(1, actualSumifStart), _
            SheetTemplate.Cells(16, actualSumifStart + catColDiff - 1) _
        ).Insert Shift:=xlShiftToRight
        For bkInsertIdx = 1 To catColDiff
            rightmostBK = COL_CATEGORY_START + templateCatCount + bkInsertIdx - 2
            Application.CutCopyMode = False
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK + 1), SheetTemplate.Cells(11, rightmostBK + 1)).Insert Shift:=xlShiftToRight
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK), SheetTemplate.Cells(11, rightmostBK)).Copy
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK + 1), SheetTemplate.Cells(11, rightmostBK + 1)).PasteSpecial Paste:=xlPasteAll
            Application.CutCopyMode = False
            SheetTemplate.Columns(rightmostBK + 1).ColumnWidth = SheetTemplate.Columns(rightmostBK).ColumnWidth
        Next bkInsertIdx
        If SheetTemplate.Cells(DETAIL_START_ROW, 1).FormatConditions.Count > 0 Then
            SheetTemplate.Cells(DETAIL_START_ROW, 1).FormatConditions(1).ModifyAppliesToRange _
                SheetTemplate.Range( _
                    SheetTemplate.Cells(DETAIL_START_ROW, 1), _
                    SheetTemplate.Cells(DETAIL_START_ROW + 1, COL_CATEGORY_HEADER_START - 1))
        End If
    ElseIf catColDiff < 0 Then
        For bkInsertIdx = 1 To Abs(catColDiff)
            rightmostBK = COL_CATEGORY_START + templateCatCount - bkInsertIdx
            savedNextColWidthBK = SheetTemplate.Columns(rightmostBK + 1).ColumnWidth
            SheetTemplate.Range(SheetTemplate.Cells(7, rightmostBK), SheetTemplate.Cells(11, rightmostBK)).Delete Shift:=xlShiftToLeft
            SheetTemplate.Columns(rightmostBK).ColumnWidth = savedNextColWidthBK
        Next bkInsertIdx
    End If
    Dim clrCol As Long
    Dim clrRow As Long
    Dim clrColStart As Long
    Dim clrColEnd As Long
    clrColStart = COL_CATEGORY_START + categoryMappings.Count + 1
    clrColEnd = COL_CATEGORY_HEADER_START - 1
    If clrColStart <= clrColEnd Then
        For clrCol = clrColStart To clrColEnd
            For clrRow = 7 To 11
                SheetTemplate.Cells(clrRow, clrCol).Interior.ColorIndex = xlNone
            Next clrRow
        Next clrCol
    End If
    If catColDiff <> 0 Then
        SheetTemplate.Columns(COL_CATEGORY_START + categoryMappings.Count).ColumnWidth = savedTotalColWidth
    End If
    If catColDiff <> 0 Then
        newTotalColBK = COL_CATEGORY_START + categoryMappings.Count
        For sumRowBK = 7 To 11
            If SheetTemplate.Cells(sumRowBK, newTotalColBK).HasFormula Then
                SheetTemplate.Cells(sumRowBK, newTotalColBK).Formula = _
                    "=SUM(" & SheetTemplate.Cells(sumRowBK, COL_CATEGORY_START).Address(False, False) & _
                    ":" & SheetTemplate.Cells(sumRowBK, newTotalColBK - 1).Address(False, False) & ")"
            End If
        Next sumRowBK
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
                tplPaRightCol = COL_CATEGORY_HEADER_START - 1
            End If
            SheetTemplate.PageSetup.PrintArea = SheetTemplate.Range( _
                SheetTemplate.Cells(1, 1), _
                SheetTemplate.Cells(tplPaLastRow, tplPaRightCol) _
            ).Address
        End If
    End If
    tplSumifStartCol = actualSumifStart + IIf(catColDiff > 0, catColDiff, 0)
End Sub

'=====================================================
' 関数名: AdjustTemplateSumifColumns
' 機能: SheetTemplateの行14〜16 SUMIFフラグ列数を設定シートに合わせて調整する
' 引数: categoryMappings    - 指摘分類マッピング（Dictionary）
'       tplSumifStartCol    - SUMIF開始列
'       templateSumifCount  - 調整前のSUMIF列数（ByRef、UpdateTemplateHeadersで使用）
'=====================================================
Public Sub AdjustTemplateSumifColumns(categoryMappings As Object, _
    tplSumifStartCol As Long, ByRef templateSumifCount As Long)
    templateSumifCount = 0
    Do While Len(CStr(SheetTemplate.Cells(DETAIL_START_ROW - 1, tplSumifStartCol + templateSumifCount).Value)) > 0
        templateSumifCount = templateSumifCount + 1
    Loop
    Dim sumifColDiff As Long
    sumifColDiff = categoryMappings.Count - templateSumifCount
    Dim ltInsertIdx As Long
    Dim rightmostLT As Long
    If sumifColDiff > 0 Then
        For ltInsertIdx = 1 To sumifColDiff
            rightmostLT = tplSumifStartCol + templateSumifCount + ltInsertIdx - 2
            Application.CutCopyMode = False
            SheetTemplate.Range(SheetTemplate.Cells(1, rightmostLT + 1), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT + 1)).Insert Shift:=xlShiftToRight
            SheetTemplate.Range(SheetTemplate.Cells(DETAIL_START_ROW - 1, rightmostLT), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT)).Copy
            SheetTemplate.Range(SheetTemplate.Cells(DETAIL_START_ROW - 1, rightmostLT + 1), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT + 1)).PasteSpecial Paste:=xlPasteAll
            Application.CutCopyMode = False
        Next ltInsertIdx
    ElseIf sumifColDiff < 0 Then
        For ltInsertIdx = 1 To Abs(sumifColDiff)
            rightmostLT = tplSumifStartCol + templateSumifCount - ltInsertIdx
            SheetTemplate.Range(SheetTemplate.Cells(1, rightmostLT), _
                                 SheetTemplate.Cells(DETAIL_START_ROW + 1, rightmostLT)).Delete Shift:=xlShiftToLeft
        Next ltInsertIdx
    End If
End Sub

'=====================================================
' 関数名: FixTemplateGapAndFormulas
' 機能: ギャップ列削除・SUMIF参照修正・列幅復元を行う
' 引数: categoryMappings   - 指摘分類マッピング（Dictionary）
'       tplSumifStartCol   - SUMIF開始列（ByRef、ギャップ修正後に更新）
'       catColDiff         - カテゴリ列差分
'       actualSumifStart   - 元のSUMIF開始列
'       templateCatCount   - 調整前のカテゴリ列数
'       savedHelperWidth   - ヘルパー列幅の保存値
'       savedSumifColWidth - SUMIF列幅の標準値
'=====================================================
Public Sub FixTemplateGapAndFormulas(categoryMappings As Object, _
    ByRef tplSumifStartCol As Long, catColDiff As Long, _
    actualSumifStart As Long, templateCatCount As Long, _
    savedHelperWidth As Double, savedSumifColWidth As Double)
    If catColDiff > 0 Then
        Dim clrRow14Col As Long
        For clrRow14Col = actualSumifStart To actualSumifStart + catColDiff - 1
            SheetTemplate.Cells(14, clrRow14Col).Interior.ColorIndex = xlNone
        Next clrRow14Col
    End If
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
    If catColDiff > 0 Then
        Dim fixCatIdx As Long
        Dim fixCatCol As Long
        Dim fixSumifCol As Long
        Dim fixRow As Long
        Dim fixColAddr As String
        For fixCatIdx = templateCatCount To categoryMappings.Count - 1
            fixCatCol = COL_CATEGORY_START + fixCatIdx
            fixSumifCol = tplSumifStartCol + fixCatIdx
            fixColAddr = Left(SheetTemplate.Cells(1, fixSumifCol).Address(False, False), _
                              Len(SheetTemplate.Cells(1, fixSumifCol).Address(False, False)) - 1)
            For fixRow = ROW_CATEGORY - 1 To ROW_CATEGORY
                SheetTemplate.Cells(fixRow, fixCatCol).Formula = _
                    "=IF(SUMIF($K15:$K16,$A" & fixRow & "," & _
                    fixColAddr & "15:" & fixColAddr & "16)=0," & _
                    Chr(34) & Chr(34) & ",SUMIF($K15:$K16,$A" & fixRow & "," & _
                    fixColAddr & "15:" & fixColAddr & "16))"
            Next fixRow
        Next fixCatIdx
    End If
    Dim newHelperCol As Long
    newHelperCol = tplSumifStartCol + categoryMappings.Count
    SheetTemplate.Columns(newHelperCol).ColumnWidth = savedHelperWidth
    Dim sumifWidthIdx As Long
    For sumifWidthIdx = tplSumifStartCol To newHelperCol - 1
        SheetTemplate.Columns(sumifWidthIdx).ColumnWidth = savedSumifColWidth
    Next sumifWidthIdx
End Sub

'=====================================================
' 関数名: UpdateTemplateHeaders
' 機能: SheetTemplateの行7/8/14のカテゴリヘッダーを設定シート順に書き換える
' 引数: categoryMappings    - 指摘分類マッピング（Dictionary）
'       tplSumifStartCol    - SUMIF開始列（FixTemplateGapAndFormulas後の確定値）
'       templateSumifCount  - 調整前のSUMIF列数（ヘッダー上書き範囲の算出に使用）
'=====================================================
Public Sub UpdateTemplateHeaders(categoryMappings As Object, _
    tplSumifStartCol As Long, templateSumifCount As Long)
    Dim tplCatHdrKeys As Variant
    tplCatHdrKeys = categoryMappings.Keys
    Dim tplCatHdrVals As Variant
    tplCatHdrVals = categoryMappings.Items
    Dim tplClearHdrCount As Long
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
End Sub

'=====================================================
' 関数名: GetReviewRecordSheets
' 機能: レビュー記録票のヘッダー/サマリー/指摘一覧シートを取得し、転記開始行を特定する
' 引数: book                 - 処理対象ブック
'       target               - 対象設計書名（拡張子除く）
'       count                - レビュー回数
'       mappings             - 項目マッピング設定
'       testMode             - テストモードフラグ
'       postingHeaderOutput  - ヘッダーシート（ByRef）
'       postingSummaryOutput - サマリーシート（ByRef）
'       postingOutput        - 指摘一覧シート（ByRef）
'       postingRow           - 指摘一覧転記行（ByRef）
'       postingSummaryRow    - サマリー転記行（ByRef）
'       postingTemplateRow   - 指摘一覧テンプレート行（ByRef）
' 戻値: Integer（0=成功, 1=ブック未発見=NEXTBOOK, 2=致命的エラー=Exit Sub）
'=====================================================
Public Function GetReviewRecordSheets(book As Workbook, target As String, count As String, _
    ByRef mappings As MappingConfig, testMode As Boolean, _
    ByRef postingHeaderOutput As Worksheet, ByRef postingSummaryOutput As Worksheet, _
    ByRef postingOutput As Worksheet, _
    ByRef postingRow As Integer, ByRef postingSummaryRow As Integer, _
    ByRef postingTemplateRow As Integer) As Integer
    Dim bookTemp As Workbook
    Dim bookTempSelected As Boolean
    bookTempSelected = False
    For Each bookTemp In Application.Workbooks
        If InStr(bookTemp.Name, target) > 0 And InStr(bookTemp.Name, SHT_REVIEW_RECORD) > 0 Then
            bookTempSelected = True
            Exit For
        End If
    Next bookTemp
    If Not bookTempSelected Then
        Module2.ShowMsg testMode, "W01", book.Name & " に対応するレビュー記録票が開いていません。", vbExclamation
        GetReviewRecordSheets = 1
        Exit Function
    End If
    If Not mappings.headerSheet = "" Then
        If Not hasSheet(bookTemp, mappings.headerSheet) Then
            Module2.ShowMsg testMode, "E06", "レビュー記録票に" & mappings.headerSheet & " シートが存在しません。", vbExclamation
            GetReviewRecordSheets = 2
            Exit Function
        End If
        Set postingHeaderOutput = bookTemp.Worksheets(mappings.headerSheet)
    End If
    If Not mappings.summarySheet = "" Then
        If Not hasSheet(bookTemp, mappings.summarySheet) Then
            Module2.ShowMsg testMode, "E06", "レビュー記録票に" & mappings.summarySheet & " シートが存在しません。", vbExclamation
            GetReviewRecordSheets = 2
            Exit Function
        End If
        Set postingSummaryOutput = bookTemp.Worksheets(mappings.summarySheet)
    End If
    If Not mappings.listSheet = "" Then
        If Not hasSheet(bookTemp, mappings.listSheet) Then
            Module2.ShowMsg testMode, "E06", "レビュー記録票に" & mappings.listSheet & " シートが存在しません。", vbExclamation
            GetReviewRecordSheets = 2
            Exit Function
        End If
        Set postingOutput = bookTemp.Worksheets(mappings.listSheet)
    End If
    If Not postingSummaryOutput Is Nothing Then
        For postingSummaryRow = mappings.summaryStartRow To (mappings.summaryStartRow + 100)
            If postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow)).Value = "" Or postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow)).Value = CStr(count) Then
                If count > 1 And Not postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow - 1)).Value = CStr(count - 1) Then
                    Module2.ShowMsg testMode, "E07", "指定されたレビュー回数が正しくありません。", vbExclamation
                    GetReviewRecordSheets = 2
                    Exit Function
                End If
                If postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow)).Value = CStr(count) And Not postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow + 1)).Value = "" Then
                    Module2.ShowMsg testMode, "E07", "指定されたレビュー回数が正しくありません。", vbExclamation
                    GetReviewRecordSheets = 2
                    Exit Function
                End If
                Exit For
            End If
        Next postingSummaryRow
        For postingSummaryRow = mappings.summaryStartRow To (mappings.summaryStartRow + 100)
            If postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow)).Value = "" Or postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow)).Value = CStr(count) Then
                Exit For
            End If
        Next postingSummaryRow
    End If
    If Not postingOutput Is Nothing Then
        For postingRow = mappings.listStartRow To (mappings.listStartRow + 1000)
            If postingOutput.Range(mappings.listCount & CStr(postingRow)).Value = "" Or postingOutput.Range(mappings.listCount & CStr(postingRow)).Value = CStr(count) Then
                Exit For
            End If
        Next postingRow
        For postingTemplateRow = mappings.listStartRow To (mappings.listStartRow + 1000)
            If postingOutput.Range(mappings.listCount & CStr(postingTemplateRow)).Value = "" Then
                Exit For
            End If
        Next postingTemplateRow
    End If
    GetReviewRecordSheets = 0
End Function

'=====================================================
' 関数名: PrepareOutputSheet
' 機能: 対象ブックに出力シートを準備する
'       E13検証（2回目以降のカテゴリ整合性チェック）、既存シート削除、
'       文書ID採番、SheetTemplateコピー、基本情報書込みを行う
' 引数: book             - 処理対象ブック
'       count            - レビュー回数
'       categoryMappings - 指摘分類マッピング（Dictionary）
'       isCopyReviewList - 一覧反映フラグ
'       listSheet        - レビュー記録一覧シート（docId採番に使用）
'       testMode         - テストモードフラグ
'       docId            - 文書ID（ByRef、採番結果を返す）
'       preDocId         - 前回文書ID（ByRef）
'       isOverwrite      - 上書きフラグ（ByRef）
' 戻値: Worksheet（成功時）、Nothing（エラー時）
'=====================================================
Public Function PrepareOutputSheet(book As Workbook, count As String, _
    categoryMappings As Object, isCopyReviewList As Boolean, _
    listSheet As Worksheet, testMode As Boolean, _
    ByRef docId As String, ByRef preDocId As String, _
    ByRef isOverwrite As Boolean) As Worksheet
    Dim outputSheetName As String
    Dim target As String
    target = Mid(book.Name, 1, InStrRev(book.Name, ".") - 1)
    outputSheetName = OUTPUT_SHEETNAME_PREFIX & CStr(count) & OUTPUT_SHEETNAME_SUFFIX
    If CLng(count) >= 2 Then
        Dim firstResultName As String
        firstResultName = OUTPUT_SHEETNAME_PREFIX & "1" & OUTPUT_SHEETNAME_SUFFIX
        If hasSheet(book, firstResultName) Then
            Dim currentKeys As String
            currentKeys = ""
            Dim catKey As Variant
            For Each catKey In categoryMappings.Keys
                If Len(currentKeys) > 0 Then currentKeys = currentKeys & ","
                currentKeys = currentKeys & CStr(catKey)
            Next catKey
            Dim existCatStr As String
            existCatStr = ""
            Dim chkCol As Long
            For chkCol = COL_CATEGORY_START To COL_CATEGORY_START + 50
                Dim chkVal As String
                chkVal = CStr(book.Worksheets(firstResultName).Cells(7, chkCol).Value)
                If Len(chkVal) = 0 Then Exit For
                If Len(existCatStr) > 0 Then existCatStr = existCatStr & ","
                existCatStr = existCatStr & chkVal
            Next chkCol
            If Len(existCatStr) > 0 And existCatStr <> currentKeys Then
                Module2.ShowMsg testMode, "E13", _
                    "カテゴリ設定が変更されました。" & _
                    "既存のレビュー結果シートのカテゴリ構造と不整合になるため、処理を中断します。" & _
                    "【対処方法】1. 設計書Excelの既存のレビュー結果シート（全て）を削除 2. 1回目のレビューから実行をやり直す", vbExclamation
                Set PrepareOutputSheet = Nothing
                Exit Function
            End If
        End If
    End If
    preDocId = ""
    isOverwrite = False
    If hasSheet(book, outputSheetName) = True Then
        isOverwrite = True
        docId = book.Worksheets(outputSheetName).Cells(ROW_DOC_ID, COL_DOC_ID).Value
        Application.DisplayAlerts = False
        book.Worksheets(outputSheetName).Delete
        Application.DisplayAlerts = True
    Else
        If count = 1 Then
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
            If hasSheet(book, OUTPUT_SHEETNAME_PREFIX & "1" & OUTPUT_SHEETNAME_SUFFIX) = True Then
                docId = book.Worksheets(OUTPUT_SHEETNAME_PREFIX & "1" & OUTPUT_SHEETNAME_SUFFIX).Cells(ROW_DOC_ID, COL_DOC_ID).Value
            End If
        End If
    End If
    SheetTemplate.Copy before:=book.Worksheets(1)
    book.Worksheets(1).Name = outputSheetName
    Dim output As Worksheet
    Set output = book.Worksheets(outputSheetName)
    output.Cells(ROW_DOC_ID, COL_DOC_ID) = docId
    output.Cells(ROW_TARGET, COL_TARGET) = target
    output.Cells(ROW_COUNT, COL_COUNT) = count
    If hasSheet(book, OUTPUT_ERR_SHEETNAME) = True Then
        Application.DisplayAlerts = False
        book.Worksheets(OUTPUT_ERR_SHEETNAME).Delete
        Application.DisplayAlerts = True
    End If
    Set PrepareOutputSheet = output
End Function

'=====================================================
' 関数名: ExtractReviewComments
' 機能: 対象ブック全シートのコメントを走査し、レビュー指摘を出力シートに書き込む
'       「*」コメント（日時情報）と指摘コメントを判別して処理する
'       useReviewRecord=Trueの場合はレビュー記録票への転記も行う
'=====================================================
Public Sub ExtractReviewComments(book As Workbook, output As Worksheet, _
    categoryMappings As Object, ByRef settings As BasicSettings, _
    ByRef mappings As MappingConfig, _
    count As String, testMode As Boolean, isOverwrite As Boolean, _
    postingHeaderOutput As Worksheet, postingSummaryOutput As Worksheet, postingOutput As Worksheet, _
    ByRef postingRow As Integer, ByRef postingSummaryRow As Integer, ByRef postingTemplateRow As Integer, _
    ByRef errcount As Integer, _
    ByRef reviewDate As String, ByRef reviewStartTime As String, _
    ByRef reviewEndTime As String, ByRef reviewTime As String)
    Dim row As Integer
    row = DETAIL_START_ROW
    Dim s As Worksheet
    Dim cmnt As Comment
    Dim cc As Variant
    Dim err_output As Worksheet
    Dim work As Variant
    Dim cmntCell As Range
    Dim workCommentCells As New Collection
    Dim workCommentCell(2) As String
    Dim err_row As Long
    errcount = 0
    Application.ScreenUpdating = False
    If isOverwrite And settings.useReviewRecord And Not postingOutput Is Nothing And Len(mappings.listCount) > 0 Then
        Dim clearRow As Long
        Dim clearLastRow As Long
        clearLastRow = postingOutput.Cells(postingOutput.Rows.Count, 1).End(xlUp).Row
        For clearRow = clearLastRow To mappings.listStartRow Step -1
            If CStr(postingOutput.Range(mappings.listCount & CStr(clearRow)).Value) = CStr(count) Then
                postingOutput.Rows(clearRow).Delete
            End If
        Next clearRow
        postingRow = mappings.listStartRow
        Do While CStr(postingOutput.Range(mappings.listCount & CStr(postingRow)).Value) <> ""
            postingRow = postingRow + 1
        Loop
        postingTemplateRow = postingRow
    End If
    If settings.useReviewRecord Then
        If Not postingSummaryOutput Is Nothing Then
            If postingSummaryOutput.Range("A" & CStr(postingSummaryRow)) = "" Then
                postingSummaryOutput.Rows(postingSummaryRow).Copy
                postingSummaryOutput.Rows(postingSummaryRow + 1).Insert
            End If
            If Len(mappings.summaryCount) > 0 Then
                postingSummaryOutput.Range(mappings.summaryCount & CStr(postingSummaryRow)) = CStr(count)
            End If
        End If
        If Not postingHeaderOutput Is Nothing Then
            If Len(mappings.headerCount) > 0 Then
                postingHeaderOutput.Range(mappings.headerCount) = CStr(count)
            End If
        End If
    End If
    Dim reviewee As String
    reviewee = Range(IDX_REVIEW_LIST_REVIEWEE).Value
    If Len(reviewee) = 0 Then
        Dim reviewListRevieweeSheet As String
        Dim reviewListRevieweeCell As String
        reviewListRevieweeSheet = Range(IDX_REVIEW_LIST_REVIEWEE_SHEET).Value
        reviewListRevieweeCell = Range(IDX_REVIEW_LIST_REVIEWEE_CELL).Value
        If checkReference(book, reviewListRevieweeSheet, reviewListRevieweeCell) Then
            reviewee = book.Worksheets(reviewListRevieweeSheet).Range(reviewListRevieweeCell).Value
        End If
    End If
    Dim reviewer As String
    Dim category As String
    Dim reviewCommentTemp As String
    Dim isFixed As Boolean
    Dim closeLine As String
    Dim rc() As String
    Dim reviewComment As String
    Dim replyComment As String
    Dim position As String
    For Each s In book.Worksheets
        For Each cmnt In s.comments
            Dim commentText As String
            commentText = cmnt.Text
            If InStr(1, StrConv(commentText, vbNarrow), ":") >= 1 And InStr(1, commentText, vbLf) >= 1 Then
                reviewer = Left(commentText, InStr(1, StrConv(commentText, vbNarrow), ":") - 1)
                category = ExtractCategory(commentText)
                If category <> "" Then
                    If GetLastChar(commentText) = "済" Then
                        isFixed = True
                    Else
                        isFixed = False
                    End If
                    closeLine = extractCloseLine(commentText)
                    If category = "*" Then
                        work = Split(commentText, vbLf)
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
                            Else
                                reviewDate = work(1)
                                reviewStartTime = work(2)
                                reviewEndTime = work(3)
                                reviewTime = work(4)
                            End If
                            output.Cells(ROW_DATE, COL_DATE) = reviewDate
                            output.Cells(ROW_START, COL_START) = reviewStartTime
                            output.Cells(ROW_END, COL_END) = reviewEndTime
                            output.Cells(ROW_BREAK, COL_BREAK) = reviewTime
                            If settings.useReviewRecord Then
                                If Not postingHeaderOutput Is Nothing Then
                                    If Len(mappings.headerDate) > 0 Then
                                        postingHeaderOutput.Range(mappings.headerDate) = reviewDate
                                    End If
                                    If Len(mappings.headerStartTime) > 0 Then
                                        postingHeaderOutput.Range(mappings.headerStartTime) = reviewStartTime
                                    End If
                                    If Len(mappings.headerEndTime) > 0 Then
                                        postingHeaderOutput.Range(mappings.headerEndTime) = reviewEndTime
                                    End If
                                    If Len(mappings.headerStartDateTime) > 0 Then
                                        postingHeaderOutput.Range(mappings.headerStartDateTime) = reviewDate & " " & reviewStartTime
                                    End If
                                    If Len(mappings.headerEndDateTime) > 0 Then
                                        postingHeaderOutput.Range(mappings.headerEndDateTime) = reviewDate & " " & reviewEndTime
                                    End If
                                    If Len(mappings.headerReviewTime) > 0 Then
                                        postingHeaderOutput.Range(mappings.headerReviewTime) = reviewTime
                                    End If
                                End If
                                If Not postingSummaryOutput Is Nothing Then
                                    If Len(mappings.summaryDate) > 0 Then
                                        postingSummaryOutput.Range(mappings.summaryDate & CStr(postingSummaryRow)) = reviewDate
                                    End If
                                    If Len(mappings.summaryStartTime) > 0 Then
                                        postingSummaryOutput.Range(mappings.summaryStartTime & CStr(postingSummaryRow)) = reviewStartTime
                                    End If
                                    If Len(mappings.summaryEndTime) > 0 Then
                                        postingSummaryOutput.Range(mappings.summaryEndTime & CStr(postingSummaryRow)) = reviewEndTime
                                    End If
                                    If Len(mappings.summaryStartDateTime) > 0 Then
                                        postingSummaryOutput.Range(mappings.summaryStartDateTime & CStr(postingSummaryRow)) = reviewDate & " " & reviewStartTime
                                    End If
                                    If Len(mappings.summaryEndDateTime) > 0 Then
                                        postingSummaryOutput.Range(mappings.summaryEndDateTime & CStr(postingSummaryRow)) = reviewDate & " " & reviewEndTime
                                    End If
                                    If Len(mappings.summaryReviewTime) > 0 Then
                                        postingSummaryOutput.Range(mappings.summaryReviewTime & CStr(postingSummaryRow)) = reviewTime
                                    End If
                                End If
                            End If
                        Else
                            If errcount = 0 Then
                                ErrorSheetTemplate.Copy before:=book.Worksheets(1)
                                book.Worksheets(1).Name = OUTPUT_ERR_SHEETNAME
                                Set err_output = book.Worksheets(OUTPUT_ERR_SHEETNAME)
                            End If
                            err_row = err_output.Cells(Application.Rows.Count, 1).End(xlUp).Row + 1
                            err_output.Cells(err_row, 1) = "レビュー日時コメントが正しく入力されていません｡実施日、開始時刻、終了時刻、レビュー時間を全て入力してください。"
                            err_output.Hyperlinks.Add err_output.Cells(err_row, 2), "", "'" & s.Name & "'" & "!" & CStr(cmnt.Parent.Address)
                            errcount = errcount + 1
                        End If
                    ElseIf IsValidCategory(category, categoryMappings) Then
                        If CbAdjustCmntPos.Value = True Then
                            workCommentCell(1) = cmnt.Parent.Address
                            workCommentCell(2) = commentText
                            workCommentCells.Add workCommentCell
                        End If
                        If settings.useReviewRecord And Not postingOutput Is Nothing Then
                            If postingOutput.Range(mappings.listCount & CStr(postingRow)).Value = "" Then
                                postingOutput.Rows(postingTemplateRow).Copy
                                postingOutput.Rows(postingRow + 1).Insert
                                postingTemplateRow = postingTemplateRow + 1
                            End If
                        End If
                        Application.CutCopyMode = False
                        output.Range(CStr(row + 1) & ":" & CStr(row + 1)).Insert
                        output.Range(CStr(row + 2) & ":" & CStr(row + 2)).Copy Destination:=output.Range(CStr(row + 1) & ":" & CStr(row + 1))
                        reviewCommentTemp = Mid(commentText, InStr(1, commentText, vbLf) + 1)
                        rc() = splitComment(reviewCommentTemp)
                        reviewComment = rc(1) & vbCrLf
                        replyComment = rc(2) & vbCrLf
                        position = CStr(cmnt.Parent.Address)
                        output.Cells(row, DETAIL_COL_SHEET) = s.Name
                        output.Cells(row, DETAIL_COL_POSITION) = Replace(position, "$", "")
                        output.Hyperlinks.Add output.Cells(row, DETAIL_COL_POSITION), "", "'" & s.Name & "'" & "!" & position
                        output.Cells(row, DETAIL_COL_REVIEWER) = reviewer
                        output.Cells(row, DETAIL_COL_CATEGORY) = category
                        output.Cells(row, DETAIL_COL_REVIEW_COMMENT) = reviewCommentTemp
                        If isFixed = True Then
                            output.Cells(row, DETAIL_COL_FIX_STATUS) = "済"
                        Else
                            output.Cells(row, DETAIL_COL_FIX_STATUS) = "未"
                        End If
                        If settings.useReviewRecord And Not postingOutput Is Nothing Then
                            If Len(mappings.listCount) > 0 Then
                                postingOutput.Range(mappings.listCount & CStr(postingRow)).Value = CStr(count)
                            End If
                            If Len(mappings.listReviewer) > 0 Then
                                postingOutput.Range(mappings.listReviewer & CStr(postingRow)).Value = reviewer
                            End If
                            If Len(mappings.listCategory) > 0 Then
                                postingOutput.Range(mappings.listCategory & CStr(postingRow)).Value = categoryMappings.item(category)
                            End If
                            If Len(mappings.listComment) > 0 Then
                                postingOutput.Range(mappings.listComment & CStr(postingRow)).Value = reviewComment
                            End If
                            If Len(mappings.listReply) > 0 Then
                                postingOutput.Range(mappings.listReply & CStr(postingRow)).Value = replyComment
                            End If
                            If Len(mappings.listReviewee) > 0 Then
                                postingOutput.Range(mappings.listReviewee & CStr(postingRow)).Value = reviewee
                            End If
                            If isFixed = True Then
                                If Len(mappings.listCloseLine) > 0 Then
                                    postingOutput.Range(mappings.listCloseLine & CStr(postingRow)).Value = closeLine
                                End If
                            Else
                                If Len(mappings.listCloseLine) > 0 Then
                                    postingOutput.Range(mappings.listCloseLine & CStr(postingRow)).Value = ""
                                End If
                            End If
                            postingOutput.Rows(postingRow).AutoFit
                        End If
                        output.Rows(CStr(row) & ":" & CStr(row)).AutoFit
                        row = row + 1
                        postingRow = postingRow + 1
                    Else
                        If errcount = 0 Then
                            ErrorSheetTemplate.Copy before:=book.Worksheets(1)
                            book.Worksheets(1).Name = OUTPUT_ERR_SHEETNAME
                            Set err_output = book.Worksheets(OUTPUT_ERR_SHEETNAME)
                        End If
                        err_row = err_output.Cells(Application.Rows.Count, 1).End(xlUp).Row + 1
                        err_output.Cells(err_row, 1) = "未登録の指摘分類エイリアスが記入されています: " & category
                        err_output.Hyperlinks.Add err_output.Cells(err_row, 2), "", "'" & s.Name & "'" & "!" & CStr(cmnt.Parent.Address)
                        errcount = errcount + 1
                    End If
                End If
            End If
        Next cmnt
        If CbAdjustCmntPos.Value = True Then
            For Each cc In workCommentCells
                s.Range(cc(1)).ClearComments
                s.Range(cc(1)).AddComment cc(2)
                s.Range(cc(1)).comment.Shape.TextFrame.AutoSize = True
            Next cc
            Set workCommentCells = New Collection
        End If
    Next s
    output.Range(CStr(row + 1) & ":" & CStr(row + 1)).Delete
    Application.ScreenUpdating = True
End Sub

'=====================================================
' 関数名: WriteToReviewList
' 機能: レビュー記録一覧への1行反映を行う
'       工程/レビュア/レビュイ値の取得（ByRef出力）も担当する
'=====================================================
Public Sub WriteToReviewList(listSheet As Worksheet, output As Worksheet, _
    count As String, docId As String, preDocId As String, _
    useSimpleSummary As Boolean, volume As Long, reviewResult As String, _
    reviewListPhase As String, reviewListPhaseSheet As String, reviewListPhaseCell As String, _
    reviewListReviewer As String, reviewListReviewerSheet As String, reviewListReviewerCell As String, _
    reviewListReviewee As String, reviewListRevieweeSheet As String, reviewListRevieweeCell As String, _
    categoryMappings As Object, testMode As Boolean, book As Workbook, errcount As Integer, _
    ByRef phase As String, ByRef listReviewer As String, ByRef listReviewee As String)
    Dim existSameDocIdAndCount As Boolean
    Dim docIdRng As Range
    Dim firstAddress As String
    existSameDocIdAndCount = False
    Dim listRow As Long
    If useSimpleSummary Then
        With listSheet.Cells(DETAIL_ROW_LIST_START, DETAIL_COL_LIST_DOC_ID).EntireColumn
            Set docIdRng = .Find(what:=docId)
            If Not docIdRng Is Nothing Then
                firstAddress = docIdRng.Address
                Do
                    If listSheet.Cells(docIdRng.Row, DETAIL_COL_LIST_COUNT).Value = count Then
                        existSameDocIdAndCount = True
                        listRow = docIdRng.Row
                    End If
                    If listSheet.Cells(docIdRng.Row, DETAIL_COL_LIST_COUNT).Value = (count - 1) Then
                        preDocId = listSheet.Cells(docIdRng.Row, DETAIL_COL_LIST_NO).Value
                    End If
                    Set docIdRng = .FindNext(docIdRng)
                    If docIdRng Is Nothing Then Exit Do
                Loop Until docIdRng.Address = firstAddress
            End If
        End With
    End If
    If useSimpleSummary And existSameDocIdAndCount = False Then
        listSheet.Activate
        listRow = listSheet.Cells(Application.Rows.Count, 3).End(xlUp).Row + 1
        If Len(listSheet.Cells(listRow, 1).Value) = 0 Then
            listSheet.Cells(listRow - 1, 1).EntireRow.Copy
            listSheet.Cells(listRow, 1).Insert
            Application.CutCopyMode = False
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
    phase = reviewListPhase
    If Len(phase) = 0 Then
        If checkReference(book, reviewListPhaseSheet, reviewListPhaseCell) Then
            phase = book.Worksheets(reviewListPhaseSheet).Range(reviewListPhaseCell).Value
        Else
            Module2.ShowMsg testMode, "W02", """工程""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
            phase = "取得できませんでした"
        End If
    End If
    listReviewer = reviewListReviewer
    If Len(listReviewer) = 0 Then
        If checkReference(book, reviewListReviewerSheet, reviewListReviewerCell) Then
            listReviewer = book.Worksheets(reviewListReviewerSheet).Range(reviewListReviewerCell).Value
        Else
            Module2.ShowMsg testMode, "W03", """レビュア""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
            listReviewer = "取得できませんでした"
        End If
    End If
    listReviewee = reviewListReviewee
    If Len(listReviewee) = 0 Then
        If checkReference(book, reviewListRevieweeSheet, reviewListRevieweeCell) Then
            listReviewee = book.Worksheets(reviewListRevieweeSheet).Range(reviewListRevieweeCell).Value
        Else
            Module2.ShowMsg testMode, "W04", """作成者・レビュイ""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
            listReviewee = "取得できませんでした"
        End If
    End If
    If useSimpleSummary Then
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
End Sub

'=====================================================
' 関数名: WriteToReviewRecordHeader
' 機能: レビュー記録票ヘッダーシートへ工程/ページ数/レビュア/レビュイを転記する
'=====================================================
Public Sub WriteToReviewRecordHeader(postingHeaderOutput As Worksheet, _
    ByRef mappings As MappingConfig, count As String, _
    phase As String, volume As Long, listReviewer As String, listReviewee As String)
    If postingHeaderOutput Is Nothing Then Exit Sub
    If Len(mappings.headerPhase) > 0 Then
        postingHeaderOutput.Range(mappings.headerPhase).Value = phase
    End If
    If Len(mappings.headerVolume) > 0 Then
        postingHeaderOutput.Range(mappings.headerVolume).Value = zeroToNull(volume)
    End If
    If Len(mappings.headerReviewer) > 0 Then
        postingHeaderOutput.Range(mappings.headerReviewer).Value = listReviewer
    End If
    If Len(mappings.headerReviewee) > 0 Then
        postingHeaderOutput.Range(mappings.headerReviewee).Value = listReviewee
    End If
End Sub

'=====================================================
' 関数名: WriteToReviewRecordSummary
' 機能: レビュー記録票サマリーシートへ工程/ページ数/レビュア/レビュイを転記する
'=====================================================
Public Sub WriteToReviewRecordSummary(postingSummaryOutput As Worksheet, _
    ByRef mappings As MappingConfig, count As String, _
    phase As String, volume As Long, listReviewer As String, listReviewee As String, _
    postingSummaryRow As Integer)
    If postingSummaryOutput Is Nothing Then Exit Sub
    If Len(mappings.summaryPhase) > 0 Then
        postingSummaryOutput.Range(mappings.summaryPhase & CStr(postingSummaryRow)).Value = phase
    End If
    If Len(mappings.summaryVolume) > 0 Then
        postingSummaryOutput.Range(mappings.summaryVolume & CStr(postingSummaryRow)).Value = zeroToNull(volume)
    End If
    If Len(mappings.summaryReviewer) > 0 Then
        postingSummaryOutput.Range(mappings.summaryReviewer & CStr(postingSummaryRow)).Value = listReviewer
    End If
    If Len(mappings.summaryReviewee) > 0 Then
        postingSummaryOutput.Range(mappings.summaryReviewee & CStr(postingSummaryRow)).Value = listReviewee
    End If
End Sub

'=====================================================
' 関数名: CalcPageVolume
' 機能: ブック内ワークシートのページ数合計を算出する
'       出力シートおよびエラーシートは除外する
'       取得失敗時は0を返す
' 引数: book - 対象ブック
' 戻値: Long（ページ数合計）
'=====================================================
Public Function CalcPageVolume(book As Workbook) As Long
    Dim volume As Long
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
    CalcPageVolume = volume
End Function

'=====================================================
' 関数名: DetermineReviewResult
' 機能: 条件付合格判定ロジック
'       CbConditional=Trueの場合に指摘件数と条件を照合して「条件付合格」を返す
' 引数: output           - 出力シート（カテゴリ集計行を参照）
'       categoryMappings - 指摘分類マッピング（Dictionary）
'       errcount         - エラー件数
' 戻値: String（"条件付合格" または ""）
'=====================================================
Public Function DetermineReviewResult(output As Worksheet, _
    categoryMappings As Object, errcount As Integer) As String
    Dim reviewResult As String
    reviewResult = ""
    If CbConditional = True Then
        Dim categoryList As Variant
        Dim categoryIdx As Long
        Dim categoryCount As Long
        categoryList = categoryMappings.Keys
        categoryCount = 0
        For categoryIdx = 0 To UBound(categoryList)
            If nullToZero(output.Cells(ROW_CATEGORY, COL_CATEGORY_START + categoryIdx).Value) > 0 Then
                categoryCount = categoryCount + 1
                If Range(IDX_CONDITIONAL_CATEGORY).Value = categoryList(categoryIdx) Then
                    If (nullToZero(output.Cells(ROW_CATEGORY, COL_CATEGORY_START + categoryIdx).Value) <= Range(IDX_CONDITIONAL_COUNT).Value And errcount = 0) Then
                        reviewResult = "条件付合格"
                    End If
                Else
                    reviewResult = ""
                    Exit For
                End If
            End If
        Next categoryIdx
    End If
    DetermineReviewResult = reviewResult
End Function

Function GetLastChar(str As String)
    Dim work As String
    work = Replace(str, " ", "")
    work = Replace(work, "　", "")
    work = Replace(work, vbTab, "")
    work = Replace(work, vbCr, "")
    work = Replace(work, vbLf, "")
    GetLastChar = Right(work, 1)
End Function
