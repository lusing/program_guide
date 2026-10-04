# 31 · 日志系统：四模式的混编现场

前 30 章把模式一个个孤立地讲，本章开始把它们放进同一间屋子。一个可扩展的日志系统看似平常，细拆下去至少四个模式同时在岗：**级别过滤是策略**（"多严重的日志放行"是可替换的判断规则）、**多 sink 广播是观察者**（Logger 不关心谁在听，sink 自己挂上来）、**前缀包装是装饰器**（接口不变、行为叠加）、**make_sink 是工厂**（客户只见 Sink 抽象不见具体类）。单看每个都简单，混编的价值在于看清它们怎么在 `log()` 一行里协作、现代 C++ 把其中哪些降成了语言设施。

## 意图与动机

日志系统的需求清单：输出要能**分级**（debug 不进生产日志）、落点要能**多路**（控制台一份、文件一份、测试内存里一份）、格式要能**叠加**（某一路想加模块前缀）、新增落点要**不改 Logger**。朴素写法把这四件事全糊在 Logger 里：`log()` 函数里 if-else 判级别、写死两路输出、字符串拼接格式化、加落点改函数——改任何一个需求都要动核心类。本章把它拆成四件可独立替换的事，并给出经典（虚函数）与现代（模板策略 + std::function）两条实现线。

## 经典写法：Sink 抽象 + Logger 编排

示例 `logger.hpp`。级别与 Sink 接口：

```cpp
enum class Level { debug = 0, info = 1, warn = 2, error = 3 };

// Sink 接口：决定"日志写到哪里"。Logger 只认这个抽象，具体落点随意增删。
struct Sink {
    virtual ~Sink() = default;
    virtual void write(Level lvl, const std::string& msg) = 0;
};

// 计数 sink：按级别攒 "L<级别号>:<msg>"，供测试断言（确定性输出，不打时间戳）。
class CountSink final : public Sink {
public:
    void write(Level lvl, const std::string& msg) override {
        const int i = static_cast<int>(lvl);
        ++count_[i];
        last_[i] = "L" + std::to_string(i) + ":" + msg;
    }
    int count(Level lvl) const { return count_[static_cast<int>(lvl)]; }
    const std::string& last(Level lvl) const { return last_[static_cast<int>(lvl)]; }
private:
    int count_[4] = {};
    std::string last_[4];
};
```

CountSink 是为本章测试量身定做的落点：它把"收到了什么"攒成确定性格式的字符串，断言直接比字符串——真实项目里对应文件 sink 或网络 sink，测试时换它即可（与第 30 章"测试用落点"的思想一致）。Logger 本体把过滤和广播写在同一行：

```cpp
class Logger {
public:
    void set_level(Level l) { level_ = l; }
    void add_sink(std::shared_ptr<Sink> s) { sinks_.push_back(std::move(s)); }

    // 策略（级别过滤）+ 观察者（广播）在同一行里协作：先过滤，后扇出。
    void log(Level lvl, const std::string& msg) {
        if (lvl < level_) return;
        for (const auto& s : sinks_) s->write(lvl, msg);
    }
private:
    Level level_ = Level::debug;
    std::vector<std::shared_ptr<Sink>> sinks_;
};
```

（代码以 `examples/31_logging/logger.hpp` 为准。）这一行是全章的枢纽：**先策略后观察者**——过滤在扇出之前，被拦下的消息连 sink 的影子都见不到。装饰器与工厂：

```cpp
// 装饰器：接口不变，行为叠加——前缀先拼，再交给内层 sink。
class PrefixSink final : public Sink {
public:
    PrefixSink(std::shared_ptr<Sink> inner, std::string prefix)
        : inner_(std::move(inner)), prefix_(std::move(prefix)) {}
    void write(Level lvl, const std::string& msg) override {
        inner_->write(lvl, prefix_ + msg);
    }
private:
    std::shared_ptr<Sink> inner_;
    std::string prefix_;
};

// 工厂：客户只见 Sink，不见具体类。
enum class SinkKind { count, null };
inline std::shared_ptr<Sink> make_sink(SinkKind kind) {
    switch (kind) {
        case SinkKind::count: return std::make_shared<CountSink>();
        case SinkKind::null:  return std::make_shared<NullSink>();
    }
    return nullptr;
}
inline std::shared_ptr<Sink> make_prefix_sink(std::shared_ptr<Sink> inner, std::string prefix) {
    return std::make_shared<PrefixSink>(std::move(inner), std::move(prefix));
}
```

PrefixSink 拿着另一个 Sink——装饰器的标志（与第 17 章结构型装饰同法，这里是行为型的落点变体）；`shared_ptr` 而非 `unique_ptr` 的理由：同一份内层 sink 可能同时被 Logger 和测试代码引用（断言要读它的计数）。运行侧（`main.cpp`）四段断言分别钉住四个需求：

```cpp
log.log(Level::debug, "dropped");                       // 阈值 info：debug 连影子都无
assert(a->count(Level::debug) == 0 && b->count(Level::debug) == 0);
log.log(Level::error, "boom");
assert(a->count(Level::error) == 1 && b->count(Level::error) == 1);   // 双 sink 双写
assert(a->last(Level::error) == "L3:boom");

log2.log(Level::error, "fatal");
assert(inner->last(Level::error) == "L3:[app] fatal");  // 装饰先加前缀，内层再格式化
```

注意前缀断言的细节：`L3:[app] fatal` 而不是 `[app] L3:fatal`——**装饰在格式化之外**，PrefixSink 拼好前缀再交给内层格式化，各层只做自己的事。运行输出：

```text
经典线: 阈值过滤 + 双 sink 广播（debug 被丢，其余各收一条）
装饰线: PrefixSink 前缀叠加，格式化仍归内层
工厂线: make_sink 返回 Sink 抽象，客户零具体类知识
现代线: 模板策略 + std::function sink，无 Sink 类同样工作
自检通过
```

## 现代写法：模板策略 + std::function sink

过滤规则换成模板参数、sink 换成 std::function——Sink 类整个消失：

```cpp
// 过滤策略：可替换的谓词对象——换阈值、换规则都只是换这个类型。
struct LevelFilter {
    explicit LevelFilter(Level l) : level(l) {}
    bool operator()(Level msg) const { return msg >= level; }
    Level level;
};

template <typename Filter = LevelFilter>
class LoggerT {
public:
    explicit LoggerT(Filter f = Filter{Level::debug}) : filter_(std::move(f)) {}
    void add_sink(std::function<void(Level, const std::string&)> fn) {
        sinks_.push_back(std::move(fn));
    }
    void log(Level lvl, const std::string& msg) {
        if (!filter_(lvl)) return;
        for (const auto& fn : sinks_) fn(lvl, msg);
    }
private:
    Filter filter_;
    std::vector<std::function<void(Level, const std::string&)>> sinks_;
};
using LoggerF = LoggerT<>;   // 默认策略 = 级别过滤
```

三个降级值得点破。**策略**从虚函数降成模板参数（Filter 编译期注入，过滤调用可内联——第 29 章 concepts 版的思路）；**观察者**从 Sink 类降成 std::function（第 30 章的擦除件直接复用，lambda 挂上来就行）；**装饰与工厂**没有对应物——std::function 的"装饰"是 lambda 里手工包装一层、工厂退化为 make_shared。现代线不是全面更优：运行期换策略（set_level 那样的动态调节）时，虚函数版改成员即可，模板版要换整个 LoggerT 实例类型。而且策略的可替换性不止阈值一种形态：把 LevelFilter 换成"采样过滤"（每 N 条放 1 条）、"包络过滤"（同一来源的高频消息折叠成计数）都只是另写一个谓词类型——**策略模板参数化把"过滤规则"这个变化维度彻底开放**，代价是每个策略类型都实例化一份 LoggerT。运行期需要混用多个策略实例时，退一步把 Filter 也擦掉（`std::function<bool(Level)>`）——编译期到运行期再擦一次，与第 30 章的骨架完全同构，本章的经典线正是这条路的虚函数版本。取舍表：

| | 经典线（Sink 虚函数） | 现代线（模板策略 + function） |
|---|---|---|
| 过滤策略 | 运行期可换（set_level） | 编译期固定（换类型 = 换 LoggerT 实例） |
| 新增落点 | 新写 Sink 子类 | 直接挂 lambda/function |
| 装饰/工厂 | PrefixSink / make_sink 独立成件 | lambda 手工包装，工厂退化为 make_shared |
| 性能 | 两跳虚调用 | 过滤内联，sink 一跳（function 擦除） |
| 适用 | 策略运行期切换、落点由配置驱动 | 策略编译期已知、落点在代码里拼装 |

## 混编的读法

本章真正的教学内容不是四个模式本身，而是**它们在同一行 log() 里的位置关系**：策略决定"这条消息走不走"，观察者决定"走到哪些落点"，装饰决定"落点上再叠什么"，工厂决定"落点从哪来"。四者层次分明、互不知名——Logger 只认 Sink，PrefixSink 只认内层 Sink，LevelFilter 只认 Level。读混编系统的方法论：**沿着一次调用的路径走，每经过一个抽象记下它回答的问题**——答案互不重叠，就是干净的混编；答案重叠（比如 Logger 里也写格式化），就是职责粘连。

## 真实落点长什么样：从 CountSink 到生产 sink

CountSink 是教学替身，把它换成生产落点能看清 Sink 合同的真实分量。**文件 sink**：持有 ofstream，write 里一行落盘——要加缓冲（攒满 flush）就在类里加一个 string 缓冲，Sink 接口纹丝不动；**控制台 sink**：write 里 std::println，注意与 std::print 的格式化各管各的——Sink 合同给的是"已格式化的 msg"，落点不再碰内容；**网络 sink**：write 把消息丢进无锁队列、后台线程负责发送——同步接口、异步实现，调用方零感知（这是 Sink 抽象最大的红利：**换落点不改调用侧**）；**测试 sink**：就是 CountSink，攒字符串供断言。四类落点共用一个接口，正说明 Sink 合同切得对：入参只有 (级别， 消息)、无返回值、语义是"投递"——**合同越窄，能装进来的实现越多**。反过来，若把"写文件"写进 Logger 主体，四类落点就变成 Logger 里的四个 if 分支，每加一路改一次核心类——单一职责在日志系统上的具象，就是"编排与落点分离"这一刀。

## 级别体系的两派：阈值 vs 分类

Level 枚举的用法在本章是**阈值派**：`lvl >= level_` 一刀切，info 之上全放行。另一派是**分类派**：不比较、按类别路由——debug 进文件、warn 以上进控制台、error 触发告警，每级别各配各的 sink 集合。阈值派实现简单（一个比较），适合"严重度单调"的语义；分类派灵活（每个级别独立的 sink 名单），但配置面从 O(1) 变成 O(级别数)。两者在 Sink 架构下都只是策略的不同形态：阈值派过滤在 Logger（本章写法），分类派把路由下沉到 sink 侧（每个 sink 自己声明 `bool accepts(Level) const`，Logger 广播给所有 sink、各 sink 自筛）。判据看运维习惯：**环境变量一个值调全站级别**选阈值派，**按落点分别配**选分类派——策略模式的本质福利就是这两派可以共存，换派不换骨架。本章选阈值派是因为断言面最小（一条比较一个计数），分类派版本留作练习：只需给 Sink 加一个默认返回 true 的 accepts、Logger::log 的过滤行换成 sinks_ 自筛，示例的计数矩阵断言原样成立。

## add_sink 的时机：订阅名单是配置也是代码

sink 名单的组装时机是个容易敷衍过去的决定，敷衍的代价是扩展性假象。编译期写死（Logger 构造函数里 new 好两个 sink）最省事，但"测试换 CountSink、生产换文件 sink"就得改代码重编；运行期组装（add_sink 由 main 或配置层调用，本章写法）把名单变成数据——同一份 Logger 二进制，测试环境挂 CountSink、生产挂文件 + 网络 sink。**组装权在哪一层，是日志系统真正的扩展点**：Sink 接口解决"落点可插拔"，组装层解决"何时插哪些"——两层配合，第 31 章经典线的 `add_sink(make_prefix_sink(inner, "[app] "))` 这一行才有了完整含义（工厂造件、装饰叠行为、组装层定名单，三个模式在一行里各就各位）。

## 陷阱清单

1. **广播时修改订阅名单**（现象：某 sink 的 write 里调用 remove_sink，遍历中 vector 失效崩溃；原因：广播循环正持有迭代器；后果：UB。对策：write 里只做通知；名单变更排队到广播结束后（复制一份 sinks_ 再遍历是最简单的快照法））。
2. **级别比较方向写反**（现象：`lvl > level_` 当成过滤条件，error 反而被丢；原因：语义上"放行 >= 阈值"，写成"丢弃 >= 阈值"；后果：高严重度日志静默丢失。对策：测试钉死——本例 main 的 debug 被滤 + error 通过两条断言就是护栏）。
3. **装饰层抢了内层的职责**（现象：PrefixSink 里连时间戳、级别号一起拼了，内层 CountSink 的 last 变成双重格式；原因：装饰越界格式化；后果：格式规则散落两层。对策：装饰只做一件事（本例只拼前缀），格式化归最内层）。
4. **std::function sink 捕获悬垂**（现象：现代线 lambda 按引用捕获局部变量，Logger 活得比变量久，之后 log 时崩溃；原因：function 不管理捕获的生命周期；后果：悬垂引用 UB。对策：捕获按值（小状态）或确保 Logger 不出作用域——与第 24 章观察者的生命周期陷阱同源）。
5. **日志调用本身带副作用**（现象：`log(debug, fmt("value={}", expensive()))`——被过滤的 debug 也把 expensive() 算了；原因：实参在调用点求值，过滤在函数体内；后果：热路径性能黑洞。对策：级别判断前置（`if (log.enabled(Level::debug)) ...`）或惰性格式化——过滤是运行期策略时这个坑尤其隐蔽）。

## 测试法

- **收包计数矩阵**：CountSink 按级别计数，断言"debug 0 条、info/warn/error 各 1 条"——三级过滤 + 阈值方向一次钉死。
- **广播对拍**：两个 sink 各持计数，同条消息后计数相等——扇出完整性。
- **装饰透明性**：挂前缀 sink 后内层格式不变（只多前缀）——装饰器"接口不变行为叠加"的承诺。
- **现代线行为一致**：LoggerF 与经典 Logger 在同一消息序列上的收包结论一致（本例 passed==1、captured=="passes"）——两线互为预言，与 25/28 章双形态对拍同一手法。
- **工厂产品的行为面**：make_sink 返回的 null sink 挂上去后发布不崩、无输出——工厂返回的抽象指针在客户侧"能用"这一最低合同也要有断言。
- **过滤与装饰的次序无关性**：前缀 sink 挂在被过滤的 Logger 上，被滤消息的计数为 0——过滤在广播前，装饰只作用于真发出的消息，两层的先后合同有断言兜底。

## 三书对应

- 之禅：混编篇总纲"设计模式是原则的具象化，原则是模式的抽象"——本章是"单一职责"（Logger 编排、Sink 落点、Filter 规则三层分离）与"开闭原则"（加落点不加类）的具象现场；另见第 18 章策略模式 18.4"策略模式的扩展——策略枚举"与本章 LevelFilter 枚举化阈值的同构。
- 刘伟：第 8 章"观察者模式"8.4 节"观察者与 MV*"；第 5 章工厂模式（5.x 工厂与配置文件结合的"工厂 + 配置"扩展，正是 make_sink(SinkKind) 的雏形）；第 17 章装饰器模式 17.3"装饰器的透明性与半透明"——PrefixSink 对外仍是 Sink（透明装饰）。
- GoF：第 5 章 5.7 Observer"实现"小节第 8 条"观察者模式与责任链/中介者的配合"；5.2 Factory Method"实现"小节对"参数化工厂"的讨论；1.6 节"设计怎样支持变化"——本章四模式各答一个"什么会变"。

*可选延伸：可运行示例见 examples/31_logging/。*
