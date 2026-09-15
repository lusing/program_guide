! ============================================================
! 17 - 随机数与统计
!   random_seed / random_number、均匀分布与直方图、Box-Muller 造
!   正态分布、蒙特卡洛估 π 与定积分、中心极限定理、Fisher-Yates
!   抽样、离散分布轮盘赌抽样、统计量（均值/方差/中位数/分位数/
!   偏度/峰度/相关系数）、手写 LCG 对比内置随机数
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 17-random.f90 -o 17-random
!   gfortran-mp-15 -std=f2018 -pedantic 17-random.f90 -o 17-random
! ============================================================

module stats
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none
  private
  public :: mean, variance, stddev, median, quantile, skewness, kurtosis, &
            corrcoef, histogram, uniform, normal_bm, shuffle_idx, &
            sample_discrete, lcg_next, lcg_seed, variance_pop

  ! 手写线性同余发生器（LCG）的状态
  integer(int64) :: lcg_state = 12345_int64

contains

  pure function mean(x) result(m)
    real(real64), intent(in) :: x(:)
    real(real64) :: m
    m = sum(x) / real(size(x), real64)
  end function mean

  ! 样本方差（除以 n-1，无偏估计）
  function variance(x) result(v)
    real(real64), intent(in) :: x(:)
    real(real64) :: v, m
    m = mean(x)
    v = sum((x - m)**2) / real(size(x) - 1, real64)
  end function variance

  ! 总体方差（除以 n）
  pure function variance_pop(x) result(v)
    real(real64), intent(in) :: x(:)
    real(real64) :: v, m
    m = mean(x)
    v = sum((x - m)**2) / real(size(x), real64)
  end function variance_pop

  function stddev(x) result(s)
    real(real64), intent(in) :: x(:)
    real(real64) :: s
    s = sqrt(variance(x))
  end function stddev

  ! 中位数：偶数个取中间两个的平均
  function median(x) result(m)
    real(real64), intent(in) :: x(:)
    real(real64) :: m
    real(real64), allocatable :: s(:)
    integer(int32) :: n
    n = size(x)
    allocate (s(n))
    s = x
    call sort_real(s)
    if (mod(n, 2) == 1) then
      m = s((n + 1) / 2)
    else
      m = 0.5_real64 * (s(n / 2) + s(n / 2 + 1))
    end if
  end function median

  ! 分位数：p ∈ [0,1]，用线性插值（与 numpy.percentile 默认一致）
  function quantile(x, p) result(q)
    real(real64), intent(in) :: x(:), p
    real(real64) :: q, pos
    real(real64), allocatable :: s(:)
    integer(int32) :: n, lo, hi
    n = size(x)
    allocate (s(n))
    s = x
    call sort_real(s)
    pos = p * real(n - 1, real64) + 1.0_real64
    lo = int(pos)
    if (lo >= n) then
      q = s(n)
      return
    end if
    hi = lo + 1
    q = s(lo) + (pos - real(lo, real64)) * (s(hi) - s(lo))
  end function quantile

  function skewness(x) result(g)
    real(real64), intent(in) :: x(:)
    real(real64) :: g, m, s
    m = mean(x)
    s = stddev(x)
    if (s <= 0.0_real64) then
      g = 0.0_real64
      return
    end if
    g = sum(((x - m) / s)**3) / real(size(x), real64)
  end function skewness

  ! 超额峰度：正态分布为 0
  function kurtosis(x) result(k)
    real(real64), intent(in) :: x(:)
    real(real64) :: k, m, s
    m = mean(x)
    s = stddev(x)
    if (s <= 0.0_real64) then
      k = 0.0_real64
      return
    end if
    k = sum(((x - m) / s)**4) / real(size(x), real64) - 3.0_real64
  end function kurtosis

  function corrcoef(x, y) result(r)
    real(real64), intent(in) :: x(:), y(:)
    real(real64) :: r, mx, my, sx, sy
    if (size(x) /= size(y) .or. size(x) < 2) then
      r = 0.0_real64
      return
    end if
    mx = mean(x); my = mean(y)
    sx = sqrt(sum((x - mx)**2)); sy = sqrt(sum((y - my)**2))
    if (sx * sy == 0.0_real64) then
      r = 0.0_real64
    else
      r = sum((x - mx) * (y - my)) / (sx * sy)
    end if
  end function corrcoef

  ! 直方图：返回每个区间的计数
  function histogram(x, lo, hi, nbins) result(cnt)
    real(real64), intent(in) :: x(:), lo, hi
    integer(int32), intent(in) :: nbins
    integer(int32), allocatable :: cnt(:)
    integer(int32) :: i, b
    real(real64) :: w
    allocate (cnt(nbins))
    cnt = 0
    w = (hi - lo) / real(nbins, real64)
    do i = 1, size(x)
      if (x(i) < lo .or. x(i) >= hi) cycle
      b = int((x(i) - lo) / w) + 1
      if (b < 1) b = 1
      if (b > nbins) b = nbins
      cnt(b) = cnt(b) + 1
    end do
  end function histogram

  ! 生成 [0,1) 均匀随机数
  function uniform() result(r)
    real(real64) :: r
    call random_number(r)
  end function uniform

  ! Box-Muller：两个独立均匀数造一个标准正态数
  function normal_bm() result(z)
    real(real64) :: z, u1, u2
    call random_number(u1)
    call random_number(u2)
    if (u1 < 1.0e-300_real64) u1 = 1.0e-300_real64     ! 防 log(0)
    z = sqrt(-2.0_real64 * log(u1)) * cos(2.0_real64 * 3.14159265358979_real64 * u2)
  end function normal_bm

  ! Fisher-Yates 洗牌（返回下标置换）
  function shuffle_idx(n) result(p)
    integer(int32), intent(in) :: n
    integer(int32), allocatable :: p(:)
    integer(int32) :: i, j, t
    real(real64) :: r
    allocate (p(n))
    p = [(i, i = 1, n)]
    do i = n, 2, -1
      call random_number(r)
      j = int(r * real(i, real64)) + 1
      if (j > i) j = i
      t = p(i); p(i) = p(j); p(j) = t
    end do
  end function shuffle_idx

  ! 按给定权重做轮盘赌抽样，返回被选中的下标
  function sample_discrete(w) result(k)
    real(real64), intent(in) :: w(:)
    integer(int32) :: k, i
    real(real64) :: r, acc, total
    total = sum(w)
    call random_number(r)
    r = r * total
    acc = 0.0_real64
    k = size(w)
    do i = 1, size(w)
      acc = acc + w(i)
      if (r <= acc) then
        k = i
        return
      end if
    end do
  end function sample_discrete

  ! ---- 手写 LCG 对照：rand = (a*seed + c) mod m ----
  !      这是历史上最常用的伪随机算法之一（Numerical Recipes 版本）
  subroutine lcg_seed(s)
    integer(int64), intent(in) :: s
    lcg_state = s
  end subroutine lcg_seed

  function lcg_next() result(r)
    real(real64) :: r
    integer(int64), parameter :: a = 1664525_int64
    integer(int64), parameter :: c = 1013904223_int64
    integer(int64), parameter :: m = 4294967296_int64       ! 2^32
    lcg_state = mod(a * lcg_state + c, m)
    r = real(lcg_state, real64) / real(m, real64)
  end function lcg_next

  ! 内部工具：简单的希尔排序（避免依赖 15 的模块）
  subroutine sort_real(a)
    real(real64), intent(inout) :: a(:)
    integer(int32) :: i, j, gap, n
    real(real64) :: key
    n = size(a)
    gap = n / 2
    do while (gap > 0)
      do i = gap + 1, n
        key = a(i)
        j = i - gap
        do while (j >= 1)
          if (a(j) <= key) exit
          a(j + gap) = a(j)
          j = j - gap
        end do
        a(j + gap) = key
      end do
      gap = gap / 2
    end do
  end subroutine sort_real

end module stats

! ============================================================

program random_demo
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  use stats
  implicit none

  integer(int32), parameter :: n = 100000
  integer(int32), parameter :: nclt = 30          ! CLT 每组样本数
  integer(int32), parameter :: nrep = 20000       ! CLT 重复次数
  real(real64), allocatable :: u(:), ubig(:), g(:), x(:), y(:), sums(:)
  integer(int32), allocatable :: cnt(:), perm(:)
  real(real64) :: pi_est, est
  integer(int32) :: i, k, seed_size
  integer(int32), allocatable :: seed(:)
  real(real64), allocatable :: ws(:)

  ! ---- 0) 固定种子，让结果可复现 ----
  call random_seed(size=seed_size)
  allocate (seed(seed_size))
  seed = 20260915
  call random_seed(put=seed)
  write (*, '(a,i0)') '0) 随机数种子长度 = ', seed_size
  write (*, '(a,i0)') '   将种子固定为 20260915，输出可复现'
  call random_seed(get=seed)
  write (*, '(a,i0)') '   取出当前种子（各编译器的种子长度不同，flang=1，gfortran=8） : ', seed(1)
  write (*, '(a)')    '   所以「固定种子后输出逐字节一致」只在同一编译器内成立'

  ! ---- 1) 均匀分布：验证均值≈0.5、方差≈1/12 ----
  allocate (u(n))
  call random_number(u)
  write (*, '(a,f0.6,a,f0.6)') '1) 均匀分布 n=100000：均值 ', mean(u), '（期望 0.5）'
  write (*, '(a,f0.6,a,f0.6)') '   方差 ', variance_pop(u), '（期望 0.083333）'
  write (*, '(a,f0.6,a,f0.6)') '   最小值 / 最大值 : ', minval(u), ' / ', maxval(u)

  ! ---- 2) 直方图：分成 10 个桶，应该每桶约 1/10 ----
  cnt = histogram(u, 0.0_real64, 1.0_real64, 10)
  write (*, '(a)') '2) 10 桶直方图（每桶期望 10000）'
  do i = 1, 10
    write (*, '(a,i2,a,i2,a,i6,a,a)') '   [', i - 1, '/10, ', i, '/10) : ', &
      cnt(i), ' ', repeat('*', cnt(i) / 500)
  end do

  ! ---- 3) 蒙特卡洛估 π：往正方形里撒点，落在内切圆的比例 = π/4 ----
  allocate (x(n), y(n))
  call random_number(x)
  call random_number(y)
  k = count((x - 0.5_real64)**2 + (y - 0.5_real64)**2 <= 0.25_real64)
  pi_est = 4.0_real64 * real(k, real64) / real(n, real64)
  write (*, '(a,f0.6,a,f0.6,a)') '3) 蒙特卡洛估 π = ', pi_est, '（真值 ', acos(-1.0_real64), '）'
  write (*, '(a,es12.4)')      '   绝对误差 = ', abs(pi_est - acos(-1.0_real64))
  write (*, '(a)')             '   误差量级 ~ 1/sqrt(n)，对 n=1e5 大约 3e-3'

  ! ---- 4) 蒙特卡洛算定积分 ∫₀¹ 4/(1+x²) dx = π ----
  est = sum(4.0_real64 / (1.0_real64 + x**2)) / real(n, real64)
  write (*, '(a,f0.8)') '4) 蒙特卡洛积分 4/(1+x²) 在 [0,1] = ', est
  write (*, '(a,es12.4)') '   与 π 的差 = ', abs(est - acos(-1.0_real64))

  ! ---- 5) Box-Muller 造正态分布：验证均值 0、方差 1、偏度 0、峰度 0 ----
  allocate (g(n))
  do i = 1, n
    g(i) = normal_bm()
  end do
  write (*, '(a,f0.5,a,f0.5)') '5) 标准正态：均值 ', mean(g), '（期望 0）'
  write (*, '(a,f0.5,a,f0.5)') '   标准差 ', stddev(g), '（期望 1）'
  write (*, '(a,f0.5,a,f0.5)') '   偏度 ', skewness(g), '（期望 0）'
  write (*, '(a,f0.5)')        '   超额峰度 ', kurtosis(g)
  write (*, '(a,f0.5,a,f0.5)') '   中位数 ', median(g), '  1% 分位 ', quantile(g, 0.01_real64)
  write (*, '(a,f0.5,a,f0.5)') '   99% 分位 ', quantile(g, 0.99_real64), '（正态理论值 ±2.326）'

  ! ---- 6) 中心极限定理：均匀分布取 n 个求均值，均值分布趋于正态 ----
  write (*, '(a,i0,a,i0,a)') '6) 中心极限定理：每次取 ', nclt, ' 个均匀数求平均，重复 ', nrep, ' 次'
  allocate (ubig(nclt * nrep), sums(nrep))
  call random_number(ubig)
  do i = 1, nrep
    sums(i) = mean(ubig(1 + (i - 1) * nclt:i * nclt))
  end do
  write (*, '(a,f0.6,a,f0.6)') '   均值 ', mean(sums), '（期望 0.5）'
  write (*, '(a,f0.6,a,f0.6,a)') '   标准差 ', stddev(sums), '（理论 1/sqrt(12*30) = ', &
    1.0_real64 / sqrt(12.0_real64 * real(nclt, real64)), '）'
  write (*, '(a)')             '   均匀分布原本是平顶的，求平均后出现了钟形'

  ! ---- 7) 抽样与洗牌 ----
  perm = shuffle_idx(10)
  write (*, '(a,10i4)') '7) 1..10 的随机置换 : ', perm
  allocate (ws(4))
  ws = [1.0_real64, 1.0_real64, 1.0_real64, 7.0_real64]   ! 第 4 项权重是别人的 7 倍
  cnt = 0
  do i = 1, 20
    call bump(sample_discrete(ws), cnt)
  end do
  write (*, '(a,4i6)') '   权重 [1,1,1,7] 抽 20 次计数 : ', cnt(1:4)
  write (*, '(a)')     '   第 4 类占比应明显更高'

  ! ---- 8) 相关系数 ----
  write (*, '(a,f0.6)') '8) corrcoef(x, y) 相关（x 与 x² 同向但非线性） : ', corrcoef(x, x**2)
  write (*, '(a,f0.6)') '   corrcoef(x, x) 完全相关 : ', corrcoef(x, x)

  ! ---- 9) 手写 LCG vs 内置随机数：质量对比 ----
  write (*, '(a)') '9) 手写 LCG（Numerical Recipes 参数）对照内置算法'
  call lcg_seed(42_int64)
  ! 注意：对已分配的数组再 allocate 是非法的（gfortran 会运行时报错，
  !       flang 会宽容地先释放再分配）—— 要显式 deallocate
  deallocate (u)
  allocate (u(n))
  do i = 1, n
    u(i) = lcg_next()
  end do
  write (*, '(a,f0.6,a,f0.6)') '   LCG  均值 ', mean(u), '  方差 ', variance_pop(u)
  call random_seed(put=seed)
  call random_number(u)
  write (*, '(a,f0.6,a,f0.6)') '   内置 均值 ', mean(u), '  方差 ', variance_pop(u)
  write (*, '(a)')             '   LCG 的均值/方差也不差，但低位周期短 —— 别用它做加密或高精度模拟'

  write (*, '(a)') '==== 17 结束 ===='

contains

  subroutine bump(kk, arr)
    integer(int32), intent(in) :: kk
    integer(int32), intent(inout) :: arr(:)
    if (kk >= 1 .and. kk <= size(arr)) arr(kk) = arr(kk) + 1
  end subroutine bump

end program random_demo
