' 16_files.bas —— 文件 IO：顺序文本三模式、二进制 Put/Get、随机记录、自清场
' 编译：fbc -w all -g -exx 16_files.bas -x 16_files.exe

Const TXT As String = "fb_demo_notes.txt"
Const BINF As String = "fb_demo_points.bin"
Const REC As String = "fb_demo_records.dat"

' ---- 1) Output 写 / Input 读 / Append 追加 ----
Dim As Integer h = FreeFile()
Var rc = Open(TXT For Output As #h)
Assert(rc = 0)
Print #h, "第一行"
Print #h, "数字也行:"; 42
Print #h, Using "pi=##.##"; 3.14159   ' 注意：Using 里 _ 是"下一字符字面量"转义，不是空格
Close #h

Dim As String line_
Dim As Integer lineCount = 0
rc = Open(TXT For Input As #h)
Assert(rc = 0)
Do Until Eof(h)
    Line Input #h, line_
    lineCount += 1
    Print "  读到["; lineCount; "]: "; line_
Loop
Close #h
Assert(lineCount = 3)

Open TXT For Append As #h
Print #h, "追加的一行"
Close #h
Open TXT For Input As #h
lineCount = 0
Do Until Eof(h) : Line Input #h, line_ : lineCount += 1 : Loop
Close #h
Print "追加后共 "; lineCount; " 行"
Assert(lineCount = 4)

' ---- 2) Binary：裸字节流，Put/Get 任意类型 ----
Type PointRec
    x As Double
    y As Double
End Type

Open BINF For Binary As #h
For i As Integer = 1 To 3
    Put #h, , Type<PointRec>(i * 1.0, i * i * 1.0)
Next
Close #h

Dim pr As PointRec
Open BINF For Binary As #h
Print "文件大小(LOF) ="; LOF(h)        ' 预计 3 * 16 = 48（LOF 收文件号）
Assert(LOF(h) = 3 * Sizeof(PointRec))
Get #h, , pr                          ' 读第一条
Close #h
Print "第 1 条: ("; pr.x; ", "; pr.y; ")"
Assert(pr.x = 1 And pr.y = 1)

' 定位读第二条（Seek 按字节；记录号从 1 起的写法见随机模式）
Open BINF For Binary As #h
Seek #h, Sizeof(PointRec) + 1         ' 跳过第 1 条（字节偏移从 1 计！）
Get #h, , pr
Close #h
Assert(pr.x = 2 And pr.y = 4)
Print "第 2 条: ("; pr.x; ", "; pr.y; ")"

' ---- 3) Random：定长记录按记录号直存直取（QB 传统艺能）----
Type Employee
    id As Integer
    name_ As String * 12              ' 定长字段是随机记录的关键
    score As Double
End Type

Open REC For Random As #h Len = Sizeof(Employee)
Put #h, 1, Type<Employee>(7, "alice", 91.5)      ' 直接写 2 号位
Put #h, 3, Type<Employee>(9, "carol", 88.0)
Put #h, 2, Type<Employee>(8, "bob", 75.25)       ' 乱序写也行

Dim emp As Employee
Get #h, 2, emp                                    ' 按记录号读
Print "记录 2: id="; emp.id; " name="; RTrim(emp.name_); " score="; emp.score
Assert(emp.id = 8 And RTrim(emp.name_) = "bob")

Get #h, 3, emp
Assert(emp.id = 9 And emp.score = 88.0)
Print "记录 3: id="; emp.id; " name="; RTrim(emp.name_)

Print "记录数(LOF/Len) ="; LOF(h) \ Sizeof(Employee)
Assert(LOF(h) \ Sizeof(Employee) = 3)
Close #h

' ---- 4) Open Cons：往真控制台写（gfx 场景的救星，18 章）----
Open Cons For Output As #h
Print #h, "Open Cons 输出走标准输出（Print 在 gfx 模式会进图形窗）"
Close #h

' ---- 5) 自清场 ----
Kill TXT : Kill BINF : Kill REC
Print "临时文件已清理"
Print "Dir 探测: "; Dir(TXT)
Assert(Dir(TXT) = "")

Print "[OK] 16_files"
End 0
