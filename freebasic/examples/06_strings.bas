Dim As String s = "FreeBASIC"
Dim As String t = " Tutorial"
Dim As String allText = s & t

Print "concat: "; allText
Print "length: "; Len(allText)
Print "left 4: "; Left(allText, 4)
Print "right 4: "; Right(allText, 4)
Print "mid 5,4: "; Mid(allText, 5, 4)
Print "upper: "; UCase(allText)
Print "lower: "; LCase(allText)
Print "find 'BASIC': "; InStr(allText, "BASIC")

