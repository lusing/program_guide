! ============================================================
! 08 - 格式化 I/O
!   格式描述符全表（I/F/E/ES/EN/D/G/L/A/X/T/斜杠/重复/冒号）、
!   格式回退规则、不限组重复 *、内部读写、namelist、iostat/iomsg
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 08-formatted-io.f90 -o 08-formatted-io
! ============================================================

program formatted_io
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  integer(int32)  :: a(5) = [3, 15, 271, 828, 1828]
  integer(int32)  :: i, ios
  real(real64)    :: x = 1234.56789_real64
  real(real64)    :: y(3) = [1.5_real64, 12.25_real64, 123.125_real64]
  character(len=48) :: msg
  character(len=96) :: buf = repeat(' ', 96)
  character(len=16) :: name = 'Ada'
  integer(int32)   :: age = 36
  namelist /person/ name, age

  ! ---- 1) 常用数值描述符 ----
  write (*, '(a,i0)')     '1) I0    不限宽    : ', a(4)
  write (*, '(a,i6)')     '   I6    右对齐 6  : ', a(4)
  write (*, '(a,i6.4)')   '   I6.4  至少 4 位 : ', a(4)
  write (*, '(a,f12.4)')  '   F12.4 定点      : ', x
  write (*, '(a,f0.2)')   '   F0.2  自适应宽  : ', x
  write (*, '(a,e12.4)')  '   E12.4 指数      : ', x
  write (*, '(a,es12.4)') '   ES12.4 科学     : ', x
  write (*, '(a,en12.4)') '   EN12.4 工程记数 : ', x
  write (*, '(a,g12.4)')  '   G12.4 通用      : ', x
  write (*, '(a,l1)')     '   L1    逻辑      : ', .true.
  write (*, '(a,l4)')     '   L4    逻辑      : ', .false.

  ! ---- 2) 字符、位置控制、斜杠 ----
  write (*, '(a)')        '2) A 与 Aw、X、T、/ 的位置控制：'
  write (*, '("   |", a10, "|")') 'ab'
  write (*, '("   |", a2,   "|")') 'abcd'      ! 宽度不足只取前 2 个字符
  write (*, '("   |", 4x, i3, 2x, f6.2, "|")') 7, 1.25
  write (*, '("   |", t10, "右边界", "|")')     ! T10：跳到第 10 列
  write (*, '("   |", tr5, "TR5", tl8, "TL8", "|")')
  write (*, '(a,/,a)') '   斜杠 / 产生记录结束：', '   这两行之间是空行（/ 本身占一行）'

  ! ---- 3) 重复系数与嵌套组 ----
  write (*, '(a)')        '3) 重复系数 3(i4) 与嵌套组 2(i3,",",f6.2)：'
  write (*, '("   ", 3(i4))') (a(i), i = 1, 3)
  write (*, '("   ", 3(i3, ":", f6.2))') (a(i), y(i), i = 1, 3)

  ! ---- 4) 格式回退：数据项比描述符多时，从最后一个括号组重新开始 ----
  write (*, '(a)')        '4) 格式 (i5) 只有 1 个描述符，却有 5 个数据 → 每个值单独成行：'
  write (*, '(i5)') a

  ! ---- 5) 不限组重复 * + 冒号 : —— 避免尾随分隔符 ----
  write (*, '(a)')        '5) *(i0, :, ", ") 的冒号在数据耗尽时终止输出：'
  write (*, '("   好例子：", *(i0, :, ", "))') a
  write (*, '("   坏例子：", *(i0, ", "))')    a

  ! ---- 6) 内部读写：字符串当文件用 ----
  write (buf, '(a,i0,a,f0.3)') '内部写 i=', 42, ' x=', 3.5_real64
  write (*, '(a,a)') '6) 内部写结果    : ', trim(buf)
  buf = '  -17    2.50done'
  read (buf, '(i5, f8.1, a4)') i, x, msg(1:4)
  write (*, '(a,i0,a,f0.1,a,a)') '   内部读回 i=', i, ' x=', x, ' a=', msg(1:4)

  ! ---- 7) namelist：结构化输入输出的省事方案 ----
  write (buf, nml=person, iostat=ios)
  if (ios == 0) then
    write (*, '(a)')        '7) namelist 写出：'
    write (*, '(a,a)')      '   ', trim(buf)
    name = 'nobody'; age = 0
    read (buf, nml=person, iostat=ios)
    write (*, '(a,a,a,i0)') '   读回后 name=', trim(name), ' age=', age
  else
    write (*, '(a)') '7) namelist 缓冲不足'
  end if

  ! ---- 8) iostat / iomsg：格式化读失败时不中止程序 ----
  buf = 'not-a-number'
  read (buf, '(i6)', iostat=ios, iomsg=msg) i
  write (*, '(a,l1)')    '8) 读 ''not-a-number'' 失败？   : ', ios /= 0
  write (*, '(a,l1)')    '   编译器是否填写了 iomsg  : ', len_trim(msg) > 0
  write (*, '(a,i0)')    '   此时 i 的值未被定义，故不打印'

  write (*, '(a)') '==== 08 结束 ===='
end program formatted_io
