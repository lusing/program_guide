# 03 · 里氏替换与依赖倒置

上一章的两个原则管"单个类怎么设计"，本章的两个管"类与类之间的关系"。里氏替换（LSP）给继承立规矩：什么样的继承才是合法的。依赖倒置（DIP）给依赖立方向：高层模块应该依赖抽象，而不是反过来。前者是"继承的合同法"，后者是"架构的宪法"——后面所有结构性模式（适配器、桥、外观）和行为性模式里的抽象依赖，都以这两条为前提。

## 里氏替换：子类必须能安全地顶替父类

### 原则本体

Barbara Liskov 1987 年提出的替换原则，刘伟书 2.4 节的定义是：**所有引用基类（父类）的地方必须能透明地使用其子类的对象**。直白版：任何按基类合同写好的代码，把子类对象传进去，行为必须仍然正确——子类可以增强，不能篡改。

判定一个继承是否合法，看两条：**前置条件不能更强**（子类方法接受的范围 ≥ 父类），**后置条件不能更弱**（子类方法承诺的效果 ≥ 父类）。违反任何一条，"子类对象当父类用"这句话就变成谎言。

### 经典反例：正方形继承长方形

数学课上老师教过"正方形是一种特殊的长方形"，这句自然语言误导了几代程序员。代码层面（示例 `lsp.hpp`）：

```cpp
class RectL {
public:
    virtual ~RectL() = default;
    virtual void set_w(int w) { w_ = w; }
    virtual void set_h(int h) { h_ = h; }
    [[nodiscard]] int w() const { return w_; }
    [[nodiscard]] int h() const { return h_; }
private:
    int w_ = 0;
    int h_ = 0;
};

class SquareL final : public RectL {
public:
    // 正方形的"合理性"破坏了长方形的后置条件：改宽会连带改高。
    void set_w(int w) override { RectL::set_w(w); RectL::set_h(w); }
    void set_h(int h) override { RectL::set_w(h); RectL::set_h(h); }
};
```

`SquareL` 为了维持"四边相等"，让 `set_w` 顺带改高。单看每个类都"正确"——可一旦有调用方按长方形的合同行事：

```cpp
// 调用方按长方形的合同写代码：set_w(5); set_h(4); 面积应为 20。
inline int area_after_resize(RectL& r) {
    r.set_w(5);
    r.set_h(4);
    return r.w() * r.h();
}
```

对 `RectL` 得 20，对 `SquareL` 得 16——第二次 `set_h(4)` 把宽也拽回 4 了。函数一个字没改，行为却变了，这就是 LSP 被破坏的现场。运行输出把两个值并排打出来：

```text
LSP: RectL 得 20, SquareL 得 16（后者违反合同）
```

细究起来，`SquareL` 违反的是**后置条件**：`RectL::set_w` 承诺"调用后 `w() == w` 且 `h()` 不变"，`SquareL` 把后半句弄丢了。这不是实现 bug，而是**合同本身不相容**——"宽高独立可变"和"宽高永远相等"是两套矛盾的状态空间，后者根本不该用前者表达。

### 修正：要么别继承，要么改合同

三条出路，按优先级：

1. **不继承，用组合**：`Square` 内部持有一个 `RectL`，自己暴露 `set_side`。两种类各自成立，谁也不冒充谁（合成复用原则，见第 04 章）。
2. **共享抽象而不互相继承**：让 `RectL` 和 `SquareL` 都实现一个只读的 `Shape` 接口（提供 `area()`），把可变行为留给各自的具体类型。
3. **改合同**：如果业务真的把两者当同一种东西，基类合同就该只承诺两者都能兑现的内容——例如只承诺 `area()`，不承诺 `set_w`。

GoF 第 1 章有一句纲领："针对接口编程，而不是针对实现编程。"LSP 从反面补足了这句话：**接口一旦立了，所有实现都要守约**；守不了的实现不是"特殊一点"，而是另一个合同。

## 依赖倒置：依赖抽象，不依赖实现

### 朴素写法及其坏处

想象一个墙壁开关。朴素设计让 `Switch` 直接认识 `Light`：

```cpp
class Switch {
    Light& light_;                 // 直接依赖具体类
public:
    void toggle() { /* 操作 light_ 的 on/off */ }
};
```

现在要接风扇：`Switch` 不认识 `Fan`，你得给它加成员、加分支。开关和灯这两个八竿子打不着的东西被焊死了。更糟的是架构上**依赖方向错了**：高层策略（"按一下切换状态"）依赖了低层细节（灯丝通电），细节一变，策略就得跟着动。

### 经典解法：中间插一层抽象

修正版（示例 `dip.hpp`）：

```cpp
class Switchable {
public:
    virtual ~Switchable() = default;
    virtual void on() = 0;
    virtual void off() = 0;
};

class Light final : public Switchable {
public:
    void on() override { state_ = "light-on"; }
    void off() override { state_ = "light-off"; }
    [[nodiscard]] const std::string& state() const { return state_; }
private:
    std::string state_ = "light-off";
};

class Fan final : public Switchable {
public:
    void on() override { state_ = "fan-on"; }
    void off() override { state_ = "fan-off"; }
    [[nodiscard]] const std::string& state() const { return state_; }
private:
    std::string state_ = "fan-off";
};

class Switch {
public:
    explicit Switch(Switchable& dev) : dev_(dev) {}
    void toggle() {
        on_ = !on_;
        if (on_) dev_.on(); else dev_.off();
    }
    [[nodiscard]] bool is_on() const { return on_; }
private:
    Switchable& dev_;
    bool on_ = false;
};
```

三个角色各就各位：`Switchable` 是抽象，`Light`/`Fan` 是实现，`Switch` 只持有 `Switchable&`。注意依赖的**方向发生了倒转**：改造前是 `Switch → Light`（高层知道低层），改造后是 `Light → Switchable ← Switch`（低层反过来依赖高层定的抽象）。抽象层由使用方（高层）定义、由实现方（低层）实现——这就是"倒置"两个字的准确含义，也是 Robert Martin 把 DIP 列为 SOLID 之一的原因。

示例把同一个 `Switch` 先后接到两种设备上：

```cpp
Light light;
Switch ls(light);
ls.toggle();
assert(ls.is_on() && light.state() == "light-on");
ls.toggle();
assert(!ls.is_on() && light.state() == "light-off");

Fan fan;
Switch fs(fan);          // 同一个 Switch，接上另一个设备照常工作
fs.toggle();
assert(fs.is_on() && fan.state() == "fan-on");
```

运行输出：

```text
DIP: light.state=light-off, fan.state=fan-on
```

`light.state` 打印 `light-off` 是因为 `ls` toggle 了两次回到关闭——输出与断言各自完整，说明**开关逻辑与设备逻辑完全解耦**：加第三种设备（比如空调），`Switch` 的代码零改动，这又是 OCP。

### 两个必须分清的近亲

DIP 常和两个概念混在一起，需要切割清楚：

- **依赖注入（DI）**：`Switch(Switchable& dev)` 通过构造函数把依赖从外面传进来，这叫注入。DIP 是**原则**（该依赖谁），注入是**手法**（怎么把依赖交到手）。C++ 没有容器化 DI 框架也能活，构造函数注入就够了。
- **控制反转（IoC）**：框架调你的代码（如 GUI 框架回调），流程的主动权反转了。DIP 只是 IoC 在"依赖管理"上的一个子集。

### 依赖的三种写法

之禅 3.3 节把"传递依赖"归纳成三种写法，C++ 里同样适用，值得并排看：

```cpp
// 1. 构造函数注入：依赖在对象出生时定死，生命周期内不变——最稳
Switch s1(light);

// 2. setter 注入：依赖可中途替换，代价是存在"没注入就调用"的窗口期
class Switch2 {
public:
    void bind(Switchable& d) { dev_ = &d; }   // 可空：注入前调用是未定义行为
    void toggle() { /* dev_->on()/off() */ }
private:
    Switchable* dev_ = nullptr;
};

// 3. 接口注入（方法参数注入）：依赖只在一次调用内有效，最轻
void press(Switchable& dev);   // 调一次给一次
```

选择的经验法则：**依赖是对象的本质配置（人的心脏、车的发动机）用构造注入；可选的、可换的（插拔外设）用 setter；一次性的（函数要用的工具）用参数**。示例 `dip.hpp` 里的 `Switch(Switchable&)` 属于第一类——开关离开设备没有意义，出生时就该绑定。注意 setter 版示例里用的是**裸指针加可空语义**：C++ 里"还没有依赖"这个状态要用 `std::optional<std::reference_wrapper<Switchable>>` 或注释明示的裸指针表达，`std::reference_wrapper` 是引用的"可重新绑定"形态——纯引用成员一旦绑定终身不能改，不适合 setter 注入。

还有一个 C++ 特有的坑要拆：**注入的依赖必须活得比使用者久**。`Switch` 存的是 `Switchable&`，若引用指向的 `Light` 是个临时对象（`Switch s(Light{});`），`Switch` 从构造那一刻起就抱着一个悬垂引用。Java 没有这个问题（GC 保命），C++ 的构造注入要遵守"成员引用只指向构造前就存在、且生命周期覆盖使用者"的对象。拿不准就存 `std::shared_ptr<Switchable>`，让所有权显式化——代价是所有权图变复杂，正因如此本书示例在"局部场景、生命周期一目了然"时优先用引用。

### 现代补充：模板参数也是"抽象"

虚接口不是唯一的抽象手段。`Switch` 也可以写成模板：

```cpp
template <typename Dev>
class TSwitch {
    Dev& dev_;
public:
    explicit TSwitch(Dev& d) : dev_(d) {}
    void toggle() { dev_.on_ ? ... }   // 只要 Dev 有 on()/off()
};
```

不需要公共基类，任何有 `on()/off()` 的类型都能接。和上一章 concepts 版 `total_area` 同一个道理。取舍也相同：运行期换设备用虚接口，编译期定死且追求零开销用模板。第 29 章会把这条谱系统一收拢。

## 陷阱清单

1. **用继承复用代码**（现象：`SquareL : RectL` 式"偷"基类实现；原因：把继承当代码搬运工具；后果：子类违反基类合同，LSP 破产。对策：复用走组合，继承只表达"是一种"且合同兼容）。
2. **override 后抛出父类不会抛的异常**（现象：基类承诺"不抛异常"，子类实现抛了；原因：后置条件变弱；后果：按基类合同写的调用方缺少处理路径。对策：C++ 用 `noexcept` 显式写进合同，子类覆盖同样 `noexcept` 的函数时再抛异常会直接 `std::terminate`——让违约早爆出来）。
3. **抽象层长出实现细节**（现象：`Switchable` 上出现 `set_brightness()` 这种只有灯才懂的方法；原因：抽象接口按某一个实现的需要随加随长；后果：接口被"特征污染"，下一个实现被迫实现无关方法——这正是接口隔离原则（第 04 章）要治的病）。
4. **倒置过度**（现象：两层抽象之间又插一层抽象，"抽象工厂的工厂"；原因：为模式而模式；后果：每个"只有一个实现"的接口都是白付的间接成本。对策：YAGNI——出现第二个实现之前，具体类就够了）。
5. **在基类合同里假设调用顺序**（现象：方法 B 只在 A 之后调用才正确但合同没写；原因：隐式时序依赖；后果：换一个实现就坏。对策：时序写进文档或干脆用类型状态（typestate）编码——第 33 章编译期状态机会正面处理）。

## 三书对应

- 之禅：第 2 章"里氏替换原则"（2.2 纠纷不断，规则压制）、第 3 章"依赖倒置原则"（3.3 依赖的三种写法——构造函数注入/setter 注入/接口注入，与本章 `Switch` 的构造注入对应）。
- 刘伟：2.4 里氏代换原则、2.5 依赖倒转原则（注意中文教材多写作"依赖倒转"）。
- GoF：第 1 章 1.6.2 节（针对接口编程）；Liskov 原始论文 GoF 书末参考文献 [Lis87]。

*可选延伸：可运行示例见 examples/03_lsp_dip/。*

---

上一章：[02 单一职责与开闭](02-srp_ocp.md) · 下一章：[04 接口隔离、迪米特与合成复用](04-isp_lod_crp.md)
