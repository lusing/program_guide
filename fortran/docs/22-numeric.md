# 第 22 章 · 数值计算

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

上一章：[第 21 章 经典算法](21-algorithms.md) ｜ 下一章：[第 23 章 线性方程组专题：Gauss-Jordan 与矩阵求逆](23-gauss-jordan.md) ｜ 返回：[README](../README.md)
