# 第 4 章 · 程序结构、类型与 KIND

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

注意 `huge(x)` 那行 —— 它用的是 `es15.6e3` 而不是常见的 `es13.6`。原因见第 31 章第 3 条：`es` 不带 `Ee` 时指数只占 2 位，`E+308` 会被挤成 `+308` 甚至更糟。

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

上一章：[第 3 章 算法与程序设计方法](03-methodology.md) ｜ 下一章：[第 5 章 表达式、运算符与数值陷阱](05-expressions.md) ｜ 返回：[README](../README.md)
