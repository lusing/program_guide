! ============================================================
! 11 - 模块与接口
!   模块结构、默认私有、use only 与重命名、泛型接口、
!   运算符与赋值重载、接口块（外部过程显式接口）、子模块
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 11-modules.f90 -o 11-modules
! ============================================================

! ------------------------------------------------------------
! 模块 A：用默认私有 + 显式 public 列表控制可见面
! ------------------------------------------------------------
module mod_alpha
  use, intrinsic :: iso_fortran_env, only: int32
  implicit none
  private                                    ! 默认全私有
  public :: alpha_val, tag_alpha, describe

  integer(int32), parameter :: alpha_val = 11
  character(len=8), parameter :: tag_alpha = 'alpha'
  integer(int32) :: counter = 0              ! 模块变量：整个程序共享一份

contains

  subroutine describe()
    counter = counter + 1
    write (*, '(a,a,a,i0)') '   [', trim(tag_alpha), '] 第 ', counter, ' 次调用'
  end subroutine describe

end module mod_alpha

! ------------------------------------------------------------
! 模块 B：故意也导出名叫 tag 的量，用来演示 use 重命名
! ------------------------------------------------------------
module mod_beta
  use, intrinsic :: iso_fortran_env, only: int32
  implicit none
  private
  public :: beta_val, tag

  integer(int32), parameter :: beta_val = 22
  character(len=8), parameter :: tag = 'beta'

end module mod_beta

! ------------------------------------------------------------
! 模块 C：向量类型 + 运算符重载 + 泛型接口
! ------------------------------------------------------------
module vecmod
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private
  public :: vec3, operator(+), operator(-), operator(*), operator(==), &
            operator(.dot.), assignment(=), show, vec_norm

  type :: vec3
    real(real64) :: x = 0.0_real64, y = 0.0_real64, z = 0.0_real64
  end type vec3

  ! 泛型名 show：三个具体过程共用一个名字，按实参类型自动挑
  interface show
    module procedure show_i, show_r, show_s
  end interface show

  interface operator(+)
    module procedure add_vv
  end interface

  interface operator(-)
    module procedure sub_vv
  end interface

  interface operator(*)
    module procedure scale_vr
  end interface

  interface operator(==)
    module procedure eq_vv
  end interface

  ! 自定义点乘运算符：名字以点号包起来
  interface operator(.dot.)
    module procedure dot_vv
  end interface

  ! 赋值重载：允许 x = 2.5 直接生成向量
  interface assignment(=)
    module procedure assign_r_to_v
  end interface

contains

  pure function add_vv(a, b) result(r)
    type(vec3), intent(in) :: a, b
    type(vec3) :: r
    r%x = a%x + b%x; r%y = a%y + b%y; r%z = a%z + b%z
  end function add_vv

  pure function sub_vv(a, b) result(r)
    type(vec3), intent(in) :: a, b
    type(vec3) :: r
    r%x = a%x - b%x; r%y = a%y - b%y; r%z = a%z - b%z
  end function sub_vv

  pure function scale_vr(a, s) result(r)
    type(vec3), intent(in) :: a
    real(real64), intent(in) :: s
    type(vec3) :: r
    r%x = a%x * s; r%y = a%y * s; r%z = a%z * s
  end function scale_vr

  pure function eq_vv(a, b) result(r)
    type(vec3), intent(in) :: a, b
    logical :: r
    r = (a%x == b%x) .and. (a%y == b%y) .and. (a%z == b%z)
  end function eq_vv

  pure function dot_vv(a, b) result(r)
    type(vec3), intent(in) :: a, b
    real(real64) :: r
    r = a%x * b%x + a%y * b%y + a%z * b%z
  end function dot_vv

  pure function vec_norm(a) result(r)
    type(vec3), intent(in) :: a
    real(real64) :: r
    r = sqrt(a%x**2 + a%y**2 + a%z**2)
  end function vec_norm

  pure subroutine assign_r_to_v(v, s)
    type(vec3), intent(out) :: v
    real(real64), intent(in) :: s
    v = vec3(s, 0.0_real64, 0.0_real64)
  end subroutine assign_r_to_v

  subroutine show_i(v)
    integer, intent(in) :: v
    write (*, '(a,i0)') '   show(integer) : ', v
  end subroutine show_i

  subroutine show_r(v)
    real(real64), intent(in) :: v
    write (*, '(a,f0.4)') '   show(real)    : ', v
  end subroutine show_r

  subroutine show_s(v)
    character(len=*), intent(in) :: v
    write (*, '(a,a)') '   show(character): ', trim(v)
  end subroutine show_s

end module vecmod

! ------------------------------------------------------------
! 模块 D：只有接口，实现在子模块里（大项目里把接口与实现分开编译）
! ------------------------------------------------------------
module stats
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private
  public :: mean, stdev

  interface
    module function mean(x) result(m)
      real(real64), intent(in) :: x(:)
      real(real64) :: m
    end function mean

    module function stdev(x) result(s)
      real(real64), intent(in) :: x(:)
      real(real64) :: s
    end function stdev
  end interface

end module stats

submodule(stats) stats_impl
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
contains

  module function mean(x) result(m)
    real(real64), intent(in) :: x(:)
    real(real64) :: m
    m = sum(x) / real(size(x), real64)
  end function mean

  ! 实现在子模块里，直接复用同一模块上一层的 mean
  module function stdev(x) result(s)
    real(real64), intent(in) :: x(:)
    real(real64) :: s
    real(real64) :: m
    m = mean(x)
    s = sqrt(sum((x - m)**2) / real(size(x) - 1, real64))
  end function stdev

end submodule stats_impl

! ============================================================

program modules_demo
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use mod_alpha                              ! 全量引入
  use mod_beta, only: beta_val, tag_b => tag ! only + 重命名：避免与 mod_alpha 的 tag 冲突
  use vecmod
  use stats
  implicit none

  type(vec3) :: u, v, w
  real(real64) :: xs(5) = [2.0_real64, 4.0_real64, 4.0_real64, 4.0_real64, 6.0_real64]

  ! 外部过程的显式接口：写在接口块里，之后就能正常调用与传参
  interface
    pure function ext_sumsq(a, n) result(s)
      import :: int32, real64
      integer(int32), intent(in) :: n
      integer(int32), intent(in) :: a(:)
      real(real64) :: s
    end function ext_sumsq
  end interface

  ! ---- 1) 模块常量与 use only ----
  write (*, '(a,a,a,i0)') '1) mod_alpha 的 tag = ', trim(tag_alpha), ' 值 = ', alpha_val
  write (*, '(a,a,a,i0)') '   mod_beta 重命名后 = ', trim(tag_b), ' 值 = ', beta_val

  ! ---- 2) 模块变量是全局唯一的一份 ----
  write (*, '(a)') '2) 调用模块过程三次，看计数器：'
  call describe()
  call describe()
  call describe()

  ! ---- 3) 泛型接口：同名不同型 ----
  write (*, '(a)') '3) 泛型接口 show：'
  call show(42)
  call show(3.25_real64)
  call show('hello')

  ! ---- 4) 运算符重载 ----
  u = vec3(1.0_real64, 2.0_real64, 3.0_real64)
  v = vec3(4.0_real64, 5.0_real64, 6.0_real64)
  w = u + v
  write (*, '(a,3f6.1)') '4) u + v      : ', w%x, w%y, w%z
  w = v - u
  write (*, '(a,3f6.1)') '   v - u      : ', w%x, w%y, w%z
  w = u * 2.0_real64
  write (*, '(a,3f6.1)') '   u * 2.0    : ', w%x, w%y, w%z
  write (*, '(a,l1)')    '   u == u     : ', u == u
  write (*, '(a,l1)')    '   u == v     : ', u == v
  write (*, '(a,f0.1)')  '   u .dot. v  : ', u .dot. v
  write (*, '(a,f0.6)')  '   |u|        : ', vec_norm(u)

  ! ---- 5) 赋值重载：实数直接变向量 ----
  w = 7.5_real64
  write (*, '(a,3f6.1)') '5) w = 7.5（赋值重载） : ', w%x, w%y, w%z

  ! ---- 6) 子模块提供的实现 ----
  write (*, '(a,f0.4)') '6) stats(子模块) mean  : ', mean(xs)
  write (*, '(a,f0.4)') '   stats(子模块) stdev : ', stdev(xs)

  ! ---- 7) 接口块声明的外部过程 ----
  write (*, '(a,f0.2)') '7) 外部函数 ext_sumsq : ', ext_sumsq([1, 2, 3, 4], 4)

  write (*, '(a)') '==== 11 结束 ===='
end program modules_demo

! 外部函数：定义在本文件里，靠上面的接口块让调用方看到显式接口
pure function ext_sumsq(a, n) result(s)
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  integer(int32), intent(in) :: n
  integer(int32), intent(in) :: a(:)
  real(real64) :: s
  integer(int32) :: k
  s = 0.0_real64
  do k = 1, n
    s = s + real(a(k), real64)**2
  end do
end function ext_sumsq
