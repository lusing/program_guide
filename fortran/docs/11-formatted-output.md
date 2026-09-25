# 第 11 章 · 格式化 I/O：输出

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

`a(5:1:-1)` 有 **5** 个元素（见第 7 章），描述符只有 `a` + `3i5` 共 4 个。于是：

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

这是 Fortran 里「让自定义类型用起来像内建类型」的关键机制，配合第 20 章的运算符重载，能做到几乎无缝。

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

上一章：[第 10 章 字符与字符串](10-strings.md) ｜ 下一章：[第 12 章 格式化输入](12-formatted-input.md) ｜ 返回：[README](../README.md)
