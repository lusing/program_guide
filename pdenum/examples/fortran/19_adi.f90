program adi2d
    implicit none
    integer, parameter :: N = 40
    real(8) :: h, tau, r
    real(8) :: u(N, N), half(N, N)
    real(8) :: a(N), b(N), c(N), d(N)
    integer :: nstep, i, j, nst
    real(8) :: pi, tf, err, exact
    real(8) :: urow(N)

    pi = 4.0d0 * atan(1.0d0)
    h = 1.0d0 / (N + 1)
    r = 5.0d0
    tau = r * h * h
    nst = nint(0.1d0 / tau)
    print *, "==== 19 adi"

    do i = 1, N
        do j = 1, N
            u(i, j) = sin(pi * i * h) * sin(pi * j * h)
        end do
    end do
    do i = 1, N
        a(i) = -r / 2.0d0
        b(i) = 1.0d0 + r
        c(i) = -r / 2.0d0
    end do
    a(1) = 0.0d0
    c(N) = 0.0d0

    do nstep = 1, nst
        ! 半步 1：x 隐
        do j = 1, N
            do i = 1, N
                d(i) = (1.0d0 - r) * u(i, j)
                if (i > 1) d(i) = d(i) + (r / 2.0d0) * u(i - 1, j)
                if (i < N) d(i) = d(i) + (r / 2.0d0) * u(i + 1, j)
            end do
            call thomas(N, a, b, c, d, half(1, j))
        end do
        ! 半步 2：y 隐
        do i = 1, N
            do j = 1, N
                d(j) = (1.0d0 - r) * half(i, j)
                if (j > 1) d(j) = d(j) + (r / 2.0d0) * half(i, j - 1)
                if (j < N) d(j) = d(j) + (r / 2.0d0) * half(i, j + 1)
            end do
            call thomas(N, a, b, c, d, urow)
            u(i, 1:N) = urow(1:N)
        end do
    end do

    tf = nst * tau
    err = 0.0d0
    do i = 1, N
        do j = 1, N
            exact = exp(-2.0d0 * pi * pi * tf) * sin(pi * i * h) * sin(pi * j * h)
            err = max(err, abs(u(i, j) - exact))
        end do
    end do
    if (err > 5.0d-2) then
        print *, 'ASSERT FAIL: ADI r=5 should be stable'; stop 1
    end if
    print '(a, f4.1, a, e12.4)', 'PR-ADI r = ', r, ': stable, err = ', err

    print *, "END ===="

contains

    subroutine thomas(n2, aa, bb, cc, dd, x)
        integer, intent(in) :: n2
        real(8), intent(in) :: aa(n2), bb(n2), cc(n2), dd(n2)
        real(8), intent(out) :: x(n2)
        real(8) :: cp(n2), dp(n2), m
        integer :: k
        cp(1) = cc(1) / bb(1)
        dp(1) = dd(1) / bb(1)
        do k = 2, n2
            m = bb(k) - aa(k) * cp(k - 1)
            cp(k) = cc(k) / m
            dp(k) = (dd(k) - aa(k) * dp(k - 1)) / m
        end do
        x(n2) = dp(n2)
        do k = n2 - 1, 1, -1
            x(k) = dp(k) - cp(k) * x(k + 1)
        end do
    end subroutine thomas

end program adi2d

