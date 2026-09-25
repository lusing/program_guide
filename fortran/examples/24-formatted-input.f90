! ============================================================
! 24 - 格式化输入
!   表控 vs 格式、Iw 的空格/截断/全空规则、Fw.d 的「自带小数点优先」、
!   指数形式、Lw、Aw 的「取最右」规则、X 跳列、BN/BZ、
!   文件多记录 + 输入版格式重现、iostat 捕获非法输入
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 24-formatted-input.f90 -o 24-formatted-input
! ============================================================

program formatted_input
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  character(len=64) :: rec          ! 内部读的「记录」
  integer(int32)    :: n, ios
  integer(int32)    :: a, b, c
  real(real64)      :: x, y
  real(real64)      :: z
  logical           :: flag
  character(len=4)  :: s4
  character(len=8)  :: s8
  integer(int32)    :: unit

  ! ---- 1) 整数 Iw：空格不算数、宽度是硬边界 ----
  write (*, '(a)') '1) 整数输入 Iw：'
  rec = '1 2';       read (rec, '(i3)') n
  write (*, '(a,a,a,i0)') '   字段 "1 2"   i3 → ', trim(adjustl(rec)), ' 的空格被忽略，得 ', n
  rec = '1234';      read (rec, '(i3)') n
  write (*, '(a,i0,a)') '   字段 "1234"  i3 → 只取前 3 列得 ', n, '（第 4 位静默丢弃）'
  rec = '  -7';      read (rec, '(i4)') n
  write (*, '(a,i0)') '   字段 "  -7"  i4 → 符号占宽度，得 ', n
  rec = '      ';    read (rec, '(i3)') n
  write (*, '(a,i0,a)') '   字段全空格   i3 → 读成 ', n, '，不是错误！'

  ! ---- 2) 实数 Fw.d：本章最重要的一节 ----
  write (*, '(a)') '2) 实数输入 Fw.d —— 自带小数点优先：'
  rec = '314567';    read (rec, '(f6.2)') x
  write (*, '(a,f9.2)') '   "314567" f6.2 → 不带小数点，d=2 定点：', x
  rec = '314.56';    read (rec, '(f6.2)') y
  write (*, '(a,f9.2)') '   "314.56" f6.2 → 自带小数点，d 被无视：', y
  rec = '314567';    read (rec, '(f6.0)') z
  write (*, '(a,f9.2)') '   "314567" f6.0 → d=0：', z
  rec = '  12.5E+02'; read (rec, '(e10.3)') x
  write (*, '(a,f9.2)') '   "12.5E+02" e10.3 → 指数形式照样收：', x

  ! ---- 3) 逻辑 Lw：第一个非空字符说了算 ----
  write (*, '(a)') '3) 逻辑输入 Lw：'
  rec = '  TRUE';    read (rec, '(l5)') flag
  write (*, '(a,l1)') '   "  TRUE" l5 → ', flag
  rec = 'f----';     read (rec, '(l5)') flag
  write (*, '(a,l1)') '   "f----" l5  → ', flag

  ! ---- 4) 字符 Aw：与赋值语句相反的「取最右」 ----
  write (*, '(a)') '4) 字符输入 Aw：'
  rec = 'CHINA'
  s4 = ''; read (rec, '(a5)') s4
  write (*, '(a,a,a)') '   a5 读 "CHINA" 进 len=4 → 取最右 4 个："', s4, '"'
  s4 = ''; read (rec, '(a)') s4
  write (*, '(a,a,a)') '   不带宽 a   读进 len=4   → 按声明长度截："', s4, '"'
  s8 = ''; read (rec, '(a5)') s8
  write (*, '(a,a,a)') '   a5 读 "CHINA" 进 len=8 → 右侧补空格："', s8, '"'

  ! ---- 5) X 跳列：列的账要一格一格算 ----
  write (*, '(a)') '5) X 跳列：'
  rec = '123456789'
  read (rec, '(1x, i3, 2x, i3)') a, b
  write (*, '(a,i0,a,i0)') '   (1x,i3,2x,i3) 读 "123456789" → ', a, ' 和 ', b

  ! ---- 6) BN / BZ：空格算不算零 ----
  write (*, '(a)') '6) BN（默认，空格忽略）与 BZ（空格按 0）：'
  rec = ' 12   '
  read (rec, '(bn, i6)') n
  write (*, '(a,i0)') '   bn, i6 读 " 12   " → ', n
  read (rec, '(bz, i6)') n
  write (*, '(a,i0,a)') '   bz, i6 读 " 12   " → ', n, '（尾部空格成了 000）'

  ! ---- 7) 文件多记录：斜杠与输入版格式重现 ----
  ! 斜杠结束当前记录；格式用完还有变量要读 → 换新记录、格式从头走。
  open (newunit=unit, file='demo24-input.txt', status='replace', action='write')
  write (unit, '(a)') '111', '222', '333'
  close (unit)
  open (newunit=unit, file='demo24-input.txt', status='old', action='read')
  read (unit, '(i3)') a, b, c          ! 一个 i3 + 三个变量 = 三条记录各取一个
  close (unit)
  write (*, '(a,3i5)') '7) 输入版格式重现：三条记录各喂一个 i3 →', a, b, c

  ! ---- 8) 非法输入：iostat 捕获，别让它炸程序 ----
  rec = 'ab1'
  read (rec, '(i3)', iostat=ios) n
  if (ios /= 0) then
    write (*, '(a)') '8) 字段 "ab1" 不是合法整数 → iostat 捕获，程序继续跑'
  else
    write (*, '(a)') '8) 意外：ab1 居然读进去了？'
  end if

  ! ---- 9) 定宽记录解析：内部读 + 格式 = 一行顶十行 ----
  rec = '20260925  0730  -12.5'
  read (rec, '(i8, 2x, i4, 2x, f5.1)') a, b, x
  write (*, '(a,i0,a,i4.4,a,f5.1)') '9) 定宽解析 "20260925  0730  -12.5" → 日期 ', a, &
       ' 时刻 ', b, ' 气温 ', x

  write (*, '(a)') '==== 24 结束 ===='

end program formatted_input
