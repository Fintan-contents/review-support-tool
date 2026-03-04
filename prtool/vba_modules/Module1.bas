- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
Public Function hasSheet(book As Workbook, query As String) As Boolean
    Dim item
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
