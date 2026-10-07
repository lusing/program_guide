# 09 · 原型

创建型模式里最"物"的一个：不谈工厂、不谈全局，直接问"能不能**复制现成的**"。刘伟 8.1.2 节的定义：**用原型实例指定创建对象的种类，并且通过拷贝这些原型创建新的对象**。别名"克隆模式"——GoF 原书标题就是 Prototype: Specification of the fundamental clone operation（原型的核心就是 clone 这一个操作）。

## 意图与动机

游戏刷怪：每波 20 个哥布林，每个哥布林要血量、技能、装备、AI 参数……逐个 `make_unique<Goblin>(hp, skill, ...)` 意味着调用方必须知道全部构造细节，而且这份"配置知识"写在刷怪代码里——策划改一个初始值，刷怪代码跟着改。而实际的配置来源往往是运行期的：第一个哥布林可能由存档、配置表或玩家行为"现场"构造出来，之后的都是它的微调副本。

原型的解法：**把一个配置好的对象当模板，`clone()` 出副本**。调用方从"知道怎么构造"退化为"知道找谁克隆"。

## 经典写法：clone 协议

示例 `prototype.hpp`：

```cpp
struct Monster {
    virtual ~Monster() = default;
    virtual std::unique_ptr<Monster> clone() const = 0;
    [[nodiscard]] virtual std::string kind() const = 0;   // 比 typeid 可移植的判定
    [[nodiscard]] virtual std::string describe() const = 0;
};

class Goblin : public Monster {
public:
    std::unique_ptr<Monster> clone() const override { return std::make_unique<Goblin>(*this); }
    [[nodiscard]] std::string kind() const override { return "goblin"; }
    [[nodiscard]] std::string describe() const override { return "goblin(hp=10)"; }
};

// 协变返回：子类 clone 声明成返回 unique_ptr<Goblin> 是可以的，
// 但接口统一在 Monster::clone 上，容器里拿到的仍是 unique_ptr<Monster>。
class GoblinChief final : public Goblin {
public:
    GoblinChief() = default;
    explicit GoblinChief(int buffs) : buffs_(buffs) {}
    std::unique_ptr<Monster> clone() const override { return std::make_unique<GoblinChief>(*this); }
    [[nodiscard]] std::string kind() const override { return "chief"; }
    [[nodiscard]] std::string describe() const override {
        return std::format("goblin-chief(buffs={})", buffs_);
    }

private:
    int buffs_ = 1;
};
```

clone 的标准写法一行：`make_unique<T>(*this)`——**调用自己的拷贝构造**，新建堆对象并按当前值复制。三个要点：

1. **`unique_ptr<Monster>` 返回值与所有权**。克隆出来的新对象归调用方，智能指针表达"你要对新对象的生命周期负责"。
2. **协变返回在智能指针下失效**。C++ 支持返回类型协变（子类 override 返回更"窄"的指针/引用类型），但只对**裸指针和引用**有效——`unique_ptr<GoblinChief>` 不是 `unique_ptr<Monster>` 的派生类，智能指针没有协变。所以接口统一返回 `unique_ptr<Monster>`；确需窄类型时用 GoF 原书 C++ 实现的裸指针协变写法（配明确的 delete 责任），或像本示例一样由调用方 `static_cast`。
3. **`kind()` 虚函数替代 `typeid`**。`typeid(*ptr).name()` 的输出格式是平台相关的（MSVC 给 `"class dp::Goblin"`，clang 给 `"dp::Goblin"`），进了断言/输出就破坏确定性；`kind()` 返回自己定义的稳定字符串，跨编译器逐字节一致。这也是本书"确定性输出"约定的又一实践。

原型的用武之地在批量复制：

```cpp
// 原型的用武之地：复杂配置的对象按模板复制 n 份，调用方不碰构造细节。
inline std::vector<std::unique_ptr<Monster>> spawn_wave(const Monster& proto, size_t n) {
    std::vector<std::unique_ptr<Monster>> wave;
    wave.reserve(n);
    for (size_t i = 0; i < n; ++i) wave.push_back(proto.clone());
    return wave;
}
```

`spawn_wave` 只认 `Monster` 接口——它是哥布林还是首领、有几个 buff，调用方（刷怪系统）不知道也不需要知道。**配置知识留在原型上，复制逻辑与产品解耦**。

## 运行观察

```text
原型: 波次 3 个，描述 goblin-chief(buffs=3)
克隆保真: chief=chief, goblin=goblin
```

断言链验证三件事：波次里 3 个全是 `chief` 且 `describe()` 完整保留 `buffs=3`（克隆带走了模板的全部状态）；`wave[1]` 与再克隆的 `wave[0]` 相互独立（深拷贝成立，改一个不影响另一个）；`Goblin` 克隆出来仍是 `goblin`（克隆保真——子类不会克隆成父类）。

## 深拷贝与浅拷贝：原型成败的分水岭

GoF 在 Prototype 一节花最大篇幅讨论深浅拷贝，因为它决定 clone 是否正确：

- **浅拷贝**：逐成员复制。指针成员复制的是**地址**——两个对象共享同一个所指。如果所指对象只读（共享的静态资源），浅拷贝正确且高效；如果可变，两个副本互相污染。
- **深拷贝**：指针成员也复制其所指对象。代价是递归复制整张对象图。

刘伟 8.3 节的实例是"邮件复制"：浅克隆的邮件副本与原件共享附件对象，一封删附件另一封跟着丢——然后引出深克隆。C++ 的独特优势是**把深浅选择写进类型**：

```cpp
struct Attachment { std::string filename; };
struct Mail {
    std::string subject;
    std::unique_ptr<Attachment> att;      // 独占 → 拷贝构造必须深拷贝
    std::shared_ptr<const Attachment> readonly_att;  // 共享只读 → 浅拷贝即正确
};
```

- `unique_ptr` **不可拷贝**：含 `unique_ptr` 的类默认拷贝构造被删除——编译器强迫你显式写 clone/拷贝构造，深拷贝逻辑不写就编译不过。**不可拷贝就是"提醒你考虑深拷贝"的编译期哨兵**。
- `shared_ptr` 可拷贝且复制的是控制块指针：天然浅拷贝、共享所指。只读数据的共享正是第 16 章享元模式的主题——原型和享元在"共享"上分工：原型共享只读部分，享元干脆把共享部分抽成外部管理。

结论：clone 的实现 = 拷贝构造 = 成员的深浅拷贝策略之和。把每个指针成员的"独占还是共享"想清楚，clone 就不会错。

## 现代写法：prototype 也逃不过 function 化

和工厂方法一样，"需要一个可复制的模板"也可以不用继承协议——**模板参数 + 值拷贝**：

```cpp
template <std::copyable M>
std::vector<M> spawn_wave2(const M& proto, size_t n) {
    return std::vector<M>(n, proto);       // 拷贝构造 n 份，连 clone() 都不用写
}
```

值语义类型（不涉及多态、成员拷贝语义正确）根本不需要 `clone()`——`vector(n, proto)` 就是原型模式的零成本形态。**clone 协议只在多态场景必要**：模板是"哪种怪物"在编译期已知的情况，虚 clone 是运行期才拿到"某个 Monster 的引用"的情况。这条分界线与全书反复出现的虚函数/模板二分完全同构。

多态场景还有一个组合技：**原型 + 注册表工厂**（第 5 章注册表的升级版）——注册的不再是 lambda 构造器，而是原型对象本身：

```cpp
class MonsterFactory {
public:
    void register_proto(std::string name, std::unique_ptr<Monster> proto);
    std::unique_ptr<Monster> create(std::string_view name) {
        return protos_.at(std::string{name})->clone();   // 工厂 = 查表 + 克隆
    }
private:
    std::map<std::string, std::unique_ptr<Monster>> protos_;
};
```

配置从配置文件加载进原型表，之后"按名字造怪"就是查表克隆——配置表驱动的对象创建，运行期连具体类的名字都不出现。GoF 在 Prototype 的"实现"节专门讨论了"原型管理器（prototype manager）"，指的就是这个结构。

## 带参克隆：clone 的参数化变体

GoF 在"实现"节还讨论了一个少被注意的变体：clone 不必是无参的。副本脱离原型后常要"个性化"——第一个哥布林克隆出来后血量减半、首领加两个 buff。两种写法：

```cpp
// 写法一：先克隆后修改（推荐，协议最简单）
auto m = proto.clone();
if (auto* chief = dynamic_cast<GoblinChief*>(m.get()))
    chief->add_buffs(2);

// 写法二：带参克隆（GoF 提及的变体）——克隆与初始化一步完成
struct Monster {
    virtual std::unique_ptr<Monster> clone(int hp_delta = 0) const = 0;
};
```

写法一保持 `clone()` 协议干净（"复制就是复制"），个性化交给克隆体的常规接口；写法二把个性化塞进签名，每加一种个性化都要动接口。GoF 把后者当作"克隆协作对象"的替代方案提及——当克隆需要**重建内部关系**（副本指向新的协作者而非共享旧的）时，带参版本能一步表达"克隆 + 重连线"，避免"先克隆出错误连线再修复"的中间态。本教程的建议：默认无参，出现"克隆后必改"的固定动作时，把这个动作做成带参克隆或独立的 `rebind()` 方法，而不是让调用方抄"克隆五连"。

## C++ 特有事故：对象切片（slicing）

原型模式围绕"按值复制多态对象"展开，而 C++ 的值语义藏着这个领域最经典的暗坑——**切片**：

```cpp
GoblinChief chief(3);
Monster m = chief;          // 编译通过！m 是切片拷贝：只有 Monster 部分被复制
m.kind();                   // 返回 "monster"（Monster 自己的版本）——buffs 丢了
```

`Monster m = chief` 把 `chief` 按 `Monster` 的尺寸拷贝：`GoblinChief` 多出来的成员被"切掉"，虚表也变成 Monster 的——副本既不完整也不多态，而且**编译器一声不吭**。切片与 clone 的关系：clone 协议的全部意义就是**绕开切片**——`unique_ptr<Monster>` 指向堆上的完整对象，复制走的是"派生类拷贝构造 + 基类指针持有"，类型信息和数据都完好。这是 GoF 原书没有展开、但对 C++ 程序员必须讲的点：**Java/Python 的引用语义天然没有切片，C++ 的 clone 教学必须配这一课**。

防御三招：

1. **按基类值传递/存储视为代码坏味道**：`void f(Monster m)`、`std::vector<Monster>` 都会切片，统一用引用传参、`vector<unique_ptr<Monster>>` 存储。
2. **把基类析构做成 protected 非 virtual**（或类标 `final` 收尾）： protected 析构能挡住"栈上构造基类"和值拷贝的多数路径（`Monster m = chief` 直接编译不过），虚析构讨论见第 11 章。
3. **拷贝构造收 `Monster&` 时显式处理**：如果确实需要从 `Monster&` 复制，写 `Monster(const Monster&) = delete;`——逼所有复制走 clone。

第 2 章里"里氏替换"讲的是行为兼容，本章补上它的值语义镜像：**能放进容器的多态对象必须是 `unique_ptr<Base>`，而不是 `Base` 的值**。

## 两版取舍

| 维度 | clone 协议（虚函数） | 值拷贝/模板 |
|---|---|---|
| 场景 | 运行期拿到基类引用，类型未知 | 类型编译期已知 |
| 要写的代码 | 每个子类一个 clone | 零（拷贝构造自带） |
| 深浅拷贝风险 | 有，必须逐成员审 | 有，同样要审（只是自动生成的拷贝构造帮你干了浅的那部分） |
| 与容器配合 | `vector<unique_ptr<Monster>>` | `vector<ConcreteT>` |

## 陷阱清单

1. **忘了拷贝构造的存在**（现象：子类加了一个指针成员，clone() 还是 `make_unique<T>(*this)`；原因：一行写法掩盖了拷贝构造；后果：新成员被浅拷贝或根本没拷（unique_ptr 直接编译错误反而是好事，裸指针静默共享）。对策：clone 依赖拷贝构造，加成员时同步审视拷贝语义）。
2. **克隆半构造对象**（现象：在构造函数或 `log()` 流程里 clone this；原因：状态未定型；后果：副本继承未完成状态。对策：只在对象状态稳定后克隆）。
3. **协变幻觉**（现象：给 `unique_ptr` 返回类型写"协变"；原因：裸指针时代的直觉；后果：编译错误或想都不想直接隐藏基类函数。对策：接口统一 `unique_ptr<Base>`，窄类型按需下转）。
4. **原型上的可变共享状态**（现象：原型对象有个 `static` 计数器或指向共享缓存；原因：状态分类不清；后果：克隆体和原型互相干扰。对策：共享只读部分用 `shared_ptr<const T>`，可变部分逐份独立）。
5. **把原型当性能银弹**（现象：为省"构造开销"全部改克隆；原因：误以为拷贝一定比构造快；后果：深拷贝一个复杂对象图远比重新构造贵。对策：先测量。原型买的是"配置复用"，不是速度）。

## 与其他创建型模式的合流点

创建型篇六章收尾前，把原型在家族里的位置钉一下。原型与工厂方法是**同业的竞争者**：两者都把"造什么"从调用方剥离——工厂方法用"专门的构造代码"造新对象，原型用"复制现成对象"造新对象；当对象的正确初始状态比对象本身难描述时（复制一个调好的配置，胜过罗列十几个参数），原型赢；当对象必须从干净状态开始时（连接、事务、随机数引擎），工厂赢。原型与单例**不共戴天**：单例把拷贝构造删了，克隆协议就断了——要 clone 的类别做单例。原型与建造者**互补**：原型复制的是"成品"，建造者分步的是"半成品"；第 22 章备忘录模式和第 34 章对象池会看到原型的近亲形态（状态快照、对象复用），核心动作同样是"别从头造，拿现成的来"。

## 三书对应

- 之禅：无独立章（第 2 版未收原型）；克隆相关讨论散见于工厂方法扩展节。
- 刘伟：第 8 章"原型模式"（8.1 动机与定义、8.2 结构与分析、8.3 实例——邮件复制浅克隆/深克隆、8.5 扩展——带原型管理器的原型）。
- GoF：第 3 章 3.4 节 Prototype——"实现"节讨论深浅拷贝、拷贝构造的参数化克隆、克隆协作对象、原型管理器，全部覆盖本章内容；其 C++ 实现示例使用裸指针协变返回，与本教程的现代化改写形成对照。

*可选延伸：可运行示例见 examples/09_prototype/。*

---

上一章：[08 单例](08-singleton.md) · 下一章：[10 建造者](10-builder.md)
