# 18 · 数值与随机：<numeric>、<numbers> 与 <random>

> 对应示例：`examples/18_numeric/`

## 18.1 <numeric>：折叠一族

求和这类"把区间折叠成一个值"的算法住在 `<numeric>` 而不是 `<algorithm>`（历史分区，记住即可）：

| 算法 | 干什么 |
|---|---|
| `accumulate(b, e, init[, op])` | 折叠：默认求和，给 op 换运算 |
| `inner_product(b1, e1, b2, init)` | 两区间点乘式累加 |
| `partial_sum(b, e, out)` | 前缀和：1 2 3 → 1 3 6 |
| `adjacent_difference(b, e, out)` | 相邻差：1 3 6 → 1 2 3 |
| `iota(b, e, start)` | 依次填 start, start+1, ... |

```cpp
std::vector<int> v(10);
std::iota(v.begin(), v.end(), 1);                        // 1..10
int sum  = std::accumulate(v.begin(), v.end(), 0);       // 55
int prod = std::accumulate(v.begin(), v.end(), 1,        // 3628800：换乘法折叠
                           [](int a, int b) { return a * b; });
```

**accumulate 初值类型陷阱**（第 15 章提过，这里钉死）：折叠的累加类型**由初值决定**——`vector<double>` 配初值 `0` 会全程按 int 累加、小数截断。浮点求和初值写 `0.0`，或干脆用下面的 `reduce`。好消息是这条陷阱 MSVC 会直接警告（C4244 "double 转换到 int 可能丢失数据"）——示例里就是故意触发它再显式圈起来的。

## 18.2 C++17 并行数值：reduce 与 transform_reduce

- **`reduce(b, e, init[, op])`**：accumulate 的并行版——**允许重排结合**，运算必须满足结合律+交换律。浮点加法恰好不严格满足（`(a+b)+c ≠ a+(b+c)` 在有限精度下），所以**并行 reduce 浮点结果可能与串行差最后几位**——这是数学不是 bug。
- **`transform_reduce`**：先变形再折叠，"MapReduce" 的标准库直译。经典题——一句话的字节总数：

```cpp
std::vector<std::string> words{"Only", "for", "testing", "purpose"};
auto total = std::transform_reduce(words.begin(), words.end(), std::size_t{0},
                                   std::plus<>{},                          // 折叠：加
                                   [](const std::string& s) { return s.size(); });   // 变形：取长度
// total == 21
```

同族的 `inclusive_scan` / `exclusive_scan`（并行版 partial_sum）知道名字即可。执行策略（`std::execution::par`）在第 29 章。

## 18.3 C++17/20 三个小而美

```cpp
std::gcd(36, 60);              // 12   —— C++17
std::lcm(4, 6);                // 12
std::midpoint(10, 20);         // 15   —— C++20：防溢出的中点（(a+b)/b 大了会溢出）
std::lerp(0.0, 10.0, 0.25);    // 2.5  —— C++20：线性插值 a + t*(b-a)
```

`midpoint` 存在的意义是 `(a + b) / 2` 在 `a`、`b` 都接近类型上限时溢出——它内部用防溢出公式。游戏/图形代码里 `lerp` 每天都在用。

## 18.4 数学常量：<numbers>（C++20）

π 终于不用自己定义了：

```cpp
std::numbers::pi;        // 3.141592653589793
std::numbers::e;         // 2.718281828459045
std::numbers::sqrt2;     // 1.4142135623730951
std::numbers::phi;       // 0.6180339887498949（黄金比）
std::numbers::pi_v<float>;   // 模板变量：要 float 版加 _v<float>
```

全套还有 `inv_pi`、`ln2`、`ln10`、`sqrt3`、`egamma` 等——都是 `double` 精度起步。加上 `<cmath>` 里的常规函数（`pow/sqrt/fabs/floor/ceil/fmod`），数值工具箱基本齐了。

## 18.5 <random>：引擎与分布分离

老 `rand()` 的三宗罪：质量差（低位周期极短）、`RAND_MAX` 只有 32767、`% n` 取模有偏差。现代随机库的架构是**三段论**：

```cpp
std::random_device rd;                       // ① 种子源：真随机（系统熵）
std::mt19937 gen{rd()};                      // ② 引擎：伪随机数流（种子定了序列就定）
std::uniform_int_distribution<int> dice{1, 6};   // ③ 分布：把引擎的均匀输出映射到你要的形状
int x = dice(gen);                           // 用法永远是“分布(引擎)”
```

**引擎**负责"生成一串均匀的比特流"。主力是 `std::mt19937`（梅森旋转，32 位版；64 位用 `mt19937_64`）——它是**标准逐比特规定的**：同一种子在任何平台产出同一序列（示例用它保证可复现）。`default_random_engine` 是实现自选（跨平台不保证一致），`random_device` 是真随机源但并非所有平台都提供。

**分布**负责"把均匀比特流捏成你要的形状"：`uniform_int_distribution<>(a, b)` 整数等概率、`uniform_real_distribution<>(a, b)` 实数等概率、`normal_distribution<>(mean, sigma)` 正态（高斯）——模拟、游戏掉落、蒙特卡洛全覆盖：

```cpp
std::normal_distribution<> height{170, 8};   // 平均 170、标准差 8 的身高
```

注意：**分布的抽样算法是实现定义的**——同一个种子，MSVC STL 与 libstdc++ 的 `normal_distribution` 序列不同。跨平台的正确姿势是断言**统计性质**（均值落在容差内），不是断言精确序列。

## 18.6 种子纪律

```cpp
std::mt19937 gen{42};          // 固定种子：测试/示例用（可复现）
std::mt19937 gen2{rd()()};     // random_device 播种：生产用（每次不同）
```

两条铁律：**引擎和分布是带状态的对象**——循环体内每次重新构造 `mt19937` 会拿到几乎相同的序列（都从种子头几个输出开始），必须构造一次反复用；**多线程共享一个引擎是数据竞争**——要么加锁，要么 `thread_local` 引擎（第 28 章）。

## 18.7 坑位清单

1. **accumulate 初值 0 截断 double**：累加类型跟初值走——浮点求和写 `0.0` 或改 `reduce`。
2. **reduce 的运算不结合/不交换**：UB——`%`、字符串拼接、矩阵乘都不能直接并行折叠；浮点并行结果允许尾数微差。
3. **循环里反复构造引擎**：`for (...) { std::mt19937 g(42); ... }` 每轮吐同样数字——引擎提升到循环外。
4. **断言随机序列的精确值**：分布算法实现定义，跨标准库不同——断言范围/均值等统计量。
5. **`uniform_int_distribution<>(1, 6)` 与 `(1, 6.0)`**：后者是 real 分布的参数错位（编译能过、语义错）；两个模板是不同工具，参数类型自查。
6. **还在写 `rand() % n`**：偏差 + 低质量 + 32767 上限——三重罪；新代码一律 `<random>`。
7. **多线程共用一个 mt19937**：数据竞争（UB）——`thread_local` 或加锁。

---

上一章：[17 一等函数](17-firstclass.md) · 下一章：[19 Ranges](19-ranges.md)
