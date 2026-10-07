# 25 · 状态

策略（第 26 章）和状态长着同一张类图——都是"接口 + 一组可替换的实现 + Context 持有其一"，GoF 甚至在相关模式一节直接点名二者是孪生。分界在**意图**：策略让客户**选择**算法（选择权在客户，运行期不常换），状态让对象**随内部状态改变行为**（状态自己决定下一个状态，切换频繁且自动）。本章用自动售货机把"状态自己驱动切换"这个状态模式独有的性质讲透。GoF 5.8 节的定义：**允许一个对象在其内部状态改变时改变它的行为，对象看起来似乎修改了它的类**。

## 意图与动机

自动售货机的规则：待机时投币记账，投足 25 分摇把手出货，出货完余款保留、回到可出货或待机。朴素写法是一个状态枚举 + 到处散落的 switch：

```cpp
std::string Machine::coin(int v) {
    switch (state_) {
        case State::Idle:     /* 记账、换态 */ break;
        case State::HasCredit: /* 记账 */ break;
        case State::Dispensing: /* 拒绝 */ break;
    }
}
```

每个事件处理函数都要写一遍全集 switch，加一个状态（比如"故障"）要改所有事件函数——**状态知识散落在每个行为里**。状态模式把每个状态做成类：加状态 = 加类，改某个状态的行为只动那个类；而且**"投完币该去哪个状态"这条转移知识归 HasCredit 自己管**，不再由 Machine 的 switch 代劳。

## 经典写法：自动售货机

示例 `state.hpp`。抽象状态与环境：

```cpp
// State：抽象状态——两事件（coin/crank）+ 过态标记。
struct State {
    virtual ~State() = default;
    virtual std::string coin(Machine& m, int v) = 0;
    virtual std::string crank(Machine& m) = 0;
    virtual bool transient() const { return false; }   // 瞬时态：事件结算后自动退出
    virtual std::string name() const = 0;
};

class Machine {
public:
    std::string coin(int v) {
        std::string msg = state_->coin(*this, v);
        settle();                     // 出货中的瞬时态就地结算
        return msg;
    }
    std::string crank() {
        std::string msg = state_->crank(*this);
        settle();
        return msg;
    }
    void add_credit(int v) { credit_ += v; }
    void take_25() { credit_ -= 25; }
    void to(std::unique_ptr<State> s) { state_ = std::move(s); }
};
```

两个细节值得停留。**第一，状态方法收 `Machine&`**——状态对象要读写环境的余额、要调用 `to()` 换态，这是 GoF 说的"状态对象封装环境角色以实现状态切换"：换态的能力交给了状态类自己。**第二，`settle()` 与瞬时态**：`Dispensing`（出货中）建模物理上的一个瞬间——投币摇杆后机器吐罐，下一个事件到来时机器已经在正常服务了。让 `Dispensing` 参与"等待下一个事件"会把"wait"消息泄漏给调用方，所以在每个事件处理末尾用 `transient()` 标记就地结算：

```cpp
// 具体状态：每个状态管"本状态的行为"和"趋向哪个状态"。
inline std::string HasCredit::crank(Machine& m) {
    if (m.credit() < 25) return "need more credit";   // 余额不足：不出货、不换态
    m.take_25();
    m.to(std::make_unique<Dispensing>());
    return "dispense";
}

inline void Machine::settle() {
    if (state_->transient()) {
        // 出货完：余款够一罐回到 HasCredit，否则回 Idle
        if (credit_ >= 25) to(std::make_unique<HasCredit>());
        else               to(std::make_unique<Idle>());
    }
}
```

`HasCredit::crank` 三个分支各司其职：不足拒绝（**状态不变**——这是新手最常漏的一支）、够则出货并把状态推向 `Dispensing`。"趋向状态处理"（刘伟 24.2 的术语）就是这行 `to(make_unique<Dispensing>())`——转移知识在状态类里，不在环境里。运行侧（`main.cpp`）：

```cpp
Machine m;
assert(m.coin(25) == "credited 25" && m.state_name() == "has_credit");
assert(m.crank() == "dispense");
assert(m.state_name() == "idle" && m.credit() == 0);    // 出货后回 idle
```

运行输出：

```text
状态: coin(25)->crank->dispense，出货后回 idle
状态: 余额 10 不足一罐，crank 提示
状态: 余款 25 跨罐保留在 has_credit
variant: 全序列与经典版逐事件同输出
```

断言覆盖三条路径：完整序列 `coin(25) → crank → "dispense" → 回 idle`；余额 10 不足一罐时 crank 提示且状态不动；投两罐余款 50、出货一次后余款 25 保留在 `has_credit`（settle 的余款分支）。

## 模式结构（ASCII 图）

```text
                 ┌────────────────────────────┐
                 │ Machine (Context)          │
                 │ coin(v) / crank()          │──state_->事件──┐
                 │ credit_ + to(unique_ptr)   │<───────────────┘
                 └──────────┬─────────────────┘        状态类持 Machine&
                            │ 持有
                            ▼
                    State（抽象状态）
                   coin / crank / transient
                   ┌────────┼──────────┐
                 Idle   HasCredit   Dispensing
                        │  余额<25 → 不动
                        │  余额≥25 → to(Dispensing)        （转移知识在状态里）
                        └──────────────────────────────→
```

与策略图（第 26 章）的差别一眼可见：策略的 Context 通常提供 `set_strategy()` 给**客户**换算法；状态的 Context 换态权**不在客户手里**——`to()` 只被状态类自己调用。这就是"谁驱动切换"的图上证据。

## 现代写法：variant 状态机

三个状态装进 variant，事件处理 = visit 按备选项分支（`variant_state.hpp`）：

```cpp
struct IdleS {}; struct HasCreditS {}; struct DispensingS {};
using StateV = std::variant<IdleS, HasCreditS, DispensingS>;

std::string crank() {
    std::string msg;
    StateV next = std::visit([&](auto& s) -> StateV {
        using T = std::decay_t<decltype(s)>;
        if constexpr (std::is_same_v<T, IdleS>) {
            msg = "need 25 first";
            return s;
        } else if constexpr (std::is_same_v<T, HasCreditS>) {
            if (credit_ < 25) {                     // 余额不足：不出货、不换态
                msg = "need more credit";
                return s;
            }
            credit_ -= 25;
            msg = "dispense";
            return StateV{DispensingS{}};
        } else { return s; }                        // DispensingS
    }, state_);
    state_ = std::move(next);                       // visit 结束后才能写 state_
    settle();
    return msg;
}
```

有一个坑值得单独讲：**新状态不能在 visit 里直接赋给 `state_`**。visit 的 visitor 参数绑定着当前备选项，visit 进行中改写 variant 会销毁正绑定的对象（UB）。所以这里让 visitor **返回**新状态，visit 结束后再赋回——"转移作为返回值"恰好也是函数式状态机的标准形态。exhaustive 收益：三态的 visit 里 `if constexpr` 链覆盖所有备选项，新增状态时遗漏的分支会在编译期暴露（相比继承版"新增状态类自然无法被旧代码调用"是不同方向的保险——variant 保操作者，继承保类型作者）。运行输出第四行钉死两形态逐事件同输出。

## 状态表 vs 状态对象

教科书之外还有第三条路：**二维转换表**（状态 × 事件 → 新状态）。它把全部转移知识集中成一张可打印、可验证的表，适合状态数与事件数都小而转移规则规则性强的场景：

| | coin | crank |
|---|---|---|
| Idle | →HasCredit 记账 | 拒绝 |
| HasCredit | 记账 | 余额≥25 →Dispensing 出货 / 不足拒绝 |
| Dispensing | （瞬时态，settle 结算） | 同左 |

三形态取舍：**状态对象**（本章经典）适合每状态行为复杂、独立演化的场景——类的体量配得上状态复杂度；**variant** 适合状态少、行为薄（都是一两行）的状态机——visit 一处写完，无堆分配；**转换表** 适合转移规则完全规则化、需要可视化审查的状态机。售货机这个体量，variant 版其实是最诚实的——三态各一两行，类外壳是纯开销。真实售货机固件（含错误态、投币器故障、找零）状态上十，类形态的状态模式才开始挣回成本。

## 与策略的正面区分（第 26 章预告）

类图相同，判据三条：**切换谁决定**（策略：客户；状态：状态自身）、**实现知不知道彼此**（策略：各算法互不知晓；状态：常常知道流转的下一站）、**切换频率**（策略：配置时定好基本不变；状态：每次事件都可能换）。同一份代码从策略视角读是"选折扣算法"，从状态视角读是"售货机流转"——模式不是代码形状，是**变化的方向**：变化由外部选择是策略，变化由内部演化是状态。

## 状态机的测试法

状态机是测试性价比最高的对象——转移规则有限且封闭，可以逐格覆盖：

- **转移正路径**：每个"状态 × 事件 → 新状态"格子至少一条序列测到（本例 idle+coin、has_credit+crank、has_credit+coin、dispensing 结算四格全覆盖）。
- **拒绝分支**：每个格子的"不动"分支单独测（idle+crank 提示、has_credit+crank 余额不足提示）——拒绝分支的状态不变性要断言两次（事件前后 `state_name()` 相同）。
- **瞬时态边界**：settle 的两个出口都要走到（余款归 Idle / 余款归 HasCredit，本例第三段"跨罐保留"专测后者）。
- **双形态一致性**：经典版与 variant 版跑**同一条事件序列**逐事件比对输出与状态名（本例 main 的 variant 段）——两形态互为对方的测试预言，一份序列养两份实现。

## 陷阱清单

1. **漏"状态不变"分支**（现象：余额不足时也走了出货逻辑或清了余额；原因：只写了正常转移路径；后果：负余额/白出货。对策：每个事件的"拒绝且不动"分支显式写（本例 `need more credit` 直接 return），状态机评审逐格过转换表）。
2. **状态对象忘记读写环境的通道**（现象：状态类想做转移却拿不到 `to()`；原因：方法签名没收 `Machine&`；后果：转移逻辑被迫搬回环境类，模式退化成 switch。对策：状态方法一律收 Context 引用（GoF 的参数化方式），或状态持 Context 引用——本例选传参，职责显式）。
3. **瞬时态泄漏给调用方**（现象：调用方收到 "wait" 消息、还得再摇一次把手；原因：把 Dispensing 当普通状态等下一个事件；后果：协议变复杂、测试翻倍。对策：瞬时态 + settle 就地结算（本例 `transient()` 标记），或干脆并入 HasCredit::crank 一步完成）。
4. **visit 中改写被访问的 variant**（现象：状态机随机崩溃/备选项销毁；原因：visit 进行中给 variant 赋新值销毁了 visitor 绑定的备选项；后果：UB。对策：转移值由 visitor 返回、visit 结束后赋回（本例 `StateV next = std::visit(...); state_ = std::move(next);`））。
5. **状态机没有"非法事件"日志**（现象：生产环境收到意外事件序列静默忽略；原因：拒绝分支只返回不记录；后果：故障无从排查。对策：拒绝路径留痕（日志/计数器），状态机的可观测性与转移逻辑同权重）。

## 三书对应

- 之禅：第 26 章"状态模式"（26.2 定义——"允许一个对象在其内部状态改变时改变它的行为"、三角色"抽象状态/具体状态/环境角色"的职责划分、"本状态的行为管理以及趋向状态处理"的表述出自这里、26.3 应用——电梯状态流转的例子（开/关/运行/停止 + 紧急/维修）、26.3.4 注意事项——"对象的状态最好不要超过 5 个"，26.4 最佳实践——与建造者模式组合按场景重组状态序列）。
- 刘伟：第 24 章"状态模式"（24.1 动机与定义、24.2 结构与分析、24.3 实例——论坛用户等级（24.3.1）/银行账户（24.3.2）、24.4 效果与应用、24.5 扩展——共享状态（与环境类结合））。
- GoF：第 5 章 5.8 节 State——TCPConnection 例（TCP 建立连接/监听/关闭三态，"实现"节讨论"谁定义状态转换（表驱动 vs 状态对象）、状态对象的创建与销毁（按需/预建）"——本章转换表一节与瞬时态讨论的源头）。

*可选延伸：可运行示例见 examples/25_state/。*

---

上一章：[24 观察者](24-observer.md) · 下一章：[26 策略](26-strategy.md)
