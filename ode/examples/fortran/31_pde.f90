program pde
    implicit none
    integer, parameter :: N = 50
    real(8) :: dx, dt, r
    real(8) :: u(0:N), un(0:N)
    integer :: i, nsteps, k

    print *, "==== 31 pde"

    ! FTCS for u_t = u_xx on [0,1], u = sin(pi x), zero boundaries.
    dx = 1.0d0 / N

    ! --- (a) stable r = 0.4 ---
    r = 0.4d0
    dt = r * dx * dx
    nsteps = nint(0.05d0 / dt)
    u = [(sin(4.0d0 * atan(1.0d0) * i * dx), i = 0, N)]
    do k = 1, nsteps
        do i = 1, N - 1
            un(i) = u(i) + r * (u(i + 1) - 2.0d0 * u(i) + u(i - 1))
        end do
        u(1:N-1) = un(1:N-1)
    end do
    ! compare with e^{-pi^2 t} sin(pi x)
    block
        real(8) :: pi, t, exact
        pi = 4.0d0 * atan(1.0d0)
        t = 0.05d0
        do i = 10, 40, 15
            exact = exp(-pi * pi * t) * sin(pi * i * dx)
            if (abs(u(i) - exact) > 1.0d-3) then
                print *, 'ASSERT FAIL stable FTCS at i =', i; stop 1
            end if
        end do
        print *, 'FTCS r=0.4: matches exp(-pi^2 t) sin(pi x) at t = 0.05'
    end block

    ! --- (b) unstable r = 0.6 ---
    r = 0.6d0
    dt = r * dx * dx
    nsteps = nint(0.2d0 / dt)
    u = [(sin(4.0d0 * atan(1.0d0) * i * dx), i = 0, N)]
    do k = 1, nsteps
        do i = 1, N - 1
            un(i) = u(i) + r * (u(i + 1) - 2.0d0 * u(i) + u(i - 1))
        end do
        u(1:N-1) = un(1:N-1)
        if (maxval(abs(u)) > 1.0d6) exit
    end do
    if (maxval(abs(u)) < 1.5d0) then
        print *, 'ASSERT FAIL: r=0.6 should be unstable'; stop 1
    end if
    print '(a, e12.4)', 'FTCS r=0.6: max|u| grows to ', maxval(abs(u)), ' (unstable)'

    print *, "END ===="
end program pde
