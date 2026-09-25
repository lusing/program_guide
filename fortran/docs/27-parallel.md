# 第 27 章 · 并行计算：OpenMP 与 do concurrent

对应示例：`20-parallel.f90`

### 两种并行写法

```fortran
! 1. OpenMP 指令（编译器扩展，标准外）
!$omp parallel do reduction(+:total)
do i = 1, n
  total = total + f(i)
end do
!$omp end parallel do

! 2. do concurrent（F2008 标准内，编译器自己决定怎么并行）
do concurrent (i = 1:n)
  a(i) = f(i)
end do
```

`do concurrent` 的好处是不依赖 OpenMP，任何编译器都能编；坏处是**并行与否由编译器决定** —— 本仓库的两个编译器在默认参数下都不会真的把它并行化。

### OpenMP 常用指令

```fortran
!$omp parallel do num_threads(4) schedule(static)
do i = 1, n
  ...
end do

!$omp parallel do reduction(+:sum) private(tmp)
do i = 1, n
  tmp = compute(i)
  sum = sum + tmp
end do

!$omp critical
counter = counter + 1
!$omp end critical

!$omp atomic
cnt = cnt + 1
!$omp end atomic

!$omp parallel sections
!$omp section
call task_a()
!$omp section
call task_b()
!$omp end parallel sections
```

### schedule 的选择

| 策略 | 适用 |
|---|---|
| `static` | 每次迭代耗时均匀 |
| `dynamic` | 耗时差异大，负载均衡优先 |
| `guided` | 介于两者，块大小递减 |

示例里对同一个循环用三种策略各跑一遍并计时。

### 计时

```fortran
use, intrinsic :: iso_c_binding, only: c_double
interface
  function omp_get_wtime() bind(c, name='omp_get_wtime') result(t)
    import :: c_double
    real(c_double) :: t
  end function
end interface
```

**为什么不用 `omp_lib`？** 因为 **flang 23 没有这个模块**（第 32 章第 4 条）。`use omp_lib` 在 flang 上直接编译失败：

```
error: Cannot parse module file for module 'omp_lib'
```

解法是自己写一个薄封装：

```fortran
module omprt
  use, intrinsic :: iso_c_binding, only: c_int, c_double
  implicit none
  interface
    function omp_get_wtime() bind(c, name='omp_get_wtime') result(t)
      import :: c_double
      real(c_double) :: t
    end function
    function omp_get_max_threads() bind(c, name='omp_get_max_threads') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
  end interface
end module
```

然后 `use omprt`。这个办法在两个编译器上都能用，而且顺便演示了 `bind(c)` 的实际价值 ——**OpenMP 运行时函数本来就是 C 接口**，Fortran 的 `omp_lib` 只是它的包装。

注意接口块里必须 `import :: c_int, c_double`，否则报 `Must be a constant value`。

### 竞态：一定要亲眼见一次

```fortran
integer :: cnt = 0
!$omp parallel do
do i = 1, 100000
  cnt = cnt + 1        ! 错：读-改-写不是原子操作
end do
```

`cnt` 几乎肯定不等于 100000。因为 `cnt = cnt + 1` 编译成「读进寄存器 → 加 1 → 写回」，两个线程可能都读到 100，各加 1 写回 101，一次增量丢了。

三种修法：

```fortran
!$omp atomic                       ! 只保护这一个操作，最快
!$omp critical                     ! 一个代码块，更通用但更慢
!$omp parallel do reduction(+:cnt) ! 各线程用私有副本，最后合并，最快
```

优先用 `reduction`，它是三者里唯一不需要在循环里做同步的。

### 一个 flang 特有的限制

下面这段在 gfortran 上没问题，在 flang 23 上编译失败：

```fortran
block
  integer :: cnt = 0
  !$omp parallel do
  do i = 1, n
    !$omp atomic
    cnt = cnt + 1
  end do
end block
```

flang 报：

```
error: The atomic variable cnt should appear as an argument of the top-level + operator
```

或者对 `do concurrent` 的 `local()`：

```
error: 'hi' may not appear in a locality-spec because it is not a definable ...
```

**原因是 flang 不接受 `block` 作用域里声明的变量出现在这些位置。** 解法很简单：把累加器和局部变量提到**程序（或模块）作用域**声明，然后在循环里用。示例 20 里所有并行累加器都在程序级声明，就是这个原因。

### 加速比的现实

示例里测了串行 vs 并行 2/4/8 线程的耗时，并算了加速比。你会看到：

- 线程数超过物理核心数后**没有收益**（甚至变慢）
- 加速比一般达不到线性 —— 有启动开销、同步开销、内存带宽瓶颈
- `schedule(dynamic)` 在小任务上可能比 `static` 更慢（调度开销大于收益）

**别看到 `!$omp` 就以为变快了。** 一定要测。

### 计时示例为什么会被列进「已知差异」

因为它打印真实耗时，而两份输出的时间戳必然不同。脚本对 `20-parallel` 直接跳过逐字节比对。

---

上一章：[第 26 章 C 互操作](26-c-interop.md) ｜ 下一章：[第 28 章 调试与查错方法](28-debugging.md) ｜ 返回：[README](../README.md)
