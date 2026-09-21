# FreeBASIC CHEATSheet（fbc 1.10.1 win64 / 1.10.2 linux-x86_64 实测）

语法速查 + 坑位索引。每行都以本机实测为准，标注与"直觉/老教程"相反的条目 ⚠。

## 编译

```bash
fbc -w all -g -exx app.bas -x app.exe    # 验证层：零警告 + 断言 + 边界/空指针检查
fbc -w all app.bas -x app.exe            # 发布层
fbc -lang qb legacy.bas                   # QB 方言（22 章）
fbc -pp app.bas                           # 看宏展开
fbc main.bas mod.bas -x out.exe           # 多文件：第一个是主模块
```

## 类型（win64）

| 写法 | 字节 | 备注 |
|---|---|---|
| `Integer`/`UInteger` | **8** | ⚠ 指针宽——win64 上 8，别当 C int 用 |
| `Long` | 4 | ⚠ 恒 4 字节（两平台一致）；C 的 int 映射到它——⚠ 但 linux-x86_64 的 C `long` 是 8，用 `LongInt`/`clong` |
| `LongInt` | 8 | 恒 64 位 |
| `Single`/`Double` | 4/8 | 小数字面量默认 Double |
| `String` | 24(描述符) | 变长；`Len` = **UTF-8 字节数** |
| `ZString * N` | N 缓冲 | C 字符串 |
| `WString * N` | 2N | Windows = UTF-16（Linux = UTF-32，码元 4 字节）；⚠ 中文字面量会按 GBK 误解（无 BOM 源，Windows 构建） |

## 声明

```freebasic
Dim a As Integer = 1, b As Double = 2.5
Var x = 3.14                       ' 推断；⚠ Dim x = 1（无 As）在 -lang fb 编译错
Const PI As Double = 3.14          ' Const 可省 As
Dim Shared g As Integer            ' 模块级全局
Static n As Integer = 0            ' 过程级静态（初始化仅一次）
Dim ByRef r As Integer = x         ' 引用别名
Dim arr(1 To 5) As Integer = {1,2,3,4,5}    ' 下界自选
Redim dyn(1 To 3) As Integer : Redim Preserve dyn(1 To 9)   ' ⚠ 动态数组必须 Redim 起步
```

## 运算符

| 类 | 写法 |
|---|---|
| 算术 | `+ - * /` `\`(整除) `Mod` `^`(乘方) |
| 逻辑 | ⚠ `AndAlso`/`OrElse` 短路；`And`/`Or`/`Xor`/`Not` **位运算不短路** |
| 移位 | `Shl` `Shr` |
| 字符串 | `&`（拼接）`+`（两边须均字符串） |
| 比较 | `= <> < <= > >=`；⚠ 字符串比较**区分大小写**（qb 方言不区分） |

## 控制流

```freebasic
If c Then ... ElseIf c2 Then ... Else ... End If
Select Case x
    Case 1, 3, 5            ' 枚举
    Case 2 To 8             ' 范围
    Case Is > 100           ' ⚠ Is 占位符，不能写 Case x > 100
    Case Else
End Select
For i As Integer = 5 To 1 Step -2 : ... : Next
Do While c : ... : Loop      /  Do : ... : Loop Until c
While c : ... : Wend
Exit For/Do/Function/Sub      Continue For/Do
Iif(c, a, b)                  ' ⚠ 1.10 实测惰性求值（老教程说双求值已过时）
```

## 过程

```freebasic
Sub s(ByVal n As Integer, ByRef out_ As Integer)   ' ⚠ 默认：标量 ByVal，String/UDT/数组 ByRef
Function f(a As Integer = 5) As Integer : Return a : End Function
Sub threadMain(ByVal ud As Any Ptr)                ' 线程入口（win64 别加 Cdecl）
Function cmp Cdecl (ByVal a As Any Ptr, ...) As Long   ' 给 C 当回调：必须 Cdecl
```

- ⚠ 函数**不能返回数组**——ByRef 出参代劳。
- 数组参数 `a() As Integer`，调用 `f(arr())`。

## OOP

```freebasic
Type Base Extends Object            ' 有虚方法必须显式继承 Object
    Public: / Private: / Protected:
    Declare Constructor(x As Double = 0)
    Declare Destructor()
    Declare Property w() As Double
    Declare Property w(v As Double)
    Static count As Integer                          ' Type 外定义：Static Base.count As Integer = 0
    Declare Abstract Function area() As Double       ' 抽象（类随之不可实例化）
    Declare Virtual Function describe() As String    ' 虚
End Type
Type Derived Extends Base
    Declare Function area() As Double Override       ' ⚠ Override 只写 Declare 行
End Type
Constructor Derived(x As Double) : Base(...) : End Constructor
Virtual Function Base.describe() As String : ...     ' 体外定义带前缀
```

## 运算符重载

```freebasic
Operator + (ByRef a As Vec, ByRef b As Vec) As Vec   ' 双目 → 全局
Declare Operator += (ByRef rhs As Vec)               ' ⚠ 复合赋值/Cast → 必须成员
Declare Operator Cast() As String
Declare Operator For()/Step()/Next(ByRef endCond As T) As Integer   ' 自定义 For 迭代
```

## 文件

```freebasic
Dim As Integer h = FreeFile()          ' ⚠ 文件号必须 >= 1（0 = runtime error 1）
If Open("x.txt" For Input As #h) <> 0 Then ...   ' ⚠ Open 返回错误码（Err 恒 0）
' 模式：Input / Output / Append / Binary / Random
Line Input #h, s                       ' 整行读
Put #h, , udt / Get #h, , udt          ' 二进制
Put #h, recno, udt                     ' Random 按记录号（从 1 计）
Open Cons For Output As #h             ' gfx 模式下控制台输出的唯一通道
LOF(h) ⚠ 收文件号（FileLen 收文件名）
```

## GFX

```freebasic
ScreenRes 320, 200, 32 : WindowTitle "t"
' ⚠ ScreenRes 后 Print 进图形窗——控制台用 Open Cons
Line (x1,y1)-(x2,y2), c, bf    ' bf 实心；B 边框；⚠ 无 B = 对角线
Circle (x,y), r, c : PSet (x,y), c : Draw String (x,y), "s", c
RGB(r,g,b) / Point(x,y)         ' ⚠ 全线 0xAARRGGBB（RGB 宏自带 FF alpha）
Dim img As Any Ptr = ImageCreate(w, h) : Put (x,y), img, PSet
Point(x, y, img)                 ' ⚠ 图像自身坐标系
Inkey / GetKey / MultiKey(SC_UP) ' ⚠ SC_* 在 namespace FB 里（Using FB）
Sleep ms                         ' 到点或按键即续；Sleep 无参 = 等键
```

## 线程

```freebasic
Dim As Any Ptr t = ThreadCreate(@main_, @ctx) : ThreadWait(t)
mtx = MutexCreate() : MutexLock(mtx) ... MutexUnlock(mtx) : MutexDestroy(mtx)
cond = CondCreate()
MutexLock(m) : While Not ready : CondWait(cond, m) : Wend : MutexUnlock(m)   ' While 防 虚假唤醒
CondSignal(cond) / CondBroadcast(cond)
```

## 错误处理

```freebasic
If Open(...) <> 0 Then ...      ' 返回码（正解）
Assert(cond)                    ' ⚠ 由 -g 激活（-e/-ex/-exx 都不激活）；单参数无消息
On Error Goto handler           ' -lang fb 下半残：捕不到 Open 失败；Resume 仅 qb/fblite
```

## 1.10.1 坑位总索引

1. ⚠ 源码**无 BOM**：带 BOM → 字面量转 GBK + 宽字符输出，管道验证报废
2. ⚠ `Assert` 由 **-g** 激活（老文档说 -e/-exx）
3. ⚠ `Integer` win64/linux-x86_64 = 8 字节；`Long` 恒 4（但 linux 上 C `long`=8，互操作用 `LongInt`/`clong`）
4. ⚠ `Cast` 转整数 = 银行家舍入（截断用 `Fix`/`Int`）
5. ⚠ `True` = -1（Print 显示 true/false）
6. ⚠ `And/Or` 不短路——指针判空用 `AndAlso`
7. ⚠ `Iif` 已惰性求值
8. ⚠ 默认传参按类型分：标量 ByVal / String·UDT·数组 ByRef
9. ⚠ 函数不能返回数组；`Type()` 初始化器不能嵌套
10. ⚠ `ChrW` 不存在叫 `WChr`；无内建 Split/Replace/Join
11. ⚠ `Dim` 局部/UDT 字段默认清零（两种方言皆然）
12. ⚠ 固定数组不能 `Redim`；`Redim Preserve` 只能动最后一维
13. ⚠ `Override` 只在 Declare 行；基类无默认构造器 → 派生初始化报 error 188
14. ⚠ 复合赋值运算符重载必须成员；回调给 C 必须 `Cdecl`（ThreadCreate 入口相反）
15. ⚠ `Open` 失败 `Err` 恒 0——查返回码
16. ⚠ `Timer` 语义随平台：Windows = 开机至今秒数，Linux = Unix epoch 秒（非自午夜）；`Format` 分钟是 `n`
17. ⚠ `Format`/日期函数须 `vbcompat.bi`；`fbDirectory` 须 `dir.bi`；`SC_*` 须 `Using FB`
18. ⚠ gfx：无 B 的 Line 画对角线；Cls 颜色参数 32bpp 不生效；Print 进图形窗；Linux 走 X11（WSL2 需 WSLg，headless 用 `xvfb-run`）
19. ⚠ `SetEnviron` 单参 `"名=值"`；`Command(-1)` 无参为空串；用户名变量 Windows `USERNAME` / Linux `USER`
20. ⚠ `Gosub/Resume/行号/变量后缀` 仅 qb/fblite 方言；qb 字符串比较不区分大小写
21. ⚠ Linux 互操作：`crt/*.bi` 不导出宏——`_SC_*`(84/85/30)、`CLOCK_MONOTONIC`(1) 手写 `#define`；无 `Extern "Windows"`，统一 `Extern "C"`
22. ⚠ `Print Using` 格式串里 `_` 是转义前缀（"clock_gettime" 印成 "clockgettime"）；`Shell`：Windows 走 `cmd /c`，Linux 走 `/bin/sh`
