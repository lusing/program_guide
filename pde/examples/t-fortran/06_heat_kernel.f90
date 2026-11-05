! Ch06 热方程 I：热核卷积演化（Fortran 经典内核）
!
! 对应书 §2.3.1：初值问题的卷积解 u = Φ(·,t)*g。
! g = 指示函数 {|y|<1}：闭式解 u(x,t) = ½[erf((x+1)/(2√t)) −
! erf((x−1)/(2√t))]。三组断言：中心值闭式、质量守恒、峰值 t^{-1/2}
! 衰减律。跳点分段积分：每段 g 取常值（端点无歧义）。

program heat_kernel
   implicit none
   double precision :: num, ex, ratio, m
   double precision, parameter :: pi = 3.141592653589793238462643383279d0
   double precision :: t
   integer :: k

   write (*, '(A)') '==== 06'

   ! (a) 中心值闭式：u(0,t) = erf(1/(2√t))
   do k = 1, 3
      t = 0.25d0*k
      num = conv(0.0d0, t)
      ex = erf(1.0d0/(2.0d0*sqrt(t)))
      write (*, '(A,F6.3,A,F12.9,A,ES10.2)') ' t=', t, '  u(0,t)=', num, &
         '  diff=', abs(num - ex)
      if (abs(num - ex) > 1d-9) call abort1()
   end do

   ! (b) 质量守恒：∫u(·,t) dx = ∫g = 2 对所有 t
   do k = 1, 3
      t = 0.5d0*k
      m = massof(t)
      write (*, '(A,F6.3,A,F12.9,A,ES10.2)') ' t=', t, '  mass=', m, &
         '  |2-m|=', abs(2.0d0 - m)
      if (abs(m - 2.0d0) > 1d-6) call abort1()
   end do

   ! (c) 核峰值衰减律 t^{-1/2}：Φ(0,4)/Φ(0,1) = 1/2（核，不是卷积解！
   ! 卷积解中心 u(0,t) = erf(1/(2√t))，大 t 渐近 u·√(πt) → 1）
   ratio = phi(0.0d0, 4.0d0)/phi(0.0d0, 1.0d0)
   write (*, '(A,F10.7,A)') ' kernel peak ratio Phi(0,4)/Phi(0,1) = ', ratio, ' (expect 0.5)'
   if (abs(ratio - 0.5d0) > 1d-12) call abort1()
   num = conv(0.0d0, 64.0d0)*sqrt(64.0d0*pi)
   write (*, '(A,F10.7,A)') ' asymptotic u(0,64)*sqrt(64 pi) = ', num, ' (->1)'
   if (abs(num - 1.0d0) > 0.01d0) call abort1()

   write (*, '(A)') 'END ===='
   stop

contains

   real(8) function phi(x, t)
      double precision, intent(in) :: x, t
      phi = (4.0d0*pi*t)**(-0.5d0)*exp(-x*x/(4.0d0*t))
   end function phi

   ! 段积分：[a,b] 上 g 取常值 gval（跳点为段端点，无歧义）
   real(8) function seg(x, t, a, b, gval)
      double precision, intent(in) :: x, t, a, b, gval
      integer, parameter :: M = 2000
      integer :: i
      double precision :: h, y, w, s
      h = (b - a)/M
      s = 0.0d0
      do i = 0, M
         y = a + i*h
         if (i == 0 .or. i == M) then
            w = 1.0d0
         else if (mod(i, 2) == 0) then
            w = 2.0d0
         else
            w = 4.0d0
         end if
         s = s + w*phi(x - y, t)*gval
      end do
      seg = s*h/3.0d0
   end function seg

   real(8) function conv(x, t)
      double precision, intent(in) :: x, t
      double precision, parameter :: L = 12.0d0
      ! g = 1 于 (-1,1)、0 于外；三段常值
      conv = seg(x, t, -L, -1.0d0, 0.0d0) + seg(x, t, -1.0d0, 1.0d0, 1.0d0) &
             + seg(x, t, 1.0d0, L, 0.0d0)
   end function conv

   real(8) function massof(t)
      double precision, intent(in) :: t
      integer, parameter :: M = 3000
      integer :: i
      double precision :: h, y, w, s
      ! 截断 [-10,10]：t=1 时解宽 ~√2，尾部 ~e^{-25}（[-7,7] 会留 6.7e-6）
      h = 20.0d0/M
      s = 0.0d0
      do i = 0, M
         y = -10.0d0 + i*h
         if (i == 0 .or. i == M) then
            w = 1.0d0
         else if (mod(i, 2) == 0) then
            w = 2.0d0
         else
            w = 4.0d0
         end if
         s = s + w*conv(y, t)
      end do
      massof = s*h/3.0d0
   end function massof

end program heat_kernel

subroutine abort1()
   write (*, '(A)') 'ASSERTION FAILED'
   stop 1
end subroutine abort1
