! ============================================================
! 19 - C 互操作（iso_c_binding）
!   kind 映射表、调用 libc（strlen/malloc/free/memset/memcpy/fabs）、
!   Fortran ↔ C 字符串互转、c_loc / c_f_pointer、c_funloc 与回调
!   （qsort）、bind(c) 结构体与内存布局、c_sizeof、
!   列主序（Fortran）vs 行主序（C）的转置陷阱、c_associated
!
! 编译（不需要额外链接参数，libc 自动带上）：
!   flang-mp-23 -std=f2018 -pedantic 19-c-interop.f90 -o 19-c-interop
!   gfortran-mp-15 -std=f2018 -pedantic 19-c-interop.f90 -o 19-c-interop
!
! 本示例只调用标准 C 库（libc），不需要写 .c 文件。
! 这也是最常见的 Fortran-C 混编形态：Fortran 当主控，
! C 侧只提供算法或系统调用。
! ============================================================

module cbridge
  use, intrinsic :: iso_c_binding
  implicit none
  private
  public :: c_strlen, c_malloc, c_free, c_memset, c_memcpy, c_qsort, c_fabs
  public :: to_c_string, from_c_string
  public :: point_t, cmp_double, cmp_int32, matrix_from_c_order

  ! ---- bind(c) 结构体：字段顺序和类型必须和 C 侧完全一致 ----
  !   对应 C 的 struct point { double x; double y; };
  type, bind(c) :: point_t
    real(c_double) :: x = 0.0_c_double
    real(c_double) :: y = 0.0_c_double
  end type point_t

  ! ---- libc 函数接口：全部用 bind(c) 声明，name= 给出 C 里的真实符号名 ----
  interface

    function c_strlen(s) bind(c, name='strlen') result(n)
      import :: c_ptr, c_size_t
      type(c_ptr), value :: s
      integer(c_size_t) :: n
    end function c_strlen

    function c_malloc(n) bind(c, name='malloc') result(p)
      import :: c_ptr, c_size_t
      integer(c_size_t), value :: n
      type(c_ptr) :: p
    end function c_malloc

    subroutine c_free(p) bind(c, name='free')
      import :: c_ptr
      type(c_ptr), value :: p
    end subroutine c_free

    function c_memset(s, ch, n) bind(c, name='memset') result(p)
      import :: c_ptr, c_int, c_size_t
      type(c_ptr), value :: s
      integer(c_int), value :: ch
      integer(c_size_t), value :: n
      type(c_ptr) :: p
    end function c_memset

    subroutine c_memcpy(dst, src, n) bind(c, name='memcpy')
      import :: c_ptr, c_size_t
      type(c_ptr), value :: dst, src
      integer(c_size_t), value :: n
    end subroutine c_memcpy

    ! qsort 最后一个参数是函数指针
    subroutine c_qsort(base, nmemb, sz, compar) bind(c, name='qsort')
      import :: c_ptr, c_size_t, c_funptr
      type(c_ptr), value :: base
      integer(c_size_t), value :: nmemb, sz
      type(c_funptr), value :: compar
    end subroutine c_qsort

    ! C 的 double fabs(double)：按值进、按值出
    function c_fabs(x) bind(c, name='fabs') result(y)
      import :: c_double
      real(c_double), value :: x
      real(c_double) :: y
    end function c_fabs

  end interface

contains

  ! ---- Fortran 字符串 → C 字符串（写进调用方给的缓冲，末尾补 NUL）----
  ! 坑点：字符子串的赋值/比较必须写 cs(i:i)，写 cs(i) 会被解析成「函数调用」！
  subroutine to_c_string(s, buf, ok)
    character(len=*), intent(in) :: s
    character(kind=c_char, len=*), intent(out) :: buf
    logical, intent(out) :: ok
    integer :: i, n
    ! 坑：字符赋值是按「空格补齐」的规则来的 —— 写 buf = c_null_char
    !     只会把第 1 个字符设成 NUL，后面 31 个位置全是空格，
    !     结果 C 侧的 strlen 找不到结束符，一路读越界（未定义行为）。
    !     要清成 NUL 必须逐字符赋值。
    do i = 1, len(buf)
      buf(i:i) = c_null_char
    end do
    n = min(len(s), len(buf) - 1)
    ok = len(buf) > len(s)                  ! 有空间放结尾的 NUL 才算成功
    do i = 1, n
      buf(i:i) = char(iachar(s(i:i)), c_char)
    end do
    if (n + 1 <= len(buf)) buf(n + 1:n + 1) = c_null_char
  end subroutine to_c_string

  ! ---- C 字符串 → Fortran 字符串（扫到第一个 NUL 为止）----
  function from_c_string(buf) result(s)
    character(kind=c_char, len=*), intent(in) :: buf
    character(len=:), allocatable :: s
    integer :: i, n
    n = 0
    do i = 1, len(buf)
      if (buf(i:i) == c_null_char) exit
      n = n + 1
    end do
    allocate (character(len=n) :: s)
    do i = 1, n
      s(i:i) = char(iachar(buf(i:i)))
    end do
  end function from_c_string

  ! ---- qsort 比较函数（double 升序）----
  !      必须 bind(c)，签名与 C 的 int (*)(const void*, const void*) 一致。
  !      不能标 pure：c_f_pointer 不是 pure 的。
  integer(c_int) function cmp_double(a, b) bind(c) result(r)
    type(c_ptr), value :: a, b
    real(c_double), pointer :: x, y
    call c_f_pointer(a, x)
    call c_f_pointer(b, y)
    if (x < y) then
      r = -1_c_int
    else if (x > y) then
      r = 1_c_int
    else
      r = 0_c_int
    end if
  end function cmp_double

  integer(c_int) function cmp_int32(a, b) bind(c) result(r)
    type(c_ptr), value :: a, b
    integer(c_int32_t), pointer :: x, y
    call c_f_pointer(a, x)
    call c_f_pointer(b, y)
    if (x < y) then
      r = -1_c_int
    else if (x > y) then
      r = 1_c_int
    else
      r = 0_c_int
    end if
  end function cmp_int32

  ! ---- 把按行主序（C 风格）排的内存重新解释成 Fortran 的列主序数组 ----
  !   C 里 double m[2][3] = {{1,2,3},{4,5,6}} 的内存是 1 2 3 4 5 6
  !   Fortran 的 m(2,3) 内存顺序是 m(1,1) m(2,1) m(1,2) ...
  !   所以要 reshape 成 (3,2) 再转置，才能拿到正确的 (2,3)
  pure function matrix_from_c_order(buf, rows, cols) result(m)
    real(c_double), intent(in) :: buf(:)
    integer, intent(in) :: rows, cols
    real(c_double) :: m(rows, cols)
    real(c_double) :: tmp(cols, rows)
    tmp = reshape(buf, [cols, rows])       ! 先按 C 的视角 (cols, rows) 看
    m = transpose(tmp)                     ! 再转置回 (rows, cols)
  end function matrix_from_c_order

end module cbridge

! ============================================================

program c_interop_demo
  use, intrinsic :: iso_c_binding
  use, intrinsic :: iso_fortran_env, only: real64
  use cbridge
  implicit none

  ! ---- 1) kind 映射表：这些常量保证与 C 侧一致 ----
  write (*, '(a)') '1) iso_c_binding 提供的 kind 常量'
  write (*, '(a,i0,a,i0)') '   c_int / c_long            位宽 = ', &
    storage_size(0_c_int), ' / ', storage_size(0_c_long)
  write (*, '(a,i0,a,i0)') '   c_double / c_float        位宽 = ', &
    storage_size(0.0_c_double), ' / ', storage_size(0.0_c_float)
  write (*, '(a,i0)')      '   c_char                    位宽 = ', storage_size(c_null_char)
  write (*, '(a,i0)')      '   c_bool                    位宽 = ', storage_size(.false._c_bool)
  write (*, '(a,i0)')      '   c_size_t                  位宽 = ', storage_size(0_c_size_t)
  write (*, '(a,i0)')      '   c_int32_t                 位宽 = ', storage_size(0_c_int32_t)
  write (*, '(a,i0)')      '   c_int64_t                 位宽 = ', storage_size(0_c_int64_t)
  write (*, '(a,i0)')      '   c_double 是否就是 real64 ？ ', merge(1, 0, c_double == real64)

  ! ---- 2) 调 libc 的 strlen ----
  block
    character(kind=c_char, len=32), target :: cbuf
    logical :: ok
    call to_c_string('hello, C', cbuf, ok)
    write (*, '(a,l1)')      '2) 转换成功（缓冲区够大）？ ', ok
    write (*, '(a)')         '   c_loc() 的实参必须可互操作：长度 >1 的字符标量不行，'// &
                             '取一个长度为 1 的子串 cbuf(1:1) 就合规了'
    write (*, '(a,i0)')      '   strlen(cbuf) = ', c_strlen(c_loc(cbuf(1:1)))
    write (*, '(a,i0)')      '   Fortran 侧 len(cbuf) = ', len(cbuf)
    write (*, '(a,a,a)')     '   转回 Fortran 字符串 : [', from_c_string(cbuf), ']'
    write (*, '(a)')         '   NUL 不算长度 —— strlen 数到第一个 NUL 为止'
    block
      character(kind=c_char, len=4), target :: tiny
      call to_c_string('hello, C', tiny, ok)
      write (*, '(a,l1)')    '   缓冲区只有 4 字节时 ok = ', ok
      write (*, '(a,a,a)')   '   被截断成 : [', from_c_string(tiny), ']'
    end block
  end block

  ! ---- 3) malloc / memset / c_f_pointer / free ----
  block
    type(c_ptr) :: p, q
    integer(c_size_t) :: nbytes
    integer(c_int32_t), pointer :: arr(:)
    integer :: i
    nbytes = int(10, c_size_t) * c_sizeof(0_c_int32_t)
    p = c_malloc(nbytes)
    if (.not. c_associated(p)) then
      write (*, '(a)') '3) malloc 失败'
    else
      write (*, '(a,i0,a)') '3) malloc ', nbytes, ' 字节成功'
      q = c_memset(p, 0_c_int, nbytes)                ! 整块填 0
      write (*, '(a,l1)') '   memset 返回的就是原指针？ ', c_associated(q, p)
      call c_f_pointer(p, arr, [10])                  ! C 内存 → Fortran 数组
      write (*, '(a,10i4)') '   memset 之后 : ', arr
      do i = 1, 10
        arr(i) = i * i
      end do
      write (*, '(a,10i4)') '   写入平方后 : ', arr
      call c_free(p)
      write (*, '(a)') '   free 之后不可再解引用（c_associated 仍为真，内容是垃圾）'
    end if
  end block

  ! ---- 4) memcpy：整块搬内存 ----
  block
    type(c_ptr) :: src, dst
    integer(c_int32_t), pointer :: pa(:), pb(:)
    integer(c_int32_t), target :: ha(4), hb(4)
    integer(c_size_t) :: nb
    ha = [11, 22, 33, 44]
    hb = 0
    nb = int(4, c_size_t) * c_sizeof(0_c_int32_t)
    src = c_loc(ha(1))
    dst = c_loc(hb(1))
    write (*, '(a,4i5)') '4) memcpy 前 hb : ', hb
    call c_memcpy(dst, src, nb)
    call c_f_pointer(dst, pb, [4])
    call c_f_pointer(src, pa, [4])
    write (*, '(a,4i5)') '   memcpy 后 hb : ', pb
    pa(1) = 999                                     ! 通过 c_ptr 改到原数组
    write (*, '(a,4i5)') '   改指针内容后 ha : ', ha
  end block

  ! ---- 5) qsort + 回调（c_funloc 把 Fortran 过程变成 C 函数指针）----
  block
    real(c_double), target :: d(8) = [3.5_c_double, 1.25_c_double, -2.0_c_double, 9.0_c_double, &
                                      0.0_c_double, 7.5_c_double, -1.0_c_double, 4.0_c_double]
    integer(c_int32_t), target :: iv(8) = [5_c_int32_t, 3_c_int32_t, 9_c_int32_t, 1_c_int32_t, &
                                          7_c_int32_t, 2_c_int32_t, 8_c_int32_t, 4_c_int32_t]
    write (*, '(a,8f8.2)') '5) 排序前 double : ', d
    call c_qsort(c_loc(d(1)), int(size(d), c_size_t), c_sizeof(d(1)), c_funloc(cmp_double))
    write (*, '(a,8f8.2)') '   qsort 后       : ', d
    write (*, '(a,8i4)')   '   排序前 int32   : ', iv
    call c_qsort(c_loc(iv(1)), int(size(iv), c_size_t), c_sizeof(iv(1)), c_funloc(cmp_int32))
    write (*, '(a,8i4)')   '   qsort 后       : ', iv
    write (*, '(a)')       '   比较函数必须 bind(c) 且签名匹配，用 c_funloc 取地址'
  end block

  ! ---- 6) bind(c) 结构体的内存布局 ----
  block
    type(point_t), target :: p
    real(c_double), pointer :: vals(:)
    p%x = 1.5_c_double
    p%y = -2.5_c_double
    write (*, '(a,i0,a)') '6) sizeof(struct point) = ', c_sizeof(p), ' 字节'
    write (*, '(a,f0.2,a,f0.2,a)') '   p = {', p%x, ', ', p%y, '}'
    call c_f_pointer(c_loc(p), vals, [2])            ! 当成 2 元素 double 数组读
    write (*, '(a,2f8.2)') '   当作 double[2] 读 : ', vals
    vals(2) = 100.0_c_double
    write (*, '(a,f0.2)') '   改 vals(2) 后 p%y = ', p%y
    write (*, '(a)')      '   说明 bind(c) 类型的布局完全按 C 规则，可整块传给 C'
  end block

  ! ---- 7) fabs：按 C 的传值约定调用 ----
  write (*, '(a,f0.4)') '7) fabs(-3.75) = ', c_fabs(-3.75_c_double)

  ! ---- 8) 列主序 vs 行主序：混编最常见的 bug ----
  block
    real(c_double) :: m(2, 3), wrong(2, 3)
    real(c_double) :: buf(6)
    integer :: i, j
    ! 假设这是 C 侧 double m[2][3] = {{1,2,3},{4,5,6}} 的内存
    buf = [1.0_c_double, 2.0_c_double, 3.0_c_double, 4.0_c_double, 5.0_c_double, 6.0_c_double]
    write (*, '(a,6f5.1)') '8) C 侧内存（行主序连续存放） : ', buf
    m = matrix_from_c_order(buf, 2, 3)
    write (*, '(a)') '   正确解读（转置后）：'
    do i = 1, 2
      write (*, '(a,3f6.1)') '     ', (m(i, j), j = 1, 3)
    end do
    wrong = reshape(buf, [2, 3])
    write (*, '(a)') '   忘了转置（直接 reshape）就读成：'
    do i = 1, 2
      write (*, '(a,3f6.1)') '     ', (wrong(i, j), j = 1, 3)
    end do
    write (*, '(a)') '   Fortran 列主序、C 行主序 —— 传多维数组必须约定谁负责转置'
  end block

  ! ---- 9) c_associated 的几种用法 ----
  block
    type(c_ptr) :: p, q
    real(c_double), target :: x = 0.0_c_double   ! 别留未定义值，c_loc 也不该指向垃圾
    p = c_loc(x)
    q = c_loc(x)
    write (*, '(a,l1)') '9) 两个 c_ptr 指向同一地址 : ', c_associated(p, q)
    p = c_null_ptr
    write (*, '(a,l1)') '   c_null_ptr 视为未关联      : ', c_associated(p)
    write (*, '(a)')    '   记得把 c_ptr 初始化为 c_null_ptr，别留未定义值'
  end block

  write (*, '(a)') '==== 19 结束 ===='
end program c_interop_demo
