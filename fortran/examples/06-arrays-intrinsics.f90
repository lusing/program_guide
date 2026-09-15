! ============================================================
! 06 - 数组内建函数
!   归约（sum/maxval/count/any/all/parity）、dim 与 mask 参数、
!   定位（maxloc/minloc/findloc）、矩阵运算（matmul/dot_product/
!   norm2/transpose）、形状变换（reshape/spread/pack/unpack/
!   cshift/eoshift）、按位归约、掩码赋值
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 06-arrays-intrinsics.f90 -o 06-arrays-intrinsics
! ============================================================

program arrays_intrinsics
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  integer(int32) :: v(6) = [5, 3, 9, 1, 7, 3]
  integer(int32) :: m(2, 3) = reshape([1, 4, 2, 5, 3, 6], [2, 3])
  integer(int32) :: tp(3, 2), pr(2, 2)
  integer(int32) :: bits(4) = [int(z'0F', int32), int(z'33', int32), int(z'55', int32), int(z'F0', int32)]
  logical        :: mk(6) = [.true., .false., .true., .true., .false., .true.]
  integer(int32), allocatable :: d(:), out(:)
  real(real64)   :: r(4) = [3.0_real64, 4.0_real64, 0.0_real64, 0.0_real64]

  write (*, '(a,6i4)') '   v     : ', v
  write (*, '(a,3i4)') '   m(1,:): ', m(1, :)
  write (*, '(a,3i4)') '   m(2,:): ', m(2, :)

  ! ---- 1) 基本归约 ----
  write (*, '(a,i0)') '1) sum(v)     : ', sum(v)
  write (*, '(a,i0)') '   product(v) : ', product(v)
  write (*, '(a,i0)') '   maxval(v)  : ', maxval(v)
  write (*, '(a,i0)') '   minval(v)  : ', minval(v)
  write (*, '(a,i0)') '   count(v>3) : ', count(v > 3)
  write (*, '(a,l1)') '   any(v>8)   : ', any(v > 8)
  write (*, '(a,l1)') '   all(v>0)   : ', all(v > 0)
  write (*, '(a,l1)') '   parity(mk) : ', parity(mk)     ! 掩码里 .true. 个数的奇偶

  ! ---- 2) dim= 参数：沿某一维归约，维数降 1 ----
  write (*, '(a,3i4)') '2) sum(m, dim=1) 沿列 : ', sum(m, dim=1)
  write (*, '(a,2i4)') '   sum(m, dim=2) 沿行 : ', sum(m, dim=2)
  ! 归约维是 1，结果形状是 (3)——m 是 (2,3)，别按 2 个写
  write (*, '(a,3i5)') '   maxval(m,dim=1)    : ', maxval(m, dim=1)

  ! ---- 3) mask= 参数：只统计掩码为真的元素 ----
  write (*, '(a,i0)') '3) sum(v, v>3)      : ', sum(v, mask=(v > 3))
  write (*, '(a,i0)') '   count(v>3)      : ', count(mask=(v > 3))
  write (*, '(a,i0)') '   maxval(v,v<5)   : ', maxval(v, mask=(v < 5))

  ! ---- 4) 定位：连下标一起拿到 ----
  write (*, '(a,i0)')  '4) maxloc(v)        : ', maxloc(v)
  write (*, '(a,i0)')  '   minloc(v)        : ', minloc(v)
  write (*, '(a,2i4)') '   maxloc(m)        : ', maxloc(m)
  write (*, '(a,i0)')  '   findloc(v, 3)    : ', findloc(v, 3)      ! 第一个等于 3 的位置
  write (*, '(a,i0)')  '   findloc 从后往前 : ', findloc(v, 3, back=.true.)
  write (*, '(a,i0)')  '   findloc(v,3,mask): ', findloc(v, 3, mask=(v > 0))

  ! ---- 5) 向量/矩阵运算 ----
  write (*, '(a,i0)')   '5) dot_product(v,v)  : ', dot_product(v, v)
  write (*, '(a,f0.6)') '   norm2([3,4,0,0])  : ', norm2(r)
  tp = transpose(m)
  write (*, '(a,2i4)')  '   transpose 形状    : ', shape(tp)
  write (*, '(a,2i4)')  '   transpose(1,:)    : ', tp(1, :)
  pr = matmul(m, tp)
  write (*, '(a,2i5)')  '   matmul(m, m^T) 首行: ', pr(1, :)

  ! ---- 6) reshape：pad= 补元素，order= 换填充顺序 ----
  d = reshape([1, 2, 3], [4], pad=[0])              ! 不足用 pad 补
  write (*, '(a,4i4)') '6) reshape pad=[0]     : ', d
  write (*, '(a,6i4)') '   order=[2,1] 展开   : ', reshape([1, 2, 3, 4, 5, 6], [2, 3], order=[2, 1])

  ! ---- 7) spread：把一个维度复制开 ----
  write (*, '(a,6i4)') '7) spread([1,2],1,3)  : ', spread([1, 2], 1, 3)

  ! ---- 8) pack / unpack：掩码压缩与还原 ----
  d = pack(v, v > 3)
  write (*, '(a,i0,a,4i4)') '8) pack 后长度 ', size(d), ' : ', d
  use_again: block
    integer(int32) :: back(6)
    back = unpack(pack(v, v > 3), (v > 3), [0, 0, 0, 0, 0, 0])
    write (*, '(a,6i4)') '   unpack 还原 : ', back
  end block use_again
  deallocate (d)

  ! ---- 9) cshift（循环移位）/ eoshift（端点补位移位）----
  d = cshift(v, 2)
  write (*, '(a,6i4)') '9) cshift(v,2)       : ', d
  d = eoshift(v, 2)                                  ! 左移 2，右端补零
  write (*, '(a,6i4)') '   eoshift(v,2)      : ', d
  d = eoshift(v, -1, boundary=-1)                    ! 右移 1，左端补 -1（boundary 对一维数组要写标量）
  write (*, '(a,6i4)') '   eoshift(v,-1,b=-1): ', d
  deallocate (d)

  ! ---- 10) 按位归约（F2008）----
  write (*, '(a,i0)') '10) iall(bits) 逐位与 : ', iall(bits)
  write (*, '(a,i0)') '    iany(bits) 逐位或 : ', iany(bits)
  write (*, '(a,i0)') '    iparity    逐位异或: ', iparity(bits)

  ! ---- 11) 掩码赋值：where / elsewhere ----
  ! 老教程爱用 forall，但 F2018 已把它列为「过时」（obsolescent），
  ! gfortran 15 在 -pedantic 下会为此发警告。官方推荐：
  !   纯数组运算 → where；需要显式循环 → do concurrent（见 20 章）。
  allocate (out(6))
  out = 0
  where (v > 3)
    out = v * 100
  elsewhere
    out = -1
  end where
  write (*, '(a,6i5)') '11) where/elsewhere 结果 : ', out
  deallocate (out)

  write (*, '(a)') '==== 06 结束 ===='
end program arrays_intrinsics
