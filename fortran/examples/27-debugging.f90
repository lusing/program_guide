! ============================================================
! 27 - 调试与查错方法
!   三类错误（编译/运行/逻辑）各配一个活体；
!   运行错误防御：iostat、分母检查；
!   三板斧实操：状态变量 + 打印中间摘要、计数器、二分定位；
!   手写断言检查排序不变量；手写边界自查（模拟 -fcheck=bounds）
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 27-debugging.f90 -o 27-debugging
!   调试构建建议（gfortran 侧）：-g -fcheck=all -Wall -Wextra
! ============================================================

program debugging_demo
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  integer(int32) :: ios, u, n
  character(len=128) :: msg
  real(real64) :: data(6), ratio, denom

  ! ---- 1) 三类错误：一张表 + 三个活体 ----
  write (*, '(a)') '1) 三类错误：编译错误（编译期现形）、运行错误（跑到才炸）、'
  write (*, '(a)') '   逻辑错误（不炸，安静地错 —— 最危险）。下面逐个演示防御。'

  ! ---- 2) 运行错误防御之一：I/O 全带 iostat ----
  open (newunit=u, file='不存在的调试输入.dat', status='old', action='read', &
        iostat=ios, iomsg=msg)
  if (ios /= 0) then
    write (*, '(a)') '2) 打不开文件 → iostat 捕获，分支处理而不是崩：'
    write (*, '(a)') '   iostat 非 0，文件存在性检查通过、走兜底分支'
    ! 注意：iostat 的具体数值和 iomsg 文本都是编译器私有的
    ! （flang 和 gfortran 各说各话），判错只判「是否为 0」，
    ! 跨编译器比对输出时更不要打印它们 —— msg 在此仅为演示留存。
    if (len_trim(msg) == 0) write (*, '(a)') '   （iomsg 为空：本分支不该发生）'
  end if

  ! ---- 3) 运行错误防御之二：除法前查分母 ----
  denom = 0.0_real64
  if (abs(denom) < tiny(1.0_real64)) then
    write (*, '(a)') '3) 分母近零 → 拒绝除法、走兜底分支：'
    write (*, '(a)') '   ratio 未定义，本例给 0 并打日志（真实代码应返回错误码）'
    ratio = 0.0_real64
  else
    ratio = 1.0_real64 / denom
  end if
  write (*, '(a,f6.2)') '   ratio = ', ratio

  ! ---- 4) 三板斧之一：打印中间摘要，让坏数据现形 ----
  ! 下面这个「均值函数」有下标差一 bug：只累加前 n-1 个元素。
  ! 打印「函数看到的样本数」与「调用方以为的样本数」，差异即线索。
  data = [10.0_real64, 20.0_real64, 30.0_real64, 40.0_real64, 50.0_real64, 999.0_real64]
  n = size(data)
  write (*, '(a)') '4) 打印中间摘要：调用方 vs 被调函数看到的样本数'
  write (*, '(a,i0,a,f0.1)') '   调用方：n=', n, '，最后一个元素 = ', data(n)
  ! 注意调用方式：先算后写。若把 buggy_mean(data) 直接塞进 write 的
  ! 输出列表，它内部的调试打印会在外层 write 进行中再启动一次
  ! write —— 运行时炸 "Recursive I/O not allowed"（gfortran 实测）。
  ! 「会打日志的函数」永远先调用、存结果、再输出。
  block
    real(real64) :: m
    m = buggy_mean(data)
    write (*, '(a,f8.2)') '   buggy_mean 的返回值 = ', m
  end block
  write (*, '(a)') '   buggy_mean 内部日志打印「实际累加了 5 个」→ 差一现形'

  ! ---- 5) 三板斧之二：计数器 —— 循环次数对不对，一打便知 ----
  ! 插入排序内层循环的交换次数有理论对照：逆序对数。
  ! 这里数据已部分有序，交换次数应当远小于 n²/4（随机数据的期望）。
  block
    integer(int32) :: a(6) = [5, 1, 4, 2, 8, 9]
    integer(int32) :: swaps, passes
    call insertion_sort_count(a, swaps, passes)
    write (*, '(a)') '5) 计数器：插入排序的交换次数与轮次'
    write (*, '(a,6i4)') '   排序结果 = ', a
    write (*, '(a,i0,a,i0,a)') '   交换 ', swaps, ' 次、外层跑了 ', passes, &
         ' 轮（初始逆序对 = (5,1)(5,4)(5,2)(4,2) 共 4 个，交换 4 次，对得上）'
  end block

  ! ---- 6) 三板斧之三：二分定位 —— 可观察现象在哪个半段变坏 ----
  ! 演示思路：流水线三个阶段，每阶段打印「输出摘要」，坏在哪段一目了然。
  block
    real(real64) :: v(3)
    v = [1.0_real64, 2.0_real64, 3.0_real64]
    write (*, '(a)') '6) 二分定位的前置：每阶段都留一个可打印的量'
    call stage1(v);  write (*, '(a,3f8.2)') '   stage1 后 max=', maxval(v)
    call stage2(v);  write (*, '(a,3f8.2)') '   stage2 后 max=', maxval(v)
    call stage3(v);  write (*, '(a,3f8.2)') '   stage3 后 max=', maxval(v)
    write (*, '(a)') '   哪一行先变得不合理，bug 就在该阶段与其上一行之间'
  end block

  ! ---- 7) 逻辑错误的防线：断言检查「不变量」 ----
  block
    integer(int32) :: sorted(6) = [1, 2, 4, 5, 8, 9]
    write (*, '(a,6i3)') '7) 断言检查对象：', sorted
    if (.not. is_sorted(sorted)) then
      write (*, '(a)') '   断言失败：排序不变量被破坏'
      stop 1
    else
      write (*, '(a)') '   断言通过：all(sorted(1:n-1) <= sorted(2:n)) 成立'
    end if
  end block

  ! ---- 8) 手写边界自查：把 gfortran -fcheck=bounds 的活干一遍 ----
  ! flang 23 没有运行时边界检查（差异清单第 5 条），关键代码自己查：
  block
    real(real64) :: buf(4)
    integer(int32) :: idx
    idx = 5                                  ! 故意越界
    if (idx < lbound(buf, 1) .or. idx > ubound(buf, 1)) then
      write (*, '(a,i0,a,i0,a,i0,a)') '8) 边界自查：idx=', idx, ' 越界（[', &
           lbound(buf, 1), ',', ubound(buf, 1), ']），拒绝访问'
    else
      buf(idx) = 1.0_real64
    end if
    write (*, '(a)') '   这就是 -fcheck=bounds 每次数组访问做的事 —— 只是它免费'
  end block

  write (*, '(a)') '==== 27 结束 ===='

contains

  ! 带 bug 的均值：do 2, n 漏了第一个元素（差一 bug 的经典形态）
  real(real64) function buggy_mean(x) result(m)
    real(real64), intent(in) :: x(:)
    integer(int32) :: k, cnt
    real(real64) :: s
    cnt = 0
    s = 0.0_real64
    do k = 2, size(x)                        ! ← bug：应从 1 开始
      s = s + x(k)
      cnt = cnt + 1
    end do
    ! 调试打印（三板斧之一）：函数自己交代它看到了什么
    write (*, '(a,i0,a,i0,a)') '   buggy_mean 内部：实际累加了 ', cnt, &
         ' 个元素（调用方给了 ', size(x), ' 个）'
    m = s / real(cnt, real64)
  end function buggy_mean

  ! 插入排序 + 交换/轮次计数
  subroutine insertion_sort_count(a, swaps, passes)
    integer(int32), intent(inout) :: a(:)
    integer(int32), intent(out) :: swaps, passes
    integer(int32) :: i, j, tmp
    swaps = 0
    passes = 0
    do i = 2, size(a)
      passes = passes + 1
      j = i
      do while (j > 1 .and. a(j) < a(j - 1))
        tmp = a(j); a(j) = a(j - 1); a(j - 1) = tmp
        swaps = swaps + 1
        j = j - 1
      end do
    end do
  end subroutine insertion_sort_count

  ! 三个「流水线阶段」：演示留痕式打印
  subroutine stage1(v)
    real(real64), intent(inout) :: v(:)
    v = v + 1.0_real64
  end subroutine stage1
  subroutine stage2(v)
    real(real64), intent(inout) :: v(:)
    v = v * 2.0_real64
  end subroutine stage2
  subroutine stage3(v)
    real(real64), intent(inout) :: v(:)
    v = v - 0.5_real64
  end subroutine stage3

  ! 排序不变量
  logical pure function is_sorted(a)
    integer(int32), intent(in) :: a(:)
    is_sorted = all(a(1:size(a)-1) <= a(2:size(a)))
  end function is_sorted

end program debugging_demo
