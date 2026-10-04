# 35 · 自注册插件框架：main 之外的构造函数

第 30 章类型擦除解决了"接口干净地装下任意类型"，本章解决它留下的最后一个问题：**新插件谁来装**。擦除版的 main 还得写 `bag.emplace_back(SqA{})`——每加一种形状都要改 main。自注册框架把这一步也消掉：每个插件在自己的翻译单元里放一个静态哨兵对象，**动态初始化阶段（main 之前）它自己把自己注册进注册表**；main 从头到尾只认名字，不认任何具体类型。这是"开放封闭原则"在链接层面的兑现：加插件 = 加一个 cpp 文件，其他一切不动。

## 意图与动机

编解码器集合要支持运行期扩展：hex、base64、reverse 今天各有实现，明天第三方要加 jwt、zlib。三种老做法各有代价：**main 里手写注册**（每加插件改 main，违背开闭）；**配置文件驱动**（字符串 → 工厂 if-else，还是要改核心）；**共享库 dlopen**（真正的运行期插件，但平台 API 各异，超出本章范围）。自注册是静态链接里的最优解：插件 = 一个 cpp 文件（类型 + 静态哨兵），编译进程序后自动在册。框架要回答两个问题：注册表怎么躲开静态初始化顺序事故；哨兵怎么在"无参静态对象"的约束下完成注册——后者刚在本章示例里真实踩过一次（见陷阱 2）。

## 经典写法：Meyers 单例 + 模板哨兵

示例 `plugin.hpp`。插件合同与注册表：

```cpp
// 插件合同：报名字 + 干活。
struct Codec {
    virtual ~Codec() = default;
    virtual std::string name() const = 0;
    virtual std::string encode(std::string_view data) const = 0;
};

// 注册表：Meyers 单例——各编译单元的静态注册量构造时才首次调用 instance()，
// 首个调用者触发构造，"谁先谁后"的跨编译单元顺序问题被函数内静态化解。
class Registry {
public:
    static Registry& instance() { static Registry r; return r; }

    bool add(std::unique_ptr<Codec> c) {
        if (c == nullptr || find(c->name()) != nullptr) return false;   // 重名拒绝
        plugins_.push_back(std::move(c));
        return true;
    }

    const Codec* find(std::string_view name) const {
        for (const auto& p : plugins_)
            if (p->name() == name) return p.get();
        return nullptr;
    }

    std::size_t size() const { return plugins_.size(); }
private:
    Registry() = default;
    std::vector<std::unique_ptr<Codec>> plugins_;
};
```

Meyers 单例是自注册框架的**地基而非懒加载优化**：插件哨兵的构造跨编译单元乱序执行，任何"命名空间级静态 Registry"都会被 C++ 的静态初始化顺序事故击穿（某个哨兵注册时 Registry 可能还没构造）；函数内静态把构造推迟到首次使用——**首个哨兵注册的那一刻 Registry 才出生**，顺序事故从根上消失（C++11 起函数内静态初始化还保证线程安全）。注册哨兵：

```cpp
// 注册哨兵：模板类——构造时把 C 实例化并注册。每个"插件"翻译单元里放一个
// 静态实例，动态初始化在 main 之前完成。模板类而非模板构造函数：
// 静态对象 `RegisterOne reg_hex;` 必须能默认构造，构造函数模板做不到。
template <class C>
struct RegisterOne {
    RegisterOne() { Registry::instance().add(std::make_unique<C>()); }
};
```

注释里那句是本章实测踩过的坑（陷阱 2 细说）：哨兵最初写成"构造函数模板"，`const dp::RegisterOne reg_hex;` 直接编不过——静态对象要的是**默认构造**，模板构造函数没有实参可推。插件本体（`hex.cpp`，其余两个同构）：

```cpp
namespace {
struct HexCodec final : dp::Codec {
    std::string name() const override { return "hex"; }
    std::string encode(std::string_view data) const override { /* 逐字节转两位 hex */ }
};

const dp::RegisterOne<HexCodec> reg_hex;   // main 之前完成注册
}  // namespace
```

插件 = 一个类型 + 一个静态哨兵，**类型藏在匿名命名空间里**（链接器外部不可见，注册表里是唯一出口）。运行侧（`main.cpp`）：

```cpp
auto* hex = Registry::instance().find("hex");
assert(hex != nullptr);                        // 走到 main 时已在册
assert(Registry::instance().size() == 3);

assert(encode_with("hex", "hi") == "6869");
assert(encode_with("b64", "hi") == "aGk=");
assert(encode_with("reverse", "hi") == "ih");
assert(encode_with("nope", "hi") == "err");    // 未知名：门面兜底

struct Dup final : Codec { /* 同名 "hex" */ };
const bool added = Registry::instance().add(std::make_unique<Dup>());
assert(!added);                                // 重名拒绝
assert(encode_with("hex", "hi") == "6869");    // 原插件未被顶替
```

main.cpp **没有 include 任何插件实现**——三个插件的注册发生在链接进来的另外三个 TU 的静态初始化里。运行输出：

```text
注册线: main 之前 3 个插件已在册（hex/b64/reverse）
编码线: hex=6869 / b64=aGk= / reverse=ih 三路各自正确
容错线: 未知名返回 err，客户零空指针
防重线: 重名注册被拒，原插件保持原位
自检通过
```

## 模式结构（注册时序）

```text
   [动态初始化阶段，main 之前]
   hex.cpp:  reg_hex 构造 -> Registry::instance() 首调 -> Registry 出生 -> add(HexCodec)
   b64.cpp:  reg_b64 构造 -> instance() 已在 -> add(B64Codec)     （顺序任意，结果一致）
   reverse.cpp: 同上

   [main]
   find("hex") -> Codec* -> encode(...)      main 零插件类型知识
   encode_with("nope",...) -> "err"          门面兜住查无此人

   加第四个插件 = 新增 plugin_cpp（类型 + 哨兵）+ 链接——main 与框架零改动
```

## 现代讨论：注册时的类型与这个模式的边界

哨兵 `RegisterOne<C>` 是第 30 章擦除的近亲：注册表里存的 `unique_ptr<Codec>` 是擦除后的接口，哨兵是"在编译期把具体类型 C 焊进去、运行期自动移交所有权"的转换器。和标准库工厂的差别在**触发时机**：本章靠静态对象构造（程序加载期），更现代的变体靠**首次询问时注册**（`Registry::instance().ensure<C>()`）或构建期生成注册代码（CMake 枚举插件目录、生成注册表 cpp——注册时序完全可控，代价是构建系统复杂化）。模式的适用边界也要看清：**同进程静态插件**本章正解；跨动态库（dlopen/LoadLibrary）时静态哨兵失效（共享库不链接就不初始化，还要处理卸载时析构顺序），需要显式的插件入口函数；插件需要参数化配置时，注册表合同要从 `add(unique_ptr<Codec>)` 扩成"注册工厂而非实例"（`add(string, function<unique_ptr<Codec>()>)`）——**注册合同越早定型，后面越不用动框架**。

## 链接形态三选一：哨兵的可见性是构建问题

陷阱 3（链接器丢哨兵）值得单独拉直成"三种构建形态各自怎么办"，因为它是自注册框架在生产环境最常翻车的一步。**直接列源文件**（本章 build 脚本形态）：可执行工程把插件 cpp 和 main.cpp 一起编译链接，目标文件必进产物——哨兵不可能丢，最省心，代价是加插件要动构建脚本一行。**静态库**：插件打包成 .lib，链接器只抽取"被引用的目标文件"——哨兵无人引用，整个目标文件被丢；对策要么在 main 里造一个引用（`[[maybe_unused]] static auto& keep = ...`），要么用链接器选项强制全取（MSVC /WHOLEARCHIVE、ld --whole-archive），各有体积代价。**动态库**：插件是独立 .dll/.so，进程启动时枚举目录逐个 LoadLibrary——库加载即跑静态初始化，哨兵自动注册；这是唯一支持"部署期增删插件"的形态，但跨平台 API 差异与卸载析构顺序是新的工程面。三形态的判据一句话：**插件集合编译期已知选直接列源，链接期已知选静态库+强制引用，部署期可变选动态库**——哨兵机制三形态通用，变的只是"谁保证它被加载"。

## 本章示例的断言面

main.cpp 四段断言钉住的合同：

- `size() == 3` 且 find("hex") 非空——main 之前三个插件已在册（自注册核心承诺）；
- 三路编码输出逐字符断言（6869 / aGk= / ih）——三个插件的行为面各有标准答案；
- encode_with("nope") == "err"——门面兜底合同；
- add(Dup) 返回 false、原插件输出不变——重名拒斥与注册表一致性。

四个断言全部不依赖注册顺序（哪个 TU 先注册结果一致）——这正是 Meyers 单例 + 顺序无关注册合同带来的可测性。

## 注册表的并发视角

本章示例是单线程的，把并发问题点到为止：**注册窗口**只在动态初始化阶段（单线程，C++ 保证），main 之后的并发 read（find/encode_with）天然安全——只要没有并发 add；**运行期加插件**（load 插件后 add）就要上锁或改用并发友好结构（shared_mutex：find 多读共享、add 独占）。Meyers 单例的首次构造在 C++11 后线程安全，但"构造完成后 add 与 find 并发"不在其保护范围——**单例的线程安全 ≠ 单例成员的线程安全**，这条分界线在第 14 章单例章埋过，本章是它的应用现场。设计取舍上，多数编解码框架选"注册窗口封闭"（main 前全部注册，运行期只读），把并发复杂度整个消掉——合同先行，又见第 31 章"组装权在哪一层"的同一决定。

## 哨兵机制适用判据

自注册不是默认选项，以下判据先过一遍：

- **插件集合会增长吗？**——增长才值得，三五个固定编解码器直接在 main 里装配更直白；
- **插件由多方提供吗？**——同一批人维护就别绕哨兵，开放扩展的价值在"加的人不改框架"；
- **能接受加载期初始化吗？**——哨兵构造在 main 前，启动敏感的系统要掂量；
- **构建形态可控吗？**——陷阱 3 的链接丢弃问题需要工程能配合（列源文件/force-link/动态库）。

四问两否以上，注册表可以要、哨兵不必急——显式注册（main 里几行 add）是零机制成本的中间态，等插件多到 main 装不下再升级成哨兵，代价也只是把那几行搬进各 cpp。

三种注册触发方案的对比，一张表备查：

| 方案 | 触发时机 | 加插件要动谁 | 主要风险 |
|---|---|---|---|
| main 显式装配 | main 执行时 | main（+1 行 add） | 无机制，但耦合装配点 |
| 静态哨兵（本章） | 动态初始化（main 前） | 无（新 cpp 即注册） | 链接丢弃、初始化时序 |
| 构建期生成注册表 | 构建系统生成 cpp | 无（目录约定） | 构建系统复杂化 |
| 动态库 dlopen | 运行期加载 | 无（放对目录） | 跨平台 API、卸载安全 |

从上到下，灵活性递增、工程复杂度也递增——选行就是选"插件集合的变化频率该由多重的机制来承载"。

## 陷阱清单

1. **静态初始化顺序事故**（现象：哨兵注册时崩溃或注册丢失，加个无关 cpp 就复现/消失；原因：命名空间级 Registry 与跨 TU 哨兵的初始化顺序未定义；后果：注册表是空壳或半成品。对策：Registry 必须是 Meyers 单例（函数内静态）——本章示例的地基，不是可选项）。
2. **哨兵写成模板构造函数**（现象：`const RegisterOne reg_hex;` 编不过——"没有合适的默认构造函数"；原因：模板构造函数不是默认构造函数，静态对象没法推 C；后果：插件编不过。对策：模板类 `RegisterOne<C>`（本章写法），C 显式给出、构造零参——这是实测踩过的坑）。
3. **哨兵被链接器丢弃**（现象：插件 cpp 编译链接了，注册表里却没有它；原因：静态库链接时无引用的目标文件整个被丢（哨兵无人引用）；后果：插件静默失踪。对策：可执行工程直接列源文件（本章 build 脚本的做法）或给哨兵加 force-link；静态库场景尤其要防）。
4. **重名覆盖**（现象：两个插件同名，add 静默覆盖或双存，find 行为不定；原因：注册表合同没定重名语义；后果：编码行为取决于注册顺序。对策：add 返回 bool、重名拒绝（本章合同）——宁可失败响亮，不许静默顶替）。
5. **哨兵构造里做重活**（现象：某插件哨兵构造时读文件、开线程，程序一加载就卡；原因：哨兵构造在 main 前，异常处理与环境都未就绪；后果：启动不可控。对策：哨兵只做轻注册（new 一个空对象）；重初始化留给插件自己的 init 接口或首次调用）。

## encode_with：门面的价值

`encode_with(kind, data)` 只有四行，却是框架对客户的完整门面：查注册表 → 查无此人返 "err" → 有则转发 encode。它把两件事从客户手里拿走了：**空指针决策**（find 返回 nullptr 时客户自己判是常态坏味道——每个调用点判一遍、漏判一处崩一次；门面收编成一处）；**具体类型暴露**（客户拿到 Codec* 后 if-else 分型是注册表抽象的破产——门面只给结果不给对象）。四行门面背后的判据：**注册表被谁用、怎么用**——如果客户总是"按名字调一次"，门面就该存在（本章）；如果客户要持有插件、反复调用，find 返回指针才对，门面退化为 find 的薄包装。接口跟着使用模式走，这一判据在 38 章权限管道（Guard 组合）会再见到。

## 测试法

- **main 前已注册**：main 第一行断言 `size() == 3` 且 find("hex") 非空——自注册的核心承诺。
- **输出固定三路**：三种编码对同一输入 "hi" 的结果逐字符断言（6869 / aGk= / ih）——插件行为面全覆盖（三个插件的输出各有标准答案）。
- **未知名兜底**：encode_with("nope") == "err"——门面合同（查无此人不是崩溃）。
- **重名拒斥**：add(Dup) 返回 false 且原插件输出不变——注册表的一致性合同。
- **注册顺序无关性**：size 与三路输出在任意 TU 初始化顺序下相同（多编译单元链接天然产生乱序初始化，本例四 TU 的实际链接顺序就是一次随机样本）。
- **插件实现的匿名性**：main.cpp 不 include 任何插件头——编译期即验证"main 零插件知识"（main.cpp 的 include 列表就是合同）。
- **find 未知名返回 nullptr**：encode_with 已兜底为 "err"，但直接 find("nope") 的空指针合同也要有断言（find 的直接客户是被测代码自己）——两条查询路径分别钉死。

## 三书对应

- 之禅：第 5 章"工厂方法模式"（5.x 工厂与配置结合的扩展讨论）与第 18 章"策略模式"（18.x 策略注册与选择——本章把"选择"从 if-else 升级为注册表查询）；另见第 6 章关于"高内聚低耦合"在模块装配上的论述。
- 刘伟：第 7 章"单例模式"7.3 节"饿汉式与懒汉式"的取舍讨论——Meyers 单例正是"懒汉式"的线程安全形态；第 9 章"工厂模式"9.4 节"简单工厂 + 配置文件"的解耦思路与本章"注册表 + 哨兵"同一动机。
- GoF：第 3 章创建型模式引言对"系统应该由它使用的类来参数化"的论述（Abstract Factory 一节对"注册工厂"的注记——"用一个注册表把原型/工厂按名存取"）；5.4 Prototype"实现"小节对"原型管理器（Prototype Manager）按名注册与查找"的讨论——本章 Registry 即管理器，Codec 即原型位的接口版。

*可选延伸：可运行示例见 examples/35_plugins/。*
