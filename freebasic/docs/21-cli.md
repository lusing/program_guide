# 21 · 命令行程序

> 对应示例：`examples/21_cli/`

## 21.1 参数三件套

```freebasic
Command(-1)        ' 完整参数串（不含程序名；无参数时为空串——实测）
Command()          ' 第 1 个参数
__FB_ARGC__        ' 参数个数（含程序名，从 1 起）
*__FB_ARGV__[i]    ' 第 i 个参数（ZString 指针，解引用得 String）
```

`__FB_ARGV__` 是 `ZString Ptr` 数组——这就是 C 的 `argv`，可直接递给接受 `ZString Ptr` 的 C 函数。

## 21.2 环境变量

```freebasic
Dim path_ As String = Environ("PATH")     ' 读
SetEnviron "FB_DEMO_OPT=42"               ' 写：单参 "名字=值"（两参数版是错的，实测）
Print Environ("FB_DEMO_OPT")
```

`SetEnviron` 改的是**本进程**的环境（传给子进程可见），不改注册表/父进程。

## 21.3 目录与文件系统

```freebasic
CurDir()                    ' 当前工作目录
ExePath()                   ' exe 所在目录（找配置文件用它，别用 CurDir）
ChDir "sub" : MkDir "tmp" : RmDir "tmp"

Dim f As String = Dir("*.bas")            ' 第一个匹配
Do While f <> ""                          ' 继续遍历
    f = Dir()
Loop

' 目录属性过滤（常量在 dir.bi）：
#Include Once "dir.bi"
f = Dir("*", fbDirectory)
```

## 21.4 执行外部程序

```freebasic
Var rc = Shell("cmd /c mytool.exe")   ' 同步执行，返回退出码
Exec("notepad", "readme.txt")         ' 也是执行（带参数分离）
```

`Shell` 走 `cmd`，返回码就是子进程的。注意转义与注入——拼用户输入进命令串前三思。

## 21.5 自制选项解析

FB 没有 getopt。_cli 教科书模式（示例有完整实现）：

```freebasic
Type CliOptions
    name_ As String
    repeat_ As Integer
    args(Any) As String              ' 位置参数动态数组
    argCount As Integer
End Type

Sub parseArgs(argc As Integer, argv() As String, ByRef opt As CliOptions)
    ' --name X / --repeat N / 其他 = 位置参数
End Sub
```

要点：**默认值先填**（缺省 `name_="world"`）、未知选项的策略想清楚（忽略/报错）、位置参数 `Redim Preserve` 追加。测试时喂 `fakeArgv()` 数组做确定性验证，不依赖真实命令行——CI 友好。

## 21.6 坑位清单（1.10.1 实测）

1. `Command(-1)` 无参数时是**空串**不是程序名；要程序名用 `*__FB_ARGV__[0]`。
2. `SetEnviron` 单参数 `"名字=值"`；`SetEnviron 名, 值` 两参数版直接编译错。
3. `fbDirectory` 等属性常量要 `#Include Once "dir.bi"`（vbcompat.bi 里也有）。
4. 找 exe 旁边的资源用 `ExePath()`，`CurDir()` 是用户运行时的目录——两者经常不同。
5. `Dir()` 是**游标式**遍历：第一次带模式，后续空参取下一个；中途改遍历别的模式会丢游标。
