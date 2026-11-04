program mathieu
    implicit none
    integer :: i, n
    real(8) :: h, y1, v1, y2, v2, tr, eps
    real(8) :: Tmat(2, 2)

    print *, "==== 12 mathieu"

    ! Numerical monodromy for the Meissner equation:
    !   u'' + (w^2 + eps*s(x))u = 0, s = +1 first half-period, -1 second.
    ! RK4 on the two fundamental solutions (initial (1,0) and (0,1)).
    eps = 0.8d0
    call monodromy(1.0d0, eps, Tmat)
    tr = Tmat(1, 1) + Tmat(2, 2)
    print '(a, f10.6)', 'Meissner(w=1, eps=0.8): tr T = ', tr
    if (abs(tr) <= 2.0d0) then
        print *, 'ASSERT FAIL: expected unstable (|tr|>2)'; stop 1
    end if
    print *, '=> unstable: parametric resonance inside first band'
    if (abs(Tmat(1, 1) * Tmat(2, 2) - Tmat(1, 2) * Tmat(2, 1) - 1.0d0) > 1.0d-9) then
        print *, 'ASSERT FAIL: det T should be 1 (Abel)'; stop 1
    end if
    print *, 'det T = 1 (Abel identity)'

    ! Sweep eps in [0, 3] at w = 1: report stability flips (band boundaries)
    print *, 'stability boundary scan (w=1):'
    n = 0
    do i = 0, 300
        eps = i * 0.01d0
        call monodromy(1.0d0, eps, Tmat)
        tr = abs(Tmat(1, 1) + Tmat(2, 2))
        if (tr > 2.0d0 + 1.0d-9 .and. n == 0) then
            print '(a, f6.2)', '  first unstable region starts near eps = ', eps
            n = 1
        end if
    end do
    if (n == 0) then
        print *, 'ASSERT FAIL: expected an unstable region'; stop 1
    end if
    print *, 'scan complete'

    ! Stable point deep inside a window (a = -0.3 analogue for Meissner
    ! is parameter-dependent; we just verify the known stable combo w=2.3)
    call monodromy(2.3d0, 0.5d0, Tmat)
    tr = abs(Tmat(1, 1) + Tmat(2, 2))
    if (tr >= 2.0d0) then
        print *, 'ASSERT FAIL: w=2.3, eps=0.5 expected stable'; stop 1
    end if
    print '(a, f8.4)', 'Meissner(w=2.3, eps=0.5): |tr T| = ', tr, ' < 2 stable'

    print *, "END ===="
contains
    subroutine monodromy(w, eps, T)
        real(8), intent(in) :: w, eps
        real(8), intent(out) :: T(2, 2)
        real(8) :: L, h, x, y1, v1, y2, v2, c1, c2
        integer :: i, nhalf
        L = 2.0d0 * acos(-1.0d0)
        nhalf = 12000
        h = L / (2 * nhalf)
        y1 = 1.0d0; v1 = 0.0d0
        y2 = 0.0d0; v2 = 1.0d0
        c1 = -(w * w + eps)      ! first half: s = +1
        c2 = -(w * w - eps)      ! second half: s = -1
        x = 0.0d0
        do i = 1, nhalf
            call rk4step(c1, y1, v1, h)
            call rk4step(c1, y2, v2, h)
            x = x + h
        end do
        do i = 1, nhalf
            call rk4step(c2, y1, v1, h)
            call rk4step(c2, y2, v2, h)
            x = x + h
        end do
        T(1, 1) = y1; T(1, 2) = y2
        T(2, 1) = v1; T(2, 2) = v2
    end subroutine monodromy
    subroutine rk4step(c, y, v, h)
        real(8), intent(in) :: c, h
        real(8), intent(inout) :: y, v
        real(8) :: k1y, k1v, k2y, k2v, k3y, k3v, k4y, k4v
        k1y = v;          k1v = c * y
        k2y = v + h*k1v/2; k2v = c * (y + h*k1y/2)
        k3y = v + h*k2v/2; k3v = c * (y + h*k2y/2)
        k4y = v + h*k3v;   k4v = c * (y + h*k3y)
        y = y + h*(k1y + 2*k2y + 2*k3y + k4y)/6
        v = v + h*(k1v + 2*k2v + 2*k3v + k4v)/6
    end subroutine rk4step
end program mathieu
