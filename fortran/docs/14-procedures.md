# 第 14 章 · 过程：子程序、函数与参数传递

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

上一章：[第 13 章 文件与流 I/O](13-files.md) ｜ 下一章：[第 15 章 模块、接口与模块目录](15-modules.md) ｜ 返回：[README](../README.md)
