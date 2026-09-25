# 05 · 语言基建先行者：那些"没毕业时你根本没法写 C++"的库

> 对应示例：`examples/05_langbase/`（14 个例程）

这一章的库有个共同点：**它们的功能今天看起来平淡无奇**——定长数组、元组、编译期断言、类型特征、`auto`。因为在 C++11 里这些全是语言/标准库的一部分了。但回到 2001–2005 年，没有它们你连一个像样的泛型库都写不出来。这批库是"Boost 库 = 标准库的预备队"最字面意义的证明：**TR1 收编名单的一半在这一章**。

| 库 | 是什么 | std 对应 | 血缘 |
|---|---|---|---|
| Boost.Tuple | 异构定长容器 | `std::tuple`（C++11） | 直系 |
| Boost.Array | 定长数组容器 | `std::array`（C++11） | 直系 |
| Boost.StaticAssert | 编译期断言 | `static_assert`（C++11） | 直系（语言特性） |
| Boost.TypeTraits | 类型内省与变换 | `<type_traits>`（C++11） | 直系 |
| Boost.Typeof | 表达式类型推导 | `auto`/`decltype`（C++11） | 直系 |
| Boost.Integer | 按位宽/值域选整型 | `<cstdint>`（部分） | 半系（"最少/最快"选择器没进 std） |
| Boost.Utility | 杂物间（swap/exchange/string_view…） | 分散毕业 | 各自直系 |
| Boost.Core | 所有 Boost 库的地基 | `std::exchange`/`addressof` 等 | 部分毕业 |
| Boost.Assert | 三档断言宏 | `assert`（语义不同） | 平行共存 |
| Boost.Config | 编译器能力探测宏 | `__has_include`/`__cpp_*` 宏 | 平行共存 |
| Boost.Predef | 版本级平台探测 | 无对应 | ⭐ 独有价值 |
| Boost.Foreach | range-for | range-for（C++11） | 直系（语言特性） |
| Boost.Align | 对齐四件套 | `std::aligned_alloc`（部分） | 半系（align_up/down 无 std 对应） |
| Boost.TypeIndex | typeid 完全体 | 无对应 | ⭐ 独有价值 |

## 5.1 Boost.Tuple：元组的原版（2002）

```cpp
boost::tuple<int, std::string, double> item{1, "ada", 3.14};
boost::get<0>(item);                       // 按下标取值（std 同款）
boost::tie(a, b) = t;                      // 解包祖师爷
auto k1 = boost::make_tuple(1, "a");       // 推导构造
// k1 < k2 —— 字典序比较（tuple_comparison）
```

运行输出（`tuple.cpp`）：

```text
id=1 name=ada score=3.14
tie 解包: 7,x
k1 < k2 ? true
结构化绑定: 2,grace,2.71
std::tuple_size = 3
```

**毕业档案**：`std::tuple`（C++11，直系）。今天用 boost 版的唯一理由是接口兼容。注意演化终点不止 C++11——`std::tie` 的解包被 C++17 结构化绑定 `auto [id, name, score] = s;` 又升级了一代；而 boost::tie 的"忽略元素"（`boost::ignore`）对应 `std::ignore`，C++26 起结构化绑定也可以 `_` 忽略了。

## 5.2 Boost.Array：STL 接口的 C 数组（2001）

```cpp
boost::array<int, 5> a{{3, 1, 4, 1, 5}};   // C++03 双花括号惯用法
std::sort(a.begin(), a.end());
boost::array<char, 4> buf{{'a', 'b', 'c', 'd'}};
std::cout.write(buf.data(), 4);            // data() 无 NUL，打印要带长度
```

运行输出（`array.cpp`）：

```text
排序后: 1 1 3 4 5
size=5 求和=14
data 前 4 字节: abcd 首元素 a
std::array 求和 = 14
```

`std::array`（C++11）是它的直系后代（Nicolai Josuttis 亲手送进 TR1）。毕业后 std 版还持续进化：单花括号初始化（聚合初始化规则修正）、CTAD、C++20 `std::to_array`。**2026 无理由用 boost 版。**

> 实测坑：`data()` 打印必须带长度——没有 NUL 终止符，`<< buf.data()` 会一直打到越界内存，输出不确定（本教程"无控制字符+确定性输出"的判定正好抓住这类问题）。

## 5.3 Boost.StaticAssert：编译期断言（2000）

```cpp
BOOST_STATIC_ASSERT_MSG(sizeof(T) >= 4, "median 需要至少 32 位宽度");
static_assert(sizeof(std::int64_t) * CHAR_BIT == 64, "int64_t 必须 64 位");
```

运行输出（`static_assert.cpp`）：

```text
median(3,1,2) = 2
编译期防线就位
```

`static_assert` 进 C++11 是这个库 11 年使命的终点。模板代码的"契约前置"（参数类型必须满足什么）从它开始，经 `enable_if`，到 C++20 concepts 走完三段演化——5.4 和第 15 章会把这条线串完。

## 5.4 Boost.TypeTraits：类型的手相术（2000）

```cpp
// C++98 时代的按特征分派（SFINAE 唯一手段）
template <typename T>
typename boost::enable_if<boost::is_integral<T>, std::string>::type describe(T);
typename boost::decay<T>::type                        // trait 变换
boost::is_same<D, std::vector<int>>::value            // trait 查询
```

运行输出（`type_traits.cpp`）：

```text
整数
类类型
is_same 检查: 1
is_pointer 检查: 1
  衰变后是否 vector: true
  衰变后是否 vector: false
std 版: true true
concepts 时代: lambda 检查 vector = true
```

这是"用模板元编程回答类型问题"这门手艺的开山之作，直接变成了 `<type_traits>`（C++11）。**三段演化**值得记住：

1. **trait 查询**（`is_integral<T>::value`）——现在写 `std::is_integral_v<T>`；
2. **enable_if 分派**——C++20 concepts 后写 `requires std::integral<T>` 直接声明约束；
3. **trait 变换**（`decay`/`remove_reference`）——仍在每天用（`std::decay_t<T>`）。

trait 本身没有过时——**concepts 是 trait 的消费者**（`std::integral<T>` 内部就是 trait）。2026 年还用 boost 版的场景：老代码、或需要 boost 版独有的少数 trait（如 `has_trivial_copy` 家族的某些变体）。

## 5.5 Boost.Typeof：auto 的前身（2004）

```cpp
BOOST_AUTO(it, table.begin());                  // = auto it = ...
BOOST_TYPEOF(table["odd"]) copy = table["odd"]; // = decltype(...)
auto it2 = table.begin();                       // C++11 毕业
```

运行输出（`typeof.cpp`）：

```text
BOOST_AUTO 拿到迭代器指向 odd
BOOST_TYPEOF 拷贝长度 3
auto+decltype: odd 3
```

它的实现是**注册表 + 编译期模拟**：宏展开后把表达式编码进模板递归——C++03 没有语言支持时的奇迹工程。`auto`/`decltype`（C++11）毕业后彻底退休。

## 5.6 Boost.Integer：按需求选整型

`<cstdint>` 给了定宽整型，但"**至少 N 位的最小类型**"、"**至少 N 位的最快类型**"、"**装得下值 V 的最小无符号**"这三类元编程选择器 std 至今没有（C 标准 `int_leastN_t`/`int_fastN_t` 是预定义别名，不是元函数）：

```cpp
using hold_200k = boost::uint_value_t<200000>::least;  // → uint32_t
using fast_8    = boost::int_t<8>::fast;               // → 最快的 ≥8 位
static_assert(std::is_same_v<boost::uint_t<16>::exact, std::uint16_t>);
std::cout << boost::high_bit_mask_t<3>::high_bit_fast;  // 1<<3
boost::static_log2<1000>::value;                        // 9（向下取整）
```

运行输出（`integer.cpp`）：

```text
装下 200000 的最小无符号: 32 位
最快 8 位有符号: 8 位
1<<3 = 0x8 log2 向下取整(1000) = 9
```

**2026 价值**：泛型代码里按值域自动选类型（序列化、协议字段）时仍然好用。

> 实测坑：`high_bit_fast` 的类型可能是 `unsigned char`——值 8 直接 `<<` 打印会变成退格控制符。打印前 cast 到 `unsigned`。

## 5.7 Boost.Utility + 5.8 Boost.Core：两个"活化石陈列柜"

Utility 和 Core 都是杂物抽屉，里面每个小工具的归宿各不相同：

| 工具 | 住址 | std 归宿 |
|---|---|---|
| `boost::swap` → 已弃用，继任 `boost::core::invoke_swap` | utility→core | `std::swap`（C++11 后可靠） |
| `boost::exchange`（`boost/core/exchange.hpp`） | core | `std::exchange`（C++14） |
| `boost::addressof` | core | `std::addressof`（C++11） |
| `boost::noncopyable` | core | `= delete`（C++11） |
| `boost::string_view` | utility | `std::string_view`（C++17，见第 12 章） |
| `boost::core::demangle` | core | 无对应（GCC/MSVC 各自的 unmangle 不是标准件） |

运行输出（`utility.cpp`）：

```text
take_over 拿到 fd=7 留下 fd=-1
swap 后 x=2 y=1
string_view... 长度 30
in_place 家族见 optional/container 章
自检通过
```

运行输出（`core.cpp`）：

```text
noncopyable 会话 id=1
真实地址非空? true
demangle: std::__1::shared_ptr<int> 可读
exchange: old=1 new=99
lightweight_test 见第 32 章（其报告走 stderr，与本章判定口径不合）
自检通过
```

> 实测坑（跨平台）：`demangle` 那行取决于 `typeid(T).name()` 给什么——MSVC 给 `class std::shared_ptr<int>`，Itanium ABI（clang/GCC）给 `NSt3__110shared_ptrIiE`，`core::demangle` 还原出来就是 `std::__1::shared_ptr<int>`（libc++ 的内联命名空间名 `__1` 会露出来）。两边都"可读"，但字符串不同。

**2026 价值**：直接用 std 版（`exchange`/`addressof`/`=delete`）；`demangle` 在跨平台日志/调试输出里仍是趁手小工具。这两个库的真正用户是**其他 Boost 库**——你 include 任何 Boost 头，Core 几乎必然在场。

## 5.9 Boost.Assert：给库作者的三档断言

```cpp
BOOST_ASSERT(b != 0);                                  // NDEBUG 后消失
BOOST_ASSERT_MSG(b != 0, "除数为 0：上游数据管道坏了");  // 带消息
BOOST_VERIFY(IsValidHandle(h));                        // 表达式保留，只断真值
```

运行输出（`assert.cpp`）：

```text
5
3
2
断言三档：ASSERT(消失)/ASSERT_MSG(带话)/VERIFY(保留副作用)
```

与 `<cassert>` 的差异是**面向库作者**的设计：断言失败可以重定向到自定义处理器（接日志/崩溃上报），`BOOST_VERIFY` 专为"Release 也要执行检查表达式"的场景（Windows API 的 `VERIFY(GetLastError() == 0)` 同款语义）。std 的 `assert` 在 C++23 才有用户可控钩子的提案。**库作者仍在用。**

## 5.10 Boost.Config 与 5.11 Boost.Predef：可移植性的两代方案

```cpp
// Config（2001）：BOOST_NO_CXXNN_* = 缺失；BOOST_HAS_* = 平台提供
std::cout << BOOST_COMPILER;      // "Microsoft Visual C++ version 14.5"
#if !defined(BOOST_NO_CXX11_VARIADIC_MACROS) ...

// Predef（2013）：每个探测宏都是编码版本数（0 = 不存在），能比大小
#if BOOST_COMP_MSVC >= BOOST_VERSION_NUMBER(19, 30, 0)
    // C++20 协程可用
#endif
```

运行输出（`config.cpp`，**Windows 侧**）：

```text
编译器=Microsoft Visual C++ version 14.5
标准库=Dinkumware standard library version 650
平台=Win32
变参宏: 有
线程支持: 有
异常: 开启
...
```

运行输出（`config.cpp`，macOS 侧）：

```text
编译器=Clang version 16.0.0 (clang-1600.0.26.6)
标准库=libc++ version 180100
平台=Mac OS
变参宏: 有
线程支持: 有
异常: 开启
span 头可用(Boost 视角): true
自检通过
```

运行输出（`predef.cpp`，**Windows 侧**）：

```text
Windows? 1
x86-64? 1
MSVC? 195136257 检测到
MSVC >= 19.30：C++20 协程可用
这是 MSVC
```

运行输出（`predef.cpp`，macOS 侧）：

```text
Windows? 0
x86-64? 1
MSVC? 0 检测不到
这是 clang
自检通过
```

> 实测坑（跨平台）：`BOOST_PLATFORM` / `BOOST_STDLIB` 这类宏的**值随平台变**（`Win32` vs `Mac OS`、`Dinkumware` vs `libc++`），`BOOST_COMP_MSVC` 在非 MSVC 上干脆是 0。所以 02 章 `version.cpp` 那段按编译器分支打印（MSVC / Clang / GCC 各一支），而不是写死 `_MSC_VER`。

Predef 的版本比较能力（`BOOST_COMP_MSVC >= BOOST_VERSION_NUMBER(19,30,0)`）是它比 Config 高明的地方——Config 的宏只能"有没有"，Predef 能"够不够新"。**2026 价值**：写跨平台库时，标准库特性用 `__has_include` + `__cpp_*` 特性宏，编译器/OS 判断用 Predef，两者互补。

## 5.12 Boost.Foreach：range-for（毕业最干脆的一个）

```cpp
BOOST_FOREACH (int x, v) { ... }
BOOST_REVERSE_FOREACH (int x, v) { ... }   // std 版至今没有原生反向 range-for！
for (auto& kv : ages) { ... }              // C++11 毕业
for (auto& [name, age] : ages) { ... }     // C++17 结构化绑定
```

运行输出（`foreach.cpp`）：

```text
1 2 3
3 2 1
ada=36 grace=85
36;85;
ada36grace85
```

> 冷知识：`BOOST_REVERSE_FOREACH` 的反向遍历在 std 里反而**没有**直接对应（要写 `std::views::reverse`，C++20）——老宏库偶尔比标准库贴心。

## 5.13 Boost.Align：对齐四件套

```cpp
boost::alignment::aligned_alloc(64, 128);        // 对齐分配
boost::alignment::align(32, 64, raw, space);     // 缓冲区内找对齐位置
boost::alignment::align_up(100, 64);             // → 128（整数算术）
boost::alignment::align_down(100, 64);           // → 64
boost::alignment::is_aligned(96, 32);            // → true
boost::alignment::aligned_allocator<int, 64>;    // 容器分配器
```

运行输出（`align.cpp`；Windows 与 macOS 一致，见下面关于第 2 行的说明）：

```text
64 对齐分配: 0 (余数应为 0)
推进量 < 32? true  结果 32 对齐? true
align_up(100, 64) = 128
align_down(100, 64) = 64
is_aligned(96, 32) = true
容器分配器对齐: true
自检通过
```

> **"推进量"为什么不明写数字**：`align()` 推进多少字节取决于 `buffer` 这次落在
> 哪个地址上——同一个二进制跑两遍都可能不同（本机两条通道一次 16、一次 0，
> 早年 Windows 上是 16）。会漂的量不能当实测值写进文档，也不能进"两通道逐字节
> 一致"的比对范围，所以例程改成打两个**恒真的事实**：推进量必 < 32、结果地址
> 必是 32 的倍数。

`std::aligned_alloc`（C++17）毕业了分配部分（且 POSIX 语义有坑：size 必须是对齐的倍数）；但 **`align_up`/`align_down`/`is_aligned` 三个整数级工具没有 std 对应**——SIMD 内存池、网络协议对齐、游戏引擎的 arena allocator 里天天用。⭐ 2026 年仍值得 include。

## 5.14 Boost.TypeIndex：typeid 的完全体

```cpp
boost::typeindex::type_id<T>().pretty_name();            // 跨编译器可读名
boost::typeindex::type_id_runtime(*b)                    // 多态精确类型（跨 DLL 可靠）
boost::typeindex::type_id_with_cvr<decltype(s)>()        // cv + 引用全保留
```

运行输出（`type_index.cpp`，**Windows 侧**）：

```text
可读名: class std::vector<class std::basic_string<...>, ...>
原生名: class std::vector<...>（MSVC 恰好也可读）
int == int32_t ? true
运行期精确类型: struct Derived
另一个对象: struct Other 是 Base 吗? false
cv+引用完整型: class std::basic_string<...> const & __ptr64
```

运行输出（`type_index.cpp`，macOS 侧）：

```text
可读名: std::__1::vector<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>, std::__1::allocator<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>>>
原生名: NSt3__16vectorINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEENS4_IS6_EEEE（MSVC 恰好也可读）
int == int32_t ? true
运行期精确类型: Derived
另一个对象: Other 是 Base 吗? false
cv+引用完整型: std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>> const&
自检通过
```

三个独有价值：**pretty_name** 归一 GCC/clang 的 mangled 名；**type_id_runtime** 在跨 DLL 边界（typeid 的经典失灵区）仍然可靠；**type_id_with_cvr** 显示完整 cv/引用限定（`const std::string&` 不退化成 `std::string`）——调试模板代码的神器。⭐ std 无对应。

> 实测坑（跨平台）：`pretty_name()` 在 MSVC 上**几乎等于** `raw_name()`（MSVC 的 `typeid().name()` 本来就可读，还带 `class`/`struct` 前缀和 `__ptr64`），所以上面两行在 Windows 上长得很像；只有在 Itanium ABI 上才能看出 pretty 的价值（`NSt3__1...` → `std::__1::...`）。另外 MSVC 的 `__ptr64` 后缀是它独有的。

## 5.15 本章速查

| 需求 | 2026 答案 |
|---|---|
| 元组/定长数组/类型特征/auto/foreach | std（C++11/17）——无悬念 |
| 按值域选整型 | `boost::uint_value_t`/`int_t` |
| 对齐算术（align_up/down/is_aligned） | `boost::alignment` ⭐ |
| 可读类型名（跨编译器/跨 DLL） | `boost::typeindex` ⭐ |
| 编译器版本探测 | `boost::predef` ⭐ |
| 库作者断言 | `BOOST_ASSERT` 家族 ⭐ |

---


> 上一章：[04 · 函数即对象](04-function.md) ｜ 下一章：[06 · 正则与随机](06-regex-random.md) ｜ 返回：[README](../README.md)
