# 18 · 责任链

行为型篇开场。行为型模式研究的不再是"怎么组织类"，而是"**职责怎么分配、对象怎么通信**"——责任链是其中最直观的一个：一条请求进来，一串处理者轮流问自己"这事我管吗"，管就处理，不管就往下传。GoF 5.1 节的定义：**使多个对象都有机会处理请求，从而避免请求的发送者和接收者之间的耦合关系。将这些对象连成一条链，并沿着这条链传递该请求，直到有一个对象处理它为止**。

## 意图与动机

报销审批是刘伟 17 章的例子：金额 ≤1000 主管批，≤5000 总监批，≤100000 CEO 批。朴素写法把这条规则写在提交函数里：

```cpp
if (amount <= 1000)      return manager->approve(amount);
else if (amount <= 5000) return director->approve(amount);
else if (amount <= 100000) return ceo->approve(amount);
else return "rejected";
```

问题有三：审批规则硬编码在提交方（新加一档审批人要改这里）；提交方必须认识所有审批人（耦合）；同样的金额分档逻辑如果出现在第二个入口（比如撤销流程），就要抄第二份。责任链把"谁能处理多大的单"装进每个处理者自己身上——**分档知识归还给拥有它的人**，提交方只认识链头。

## 经典写法：审批链

示例 `chain.hpp`。链骨架在基类，子类只回答两个问题：

```cpp
class Approver {
public:
    virtual ~Approver() = default;
    void set_next(std::unique_ptr<Approver> n) { next_ = std::move(n); }

    std::string handle(int amount) {
        if (amount <= limit())
            return approve(amount);          // 我能批
        if (next_)
            return next_->handle(amount);    // 超权限：传给下一环
        return "rejected";                   // 链尾无人接：默认拒绝
    }

protected:
    [[nodiscard]] virtual std::string approve(int) const = 0;
    [[nodiscard]] virtual int limit() const = 0;
private:
    std::unique_ptr<Approver> next_;
};

class Manager final : public Approver {
protected:
    [[nodiscard]] std::string approve(int) const override { return "manager"; }
    [[nodiscard]] int limit() const override { return 1000; }
};
// Director（5000）、Ceo（100000）同构，略
```

四个要点：

1. **`handle` 的三分支结构是责任链的"心跳"**：够权限就处理、不够且有下家就传、传到头就默认拒绝。子类完全不碰传递逻辑——`next_` 的管理在基类，GoF 参与者表里 Successor 的维护职责被收进了链骨架。
2. **每环两件事：门槛（limit）与动作（approve）**。门槛决定"接不接"，动作决定"怎么处理"。两者都是虚函数，新增一档审批人 = 新写一个类，链的其余部分零改动。
3. **链尾的默认策略写在骨架里**：`"rejected"`。这是"无人接单"的显式决定——责任链不保证请求一定被处理，调用方必须知道这一点（GoF 在"后果"节专门列了这条：请求可能到链尾都无人处理）。
4. **`unique_ptr` 管链**：链头拥有整条链，装配点 `set_next` 逐环挂接，链整体析构一次搞定。

运行输出：

```text
链: 900->manager, 3000->director, 99999->ceo
链: 200000 -> rejected（无人可接）
```

断言逐档验证：900 归 manager、3000 穿过 manager 归 director、99999 穿过前两环归 ceo、200000 走完全链落到 rejected——传递、拦截、默认三种路径全部走到。

## 现代写法：表驱动处理器

继承链是"结构化"的传递；同样的语义用一张**处理器表**表达更轻（`chain.hpp` 末尾）：

```cpp
inline std::string handle_with_table(
    std::span<const std::function<std::optional<std::string>(int)>> handlers,
    int amount) {
    for (const auto& h : handlers) {
        if (auto r = h(amount)) return *r;      // 有人接单
    }
    return "rejected";                           // 无人接：与链版同一默认策略
}
```

每个处理器是 `function<optional<string>(int)>`：接单返回 `optional{结果}`，不接返回 `nullopt`——**"处理还是传递"从控制流（if + 递归调用）变成了返回类型（optional 有没有值）**。调用侧：

```cpp
std::vector<std::function<std::optional<std::string>(int)>> table = {
    [](int a) -> std::optional<std::string> {
        return a <= 1000 ? std::optional{"manager"} : std::nullopt; },
    /* director / ceo 两行同构 */
};
handle_with_table(table, 3000);   // -> "director"
```

运行输出第三行：

```text
表: 三档与超限结果与链版完全一致
```

两种写法逐档同值——**责任链的本质是"顺序尝试、首个接单者胜出"的搜索，链只是这个搜索的一种数据结构**。表版失去了什么？链可以在**运行期重排/增删环节**（每环持 next 指针，动态改链）；表版增删就是改 vector，其实也行。链版多出的真实能力只有一条：**环节可以持有状态并且按需决定传递目标**（不一定是"下一个"，可以跳环、回环）。纯"线性顺序尝试"的场景，表版是更诚实的结构。

## 两版取舍

| 维度 | 继承链（GoF 经典） | 表驱动（现代） |
|---|---|---|
| 环节形态 | 类（可带状态、方法） | 闭包 |
| 传递逻辑 | 骨架递归 | 循环 + optional |
| 传递目标 | 可跳环/回环/条件传 | 固定线性 |
| 调试 | 断点逐环清晰 | 调用栈浅但闭包内容要展开看 |
| 教科书对应 | GoF/刘伟/之禅 | 无——生产代码常态 |

## 与装饰的边界（回看第 14 章）

两个模式都"层层传递"，第 14 章给过三个分界，这里换到行为视角再看一眼：装饰链**每层都处理**（加工内容，结果回传组装），责任链**找到处理者就停**（决策分派，不回传）。装饰的每一层必须转发（接口契约），责任链的每一环可以不转发（"我不管"是合法输出）。判据一句话：请求需要**每个人的加工**用装饰，需要**其中一个的裁决**用责任链。

## 链的形状：不止一条直线

本例的链是纯线性的，GoF 在"实现"节专门讨论了链可以更长成的形状：

1. **线性链**——本例形态。每环的传递目标固定是"下一环"，适合"按数量/等级分档"的场景。
2. **树状链**——刘伟 17.5 的扩展：组合模式（第 13 章）构建的审批树，请求从根流入，每个内结点"先看自己能不能批、不能就发给子结点"。适合组织架构这种天然分层的结构——请求沿汇报线上浮。
3. **条件路由**——每环按请求内容决定传给谁（不一定是 next）。比如技术支持链：硬件问题跳给硬件组，软件问题跳给软件组。这时 `next_` 单指针不够，处理者要持有一张"问题类型 → 下家"的映射。

形状越复杂，"链骨架收进基类"的收益越小——条件路由的传递逻辑没法对每环通用。判定：**纯线性分档用继承链，路由逻辑一复杂就退回表驱动（自己控制循环就是最大的路由自由度），层级结构用组合树**。

## 请求不止是 int：泛化签名

真实系统的请求很少是一个裸 int。把请求升级为类型，链的签名怎么变：

```cpp
struct Request {
    int amount;
    std::string title;          // 什么开销
    std::string submitter;      // 谁提交的
};

class Approver {
public:
    virtual ~Approver() = default;
    void set_next(std::unique_ptr<Approver> n) { next_ = std::move(n); }

    std::string handle(const Request& req) {
        if (req.amount <= limit()) return approve(req);
        if (next_) return next_->handle(req);
        return "rejected";
    }

protected:
    [[nodiscard]] virtual std::string approve(const Request&) const = 0;
    [[nodiscard]] virtual int limit() const = 0;
private:
    std::unique_ptr<Approver> next_;
};
```

与 `int` 版逐行对照：`handle` 的三分支心跳一个字没变——**变的只是请求类型的宽度**。这正是责任链骨架与业务解耦的证据：`limit()` 分档可以依据 `req.title`（差旅费与招待费不同门槛），`approve` 的返回可以带上审批意见。泛化的方向永远是"请求变胖、骨架不变"，反过来（骨架跟着请求变）就是设计出了问题。

## 性能账：穿链的成本模型

责任链的开销 = **没接单的环数 × 每环的判断成本**。最坏情形（请求落到链尾被拒）：n 环各判断一次。这个账决定了两条纪律：

1. **判断要便宜**。本例 `limit()` 是常量——一次比较就分出接与不接。若接单判断本身昂贵（查数据库、解密验证），穿链成本 = n × 贵操作，链越长越惨。对策：接单判断只用内存里的便宜规则（门槛、类型 tag），贵的操作放在确定接单之后。
2. **环数要克制**。十环链的最坏穿链是十次虚调用——虚调用本身不贵，但**调用栈深度与调试跟踪成本线性增长**。超过一打的线性分档，说明分档逻辑该改成表（按上限二分查找直接定位审批人，O(log n) 一次定位）。

虚调用成本本身在多数业务里可忽略，真正的性能杀手是判断里的 IO——这也回到陷阱 4 的同一对策。

## 测试策略

责任链的可测性来自它的三个可拆点：

- **单环测试**：`Manager().handle(900)`、`Manager().handle(3000)` 各自独立可测——不必搭整条链。本例 `handle` 的三分支中，"传给下家"那支在单环测试里表现为"无下家返回 rejected"，恰好覆盖了边界。
- **全链测试**：装配一条完整链，对每个分档值断言结果（900/3000/99999/200000 四个点，本例 main 全部覆盖）。分档边界值（恰好 1000、恰好 1001）值得补测——`<=` 还是 `<` 是这类代码的经典 off-by-one。
- **装配测试**：链断了的陷阱（陷阱 1）靠"装配函数返回链长"或断言链尾可达来防。装配集中在一个 `make_chain()` 工厂里，测试断言其返回结构的环数。

## 陷阱清单

1. **链断了没人知道**（现象：某环 `set_next` 忘调，请求走到中间就 `rejected`；原因：装配零散；后果：偶发的"没人处理"，排查困难。对策：装配集中在一个函数/工厂里，装配后断言链长或写注册表式构建）。
2. **环环相扣成环**（现象：A 的 next 是 B、B 的 next 是 A；原因：动态改链手滑；后果：无限循环。对策：链只单向构建不改，或者装配器里做环检测）。
3. **每环都处理但没人收尾**（现象：把"每环都加工"的流程写成责任链；原因：与装饰混淆；后果：请求被第一个接单者截停，后面的环节全跳过——与预期加工流程不符。对策：回到装饰/责任链分界，加工用装饰）。
4. **链上做重查询**（现象：每环 `handle` 先查数据库判断接不接；原因：接单判断本身昂贵；后果：穿链成本 = 环数 × 查询成本。对策：接单判断用便宜的内存规则（门槛表、类型 tag），贵的操作只在确定接单后做——本例 `limit()` 是常量的原因）。
5. **没有"无人处理"的预案**（现象：调用方假设总有结果；原因：忽略 GoF 列出的"可能无人处理"；后果：链尾静默丢弃请求。对策：默认策略显式化（本例返回 rejected），或链尾挂一个兜底环）。

## 三书对应

- 之禅：第 16 章"责任链模式"（16.2 定义、16.3 应用——三男追女的比喻：请求在追求者之间传递、16.4 最佳实践）。
- 刘伟：第 17 章"职责链模式"（17.1 动机与定义、17.2 结构与分析——纯/不纯的职责链之分（不纯者可部分处理再传）、17.3 实例——请假审批、17.5 扩展——与组合模式配合构成"树状职责链"）。
- GoF：第 5 章 5.1 节 Chain of Responsibility——HelpHandler 例（帮助事件沿控件链上浮），"实现"节讨论"链的形状（线性/树/图）、谁维护后继、请求显式传参 vs 基类已知"。

*可选延伸：可运行示例见 examples/18_chainofresp/。*

---

上一章：[17 代理](17-proxy.md) · 下一章：[19 命令](19-command.md)
