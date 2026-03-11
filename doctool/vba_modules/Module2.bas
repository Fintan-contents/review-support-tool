- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Option Explicit

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

'ダイアログログに追加（testMode時のみ）
Private Sub LogDialog(message As String)
    If dialogLog <> "" Then
        dialogLog = dialogLog & vbCrLf
    End If
    dialogLog = dialogLog & message
End Sub

Sub DelAllReviewComments_Click()
    'UIボタンから呼ばれる場合はtestMode=False
    Call DelAllReviewComments_Click_Core(testMode:=False)
End Sub

Public Sub DelAllReviewComments_Click_Core(Optional testMode As Boolean = False)
    Dim targetBookNamePattern As Object
    Dim noTargetBookNamePattern As Object
    Call InitRegexPatterns(targetBookNamePattern, noTargetBookNamePattern)
    Dim book As Workbook
    Dim s As Worksheet
    Dim cmnt As Comment
    Dim fileCount As Integer
    fileCount = 0
    Dim category As String
    Dim categoryMappings As Object
    Set categoryMappings = CreateObject("Scripting.Dictionary")
    With ThisWorkbook.Worksheets(SHEETNAME_CATEGORY_MAPPING)
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
            If Not testMode Then
                If MsgBox(book.Name & " のメモを削除してよろしいですか？", vbYesNo, vbInformation) = vbNo Then
                    GoTo NEXTBOOK
                End If
            Else
                LogDialog "[DIALOG] " & book.Name & " のメモを削除してよろしいですか？"
            End If
            For Each s In book.Worksheets
                Dim commentText As String
                For Each cmnt In s.Comments
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
            If Not testMode Then
                MsgBox book.Name & " のメモを削除しました。", vbInformation
            Else
                LogDialog "[INFO] " & book.Name & " のメモを削除しました。"
            End If
        End If
NEXTBOOK:
    Next book
    If Not testMode Then
        If fileCount = 0 Then
            MsgBox "メモ削除対象のファイルはありませんでした。", vbExclamation
        End If
    Else
        If fileCount = 0 Then
            LogDialog "[INFO] メモ削除対象のファイルはありませんでした。"
        End If
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
    Dim noTargetBookNamePattern As Object
    Call InitRegexPatterns(targetBookNamePattern, noTargetBookNamePattern)
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
            If Not testMode Then
                If MsgBox(book.Name & " のレビュー結果シートを削除してよろしいですか？", vbYesNo, vbInformation) = vbNo Then
                    GoTo NEXTBOOK
                End If
            Else
                LogDialog "[DIALOG] " & book.Name & " のレビュー結果シートを削除してよろしいですか？"
            End If
            For Each s In book.Worksheets
                If (InStr(s.Name, "レビュー結果") > 0 And InStr(s.Name, "回目") > 0) Or s.Name = "エラーシート" Then
                s.Delete
            End If
        Next s
        If Not testMode Then
            MsgBox book.Name & " のレビュー結果シートを削除しました。", vbInformation
        Else
            LogDialog "[INFO] " & book.Name & " のレビュー結果シートを削除しました。"
        End If
    End If
NEXTBOOK:
Next book
If Not testMode Then
    If fileCount = 0 Then
        MsgBox "レビュー結果シート削除対象のファイルはありませんでした。", vbExclamation
    End If
Else
    If fileCount = 0 Then
        LogDialog "[INFO] レビュー結果シート削除対象のファイルはありませんでした。"
    End If
End If
Application.DisplayAlerts = True
Application.ScreenUpdating = True
Application.Cursor = xlDefault
End Sub
