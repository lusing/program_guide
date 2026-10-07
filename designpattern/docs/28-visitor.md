# 28 · 访问者

行为型篇收官。访问者是 GoF 行为型里**结构最重、争议最大**的一个：accept/visit 双重分派的两跳跳板常被诟病"为加操作而扭曲类型结构"，但"结构稳定 + 操作爆炸"的场景里它仍是唯一正解。GoF 5.11 节的定义：**表示一个作用于某对象结构中的各元素的操作。它使你可以在不改变各元素的类的前提下定义作用于这些元素的新操作**。本章把双重分派拆开看清楚，再讲 variant 版如何把两跳跳板压成一次 visit。

## 意图与动机

一批图形对象（圆/矩形/三角形）要支持两个操作：算总面积、导出 JSON。朴素写法一：操作写进 Shape 基类——`area()` 还好，`to_json()` 混进几何类就脏了；再加第三种操作（打印、序列化、命中测试）Shape 持续膨胀，**每加一个操作改一次全部形状类**。朴素写法二：外部函数 + `dynamic_cast` 逐个判型——`if (auto* c = dynamic_cast<const Circle*>(s)) ...` 的链越拉越长，**加形状改所有操作函数**。两条路各死一边：操作易加则形状难加，形状易加则操作难加。访问者的抉择是：**把"形状易加"永久放弃，换取"操作无限加"**——形状集合冻结在 accept 跳板里，操作全走 Visitor 子类。

## 经典写法：图形导出

示例 `visitor.hpp`。Visitor 接口与形状：

```cpp
// Visitor：每种形状一个 visit 重载——新增操作 = 新写一个 Visitor 子类。
struct Visitor {
    virtual ~Visitor() = default;
    virtual void visit(const Circle&) const = 0;
    virtual void visit(const Rect&) const = 0;
    virtual void visit(const Tri&) const = 0;
};

// Shape：accept 是第二分派的跳板——"我知道我是谁，替你选对的重载"。
struct Shape {
    virtual ~Shape() = default;
    virtual void accept(Visitor& v) const = 0;
};

struct Circle final : Shape {
    explicit Circle(double r) : r(r) {}
    void accept(Visitor& v) const override { v.visit(*this); }   // this 是 Circle*
    double r;
};
// Rect(w,h) / Tri(b,h) 同构，略
```

`accept` 的一行 `v.visit(*this)` 是全模式的枢纽：`*this` 的**静态类型**在 Circle::accept 里是 `const Circle&`——于是 `v.visit` 选中 Circle 重载。**第一跳**：`s->accept(v)` 按对象的动态类型进到正确的 accept（虚函数）；**第二跳**：accept 里 `visit(*this)` 按形状静态类型选对重载。两跳合起来完成"根据元素真实类型分派操作"——这就是**双重分派**，C++ 单分派语言里模拟多分派的标准手法。两个具体访问者：

```cpp
// ConcreteVisitor 一：求面积和——累计在访问者成员里，形状类毫不知情。
struct AreaVisitor final : Visitor {
    void visit(const Circle& c) const override { total += 3.14159265358979 * c.r * c.r; }
    void visit(const Rect& r) const override { total += r.w * r.h; }
    void visit(const Tri& t) const override { total += t.b * t.h / 2.0; }
    mutable double total = 0.0;      // const visit 累计：逻辑 const 物理可变
};

// ConcreteVisitor 二：JSON 导出——同一批形状，第二种操作零改动。
struct JsonVisitor final : Visitor {
    void visit(const Circle& c) const override {
        out += R"({"t":"circle","r":)" + std::to_string(c.r) + "}";
    }
    // Rect / Tri 略
    mutable std::string out;         // 拼接结果（const visit 内累计，同 AreaVisitor）
};
```

注意 `mutable`：visit 声明为 const（访问不该改元素），累计结果落在访问者自己的成员上——**逻辑 const、物理可变**的手法与第 16 章享元的缓存池同源。运行侧（`main.cpp`）：

```cpp
std::vector<std::unique_ptr<Shape>> shapes;
shapes.push_back(std::make_unique<Circle>(2.0));    // 面积 4π
shapes.push_back(std::make_unique<Rect>(3.0, 4.0)); // 12
shapes.push_back(std::make_unique<Tri>(5.0, 6.0));  // 15

AreaVisitor av;
for (const auto& s : shapes) s->accept(av);
const double expected = 4.0 * 3.14159265358979 + 12.0 + 15.0;
assert(std::abs(av.total - expected) < 1e-9);

JsonVisitor jv;
for (const auto& s : shapes) s->accept(jv);
assert(jv.out.find("\"circle\"") != std::string::npos);
```

运行输出：

```text
访问者: AreaVisitor 累计 = 4π+12+15（与手算一致）
访问者: JsonVisitor 串含 circle/rect/tri 三类标记
variant: 同 total、同 JSON 标记（无 accept/visit 跳板）
```

断言验证：面积和与手算值一致（三形状三种面积公式各算各的）；JSON 串含三类类型标记——**同一批形状，第二种操作零改动**，访问者模式的红利全额兑现。

## 模式结构（ASCII 双重分派调用序）

```text
   客户 ──accept(v)──> Circle::accept(v)        第一跳：按元素动态类型（虚函数）
                          │
                          └─v.visit(*this)──> Visitor::visit(const Circle&)
                                              第二跳：按元素静态类型（重载决议）
                                              ↓
                                        AreaVisitor::visit(const Circle&)

   新操作 = 新写一个 Visitor 子类（三个 visit 全实现）——形状类零改动
   新形状 = 加类 + Visitor 加重载 + 全部 Visitor 补实现——操作全要动
```

GoF 五角色：Visitor（接口）、ConcreteVisitor（Area/Json）、Element（Shape）、ConcreteElement（三个形状）、ObjectStructure（本例 `vector<unique_ptr<Shape>>`）。最后一行是模式的代价清单——**加形状 = 触碰所有访问者**，这个不对称性是刻意的（见下节 variant 的对照）。

## 现代写法：variant + overload

形状集合用 variant 冻结，操作用一组 lambda 的 overload 写成一处（`variant_visitor.hpp`）：

```cpp
// overload 组合子：把多个 lambda 合成一个多重调用体（C++20 起 CTAD 免写推导指引）。
template <class... Ts>
struct overload : Ts... {
    using Ts::operator()...;
};

using ShapeS = std::variant<CircleS, RectS, TriS>;

inline double area_of(const ShapeS& s) {
    return std::visit(overload{
        [](const CircleS& c) { return 3.14159265358979 * c.r * c.r; },
        [](const RectS& r) { return r.w * r.h; },
        [](const TriS& t) { return t.b * t.h / 2.0; },
    }, s);
}
```

对比经典版：**accept/visit 两跳跳板消失了**——`std::visit` 一次调用直接按备选项分派到对应 lambda（编译器生成的跳转表，比两跳虚表还快）；"每种形状一个重载"变成"每种形状一个 lambda"；累计落在返回值而不是 mutable 成员（`area_of` 纯函数化）。运行输出第三行钉死 variant 版同 total、同 JSON 标记。代价在**封闭性**：`ShapeS` 的备选项列表写死在 using 声明里，加一种形状 = 改 variant 类型 + 检查所有 visit 点（好在漏改的 visit 会编译报错——封闭反而换来了 exhaustive 检查）。两版取舍：

| | 继承 + accept/visit | variant + overload |
|---|---|---|
| 加操作 | 新 Visitor 子类，零改动现有 | 新写一个函数（新的 overload 组），零改动现有 |
| 加形状 | 加类 + 所有 Visitor 补虚 | 改 using + 编译器逼你补所有 visit 点 |
| 分派成本 | 两跳虚表 | 一跳（编译器跳转表，可消减） |
| 元素异构容器 | 天然支持（共同基类） | 天然支持（variant 的同类型列表） |
| 类型集合 | 开放（派生无上限） | 封闭（列表写死） |

判定一句话：**形状集合稳定且操作持续膨胀 → 两个版本都好，variant 更轻；形状集合需要跨编译单元开放扩展 → 只有继承版做得到**。这正是"表达式问题"的两难（第 20 章解释器已埋过伏笔）——C++ 没有同时开放两个维度的语言机制，模式的作用就是把"牺牲哪一边"变成显式决定。

## 什么时候不该用访问者

访问者的骨架成本（accept 跳板 + Visitor 接口 + 双跳分派）必须被红利覆盖才值得付。三个"不值得"的信号：**操作就一两个**——直接给元素类加方法更诚实（访问者是为"操作持续膨胀"设计的，两个操作撑不起骨架）；**元素异构性是假的**——三个形状都有 `area()` 时，虚函数 `area()` 一行解决，访问者是绕路；**元素会增派生类**——插件式形状库（第三方可注册新形状）里 Visitor 接口封死了扩展，用 dynamic_cast 链或第 30 章 type erasure 反而可行。访问者真正的甜区：编译器 AST（节点集合冻结、遍历/优化/打印/类型检查操作无限膨胀）、序列化框架（一组稳定消息类型 × 多种编解码）、以及本例这类"结构固定的小型对象集合 + 多报表"。

## 陷阱清单

1. **accept 写成转发错类型**（现象：每个派生类 accept 都写 `v.visit(*this)` 但基类把 accept 实现了（非纯虚），某派生类忘了覆盖，visit 收到的是基类切片或错误重载；原因：accept 没留在纯虚状态；后果：分派到错误操作或编译失败。对策：accept 在 Shape 纯虚（本例如此），每个具体形状必须自己跳）。
2. **Visitor 加形状时漏实现**（现象：新形状加了，某个旧 Visitor 没有 visit(NewShape) 重载，静默走了基类默认（若有）或编不过；原因：继承版无 exhaustive 检查；后果：漏报错或静默缺操作。对策：Visitor 的 visit 不给默认实现（强制编译报错）；或转 variant 版让编译器检查覆盖）。
3. **访问者携带状态跨 accept 调用**（现象：AreaVisitor 复用于两批形状，total 没清零，两批面积相加；原因：访问者成员跨趟累积；后果：结果错且难查。对策：一趟一个新访问者实例（本例每趟 new），或提供 reset()——访问者的生命周期 = 一趟遍历）。
4. **const 撕裂**（现象：visit(const Circle&) 里想改 c 的某个缓存字段，编译不过或被迫 const_cast；原因：元素的缓存与"访问不改元素"的承诺冲突；后果：const_cast 泛滥。对策：mutable 缓存字段（元素侧）或访问者侧 mutable 累计（本例）——const 边界要提前设计，别靠强转）。
5. **把 ObjectStructure 的遍历也塞进 Visitor**（现象：Visitor 里写树的递归下降逻辑；原因：访问者与结构遍历职责混淆；后果：每种"结构"都要 Visitor 配套重写。对策：遍历归 ObjectStructure/客户（本例 for 循环在 main），Visitor 只做"到达元素之后的事"——复合结构（第 13 章）+ 访问者叠加时尤其要分清）。

## visit 的返回类型：variant 版的一个细节

经典版的 visit 返回 void、累计走访问者成员；variant 版的 lambda 各有返回值，`std::visit` 要求**整组 lambda 返回类型一致**（或能统一转换）。本例 `area_of` 全返 double、`json_of` 全返 `std::string`——恰好一致。若某个操作对圆返回 double、对矩形返回 string，visit 直接编不过。三个解法按顺序考虑：统一返回类型（把"值"变成 `std::variant<double,std::string>`，消费端再拆）、把副作用收进 lambda 体内（返回 void，累计到外部捕获的变量——与经典版成员累计殊途同归）、或拆成两个 visit 各管各的返回类型。这个约束本质上是"一次遍历一个语义"的强迫——经典版靠纪律，variant 版靠编译器。

## 测试法

访问者的测试围绕"结构与操作解耦"的承诺展开：

- **逐访问者定点测**：每个 Visitor 独立成趟（本例 AreaVisitor、JsonVisitor 各起一个实例），对已知形状集合断言精确结果——面积用手算和、JSON 用子串查找，浮点走 `abs(diff) < 1e-9` 容差。
- **加操作不改旧**：断言第二个访问者引入后第一个访问者行为不变（模式承诺的行为回归）——真实项目里这就是"新增 JsonVisitor 后 AreaVisitor 的测试原样通过"。
- **双形态对拍**：继承版与 variant 版在同一形状集合上比 total、比 JSON 标记（本例 main 第三段）——两形态互为测试预言，与第 25/26 章同一手法。
- **类型覆盖完备性**：variant 版天然有编译期覆盖保证；继承版的补充手段是"遍历元素时对每种具体类型至少断言一次被访问过"（可在访问者里加 visited 计数）——漏写的 visit 重载在运行期以"计数为 0"现形，这是继承版唯一能追平 variant exhaustive 的手段。

## 行为型篇小结

行为型 11 章到此收官，最后给一张"变化方向"总图收束全篇——**每个行为型模式都在回答同一个问题：哪种变化会持续发生，就把哪种知识集中到一处**：

| 章 | 模式 | 集中的变化 |
|---|---|---|
| 18 | 责任链 | 处理者的分档知识（谁能接单） |
| 19 | 命令 | 操作的参数化与可逆性（execute/undo 成对） |
| 20 | 解释器 | 文法规则（规则即类） |
| 21 | 迭代器 | 遍历方式（已下沉为语言基础设施） |
| 22 | 中介者 | 群体交互协议（网状改星型） |
| 23 | 备忘录 | 状态的存取时点（快照黑箱化） |
| 24 | 观察者 | 通知的订阅名单（主题零反向知识） |
| 25 | 状态 | 状态转移知识（状态自己驱动切换） |
| 26 | 策略 | 算法的选择权（客户选、算法不知彼此） |
| 27 | 模板方法 | 流程骨架（步骤下放、结构锁死） |
| 28 | 访问者 | 操作维度（结构冻结、操作开放） |

创建型回答"怎么造"，结构型回答"怎么组装"，行为型回答"**职责怎么分、变化往哪集中**"——三篇合起来，就是设计模式的全部地基。后面的章节（29-36）将走出 GoF 清单，用现代 C++ 的语言设施重访这些主题。

## 三书对应

- 之禅：第 25 章"访问者模式"（25.1 员工的隐私何在——员工报表的固定员工集合 × 多种报表统计、25.2 定义、25.3 应用、25.4 扩展——统计报表与过滤器的混编、25.5 最佳实践——定位为"集中规整模式，特别适用于大规模重构的项目"）。
- 刘伟：第 27 章"访问者模式"（27.1 动机与定义、27.2 结构与分析、27.3 实例——购物车（27.3.1）/奖励审批系统（27.3.2）、27.4 效果与应用——与组合模式结合遍历对象结构）。
- GoF：第 5 章 5.11 节 Visitor——Node/AST 例（编译器对语法树做多趟操作，正是本章"什么时候该用"一节的现实版），"实现"节讨论"双重分派的语言背景（CLOS 多分派 / Smalltalk double dispatching）、谁负责遍历对象结构、无抽象访问者的缺省访问"。

*可选延伸：可运行示例见 examples/28_visitor/。*

---

上一章：[27 模板方法](27-templatemethod.md) · 下一章：[29 多态的三副面孔（虚函数/concepts/variant）](29-polymorphism.md)
