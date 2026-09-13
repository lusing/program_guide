Function AddTwo(ByVal a As Integer, ByVal b As Integer) As Integer
    Return a + b
End Function

Function MulTwo(ByVal a As Integer, ByVal b As Integer) As Integer
    Return a * b
End Function

Dim As Integer choice = 2
Dim As Integer x = 6, y = 7

Print "Menu: 1) add  2) mul"
Print "choice = "; choice

Select Case choice
Case 1
    Print "result = "; AddTwo(x, y)
Case 2
    Print "result = "; MulTwo(x, y)
Case Else
    Print "invalid choice"
End Select

