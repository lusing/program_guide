! ============================================================
! 05 - 数组基础
!   声明与自定义下界、数组构造器、隐含 do、切片与跨步、
!   整体运算（无循环）、列主序、bounds 查询、数组节别名
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 05-arrays-basics.f90 -o 05-arrays-basics
! ============================================================

program arrays_basics
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  integer(int32)  :: a(5)             ! 1..5，默认下界是 1
  integer(int32)  :: b(0:4)           ! 下界 0
  integer(int32)  :: m(2, 3)          ! 2 行 3 列（第一个维是「行」）
  integer(int32)  :: sq(5), evens(3)
  integer(int32)  :: lin(6)
  real(real64)    :: r(4) = [1.0_real64, 2.0_real64, 3.0_real64, 4.0_real64]
  integer(int32)  :: i, j
  real(real64)    :: c(3, 4)

  ! ---- 1) 数组构造器：方括号是 F2003 之后的写法，等价于旧式 (/ /) ----
  a = [10, 20, 30, 40, 50]
  b = [(i, i = 0, 4)]                 ! 隐含 do
  sq = [(i*i, i = 1, 5)]
  evens = [(i, i = 2, 6, 2)]

  write (*, '(a,5i5)') '1) a        : ', a
  write (*, '(a,5i5)') '   b(0:4)   : ', b
  write (*, '(a,5i5)') '   sq       : ', sq
  write (*, '(a,3i5)') '   evens    : ', evens

  ! ---- 2) 构造器可以强制类型：混合字面量会出事 ----
  write (*, '(a,4f7.1)') '2) [real::1,2,3,4] : ', [real(real64) :: 1, 2, 3, 4]

  ! ---- 3) 整体运算：没有循环，逐元素同时算完 ----
  a = a * 2 + 1
  sq = sq + evens(1)
  write (*, '(a,5i5)') '3) a*2+1   : ', a
  write (*, '(a,5i5)') '   sq+2    : ', sq
  write (*, '(a,4f7.2)') '   sqrt(r) : ', sqrt(r)
  write (*, '(a,4f7.2)') '   r**2    : ', r**2
  write (*, '(a,4l3)')   '   r > 2   : ', r > 2.0_real64

  ! ---- 4) 切片与跨步：a(first:last:stride) ----
  write (*, '(a,3i5)') '4) a(1:3)   : ', a(1:3)
  write (*, '(a,3i5)') '   a(1:5:2) : ', a(1:5:2)      ! 奇数位
  write (*, '(a,5i5)') '   a(:)    : ', a(:)
  ! 【坑】a(5:1:-1) 是 5 个元素（5,4,3,2,1），不是 3 个。步长为负时
  !      元素个数 = (last-first+stride)/stride，这里 = 5。描述符写少了
  !      会触发「格式重现」：多出来的数据项从头再走一遍格式，第一个
  !      (a) 描述符拿到的是一个整数，于是把它的原始字节直接吐到终端。
  write (*, '(a,5i5)') '   a(5:1:-1): ', a(5:1:-1)     ! 倒序，5 个
  write (*, '(a,3i5)') '   a(5:3:-1): ', a(5:3:-1)     ! 只要 3 个就写 5:3:-1
  ! 切片可以直接被赋值
  a(2:4) = [0, 0, 0]
  write (*, '(a,5i5)') '   置零后  : ', a

  ! ---- 5) 二维数组与「列主序」内存布局 ----
  lin = [(i, i = 1, 6)]
  m = reshape(lin, [2, 3])            ! 先填第 1 列，再填第 2 列…
  write (*, '(a)')      '5) reshape([1..6],[2,3]) →'
  do i = 1, 2
    write (*, '(a,3i5)') '     ', (m(i, j), j = 1, 3)
  end do
  c = reshape([(real(i, real64), i = 1, 12)], [3, 4])
  write (*, '(a)')      '   reshape([1..12],[3,4]) 按列填：'
  do i = 1, 3
    write (*, '(a,4f7.1)') '     ', (c(i, j), j = 1, 4)
  end do

  ! ---- 6) 边界查询 ----
  write (*, '(a,2i4)') '6) lbound(m)  : ', lbound(m)
  write (*, '(a,2i4)') '   ubound(m)  : ', ubound(m)
  write (*, '(a,2i4)') '   shape(m)   : ', shape(m)
  write (*, '(a,i0)')  '   size(m)    : ', size(m)
  write (*, '(a,i0)')  '   size(m,1)  : ', size(m, 1)
  write (*, '(a,i0)')  '   rank(m)    : ', rank(m)
  write (*, '(a,i0)')  '   lbound(b)  : ', lbound(b)

  ! ---- 7) 整行/整列切片与矩阵运算的入口 ----
  write (*, '(a,2i5)') '7) m(:,2) 第 2 列 : ', m(:, 2)
  write (*, '(a,3i5)') '   m(1,:) 第 1 行 : ', m(1, :)

  ! ---- 8) 数组节的别名陷阱：源与目标重叠时标准不允许 ----
  b = [(i*10, i = 0, 4)]              ! 0 10 20 30 40
  write (*, '(a,5i5)') '8) 左移前的 b : ', b
  block
    integer(int32) :: tmp(3)
    tmp = b(1:3)                      ! 先存一份临时副本（b(2:4)=b(1:3) 是重叠赋值，禁止）
    b(2:4) = tmp
  end block
  write (*, '(a,5i5)') '   左移后的 b : ', b

  write (*, '(a)') '==== 05 结束 ===='
end program arrays_basics
