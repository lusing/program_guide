program lax_wendroff
    implicit none
    integer, parameter :: J = 400
    real(8) :: h, lam, tau, T
    real(8) :: u(0:J), un(0:J)
    integer :: n, i, nst
    real(8) :: err1, err2, ratio

    print *, "==== 07 lax_wendroff"

    ! ---------- (1) 方波推进：LW 的振荡（对照 LF 的单调） ----------
    h = 1.0d0 / J
    lam = 0.8d0
    tau = lam * h
    T = 0.5d0
    nst = nint(T / tau)
    do i = 0, J
        u(i) = gwave(i * h)
    end do
    do n = 1, nst
        do i = 1, J - 1
            un(i) = u(i) - 0.5d0 * lam * (u(i + 1) - u(i - 1)) &
                    + 0.5d0 * lam * lam * (u(i + 1) - 2.0d0 * u(i) + u(i - 1))
        end do
        ! 周期边界
        un(0) = u(0) - 0.5d0 * lam * (u(1) - u(J - 1)) &
                + 0.5d0 * lam * lam * (u(1) - 2.0d0 * u(0) + u(J - 1))
        un(J) = un(0)
        u(0:J) = un(0:J)
    end do
    if (minval(u) > -0.05d0) then
        print *, 'ASSERT FAIL: LW should oscillate near discontinuity'; stop 1
    end if
    print '(a, f8.4)', 'LW on square pulse: min value = ', minval(u), ' (oscillation)'

    ! ---------- (2) 光滑波二阶收敛 ----------
    err1 = lw_err(2.0d0 * h)
    err2 = lw_err(h)
    ratio = err1 / err2
    if (ratio < 3.5d0 .or. ratio > 4.5d0) then
        print *, 'ASSERT FAIL: LW should be 2nd order, ratio = ', ratio; stop 1
    end if
    print '(a, f6.3)', 'LW smooth-wave convergence: h->h/2 error ratio = ', ratio

    print *, "END ===="

contains

    function gwave(x) result(v)
        real(8), intent(in) :: x
        real(8) :: v
        if (x > 0.3d0 .and. x < 0.6d0) then
            v = 1.0d0
        else
            v = 0.0d0
        end if
    end function gwave

    function gsin(x) result(v)
        real(8), intent(in) :: x
        real(8) :: v
        v = sin(2.0d0 * 4.0d0 * atan(1.0d0) * x)
    end function gsin

    function lw_err(hh) result(err)
        ! 对流方程 a=1，初值 sin(2*pi*4x)，T=0.5：与精确平移解比 L1 误差
        real(8), intent(in) :: hh
        real(8) :: err
        integer :: JJ, nn, kk, ii, nsteps
        real(8), allocatable :: uu(:), uun(:)
        real(8) :: tt, lam2, tau2, ex, s
        JJ = nint(1.0d0 / hh)
        allocate (uu(0:JJ), uun(0:JJ))
        lam2 = 0.8d0
        tau2 = lam2 * hh
        nsteps = nint(0.5d0 / tau2)
        do ii = 0, JJ
            uu(ii) = gsin(ii * hh)
        end do
        do nn = 1, nsteps
            do ii = 1, JJ - 1
                uun(ii) = uu(ii) - 0.5d0 * lam2 * (uu(ii + 1) - uu(ii - 1)) &
                          + 0.5d0 * lam2 * lam2 * (uu(ii + 1) - 2.0d0 * uu(ii) + uu(ii - 1))
            end do
            uun(0) = uu(0) - 0.5d0 * lam2 * (uu(1) - uu(JJ - 1)) &
                     + 0.5d0 * lam2 * lam2 * (uu(1) - 2.0d0 * uu(0) + uu(JJ - 1))
            uun(JJ) = uun(0)
            uu(0:JJ) = uun(0:JJ)
        end do
        s = 0.0d0
        do ii = 0, JJ - 1
            ex = gsin(mod(ii * hh - 0.5d0 + 10.0d0, 1.0d0))
            s = s + abs(uu(ii) - ex)
        end do
        err = s / JJ
        deallocate (uu, uun)
    end function lw_err

end program lax_wendroff
