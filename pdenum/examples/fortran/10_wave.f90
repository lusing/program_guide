program wave
    implicit none
    integer, parameter :: J = 200
    real(8) :: h, lam, tau
    real(8) :: u0(0:J), u1(0:J), un(0:J)
    integer :: n, i, nst
    real(8) :: pi

    pi = 4.0d0 * atan(1.0d0)
    print *, "==== 10 wave"

    ! ---------- (1) 方波分裂传播（CFL = 0.8，双波前左右分开） ----------
    h = 1.0d0 / J
    lam = 0.8d0
    tau = lam * h
    nst = nint(0.25d0 / tau)
    do i = 0, J
        if (0.4d0 < i * h .and. i * h < 0.6d0) then
            u0(i) = 1.0d0
        else
            u0(i) = 0.0d0
        end if
    end do
    ! 二阶起步（g = 0）：u^1 = f + (lam^2/2) delta^2 f
    do i = 1, J - 1
        u1(i) = u0(i) + 0.5d0 * lam * lam * (u0(i + 1) - 2.0d0 * u0(i) + u0(i - 1))
    end do
    u1(0) = u1(J - 1)   ! 周期
    u1(J) = u1(0)
    do n = 2, nst
        do i = 1, J - 1
            un(i) = 2.0d0 * u1(i) - u0(i) + lam * lam * (u1(i + 1) - 2.0d0 * u1(i) + u1(i - 1))
        end do
        un(0) = un(J - 1)
        un(J) = un(0)
        u0 = u1
        u1 = un
    end do
    ! 方波分裂成左右行波：中点区域回落，两波前分离
    if (abs(u1(J / 2)) > 0.05d0) then
        print *, 'ASSERT FAIL: square pulse should split, center near 0'; stop 1
    end if
    print '(a, f8.4, a)', 'square pulse splits (center value = ', u1(J / 2), '), CFL = 0.8 stable'

    ! ---------- (2) 违反 CFL：lam = 1.01 爆炸 ----------
    lam = 1.01d0
    tau = lam * h
    nst = nint(0.5d0 / tau)
    do i = 0, J
        u0(i) = sin(2.0d0 * pi * i * h)
    end do
    do i = 1, J - 1
        u1(i) = u0(i) + 0.5d0 * lam * lam * (u0(i + 1) - 2.0d0 * u0(i) + u0(i - 1))
    end do
    u1(0) = u1(J - 1)
    u1(J) = u1(0)
    do n = 2, nst
        do i = 1, J - 1
            un(i) = 2.0d0 * u1(i) - u0(i) + lam * lam * (u1(i + 1) - 2.0d0 * u1(i) + u1(i - 1))
        end do
        un(0) = un(J - 1)
        un(J) = un(0)
        u0 = u1
        u1 = un
        if (maxval(abs(u1)) > 1.0d6) exit
    end do
    if (maxval(abs(u1)) < 100.0d0) then
        print *, 'ASSERT FAIL: lam=1.01 should blow up'; stop 1
    end if
    print '(a, e12.4)', 'lam = 1.01 violates CFL: max|u| = ', maxval(abs(u1))

    print *, "END ===="
end program wave
