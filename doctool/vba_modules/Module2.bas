- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
Sub DelAllReviewComments_Click()
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
    Application.ScreenUpdating = False
    '開いている全ブックを確認
    For Each book In Application.Workbooks
        'ファイル名に正規表現パターンマッチを行い対象ファイルを抽出
        If targetBookNamePattern.test(book.Name) And Not noTargetBookNamePattern.test(book.Name) Then
            fileCount = fileCount + 1
            If MsgBox(book.Name & " のメモを削除してよろしいですか？", vbYesNo, vbInformation) = vbNo Then
                GoTo NEXTBOOK
            End If
            For Each s In book.Worksheets
                For Each cmnt In s.comments
                    Dim commentText As String
                    commentText = cmnt.Text
                    'コメントに:が含まれ、改行があれば処理対象に
                    If InStr(1, StrConv(commentText, vbNarrow), ":") >= 1 And InStr(1, commentText, vbLf) >= 1 Then
                        ':の直後の1文字を取得して、カテゴリとする。
                        category = StrConv(Mid(commentText, InStr(1, StrConv(commentText, vbNarrow), ":") + 1, 1), vbNarrow)
                        'カテゴリがない(:直後が改行の)場合は処理しない
                        If category = "*" Or ("a" <= category And category <= "i") Then
                            cmnt.Delete
                        End If
                    End If
                Next cmnt
            Next s
            MsgBox book.Name & " のメモを削除しました。", vbInformation
        End If
NEXTBOOK:
    Next book
    If fileCount = 0 Then
        MsgBox "メモ削除対象のファイルはありませんでした。", vbExclamation
    End If
    Application.ScreenUpdating = True
    Application.Cursor = xlDefault
End Sub
Sub DelAllReviewResultSheets_Click()
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
            If MsgBox(book.Name & " のレビュー結果シートを削除してよろしいですか？", vbYesNo, vbInformation) = vbNo Then
                GoTo NEXTBOOK
            End If
            For Each s In book.Worksheets
                If (InStr(s.Name, "レビュー結果") > 0 And InStr(s.Name, "回目") > 0) Or s.Name = "エラーシート" Then
                s.Delete
            End If
        Next s
        MsgBox book.Name & " のレビュー結果シートを削除しました。", vbInformation
    End If
NEXTBOOK:
Next book
If fileCount = 0 Then
    MsgBox "レビュー結果シート削除対象のファイルはありませんでした。", vbExclamation
End If
Application.DisplayAlerts = True
Application.ScreenUpdating = True
Application.Cursor = xlDefault
End Sub
