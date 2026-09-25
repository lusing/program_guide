# 第 32 章 · 双编译器差异清单与可移植写法

这些不是从文档查的，是在本机把 31 个示例跑通的过程中一条条撞出来的。**碰到「同一份代码一边过一边不过」，先来这里对一下。**

| # | 差异 | flang 23 | gfortran 15 | 可移植写法 |
|---|---|---|---|---|
| 1 | 四倍精度 `real128` | 不支持（`real128 = -1`） | 支持 | 用 `real64`；要更高精度用 `selected_real_kind` 并检查返回值 |
| 2 | 参数化派生类型（PDT） | 不支持 | 支持 | 别用 PDT，改成普通派生类型 + 运行时检查 |
| 3 | 共数组（coarray） | 不支持 | 支持（`-fcoarray`） | 用 MPI / OpenMP 代替 |
| 4 | `omp_lib` 模块 | **没有** | 有 | 自己写 `bind(c, name='omp_*')` 接口（示例 20 的 `omprt`） |
| 5 | `-fcheck=` 运行时检查 | 没有对应选项 | 有 | 用断言 + `-O2` 暴露；靠测试而不是靠检查器 |
| 6 | `block` 内变量的 `!$omp atomic` / `do concurrent local()` | 报错 | 接受 | 把并行相关变量提到程序/模块作用域 |
| 7 | `forall` 带类型声明 | 接受（F2008） | 拒绝，且认为 `forall` 过时 | 别用 `forall`，改成数组整体运算或 `where` |
| 8 | `pure function` 带 `intent(inout)` 哑元 | 放行 | 按标准拒绝 | 需要改哑元就写 `pure subroutine` |
| 9 | 递归函数 | 未写 `recursive` 也可能放行 | 必须显式写 | 一律写 `recursive` |
| 10 | 重复 `allocate` 已分配变量 | 运行时宽容 | 运行时报错 | 先 `deallocate`，或用 `stat=` 检查 |
| 11 | `random_seed(size=)` | 1 | 8 | 永远先 `size=n` 再分配种子数组 |
| 12 | `stat=` 的具体数值 | 12 等 | 5014 等 | 只判 `/= 0`，绝不对具体数值做判断 |
| 13 | namelist 输出排版 | 一套风格 | 另一套 | 不依赖打印格式，只依赖读回能力 |
| 14 | 已删/过时特性（PAUSE、语句函数、alternate return）在 `-std=f2018` 下 | PAUSE 接受（仅 portability 警告），另两个零警告接受 | **PAUSE 拒绝编译**；另两个报 Obsolescent 警告 | 别用它们；老代码走 legacy 通道（见第 19 章实测表） |
| 15 | 同一数组元素被两条 DATA 重复初始化（legacy 通道） | 拒绝 | 接受（后者覆盖） | 每个元素只喂一次初值（示例 72 的实测坑） |
| 14 | `-pedantic` 下对 `forall` 的态度 | 不警告 | 警告「已过时」 | 见第 7 条 |

### 关于第 4 条：没有 `omp_lib` 怎么办

这是实际影响最大的一条。flang 23 编译 `use omp_lib` 直接失败：

```
error: Cannot parse module file for module 'omp_lib'
```

而 `!$omp` 指令本身 flang 是支持的（只要加 `-fopenmp`），缺的只是**那个便利模块**。

**通用解法：自己声明 C 接口。**

```fortran
module omprt
  use, intrinsic :: iso_c_binding, only: c_int, c_double
  implicit none
  private
  public :: omp_get_wtime, omp_get_max_threads, omp_get_thread_num, &
            omp_get_num_procs, omp_in_parallel

  interface
    function omp_get_wtime() bind(c, name='omp_get_wtime') result(t)
      import :: c_double
      real(c_double) :: t
    end function
    function omp_get_max_threads() bind(c, name='omp_get_max_threads') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
    function omp_get_thread_num() bind(c, name='omp_get_thread_num') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
    function omp_get_num_procs() bind(c, name='omp_get_num_procs') result(n)
      import :: c_int
      integer(c_int) :: n
    end function
    function omp_in_parallel() bind(c, name='omp_in_parallel') result(b)
      import :: c_int
      integer(c_int) :: b
    end function
  end interface
end module
```

**这个模块在两个编译器上都能用**，因为 `omp_*` 本来就是 C 符号。而且它顺便说明了一件事：`iso_c_binding` 不是「跟 C 交互才用得到」的东西，它是访问**任何 C 接口库**的通用工具。

### 关于第 7 条：`forall` 该退休了

`forall` 在 F95 引入，F2008 起就被 `do concurrent` 和数组整体运算取代，F2018 正式列为**过时特性**。

```fortran
! 老写法
forall (i = 1:n) a(i) = b(i) * 2.0_real64

! 新写法
a = b * 2.0_real64

! 带条件的
forall (i = 1:n, b(i) > 0.0_real64) a(i) = b(i)

! 新写法
where (b > 0.0_real64) a = b
```

`where` 比 `forall` 更安全（元素级语义，不会越界）也更快（编译器更容易向量化）。**新代码不要再用 `forall`。**

### 关于第 6 条：block 里的并行变量

```fortran
! flang 报错的写法
block
  integer :: cnt = 0
  !$omp parallel do
  do i = 1, n
    !$omp atomic
    cnt = cnt + 1
  end do
end block

! 两个编译器都接受的写法
integer :: cnt      ! 提到程序/模块作用域
cnt = 0
!$omp parallel do
do i = 1, n
  !$omp atomic
  cnt = cnt + 1
end do
```

同样的限制也适用于 `do concurrent ... local(x)`：`x` 必须在程序或模块作用域声明。

代价是变量作用域变宽了，但这是目前唯一能同时通过两个编译器的写法。**如果你的项目只用 gfortran，可以不必迁就** —— 但要知道迁就什么。

### 可移植性检查清单

写完一段想「两边都过」的代码，按这个顺序过一遍：

1. **不碰 `real128`、PDT、coarray** —— 这三个 flang 直接没有
2. **不 `use omp_lib`** —— 换自己的 `bind(c)` 包装
3. **`pure` 函数不改哑元** —— 需要改就用 `pure subroutine`
4. **递归一律写 `recursive`**
5. **`allocate` 前先 `deallocate`**
6. **随机数种子先问 `size`**
7. **`stat`/`iostat` 只判 `/= 0`**
8. **不用 `forall`**
9. **并行累加变量放程序级作用域**
10. **每行 ≤ 132 列，`-pedantic` 下零警告**

这十条也就是本仓库 `run-all.sh` / `build.ps1` 的判定标准背后的东西。**把验证脚本当编译器用**，是保持双编译器可移植最省事的办法。

---

## 附录：怎么跑这本书里的代码

```bash
cd /Users/xulun/code/programming/fortran

# 全部跑一遍（31 示例 × 2 编译器）
./run-all.sh

# 看某个示例的完整输出
./run-all.sh -v 16

# 老格式示例单独跑：脚本自动改用固定格式编译（.f 不加 -pedantic，
# gfortran 侧加 -std=legacy，flang 侧不加 -std）
./run-all.sh 70 71

# 手动编译单个示例，两个编译器各来一次
flang-mp-23    -std=f2018 -pedantic -O2 -J build/mod/flang    examples/16-numeric.f90 -o /tmp/n.f && /tmp/n
gfortran-mp-15 -std=f2018 -pedantic -O2 -J build/mod/gfortran examples/16-numeric.f90 -o /tmp/n.g && /tmp/n.g
```

PowerShell：

```powershell
cd /Users/xulun/code/programming/fortran
pwsh ./build.ps1 -All
pwsh ./build.ps1 -File 16-numeric.f90 -Verbose
pwsh ./build.ps1 -Clean
```

**建议的读法**：第 1–6 章打底（第 3 章讲算法与程序设计的方法论，写过别的语言的人可以跳），然后 7–9 章（数组）是 Fortran 的核心价值，一定要动手改改示例里的数组表达式。11–15 章是把代码从「脚本」变成「工程」的 I/O 与过程设施。22–24 章是数值计算的正餐，27 章并行让 Fortran 真正快起来。第 31、32 章当手册查，第 30 章的谜题值得在做完每章练习后回来刷一遍。
---

上一章：[第 31 章 坑清单（与编译器无关）](31-pitfalls.md) ｜ 返回：[README](../README.md)
