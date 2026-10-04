# 26 · 策略

上一章结尾给了状态与策略的三条判据，本章正面讲策略自己。GoF 5.9 节的定义：**定义一系列的算法，把它们一个个封装起来，并且使它们可互相替换。本模式使得算法可独立于使用它的客户而变化**。关键词是"封装 + 替换 + 独立变化"——收银台不知道明天会发明什么新折扣，它只知道"有个东西能对原价算出应付价"。

## 意图与动机

结账逻辑：不打折、打 8 折、满 200 减 30。朴素写法把三种规则塞进一个函数：

```cpp
double checkout(int type, double origin) {
    if (type == 0) return origin;
    if (type == 1) return origin * 0.8;
    if (type == 2) return origin >= 200 ? origin - 30 : origin;
}
```

三个问题：加一种折扣改收银台（回改成本）；type 的语义全靠注释（魔法数字）；同一规则若在退款、对账两个入口出现要抄两份。策略把每条规则做成对象，收银台只收"Discount&"——**规则自己会算，收银台只会调用**。之禅 18 章的比喻妙在"锦囊"：诸葛亮给赵云三个锦囊（三个策略对象），按情况拆开执行（运行期选择），赵云不需要懂计谋内容（封装）。

## 经典写法：折扣族

示例 `strategy.hpp`。抽象策略与三个实现：

```cpp
// Strategy：抽象折扣。
struct Discount {
    virtual ~Discount() = default;
    [[nodiscard]] virtual double apply(double origin) const = 0;
};

struct NoDiscount final : Discount {
    [[nodiscard]] double apply(double origin) const override { return origin; }
};

struct PercentDiscount final : Discount {
    explicit PercentDiscount(double pct) : pct_(pct) {}
    [[nodiscard]] double apply(double origin) const override {
        return origin * (1.0 - pct_ / 100.0);
    }

private:
    double pct_;                     // 有状态：策略对象携带自己的参数
};

struct ThresholdDiscount final : Discount {
    [[nodiscard]] double apply(double origin) const override {
        return origin >= 200.0 ? origin - 30.0 : origin;   // 满 200 减 30
    }
};
```

Context 是一个函数——策略模式的 Context 未必是类，**"只认抽象、不认实现"的一个函数就够了**：

```cpp
// Context：结算函数——只认 Discount&，具体算法运行期才绑定。
inline double checkout(const Discount& d, double origin) { return d.apply(origin); }
```

运行侧（`main.cpp`）：

```cpp
const NoDiscount none;
const PercentDiscount p20(20.0);            // 打 8 折
const ThresholdDiscount thresh;             // 满 200 减 30

assert(checkout(none, 100.0) == 100.0);
assert(checkout(p20, 100.0) == 80.0);
assert(checkout(thresh, 100.0) == 100.0);   // 不达 200 门槛
assert(checkout(p20, 260.0) == 208.0);
assert(checkout(thresh, 260.0) == 230.0);
```

运行输出：

```text
策略: 100 元 -> 100 / 80 / 100（门槛不触发）
策略: 260 元 -> 8折 208 / 满减 230
function: 五个点与虚函数版逐点同值
concepts: checkout_fast 静态分发结果一致（无虚表）
```

五个断言点：100 元三种折扣 100/80/100（门槛不触发的**拒绝分支**被显式测到——不达门槛原价返回与"不打折"同值但语义不同），260 元两种 208/230。`PercentDiscount` 带 `pct_` 参数这一笔是策略与闭包分界的前哨：**策略可以是有状态的一等公民**，参数在构造期冻结。

## 模式结构（ASCII 图）

```text
   checkout(d, origin) ──d.apply(origin)──> Discount (Strategy)
                                             +apply(origin)=0
                                    ┌──────────┼──────────────┐
                               NoDiscount  PercentDiscount  ThresholdDiscount
                               （参数有无各不相同——族内可以不对称）
```

GoF 三角色：Strategy（接口）、ConcreteStrategy ×3、Context（checkout）。与第 25 章状态图的差异在箭头方向：**没有任何一块箭头从策略指回策略**——算法之间互不知晓；而状态图里状态类握着 Context 引用往下一站推。

## 现代写法一：function 策略

```cpp
using DiscountFn = std::function<double(double)>;

const DiscountFn fn_none = [](double o) { return o; };
const DiscountFn fn_p20 = [](double o) { return o * 0.80; };
const DiscountFn fn_thresh = [](double o) { return o >= 200.0 ? o - 30.0 : o; };
```

五点断言与虚函数版逐点同值（运行输出第三行）——**两种形态在数学上完全等价**，差别只在机制（虚表 vs 闭包）与表达力边界：lambda 写"满 200 减 30"绰绰有余；但如果折扣要带历史（"本月第三次下单减 10"），闭包得捕获可变状态，生命周期与并发安全立刻复杂化——**有状态策略仍以对象为宜**，对象把状态与不变式圈在自己的类里。

## 现代写法二：concepts 静态分发

运行期选择折扣用 function；**编译期就知道用哪个**的场景，concepts 把虚调用降为零：

```cpp
// 双形态 concept：类策略走 .apply(o)，闭包走 operator()——析取收编两形态。
// （单一 `{ f(o) }` 写法对类策略不成立：类没有 operator()。）
template <typename F>
concept DiscountLike =
    requires(const F& f, double o) { { f.apply(o) } -> std::convertible_to<double>; } ||
    requires(const F& f, double o) { { f(o) } -> std::convertible_to<double>; };

template <DiscountLike F>
[[nodiscard]] double checkout_fast(const F& f, double origin) {
    if constexpr (requires { f.apply(origin); }) return f.apply(origin);
    else return f(origin);           // 闭包：operator() 直调
}
```

这里埋了一个实测教训：**concept 的单一形态 `{ f(o) }` 写法对类策略不成立**——`f(o)` 要求 `operator()`，`PercentDiscount` 没有；而且实测（MSVC 18）把这种 concept 写在析取里时，孤立的 `{ f(o) } -> convertible_to` 简单形态还出现过"对无 operator() 的类返回 true"的误判（requires 表达式的顺序相关 bug），`.apply` 优先的双形态是实测后站得住的写法。`static_assert(DiscountLike<PercentDiscount>)` 与 `DiscountLike<decltype(fn_p20)>` 双双通过——类与闭包被同一 concept 收编（运行输出第四行验证静态分发结果一致）。取舍：`checkout_fast` 换来零虚表、可内联，代价是**算法选择从运行期参数变成编译期类型**——促销活动这种"用户点哪个用哪个"的场景必须运行期，function 版是正解；模板库内部的策略点（排序器的比较器）用 concepts 是常态——`std::sort` 的 Compare 参数就是这条路的工业级先例。

## 策略表：运行期装配的形态

多个折扣同时在场、按条件选用时，"选择"本身需要一个容器——最诚实的形态是**策略表**（名字 → 策略对象）：

```cpp
// 装配点：规则集中一处，Context 与调用方都不见选择逻辑
std::map<std::string, DiscountFn> policies = {
    {"none",    fn_none},
    {"member",  fn_p20},
    {"promo",   fn_thresh},
};

double pay = checkout(*policies.at("member"), 260.0);   // 虚版同理：map<string, unique_ptr<Discount>>
```

装配表回答了"谁选策略"（陷阱 1）的落地问题：**选择逻辑收敛到一个 map 的初始化处**——配置文件加载、运营后台开关，最终都落成往这张表里放对象。加策略 = 表里加一行；改生效策略 = 换 key。与第 18 章责任链的表驱动版对照：策略表按**名字查找一次**（互斥选择），责任链表按**顺序尝试**（首个接单者胜出）——都是表，搜索结构不同：map 是点查，vector 是线性扫。

## 与工厂方法、简单工厂的分工

之禅 18.4 点名了策略与简单工厂的常见合体，这里把三者分工说清：

- **策略**管"一族算法怎么封装互换"——本章主体。
- **简单工厂**管"从参数造出哪个策略"——`make_discount("percent", 20)` 返回 `unique_ptr<Discount>`，把 `if/else 选类型` 的知识圈在工厂一处。
- **工厂方法**（第 6 章）管"把造哪种的**决定权**再下放给子类"——只有"由谁决定造什么"本身是变化点时才升级到它。

促销系统的典型分工：工厂从运营配置造策略（简单工厂）→ 收银台只认 `Discount&`（策略）→ 折扣之间互不知晓。三者叠加后，加一种新折扣的唯一改动点是：新策略类 + 工厂表一行 + 运营配置——调用链全程零改动。

## 测试策略

折扣算法可测性极好，值得单独给一节：

- **逐策略定点断言**：每个策略对已知输入的精确输出（本例五个断言点）。门槛类规则必须测**门槛两侧**（199/200/201）——`>=` 与 `>` 的边界错在这里现形。
- **同点跨形态对拍**：虚版与 function 版、虚版与 concepts 版在同一组输入上逐点比对（本例全部如此）——三形态互为测试预言。
- **组合不搭界**：断言策略之间互不干扰（none 不影响 p20 的结果）——策略隔离性是模式承诺，测它就是测模式本身。
- **concepts 约束自身**：`static_assert` 进测试（本例对 PercentDiscount 与 lambda 各一条）——concept 的满足性是编译期事实，用断言把它钉进回归，防止日后改 concept 定义时静默收编或漏收。

## 何时不用策略

策略也有不值当的信号，与第 28 章访问者的"不值得"清单同一笔法：**算法只有两个且永远不会第三个**——if/else 两行更诚实，抽象要为第三个实现才有回报；**算法是纯参数差异**——`origin * (1.0 - rate)` 与 `origin - fixed` 都能用一个 `Discount(double)` 参数化时，别造类层次，参数化解决；**选择逻辑本身需要编排**——折扣叠加（先会员 8 折再满减）时，单个策略装不下，该考虑的是组合子/责任链（或干脆的管道）。策略的甜区判据不变：算法族成员**持续增长**、彼此**结构异质**（参数化装不下）、客户**不应知道**族内细节。

## 与状态的正面区分（回看第 25 章）

第 25 章给过三条判据，这里落到折扣场景验证一遍：**切换谁决定**——收银台选折扣（外部选择）是策略；若"用完一次自动升级为下一档折扣"是内部演化，那是状态。**实现知不知道彼此**——三种折扣互不引用；售货机的 HasCredit 明确知道下一站是 Dispensing。**切换频率**——折扣按订单选定后不变；售货机每个事件都可能换态。三条判据指向同一侧时用策略，指向另一侧时用状态。

## 陷阱清单

1. **Context 退化成 switch 分发**（现象：`checkout(type)` 里 switch 选策略；原因：策略对象没建起来，只抽了算法没抽选择；后果：加策略改 Context，白抽。对策：选择逻辑上移到装配点（构造/工厂/配置），Context 只持一个抽象引用）。
2. **策略泄漏到调用点**（现象：调用方 `if (dynamic_cast<PercentDiscount*>(&d))` 特判；原因：某个策略需要特殊参数；后果：抽象名存实亡，加策略处处改。对策：特殊需求变成策略自己的构造参数（`pct_` 就是这么处理的），或重新审视接口是否缺方法）。
3. **无状态假设被打破**（现象：策略对象里加了 `mutable int count_` 计下单次数，多线程下炸；原因：策略常被当无状态共享单例；后果：数据竞争。对策：策略要么明确不可变（文档写明），要么每次用 freshly 构造的实例——别在共享单例上攒状态）。
4. **lambda 策略捕获悬空**（现象：lambda 捕获局部变量引用，存进策略表后调用方栈已退；原因：闭包生命周期超出捕获物；后果：UB。对策：function 策略表只存不捕获或捕获值/智能指针；捕获引用的 lambda 只允许同步短命使用）。
5. **concepts 版把运行期选择硬编译**（现象：促销规则要运营配置，却写成了模板参数；原因：把"编译期能定"和"必须运行期定"混为一谈；后果：改个规则要重编译发版。对策：先问选择权在谁手里——编译期（模板/概念）还是运行期（虚函数/function），答案不同形态就不同）。

## 三书对应

- 之禅：第 18 章"策略模式"（18.1 刘备江东娶妻——诸葛亮三个锦囊妙计，"三个妙计应该实现的是同一个接口"正是抽象策略的直觉来源、18.2 定义、18.3 应用、18.4 扩展——策略与简单工厂的结合：工厂负责选、策略负责算）。
- 刘伟：第 25 章"策略模式"（25.1 动机与定义、25.2 结构与分析——环境类 Context 的作用、25.3 实例——排序策略（25.3.1）/旅游出行策略（25.3.2）、25.4 效果与应用、25.5 扩展——策略与状态/简单工厂的对比）。
- GoF：第 5 章 5.9 节 Strategy——"实现"节讨论"Strategy 与 Context 的接口（Context 传多少数据给策略——胖接口 vs 窄接口+Context 自引用）、Strategy 作为模板参数（本章 concepts 版的原型）、可选的 Strategy 对象（默认策略 + 可替换）"。

*可选延伸：可运行示例见 examples/26_strategy/。*
