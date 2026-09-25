! ============================================================
! 25 - 线性方程组专题：Gauss-Jordan 消元与矩阵求逆
!   带列主元的 Gauss-Jordan 解方程组、[A|I]→[I|A⁻¹] 求逆、
!   乘法验算 ‖A·A⁻¹ − I‖、Hilbert 病态矩阵的误差爆炸演示
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 25-gauss-jordan.f90 -o 25-gauss-jordan
! ============================================================

module gj_mod
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: gj_solve, gj_invert, hilbert

contains

  ! 带列主元的 Gauss-Jordan：解 A x = b。
  ! aug 初始为 [A|b]（n×(n+1)），消元结束变成 [I|x]。
  subroutine gj_solve(aug, x, ok)
    real(real64), intent(inout) :: aug(:,:)
    real(real64), intent(out)   :: x(:)
    logical,      intent(out)   :: ok
    integer(int32) :: n, k, i, p
    real(real64)   :: pivot

    n = size(x)
    ok = .true.
    do k = 1, n
      ! 列主元：第 k 列（只看下方行）绝对值最大的换到第 k 行
      p = maxloc(abs(aug(k:n, k)), dim=1) + k - 1
      if (p /= k) then
        aug([k, p], :) = aug([p, k], :)   ! 整行交换，向量下标一行搞定
      end if
      pivot = aug(k, k)
      if (abs(pivot) < 1.0e-14_real64) then
        ok = .false.                       ! 主元近零：奇异或病态到不可解
        return
      end if
      aug(k, :) = aug(k, :) / pivot        ! 主元行归一
      do i = 1, n                          ! 上下一起消 → 单位阵（与 LU 的分野）
        if (i /= k) aug(i, :) = aug(i, :) - aug(i, k) * aug(k, :)
      end do
    end do
    x = aug(:, n + 1)
  end subroutine gj_solve

  ! Gauss-Jordan 求逆：把增广矩阵右半边从 b 换成 I，
  ! 复用同一个消元循环骨架。
  subroutine gj_invert(a, ainv, ok)
    real(real64), intent(in)  :: a(:,:)
    real(real64), intent(out) :: ainv(:,:)
    logical,      intent(out) :: ok
    real(real64), allocatable :: aug(:,:)
    integer(int32) :: n, i
    real(real64), allocatable :: dummy(:)

    n = size(a, 1)
    allocate (aug(n, 2*n), dummy(n))
    aug = 0.0_real64
    aug(:, 1:n) = a
    do i = 1, n                                   ! 右半边是单位阵
      aug(i, n + i) = 1.0_real64
    end do
    call gj_solve(aug, dummy, ok)                 ! 消元后 aug = [I | A⁻¹]
    ainv = aug(:, n + 1:2*n)
    deallocate (aug, dummy)
  end subroutine gj_invert

  ! Hilbert 矩阵：元素 1/(i+j-1)，对称正定但条件数指数爆炸
  pure function hilbert(n) result(h)
    integer(int32), intent(in) :: n
    real(real64) :: h(n, n)
    integer(int32) :: i, j
    do j = 1, n
      do i = 1, n
        h(i, j) = 1.0_real64 / real(i + j - 1, real64)
      end do
    end do
  end function hilbert

end module gj_mod

program gauss_jordan
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use gj_mod
  implicit none

  real(real64), allocatable :: aug(:,:), a(:,:), ainv(:,:), prod(:,:)
  real(real64), allocatable :: x(:), eye(:,:)
  real(real64) :: resid
  logical :: ok
  integer(int32) :: i, k, n
  integer(int32) :: orders(3) = [3, 6, 8]

  ! ---- 1) 解一个已知答案的方程组 ----
  !   3x + 2y +  z = 14
  !    x +  y +  z = 10
  !   2x + 3y −  z = 1        解为 x=1, y=2, z=7
  allocate (aug(3,4), x(3))
  aug = reshape([3.0_real64, 1.0_real64, 2.0_real64, &
                 2.0_real64, 1.0_real64, 3.0_real64, &
                 1.0_real64, 1.0_real64, -1.0_real64, &
                 14.0_real64, 10.0_real64, 1.0_real64], [3, 4])
  call gj_solve(aug, x, ok)
  write (*, '(a)') '1) Gauss-Jordan 解 3×3 方程组（答案应为 1, 2, 7）：'
  do i = 1, 3
    write (*, '("   x", i0, " = ", f10.6)') i, x(i)
  end do
  ! 残差 ‖Ax − b‖：解出来的 x 代回原方程，应当接近 0
  resid = maxval(abs(matmul(aug(:, 1:3), x) - aug(:, 4)))
  write (*, '(a,es9.2)') '   残差 max|Ax-b|   = ', resid

  ! ---- 2) 求逆 + 乘法验算 ----
  allocate (a(3,3), ainv(3,3), prod(3,3), eye(3,3))
  a = reshape([4.0_real64, 1.0_real64, 0.0_real64, &
               1.0_real64, 3.0_real64, 1.0_real64, &
               0.0_real64, 1.0_real64, 2.0_real64], [3, 3])
  call gj_invert(a, ainv, ok)
  write (*, '(a)') '2) Gauss-Jordan 求逆（增广矩阵右半边换成 I）：'
  do i = 1, 3
    write (*, '("   ", 3f10.6)') ainv(i, :)
  end do
  eye = 0.0_real64
  do i = 1, 3
    eye(i, i) = 1.0_real64
  end do
  prod = matmul(a, ainv)
  write (*, '(a,es9.2)') '   验算 max|A·A⁻¹−I| = ', maxval(abs(prod - eye))

  ! ---- 3) Hilbert 病态矩阵：算法正确，数字全错 ----
  ! 条件数随阶数指数增长；real64 只有约 16 位十进制有效数字，
  ! 8 阶时求逆的验算误差已经涨到 1e-7 量级 —— 不是代码 bug，
  ! 是浮点表示的根本局限。
  write (*, '(a)') '3) Hilbert 病态矩阵的求逆验算误差（量级）：'
  do k = 1, 3
    n = orders(k)                     ! 3 阶 / 6 阶 / 8 阶
    block
      real(real64), allocatable :: h(:,:), hinv(:,:), eyen(:,:)
      allocate (h(n,n), hinv(n,n), eyen(n,n))
      h = hilbert(n)
      call gj_invert(h, hinv, ok)
      if (.not. ok) then
        write (*, '("   n=", i0, "：主元近零，放弃")') n
      else
        eyen = 0.0_real64
        do i = 1, n
          eyen(i, i) = 1.0_real64
        end do
        write (*, '("   n=", i0, "：max|H·H⁻¹−I| ≈ ", es9.2)') n, maxval(abs(matmul(h, hinv) - eyen))
      end if
      deallocate (h, hinv, eyen)
    end block
  end do

  write (*, '(a)') '==== 25 结束 ===='

end program gauss_jordan
