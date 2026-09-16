# 17 · 编译期编程：让计算发生在编译时

> 对应示例：`examples/17_compiletime/`

## 17.1 constexpr 函数：同一份代码，两个世界

```cpp
constexpr unsigned long long factorial(unsigned n) {
    unsigned long long r = 1;
    for (unsigned i = 2; i <= n; ++i) {
        r *= i;
    }
    return r;
}
// ……
static_assert(factorial(10) == 3'628'800ULL);  // 编译期算，构建时验证
constexpr auto fact5 = factorial(5);           // 编译期值
int runtime_n = 6;                             // 运行期输入也能调同一函数
std::println("5! = {}，运行期 6! = {}", fact5, factorial(runtime_n));
```

`constexpr` 函数的承诺：**只要参数是编译期常量，结果就在编译期算出**；参数是运行期值时，它就是普通函数。**一份代码两个世界**——这是 C++11 之前"模板元编程"苦海的全部救赎：老方法要在模板里模拟循环（递归展开）和条件（特化），现代 constexpr 直接写 for 和 if。

`constexpr` 变量则**强制**编译期求值（拿运行期值初始化它直接编译错），这是它和普通 const 的本质区别。函数体自由度逐年放宽：C++14 起可有循环/分支/局部变量，C++20 起甚至能有 if（无 goto），本例的写法在 C++11 时代是编译不过的。

## 17.2 static_assert 与 consteval

```cpp
static_assert(factorial(10) == 3'628'800ULL);  // 编译期断言：免费的单测

consteval int compile_time_square(int v) {
    return v * v;
}
constexpr int side = 12;
std::array<int, compile_time_square(side)> table{};  // consteval 结果当数组长度
std::println("表格长度 = {}", table.size());  // 144
```

`static_assert(常量表达式)` 在**构建期**验证不变量——assert 的编译期版（第 07 章对照过），发布版不会被去掉因为它压根不存在于产物里。数学常数、查表、协议字段偏移这类"逻辑上恒定"的东西，都值得一条 static_assert 护航。

**`consteval`（C++20）**是 constexpr 的严格版：**只许编译期调用**。传运行期值直接编译错——用在"必须是编译期常量"的场景（数组长度、模板参数），让契约长在签名上，而不是等到使用处才报错。

## 17.3 if constexpr：编译期剪枝

```cpp
template <typename T>
std::string describe(const T& value) {
    if constexpr (std::is_arithmetic_v<T>) {
        return "数值: " + std::to_string(value);
    } else if constexpr (std::is_convertible_v<T, std::string_view>) {
        return "文本: " + std::string(value);
    } else {
        return "其他类型";
    }
}
// 数值: 3.140000 / 文本: 文本 / 其他类型
```

`if constexpr (编译期布尔)` 在**实例化时只编译命中的分支**，其余分支当不存在。对比普通 if：普通 if 两个分支都要编译（`std::to_string(value)` 对 Point 编译不过→报错），if constexpr 让"数值走 to_string、文本走 string 构造"在同一个模板里共存——**这是模板世界里写"类型分支"的正道**。

判断条件常用 `<type_traits>` 的 `is_arithmetic_v` / `is_convertible_v`（第 14 章说过，它们是概念的原料）；C++20 起判断条件也可以直接是概念（`if constexpr (std::integral<T>)`）。非模板代码里写 if constexpr 没有意义（类型确定，剪枝无从谈起）。

## 17.4 变参模板与 fold 表达式

```cpp
template <typename... Ts>
auto sum_all(Ts... values) {
    return (values + ...);  // 一元右折叠：((v1+v2)+v3)…
}

template <typename... Ts>
bool all_small(int limit, Ts... values) {
    return ((values < limit) && ...);  // 逻辑与折叠
}
// ……
std::println("sum_all = {}", sum_all(1, 2, 3, 4.5));   // 10.5
std::println("all_small = {}", all_small(3, 1, 2, 3));  // false
```

**变参模板**（variadic template）：`typename... Ts` 声明类型参数包、`Ts... values` 收下任意个数参数（编译期展开）。**fold 表达式**（C++17）把参数包按运算符折叠成一串表达式——`(values + ...)` 展开为 `((v1+v2)+v3)+v4`，`((values < limit) && ...)` 展开为 `(v1<limit) && (v2<limit) && …`。

四种形态认识两种就够用：

| 形态 | 写法 | 展开方向 |
|---|---|---|
| 一元右折叠 | `(pack op ...)` | `v1 op (v2 op (v3 op …))` |
| 一元左折叠 | `(... op pack)` | `((v1 op v2) op v3) op …` |
| 二元折叠 | `(init op ... op pack)` | 带初值，**空包不报错** |

一元折叠对**空参数包**多半报错（`+` 没有单位元），二元的 `0 + ... + values` 空包得初值——写通用工具时记得这点（见坑位）。变参模板是 `std::make_unique`、`emplace_back`、`std::format` 这些"万能参数转发"设施的底层机械。

## 17.5 边界：编译期能做什么

constexpr 函数的自由度清单（C++20/23 现状）：

| ✅ 可以 | ❌ 不可以 |
|---|---|
| 循环、分支、局部变量 | 静态/线程局部变量 |
| 算术、指针运算（不越界） | 虚函数调用 |
| 调用其他 constexpr 函数 | 未初始化读、UB（编译器会抓） |
| C++20：try/catch（不能抛）、constexpr 容器/ string（析构要 constexpr） | IO（print、文件）——老天爷的规定 |

**模板元编程（TMP）一段话**：C++11 之前"编译期计算"只能用模板特化模拟（递归展开当循环、特化当分支），产生了大量著名的黑魔法（SFINAE、expression templates）。现代路线：**constexpr 管计算、concepts 管约束、if constexpr 管分支**，TMP 退守少数极致库（如表达式模板优化）。认识历史代码即可，新代码不必再学全套黑魔法。

## 17.6 坑位清单

1. **一元折叠吃空包**：`sum_all()` 零参数——`(values + ...)` 没有单位元，编译错。改二元折叠 `0 + ... + values`，或约束至少一个参数。
2. **constexpr 函数偷偷依赖全局状态**：读了非 constexpr 全局变量→在编译期语境下直接编译错，运行期语境下能跑——两副面孔不一致。constexpr 函数保持纯净（输入决定输出）。
3. **if constexpr 写在非模板里**：类型全确定，分支永远只有一条活——普通 if 就够，别加戏。
4. **编译时间失控**：重 constexpr 递归、超长展开让构建从 30 秒变 10 分钟。编译期计算也要看账单——把不变的查表 constexpr 化，把每次都变的留运行期。
5. **consteval 参数手滑传运行期值**：直接编译错（这正是它的价值）；真要两栖就退回 constexpr。
6. **把编译期常量当安全边界**：constexpr 只保证"何时算"，不保证"算得对"——值对不对仍要 static_assert/单测来验。
