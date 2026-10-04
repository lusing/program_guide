# algorithm CHEATSheet —— C++23 算法教程（CLRS 线）速查与坑位总账

> 逐批交付、逐批填充。三部分：A. 算法复杂度速查总表（37 章收束时定稿）；
> B. C++23 语言/库坑位（写作中实测）；C. 跨通道差异判据（MSVC / clang / g++）。

## A. 复杂度速查总表

（批次 15 收束时随 docs/37 定稿——排序/选择/图算法/NP/近似全量对照表。）

## B. C++23 语言/库坑位

（随批次登记，每条四段式：现象/原因/后果/对策。）

## C. 跨通道差异判据

- **`<print>` 链接（g++ 通道）**：scoop MinGW libstdc++ 15.2 缺
  `std::__open_terminal` 符号，一链接 `<print>` 必挂（designpattern 2026-09-28
  实测）；build.ps1 两级探针自动降级 `-DALGO_NO_PRINT`，示例顶部 8 行 IO 垫片兜底
  （`std::format` + `std::printf` 产出与 `std::println` 逐字节相同的 UTF-8）。
- **`uniform_int_distribution` 不可移植**：分布算法实现未规定，MSVC 与 libstdc++
  给出不同序列——跨通道逐字节对账必挂；一律自写 `rand_below(rng, n)`。
- **unordered 容器遍历序跨实现不同**：对账高压线；排序后再打印或改用 `std::map`。
