# 26 · 现代元编程：mp11 / hana / fusion / tti / function_types

> 对应示例：`examples/26_modern_tmp/`（5 个例程）

Boost 的元编程分两纪元：古典（MPL/Preprocessor，27 章）与现代（本章）。现代纪元的标志是**C++11/14 的力量**：别名模板让元函数变成一行推导、变参模板让列表成为一等公民、泛型 lambda 直接进了编译期。

## 26.1 Boost.Mp11（2015）：现代 TMP 的事实标准

Mp11 的哲学：类型列表 + 函数式三件套（map/filter/fold），全部用 `using` 别名实现——无运行期痕迹、报错友好：

```cpp
using L = mp::mp_list<int, float, double, char>;
mp::mp_transform<std::add_pointer_t, L>;         // map
mp::mp_copy_if<L, std::is_floating_point>;        // filter
mp::mp_fold<Cnts, mp_int<0>, mp::mp_plus>;        // fold/reduce
mp::mp_find<L, double>;  mp::mp_contains<L, char>;
mp::mp_sort<Sizes, mp::mp_less>;  mp::mp_repeat<...>;
```

运行输出（`mp11.cpp`）：

```text
mp_transform OK（第 0 个变 int*）
mp_copy_if OK（浮点数 2 个）
mp_fold 求和 = 6
double 的下标 = 2 mp_size = 4
mp_contains<char> OK
按 sizeof 排序后最小 = char 的大小 OK
mp_repeat 生成 3 元列表 OK
自检通过
```

⭐ **2026 年写 TMP 的默认选择**。Describe/PFR（18 章）、JSON 等新库的底层全是它。C++26 反射落地前，mp11 就是"类型列表操作"的标准词汇。

## 26.2 Boost.Hana（2015）：编译期 STL

Hana 的野心：**类型和值用同一套容器与算法**——`tuple` 里可以装类型也可以装值，`transform/filter/any_of` 对两者通吃：

```cpp
auto animals = hana::make_tuple(BOOST_HANA_STRING("cat"), ...);
hana::contains(animals, BOOST_HANA_STRING("dog"));       // 编译期查
auto types = hana::tuple_t<int, float, double>;          // 类型也能装
hana::transform(types, [](auto t){ return hana::sizeof_(t); });
hana::filter(types, [](auto t){ return hana::sizeof_(t) >= 8_c; });
```

运行输出（`hana.cpp`）：

```text
动物数 = 3
有 dog? 1
类型数 = 3
有 float? 1
transform 取 sizeof OK
≥8 字节的类型数 = 1
map 里 x = 3
if_ = 真分支
自检通过
```

⭐ 通用 TMP（尤其"跨类型与值"的场景）；配合 `BOOST_HANA_ADAPT_STRUCT` 可给结构体编译期按名访问（Describe 的同族能力）。

> 实测坑：`"str"_s` 字面量在 `/std:c++latest` 下撞上标准库新字面量解析（找不到运算符）——用 `BOOST_HANA_STRING("str")` 宏等价替代。

## 26.3 Boost.Fusion（2005）：结构体 ↔ 序列的桥

Fusion 的招牌：**任意结构体适配成异构序列**（`BOOST_FUSION_ADAPT_STRUCT`），之后 transform/for_each/at_c 全套可用：

```cpp
struct Point3 { double x, y, z; };
BOOST_FUSION_ADAPT_STRUCT(Point3, x, y, z)
at_c<1>(p);                              // p.y —— 编译期按下标
for_each(p, [](const auto& v){ ... });   // 遍历成员
auto doubled = transform(p, ×2);         // 成员级变换
```

运行输出（`fusion.cpp`）：

```text
at_c<1> = ada
for_each: 7 ada 3.5
Point3 的 y = 2.5
成员遍历: 1.5 2.5 3.5
翻倍后 x = 3
自检通过
```

**定位**：序列化（第 30 章 JSON/ptree 的结构体遍历底座）、结构体泛型打印。Hana 是它的现代继任，但 Fusion 在 Boost 生态里仍是 JSON/Spirit/Fusion-MPL 桥的既定底座。

## 26.4 Boost.TTI（2011）：类型体检

"有没有这个成员/嵌套类型/成员函数"——SFINAE 分派的地基：

```cpp
BOOST_TTI_HAS_TYPE(value_type)               // 生成 has_type_value_type<T>
BOOST_TTI_HAS_MEMBER_FUNCTION(reset)         // 生成 has_member_function_reset<T, R>
if constexpr (has_member_function_reset<T, void>::value) obj.reset();
```

运行输出（`tti.cpp`）：

```text
Full 有 value_type? 1
Bare 有 value_type? 0
Full 有 reset()? 1
Full: 已重置 / Bare: 无 reset 可调
自检通过
```

**与 C++20 的关系**：`requires { obj.reset(); }` 能做同样的事且更好读——但 TTI 支持到 C++03，且能检测嵌套类型/静态成员/数据成员/模板等 requires 不便表达的东西。⭐ 老标准与新需求的桥。

> 实测坑：宏生成的元函数在**全局命名空间**（`boost::tti::has_member_function_reset` 写法编不过）。

## 26.5 Boost.FunctionTypes（2004）：函数类型解剖刀

比 callable_traits（04 章）更底层：把任意函数类型拆成**构件**（返回/参数/调用约定/成员性），也能反向拼装：

```cpp
parameter_types<F>;     // 参数类型序列
result_type<F>;         // 返回类型
is_member_function_pointer<M>;
```

运行输出（`function_types.cpp`）：

```text
是函数类型? 1
参数个数 = 2
返回类型与 int 同? 1
是成员函数指针? 1
自检通过
```

**选型**：现代代码优先 callable_traits（04 章，C++11 风格）；FunctionTypes 的独门是**反向拼装**（从参数序列重新构造函数类型——绑定器/信号库的底层技术）。

---


> 上一章：[25 · 线代、图像与 GPU](25-compute.md) ｜ 下一章：[27 · 古典元编程](27-classic-tmp.md) ｜ 返回：[README](../README.md)
