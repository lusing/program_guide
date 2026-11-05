program multigrid
    implicit none
    ! 坑账：Fortran 大小写不敏感，N 与 n、Nc 与 nc 各自同名——细/粗
    ! 规模分别命名为 Mfine / Mcoarse / Kfine / Kcoarse
    integer, parameter :: Mfine = 64, Mcoarse = Mfine / 2
    integer, parameter :: Kfine = Mfine - 1, Kcoarse = Mcoarse - 1

    real(8) :: h, hc, w, err1, err2, rho
    real(8) :: u(Mfine), uex(Mfine), un(Mfine), r(Mfine), rc(Kcoarse), ec(Kcoarse), ecn(Kcoarse), e(Mfine)
    integer :: k, cyc, s

    h = 1.0d0 / Mfine
    hc = 1.0d0 / Mcoarse
    w = 2.0d0 / 3.0d0
    print *, "==== 33 multigrid"

    do k = 1, Kfine
        uex(k) = k * h * (1 - k * h) / 2.0d0
    end do

    ! 两圈 V 循环，各自报告误差
    u = 0.0d0
    do cyc = 1, 2
        ! 前光滑 3 步
        do s = 1, 3
            un = u
            do k = 1, Kfine
                if (k > 1) then
                    un(k) = (1 - w) * u(k) + w * 0.5d0 * (u(k-1) + u(k+1) + h*h)
                else
                    un(k) = (1 - w) * u(k) + w * 0.5d0 * (0.0d0 + u(k+1) + h*h)
                end if
                if (k == Kfine) un(k) = (1 - w) * u(k) + w * 0.5d0 * (u(k-1) + 0.0d0 + h*h)
            end do
            u = un
        end do
        ! 残差（A = delta2/h^2, f = -1）
        do k = 1, Kfine
            r(k) = -1.0d0 - ((merge(0.0d0, u(k-1), k == 1)) - 2.0d0*u(k) + merge(0.0d0, u(k+1), k == Kfine)) / h**2
        end do
        ! 限制
        do k = 1, Kcoarse
            rc(k) = 0.5d0 * r(2*k) + 0.25d0 * (r(2*k-1) + r(2*k+1))
        end do
        ! 粗网格 GS（A e = rc ⟹ e = 0.5(ul+ur−hc²rc)）
        ec = 0.0d0
        do s = 1, 20000
            ecn = ec
            do k = 1, Kcoarse
                if (k > 1 .and. k < Kcoarse) then
                    ecn(k) = 0.5d0 * (ec(k-1) + ec(k+1) - hc*hc*rc(k))
                else if (k == 1) then
                    ecn(k) = 0.5d0 * (0.0d0 + ec(2) - hc*hc*rc(1))
                else
                    ecn(k) = 0.5d0 * (ec(Kcoarse-1) + 0.0d0 - hc*hc*rc(Kcoarse))
                end if
            end do
            ec = ecn
            if (maxval(abs(ec)) < 1.0d-12) exit
        end do
        ! 延拓
        e = 0.0d0
        do k = 1, Kcoarse
            e(2*k) = ec(k)
        end do
        e(1) = ec(1) / 2.0d0
        do k = 1, Kcoarse - 1
            e(2*k+1) = (ec(k) + ec(k+1)) / 2.0d0
        end do
        e(Kfine) = ec(Kcoarse) / 2.0d0
        u = u + e
        ! 后光滑
        do s = 1, 3
            un = u
            do k = 1, Kfine
                if (k > 1 .and. k < Mfine) then
                    un(k) = (1 - w) * u(k) + w * 0.5d0 * (u(k-1) + u(k+1) + h*h)
                else if (k == 1) then
                    un(k) = (1 - w) * u(k) + w * 0.5d0 * (0.0d0 + u(2) + h*h)
                else
                    un(k) = (1 - w) * u(k) + w * 0.5d0 * (u(Mfine-1) + 0.0d0 + h*h)
                end if
            end do
            u = un
        end do
        err1 = maxval(abs(u(1:Kfine) - uex(1:Kfine)))
        print '(a, i2, a, e12.4)', 'V-cycle ', cyc, ': err = ', err1
        if (cyc == 1) err2 = err1
    end do
    rho = err1 / err2
    print '(a, f8.4)', 'contraction factor = ', rho
    if (rho > 0.5d0) then
        print *, 'ASSERT FAIL: V-cycle should contract fast'; stop 1
    end if
    if (err1 > 1.0d-4) then
        print *, 'ASSERT FAIL: two cycles should nearly converge'; stop 1
    end if

    print *, "END ===="
end program multigrid






