# 第 25 章 · 随机数与统计

对应示例：`17-random.f90`

### 标准随机数接口

```fortran
real(real64) :: r
call random_seed()          ! 用当前时间初始化（实现相关）
call random_number(r)       ! [0,1) 的均匀分布
call random_number(arr)     ! 数组一次填满
```

### 保底：先问尺寸

```fortran
integer :: n
integer, allocatable :: seed(:)
call random_seed(size=n)
allocate (seed(n))
call random_seed(get=seed)
! ... 想固定实验可复现，就 seed = 42；想把种子打印出来留着，就 write(*,*) seed
call random_seed(put=seed)
```

**`random_seed(size=n)` 返回的 `n` 两个编译器不一样**：

| 编译器 | `n` |
|---|---|
| flang 23 | 1 |
| gfortran 15 | 8 |

所以示例 17 的「把种子打印出来」这一行没法做到跨编译器一致，被列进了已知差异。

**不要假设 `n` 是某个固定值**，也**不要手写种子值除非你确定尺寸** —— `seed` 数组长度不对会报错或行为未定义。

### 想要可复现的随机数

`random_number` 的实现是编译器相关的，**同一份代码在两个编译器上会给出不同的随机序列**。要严格复现，只能：

1. 固定 `seed`（但序列仍在不同编译器间不同），或
2. **自己写一个确定性发生器**

示例 17 里就手写了一个 LCG（线性同余发生器）：

```fortran
module lcg
  implicit none
  integer(int64), parameter :: A = 6364136223846793005_int64
  integer(int64), parameter :: C = 1442695040888963407_int64
  integer(int64) :: state = 12345_int64
contains
  subroutine lcg_seed(s)
    integer(int64), intent(in) :: s
    state = s
  end subroutine
  pure real(real64) function lcg_next() result(r)
    state = A * state + C
    r = real(ishft(state, -11), real64) / real(2_int64 ** 53, real64)
  end function
end module
```

**这个序列是跨编译器完全一致的**，因为它是纯整数运算。需要「两边跑出一样的结果」时，用这个。

（当然，LCG 的统计质量一般，正经蒙特卡洛还是用 `random_number`。）

### 常见分布的生成

**正态分布 —— Box-Muller 变换**：

```fortran
pure function randn() result(z)
  real(real64) :: z, u1, u2
  call random_number(u1)
  call random_number(u2)
  z = sqrt(-2.0_real64 * log(u1)) * cos(2.0_real64 * 3.14159265358979323846_real64 * u2)
end function
```

**指数分布**：`-log(u) / lambda`。**均匀整数**：`floor(u * n) + 1`。

### 蒙特卡洛

```fortran
! 用随机点估 π：落在单位圆内的比例 × 4
integer :: inside = 0
real(real64) :: x, y
do i = 1, n
  call random_number(x); call random_number(y)
  if (x*x + y*y <= 1.0_real64) inside = inside + 1
end do
pi_est = 4.0_real64 * real(inside, real64) / real(n, real64)
```

误差按 `1/sqrt(n)` 收敛 —— 所以要想多一位精度，样本量得翻 100 倍。示例里打印了不同 `n` 下的估计值和实际误差，能直观看到这个规律。

同理可以估积分：`∫f` ≈ 区间长度 × `f` 在随机点上的均值。

### 描述统计

```fortran
mean     = sum(x) / size(x)
variance = sum((x - mean)**2) / (size(x) - 1)        ! 样本方差，注意是 n-1
stddev   = sqrt(variance)
```

**注意 `n` 还是 `n-1`**：总体方差除以 `n`，样本方差除以 `n-1`（贝塞尔修正）。写代码时明确一下你要哪个，别到论文里才发现。

中位数、分位数用手写的排序：

```fortran
pure function median(x) result(m)
  real(real64), intent(in) :: x(:)
  real(real64) :: m
  real(real64), allocatable :: s(:)
  integer :: n
  s = x                                     ! 拷贝，别改调用者的数组
  call insertion_sort_r(s)
  n = size(s)
  if (mod(n, 2) == 1) then
    m = s((n + 1) / 2)
  else
    m = (s(n / 2) + s(n / 2 + 1)) / 2.0_real64
  end if
end function
```

偏度、峰度按标准公式算。相关系数用 Pearson：

```fortran
r = sum((x - mx) * (y - my)) / (sqrt(sum((x-mx)**2)) * sqrt(sum((y-my)**2)))
```

### 统计的数值稳定陷阱

朴素的方差公式 `E[x²] - E[x]²` 在数据均值很大时会**灾难性抵消**：

```fortran
! 危险：x = 1e8 + 随机小量时，这两个大数相减会丢掉所有有效位
variance = sum(x**2)/n - (sum(x)/n)**2

! 安全：两步法（先算均值，再算偏差平方和）
mean = sum(x) / n
variance = sum((x - mean)**2) / n
```

示例 17 里两种都算了，能看出差别。

---

上一章：[第 24 章 常微分方程数值解](24-ode.md) ｜ 下一章：[第 26 章 C 互操作](26-c-interop.md) ｜ 返回：[README](../README.md)
