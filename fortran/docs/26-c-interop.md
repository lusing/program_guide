# 第 26 章 · C 互操作

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

上一章：[第 25 章 随机数与统计](25-random.md) ｜ 下一章：[第 27 章 并行计算：OpenMP 与 do concurrent](27-parallel.md) ｜ 返回：[README](../README.md)
