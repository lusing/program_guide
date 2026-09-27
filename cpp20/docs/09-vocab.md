# 09 · 词汇类型：pair、tuple、variant 与 any

> 对应示例：`examples/09_vocab/`

## 9.1 什么是"词汇类型"

有些类型会像 int、double 一样天天出现在你的签名里——标准库管这类"通用积木"叫**词汇类型（vocabulary types）**。它们把常见的语义组合直接编码进类型系统：

| 你想表达的 | 词汇类型 | 章节 |
|---|---|---|
| 可能有值 / 可能没有 | `optional<T>` | 第 10 章 |
| 值，或带理由的错误 | `expected<T, E>` | 第 10 章 |
| 只读字符串参数 | `string_view` | 第 07 章 |
| 任意连续序列参数 | `span<T>` | 第 08 章 |
| **恰好两个值** | `pair<A, B>` | 本章 |
| **固定个数的异质值** | `tuple<Ts...>` | 本章 |
| **备选集合里选一个** | `variant<Ts...>` | 本章 |
| **任意类型装一个** | `any` | 本章 |

## 9.2 pair：两个值打一个包

```cpp
std::pair<std::string, int> lang{"cpp", 23};
lang.first;   lang.second;          // 成员名就叫 first / second
auto [name, year] = lang;           // 结构化绑定拆开
```

pair 是 tuple 的两元特例，日常两大来源：**map 的元素类型就是 `pair<const Key, Value>`**（`for (const auto& [k, v] : m)` 绑定的就是它，第 14 章），以及返回两个相关值的函数（`std::minmax` 返回 `pair`）。能用结构化绑定就别写 `.first`——两个裸 `.first` 的可读性惨案多发生在 pair 套 pair 时。

## 9.3 tuple：任意个数的值打一个包

```cpp
std::tuple<std::string, int, double> point{"原点", 3, 4.5};
std::get<0>(point);                      // 按下标取（类型唯一时也可 std::get<std::string>）
auto [label, x, y] = point;              // 结构化绑定按位置拆
std::tie(a_label, a_x, std::ignore) = point;   // 拆到已有变量，跳过的用 ignore
std::tuple_cat(point, std::make_tuple("附注")); // 元组拼接
```

tuple 把"一条记录"做成值：能装进容器、能当返回值、能比较（逐元素字典序）。按位置取值（`get<0>`）意味着**结构决定语义**——超过三个元素就该换成带名字的 struct 了（`.name` 比 `get<2>` 自文档）。`std::ignore` 占位、`tuple_cat` 拼接是工具箱里的常客。

## 9.4 variant：类型安全的 union

```cpp
using Value = std::variant<int, std::string, bool>;
Value v{42};
v.index();                          // 0 —— 当前备选的下标
std::get<int>(v);                   // 取当前值；类型不符抛 bad_variant_access
std::get_if<int>(&v);               // 指针式取值：不符返回 nullptr，不抛
v = std::string{"hello"};           // 换备选：旧值先析构（union 做不到的事）
```

C 的 union 所有成员**共享内存**，写一个读另一个是 reinterpret 的温床；variant 同一时刻只装**备选类型之一**，并且**记着自己装的是哪个**。取错类型抛 `bad_variant_access`——错误从 UB 升级成异常，这就是"类型安全 union"的含义。

**`std::visit` + 重载集**是 variant 的灵魂用法——对"当前是哪种值"做**穷举**分派：

```cpp
template <class... Ts>
struct overloaded : Ts... {
    using Ts::operator()...;             // C++20：继承全部 lambda 的调用运算符
};
std::string desc = std::visit(overloaded{
    [](int i)               { return "整数 " + std::to_string(i); },
    [](const std::string& s){ return "字符串 \"" + s + "\""; },
    [](bool b)              { return std::string{"布尔 "} + (b ? "true" : "false"); },
}, w);
```

好处是编译器级的：**漏写一个备选直接编译错**——以后 variant 加新备选，所有忘更新的 visit 一夜爆红。这正是模板章说过的"想一个栈装多种类型要 variant"（第 18 章）的正脸。

## 9.5 any：装得下任何类型的盒子

```cpp
std::any box{std::string{"可装任何东西"}};
std::any_cast<std::string>(box);    // 取出：类型不符抛 bad_any_cast
box = 3.14;                          // 随时换成任意可拷贝类型
```

any 走**类型擦除**路线：不限定备选集合，什么都装，取的时候 `any_cast<T>` 对暗号。灵活的代价是**取值必须知道装的是什么**（错了抛异常）、存取各有一次类型检查/可能的堆分配。**选型口诀：备选集合写得出来就用 variant（编译器帮你穷举），写不出来才 any**——任何"运行期才知道类型"的场景（脚本值、属性表）是 any 的领地。

## 9.6 坑位清单

1. **variant 取错类型**：`std::get<T>(v)` 在不符时抛 `bad_variant_access`——先 `holds_alternative<T>(v)` 判或用 `get_if`。
2. **variant 也能进"无值"状态**：异常时机的换备选可能留下 `valueless_by_exception()`——极罕见，知道名字即可。
3. **any_cast 对不上**：抛 `bad_any_cast`——any 装的到底是什么，全靠调用约定维系，慎入公共接口。
4. **tuple 过长**：超过 3 个元素改 struct——`get<3>` 是"魔法数字"的另一种写法。
5. **结构化绑定不能整体赋值**：`auto [a, b] = p` 拆出的是新变量；要写回用 `std::tie(a, b) = p`。
6. **visit 里漏一个备选**：编译错（这是特性！）——别用 `[](auto)` 兜底偷懒，那等于关掉穷举检查。
