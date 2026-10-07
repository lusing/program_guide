# 02 · 单一职责与开闭原则

六大原则是 23 个模式的公理系统：每个模式都是某几条原则的工程化落地。本章讲其中最常被并提的两个——单一职责（SRP）回答"一个类该干什么"，开闭原则（OCP）回答"需求变化时代码该怎么长"。理解了这一对，后面遇到工厂方法、策略、装饰时你会发现它们只是把这两句话分别用在"创建"和"行为"上的固定套路。

## 单一职责：一个类只有一个变更理由

### 朴素写法及其坏处

之禅第 1 章的例子是用户管理：把用户的属性、行为、展示全塞进一个接口。我们换一个更日常的场景——发工资。朴素写法是把员工的一切都写进一个类：

```cpp
struct Employee {
    std::string name;
    double base{};
    int hours{};
    double rate{};

    double calculate_pay() const;                  // 算钱：财务部关心
    std::string format_report() const;             // 报表：行政部关心
    void save_to_database() const;                 // 存储：IT 部关心
};
```

这个类看起来"很内聚"——员工的事都在 `Employee` 里。问题在**变化的方向**：财务部改了加班费算法，你要动 `Employee`；行政部改了报表格式，你要动 `Employee`；数据库换了，你还要动 `Employee`。三个互不相关的部门，共享同一个改坏彼此代码的机会。而且任何用到 `Employee` 的模块（哪怕只用它的名字字段）都因为这三个方法的改动被迫重编。刘伟书 2.2 节的定义说得很准：**应该有且仅有一个原因引起类的变更**。"原因"不是指代码行数，而是指**变化的驱动者**。

### 拆开：两个自由函数

修正后的代码（示例 `srp.hpp` 的核心）：

```cpp
struct Employee {
    std::string name;
    double base{};
    int hours{};
    double rate{};
};

// 财务域关心的只有"多少钱"，与展示无关。
inline double calculate_pay(const Employee& e) {
    return e.base + e.hours * e.rate;
}

// 报表域只做字符串拼装，不知道钱是怎么算出来的。
inline std::string format_report(const Employee& e, double pay) {
    return std::format("{} 应发 {}", e.name, pay);
}
```

注意两个设计决定。第一，`Employee` 退化成了纯数据结构——它只剩"是数据"这一个职责，行为全部外移。第二，拆出来的是**自由函数**而不是新类的成员函数。C++ 教你写类，但没人逼你什么都要塞进类：`calculate_pay` 不持有任何状态，做成自由函数以后它的依赖（只读 `Employee`）在签名上一目了然，测试时构造一个 `Employee` 就能调，不需要 mock 任何基础设施。之禅 1.4 节的"最佳实践"说的就是这个：职责粒度落到方法级，比形式上的类级拆分更实用。

验证输出的前两行就是这两个函数的运行结果：

```text
SRP: alice 应发 5000
```

`calculate_pay({base:3000, hours:80, rate:25})` 得 `3000 + 80×25 = 5000`，`format_report` 把名字和金额拼成一行。示例里还有两条断言分别钉住金额与文本：`assert(pay == 5000)` 和 `assert(line == "alice 应发 5000")`——以后任何人改动算薪逻辑或报表格式，测试立刻指认，这正是职责隔离带来的可测试性。

### SRP 的反面教训：拆过头

要警惕把 SRP 执行成"一个类一个函数"的强迫症。判断标准不是函数数量，而是**变化是否真的独立**：如果算薪方式和报表格式永远一起改（比如都跟着薪酬制度走），拆开反而制造了两个需要同步维护的地方。刘伟 2.2.2 节的分析提到，SRP 是六大原则中最具争议的一条，难点全在"职责"的定义上——工程上的可操作判据是：**问这个类/函数"你为什么会被改"，如果答案超过一个且互不相关，就该拆了**。

## 开闭原则：对扩展开放，对修改关闭

### 朴素写法及其坏处

开闭原则（Bertrand Meyer 1988 年提出，之禅第 6 章、刘伟 2.3 节）的原文是：软件实体应当对扩展开放、对修改关闭（open for extension, closed for modification）。听着玄，落到代码上就一个问题：**加一种新情况，你要改几处旧代码？**

朴素写法用类型标签 + switch：

```cpp
double area_of(int kind, double a, double b) {
    switch (kind) {
        case 0: return 3.14159265358979 * a * a;   // 圆：a=半径
        case 1: return a * b;                       // 矩形：a=宽, b=高
        default: return 0.0;
    }
}
```

加三角形？改这个函数。加椭圆？改这个函数。每加一种形状，这个函数都要"开膛"一次，所有调用它的人都承担回归风险。类型标签还把"哪种形状"这个本该由类型系统管的事降级成了运行期整数，编译器再也帮不了你。

### 经典解法：抽象基类 + 虚函数

GoF 的答案是多态（示例 `ocp.hpp`）：

```cpp
class Shape {
public:
    virtual ~Shape() = default;
    [[nodiscard]] virtual double area() const = 0;
};

class Circle final : public Shape {
public:
    explicit Circle(double r) : r_(r) {}
    [[nodiscard]] double area() const override { return 3.14159265358979 * r_ * r_; }
private:
    double r_;
};

class Rect final : public Shape {
public:
    Rect(double w, double h) : w_(w), h_(h) {}
    [[nodiscard]] double area() const override { return w_ * h_; }
private:
    double w_, h_;
};
```

聚合求和的函数只认抽象接口：

```cpp
inline double total_area(std::span<const std::unique_ptr<Shape>> shapes) {
    double sum = 0.0;
    for (const auto& s : shapes) sum += s->area();
    return sum;
}
```

参数是 `std::span<const std::unique_ptr<Shape>>`——一个不可变的指针视图。三个 C++23 细节值得展开：

1. **`unique_ptr<Shape>` 而不是 `Shape*`**：容器持有所有权，离开作用域自动逐个析构，虚析构函数（`virtual ~Shape() = default`）保证经过基类指针删除时先调用的派生类析构函数再调基类析构函数。GoF 时代的 C++ 示例里 `delete` 满天飞，现代 C++ 里 RAII 接管了这份责任。
2. **`std::span`**：视图不拷贝容器。调用方传 `vector` 也好、数组也好，`total_area` 都不用改——这本身就是对函数签名维度上的 OCP。
3. **`const std::span`**：只读求和， accidental 修改编译期就被拦下。

现在加三角形长什么样？示例的 `main.cpp` 里当场演示：

```cpp
class Tri final : public Shape {
public:
    double area() const override { return 1.0; }
};
shapes.push_back(std::make_unique<Tri>());
assert(total_area(shapes) > 10.1415926 && total_area(shapes) < 10.1415927);
```

`Tri` 定义在使用点、直接塞进同一个容器，`total_area` 一行未动。这就是"对扩展开放（加新类）、对修改关闭（旧函数不动）"的字面兑现。运行输出：

```text
OCP 经典: total_area = 9.141593
```

圆面积 π≈3.141593 加矩形 6 得 9.141593；加入三角形后断言区间抬到 10.141593 附近（π+6+1）。断言写成区间比较（`> a && < b`）而不是 `==`，是因为浮点求和的顺序误差——**不要对浮点用精确相等断言**，这算 OCP 之外的免费一课。

### 现代解法：concepts 不需要继承

虚函数方案有一个隐性代价：`Hex` 想进 `total_area`，就必须继承 `Shape` 并实现虚函数。如果你的 `Hex` 来自第三方库，改不了继承，虚函数路线就断了。C++20 起的 concepts 提供了另一条路（`ocp.hpp` 后半）：

```cpp
template <typename S>
concept ShapeLike = requires(const S& s) {
    { s.area() } -> std::convertible_to<double>;
};

template <std::ranges::input_range R>
    requires ShapeLike<std::ranges::range_value_t<R>>
double total_area2(const R& shapes) {
    double sum = 0.0;
    for (const auto& s : shapes) sum += s.area();
    return sum;
}
```

`ShapeLike` 只问一个问题："你有没有 `area()`？"——不管你是谁的儿子。`total_area2` 接受任何元素满足 `ShapeLike` 的范围（range），连 `std::span` 都不用手工构造。示例里的用法：

```cpp
struct Hex {
    double side;
    double area() const { return 2.598 * side * side; }
};
std::vector<Rect> rects{Rect{2.0, 3.0}};
std::vector<Hex> hexes{Hex{1.0}};                    // 与 Shape 零继承关系
assert(total_area2(rects) == 6.0);
assert(total_area2(hexes) == 2.598);
```

`Hex` 与 `Shape` 毫无继承关系，照样参与求和。输出第三行：

```text
OCP 现代: total_area2(rects)=6, total_area2(hexes)=2.598
```

`2.598` 和 `6.0` 都是整数级精确值，所以这里 `==` 断言是安全的——对比上面虚函数版本的区间断言，可以体会"值本身是否精确"决定断言写法。

实现机制上，`total_area2` 是模板：编译器为每种元素类型生成一份专属代码，`s.area()` 直接内联调用，没有虚表跳转。代价是每种类型一份代码副本（代码膨胀）和更复杂的错误信息。`total_area` 只有一份代码，所有形状共用，代价是每次调用都过一遍虚表。示例里两版输出逐字节一致（构建框架自动比对双通道输出），行为上完全等价。

### 两版取舍

| 维度 | 虚函数版 | concepts 版 |
|---|---|---|
| 类型集合 | 运行期开放，新类型随时入列 | 编译期封闭，传什么类型写代码时就要定 |
| 第三方类型 | 必须能改其继承（或写适配器） | 直接可用 |
| 运行开销 | 每元素一次虚调用 | 零开销，可内联 |
| 代码体积 | 一份 | 每类型一份 |
| 异构容器 | 天然支持（都装进 `unique_ptr<Shape>`） | 不支持（类型不同容器就不同） |

工程结论：**运行期才决定用什么对象（插件、脚本配置、用户输入）选虚函数；编译期就确定类型集合且在乎性能选 concepts**。两者并不互斥——标准库自己就是混合体：`std::function` 内部是虚调用，`std::sort` 的比较器是模板。

## 陷阱清单

1. **切片**（现象：派生类对象赋给基类变量后行为变基类；原因：值语义拷贝只拷贝基类子对象；后果：静默错误，多态失效。对策：接口一律用引用/指针/智能指针传递，基类构造函数声明为 `explicit` 的场景不要接受派生类隐式转换）。
2. **虚函数在构造/析构中失效**（现象：构造函数里调 `area()` 永远得到基类版本；原因：对象按"基类→派生类"顺序构造，构造基类部分时动态类型还是基类；后果：看似调用了派生类实现实则没有。GoF 在工厂方法一章专门警告过这件事，本教程第 6 章回收）。
3. **忘了虚析构函数**（现象：`delete base_ptr` 只析构了基类部分；原因：非虚析构按静态类型绑定；后果：资源泄漏，未定义行为。对策：所有多态基类写 `virtual ~T() = default`，或干脆用 `std::unique_ptr` 并保持基类析构可见）。
4. **用 SRP 当借口拆出平行类**（现象：十几个单方法类互相纠缠；原因：把"变化原因"误当"函数数量"；后果：复杂度不降反升。对策：按"变化驱动者"拆，不按行数拆）。
5. **switch 换多态只换了形式**（现象：调用方 `if (kind == ...) c = new ...`；原因：把类型判断从被调方搬到了调用方；后果：还是开膛手术，只是刀口换了位置。对策：创建逻辑交给工厂（第 5–6 章），使用方只认抽象）。

## 三书对应

- 之禅：第 1 章"单一职责原则"（1.1 定义、1.2 绝杀技）、第 6 章"开闭原则"（6.2 庐山真面目、6.4 如何使用）。
- 刘伟：2.2 单一职责原则、2.3 开闭原则（含定义/分析/实例三段式）。
- GoF：第 1 章 1.6.2 节"针对接口编程，而不是针对实现编程"——OCP 的机制基础；第 3 章 3.3 节对创建型模式与封装变化的关系有总述。

*可选延伸：可运行示例见 examples/02_srp_ocp/。*

---

上一章：[01 引论：为什么是模式](01-intro.md) · 下一章：[03 里氏替换与依赖倒置](03-lsp_dip.md)
