# 04 · 接口隔离、迪米特与合成复用

六大原则收尾三讲合在一章，因为它们主题一致：**控制"知道多少"**。接口隔离（ISP）限制接口对客户端暴露多少，迪米特法则（LoD）限制对象对朋友的朋友知道多少，合成复用原则（CRP）限制继承的使用场合——能用"拥有"解决就别用"是"。三条合起来是 C++ 封装精神的完整拼图，也是全书"薄接口"审美的源头。

## 接口隔离：别强迫客户端依赖它用不到的方法

### 朴素写法及其坏处

一体机（打印/传真/扫描三合一）是教科书的经典场景。朴素设计做一个大接口：

```cpp
class Machine {
public:
    virtual std::string print(std::string_view doc) = 0;
    virtual std::string fax(std::string_view doc) = 0;
    virtual std::string scan(std::string_view doc) = 0;
    virtual ~Machine() = default;
};
```

麻烦出在"老式打印机"上：它只会打印。让它继承 `Machine`，`fax`/`scan` 只能写出：

```cpp
std::string fax(std::string_view) override { throw std::logic_error("不支持"); }
```

两种恶果随之而来：运行期调用方拿到莫名其妙的异常；编译期 `OldPrinter` 被迫知道"传真"这个概念，接口一加方法，全世界的实现类都要重编。刘伟书 2.6 节的定义直指要害：**客户端不应该依赖它不需要的接口**。

### 拆分：按能力切小接口

修正版（示例 `isp.hpp`）：

```cpp
struct Printable {
    virtual ~Printable() = default;
    virtual std::string print(std::string_view doc) = 0;
};

struct Faxable {
    virtual ~Faxable() = default;
    virtual std::string fax(std::string_view doc) = 0;
};

// 老打印机只实现它真正有的能力，编译器不再强迫它假装能传真。
class OldPrinter final : public Printable {
public:
    std::string print(std::string_view doc) override {
        return std::string("print(") + std::string(doc) + ")";
    }
};

class MultiMachine final : public Printable, public Faxable {
public:
    std::string print(std::string_view doc) override {
        return std::string("print(") + std::string(doc) + ")";
    }
    std::string fax(std::string_view doc) override {
        return std::string("fax(") + std::string(doc) + ")";
    }
};
```

接口按**能力**（capability）切分，实现类按需拼装：`OldPrinter` 只挂 `Printable`，`MultiMachine` 用 C++ 多继承同时挂两个。这里多继承不是禁区——**继承多个纯接口（无数据成员、无实现）是安全的**，危险的是继承多个带状态的实现类（菱形继承、状态重复），那正是合成复用原则管的事。

使用端按能力取视图：

```cpp
Printable& as_printer = mm;   // 当打印机用
Faxable& as_fax = mm;         // 当传真机用
```

`MultiMachine` 对象同时"是"两种东西，每个视图只看得见自己那份合同。这就是 GoF 第 4 章"适配器模式"里类适配器敢用多重继承的原因——继承的都是纯接口。运行输出：

```text
ISP: print(doc) / fax(doc)
```

### 现代补充：concepts 是"不注册的能力清单"

虚接口的隔离要在**设计期**预先切好，concepts 把切分推迟到了**使用点**：

```cpp
template <typename T>
concept Printer = requires(T t, std::string_view doc) {
    { t.print(doc) } -> std::convertible_to<std::string>;
};
```

`OldPrinter` 什么都不用声明，只要真有 `print` 就自动满足 `Printer`。能力由类型**事实上拥有**而非**名义上注册**。取舍照旧：能力集合编译期封闭、追求零开销用 concept；能力集合运行期开放（容器里混装）用虚接口。本章三原则里，ISP 是 concepts 优势最明显的一条。

## 迪米特法则：只和直接朋友说话

### 原则本体

迪米特法则（Law of Demeter，之禅第 5 章，刘伟 2.8 节）来自东北大学的一个面向对象项目（Demeter 项目），规则是：一个对象应当对其他对象有最少的了解，只与**直接朋友**通信。直接朋友限定为：自己、方法参数、方法内创建的对象、成员变量、（C++ 全局视角下）聚合计量的全局对象。

反面场景一行就能演出来：

```cpp
customer.wallet().money() -= price;      // 违反 LoD
```

收银员摸进了顾客的钱包（顾客的钱包，是顾客的朋友的朋友）。钱包的内部结构一旦变化（比如改成两张卡），所有收银代码全崩。

### 好写法：把行为推给数据的主人

修正版（示例 `lod.hpp`）：

```cpp
class Customer {
public:
    explicit Customer(int cash) : cash_(cash) {}

    // 直接朋友：自己。内部怎么扣钱，收银员不需要知道。
    bool pay(int amount) {
        if (cash_ < amount) return false;
        cash_ -= amount;
        return true;
    }
    [[nodiscard]] int cash() const { return cash_; }

private:
    int cash_;
};

class Checkout {
public:
    // 只与参数（直接朋友）交流，不摸 Customer 的钱包内部。
    bool scan(const Customer& c, int price) { return c.cash() >= price; }
};
```

`Checkout::scan` 只问一句"够不够"，真扣钱发生在 `Customer::pay` 里——钱包是几个槽、现钞还是余额，收银台永远不知道。示例的断言链路是：先 `scan` 两单（有钱的真、钱不够的假），再真正 `pay(30)` 验证余额从 100 减到 70。运行输出只有一行：

```text
LoD: pay(30) 后 cash=70
```

注意一个分寸：`Checkout` 调了 `c.cash()` 和 `c.pay()`——这两个都是**直接朋友（方法参数）的公开方法**，不违反 LoD。LoD 禁止的是**链式深入**（`c.wallet().card().limit()`），不是"调用方法参数的方法"。有一种激进读法（"只跟自己的成员说话"）会连参数方法都禁止，那在实际工程里走不通，之禅 5.2 节也明确不采纳。

### LoD 在 C++ 的独特红利：编译防火墙

Java/Python 里守 LoD 主要图可维护性，C++ 多赚一层：头文件耦合。成员变量哪怕只出现在 `.cpp` 里也会把它的头文件拖进包含链；用 LoD 风格把访问收敛成方法调用，再配合前向声明和 pImpl（第 12 章桥接模式），能让"改一个类 → 重编半个工程"的连锁反应归零。这是后面结构性模式反复兑现的红利。

## 合成复用：优先"拥有"，其次"是"

### 原则本体

合成复用原则（Composite Reuse Principle，刘伟 2.7 节）一句话：**尽量使用对象组合/聚合，而不是继承来达到复用的目的**。继承的三个固有代价：编译期绑死（运行期不能换）、白盒暴露（子类看见基类实现细节，破坏封装）、爆炸半径（继承树一动，满树皆惊）。组合只付一个代价——多写一个成员变量和一层转发——换来运行期可换、黑盒复用、自由增删。

### 对照实验：继承武器 vs 组合武器

示例 `crp.hpp` 用组合实现玩家换武器：

```cpp
struct Weapon {
    virtual ~Weapon() = default;
    virtual int attack() const = 0;
    virtual std::string name() const = 0;
};

class Sword final : public Weapon {
public:
    int attack() const override { return 10; }
    std::string name() const override { return "sword"; }
};

class Axe final : public Weapon {
public:
    int attack() const override { return 25; }
    std::string name() const override { return "axe"; }
};

class Player {
public:
    explicit Player(std::unique_ptr<Weapon> w) : weapon_(std::move(w)) {}
    void rearm(std::unique_ptr<Weapon> w) { weapon_ = std::move(w); }
    int strike() const { return weapon_->attack(); }
    std::string armed_with() const { return weapon_->name(); }

private:
    std::unique_ptr<Weapon> weapon_;  // 组合：运行期可换，继承做不到
};
```

关键在 `unique_ptr<Weapon> weapon_`：玩家**拥有**一把武器（所有权清楚），武器类型在运行期通过 `rearm` 随意替换。如果改成继承——`Player : public Sword`——"换武器"就得整对象重建，`Player` 还被迫背上剑的全部方法。运行输出：

```text
CRP: axe -> strike=25
```

断言链：先持剑 `strike()==10`，`rearm` 斧头后 `strike()==25`、`armed_with()=="axe"`。

细心的读者会发现：这正是**策略模式**的雏形——`Weapon` 是策略接口，`rearm` 是策略切换。六大原则到本章全部就位，23 个模式就是这些原则的反复应用：组合代替继承（策略、装饰、状态），依赖抽象（工厂、观察者），隔离接口（适配器、访问者）。原则不是模式的装饰，而是模式的生成语法。

## 陷阱清单

1. **为隔离而分裂**（现象：一个类实现十几个单方法接口；原因：把 ISP 执行成接口数竞赛；后果：类型声明爆炸，实际内聚关系反而看不清。对策：按客户端分组拆，一个客户端群一个接口）。
2. **LoD 教条化**（现象：为避免链式调用层层写转发方法，类膨胀成一叠委托壳；原因：把法则当铁律；后果：转发样板淹没真实逻辑。对策：链深 ≤2 时随它去，链上出现第三方类型或跨模块时再收口）。
3. **接口继承与实现继承混用**（现象：基类既有纯虚函数又有可被子类踩的实现；原因：C++ 允许二者混在同一个类里；后果：子类在"重写"与"复用"之间摇摆，改基类实现炸半树子类。对策：纯接口类（无成员无实现）与可复用实现类（final）分开写）。
4. **组合对象被两个主人共享**（现象：`Player` 里放裸 `Weapon*`，两个玩家指向同一把斧头；原因：所有权没编码进类型；后果：悬垂指针双重释放。对策：独占用 `unique_ptr`，共享用 `shared_ptr` 并在正文说明为什么共享）。
5. **concept 拼写过宽**（现象：`concept Printable = true;` 之类的万能概念；原因：把 concept 当注释写；后果：错误调用推迟到实例化深处才报。对策：requires 子句逐个列成员与返回约束，让违约在匹配期就死掉）。

## 三书对应

- 之禅：第 4 章"接口隔离原则"（4.3 保证接口的纯洁性）、第 5 章"迪米特法则"（5.2 我的知识你知道得越少越好）；合成复用在之禅第 7 章单例模式扩展里被引用。
- 刘伟：2.6 接口隔离原则、2.7 合成复用原则、2.8 迪米特法则（每节都带定义/分析/实例）。
- GoF：第 1 章 1.6.2 节"优先使用对象组合"（favor object composition over class inheritance，GoF 23 模式背后最重要的两句话之一，另一句是针对接口编程）。

*可选延伸：可运行示例见 examples/04_isp_lod_crp/。*
