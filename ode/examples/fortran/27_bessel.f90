program bessel
    implicit none
    integer :: k, i
    real(8) :: x, s, term
    real(8) :: a, b, m

    print *, "==== 27 bessel"

    ! J0 via series (scaled term recurrence, 30 terms) vs flang builtin
    do k = 0, 4
        x = 0.5d0 + k * 1.5d0
        s = 1.0d0
        term = 1.0d0
        do i = 1, 30
            term = term * (-(x / 2.0d0)**2) / (real(i, 8) * real(i, 8))
            s = s + term
        end do
        if (abs(s - bessel_j0(x)) > 1.0d-10) then
            print *, 'ASSERT FAIL at x =', x; stop 1
        end if
    end do
    print *, 'J0 series (30 terms) matches builtin bessel_j0 at 5 points'

    if (abs(bessel_j0(1.0d0) - 0.7651976865579666d0) > 1.0d-12) then; stop 1; end if
    if (abs(bessel_j0(5.0d0) + 0.1775967713143383d0) > 1.0d-12) then; stop 1; end if
    print *, 'builtin J0(1) = 0.76520, J0(5) = -0.17760 (literature)'

    ! first zero of J0 by bisection
    a = 1.0d0; b = 3.0d0
    do i = 1, 200
        m = (a + b) / 2
        if (bessel_j0(a) * bessel_j0(m) <= 0) then
            b = m
        else
            a = m
        end if
    end do
    m = (a + b) / 2
    if (abs(m - 2.4048255577d0) > 1.0d-6) then; stop 1; end if
    print '(a, f10.6)', 'first zero of J0 = ', m

    ! second zero and gap -> pi trend
    a = 4.0d0; b = 6.0d0
    do i = 1, 200
        m = (a + b) / 2
        if (bessel_j0(a) * bessel_j0(m) <= 0) then
            b = m
        else
            a = m
        end if
    end do
    print '(a, f10.6)', 'second zero of J0 = ', (a + b) / 2

    print *, "END ===="
end program bessel
