! ============================================================
! 07 - 字符与字符串
!   定长与延迟长度字符串、子串与子串赋值、拼接与比较规则、
!   常用内建函数、数字↔字符串转换、手写大小写转换、字符串数组
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 07-strings.f90 -o 07-strings
! ============================================================

program strings
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  character(len=10) :: fixed
  character(len=:), allocatable :: dyn, joined
  character(len=8)  :: num
  character(len=64) :: buf
  character(len=6)  :: words(5) = ['pear  ', 'apple ', 'fig   ', 'kiwi  ', 'plum  ']
  character(len=10) :: part
  character(len=10) :: src = '  3.1400  '
  integer(int32)    :: i, j, k
  real(real64)      :: x = 2.718281828_real64

  ! ---- 1) 定长 vs 延迟长度 ----
  fixed = 'abc'                    ! 不足自动补空格到 10
  write (*, '(a,i0,a,a,a)') '1) fixed len=', len(fixed), ' [', fixed, ']'
  dyn = 'abc'                      ! 延迟长度：赋多长就是多长
  write (*, '(a,i0,a,a,a)') '   dyn   len=', len(dyn), ' [', dyn, ']'
  dyn = dyn // 'def'               ! 自动增长
  write (*, '(a,i0,a,a,a)') '   拼接后 len=', len(dyn), ' [', dyn, ']'

  ! ---- 2) 子串取用与子串赋值 ----
  write (*, '(a,a)')   '2) dyn(1:3) = ', dyn(1:3)
  write (*, '(a,a)')   '   dyn(4:6) = ', dyn(4:6)
  write (*, '(a,a)')   '   dyn(2:)  = ', dyn(2:)
  fixed = 'ABCDEFGHIJ'
  fixed(2:3) = 'xy'                ! 子串赋值：左右长度必须一致
  write (*, '(a,a,a)') '   子串赋值后 [', fixed, ']'
  fixed(5:) = repeat('*', 6)       // ''  ! 右边长度不足会补空格，试一下
  write (*, '(a,a,a)') '   尾部赋值后 [', fixed, ']'

  ! ---- 3) 比较规则：短串右侧补空格后再比 ----
  write (*, '(a,l1)') "3) 'abc' == 'abc   '   : ", 'abc' == 'abc   '
  write (*, '(a,l1)') "   'abc' <  'abd'      : ", 'abc' < 'abd'
  write (*, '(a,l1)') "   'Z'   <  'a'（ASCII）: ", 'Z' < 'a'
  write (*, '(a,l1)') "   '10'  <  '9'（字典序）: ", '10' < '9'

  ! ---- 4) 常用内建函数 ----
  joined = '  hello world  '
  write (*, '(a,i0)')  '4) len(joined)          : ', len(joined)
  write (*, '(a,i0)')  '   len_trim(joined)     : ', len_trim(joined)
  write (*, '(a,a,a)') '   trim 后 [', trim(joined), ']'
  write (*, '(a,a,a)') '   adjustl 后 [', adjustl(joined), ']'
  write (*, '(a,a,a)') '   adjustr 后 [', adjustr(joined), ']'
  write (*, '(a,a,a)') '   repeat(''ab'',3) [', repeat('ab', 3), ']'
  write (*, '(a,i0)')  '   index(''hello'',''llo'') : ', index('hello', 'llo')
  write (*, '(a,i0)')  "   index 反向查找       : ", index('hello', 'l', back=.true.)
  write (*, '(a,i0)')  '   scan(''abc123'',''0123456789'') : ', scan('abc123', '0123456789')
  write (*, '(a,i0)')  '   verify(''12345'',''0123456789'') : ', verify('12345', '0123456789')
  write (*, '(a,a)')   "   'ab'//'cd'           : ", 'ab'//'cd'

  ! ---- 5) 数字 ↔ 字符串 ----
  write (num, '(i0)') 12345               ! 整数转字符串
  write (*, '(a,a)') '5) i0 → [', trim(num)//']'
  write (num, '(i8.5)') 42                ! I8.5：占 8 宽、至少 5 位数字、前导零
  write (*, '(a,a)') '   i8.5 → [', num//']'
  write (buf, '(a,f0.4)') 'x = ', x
  write (*, '(a,a)') '   f0.4 → [', trim(buf)//']'
  read (src, '(f8.4)') x                  ! 字符串转实数（内部读的单元必须是变量，不能是常量表达式）
  write (*, '(a,f0.4)') '   f8.4 读回 → ', x

  ! ---- 6) 手写大小写转换（achar/iachar 是标准内建）----
  part = 'Hello World'
  write (*, '(a,a)') '6) 原文   : ', part
  write (*, '(a,a)') '   转大写 : ', upper(part)
  write (*, '(a,a)') '   转小写 : ', lower(part)

  ! ---- 7) 字符串数组：整体与逐元素 ----
  write (*, '(a,5(a,a))') '7) 原数组 :', ('[', trim(words(i))//']', i = 1, 5)
  write (*, '(a,a,a)')    '   最小的 : [', minval(words), ']'
  write (*, '(a,a,a)')    '   最大的 : [', maxval(words), ']'
  ! 选择排序（字典序）
  do i = 1, 4
    k = i
    do j = i + 1, 5
      if (words(j) < words(k)) k = j
    end do
    if (k /= i) then
      part = words(i); words(i) = words(k); words(k) = part
    end if
  end do
  write (*, '(a,5(a,a))') '   排序后 :', ('[', trim(words(i))//']', i = 1, 5)

  ! ---- 8) 拆分字符串（固定分隔符）----
  block
    character(len=:), allocatable :: csv, f(:)
    integer(int32) :: n
    csv = 'alpha,beta,,gamma'
    f = split(csv, ',')
    write (*, '(a,i0)') '8) 拆分段数 : ', size(f)
    do n = 1, size(f)
      write (*, '(a,i0,a,a,a)') '   [', n, '] = "', trim(f(n)), '"'
    end do
  end block

  write (*, '(a)') '==== 07 结束 ===='

contains

  pure function upper(s) result(r)
    character(len=*), intent(in) :: s
    character(len=len(s)) :: r
    integer :: n, c
    do n = 1, len(s)
      c = iachar(s(n:n))
      if (c >= iachar('a') .and. c <= iachar('z')) then
        r(n:n) = achar(c - 32)
      else
        r(n:n) = s(n:n)
      end if
    end do
  end function upper

  pure function lower(s) result(r)
    character(len=*), intent(in) :: s
    character(len=len(s)) :: r
    integer :: n, c
    do n = 1, len(s)
      c = iachar(s(n:n))
      if (c >= iachar('A') .and. c <= iachar('Z')) then
        r(n:n) = achar(c + 32)
      else
        r(n:n) = s(n:n)
      end if
    end do
  end function lower

  ! 按单字符分隔符拆分；连续分隔符会产生空段
  pure function split(s, sep) result(r)
    character(len=*), intent(in) :: s, sep
    character(len=:), allocatable :: r(:)
    integer :: n, cnt, p, q
    cnt = 0
    do n = 1, len(s)
      if (s(n:n) == sep) cnt = cnt + 1
    end do
    allocate (character(len=len(s)) :: r(cnt + 1))
    p = 1
    do n = 1, cnt + 1
      q = index(s(p:), sep)
      if (q == 0) then
        r(n) = s(p:)
        exit
      end if
      r(n) = s(p:p + q - 2)
      p = p + q
    end do
  end function split

end program strings
