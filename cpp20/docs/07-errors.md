# 07 · 错误处理：异常、optional 与 expected

> 对应示例：`examples/07_errors/`

## 7.1 先给结论：三种错误，三把武器

C++ 处理"出错了"的手段比多数语言多，因为不同性质的错误需要不同代价的工具：

| 错误性质 | 例子 | 武器 | 章节 |
|---|---|---|---|
| **预期内的失败**（常规业务分支） | 解析失败、没找到、被零除 | `expected` / `optional` | 本章 |
| **真正的意外**（不变量被打破） | 配置损坏、内存耗尽 | 异常 | 本章 |
| **程序员的 bug** | 前置条件不满足 | `assert` | 本章 + 第 23 章 |

选型哲学一句话：**失败越"正常"，越该出现在类型签名里**（调用方被迫处理）；越"异常"，越适合抛（沿调用栈逃逸直到有人接得住）；bug 则根本不该有"处理"——修它。C++23 的 `expected` 到位后，"返回错误码 / 抛异常"的二选一困境终于有了现代答案。

## 7.2 异常：留给真正的意外

```cpp
double safe_divide(double a, double b) {
    if (b == 0.0) {
        throw std::invalid_argument("除数为零");
    }
    return a / b;
}
// ……
try {
    std::println("10 / 3 = {}", safe_divide(10, 3));
    std::println("10 / 0 = {}", safe_divide(10, 0));  // 抛！
} catch (const std::exception& e) {
    std::println("捕获异常：{}", e.what());  // 捕获异常：除数为零
}
```

`throw` 抛出对象，沿调用栈上溯直到最近的匹配 `catch`。规矩三条：**按 `const std::exception&` 捕获**（基类引用接住所有标准异常、零拷贝）；**抛标准异常家族**（`<stdexcept>` 的 invalid_argument/out_of_range/runtime_error…，都带 `what()` 文案）；**栈展开时局部对象照常析构**——这让异常和 RAII（第 08 章）天然互补，资源永不泄漏。

异常的成本模型要心里有数：不抛时近乎零开销（编译器按"零成本"模型设计），**抛出的一次很贵**（栈展开是重量级操作）。所以"每 tenth 调用必失败"的场景用 expected，"一年触发一次"的才用异常。

## 7.3 optional："可能没有"放进类型

```cpp
std::optional<int> first_even(const std::vector<int>& xs) {
    for (int v : xs) {
        if (v % 2 == 0) {
            return v;
        }
    }
    return std::nullopt;  // 明确的"没有"
}
// ……
std::println("第一个偶数 = {}", first_even(xs).value_or(-1));   // 8
std::println("空表兜底 = {}", first_even({}).value_or(-1));     // -1
```

`std::optional<T>`（C++17）回答一个问题：**值存在吗**。对比老 C 风格 `int first_even(..., bool* ok)` 或哨兵值 `-1`（-1 恰好是合法偶数怎么办？），optional 把"可能没有"编码进类型——不检查就 `value()` 会抛 bad_access，编译器看得见的协议。

API 速查：`has_value()` 判空、`*opt` / `opt.value()` 取值（后者空时抛）、`value_or(fallback)` 带默认取值。C++23 补齐了链式操作（`and_then`/`transform`/`or_else`），玩法与下节 expected 同构。

## 7.4 expected<T, E>：值或错误都在类型里（C++23）

```cpp
std::expected<int, std::string> parse_int(std::string_view text) {
    int value = 0;
    auto [ptr, ec] = std::from_chars(text.data(), text.data() + text.size(), value);
    if (ec != std::errc{} || ptr != text.data() + text.size()) {
        return std::unexpected("不是合法整数: " + std::string(text));
    }
    return value;
}
// ……
auto ok = parse_int("42");
auto bad = parse_int("4x");
std::println("parse(42) = {}", ok.value());               // 42
if (!bad) {
    std::println("parse(4x) 失败：{}", bad.error());       // 不是合法整数: 4x
}
```

`std::expected<T, E>`（C++23）= "T 或 E"的类型：成功时装值、失败时装**带理由的错误**（`std::unexpected("...")` 构造）。它是 optional 的完全升级版——optional 只会说"没有"，expected 会说"为什么没有"。

判空与取值四件套：`if (r)` / `r.has_value()` 判成功；`r.value()`（失败时抛）；`r.error()` 取错误；`*r` 直接取值（先判过空才安全）。**调用方不处理错误连编译都过不了的心态压力**，就是它对代码质量的贡献——签名即文档。

`std::from_chars`（`<charconv>`）顺带认识一下：无异常、无分配、无 locale 的最快数字解析，比 `std::stoi`（抛异常）和 `atoi`（无错误报告）都现代。

## 7.5 链式组合：monadic 风格

```cpp
std::expected<double, std::string> parse_ratio(std::string_view a, std::string_view b) {
    return parse_int(a).and_then([b](int x) {
        return parse_int(b).and_then([x](int y) -> std::expected<double, std::string> {
            if (y == 0) {
                return std::unexpected("除数为零");
            }
            return static_cast<double>(x) / y;
        });
    });
}
// ……
auto r1 = parse_ratio("10", "4");   // 2.5
auto r2 = parse_ratio("10", "0");   // 错误：除数为零
auto r3 = parse_ratio("1o", "4");   // 错误：不是合法整数: 1o
```

`and_then`（失败短路，继续可能失败的操作）与 `transform`（成功值变形）让错误**自动向下传播**，不用一层层 if。同一逻辑的三种写法对照：

| 写法 | 行数 | 错误路径可见性 | 心智负担 |
|---|---|---|---|
| 嵌套 if + 返回码 | ~12 行，箭头型 | 低（要追每个 return） | 高 |
| 异常版 | ~6 行 | 隐藏在 throw 里 | 低，但控制流隐形 |
| **expected 链式** | ~8 行 | **签名与链上显式** | 低 |

判定：**预期失败的管线（解析→校验→计算）用 expected 链**，是可读性和安全性的甜点区。

## 7.6 断言：开发期抓 bug 的地板

```cpp
int amount = 100;
assert(amount > 0 && "金额必须为正");  // Release (NDEBUG) 下会被编译掉
```

`assert(expr && "文案")` 的惯用形：表达式为假时中止并打印表达式与文案。它是**给开发者**的：表达"此处不变量必然成立"，被打破说明代码写错了（不是用户错了）。发布版定义 `NDEBUG` 后 assert 整个消失——所以**绝不能放副作用**（`assert(pop_queue())` 在 Release 里就不弹了）。

运行期校验用户输入 ≠ assert 的事——那是 expected/异常的事。分层测试与断言策略见第 23 章。

## 7.7 坑位清单

1. **catch 按值捕获**：`catch (std::exception e)` 切片+拷贝，多态信息丢失——永远 `const T&`。
2. **optional 没 `value()` 就用**：空 optional 调 `value()` 抛 bad_optional_access——先判再取，或 `value_or` 兜底。
3. **异常当流程控制**：高频率抛接（循环里解析脏数据）性能雪崩——那是 expected 的场景。异常的"意外"频率应是月/年级。
4. **构造函数里抛异常**：合法且安全（成员已构造的会被析构），但构造到一半的对象本身不调析构——RAII 成员是唯一正确姿势（第 08 章回扣）。
5. **assert 里放副作用**：Release 下消失，Debug/Release 行为分叉——assert 只放纯判断。
6. **expected 的 error 类型随手写 string**：教程演示用 string；工程上错误类型用 enum class（可穷举、可 switch）更利于编译器查漏。
