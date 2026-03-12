- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
'testMode時のダイアログログ用変数
Private dialogLog As String

'ダイアログログを取得（テスト用）
Public Function GetDialogLog() As String
    GetDialogLog = dialogLog
End Function

'ダイアログログをクリア（テスト用）
Public Sub ClearDialogLog()
    dialogLog = ""
End Sub

'ダイアログログに追加（内部用）
Private Sub LogDialog(message As String)
    If dialogLog <> "" Then
        dialogLog = dialogLog & vbCrLf
    End If
    dialogLog = dialogLog & message
End Sub

'testMode対応のメッセージ表示関数
'  testMode=True : MsgBox を表示せず [MSG:{msgId}] をダイアログログに記録し defaultReturn を返す
'  testMode=False: 通常の MsgBox を表示し、ユーザーの選択結果を返す
'戻り値: vbOK / vbYes / vbNo など（MsgBoxと同じ値）
Public Function ShowMsg( _
    testMode As Boolean, _
    msgId As String, _
    msg As String, _
    Optional msgType As Long = vbInformation, _
    Optional defaultReturn As Long = vbOK _
) As Long
    If testMode Then
        LogDialog "[MSG:" & msgId & "] " & msg
        ShowMsg = defaultReturn
    Else
        ShowMsg = MsgBox(msg, msgType)
    End If
End Function

Sub DelAllReviewComments_Click()
    'UIボタンから呼ばれる場合はtestMode=False
    Call DelAllReviewComments_Click_Core(testMode:=False)
End Sub

Public Sub DelAllReviewComments_Click_Core(Optional testMode As Boolean = False)
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
    Dim book As Workbook
    Dim s As Worksheet
    Dim cmnt As comment
    Dim fileCount As Integer
    fileCount = 0
    Dim category As String
    Dim categoryMappings As Object
    Set categoryMappings = CreateObject("Scripting.Dictionary")
    With ThisWorkbook.Worksheets("指摘分類マッピング設定")
        Dim cmRow As Long
        For cmRow = 2 To .Cells(Application.Rows.Count, 1).End(xlUp).Row
            Call categoryMappings.Add(.Cells(cmRow, 1).Value, .Cells(cmRow, 2).Value)
        Next cmRow
    End With
    Application.ScreenUpdating = False
    '開いている全ブックを確認
    For Each book In Application.Workbooks
        'ファイル名に正規表現パターンマッチを行い対象ファイルを抽出
        If targetBookNamePattern.test(book.Name) And Not noTargetBookNamePattern.test(book.Name) Then
            fileCount = fileCount + 1
            If ShowMsg(testMode, "C04", book.Name & " のメモを削除してよろしいですか？", vbYesNo, vbYes) = vbNo Then
                GoTo NEXTBOOK
            End If
            For Each s In book.Worksheets
                For Each cmnt In s.comments
                    Dim commentText As String
                    commentText = cmnt.Text
                    'コメントに:が含まれ、改行があれば処理対象に
                    If InStr(1, StrConv(commentText, vbNarrow), ":") >= 1 And InStr(1, commentText, vbLf) >= 1 Then
                        'カテゴリを抽出（1-2文字対応）
                        category = ExtractCategory(commentText)
                        'カテゴリがない場合は処理しない
                        If category = "*" Or IsValidCategory(category, categoryMappings) Then
                            cmnt.Delete
                        End If
                    End If
                Next cmnt
            Next s
            ShowMsg testMode, "I02", book.Name & " のメモを削除しました。", vbInformation
        End If
NEXTBOOK:
    Next book
    If fileCount = 0 Then
        ShowMsg testMode, "E09", "メモ削除対象のファイルはありませんでした。", vbExclamation
    End If
    Application.ScreenUpdating = True
    Application.Cursor = xlDefault
End Sub
Sub DelAllReviewResultSheets_Click()
    'UIボタンから呼ばれる場合はtestMode=False
    Call DelAllReviewResultSheets_Click_Core(testMode:=False)
End Sub

Public Sub DelAllReviewResultSheets_Click_Core(Optional testMode As Boolean = False)
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
    Dim book As Workbook
    Dim s As Worksheet
    Dim fileCount As Integer
    fileCount = 0
    Application.DisplayAlerts = False
    Application.ScreenUpdating = False
    '開いている全ブックを確認
    For Each book In Application.Workbooks
        'ファイル名に正規表現パターンマッチを行い対象ファイルを抽出
        If targetBookNamePattern.test(book.Name) And Not noTargetBookNamePattern.test(book.Name) Then
            fileCount = fileCount + 1
            If ShowMsg(testMode, "C05", book.Name & " のレビュー結果シートを削除してよろしいですか？", vbYesNo, vbYes) = vbNo Then
                GoTo NEXTBOOK
            End If
            For Each s In book.Worksheets
                If (InStr(s.Name, "レビュー結果") > 0 And InStr(s.Name, "回目") > 0) Or s.Name = "エラーシート" Then
                s.Delete
            End If
        Next s
        ShowMsg testMode, "I03", book.Name & " のレビュー結果シートを削除しました。", vbInformation
    End If
NEXTBOOK:
Next book
If fileCount = 0 Then
    ShowMsg testMode, "E10", "レビュー結果シート削除対象のファイルはありませんでした。", vbExclamation
End If
Application.DisplayAlerts = True
Application.ScreenUpdating = True
Application.Cursor = xlDefault
End Sub
