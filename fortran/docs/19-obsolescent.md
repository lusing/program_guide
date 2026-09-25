# 第 19 章 · 老特性考古 II：DATA、语句函数与 alternate return

对应示例：`72-obsolescent.f`（固定格式，走 legacy 编译通道）

第 71 号示例演示过隐式类型、COMMON、EQUIVALENCE 这三件 FORTRAN 77 招牌。这一章再考古一批：它们还躺在你能拿到的大批生产代码和老教材里（本教程参考的两本 2017/2018 年的中文教材就在教它们），但每一个都已有更好的现代写法。**这一章的目标是「读得懂」，不是「用得上」。**

本章特性横跨「仍标准」「已过时（obsolescent，警告）」「已删除（deleted，拒绝）」三档。「标准说什么」和「编译器做什么」是两回事 —— 下表的状态列来自标准，后两列是本机实测（`-std=f2018 -pedantic`）：

| 特性 | 标准状态 | flang 23 | gfortran 16 | 现代替代 |
|---|---|---|---|---|
| `DATA` 语句 | 仍标准（有限制） | 接受 | 接受 | 声明时初始化 `integer :: n = 0` |
| `SAVE` 局部变量 | 仍标准 | 接受 | 接受 | 声明时初始化（隐含 SAVE） |
| 语句函数 | F2018 起过时 | **照单全收、零警告** | 警告 Obsolescent | 内部函数 / `elemental function` |
| `PAUSE` 语句 | F95 已删除 | **接受，仅 portability 警告** | **拒绝编译** | `read(*,'(a)')` 等回车 / 调试器断点 |
| alternate return | F2018 起过时 | 照单全收 | 警告 Obsolescent | 返回整数错误码，调用方 `select case` |
| `EXTERNAL` / `INTRINSIC` | 仍活着（语义靠约定） | 接受 | 接受 | `interface` + `procedure()` 哑元 |
| 算术 `GO TO` / 计算 `GO TO` | 前者 F95 删、后者 F2018 删 | —— | 拒绝 | `if` / `select case` |

两条实测教训：**flang 不替你挡这些特性**（连 F95 就删了的 PAUSE 都给编），指望编译器报警不如自己不写；反过来 gfortran 对 obsolescent 特性只警告不拒绝 —— `-pedantic` 下「警告为零」的纪律（第 29 章）正是为了把这些灰区清零。

### DATA 语句：编译期赋初值的老办法

```fortran
integer :: a(5), i
data a /1, 2, 3, 4, 5/                 ! 逐元素初值
data a /5*0/                           ! 重复因子：5 个 0
data (a(i), i = 1, 3) /7, 8, 9/       ! 隐 DO 只给前 3 个赋值
data a /1.5, 2.5/                     ! 实数初值 → 自动转整（截断！）
```

四个细节，每个都是坑：

1. **DATA 是说明性语句**，动作发生在程序运行**之前**（初始化静态存储），不是运行到那一行才赋值 —— 它写在循环里也不会执行 n 次。
2. **重复因子 `n*值`** 与数组构造器里的 `n*值` 写法相同，含义也相同 —— 那个写法就是从 DATA 继承来的。
3. **类型不匹配自动转换**：给整型数组喂 `1.5`，得到 1。编译器一声不吭。`-std=f2018 -pedantic` 下 gfortran 会警告，别忽略这种警告。
4. 初值落位后的变量隐含 `SAVE` —— **过程里的 DATA 变量在多次调用间保值**。这一点和「声明时初始化」一致（后者也隐含 SAVE），但和普通局部变量（每次调用无定义）不同，是初学者最容易想错的地方。

现代写法一行顶 DATA 一行还带类型检查：

```fortran
integer :: a(5) = [1, 2, 3, 4, 5]      ! 声明 + 构造器初始化
```

DATA 今天仅剩的合理场景：给「无初始化语法的对象」赋初值 —— 比如派生类型数组想只初始化个别分量时。其他场合一律用声明时初始化。

### 语句函数：一行函数的 1960 年方案

```fortran
f(x) = x*x + x + 1.0                   ! 一条语句定义一个函数
...
y = f(2.0) + f(3.0)                    ! 像调内部函数一样用
```

规则：定义必须放在**所有可执行语句之前**；只有本程序单元可见；虚参只能是普通变量名；**不能递归**；函数体必须单行装得下。它是「表达式级的小工具」—— 在没有内部函数的年代，`diag(a,b) = sqrt(a*a + b*b)` 这种一次性小函数只能这么写。

Fortran 90 引入内部过程后它就没有存在必要了，Fortran 2018 把它标记为过时（gfortran 在 `-std=f2018 -pedantic` 下警告；flang 干脆照单全收）。现代等价物：

```fortran
contains
  elemental real(real64) function f(x)
    real(real64), intent(in) :: x
    f = x*x + x + 1.0_real64
  end function f
```

多几行，换来的是：类型显式、可以递归、可以多行、可以 `pure`/`elemental`、别的程序单元经模块还能复用。读老代码见到 `名字(虚参) = 表达式` 出现在说明部，认出它是语句函数即可。

### PAUSE：半个世纪前的「断点」

```fortran
pause 200          ! 打印 "PAUSE 200"，等操作员按回车再继续
```

PAUSE 的设计场景是批处理年代：程序跑到关键处停下，操作员检查打印机输出，确认无误后放行。交互式调试器出现后它就失业了，Fortran 95 将其删除。

为什么本教程不实测它：gfortran 在 legacy 模式下遇到 `pause` 会往 stderr 打一行 `PAUSE` 然后等 stdin —— 在自动验证脚本里等于挂死程序。这本身就说明它属于另一个时代。今天的对应物是调试器断点（第 28 章），或者「等待确认」就老实写 `read(*,'(a)') dummy`。

### alternate return：子程序的多个出口

```fortran
      SUBROUTINE CHECK(N, *, *)
      ...
      IF (N > 0) RETURN 1          ! 返回后跳到调用方的标号 100
      IF (N < 0) RETURN 2          ! 返回后跳到调用方的标号 200
      END

      CALL CHECK(N, *100, *200)    ! *冠名的标号做「返回地址」
  100 ...                           ! N > 0 走这里
  200 ...                           ! N < 0 走这里
```

虚参表里的 `*` 对应实参里的 `*标号`，`RETURN n` 跳到第 n 个标号。一个入口、多个出口 —— 这正是结构化程序设计（第 3 章）明确反对的形态：调用点之后的控制流要看被调方脸色，程序无法局部推理。F2018 把它标记为过时（两个编译器目前都还编译，gfortran 给警告）。

现代等价物是再朴素不过的「错误码模式」：

```fortran
call check(n, status)
select case (status)
case (0);    ! 正常
case (1);    ! n > 0 的处理
case (2);    ! n < 0 的处理
end select
```

示例 72 里 alternate return 段与这段现代写法并排放着，对照着看最直观。

### EXTERNAL 与 INTRINSIC：过程名做实参的老声明

把函数名当参数传（数值积分传被积函数、求根传目标函数）时，老代码必须先声明「这个名字是过程，不是变量」：

```fortran
      EXTERNAL FUNC          ! 用户写的函数子程序
      INTRINSIC SIN          ! 编译器的内部函数
      CALL INTEGRATE(FUNC, A, B)
      CALL INTEGRATE(SIN,  A, B)
```

不写 EXTERNAL，编译器会把 `FUNC` 当普通实数变量；不写 INTRINSIC，`SIN` 会被当作用户外部函数去链接，链接器找不到就报错。这套「靠声明消歧」的机制在 implicit none + 接口面前全面过时 —— 现代写法（第 14 章）用 `procedure` 哑元 + 显式接口：

```fortran
subroutine integrate(f, a, b)
  procedure(func_iface) :: f     ! 接口说了算，不需要 EXTERNAL
  ...
end subroutine
```

顺带一提第 31 章的坑：泛型内部函数（`sin`、`exp`）**不能**直接做实参，老代码里因此常见 `INTRINSIC DSIN`（专用双精度名）—— 现代做法是拿 `interface` 包一层具体种类的函数再传。

### 这一章的正确打开方式

这些特性的共同点：**都在某个历史阶段解决过真问题**（内存稀缺、没有内部函数、没有调试器、没有错误码约定），然后都被更好的机制取代。读老代码时它们是词汇表；写新代码时，上表右列就是全部答案。判断一段老代码「能不能照抄」，最快的办法是丢给 `-std=f2018 -pedantic` 编一遍 —— 但注意上表的 flang 列：它对老特性宽大为怀，**同一份代码在 flang 全绿、在 gfortran 警告/报错是常态**（第 32 章差异清单新增了几条）。双编译器互相校准，在老代码面前尤其值钱。

顺带记一条 legacy 通道的实测差异：flang 拒绝「同一数组元素被两条 DATA 语句重复初始化」，gfortran `-std=legacy` 容忍（后者覆盖前者）—— 示例 72 因此用两个数组分别演示，而不是对同一数组先整体赋值再局部覆盖。

---

上一章：[第 18 章 指针与可分配变量](18-pointers.md) ｜ 下一章：[第 20 章 泛型、重载与 submodule](20-generics.md) ｜ 返回：[README](../README.md)
