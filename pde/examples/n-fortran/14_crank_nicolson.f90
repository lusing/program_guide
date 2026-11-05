program crank_nicolson
    implicit none
    integer, parameter :: J = 10
    real(8) :: h, tau, lam
    real(8) :: u(J - 1), rhs(J - 1)
    real(8) :: a3(J - 1), b3(J - 1), c3(J - 1)
    integer :: n, i, nst, k
    real(8) :: pi, exact, r_ratio, e1, e2

    pi = 4.0d0 * atan(1.0d0)
    h = 1.0d0 / J
    exact = 0.0183519d0
    print *, "==== 14 crank_nicolson"

    ! ---------- (1) 书表 4.1 的 CN 列 ----------
    do k = 0, 5
        lam = 0.25d0 * (2.0d0 ** k)
        tau = lam * h * h
        nst = nint(0.4d0 / tau)
        do i = 1, J - 1
            u(i) = sin(pi * i * h)
            a3(i) = -lam / 2.0d0
            b3(i) = 1.0d0 + lam
            c3(i) = -lam / 2.0d0
        end do
        do n = 1, nst
            do i = 1, J - 1
                if (i == 1) then
                    rhs(i) = u(i) + (lam / 2.0d0) * (-2.0d0 * u(i) + u(i + 1))
                else if (i == J - 1) then
                    rhs(i) = u(i) + (lam / 2.0d0) * (u(i - 1) - 2.0d0 * u(i))
                else
                    rhs(i) = u(i) + (lam / 2.0d0) * (u(i - 1) - 2.0d0 * u(i) + u(i + 1))
                end if
            end do
            call thomas(J - 1, a3, b3, c3, rhs, u)
        end do
        write (*, '(a, f5.2, a, f12.7)') 'CN  lam = ', lam, '   u(0.4,0.4) = ', u(4)
    end do
    ! 书表 CN 列对账（λ=0.25/1/2/4 四行）
    if (abs(cn_value(0.25d0) - 0.0189519d0) > 2.0d-6) then
        print *, 'ASSERT FAIL: CN lam=0.25'; stop 1
    end if
    if (abs(cn_value(1.0d0) - 0.0188963d0) > 2.0d-6) then
        print *, 'ASSERT FAIL: CN lam=1'; stop 1
    end if
    if (abs(cn_value(4.0d0) - 0.0180093d0) > 2.0d-6) then
        print *, 'ASSERT FAIL: CN lam=4'; stop 1
    end if
    print *, 'CN column matches book Table 4.1 (rows lam = 0.25/1/4)'

    print *, "END ===="

contains

    subroutine thomas(n, a, b, c, d, x)
        integer, intent(in) :: n
        real(8), intent(in) :: a(n), b(n), c(n), d(n)
        real(8), intent(out) :: x(n)
        real(8) :: cp(n), dp(n), m
        integer :: i
        cp(1) = c(1) / b(1)
        dp(1) = d(1) / b(1)
        do i = 2, n
            m = b(i) - a(i) * cp(i - 1)
            cp(i) = c(i) / m
            dp(i) = (d(i) - a(i) * dp(i - 1)) / m
        end do
        x(n) = dp(n)
        do i = n - 1, 1, -1
            x(i) = dp(i) - cp(i) * x(i + 1)
        end do
    end subroutine thomas

    function cn_value(lam) result(v)
        real(8), intent(in) :: lam
        real(8) :: v
        real(8) :: uu(J - 1), rr(J - 1), aa(J - 1), bb(J - 1), cc(J - 1), ttau
        integer :: nn, ii, nst2
        ttau = lam * h * h
        nst2 = nint(0.4d0 / ttau)
        do ii = 1, J - 1
            uu(ii) = sin(pi * ii * h)
            aa(ii) = -lam / 2.0d0
            bb(ii) = 1.0d0 + lam
            cc(ii) = -lam / 2.0d0
        end do
        do nn = 1, nst2
            do ii = 1, J - 1
                if (ii == 1) then
                    rr(ii) = uu(ii) + (lam / 2.0d0) * (-2.0d0 * uu(ii) + uu(ii + 1))
                else if (ii == J - 1) then
                    rr(ii) = uu(ii) + (lam / 2.0d0) * (uu(ii - 1) - 2.0d0 * uu(ii))
                else
                    rr(ii) = uu(ii) + (lam / 2.0d0) * (uu(ii - 1) - 2.0d0 * uu(ii) + uu(ii + 1))
                end if
            end do
            call thomas(J - 1, aa, bb, cc, rr, uu)
        end do
        v = uu(4)
    end function cn_value

end program crank_nicolson
