! ============================================================
! 16 - 数值计算
!   求根（二分法/牛顿法/割线法/不动点迭代）、数值积分（梯形法/
!   辛普森法/中点法）、数值微分（中心差分/Richardson 外推）、
!   线性方程组（LU 分解 + 部分主元）、拉格朗日插值、
!   求极限与收敛阶验证
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 16-numeric.f90 -o 16-numeric
!   gfortran-mp-15 -std=f2018 -pedantic 16-numeric.f90 -o 16-numeric
! ============================================================

module numeric
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: bisect, newton, secant, fixed_point, &
            trapezoid, simpson, midpoint, &
            central_diff, richardson, &
            lu_solve, det, &
            lagrange_interp, solve_lu
  public :: fx, dfx, gx       ! 演示用的被求函数

  real(real64), parameter :: tol = 1.0e-12_real64
  integer(int32), parameter :: maxit = 100

contains

  ! ---- 被求根的三个函数：f(x) = x^3 - 2x - 5，在 [2,3] 有唯一实根 ----
  pure function fx(x) result(y)
    real(real64), intent(in) :: x
    real(real64) :: y
    y = x**3 - 2.0_real64 * x - 5.0_real64
  end function fx

  pure function dfx(x) result(y)
    real(real64), intent(in) :: x
    real(real64) :: y
    y = 3.0_real64 * x**2 - 2.0_real64
  end function dfx

  ! 不动点迭代用：x = g(x)，等价于 x^3-2x-5=0 的一个变形
  pure function gx(x) result(y)
    real(real64), intent(in) :: x
    real(real64) :: y
    y = (2.0_real64 * x + 5.0_real64)**(1.0_real64 / 3.0_real64)
  end function gx

  ! ---- 二分法：有根区间一定能收敛，但慢（线性收敛）----
  subroutine bisect(f, a, b, x, niter, ok)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
    end interface
    real(real64), intent(in) :: a, b
    real(real64), intent(out) :: x
    integer(int32), intent(out) :: niter
    logical, intent(out) :: ok
    real(real64) :: lo, hi, mid, flo, fmid
    lo = a; hi = b; flo = f(lo)
    ok = .false.
    niter = 0
    if (flo * f(hi) > 0.0_real64) return      ! 端点同号，不能用二分法
    do niter = 1, maxit
      mid = 0.5_real64 * (lo + hi)
      fmid = f(mid)
      if (abs(fmid) < tol .or. abs(hi - lo) < tol * max(1.0_real64, abs(mid))) then
        x = mid
        ok = .true.
        return
      end if
      if (flo * fmid < 0.0_real64) then
        hi = mid
      else
        lo = mid; flo = fmid
      end if
    end do
    x = 0.5_real64 * (lo + hi)
  end subroutine bisect

  ! ---- 牛顿法：二阶收敛，但需要导数，且初值差会发散 ----
  subroutine newton(f, df, x0, x, niter, ok)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
      pure function df(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function df
    end interface
    real(real64), intent(in) :: x0
    real(real64), intent(out) :: x
    integer(int32), intent(out) :: niter
    logical, intent(out) :: ok
    real(real64) :: cur, step
    cur = x0
    ok = .false.
    do niter = 1, maxit
      if (abs(df(cur)) < 1.0e-300_real64) return    ! 导数太小，避免溢出
      step = f(cur) / df(cur)
      cur = cur - step
      if (abs(step) < tol) then
        x = cur
        ok = .true.
        return
      end if
    end do
    x = cur
  end subroutine newton

  ! ---- 割线法：不用导数，用两点差商近似 ----
  subroutine secant(f, x0, x1, x, niter, ok)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
    end interface
    real(real64), intent(in) :: x0, x1
    real(real64), intent(out) :: x
    integer(int32), intent(out) :: niter
    logical, intent(out) :: ok
    real(real64) :: p0, p1, p2, f0, f1, den
    p0 = x0; p1 = x1
    f0 = f(p0); f1 = f(p1)
    ok = .false.
    do niter = 1, maxit
      den = f1 - f0
      if (abs(den) < 1.0e-300_real64) return
      p2 = p1 - f1 * (p1 - p0) / den
      if (abs(p2 - p1) < tol) then
        x = p2
        ok = .true.
        return
      end if
      p0 = p1; f0 = f1
      p1 = p2; f1 = f(p1)
    end do
    x = p1
  end subroutine secant

  ! ---- 不动点迭代：x = g(x)，收敛条件是 |g'(x)| < 1 ----
  subroutine fixed_point(g, x0, x, niter, ok)
    interface
      pure function g(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function g
    end interface
    real(real64), intent(in) :: x0
    real(real64), intent(out) :: x
    integer(int32), intent(out) :: niter
    logical, intent(out) :: ok
    real(real64) :: cur, prev
    cur = x0
    ok = .false.
    do niter = 1, maxit
      prev = cur
      cur = g(cur)
      if (abs(cur - prev) < tol) then
        x = cur
        ok = .true.
        return
      end if
    end do
    x = cur
  end subroutine fixed_point

  ! ---- 复合梯形法：误差 O(h^2) ----
  pure function trapezoid(f, a, b, n) result(s)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
    end interface
    real(real64), intent(in) :: a, b
    integer(int32), intent(in) :: n
    real(real64) :: s, h
    integer(int32) :: i
    h = (b - a) / real(n, real64)
    s = 0.5_real64 * (f(a) + f(b))
    do i = 1, n - 1
      s = s + f(a + real(i, real64) * h)
    end do
    s = s * h
  end function trapezoid

  ! ---- 复合辛普森法：误差 O(h^4)，n 必须是偶数 ----
  pure function simpson(f, a, b, n) result(s)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
    end interface
    real(real64), intent(in) :: a, b
    integer(int32), intent(in) :: n
    real(real64) :: s, h, x
    integer(int32) :: i, m
    m = n
    if (mod(m, 2) /= 0) m = m + 1          ! 兜一下：奇数就加一节
    h = (b - a) / real(m, real64)
    s = f(a) + f(b)
    do i = 1, m - 1
      x = a + real(i, real64) * h
      if (mod(i, 2) == 0) then
        s = s + 2.0_real64 * f(x)
      else
        s = s + 4.0_real64 * f(x)
      end if
    end do
    s = s * h / 3.0_real64
  end function simpson

  ! ---- 复合中点法：最朴素，但误差也是 O(h^2) 且常数更小 ----
  pure function midpoint(f, a, b, n) result(s)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
    end interface
    real(real64), intent(in) :: a, b
    integer(int32), intent(in) :: n
    real(real64) :: s, h
    integer(int32) :: i
    h = (b - a) / real(n, real64)
    s = 0.0_real64
    do i = 0, n - 1
      s = s + f(a + (real(i, real64) + 0.5_real64) * h)
    end do
    s = s * h
  end function midpoint

  ! ---- 中心差分求导：误差 O(h^2) ----
  pure function central_diff(f, x, h) result(d)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
    end interface
    real(real64), intent(in) :: x, h
    real(real64) :: d
    d = (f(x + h) - f(x - h)) / (2.0_real64 * h)
  end function central_diff

  ! ---- Richardson 外推：把 O(h^2) 推到 O(h^4) ----
  pure function richardson(f, x, h) result(d)
    interface
      pure function f(x) result(y)
        use, intrinsic :: iso_fortran_env, only: real64
        real(real64), intent(in) :: x
        real(real64) :: y
      end function f
    end interface
    real(real64), intent(in) :: x, h
    real(real64) :: d, d1, d2
    d1 = (f(x + h) - f(x - h)) / (2.0_real64 * h)
    d2 = (f(x + h / 2.0_real64) - f(x - h / 2.0_real64)) / h
    d = (4.0_real64 * d2 - d1) / 3.0_real64
  end function richardson

  ! ---- LU 分解 + 部分主元求解 Ax = b ----
  !      A 会被原地分解破坏（A = L\U 紧凑存储），b 是只读的
  subroutine lu_solve(A, b, x, ok)
    real(real64), intent(inout) :: A(:, :)
    real(real64), intent(in) :: b(:)
    real(real64), intent(out) :: x(:)
    logical, intent(out) :: ok
    integer(int32) :: n, i, j, k, piv
    real(real64) :: factor, tmp, maxv, rowsum, tmpb
    real(real64), allocatable :: y(:)
    n = size(b)
    ok = .false.
    if (size(A, 1) /= n .or. size(A, 2) /= n .or. size(x) /= n) return
    ! 右端项要跟着 A 一起换行！这是选主元最容易漏的一步
    allocate (y(n))
    y = b
    do k = 1, n - 1
      ! 选主元：找第 k 列下方绝对值最大的行
      piv = k
      maxv = abs(A(k, k))
      do i = k + 1, n
        if (abs(A(i, k)) > maxv) then
          maxv = abs(A(i, k)); piv = i
        end if
      end do
      if (maxv < 1.0e-14_real64) return          ! 奇异
      if (piv /= k) then
        do j = 1, n
          tmp = A(k, j); A(k, j) = A(piv, j); A(piv, j) = tmp
        end do
        tmpb = y(k); y(k) = y(piv); y(piv) = tmpb   ! ← 别忘了它
      end if
      do i = k + 1, n
        A(i, k) = A(i, k) / A(k, k)              ! 存 L 的乘子（就地）
        factor = A(i, k)
        do j = k + 1, n
          A(i, j) = A(i, j) - factor * A(k, j)
        end do
      end do
    end do
    if (abs(A(n, n)) < 1.0e-14_real64) return
    ! 前代
    do i = 2, n
      do j = 1, i - 1
        y(i) = y(i) - A(i, j) * y(j)
      end do
    end do
    ! 回代
    x(n) = y(n) / A(n, n)
    do i = n - 1, 1, -1
      rowsum = y(i)
      do j = i + 1, n
        rowsum = rowsum - A(i, j) * x(j)
      end do
      x(i) = rowsum / A(i, i)
    end do
    ok = .true.
  end subroutine lu_solve

  ! ---- 用 LU 分解算行列式（对角元乘积 × 符号）----
  pure function det(Ain) result(d)
    real(real64), intent(in) :: Ain(:, :)
    real(real64) :: d
    real(real64), allocatable :: A(:, :)
    integer(int32) :: n, i, j, k, piv
    real(real64) :: maxv, tmp, factor
    logical :: neg
    n = size(Ain, 1)
    allocate (A(n, n))
    A = Ain
    d = 0.0_real64
    neg = .false.
    do k = 1, n - 1
      piv = k; maxv = abs(A(k, k))
      do i = k + 1, n
        if (abs(A(i, k)) > maxv) then
          maxv = abs(A(i, k)); piv = i
        end if
      end do
      if (maxv < 1.0e-14_real64) return
      if (piv /= k) then
        neg = .not. neg
        do j = 1, n
          tmp = A(k, j); A(k, j) = A(piv, j); A(piv, j) = tmp
        end do
      end if
      do i = k + 1, n
        factor = A(i, k) / A(k, k)
        do j = k + 1, n
          A(i, j) = A(i, j) - factor * A(k, j)
        end do
      end do
    end do
    d = 1.0_real64
    do i = 1, n
      d = d * A(i, i)
    end do
    if (neg) d = -d
  end function det

  ! ---- 拉格朗日插值：给定 n 个点，求任意 x 处的值 ----
  pure function lagrange_interp(xs, ys, x) result(y)
    real(real64), intent(in) :: xs(:), ys(:), x
    real(real64) :: y, term
    integer(int32) :: i, j, n
    n = size(xs)
    y = 0.0_real64
    do i = 1, n
      term = ys(i)
      do j = 1, n
        if (j /= i) then
          term = term * (x - xs(j)) / (xs(i) - xs(j))
        end if
      end do
      y = y + term
    end do
  end function lagrange_interp

  ! ---- 给演示用的便捷封装：解 3x3 ----
  function solve_lu(A, b) result(x)
    real(real64), intent(in) :: A(:, :), b(:)
    real(real64), allocatable :: x(:)
    real(real64), allocatable :: Ac(:, :)
    logical :: ok
    integer(int32) :: n
    n = size(b)
    allocate (Ac(n, n), x(n))
    Ac = A
    call lu_solve(Ac, b, x, ok)
    if (.not. ok) x = -999.0_real64
  end function solve_lu

end module numeric

! ============================================================

program numeric_demo
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use numeric
  implicit none

  real(real64) :: r, x, x2, pi_ref, err, h, dnum, dexact, s_tr, s_si, s_mi
  real(real64) :: A(3, 3), b(3), xs(5), ys(5)
  integer(int32) :: it, n
  logical :: ok
  real(real64), allocatable :: sol(:)

  write (*, '(a)') '被求方程 f(x) = x^3 - 2x - 5 = 0，真根 x0 = 2.0945514815423265'
  r = 2.0945514815423265_real64

  ! ---- 1) 四种求根方法对照 ----
  write (*, '(a)') '1) 求根方法对比（|误差| 越小越好）'
  call bisect(fx, 2.0_real64, 3.0_real64, x, it, ok)
  write (*, '(a,l1,a,i0,a,es12.4)') '   二分法     ok=', ok, '  迭代 ', it, ' 次  误差 ', abs(x - r)
  call newton(fx, dfx, 2.0_real64, x2, it, ok)
  write (*, '(a,l1,a,i0,a,es12.4)') '   牛顿法     ok=', ok, '  迭代 ', it, ' 次  误差 ', abs(x2 - r)
  call secant(fx, 2.0_real64, 3.0_real64, x2, it, ok)
  write (*, '(a,l1,a,i0,a,es12.4)') '   割线法     ok=', ok, '  迭代 ', it, ' 次  误差 ', abs(x2 - r)
  call fixed_point(gx, 2.0_real64, x2, it, ok)
  write (*, '(a,l1,a,i0,a,es12.4)') '   不动点迭代 ok=', ok, '  迭代 ', it, ' 次  误差 ', abs(x2 - r)
  write (*, '(a)') '   牛顿法迭代次数最少 —— 二阶收敛的直接体现'

  ! ---- 2) 求根区间不合法时二分法会拒绝 ----
  call bisect(fx, 3.0_real64, 4.0_real64, x2, it, ok)
  write (*, '(a,l1)') '2) 区间 [3,4] 端点同号，二分法 ok=', ok

  ! ---- 3) 数值积分：三种方法算 ∫₀^π sin(x) dx = 2 ----
  pi_ref = acos(-1.0_real64)
  n = 100
  s_tr = trapezoid(my_sin, 0.0_real64, pi_ref, n)
  s_si = simpson(my_sin, 0.0_real64, pi_ref, n)
  s_mi = midpoint(my_sin, 0.0_real64, pi_ref, n)
  write (*, '(a,i0,a)') '3) 积分 ∫₀^π sin(x)dx，n = ', n, '（真值 2）'
  write (*, '(a,es14.6)') '   梯形法  误差 : ', abs(s_tr - 2.0_real64)
  write (*, '(a,es14.6)') '   辛普森  误差 : ', abs(s_si - 2.0_real64)
  write (*, '(a,es14.6)') '   中点法  误差 : ', abs(s_mi - 2.0_real64)

  ! ---- 4) 收敛阶验证：n 翻倍误差降多少倍 ----
  write (*, '(a)') '4) 收敛阶验证（n = 10/20/40，看误差比值）'
  do n = 10, 40, 10
    err = abs(trapezoid(my_sin, 0.0_real64, pi_ref, n) - 2.0_real64)
    write (*, '(a,i3,a,es12.4)') '   n=', n, '  梯形法误差 = ', err
  end do
  write (*, '(a)') '   n 每翻倍误差降到约 1/4 → O(h^2)；辛普森是 O(h^4)'

  ! ---- 5) 数值微分 ----
  write (*, '(a)') '5) f(x)=sin(x) 在 x=1 处求导，真值 cos(1) = 0.5403023058681398'
  dexact = cos(1.0_real64)
  h = 1.0e-2_real64
  dnum = central_diff(my_sin, 1.0_real64, h)
  write (*, '(a,es14.6)') '   中心差分 h=1e-2 误差 : ', abs(dnum - dexact)
  dnum = richardson(my_sin, 1.0_real64, h)
  write (*, '(a,es14.6)') '   Richardson 外推 误差 : ', abs(dnum - dexact)
  write (*, '(a)') '   再看 h 变小时中心差分的误差行为：'
  do n = 1, 6
    h = 10.0_real64**(-real(n, real64))
    write (*, '(a,i0,a,es12.4)') '   h = 1e-', n, '   误差 = ', abs(central_diff(my_sin, 1.0_real64, h) - dexact)
  end do
  write (*, '(a)') '   h 太小反而变差 —— 分子相减的灾难性抵消'

  ! ---- 6) 线性方程组 ----
  A(1, :) = [2.0_real64, 1.0_real64, -1.0_real64]
  A(2, :) = [-3.0_real64, -1.0_real64, 2.0_real64]
  A(3, :) = [-2.0_real64, 1.0_real64, 2.0_real64]
  b = [8.0_real64, -11.0_real64, -3.0_real64]     ! 真解 (2, 3, -1)
  sol = solve_lu(A, b)
  write (*, '(a,3(f11.6,1x))') '6) LU 求解结果  : ', sol
  write (*, '(a,es14.6)') '   与真解 (2,3,-1) 的最大偏差 : ', &
    maxval(abs(sol - [2.0_real64, 3.0_real64, -1.0_real64]))
  write (*, '(a,es14.6)') '   行列式 det(A) = ', det(A)     ! = -1
  write (*, '(a)') '   注意：选主元换行时右端项必须同步交换，否则解是错的'

  ! ---- 7) 拉格朗日插值 ----
  xs = [0.0_real64, 1.0_real64, 2.0_real64, 3.0_real64, 4.0_real64]
  ys = [1.0_real64, 2.0_real64, 5.0_real64, 10.0_real64, 17.0_real64]   ! y = x^2 + 1
  write (*, '(a)') '7) 拉格朗日插值（数据取自 y = x²+1）'
  do n = 0, 4
    write (*, '(a,f4.1,a,f10.6,a,f10.6)') '   x=', real(n, real64) + 0.5_real64, &
      '  插值 = ', lagrange_interp(xs, ys, real(n, real64) + 0.5_real64), &
      '  真值 = ', (real(n, real64) + 0.5_real64)**2 + 1.0_real64
  end do

  write (*, '(a)') '==== 16 结束 ===='

contains

  ! 内部过程也能作为过程实参传出去（f90 起支持 internal procedure）
  pure function my_sin(x) result(y)
    real(real64), intent(in) :: x
    real(real64) :: y
    y = sin(x)
  end function my_sin

end program numeric_demo
