program apps
    implicit none
    integer :: i
    real(8) :: wc, Tcyc, h, s(6), vperp, t
    real(8) :: M(3), M0(3), gB, TLar

    print *, "==== 18 apps"

    ! --- (a) charged particle in B = B z-hat: helical motion ---
    wc = 2.0d0                       ! qB/m
    Tcyc = 2.0d0 * acos(-1.0d0) / wc
    s = [0.0d0, 0.0d0, 0.0d0, 1.0d0, 0.5d0, 0.3d0]
    h = Tcyc / 24000
    t = 0.0d0
    do i = 1, 24000
        call rk4step_particle(wc, t, s, h)
    end do
    if (sqrt(s(1)**2 + s(2)**2) > 1.0d-6) then; print *, 'ASSERT FAIL xy return'; stop 1; end if
    if (abs(s(3) - 0.3d0 * Tcyc) > 1.0d-8) then; print *, 'ASSERT FAIL z drift'; stop 1; end if
    vperp = sqrt(s(4)**2 + s(5)**2)
    if (abs(vperp - sqrt(1.0d0**2 + 0.5d0**2)) > 1.0d-9) then; print *, 'ASSERT FAIL vperp'; stop 1; end if
    print '(a, f8.5, a, f8.5)', 'helix: one cyclotron period, |xy| back to ~0, z drift ', s(3), &
        ' = v_z*Tcyc = ', 0.3d0 * Tcyc

    ! --- (b) magnetic moment precession: Mdot = -gB z x M ---
    gB = 3.0d0
    M0 = [0.8d0, 0.3d0, 0.5d0]
    M = M0
    TLar = 2.0d0 * acos(-1.0d0) / gB
    h = TLar / 24000
    t = 0.0d0
    do i = 1, 24000
        call rk4step_moment(gB, t, M, h)
    end do
    if (sqrt(sum((M - M0)**2)) > 1.0d-6) then; print *, 'ASSERT FAIL Larmor return'; stop 1; end if
    if (abs(M(3) - M0(3)) > 1.0d-9) then; print *, 'ASSERT FAIL Mz'; stop 1; end if
    print *, 'Larmor precession: full period return, M_z conserved'

    print *, "END ===="
contains
    subroutine rk4step_particle(wc, t, s, h)
        real(8), intent(in) :: wc, h
        real(8), intent(inout) :: t, s(6)
        real(8) :: k1(6), k2(6), k3(6), k4(6)
        k1 = fpart(wc, t, s)
        k2 = fpart(wc, t + h/2, s + h*k1/2)
        k3 = fpart(wc, t + h/2, s + h*k2/2)
        k4 = fpart(wc, t + h, s + h*k3)
        s = s + h*(k1 + 2*k2 + 2*k3 + k4)/6
        t = t + h
    end subroutine
    function fpart(wc, t, s) result(f)
        real(8), intent(in) :: wc, t, s(6)
        real(8) :: f(6)
        f = [s(4), s(5), s(6), wc*s(5), -wc*s(4), 0.0d0]
    end function
    subroutine rk4step_moment(gB, t, M, h)
        real(8), intent(in) :: gB, h
        real(8), intent(inout) :: t, M(3)
        real(8) :: k1(3), k2(3), k3(3), k4(3)
        k1 = fmom(gB, M)
        k2 = fmom(gB, M + h*k1/2)
        k3 = fmom(gB, M + h*k2/2)
        k4 = fmom(gB, M + h*k3)
        M = M + h*(k1 + 2*k2 + 2*k3 + k4)/6
        t = t + h
    end subroutine
    function fmom(gB, M) result(f)
        real(8), intent(in) :: gB, M(3)
        real(8) :: f(3)
        f = [-gB*M(2), gB*M(1), 0.0d0]
    end function
end program apps
