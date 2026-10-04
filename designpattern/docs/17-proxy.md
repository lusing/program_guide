# 17 · 代理

结构型篇收官。代理与装饰结构几乎相同（都实现接口、都持有内层对象），差别在一个词：**代理管"能不能/值不值/什么时候"访问本体，装饰管"访问之后多做点什么"**。GoF 4.7 节的定义：**为其他对象提供一种代理以控制对这个对象的访问**。

## 意图与动机

图片查看器是教科书场景：相册列表要展示 100 张图，每张图 `draw()` 前要"从磁盘解码"（贵）。列表 UI 只需要每张图的名字和缩略占位——**100 张图没必要在列表出现时就全部解码**。朴素写法 `vector<RealImage>` 构造时就把 100 张全解码：打开相册卡 3 秒，其中 2.9 秒在解码用户根本没点开的图。

代理的解法：造一个与 `RealImage` 同接口的 `LazyImageProxy`，它**看起来是图、实际上是一个"将来才有图"的占位**——第一次 `draw()` 时才真正加载，之后直接转发。

## 经典写法：虚代理（懒加载）

示例 `proxy.hpp`。本体与接口：

```cpp
// Subject：代理与本体共同的接口。
struct Image {
    virtual ~Image() = default;
    virtual void draw() const = 0;
    [[nodiscard]] virtual std::string name() const = 0;
};

// RealSubject：真身——构造即"昂贵"（教学里用静态计数模拟加载成本）。
class RealImage final : public Image {
public:
    explicit RealImage(std::string name) : name_(std::move(name)) { ++constructed; }
    void draw() const override { last_drawn_ = name_; }
    [[nodiscard]] std::string name() const override { return name_; }
    [[nodiscard]] static int constructed_count() { return constructed; }
    [[nodiscard]] static const std::string& last_drawn() { return last_drawn_; }

    inline static int constructed = 0;               // 教学观测：构造次数
private:
    std::string name_;
    inline static std::string last_drawn_;
};
```

`constructed` 静态计数是"加载成本"的确定性化身——不用真开文件，构造次数就是可断言的加载次数。代理本体：

```cpp
class LazyImageProxy final : public Image {
public:
    explicit LazyImageProxy(std::string name) : name_(std::move(name)) {}

    void draw() const override {
        ensure_loaded();                              // 首次才付加载成本
        real_->draw();
    }
    [[nodiscard]] std::string name() const override { return name_; }  // 便宜操作直通

private:
    void ensure_loaded() const {
        if (!real_) real_ = std::make_unique<RealImage>(name_);
    }
    std::string name_;
    mutable std::unique_ptr<RealImage> real_;         // mutable：惰性装配位
};
```

四个要点：

1. **代理与本体同接口**：`Image&` 的消费方根本分不清拿到的是本体还是代理——这是代理区别于"随便一个包装类"的形式要求（接口一致性，GoF 参与者表的第一条）。
2. **`mutable` + const `draw()`**：draw 语义上只是"画"，物理上要装配真身——懒装配是 const 语义下的实现细节，与第 16 章享元池、第 8 章单例的 mutable 一脉相承。
3. **代理自己管真身的生命周期**：`real_` 是代理的成员，真身直到首次 draw 才出生。对比第 14 章装饰：装饰的内层是**调用方递进来的**，代理的真身是**自己按需创建的**——一层之隔，意图全变。
4. **便宜操作直通**：`name()` 不触发加载——代理的价值在"区分贵与不贵"，如果所有操作都触发加载，代理退化为本体。

运行输出：

```text
代理: 代理构造+name() 后 RealImage 构造数=0
代理: 首次 draw 后 RealImage 构造数=1
代理: 二次 draw 构造数仍=1（懒加载只付一次）
多态: Image& 消费代理，行为与本体一致
```

断言链精确到次数：代理构造后 `RealImage::constructed == 0`（零成本占位）；首次 draw 后 ==1（加载发生）；二次 draw 后仍 ==1（只付一次）。100 张图的相册，从"100 次解码"变成"点几张解几张"。

## 代理家族：一张表认全

GoF 给代理列了四个变体，差别全在"控制什么"：

| 变体 | 控制什么 | 触发条件 | C++ 里的熟面孔 |
|---|---|---|---|
| 虚代理（virtual） | 创建成本 | 首次使用才建 | 本章懒加载；`unique_ptr` 指向昂贵资源 |
| 保护代理（protection） | 访问权限 | 权限不足拒转发 | `AccessControl` 包装：draw 前查角色 |
| 远程代理（remote） | 地址空间 | 本地桩转发到远端 | RPC stub、CORBA/COM 代理 |
| 智能引用（smart reference） | 生命周期/额外动作 | 计数、加锁、写时复制 | `shared_ptr` 本尊 |

`shared_ptr` 是"智能引用代理"的完美标本：它控制的是**生命周期**（引用计数）与**线程安全**（控制块原子操作），本体（指向的对象）对使用者透明——这就是为什么说"现代 C++ 把代理的一部分内化进了语言层"。保护代理在 C++ 里最常见于跨边界访问（UI 层只能调 `const` 方法、进程内插件只能走白名单接口），实现就是本章 LazyImageProxy 的结构换成权限判断。

## 现代写法：std::optional 惰性

懒加载不必堆分配——`std::optional<RealImage>` 把真身内嵌在代理对象里，首次使用 `emplace` 原地构造（`proxy.hpp` 末尾）：

```cpp
class OptImage {
public:
    explicit OptImage(std::string name) : name_(std::move(name)) {}
    void draw() {
        if (!real_) real_.emplace(name_);             // emplace 原地构造
        real_->draw();
    }
    [[nodiscard]] std::string name() const { return name_; }
private:
    std::string name_;
    std::optional<RealImage> real_;
};
```

与 `unique_ptr` 版的取舍：

- **`optional`**：真身大小已知、代理自身可容纳双份内存（占位时浪费一份）→ 少一次堆分配，缓存局部性好；缺点是代理对象变大、不能"真身比代理活得久"。
- **`unique_ptr`**：真身可以很大/多态/与代理不同生命周期 → 灵活；多一次分配。

运行输出最后一行验证 optional 版同样"首次 draw 且仅首次触发加载"。另一个现代形态值得点名：**写时复制（COW）**——`shared_ptr` + 首次写时 `clone`，是"智能引用代理"的现代实现，Qt 的隐式共享、`std::filesystem::path` 的实现技巧都是它。本章示例单文件教学不展开，第 34 章对象池会用到"池本身就是一个大代理"的视角。

## 两版取舍

| 维度 | 经典代理（虚基类 + 指针） | optional 惰性 | lambda 惰性 |
|---|---|---|---|
| 真身类型 | 运行期多态（Image 家族） | 编译期已知 | 编译期已知 |
| 零堆分配 | 否 | 是 | 是 |
| 框架接口适配 | 天然（is-a Subject） | 需要包一层 | 需要包一层 |
| 典型场景 | 跨模块 API、插件边界 | 类内成员惰性装配 | 函数内惰性计算 |

第三种一眼即明：

```cpp
auto lazy_draw = [img = std::optional<RealImage>{},
                  name = std::string{"photo.png"}]() mutable {
    if (!img) img.emplace(name);
    img->draw();
};
```

lambda 捕获 optional——把"懒"压缩成一个局部值。判据：**代理出现在类/框架边界（需要多态）→ 经典代理；惰性只是类内实现细节 → optional；惰性只是局部逻辑 → lambda**。

## 保护代理：二十行写一个权限墙

虚代理控制"什么时候访问"，保护代理控制"**谁能**访问"——结构不变，ensure_loaded 换成权限检查：

```cpp
enum class Role { Guest, Admin };

class GuardedImageProxy final : public Image {
public:
    GuardedImageProxy(std::string name, Role caller_role)
        : name_(std::move(name)), role_(caller_role) {}

    void draw() const override {
        if (role_ != Role::Admin)
            throw std::runtime_error("无权限查看图片");    // 拦截点：先于转发
        ensure_loaded();
        real_->draw();
    }
    [[nodiscard]] std::string name() const override { return name_; }  // 元数据公开

private:
    std::string name_;
    Role role_;
    mutable std::unique_ptr<RealImage> real_;
    void ensure_loaded() const { if (!real_) real_ = std::make_unique<RealImage>(name_); }
};
```

注意两条设计纪律：**拦截先于加载**（Guest 连磁盘解码都不触发——权限检查在最前面，这也顺手实现了"未授权不浪费资源"）；**元数据与内容分级**（`name()` 公开、`draw()` 受限——真实系统的"列表可见、内容受限"正是这个形状）。保护代理的价值不在几行 if，在**权限检查与业务代码分离**：`RealImage` 里一行权限代码都没有，权限策略全部集中在代理层——策略变了（加角色、加时间窗）只动代理。

## 远程代理与 RPC 桩：代理的最大规模应用

保护代理拦截的是权限，远程代理拦截的是**地址空间**——调用方以为在调本地函数，实际参数被序列化、发过网络、远端执行、结果送回来。这个"本地假象"的载体就是远程代理（RPC 桩 stub）：

```text
调用方 ──buy(item)──> OrderStub（远程代理）
                        │ 序列化参数 + 方法名
                        ▼
                     网络 ──> 服务端骨架（skeleton）──> RealOrderService
                        ▲
调用方 <──返回值/异常──  │ 反序列化
```

`OrderStub` 完全符合代理的结构定义：与本体同接口（接口定义语言 IDL 生成的头文件就是 Subject）、持有"真身"（一个网络连接）、每个调用都过代理（序列化点）。你现在能在 C++ 生态里认出它的后裔：gRPC 生成的 stub 类、CORBA/COM 代理、甚至 `std::future` 对"远端计算结果"的代言。GoF 1995 年写这一节时的判断到今天没有失效——**分布式系统的边界复杂度，靠的就是把"网络"藏在代理接口后面**。

## 陷阱清单

1. **代理与本体接口漂移**（现象：本体加了方法，代理忘加或签名不同；原因：手工双维护；后果：多态调用走不到代理逻辑或编译错误。对策：接口变更时代理本体同步改；C++ 无动态代理（Java 的动态代理反射生成），所以更要靠测试钉住接口一致性）。
2. **所有操作都触发加载**（现象：`name()` 里也 ensure_loaded；原因：图省事统一走真身；后果：懒加载白做，列表页还是卡。对策：把操作按"需要真身吗"分类，只需要元数据的直通代理自己的缓存）。
3. **const 代理暴露非 const 真身**（现象：代理提供 `RealImage& get()`；原因：为方便；后果：调用方绕过代理直接改真身，代理的控制全失效。对策：真身严格 private，所有访问过代理的方法——这是代理的立身之本）。
4. **懒加载撞并发**（现象：两个线程同时首次 draw，真身构造两次（或 worse）；原因：`if (!real_)` 无同步；后果：双份资源、计数错乱。对策：`std::call_once`（第 8 章同款）或互斥锁保护装配点；单线程场景才敢裸判空）。
5. **代理叠代理**（现象：LazyProxy(ProtectionProxy(Real))；原因：控制点都要；后果：每次调用穿两层，顺序语义（先查权限还是先加载？）说不清。对策：代理一般一层；确需多层时明确顺序并把"加载"和"鉴权"拆成责任链（第 19 章）或装饰链——用对模式）。

## 结构型篇小结：七模式一张图

第 11-17 章讲的全是"把类和对象组合成更大的结构"，合上时值得并排看一眼。七者的核心动作各不相同：

```text
适配器：接口不合 → 转换接口（缝合已有代码）
桥接  ：两维正交 → 拆成两棵树 + 一根桥（防 m×n 爆炸）
组合  ：部分整体 → 叶夹同接口递归转发（树）
装饰  ：职责叠加 → 同接口层层包装（洋葱）
外观  ：零件一堆 → 一个入口收拢流程知识（门面）
享元  ：大量细粒度 → 内蕴共享外蕴外传（省内存）
代理  ：访问本体 → 同接口替身控制访问（懒/权限/远程）
```

记忆抓手按"包装层"归堆：**转换型**（适配器——改接口）、**汇聚型**（外观、享元——多收一）、**拆分型**（桥接、组合——一拆多）、**包装型**（装饰、代理——一层套一层，靠"内层谁给的"区分）。结构型模式的共同代价都是**多一层间接**——模式选择的本质是判断这层间接买到了什么（兼容、正交、递归、叠加、简化、共享、控制），买不到就别加。行为型篇（第 18 章起）将从"怎么组合"转向"怎么分配职责与通信"。

## 三书对应

- 之禅：第 12 章"代理模式"（12.2 定义、12.3 应用——游戏打怪强制的例子、12.4 扩展——普通代理/强制代理/动态代理的 Java 语境讨论）、第 31 章 31.1 节"代理 VS 装饰"。
- 刘伟：第 16 章"代理模式"（16.1 动机与定义、16.2 结构与分析、16.3 实例——收费商务信息查询系统（保护代理）、16.4 效果与应用、16.5 扩展——远程/虚拟/缓冲/智能引用等 8 种代理的分类）。
- GoF：第 4 章 4.7 节 Proxy——ImageProxy 例（本章同源），"相关模式"节列了四个变体与 Adapter/Decorator 的辨析（Decorator 只加职责不改接口，Proxy 可以先拦后转）。

*可选延伸：可运行示例见 examples/17_proxy/。*
