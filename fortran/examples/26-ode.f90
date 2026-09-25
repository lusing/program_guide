! ============================================================
! 26 - 常微分方程数值解
!   欧拉法 / 改进欧拉（Heun）/ 经典 RK4，解 y' = -y + x²+1
!   （有精确解 y = x²−2x+3−3e⁻ˣ，可逐点算误差）；
!   二阶方程降阶成方程组（y''=-y → y'=v, v'=-y，解 y=sin x）；
!   显式欧拉的稳定性边界演示（|λh|>2 时解发散）
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 26-ode.f90 -o 26-ode
! ============================================================

module ode_mod
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: euler_step, heun_step, rk4_step, rk4v_step, exact, rhs, exact2

  abstract interface
    ! 标量右端函数 f(x, y)
    real(real64) pure function f_iface(x, y)
      import :: real64
      real(real64), intent(in) :: x, y
    end function
    ! 向量右端函数 f(x, u) —— 方程组版
    function fu_iface(x, u)
      import :: real64
      real(real64), intent(in) :: x, u(:)
      real(real64) :: fu_iface(size(u))
    end function
  end interface

contains

  ! 被解的方程：y' = -y + x² + 1
  real(real64) pure function rhs(x, y)
    real(real64), intent(in) :: x, y
    rhs = -y + x * x + 1.0_real64
  end function rhs

  ! 精确解：y = x² − 2x + 3 − 3e⁻ˣ（y(0)=0 代入得 C=-3）
  real(real64) pure function exact(x)
    real(real64), intent(in) :: x
    exact = x * x - 2.0_real64 * x + 3.0_real64 - 3.0_real64 * exp(-x)
  end function exact

  ! 精确解（方程组那道题）：y = sin x
  real(real64) pure function exact2(x)
    real(real64), intent(in) :: x
    exact2 = sin(x)
  end function exact2

  ! 欧拉法：沿起点的斜率走一步 —— 最笨也最透明
  real(real64) pure function euler_step(f, x, y, h)
    procedure(f_iface) :: f
    real(real64), intent(in) :: x, y, h
    euler_step = y + h * f(x, y)
  end function euler_step

  ! 改进欧拉（Heun）：两端斜率取平均，误差从 O(h) 降到 O(h²)
  real(real64) pure function heun_step(f, x, y, h)
    procedure(f_iface) :: f
    real(real64), intent(in) :: x, y, h
    real(real64) :: k1, k2
    k1 = f(x, y)
    k2 = f(x + h, y + h * k1)
    heun_step = y + 0.5_real64 * h * (k1 + k2)
  end function heun_step

  ! 经典 RK4：四个斜率加权平均，误差 O(h⁴)
  real(real64) pure function rk4_step(f, x, y, h)
    procedure(f_iface) :: f
    real(real64), intent(in) :: x, y, h
    real(real64) :: k1, k2, k3, k4
    k1 = f(x, y)
    k2 = f(x + 0.5_real64 * h, y + 0.5_real64 * h * k1)
    k3 = f(x + 0.5_real64 * h, y + 0.5_real64 * h * k2)
    k4 = f(x + h, y + h * k3)
    rk4_step = y + h * (k1 + 2.0_real64 * k2 + 2.0_real64 * k3 + k4) / 6.0_real64
  end function rk4_step

  ! RK4 的方程组版：u 是向量，size(u) 自动数组让同一份代码通吃任意维
  function rk4v_step(f, x, u, h) result(un)
    procedure(fu_iface) :: f
    real(real64), intent(in) :: x, u(:), h
    real(real64) :: un(size(u))
    real(real64) :: k1(size(u)), k2(size(u)), k3(size(u)), k4(size(u))
    k1 = f(x, u)
    k2 = f(x + 0.5_real64 * h, u + 0.5_real64 * h * k1)
    k3 = f(x + 0.5_real64 * h, u + 0.5_real64 * h * k2)
    k4 = f(x + h, u + h * k3)
    un = u + h * (k1 + 2.0_real64 * k2 + 2.0_real64 * k3 + k4) / 6.0_real64
  end function rk4v_step

end module ode_mod

program ode_demo
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use ode_mod
  implicit none

  real(real64), parameter :: x0 = 0.0_real64, x1 = 1.0_real64
  real(real64), parameter :: y0 = 0.0_real64
  real(real64), parameter :: exact_y1 = 0.8963622665669971_real64  ! = 2 - 3/e
  integer(int32), parameter :: n = 10       ! h = 0.1
  real(real64) :: h, x, ye, yh, yr
  integer(int32) :: i

  h = (x1 - x0) / real(n, real64)

  ! ---- 1) 三种方法走同一条方程，误差差五个数量级 ----
  ye = y0; yh = y0; yr = y0
  x = x0
  do i = 1, n
    ye = euler_step(rhs, x, ye, h)
    yh = heun_step(rhs, x, yh, h)
    yr = rk4_step(rhs, x, yr, h)
    x = x0 + real(i, real64) * h
  end do
  write (*, '(a)')        '1) y''= -y + x² + 1, y(0)=0, h=0.1 走到 x=1：'
  write (*, '(a,f12.8)')  '   精确解 y(1)      = ', exact_y1
  write (*, '(a,f12.8,a,es9.2)') '   欧拉法          = ', ye, '   误差 ', abs(ye - exact_y1)
  write (*, '(a,f12.8,a,es9.2)') '   改进欧拉        = ', yh, '   误差 ', abs(yh - exact_y1)
  write (*, '(a,f12.8,a,es9.2)') '   RK4             = ', yr, '   误差 ', abs(yr - exact_y1)
  write (*, '(a)')        '   ↑ 同一方程同一步长：每步多算几次斜率，误差掉四个多数量级'

  ! ---- 2) 二阶方程降阶：y'' = -y → y' = v, v' = -y ----
  ! 初值 y(0)=0, v(0)=1 ⇒ y = sin(x)。RK4 方程组版一步到位。
  block
    real(real64) :: u(2)
    u = [0.0_real64, 1.0_real64]          ! u(1)=y, u(2)=v=y'
    x = x0
    do i = 1, n
      u = rk4v_step(sho, x, u, h)
      x = x0 + real(i, real64) * h
    end do
    write (*, '(a)')      '2) y''''=-y（单摆小角度）降阶成方程组，RK4 同一份代码：'
    write (*, '(a,f10.7,a,f10.7)') '   y(1)=', u(1), '  精确 sin(1)=', exact2(1.0_real64)
    write (*, '(a,es9.2)') '   误差 = ', abs(u(1) - exact2(1.0_real64))
  end block

  ! ---- 3) 稳定性边界：显式欧拉解 y' = λy 要求 |λh| < 2 ----
  ! λ=-2.6：h=0.5 ⇒ |λh|=1.3 收敛；h=0.9 ⇒ |λh|=2.34 每步放大 1.34 倍，
  ! 40 步后 1.34⁴⁰ ≈ 1e5 —— 不是「不准」，是「发散」。
  ! 解析解 y(40h) = e^(λ·40h)，对照打印。
  block
    real(real64), parameter :: lambda = -2.6_real64
    real(real64) :: y_e, h_s
    integer(int32) :: m
    h_s = 0.5_real64
    y_e = 1.0_real64
    do m = 1, 40
      y_e = y_e + h_s * lambda * y_e
    end do
    write (*, '(a)') '3) 显式欧拉的稳定边界（y''=λy, λ=-2.6, 40 步后）：'
    write (*, '(a,es10.3,a,es9.2,a)') '   h=0.5  |λh|=1.30 <2  → y=', y_e, &
         '（解析 ', exp(lambda * 40.0_real64 * h_s), '）一致收敛'
    h_s = 0.9_real64
    y_e = 1.0_real64
    do m = 1, 40
      y_e = y_e + h_s * lambda * y_e
    end do
    write (*, '(a,es10.3,a,es9.2,a)') '   h=0.9  |λh|=2.34 >2  → y=', y_e, &
         '（解析 ', exp(lambda * 40.0_real64 * h_s), '）—— 数值发散'
  end block

  write (*, '(a)') '==== 26 结束 ===='

contains

  ! 方程组右端：u = [y, v]，y'=v、v'=-y
  function sho(x, u) result(dudt)
    real(real64), intent(in) :: x, u(:)
    real(real64) :: dudt(size(u))
    dudt = [u(2), -u(1)]
  end function sho

end program ode_demo
