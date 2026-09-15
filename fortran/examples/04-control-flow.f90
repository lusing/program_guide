! ============================================================
! 04 - 控制流
!   if / else if、单行 if、select case（含区间与字符）、
!   计数 do、do while、命名循环、cycle 与 exit 带标签、
!   where 掩码赋值、merge、associate、block
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 04-control-flow.f90 -o 04-control-flow
! ============================================================

program control_flow
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  integer(int32) :: i, j, n = 0
  character(len=16) :: grade
  real(real64)    :: v(6) = [1.0_real64, -2.0_real64, 3.0_real64, -4.0_real64, 5.0_real64, -6.0_real64]
  integer(int32)  :: a(8) = [3, -1, 4, -1, 5, -9, 2, -6]

  ! ---- 1) if 块结构 ----
  block
    integer(int32) :: sc = 87
    if (sc >= 90) then
      grade = 'A'
    else if (sc >= 80) then
      grade = 'B'
    else if (sc >= 60) then
      grade = 'C'
    else
      grade = 'F'
    end if
    write (*, '(a,i0,a,a)') '1) 分数 ', sc, ' → 等级 ', grade
  end block

  ! ---- 2) 单行 if（无 end if） ----
  i = 5
  if (i > 0) write (*, '(a)') '2) 单行 if：i 为正'

  ! ---- 3) select case：整数、字符、区间、多值 ----
  do i = 1, 5
    select case (i)
    case (1)
      grade = 'one'
    case (2:3)
      grade = 'two-or-three'
    case (4, 5)
      grade = 'four-or-five'
    case default
      grade = 'other'
    end select
    write (*, '(a,i0,a,a)') '3) case ', i, ' → ', trim(grade)
  end do

  select case ('b')
  case ('a', 'e', 'i', 'o', 'u')
    write (*, '(a)') "3b) 'b' 是元音"
  case default
    write (*, "(a)") "3b) 'b' 是辅音"
  end select

  ! ---- 4) 计数 do：step 可以为负 ----
  write (*, '(a)', advance='no') '4) 正步长：'
  do i = 1, 5, 2
    write (*, '(i3)', advance='no') i
  end do
  write (*, '(a)') ''
  write (*, '(a)', advance='no') '   负步长：'
  do i = 5, 1, -2
    write (*, '(i3)', advance='no') i
  end do
  write (*, '(a)') ''

  ! ---- 5) do while 与无限 do + exit ----
  i = 1
  do while (i < 100)
    i = i * 3
  end do
  write (*, '(a,i0)') '5) do while 后 i = ', i

  j = 0
  do
    j = j + 1
    if (j >= 4) exit
  end do
  write (*, '(a,i0)') '   无限 do + exit 后 j = ', j

  ! ---- 6) 命名循环：内层 exit/cycle 可以指向外层 ----
  n = 0
  outer: do i = 1, 5
    inner: do j = 1, 5
      if (j > i) cycle inner          ! 跳过本轮内层
      if (i * j > 8) exit outer       ! 直接跳出外层
      n = n + 1
    end do inner
  end do outer
  write (*, '(a,i0)') '6) 命名循环累计 n = ', n

  ! ---- 7) where 构造：对数组按掩码逐元素赋值 ----
  write (*, '(a,6f7.1)') '7) 原数组  : ', v
  where (v > 0.0_real64)
    v = v * 10.0_real64
  elsewhere
    v = 0.0_real64
  end where
  write (*, '(a,6f7.1)') '   处理后  : ', v

  ! ---- 8) merge：三元选择的数组/标量版本 ----
  write (*, '(a,3i4)') '8) merge([1,2,3],[9,8,7],mask) = ', &
      merge([1, 2, 3], [9, 8, 7], [1, 2, 3] > 1)

  ! ---- 9) associate：给长表达式起别名 ----
  write (*, '(a,8i4)') '9) a = ', a
  associate (neg => a < 0, cnt => count(a < 0))
    write (*, '(a,l1)')  '9) associate neg(1) = ', neg(1)
    write (*, '(a,i0)')  '   负数个数          = ', cnt
  end associate

  ! ---- 10) block：局部作用域，同名变量互不干扰 ----
  i = 111
  block
    integer(int32) :: i
    i = 222
    write (*, '(a,i0)') '10) block 内 i = ', i
  end block
  write (*, '(a,i0)')  '    外层 i     = ', i

  write (*, '(a)') '==== 04 结束 ===='
end program control_flow
