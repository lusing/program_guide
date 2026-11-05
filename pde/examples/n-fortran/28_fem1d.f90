program fem1d
    implicit none
    integer, parameter :: N = 40
    real(8) :: h
    real(8) :: K(0:N, 0:N), F(0:N), Kred(N, N), Fred(N)
    real(8) :: ke(2, 2), fe(2), xe, xf
    real(8) :: u(0:N), c(N)
    real(8) :: pi, maxerr, uex
    integer :: e, a, b, i

    pi = 4.0d0 * atan(1.0d0)
    h = 1.0d0 / N
    print *, "==== 28 fem1d"

    K = 0.0d0
    F = 0.0d0
    do e = 1, N
        xe = (e - 1) * h
        xf = e * h
        ke(1, 1) = 1.0d0 / h + 2.0d0 * h / 6.0d0
        ke(1, 2) = -1.0d0 / h + h / 6.0d0
        ke(2, 1) = ke(1, 2)
        ke(2, 2) = ke(1, 1)
        fe(1) = h / 6.0d0 * (2.0d0 * fg(xe) + fg(xf))
        fe(2) = h / 6.0d0 * (fg(xe) + 2.0d0 * fg(xf))
        do a = 1, 2
            do b = 1, 2
                K(e - 2 + a, e - 2 + b) = K(e - 2 + a, e - 2 + b) + ke(a, b)   ! 坑账：0 基数组局部-整体映射是 e-2+a（Julia 1 基是 e-1+a）
            end do
            F(e - 2 + a) = F(e - 2 + a) + fe(a)
        end do
    end do
    ! Robin：u'(1) + 2u(1) = -pi
    K(N, N) = K(N, N) + 2.0d0
    F(N) = F(N) - pi
    ! Dirichlet u(0)=0：删行列
    Kred = K(1:N, 1:N)
    Fred = F(1:N)
    call thomas(N, Kred, Fred, c)
    u(0) = 0.0d0
    u(1:N) = c

    maxerr = 0.0d0
    do i = 0, N
        maxerr = max(maxerr, abs(u(i) - sin(pi * i * h)))
    end do
    if (maxerr > 1.0d-3) then
        print *, 'ASSERT FAIL: FEM nodal error too large'; stop 1
    end if
    print '(a, e12.4)', 'FEM (N=40) nodal err vs sin(pi x) = ', maxerr

    print *, "END ===="

contains

    function fg(x) result(v)
        real(8), intent(in) :: x
        real(8) :: v
        v = (pi * pi + 1.0d0) * sin(pi * x)
    end function fg

    subroutine thomas(n2, A, d, x)
        integer, intent(in) :: n2
        real(8), intent(in) :: A(n2, n2), d(n2)
        real(8), intent(out) :: x(n2)
        real(8) :: aa(n2), bb(n2), cc(n2), cp(n2), dp(n2), m
        integer :: k
        do k = 1, n2
            bb(k) = A(k, k)
            if (k > 1) aa(k) = A(k, k - 1)
            if (k < n2) cc(k) = A(k, k + 1)
        end do
        cp(1) = cc(1) / bb(1)
        dp(1) = d(1) / bb(1)
        do k = 2, n2
            m = bb(k) - aa(k) * cp(k - 1)
            cp(k) = cc(k) / m
            dp(k) = (d(k) - aa(k) * dp(k - 1)) / m
        end do
        x(n2) = dp(n2)
        do k = n2 - 1, 1, -1
            x(k) = dp(k) - cp(k) * x(k + 1)
        end do
    end subroutine thomas

end program fem1d

