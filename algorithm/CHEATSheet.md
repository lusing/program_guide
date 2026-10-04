# algorithm CHEATSheet —— C++23 算法教程（CLRS 线）速查与坑位总账

> 逐批交付、逐批填充。三部分：A. 算法复杂度速查总表（37 章收束时定稿）；
> B. C++23 语言/库坑位（写作中实测）；C. 跨通道差异判据（MSVC / clang / g++）。

## A. 复杂度速查总表

（批次 15 收束时随 docs/37 定稿——排序/选择/图算法/NP/近似全量对照表。）

## B. C++23 语言/库坑位

（逐批登记，四段式详见各章「坑位清单」，此处是速查摘要。）

01–04 章批次（8 条）：

1. `std::ranges::sort` 报「不是 std::ranges 的成员」——算法在 `<algorithm>`，
   `<ranges>` 只有视图（01 章，三通道齐红实测）。
2. libstdc++ 特性宏拆散在各头文件，`<algorithm>` 只带自己的宏；探测前必须
   `#include <version>`（01 章，msvc=1/gcc=0 假象）。
3. MinGW libstdc++ 15.2 链接 `<print>` 必挂（缺 `std::__open_terminal`）——
   两级探针 + `-DALGO_NO_PRINT` + IO 垫片（01 章；垫片用 `std::format`+
   `printf`，字节流与 `std::print` 一致）。
4. 特性宏「数值」跨库不同（`__cpp_lib_ranges_zip` 202207 vs 202110）——
   探测表只打 0/1 布尔（01 章）。
5. 无符号 `assert(n > 0)` 触发 gcc `-Wextra`（-Wtype-limits）——写 `n != 0`
   （01 章）。
6. `std::size_t` 下标回绕：边界检查必须前置（`i > 0 && a[i-1] > key`），
   且比较计数放 `&&` 右侧防短路漏计（02 章）。
7. `std::log/pow` 尾数跨标准库可异——分析实验全整数运算，⌊lg n⌋ 用
   `bit_width(n)-1`（03 章）。
8. Strassen 公式手抄错号（C22 的 −P7 写进括号变成 +P7）——与朴素乘法
   `assert(mat_eq(...))` 对账，第一次运行就抓住（04 章，真实翻车实录）。

## C. 跨通道差异判据

- **`<print>` 链接（g++ 通道）**：scoop MinGW libstdc++ 15.2 缺
  `std::__open_terminal` 符号，一链接 `<print>` 必挂（designpattern 2026-09-28
  实测）；build.ps1 两级探针自动降级 `-DALGO_NO_PRINT`，示例顶部 8 行 IO 垫片兜底
  （`std::format` + `std::printf` 产出与 `std::println` 逐字节相同的 UTF-8）。
- **`uniform_int_distribution` 不可移植**：分布算法实现未规定，MSVC 与 libstdc++
  给出不同序列——跨通道逐字节对账必挂；一律自写 `rand_below(rng, n)`。
- **unordered 容器遍历序跨实现不同**：对账高压线；排序后再打印或改用 `std::map`。
