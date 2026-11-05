program five_point
    implicit none
    integer, parameter :: N = 40
    real(8) :: h, pi, omega, diffn
    real(8) :: u(0:N, 0:N), gs, newv
    integer :: i, j, it
    real(8) :: err, exact, tf

    pi = 4.0d0 * atan(1.0d0)
    h = 1.0d0 / N
    print *, "==== 21 five point"

    ! Poisson：u = x^2 - y^2 + sin(pi x) sin(pi y)，f = -2 pi^2 sin sin
    do i = 0, N
        u(i, 0) = g(i * h, 0.0d0)
        u(i, N) = g(i * h, 1.0d0)
        u(0, i) = g(0.0d0, i * h)
        u(N, i) = g(1.0d0, i * h)
    end do
    omega = 2.0d0 / (1.0d0 + sin(pi / N))
    do it = 1, 200000
        diffn = 0.0d0
        do j = 1, N - 1
            do i = 1, N - 1
                gs = 0.25d0 * (u(i + 1, j) + u(i - 1, j) + u(i, j + 1) + u(i, j - 1) &
                               - h * h * f(i * h, j * h))
                newv = u(i, j) + omega * (gs - u(i, j))
                diffn = max(diffn, abs(newv - u(i, j)))
                u(i, j) = newv
            end do
        end do
        if (diffn < 1.0d-11) exit
    end do

    err = 0.0d0
    do i = 1, N - 1
        do j = 1, N - 1
            err = max(err, abs(u(i, j) - g(i * h, j * h)))
        end do
    end do
    if (err > 5.0d-3) then
        print *, 'ASSERT FAIL: five-point error too large'; stop 1
    end if
    print '(a, i6, a, e12.4)', 'SOR converged in ', it, ' iters, err = ', err

    print *, "END ===="

contains

    function f(x, y) result(v)
        real(8), intent(in) :: x, y
        real(8) :: v
        v = -2.0d0 * pi * pi * sin(pi * x) * sin(pi * y)
    end function f

    function g(x, y) result(v)
        real(8), intent(in) :: x, y
        real(8) :: v
        v = x * x - y * y + sin(pi * x) * sin(pi * y)
    end function g

end program five_point
