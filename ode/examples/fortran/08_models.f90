program models
    implicit none
    integer :: i, n
    real(8) :: h, y, total, err

    print *, "==== 08 models"

    ! --- (a) Friction (book ex 2.32): v' = -(k/m)v, total distance v0*m/k ---
    n = 300000
    h = 30.0d0 / n
    total = 0.0d0
    do i = 1, n
        total = total + v(i * h) * h
    end do
    ! right sum (i=1..n) -> trapezoid: add half of (f0 - fn)
    total = total + 0.5d0 * (v(0.0d0) - v(30.0d0)) * h
    err = abs(total - 4.0d0 * 2.0d0 / 3.0d0)
    if (err >= 1.0d-4) then
        print *, 'ASSERT FAIL friction total distance'; stop 1
    end if
    print '(a, f10.6, a, f10.6)', 'friction: total distance ', total, ' vs v0*m/k ', 8.0d0/3.0d0

    ! --- (b) Cooling (book ex 2.34): excess decays e^{-kt} ---
    if (abs(excess(3.0d0) / 70.0d0 - exp(-3.0d0)) > 1.0d-12) then
        print *, 'ASSERT FAIL cooling'; stop 1
    end if
    print *, 'cooling: T(3 tau) excess = e^{-3} of initial'

    ! --- (c) Half-life (book ex 2.35): lambda = ln2/30 ---
    if (abs(exp(-log(2.0d0) / 30.0d0 * 30.0d0) - 0.5d0) > 1.0d-12) then
        print *, 'ASSERT FAIL half-life'; stop 1
    end if
    print *, 'decay: lambda = ln2/30, N(30) = N0/2'

    ! --- (d) Brine tank (book ex 2.36): V' = -6V/(150-2t), V(0)=6 ---
    ! RK4 to t=60, analytic V = 6(150-2t)^3/150^3 = 0.048
    y = 6.0d0
    n = 60000
    h = 60.0d0 / n
    do i = 0, n - 1
        y = rk4_brine(i * h, y, h)
    end do
    if (abs(y - 0.048d0) > 1.0d-10) then
        print *, 'ASSERT FAIL brine'; stop 1
    end if
    print '(a, f12.8, a)', 'brine: V(60) = ', y, ' (analytic 0.048)'

    ! --- (e) RL circuit (book ex 2.41): i = (E/R)(1 - e^{-t/tau}) ---
    if (abs(rl_i(0.5d0) - 3.0d0 * (1.0d0 - exp(-1.0d0))) > 1.0d-12) then
        print *, 'ASSERT FAIL RL'; stop 1
    end if
    print *, 'RL: E/R = 3 A, tau = L/R = 0.5 s, i(tau) = 63.2%'

    print *, "END ===="
contains
    real(8) function v(t)
        real(8), intent(in) :: t
        v = 4.0d0 * exp(-1.5d0 * t)     ! v0 exp(-(k/m)t), k/m = 3/2
    end function v
    real(8) function excess(t)
        real(8), intent(in) :: t
        excess = 70.0d0 * exp(-1.0d0 * t)   ! k = 1, tau = 1, 3 tau = t=3
    end function excess
    real(8) function rk4_brine(t, y, h)
        real(8), intent(in) :: t, y, h
        real(8) :: k1, k2, k3, k4
        k1 = fbrine(t, y)
        k2 = fbrine(t + h / 2, y + h * k1 / 2)
        k3 = fbrine(t + h / 2, y + h * k2 / 2)
        k4 = fbrine(t + h, y + h * k3)
        rk4_brine = y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    end function rk4_brine
    real(8) function fbrine(t, vv)
        real(8), intent(in) :: t, vv
        fbrine = -6.0d0 * vv / (150.0d0 - 2.0d0 * t)
    end function fbrine
    real(8) function rl_i(t)
        real(8), intent(in) :: t
        rl_i = 3.0d0 * (1.0d0 - exp(-t / 0.5d0))
    end function rl_i
end program models
