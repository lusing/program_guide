# 11 · 适配器

结构型篇从适配器开始——它不设计新系统，它**缝合旧代码**。刘伟 10.1.2 节的定义：**将一个接口转换成客户希望的另一个接口，使接口不兼容的那些类可以一起工作**。别名"包装器（Wrapper）"。GoF 把它列为第一个结构型模式不是偶然：结构型模式研究"怎么组合类和对象成更大的结构"，而组合世界中最先遇到的问题就是"两边接口对不上"。

## 意图与动机

工程里最现实的场景：系统已经跑了一段时间，某模块一直在用自己的 `LegacyStack`；现在要接入一个新框架，框架的扩展点要求的是 `StackLike` 接口（有 `empty()`，没有 `size()`）。两条路都难走：改 `LegacyStack` 的接口——它是老代码，改了牵动所有旧调用方（甚至没有源码）；改新框架的扩展点——那是第三方代码。两边都动不了，唯一出路是在中间放一个**转换层**：实现 `StackLike`，内部持有一个 `LegacyStack`，每个新接口请求都翻译成旧接口调用。GoF 引用的是电源适配器：插座形状（接口）不变，插头形状（被适配者）不变，适配器在中间做机械转换。

## 经典写法：对象适配器

示例 `object_adapter.hpp`。被适配者与目标接口：

```cpp
// Adaptee：已有代码，接口不合用（pop 同时返回并移除，但没有 empty）。
class LegacyStack {
public:
    void push(int v) { data_[count_++] = v; }
    int pop() { return data_[--count_]; }
    [[nodiscard]] int top() const { return data_[count_ - 1]; }
    [[nodiscard]] size_t size() const { return count_; }
private:
    int data_[64]{};
    size_t count_ = 0;
};

// Target：调用方想要的接口。
struct StackLike {
    virtual ~StackLike() = default;
    virtual void push(int) = 0;
    virtual int pop() = 0;
    [[nodiscard]] virtual bool empty() const = 0;
};
```

适配器本体只有十行：

```cpp
class StackAdapter final : public StackLike {
public:
    explicit StackAdapter(LegacyStack& legacy) : legacy_(&legacy) {}

    void push(int v) override { legacy_->push(v); }      // 直通
    int pop() override { return legacy_->pop(); }        // 直通
    [[nodiscard]] bool empty() const override {
        return legacy_->size() == 0;                     // 翻译：size==0 扮演 empty
    }
private:
    LegacyStack* legacy_;
};
```

三个要点：

1. **"实现 Target + 持有 Adaptee"是对象适配器的全部结构**。`push`/`pop` 是直通转发（两边签名恰好一致），`empty()` 是真正的"翻译"（Target 问有没有，Adaptee 只会说有几个）——一个适配器里两种请求形态并存，这正是真实适配器的常态：部分直通、部分换算、部分干脆补写（Adaptee 缺的功能在 Adapter 里现场实现）。
2. **持有引用/指针而不是值**。适配器不拥有被适配者——`LegacyStack` 的生命周期归旧系统管，适配器只是"借它的服务"。若持值，每适配一份就多一份拷贝状态，新旧两个对象数据不同步。
3. **`final` 收尾**。适配器是末端装配件，不再开放继承。

运行输出：

```text
对象适配器: push×3 后 empty=否
对象适配器: pop 顺序 3->2->1 LIFO 正确
```

断言验证 LIFO：push 1/2/3 后 pop 依次得 3、2、1——适配没有改变被适配者的行为语义，只翻译了接口。**适配器是行为中立的，它不做业务**。

## C++ 特有形态：类适配器（私有继承）

GoF 的 Adapter 分两个变体：对象适配器（组合）和类适配器（多重继承）。类适配器是 C++ 特有的多继承礼物——Java 只有单继承，做不了；C++ 能做，示例 `template_adapter.hpp`：

```cpp
// 继承 Target 获得"是一个栈"的接口身份；私有继承 Adaptee 获得它的实现，
// 但阻断"Adapter 不是一个 LegacyStack"的误用——私有继承表达"按实现继承"。
class StackClassAdapter final : public StackLike, private LegacyStack {
public:
    void push(int v) override { LegacyStack::push(v); }   // 显式指名，防自递归
    int pop() override { return LegacyStack::pop(); }
    [[nodiscard]] bool empty() const override { return size() == 0; }
private:
    using LegacyStack::top;   // 旧接口不外泄：把 top 留成私有
    using LegacyStack::size;
};
```

细读这段代码的四个设计决定：

1. **public 继承 `StackLike`、private 继承 `LegacyStack`**：公有继承对外的语义是"是一个"（适配器确实可以当栈用），私有继承对外的语义是"按它实现"（但适配器不承诺自己是 LegacyStack，旧代码不能把适配器传给期待 LegacyStack 的函数——这个方向本来就是错的）。如果两个都 public 继承，适配器会同时是两种东西，接口污染。
2. **`LegacyStack::push(v)` 显式限定**：成员函数里裸调 `push(v)` 会先匹配到自己的 `push` 虚函数——无限自递归当场栈溢出。这是多继承覆写同名函数的通用防御写法。
3. **`using LegacyStack::top` 挪进 private**：私有继承把继承来的 public 成员降为 private（本已不可见），但 `using` 声明可以把它们"提"回当前作用域——这里反着用：把旧接口里不该外泄的 `top`/`size` 收进私有区，只暴露翻译过的 `empty()`。
4. **类适配器不需要引用、不需要间接**：`push` 直接是成员函数调用，连指针解引用都省了。

运行第三行：

```text
类适配器: pop 顺序 20->10 LIFO 正确
多态: StackLike& 消费对象/类两种适配器均可用
```

两种适配器都能被 `StackLike&` 多态消费——从调用方视角它们无差别。差别全在实现侧。

## 两版取舍

| 维度 | 对象适配器（组合） | 类适配器（私有继承） |
|---|---|---|
| 适配对象 | 任意 Adaptee 实例（含子类） | 只有 LegacyStack 及其子类 |
| 能否重绑 | 可以（换一个 legacy 引用） | 不行（Adaptee 部分编译期焊死） |
| 额外间接 | 一次指针解引用 | 零（成员调用直通） |
| 访问 Adaptee 受保护成员 | 不能（没有继承关系） | 能（私有继承也算继承） |
| 第 4 章合成复用原则 | 符合（组合优先） | 例外——"为了复用而继承"的唯一正当场景 |

GoF 原书自己说"对象适配器更灵活"，C++ 教材（刘伟 10.2 节同时给两个版本）通常加一句：能用对象适配器就用对象适配器。类适配器的真实用武之地很窄：**Adaptee 是无状态类、适配关系永久、且需要访问其 protected 成员或虚函数钩子**时。多数现代代码遇到"接口不合"还有第三条路——如果 Target 接口是新设计的，直接让新接口带模板参数/concept 约束，任何"长得像"的类型都免适配：`concept StackLike2 = requires(...) { ... }`，鸭子类型让适配器都省了。但那是编译期多态的领地；运行期多态（框架扩展点是虚接口）时，适配器仍不可替代。

## 适配器在模式家族里的位置

之禅第 19 章给了适配器一个准确的标签：**补救模式**——它不属于"为未来设计"，属于"为过去擦屁股"。三个特征让你认出适配器需求：接口不合（签名/参数/返回值对不上）、两边都不能改（旧系统有依赖、新系统是三方）、语义一致（都是栈，只是说法不同）。第三条是分界线：语义不一致时上的不是适配器，是**防腐层（Anti-Corruption Layer）**——那层代码会做真正的业务换算（单位、货币、模型映射），设计上长得像适配器，职责上完全不同。适配器一行业务都不该有；一旦发现 Adapter 里开始出现"如果 XX 就换算成 YY"，它已经不是适配器了，把它按防腐层重新命名和管理。

## 缺省适配器：只覆写一半的 Target

Target 接口大、调用方只用其中两三个方法是常态。刘伟 10.5 节的"缺省适配器（Default Adapter）"给中间垫一层空实现，具体类只覆写需要的：

```cpp
struct FatTarget {
    virtual ~FatTarget() = default;
    virtual void on_click() = 0;
    virtual void on_hover() = 0;
    virtual void on_key(int) = 0;
};

// 缺省适配器：五个空实现垫底（含析构在内的公共默认行为）
class DefaultHandler : public FatTarget {
public:
    void on_click() override {}
    void on_hover() override {}
    void on_key(int) override {}
};

// 具体类：只关心点击
class ClickOnly final : public DefaultHandler {
public:
    void on_click() override { last_ = "clicked"; }
    [[nodiscard]] const char* last() const { return last_; }
private:
    const char* last_ = "";
};
```

这个结构的现代对应物其实是 **lambda/回调注册**：框架提供 `set_on_click(std::function<void()>)`，只关心什么就注册什么，三个空实现都不用写。缺省适配器是回调机制出现前 OOP 框架的标准解（Java 的 WindowAdapter 至今活着），遇到老框架仍会碰到。

## std::function 作适配器

当 Target 接口只有一个方法时，连类都不用写——`std::function` 就是对象适配器的函数形态：

```cpp
// Target 是单方法接口（比如回调槽）：
using IntSource = std::function<int()>;

// 老代码给的是 LegacyStack（pop 返回栈顶）。一个 lambda 完成适配：
LegacyStack legacy;
IntSource src = [&legacy] { return legacy.pop(); };   // 接口翻译一行写完
```

没有 Adapter 类、没有继承，适配逻辑内联在捕获里。这条路线的边界也清楚：**单方法、无状态或轻状态、适配关系就地使用**——复杂了（多方法、要管理生命周期、要被多态指认）就退回类适配器。与第 6 章"FnLoggerCreator 替代 Creator 类"同一个判据。

## 编译期适配：concept 让一部分适配器消失

运行期多态的适配靠 Adapter 类；编译期泛型的"适配"有更轻的工具——concept 直接描述"我需要什么能力"，长得不一样的类型只要能力对得上就免适配：

```cpp
template <typename S>
concept SizedStack = requires(S s, int v) {
    s.push(v);
    { s.size() } -> std::convertible_to<size_t>;
};

template <SizedStack S>
bool is_empty_via_size(const S& s) { return s.size() == 0; }
```

`LegacyStack` 没实现任何接口，但 `is_empty_via_size(legacy)` 直接能用——concept 只问"会不会做"，不问"有没有声明会做"。这与第 2 章 `ShapeLike` 的精神一致：**鸭子类型让"结构兼容"的类型互为适配器**。三条边界要认清：它只服务编译期（模板实例化点检查）；错误信息发生在使用现场（而非类型定义处）；同一个 concept 的两种类型仍是两个类型（不能塞进同一个容器）。所以工程上的分法：**框架扩展点（运行期插件、二进制边界）→ 继承 + Adapter；算法泛型（编译期、同进程）→ concept 免适配**。

## 陷阱清单

1. **Adapter 里长出业务逻辑**（现象：`empty()` 顺手做了一次缓存刷新；原因：适配层"顺手"；后果：行为中立的承诺被打破，调用方再也不敢假设适配无损。对策：适配器只翻译接口，任何额外动作挪出去）。
2. **双向适配的诱惑**（现象：一个类同时实现 A 接口包 B、B 接口包 A；原因：想复用；后果：互相引用成环，理解成本爆炸。对策：两个方向各写一个适配器，代价小得多）。
3. **类适配器忘记限定名**（现象：`push(v)` 裸调；原因：以为调用的是基类版本；后果：无限递归栈溢出。对策：多继承覆写一律 `Base::func` 显式限定）。
4. **适配缺省接口**（现象：Target 有五个纯虚函数，Adaptee 只需要覆盖三个；原因：照抄 Target 签名；后果：两个空实现污染。对策：先写一个缺省适配器（Default Adapter，刘伟 10.5 节的扩展形态——用空实现垫底），子类只覆写需要的）。
5. **把适配器当性能层**（现象：每次调用都新建适配器包装；原因：不理解适配器是无状态薄壳；后果：对象爆炸。对策：适配器轻到可以随便造，但包装关系保持稳定——要么持有适配器，要么不持有）。

## 动手前的一个问题：要不要适配

适配器是"补救模式"不假，但补救也要挑时机。动手写 Adapter 前问一句：**这个接口不合是永久的还是暂时的**？暂时（三方库下个版本会提供原生接口）就写薄适配器、标注版本、准备拆除；永久（私有协议、历史遗产）才值得做完整适配层（含缺省适配器、错误换算）。反过来，"预计将来接口会换"不是上适配器的理由——那是过度设计：YAGNI 判据在结构型模式里同样适用，第二个消费者出现之前，适配逻辑留在一个函数里就够。本章 `StackAdapter` 十行写完，正是"薄适配"的样子；需要加厚时（错误翻译、日志、生命周期管理），它已经是一个类，加厚不加价。

## 三书对应

- 之禅：第 19 章"适配器模式"（19.2 定义、19.3 应用——变压器比喻、19.4 扩展——双向适配器），另第 31 章 31.2 节"装饰模式 VS 适配器模式"的 PK 分析在读完第 14 章装饰后值得回看。
- 刘伟：第 10 章"适配器模式"（10.1 动机与定义、10.2 结构与分析——类/对象两版、10.3 实例——机器人仿生狗、10.4 效果与应用、10.5 扩展——缺省适配器、双向适配器）。
- GoF：第 4 章 4.1 节 Adapter——TextShape 例子（TextView 被适配成 Shape）同时演示类/对象两版，"相关模式"节指出 Adapter 与 Bridge 的关系（两者都转发请求，Adapter 先天存在而 Bridge 是有意设计出来的）。

*可选延伸：可运行示例见 examples/11_adapter/。*

---

上一章：[10 建造者](10-builder.md) · 下一章：[12 桥接](12-bridge.md)
