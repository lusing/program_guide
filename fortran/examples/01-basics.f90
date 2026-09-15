! ============================================================
! 01 - 程序结构与输出
!   最小程序单元、implicit none、write/print、格式描述符入门、
!   续行、语句分隔、内部写、block 构造
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 01-basics.f90 -o 01-basics
!   gfortran-mp-15 -std=f2018 -pedantic 01-basics.f90 -o 01-basics
! ============================================================

program basics
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  ! ---- 声明区：所有变量必须先声明（implicit none 的作用）----
  integer(int32)    :: i    = 42
  real(real64)      :: pi   = 3.14159265358979_real64
  character(len=16) :: name = 'Fortran'
  logical           :: flag = .true.

  ! ---- 1) print 与 write 的区别 ----
  ! print 只写标准输出，格式串必须写；write 可以把单元号参数化
  print '(a)',        '1) print 语句（只能写 stdout）'
  write (*, '(a)')    '   write 语句（单元号可参数化）'

  ! ---- 2) 常用格式描述符 ----
  write (*, '(a,i0)')     '2) I0  不限宽整数     : ', i
  write (*, '(a,i6)')     '   I6  右对齐占 6 格   : ', i
  write (*, '(a,f0.6)')   '   F0.6 定点 6 位小数  : ', pi
  write (*, '(a,es12.5)') '   ES12.5 科学计数     : ', pi
  write (*, '(a,a)')      '   A   字符（可省宽）  : ', trim(name)
  write (*, '(a,l1)')     '   L1  逻辑            : ', flag

  ! ---- 3) 一条语句行可以放多条语句：分号 ----
  i = 1; i = i + 1; i = i * 10
  write (*, '(a,i0)') '3) 分号串联后 i = ', i

  ! ---- 4) 续行：行尾 & 表示「下一行接上」 ----
  i = 100 + &
      200 + &
      300
  write (*, '(a,i0)') '4) 续行求和 i = ', i

  ! ---- 5) 内部写：把结果格式化进字符串，而不是打到终端 ----
  block
    character(len=64) :: buf
    write (buf, '(a,i0)') '内部写结果：i/10 = ', i/10
    write (*, '(a,a)') '5) ', trim(buf)
  end block

  ! ---- 6) 换行与不换行输出：advance='no' ----
  write (*, '(a)', advance='no') '6) 这一行不换行…'
  write (*, '(a)') '…然后接到这里'

  write (*, '(a)') '==== 01 结束 ===='
end program basics
