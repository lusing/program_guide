# 24 · 观察者

行为型下篇从观察者开始——它是三个模式（观察者/中介者/责任链）中"解耦通知"最纯粹的一个，也是 GUI 框架、消息队列、响应式编程共同的祖先。GoF 5.7 节的定义：**定义对象间的一种一对多依赖关系，使得每当一个对象状态发生改变时，其相关依赖对象皆得到通知并被自动更新**。定义里"一对多"是结构，"自动更新"才是意图——主题不知道谁在听、听来干什么，它只负责"变了就说一声"。

## 意图与动机

气象站的温度变了，A 显示板要刷新数字，B 显示板要刷新曲线。朴素写法是气象站更新后手动调两块板的刷新函数——**主题必须认识每一个显示者**，加第三块板要改气象站。观察者把依赖倒过来：显示板主动"订阅"气象站，气象站只维护一张订阅者名单，状态一变就沿名单通知。加新显示板 = 新对象调一次 attach，气象站零改动。刘伟 23 章的动机表述精炼：观察者模式又叫做**发布-订阅模式**——发布者与订阅者互不相识，全凭名单相连。

## 经典写法：气象站

示例 `observer.hpp`。抽象观察者与主题：

```cpp
// Observer：抽象观察者——主题只认这个接口，具体显示板对主题不可见。
class Observer {
public:
    virtual ~Observer() = default;
    virtual void on_update(double t) = 0;
};

// Subject：主题——attach/detach/notify 三件套。
class Subject {
public:
    void attach(Observer* o) { obs_.push_back(o); }
    void detach(Observer* o) {
        for (auto it = obs_.begin(); it != obs_.end(); ++it)
            if (*it == o) { obs_.erase(it); return; }
    }
    void notify(double t) {
        for (auto* o : obs_) o->on_update(t);      // 顺序通知：观察者 O(n)
    }
    [[nodiscard]] size_t count() const { return obs_.size(); }

private:
    std::vector<Observer*> obs_;     // 裸指针：主题不拥有观察者（生命周期归客户）
};
```

**裸指针是本例的深思熟虑而非偷懒**：主题不拥有观察者——显示板的生命周期归界面层管，主题只是"知道有这些人"。谁创建谁删除（RAII 纪律照旧），主题只做登记与通知；`detach` 存在的意义正是让观察者死亡前自觉退订（不退订就是悬空——见陷阱 2）。两块显示板：

```cpp
struct DisplayA final : Observer {
    double last = -999;
    void on_update(double t) override { last = t; }
};

struct DisplayB final : Observer {
    double last = -999;
    bool received = false;
    void on_update(double t) override { last = t; received = true; }
};
```

运行侧（`main.cpp`）：

```cpp
Subject station;
DisplayA a;  DisplayB b;
station.attach(&a);  station.attach(&b);
station.notify(25.5);
assert(a.last == 25.5 && b.last == 25.5);   // 两个都收到

station.detach(&a);                          // A 退订
station.notify(30.0);
assert(a.last == 25.5);                      // A 停在旧值——没再收到
assert(b.last == 30.0);                      // B 跟上
```

运行输出：

```text
观察者: notify(25.5) 后 A/B 各自更新
观察者: detach A 后再 notify，仅 B 更新
信号: function 订阅 lambda 收值 25.5/30.0
```

断言钉死"退订即隔离"：detach 后 A 的 `last` 冻结在旧值——它从通知流里消失了，而主题对这一切毫不知情（count 只反映名单长度）。这正是"一对多、单向依赖"的兑现：**依赖只有一条边（观察者 → 主题），主题侧零反向知识**。

## 模式结构（ASCII 图）

```text
      DisplayA ──attach──┐
      DisplayB ──attach──┤    ┌──────────────┐
                         ├──>│ Subject      │
      （依赖方向：        │   │ notify(t)    │────for o in obs_────> o->on_update(t)
        观察者认识主题，  └───│ attach/detach│
        主题只见接口）        └──────────────┘
```

GoF 四角色：Subject（气象站）、Observer（接口）、ConcreteObserver（两块板）。ConcreteSubject（具体主题）本例与 Subject 合一——只有一个主题时接口层省略，与全书"抽象在第二个实现出现时才引入"一致。

## 现代写法：function 主题

只有"收到值做点事"的观察者，接口类可以整个换掉——订阅一个闭包：

```cpp
class FunctionHub {
public:
    void subscribe(std::function<void(double)> f) { subs_.push_back(std::move(f)); }
    void notify(double t) const {
        for (const auto& f : subs_) f(t);
    }
private:
    std::vector<std::function<void(double)>> subs_;
};

// 使用：lambda 即观察者
FunctionHub hub;
std::vector<double> got;
hub.subscribe([&got](double t) { got.push_back(t); });
hub.notify(25.5);
```

类观察者 → 闭包，`attach` → `subscribe`，接口方法 → lambda 签名——结构与经典版一一对应。**坑也随之换形**：经典版退订阅靠 `detach`（按指针身份删除，安全），function 版没有身份——想移除就得按值比较（lambda 不可比较）或改存 id→function 的映射；更隐蔽的是**通知途中退订**：某个观察者在 `on_update` 里调 `unsubscribe`，正遍历的 `vector` 迭代器立刻失效。经典版同有此坑（on_update 里 detach 自己），但 function 版 lambda 匿名无身份，防不胜防。对策三条：通知期间只收集不改名单（延迟删除）、名单存 `shared_ptr` 令牌按令牌退订、或整个换成第 22 章的信号槽实现（Qt 信号槽的 connection 对象就是"令牌"形态的工业答案）。运行输出第三行验证 lambda 订阅收值正常。

## 通知语义的三个决定

实现观察者前必须回答三问，答案写进文档，否则每次并发/异常讨论都会翻案：

1. **通知顺序**：`std::vector` 保证插入序（本例如此）——但观察者间有依赖时（B 依赖 A 的副作用）这个序就是契约，一旦依赖文档要写明。
2. **异常传播**：某个观察者 on_update 抛异常，后面的观察者还收得到吗？本例不允许抛（异常炸穿 notify，名单后续全断）。工业实现通常逐观察者吞异常记录——通知是主题的义务，不是观察者要挟主题的筹码。
3. **同步还是异步**：本例同步（notify 返回时所有观察者已更新完，调用方拿到的是"已生效"的世界）；消息队列是异步形态（notify 只是投递，生效时刻不确定）。同步简单且可断言，代价是慢观察者拖住主题——拖不动了就该换异步，而异步一上来，第 31 章并发篇的整套问题（顺序、背压、线程安全）随之而来。

这三问没有标准答案，但有标准动作：**写进 Subject 类的注释里**。观察者通知语义是典型的"隐式契约"，不落纸面，两年后没人知道 notify 是同步还是异步、顺序是否有保证——而此时已有五个观察者悄悄依赖了实现细节。契约先行，是主题类唯一一件在 attach 之前就该做的事。

## 推模型 vs 拉模型

本例 `on_update(double t)` 把状态值**推**给观察者——推模型。反向是拉模型：`on_update(Subject&)` 只通知"变了"，观察者需要什么自己回查主题：

```cpp
// 拉模型：观察者持有主题引用，"变了吗"推过来，"变了什么"拉回去
struct PullDisplay final : Observer {
    explicit PullDisplay(const Subject& s) : subject_(s) {}
    void on_update(double) override { last_ = subject_.temperature(); }   // 拉取
private:
    const Subject& subject_;
    double last_ = -999;
};
```

两模型取舍：**推**高效（观察者不用再问一遍）、但主题要猜测观察者关心什么（温度变了湿度也变了，通知什么？）；**拉**接口稳定（永远只说"变了"）、但观察者与主题耦合加深（要认识 Subject 的查询接口）。GoF 建议折中：推"感兴趣的最小信息"，细节留给拉。第 22 章信号槽的 `(from, msg)` 参数就是推模型，Qt 属性系统的 `Q_PROPERTY + notify` 是拉模型的近亲。

## 观察者的谱系：从回调到响应式

观察者不是孤立模式，它是一族技术的共同祖先，C++23 语境下的谱系：

| 形态 | 本章位置 | 增量能力 |
|---|---|---|
| 接口观察者（经典） | 经典写法 | —— |
| function 观察者 | 现代写法 | 免写订阅类，闭包即订阅 |
| 信号槽 | 第 22 章 | 带令牌的退订、断连安全 |
| 事件总线 | 第 32 章 | 跨模块全局广播、按类型分派 |
| Observable 管道 | 第 31 章并发篇 | 异步通知、操作符组合（filter/map/merge） |

谱系的每一步都在补经典观察者的一个短板：退订安全（信号槽）、作用域控制（事件总线）、背压与线程（响应式）。反过来读这张表也是一条重构路径：项目里手写的 `vector<Observer*>` 长出退订需求时升信号槽，长出跨模块广播需求时升事件总线——**按需求的复杂度逐级换形态，不要一步到位上响应式框架**。

## Java Observable 之死：一个模式工程的警世故事

Java 9 把 `java.util.Observable` 标记为 deprecated——GoF 原书配套的标准类库组件，二十年后官方劝退。原因清单读起来眼熟：**不可序列化、线程安全模型含混（setChanged/notifyObservers 各自为政）、观察者顺序无契约、事件对象只有 Object**。对照本章陷阱清单，它几乎逐条踩过（通知途中改名单、变化标记含混）。C++ 标准库没有内置 Observable——这是**幸运而非缺失**：语言没有强制开发者接受一个二十年后才暴露设计问题的实现，每个项目按需造 observe 基建（本章 30 行）或选用成熟方案（信号槽库）。教训一分为二：模式的**意图**不朽（GUI 框架全在用），模式的**某个具体实现**会衰老；读 GoF 读意图，写代码按当下语言的能力重新落地——这正是本书"经典↔现代"双写法的立场。

## 三个解耦模式的合流处

行为型里管"解耦"的三兄弟容易混，给一张并排表收拢（细节回看各自章节）：

| | 观察者（本章） | 责任链（第 18 章） | 中介者（第 22 章） |
|---|---|---|---|
| 解耦什么 | 状态变化的通知 | 请求的处理权 | 群体交互协议 |
| 拓扑 | 一对多广播 | 线性顺序尝试 | 星型枢纽 |
| 传播停止条件 | 永不停（人人收到） | 首个接单者胜出 | 枢纽决定 |
| 主题/枢纽懂业务吗 | 不懂（纯名单） | 每环懂分档 | 懂（交互规则收口） |
| 典型 | GUI 刷新、事件订阅 | 审批流、过滤链 | 对话框联动、聊天室 |

一句话判别：**通知人人有份用观察者，找一个能处理的用责任链，多方协作规则集中用中介者**。三者在真实系统里常叠用——GUI 框架用中介者收敛控件联动、用观察者广播属性变化、用责任链分发输入事件（WinUI/Qt 里三者都能找到化身）。

## 陷阱清单

1. **通知风暴**（现象：一个观察者收到通知后去改主题状态，触发新通知，滚雪球；原因：观察者回调里写主题；后果：栈溢出或事件循环放大。对策：主题设 `notifying_` 标志拒绝重入（第 22 章中介者陷阱 5 同款），或观察者只消费不回写）。
2. **悬空观察者**（现象：观察者析构了主题还在通知它；原因：忘了 detach 或主题持共享所有权拖延了死亡；后果：UB。对策：观察者析构函数里自觉 detach（或 RAII 订阅令牌析构自动退订）——裸指针名单下这是生死线）。
3. **on_update 里抛异常**（现象：一个观察者的异常炸掉整轮通知；原因：通知循环无隔离；后果：后续观察者失联。对策：约定观察者不抛、或主题逐个 try-catch 记录后继续）。
4. **通知途中改名单**（现象：遍历中 attach/detach，迭代器失效或漏通知；原因：修改发生在 notify 的 for 循环里；后果：UB 或观察顺序错乱。对策：见现代写法一节的三条对策——延迟删除是底线）。
5. **状态没变也通知**（现象：温度计每秒 notify 一次，哪怕读数没变；原因：省略变化检测；后果：观察者空转、下游放大。对策：`setChanged/clearChanged` 语义（刘伟 23 章扩展节讲的 Java Observable 正是这个）——只在状态真变时置位再通知）。

## 三书对应

- 之禅：第 22 章"观察者模式"（22.1 韩非子身边的卧底——李斯安插间谍监控韩非子饮食娱乐，间谍即观察者、韩非子即主题；22.2 定义、22.3 应用、22.4 扩展——与 Java Observable 的关系）。
- 刘伟：第 23 章"观察者模式"（23.1 动机与定义、23.2 结构与分析、23.3 实例——猫、狗与老鼠（23.3.1）/自定义登录控件（23.3.2）、23.4 效果与应用、23.5 扩展——Java Observable 类与 MVC 模式）。
- GoF：第 5 章 5.7 节 Observer——"实现"节专列了本章全部难点：谁触发更新（setChanged 语义）、对已删除目标的悬挂引用（陷阱 2）、在发出通知前确保目标状态自身一致、避免特定于观察者的更新协议（推 vs 拉——本例 `on_update(double)` 是推模型，拉模型是观察者回查主题）。

*可选延伸：可运行示例见 examples/24_observer/。*
