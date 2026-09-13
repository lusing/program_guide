Dim fixedArr(1 To 5) As Integer
For i As Integer = 1 To 5
    fixedArr(i) = i * 10
Next

ReDim dynamicArr(0 To 3) As Integer
For i As Integer = 0 To 3
    dynamicArr(i) = i * i
Next

Dim As Integer sum = 0
For i As Integer = 1 To 5
    sum += fixedArr(i)
Next
Print "fixed sum = "; sum
Print "dynamic[3] = "; dynamicArr(3)

