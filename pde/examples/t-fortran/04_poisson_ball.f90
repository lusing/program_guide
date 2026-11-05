! Ch04 Laplace 方程 II：球的 Poisson 核积分（Fortran 经典内核）
!
! 对应书 §2.2.4 末（Poisson 核与球内解的表示）：
!   u(x) = ∮_{|y|=1} (1-|x|^2)/(2π|x-y|^2) g(y) dS(y)
! g = cos(2θ) 的解析解是 r^2 cos2θ = x^2 - y^2。
! 圆周梯形（8192 点）积分，三点重构对账到机器精度级。

program poisson_ball
   implicit none
   integer, parameter :: N = 8192
   integer :: k
   double precision :: x(2), num, exact, th, y1, y2, P
   double precision, parameter :: pi = 3.141592653589793238462643383279d0
   double precision, external :: g

   write (*, '(A)') '==== 04'

   call solve(0.2d0, 0.1d0, num)
   exact = 0.2d0**2 - 0.1d0**2
   write (*, '(A,2F10.5,A,ES10.2)') ' poisson ball at (0.2,0.1): ', num, exact, '  diff=', abs(num - exact)
   if (abs(num - exact) > 1d-10) call abort1()

   call solve(0.5d0, -0.3d0, num)
   exact = 0.5d0**2 - 0.3d0**2
   write (*, '(A,2F10.5,A,ES10.2)') ' poisson ball at (0.5,-0.3): ', num, exact, '  diff=', abs(num - exact)
   if (abs(num - exact) > 1d-10) call abort1()

   call solve(0.0d0, 0.7d0, num)
   exact = -0.7d0**2
   write (*, '(A,2F10.5,A,ES10.2)') ' poisson ball at (0.0,0.7): ', num, exact, '  diff=', abs(num - exact)
   if (abs(num - exact) > 1d-10) call abort1()

   write (*, '(A)') 'END ===='
   stop

contains

   subroutine solve(x1, x2, u)
      double precision, intent(in) :: x1, x2
      double precision, intent(out) :: u
      integer :: kk
      double precision :: thk, yy1, yy2, pk
      u = 0.0d0
      do kk = 0, N - 1
         thk = 2.0d0*pi*kk/N
         yy1 = cos(thk)
         yy2 = sin(thk)
         pk = (1.0d0 - (x1**2 + x2**2))/(2.0d0*pi*((x1 - yy1)**2 + (x2 - yy2)**2))
         u = u + pk*g(thk)*(2.0d0*pi/N)
      end do
   end subroutine solve

end program poisson_ball

double precision function g(th)
   double precision, intent(in) :: th
   g = cos(2.0d0*th)
end function g

subroutine abort1()
   write (*, '(A)') 'ASSERTION FAILED'
   stop 1
end subroutine abort1
