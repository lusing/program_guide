! ============================================================
! 03 - 表达式与运算符
!   算术/关系/逻辑运算符与优先级、整数除法、混合类型提升、
!   mod 与 modulo 的区别、幂运算、位运算全套、浮点误差
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 03-expressions.f90 -o 03-expressions
! ============================================================

program expressions
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none

  integer(int32)  :: a = 7, b = 2, bits
  real(real64)    :: x
  logical         :: p = .true., q = .false.

  ! ---- 1) 算术运算符：+ - * / ** ----
  write (*, '(a,i0)')    '1) 7 + 2  = ', a + b
  write (*, '(a,i0)')    '   7 - 2  = ', a - b
  write (*, '(a,i0)')    '   7 * 2  = ', a * b
  write (*, '(a,i0)')    '   7 / 2  = ', a / b   ! 整数除法：截断，不是四舍五入
  write (*, '(a,i0)')    '   7 ** 2 = ', a ** b

  ! ---- 2) 整数除法的方向：向零截断（不是向下取整）----
  write (*, '(a,i0)')    '2) (-7) / 2  = ', (-7) / 2
  write (*, '(a,i0)')    '   (-7) / (-2)= ', (-7) / (-2)

  ! ---- 3) 混合类型运算：结果是「精度更高」的那一边 ----
  write (*, '(a,f0.4)')  '3) 7 / 2.0    = ', real(a, real64) / 2.0_real64
  write (*, '(a,f0.4)')  '   real(7)/2  = ', real(7, real64) / real(2, real64)
  write (*, '(a,f0.6)')  '   1.0/3.0    = ', 1.0_real64/3.0_real64

  ! ---- 4) mod 与 modulo：负数上结果不同，这是最常见的坑 ----
  write (*, '(a,i0)')    '4) mod(-7, 3)    = ', mod(-7, 3)      ! -1，结果符号跟被除数
  write (*, '(a,i0)')    '   modulo(-7, 3) = ', modulo(-7, 3)   !  2，结果符号跟除数
  write (*, '(a,i0)')    '   mod(7, -3)    = ', mod(7, -3)
  write (*, '(a,i0)')    '   modulo(7, -3) = ', modulo(7, -3)

  ! ---- 5) 关系运算符：两种写法等价 ----
  write (*, '(a,l1)')    '5) 7 > 2      : ', a > b
  write (*, '(a,l1)')    '   7 .gt. 2   : ', a .gt. b
  write (*, '(a,l1)')    '   7 == 7     : ', a == 7
  write (*, '(a,l1)')    '   7 .eq. 7   : ', a .eq. 7
  write (*, '(a,l1)')    '   7 /= 8     : ', a /= 8
  write (*, '(a,l1)')    '   7 .ne. 8   : ', a .ne. 8

  ! ---- 6) 逻辑运算符：.not. > .and. > .or. > .eqv./.neqv. ----
  write (*, '(a,l1)')    '6) T .and. F  : ', p .and. q
  write (*, '(a,l1)')    '   T .or.  F  : ', p .or. q
  write (*, '(a,l1)')    '   .not. T    : ', .not. p
  write (*, '(a,l1)')    '   T .eqv. F  : ', p .eqv. q
  write (*, '(a,l1)')    '   T .neqv. F : ', p .neqv. q
  ! 优先级验证：.not. 先算，所以下面等价于 (.not. q) .or. q = .true.
  write (*, '(a,l1)')    '   .not.q .or. q : ', .not. q .or. q

  ! ---- 7) 位运算：整数按位操作，操作数宽度决定回绕范围 ----
  bits = int(z'F0F0', int32)
  write (*, '(a,i0)')    '7) popcnt(z''F0F0'')   : ', popcnt(bits)
  write (*, '(a,i0)')    '   leadz(z''F0F0'')    : ', leadz(bits)
  write (*, '(a,i0)')    '   trailz(z''F0F0'')   : ', trailz(bits)
  write (*, '(a,i0)')    '   iand(6, 3)        : ', iand(6, 3)
  write (*, '(a,i0)')    '   ior(6, 3)         : ', ior(6, 3)
  write (*, '(a,i0)')    '   ieor(6, 3)        : ', ieor(6, 3)
  write (*, '(a,i0)')    '   not(0_int32)      : ', not(0_int32)
  write (*, '(a,i0)')    '   shiftl(1, 4)      : ', shiftl(1_int32, 4)
  write (*, '(a,i0)')    '   shiftr(16, 4)     : ', shiftr(16_int32, 4)
  write (*, '(a,i0)')    '   ishft(-8, 1)      : ', ishft(-8_int32, 1)   ! 算术右移
  write (*, '(a,i0)')    '   ishftc(z''F0F0'',4): ', ishftc(bits, 4)
  write (*, '(a,l1)')    '   btest(16, 4)      : ', btest(16_int32, 4)
  write (*, '(a,i0)')    '   ibset(0, 3)       : ', ibset(0_int32, 3)
  write (*, '(a,i0)')    '   ibclr(15, 0)      : ', ibclr(15_int32, 0)
  write (*, '(a,i0)')    '   maskl(8)          : ', maskl(8_int32)

  ! ---- 8) 浮点误差：不要用 == 比较实数 ----
  x = 0.1_real64 + 0.2_real64
  write (*, '(a,l1)')    '8) 0.1 + 0.2 == 0.3   : ', x == 0.3_real64
  write (*, '(a,es20.16)') '   真实值            : ', x
  write (*, '(a,es20.16)') '   差值              : ', x - 0.3_real64
  write (*, '(a,l1)')    '   abs(差) < epsilon : ', abs(x - 0.3_real64) < epsilon(1.0_real64)

  ! ---- 9) 用 integer 做位模式比较是可靠的 ----
  write (*, '(a,l1)')    '9) 0.5 精确可表示？  : ', 1.0_real64/2.0_real64 == 0.5_real64

  write (*, '(a)') '==== 03 结束 ===='
end program expressions
