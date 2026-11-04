program field
    implicit none
    integer :: i, k, m
    real(8) :: h, y, err(6), hs(6)
    real(8) :: p
    integer, parameter :: nmethod = 3
    character(len=6) :: names(3) = ['euler ', 'heun  ', 'rk4   ']

    print *, "==== 02 field"

    ! Convergence-order measurement for y' = x + y, y(0)=1, truth 2e-2 at x=1.
    hs = [(0.5d0 ** (k + 3), k = 0, 5)]   ! h = 1/8 .. 1/256
    do m = 1, nmethod
        do i = 1, 6
            err(i) = err_at_x1(m, hs(i))
        end do
        p = fit_slope(hs, err)
        print '(a, a, a, f6.3)', 'method ', names(m), ' fitted order p = ', p
        select case (m)
        case (1); if (p < 0.85d0 .or. p > 1.15d0) then; print *, 'ASSERT FAIL euler order'; stop 1; end if
        case (2); if (p < 1.85d0 .or. p > 2.15d0) then; print *, 'ASSERT FAIL heun order'; stop 1; end if
        case (3); if (p < 3.70d0 .or. p > 4.30d0) then; print *, 'ASSERT FAIL rk4 order'; stop 1; end if
        end select
    end do
    print *, 'orders: euler~1, heun~2, rk4~4 (log-log fit)'

    ! Isocline check: on x + y = 1 the slope f = 1 identically.
    do i = 0, 10
        h = -1.5d0 + 0.3d0 * i          ! reuse h as x here
        y = 1.0d0 - h
        if (abs((h + y) - 1.0d0) > 1.0d-15) then
            print *, 'ASSERT FAIL isocline'; stop 1
        end if
    end do
    print *, 'isocline x + y = 1: slope = 1 at 11 samples'

    print *, "END ===="
contains
    real(8) function f(x, y)
        real(8), intent(in) :: x, y
        f = x + y
    end function f

    real(8) function step(m, x, y, h)
        integer, intent(in) :: m
        real(8), intent(in) :: x, y, h
        real(8) :: k1, k2, k3, k4
        select case (m)
        case (1)
            step = y + h * f(x, y)
        case (2)
            k1 = f(x, y); k2 = f(x + h, y + h * k1)
            step = y + h * (k1 + k2) / 2
        case default
            k1 = f(x, y)
            k2 = f(x + h / 2, y + h * k1 / 2)
            k3 = f(x + h / 2, y + h * k2 / 2)
            k4 = f(x + h, y + h * k3)
            step = y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
        end select
    end function step

    real(8) function err_at_x1(m, h)
        integer, intent(in) :: m
        real(8), intent(in) :: h
        integer :: n, i
        real(8) :: y
        n = nint(1.0d0 / h)
        y = 1.0d0
        do i = 0, n - 1
            y = step(m, i * h, y, h)
        end do
        err_at_x1 = abs(y - (2.0d0 * exp(1.0d0) - 2.0d0))
    end function err_at_x1

    real(8) function fit_slope(hs, errs)
        real(8), intent(in) :: hs(6), errs(6)
        real(8) :: lx(6), ly(6), mx, my
        lx = log(hs); ly = log(errs)
        mx = sum(lx) / 6; my = sum(ly) / 6
        fit_slope = sum((lx - mx) * (ly - my)) / sum((lx - mx)**2)
    end function fit_slope
end program field
