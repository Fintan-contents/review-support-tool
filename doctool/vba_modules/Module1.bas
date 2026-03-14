- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Option Explicit

Dim re As Object

'=====================================================
' パフォーマンス計測
' ENABLE_PERF_LOG = True で計測ON、False で計測OFF（本番運用時は False に設定）
'=====================================================
Public Const ENABLE_PERF_LOG As Boolean = False

'=====================================================
' シート名定数
'=====================================================
Public Const SHT_KIHON_SETTINGS As String = "基本設定"
Public Const SHT_CATEGORY_MAPPINGS As String = "指摘分類マッピング設定"
Public Const SHT_ITEM_MAPPINGS As String = "項目マッピング設定"
Public Const SHT_REVIEW_RECORD As String = "レビュー記録票"
Public Const SHT_PERF_LOG As String = "パフォーマンス計測"

Private timerLabels() As String
Private timerElapsed() As Double
Private timerInterval() As Double
Private timerLogCount As Long
Private timerStartTime As Double
Private timerStartDateTime As Date

Public Sub InitTimerLog()
    If Not ENABLE_PERF_LOG Then Exit Sub
    timerLogCount = 0
    ReDim timerLabels(0)
    ReDim timerElapsed(0)
    ReDim timerInterval(0)
    timerStartTime = Timer
    timerStartDateTime = Now
End Sub

Public Sub RecordTimer(label As String)
    If Not ENABLE_PERF_LOG Then Exit Sub
    Dim elapsed As Double
    Dim interval As Double
    elapsed = Timer - timerStartTime
    If elapsed < 0 Then elapsed = elapsed + 86400  ' 日付またぎ補正
    If timerLogCount = 0 Then
        interval = 0
    Else
        interval = elapsed - timerElapsed(timerLogCount - 1)
    End If
    ReDim Preserve timerLabels(timerLogCount)
    ReDim Preserve timerElapsed(timerLogCount)
    ReDim Preserve timerInterval(timerLogCount)
    timerLabels(timerLogCount) = label
    timerElapsed(timerLogCount) = elapsed
    timerInterval(timerLogCount) = interval
    timerLogCount = timerLogCount + 1
End Sub

Public Sub OutputTimerLog(targetWorkbook As Workbook)
    If Not ENABLE_PERF_LOG Then Exit Sub
    Dim perfSheet As Worksheet
    If hasSheet(targetWorkbook, SHT_PERF_LOG) Then
        Set perfSheet = targetWorkbook.Worksheets(SHT_PERF_LOG)
        perfSheet.Cells.ClearContents
    Else
        Application.DisplayAlerts = False
        targetWorkbook.Worksheets.Add After:=targetWorkbook.Worksheets(targetWorkbook.Worksheets.Count)
        Application.DisplayAlerts = True
        Set perfSheet = targetWorkbook.Worksheets(targetWorkbook.Worksheets.Count)
        perfSheet.Name = SHT_PERF_LOG
    End If
    perfSheet.Cells(1, 1).Value = "計測日時"
    perfSheet.Cells(1, 2).Value = Format(timerStartDateTime, "yyyy/mm/dd hh:mm:ss")
    perfSheet.Cells(3, 1).Value = "フェーズ"
    perfSheet.Cells(3, 2).Value = "全体経過(秒)"
    perfSheet.Cells(3, 3).Value = "区間(秒)"
    Dim i As Long
    For i = 0 To timerLogCount - 1
        perfSheet.Cells(i + 4, 1).Value = timerLabels(i)
        perfSheet.Cells(i + 4, 2).Value = timerElapsed(i)
        perfSheet.Cells(i + 4, 3).Value = timerInterval(i)
    Next i
End Sub
Public Sub initializeModule1()
    If Not re Is Nothing Then
        Set re = Nothing
    End If
    Set re = CreateObject("VBScript.RegExp")
    With re
        .Pattern = "^---+$"
        .Global = True
    End With
End Sub

'=====================================================
' 関数名: InitRegexPatterns
' 機能: 基本設定シートのB4/B5セルから対象/除外ブック名の正規表現パターンを生成
' 引数: targetPattern    - 対象ブック名パターン（ByRef、呼び出し元に返す）
'       noTargetPattern  - 除外ブック名パターン（ByRef、呼び出し元に返す）
'=====================================================
Public Sub InitRegexPatterns(ByRef targetPattern As Object, ByRef noTargetPattern As Object)
    Set targetPattern = CreateObject("VBScript.RegExp")
    With targetPattern
        .Pattern = ThisWorkbook.Worksheets(SHT_KIHON_SETTINGS).Range("B4").Value
        .IgnoreCase = False
        .Global = True
    End With
    Set noTargetPattern = CreateObject("VBScript.RegExp")
    With noTargetPattern
        .Pattern = ThisWorkbook.Worksheets(SHT_KIHON_SETTINGS).Range("B5").Value
        .IgnoreCase = False
        .Global = True
    End With
End Sub
Public Function hasSheet(book As Workbook, query As String) As Boolean
    Dim item As Variant
    For Each item In book.Worksheets
        If item.Name = query Then
            hasSheet = True
            Exit Function
        End If
    Next
    hasSheet = False
End Function
Public Function inStrCount(s As String, query As String) As Integer
    Dim work As String
    work = s
    Dim cnt As Integer
    cnt = 0
    Do While InStr(1, work, query) >= 1
        work = Mid(work, InStr(1, work, query) + 1)
        cnt = cnt + 1
    Loop
    inStrCount = cnt
End Function
Public Function repeat(s As String, cnt As Integer) As String
    Dim work As String
    Dim i As Long
    work = ""
    For i = 1 To cnt
        work = work & s
    Next i
    repeat = work
End Function
Public Function nullToZero(v As Variant) As Long
    Dim work As Long
    If IsNumeric(v) Then
        work = v
    Else
        work = 0
    End If
    nullToZero = work
End Function
Public Function zeroToNull(v As Variant) As Variant
    Dim work As Variant
    If v = "0" Then
        work = ""
    Else
        work = v
    End If
    zeroToNull = work
End Function
Public Function checkReference(book As Workbook, querysheet As String, querycell As String) As Boolean
    On Error GoTo ReferenceError
    Dim item As String
    item = book.Worksheets(querysheet).Range(querycell).Value
    checkReference = True
    Exit Function
ReferenceError:
    checkReference = False
End Function
Public Function splitComment(comment As String) As String()
    Dim lines() As String
    Dim reviewComment() As String
    Dim replyComment() As String
    Dim s As Variant
    Dim matched As Boolean
    Dim rc() As String
    matched = False
    ReDim reviewComment(0)
    ReDim replyComment(0)
    lines = Split(comment, vbLf)
    For Each s In lines()
        If Not matched And re.test(s) Then
            matched = True
        Else
            If matched Then
                ReDim Preserve replyComment(UBound(replyComment) + 1)
                replyComment(UBound(replyComment)) = s
            Else
                ReDim Preserve reviewComment(UBound(reviewComment) + 1)
                reviewComment(UBound(reviewComment)) = s
            End If
        End If
    Next s
    ReDim rc(2)
    rc(1) = Join(reviewComment, vbCrLf)
    rc(2) = Join(replyComment, vbCrLf)
    splitComment = rc()
End Function
'=====================================================
' 関数名: ExtractCategory
' 機能: コメントテキストからカテゴリ（1-2文字）を抽出
' 引数: commentText - コメント全文（"レビュア名:カテゴリ\nコメント"形式）
' 戻値: カテゴリ文字列（"a", "ab"等）、エラー時は空文字
'=====================================================
Public Function ExtractCategory(commentText As String) As String
    Dim colonPos As Long
    Dim crlfPos As Long
    Dim categoryLen As Long
    Dim extractedText As String

    ' コロン位置を取得（半角変換後）
    colonPos = InStr(1, StrConv(commentText, vbNarrow), ":")
    If colonPos = 0 Then
        ExtractCategory = ""
        Exit Function
    End If

    ' 改行位置を取得（コロン以降）
    crlfPos = InStr(colonPos, commentText, vbLf)
    If crlfPos = 0 Then
        ' 改行がない場合は文末まで
        crlfPos = Len(commentText) + 1
    End If

    ' カテゴリの長さを計算（最大2文字）
    categoryLen = crlfPos - colonPos - 1
    If categoryLen > 2 Then categoryLen = 2
    If categoryLen < 1 Then
        ExtractCategory = ""
        Exit Function
    End If

    ' カテゴリを抽出（半角変換）
    extractedText = Mid(commentText, colonPos + 1, categoryLen)
    ExtractCategory = StrConv(extractedText, vbNarrow)
End Function
'=====================================================
' 関数名: IsValidCategory
' 機能: カテゴリが設定シートに登録済みかチェック
' 引数: category - カテゴリ文字列
'       categoryMappings - 設定シートから読み込んだ辞書オブジェクト
' 戻値: True=有効、False=無効
'=====================================================
Public Function IsValidCategory(category As String, categoryMappings As Object) As Boolean
    If category = "" Then
        IsValidCategory = False
        Exit Function
    End If
    IsValidCategory = categoryMappings.Exists(category)
End Function
Public Function extractCloseLine(commentText As String) As String
    extractCloseLine = ""
    Dim index1 As Long, index2 As Long, length As Long
    index1 = InStrRev(commentText, "済")
    If index1 > 0 Then
        index2 = InStrRev(commentText, vbLf, index1)
        length = (index1 - 1) - (index2 + 1)
        If length > 0 Then
            extractCloseLine = Mid(commentText, index2 + 1, length)
        End If
    End If
End Function
