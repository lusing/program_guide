# 22 · 中介者

迭代器解耦"遍历"，中介者解耦"群体通信"。GoF 5.5 节的定义：**用一个中介对象来封装一系列的对象交互。中介者使各对象不需要显式地相互引用，从而使其耦合松散，而且可以独立地改变它们之间的交互**。定义里最有分量的是最后半句——交互方式本身被装进了中介者这一个类里，改交互协议不再需要动任何一个同事。

## 意图与动机

对比两种拓扑。3 个人互相发消息，网状拓扑下每个 `User` 要持有另外 2 人的引用——**n 个对象的网状通信需要 n·(n−1) 条连接**，加第 4 个人要改前 3 个类。星型拓扑下所有人只持一个 `ChatRoom*`——连接数降为 n，加人零改动。这个"网状改星型"就是中介者的全部几何：**交互知识从每个对象身上抽走，集中到枢纽一处**。

现实中的中介者无处不在：聊天室（本章例子）、机场塔台（每架飞机只跟塔台通话，不跟其他飞机协调）、GUI 对话框（输入框、按钮、复选框互相不认识，联动逻辑全在对话框类里）、Qt 的信号槽本质也是广播式中介。

## 经典写法：聊天室

示例 `mediator.hpp`。中介者与同事：

```cpp
// Mediator：聊天室——唯一的"枢纽"，成员表 + 消息日志。
class ChatRoom {
public:
    void join(std::string name) { members_.push_back(std::move(name)); }

    // 群发：from -> 所有其他成员；日志记一笔
    void send(std::string_view from, std::string_view msg) {
        log_.push_back(std::format("{}->{}", from, msg));
    }

    [[nodiscard]] size_t log_size() const { return log_.size(); }
private:
    std::vector<std::string> members_;
    std::vector<std::string> log_;
};

// Colleague：用户——只认识中介者，不认识任何其他用户。
struct User {
    std::string name;
    ChatRoom* room;                    // 中介者指针：同事的全部通信信道

    void say(std::string_view msg) const { room->send(name, msg); }
};
```

注意 `User::say` 的一行实现：用户只做一件事——**把消息交给房间**。alice 不需要认识 bob 和 carol，甚至不需要知道房间里有谁；"谁会收到、以什么形式收到"是 `ChatRoom::send` 的私有决定。这就是"可以独立地改变交互"：把群发改成私聊、把日志改成审计，User 一行不改。运行侧（`main.cpp`）：

```cpp
ChatRoom room;
room.join("alice");  room.join("bob");  room.join("carol");

User alice{"alice", &room};
User bob{"bob", &room};
User carol{"carol", &room};

alice.say("hello");
bob.say("hi");
assert(room.log_size() == 2);                 // 两条消息都进日志
assert(room.log()[0] == "alice->hello");
```

运行输出：

```text
中介者: 3 人房间 2 条消息，日志含 -> 行
星型: 同事互不相识，全部通信经 ChatRoom 枢纽
```

断言钉死两件事：3 个成员 2 条消息日志逐行正确（`"alice->hello"` 格式），carol 事后 `say` 也不需要任何接线——`room` 指针就是全部通信协议。

## 模式结构（ASCII 图）

```text
   网状（n·(n-1) 条线，改一个牵全体）        星型（n 条线，改协议只动枢纽）

   alice ── bob                                 alice
     │  ╲ ╱  │                                    │
     │  ╳╳   │                                    ▼
     │ ╱  ╲  │                                 ┌─────────┐
   carol ── ...                              carol ──>│ ChatRoom │<── bob
                                                      │ send/log │
                                                      └─────────┘
                                                      交互知识唯一归口
```

GoF 四角色：Mediator（ChatRoom）、ConcreteMediator（本例合一）、Colleague（User）。GoF 原始设计里 Mediator 是接口、ConcreteMediator 才是聊天室——C++ 里只有一个中介实现时，接口这层皮可以省（与全书"先跑通再抽象"的立场一致）；但多个通信场景（聊天室、群组、私聊）并存时，Mediator 接口就值得抽出来。

## 现代写法：信号槽广播

中介者的极简形态是**广播表**：订阅即注册回调，发布即遍历回调（`mediator.hpp` 末尾）：

```cpp
class SignalHub {
public:
    using Slot = std::function<void(std::string_view, std::string_view)>;

    void subscribe(std::string who, Slot slot) {
        slots_.emplace_back(std::move(who), std::move(slot));
    }
    void publish(std::string_view from, std::string_view msg) const {
        for (const auto& [who, slot] : slots_)
            if (who != from) slot(from, msg);      // 不回声给自己
    }
private:
    std::vector<std::pair<std::string, Slot>> slots_;
};
```

对比 ChatRoom：**枢纽从"知道一切、代为分发"退化成"只管转发表"**——收到什么、怎么反应，决定权移到了每个订阅者的槽函数里。这是中介者的现代谱系：经典中介者（集中决策）→ 观察者/信号槽（分散反应）→ 事件总线（全局广播，第 32 章 eventbus 实战）。运行侧验证：

```cpp
SignalHub hub;
std::vector<std::string> inbox_bob, inbox_carol;
hub.subscribe("alice", [](std::string_view, std::string_view) {});   // 自己也订阅
hub.subscribe("bob",   [&](auto from, auto msg) { inbox_bob.push_back(std::format("{}:{}", from, msg)); });
hub.subscribe("carol", [&](auto from, auto msg) { inbox_carol.push_back(std::format("{}:{}", from, msg)); });

hub.publish("alice", "ping");
assert(inbox_bob.size() == 1);                // bob 收到，alice 不回声

hub.publish("bob", "pong");
assert(inbox_bob.size() == 1);                // bob 不收自己的消息
```

运行输出后两行：

```text
信号槽: 发布 1 条，2 个订阅者各收到 1 条（不回声给发布者）
信号槽: bob 发布后自己不回声，carol 收到第 2 条
```

**"不回声"**（`who != from`）是信号槽与经典中介者的一个微妙差异点：经典中介者按业务逻辑决定转发目标，信号槽按"订阅者是否恰好是发布者"一刀切。两种写法逐条验证：alice 发布 ping 后 bob/carol 各收 1 条、alice 收 0 条；bob 发布 pong 后自己仍是 1 条、carol 变 2 条。

## GUI 联动：中介者的主场

聊天室例子太"温和"——同事间几乎没有真交互。中介者的原生场景是 **GUI 对话框联动**（GoF 的 FontDialogDirector、刘伟 21.5 都用这个）：一个输入框、一个复选框、一个确定按钮，规则是"勾选同意才允许点确定"：

```cpp
// 同事们互不引用，联动规则全在对话框（中介者）里
class Dialog {                      // 中介者
public:
    void on_checkbox(bool checked) {
        ok_enabled_ = checked;      // 联动规则唯一归口
        if (input_ && !checked) input_->clear();   // 取消勾选顺带清空
    }
    void on_input(std::string text) {
        ok_enabled_ = !text.empty() && agreed_;    // 规则可以再叠
    }
    bool ok_enabled() const { return ok_enabled_; }
    void set_agreed(bool v) { agreed_ = v; }
private:
    Widget* input_ = nullptr;       // 同事只认识 Dialog
    bool agreed_ = false;
    bool ok_enabled_ = false;
};
```

把这段与网状拓扑对照：朴素写法里 `Checkbox` 要持 `Button&`（点击时改按钮状态）、`InputBox` 也要持 `Button&`——两个控件类里各埋一份"按钮何时可用"的知识。中介者收编后，**控件类退化为纯事件源**（只报告"我被点了"），业务规则一个地方可查。这就是为什么所有 GUI 框架的事件模型（WinUI 的 x:Bind、Qt 的信号槽、浏览器的 DOM 事件）都在往"组件发事件、逻辑在外"的方向演化——本质都是把中介者的联动规则从控件类里抽出来。代价也看得见：`Dialog` 随控件增多而膨胀（陷阱 1），控件超过一打就该把联动规则拆成多个小中介者或迁往信号槽。

## 接口分层：什么时候需要 Mediator 抽象类

本例 `ChatRoom` 是具体类，没有 GoF 图里的 `Mediator` 接口。省掉的理由：只有一个中介实现时，接口是空转的一层。什么时候该补上：

```cpp
// 多个通信场景并存时，同事改持接口——可替换的中介者
class ChatMediator {
public:
    virtual ~ChatMediator() = default;
    virtual void send(std::string_view from, std::string_view msg) = 0;
};

class Room final : public ChatMediator { /* 群聊实现 */ };
class PrivateLine final : public ChatMediator { /* 私聊实现 */ };

struct User {
    std::string name;
    ChatMediator* channel;          // 从 ChatRoom* 放宽为接口指针
};
```

判定与全书其他模式的接口二分一致：**抽象在第二个实现出现时才引入**。聊天室/私聊/群组并存（交互协议不同）、或测试时需要替身中介者（mock 注入）——两种情况任一出现，接口就该补上；只有一种交互方式时，具体类更诚实。这个顺序（先具体后抽象）与 GoF 图（先抽象后具体）的呈现顺序相反，但工程上更稳：GoF 图描述的是"成熟系统的最终形态"，不是起步姿势。

## 与观察者的分界（第 25 章预告）

信号槽这个写法让人疑惑：这不就是观察者吗？分界在**意图**而非实现：观察者管**通知**（状态变了，告诉我一声——单向、一对多、主题不知道订阅者用来干嘛）；中介者管**协作**（多方交互的协议收敛到一处——双向、多方、枢纽理解交互语义）。信号槽实现天然横跨两者：用于 UI 事件通知时是观察者，用于收敛一群对象的互调协议时是中介者。判断标准一句话：**枢纽理解消息的含义吗？理解（比如"发消息要记日志"）是中介者，不理解（纯转发）是观察者**。第 25 章观察者会把 WeatherData 例子做一遍，两者代码长得很像但思考起点完全不同。

## 陷阱清单

1. **上帝中介者**（现象：枢纽类几千行、塞满各业务联动；原因：所有交互知识集中一处，天然吸引功能堆积；后果：中介者自己变成最难改的类——解耦了同事，耦合了上帝。对策：交互协议分层（聊天室/群组/私聊各一个中介者），或降级为信号槽让决策回流到订阅者）。
2. **同事互持引用的漏网**（现象：某同事图方便直接拿了另一个同事的指针；原因：星型纪律被绕过；后果：网状连接悄悄回来，改协议时漏改。对策：同事类只收 `Mediator&` 构造参数（本例 User 只持 `ChatRoom*`），review 时盯" colleague 之间有没有线"）。
3. **双向依赖编不过去**（现象：User.h include ChatRoom.h、ChatRoom.h 又 include User.h；原因：双向通信的自然冲动；后果：循环包含。对策：中介者接口与同事分头前向声明，或像本例一样把接口内联在头文件里单向 include）。
4. **信号槽悬空捕获**（现象：槽 lambda 捕获栈上 vector 引用，发布时对象已析构；原因：订阅生命周期长于捕获对象；后果：UB。对策：订阅与取消订阅配对（SignalHub 应有 unsubscribe）、或槽内用 weak 语义（本例生命周期都在 main 内，免于此劫））。
5. **回声与自触发**（现象：A 发布→B 的槽里又 publish→A 收到自己引发的间接消息，循环放大；原因：广播拓扑对环路不设防；后果：消息风暴。对策：枢纽记"处理中"标志拒绝重入，或协议上禁止槽内 publish）。

## 三书对应

- 之禅：第 14 章"中介者模式"（14.2 定义、14.3 应用——"进销存"三大模块经中介者协调的例子、14.4 扩展——明确指出"中介者模式的缺点是中介者会膨胀"，与本章陷阱 1 同源）。
- 刘伟：第 21 章"中介者模式"（21.1 动机与定义、21.2 结构与分析、21.3 实例——客户关系管理 CRM 系统各模块协调、21.5 扩展——中介者与GUI开发（对话框即中介者））。
- GoF：第 5 章 5.5 节 Mediator——对话框例（FontDialogDirector 联动输入框与列表框，本章 GUI 一提的展开），"实现"节讨论"谁来仲裁（自行/外部）、Mediator 与 Colleague 的相互引用方式"。

*可选延伸：可运行示例见 examples/22_mediator/。*

---

上一章：[21 迭代器](21-iterator.md) · 下一章：[23 备忘录](23-memento.md)
