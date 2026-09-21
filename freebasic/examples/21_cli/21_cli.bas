' 21_cli.bas —— 命令行程序：参数、环境、目录、自制选项解析
' 编译：fbc -w all -g -exx 21_cli.bas -x 21_cli.exe
' 验证脚本无参运行本示例；带参玩法见章内说明。

#Include Once "dir.bi"              ' fbDirectory 等 Dir() 属性常量

' ---- 1) 参数三件套：Command() / __FB_ARGC__ / __FB_ARGV__ ----
Print "== 命令行 =="
Print "Command(-1) 全参数串 = ["; Command(-1); "]"
Print "__FB_ARGC__ ="; __FB_ARGC__
For i As Integer = 0 To __FB_ARGC__ - 1
    Print "  argv["; i; "] = "; *__FB_ARGV__[i]
Next
Assert(__FB_ARGC__ >= 1)             ' 至少有程序名

' ---- 2) 环境：Environ 读 / SetEnviron 写 ----
Print "== 环境 =="
SetEnviron "FB_DEMO_OPT=42"           ' 注意：单参 "名字=值" 形式
Print "FB_DEMO_OPT ="; Environ("FB_DEMO_OPT")
Assert(Environ("FB_DEMO_OPT") = "42")
#ifdef __FB_WIN32__
Dim user_ As String = Environ("USERNAME")        ' Windows 恒有 USERNAME
Print "USERNAME ="; user_
#else
Dim user_ As String = Environ("USER")            ' Linux/macOS 惯例是 USER（USERNAME 常为空）
Print "USER ="; user_
#endif
Assert(Len(user_) > 0)

' ---- 3) 目录与可执行文件 ----
Print "== 路径 =="
Print "CurDir ="; CurDir()
Print "ExePath ="; ExePath()
Assert(CurDir() <> "")

MkDir "fb_cli_tmp"
ChDir "fb_cli_tmp"
Print "进入子目录后 CurDir ="; CurDir()
ChDir ".."
RmDir "fb_cli_tmp"
Assert(Dir("fb_cli_tmp", fbDirectory) = "")   ' 已删除

' ---- 4) Dir() 模式遍历 ----
Print "== Dir() 遍历本目录 .bas =="
Dim count As Integer = 0
Dim f As String = Dir("*.bas")
Do While f <> ""
    count += 1
    Print "  "; f
    f = Dir()
Loop
Print "共 "; count; " 个 .bas"
Assert(count >= 1)

' ---- 5) 自制选项解析（getopt 简化版：--name X / --repeat N / 位置参数）----
Type CliOptions
    name_ As String
    repeat_ As Integer
    args(Any) As String              ' 动态数组收位置参数
    argCount As Integer
End Type

Sub parseArgs(argc As Integer, argv() As String, ByRef opt As CliOptions)
    opt.name_ = "world"
    opt.repeat_ = 1
    Dim i As Integer = 1             ' 0 号是程序名，跳过
    While i <= argc
        Var a = argv(i)
        If a = "--name" AndAlso i < argc Then
            i += 1
            opt.name_ = argv(i)
        ElseIf a = "--repeat" AndAlso i < argc Then
            i += 1
            opt.repeat_ = ValInt(argv(i))
        ElseIf Left(a, 1) = "-" Then
            ' 未知选项：忽略（严谨实现应报错）
        Else
            opt.argCount += 1
            Redim Preserve opt.args(0 To opt.argCount - 1)
            opt.args(opt.argCount - 1) = a
        End If
        i += 1
    Wend
End Sub

' 模拟一组参数做确定性验证（真实场景把 __FB_ARGV__ 内容拷进来即可）
Dim fakeArgv(0 To 4) As String = { "prog", "--name", "fbc", "--repeat", "3" }
Dim As CliOptions opt
parseArgs(4, fakeArgv(), opt)
Print "== 解析结果 =="
Print "name="; opt.name_; " repeat="; opt.repeat_
Assert(opt.name_ = "fbc" And opt.repeat_ = 3)

Dim fake2(0 To 2) As String = { "prog", "alpha", "beta" }
Dim As CliOptions opt2
parseArgs(2, fake2(), opt2)
Print "默认 name="; opt2.name_; " 位置参数 "; opt2.argCount; " 个"
Assert(opt2.name_ = "world" And opt2.argCount = 2)
Assert(opt2.args(0) = "alpha" And opt2.args(1) = "beta")

Print "[OK] 21_cli"
End 0
