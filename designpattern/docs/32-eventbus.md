# 32 · 事件总线：观察者的解耦终点

第 24 章讲观察者时，主题（Subject）还得知道观察者的抽象类型、持有观察者列表。事件总线把最后一点知识也抹掉：**发布者与订阅者互相只知道一个字符串**——话题名。订阅凭字符串、发布凭字符串、退订凭 id，双方从头到尾不需要共享任何类型。这是观察者谱系的解耦终点，也是最常被滥用的一个终点：耦合从类型层退到字符串层，编译器从此管不了你。本章把总线写完整（订阅/发布/退订全链路），再把"字符串耦合"的代价讲透。

## 意图与动机

一个进程内常有的场景：多个模块关心彼此的事，但不想互相 include——订单模块发货了，物流、通知、统计都想收到消息，订单模块不该为了通知他们 include 三家头文件。第 24 章的观察者能解一部分：Subject 持 `vector<Observer*>`，但 Subject 至少要知道 Observer 抽象基类，观察者要知道"attach 到哪个 Subject"。事件总线再抽走一层：所有模块只认识一个 EventBus 和若干话题字符串，**订阅者登记"我对 topicA 感兴趣"，发布者喊"topicA 发生了什么"**——模块间唯一的共同知识是话题命名约定。代价随即埋下：拼错字符串、发布没人听、订阅没人发，编译器全部沉默。

## 经典写法：id 化订阅 + 话题分桶

示例 `eventbus.hpp`。事件与总线：

```cpp
struct Evt {
    std::string topic;
    std::string payload;
};

class EventBus {
public:
    using Handler = std::function<void(const Evt&)>;

    // 订阅：返回全局单调递增的 id，退订凭它。同一 topic 可挂任意多个 handler。
    std::size_t subscribe(std::string topic, Handler h) {
        const std::size_t id = next_id_++;
        topics_[std::move(topic)].push_back({id, std::move(h)});
        return id;
    }

    // 退订：找到持有该 id 的桶并摘除。返回是否真的退掉了（重复退订 = false）。
    bool unsubscribe(std::size_t id) {
        for (auto& [topic, list] : topics_) {
            for (auto it = list.begin(); it != list.end(); ++it) {
                if (it->first == id) {
                    list.erase(it);
                    return true;
                }
            }
        }
        return false;
    }

    // 发布：按 topic 定位桶，逐个通知。无人订阅的话题静默通过。
    void publish(const Evt& e) {
        auto it = topics_.find(e.topic);
        if (it == topics_.end()) return;
        for (const auto& [id, h] : it->second) h(e);   // 桶内顺序 = 订阅顺序
    }

private:
    std::unordered_map<std::string, std::vector<std::pair<std::size_t, Handler>>> topics_;
    std::size_t next_id_ = 1;
};
```

三个设计决定各值一段话。**id 化退订**：lambda 没有身份（std::function 不可比较），"退订某个观察者"必须另发身份凭证——全局单调递增的 id 是最朴素可靠的方案；对比第 24 章经典观察者退订凭对象指针，这里凭 token。**分桶结构**：`unordered_map<string, vector<pair<id, Handler>>>`——按话题 O(1) 定位桶，桶内保持订阅顺序（通知顺序可复现，测试因此可断言）。**静默发布**：没人订阅的话题不报错——这既是自由（发布者不必探测有没有人听）也是风险（拼错话题名消息人间蒸发），见陷阱清单第 3 条。

运行侧（`main.cpp`）全链路断言：

```cpp
const auto id1 = bus.subscribe("topicA", [&](const Evt& e) { ++a1; last_payload = e.payload; });
const auto id2 = bus.subscribe("topicA", [&](const Evt&) { ++a2; });
const auto id3 = bus.subscribe("topicB", [&](const Evt&) { ++b1; });
assert(id1 < id2 && id2 < id3);                    // id 全局单调递增

bus.publish({"topicA", "first"});
bus.publish({"topicA", "second"});
assert(a1 == 2 && a2 == 2 && b1 == 0);             // topicA 两路各收 2，topicB 收 0
assert(last_payload == "second");                  // handler 收到完整事件

assert(bus.unsubscribe(id2));                      // 退订 topicA 的第二路
assert(!bus.unsubscribe(id2));                     // 重复退订：false
bus.publish({"topicA", "third"});
assert(a1 == 3 && a2 == 2);                        // a2 从此不再增长

bus.publish({"no-such-topic", "x"});               // 无人话题：静默，不崩
```

运行输出：

```text
事件总线: 3 订阅 / 5 发布 / 1 退订，计数与 id 单调性全部符合预期
自检通过
```

## 模式结构（对照第 24 章观察者）

```text
   第 24 章 观察者：  Subject ──持有──> vector<Observer*>   主题知道观察者的抽象类型
   第 32 章 事件总线： 发布者 ──publish(topic)──> EventBus <──subscribe(topic)── 订阅者
                      双方只共享：EventBus 引用 + 话题字符串

   一次发布的路径：publish(e) ──find(e.topic)──> 桶 vector<pair<id,Handler>>
                                              └──逐个 h(e)──> 各 lambda

   解耦的代价：类型检查范围缩水
     24 章：attach/detach 参数是 Observer*，类型错 = 编译错
     32 章：topic 是字符串，拼错 = 运行期静默丢消息
```

## 现代线讨论：同一个骨架的三个升级方向

本章示例是最小教学版，工业级总线沿三个方向升级，方向本身就是复习前 30 章的三课：

- **线程安全（复习第 14 章单例/互斥）**：真实系统多线程 publish/subscribe，topics_ 与桶要上锁；更微妙的是"publish 进行中 unsubscribe"——**快照法**（先拷贝 handler 列表再遍历）保证退订者不会被正在进行的广播叫到，与第 31 章陷阱清单第 1 条同一手法。
- **类型化载荷（复习第 30 章擦除）**：本例 payload 是字符串，真实总线常用 `std::any` 装载荷、发布时 `std::type_index` 参与分桶——按"话题 + 载荷类型"双键订阅，handler 里 any_cast 回具体类型。擦除件直接复用，代价是 any_cast 失败处理要在合同里写明。
- **编译期话题（复习第 29 章）**：话题名用 `fixed_string` / 枚举常量，模板参数分桶——字符串拼错的运行期事故直接变成编译错。适合话题集合封闭的系统，开放生态（插件可自定义话题）仍需字符串。

三个方向都成立，选型取决于哪个维度会变：线程模型、载荷异构性、话题开放性——与第 28 章"变化方向"总图的方法论完全一致。

## RAII 订阅句柄：把生命周期交给作用域

陷阱清单第 2 条的对策值得展开成代码，因为它集中体现了 C++ 的资源管理哲学。裸调 subscribe/unsubscribe 的客户代码把"退订"变成手动义务，忘了就是悬垂。RAII 句柄把义务折叠进作用域：

```cpp
// 订阅句柄：构造即订阅、析构即退订——生命周期 = 作用域。
class Subscription {
public:
    Subscription(EventBus& bus, std::string topic, EventBus::Handler h)
        : bus_(bus), id_(bus.subscribe(std::move(topic), std::move(h))) {}
    ~Subscription() { bus_.unsubscribe(id_); }
    Subscription(const Subscription&) = delete;             // id 唯一，拷贝即双重退订
    Subscription& operator=(const Subscription&) = delete;
private:
    EventBus& bus_;
    std::size_t id_;
};

// 用法：订阅者的成员——订阅者析构时句柄随之析构，自动退订
class Metrics {
    Subscription sub_;
public:
    explicit Metrics(EventBus& bus)
        : sub_(bus, "topicA", [this](const Evt& e) { this->on_order(e); }) {}
    void on_order(const Evt&);
};
```

两个细节是骨架级经验。**句柄禁拷贝**：id 全局唯一，拷贝句柄意味着两个对象退同一个 id（一次成功一次 false），正确做法是禁拷贝或实现转移语义；**捕获 this 的时机**：lambda 按引用捕获成员时，句柄必须活不过 this——把句柄做成订阅者的成员（如上）是最稳的挂法，构造函数里订阅、析构序列里最先析构的成员之一自动退订。有了句柄，第 24 章观察者"attach/detach 手动配对"的最后一处手动义务也消失了——解耦模式 + RAII，才是 C++ 里这对模式的完整形态。

## 发布语义的三个决定

`publish` 一行代码背后藏着三个必须显式决定（或显式接受默认）的语义，工业级总线的设计文档写的就是这三条。**同步还是异步**：本例同步——publish 返回时所有 handler 已执行完，发布者承担 handler 的耗时（一个慢 handler 拖慢发布线程）；异步总线把事件丢队列、后台线程分发，发布者立即返回，代价是顺序不可控、生命周期问题加倍（快照里存的是谁的引用？）。**顺序**：同步天然保证桶内按订阅顺序、逐个完成（本例合同里"桶内顺序 = 订阅顺序"写进了注释与测试）；一旦并行分发（每 handler 一个线程），顺序合同消失，依赖顺序的 handler 组必须合成一个。**异常传播**：handler 抛异常时怎么办——本例没写 catch，异常穿透 publish 传播给发布者（同步语义的自然推论）；工业总线通常在分发处 catch 住并隔离（一个 handler 崩不连累其他订阅者），但"吞异常"要在文档里写明，否则调试时找不到崩溃源。三个决定没有标准答案，标准的是**必须有人决定**：教学版用语言默认（同步、保序、异常穿透），每个默认值都写得出来理由——这比"用了什么框架"更能说明一个系统的事件语义。

## 计数器测试法：为什么不用 mock

本章 main 的全部断言都建立在三个 int 计数器和一个 string 上，没有引任何测试框架、没有 mock——这个选择值得说明。事件总线的被测行为是"**谁收到了几次、收到了什么**"，计数器恰好一一对应：`++a1` 就是"订阅者 1 收到一条"，`last_payload` 就是"内容完整传导"。mock 框架在 C++ 里要引入 gmock 依赖、写 EXPECT_CALL 语法，而它能验证的（调用次数、参数匹配）计数器同样验证得了——**行为面窄的系统，朴素计数器是最便宜的测试预言**。更重要的是计数器对**并发与顺序**问题的天然敏感：退订后 a2 不再增长、id 单调递增，这些时间线性质用计数器的先后断言表达得直接而准确。惯例化建议：给每个订阅 handler 配一个"计数 + 最后载荷"的小结构（测试代码里三行定义），任何发布-订阅系统的冒烟测试都从它起步——与第 31 章 CountSink 同一思想，与第 25 章售货机、第 32 章 id 比大小的"不打印值、只断言关系"纪律同源。

## 从单机到跨进程：总线的边界

本章总线是进程内的，值得把边界也画出来，免得误用。进程内的 EventBus 直接持有 handler 对象——**发布即函数调用**，没有序列化、没有网络栈、没有超时；一旦话题要跨进程或跨机器，图景全变：payload 要能序列化（本例的 `std::function` handler 无法过网线，跨进程总线的订阅侧从"回调"变成"本地收发器"）、消息要有版本与兜底（新版本发布者 + 旧版本订阅者）、失败要可见（网络丢包不是"静默通过"能吞掉的）。所以扩展到分布式时的正路是：**进程内总线保留（模块间解耦照旧），网关订阅本地话题、负责序列化与转发**——本地合同与远程合同分层，各自演化。判断需求属于哪边的一个粗筛：如果"发布一条消息"的延迟要求低于微秒级、或 payload 里装着不可序列化的对象（句柄、闭包），那是进程内场景；如果"多语言订阅者""持久化重放""跨机房"出现在需求里，那是消息队列的地界——自己拿字符串总线往上摞，是常见的过度自研。

本例钉死的总线合同，逐条列出：

- `subscribe` 返回的 id 全局单调递增，跨话题单调（`id1 < id2 < id3` 跨 A/B 两桶）；
- 同话题多订阅者各收每条；异话题零串扰（`b1 == 0` 贯穿 A 的三次发布）；
- handler 收到完整 Evt（topic + payload 都可读，`last_payload` 断言）；
- `unsubscribe` 幂等语义：首次 true、重复 false；
- 退订后立即生效（下一条 publish 就看不见退订者）；
- 无人话题静默、不抛、不崩。

六条合同任何一条被实现变更打破（换成异步分发、改成分级退订），本例 main 都会有断言变红——合同测试的意义就在于此。

## 陷阱清单

1. **handler 里再订阅/退订**（现象：某 handler 的回调里调用 subscribe/unsubscribe，遍历正持有的 vector 迭代器失效；原因：广播与名单修改并发；后果：UB 或崩溃。对策：回调里只发消息；名单变更攒到广播后（或递延队列），快照遍历是最小防线）。
2. **生命周期悬垂**（现象：订阅者析构了没退订，下次 publish 调进悬垂 lambda，按引用捕获的成员全炸；原因：总线不知道订阅者死了；后果：UB，且崩溃点离出错点极远。对策：RAII 订阅句柄（构造 subscribe、析构 unsubscribe——本例 unsubscribe(id) 的 bool 返回值就是为它准备的）；教学版至少在析构里显式退订）。
3. **话题字符串无约束**（现象：发布者拼 "TopicA"、订阅者注册 "topicA"，消息静默蒸发，无人报错；原因：字符串耦合在编译期不可见；后果：最难查的一类"功能没生效"。对策：话题名常量集中定义（`inline constexpr std::string_view kTopicA = "topicA";`）、启动时自检（发布统计：计数为 0 的话题告警）、测试用本例的收包计数器钉死收发双方）。
4. **payload 用万能字符串**（现象：所有消息 payload 都是"字段=值;字段=值"的拼串，订阅方解析代码散落各处；原因：贪图不定义消息类型；后果：协议演化无保护，解析脆弱。对策：载荷定类型（struct + variant/any），或至少给每话题一个编码函数集中管理——解析逻辑一处定义）。
5. **发布顺序假设**（现象：代码假设"topicA 的两个 handler 先后执行且第二个能看到第一个的副作用"，换个容器顺序就翻车；原因：桶内顺序是实现细节，不是合同；后果：隐式顺序依赖。对策：handler 之间不共享可变状态；确需顺序就合成一个 handler，或明确文档化"按订阅顺序同步通知"并写进测试（本例 last_payload 断言即是））。

## 测试法

- **收包计数矩阵**：三订阅两话题，逐 publish 断言各计数器（`a1==2 && a2==2 && b1==0`）——"同话题双订阅各收、异话题不串"两条合同一次钉死。
- **退订幂等性**：`unsubscribe(id2)` 第一次 true、第二次 false——退订合同的完整行为面。
- **id 单调性**：只比大小不打印值（`id1 < id2 && id2 < id3`）——id 是内部凭证，测试合同是单调而非具体数值（与全书"确定性输出"纪律一致）。
- **无人话题静默**：发布不存在的话题不崩、不抛——负面用例同样是合同。
- **payload 传导**：`last_payload == "second"` 断言 handler 收到的是完整事件对象而非通知哨兵。

## 三书对应

- 之禅：第 24 章"观察者模式"（24.x 观察者模式的扩展——"发布-订阅"形态的讨论：中介层把订阅关系从对象间转移到消息间）；另见第 32 章中介者模式关于"用中介对象消灭网状引用"的总纲——EventBus 就是最轻量的中介者。
- 刘伟：第 22 章"中介者模式"（22.x 用中介对象封装一系列对象的交互，使各对象不需要显式相互引用）与第 8 章"观察者模式"8.2 节"观察者与发布-订阅的关系"——事件总线是两者的交点。
- GoF：第 5 章 5.7 Observer"实现"小节对"订阅/退订管理"（第 4 条：维护引用 vs 代理对象）与"谁触发更新"的讨论；5.5 Mediator 对"中介者协调通信"的定位——本章把 5.7 的订阅管理做成了 id 化完整合同。

*可选延伸：可运行示例见 examples/32_eventbus/。*
