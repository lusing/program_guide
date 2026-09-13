Dim As Integer n = 7

If n < 0 Then
    Print "negative"
ElseIf n = 0 Then
    Print "zero"
Else
    Print "positive"
End If

Dim As Integer total = 0
For i As Integer = 1 To 5
    total += i
Next
Print "sum 1..5 = "; total

Dim As Integer counter = 0
Do
    counter += 1
Loop Until counter = 3
Print "counter = "; counter

