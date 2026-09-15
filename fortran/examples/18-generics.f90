! ============================================================
! 18 - 泛型、重载与 submodule
!   算子重载（operator(+/-/*/==/</)//）、赋值重载 assignment(=)、
!   泛型接口（同名过程覆盖多种类型）、elemental 自定义函数、
!   派生类型自定义 I/O（dt 描述符）、模块接口 + submodule 分离
!   实现、泛型名 + optional 参数
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 18-generics.f90 -o 18-generics
!   gfortran-mp-15 -std=f2018 -pedantic 18-generics.f90 -o 18-generics
!   注意：submodule 必须先编模块再编 submodule（本文件已按此顺序书写，
!         同文件内单次编译即可）
! ============================================================

! ============ 模块接口（只写声明）============

module vecmath
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private

  ! 三维向量：算子重载的载体
  type, public :: vec3
    real(real64) :: x = 0.0_real64, y = 0.0_real64, z = 0.0_real64
  contains
    procedure :: norm => vec3_norm
    procedure :: dot  => vec3_dot
    procedure :: to_string => vec3_to_string
    procedure :: fmt                            ! 自定义 I/O
    generic   :: write(formatted) => fmt
  end type vec3

  ! 有理数：演示 assignment(=) 与比较算子
  type, public :: frac
    integer(int32) :: num = 0, den = 1
  end type frac

  ! ---- 算子接口 ----
  public :: operator(+), operator(-), operator(*), operator(==), &
            operator(<), operator(/=), operator(>)

  interface operator(+)
    module procedure vec_add
  end interface

  interface operator(-)
    module procedure vec_sub
  end interface

  interface operator(*)
    module procedure vec_scale_left, vec_scale_right
  end interface

  interface operator(==)
    module procedure vec_eq, frac_eq
  end interface

  interface operator(<)
    module procedure frac_lt
  end interface

  interface operator(>)
    module procedure frac_gt
  end interface

  interface operator(/=)
    module procedure frac_ne
  end interface

  ! ---- 赋值重载：把实数/整数赋给有理数自动化简 ----
  public :: assignment(=)
  interface assignment(=)
    module procedure frac_from_int, frac_from_real
  end interface

  ! ---- 泛型接口：一个名字覆盖多种类型 ----
  public :: swap, show, norm2d, mkvec, mkfrac, frac_norm
  interface swap
    module procedure swap_i, swap_r, swap_s
  end interface

  interface show
    module procedure show_i, show_r, show_s, show_vec
  end interface

  interface norm2d
    module procedure norm2d_r, norm2d_i
  end interface

  interface mkvec
    module procedure mkvec3, mkvec_scalar
  end interface

  interface mkfrac
    module procedure mkfrac_ii, mkfrac_ir
  end interface

  ! ---- elemental 自定义函数：可以像内建函数一样吃数组 ----
  public :: clamp, square
  interface square
    module procedure square_r, square_i
  end interface

  ! ---- 下面这些放在 submodule 里实现 ----
  public :: vec_norm_sub, vec_scale_sub, frac_reduce_sub, describe

  interface
    module function vec_norm_sub(v) result(n)
      type(vec3), intent(in) :: v
      real(real64) :: n
    end function vec_norm_sub

    module function vec_scale_sub(s, v) result(r)
      real(real64), intent(in) :: s
      type(vec3), intent(in) :: v
      type(vec3) :: r
    end function vec_scale_sub

    module subroutine frac_reduce_sub(f, n, d)
      type(frac), intent(in) :: f
      integer(int32), intent(out) :: n, d
    end subroutine frac_reduce_sub

    module function describe(v) result(s)
      type(vec3), intent(in) :: v
      character(len=:), allocatable :: s
    end function describe
  end interface

contains

  ! ---- 模块内直接实现的算子 ----
  pure function vec_add(a, b) result(r)
    type(vec3), intent(in) :: a, b
    type(vec3) :: r
    r%x = a%x + b%x; r%y = a%y + b%y; r%z = a%z + b%z
  end function vec_add

  pure function vec_sub(a, b) result(r)
    type(vec3), intent(in) :: a, b
    type(vec3) :: r
    r%x = a%x - b%x; r%y = a%y - b%y; r%z = a%z - b%z
  end function vec_sub

  ! 标量在左：s * v
  pure function vec_scale_left(s, v) result(r)
    real(real64), intent(in) :: s
    type(vec3), intent(in) :: v
    type(vec3) :: r
    r%x = s * v%x; r%y = s * v%y; r%z = s * v%z
  end function vec_scale_left

  ! 标量在右：v * s
  pure function vec_scale_right(v, s) result(r)
    type(vec3), intent(in) :: v
    real(real64), intent(in) :: s
    type(vec3) :: r
    r%x = v%x * s; r%y = v%y * s; r%z = v%z * s
  end function vec_scale_right

  pure function vec_eq(a, b) result(ok)
    type(vec3), intent(in) :: a, b
    logical :: ok
    real(real64), parameter :: eps = 1.0e-12_real64
    ok = abs(a%x - b%x) < eps .and. abs(a%y - b%y) < eps .and. abs(a%z - b%z) < eps
  end function vec_eq

  ! 类型绑定过程
  pure function vec3_norm(self) result(n)
    class(vec3), intent(in) :: self
    real(real64) :: n
    n = sqrt(self%x**2 + self%y**2 + self%z**2)
  end function vec3_norm

  pure function vec3_dot(self, other) result(d)
    class(vec3), intent(in) :: self
    type(vec3), intent(in) :: other
    real(real64) :: d
    d = self%x * other%x + self%y * other%y + self%z * other%z
  end function vec3_dot

  pure function vec3_to_string(self) result(s)
    class(vec3), intent(in) :: self
    character(len=:), allocatable :: s
    character(len=64) :: buf
    write (buf, '(a,f0.3,a,f0.3,a,f0.3,a)') '(', self%x, ', ', self%y, ', ', self%z, ')'
    s = trim(buf)
  end function vec3_to_string

  ! 派生类型的格式化输出：被 write(*,'(dt)') 调用
  ! vlist 里装的就是 '(dt(2))' 括号里的参数 —— 这里用它控制小数位数
  subroutine fmt(self, unit, iotype, vlist, iostat, iomsg)
    class(vec3), intent(in) :: self
    integer, intent(in) :: unit
    character(*), intent(in) :: iotype
    integer, intent(in) :: vlist(:)
    integer, intent(out) :: iostat
    character(*), intent(inout) :: iomsg
    character(len=8) :: nd
    character(len=64) :: fspec
    if (size(vlist) > 0) then
      write (nd, '(i0)') vlist(1)
    else
      nd = '3'
    end if
    ! 运行时拼格式串是合法的：字符串拼接后作为 write 的格式实参
    fspec = '(a,f0.'//trim(nd)//',1x,f0.'//trim(nd)//',1x,f0.'//trim(nd)//',a)'
    write (unit, fspec, iostat=iostat, iomsg=iomsg) '[', self%x, self%y, self%z, ']'
  end subroutine fmt

  pure function mkvec3(x, y, z) result(v)
    real(real64), intent(in) :: x, y, z
    type(vec3) :: v
    v = vec3(x, y, z)
  end function mkvec3

  pure function mkvec_scalar(x) result(v)
    real(real64), intent(in) :: x
    type(vec3) :: v
    v = vec3(x, x, x)
  end function mkvec_scalar

  ! ---- 有理数的化简与比较 ----
  pure function frac_gcd(a, b) result(g)
    integer(int32), intent(in) :: a, b
    integer(int32) :: g, x, y, t
    x = abs(a); y = abs(b)
    do while (y /= 0)
      t = mod(x, y); x = y; y = t
    end do
    g = max(x, 1)
  end function frac_gcd

  pure function frac_norm(num, den) result(f)
    integer(int32), intent(in) :: num, den
    type(frac) :: f
    integer(int32) :: g, sgn
    if (den == 0) then                      ! 分母为 0 → 约定返回 0/1
      f%num = 0; f%den = 1
      return
    end if
    g = frac_gcd(num, den)
    sgn = merge(1, -1, den > 0)
    f%num = sgn * num / g
    f%den = abs(den) / g
  end function frac_norm

  pure function mkfrac_ii(num, den) result(f)
    integer(int32), intent(in) :: num, den
    type(frac) :: f
    f = frac_norm(num, den)
  end function mkfrac_ii

  pure function mkfrac_ir(num, den) result(f)
    integer(int32), intent(in) :: num
    real(real64), intent(in) :: den
    type(frac) :: f
    f = frac_norm(num * 1000, nint(den * 1000.0_real64))
  end function mkfrac_ir

  subroutine frac_from_int(f, i)
    type(frac), intent(out) :: f
    integer(int32), intent(in) :: i
    f = frac_norm(i, 1)
  end subroutine frac_from_int

  subroutine frac_from_real(f, r)
    type(frac), intent(out) :: f
    real(real64), intent(in) :: r
    ! 演示用：把小数按 1e-6 精度转成分数
    f = frac_norm(nint(r * 1.0e6_real64), 1000000)
  end subroutine frac_from_real

  pure function frac_eq(a, b) result(ok)
    type(frac), intent(in) :: a, b
    logical :: ok
    ok = (a%num == b%num) .and. (a%den == b%den)
  end function frac_eq

  pure function frac_lt(a, b) result(ok)
    type(frac), intent(in) :: a, b
    logical :: ok
    ok = a%num * b%den < b%num * a%den
  end function frac_lt

  pure function frac_gt(a, b) result(ok)
    type(frac), intent(in) :: a, b
    logical :: ok
    ok = b < a
  end function frac_gt

  pure function frac_ne(a, b) result(ok)
    type(frac), intent(in) :: a, b
    logical :: ok
    ok = .not. (a == b)
  end function frac_ne

  ! ---- 泛型 swap ----
  pure subroutine swap_i(a, b)
    integer(int32), intent(inout) :: a, b
    integer(int32) :: t
    t = a; a = b; b = t
  end subroutine swap_i

  pure subroutine swap_r(a, b)
    real(real64), intent(inout) :: a, b
    real(real64) :: t
    t = a; a = b; b = t
  end subroutine swap_r

  pure subroutine swap_s(a, b)
    character(len=*), intent(inout) :: a, b
    character(len=len(a)) :: t
    t = a; a = b; b = t
  end subroutine swap_s

  ! ---- 泛型 show ----
  pure function show_i(x) result(s)
    integer(int32), intent(in) :: x
    character(len=:), allocatable :: s
    character(len=32) :: b
    write (b, '(i0)') x
    s = 'int('//trim(b)//')'
  end function show_i

  pure function show_r(x) result(s)
    real(real64), intent(in) :: x
    character(len=:), allocatable :: s
    character(len=32) :: b
    write (b, '(f0.3)') x
    s = 'real('//trim(b)//')'
  end function show_r

  pure function show_s(x) result(s)
    character(len=*), intent(in) :: x
    character(len=:), allocatable :: s
    s = 'str('//x//')'
  end function show_s

  pure function show_vec(v) result(s)
    type(vec3), intent(in) :: v
    character(len=:), allocatable :: s
    s = 'vec' // v%to_string()
  end function show_vec

  ! ---- 泛型 norm2d：实数 / 整数两种参数 ----
  pure function norm2d_r(x, y) result(n)
    real(real64), intent(in) :: x, y
    real(real64) :: n
    n = sqrt(x * x + y * y)
  end function norm2d_r

  pure function norm2d_i(x, y) result(n)
    integer(int32), intent(in) :: x, y
    real(real64) :: n
    n = sqrt(real(x * x + y * y, real64))
  end function norm2d_i

  ! ---- elemental 自定义函数（可以吃数组）----
  pure elemental function clamp(x, lo, hi) result(y)
    real(real64), intent(in) :: x, lo, hi
    real(real64) :: y
    y = min(max(x, lo), hi)
  end function clamp

  pure elemental function square_r(x) result(y)
    real(real64), intent(in) :: x
    real(real64) :: y
    y = x * x
  end function square_r

  pure elemental function square_i(x) result(y)
    integer(int32), intent(in) :: x
    integer(int32) :: y
    y = x * x
  end function square_i

end module vecmath

! ============ submodule：把实现藏在另一个文件/区块里 ============
! 真实项目里 submodule 通常单独成文件，编译顺序是
!   flang -c vecmath.f90  →  生成 vecmath.mod
!   flang -c vecmath_impl.f90 -I.  →  生成 .smod
!   flang main.f90 vecmath.o vecmath_impl.o
! 这里为了单文件演示，写在同一个文件里。

submodule(vecmath) vecmath_impl
  implicit none

contains

  module function vec_norm_sub(v) result(n)
    type(vec3), intent(in) :: v
    real(real64) :: n
    n = sqrt(v%x**2 + v%y**2 + v%z**2)
  end function vec_norm_sub

  module function vec_scale_sub(s, v) result(r)
    real(real64), intent(in) :: s
    type(vec3), intent(in) :: v
    type(vec3) :: r
    r%x = s * v%x; r%y = s * v%y; r%z = s * v%z
  end function vec_scale_sub

  module subroutine frac_reduce_sub(f, n, d)
    type(frac), intent(in) :: f
    integer(int32), intent(out) :: n, d
    n = f%num
    d = f%den
  end subroutine frac_reduce_sub

  module function describe(v) result(s)
    type(vec3), intent(in) :: v
    character(len=:), allocatable :: s
    character(len=128) :: b
    write (b, '(a,f0.4,a,f0.4)') 'vec3 |v|=', sqrt(v%x**2 + v%y**2 + v%z**2), ' z=', v%z
    s = trim(b)
  end function describe

end submodule vecmath_impl

! ============ 主程序 ============

program generics_demo
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use vecmath
  implicit none

  type(vec3) :: a, b, c, s
  type(frac) :: f1, f2, f3
  integer(int32) :: i, j, n, d
  real(real64) :: p, q
  character(len=16) :: s1, s2
  integer(int32) :: ai(5) = [1, 2, 3, 4, 5]
  real(real64) :: ar(5) = [-3.0_real64, -0.5_real64, 0.0_real64, 0.7_real64, 9.0_real64]

  ! ---- 1) 向量算子重载 ----
  a = mkvec(1.0_real64, 2.0_real64, 3.0_real64)
  b = mkvec(4.0_real64, 5.0_real64, 6.0_real64)
  write (*, '(a,dt)') '1) a        = ', a
  write (*, '(a,dt)') '   b        = ', b
  c = a + b
  write (*, '(a,dt)') '   a + b    = ', c
  c = a - b
  write (*, '(a,dt)') '   a - b    = ', c
  c = 2.5_real64 * a
  write (*, '(a,dt)') '   2.5 * a  = ', c
  c = b * 2.0_real64
  write (*, '(a,dt)') '   b * 2.0  = ', c
  write (*, '(a,l1)')  '   a == a ? ', (a == a)
  write (*, '(a,l1)')  '   a == b ? ', (a == b)
  write (*, '(a,f0.4)') '   a % dot(b) = ', a%dot(b)
  write (*, '(a,f0.4)') '   a % norm() = ', a%norm()
  write (*, '(a,a)')    '   a % to_string() = ', a%to_string()

  ! ---- 2) 自定义输出格式 '(dt(2))' 传小数位数 ----
  write (*, '(a,dt(2))') '2) a 用 dt(2) 输出 : ', a
  write (*, '(a,dt(4))') '   a 用 dt(4) 输出 : ', a

  ! ---- 3) 有理数：赋值重载自动化简 ----
  f1 = frac_norm(6, 8)
  write (*, '(a,i0,a,i0)') '3) frac_norm(6,8) = ', f1%num, '/', f1%den
  f2 = frac_norm(-4, -6)
  write (*, '(a,i0,a,i0)') '   frac_norm(-4,-6) = ', f2%num, '/', f2%den
  f3 = 0                                  ! 整数赋值 → assignment(=)
  write (*, '(a,i0,a,i0)') '   整数 0 赋值 = ', f3%num, '/', f3%den
  f3 = 0.25_real64                        ! 实数赋值 → assignment(=)
  write (*, '(a,i0,a,i0)') '   实数 0.25 赋值 = ', f3%num, '/', f3%den

  ! ---- 4) 有理数比较 ----
  f1 = mkfrac(1, 3)
  f2 = mkfrac(1, 2)
  write (*, '(a,i0,a,i0,a,i0,a,i0,a,l1)') '4) 1/3 < 1/2 ? ', f1%num, '/', f1%den, ' < ', &
    f2%num, '/', f2%den, ' = ', (f1 < f2)
  write (*, '(a,l1)') '   1/3 > 1/2 ? ', (f1 > f2)
  write (*, '(a,l1)') '   1/3 == 2/6 ? ', (f1 == mkfrac(2, 6))
  write (*, '(a,l1)') '   1/3 /= 2/6 ? ', (f1 /= mkfrac(2, 6))
  write (*, '(a,i0,a,i0)') '   mkfrac(3, 7) 的分子分母 = ', get_num(mkfrac(3, 7)), '/', get_den(mkfrac(3, 7))

  ! ---- 5) 泛型 swap：三种类型同一个名字 ----
  i = 1; j = 2
  call swap(i, j)
  write (*, '(a,2i4)') '5) swap 整数 : ', i, j
  p = 1.5_real64; q = 2.5_real64
  call swap(p, q)
  write (*, '(a,2f6.2)') '   swap 实数 : ', p, q
  s1 = 'alpha'; s2 = 'beta'
  call swap(s1, s2)
  write (*, '(a,a,a,a)') '   swap 字符 : ', trim(s1), ' ', trim(s2)

  ! ---- 6) 泛型 show：同一个名字覆盖四种 ----
  write (*, '(a,a)') '6) show(42)      = ', show(42)
  write (*, '(a,a)') '   show(3.14159)  = ', show(3.14159_real64)
  write (*, '(a,a)') '   show("hi")     = ', show('hi')
  write (*, '(a,a)') '   show(a)        = ', show(a)

  ! ---- 7) elemental 自定义函数吃数组 ----
  write (*, '(a,5f7.2)') '7) square(ar) 逐元素平方 : ', square(ar)
  write (*, '(a,5i5)')   '   square(ai)             : ', square(ai)
  write (*, '(a,5f7.2)') '   clamp(ar,-1.0,1.0)     : ', clamp(ar, -1.0_real64, 1.0_real64)
  write (*, '(a,l1)')    '   ar、ai 都没被改动？ ', (ar(1) < 0.0_real64)

  ! ---- 8) 泛型接口 + 混合精度参数 ----
  write (*, '(a,f0.6)') '8) norm2d(3.0, 4.0)  实数版 = ', norm2d(3.0_real64, 4.0_real64)
  write (*, '(a,f0.6)') '   norm2d(3, 4)      整数版 = ', norm2d(3, 4)
  write (*, '(a,dt)')   '   mkvec(7.0)  标量广播   = ', mkvec(7.0_real64)
  write (*, '(a,dt)')   '   mkvec(1.0,2.0,3.0)    = ', mkvec(1.0_real64, 2.0_real64, 3.0_real64)

  ! ---- 9) submodule 里实现的东西 ----
  write (*, '(a,f0.6)') '9) vec_norm_sub(a)      = ', vec_norm_sub(a)
  s = vec_scale_sub(3.0_real64, a)
  write (*, '(a,dt)')   '   vec_scale_sub(3, a) = ', s
  call frac_reduce_sub(mkfrac(14, 21), n, d)
  write (*, '(a,i0,a,i0)') '   submodule 里化简 14/21 = ', n, '/', d
  write (*, '(a,a)')    '   describe(a)         = ', describe(a)

  ! ---- 10) 模块级泛型名和类型绑定过程可以混用 ----
  write (*, '(a,a)') '10) 同名 show 也能吃 vec3（靠类型匹配） : ', &
    show(mkvec(1.0_real64, 1.0_real64, 1.0_real64))

  write (*, '(a)') '==== 18 结束 ===='

contains

  ! 演示用：把 frac 的分量取出来（模块 private 分量访问不到，这里只是打个样）
  pure function get_num(f) result(n)
    type(frac), intent(in) :: f
    integer(int32) :: n
    n = f%num
  end function get_num

  pure function get_den(f) result(n)
    type(frac), intent(in) :: f
    integer(int32) :: n
    n = f%den
  end function get_den

end program generics_demo
