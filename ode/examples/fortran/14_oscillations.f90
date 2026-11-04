program oscil
    implicit none
    integer :: i, k, wsteps, nper
    real(8) :: w0, dlt, w, wr, peak, t, y, v, h, Xw, Xmax, pi

    print *, "==== 14 oscillations"

    ! Frequency sweep of x'' + 2*delta*x' + w0^2*x = cos(w t):
    ! integrate 60 periods per point, measure steady peak over one more
    ! period; compare against the analytic amplitude X(w).
    pi = acos(-1.0d0)
    w0 = 1.0d0
    dlt = 0.15d0
    wr = sqrt(w0 * w0 - 2 * dlt * dlt)
    Xmax = 1.0d0 / sqrt((w0*w0 - wr*wr)**2 + (2*dlt*wr)**2)

    wsteps = 25
    nper = 60
    do i = 1, wsteps
        w = 0.2d0 * w0 + (i - 1) * (1.8d0 * w0 / (wsteps - 1))
        h = (2.0d0 * pi) / (w * 400)
        t = 0.0d0; y = 0.0d0; v = 0.0d0
        call sweep_step(w, dlt, w0, t, y, v, h, nper * 400)
        peak = 0.0d0
        do k = 1, 400
            call sweep_step(w, dlt, w0, t, y, v, h, 1)
            peak = max(peak, abs(y))
        end do
        Xw = 1.0d0 / sqrt((w0*w0 - w*w)**2 + (2*dlt*w)**2)
        if (abs(peak - Xw) > 0.02d0 * Xw) then
            print *, 'ASSERT FAIL: sweep amplitude mismatch at w =', w
            stop 1
        end if
        if (i == 1 .or. mod(i, 6) == 0) then
            print '(a, f8.4, a, f10.6, a, f10.6)', 'w =', w, &
                '  numeric peak =', peak, '  analytic X(w) =', Xw
        end if
    end do
    print *, 'sweep: 25 frequencies, numeric peak matches X(w) within 2%'
    print '(a, f8.4)', 'analytic peak at wr =', wr
    print '(a, f8.4)', 'peak amplitude Xmax =', Xmax
    ! 半功率近似核对：Xmax ≈ 1/(2 delta wr)（小阻尼，误差 O(delta^2/w0^2) ~ 1.2%）
    if (abs(Xmax / (1.0d0 / (2.0d0 * dlt * wr)) - 1.0d0) > 0.02d0) then
        print *, 'ASSERT FAIL: Xmax approx check'; stop 1
    end if
    print *, 'Xmax ~ 1/(2*delta*wr) (half-power width 2*delta, Q = w0/(2*delta))'

    print *, "END ===="
contains
    subroutine sweep_step(w, dlt, w0, t, y, v, h, n)
        real(8), intent(in) :: w, dlt, w0, h
        real(8), intent(inout) :: t, y, v
        integer, intent(in) :: n
        integer :: k
        real(8) :: k1y, k1v, k2y, k2v, k3y, k3v, k4y, k4v
        do k = 1, n
            k1y = v;  k1v = -2*dlt*v - w0*w0*y + cos(w*t)
            k2y = v + h*k1v/2
            k2v = -2*dlt*(v+h*k1v/2) - w0*w0*(y+h*k1y/2) + cos(w*(t+h/2))
            k3y = v + h*k2v/2
            k3v = -2*dlt*(v+h*k2v/2) - w0*w0*(y+h*k2y/2) + cos(w*(t+h/2))
            k4y = v + h*k3v
            k4v = -2*dlt*(v+h*k3v) - w0*w0*(y+h*k3y) + cos(w*(t+h))
            y = y + h*(k1y + 2*k2y + 2*k3y + k4y)/6
            v = v + h*(k1v + 2*k2v + 2*k3v + k4v)/6
            t = t + h
        end do
    end subroutine sweep_step
end program oscil
