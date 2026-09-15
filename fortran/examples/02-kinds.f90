! ============================================================
! 02 - 类型与 KIND
!   五种内建类型、kind 常量、selected_*_kind、数值模型查询、
!   字面量后缀、BOZ 字面量、类型转换
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 02-kinds.f90 -o 02-kinds
! ============================================================

program kinds
  use, intrinsic :: iso_fortran_env, only: &
      int8, int16, int32, int64, real32, real64, real128
  implicit none

  integer(int32)  :: k
  ! 写成 parameter：flang 会把「只用来取 kind 的变量」判成未使用
  real(real32), parameter :: r32 = 1.0_real32
  real(real64)    :: r64 = 1.0_real64
  integer(int64)  :: big
  complex(real64) :: z
  character(len=8) :: s = 'abc'

  ! ---- 1) 整数 kind：数值恰好等于字节数，但标准只保证「至少这么宽」 ----
  write (*, '(a,4i4)') '1) 整数 kind  int8/16/32/64 : ', int8, int16, int32, int64
  write (*, '(a,i0)')  '   storage_size(int64)/8    : ', storage_size(0_int64)/8

  ! ---- 2) 实数 kind：real128 在 flang 23 上是 -1（不支持该精度）----
  write (*, '(a,3i4)') '2) 实数 kind  real32/64/128  : ', real32, real64, real128
  write (*, '(a,l1)')  '   本机支持四倍精度吗       : ', real128 /= -1

  ! ---- 3) 可移植写法：不写死字节数，而是「要求多少位十进制精度」 ----
  k = selected_real_kind(15)
  write (*, '(a,i0)') '3) selected_real_kind(15)   : ', k
  write (*, '(a,i0)') '   selected_real_kind(30)   : ', selected_real_kind(30)
  write (*, '(a,i0)') '   selected_int_kind(9)     : ', selected_int_kind(9)
  write (*, '(a,i0)') '   selected_int_kind(18)    : ', selected_int_kind(18)

  ! ---- 4) 字面量后缀：把常数钉死在某个 kind 上 ----
  r64 = 3.14159265358979_real64
  big = 9000000000_int64            ! 超过 int32 范围，必须带后缀
  write (*, '(a,f0.14)') '4) 3.14159265358979_real64 : ', r64
  write (*, '(a,i0)')    '   9000000000_int64         : ', big

  ! ---- 5) 数值模型查询：写数值算法前必须知道这些量 ----
  write (*, '(a,i0)')    '5) digits(r64)      : ', digits(r64)
  write (*, '(a,i0)')    '   precision(r64)   : ', precision(r64)
  write (*, '(a,i0)')    '   range(r64)       : ', range(r64)
  write (*, '(a,i0)')    '   radix(r64)       : ', radix(r64)
  write (*, '(a,i0)')    '   maxexponent(r64) : ', maxexponent(r64)
  write (*, '(a,i0)')    '   minexponent(r64) : ', minexponent(r64)
  ! 坑：ES/EN/E 描述符不写 Ee 时，指数位固定只有 2 位。
  !     huge(real64) 的指数是 308，要 3 位；装不下时两个编译器都会打出
  !     残缺的 "1.797693+308"（连字母 E 都没了），而且把字段加宽也没用。
  !     正确做法是显式给出指数位宽：ESw.dEe，这里用 es15.6e3。
  write (*, '(a,es15.6e3)')'   huge(r64)        : ', huge(r64)
  write (*, '(a,es15.6e3)')'   tiny(r64)        : ', tiny(r64)
  write (*, '(a,es13.6)')'   epsilon(r64)     : ', epsilon(r64)
  write (*, '(a,es13.6)')'   epsilon(r32)     : ', epsilon(r32)

  ! ---- 6) 复数：两个实数分量，kind 由分量决定 ----
  z = (1.0_real64, 2.0_real64)
  write (*, '(a,f0.1,a,f0.1,a)') '6) z = ', real(z), ' + ', aimag(z), 'i'
  write (*, '(a,f0.4)')          '   abs(z)     : ', abs(z)
  write (*, '(a,f0.1,a,f0.1,a)') '   conjg(z) = ', real(conjg(z)), ' - ', aimag(conjg(z)), 'i'
  write (*, '(a,f0.1,a,f0.1,a)') '   z*z = ', real(z*z), ' + ', aimag(z*z), 'i'

  ! ---- 7) BOZ 字面量：二进制/八进制/十六进制位模式 ----
  write (*, '(a,i0)') '7) int(z''FF'', int32)      : ', int(z'FF', int32)
  write (*, '(a,i0)') '   int(o''17'', int32)      : ', int(o'17', int32)
  write (*, '(a,i0)') '   int(b''1010'', int32)    : ', int(b'1010', int32)

  ! ---- 8) 类型转换函数 ----
  write (*, '(a,i0)')    '8) int(3.9)     : ', int(3.9)        ! 截断
  write (*, '(a,i0)')    '   nint(3.5)    : ', nint(3.5)       ! 四舍六入五成双
  write (*, '(a,i0)')    '   floor(-3.2)  : ', floor(-3.2)
  write (*, '(a,i0)')    '   ceiling(-3.2): ', ceiling(-3.2)
  write (*, '(a,f0.2)')  '   real(7,int)  : ', real(7, real64)
  write (*, '(a,l1)')    '   ichar(''a'') > 0 : ', ichar('a') > 0
  write (*, '(a,i0)')    '   len(s)       : ', len(s)
  write (*, '(a,i0)')    '   len_trim(s)  : ', len_trim(s)

  write (*, '(a)') '==== 02 结束 ===='
end program kinds
