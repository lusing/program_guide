program matexp
    implicit none
    integer, parameter :: n = 2
    real(8) :: A(n, n), E(n, n), t
    integer :: i, j

    print *, "==== 17 matexp"

    ! Series computation of e^{At} (truncated when the term norm < 1e-16).
    ! Jordan block [[1,1],[0,1]]: e^{At} = e^t [[1, t],[0,1]]
    t = 0.7d0
    A = reshape([1.0d0, 0.0d0, 1.0d0, 1.0d0], [2, 2])   ! column-major: A(1,1)=1 A(2,1)=0 A(1,2)=1 A(2,2)=1
    call matexp_series(A, t, E)
    if (abs(E(1, 1) - exp(t)) > 1.0d-12) then; print *, 'ASSERT FAIL E11'; stop 1; end if
    if (abs(E(1, 2) - t * exp(t)) > 1.0d-12) then; print *, 'ASSERT FAIL E12'; stop 1; end if
    if (abs(E(2, 1)) > 1.0d-15) then; print *, 'ASSERT FAIL E21'; stop 1; end if
    if (abs(E(2, 2) - exp(t)) > 1.0d-12) then; print *, 'ASSERT FAIL E22'; stop 1; end if
    print *, 'Jordan [[1,1],[0,1]]: e^{At} = e^t [[1,t],[0,1]] (series, t=0.7)'

    ! Rotation matrix [[0,-1],[1,0]]: e^{At} = [[cos t, -sin t],[sin t, cos t]]
    t = 1.1d0
    A = reshape([0.0d0, 1.0d0, -1.0d0, 0.0d0], [2, 2])
    call matexp_series(A, t, E)
    if (abs(E(1, 1) - cos(t)) > 1.0d-12) then; print *, 'ASSERT FAIL rot 11'; stop 1; end if
    if (abs(E(1, 2) + sin(t)) > 1.0d-12) then; print *, 'ASSERT FAIL rot 12'; stop 1; end if
    if (abs(E(2, 1) - sin(t)) > 1.0d-12) then; print *, 'ASSERT FAIL rot 21'; stop 1; end if
    if (abs(E(2, 2) - cos(t)) > 1.0d-12) then; print *, 'ASSERT FAIL rot 22'; stop 1; end if
    print *, 'rotation [[0,-1],[1,0]]: e^{At} = [[cos,-sin],[sin,cos]] (series, t=1.1)'

    ! det e^{At} = e^{tr(A) t}
    if (abs(E(1,1)*E(2,2) - E(1,2)*E(2,1) - 1.0d0) > 1.0d-12) then
        print *, 'ASSERT FAIL det'; stop 1
    end if
    print *, 'det e^{At} = e^{tr(A) t} = 1 for the rotation matrix'

    print *, "END ===="
contains
    subroutine matexp_series(A, t, E)
        real(8), intent(in) :: A(2, 2), t
        real(8), intent(out) :: E(2, 2)
        real(8) :: term(2, 2)
        integer :: k
        E = reshape([1.0d0, 0.0d0, 0.0d0, 1.0d0], [2, 2])
        term = E
        do k = 1, 40
            term = matmul(term, A) * (t / k)
            E = E + term
            if (sqrt(sum(term * term)) < 1.0d-16) exit
        end do
    end subroutine matexp_series
end program matexp
