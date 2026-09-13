Function ParseIntOrZero(ByVal text As String) As Integer
    If Len(Trim(text)) = 0 Then Return 0
    Return ValInt(text)
End Function

Function Clamp(ByVal value As Integer, ByVal lo As Integer, ByVal hi As Integer) As Integer
    If value < lo Then Return lo
    If value > hi Then Return hi
    Return value
End Function

Sub ShowResult(ByVal inputText As String)
    Dim As Integer parsed = ParseIntOrZero(inputText)
    Dim As Integer clamped = Clamp(parsed, 0, 100)
    Print "input='" & inputText & "', parsed="; parsed; ", clamped="; clamped
End Sub

ShowResult("42")
ShowResult("-7")
ShowResult("888")

