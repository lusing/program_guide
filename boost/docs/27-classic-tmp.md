# 27 · 古典元编程：mpl / preprocessor / vmd / metaparse / proto / yap / wave

> 对应示例：`examples/27_classic_tmp/`（7 个例程）

2001–2006 年，Boost 的先辈们在**没有 C++11** 的世界里，用预处理器和模板递归建起了一整套"编译期计算"文明。这一章是考古，也是寻根——现代 C++ 的每一步都踩在它们的脚印上。

## 27.1 Boost.MPL（2003）：编译期 STL 的丰碑

MPL 在 C++03 上实现了完整的编译期容器与算法。看它一眼就知道 C++11 前的人有多苦——以及多强：

```cpp
using Ptrs = mpl::transform<V, std::add_pointer<mpl::_1>>::type;   // 每步都要 ::type
using Floats = mpl::copy_if<V, std::is_floating_point<mpl::_1>>::type;   // _1 占位符 = 当年的"模板 lambda"
mpl::accumulate<Cnts, mpl::int_<0>, mpl::plus<mpl::_1, mpl::_2>>::type;
```

运行输出（`mpl.cpp`）：

```text
transform → int* OK（比 mp11 多个 ::type）
浮点数 = 2 个
accumulate 求和 = 6
size = 4 at<2> = double
自检通过
```

**已被 mp11/hana 取代**——但它定义的词汇（sequence/algorithm/metafunction/tag dispatch）是整个 TMP 世界的母语，海量老代码与 Boost 内部仍在用。

## 27.2 Boost.Preprocessor（2001）：预处理器的极限运动

X 宏惯用法至今仍是"一表多展开"的最佳实践：

```cpp
#define MESSAGE_TABLE ((继续,100)) ((未找到,404)) ((服务器错,500))
#define AS_ENUM(r, data, elem) 名 = 码,
enum Status { BOOST_PP_SEQ_FOR_EACH(AS_ENUM, _, MESSAGE_TABLE) };
#define AS_CASE(r, data, elem) case 码: return #名;
BOOST_PP_REPEAT(3, TRACE_CALL, _)      // 重复展开
BOOST_PP_ADD(2, 3)                      // 预处理器算术
```

运行输出（`preprocessor.cpp`）：

```text
404 = 未找到
500 = 服务器错
重复展开:
  第 0 层
  第 1 层
  第 2 层
BOOST_PP_ADD(2,3) = 5
自检通过
```

⭐ 依然活着：反射来临前，"数据表 → 多处代码"的展开还是它的地盘。

## 27.3 Boost.VMD（2013）：宏参数的体检器

检验宏参数是元组/序列/数组/数字——但有个**铁律**：VMD 宏只在 `#if` 预处理语境工作，不能当运行期函数：

```cpp
#if BOOST_VMD_IS_TUPLE((1, 2))
    // 编译这条分支
#endif
```

运行输出（`vmd.cpp`）：

```text
(1,2) 是 元组
(x)(y) 是 序列
(a,b,c) 的长度 = 3
自检通过
```

⭐ 宏接口自适应（按参数形态选展开）的最后一块拼图。

> 实测坑：IS_SEQ 等展开在 MSVC 预处理器下有固有 C4003（内部宏参数不足告警），使用点要 pragma 压制。

## 27.4 Boost.Metaparse（2018）：编译期解析字符串

```cpp
using int_parser = build_parser<entire_input<token<int_>>>;
using parsed = int_parser::apply<BOOST_METAPARSE_STRING("42")>::type;
static_assert(parsed::value == 42);
```

运行输出（`metaparse.cpp`）：

```text
编译期解析 "42" → 42
（DSL 字面量 → 编译期数据结构 = Metaparse 的主场）
自检通过
```

把 DSL 字面量在编译期变成类型级数据结构（它的原生场景是编译期解析类型列表）。C++26 反射（可迭代字符串字面量）会让它退场，但"编译期解析器组合子"的思路值得记住。

## 27.5 Boost.Proto（2006）：表达式模板的工厂

把 `a + b * c` 这样的表达式**捕获成 AST**（不求值），然后变换、求值、重写——Spirit/Phoenix/Units 三家的共同地基：

```cpp
auto expr = one + one + one;                     // AST：(1+1)+1
proto::eval(expr, proto::default_context{});     // 3
proto::display_expr(one + _1 * one);             // 打印 AST
```

运行输出（`proto.cpp`）：

```text
eval = 3（AST 先建好，eval 才算）
存了再 eval = 3
AST 结构:
plus(
    terminal[1]
  , multiplies(
        terminal[_1]
      , terminal[1]
    )
)
自检通过
```

**维护模式**（不再进化），新项目看 YAP。

## 27.6 Boost.YAP（2018）：Proto 的简化继任

C++14 重写，目标是"写 EDSL 不再需要 TMP 大师学位"：

```cpp
auto ast = make_terminal(a) + make_terminal(b) * 2.0;   // 捕获不求值
boost::yap::transform(sum_expr, AddEval{});              // 自定义求值器
```

运行输出（`yap.cpp`）：

```text
AST 建好（未求值）
逐元素相加: 11 22 33
自检通过
```

例程演示了最小可用 EDSL：给 `vector<double>` 捕获表达式 + 一个 plus 节点的求值器 = 逐元素加法。⭐ 延迟求值、自动求导、GPU 代码生成的现代地基。

> 实测坑：`algorithm.hpp` 在 MSVC 19.51 有 C4702（不可达代码，库自身问题）——include 处 pragma 压制。

## 27.7 Boost.Wave（2003）：可当库用的 C++ 预处理器

Wave 是**C++ 预处理器的完整实现**——把 `#define/#if` 的展开做成可编程的 token 流：

```cpp
context_type ctx(code.begin(), code.end(), "demo.cpp");
for (auto it = ctx.begin(); it != ctx.end(); ++it)
    // 预处理后的每个 token
```

运行输出（`wave.cpp`）：

```text
宏展开含 Hello? 1 含 World? 1
token 数 = 14
自检通过
```

`GREETING(WORLD)` 展开成 `Hello, World!`——例程验证了宏与条件编译全部正确展开。⭐ 静态分析工具、编译器前端、预处理转储的唯一标准件级选择。

---

下一章：[28 · 网络编程](28-network.md)——asio / beast / url。
