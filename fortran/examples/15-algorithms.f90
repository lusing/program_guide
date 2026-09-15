! ============================================================
! 15 - 经典算法
!   递归 vs 迭代、冒泡/插入/快速/归并排序、二分查找、埃氏筛法、
!   欧几里得算法、汉诺塔、记忆化斐波那契、数组传参与 inout 语义
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 15-algorithms.f90 -o 15-algorithms
!   gfortran-mp-15 -std=f2018 -pedantic 15-algorithms.f90 -o 15-algorithms
! ============================================================

module algorithms
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none
  private
  public :: bubble_sort, insertion_sort, quick_sort, merge_sort, &
            binary_search_rec, binary_search_iter, sieve, gcd_rec, gcd_iter, &
            hanoi, hanoi_moves, fib_memo, fib_iter, is_sorted, shuffle

  integer(int32) :: hanoi_count = 0

contains

  ! ---- 冒泡排序：最直观，O(n^2) ----
  subroutine bubble_sort(a)
    integer(int32), intent(inout) :: a(:)
    integer(int32) :: i, j, tmp, n
    n = size(a)
    do i = 1, n - 1
      do j = 1, n - i
        if (a(j) > a(j + 1)) then
          tmp = a(j); a(j) = a(j + 1); a(j + 1) = tmp
        end if
      end do
    end do
  end subroutine bubble_sort

  ! ---- 插入排序：小数组上比快排还快 ----
  subroutine insertion_sort(a)
    integer(int32), intent(inout) :: a(:)
    integer(int32) :: i, j, key
    do i = 2, size(a)
      key = a(i)
      j = i - 1
      do while (j >= 1)
        if (a(j) <= key) exit
        a(j + 1) = a(j)
        j = j - 1
      end do
      a(j + 1) = key
    end do
  end subroutine insertion_sort

  ! ---- 快速排序：递归 + 分区。注意 Fortran 传的是引用，
  !      递归调用时传数组节 a(lo:hi) 会自动生成「数组片段描述符」 ----
  recursive subroutine quick_sort(a, lo, hi)
    integer(int32), intent(inout) :: a(:)
    integer(int32), intent(in) :: lo, hi
    integer(int32) :: p
    if (lo >= hi) return
    p = partition(a, lo, hi)
    call quick_sort(a, lo, p - 1)
    call quick_sort(a, p + 1, hi)
  end subroutine quick_sort

  ! 注意：pure 函数的哑元只能是 intent(in) 或 value，
  !       所以这里要原地改数组就不能标 pure（flang 会放行，gfortran 会报错）
  function partition(a, lo, hi) result(p)
    integer(int32), intent(inout) :: a(:)
    integer(int32), intent(in) :: lo, hi
    integer(int32) :: p, i, tmp, pivot
    pivot = a(hi)
    p = lo - 1
    do i = lo, hi - 1
      if (a(i) <= pivot) then
        p = p + 1
        tmp = a(p); a(p) = a(i); a(i) = tmp
      end if
    end do
    p = p + 1
    tmp = a(p); a(p) = a(hi); a(hi) = tmp
  end function partition

  ! ---- 归并排序：需要 O(n) 额外空间，但稳定 ----
  recursive subroutine merge_sort(a)
    integer(int32), intent(inout) :: a(:)
    integer(int32), allocatable :: tmp(:)
    integer(int32) :: mid
    if (size(a) <= 1) return
    mid = size(a) / 2
    call merge_sort(a(1:mid))          ! 数组节作实参：直接改到原数组上
    call merge_sort(a(mid + 1:))
    allocate (tmp(size(a)))
    tmp = merge2(a(1:mid), a(mid + 1:))
    a = tmp
    deallocate (tmp)
  end subroutine merge_sort

  pure function merge2(left, right) result(res)
    integer(int32), intent(in) :: left(:), right(:)
    integer(int32), allocatable :: res(:)
    integer(int32) :: i, j, k
    allocate (res(size(left) + size(right)))
    i = 1; j = 1; k = 1
    do while (i <= size(left) .and. j <= size(right))
      if (left(i) <= right(j)) then
        res(k) = left(i); i = i + 1
      else
        res(k) = right(j); j = j + 1
      end if
      k = k + 1
    end do
    if (i <= size(left)) res(k:) = left(i:)
    if (j <= size(right)) res(k:) = right(j:)
  end function merge2

  ! ---- 二分查找（递归版）：返回下标，找不到返回 0 ----
  recursive function binary_search_rec(a, key, lo, hi) result(pos)
    integer(int32), intent(in) :: a(:), key
    integer(int32), intent(in) :: lo, hi
    integer(int32) :: pos, mid
    if (lo > hi) then
      pos = 0
      return
    end if
    mid = (lo + hi) / 2
    if (a(mid) == key) then
      pos = mid
    else if (a(mid) < key) then
      pos = binary_search_rec(a, key, mid + 1, hi)
    else
      pos = binary_search_rec(a, key, lo, mid - 1)
    end if
  end function binary_search_rec

  ! ---- 二分查找（迭代版）：实际代码优先用这个 ----
  pure function binary_search_iter(a, key) result(pos)
    integer(int32), intent(in) :: a(:), key
    integer(int32) :: pos, lo, hi, mid
    lo = 1; hi = size(a); pos = 0
    do while (lo <= hi)
      mid = (lo + hi) / 2
      if (a(mid) == key) then
        pos = mid
        return
      else if (a(mid) < key) then
        lo = mid + 1
      else
        hi = mid - 1
      end if
    end do
  end function binary_search_iter

  ! ---- 埃氏筛法：逻辑数组当掩码，比整数数组更省 ----
  function sieve(n) result(primes)
    integer(int32), intent(in) :: n
    integer(int32), allocatable :: primes(:)
    logical, allocatable :: isp(:)
    integer(int32) :: i, j, cnt
    allocate (isp(2:n))
    isp = .true.
    do i = 2, int(sqrt(real(n, real64)))
      if (isp(i)) then
        do j = i * i, n, i
          isp(j) = .false.
        end do
      end if
    end do
    cnt = count(isp)
    allocate (primes(cnt))
    cnt = 0
    do i = 2, n
      if (isp(i)) then
        cnt = cnt + 1
        primes(cnt) = i
      end if
    end do
  end function sieve

  ! ---- 欧几里得算法：递归版 ----
  recursive pure function gcd_rec(a, b) result(g)
    integer(int32), intent(in) :: a, b
    integer(int32) :: g
    if (b == 0) then
      g = abs(a)
    else
      g = gcd_rec(b, mod(a, b))
    end if
  end function gcd_rec

  ! ---- 非递归版：位运算加速（二进制 GCD 思路的简化）----
  pure function gcd_iter(a, b) result(g)
    integer(int32), intent(in) :: a, b
    integer(int32) :: g, x, y, t
    x = abs(a); y = abs(b)
    do while (y /= 0)
      t = mod(x, y)
      x = y
      y = t
    end do
    g = x
  end function gcd_iter

  ! ---- 汉诺塔：递归的教科书例子 ----
  recursive subroutine hanoi(n, from, to, via)
    integer(int32), intent(in) :: n
    character(len=1), intent(in) :: from, to, via
    if (n == 1) then
      hanoi_count = hanoi_count + 1
      return
    end if
    call hanoi(n - 1, from, via, to)
    hanoi_count = hanoi_count + 1
    call hanoi(n - 1, via, to, from)
  end subroutine hanoi

  function hanoi_moves(n) result(cnt)
    integer(int32), intent(in) :: n
    integer(int32) :: cnt
    hanoi_count = 0
    call hanoi(n, 'A', 'C', 'B')
    cnt = hanoi_count
  end function hanoi_moves

  ! ---- 记忆化斐波那契：用 module 变量做缓存 ----
  !      比朴素递归 O(2^n) 快若干个数量级
  !      自己调用自己，必须显式声明 recursive
  recursive function fib_memo(n) result(v)
    integer(int32), intent(in) :: n
    integer(int64) :: v
    integer(int64), allocatable, save :: cache(:)
    if (n < 0) then
      v = 0
      return
    end if
    if (.not. allocated(cache)) then
      allocate (cache(0:n))
      cache = -1_int64
    else if (n > ubound(cache, 1)) then
      call grow(cache, n)
    end if
    if (cache(n) < 0) then
      if (n <= 1) then
        cache(n) = int(n, int64)
      else
        cache(n) = fib_memo(n - 1) + fib_memo(n - 2)
      end if
    end if
    v = cache(n)
  end function fib_memo

  subroutine grow(cache, n)
    integer(int64), allocatable, intent(inout) :: cache(:)
    integer(int32), intent(in) :: n
    integer(int64), allocatable :: bigger(:)
    allocate (bigger(0:n))
    bigger = -1_int64
    bigger(0:ubound(cache, 1)) = cache
    call move_alloc(bigger, cache)
  end subroutine grow

  ! ---- 迭代版斐波那契：O(n) 时间 O(1) 空间，最实用 ----
  pure function fib_iter(n) result(v)
    integer(int32), intent(in) :: n
    integer(int64) :: v
    integer(int64) :: a, b, t
    integer(int32) :: i
    a = 0_int64; b = 1_int64
    do i = 1, n
      t = a + b; a = b; b = t
    end do
    v = a
  end function fib_iter

  pure function is_sorted(a) result(ok)
    integer(int32), intent(in) :: a(:)
    logical :: ok
    integer(int32) :: i
    ok = .true.
    do i = 2, size(a)
      if (a(i - 1) > a(i)) then
        ok = .false.
        return
      end if
    end do
  end function is_sorted

  ! ---- Fisher-Yates 洗牌：注意 random_number 的用法 ----
  subroutine shuffle(a)
    integer(int32), intent(inout) :: a(:)
    integer(int32) :: i, j, tmp
    real(real64) :: r
    do i = size(a), 2, -1
      call random_number(r)
      j = int(r * i) + 1          ! [1, i]
      if (j > i) j = i
      tmp = a(i); a(i) = a(j); a(j) = tmp
    end do
  end subroutine shuffle

end module algorithms

! ============================================================

program algorithms_demo
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  use algorithms
  implicit none

  integer(int32) :: v(10) = [42, 7, 19, 3, 88, 1, 55, 23, 11, 60]
  integer(int32), allocatable :: a(:), primes(:), rnd(:)
  integer(int32) :: i

  write (*, '(a,10i4)') '原始 : ', v

  ! ---- 1) 四种排序对照 ----
  a = v; call bubble_sort(a)
  write (*, '(a,10i4)') '1) 冒泡排序 : ', a

  a = v; call insertion_sort(a)
  write (*, '(a,10i4)') '   插入排序 : ', a

  a = v; call quick_sort(a, 1, size(a))
  write (*, '(a,10i4)') '   快速排序 : ', a
  write (*, '(a,l1)')   '   已有序？ : ', is_sorted(a)

  a = v; call merge_sort(a)
  write (*, '(a,10i4)') '   归并排序 : ', a
  write (*, '(a,l1)')   '   已有序？ : ', is_sorted(a)

  ! ---- 2) 二分查找：必须先有序 ----
  a = v; call quick_sort(a, 1, size(a))
  i = binary_search_rec(a, 55, 1, size(a))
  write (*, '(a,i0,a,i0,a)') '2) 二分查找 55（递归）-> 下标 ', i, '，值为 ', a(i), ''
  write (*, '(a,i0)')      '   二分查找 55（迭代）-> 下标 ', binary_search_iter(a, 55)
  write (*, '(a,i0)')      '   二分查找 99（不存在）-> 下标 ', binary_search_iter(a, 99)

  ! ---- 3) 埃氏筛法 ----
  primes = sieve(100)
  write (*, '(a,i0)') '3) 100 以内素数个数 : ', size(primes)
  write (*, '(a,25i4)') '   前 25 个 : ', primes(1:min(25, size(primes)))
  write (*, '(a,i0)')   '   最大的一个 : ', maxval(primes)

  ! ---- 4) 最大公约数 ----
  write (*, '(a,i0)') '4) gcd(1071, 462) 递归 -> ', gcd_rec(1071, 462)
  write (*, '(a,i0)') '   gcd(1071, 462) 迭代 -> ', gcd_iter(1071, 462)
  write (*, '(a,i0)') '   lcm(21, 6)          -> ', 21 * 6 / gcd_rec(21, 6)
  write (*, '(a,i0)') '   gcd(0, 5)           -> ', gcd_rec(0, 5)      ! 边界：b=0

  ! ---- 5) 汉诺塔：n 个盘子至少 2^n - 1 步 ----
  write (*, '(a,i0,a,i0,a)') '5) 汉诺塔 10 个盘子最少步数 : ', hanoi_moves(10), '（2^10-1 = ', 2**10 - 1, '）'

  ! ---- 6) 斐波那契：三种实现 ----
  write (*, '(a,i0)') '6) fib_memo(50) = ', fib_memo(50)
  write (*, '(a,i0)') '   fib_iter(50) = ', fib_iter(50)
  write (*, '(a,i0)') '   fib_iter(90) = ', fib_iter(90)     ! int64 能装下
  write (*, '(a)')    '   朴素递归 fib(50) 需要 2^50 次调用，记忆化后是线性的'

  ! ---- 7) 洗牌 ----
  allocate (rnd(10))
  rnd = [(i, i = 1, 10)]
  call shuffle(rnd)
  write (*, '(a,10i4)') '7) 洗牌后 : ', rnd
  a = rnd
  call insertion_sort(a)
  write (*, '(a,10i4)') '   排序后 : ', a

  write (*, '(a)') '==== 15 结束 ===='
end program algorithms_demo
