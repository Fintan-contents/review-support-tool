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
    On Error GoTo ERROR
    Application.Cursor = xlWait
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
    reviewListFilepath = Range(IDX_REVIEW_LIST_FILEPATH).Value
    If useSimpleSummary And Len(reviewListFilepath) = 0 Then
        isCopyReviewList = False
        MsgBox "レビュー記録一覧のファイルパスが未入力です。", vbExclamation
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
            MsgBox "一覧への反映値が未入力です。固定値または、成果物のシート名とセルのどちらかを指定してください。", vbExclamation
            Application.ScreenUpdating = True
            Application.Cursor = xlDefault
            Exit Sub
        End If
        If useSimpleSummary Then
            reviewListSheet = Range(IDX_REVIEW_LIST_SHEET).Value
            If Len(reviewListSheet) = 0 Then
                MsgBox "レビュー記録一覧のシート名が未入力です。", vbExclamation
                Application.ScreenUpdating = True
                Application.Cursor = xlDefault
                Exit Sub
            End If
            isCopyReviewList = True
            'レビュー一覧を既に開いているかどうか
            reviewListFileNm = Dir(reviewListFilepath)
            If Len(reviewListFileNm) = 0 Then
                MsgBox "レビュー記録一覧ファイルが存在しません。", vbExclamation
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
                        If MsgBox("レビュー記録一覧を一旦閉じて開き直します。編集中の内容は保存されます。" & vbCrLf & "処理を続行してよろしいですか？", vbYesNo, vbInformation) = vbNo Then
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
                MsgBox "レビュー記録一覧ファイルに指定されたシートが存在しません。", vbExclamation
                Application.ScreenUpdating = True
                Application.Cursor = xlDefault
                Exit Sub
            End If
            Set listSheet = reviewListBook.Worksheets(Range(IDX_REVIEW_LIST_SHEET).Value)
        End If
    End If
    '------------------
    ' 抽出処理
    '------------------
    '開いている全ブックを確認
    For Each book In Application.Workbooks
        'ファイル名に正規表現パターンマッチを行い対象ファイルを抽出
        If targetBookNamePattern.test(book.Name) And Not noTargetBookNamePattern.test(book.Name) Then
            '処理実施確認
            res = MsgBox(book.Name & "のレビュー内容を抽出しますか？", vbYesNoCancel, 確認)
            If res = vbCancel Then
                MsgBox "以降の処理を中止します。" 'それまでの処理をキャンセルはできないので「以降の処理を中止」
                Exit For
            ElseIf res = vbNo Then
                '処理スキップ
                GoTo NEXTBOOK
            Else
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
                        MsgBox book.Name & " に対応するレビュー記録票が開いていません。", vbExclamation
                        Application.ScreenUpdating = True
                        Application.Cursor = xlDefault
                        GoTo NEXTBOOK
                    End If
                    '転記先シートの取得
                    If Not mappingHeaderSheet = "" Then
                        If Not hasSheet(bookTemp, mappingHeaderSheet) Then
                            MsgBox "レビュー記録票に" & mappingHeaderSheet & " シートが存在しません。", vbExclamation
                            Application.ScreenUpdating = True
                            Application.Cursor = xlDefault
                            Exit Sub
                        End If
                        Set postingHeaderOutput = bookTemp.Worksheets(mappingHeaderSheet)
                    End If
                    If Not mappingSummarySheet = "" Then
                        If Not hasSheet(bookTemp, mappingSummarySheet) Then
                            MsgBox "レビュー記録票に" & mappingSummarySheet & " シートが存在しません。", vbExclamation
                            Application.ScreenUpdating = True
                            Application.Cursor = xlDefault
                            Exit Sub
                        End If
                        Set postingSummaryOutput = bookTemp.Worksheets(mappingSummarySheet)
                    End If
                    If Not mappingListSheet = "" Then
                        If Not hasSheet(bookTemp, mappingListSheet) Then
                            MsgBox "レビュー記録票に" & mappingListSheet & " シートが存在しません。", vbExclamation
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
                                    MsgBox "指定されたレビュー回数が正しくありません。", vbExclamation
                                    Application.ScreenUpdating = True
                                    Application.Cursor = xlDefault
                                    Exit Sub
                                End If
                                If postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value = CStr(count) And Not postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow + 1)).Value = "" Then
                                    MsgBox "指定されたレビュー回数が正しくありません。", vbExclamation
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
                            ':の直後の1文字を取得して、カテゴリとする。
                            category = StrConv(Mid(commentText, InStr(1, StrConv(commentText, vbNarrow), ":") + 1, 1), vbNarrow)
                            'カテゴリがない(:直後が改行の)場合は処理しない
                            If category <> vbLf Then
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
                                ElseIf "a" <= category And category <= "i" Then
                                    'a～iが指定されていればレビューコメント
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
                                    err_output.Cells(err_row, 1) = "指摘分類エイリアスにa～i以外が記入されています。"
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
                    MsgBox """工程""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
                    phase = "取得できませんでした"
                End If
            End If
            'レビュア
            listReviewer = Range(IDX_REVIEW_LIST_REVIEWER).Value
            If Len(listReviewer) = 0 Then
                If checkReference(book, reviewListReviewerSheet, reviewListReviewerCell) Then
                    listReviewer = book.Worksheets(reviewListReviewerSheet).Range(reviewListReviewerCell).Value
                Else
                    MsgBox """レビュア""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
                    listReviewer = "取得できませんでした"
                End If
            End If
            'レビュイ
            listReviewee = Range(IDX_REVIEW_LIST_REVIEWEE).Value
            If Len(listReviewee) = 0 Then
                If checkReference(book, reviewListRevieweeSheet, reviewListRevieweeCell) Then
                    listReviewee = book.Worksheets(reviewListRevieweeSheet).Range(reviewListRevieweeCell).Value
                Else
                    MsgBox """作成者・レビュイ""を成果物から取得できません。指定したシート名、セルを確認してください。抽出処理は続行します。"
                    listReviewee = "取得できませんでした"
                End If
            End If
            'レビュー結果 - 条件付合格判定
            reviewResult = ""
            If CbConditional = True Then
                Dim categoryList As Variant
                Dim categoryIdx As Long
                Dim categoryCount As Long
                categoryList = Array("a", "b", "c", "d", "e", "f", "g", "h", "i")
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
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_A) = zeroToNull(output.Cells(ROW_CATEGORY, 2).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_B) = zeroToNull(output.Cells(ROW_CATEGORY, 3).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_C) = zeroToNull(output.Cells(ROW_CATEGORY, 4).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_D) = zeroToNull(output.Cells(ROW_CATEGORY, 5).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_E) = zeroToNull(output.Cells(ROW_CATEGORY, 6).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_F) = zeroToNull(output.Cells(ROW_CATEGORY, 7).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_G) = zeroToNull(output.Cells(ROW_CATEGORY, 8).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_H) = zeroToNull(output.Cells(ROW_CATEGORY, 9).Value)
                listSheet.Cells(listRow, DETAIL_COL_LIST_CATEGORY_I) = zeroToNull(output.Cells(ROW_CATEGORY, 10).Value)
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
        MsgBox "レビュー対象文書が見つかりません。", vbExclamation, "エラー"
    Else
        MsgBox "レビュー結果の抽出が完了しました。" & vbCrLf & vbCrLf & "処理ファイル数:" & fileCount & "件", vbInformation
    End If
    Exit Sub
ERROR:
    MsgBox "処理中にエラーが発生しました。" & Err.Number & vbCrLf & vbCrLf & Err.Description, vbError
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
