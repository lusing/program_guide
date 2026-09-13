Function SafeDivide(ByVal a As Double, ByVal b As Double, ByRef outValue As Double) As Integer
    If b = 0 Then
        Return 0
    End If
    outValue = a / b
    Return 1
End Function

Dim As Double result
If SafeDivide(10, 2, result) Then
    Print "10 / 2 = "; result
Else
    Print "divide by zero"
End If

If SafeDivide(10, 0, result) Then
    Print "10 / 0 = "; result
Else
    Print "divide by zero"
End If

