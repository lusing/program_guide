# 12 · 运算符重载：让类像内建类型一样运算

> 对应示例：`examples/12_opoverload/`

第 11 章的 Vec2 已经用过 `+` 和 `<=>`；本章把它们拼成完整的方法论：**哪些运算符、成员还是非成员、按什么惯例写**。

## 12.1 运算符就是名字特殊的函数

```cpp
Money total{price};
total += fee;                 // 等价 total.operator+=(fee)
constexpr Money operator+(const Money& rhs) const;   // a + b 即 a.operator+(b)
```

`operator+`、`operator[]`、`operator<=>`……都是函数名，`a + b` 只是 `a.operator+(b)` 的中缀写法。**铁律只有三条**：不能发明新运算符、不能改优先级/结合性/操作数个数、至少一个操作数是类类型（不能重载 `int + int`）。该不该重载的判据（第 11 章说过，这里正装）：**类的数学语义自然才重载**——金额相加、向量点乘、日期比较：重载让代码像数学；字符串"减法"：起个有名函数。

一个反例值得背下来：给 Box 按**体积相等**定义 `==`，两个尺寸完全不同的箱子会"相等"——用户看到 `==` 想的是"相等"，不是"等体积"。要特殊语义就叫 `hasSameVolumeAs()`，可读性比紧凑永远优先。同理**永远别重载 `&&`/`||`**：重载版无法短路（两个操作数总会求值），行为与内建版注定不同。

## 12.2 算术：先写 `op=`，再用它实现 `op`

```cpp
constexpr Money& operator+=(const Money& rhs) {     // 1) 复合赋值：改自身、返回 *this
    cents_ += rhs.cents_;
    return *this;
}
[[nodiscard]] constexpr Money operator+(const Money& rhs) const {   // 2) 二元 + 借力 +=
    Money copy{*this};
    copy += rhs;
    return copy;
}
[[nodiscard]] constexpr Money operator-() const { return Money{-cents_}; }   // 一元负号：返回新值
```

这是标准库自己都在用的惯例：**复合赋值是"地基"（修改自身、返回 `*this` 引用——链式赋值的基石），二元运算拷贝左值、复用 `op=`、按值返回新对象**。`a + b + c` 会产生临时对象但别慌——RVO（第 20 章）几乎总能把它们优化掉。一元运算符（`-`、`+`、`!`）返回**新对象**，不碰自身。

## 12.3 左操作数不是本类：必须写成非成员

```cpp
[[nodiscard]] constexpr Money operator*(double k, const Money& m);   // 2.0 * price
// 想让 price * 2.0 也通，就再写一个成员版 operator*(double)——两个方向各写一个才顺手
```

成员运算符的左操作数**永远是本类**（就是 this）。`2.0 * price` 的左操作数是 double——double 加不了成员函数，只能写成**非成员函数**。判别式：比较运算符（`<=>`/`==`）编译器会自动交换操作数顺序（`6.0 <= box` 会改写成 `box >= 6.0`），其余二元运算符想要两个方向都得自己写。非成员版本放**与类相同的命名空间**（第 24 章 ADL 的伏笔）。

## 12.4 比较：`= default` 一步到位

```cpp
auto operator<=>(const Money&) const = default;   // 连 == 一起生成
```

第 11 章 Vec2 手写过 `<=>`；当"成员按声明序做字典序比较"就是你想要的语义时，`= default` 让编译器生成**并永久维护**（加新成员自动跟上，手写版最经典的 bug 就是忘了补新成员）。想按体积比就手写（返回类型选 `partial_ordering`，成员含 double 时如此）；只要"有序且一致"（排序、当 map 的键）就用 default——字典序还更强。默认版拿不到"跨类型比较"（`Money` vs `long long` 得手写），且成员缺失 `<=>` 时 default 版会被隐式删除。

## 12.5 类型转换：`explicit` 挡住暗门

```cpp
[[nodiscard]] constexpr explicit operator double() const { return cents_ / 100.0; }
static_cast<double>(total);   // ✔ 显式写明
// double x = total;          // ✘ 编译错：explicit 禁止隐式转换
```

转换运算符 `operator T()` 让类能变成 T（无返回类型——返回类型就写在函数名里）。**永远加 explicit**：隐式转换会让 `money1 == money2` 意外变成两个 double 在比、让重载解析凭空多出十条歧义路径。单参构造函数同理（第 11 章 `explicit Session` 的回声）。

## 12.6 下标运算符：引用才能"写穿" + C++23 多参数

```cpp
[[nodiscard]] int& operator[](std::size_t i) { return cells_[i]; }        // 非 const：返回引用
[[nodiscard]] int operator[](std::size_t i) const { return cells_[i]; }   // const：返回值
g[0] = 10;            // 左值：int& 写穿到内部数组
g[1, 2] = 99;         // C++23：operator[] 可收多参 —— 矩阵写 m[row, col]，不是 m[row][col]
```

返回**引用**（非 const 版）下标才能出现在赋值号左边——返回值的话 `g[0] = 10` 改的只是临时拷贝。const/非 const 两个版本配套是"容器类"的标准姿势。C++23 允许多参数 `operator[]`，多维数据的天然写法从 `m(r, c)`（函数调用）或 `m[r][c]`（嵌套代理）统一成 `m[r, c]`——`std::mdspan` 就用它（第 29 章）。**提醒**：标准容器用 `at()` 才查边界，`operator[]` 不查（越界 UB）——自定义类型想要"带检查的下标"，抛 `out_of_range` 是惯例（第 10 章）。

## 12.7 print 时代的"输出重载"：特化 std::formatter

```cpp
template <>
struct std::formatter<Money> {
    constexpr auto parse(std::format_parse_context& ctx) { return ctx.begin(); }
    auto format(const Money& m, std::format_context& ctx) const {
        long long c = m.cents();
        const char* sign = c < 0 ? "-" : "";
        if (c < 0) c = -c;
        return std::format_to(ctx.out(), "{}{}.{:02d} 元", sign, c / 100, c % 100);
    }
};
std::println("{}", total);    // "17.45 元" —— print 直接认识 Money 了
```

老 C++ 的输出重载是 `operator<<(std::ostream&, const T&)`（存量代码遍地都是，认得即可）；**print/format 时代对应物是特化 `std::formatter<T>`**——实现 `parse`（吃格式说明，最简版原样返回）和 `format`（往 `ctx.out()` 写）。`format_to` + `{:02d}` 处理"分"的两位补零和负号——这就是 12.50 元格式的来历。函数调用运算符 `operator()` 不在本章——它是"仿函数"，第 16 章一等函数的主角。

## 12.8 坑位清单

1. **重载 `&&`/`||`**：无法短路——用 `&`/`|` 的语义提醒读者"两边都会算"。
2. **`==` 语义反直觉**：等体积 ≠ 相等——特殊语义起有名函数。
3. **二元 `op` 不借 `op=`**：两份逻辑两份 bug——地基法 `+=` 写一遍，`+` 复用。
4. **`operator[]` 返回值而非引用**：`g[0] = x` 改了个寂寞——非 const 版返回 `T&`。
5. **转换运算符不加 explicit**：静默转换引入重载歧义——一律 explicit。
6. **手写比较忘了跟成员变动**：加字段忘补 `==` 是经典陈年 bug——能 default 就 default。
7. **`m[r][c]` 的代理陷阱**：自定义矩阵在 C++23 直接写 `operator[](r, c)`，一步到位。
