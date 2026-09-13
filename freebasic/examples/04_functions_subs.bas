Function Add(ByVal a As Integer, ByVal b As Integer) As Integer
    Return a + b
End Function

Sub PrintBanner(ByVal text As String)
    Print "==== " & text & " ===="
End Sub

PrintBanner("Functions/Subs")
Dim As Integer r = Add(3, 4)
Print "3 + 4 = "; r

