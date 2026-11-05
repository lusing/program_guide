! Ch09 波方程 I：能量近似守恒与 O(dt²) 漂移律（Fortran 经典内核）
!
! 对应书 §2.4.3（能量方法：E(t) = ½∫(u_t² + u_x²) dx 守恒）。
! 蛙跳（leapfrog）+ 周期边界。朴素离散能量（速度取 u^n/u^{n-1} 层差）
! 不严格守恒——漂移 O(dt²)（速度在半层、梯度在整层的时点错配；
! 严格的辛不变量要交错梯度）。数值实验的双重断言：
!   ①漂移 < 5e-3（近似守恒）；②CFL 减半 ⟹ 漂移缩 4 倍（O(dt²) 签名）。

program wave_energy
   implicit none
   integer, parameter :: N = 256
   integer :: istep, k
   double precision :: h, drift1, drift2, ratio
   double precision, parameter :: pi = 3.141592653589793238462643383279d0
   double precision :: u(0:N-1), up(0:N-1), um(0:N-1)

   write (*, '(A)') '==== 09'

   h = 1.0d0/N
   call run(0.4d0, drift1)
   call run(0.2d0, drift2)
   ratio = drift1/drift2
   write (*, '(A,ES10.2,A,ES10.2,A,F6.2,A)') ' drift(cfl=.4)=', drift1, &
      '  drift(cfl=.2)=', drift2, '  ratio=', ratio, ' (halving law: O(dt^2) oscillation + secular)'
   if (drift1 > 5.0d-3) call abort1()
   if (abs(ratio - 2.0d0) > 0.5d0) call abort1()

   write (*, '(A)') 'END ===='
   stop

contains

   subroutine run(cfl, drift)
      double precision, intent(in) :: cfl
      double precision, intent(out) :: drift
      double precision :: dt, E0, E
      integer :: nsteps
      dt = cfl*h
      nsteps = nint(3.125d0/dt)     ! 固定终点时间：漂移律才干净（dt² 相同时间）
      do k = 0, N - 1
         u(k) = sin(2.0d0*pi*k*h)
      end do
      um = u                       ! 起步层（u_t(0) = 0 ⟹ 对称起步精确）
      call energy(u, um, dt, E0)
      do istep = 1, nsteps
         do k = 0, N - 1
            up(k) = 2.0d0*u(k) - um(k) + (dt*dt/h/h)*(u(mod(k + 1, N)) - 2.0d0*u(k) + u(mod(k + N - 1, N)))
         end do
         um = u
         u = up
      end do
      call energy(u, um, dt, E)
      drift = abs(E - E0)/E0
   end subroutine run

   subroutine energy(u, um, dt, E)
      double precision, intent(in) :: u(0:N-1), um(0:N-1), dt
      double precision, intent(out) :: E
      double precision :: vt, gx
      E = 0.0d0
      do k = 0, N - 1
         vt = (u(k) - um(k))/dt
         gx = (u(mod(k + 1, N)) - u(k))/h
         E = E + 0.5d0*vt*vt + 0.5d0*gx*gx
      end do
      E = E*h
   end subroutine energy

end program wave_energy

subroutine abort1()
   write (*, '(A)') 'ASSERTION FAILED'
   stop 1
end subroutine abort1

