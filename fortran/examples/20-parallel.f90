! ============================================================
! 20 - 并行计算（OpenMP + do concurrent）
!   !$omp 指令、reduction、private/firstprivate、atomic、critical、
!   schedule(static/dynamic/guided)、num_threads、parallel sections、
!   omp_get_wtime 计时与加速比、数据竞争演示、F2018 的 do concurrent
!
! 编译（必须带 -fopenmp，否则链接不到 OpenMP 运行时）：
!   flang-mp-23 -std=f2018 -pedantic -fopenmp -O2 20-parallel.f90 -o 20-parallel
!   gfortran-mp-15 -std=f2018 -pedantic -fopenmp -O2 20-parallel.f90 -o 20-parallel
!
! 线程数用环境变量控制：
!   OMP_NUM_THREADS=8 ./20-parallel
!
! 【差异 1】flang 不带 omp_lib 模块（gfortran 带）。所以本示例不用
!           use omp_lib，而是用 bind(c) 显式接口直接绑 OpenMP 运行时
!           的 C 符号。同一份源码两个编译器都能过。
!
! 【差异 2 · flang 的坑】flang 23 不支持对「block 构造内声明的变量」使用
!           !$omp atomic 和 do concurrent 的 locality-spec：
!             block
!               integer :: cnt = 0
!               !$omp atomic
!               cnt = cnt + 1        ← flang 报错，gfortran 正常
!             end block
!           所以本示例把所有并行累加器都声明在程序作用域，不放进 block。
!           完整的最小复现在 README 的「flang vs gfortran 差异清单」里。
!
! 本示例第 9 节含墙钟计时，输出不保证逐字节可复现。
! ============================================================

module omprt
  ! OpenMP 运行时接口。omp_lib 在 flang 里不存在，所以自己绑 C 符号。
  use, intrinsic :: iso_c_binding
  implicit none
  public :: omp_get_max_threads, omp_get_num_threads, omp_get_thread_num
  public :: omp_get_wtime, omp_set_num_threads, omp_in_parallel

  interface
    ! 接口块内的名字不会自动继承宿主的 use 关联，必须显式 import
    integer(c_int) function omp_get_max_threads() bind(c, name='omp_get_max_threads')
      import :: c_int
    end function omp_get_max_threads

    integer(c_int) function omp_get_num_threads() bind(c, name='omp_get_num_threads')
      import :: c_int
    end function omp_get_num_threads

    integer(c_int) function omp_get_thread_num() bind(c, name='omp_get_thread_num')
      import :: c_int
    end function omp_get_thread_num

    real(c_double) function omp_get_wtime() bind(c, name='omp_get_wtime')
      import :: c_double
    end function omp_get_wtime

    subroutine omp_set_num_threads(n) bind(c, name='omp_set_num_threads')
      import :: c_int
      integer(c_int), value :: n
    end subroutine omp_set_num_threads

    integer(c_int) function omp_in_parallel() bind(c, name='omp_in_parallel')
      import :: c_int
    end function omp_in_parallel

  end interface

end module omprt

! ============================================================

program parallel_demo
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  use omprt
  implicit none

  integer(int32), parameter :: n = 20000000_int32

  integer(int32) :: i
  integer(int32) :: n_inside, n_serial
  integer(int64) :: sum64, sum_seq, cnt64, total64, shared_cnt
  integer(int64) :: sa, sb, sc
  integer(int64) :: r1, r2, r3, r4
  integer(int64) :: bad
  integer(int32) :: sq(16), hi, k, local_k, fp_val
  real(real64) :: t0, t1, tseq, tpar
  real(real64), allocatable :: a(:)
  logical :: ok

  write (*, '(a,i0)') '0) 可见逻辑核心数 omp_get_max_threads() = ', omp_get_max_threads()
  write (*, '(a)')    '   线程数可用环境变量 OMP_NUM_THREADS 覆盖'

  ! ---- 1) 最简单的 parallel 区：每个线程都执行一遍，线程号不同 ----
  n_inside = 0
  n_serial = 0
  !$omp parallel num_threads(4)
  !$omp single
  n_inside = omp_get_num_threads()          ! single 段只有一个线程执行
  !$omp end single
  !$omp end parallel
  n_serial = omp_get_num_threads()          ! 并行区外永远是 1
  write (*, '(a,i0,a,i0)') '1) num_threads(4)：并行区内实际线程数 = ', n_inside, &
    '，并行区外 = ', n_serial
  write (*, '(a,i0)') '   omp_in_parallel() 在串行区 = ', omp_in_parallel()

  ! ---- 2) parallel do + reduction：唯一「不加锁还正确」的累加方式 ----
  sum64 = 0_int64
  !$omp parallel do reduction(+:sum64) schedule(static)
  do i = 1, 1000000_int32
    sum64 = sum64 + int(i, int64)
  end do
  !$omp end parallel do
  write (*, '(a,i0)') '2) reduction 求和 = ', sum64
  write (*, '(a,l1)') '   与串行真值 500000500000 一致？ ', sum64 == 500000500000_int64

  ! ---- 3) atomic：单个内存位置的自增，硬件级别原子 ----
  cnt64 = 0_int64
  !$omp parallel do num_threads(4)
  do i = 1, 100000_int32
    !$omp atomic
    cnt64 = cnt64 + 1_int64
  end do
  !$omp end parallel do
  write (*, '(a,i0,a,l1)') '3) atomic 计数 = ', cnt64, '，等于 100000 ？ ', cnt64 == 100000_int64

  ! ---- 4) critical：一段代码同时只有一个线程能进 ----
  total64 = 0_int64
  !$omp parallel num_threads(4)
  !$omp do
  do i = 1, 10000_int32
    !$omp critical
    total64 = total64 + int(i, int64)
    !$omp end critical
  end do
  !$omp end do
  !$omp end parallel
  write (*, '(a,i0,a,l1)') '4) critical 求和 = ', total64, '，正确 ？ ', total64 == 50005000_int64
  write (*, '(a)') '   atomic 只保护「一个变量的一次更新」，critical 保护任意代码块'

  ! ---- 5) private / firstprivate / shared ----
  shared_cnt = 0_int64
  fp_val = 7
  !$omp parallel do private(local_k, k) firstprivate(fp_val) shared(shared_cnt)
  do i = 1, 8_int32
    local_k = i * 10
    k = local_k + fp_val                ! fp_val 每个线程各拿一份初值 7
    !$omp atomic
    shared_cnt = shared_cnt + int(k, int64)
  end do
  !$omp end parallel do
  write (*, '(a,i0)') '5) private + firstprivate 累加 = ', shared_cnt
  write (*, '(a,i0)') '   真值 sum(i*10+7, i=1..8) = ', 8 * 9 / 2 * 10 + 8 * 7
  write (*, '(a)')    '   private 的初值未定义（别依赖），firstprivate 会拷贝进线程'

  ! ---- 6) schedule(static) vs schedule(dynamic) vs guided ----
  sa = 0_int64; sb = 0_int64; sc = 0_int64
  !$omp parallel do reduction(+:sa) schedule(static)
  do i = 1, 100000_int32
    sa = sa + int(i, int64)
  end do
  !$omp end parallel do
  !$omp parallel do reduction(+:sb) schedule(dynamic, 1000)
  do i = 1, 100000_int32
    sb = sb + int(i, int64)
  end do
  !$omp end parallel do
  !$omp parallel do reduction(+:sc) schedule(guided)
  do i = 1, 100000_int32
    sc = sc + int(i, int64)
  end do
  !$omp end parallel do
  write (*, '(a,3i14)') '6) static/dynamic/guided 三种调度的结果 = ', sa, sb, sc
  write (*, '(a,l1)')   '   三者必须完全相同 ？ ', sa == sb .and. sb == sc
  write (*, '(a)')      '   静态调度按线程切块（开销小）；动态调度谁空谁领（负载均衡好）'

  ! ---- 7) parallel sections：不同任务分给不同线程，天然无数据竞争 ----
  r1 = 0_int64; r2 = 0_int64; r3 = 0_int64; r4 = 0_int64
  !$omp parallel sections num_threads(4)
  !$omp section
  r1 = sum([(int(i, int64), i = 1, 100000)])
  !$omp section
  r2 = sum([(int(i, int64) * i, i = 1, 1000)])
  !$omp section
  r3 = count([(mod(i, 3), i = 1, 10000)] == 0)
  !$omp section
  r4 = 42_int64
  !$omp end parallel sections
  write (*, '(a,i0,a,i0,a,i0,a,i0)') '7) sections: r1=', r1, ' r2=', r2, ' r3=', r3, ' r4=', r4
  write (*, '(a)') '   四个任务互不依赖，各自写自己的变量，不需要加锁'

  ! ---- 8) 数据竞争：不用 reduction 会丢结果 ----
  !      这里不打印那个错误值（它每次都不一样），只演示正确写法
  bad = 0_int64
  !$omp parallel do num_threads(4) reduction(+:bad)
  do i = 1, 1000000_int32
    bad = bad + int(i, int64)
  end do
  !$omp end parallel do
  write (*, '(a,i0)') '8) 正确写法（reduction）= ', bad
  write (*, '(a)')    '   把 reduction 去掉、直接写 bad = bad + i，多个线程会互相覆盖，'
  write (*, '(a)')    '   结果偏小且每次运行都不同 —— 这就是数据竞争（race condition）'
  write (*, '(a)')    '   此处故意不打印那个错值：不可复现本身就是问题的一部分'

  ! ---- 9) 计时与加速比（含墙钟时间，输出不保证可复现）----
  allocate (a(n))
  do i = 1, n
    a(i) = 1.0_real64 / real(i, real64)
  end do
  t0 = omp_get_wtime()
  sum_seq = 0_int64
  do i = 1, n
    sum_seq = sum_seq + int(a(i) * 1000.0_real64, int64)
  end do
  t1 = omp_get_wtime()
  tseq = t1 - t0

  t0 = omp_get_wtime()
  sum64 = 0_int64
  !$omp parallel do reduction(+:sum64) schedule(static)
  do i = 1, n
    sum64 = sum64 + int(a(i) * 1000.0_real64, int64)
  end do
  !$omp end parallel do
  t1 = omp_get_wtime()
  tpar = t1 - t0

  write (*, '(a,es12.4,a,es12.4,a)') '9) 串行耗时 ', tseq, ' 秒，并行耗时 ', tpar, ' 秒'
  ok = (sum_seq == sum64)
  write (*, '(a,l1)') '   串行与并行结果一致？ ', ok
  write (*, '(a,f0.2,a,i0,a)') '   加速比 ≈ ', tseq / max(tpar, 1.0e-9_real64), &
    '×（逻辑核心 ', omp_get_max_threads(), ' 个）'

  ! ---- 10) F2018 的 do concurrent：语言级并行，交给编译器 ----
  sq = 0
  do concurrent (i = 1:16)
    sq(i) = i * i
  end do
  write (*, '(a,16i5)') '10) do concurrent 求平方 : ', sq
  ! 带 locality 说明：编译器据此自动并行化
  hi = 0
  do concurrent (i = 1:16) local(hi)
    hi = i * 10
  end do
  write (*, '(a,i0)') '    local(hi) 声明临时变量只在本迭代内有效，hi 退出后仍是 ', hi
  write (*, '(a)')    '    没开 -fopenmp 时它就是普通串行循环，开了就可能被并行化'
  write (*, '(a)')    '    flang 要求 local() 里的变量声明在 block 之外，见文件头【差异 2】'

  write (*, '(a)') '==== 20 结束 ===='
end program parallel_demo
