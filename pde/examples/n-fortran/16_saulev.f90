program saulev
    implicit none
    integer, parameter :: J = 100
    real(8) :: h, tau, r
    real(8) :: u(0:J), un(0:J)
    integer :: n, i, nst
    real(8) :: pi, err, tf

    pi = 4.0d0 * atan(1.0d0)
    h = 1.0d0 / J
    r = 5.0d0          ! 远超 FTCS 的 1/2 限制
    tau = r * h * h
    nst = nint(0.4d0 / tau)
    print *, "==== 16 saulev"

    do i = 0, J
        u(i) = sin(pi * i * h)
    end do

    do n = 1, nst
        un(0) = 0.0d0
        un(J) = 0.0d0
        if (mod(n, 2) == 1) then
            ! (2.16) 从左向右
            do i = 1, J - 1
                un(i) = ((1.0d0 - r) * u(i) + r * u(i + 1) + r * un(i - 1)) / (1.0d0 + r)
            end do
        else
            ! (2.17) 从右向左
            do i = J - 1, 1, -1
                un(i) = ((1.0d0 - r) * u(i) + r * u(i - 1) + r * un(i + 1)) / (1.0d0 + r)
            end do
        end if
        u(0:J) = un(0:J)
    end do

    tf = nst * tau
    err = 0.0d0
    do i = 0, J
        err = max(err, abs(u(i) - exp(-pi * pi * tf) * sin(pi * i * h)))
    end do
    if (err > 3.0d-2) then
        print *, 'ASSERT FAIL: Sauliev r=5 should be stable'; stop 1
    end if
    print '(a, f8.5, a, f4.1)', 'Saulev r=5 sweeps: err = ', err, ' (r = ', r, ')'

    print *, "END ===="
end program saulev
