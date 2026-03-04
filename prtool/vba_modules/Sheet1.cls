- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
'位置情報
Const IDX_REVIEW_LIST_FILEPATH = "REVIEW_LIST_FILEPATH"
Const IDX_REVIEW_LIST_PHASE = "REVIEW_LIST_PHASE"
Const IDX_REVIEW_LIST_REVIEWER = "REVIEW_LIST_REVIEWER"
Const IDX_REVIEW_LIST_REVIEWEE = "REVIEW_LIST_REVIEWEE"
Private Sub CbAdjustCmntPos_Click()
End Sub
Private Sub CheckBox1_Click()
End Sub
'抽出ボタンクリック
Private Sub CmdGen_Click()
    On Error GoTo ERROR
    Application.Cursor = xlWait
    Application.ScreenUpdating = False
    Dim row As Integer
    Dim output As Worksheet
    Dim fileCount As Integer
    Dim book As Workbook
    Dim outputSheetName As String
    Dim docId As String, Target As String, count As String, defaultReviewer As String, category As String, reviewComment As String, position As String, replyComment As String, reviewCommentTemp As String
    Dim preDocId As String
    Dim docIdSuffix As String
    Dim isFixed As Boolean
    Dim delimiterIndex As Integer
    Dim reviewDate As String, reviewStartTime As String, reviewEndTime As String, reviewOrBreakTime As String
    Dim closeLine As String
    Dim additions As Integer, deletions As Integer
    Dim reviewListPhase As String
    Dim reviewListReviewer As String
    Dim reviewListReviewee As String
    '転記先のレビュー記録票
    Dim postingHeaderOutput As Worksheet, postingSummaryOutput As Worksheet, postingOutput As Worksheet
    'レビュー記録票の書き出し行
    Dim postingRow As Integer, postingSummaryRow As Integer
    'レビュー記録票のテンプレート行（コピー元）
    Dim postingTemplateRow As Integer
    Dim defaultCloseLine As String
    defaultCloseLine = Range("CLOSE_LINE").Value
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
        '(ヘッダー)レビュー日付
        Dim mappingHeaderDate As String: mappingHeaderDate = .Cells(9, 2).Value & CStr(.Cells(9, 3).Value)
        '(ヘッダー)レビュー開始時刻
        Dim mappingHeaderStartTime As String: mappingHeaderStartTime = .Cells(10, 2).Value & CStr(.Cells(10, 3).Value)
        '(ヘッダー)レビュー終了時刻
        Dim mappingHeaderEndTime As String: mappingHeaderEndTime = .Cells(11, 2).Value & CStr(.Cells(11, 3).Value)
        '(ヘッダー)レビュー開始日時
        Dim mappingHeaderStartDateTime As String: mappingHeaderStartDateTime = .Cells(12, 2).Value & CStr(.Cells(12, 3).Value)
        '(ヘッダー)レビュー終了日時
        Dim mappingHeaderEndDateTime As String: mappingHeaderEndDateTime = .Cells(13, 2).Value & CStr(.Cells(13, 3).Value)
        '(ヘッダー)レビュー時間
        Dim mappingHeaderReviewOrBreakTime As String: mappingHeaderReviewOrBreakTime = .Cells(14, 2).Value & CStr(.Cells(14, 3).Value)
        '(ヘッダー)レビュア
        Dim mappingHeaderReviewer As String: mappingHeaderReviewer = .Cells(15, 2).Value & CStr(.Cells(15, 3).Value)
        '(ヘッダー)レビュイ
        Dim mappingHeaderReviewee As String: mappingHeaderReviewee = .Cells(16, 2).Value & CStr(.Cells(16, 3).Value)
        '(ヘッダー)ソース追加行数
        Dim mappingHeaderAdditions As String: mappingHeaderAdditions = .Cells(17, 2).Value & CStr(.Cells(17, 3).Value)
        '(ヘッダー)ソース削除行数
        Dim mappingHeaderDeletions As String: mappingHeaderDeletions = .Cells(18, 2).Value & CStr(.Cells(18, 3).Value)
        '(ヘッダー)ソース追加・削除行数
        Dim mappingHeaderAdditionsAndDeletions As String: mappingHeaderAdditionsAndDeletions = .Cells(19, 2).Value & CStr(.Cells(19, 3).Value)
        '(サマリー)シート名
        Dim mappingSummarySheet As String: mappingSummarySheet = .Cells(2, 6).Value
        '(サマリー)開始行
        Dim mappingSummaryStartRow As Integer: mappingSummaryStartRow = .Cells(3, 6).Value
        '(サマリー)レビュー回数
        Dim mappingSummaryCount As String: mappingSummaryCount = .Cells(7, 6).Value
        '(サマリー)工程
        Dim mappingSummaryPhase As String: mappingSummaryPhase = .Cells(8, 6).Value
        '(サマリー)レビュー日付
        Dim mappingSummaryDate As String: mappingSummaryDate = .Cells(9, 6).Value
        '(サマリー)レビュー開始時刻
        Dim mappingSummaryStartTime As String: mappingSummaryStartTime = .Cells(10, 6).Value
        '(サマリー)レビュー終了時刻
        Dim mappingSummaryEndTime As String: mappingSummaryEndTime = .Cells(11, 6).Value
        '(サマリー)レビュー開始日時
        Dim mappingSummaryStartDateTime As String: mappingSummaryStartDateTime = .Cells(12, 6).Value
        '(サマリー)レビュー終了日時
        Dim mappingSummaryEndDateTime As String: mappingSummaryEndDateTime = .Cells(13, 6).Value
        '(サマリー)レビュー時間
        Dim mappingSummaryReviewOrBreakTime As String: mappingSummaryReviewOrBreakTime = .Cells(14, 6).Value
        '(サマリー)レビュア
        Dim mappingSummaryReviewer As String: mappingSummaryReviewer = .Cells(15, 6).Value
        '(サマリー)レビュイ
        Dim mappingSummaryReviewee As String: mappingSummaryReviewee = .Cells(16, 6).Value
        '(サマリー)ソース追加行数
        Dim mappingSummaryAdditions As String: mappingSummaryAdditions = .Cells(17, 6).Value
        '(サマリー)ソース削除行数
        Dim mappingSummaryDeletions As String: mappingSummaryDeletions = .Cells(18, 6).Value
        '(サマリー)ソース追加・削除行数
        Dim mappingSummaryAdditionsAndDeletions As String: mappingSummaryAdditionsAndDeletions = .Cells(19, 6).Value
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
        '(指摘一覧)指摘へのリンク
        Dim mappingListUrl As String: mappingListUrl = .Cells(14, 9).Value
    End With
    reviewListPhase = Range(IDX_REVIEW_LIST_PHASE).Value
    reviewListReviewer = Range(IDX_REVIEW_LIST_REVIEWER).Value
    reviewListReviewee = Range(IDX_REVIEW_LIST_REVIEWEE).Value
    If (Len(reviewListPhase) = 0) Then
        MsgBox "工程を入力してください。", vbExclamation
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
    End If
    If (Len(reviewListReviewer) = 0) Then
        MsgBox "レビュアを入力してください。", vbExclamation
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
    End If
    If (Len(reviewListReviewee) = 0) Then
        MsgBox "レビュイを入力してください。", vbExclamation
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
    End If
    Dim usernameMappings As Object
    Set usernameMappings = CreateObject("Scripting.Dictionary")
    With ThisWorkbook.Worksheets("ユーザー名マッピング設定")
        For row = 2 To .Cells(Application.Rows.count, 2).End(xlUp).row
            If Not .Cells(row, 2).Value = "" Then
                Call usernameMappings.Add(.Cells(row, 2).Value, .Cells(row, 3).Value)
            End If
        Next row
    End With
    '------------------
    ' 抽出処理
    '------------------
    '基本情報
    count = Range("REVIEW_TIMES").Value
    '転記先のレビュー記録票を取得する
    '"レビュー記録票"を含んでいれば対象設計書のレビュー記録票とみなす
    Dim bookTemp As Workbook
    Dim selectedReviewRecordBook As Boolean
    selectedReviewRecordBook = False
    For Each bookTemp In Application.Workbooks
        If InStr(bookTemp.Name, "レビュー記録票") > 0 Then
            res = MsgBox(bookTemp.Name & " をレビュー記録票として使用しますか？", vbYesNoCancel, 確認)
            If res = vbCancel Then
                MsgBox "処理を中止します。"
                Application.ScreenUpdating = True
                Application.Cursor = xlDefault
                Exit Sub
            ElseIf res = vbYes Then
                selectedReviewRecordBook = True
                Exit For
            End If
        End If
    Next bookTemp
    If Not selectedReviewRecordBook Then
        MsgBox "レビュー記録票が選択されていません。", vbExclamation
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
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
    Dim tempStr As String
    If Not postingSummaryOutput Is Nothing Then
        'レビュー回数のチェック
        For postingSummaryRow = mappingSummaryStartRow To (mappingSummaryStartRow + 100)
            tempStr = postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value
            If tempStr = "" Or tempStr = CStr(count) Then
                If count > 1 And Not postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow - 1)).Value = CStr(count - 1) Then
                    MsgBox "指定されたレビュー回数が正しくありません。", vbExclamation
                    Application.ScreenUpdating = True
                    Application.Cursor = xlDefault
                    Exit Sub
                End If
                If tempStr = CStr(count) And Not postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow + 1)).Value = "" Then
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
            tempStr = postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)).Value
            If tempStr = "" Or tempStr = CStr(count) Then
                Exit For
            End If
        Next postingSummaryRow
    End If
    If Not postingOutput Is Nothing Then
        '転記先の開始行数を取得（指摘一覧）
        For postingRow = mappingListStartRow To (mappingListStartRow + 1000)
            tempStr = postingOutput.Range(mappingListCount & CStr(postingRow)).Value
            If tempStr = "" Or tempStr = CStr(count) Then
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
    '前回レビュー時に最後に記載された指摘コメントのリンク（URL）を取得
    Dim lastReviewCommentUrl As String
    If Not postingOutput Is Nothing Then
        If postingRow > mappingListStartRow Then
            Dim tempHyperlink As Hyperlink
            For Each tempHyperlink In postingOutput.Hyperlinks
                If tempHyperlink.Range.Address = "$" & mappingListUrl & "$" & CStr(postingRow - 1) Then
                    lastReviewCommentUrl = tempHyperlink.Address & "#" & tempHyperlink.SubAddress
                End If
            Next tempHyperlink
        End If
    End If
    '----------------------------------------------------------------------------
    'レビュー指摘を抽出
    '----------------------------------------------------------------------------
    Dim s As Worksheet
    Dim cmntCell As Range
    Dim workCommentCells As New Collection
    Dim workCommentCell(2) As String
    Application.ScreenUpdating = False
    '転記先のレビュー記録票（サマリー）のカレント行にレビュー回数が書かれていない場合は行を追加
    If Not postingSummaryOutput Is Nothing Then
        If postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)) = "" Then
            postingSummaryOutput.Rows(postingSummaryRow).Copy
            postingSummaryOutput.Rows(postingSummaryRow + 1).Insert
        End If
    End If
    Call GetAndLoadPullRequest
    Dim tempSheet As Worksheet
    Set tempSheet = ThisWorkbook.Worksheets("temp")
    'エラーメッセージがあればエラーとみなす
    Dim errorMessage As String
    errorMessage = tempSheet.Cells(1, 1).Value
    If Len(errorMessage) > 0 Then
        errorMessage = Replace(errorMessage, "\n", vbCrLf)
        MsgBox errorMessage, vbExclamation
        Application.ScreenUpdating = True
        Application.Cursor = xlDefault
        Exit Sub
    End If
    'ソース追加行数、削除行数、レビュー日付、開始時刻、終了時刻、レビュー時間のプロット
    additions = tempSheet.Cells(2, 1).Value
    deletions = tempSheet.Cells(2, 2).Value
    reviewDate = tempSheet.Cells(2, 3).Value
    reviewStartTime = tempSheet.Cells(2, 4).Value
    reviewEndTime = tempSheet.Cells(2, 5).Value
    reviewOrBreakTime = tempSheet.Cells(2, 6).Value
    'レビュー記録票（ヘッダー）へ転記する
    If Not postingHeaderOutput Is Nothing Then
        If Len(mappingHeaderCount) > 0 Then
            postingHeaderOutput.Range(mappingHeaderCount) = CStr(count)
        End If
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
        If Len(mappingHeaderReviewOrBreakTime) > 0 Then
            postingHeaderOutput.Range(mappingHeaderReviewOrBreakTime) = reviewOrBreakTime
        End If
        If Len(mappingHeaderAdditions) > 0 Then
            postingHeaderOutput.Range(mappingHeaderAdditions) = CStr(additions)
        End If
        If Len(mappingHeaderDeletions) > 0 Then
            postingHeaderOutput.Range(mappingHeaderDeletions) = CStr(deletions)
        End If
        If Len(mappingHeaderAdditionsAndDeletions) > 0 Then
            postingHeaderOutput.Range(mappingHeaderAdditionsAndDeletions) = CStr(additions + deletions)
        End If
    End If
    'レビュー記録票（サマリー）へ転記する
    If Not postingSummaryOutput Is Nothing Then
        If Len(mappingSummaryCount) > 0 Then
            postingSummaryOutput.Range(mappingSummaryCount & CStr(postingSummaryRow)) = CStr(count)
        End If
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
        If Len(mappingSummaryReviewOrBreakTime) > 0 Then
            postingSummaryOutput.Range(mappingSummaryReviewOrBreakTime & CStr(postingSummaryRow)) = reviewOrBreakTime
        End If
        If Len(mappingSummaryAdditions) > 0 Then
            postingSummaryOutput.Range(mappingSummaryAdditions & CStr(postingSummaryRow)) = CStr(additions)
        End If
        If Len(mappingSummaryDeletions) > 0 Then
            postingSummaryOutput.Range(mappingSummaryDeletions & CStr(postingSummaryRow)) = CStr(deletions)
        End If
        If Len(mappingSummaryAdditionsAndDeletions) > 0 Then
            postingSummaryOutput.Range(mappingSummaryAdditionsAndDeletions & CStr(postingSummaryRow)) = CStr(additions + deletions)
        End If
    End If
    Dim commentDelimiter As String
    commentDelimiter = ThisWorkbook.Worksheets("基本設定").Range("B8").Value
    'コメント処理を開始する行を算出
    Dim commentStartRow As Integer
    commentStartRow = 3
    If Len(lastReviewCommentUrl) Then
        For row = 3 To tempSheet.Cells(Rows.count, 3).End(xlUp).row
            If lastReviewCommentUrl = tempSheet.Cells(row, 1).Value Then
                commentStartRow = row + 1
                Exit For
            End If
        Next row
    End If
    'コメントを抽出
    For row = commentStartRow To tempSheet.Cells(Rows.count, 1).End(xlUp).row
        Dim url As String
        url = tempSheet.Cells(row, 1).Value
        Dim reviewerComment As String
        reviewerComment = tempSheet.Cells(row, 2).Value
        Dim reviewer As String
        reviewer = tempSheet.Cells(row, 3).Value
        If usernameMappings.Exists(reviewer) Then
            reviewer = usernameMappings.item(reviewer)
        End If
        If Len(reviewer) = 0 Then
            reviewer = reviewListReviewer
        End If
        Dim revieweeComment As String
        revieweeComment = tempSheet.Cells(row, 4).Value
        Dim reviewee As String
        reviewee = tempSheet.Cells(row, 5).Value
        If usernameMappings.Exists(reviewee) Then
            reviewee = usernameMappings.item(reviewee)
        End If
        If Len(reviewee) = 0 Then
            reviewee = reviewListReviewee
        End If
        Dim resolved As Boolean
        resolved = tempSheet.Cells(row, 6).Value
        Dim hasResolvedStatus As Boolean
        hasResolvedStatus = tempSheet.Cells(row, 7).Value
        Dim commentText As String
        If Not reviewerComment = "" And Not revieweeComment = "" Then
            commentText = Replace(reviewerComment, "\n", vbCrLf) & vbCrLf & commentDelimiter & vbCrLf & Replace(revieweeComment, "\n", vbCrLf)
        ElseIf Not reviewerComment = "" Then
            commentText = Replace(reviewerComment, "\n", vbCrLf)
        ElseIf Not revieweeComment = "" Then
            commentText = commentDelimiter & vbCrLf & Replace(revieweeComment, "\n", vbCrLf)
        Else
            commentText = ""
        End If
        '1行目が1文字のみの場合、それをカテゴリとする
        If InStr(commentText, vbCrLf) > 0 Then
            category = Trim(Mid(commentText, 1, InStr(commentText, vbCrLf) - 1))
            If Len(category) = 1 Then
                commentText = Trim(Mid(commentText, InStr(commentText, vbCrLf) + Len(vbCrLf)))
            Else
                category = ""
            End If
        Else
            category = Trim(commentText)
            If Len(category) = 1 Then
                commentText = ""
            Else
                category = ""
            End If
        End If
        '指摘クローズの判定
        closeLine = defaultCloseLine
        isFixed = resolved
        'コメントの最後に"済"があれば対応済みと判断
        If GetLastChar(commentText) = "済" Then
            isFixed = True
            hasResolvedStatus = True
            closeLine = extractCloseLine(commentText)
        End If
        '転記先のレビュー記録票の行特定列に値が書かれていない場合は行を追加
        If Not postingOutput Is Nothing Then
            If postingOutput.Range(mappingListCount & CStr(postingRow)).Value = "" Then
                postingOutput.Rows(postingTemplateRow).Copy
                postingOutput.Rows(postingRow + 1).Insert
                postingTemplateRow = postingTemplateRow + 1
            End If
        End If
        Application.CutCopyMode = False
        'レビューコメントと返信のパース
        delimiterIndex = InStr(commentText, commentDelimiter)
        If delimiterIndex > 0 Then
            reviewComment = Mid(commentText, 1, delimiterIndex - 1) & vbCrLf
            replyComment = Mid(commentText, delimiterIndex + Len(commentDelimiter) + Len(vbCrLf)) & vbCrLf
        Else
            reviewComment = commentText & vbCrLf
            replyComment = "" & vbCrLf
        End If
        'レビュー記録票（指摘一覧）へ転記する
        If Not postingOutput Is Nothing Then
            If Len(mappingListCount) > 0 Then
                postingOutput.Range(mappingListCount & CStr(postingRow)).Value = CStr(count)
            End If
            If Len(mappingListReviewer) > 0 Then
                postingOutput.Range(mappingListReviewer & CStr(postingRow)).Value = reviewer
            End If
            If Len(mappingListCategory) > 0 And ("a" <= category And category <= "i") Then
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
            If hasResolvedStatus Then
                If isFixed Then
                    If Len(mappingListCloseLine) > 0 Then
                        postingOutput.Range(mappingListCloseLine & CStr(postingRow)).Value = closeLine
                    End If
                Else
                    If Len(mappingListCloseLine) > 0 Then
                        postingOutput.Range(mappingListCloseLine & CStr(postingRow)).Value = ""
                    End If
                End If
            End If
            If Len(mappingListUrl) > 0 Then
                postingOutput.Hyperlinks.Add postingOutput.Range(mappingListUrl & CStr(postingRow)), url
            End If
            ''行の高さを調整
            postingOutput.Rows(postingRow).AutoFit
        End If
        postingRow = postingRow + 1
    Next row
    Application.ScreenUpdating = True
    '----------------------------------------------------------------------------
    'レビュー記録一覧への反映
    '----------------------------------------------------------------------------
    Dim phase As String, autor As String, volume As Long, listReviewer As String, listReviewee As String, reviewWay As String, reviewResult As String
    Dim listRow As Long
    Dim existSameDocIdAndCount As Boolean
    phase = Range(IDX_REVIEW_LIST_PHASE).Value
    listReviewer = Range(IDX_REVIEW_LIST_REVIEWER).Value
    listReviewee = Range(IDX_REVIEW_LIST_REVIEWEE).Value
    '既に存在する文書ID・回数の場合、一覧に反映しない
    '前回記録No.もここで取得しておく
    Dim docIdRng As Range
    Dim firstAddress As String
    existSameDocIdAndCount = False
    'ヘッダーの転記
    If Not postingHeaderOutput Is Nothing Then
        If Len(mappingHeaderPhase) > 0 Then
            postingHeaderOutput.Range(mappingHeaderPhase).Value = phase
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
        If Len(mappingSummaryReviewer) > 0 Then
            postingSummaryOutput.Range(mappingSummaryReviewer & CStr(postingSummaryRow)).Value = listReviewer
        End If
        If Len(mappingSummaryReviewee) > 0 Then
            postingSummaryOutput.Range(mappingSummaryReviewee & CStr(postingSummaryRow)).Value = listReviewee
        End If
    End If
    Application.Cursor = xlDefault
    MsgBox "レビュー結果の抽出が完了しました。", vbInformation
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
Sub GetAndLoadPullRequest()
    Dim tempSheet As Worksheet
    Set tempSheet = ThisWorkbook.Worksheets("temp")
    'シートの内容をクリアする
    tempSheet.Cells.Clear
    '外部プログラムを使用してプルリクエストの内容をCSV形式で取得し、ツールにある一時作業用シートへ読み込む
    Dim directory As String
    directory = ThisWorkbook.Path
    Dim csvFilePath As String
    csvFilePath = directory & "\temp\review-data.csv"
    If Dir(csvFilePath) <> "" Then
        Dim fso As Object
        Set fso = CreateObject("Scripting.FileSystemObject")
        fso.DeleteFile csvFilePath
        Set fso = Nothing
    End If
    Dim cmdArgs As String
    With ThisWorkbook.Worksheets("基本設定")
        If Len(.Range("B2").Value) > 0 Then
            cmdArgs = "--target=""" & StrConv(.Range("B2").Value, vbLowerCase) & """"
        End If
        If Len(.Range("B3").Value) > 0 Then
            cmdArgs = cmdArgs & " --endpoint=""" & .Range("B3").Value & """"
        End If
        If Len(.Range("B4").Value) > 0 Then
            cmdArgs = cmdArgs & " --org=""" & .Range("B4").Value & """"
        End If
        If Len(.Range("B5").Value) > 0 Then
            cmdArgs = cmdArgs & " --repo=""" & .Range("B5").Value & """"
        End If
        If Len(Range("PULL").Value) > 0 Then
            cmdArgs = cmdArgs & " --pull=""" & Range("PULL").Value & """"
        End If
        If Len(.Range("B6").Value) > 0 Then
            cmdArgs = cmdArgs & " --proxy=""" & .Range("B6").Value & """"
        End If
        If Len(.Range("B7").Value) > 0 Then
            cmdArgs = cmdArgs & " --post-script-prefix=""" & .Range("B7").Value & """"
        End If
        If Len(.Range("B8").Value) > 0 Then
            cmdArgs = cmdArgs & " --delimiter=""" & .Range("B8").Value & """"
        End If
        If Len(Range("REVIEW_TIMES").Value) > 0 Then
            cmdArgs = cmdArgs & " --review-times=""" & Range("REVIEW_TIMES").Value & """"
        End If
        If Len(.Range("B9").Value) > 0 Then
            cmdArgs = cmdArgs & " --access-token=""" & .Range("B9").Value & """"
        End If
        'cmdArgs = cmdArgs & " --use-diff-count=true"
        cmdArgs = cmdArgs & " --csv-file=""" & csvFilePath & """"
        'cmdArgs = cmdArgs & " --use-sjis-file=true"
        'cmdArgs = cmdArgs & " --use-sjis-stderr=true"
    End With
    Dim wsh As Object
    Set wsh = CreateObject("WScript.Shell")
    Dim exec As Object
    Set exec = wsh.exec("""" & directory & "\getpr.exe"" " & cmdArgs)
    Dim stdErr As String
    stdErr = exec.stdErr.ReadAll
    If exec.ExitCode <> 0 Then
        stdErr = Replace(stdErr, vbCr, "")
        stdErr = Replace(stdErr, vbLf, "\n")
        tempSheet.Cells(1, 1).Value = stdErr
        Exit Sub
    End If
    Set wsh = Nothing
    If Dir(csvFilePath) = "" Then
        tempSheet.Cells(1, 1).Value = "プルリクエストデータの取得に失敗しました"
        Exit Sub
    End If
    With tempSheet.QueryTables.Add(Connection:="TEXT;" & directory & "\temp\review-data.csv", Destination:=tempSheet.Cells(2, 1))
        .Name = "csv"
        .FieldNames = False
        .RowNumbers = False
        .RefreshPeriod = 0
        .TextFilePromptOnRefresh = False
        .TextFilePlatform = 932
        .TextFileParseType = xlDelimited
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .TextFileCommaDelimiter = True
        .TextFileColumnDataTypes = Array(xlTextFormat, xlTextFormat, xlTextFormat, xlTextFormat, xlTextFormat, xlTextFormat, xlTextFormat)
        .Refresh BackgroundQuery:=False
    End With
    For Each qt In tempSheet.QueryTables
        qt.Delete
    Next qt
End Sub
