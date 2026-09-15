! ============================================================
! 10 - 过程：子程序与函数
!   intent、result、可选参数、关键字实参、内部过程、
!   pure / elemental / impure elemental、recursive、
!   假设形状数组、可分配结果、过程作为实参
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 10-procedures.f90 -o 10-procedures
! ============================================================

module proc_lib
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: swap_i, mean_r, polyval, sq, bump, fib, &
            apply_r, mk_range, concat, split_pair, my_sin, my_exp

  ! 抽象接口：描述「函数长什么样」，用来把过程当参数传
  abstract interface
    pure real(real64) function rfun(x)
      import :: real64
      real(real64), intent(in) :: x
    end function rfun
  end interface

contains

  ! ---- 子程序 + intent(inout)：真能改到实参 ----
  pure subroutine swap_i(a, b)
    integer(int32), intent(inout) :: a, b
    integer(int32) :: t
    t = a; a = b; b = t
  end subroutine swap_i

  ! ---- 函数 + result 子句（结果名与函数名分离）----
  pure function mean_r(x) result(m)
    real(real64), intent(in) :: x(:)        ! 假设形状数组：形状随实参走
    real(real64) :: m
    m = sum(x) / real(size(x), real64)
  end function mean_r

  ! ---- 可选参数：present() 判断是否真的传了 ----
  ! deriv 为真时返回导数。Horner 法可以同时算出多项式值和导数值：
  !   d = d*x + v ;  v = v*x + c(k)   两句的顺序不能换
  pure function polyval(x, c, deriv) result(v)
    real(real64), intent(in) :: x, c(:)     ! c(1) 是常数项
    logical, intent(in), optional :: deriv
    real(real64) :: v, d
    integer(int32) :: k
    v = 0.0_real64
    d = 0.0_real64
    do k = size(c), 1, -1
      d = d * x + v
      v = v * x + c(k)
    end do
    if (present(deriv)) then
      if (deriv) v = d
    end if
  end function polyval

  ! ---- 递归函数：必须先声明 recursive ----
  recursive function fib(n) result(r)
    integer(int32), intent(in) :: n
    integer(int32) :: r
    if (n < 2) then
      r = n
    else
      r = fib(n - 1) + fib(n - 2)
    end if
  end function fib

  ! ---- 元素过程：标量写一次，数组可以整体调用 ----
  pure elemental integer(int32) function sq(x) result(r)
    integer(int32), intent(in) :: x
    r = x * x
  end function sq

  ! ---- 非纯元素过程：元素过程默认是 pure，impure 才能做副作用 ----
  impure elemental subroutine bump(x, by)
    integer(int32), intent(inout) :: x
    integer(int32), intent(in)    :: by
    x = x + by
  end subroutine bump

  ! ---- 把过程当实参传：哑元用 abstract interface 描述 ----
  pure function apply_r(f, x) result(y)
    procedure(rfun) :: f
    real(real64), intent(in) :: x
    real(real64) :: y
    y = f(x)
  end function apply_r

  ! 坑：sin / exp 是「泛型」内建，具体过程不唯一（real32/real64/complex…），
  ! 直接当实参传会报接口不匹配。正确做法是先包一层签名明确的函数。
  pure real(real64) function my_sin(x) result(y)
    real(real64), intent(in) :: x
    y = sin(x)
  end function my_sin

  pure real(real64) function my_exp(x) result(y)
    real(real64), intent(in) :: x
    y = exp(x)
  end function my_exp

  ! ---- 可分配结果：长度/大小在运行时才定 ----
  pure function mk_range(a, b, step) result(r)
    integer(int32), intent(in) :: a, b, step
    integer(int32), allocatable :: r(:)
    integer(int32) :: n, k
    n = (b - a) / step + 1
    allocate (r(n))
    r = [(a + (k - 1) * step, k = 1, n)]
  end function mk_range

  ! ---- 返回延迟长度字符串 ----
  pure function concat(a, b, sep) result(r)
    character(len=*), intent(in) :: a, b, sep
    character(len=:), allocatable :: r
    r = trim(a) // sep // trim(b)
  end function concat

  ! ---- 输出型哑元：同时改到实参 ----
  pure subroutine split_pair(txt, left, right)
    character(len=*), intent(in)  :: txt
    character(len=*), intent(out) :: left, right
    integer(int32) :: k
    k = index(txt, '=')
    if (k > 0) then
      left = txt(1:k - 1)
      right = txt(k + 1:)
    else
      left = txt
      right = ''
    end if
  end subroutine split_pair

end module proc_lib

! ============================================================

program procedures
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use proc_lib
  implicit none

  integer(int32) :: a, b
  integer(int32) :: arr(5) = [1, 2, 3, 4, 5]
  real(real64)   :: xs(5) = [1.0_real64, 2.0_real64, 3.0_real64, 4.0_real64, 5.0_real64]
  character(len=16) :: l, r

  ! 外部过程要当实参传，调用方也得有显式接口：写个接口块即可
  interface
    pure real(real64) function my3x(x)
      import :: real64
      real(real64), intent(in) :: x
    end function my3x
  end interface

  ! ---- 1) 子程序改实参 ----
  a = 1; b = 2
  call swap_i(a, b)
  write (*, '(a,i0,a,i0)') '1) swap 后 a=', a, ' b=', b

  ! ---- 2) 假设形状数组：什么长度都能收 ----
  write (*, '(a,f0.4)') '2) mean_r([1..5]) : ', mean_r(xs)
  write (*, '(a,f0.4)') '   mean_r(3 个)   : ', mean_r(xs(1:3))

  ! ---- 3) 可选参数与关键字实参 ----
  write (*, '(a,f0.2)') '3) p(2) 默认       : ', polyval(2.0_real64, [1.0_real64, 0.0_real64, 1.0_real64])
  write (*, '(a,f0.2)') '   p(2) 求导       : ', &
      polyval(x=2.0_real64, c=[1.0_real64, 0.0_real64, 1.0_real64], deriv=.true.)

  ! ---- 4) 递归 ----
  write (*, '(a,i0)') '4) fib(20) : ', fib(20)

  ! ---- 5) 元素过程：标量形式 vs 数组整体 ----
  write (*, '(a,5i4)') '5) sq 逐元素 : ', sq(arr)
  call bump(arr, 10)
  write (*, '(a,5i4)') '   bump +10  : ', arr

  ! ---- 6) 内部过程：能访问宿主作用域的变量 ----
  write (*, '(a,i0)') '6) 内部过程累加 1..100 : ', sum_to(100)

  ! ---- 7) 把过程当实参（模块过程、外部过程、内部过程都可以）----
  write (*, '(a,f0.6)') '7) apply_r(my_sin, 1.0) : ', apply_r(my_sin, 1.0_real64)
  write (*, '(a,f0.6)') '   apply_r(my_exp, 1.0) : ', apply_r(my_exp, 1.0_real64)
  write (*, '(a,f0.6)') '   apply_r(my3x,   1.0) : ', apply_r(my3x, 1.0_real64)
  write (*, '(a,f0.6)') '   apply_r(inner4, 1.0) : ', apply_r(inner4, 1.0_real64)
  write (*, '(a,a)')    '   （sin/exp 是泛型内建，不能直接当实参，见模块里的注释）'

  ! ---- 8) 可分配结果与延迟长度字符串 ----
  block
    integer(int32), allocatable :: rg(:)
    rg = mk_range(2, 20, 3)
    write (*, '(a,i0,a,7i4)') '8) mk_range(2,20,3) n=', size(rg), ' : ', rg
  end block
  write (*, '(a,a)') '   concat : ', concat('left', 'right', ' | ')

  ! ---- 9) 输出型哑元 ----
  call split_pair('key=value', l, r)
  write (*, '(a,a,a,a,a)') '9) 拆分后 [', trim(l), '] [', trim(r), ']'

  ! ---- 10) 同一过程的不同调用形态 ----
  write (*, '(a,i0)') '10) sq(arr(3))      = ', sq(arr(3))
  write (*, '(a,i0)') '    sum(sq(arr))    = ', sum(sq(arr))
  write (*, '(a,i0)') '    标量哑元收到数组？形状不匹配，编译期就该报错'

  write (*, '(a)') '==== 10 结束 ===='

contains

  ! 内部过程：直接看得见 host 里的 a、b、k
  pure function sum_to(n) result(s)
    integer(int32), intent(in) :: n
    integer(int32) :: s
    s = n * (n + 1) / 2
  end function sum_to

  pure real(real64) function inner4(x) result(y)
    real(real64), intent(in) :: x
    y = 4.0_real64 * x
  end function inner4

end program procedures

! 外部过程：必须显式声明接口才能当实参（这里靠模块里的抽象接口）
pure real(real64) function my3x(x)
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  real(real64), intent(in) :: x
  my3x = 3.0_real64 * x
end function my3x
