program vdp
    implicit none
    integer :: i, mu_i
    real(8) :: mu, h, t
    real(8) :: u(2), xmax, prevx, prevprevx
    real(8) :: peaks(4)
    integer :: np

    print *, "==== 22 vanderpol"

    ! van der Pol: x' = y, y' = mu(1-x^2)y - x
    ! (a) orbit sticks to the limit cycle: successive maxima of x converge
    mu = 4.0d0
    u = [1.0d0, 0.0d0]
    h = 0.002d0
    t = 0.0d0
    xmax = 0.0d0
    prevx = u(1)
    prevprevx = 0.0d0
    np = 0
    do i = 1, 60000            ! t = 120
        call rk4step(mu, t, u, h)
        if (prevprevx < prevx .and. prevx > u(1) .and. prevx > 1.0d0) then
            np = np + 1
            if (np <= 4) peaks(np) = prevx
        end if
        prevprevx = prevx
        prevx = u(1)
        if (t > 60.0d0) xmax = max(xmax, abs(u(1)))
    end do
    if (abs(xmax - 2.0d0) > 0.3d0) then; print *, 'ASSERT FAIL amplitude'; stop 1; end if
    ! 相邻峰值差 → 0：轨道贴环
    if (abs(peaks(4) - peaks(3)) > 0.02d0 * peaks(3)) then
        print *, 'ASSERT FAIL successive maxima converge'; stop 1
    end if
    print '(a, f8.4)', 'mu=4: envelope max|x| = ', xmax, ' (harmonic balance ~2)'
    print *, 'successive maxima converge: orbit is on the limit cycle'

    ! (b) period from peak spacing (mu = 4): T ~ 1.9*mu scale
    ! collect peak times instead
    np = 0
    u = [1.0d0, 0.0d0]
    t = 0.0d0
    prevx = u(1); prevprevx = 0.0d0
    peaks = 0.0d0
    do i = 1, 120000
        call rk4step(mu, t, u, h)
        if (prevprevx < prevx .and. prevx > u(1) .and. prevx > 1.0d0 .and. t > 100.0d0) then
            np = np + 1
            peaks(min(np, 4)) = t
            if (np >= 4) exit
        end if
        prevprevx = prevx
        prevx = u(1)
    end do
    block
        real(8) :: Tper
        Tper = (peaks(4) - peaks(1)) / 3.0d0
        print '(a, f8.4)', 'period T(mu=4) = ', Tper, ' (order mu*(3-2ln2) = 6.45, still relaxing)'
        if (Tper < 8.0d0 .or. Tper > 11.5d0) then; print *, 'ASSERT FAIL period'; stop 1; end if
    end block

    print *, "END ===="
contains
    subroutine rk4step(mu, t, u, h)
        real(8), intent(in) :: mu, h
        real(8), intent(inout) :: t, u(2)
        real(8) :: k1(2), k2(2), k3(2), k4(2)
        k1 = f(mu, t, u)
        k2 = f(mu, t + h/2, u + h*k1/2)
        k3 = f(mu, t + h/2, u + h*k2/2)
        k4 = f(mu, t + h, u + h*k3)
        u = u + h*(k1 + 2*k2 + 2*k3 + k4)/6
        t = t + h
    end subroutine
    function f(mu, t, u) result(fv)
        real(8), intent(in) :: mu, t, u(2)
        real(8) :: fv(2)
        fv = [u(2), mu*(1.0d0 - u(1)**2)*u(2) - u(1)]
    end function
end program vdp
