Dim As String filePath = "freebasic_demo.txt"
Dim As Integer ff = FreeFile()

Open filePath For Output As #ff
Print #ff, "line1"
Print #ff, "line2"
Close #ff

ff = FreeFile()
Dim As String lineText
Open filePath For Input As #ff
If EOF(ff) = 0 Then Line Input #ff, lineText : Print "read1: "; lineText
If EOF(ff) = 0 Then Line Input #ff, lineText : Print "read2: "; lineText
Close #ff

