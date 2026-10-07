# 12 · 桥接

适配器缝合的是"已经存在、不能改"的两边；桥接处理的是"还没写、正在分头演化"的两边。GoF 4.2 节的定位：**将抽象部分与它的实现部分分离，使它们都可以独立地变化**。这句话每个词都容易误读——"实现"不是"抽象类的实现"，而是"实现所依赖的另一套可变的东西"。

## 意图与动机

GoF 的动机节讲得很直接：跨平台绘图。一个绘图库要画多种形状（圆、方、线），每种形状又要支持多种渲染后端（矢量、光栅）。朴素的多继承矩阵是 `VectorCircle`、`RasterCircle`、`VectorRect`、`RasterRect`……**两个维度的笛卡尔积**：形状 m 种 × 后端 n 种 = mn 个类，加一种形状要写 n 个类，加一种后端要写 m 个——类的数量和修改点都按乘法爆炸。

桥接的解法：把两个维度拆成两棵独立的继承树，中间用**一根指针**连起来。形状树持有"指向渲染器"的引用（这根引用就是"桥"），渲染树独立演化。类的数量从 mn 降到 m+n，两个维度各自加东西都只加一个类。

## 经典写法：Shape × Renderer

示例 `bridge.hpp`。实现侧（Renderer 树）：

```cpp
// Implementor：实现侧接口——"怎么画"。
struct Renderer {
    virtual ~Renderer() = default;
    [[nodiscard]] virtual std::string render_circle(double r) const = 0;
};

struct VectorRenderer final : Renderer {
    [[nodiscard]] std::string render_circle(double r) const override {
        return std::format("vector circle r={}", r);
    }
};

struct RasterRenderer final : Renderer {
    [[nodiscard]] std::string render_circle(double r) const override {
        return std::format("raster circle r={}", r);
    }
};
```

抽象侧（Shape 这边）——重点是那根桥怎么搭：

```cpp
// Abstraction：抽象侧——持有"指向实现"的桥（这里是 const 引用）。
class BridgeCircle {
public:
    BridgeCircle(const Renderer& r, double radius) : r_(&r), radius_(radius) {}

    // 抽象操作把请求转给实现：形状逻辑（画的是圆）与渲染逻辑（怎么画）合流于此。
    [[nodiscard]] std::string draw() const { return r_->render_circle(radius_); }

    // 抽象维度可独立扩展：加一个"描边圆"只动这一层，不动任何 Renderer。
    [[nodiscard]] std::string draw_outlined() const {
        return "outline(" + r_->render_circle(radius_) + ")";
    }

private:
    const Renderer* r_;
    double radius_;
};
```

三个要点：

1. **桥是一根指针，不是一个继承关系**。`BridgeCircle` 与 `Renderer` 之间没有 `is-a`，只有"知道一个"——这正是与多继承矩阵的本质区别：**继承把两维焊死在类定义里，指针把两维焊在构造函数参数上**。构造时注入哪个渲染器，运行期就画成哪种。
2. **抽象维度照常扩展**：`draw_outlined` 是抽象层自己的新功能（描边圆），它复用桥而不关心对面是谁。抽象层的继承（以后可以有 `Ellipse`、`Polygon`）与实现层的继承（以后可以有 `SvgRenderer`）互不牵动。
3. **请求的合流点在 `draw()`**：形状决定"画什么、多大"，渲染器决定"用什么技术画"——两棵树的代码在虚调用这一行汇合。GoF 称这种结构为"句柄/正文（handle/body）"的推广：抽象是句柄，实现是正文。

运行输出：

```text
桥接: vector circle r=2 / raster circle r=2
抽象扩展: outline(vector circle r=2)
```

第一行：同一个 `BridgeCircle` 逻辑配两种渲染器，产出两种实现。第二行：抽象层新方法（描边）对实现层透明。断言验证 `draw()` 输出精确含 `"vector circle r=2"` 与 `"raster"`——两维的独立变化全部可观察。

## 模式结构（ASCII 类图）

```text
  抽象维度（m 个类）              实现维度（n 个类）
  BridgeCircle ──────r_─────┐    Renderer
  (draw, draw_outlined)     └──> ├─ VectorRenderer
  Ellipse    ──────r_─────>      └─ RasterRenderer
  Polygon    ──────r_─────>

  类总数 m+n（不是 m×n）；两棵树各自加类，另一棵不动。
```

GoF 的参与者表里四个角色：Abstraction（BridgeCircle）、RefinedAbstraction（将来的 Ellipse）、Implementor（Renderer）、ConcreteImplementor（Vector/Raster）。记法只有一个："**两棵树，一根桥**"。

## 现代写法：pImpl——桥接的编译期同构

C++ 程序员其实每天都在用桥接的变体而不自知——**pImpl（pointer to implementation）**。示例 `bridge.hpp` 末尾：

```cpp
class Widget {
public:
    Widget();
    ~Widget();                                  // 析构必须在 Impl 完整类型处定义
    Widget(Widget&&) noexcept;
    Widget& operator=(Widget&&) noexcept;
    [[nodiscard]] std::string describe() const;
private:
    struct Impl;
    std::unique_ptr<Impl> p_;
};

// 单文件教学示例：Impl 的定义放在类外（真实工程里放在 .cpp 中）。
struct Widget::Impl {
    std::string detail = "impl-ready";
};

inline Widget::Widget() : p_(std::make_unique<Impl>()) {}
inline Widget::~Widget() = default;
inline Widget::Widget(Widget&&) noexcept = default;
inline Widget& Widget::operator=(Widget&&) noexcept = default;
inline std::string Widget::describe() const { return p_->detail; }
```

pImpl 与经典桥接的骨架一模一样：公开接口持有"指向实现"的 `unique_ptr`，请求转发给实现。但它服务的是**另一个目的**——不是运行期的多维度变化，而是**编译防火墙**：

1. **接口与实现物理隔离**。`Impl` 的成员（哪怕是很重的依赖、很脏的实现细节）不出现在头文件里，头文件的 `#include` 列表大幅缩短——改 `Impl` 只重编 `Widget.cpp`，不重编所有使用 `Widget` 的编译单元。大型工程里这一条能把增量编译时间砍半。
2. **ABI 稳定**。只要 `unique_ptr<Impl>` 的位置不变，`Impl` 里加字段删字段都不改变 `Widget` 的二进制布局——SDK 发布后仍可升级实现。
3. **异常安全更简单**。pImpl 惯用法与"编译器生成的特殊成员函数"配合时有一个著名坑：析构函数若在头文件 inline 定义（`= default` 写在类内），编译器在"Impl 还是不完整类型"的位置生成 `delete p_` 代码——对不完整类型 delete 是未定义行为。所以**析构（以及移动赋值）必须在 Impl 完整处定义**，本章代码里那行注释就是为此。

| | 经典桥接 | pImpl |
|---|---|---|
| 目的 | 两维独立演化（运行期） | 编译防火墙 + ABI 稳定 |
| 实现侧数量 | 多个 ConcreteImplementor | 通常一个 Impl |
| 多态 | 虚函数运行期分派 | 无虚函数（或仅抽象侧有） |
| 出现位置 | 架构设计阶段 | 实现技巧层面 |

可以说 pImpl 是桥接思想的"单实现特例"——当桥接的"实现维度"退化为只有一个实现、且变化只发生在编译期（换版本、改内部），桥接就长成了 pImpl。Herb Sutter 的 GotW #100（"Pimpl"）是这条线的权威展开。

## 两版取舍

| 维度 | 虚基类版（GoF 经典） | 模板参数版（编译期桥） |
|---|---|---|
| 后端选择时机 | 运行期（配置/用户选择） | 编译期（构建变体） |
| 开销 | 虚调用 + 指针间接 | 零（内联展开） |
| 混合后端对象 | 天然（不同对象不同桥） | 需要类型参数或类型擦除 |
| 代码体积 | 一份抽象代码 | 每组合一份实例化 |

编译期版本一眼即明：

```cpp
template <typename R>                 // R 满足"能 render_circle"
class TCircle {
public:
    explicit TCircle(R r, double radius) : r_(std::move(r)), radius_(radius) {}
    [[nodiscard]] std::string draw() const { return r_.render_circle(radius_); }
private:
    R r_;
    double radius_;
};
```

没有虚基类，没有指针，`R` 换成什么类型桥就连到什么实现——第 2 章 `ShapeLike` concept 那套在这里原样适用。选型判据全书统一：**后端运行期可知用虚基类版，编译期可知用模板版**。

## 桥接与依赖倒置：同一件事的两个视角

读完第 3 章的读者会发现眼熟：**抽象层依赖"实现的抽象"，不依赖具体实现**——这不就是依赖倒置原则吗？两者关系值得钉死：

- **DIP 是原则**：高层模块不该依赖低层模块，两者都依赖抽象。它约束的是依赖方向。
- **桥接是结构**：为了"两维独立演化"把系统拆成两棵树加一根桥。它约束的是类结构。

桥接的实现天然满足 DIP（BridgeCircle 依赖 `Renderer` 抽象）；但满足 DIP 的设计不一定是桥接——`Switch` 依赖 `Switchable`（第 3 章例）只有一维变化，是纯 DIP；加上"电器种类 × 品牌协议"两维同时变化时，才需要把两个维度各立一棵树，那时 DIP 的结构升级为桥接。教学顺序也印证了这一点：**先立原则（DIP），后给结构（桥接）**。刘伟 11.1 节动机里"防止类的数目指数增长"讲的是桥接的结构收益，"面向抽象编程"讲的是它的 DIP 内核——一句话两件事，读的时候分开接住。

## 实现侧谁来造：桥接 × 抽象工厂的固定搭档

`BridgeCircle` 构造时要传一个 `Renderer`，但 `Renderer` 是抽象的——**桥的另一头总得有个具体对象**。谁造它？GoF 在 Bridge"相关模式"节的答案：Abstract Factory 创建并配置具体的 Bridge 对象。落到本章场景：

```cpp
// 抽象工厂（第 7 章）负责"一整套配套"的实现侧零件
struct GraphicsFactory {
    virtual ~GraphicsFactory() = default;
    [[nodiscard]] virtual std::unique_ptr<Renderer> make_renderer() const = 0;
};

struct VectorFactory final : GraphicsFactory {
    [[nodiscard]] std::unique_ptr<Renderer> make_renderer() const override {
        return std::make_unique<VectorRenderer>();
    }
};

// 装配点：工厂决定后端，桥接消费它
auto factory = VectorFactory{};
auto renderer = factory.make_renderer();
BridgeCircle circle(*renderer, 2.0);
```

分工清晰：**工厂管"哪一套"（族选择，运行期读配置），桥接管"怎么用"（两维协作，运行期转发）**。注意生命周期顺序——`renderer` 必须活得比 `circle` 久（桥是 `const Renderer&`，第 12 章陷阱 4 的原型），装配点用局部变量声明顺序保证这一点。这段搭档在真实系统里的形态：配置文件读出 `backend=vector`，启动代码据此选工厂，之后整个绘图子系统都在抽象侧工作，再也不见具体后端名。

## 陷阱清单

1. **把桥接用成"两个类的包装"**（现象：只有一个 Renderer 实现也要桥；原因：模式先行；后果：多一层间接零收益。对策：桥接是给"两个都在变的维度"预备的，单维度变化用普通继承或函数指针就够）。
2. **桥的方向搞反**（现象：Renderer 反过来持有 Shape；原因：依赖方向没想清；后果：实现层理解抽象层，两维重新耦合。对策：抽象层持桥指向实现层——"高层知道低层"是稳定方向）。
3. **pImpl 析构写在头文件**（现象：`~Widget() = default` 留在类内；原因：以为 default 没有代码；后果：`delete` 不完整类型，未定义行为——部分编译器报 static_assert，部分沉默。对策：析构/移动操作在 Impl 完整的翻译单元定义）。
4. **桥上的生命周期悬空**（现象：`BridgeCircle` 持 `const Renderer&`，渲染器是临时对象或先析构了；原因：桥不拥有实现；后果：悬垂引用崩溃。对策：桥接双方由同一个装配点管理生命周期（第 10 章 builder 的场景），或实现侧用 `shared_ptr` 共享所有权）。
5. **Impl 忘了处理拷贝语义**（现象：pImpl 类用了编译器生成的拷贝构造——浅拷贝了 unique_ptr；原因：默认行为；后果：两个对象共享一个 Impl，析构双重释放。对策：pImpl 类显式处理五件套（拷贝×2 + 移动×2 + 析构），或者禁止拷贝）。

## 三书对应

- 之禅：第 29 章"桥梁模式"（29.2 定义、29.3 应用—— rapeseed 场景/区分"抽象化的类"与"实现化的类"、29.4 最佳实践），另第 33 章 33.1 节"策略模式 VS 桥梁模式"的辨析在本章末值得回看。
- 刘伟：第 11 章"桥接模式"（11.1 动机与定义——含"如何实现国际化软件"的引入、11.2 结构与分析、11.3 实例——跨平台视频播放器、11.4 效果与应用、11.5 扩展——桥接与适配器联动改造已有系统）。
- GoF：第 4 章 4.2 节 Bridge——Window 跨平台例（抽象 Window/IconWindow，实现 WindowImp/XWindowImp），"相关模式"节讨论 Bridge 与 Adapter 的分界与 Abstract Factory 配 Bridge 造实现对象。

*可选延伸：可运行示例见 examples/12_bridge/。*

---

上一章：[11 适配器](11-adapter.md) · 下一章：[13 组合](13-composite.md)
