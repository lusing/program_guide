# 07 · 抽象工厂

工厂方法管"一种产品怎么造"，抽象工厂管"一族产品怎么配套造"。刘伟 6.1 节的定义：**提供一个创建一系列相关或相互依赖对象的接口，而无需指定它们具体的类**。关键词是"一族"和"相互依赖"——按钮和边框必须风格一致，这份"一致性约束"就是本章的戏肉。

## 意图与动机

跨平台 UI 是教科书场景：一套界面要在 Windows 和 Linux 上都原生。按钮、边框、菜单各有两种实现，且**不许混搭**——Windows 按钮配 Linux 边框在视觉上是事故。用第 6 章的工厂方法，你给每种产品各写一条工厂链（ButtonFactory 链、BorderFactory 链），但"按钮与边框同族"的约束没有载体：调用方完全可能用 `WinButtonFactory` 配 `LinuxBorderFactory`，编译器不会拦。

抽象工厂的解法：把**一族产品的创建函数收进一个工厂接口**。`make_button()` 和 `make_border()` 同生共死于 `WidgetFactory`，调用方拿到哪一个工厂，就意味着拿到了"整族一致"的承诺。

## 经典写法：控件族

示例 `abstract_factory.hpp` 先铺产品（两组平行类，代码略长但结构机械）：

```cpp
struct Button {
    virtual ~Button() = default;
    [[nodiscard]] virtual std::string render() const = 0;
};

struct Border {
    virtual ~Border() = default;
    [[nodiscard]] virtual std::string render() const = 0;
};

struct WinButton final : Button {
    [[nodiscard]] std::string render() const override { return "win-button"; }
};

struct WinBorder final : Border {
    [[nodiscard]] std::string render() const override { return "win-border"; }
};

struct LinuxButton final : Button {
    [[nodiscard]] std::string render() const override { return "linux-button"; }
};

struct LinuxBorder final : Border {
    [[nodiscard]] std::string render() const override { return "linux-border"; }
};
```

两个产品等级结构（Button 是一个、Border 是一个），每个结构两个实现（Win/Linux）。工厂接口把两条"制造线"捆在一起：

```cpp
class WidgetFactory {
public:
    virtual ~WidgetFactory() = default;
    [[nodiscard]] virtual std::unique_ptr<Button> make_button() const = 0;
    [[nodiscard]] virtual std::unique_ptr<Border> make_border() const = 0;
};

class WinFactory final : public WidgetFactory {
public:
    [[nodiscard]] std::unique_ptr<Button> make_button() const override {
        return std::make_unique<WinButton>();
    }
    [[nodiscard]] std::unique_ptr<Border> make_border() const override {
        return std::make_unique<WinBorder>();
    }
};

class LinuxFactory final : public WidgetFactory {
public:
    [[nodiscard]] std::unique_ptr<Button> make_button() const override {
        return std::make_unique<LinuxButton>();
    }
    [[nodiscard]] std::unique_ptr<Border> make_border() const override {
        return std::make_unique<LinuxBorder>();
    }
};
```

消费端是"一致性"的直接受益者：

```cpp
// 对话框只依赖抽象工厂：按钮和边框必然来自同一族。
inline std::string draw_dialog(const WidgetFactory& f) {
    return f.make_button()->render() + "+" + f.make_border()->render();
}
```

`draw_dialog` 拿到的按钮和边框**必然**出自同一个工厂对象——混搭在结构上不可能发生，因为产品不是"分别要来的"，而是"一族一起来的"。运行输出：

```text
抽象工厂: win-button+win-border
抽象工厂: linux-button+linux-border
```

## 模式结构（ASCII 类图）

```text
产品等级结构（按"是什么"分）        产品族（按"给谁用"分）
Button ← WinButton ─────┐           WinFactory 产 (WinButton, WinBorder)
      ← LinuxButton ────┤           LinuxFactory 产 (LinuxButton, LinuxBorder)
Border ← WinBorder ─────┤
      ← LinuxBorder ────┘

抽象工厂 = 矩阵的"行"维度：一个工厂 = 一行 = 一族产品
```

这张矩阵图是理解抽象工厂的钥匙：**列**是产品等级结构（Button 家族、Border 家族），**行**是产品族（Win 一行、Linux 一行）。工厂方法每列一条竖线地工作，抽象工厂每行整行地工作。刘伟 6.2.2 节的分析强调：新增一**列**（加一种产品"菜单"）要改所有工厂接口——违反 OCP；新增一**行**（加 macOS 族）只要一个新类——符合 OCP。**抽象工厂对"产品族"开放、对"产品种类"封闭**，选用前先想清楚你扩展的是哪个方向。

## 现代写法：concepts 约束产品族一致性

继承版把"整族一致"编码在运行期对象（工厂实例）上。C++ 模板可以在**编译期**表达同一约束（`abstract_factory.hpp` 末尾）：

```cpp
// concepts 约束：任何想当"控件工厂"的类型必须同时能产按钮和边框，
// 少一样在实例化点就报错——比运行期 nullptr 好查得多。
template <typename F>
concept WidgetFactoryLike = requires(const F& f) {
    { f.make_button() } -> std::convertible_to<std::unique_ptr<Button>>;
    { f.make_border() } -> std::convertible_to<std::unique_ptr<Border>>;
};
```

`WidgetFactoryLike` 不要求继承 `WidgetFactory`——只要类型"能造按钮 + 能造边框"就满足。示例 main 里的编译期检验：

```cpp
static_assert(WidgetFactoryLike<WinFactory>);
static_assert(WidgetFactoryLike<LinuxFactory>);
```

还可以更进一步：**连运行期基类都不要**，用纯模板工厂（每个族一个普通 struct）：

```cpp
struct TWinFactory {
    std::unique_ptr<Button> make_button() const { return std::make_unique<WinButton>(); }
    std::unique_ptr<Border> make_border() const { return std::make_unique<WinBorder>(); }
};

template <WidgetFactoryLike F>
std::string t_draw_dialog(const F& f) {
    return f.make_button()->render() + "+" + f.make_border()->render();
}
```

`t_draw_dialog` 为每个族实例化一份，调用零虚开销。GoF 在 Abstract Factory 的"实现"节讨论过"用原型/类对象做工厂"（Smalltalk 用类对象当工厂），C++ 模板是这一思路的极致版——**类型本身就是工厂**。

## 两版取舍

| 维度 | 继承版（GoF 经典） | concepts/模板版 |
|---|---|---|
| 族的切换时机 | 运行期（读配置、换主题） | 编译期（`#ifdef`/构建变体） |
| 二进制体积 | 一份代码 | 每族一份实例化 |
| 加新族 | 新子类，旧代码不动 | 传新类型即可，同样不动旧代码 |
| 加新产品种类 | 改抽象工厂接口 + 所有子类（矩阵加列） | 改 concept + 所有族类型（同样疼） |
| 混族错误发现时机 | 运行期（若没有类型约束）或设计审查 | 编译期 |

结论与第 2 章 OCP 一脉相承：**族在运行期才确定（用户换皮肤、热切换主题）用继承版；族是构建配置的一部分（Debug/Release 后端、平台后端）用模板版**。工程里最常见的混合体：模板版做编译期分派，对外再包一层虚接口给运行期选择。

## 刘伟 6.3 的数据库操作工厂：抽象工厂的第二个经典土壤

跨平台 UI 之外，抽象工厂在 Java 教材里最常引用的场景是**多数据库支持**：系统要能在 SqlServer、Oracle、Access 之间切换，且 `User` 表和 `Dept` 表的 DAO 必须**来自同一个数据库**——用 SqlServer 的 UserDAO 配 Oracle 的 DeptDAO，事务跨库直接炸。这与"按钮配边框"是同构问题：

```text
产品等级结构（列）：IUserDAO / IDeptDAO
产品族（行）：     SqlServer 族 / Oracle 族 / Access 族
                   ── 抽象工厂 = IDataAccess { create_user_dao(); create_dept_dao(); }
```

`IDataAccess` 有两个 `create_xxx_dao()`，三个数据库各一个工厂子类；业务层持有 `IDataAccess&`，读到哪套 DAO 由装配点（读配置文件）决定。这个例子比 UI 例更贴近后端工程，也点出抽象工厂在真实系统里的常客身份：**"可替换基础设施"的装配层**——数据库、消息队列、缓存客户端，凡是"一整套配套换"的基础设施都适用。C++ 语境的同类需求：存储引擎（内存版/SQLite 版/网络版）各自配套 `make_kv()`/`make_iter()`/`make_tx()`，第 34 章对象池实战会以这个形态出现。

## 与工厂方法正面对比

两章连读容易混，一张表钉死分界：

| | 工厂方法（第 6 章） | 抽象工厂（本章） |
|---|---|---|
| 管理的产品 | 一个等级结构（Button 的多种实现） | 多个等级结构 × 多个族（矩阵） |
| 抽象工厂接口 | 一个 `create()` | N 个 `make_xxx()` |
| 扩展友好方向 | 加产品实现（列） | 加产品族（行） |
| 一致性保证 | 无需（单产品） | 族内配套由工厂实例保证 |
| 典型组合 | Creator 常为模板方法宿主 | 常与单例（每族一个工厂实例）搭配 |

选用判据一句话：**只有一个"怎么变"的维度用工厂方法；两个维度（种类 × 族）且族内强制配套，用抽象工厂**。若发现抽象工厂的接口退化到只剩一个 `make_xxx()`——你已经不需要抽象工厂，退回工厂方法。

## 陷阱清单

1. **矩阵加列的冲动**（现象：往 `WidgetFactory` 加 `make_menu()`；原因：新需求真实存在；后果：所有族子类同步改动，第三方工厂全断。对策：先判断新产品的"族内一致性"是否成立；不成立的按工厂方法单独立链）。
2. **族内单件越界共享**（现象：三个对话框各自调用 `WinFactory{}` 造出三份按钮工厂；原因：工厂无状态被当临时对象；后果：一致性约束名存实亡，成本浪费。对策：工厂实例按族全局唯一（配第 8 章单例或依赖注入））。
3. **抽象工厂 + 单例的意大利面**（现象：`WinFactory::instance()` 里造单例按钮；原因：图省事；后果：测试无法替换产品族（第 8 章单例可测试性问题预演）。对策：工厂可以单例，产品每次新造；单例里别锁死产品）。
4. **concept 约束了签名没约束语义**（现象：某"工厂"的 `make_border()` 返回的是按钮；原因：concept 只查类型；后果：编译通过、运行荒谬。对策：语义约束靠命名 + 文档 + 测试，类型系统帮不了全部）。
5. **下转型消费产品**（现象：拿到 `unique_ptr<Button>` 后 `dynamic_cast<WinButton*>`；原因：调用方其实依赖具体族；后果：抽象工厂的封装被架空，换族必炸。对策：消费端只用抽象产品接口；确需族信息就传族参数本身）。

## 三书对应

- 之禅：第 9 章"抽象工厂模式"（9.2 定义、9.3 应用——女娲造人续篇：人种与阴阳）。
- 刘伟：第 6 章"抽象工厂模式"（6.1 动机与定义、6.2 结构与分析——产品等级结构与产品族的矩阵分析、6.3 实例——电器工厂/数据库操作工厂、6.5 扩展）。
- GoF：第 3 章 3.2 节 Abstract Factory——实现节讨论"工厂作为单件""创建产品的类 vs 对象"、"为不同产品族定义可扩展的工厂"（GetExtender 打法），是本章模板版思路的先声。

*可选延伸：可运行示例见 examples/07_abstractfactory/。*

---

上一章：[06 工厂方法](06-factorymethod.md) · 下一章：[08 单例](08-singleton.md)
