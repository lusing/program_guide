# 04 · 函数即对象：function/bind 家族与 lambda 的战争

> 对应示例：`examples/04_function/`（11 个例程）

这一章讲的是同一个故事的十一个版本：**怎么把"一段可执行的代码"当成值来传递**。这个故事里 Boost 是先驱——`function`（2001）、`bind`（2002）、`Lambda`（2002）——然后 C++11 的 lambda 一举拿下了故事的主线，剩下的角色各自找到新活法：退役的、重制的、往标准反向输送的。读懂这十一个库的兴衰，就读懂了"语言特性如何杀死库、又如何需要新库"。

族谱总览（先给结论）：

| 库 | 干什么 | 现状（2026 视角） |
|---|---|---|
| Boost.Function | 可调用物万能容器 | ✅ `std::function`；C++23 `move_only_function`、C++26 `function_ref` 是它的续集 |
| Boost.Bind | 参数绑定 | ✅ `std::bind`/`std::bind_front`；日常被 lambda 替代 |
| Boost.Functional | 工厂/静态重载分派 | ⭐ `overloaded_function` 无 std 对应 |
| Boost.Lambda | C++03 表达式 lambda | 🪦 已弃用，被 C++11 lambda 淘汰 |
| Boost.Lambda2 | 同语法现代重制 | ✅ STL 算法一行谓词的轻量替代，无依赖 |
| Boost.HOF | 高阶函数工具箱 | ⭐ compose/partial/pipable/match 无 std 对应 |
| Boost.CallableTraits | 解剖可调用物签名 | ✅ 基本被 C++20 concepts + `<functional>` 覆盖 |
| Boost.LocalFunction | 函数体内具名函数 | 🪦 被 lambda + `std::function` 递归法淘汰 |
| Boost.Phoenix | 函数式 EDSL 完全体 | ⭐ 惰性求值/运行期组装无可替代 |
| Boost.Parameter | 命名参数 | ⭐ 真正的乱序省略；C++20 指定初始化器只覆盖一半 |
| Boost.Compat | 新 std 特性回移植 | ⭐ 跨标准代码库的桥（反向毕业） |

## 4.1 Boost.Function：万能容器的原版

```cpp
boost::function<int(int, int)> op = add;                    // 函数指针
op = [](int a, int b) { return a - b; };                    // lambda
boost::function<int(int)> m = Mul{10};                      // 仿函数
```

运行输出（`function.cpp`）：

```text
函数指针: 7
lambda:   -1
仿函数:   50
empty 可调用? false
捕获 boost::bad_function_call
std→boost: 12
```

三个要点：

1. **类型擦除换来的万能**：`function<int(int,int)>` 能装任何匹配签名的东西，代价是间接调用（一次虚调用级别的开销）+ 可能的堆分配（捕获太大时）。
2. **空状态是一等公民**：`bool(empty)` 检查、调用空的抛 `bad_function_call`——回调可选时这个语义很重要（早年的函数指针得用 `nullptr` 惯用法模拟）。
3. **boost 版与 std 版可以互装但不是同一个类型**：跨 ABI 边界（DLL 接口）的 API 若规定了某一版，调用方就得用那一版。

**毕业档案**：`std::function`（C++11，直系）。续集们：`std::move_only_function`（C++23，可装 move-only 可调用物）、`std::function_ref`（C++26，零所有权视图，参数传递专用）。**2026 新代码没有理由用 boost 版**。

## 4.2 Boost.Bind：参数绑定

```cpp
using namespace boost::placeholders;               // 1.69 起必须显式引入

auto get_score = boost::bind(&Player::score, &bob, _1);   // 绑成员函数
auto w = boost::bind(weighted, _1, 0.5, 100);              // 预绑定
auto reordered = boost::bind(weighted, _2, 1.0, _1);       // 参数重排
auto name_of = boost::bind(&Player::name, _1);             // 绑数据成员
auto sp_score = boost::bind(&Player::score, sp, _1);       // 绑 shared_ptr
```

运行输出（`bind.cpp`）：

```text
成员函数: 42
预绑定: 60
重排: 27
成员指针: alice
shared_ptr: 42
```

历史上 `boost::bind` 比 `std::bind1st/bind2nd` 强出一代：任意参数个数、绑成员函数、绑成员指针、绑智能指针。它 2005 年进 TR1、2011 年进 std。

**2026 视角**：日常绑定用 lambda（可读、可内联、无占位符心智负担），std::bind 只在"元编程里需要部分应用一个未知签名的函数"时还有位置。boost 版仅在维护老代码时出现。

> 陷阱备忘：`std::bind`/`boost::bind` 对**按值捕获**的默认行为与 lambda 不同——`bind(f, x)` 拷贝 x，要引用得写 `boost::ref(x)`；lambda 的 `[&]`/`[=]` 更显眼，这也是它赢的原因之一。

## 4.3 Boost.Functional：三个幸存者

```cpp
boost::value_factory<Widget> vf;  Widget w = vf("value", 1);   // 产出值
boost::factory<Widget*> pf;                                    // 产出指针
boost::overloaded_function<int(int), double(double)> of(as_int, as_double);  // 静态重载
```

运行输出（`functional.cpp`）：

```text
value_factory: value1
factory: ptr2
overloaded(int 10) = 10
overloaded(double 10) = 15
```

`overloaded_function` 是本库最有意思的幸存者：把多个**不同签名**的函数静态分派成一个可调用物。std 至今没有对应物（C++17 的重载 lambda 惯用法 `struct F : A, B, C { using A::operator(); ... }` 要手写 using，且是类型不是对象）。工厂部分已被 `make_unique`/`make_shared` 和泛型 lambda 覆盖。

## 4.4 Boost.Lambda：被语言特性正面消灭的库

```cpp
using namespace boost::lambda;
std::for_each(v.begin(), v.end(), std::cout << _1 * 2 << ' ');   // 2002 年的奇迹
std::for_each(v.begin(), v.end(), sum += _1);
```

运行输出（`lambda.cpp`）：

```text
2 4 6 8 10
sum=15
C++11 lambda: sum2=15
```

2002 年，用表达式模板在**没有任何语言支持**的 C++03 里模拟出了内联函数。代价是：只支持运算符级别的表达式（不能写语句）、报错信息臭名昭著、性能靠编译器心情。C++11 lambda 一出，整个库失去存在意义，1.92 里仍带着但标了 deprecated。**它存在的意义是历史课**：语言特性碾碎库的最纯粹案例。

## 4.5 Boost.Lambda2：同一语法的现代重制

```cpp
using namespace boost::lambda2;
std::count_if(v.begin(), v.end(), _1 % 2 == 0);
std::transform(v.begin(), v.end(), back_inserter(out), _1 * _1 + 1);
```

运行输出（`lambda2.cpp`）：

```text
偶数个数 = 2
x^2+1: 2 5 10 17 26
点乘式对应相乘: 10 40 90 160 250
```

2021 年 Paul Mensonides 用几百行 C++11 重写了 Lambda 的核心语法。它**没有**被 lambda 淘汰，因为定位不同：lambda2 的 `_1 * _1 + 1` 是一个**类型**（表达式模板），可以存、可以组合、可以在泛型代码里当轻量谓词传——而 lambda 是不透明的闭包。写 STL 算法的一行谓词时，`_1 % 2 == 0` 比 `[](int x){ return x % 2 == 0; }` 短一半，还不用想参数类型。无依赖、单头文件，是少数"2026 年仍值得新代码使用"的占位符库。

## 4.6 Boost.HOF：高阶函数的正牌工具箱

```cpp
auto dq = boost::hof::compose(quote, dbl);          // 函数组合
auto add10 = boost::hof::partial(add3)(10);         // 偏应用
auto pipe_dbl = boost::hof::pipable(dbl);           // 管道化
auto dispatch = boost::hof::match([](int){...}, [](double){...}, [](auto&&){...});  // 按签名分派
```

运行输出（`hof.cpp`）：

```text
compose(quote, dbl)(21) = [42]
partial 先固定 a=10: 60
5 | inc | dbl = 12
flip(subtract)(3, 10) = 7
int:double:other:
```

C++ 标准库有 `std::bind_front`（C++20）覆盖了 partial 的一半，但 `compose`（函数组合）、`pipable`（`x | f | g` 管道）、`match`（多签名分派）至今没有 std 对应——ranges 时代的函数式风格恰恰最缺这几个零件。HOF 是这个领域的唯一正牌，质量极高（constexpr 全覆盖）。

## 4.7 Boost.CallableTraits：解剖可调用物

```cpp
using args = boost::callable_traits::args_t<F>;         // 参数类型包
using ret  = boost::callable_traits::return_type_t<F>;  // 返回类型
boost::callable_traits::is_const_member_v<memfn>;       // 成员函数的 const 性
```

运行输出（`callable_traits.cpp`；`typeid` 名在 MSVC 上是可读形，见下）：

```text
函数类型: 参数个数=2 返回类型=i 第2参数=NSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEE
仿函数: 参数个数=2 返回类型=d 第2参数=i
lambda: 参数个数=2 返回类型=d 第2参数=d
成员函数 is_const = true
自检通过
```

> 实测坑（跨平台）：这三行的"类型名"是 `typeid(T).name()`，MSVC 给 `int` / `class std::basic_string<...>`，Itanium ABI（clang/GCC）给 `i` / `NSt3__112basic_stringIc...` 这种 mangled 裸名。同一份代码在两个平台上打印完全不同——**别把类型名字符串写进断言**，要判断类型就用 `std::is_same` 或 `boost::typeindex`。

写泛型库时回答"T 能不能调、怎么调"的专用工具。**2026 视角**：日常泛型约束用 C++20 concepts（`std::invocable<F, int>`）；callable_traits 剩余价值在**拆解**签名（取出第 N 个参数类型、判断 noexcept/const 成员、变换签名再重组）——这些 concepts 做不到。

## 4.8 Boost.LocalFunction：函数体内的具名函数

```cpp
bool BOOST_LOCAL_FUNCTION(const bind& threshold, bind& count, int x) {
    bool is_above = x > threshold;
    if (is_above) ++count;
    return is_above;
} BOOST_LOCAL_FUNCTION_NAME(above)
```

运行输出（`local_function.cpp`）：

```text
threshold=4 以上: 5 8 9
命中 3 个
```

宏实现的函数体内具名函数，能引用局部变量（`bind&` 是引用捕获）。它对 lambda 的**唯一残余优势**是天然可递归（名字先行声明）；但 lambda 的 `auto fib = [&](auto&& self, int n) { ... self(self, n-1) ... };` 自递归惯用法加上 Y 组合子的知识已经覆盖了这个场景。**判死刑**：被淘汰。

> 实测坑：这个库的宏在 `/W4` 下有固有噪声（C4459 宏内部变量遮蔽），例程里定点压制并注明了原因——宏库的通病。
>
> 实测坑（跨平台写法）：压制**不能只写 MSVC 那一支**。原来的写法是裸 `#pragma warning(push/disable:4459/pop)`，在 clang 上先变成 `-Wunknown-pragmas` 告警；用 `#if defined(_MSC_VER)` 把它围起来之后，clang 立刻报出**另一批**告警（`-Wunused-local-typedef`、`-Wunused-private-field`）——也就是说 MSVC 的 pragma 一直在**顺手盖掉 clang 的不同告警**。正确姿势是三支分开写，并配 `#pragma clang/gcc diagnostic push/ignored/pop`：
> ```cpp
> #if defined(_MSC_VER)
> #  pragma warning(push) / #  pragma warning(disable: 4459) … #  pragma warning(pop)
> #elif defined(__clang__)
> #  pragma clang diagnostic push
> #  pragma clang diagnostic ignored "-Wunused-local-typedef"
> #  pragma clang diagnostic ignored "-Wunused-private-field"
> #  pragma clang diagnostic pop
> #elif defined(__GNUC__)
> #  pragma GCC diagnostic push … #  pragma GCC diagnostic pop
> #endif
> ```

## 4.9 Boost.Phoenix：函数式 EDSL 的完全体

Phoenix（凤凰，Lambda 作者的续作）把整个函数式编程搬进了表达式模板：

```cpp
std::accumulate(v.begin(), v.end(), 0, _1 + _2 * _2);         // 惰性表达式当算法参数
std::for_each(v.begin(), v.end(), if_(_1 < 0)[++ref(neg)]);   // 表达式里内联 if
auto hypot_sq = let(_a = _1, _b = _2)[_a * _a + _b * _b];     // let 绑定
auto abs_it = if_else(_1 < 0, -_1, _1);                        // 产值版三元
auto log_it = ++ref(trace);                                     // 独立动作
// log_it 与 abs_it 可以分开定义、运行期装配、跨函数传递——lambda 做不到
```

运行输出（`phoenix.cpp`）：

```text
平方和 = 172
负数个数 = 3
3-4 直角三角形斜边平方 = 25
3 5 4
construct pair = (3,7)
复合动作运行 7 次, |x| 序列: 3 1 4 5 9 2 6
```

**独门绝技是运行期组装**：lambda 是编译期一次成型的闭包；Phoenix 的表达式是值——可以存进容器、按条件拼接、序列化后重新求值。规则引擎、查询计划、惰性 DSL 的 C++ 实现至今仍走这条路（很多用它的孙子辈 Proto/YAP，见第 27 章）。

> 实测坑：`bind(&std::string::size, _1)` 这类 noexcept 成员函数指针会让 Phoenix 的 result_of 推导直接报错——包一层自由函数即可（例程注释里有）。这是 2026 年的老库与新编译器磨合的典型症状。

## 4.10 Boost.Parameter：真正的命名参数

```cpp
render();                                   // 全默认
render(_width = 120);                       // 省略其他
render(_color = "red", _title = "chart");   // 乱序也行
```

运行输出（`parameter.cpp`）：

```text
render title=untitled width=80 color=black
render title=untitled width=120 color=black
render title=chart width=80 color=red
C++20 指定初始化 title=untitled width=40 color=blue
```

22 个参数的大型 API（图形渲染、科学计算配置）的真实需求。C++20 指定初始化器（`{.width = 40, .color = "blue"}`）覆盖了"命名+默认"的一半需求，但有两个硬限制：**必须按声明顺序**（例程里交换顺序就是 C7560 编译错误）、必须聚合成 struct。Parameter 两条都没有，还能做必选/可选/谓词校验。代价是宏 + 编译时间，小型 API 不值得。

## 4.11 Boost.Compat：反向毕业，std 新特性回移植

这个库讲的是时间线的**反方向**——不是 Boost 进 std，而是把 std 的新组件搬回 C++11，让老代码库用上现代接口：

```cpp
int apply(boost::compat::function_ref<int(int, int)> f, int a, int b);  // C++26 预演

boost::compat::function_ref<int(int,int)> fr = [](int a, int b) { return a * b; };
boost::compat::move_only_function<int()> task = [p = std::make_unique<int>(55)] { return *p; };
```

运行输出（`compat.cpp`）：

```text
function_ref+函数指针: 7
function_ref+lambda:   12
bind_front(add, 7)(8) = 15
move_only_function 持 unique_ptr: 55
移动后调用: 55
```

三个回移植件都值得单独记：

| 组件 | std 对应 | 为什么值得等它/用它 |
|---|---|---|
| `function_ref` | `std::function_ref`（C++26） | 参数传可调用物的**正确默认**：零分配、零所有权、视图语义。比 `const std::function&` 快一个量级 |
| `move_only_function` | C++23 | 能装 move-only lambda（捕获 unique_ptr 的任务）——`std::function` 装不了 |
| `bind_front` | C++20 std | 老标准下的部分应用 |

**选型建议**：库要支持 C++11/14 用户时，`#include <boost/compat/function_ref.hpp>` 拿到与 C++26 完全同形的接口——等代码库升级到新标准，改一行 include 就迁移。

## 4.12 本章选型速查

```text
要装一个可调用物？
  成员/回调存储           → std::function
  参数传递（性能敏感）     → boost::compat::function_ref（未来 std::function_ref）
  捕获 move-only          → std::move_only_function（C++23）/ compat 回移植
要造一个函数值？
  STL 算法一行谓词        → boost::lambda2 的 _1（或就写 lambda）
  组合/管道/分派           → boost::hof
  运行期组装逻辑          → boost::phoenix
要写大型配置 API？         → boost::parameter（小 API 用 C++20 指定初始化器）
要拆解/变换签名？          → boost::callable_traits
要支持老标准？             → boost::compat
```

---


> 上一章：[03 · 所有权革命](03-smartptr.md) ｜ 下一章：[05 · 语言基建先行者](05-langbase.md) ｜ 返回：[README](../README.md)
