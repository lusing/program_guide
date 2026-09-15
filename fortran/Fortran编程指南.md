# Fortran 编程指南

一份面向「会写别的语言，但没写过 Fortran」的人的教程。全书 24 章，配 24 个可运行示例（22 个现代 `.f90` + 2 个 FORTRAN 77 风格的固定格式 `.f`），每个示例都在 **LLVM flang 23** 和 **GNU Fortran 15** 两个编译器上实测通过。

学完你会明白：现代 Fortran 不是「老古董」，它是一门**为数值计算而生、但已经长出模块系统和面向对象**的语言。它所有看起来奇怪的地方 —— 列主序、1 起下标、传引用、`implicit none` 必须写、数组整体运算 —— 都是同一个前提的推论：**让科学家写的公式，能几乎一对一地敲进代码**。

> 本指南里所有的「实测」「报错」「差异」都不是从文档抄的，是在本机两个编译器上真的撞出来的。第 23、24 章是完整的坑清单。

---

## 目录

1. [语言概览：Fortran 到底在干什么](#第-1-章-语言概览fortran-到底在干什么)
2. [工具链与运行方式](#第-2-章-工具链与运行方式)
3. [程序结构、类型与 KIND](#第-3-章-程序结构类型与-kind)
4. [表达式、运算符与数值陷阱](#第-4-章-表达式运算符与数值陷阱)
5. [控制流](#第-5-章-控制流)
6. [数组（一）：声明、构造、切片](#第-6-章-数组一声明构造切片)
7. [数组（二）：内建函数](#第-7-章-数组二内建函数)
8. [字符与字符串](#第-8-章-字符与字符串)
9. [格式化 I/O](#第-9-章-格式化-io)
10. [文件与流 I/O](#第-10-章-文件与流-io)
11. [过程：子程序、函数与参数传递](#第-11-章-过程子程序函数与参数传递)
12. [模块、接口与模块目录](#第-12-章-模块接口与模块目录)
13. [派生类型](#第-13-章-派生类型)
14. [面向对象与多态](#第-14-章-面向对象与多态)
15. [指针与可分配变量](#第-15-章-指针与可分配变量)
16. [泛型、重载与 submodule](#第-16-章-泛型重载与-submodule)
17. [经典算法](#第-17-章-经典算法)
18. [数值计算](#第-18-章-数值计算)
19. [随机数与统计](#第-19-章-随机数与统计)
20. [C 互操作](#第-20-章-c-互操作)
21. [并行计算：OpenMP 与 do concurrent](#第-21-章-并行计算openmp-与-do-concurrent)
22. [错误处理与单元测试](#第-22-章-错误处理与单元测试)
23. [坑清单（与编译器无关）](#第-23-章-坑清单与编译器无关)
24. [双编译器差异清单与可移植写法](#第-24-章-双编译器差异清单与可移植写法)

---

## 第 1 章 语言概览：Fortran 到底在干什么

### 历史与发展：一门为公式而生的语言

FORTRAN 是 **FOR**mula **TRAN**slation（公式翻译）的缩写。1954 年，IBM 的 John Backus 立项做一件事：让科学家把数学公式**几乎原样**敲进计算机，而不是手写汇编。1957 年 FORTRAN I 交付，编译出来的浮点循环能和手写汇编打平 —— 这在当时是惊人成就，也一举证明了「高级语言」这条路走得通。

理解它 1957 年的出身，这门语言里几乎所有「奇怪」的设计都解释得通：打孔卡片版面（本章末尾的固定格式）、1 起下标（数学惯用）、传引用（当年复制内存太贵）、数列主序（先变第一个下标）、`GOTO` 满天飞（还没有结构化编程的概念）。它比 Lisp 早一年、比 C 早 15 年，是**今天仍在生产环境大规模使用的最古老高级语言**。

演进脉络，一张表看完（年份按标准发布）：

| 年份 | 标准名 | 关键变化 |
|---|---|---|
| 1957 | FORTRAN I（IBM 实现） | 公式翻译成机器码，证明高级语言可行 |
| 1958–62 | FORTRAN II / IV | 子程序与独立编译，成为科学界的通用语言 |
| 1966 | FORTRAN 66 | 第一个正式标准，各厂商实现有了共同基准 |
| 1978 | FORTRAN 77 | `CHARACTER` 类型、块 `IF`/`ELSE`/`END IF`；此后 15 年是「老 Fortran」的黄金期，海量遗留代码都长这样 |
| 1991 | **Fortran 90** | 大重构：自由格式、`module`/`use`、动态内存（`allocate`）、数组整体运算与切片、递归。**拼写从全大写 FORTRAN 改为 Fortran** —— 老资料大写、新资料首字母大写，以此分界 |
| 1997 | Fortran 95 | `pure`/`elemental` 过程等小修 |
| 2004 | Fortran 2003 | 面向对象（类型绑定、`class` 多态）、C 互操作（`iso_c_binding`）进标准 —— 这版之后它是货真价实的现代语言 |
| 2010 | Fortran 2008 | `do concurrent`、`submodule`、coarray 并行 |
| 2018 | Fortran 2018 | **本书的基线标准**；C 互操作进一步增强 |
| 2023 | Fortran 2023 | 最新标准，继续小步迭代 |

一个值得记住的事实：**Fortran 90 是分水岭**。90 之前的代码（`.f` 固定格式）和之后的（`.f90` 自由格式）几乎是两门语言的样子，但它们可以互相调用、在同一个程序里链接 —— 60 多年不翻脸的向后兼容，是这门语言统治科学计算 60 多年的原因，也是它所有历史包袱的来源。

### 长处与不足：什么时候选它，什么时候绕开

**长处** —— 为什么 2026 年了，天气预报、气候模拟、核仿真、计算流体力学还在用甚至新写 Fortran：

1. **数组是一等公民。** 整体运算、切片、`where` 掩码都是语法，不是库。代码长得像公式，编译器还因此拿到了最大的向量化空间（它看得见整个数组操作，不用像 C 那样在循环里猜）。
2. **性能密度高。** 传引用零拷贝、列主序对缓存友好、60 多年针对浮点循环的编译器优化积累。同样的数值代码，Fortran 往往比手写 C 更短也更快。
3. **并行是一等公民。** OpenMP 指令、`do concurrent`、coarray，见第 21 章。
4. **数值生态厚且久经考验。** BLAS/LAPACK 这类基石库是 Fortran 写的；几个主流天气预报模式至今是 Fortran 代码库，跑在全世界最贵的超算上。
5. **代码保值。** 1977 年的数值代码今天多半还能编译运行 —— 没有哪个主流语言敢这么承诺。

**不足** —— 同样要清楚，免得错配：

1. **生态边界极窄。** 出了数值计算，Web、GUI、脚本化、机器学习前端，几乎没有像样的库。
2. **构建与包管理年轻。** fpm 2021 年才出现，离 cargo/pip 的成熟度还有距离；现实里的 Fortran 工程还在和 Makefile、CMake 纠缠。
3. **文本处理弱。** 定长字符串是默认、没有内建 split 和正则 —— 第 8 章那点字符串操作就是全部家底。
4. **历史包袱要靠纪律对抗。** 隐式类型规则、1 起下标、与 C 互操作时的列主序错位 —— 每一条本书都花了力气讲怎么防。
5. **编译器差异比主流语言大。** 同一份代码 flang 和 gfortran 都会各让你撞几回（第 24 章的清单就是实证）；新特性在不同编译器里落地快慢不一。
6. **社区小、就业面窄。** 学习资料少、Stack Overflow 活跃度低，遇到怪问题往往只能读编译器文档。

一句话结论：**数值密集、数组大、性能敏感** —— Fortran 至今是一线选择；除此之外，选别的语言不会后悔。

### 三个观念

如果你从 C 或 Python 过来，最先要调整的是三个观念。

**观念一：数组是语言的一等公民，不是「指向首元素的指针」。**

```fortran
real(real64) :: a(1000), b(1000), c(1000)
c = a * 2.0_real64 + b          ! 一行搞定 1000 个元素
where (c < 0.0_real64) c = 0.0_real64   ! 带掩码的赋值
```

没有 `for` 循环，编译器知道怎么向量化。C 里你得写循环或者调 BLAS，Fortran 里这就是语法。

**观念二：内存是「列主序」（column-major）。**

```fortran
integer :: m(2, 3)       ! 2 行 3 列
m = reshape([1,2,3,4,5,6], [2, 3])
! m(1,:) = 1 3 5
! m(2,:) = 2 4 6
```

`reshape` 按**列**填充：先把第 1 列填满，再填第 2 列。这跟 C、NumPy（默认行主序）正好相反。写数值代码时这个顺序决定了缓存命中率 —— 遍历二维数组应当**先变第一维**：

```fortran
do j = 1, n
  do i = 1, m      ! 内层走第一维 = 内存连续
    ...
  end do
end do
```

这也是跟 C 交互时最容易翻车的地方（见第 20 章）。

**观念三：默认是「传引用」，且没有 `const` 的保护。**

```fortran
subroutine scale(x, k)
  real(real64), intent(inout) :: x(:)
  real(real64), intent(in)    :: k
  x = x * k                  ! 直接改到调用者的数组上，不复制
end subroutine
```

`intent(in)` 是你能给的最强承诺：进来只读，不会被改。**每个哑元都写 `intent`**，这是现代 Fortran 最重要的习惯 —— 它既是文档，也是编译器优化的依据。

再补三条最容易忘的：

- **`implicit none` 必须写在每个程序单元的开头。** 不写的话，`x = 1.0` 里那个没声明的 `x` 会被默认为 `real`，拼错变量名不会有任何报错。这一条是 Fortran 历史上最大的坑，新代码一律写。
- **大小写不敏感。** `DO`/`do`/`Do` 一样，`MyVar` 和 `myvar` 是同一个变量。但**字符串字面量里的大小写是有意义的**。
- **空格在自由格式下无意义。** `do i = 1, n` 和 `doi=1,n` 一样。所以 `do i = 1. 10` 会被解析成 `do i = 1.10`（赋值给变量 `i`），这是经典事故 —— 别省那个逗号。

### 固定格式与自由格式：打孔卡片的遗产

**为什么会有「格式」这回事。** Fortran 早年唯一的数据输入方式是打孔卡片：一张卡片 80 列，一列一个字符，一张卡一行代码。卡片有可能散落一地，所以要留出**最后 8 列（73–80）写卡片序号**，散了也能按号重排。程序能用的只有前 72 列，这个物理限制直到今天还在编译器里活着。

**固定格式的列规则**（`.f` / `.for` / `.f77` 后缀，编译器按后缀自动选）：

| 列 | 用途 | 说明 |
|---|---|---|
| 第 1 列 | `C` 或 `*` | 整行是注释 |
| 第 1–5 列 | 语句标号 | 右对齐，给 `FORMAT`、循环终点、`GOTO` 用 |
| 第 6 列 | 续行标志 | 放任意非空格字符，本行就接上一行 |
| 第 7–72 列 | 语句正文 | **只有这 66 列能写代码** |
| 第 73–80 列 | 卡片序号 | 编译器无视，但写了会被当语句截掉 |

**自由格式**（`.f90` / `.f95` / `.f03` / `.f08` 后缀）是 Fortran 90 的产物，用现代习惯重立了规矩：缩进随意、一行 132 列、`!` 引导注释、行尾 `&` 续行。两种格式的日常写法对照：

| | 固定格式（.f） | 自由格式（.f90） |
|---|---|---|
| 注释 | 第 1 列写 `C` | 行内任意位置 `!` 之后 |
| 续行 | 第 6 列放非空格字符 | 行尾 `&`（下行可再放 `&` 接住） |
| 行长上限 | 语句只许到第 72 列 | 132 列 |
| 循环结尾 | `DO 100 ... 100 CONTINUE` | `DO ... END DO` |
| 大小写 | 传统上全大写 | 惯例小写 |

**今天还要不要懂固定格式？** 要 —— 不是为了怀旧：气象、核工程、油气领域仍有海量 FORTRAN 77 代码在生产环境运行，读得懂它们是拿这份工资的一部分。本仓库的示例 70、71 就是两个能编译能运行的 FORTRAN 77 风格 `.f`，注释里逐条给了现代对照写法；老代码不带 `-pedantic` 跑（gfortran 用 `-std=legacy`，flang 23 干脆不写 `-std`——它不认 legacy，不加本来就接受）。**新代码一律 `.f90` 自由格式**，这就是本仓库其余 22 个示例的格式。

---

## 第 2 章 工具链与运行方式

### 两个编译器

| 工具 | 路径 | 版本 | 定位 |
|---|---|---|---|
| `flang-mp-23` | `/opt/local/bin/flang-mp-23` | flang 23.1.0（LLVM 23） | 主通道 |
| `gfortran-mp-15` | `/opt/local/bin/gfortran-mp-15` | GNU Fortran 15.2.0 | 对照通道 |

为什么要两个？因为在 macOS 上它们各有硬伤，**互补**才能把示例写全：

- flang 缺 `real128`、参数化派生类型、共数组、`-fcheck`，**尤其缺 `omp_lib` 模块**（于是 `use omp_lib` 编译不过）。
- gfortran 在 F2018 语法上更保守：`forall` 带类型声明它会拒绝，`pure function` 带 `intent(inout)` 它按标准报错。

只用其中一个，你会误以为某些特性「Fortran 不支持」。用两个，你才知道边界在哪 —— 这也正是第 24 章那份差异清单的来源。

### 编译命令

```bash
flang-mp-23 -std=f2018 -pedantic -O2 -J build/mod/flang examples/01-basics.f90 -o build/01-basics.flang
gfortran-mp-15 -std=f2018 -pedantic -O2 -J build/mod/gfortran examples/01-basics.f90 -o build/01-basics.gfortran
```

逐条解释：

| 参数 | 作用 | 为什么这么选 |
|---|---|---|
| `-std=f2018` | 按 Fortran 2018 标准检查 | 不写的话编译器会接受一堆历史遗留语法，学不到正确的写法 |
| `-pedantic` | 对标准之外的扩展报诊断 | **本仓库把警告当错误**：stderr 非空即判失败 |
| `-O2` | 开优化 | 能暴露出「未初始化变量」「别名假设」这类只有优化时才显形的问题 |
| `-J <dir>` | 指定 `.mod` 模块文件目录 | 两个编译器共用一个目录会互相覆盖，必须分开 |
| `-fopenmp` | 开 OpenMP | 只在源码含 `!$omp` 时加，脚本自动判断 |

单文件示例一条命令就完成编译 + 链接。多文件工程才需要 `-c` 分步编译再链接。

### 三条通道与结束标记

每个示例都跑三条通道：flang 编译运行、gfortran 编译运行、两边的 stdout 逐字节 `cmp`。

每个示例的最后一行一定是：

```fortran
write (*, '(a)') '==== 01 结束 ===='
```

这个标记是判定「程序真的跑完了」的依据。没有它的话，一个中途 `stop` 掉的程序也可能退出码 0、stderr 干净 —— 看起来「通过」了。

所以判定标准是四条同时满足：

1. 退出码 0
2. stderr 为空（`-pedantic` 下警告也算问题）
3. stdout 无多余控制字符（见第 9 章的「格式重现」）
4. stdout 有 `==== NN 结束 ====`

第 3 条是编写本仓库时才加上去的。原因见第 9 章。

### 两个入口

```bash
./run-all.sh          # shell 版，只打摘要
./run-all.sh -v       # 附带完整输出
./run-all.sh 05 06    # 只跑指定编号
```

```powershell
pwsh ./build.ps1 -All
pwsh ./build.ps1 -File 12-derived-types.f90
pwsh ./build.ps1 -Clean
```

两者判定逻辑完全一致，实测结果也一致。

---

## 第 3 章 程序结构、类型与 KIND

对应示例：`01-basics.f90`、`02-kinds.f90`

### 最小程序

```fortran
program hello
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  write (*, '(a)') '你好，Fortran'
  print '(a,i0)', '2 + 3 = ', 2 + 3
end program hello
```

- `program`/`end program` 是一对，`end program hello` 里写名字是可选的良好习惯。
- `print` 是 `write(*,)` 的简写，两者功能相同。`write` 更通用（能指定 unit），本仓库统一用 `write`。
- `use, intrinsic :: iso_fortran_env, only: int32, real64` —— 标准库里定义 KIND 常量的模块，`only:` 限制导入范围。

### KIND 才是 Fortran 的类型系统

Fortran 里 `real` 不是一个确定精度的类型，而是一个**种类参数**。正确写法：

```fortran
use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64

integer(int32) :: n = 100
real(real64)   :: x = 3.141592653589793_real64
complex(real64) :: z = (1.0_real64, -2.0_real64)
logical :: flag = .true.
character(len=32) :: name = 'fortran'
```

为什么不能偷懒写 `real`？因为 `real` 的精度**由编译器决定**，换平台可能变。`real64` 保证是 IEEE 双精度。

字面量也要带 KIND 后缀：`3.141592653589793_real64`。不带后缀的实数默认是单精度 —— 写 `x = 3.141592653589793` 会先按单精度四舍五入再赋给双精度变量，精度就这么丢了。这是数值代码里最常见的隐性错误。

### 查询类型的性质

```fortran
integer(int32) :: i
real(real64)   :: x

write (*, '(a,i0)') 'int32 的极大值  : ', huge(i)     ! 2147483647
write (*, '(a,i0)') 'int32 的位数    : ', digits(i)   ! 31
write (*, '(a,i0)') 'real64 的有效位 : ', digits(x)   ! 53
write (*, '(a,i0)') 'real64 的十进制位: ', precision(x) ! 15
write (*, '(a,i0)') 'real64 指数范围 : ', range(x)    ! 307
write (*, '(a,es15.6e3)') 'real64 的极大值: ', huge(x) ! 1.797693E+308
write (*, '(a,es15.6e3)') 'real64 的极小正数: ', tiny(x) ! 2.225074E-308
write (*, '(a,es15.6e3)') 'real64 的机器精度: ', epsilon(x) ! 2.220446E-016
```

注意 `huge(x)` 那行 —— 它用的是 `es15.6e3` 而不是常见的 `es13.6`。原因见第 23 章第 3 条：`es` 不带 `Ee` 时指数只占 2 位，`E+308` 会被挤成 `+308` 甚至更糟。

### 按需求选择 KIND

不是所有平台都有 `real64` 之上的精度，写死 `real128` 会编译失败。正确姿势：

```fortran
integer, parameter :: wp = selected_real_kind(15, 307)   ! 要 15 位有效数字、10^307 量级
integer, parameter :: ip = selected_int_kind(9)            ! 要能装下 10^9

real(wp) :: x
integer(ip) :: n
```

`selected_real_kind` 返回**能满足要求的最小 KIND**，如果没有任何类型满足就返回 `-1`。示例 02 里就打印了这个：

```fortran
write (*, '(a,i0)') 'selected_real_kind(30) = ', selected_real_kind(30)
! flang 23 打印 -1（没有四倍精度）
! gfortran 15 打印 16（有 real128）
```

这就是为什么本仓库的示例全部用 `real64` 而不碰 `real128`。

### 其他字面量写法

```fortran
integer(int32), parameter :: mask = z'FF'        ! 十六进制
integer(int32), parameter :: bits = b'1010'      ! 二进制
integer(int32), parameter :: oct  = o'17'        ! 八进制
character(len=1), parameter :: c = achar(65)     ! 'A'
character(len=1), parameter :: ch = char(65, kind=c_char)
```

### 常量：`parameter`

```fortran
real(real64), parameter :: pi = 3.14159265358979323846_real64
integer, parameter      :: max_iter = 1000
real(real64), parameter :: coef(3) = [1.0_real64, 2.0_real64, 3.0_real64]
```

`parameter` 是编译期常量，可以用来定义数组维度、作为 `case` 分支、传给需要常量的场合。它比 `const` 更强：真的会被折叠进代码。

---

## 第 4 章 表达式、运算符与数值陷阱

对应示例：`03-expressions.f90`

### 优先级

从高到低：

```
**                            （幂，右结合）
*  /                          （乘除）
+  -                          （加减）
//                            （字符串拼接）
==  /=  <  <=  >  >=          （关系）
.not.                         （逻辑非）
.and.
.or.
.eqv.  .neqv.
```

**`**` 是右结合的**：`2**3**2` = `2**(3**2)` = 512，不是 `(2**3)**2` = 64。

### 头号陷阱：整数除法

```fortran
write (*, '(a,i0)') '7 / 2     = ', 7 / 2          ! 3
write (*, '(a,f10.4)') '7 / 2     = ', 7 / 2        ! 3.0000   ← 先整除再转实数
write (*, '(a,f10.4)') 'real(7)/2 = ', real(7, real64) / 2.0_real64  ! 3.5000
```

`7 / 2` 两个操作数都是整数，结果是整数 3。**先算完再转类型，转不回来。**

同样的坑在数组和函数返回值上：

```fortran
average = sum(a) / size(a)                    ! 错：整数除法
average = real(sum(a), real64) / real(size(a), real64)   ! 对
```

### 混合模式运算

不同 KIND 混算时，结果取**更宽的那个**：

```fortran
real(real32) :: a = 1.0_real32
real(real64) :: b = 2.0_real64
! a + b 的结果是 real64
```

但字面量陷阱还在：`a + 1.5` 里的 `1.5` 是 `real32`，没问题；`x_real64 + 1.5` 里 `1.5` 是单精度的 1.5（这个数在单精度里精确），但如果写 `1.1` 就不精确了。**养成习惯：所有实数字面量都带 `_real64` 后缀。**

### 幂运算的两个坑

```fortran
write (*, '(a,f0.6)') '2.0 ** 0.5 = ', 2.0_real64 ** 0.5_real64   ! 1.414214
write (*, '(a,f0.6)') '2.0 ** (-2) = ', 2.0_real64 ** (-2)        ! 0.250000
write (*, '(a,i0)')   '2 ** 3 ** 2 = ', 2 ** 3 ** 2               ! 512（右结合）
```

**负数的实数次幂**：`(-8.0_real64) ** (1.0_real64/3.0_real64)` 不会给你 `-2.0`，而是产生 NaN —— 因为浮点幂运算是用 `exp(y*log(x))` 实现的，`log(负数)` 无定义。要算立方根得自己处理符号。

### 关系运算与浮点比较

```fortran
real(real64), parameter :: eps = 1.0e-12_real64
if (abs(a - b) < eps) then
  ! 认为相等
end if
```

**永远不要用 `==` 比较浮点数。** 示例 21 的测试框架里专门提供了 `assert_close` 而不是只给 `assert_eq_r`，就是为了这个。

### 字符串拼接

```fortran
character(len=32) :: s
s = 'Hello' // ', ' // 'World'     ! // 是拼接，+ 不是
```

### 一点性能常识

- `**2` 和 `*x` 相比，编译器通常能识别平方并优化，但 `**n` 的整数次幂不用想太多，用 `x*x*x` 更稳。
- `sqrt`、`abs`、`exp`、`sin` 都是 `elemental` 内建函数，可以直接作用在数组上。
- 整数除法和取模对负数的行为：Fortran 的 `mod` 结果符号跟被除数一致，`modulo` 结果符号跟除数一致。分不清就选 `modulo`。

```fortran
write (*, '(a,i3)') 'mod(-7, 3)    = ', mod(-7, 3)       ! -1
write (*, '(a,i3)') 'modulo(-7, 3) = ', modulo(-7, 3)    !  2
```

---

## 第 5 章 控制流

对应示例：`04-control-flow.f90`

### if 结构

```fortran
if (x > 0.0_real64) then
  ...
else if (x < 0.0_real64) then
  ...
else
  ...
end if

! 单行形式
if (n < 0) n = 0
```

注意 `end if` 是两个词（`endif` 也行），`else if` 是分着的。

### select case

```fortran
select case (n)
case (0)
  write (*, '(a)') '零'
case (1:9)
  write (*, '(a)') '个位数'
case (10, 20, 30)
  write (*, '(a)') '整十'
case default
  write (*, '(a)') '其他'
end select
```

`case (1:9)` 是范围，`case (10,20,30)` 是枚举。比 C 的 `switch` 强的地方：**默认不会穿透**，不用写 `break`。类型上 `case` 的选择器可以是整数、字符、逻辑。

### 循环

```fortran
do i = 1, 10            ! 1..10，含两端
do i = 10, 1, -1        ! 倒序，步长 -1
do i = 1, 10, 2         ! 1,3,5,7,9
do while (condition)    ! 条件循环
do                      ! 无限循环，靠 exit 跳出
end do
```

**Fortran 的 `do` 循环边界在进入循环时求值一次**，循环体内改 `n` 不影响次数：

```fortran
n = 5
do i = 1, n
  n = 100              ! 不影响循环次数，仍是 5 次
end do
```

这跟 Python 的 `range` 类似，跟 C 的 `for(i=0;i<n;i++)` 不同。

### 命名循环、exit 与 cycle

```fortran
outer: do i = 1, 3
  inner: do j = 1, 3
    if (i == j) cycle inner        ! 跳过本轮内层
    if (i * j > 4) exit outer       ! 直接跳出外层
    write (*, '(2(a,i0))') 'i=', i, ' j=', j
  end do inner
end do outer
```

`exit` = `break`，`cycle` = `continue`。**可以带循环名跳出多层**，这是 C 里得用 `goto` 的场合。

### where / elsewhere：带掩码的数组赋值

```fortran
real(real64) :: c(6)
c = [1.0_real64, -2.0_real64, 3.0_real64, -4.0_real64, 5.0_real64, -6.0_real64]

where (c < 0.0_real64)
  c = 0.0_real64
elsewhere
  c = c * 10.0_real64
end where
! 结果：10 0 30 0 50 0
```

这是 Fortran 特有的语法，等价于一个元素级的三元表达式，但**不会越界**（掩码为假的元素根本不参与计算）。比 `merge` 更安全，因为 `merge(c*2, 0, mask)` 会先把所有元素都算一遍。

> 顺带一句：老教材里的 `forall` 已经过时了（gfortran 在 `-pedantic` 下直接警告）。能用 `where` 的地方就用 `where`，能写成数组整体运算的就别用 `forall`。

### merge：函数式的三元

```fortran
write (*, '(3i5)') merge(a, b, mask)    ! mask 为真取 a，否则取 b
```

注意 `merge` 的两个分支都会被求值，只是结果被丢掉 —— 所以别在分支里写有副作用的表达式。

### associate：给表达式起个短名字

```fortran
associate (m2 => matmul(a, b), n => size(a, 1))
  write (*, '(a,i0)') 'n = ', n
  write (*, '(a,f0.3)') 'trace = ', m2(1,1) + m2(2,2)
end associate
```

`associate` 是**别名**，不是拷贝 —— 改 `m2` 不会改到原数组（因为它是个表达式的结果），但 `associate (p => a)` 里改 `p` 就会改到 `a`。想清楚再用。

### block：局部作用域

```fortran
block
  integer(int32) :: tmp(3)
  tmp = b(1:3)
  b(2:4) = tmp
end block
```

`block` 里声明的变量出了块就没了，可以用 `import` 引用外层变量。示例 05 用它来创建处理「数组节重叠赋值」的临时副本，示例 20 则踩到了它的一个 flang 限制（见第 24 章第 6 条）。

---

## 第 6 章 数组（一）：声明、构造、切片

对应示例：`05-arrays-basics.f90`

### 声明与下标范围

```fortran
integer(int32) :: a(5)          ! 下标 1..5，默认下界是 1
integer(int32) :: b(0:4)        ! 下标 0..4，自定义下界
integer(int32) :: m(2, 3)       ! 二维，先变第一维（列主序）
real(real64)   :: r(4) = [1.0_real64, 2.0_real64, 3.0_real64, 4.0_real64]
integer, parameter :: n = 8
real(real64)   :: dyn(-n:n)     ! 用常量表达式做边界
```

### 数组构造器

```fortran
a = [10, 20, 30, 40, 50]
b = [(i, i = 0, 4)]              ! 隐式 do：0 1 2 3 4
sq = [(i*i, i = 1, 5)]           ! 平方：1 4 9 16 25
evens = [(i, i = 2, 6, 2)]       ! 带步长：2 4 6
```

`[...]` 是 F2003 起的写法，老代码里的 `(/ ... /)` 等价。

**注意**：构造器里所有元素必须同类型同 KIND。写 `[1, 2.0]` 是错的，得写 `[real(real64) :: 1, 2.0_real64]`：

```fortran
write (*, '(a,4f7.1)') '2) [real::1,2,3,4] : ', [real(real64) :: 1, 2, 3, 4]
```

### 整体运算（Elemental）

```fortran
a = a * 2 + 1            ! 每个元素都做
sq = sq + evens(1)       ! 标量广播到整个数组
write (*, '(a,4f7.2)') 'sqrt(r) : ', sqrt(r)     ! 内建函数直接作用
write (*, '(a,4l3)')   'r > 2   : ', r > 2.0_real64  ! 得到 logical 数组
```

**这是 Fortran 相对 C 最大的生产力优势**。没有循环，没有 `for_each`，编译器还知道怎么向量化。

### 切片与跨步

```fortran
a(1:3)       ! 前三个
a(1:5:2)     ! 奇数位：a(1), a(3), a(5)
a(:)         ! 整个数组
a(5:1:-1)    ! 倒序 —— 注意这是 5 个元素，不是 3 个
a(5:3:-1)    ! 只要后三个的倒序
```

**步长为负时元素个数是 `(last - first + stride) / stride`**。

- `a(5:1:-1)` → `(1 - 5 + (-1)) / (-1)` = 5 个
- `a(5:3:-1)` → `(3 - 5 + (-1)) / (-1)` = 3 个
- `a(1:5:-1)` → 空节，0 个（方向反了）

这个公式一定要记牢。写 `write(*,'(a,3i5)') 'x', a(5:1:-1)` 是不对的 —— 描述符只有 3 个但数据有 5 个，会触发「格式重现」，见第 9 章。

验证一下：

```fortran
write (*, '(a,i0)') 'size(a(5:1:-1)) = ', size(a(5:1:-1))   ! 5
write (*, '(a,i0)') 'size(a(1:5:-1)) = ', size(a(1:5:-1))   ! 0
```

### 切片可以整体赋值

```fortran
a(2:4) = [0, 0, 0]
a(1:3) = a(4:6) * 2.0_real64
```

**但源和目标不能重叠**（标准明确禁止）：

```fortran
b(2:4) = b(1:3)      ! 错：a 既是输入又是输出，结果是实现相关的
```

正确做法是先存临时副本：

```fortran
block
  integer(int32) :: tmp(3)
  tmp = b(1:3)
  b(2:4) = tmp
end block
```

### 边界查询

```fortran
lbound(m)      ! 每维下界 → [1, 1]
ubound(m)      ! 每维上界 → [2, 3]
shape(m)       ! 形状 → [2, 3]
size(m)        ! 元素总数 → 6
size(m, 1)     ! 第 1 维长度 → 2
rank(m)        ! 维数 → 2
```

多态和过程里传数组时，这些函数是你的安全带 —— 永远用 `size(x)`，不要假设它有多大。

---

## 第 7 章 数组（二）：内建函数

对应示例：`06-arrays-intrinsics.f90`

Fortran 的数组内建函数库非常全，很多在 NumPy 里要写好几遍的东西这里一个函数就够。

### 归约

```fortran
sum(v)          product(v)      maxval(v)       minval(v)
count(mask)     any(mask)       all(mask)       parity(mask)
```

`parity` 是「掩码里真值的个数是否为奇数」，相当于 `count(...) mod 2 == 1`。

### dim= 与 mask= 参数

```fortran
sum(m, dim=1)          ! 沿第 1 维求和：结果形状少一维
maxval(m, dim=1)
sum(v, mask=(v > 3))   ! 只统计满足条件的位置
count(mask = (v > 3))
maxval(v, mask=(v < 5))
```

`dim=` 的语义：**沿着这一维做归约，结果的维数降 1**。

```fortran
integer(int32) :: m(2, 3)
! m = reshape([1,2,3,4,5,6], [2,3])  →  m(1,:)=1 3 5,  m(2,:)=2 4 6
write (*, '(a,3i4)') 'sum(m, dim=1) : ', sum(m, dim=1)    ! 3 7 9   ← 形状 (3)
write (*, '(a,2i4)') 'sum(m, dim=2) : ', sum(m, dim=2)    ! 9 12    ← 形状 (2)
```

**这里有个容易写错的点**：`m` 是 (2,3)，`sum(m, dim=1)` 的结果形状是 **(3)**，不是 2。格式描述符要按结果写。写 `(a,2i5)` 配一个 3 元素结果，就会触发格式重现，输出里混进整数的原始字节。这是真实踩过的坑。

### 定位

```fortran
maxloc(v)                        ! 最大值的位置
minloc(v)
maxloc(m)                        ! 二维返回两个下标
findloc(v, 3)                    ! 第一个等于 3 的位置
findloc(v, 3, back=.true.)       ! 从后往前找
findloc(v, 3, mask=(v > 0))      ! 带掩码
```

要的是**值**就用 `maxval`，要的是**位置**就用 `maxloc`。

### 线代

```fortran
dot_product(v, w)        ! 内积
norm2(v)                 ! 欧几里得范数 sqrt(sum(v**2))
matmul(a, b)             ! 矩阵乘
transpose(m)             ! 转置
```

`matmul` 会检查维度匹配，不匹配报运行时错误。`transpose` 返回的是转置后的数组（不共享内存）。

### 重塑与重排

```fortran
reshape(lin, [2, 3])                     ! 按列填充
reshape(x, [4, 6], pad=[0])              ! 不够的部分补 0
reshape(x, [4, 6], order=[2, 1])         ! 改变填充顺序
```

### 选取与构造

```fortran
spread([1,2], 1, 3)          ! 沿第 1 维复制 3 次 → 3×2
pack(v, mask)                ! 把掩码为真的元素打包成更短的数组
unpack(short, mask, 0)       ! 反向：按掩码放回去，其余填 0
```

`pack` 在「提取所有满足条件的值」时特别顺手：

```fortran
write (*, '(a,3i5)') 'pack 后长度 3 : ', pack(v, v > 3)
```

### 循环移位

```fortran
cshift(v, 2)                 ! 循环左移 2
cshift(v, -2)                ! 循环右移 2
eoshift(v, 2)                ! 末端补 0 的左移
eoshift(v, -1, b=-1)         ! 指定填充值
```

`cshift` 是环形回绕，`eoshift` 是「移位丢掉的补填充值」。

### 位运算归约

```fortran
iall(bits)        ! 所有元素按位与
iany(bits)        ! 所有元素按位或
iparity(bits)     ! 所有元素按位异或
```

这三个是「所有元素」级的归约，和 `sum`/`product` 同层次。

### 一个提醒

内建函数里 `sin`、`exp`、`max` 这些**泛型名不能直接当过程实参**。想把它传给接受 `procedure()` 的过程，得先包一层：

```fortran
interface
  pure function my_sin(x) result(y)
    real(real64), intent(in) :: x
    real(real64) :: y
  end function
end interface

y = apply(my_sin, 1.0_real64)     ! 而不能写 apply(sin, 1.0_real64)
```

---

## 第 8 章 字符与字符串

对应示例：`07-strings.f90`

### 两种字符串

```fortran
character(len=32) :: fixed = '定长'       ! 声明时定长，永远占 32 字节
character(len=:), allocatable :: dyn      ! 延迟长度，运行时决定
dyn = 'hello'
dyn = 'a much longer string'              ! 自动重新分配
```

定长字符串赋值时会**自动填充空格**到声明长度，比较也会忽略尾空格（`==` 比较时短的一方当作空格补齐）。

### 零号陷阱：子串赋值

```fortran
character(len=8) :: cs
cs(1:1) = 'X'         ! 对
cs(1) = 'X'           ! 错！这是「调用名为 cs 的数组/函数」，编译报错
```

`cs(i)` 被解析成**引用 `cs` 的第 i 个元素**（像数组一样），只有 `cs(i:i)` 才是子串。两个编译器都会报 `'cs' is not a callable procedure`。

### 常用操作

```fortran
len_trim(s)             ! 去掉尾部空格后的长度
trim(s)                 ! 返回去尾空格的字符串（不改变原变量）
adjustl(s)              ! 左对齐，把前导空格挪到后面
adjustr(s)
index(s, 'foo')         ! 子串第一次出现的位置，没有返回 0
scan(s, 'aeiou')        ! 第一个属于字符集的位置
verify(s, 'aeiou')      ! 第一个不属于字符集的位置
repeat(s, 3)            ! 重复 3 次
s(3:5)                  ! 子串
```

### 类型转换

```fortran
! 数值 → 字符串（内部写）
character(len=32) :: buf
write (buf, '(i8)') 42

! 字符串 → 数值（内部读）
integer :: n
read (buf, *) n
```

**内部读的 unit 必须是字符变量，不能直接写字符串字面量**：

```fortran
read ('42', '(i5)') n        ! 错，两个编译器都拒绝
read (buf, '(i5)') n         ! 对
```

### 一个手写的 split

```fortran
subroutine split(s, sep, parts, n)
  character(len=*), intent(in)  :: s, sep
  character(len=*), intent(out) :: parts(:)
  integer, intent(out)          :: n
  integer :: p, q, k
  k = 0
  p = 1
  do
    q = index(s(p:), sep)
    if (q == 0) exit
    k = k + 1
    if (k > size(parts)) exit
    parts(k) = s(p : p + q - 2)
    p = p + q + len(sep) - 1
  end do
  if (k < size(parts) .and. p <= len_trim(s)) then
    k = k + 1
    parts(k) = s(p : len_trim(s))
  end if
  n = k
end subroutine
```

Fortran 标准库里没有 `split`，这是最常见的「缺件」之一。上面这段能正确处理连续分隔符之外的大多数情况。

### 一个真实的坑

```fortran
character(len=8) :: buf
buf = c_null_char     ! 只把第 1 个字符设成 NUL！
                      ! 剩下 7 个字节是空格，不是 NUL
```

想清空必须逐字符：

```fortran
do i = 1, len(buf)
  buf(i:i) = c_null_char
end do
```

这个坑在跟 C 互操作时很致命 —— C 的 `strlen` 会一直往后读，直到碰见真正的 NUL。详见第 20 章。

### 打印时的空格

`trim(s)` 只是「返回一个去掉了尾部空格的新字符串」，如果接收方是定长变量，赋值时又会补齐。要紧凑输出，直接用子串：

```fortran
character(len=64) :: colname
write (*, '(a,a)') 'name=', colname(1:len_trim(colname))
```

或者用 `s(1:12)` 这种固定切片。示例 22 里排表格时就是这么做的。

---

## 第 9 章 格式化 I/O

对应示例：`08-formatted-io.f90`

### 描述符速查

| 描述符 | 用途 | 例子 | 输出 |
|---|---|---|---|
| `iW` | 整数，宽度 W | `i5` | `  42` |
| `i0` | 整数，最小宽度 | `i0` | `42` |
| `fW.D` | 定点，宽 W 小数 D 位 | `f10.3` | `     3.142` |
| `f0.D` | 定点，最小宽度 | `f0.3` | `3.142`（**无前导零**：`0.5` → `.500`） |
| `eW.D` | 科学计数，指数 2 位 | `e12.4` | `  3.1416E+00` |
| `esW.D` | 科学计数（规范化） | `es12.4` | `  3.1416E+00` |
| `esW.DEe` | **指定指数位数** | `es15.6e3` | `  3.141593E+000` |
| `aW` | 字符，宽 W | `a` / `a10` | 原样 / 定宽 |
| `lW` | 逻辑 | `l1` | `T` / `F` |
| `x` | 一个空格 | `3x` | `   ` |
| `'...'` | 字面量 | `'x='` | `x=` |
| `/` | 换行 | `/,` | 新记录 |

### 括号里的重复

```fortran
write (*, '(a,5i5)') 'v : ', v          ! i5 重复 5 次
write (*, '(a,3i5)') 'w : ', w(1:3)
write (*, '(3(f8.3,2x))') a, b, c
```

`5i5` 就是 `i5,i5,i5,i5,i5` 的简写。

### 格式重现（Format Reversion）：本章最重要的一小节

当**数据项比描述符多**时，Fortran 不会报错，而是**从头再来一遍格式**（如果有嵌套括号组，则从最后一个组重来）：

```fortran
real(real64) :: arr(6)
arr = [(real(i, real64), i = 1, 6)]
write (*, '(a,f6.1)') 'arr : ', arr
! 输出：
! arr :   1.0
!   2.0
!   3.0
! ...
```

这里格式只有 1 个 `f6.1`，但有 6 个元素 —— 于是每一遍格式（也就是每个记录）放一个元素，共 6 行。这正是我们想要的表格换行效果。

**但当重复的那个描述符不是数字描述符时，就会出事**：

```fortran
integer(int32) :: a(5)
a = [10, 20, 30, 40, 50]
write (*, '(a,3i5)') 'a : ', a(5:1:-1)
```

`a(5:1:-1)` 有 **5** 个元素（见第 6 章），描述符只有 `a` + `3i5` 共 4 个。于是：

1. 第一遍：`a` ← 字符串 `'a : '`，`i5` 打印 50、40、30
2. 格式用完，还剩 20 和 10 → **重现**
3. 第二遍：`a` ← 整数 20！`(a)` 描述符拿到一个整数，编译器不等你，直接把它的**原始内存字节**当字符吐出来（小端 int32 的 20 = `14 00 00 00`）
4. `i5` ← 整数 10，打印 `   10`

于是 stdout 里出现了控制字符。

**输出里混进 NUL 字节，几乎百分百是描述符写少了。** 本仓库的验证脚本专门检查这一条，因为这种错误：

- 编译通过，没有任何警告
- 退出码 0，stderr 干净
- 肉眼翻看时那几行「就是有点怪」，很容易滑过去
- 但管道给别的程序、写进文件、或者上传到哪，都是脏数据

正确写法是按实际元素个数写描述符：

```fortran
write (*, '(a,5i5)') 'a : ', a(5:1:-1)     ! 5 个元素，5 个描述符
```

或者把数组切到描述符个数那么多：

```fortran
write (*, '(a,3i5)') 'a : ', a(5:3:-1)     ! 3 个元素
```

**规则记住：写数组进 I/O 列表前，先确认它的元素个数。**

### 内部写：把结果写进字符串

```fortran
character(len=16) :: buf
write (buf, '(f0.3)') 3.14159      ! buf = '3.142'
```

配合「运行时拼格式串」可以做动态宽度：

```fortran
character(len=32) :: spec
write (spec, '(a,i0,a)') '(f', width, '.', 3, ')'
write (*, spec) x
```

示例 18 里自定义类型 I/O 就用了这一招。

### dt 自定义 I/O（派生类型的格式化输出）

```fortran
module vecmod
  type :: vec3
    real(real64) :: x, y, z
  contains
    procedure :: write_vec
    generic :: write(formatted) => write_vec
  end type
contains
  subroutine write_vec(dtv, unit, iotype, v_list, iostat, iomsg)
    class(vec3), intent(in) :: dtv
    integer, intent(in) :: unit
    character(len=*), intent(in) :: iotype
    integer, intent(in) :: v_list(:)
    integer, intent(out) :: iostat
    character(len=*), intent(inout) :: iomsg
    write (unit, '(a,3f8.3)', iostat=iostat, iomsg=iomsg) '[', dtv%x, dtv%y, dtv%z
    write (unit, '(a)', iostat=iostat, iomsg=iomsg) ']'
  end subroutine
end module
```

定义好之后：

```fortran
write (*, '(a,dt)') 'v = ', v      ! v = [   1.000   2.000   3.000]
write (*, '(dt(10))') v            ! v_list 会收到 [10]
```

这是 Fortran 里「让自定义类型用起来像内建类型」的关键机制，配合第 16 章的运算符重载，能做到几乎无缝。

### namelist：按键名读写

```fortran
real(real64) :: alpha, beta
integer :: max_iter
namelist /params/ alpha, beta, max_iter

alpha = 1.0_real64; beta = 2.0_real64; max_iter = 100
write (*, nml=params)
open (newunit=u, file='params.nml', status='replace')
write (u, nml=params)
close (u)
```

**namelist 写出的排版由编译器决定** —— flang 和 gfortran 排出来的空格和换行不一样，所以示例 08 被列进了「已知差异」清单。读回来的能力是标准的，排版不要指望。

---

## 第 10 章 文件与流 I/O

对应示例：`09-files.f90`

### 打开文件：用 newunit

```fortran
integer :: u
open (newunit=u, file='data.txt', status='replace', action='write')
write (u, '(a)') 'hello'
close (u)
```

`newunit=` 让库分配一个**负数**的 unit 号，保证不会和你手动写的 `10`、`20` 撞车。**不要再写 `open(10, ...)` 这种老风格**，尤其是过程里 —— 两次调用撞同一个 unit 是经典 bug。

`status=` 的取值：

| 值 | 含义 |
|---|---|
| `'old'` | 文件必须存在 |
| `'new'` | 文件必须不存在 |
| `'replace'` | 有就覆盖，没有就建 |
| `'scratch'` | 临时文件，`close` 时自动删 |
| `'unknown'` | 默认行为（有则用，无则建） |

`action=`：`'read'` / `'write'` / `'readwrite'`。写清楚能提前捕获「打开方式不对」的错误。

### 四访问模式

| 模式 | 关键字 | 用途 |
|---|---|---|
| 有格式顺序 | `form='formatted'`（默认） | 文本文件 |
| 无格式顺序 | `form='unformatted'` | 二进制，快但不可移植 |
| 流 | `access='stream'` | 二进制，按字节偏移读写 |
| 直接 | `access='direct', recl=N` | 定长记录，可随机访问 |

流访问：

```fortran
open (newunit=u, file='bin.dat', access='stream', form='unformatted', status='replace')
write (u) 42                                  ! 写 4 字节
write (u) [1.0_real64, 2.0_real64]            ! 写 16 字节
close (u)
```

直接访问（随机读写定长记录）：

```fortran
open (newunit=u, file='recs.dat', access='direct', recl=16, status='replace')
write (u, rec=1) 100
write (u, rec=3) 300                          ! 直接跳到第 3 条记录
read (u, rec=2) x                             ! 读第 2 条
close (u)
```

### 用 inquire 问文件的状态

```fortran
logical :: ex, op
integer :: sz
inquire (file='data.txt', exist=ex, opened=op, size=sz)
```

`size=` 只对**已连接**的文件有意义；对没打开的普通文件，`size` 在多数实现里返回 -1 或不修改。示例 09 里演示了这个行为。

### 读写循环的标准写法

```fortran
integer :: ios
character(len=256) :: line
open (newunit=u, file='data.txt', status='old', action='read')
do
  read (u, '(a)', iostat=ios) line
  if (ios /= 0) exit              ! ios < 0 表示文件结束，> 0 表示出错
  write (*, '(a)') trim(line)
end do
close (u)
```

**`iostat=` 是 Fortran 里唯一可靠的「读到了吗」判断方式。** 不要靠「读回来的内容是不是空的」来判断，那在遇到空行时会出错。

---

## 第 11 章 过程：子程序、函数与参数传递

对应示例：`10-procedures.f90`

### 两种过程

```fortran
subroutine print_vec(v)          ! 子程序：靠参数传出结果
  real(real64), intent(in) :: v(:)
  write (*, '(a,3f8.3)') 'v = ', v
end subroutine print_vec

pure function norm2d(x, y) result(r)   ! 函数：有返回值
  real(real64), intent(in) :: x, y
  real(real64) :: r
  r = sqrt(x*x + y*y)
end function norm2d
```

- 子程序用 `call print_vec(v)`
- 函数用在表达式里：`d = norm2d(3.0_real64, 4.0_real64)`
- **函数应当尽量是 `pure` 的**（不修改任何东西，只靠参数算结果）。`pure` 让编译器能放心优化，也让读者放心。

### intent 三件套

```fortran
subroutine scale(x, k, ok)
  real(real64), intent(inout) :: x(:)     ! 会被改，且需要进来时的初值
  real(real64), intent(in)    :: k        ! 只读
  logical,      intent(out)   :: ok       ! 只写，进来时的值无意义
```

- `intent(in)`：只读，最安全
- `intent(out)`：只在赋值后才有定义，**不要把 `intent(out)` 当 `inout` 用**
- `intent(inout)`：读写

### 可选参数与关键字调用

```fortran
subroutine greet(name, prefix)
  character(len=*), intent(in) :: name
  character(len=*), intent(in), optional :: prefix
  if (present(prefix)) then
    write (*, '(a,a,a)') trim(prefix), ' ', trim(name)
  else
    write (*, '(a,a)') 'Hello, ', trim(name)
  end if
end subroutine
```

调用：

```fortran
call greet('Fortran')                        ! 用默认
call greet('Fortran', 'Hi')                  ! 位置调用
call greet(name='Fortran', prefix='Hi')      ! 关键字调用，顺序随意
```

关键字调用是个被低估的好东西：参数多了以后，调用点自己会说话。

### 数组哑元的三种形状

```fortran
real(real64), intent(in) :: a(:)       ! 一维，长度由调用者定
real(real64), intent(in) :: b(0:)      ! 一维，下界固定 0
real(real64), intent(in) :: c(:,:)     ! 二维，形状由调用者定
real(real64), intent(in) :: d(*)       ! 假定大小（不推荐，无法检查越界）
```

用 `(:)` 而不是固定长度，过程就能复用到不同大小的数组上。

### 内部过程与外部过程

```fortran
program procs
  implicit none
  call outer(5)
contains
  subroutine outer(n)                  ! 内部过程：能看见宿主的所有变量
    integer, intent(in) :: n
    call inner(n * 2)
  end subroutine
  subroutine inner(m)
    integer, intent(in) :: m
    write (*, '(a,i0)') 'm = ', m
  end subroutine
end program
```

内部过程写在 `contains` 之后，能访问宿主作用域的变量（这叫**宿主关联**）。方便，但也容易不小心改到宿主的变量，小脚本用它很好，大程序建议放模块里。

### 递归

```fortran
recursive function fact(n) result(r)
  integer, intent(in) :: n
  integer :: r
  if (n <= 1) then
    r = 1
  else
    r = n * fact(n - 1)
  end if
end function fact
```

**`recursive` 关键字必须写。** gfortran 严格按标准来，不写会报错；flang 有时会放行，但依赖这种行为是自找麻烦。

### 把内建函数包一层

前面提过，泛型内建函数不能直接当过程实参。示例 10 里演示了做法：

```fortran
pure function d_sin(x) result(y)
  real(real64), intent(in) :: x
  real(real64) :: y
  y = sin(x)
end function

! 现在可以传了
y = apply(d_sin, 1.0_real64)
```

### impure elemental

`elemental` 过程可以自动作用在数组上（像 `sqrt` 那样）。加上 `impure` 就允许它带副作用（比如往文件里写东西）：

```fortran
impure elemental subroutine log_it(x)
  real(real64), intent(in) :: x
  write (*, '(f8.3)') x        ! 有副作用，所以必须 impure
end subroutine

call log_it([1.0_real64, 2.0_real64, 3.0_real64])   ! 自动对每个元素调用
```

---

## 第 12 章 模块、接口与模块目录

对应示例：`11-modules.f90`

### 模块是 Fortran 的命名空间 + 库

```fortran
module mathlib
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private                              ! 默认全私有
  public :: area_circle, PI

  real(real64), parameter :: PI = 3.14159265358979323846_real64

contains
  pure function area_circle(r) result(a)
    real(real64), intent(in) :: r
    real(real64) :: a
    a = PI * r * r
  end function
end module mathlib
```

- `private` + 显式 `public` 是**推荐的默认姿态**：只有你主动公开的东西才对外可见。
- 模块里的过程自动拥有**显式接口**，调用方不需要写 `interface` 块，编译器也能做完整的参数检查。

### use 的各种姿势

```fortran
use mathlib                                   ! 全拿
use mathlib, only: area_circle                ! 只要一个
use mathlib, only: area => area_circle        ! 改名导入
use mathlib, only: operator(.ar.) => area_circle   ! 当运算符用
```

`only:` 不只是洁癖 —— 它能让名字冲突更容易发现，也让依赖关系一目了然。

### 模块目录：-J 参数

编译带模块的源文件时，编译器会生成 `.mod` 文件。用 `-J` 指定输出目录：

```bash
flang-mp-23 -std=f2018 -pedantic -O2 -J build/mod/flang examples/11-modules.f90 -o build/11
```

**两个编译器必须用不同的 `.mod` 目录。** `.mod` 是编译器私有的二进制格式，flang 和 gfortran 生成的互相不认。本仓库用 `build/mod/flang` 和 `build/mod/gfortran` 分开。

### 模块变量：全局状态的正确姿势

```fortran
module counter
  implicit none
  private
  public :: tick, current

  integer :: n = 0                     ! 模块变量，全程序唯一

contains
  subroutine tick()
    n = n + 1
  end subroutine
  pure integer function current()      ! 注意：不能 pure，因为它读模块变量
    current = n
  end function
end module
```

模块变量是 Fortran 里唯一的「全局变量」机制。用它可以，但**别滥用** —— 多线程下模块变量是竞态的高发区（见第 21 章）。

### submodule：把接口和实现分开

大型项目里，`.mod` 文件会因为「只改实现也导致连锁重编译」而拖慢构建。`submodule` 解决这个问题：

```fortran
! 父模块：只声明接口
module shapes
  implicit none
  interface
    module function area(r) result(a)
      real(real64), intent(in) :: r
      real(real64) :: a
    end function
  end interface
end module

! 子模块：放实现
submodule (shapes) shapes_impl
contains
  module function area(r) result(a)
    real(real64), intent(in) :: r
    real(real64) :: a
    a = 3.14159265358979323846_real64 * r * r
  end function
end submodule
```

改 `shapes_impl` 里的实现，用到 `shapes` 的其他代码**不需要重新编译**。示例 18 里有完整可运行的版本。

---

## 第 13 章 派生类型

对应示例：`12-derived-types.f90`

### 定义与构造

```fortran
type :: point
  real(real64) :: x = 0.0_real64
  real(real64) :: y = 0.0_real64
end type point

type(point) :: p
p = point(1.0_real64, 2.0_real64)     ! 位置构造器
p = point(x=1.0_real64)               ! 关键字构造器，y 用默认值
```

给分量写默认值是好习惯 —— 这样 `type(point) :: arr(100)` 直接就是全 0。

### 数组与可分配分量

```fortran
type :: matrix
  integer :: nrow = 0, ncol = 0
  real(real64), allocatable :: v(:,:)
end type

type(matrix) :: m
allocate (m%v(3, 3))
m%nrow = 3; m%ncol = 3
m%v = 0.0_real64
```

**可分配分量让类型能装任意大小的数据**，而且深拷贝语义是对的：

```fortran
type(matrix) :: a, b
allocate (a%v(1000, 1000))
b = a          ! 完整深拷贝，b%v 是独立的一块内存
```

这是 Fortran 相对 C 的一大优势 —— 没有指针语义的困扰，赋值就是拷贝。

### 嵌套类型

```fortran
type :: line
  type(point) :: p1, p2
end type

type(line) :: l
l = line(point(0.0_real64, 0.0_real64), point(3.0_real64, 4.0_real64))
```

### move_alloc：避免大数组拷贝

```fortran
real(real64), allocatable :: big(:), tmp(:)
allocate (tmp(1000000))
! ... 填 tmp ...
call move_alloc(tmp, big)      ! 把 tmp 的内存「移」给 big，不拷贝
! 现在 tmp 变成未分配状态
```

`move_alloc` 是 O(1) 的，把分配标记和内存一起转手。在「在函数里算完大数组再返回」的场合非常重要 —— 不然会有一次完整的拷贝。

### 一个经典错误

```fortran
type(point), allocatable :: pts(:)
allocate (pts(10))
! ...
deallocate (pts)      ! 忘了这句，再 allocate 就是错误
allocate (pts(20))
```

**重复 `allocate` 已分配的变量是错误。** gfortran 会在运行时直接报错终止，flang 有时宽容地放过 —— 别依赖这种宽容。要重新分配就先 `deallocate`，或者用 `allocate(..., stat=ios)` 检查：

```fortran
allocate (pts(20), stat=ios)
if (ios /= 0) then
  write (*, '(a,i0)') '分配失败，stat = ', ios
end if
```

注意 `stat` 的**具体数值两个编译器不一样**（示例 24 章第 12 条），只能判 `/= 0`，不能比具体数字。

---

## 第 14 章 面向对象与多态

对应示例：`13-oop.f90`

Fortran 2003 起就有了完整的 OOP。它不是「像 C++」，而是有自己的一套：

### 类型绑定过程

```fortran
type :: circle
  real(real64) :: r = 0.0_real64
contains
  procedure :: area => circle_area
  procedure :: describe => circle_describe
  generic :: operator(.lt.) => less_than
end type

contains
  pure function circle_area(self) result(a)
    class(circle), intent(in) :: self
    real(real64) :: a
    a = 3.14159265358979323846_real64 * self%r ** 2
  end function
```

调用就像访问成员：

```fortran
type(circle) :: c
c = circle(2.0_real64)
write (*, '(f0.4)') c%area()
```

### class 和 abstract

```fortran
type, abstract :: shape
  real(real64) :: scale = 1.0_real64
contains
  procedure(area_iface), deferred :: area      ! 延迟绑定：子类必须实现
  procedure :: describe => shape_describe      ! 有默认实现，可被覆写
end type

abstract interface
  pure function area_iface(self) result(a)
    import :: shape, real64
    class(shape), intent(in) :: self
    real(real64) :: a
  end function
end interface
```

- `type, abstract :: shape` —— 抽象类型，不能实例化
- `deferred` —— 子类**必须**实现，否则子类也是抽象的
- `abstract interface` 里必须 `import` 用到的名字

### extends：继承

```fortran
type, extends(shape) :: rect
  real(real64) :: w = 0.0_real64, h = 0.0_real64
contains
  procedure :: area => rect_area
end type

pure function rect_area(self) result(a)
  class(rect), intent(in) :: self
  real(real64) :: a
  a = self%w * self%h * self%scale     ! scale 是继承来的
end function
```

### 多态与 select type

```fortran
class(shape), allocatable :: s
s = circle(2.0_real64)                 ! 多态分配
write (*, '(f0.4)') s%area()           ! 动态派发，调用 circle 的版本

select type (s)
type is (circle)
  write (*, '(a,f0.3)') 'circle r = ', s%r
class is (rect)
  write (*, '(a,f0.3)') 'rect w = ', s%w
class default
  write (*, '(a)') 'unknown'
end select
```

**`select type` 是 Fortran 版的「类型分支」**，`type is` 是精确匹配，`class is` 包含子类。

### class(*)：无类型多态

```fortran
class(*), allocatable :: anything
anything = 42
anything = 'hello'
anything = 3.14_real64
```

能装任何类型，但要用必须先 `select type` 问它是什么。适合做「通用容器」。

### 多态数组

```fortran
class(shape), allocatable :: shapes(:)
allocate (shapes, source=[circle(1.0_real64), ...])   ! source= 推导具体类型
```

用 `source=` 分配能保证每个元素是自己真正的类型。直接用 `allocate(shapes(3))` 是不行的 —— 抽象类型没法凭空造实例。

### 终结器

```fortran
type :: resource
  integer :: handle = -1
contains
  final :: resource_cleanup
end type

subroutine resource_cleanup(self)
  type(resource), intent(inout) :: self
  if (self%handle >= 0) then
    ! 释放 handle
    self%handle = -1
  end if
end subroutine
```

**但不要指望终结器解决所有资源管理问题** —— 它不是析构函数，触发时机由编译器决定，且不保证在程序退出前一定执行。要可靠的资源管理，还是得显式写 `close`/`deallocate`，或者用可以显式调用的清理过程。

### 什么时候该用 OOP

说实话：**大部分数值代码不需要 OOP**。数组 + 模块 + `pure` 过程能解决 90% 的问题，而且更快（没有虚函数表、没有动态派发）。

OOP 值得用的场合是：

- 你有一族**行为随类型变化**的东西（不同的求解器、不同的几何形状、不同的边界条件）
- 你想让**调用方不关心具体类型**（写一套后处理代码，能处理所有 shape）
- 你要实现**类型擦除的容器**

示例 13 里把这些都跑了一遍，跑完你会知道什么时候该用、什么时候是过度设计。

---

## 第 15 章 指针与可分配变量

对应示例：`14-pointers.f90`

Fortran 的指针和 C 的指针**不是一回事**，先把这个搞清楚：

| | 可分配变量 `allocatable` | 指针 `pointer` |
|---|---|---|
| 语义 | 值语义 | 引用/别名语义 |
| `b = a` | **深拷贝**，b 是独立副本 | 让 b 也指向 a 的目标（浅） |
| 能指向已有变量 | 不能 | 能（配 `target`） |
| 改 b 影响 a | 不会 | 会 |
| 内存泄漏 | `deallocate` 即可 | 容易漏，需要主动 `nullify` |
| 推荐度 | **默认用它** | 只在需要时才用 |

### 值语义 vs 别名

```fortran
real(real64), allocatable :: a(:), b(:)
allocate (a(3))
a = [1.0_real64, 2.0_real64, 3.0_real64]
b = a                    ! 深拷贝
b(1) = 99.0_real64       ! a 不受影响

real(real64), pointer :: p(:), q(:)
real(real64), target :: t(3) = [1.0_real64, 2.0_real64, 3.0_real64]
p => t                   ! p 指向 t
q => p                   ! q 也指向 t
q(1) = 99.0_real64       ! t 被改了
```

**默认选 `allocatable`。** 只有下面这些场合才需要 `pointer`：

- 指向**已有变量**（比如函数想返回数组的某一段）
- 再造数据结构（链表、树）—— 因为需要引用语义
- 想在两个名字之间共享同一块内存

### target 与 associated

```fortran
real(real64), target :: x = 1.0_real64
real(real64), pointer :: px
px => x
if (associated(px)) write (*, '(a)') 'px 有目标'
if (associated(px, x)) write (*, '(a)') 'px 指向 x'
nullify(px)                                  ! 断开
```

**只有被声明为 `target` 的变量才能被指针指向。** 这是编译器能优化矩阵运算的关键 —— 没有 `target` 声明的变量，编译器可以放心假设「没有别人在背后改它」。

### 指针切片

```fortran
real(real64), pointer :: mid(:)
real(real64), target :: arr(10)
mid => arr(4:7)              ! 指向中间一段，改 mid 就是改 arr
```

Pointer slicing 是 `pointer` 相对 `allocatable` 的一个真实优势。`allocatable` 做不到这个（虽然有 `pointer` 分量可以绕）。

### 用指针造链表

```fortran
type :: node
  integer :: val = 0
  type(node), pointer :: next => null()
end type

type(node), pointer :: head => null()
```

注意 `=> null()` 的默认初始化 —— **不写它，未赋值分量的指针状态是未定义的**，`associated` 会返回垃圾值。

链表在 Fortran 里能用，但性能一般（每个节点都是一次分散的 `allocate`）。数值场景下，用「数组 + 整数索引当链」的方式通常快得多：

```fortran
integer :: next(:)      ! next(i) 是节点 i 的后继下标，0 表示结束
```

### move_alloc 与指针的对比

```fortran
! allocatable 版：O(1)，且自动管理生命周期
call move_alloc(tmp, big)

! pointer 版：也能 O(1)，但你得自己管释放
big_p => tmp
nullify(tmp)
```

能用 `move_alloc` 就别用指针 —— 前者会在必要时自动 `deallocate`，不会泄漏。

### 一个真实教训

示例 14 里演示了同一段逻辑用 `allocatable` 和用 `pointer` 写出来的差别。指针版的代码更长、更容易漏内存，而功能完全一样。**在 Fortran 里，指针是最后手段，不是默认选择。**

---

## 第 16 章 泛型、重载与 submodule

对应示例：`18-generics.f90`

### 运算符重载

```fortran
module vecmod
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private
  public :: vec3, operator(+), operator(*), operator(==), operator(/=), operator(<)

  type :: vec3
    real(real64) :: x = 0.0_real64, y = 0.0_real64, z = 0.0_real64
  contains
    procedure :: add       => vec_add
    procedure :: mul       => vec_mul
    procedure :: eq        => vec_eq
    procedure :: lt        => vec_lt
    generic :: operator(+)  => add
    generic :: operator(*)  => mul
    generic :: operator(==) => eq
    generic :: operator(/=) => vec_ne
    generic :: operator(<)  => lt
  end type

contains
  pure function vec_add(a, b) result(r)
    class(vec3), intent(in) :: a, b
    type(vec3) :: r
    r%x = a%x + b%x;  r%y = a%y + b%y;  r%z = a%z + b%z
  end function
```

之后就能写 `v3 = v1 + v2` 了。**注意 `operator(+)` 的两个操作数类型可以不同**：

```fortran
generic :: operator(*) => mul, mul_scalar
! 支持 vec3 * vec3 和 vec3 * real 两种
```

### assignment(=)：自定义赋值

```fortran
subroutine assign_from_real(self, r)
  class(vec3), intent(inout) :: self
  real(real64), intent(in) :: r
  self%x = r;  self%y = r;  self%z = r
end subroutine

! 之后
v = 5.0_real64      ! 三个分量都变成 5
```

`assignment(=)` 是把一个类型「变成」另一个类型的钩子。用它可以让自定义类型在赋值语句里表现得像内建类型。

**但要小心**：重载 `assignment(=)` 会**关掉默认的成员拷贝**语义，容易写出意外的代码。只在确实需要隐式转换时用。

### 泛型接口

```fortran
interface mkvec
  module procedure mkvec3, mkvec_r
end interface

interface norm2d
  module procedure norm2d_r, norm2d_i
end interface
```

调用时编译器按实参类型选。这让一套「概念上的同一个操作」能有一组实现：

```fortran
v = mkvec(1.0_real64, 2.0_real64, 3.0_real64)    ! → mkvec3
v = mkvec(2.5_real64)                             ! → mkvec_r
```

### elemental

```fortran
elemental pure function clamp(x, lo, hi) result(y)
  real(real64), intent(in) :: x, lo, hi
  real(real64) :: y
  y = min(max(x, lo), hi)
end function
```

标量上是普通函数，数组上自动逐元素作用：

```fortran
y = clamp(arr, 0.0_real64, 1.0_real64)     ! arr 整个数组被夹紧
```

### submodule 的实战用法

见第 12 章末尾。这里补一个坑：**submodule 里的过程定义必须和父模块的接口完全一致**，包括 `result` 变量名。名字不一致会报 `FUNCTION name mismatch`。

改代码时如果批量替换了函数名（比如把 `mkvec3` 统一成 `mkvec`），**要留意别把定义行也替换掉** —— 定义行的名字必须和接口声明的那个名字对得上。这个坑在本仓库编写时真的踩过一次。

---

## 第 17 章 经典算法

对应示例：`15-algorithms.f90`

这一章不是算法教学，是**用 Fortran 写算法时的语言注意事项**。算法本身都是教科书内容：冒泡/插入/快速/归并排序、递归与迭代二分查找、埃氏筛、`gcd`、汉诺塔、记忆化与迭代斐波那契、Fisher-Yates 洗牌。

### 排序：数组哑元的写法

```fortran
pure subroutine insertion_sort(a)
  integer(int32), intent(inout) :: a(:)
  integer(int32) :: i, j, key
  do i = 2, size(a)
    key = a(i)
    j = i - 1
    do while (j >= 1 .and. a(j) > key)
      a(j + 1) = a(j)
      j = j - 1
    end do
    a(j + 1) = key
  end do
end subroutine
```

### 这里的语言坑：纯函数不能改哑元

快速排序的分区步骤需要改数组，你可能会写：

```fortran
pure function partition(a, lo, hi) result(p)
  integer(int32), intent(inout) :: a(:)     ! 想改
  ...
end function
```

**gfortran 直接拒绝**：纯函数的哑元必须是 `intent(in)` 或 `value`。flang 会放行（更宽松），但这是标准明确禁止的 —— 别依赖。

正确姿势是把分区写成 `pure subroutine`：

```fortran
pure subroutine partition(a, lo, hi, p)
  integer(int32), intent(inout) :: a(:)
  integer(int32), intent(in)    :: lo, hi
  integer(int32), intent(out)   :: p
  ...
end subroutine
```

子程序可以改 `intent(inout)` 哑元，同时保持 `pure`（纯子程序）。这一点很容易忘。

### 递归函数要写 recursive

```fortran
recursive function fib_memo(n, memo) result(r)
  integer, intent(in) :: n
  integer, intent(inout) :: memo(:)
  integer :: r
  if (n <= 2) then
    r = 1
  else if (memo(n) > 0) then
    r = memo(n)
  else
    r = fib_memo(n - 1, memo) + fib_memo(n - 2, memo)
    memo(n) = r
  end if
end function
```

记忆化把指数复杂度打回线性。注意 `memo` 是 `intent(inout)` —— 递归函数可以有 `intent(inout)` 哑元，只要不是 `pure`。

### 洗牌与随机

Fisher-Yates 洗牌需要随机数，而随机数发生器在两个编译器上不同，所以示例 15 的输出被列进了「已知差异」。见第 19 章。

### 二分查找的边界

```fortran
pure function bsearch(a, key) result(pos)
  integer(int32), intent(in) :: a(:), key
  integer(int32) :: pos
  integer(int32) :: lo, hi, mid
  lo = 1; hi = size(a); pos = -1
  do while (lo <= hi)
    mid = (lo + hi) / 2            ! 注意：整数除法，自动向下取整
    if (a(mid) == key) then
      pos = mid
      return
    else if (a(mid) < key) then
      lo = mid + 1
    else
      hi = mid - 1
    end if
  end do
end function
```

`(lo + hi) / 2` 在 Fortran 里不用写 `floor`，整数除法的语义就是截断。但**注意 `lo + hi` 可能溢出**，虽然实践上不可能发生（数组没到 2^30）。

---

## 第 18 章 数值计算

对应示例：`16-numeric.f90`

### 求根：四种方法

| 方法 | 收敛阶 | 需要 | 特点 |
|---|---|---|---|
| 二分 | 线性 | 括号区间 | 稳，一定收敛，慢 |
| 牛顿 | 二次 | 导数 | 快，但导数难写时麻烦 |
| 割线 | 超线性（≈1.618） | 两个初值 | 不用导数，接近牛顿 |
| 不动点迭代 | 线性 | `x = g(x)` 形式 | 简单，收敛条件苛刻 |

```fortran
pure function newton(f, df, x0, tol, maxiter, ok) result(x)
  interface
    pure function f(x) result(y)
      real(real64), intent(in) :: x
      real(real64) :: y
    end function
    pure function df(x) result(y)
      real(real64), intent(in) :: x
      real(real64) :: y
    end function
  end interface
  real(real64), intent(in) :: x0, tol
  integer, intent(in) :: maxiter
  logical, intent(out) :: ok
  real(real64) :: x
  integer :: it
  x = x0; ok = .false.
  do it = 1, maxiter
    if (abs(df(x)) < 1.0e-15_real64) return     ! 导数为 0，放弃
    x = x - f(x) / df(x)
    if (abs(f(x)) < tol) then
      ok = .true.
      return
    end if
  end do
end function
```

**`ok` 这样的「成功标志」一定要有。** 数值方法不收敛是常态，不是异常，调用方需要知道。

### 积分：三种公式

```fortran
! 梯形法
pure function trapezoid(f, a, b, n) result(s)
  interface
    pure function f(x) result(y)
      real(real64), intent(in) :: x
      real(real64) :: y
    end function
  end interface
  real(real64), intent(in) :: a, b
  integer, intent(in) :: n
  real(real64) :: s, h
  integer :: i
  h = (b - a) / real(n, real64)
  s = (f(a) + f(b)) / 2.0_real64
  do i = 1, n - 1
    s = s + f(a + real(i, real64) * h)
  end do
  s = s * h
end function
```

辛普森法要求 `n` 是偶数；中点法精度介于两者之间。示例里把三种都跑了一遍并比较误差。

### 数值微分与理查森外推

```fortran
dd = (f(x + h) - f(x - h)) / (2.0_real64 * h)          ! 中心差分，O(h²)
```

理查森外推用两个不同 `h` 的结果组合，把误差阶数提高：

```fortran
d1 = central_diff(f, x, h)
d2 = central_diff(f, x, h / 2.0_real64)
d  = d1 + (d1 - d2) / 3.0_real64                        ! O(h⁴)
```

### LU 分解：一个经典 bug 的完整记录

带部分主元（partial pivoting）的 LU 分解，用 0 基索引用 1 基下标的 Fortran 写：

```fortran
subroutine lu_solve(a, b, x, ok)
  real(real64), intent(inout) :: a(:,:)
  real(real64), intent(inout) :: b(:)
  real(real64), intent(out)   :: x(:)
  logical, intent(out)        :: ok
  real(real64), allocatable :: y(:)
  integer :: n, i, k, piv
  real(real64) :: tmp, factor

  n = size(b); ok = .false.
  y = b                                    ! ★ 关键：拷贝一份再换行

  do k = 1, n - 1
    ! 找主元
    piv = k
    do i = k + 1, n
      if (abs(a(i, k)) > abs(a(piv, k))) piv = i
    end do
    if (abs(a(piv, k)) < 1.0e-14_real64) return      ! 奇异

    ! 交换 a 的两行 —— 同时必须交换 y！忘了这步就得到错误的解
    if (piv /= k) then
      do i = 1, n
        tmp = a(k, i); a(k, i) = a(piv, i); a(piv, i) = tmp
      end do
      tmp = y(k); y(k) = y(piv); y(piv) = tmp        ! ★★ 这一行是必须的
    end if

    ! 消元
    do i = k + 1, n
      factor = a(i, k) / a(k, k)
      a(i, k:n) = a(i, k:n) - factor * a(k, k:n)
      y(i) = y(i) - factor * y(k)
    end do
  end do

  if (abs(a(n, n)) < 1.0e-14_real64) return

  ! 回代
  do i = n, 1, -1
    x(i) = (y(i) - dot_product(a(i, i + 1:n), x(i + 1:n))) / a(i, i)
  end do
  ok = .true.
end subroutine
```

**加星号的两处是本仓库编写时真实掉进去的坑。** 只交换 `A` 的行、忘了同步交换右端项 `b`，程序会：

- 编译通过
- 退出码 0，没有任何错误
- **给出完全错误的解**

当时解一个 3 元方程组，真解是 `2, 3, -1`，程序给出 `23, -21, 28`。这种事数值代码里极其常见 —— 因为主元交换的语义是「重排方程的顺序」，方程顺序变了，右端项当然要跟着变。

**教训**：数值代码一定要用「已知答案」的算例验证。示例 16 里就是这么做的。

### 行列式与插值

```fortran
! 有了 LU 之后，行列式就是所有对角线元素的乘积（再乘上交换次数的符号）
det = product(diag)

! 拉格朗日插值：过 n 个点的 n-1 次多项式
pure function lagrange(xs, ys, x) result(y)
  real(real64), intent(in) :: xs(:), ys(:), x
  real(real64) :: y, term
  integer :: i, j
  y = 0.0_real64
  do i = 1, size(xs)
    term = ys(i)
    do j = 1, size(xs)
      if (j /= i) term = term * (x - xs(j)) / (xs(i) - xs(j))
    end do
    y = y + term
  end do
end function
```

---

## 第 19 章 随机数与统计

对应示例：`17-random.f90`

### 标准随机数接口

```fortran
real(real64) :: r
call random_seed()          ! 用当前时间初始化（实现相关）
call random_number(r)       ! [0,1) 的均匀分布
call random_number(arr)     ! 数组一次填满
```

### 保底：先问尺寸

```fortran
integer :: n
integer, allocatable :: seed(:)
call random_seed(size=n)
allocate (seed(n))
call random_seed(get=seed)
! ... 想固定实验可复现，就 seed = 42；想把种子打印出来留着，就 write(*,*) seed
call random_seed(put=seed)
```

**`random_seed(size=n)` 返回的 `n` 两个编译器不一样**：

| 编译器 | `n` |
|---|---|
| flang 23 | 1 |
| gfortran 15 | 8 |

所以示例 17 的「把种子打印出来」这一行没法做到跨编译器一致，被列进了已知差异。

**不要假设 `n` 是某个固定值**，也**不要手写种子值除非你确定尺寸** —— `seed` 数组长度不对会报错或行为未定义。

### 想要可复现的随机数

`random_number` 的实现是编译器相关的，**同一份代码在两个编译器上会给出不同的随机序列**。要严格复现，只能：

1. 固定 `seed`（但序列仍在不同编译器间不同），或
2. **自己写一个确定性发生器**

示例 17 里就手写了一个 LCG（线性同余发生器）：

```fortran
module lcg
  implicit none
  integer(int64), parameter :: A = 6364136223846793005_int64
  integer(int64), parameter :: C = 1442695040888963407_int64
  integer(int64) :: state = 12345_int64
contains
  subroutine lcg_seed(s)
    integer(int64), intent(in) :: s
    state = s
  end subroutine
  pure real(real64) function lcg_next() result(r)
    state = A * state + C
    r = real(ishft(state, -11), real64) / real(2_int64 ** 53, real64)
  end function
end module
```

**这个序列是跨编译器完全一致的**，因为它是纯整数运算。需要「两边跑出一样的结果」时，用这个。

（当然，LCG 的统计质量一般，正经蒙特卡洛还是用 `random_number`。）

### 常见分布的生成

**正态分布 —— Box-Muller 变换**：

```fortran
pure function randn() result(z)
  real(real64) :: z, u1, u2
  call random_number(u1)
  call random_number(u2)
  z = sqrt(-2.0_real64 * log(u1)) * cos(2.0_real64 * 3.14159265358979323846_real64 * u2)
end function
```

**指数分布**：`-log(u) / lambda`。**均匀整数**：`floor(u * n) + 1`。

### 蒙特卡洛

```fortran
! 用随机点估 π：落在单位圆内的比例 × 4
integer :: inside = 0
real(real64) :: x, y
do i = 1, n
  call random_number(x); call random_number(y)
  if (x*x + y*y <= 1.0_real64) inside = inside + 1
end do
pi_est = 4.0_real64 * real(inside, real64) / real(n, real64)
```

误差按 `1/sqrt(n)` 收敛 —— 所以要想多一位精度，样本量得翻 100 倍。示例里打印了不同 `n` 下的估计值和实际误差，能直观看到这个规律。

同理可以估积分：`∫f` ≈ 区间长度 × `f` 在随机点上的均值。

### 描述统计

```fortran
mean     = sum(x) / size(x)
variance = sum((x - mean)**2) / (size(x) - 1)        ! 样本方差，注意是 n-1
stddev   = sqrt(variance)
```

**注意 `n` 还是 `n-1`**：总体方差除以 `n`，样本方差除以 `n-1`（贝塞尔修正）。写代码时明确一下你要哪个，别到论文里才发现。

中位数、分位数用手写的排序：

```fortran
pure function median(x) result(m)
  real(real64), intent(in) :: x(:)
  real(real64) :: m
  real(real64), allocatable :: s(:)
  integer :: n
  s = x                                     ! 拷贝，别改调用者的数组
  call insertion_sort_r(s)
  n = size(s)
  if (mod(n, 2) == 1) then
    m = s((n + 1) / 2)
  else
    m = (s(n / 2) + s(n / 2 + 1)) / 2.0_real64
  end if
end function
```

偏度、峰度按标准公式算。相关系数用 Pearson：

```fortran
r = sum((x - mx) * (y - my)) / (sqrt(sum((x-mx)**2)) * sqrt(sum((y-my)**2)))
```

### 统计的数值稳定陷阱

朴素的方差公式 `E[x²] - E[x]²` 在数据均值很大时会**灾难性抵消**：

```fortran
! 危险：x = 1e8 + 随机小量时，这两个大数相减会丢掉所有有效位
variance = sum(x**2)/n - (sum(x)/n)**2

! 安全：两步法（先算均值，再算偏差平方和）
mean = sum(x) / n
variance = sum((x - mean)**2) / n
```

示例 17 里两种都算了，能看出差别。

---

## 第 20 章 C 互操作

对应示例：`19-c-interop.f90`

`iso_c_binding` 是 Fortran 2003 起的标准机制，让 Fortran 和 C 能安全地互相调用。

### KIND 对照表

```fortran
use, intrinsic :: iso_c_binding
```

| Fortran | C | 说明 |
|---|---|---|
| `integer(c_int)` | `int` | 最常用 |
| `integer(c_long)` | `long` | |
| `integer(c_int64_t)` | `int64_t` | 明确位宽 |
| `real(c_float)` | `float` | |
| `real(c_double)` | `double` | |
| `complex(c_double_complex)` | `double complex` | |
| `character(kind=c_char)` | `char` | **逐字符** |
| `logical(c_bool)` | `bool`（`stdbool.h`） | 不是普通 `logical` |
| `type(c_ptr)` | `void *` | 不透明指针 |
| `type(c_funptr)` | 函数指针 | |

### 调用 C 函数

```fortran
interface
  function strlen(s) bind(c, name='strlen') result(n)
    import :: c_ptr, c_size_t
    type(c_ptr), value :: s
    integer(c_size_t) :: n
  end function
end interface
```

关键三点：

1. **`bind(c, name='...')`** 指定 C 里面的真实符号名（Fortran 会做名字改编，C 不会）
2. **`value` 属性**：默认 Fortran 传引用，加了 `value` 才是传值（C 的默认）
3. **`import`**：接口块里的名字要 import 进来（`c_ptr`、`c_size_t` 等）

**忘了写 `value` 是最常见的错误** —— 编译可能过，运行时 `strlen` 拿到的是一个指向指针的指针，结果随机崩。

### 字符串：必须显式处理

Fortran 的 `character` 和 C 的 `char *` **不是同一个东西**：

- Fortran 字符知道自己的长度（隐藏在描述符里）
- C 字符串靠末尾的 NUL 终止

所以传递字符串需要转成 `c_char` 数组，并自己加终止符：

```fortran
subroutine fortran_to_c(fstr, cbuf)
  character(len=*), intent(in) :: fstr
  character(kind=c_char), intent(out) :: cbuf(*)
  integer :: i
  do i = 1, len_trim(fstr)
    cbuf(i) = char(iachar(fstr(i:i)), c_char)
  end do
  cbuf(len_trim(fstr) + 1) = c_null_char        ! 手动终止
end subroutine
```

`char(iachar(c), c_char)` 是把默认 kind 的字符转成 `c_char` 的写法。写成 `c_'h'` 这种字面量是**不合法**的（`c_'...'` 只对个别字符有效，且不被两个编译器一致支持）。

### 最大的坑：`buf = c_null_char` 不清空

```fortran
character(kind=c_char) :: buf(33)
buf = c_null_char          ! 错！！！
```

这一句**只把 `buf(1)` 设成 NUL，剩下 32 个字节是空格（0x20），不是 NUL**。于是 C 的 `strlen(buf)` 会越过你的缓冲区继续读，直到碰见某个 0 —— 读到什么完全是运气。

本仓库编写时踩过这个坑，两个编译器给出的结果不一样（一个报 32，一个报 37），这就是**未定义行为**的典型表现。

正确做法：

```fortran
do i = 1, size(buf)
  buf(i) = c_null_char
end do
```

### c_loc 与 c_f_pointer

```fortran
real(c_double), target :: arr(10)
type(c_ptr) :: p

p = c_loc(arr)                          ! Fortran 数组 → C 指针
! 传给 C 函数...

! C 指针 → Fortran 指针
real(c_double), pointer :: fp(:)
call c_f_pointer(p, fp, [10])
```

**`c_loc` 的参数必须是「可互操作」的**（`target`、`interoperable` 类型）。对字符串标量用 `c_loc(cbuf)` 会报「缺 TARGET 属性」之类的警告 —— 正确写法是 `c_loc(cbuf(1:1))`，取第一个字符的地址。

### 回调：把 Fortran 过程传给 C

`qsort` 的比较函数是个经典例子：

```fortran
! C 侧：void qsort(void *base, size_t nmemb, size_t size,
!                 int (*compar)(const void *, const void *));

function cmp_int(a, b) bind(c) result(r)
  use, intrinsic :: iso_c_binding, only: c_ptr, c_int, c_f_pointer
  type(c_ptr), value :: a, b
  integer(c_int) :: r
  integer(c_int), pointer :: pa, pb
  call c_f_pointer(a, pa)
  call c_f_pointer(b, pb)
  r = pa - pb
end function
```

传的时候用 `c_funloc(cmp_int)`：

```fortran
call qsort(c_loc(arr), int(size(arr), c_size_t), &
           int(c_sizeof(arr(1)), c_size_t), c_funloc(cmp_int))
```

**注意比较函数不能是 `pure`** —— `c_f_pointer` 不是纯过程。第一次写的时候加了 `pure`，编译直接报错。

### 结构体布局

```fortran
type, bind(c) :: c_point
  real(c_double) :: x, y
end type
```

`bind(c)` 的类型会按 C 的布局规则排列（无对齐填充差异）。字段顺序必须和 C 的 `struct` 完全一致。**别在 `bind(c)` 类型里放可分配分量或指针分量**（C 没这个概念）。

### 最后一课：列主序 vs 行主序

```fortran
real(c_double) :: m(2, 3)     ! Fortran：m(i,j)，内存顺序 m(1,1), m(2,1), m(1,2), ...
```

C 里对应的 `double m[2][3]` 内存顺序是 `m[0][0], m[0][1], m[0][2], m[1][0], ...`。

**同一个内存块，两边看到的矩阵是转置关系。**

要让 C 拿到「正确」的矩阵，两条路：

1. 在 Fortran 侧转置后再传（多一次拷贝）
2. 让 C 侧理解「这是列主序」（零拷贝，但要改 C 代码）

BLAS/LAPACK 的传统就是选 2 —— 所以 `dgemm` 的参数是 `TRANSA`、`TRANSB`，让调用者说明「我给的到底是行主序还是列主序」。这不是历史包袱，是列主序语言的事实标准。

示例 19 里用一份内存、两种读法演示了这个转置效果。

---

## 第 21 章 并行计算：OpenMP 与 do concurrent

对应示例：`20-parallel.f90`

### 两种并行写法

```fortran
! 1. OpenMP 指令（编译器扩展，标准外）
!$omp parallel do reduction(+:total)
do i = 1, n
  total = total + f(i)
end do
!$omp end parallel do

! 2. do concurrent（F2008 标准内，编译器自己决定怎么并行）
do concurrent (i = 1:n)
  a(i) = f(i)
end do
```

`do concurrent` 的好处是不依赖 OpenMP，任何编译器都能编；坏处是**并行与否由编译器决定** —— 本仓库的两个编译器在默认参数下都不会真的把它并行化。

### OpenMP 常用指令

```fortran
!$omp parallel do num_threads(4) schedule(static)
do i = 1, n
  ...
end do

!$omp parallel do reduction(+:sum) private(tmp)
do i = 1, n
  tmp = compute(i)
  sum = sum + tmp
end do

!$omp critical
counter = counter + 1
!$omp end critical

!$omp atomic
cnt = cnt + 1
!$omp end atomic

!$omp parallel sections
!$omp section
call task_a()
!$omp section
call task_b()
!$omp end parallel sections
```

### schedule 的选择

| 策略 | 适用 |
|---|---|
| `static` | 每次迭代耗时均匀 |
| `dynamic` | 耗时差异大，负载均衡优先 |
| `guided` | 介于两者，块大小递减 |

示例里对同一个循环用三种策略各跑一遍并计时。

### 计时

```fortran
use, intrinsic :: iso_c_binding, only: c_double
interface
  function omp_get_wtime() bind(c, name='omp_get_wtime') result(t)
    import :: c_double
    real(c_double) :: t
  end function
end interface
```

**为什么不用 `omp_lib`？** 因为 **flang 23 没有这个模块**（第 24 章第 4 条）。`use omp_lib` 在 flang 上直接编译失败：

```
error: Cannot parse module file for module 'omp_lib'
```

解法是自己写一个薄封装：

```fortran
module omprt
  use, intrinsic :: iso_c_binding, only: c_int, c_double
  implicit none
  interface
    function omp_get_wtime() bind(c, name='omp_get_wtime') result(t)
      import :: c_double
      real(c_double) :: t
    end function
    function omp_get_max_threads() bind(c, name='omp_get_max_threads') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
  end interface
end module
```

然后 `use omprt`。这个办法在两个编译器上都能用，而且顺便演示了 `bind(c)` 的实际价值 ——**OpenMP 运行时函数本来就是 C 接口**，Fortran 的 `omp_lib` 只是它的包装。

注意接口块里必须 `import :: c_int, c_double`，否则报 `Must be a constant value`。

### 竞态：一定要亲眼见一次

```fortran
integer :: cnt = 0
!$omp parallel do
do i = 1, 100000
  cnt = cnt + 1        ! 错：读-改-写不是原子操作
end do
```

`cnt` 几乎肯定不等于 100000。因为 `cnt = cnt + 1` 编译成「读进寄存器 → 加 1 → 写回」，两个线程可能都读到 100，各加 1 写回 101，一次增量丢了。

三种修法：

```fortran
!$omp atomic                       ! 只保护这一个操作，最快
!$omp critical                     ! 一个代码块，更通用但更慢
!$omp parallel do reduction(+:cnt) ! 各线程用私有副本，最后合并，最快
```

优先用 `reduction`，它是三者里唯一不需要在循环里做同步的。

### 一个 flang 特有的限制

下面这段在 gfortran 上没问题，在 flang 23 上编译失败：

```fortran
block
  integer :: cnt = 0
  !$omp parallel do
  do i = 1, n
    !$omp atomic
    cnt = cnt + 1
  end do
end block
```

flang 报：

```
error: The atomic variable cnt should appear as an argument of the top-level + operator
```

或者对 `do concurrent` 的 `local()`：

```
error: 'hi' may not appear in a locality-spec because it is not a definable ...
```

**原因是 flang 不接受 `block` 作用域里声明的变量出现在这些位置。** 解法很简单：把累加器和局部变量提到**程序（或模块）作用域**声明，然后在循环里用。示例 20 里所有并行累加器都在程序级声明，就是这个原因。

### 加速比的现实

示例里测了串行 vs 并行 2/4/8 线程的耗时，并算了加速比。你会看到：

- 线程数超过物理核心数后**没有收益**（甚至变慢）
- 加速比一般达不到线性 —— 有启动开销、同步开销、内存带宽瓶颈
- `schedule(dynamic)` 在小任务上可能比 `static` 更慢（调度开销大于收益）

**别看到 `!$omp` 就以为变快了。** 一定要测。

### 计时示例为什么会被列进「已知差异」

因为它打印真实耗时，而两份输出的时间戳必然不同。脚本对 `20-parallel` 直接跳过逐字节比对。

---

## 第 22 章 错误处理与单元测试

对应示例：`21-errors-testing.f90`

### Fortran 没有异常

这是从 Python/Java 过来最不习惯的地方：**Fortran 标准没有 `try/catch`**。错误处理靠三个机制：

1. **`iostat=` / `stat=` / `iomsg=`** —— 所有 I/O 和分配操作都能拿到状态码
2. **`err=` 标签** —— 跳到错误处理位置
3. **`error stop`** —— 不可恢复时终止，带退出码

### iostat 的正确用法

```fortran
integer :: ios, u
character(len=256) :: iomsg
open (newunit=u, file='nope.txt', status='old', action='read', iostat=ios, iomsg=iomsg)
if (ios /= 0) then
  write (*, '(a,i0)') '打开失败，iostat = ', ios
  write (*, '(a,a)')  '错误信息：', trim(iomsg)
end if
```

**`iomsg` 是编译器给的文字描述**，可能不适用于错误码不匹配的情况；而且不同编译器的文字不同。**不要用它做逻辑判断**，只用来打印给人看。

### stat 与 errmsg

```fortran
allocate (big(1000000000), stat=ios, errmsg=msg)
if (ios /= 0) write (*, '(a,a)') '分配失败：', trim(msg)
```

**`stat` 的具体数值是编译器相关的**：

| 场景 | flang 23 | gfortran 15 |
|---|---|---|
| 重复 allocate | 放行（不报错） | 报错，`stat` ≈ 5014 |
| 其他场景 | 12 | 各不相同 |

所以**只能判 `/= 0`**，绝不能写 `if (ios == 5014)`。示例 21 里把这个差异演示出来了，它也是「已知差异」清单的一员。

### err= 标签（老风格，但有时更简洁）

```fortran
read (u, *, err=100, end=200) x
! 正常路径
goto 300
100 continue
write (*, '(a)') '读取出错'
goto 300
200 continue
write (*, '(a)') '文件结束'
300 continue
```

能用 `iostat` 的地方就**别用 `err=`** —— 标签会把控制流打散。只在非常简单的读循环里偶尔用一下。

### inquire：先问再开

```fortran
logical :: ex
inquire (file='data.txt', exist=ex)
if (.not. ex) then
  write (*, '(a)') '文件不存在'
  stop 1
end if
```

注意 `inquire(size=)` 需要**标量整数**变量，传数组进去编译报错。

### error stop 与退出码

```fortran
if (bad) error stop 3      ! 退出码 3
if (bad) stop 3            ! 也可以，但不会触发清理
```

`error stop` 和 `stop` 的区别：`error stop` 会**刷新所有已连接的单元的缓冲**再退出，`stop` 不保证。写数据的程序一定要用 `error stop`。

**验证退出码需要子进程**。示例 21 的做法：父程序用 `execute_command_line` 启动一个会 `error stop 3` 的子程序，子程序把消息写进临时文件，父程序读出来再删掉。

为什么要绕这一圈？因为如果让子进程直接写 stdout，输出会和父进程的缓冲区交错，**两个编译器给出的交错顺序不一样**，逐字节比对就失败了。写文件 + 父进程读取 + 删除，输出就完全确定了。

（`execute_command_line` 是标准里唯一能起子进程的方式，但它需要一个 shell，可移植性一般。）

### 手写一个断言框架

Fortran 标准库没有测试框架（虽然社区有 `test-drive` 等）。示例 21 里手写了一个够用的：

```fortran
module unittest
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private
  public :: assert_true, assert_false, assert_eq_i, assert_eq_r, assert_close, &
            assert_eq_s, test_summary

  integer :: n_pass = 0, n_fail = 0

contains
  subroutine assert_true(cond, name)
    logical, intent(in) :: cond
    character(len=*), intent(in) :: name
    if (cond) then
      n_pass = n_pass + 1
      write (*, '(a,a)') '  [PASS] ', name
    else
      n_fail = n_fail + 1
      write (*, '(a,a)') '  [FAIL] ', name
    end if
  end subroutine

  subroutine assert_close(got, want, tol, name)
    real(real64), intent(in) :: got, want, tol
    character(len=*), intent(in) :: name
    call assert_true(abs(got - want) <= tol, name)
  end subroutine

  subroutine test_summary()
    write (*, '(a,i0,a,i0)') '通过 ', n_pass, '   失败 ', n_fail
    if (n_fail > 0) error stop 1        ! 让 CI 能感知失败
  end subroutine
end module
```

要点：

- **浮点比较一定要有 `assert_close`**，不能只给 `assert_eq_r`（第 4 章）
- **失败时 `error stop 1`**，这样接入 CI 时退出码能反映结果
- 计数器放在模块里，所以测试代码不需要把状态传来传去

### 被测模块与测试的分离

```fortran
module ratlib
  implicit none
  private
  public :: gcd, simplify
contains
  pure function gcd(a, b) result(g)
    integer, intent(in) :: a, b
    integer :: g, x, y, t
    x = abs(a); y = abs(b)
    do while (y /= 0)
      t = mod(x, y); x = y; y = t
    end do
    g = x
  end function
end module
```

测试程序 `use ratlib` 然后一组断言。**测试放在同一个文件里**（本仓库的示例是单文件自包含的），实际项目里应当分开成 `src/` 和 `test/`。

### 值得遵守的几条

1. **所有 I/O 都带 `iostat=`**，除非是控制台输出。
2. **过程里加 `ok`/`status` 输出参数**，不要靠副作用或全局变量报错。
3. **`error stop` 带非零退出码**，让 shell 能感知。
4. **数值代码必须有「已知答案」的测试**（第 18 章的 LU 事故就是这么发现不了的）。
5. **`-pedantic` 下编译警告为零**，是能持续保持的最实际的纪律。

---

## 第 23 章 坑清单（与编译器无关）

这一章是纯语言层面的。每条都在这本仓库的示例里真实出现过。

### 1. `cs(i) = x` 是函数调用

```fortran
character(len=8) :: cs
cs(1:1) = 'X'      ! 对：子串赋值
cs(1)   = 'X'      ! 错：'cs' is not a callable procedure
```

`cs(i)` 被解析成数组/函数引用。**子串赋值必须写 `cs(i:i)`。**

### 2. 格式描述符比数据项少 → 格式重现 → stdout 混进垃圾

见第 9 章。这是本仓库最值得记住的一条，因为它**编译通过、运行成功、退码为 0**，只有肉眼或者专门检查才能发现。

```fortran
write (*, '(a,3i5)') 'x : ', a(5:1:-1)   ! a(5:1:-1) 有 5 个元素，少写了 2 个描述符
```

**规则**：I/O 列表里放数组前，用 `size()` 确认元素个数，描述符个数不能少。

### 3. `a(5:1:-1)` 是 5 个元素，不是 3 个

```fortran
! 元素个数 = (last - first + stride) / stride
size(a(5:1:-1))   ! 5
size(a(5:3:-1))   ! 3
size(a(1:5:-1))   ! 0（空节）
```

写倒序切片时脑子里过一遍这个公式。

### 4. `es`/`en`/`e` 描述符不带 `Ee` 时指数 2 位

```fortran
write (*, '(a,es13.6)')   huge(x)   ! 1.797693+308   ← 位数不够，E 被挤掉
write (*, '(a,es15.6e3)') huge(x)   ! 1.797693E+308
```

**要输出三位指数（`E+308`）必须写 `Ee`。** 反过来，`es13.6` 也**不会**自动加宽 —— 加宽字段宽度没用，必须显式指定指数位数。

### 5. `F0.d` 不输出前导零

```fortran
write (*, '(f0.2)') 0.5      ! .50    ← 不是 0.50
```

要前导零就指定固定宽度 `f6.2`。

### 6. 内部读的 unit 必须是字符变量

```fortran
read ('42', '(i5)') n        ! 错
character(len=8) :: buf
buf = '42'
read (buf, '(i5)') n         ! 对
```

### 7. `buf = c_null_char` 只设一个字符

```fortran
character(kind=c_char) :: buf(33)
buf = c_null_char            ! 只有 buf(1) 是 NUL，其余是空格
do i = 1, size(buf)          ! 要清空得这么写
  buf(i) = c_null_char
end do
```

### 8. `a` 描述符不带宽度用「声明长度」

```fortran
character(len=64) :: name
name = 'hi'
write (*, '(a)') trim(name)      ! 还是补齐到 64 个字符！
write (*, '(a)') name(1:len_trim(name))   ! 这样才对
```

因为 `trim(name)` 的结果被赋给 `a` 描述符时，`a` 的长度是**声明长度**。要么用子串，要么用 `(a)` 配一个 `character(len=:)` 的变量。

### 9. 泛型内建函数不能当过程实参

```fortran
y = apply(sin, x)            ! 错：sin 是泛型名
y = apply(d_sin, x)          ! 对：先包一层
```

### 10. 自由格式 132 列上限

超过会被截断。gfortran 报 `Line truncated`，flang 有时只警告。**用 `&` 续行**：

```fortran
write (*, '(a,i0,a,i0)') 'result = ', result, &
                          ' iterations = ', iters
```

`&` 必须在行末，续行也要用 `&` 开头（字符串字面量跨行时有额外的 `&` 规则）。

### 11. 列主序 vs C 行主序

见第 20 章。跟 C 交换二维数组时必须处理。

### 12. 数组节重叠赋值是禁止的

```fortran
a(2:4) = a(1:3)              ! 错：源和目标重叠
block
  integer :: tmp(3)
  tmp = a(1:3); a(2:4) = tmp  ! 对
end block
```

### 13. 未写 `recursive` 的递归函数

```fortran
function fact(n) result(r)   ! gfortran 报错
recursive function fact(n) result(r)   ! 必须这么写
```

### 14. 重复 allocate

```fortran
allocate (a(10))
allocate (a(20))              ! gfortran 运行时错误；flang 宽容放行
deallocate (a)                ! 先释放
allocate (a(20))
```

### 15. `mod` vs `modulo`

```fortran
mod(-7, 3)      ! -1   结果符号跟被除数
modulo(-7, 3)   !  2   结果符号跟除数
```

### 16. 浮点数不能用 `==`

```fortran
if (abs(a - b) < 1.0e-12_real64) then ... end if
```

### 17. 整数除法

```fortran
7 / 2                      ! 3
real(7, real64) / 2.0_real64    ! 3.5
sum(a) / size(a)           ! 整数平均，丢小数
```

### 18. 解析歧义：`do i = 1. 10`

```fortran
do i = 1, 10      ! 循环
do i = 1. 10      ! 赋值 i = 1.10 —— 经典事故
```

### 19. 局部变量数组不会自动清空

```fortran
subroutine f()
  real(real64) :: acc(10)     ! 可能是上一次调用留下的值！
  acc = 0.0_real64            ! 必须显式初始化
end subroutine
```

模块变量有初值（`:: acc(10) = 0.0_real64` 会保证初始化一次），但**过程里的局部变量每次进过程都是脏的**。

### 20. LU 分解忘swap b

见第 18 章。给出错误答案但一切「正常」。

---

## 第 24 章 双编译器差异清单与可移植写法

这些不是从文档查的，是在本机把 22 个示例跑通的过程中一条条撞出来的。**碰到「同一份代码一边过一边不过」，先来这里对一下。**

| # | 差异 | flang 23 | gfortran 15 | 可移植写法 |
|---|---|---|---|---|
| 1 | 四倍精度 `real128` | 不支持（`real128 = -1`） | 支持 | 用 `real64`；要更高精度用 `selected_real_kind` 并检查返回值 |
| 2 | 参数化派生类型（PDT） | 不支持 | 支持 | 别用 PDT，改成普通派生类型 + 运行时检查 |
| 3 | 共数组（coarray） | 不支持 | 支持（`-fcoarray`） | 用 MPI / OpenMP 代替 |
| 4 | `omp_lib` 模块 | **没有** | 有 | 自己写 `bind(c, name='omp_*')` 接口（示例 20 的 `omprt`） |
| 5 | `-fcheck=` 运行时检查 | 没有对应选项 | 有 | 用断言 + `-O2` 暴露；靠测试而不是靠检查器 |
| 6 | `block` 内变量的 `!$omp atomic` / `do concurrent local()` | 报错 | 接受 | 把并行相关变量提到程序/模块作用域 |
| 7 | `forall` 带类型声明 | 接受（F2008） | 拒绝，且认为 `forall` 过时 | 别用 `forall`，改成数组整体运算或 `where` |
| 8 | `pure function` 带 `intent(inout)` 哑元 | 放行 | 按标准拒绝 | 需要改哑元就写 `pure subroutine` |
| 9 | 递归函数 | 未写 `recursive` 也可能放行 | 必须显式写 | 一律写 `recursive` |
| 10 | 重复 `allocate` 已分配变量 | 运行时宽容 | 运行时报错 | 先 `deallocate`，或用 `stat=` 检查 |
| 11 | `random_seed(size=)` | 1 | 8 | 永远先 `size=n` 再分配种子数组 |
| 12 | `stat=` 的具体数值 | 12 等 | 5014 等 | 只判 `/= 0`，绝不对具体数值做判断 |
| 13 | namelist 输出排版 | 一套风格 | 另一套 | 不依赖打印格式，只依赖读回能力 |
| 14 | `-pedantic` 下对 `forall` 的态度 | 不警告 | 警告「已过时」 | 见第 7 条 |

### 关于第 4 条：没有 `omp_lib` 怎么办

这是实际影响最大的一条。flang 23 编译 `use omp_lib` 直接失败：

```
error: Cannot parse module file for module 'omp_lib'
```

而 `!$omp` 指令本身 flang 是支持的（只要加 `-fopenmp`），缺的只是**那个便利模块**。

**通用解法：自己声明 C 接口。**

```fortran
module omprt
  use, intrinsic :: iso_c_binding, only: c_int, c_double
  implicit none
  private
  public :: omp_get_wtime, omp_get_max_threads, omp_get_thread_num, &
            omp_get_num_procs, omp_in_parallel

  interface
    function omp_get_wtime() bind(c, name='omp_get_wtime') result(t)
      import :: c_double
      real(c_double) :: t
    end function
    function omp_get_max_threads() bind(c, name='omp_get_max_threads') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
    function omp_get_thread_num() bind(c, name='omp_get_thread_num') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
    function omp_get_num_procs() bind(c, name='omp_get_num_procs') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
    function omp_in_parallel() bind(c, name='omp_in_parallel') result(b)
      import :: c_int
      integer(c_int) :: b
    end function
  end interface
end module
```

**这个模块在两个编译器上都能用**，因为 `omp_*` 本来就是 C 符号。而且它顺便说明了一件事：`iso_c_binding` 不是「跟 C 交互才用得到」的东西，它是访问**任何 C 接口库**的通用工具。

### 关于第 7 条：`forall` 该退休了

`forall` 在 F95 引入，F2008 起就被 `do concurrent` 和数组整体运算取代，F2018 正式列为**过时特性**。

```fortran
! 老写法
forall (i = 1:n) a(i) = b(i) * 2.0_real64

! 新写法
a = b * 2.0_real64

! 带条件的
forall (i = 1:n, b(i) > 0.0_real64) a(i) = b(i)

! 新写法
where (b > 0.0_real64) a = b
```

`where` 比 `forall` 更安全（元素级语义，不会越界）也更快（编译器更容易向量化）。**新代码不要再用 `forall`。**

### 关于第 6 条：block 里的并行变量

```fortran
! flang 报错的写法
block
  integer :: cnt = 0
  !$omp parallel do
  do i = 1, n
    !$omp atomic
    cnt = cnt + 1
  end do
end block

! 两个编译器都接受的写法
integer :: cnt      ! 提到程序/模块作用域
cnt = 0
!$omp parallel do
do i = 1, n
  !$omp atomic
  cnt = cnt + 1
end do
```

同样的限制也适用于 `do concurrent ... local(x)`：`x` 必须在程序或模块作用域声明。

代价是变量作用域变宽了，但这是目前唯一能同时通过两个编译器的写法。**如果你的项目只用 gfortran，可以不必迁就** —— 但要知道迁就什么。

### 可移植性检查清单

写完一段想「两边都过」的代码，按这个顺序过一遍：

1. **不碰 `real128`、PDT、coarray** —— 这三个 flang 直接没有
2. **不 `use omp_lib`** —— 换自己的 `bind(c)` 包装
3. **`pure` 函数不改哑元** —— 需要改就用 `pure subroutine`
4. **递归一律写 `recursive`**
5. **`allocate` 前先 `deallocate`**
6. **随机数种子先问 `size`**
7. **`stat`/`iostat` 只判 `/= 0`**
8. **不用 `forall`**
9. **并行累加变量放程序级作用域**
10. **每行 ≤ 132 列，`-pedantic` 下零警告**

这十条也就是本仓库 `run-all.sh` / `build.ps1` 的判定标准背后的东西。**把验证脚本当编译器用**，是保持双编译器可移植最省事的办法。

---

## 附录：怎么跑这本书里的代码

```bash
cd /Users/xulun/code/programming/fortran

# 全部跑一遍（24 示例 × 2 编译器）
./run-all.sh

# 看某个示例的完整输出
./run-all.sh -v 16

# 老格式示例单独跑：脚本自动改用固定格式编译（.f 不加 -pedantic，
# gfortran 侧加 -std=legacy，flang 侧不加 -std）
./run-all.sh 70 71

# 手动编译单个示例，两个编译器各来一次
flang-mp-23    -std=f2018 -pedantic -O2 -J build/mod/flang    examples/16-numeric.f90 -o /tmp/n.f && /tmp/n
gfortran-mp-15 -std=f2018 -pedantic -O2 -J build/mod/gfortran examples/16-numeric.f90 -o /tmp/n.g && /tmp/n.g
```

PowerShell：

```powershell
cd /Users/xulun/code/programming/fortran
pwsh ./build.ps1 -All
pwsh ./build.ps1 -File 16-numeric.f90 -Verbose
pwsh ./build.ps1 -Clean
```

**建议的读法**：第 1–5 章打底，然后 6–7 章（数组）是 Fortran 的核心价值，一定要动手改改示例里的数组表达式。11、13、16 章是把代码从「脚本」变成「工程」的三块。18、21 章是数值和并行，真正让 Fortran 快起来的地方。第 23、24 章当手册查。
