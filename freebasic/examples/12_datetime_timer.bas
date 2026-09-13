Dim As String d = Date
Dim As String t = Time
Dim As Double t0 = Timer

Dim As Long acc = 0
For i As Integer = 1 To 200000
    acc += i
Next

Dim As Double elapsed = Timer - t0

Print "date: "; d
Print "time: "; t
Print "acc : "; acc
Print "elapsed(s): "; elapsed

