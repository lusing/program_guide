program existence
    implicit none
    integer, parameter :: n = 1000
    real(8), parameter :: h = 1.0d0 / n
    real(8) :: y(0:n), ynew(0:n)
    real(8) :: truth1, err
    integer :: i, k, round

    print *, "==== 01 existence"

    ! Picard iteration for y' = x + y, y(0) = 1:
    !   y_{k+1}(x) = 1 + int_0^x (t + y_k(t)) dt
    ! composite trapezoid on a fixed grid; y_0 = 1
    y = 1.0d0
    truth1 = 2.0d0 * exp(1.0d0) - 2.0d0
    do round = 1, 6
        ynew(0) = 1.0d0
        do i = 1, n
            ! trapezoid of (t + y) over [0, i*h]
            ynew(i) = 1.0d0 + trap(i)
        end do
        y = ynew
        err = abs(y(n) - truth1)
        print '(a, i2, a, es14.6)', 'round ', round, '  |y(1) - truth| = ', err
    end do
    if (err >= 5.0d-4) then
        print *, 'ASSERT FAIL: round-6 error should be < 5e-4'
        stop 1
    end if
    print *, 'Picard round 6 error < 5e-4 (contraction ~1/6 per round)'

    ! Blow-up check: y = 1/(2-x) at x = 1.999 exceeds 500
    if (1.0d0 / (2.0d0 - 1.999d0) <= 500.0d0) then
        print *, 'ASSERT FAIL: blow-up solution should diverge'
        stop 1
    end if
    print *, 'y = 1/(2-x): y(1.999) = ', 1.0d0 / (2.0d0 - 1.999d0), ' (blow-up)'

    print *, "END ===="
contains
    ! trapezoid of f(t) = t + y(t) on [0, i*h] using the shared grid
    function trap(i) result(s)
        integer, intent(in) :: i
        real(8) :: s
        integer :: j
        s = 0.0d0
        s = 0.5d0 * (fgrid(0) + fgrid(i))
        do j = 1, i - 1
            s = s + fgrid(j)
        end do
        s = s * h
    end function trap
    function fgrid(j) result(v)
        integer, intent(in) :: j
        real(8) :: v
        v = j * h + y(j)
    end function fgrid
end program existence
