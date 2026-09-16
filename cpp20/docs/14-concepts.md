# 14 · 概念：给模板参数立规矩

> 对应示例：`examples/14_concepts/`

## 14.1 痛点先行：模板报错墙

调用第 13 章的模板，传了个不支持的类型：

```cpp
sum_all(std::vector<std::vector<int>>{...});  // vector 没有 operator+
```

C++20 之前的报错是一堵墙：在 `sum_all` 内部第一处用到 `+` 的地方爆炸，附带你从未听过的实例化栈。**问题不是错误难，是错误报错了地方**——责任在调用方传错类型，火却在模板内部烧。

概念（concepts，C++20）把约束提到签名上：`template <Addable T>` 读作"T 必须可加"。传错类型时错误变成一句人话：**"constraint not satisfied: Addable"在调用行**。这也是给读者的阅读信号：约束是模板的自述文档。

## 14.2 requires 表达式：自己写概念

```cpp
template <typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::convertible_to<T>;  // 要求 a+b 存在且结果能转回 T
};
```

概念是**编译期布尔**，值为"类型是否满足要求"。`requires(T a, T b) { ... }` 里写"合法即满足"的表达式——逐词拆解上面这行：

- `requires (T a, T b)`：给我两个 T 类型的值 a、b（只用于检查，不真运行）；
- `{ a + b }`：这个复合要求——表达式 `a + b` 必须**能编译**；
- `-> std::convertible_to<T>`：且结果类型能转换回 T。

简单要求（不带返回约束）也常用：`requires(T a) { a.sort(); ++a; }` 表示"能调 sort、能自增"。概念能组合：`concept X = A && B;`。

## 14.3 三种用法：把约束写上签名

```cpp
template <Addable T>                      // 写法一：直接当约束
T sum_all(const std::vector<T>& xs) { … }

template <typename T>
    requires std::is_arithmetic_v<T>      // 写法二：requires 子句
T half(T v) { return v / 2; }
// 写法三：简写（auto 位上直接放概念）
// void print_twice(std::integral auto x) { … }
```

三种姿势等价，选择看口味与场景：**自定义概念用写法一**（最像"类型"）；**临时组合现成条件用写法二**；**单参数快速约束用写法三**。示例的 `half` 用写法二演示 `std::is_arithmetic_v`（`<type_traits>` 的编译期布尔，C++11 时代的老前辈——概念接管后它退居幕后当原料）。

标准库自带概念速查（`<concepts>`，C++20）：

| 概念 | 要求 |
|---|---|
| `std::integral` / `std::floating_point` | 整数 / 浮点 |
| `std::same_as<T>` / `std::convertible_to<T>` | 同型 / 可转 |
| `std::equality_comparable` / `std::totally_ordered` | 可 == / 全序 |
| `std::invocable<F, Args...>` | 可像函数一样调用 |
| `std::ranges::range` | 是个 range（容器/视图） |

## 14.4 约束重载：按能力分派

```cpp
template <typename T>
    requires std::integral<T>
const char* kind(const T&) {
    return "整数";
}

template <typename T>
    requires std::floating_point<T>
const char* kind(const T&) {
    return "浮点";
}

template <typename T>
const char* kind(const T&) {
    return "其他（兜底）";
}
// ……
std::println("kind(42) = {}", kind(42));        // 整数
std::println("kind(1.5) = {}", kind(1.5));      // 浮点
std::println("kind('c') = {}", kind('c'));      // 整数！char 是整数类型
std::println("kind(vector) = {}", kind(nums));  // 兜底
```

同一函数名、不同约束——编译器**优先选约束更严格的版本**（包含排序：一个约束蕴含另一个时，强者为胜），都不满足走兜底。注意本例实打实的教训：**三个重载的形参形式必须完全一致**（都是 `const T&`）——示例开发时就踩过 `T` 与 `const T&` 混用导致"对重载函数的调用不明确"（C2668）的坑，统一后才生效。

这套"按能力分派"替代了老 C++ 的两件黑魔法：**tag dispatch** 和 **std::enable_if**（SFINAE）。见到存量代码里的 `typename std::enable_if<...>::type`，心里翻译成"手写版 concepts"即可，新代码一律用概念。

## 14.5 static_assert：概念是编译期布尔

```cpp
static_assert(Addable<int>);              // int 可加：通过
static_assert(Addable<std::string>);      // string 也可加（拼接）
// static_assert(Addable<std::vector<int>>);  // 编译失败：vector 没有 +
```

概念既然是编译期布尔，就能 `static_assert`（第 03 章伏笔回收）——给类型约定写"合同测试"。更常见的联动是 **if constexpr**（第 17 章）：`if constexpr (std::integral<T>)` 在模板里按能力走不同分支——概念做判断，if constexpr 做剪枝，天生一对。

## 14.6 坑位清单

1. **约束重载形参不一致**：`f(T)` 与 `f(const T&)` 并存时包含排序不生效，调用二义（C2668）——同族重载形参形式钉死一致（本示例的实测教训）。
2. **概念是"能做什么"不是"是什么"**：`Addable` 不关心继承血缘，只关心 `a + b` 能否编译（鸭子类型的编译期版）。想着"用概念模拟 OO 类型层次"会失望。
3. **约束了概念还是报老长错**：约束在签名上才提前爆；约束只写了 `typename T`（没概念）就还是老世界。检查是不是真的把概念写上去了。
4. **auto 位概念的位置手滑**：`std::integral auto x`（对）与 `auto std::integral x`（错）——概念在 auto **前面**。
5. **自定义概念过度检查**：`requires(T a, T b) { a + b; a - b; a * b; a / b; }` 全都要——约束写多一眼，适用面窄一分。只写真正需要的最小要求（接口最小主义），模板才好复用。
