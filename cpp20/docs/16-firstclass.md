# 16 · 一等函数：函数指针、仿函数与 std::function

> 对应示例：`examples/16_firstclass/`

第 06 章见了 lambda 的雏形，第 15 章把它当谓词使——本章把"函数当值用"的整条演化链走通：**函数指针 → 仿函数 → lambda → std::function**。

## 16.1 函数指针：能"换弹"的最原始形态

```cpp
long add(long a, long b) { return a + b; }
long multiply(long a, long b) { return a * b; }

using BinOp = long (*)(long, long);   // “函数指针类型”的别名
BinOp op = add;                       // 也常写 auto* op{add};
op(3, 5);                             // 8
op = multiply;                        // 同签名可换函数
op(3, 5);                             // 15
```

函数代码也躺在内存里，有地址就能存进指针；指针类型必须带全**返回类型 + 形参表**（调用约定的一部分），所以只能指向签名精确匹配的函数。原始声明语法 `long (*op)(long, long)` 里括号不能省（省了就变成"返回函数指针的函数声明"）——实战写 `auto*` 或 `using` 别名，别手写第二遍。

函数指针的第一个用途就是**回调**：把"怎么比较"作为参数传给"怎么找"——

```cpp
template <typename T, typename Comparison>
const T* find_optimum(const std::vector<T>& values, Comparison compare);
find_optimum(nums, [](const int& a, const int& b) { return a < b; });  // 找最小
find_optimum(names, by_length);                                          // 找最长
```

接收方（高阶函数）拿"另一个函数当参数"的函数。**无捕获 lambda 可以隐式转换成函数指针**（编译器替它生成了一个普通函数），但签名要精确吻合——`[](int, int)` 转不成 `bool(*)(const int&, const int&)`。C 风格 API 的回调参数（`qsort` 的 compar）至今长这样。

## 16.2 仿函数：带状态的"函数对象"

```cpp
class Nearer {
public:
    explicit Nearer(int target) : target_{target} {}
    bool operator()(int a, int b) const {          // 函数调用运算符
        return std::abs(a - target_) < std::abs(b - target_);
    }
private:
    int target_;                                    // 状态：比较基准
};
find_optimum(nums, Nearer{50});    // 离 50 最近的数
```

**重载了 `operator()` 的类的对象**叫仿函数（函数对象）：能像函数一样调用，但它是对象——**可以有成员变量（状态）、可以有多个重载、可以被内联优化**。函数指针装不下的"比较基准从哪来"这个问题，仿函数用构造函数解决。C++23 起**不碰成员状态的 `operator()` 建议加 `static`**（少传一个 this，还允许 `&Cls::operator()` 取地址）。你已经用过一堆仿函数了：`std::greater{}`（第 15 章排序的降序比较器）就是 `<functional>` 里现成的仿函数，家族还有 `less`/`plus`/`minus` 全套运算符的"官方造"。

## 16.3 lambda：编译器替你写的仿函数

```cpp
int threshold = 20;
auto by_value = [threshold](int v) { return v > threshold; };   // 值捕获：快照
auto by_ref = [&threshold](int v) { return v > threshold; };    // 引用捕获：实时
threshold = 60;
// by_value 仍比 20（4 个），by_ref 实时比 60（2 个）
```

lambda 表达式 = **编译器现场生成一个仿函数类**：`[捕获](参数) { 体 }` 里的捕获列表就是那个类的成员变量初始化列表。理解了 16.2 的 Nearer，就理解了 lambda 的一切——`[threshold]` 生成的类长得和 Nearer 一模一样。捕获语义全家福：

| 写法 | 语义 | 何时用 |
|---|---|---|
| `[x]` | 值捕获：拷贝快照，默认不可改（`mutable` 解锁改**副本**） | 小变量默认 |
| `[&x]` | 引用捕获：实时读写本体 | 大对象且 lambda 当场用完 |
| `[x = expr]` | 初始化捕获：新名字接任意表达式（C++14） | `[p = std::move(ptr)]` 捕走 move-only |
| `[this]` | 捕获 this 指针 → 全成员可访问 | 成员函数内定义 lambda（示例的 Counter） |
| `[=]` / `[&]` | 全捕获（历史代码常见） | **新代码别用**——读不出 lambda 碰了什么 |

**引用捕获悬垂是 lambda 头号事故**（第 15 章坑位回锅）：lambda 活得比局部变量久（存进容器、跨线程、被返回）→ 调用时 UB。存下来的 lambda 一律值捕获。

泛型 lambda 两种写法都认识：`[](const auto& x)`（第 15 章用过——每个调用类型各实例化一份，零开销）和 C++20 的显式模板形参 `[]<typename T>(const T& a, const T& b)`（需要"两个参数同类型"这类约束时用，混型实参直接编译错）。

## 16.4 std::function：能装一切可调用的容器

```cpp
std::function<bool(int, int)> chooser;
chooser = [](int a, int b) { return a < b; };   // 装 lambda
chooser = Nearer{50};                            // 换成仿函数——继续换弹
chooser(43, 91);                                 // true
std::function<void()> empty;
empty == nullptr;                                // true；空调用抛 bad_function_call
```

函数指针、仿函数、lambda **类型各异**（lambda 的类型只有编译器知道），模板参数（`Comparison`）虽能通吃但会为每种类型实例化一份代码。`std::function<R(Args...)>` 是**类型擦除的统一外壳**：能装、能拷、能换弹、能进容器——代价是多一层间接调用和可能的堆分配。**回调注册表**是它的招牌场景：

```cpp
std::vector<std::function<void()>> on_shutdown;
on_shutdown.push_back([&cleaned] { ++cleaned; });
on_shutdown.push_back([] { std::println("再见！"); });
for (const auto& task : on_shutdown) task();
```

一堆"类型各不相同的稍后执行"塞进同一个 vector——函数指针做不到（类型不同），模板做不到（容器元素类型必须唯一）。C++23 补了 `std::move_only_function`：装 move-only 仿函数（如捕获了 `unique_ptr` 的 lambda），`std::function` 要求可拷贝装不下它。选型顺口溜：**能 `auto` 接 lambda 就别包 function；要"当变量管理"（存容器/换弹/成员变量）才上 function。**

## 16.5 坑位清单

1. **引用捕获悬垂**：lambda 活得比变量久（容器/跨线程/返回值）→ UB。存下来的 lambda 一律值捕获或初始化捕获。
2. **无捕获 lambda 转函数指针签名不匹配**：`[](int,int)` ≠ `bool(*)(const int&, const int&)`——按目标的签名原样写。
3. **`[=]` 隐式捕 this（C++20 弃用）**：老代码 `[=]` 里用成员实际捕的是 this 指针——新代码显式 `[this]` 或 `[member]`。
4. **`mutable` 以为是改本体**：它只解锁改**捕获的副本**；要改本体用引用捕获。
5. **`std::function` 空着就调**：抛 `bad_function_call`——判空或保证初始化。
6. **`std::function` 装 move-only 仿函数**：装不下（要求可拷贝）——C++23 用 `move_only_function`。
7. **函数指针未初始化就调**：与裸指针同罪——`auto* op{fn};` 起步，别裸声明。
