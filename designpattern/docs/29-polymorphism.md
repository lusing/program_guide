# 29 · 多态的三副面孔

GoF 篇收官之后的第一章，走出现代 23 模式清单，回答一个更底层的问题：**"对同一批调用者呈现统一接口"这件事，C++ 到底给了几种机制**。三种机制是虚函数、concepts、variant——它们不是同一模式的三个变体，而是三份取舍完全不同的合同：虚函数在运行期分派、类型集合开放；concepts 在编译期分派、异构集合写死在调用表达式里；variant 在两者之间，用封闭集合换一跳跳转表。本章用同一个 Drawable 场景把三版写齐、断言到逐字符一致，再把"什么时候选哪个"钉成一张表。

## 意图与动机

一批形状（正方形 Sq、圆 Ci）要支持同一个操作 draw：把自己画进一个字符串。客户手里有一个容器，想一次遍历把所有形状画出来，输出 `sq;ci`。这个需求有三种满足方式：**容器里放基类指针**（虚函数）、**每个类型调一份模板函数**（concepts）、**容器里放 variant**（闭集分派）。三者的输出合同完全一致，差别全部在"谁能混进容器、分派发生在何时、加一个新形状要动谁"。把这三条线拉直，后面 30 章（类型擦除）与 31-32 章（策略/观察者的现代形态）才有着陆点——它们全是这三副面孔的组合运用。

## 经典写法：虚函数

示例 `virtual_poly.hpp`。抽象接口与两个形状：

```cpp
// 抽象接口：draw 把自己的名字追加到 out。
struct Drawable {
    virtual ~Drawable() = default;
    virtual void draw(std::string& out) const = 0;
};

struct Sq final : Drawable {
    void draw(std::string& out) const override {
        if (!out.empty()) out += ';';   // 追加式合同：分隔符由"先来者"负责
        out += "sq";
    }
};
struct Ci final : Drawable { /* 同构，追加 "ci"，略 */ };

// 运行期多态：异构容器（unique_ptr<Drawable>），虚表分派。
inline std::string render(const std::vector<std::unique_ptr<Drawable>>& v) {
    std::string out;
    for (const auto& d : v) d->draw(out);
    return out;
}
```

虚函数版的本质特征有两条。第一，**类型集合开放**：任何编译单元里的任何代码都能写 `struct X : Drawable`，X 立刻就能进容器——扩展性跨动态库都成立（第 35 章插件系统就靠这一点）。第二，**分派在运行期**：`d->draw(out)` 每次循环查一次虚表，编译器无法内联（除非去虚化证明类型唯一）。代价随之而来：对象必须堆上经指针持有、每个类型一张虚表、调用无法内联。

## 模式结构（三版合同对照）

```text
   合同（三版共用）：draw(std::string&) 把名字追加进 out；render 返回 "sq;ci"

   虚函数版   vector<unique_ptr<Drawable>> ──虚表──> Sq::draw / Ci::draw
              类型集合：开放（任何 : Drawable 的派生类）
              分派时点：运行期（每次调用查虚表）

   concepts版 render<Sq> / render<Ci> 两份实例化（每类型一份机器码）
              类型集合：开放（满足 DrawableLike 即可），但一次调用的容器是同质的
              分派时点：编译期（直接调用，可内联）

   variant版  vector<AnyShape=variant<Sq,Ci>> ──visit──> 跳转表
              类型集合：封闭（写死在 using 里）
              分派时点：运行期（一跳，编译器可生成跳转表）
```

## 现代写法一：concepts

示例 `concept_poly.hpp`。合同写成 concept，render 按类型实例化：

```cpp
template <typename D>
concept DrawableLike = requires(const D& d, std::string& out) {
    d.draw(out);
};

// 每个具体类型 D 实例化一份 render——"sq" 与 "ci" 各得一份机器码。
template <DrawableLike D>
inline std::string render(std::span<const D> v) {
    std::string out;
    for (const auto& d : v) d.draw(out);
    return out;
}
```

关键限制立刻浮出水面：`span<const D>` 是**同质**的——一个 vector 里装不了 Sq 和 Ci 两种值类型。要混排，只能在编译期把类型集合写进调用表达式：

```cpp
// 编译期混排：类型集合作为参数包在调用点展开——同一份输出合同。
template <DrawableLike... Ds>
inline std::string render_pack(const Ds&... ds) {
    std::string out;
    (ds.draw(out), ...);
    return out;
}
```

运行侧（`main.cpp`）把两幅面孔钉在断言上：

```cpp
const Sq s1{}, s2{};
const Ci c1{}, c2{};
std::string out = render(std::span{sqs});   // 实例化 render<Sq>
out += render(std::span{cis});              // 实例化 render<Ci>，再拼
assert(out == "sq;sqci;ci");                // 分段各自接续：段间分隔符客户自理

assert(render_pack(Sq{}, Ci{}) == "sq;ci"); // 参数包混排：输出与虚函数版逐字符一致
```

第一段断言是本版最重要的教学点：分段拼接得到 `sq;sqci;ci` 而不是 `sq;ci`——**分隔符协议在异构边界上失效了**，因为两次 render 调用各自持有独立的 out，段与段之间没有任何协调。concepts 版不是"更先进的虚函数"，它是另一份合同：类型集合在调用点冻结、容器同质、跨类型编排靠客户。

## 现代写法二：variant

示例 `variant_poly.hpp`。封闭集合 + 一跳分派：

```cpp
using AnyShape = std::variant<Sq, Ci>;

inline std::string render(const std::vector<AnyShape>& v) {
    std::string out;
    for (const auto& s : v) {
        std::visit([&](const auto& d) { d.draw(out); }, s);
    }
    return out;
}
```

variant 版两头占：**异构容器**（`vector<AnyShape>` 与虚函数版一样一次 render 得到 `sq;ci`）加**内联潜力**（visit 生成跳转表，编译器比两跳虚表优化得好）。代价是**封闭性**：`Sq, Ci` 写死在 using 里，加形状改这一行——好在改漏了会编译报错（visit 的 lambda 没覆盖到新备选项时），封闭换来了 exhaustive 检查。运行输出：

```text
虚函数: 异构容器一次 render -> sq;ci
concepts: render<Sq>/render<Ci> 两份实例化，分段拼接
concepts: render_pack 编译期混排 -> sq;ci
variant: 封闭集合混合容器一次 render -> sq;ci
```

## 三栏对比：三版到底差在哪

| | 虚函数 | concepts | variant |
|---|---|---|---|
| 实例化数量 | render 一份，调用方间接分派 | **每类型一份** render\<D\>；用得越多二进制里的代码越多 | render 一份，visit 生成跳转表 |
| 错误信息质量 | 派生类漏 override 编译期报错；接口不合报在类定义处 | **最差**：concept 不满足时错误落在调用点，模板展开层层叠叠，初学者最难读 | 加形状漏 visit 报在使用处，信息中等偏可读 |
| 二进制体积 | 最小代码膨胀，但每类一张虚表 + RTTI | 每类型一份实例化，类型多时体积最大；换来零虚表零 RTTI | 介于两者：一份 render + variant 自身的存储开销 |
| 类型集合 | 开放，跨编译单元/动态库 | 开放但每次调用冻结 | 封闭，加类型改 using |
| 分派成本 | 两级内存访问（vptr→虚表→函数） | 零（直接调用，可内联） | 一跳跳转表 |

表里的三行——实例化数量、错误信息质量、二进制体积——正是选型的判据，展开说：**实例化数量**决定编译时间与代码体积的斜率，形状类型越多 concepts 版越亏；**错误信息质量**决定团队维护成本，concepts 版的失败信息在深层模板里，variant 版漏覆盖在 visit 处、虚函数版漏 override 在类定义处，都更容易定位；**二进制体积**上虚函数最省、concepts 最费，但嵌入式/热路径场景 concepts 换来的内联可能反过来缩小体积。所以结论按场景给：**接口要跨库稳定、类型集合开放 → 虚函数；类型集合封闭且追求分派速度与 exhaustive 检查 → variant；类型集合编译期已知、追求零运行期开销 → concepts**。三者不互相取代，30 章的类型擦除会把"虚函数 + concepts"合体成第四种答案。

## 选型流程：三问定版

把结论压缩成可执行的决策序列，三个问题按序问下来。**第一问：类型集合在运行期才知道吗？**——容器内容来自配置、用户输入、插件注册（第 35 章），编译期无从枚举：concepts 版直接出局，在虚函数与 variant 里选。**第二问：类型集合会增长吗？**——会加新形状且加的人不止你一个：选虚函数，开放扩展是它独有的能力；集合冻结、加类型必改 using 可接受：选 variant，白得 exhaustive 检查。**第三问（对纯编译期场景）：类型在调用表达式里全部写得出吗？**——写得出且追求零开销：concepts + 参数包（`render_pack`）；写不出（容器来自运行期逻辑）：回到前两问。三问全走完仍两可的场景（集合冻结、追求性能、又想留扩展口），默认选 variant——它的错误信息质量和 exhaustive 检查在维护期的收益，比虚函数的"理论开放性"实在；真要开放时，改回虚函数版的改动是局部的（容器元素类型从 AnyShape 换成 unique_ptr<Drawable>），反向改动同理——**形态切换的成本被三版共用的 Sq/Ci/draw 合同压到了最低**，这也是本章坚持三版同合同的原因之一。

## 错误信息的实际长相

三栏表把"错误信息质量"排进了选型判据，这里把三种失败的实际长相摆出来，理由会变得具体。**虚函数版**的典型失败：派生类写了 `void draw(std::string&)` 漏了 const——MSVC 给出 C2678"没有找到接受左值的运算符或重载"，错误落在**派生类的成员函数声明处**，一行定位；基类纯虚未实现则报 C2259"不能实例化抽象类"，同样指名道姓。**concepts 版**的典型失败：某类型缺 id()，错误落在**调用点**——模板实例化链条上每个参与的函数签名都会被打印出来（MSVC 的模板诊断瀑布动辄几十行），真正的错因（"约束未满足：d.id()"）埋在链条深处；concept 表达式越复杂，翻译成"缺什么"的难度越高。**variant 版**的典型失败：加形状后 visit 的 lambda 组没覆盖新备选项——编译器报"没有匹配的重载"且**指向 visit 调用点**，配合备选项列表一对照就懂；好在失败的形态是"缺一个 lambda"，补上即过。维护期的经验值：**失败的报错位置比报错内容更重要**——虚函数版报在类定义处（写类型的人看到）、variant 版报在 visit 处（用类型的人看到）、concepts 版报在实例化深处（最远）。团队里"改类型的人"和"写调用的人"若是同一批人，差距缩小；跨库分工时，这条往往是决定性的。

## 通往后续章节的路

三副面孔不是并列的三个知识点，而是后面四章的词汇表。**30 章类型擦除**是虚函数与 concepts 的合体：客户侧合同用 concept（继承约束消失）、内部分派用虚函数（外壳非模板）——三件套的每一件都能在本章找到出处（concept 来自本章、虚表来自经典写法、值语义外壳是 variant 值存储思想的延伸）。**31 章日志系统**把策略与观察者按两条线各写一遍：Sink 虚函数线是经典写法的直接运用，模板策略 + std::function 线是 concepts 版"零虚表"思想的落地。**32 章事件总线**是观察者的解耦终点，其 id 化订阅、闭包装载 handler 全部踩在 std::function 的擦除能力上。也就是说：**虚函数教的是"分派"，concepts 教的是"合同"，variant 教的是"封闭集合上的值语义多态"**——三个词此后反复出现，本章把它们一次讲透。读法建议：先把三份 hpp 对照着读一遍（同一个 draw 合同的三种表达，总共不到一百行），再看本章正文；示例 main 的四段断言按"虚函数 → concepts → variant"的顺序覆盖三版，双编译器输出逐字节一致。

## 陷阱清单

1. **把 concepts 版当"更好的虚函数"塞进异构容器**（现象：`vector<Sq>` 与 `vector<Ci>` 各写一遍循环，段间分隔符丢失；原因：模板对容器同质化；后果：输出合同悄悄改变。对策：先问"运行期集合还是编译期集合"，运行期就用虚函数或 variant）。
2. **基类析构不是 virtual**（现象：`delete base_ptr` 只析构基类部分，派生成员泄漏；原因：无虚析构则删除行为未定义；后果：内存损坏或泄漏。对策：接口类一律 `virtual ~Drawable() = default`，本例第一条就写它）。
3. **variant 的 visit 在 lambda 里改容器**（现象：visit 进行中向 vector 增删元素，程序崩或输出错乱；原因：visit 正在分派，改写集合可能触发元素重定位；后果：UB。对策：visit 返回新状态、visit 结束后再赋回——与第 25 章 variant 状态机同一纪律）。
4. **concepts 合同写得太宽**（现象：concept 只要求 `d.draw(out)`，某类型 draw 带副作用也能过编译，render 假设纯函数就错了；原因：concept 只查语法不查语义；后果：编译通过、语义违约。对策：concept 里写全期望的表达式形态，文档写明语义合同——"语法满足 ≠ 行为正确"）。
5. **切片（slicing）混入值语义容器**（现象：`vector<Drawable>`（非指针）push_back 派生类对象，只拷贝基类子对象，draw 输出空或崩；原因：值拷贝按静态类型裁切；后果：多态静默失效。对策：多态容器永远装 `unique_ptr<Base>` 或 variant，不装基类值）。

## 去虚化：虚函数版也有被"编译期化"的时候

三栏表把虚函数钉在"运行期分派"上，但有一个重要的例外值得单独说：**去虚化（devirtualization）**。当编译器能证明调用点的动态类型唯一时——派生类标了 `final`（本例 `struct Sq final : Drawable` 就是为此）、或调用发生在构造/析构函数内、或经过常量传播——虚调用会被直接替换成静态调用并内联，虚函数版的分派成本瞬间归零。这解释了两个常见现象：其一，`final` 不是文档装饰，它是给优化器的合同；其二，虚函数版在"容器里其实只有一种形状"的热路径上未必比 concepts 慢——前提是把类型封闭性告诉编译器。反过来，一旦容器真的混装（本例的常态），去虚化无从谈起，三栏表的分派成本差异就全额生效。选型时把这条记在心里：**三栏表比较的是"混装集合"的真实场景，单一类型的热循环另当别论**。

## 三版合同的公共条款

三种形态的 draw 合同能对拍到逐字符一致，靠的是几条从一开始就锁定的公共条款——它们同样适用于任何"多形态并存"的重构现场：

- **追加式输出**：draw 只往 out 里追加，不拥有、不清空 out——三版才能用同一个断言 `== "sq;ci"` 比对；
- **分隔符责任归"先来者"**：`if (!out.empty()) out += ';'` 写在每个 draw 里，render 循环零拼接逻辑——段间协议失效（concepts 版分段）才会立刻显形；
- **无状态**：形状与 render 都不改自身——三版可以在同一 main 里混用、互为预言；
- **合同先行**：先定 `draw(std::string&)` 的行为，再选形态——三版 hpp 的注释第一行都是合同描述，形态是合同的表达方式而非合同本身。

这四条里最容易被跳过的是最后一条：先写了继承结构、再想让 variant 版"长得一样"，就会发现虚函数版的成员/接口命名早已把形态焊死。合同先行是三形态自由切换的前提。

## 测试法

- **三版对拍**：同一形状集合，三个版本的 render 输出逐字符一致（本例 main 的三段断言互为预言）——形态可以换，合同不能变，这是跨形态回归的基本盘。
- **分隔符协议边界**：分段拼接的输出（`sq;sqci;ci`）单独断言，把"异构边界上协议失效"钉成显式事实，防止后人当成 bug 修掉。
- **id 单调与 size 计数**：容器 size 与输出段数一致（本例 `shapes.size() == 2`），防 render 吞元素。
- **编译期覆盖检查**：variant 版漏覆盖 visit 分支编译即报错，属免费测试；concepts 版给每类一个 `static_assert(DrawableLike<T>)` 把合同检查前置到类型定义处。

## 三书对应

- 之禅：混编篇的精神——"模式是死的、组合是活的"，本章三种形态即三种"模式组合"的原料；另见第 18 章"策略模式"（18.5 策略与模板方法的混编）中"用继承还是用组合封装算法"的讨论，正是虚函数对 concepts 的雏形之争。
- 刘伟：第 25 章"策略模式"25.4 节对策略的三种实现方式（继承、组合、泛型）的对比，以及第 27 章访问者中"对象结构稳定 vs 操作开放"的取舍，与本章"类型集合开放 vs 封闭"同构。
- GoF：第 1 章 1.6 节"继承和参数化类型的比较"——1989 年就把"用继承表达多态"与"用模板表达多态"的对立摆上了台面（Smalltalk 类 vs CLU 参数化），本章只是把这场争论接到了 C++23 的 concepts 与 variant 上；另见 5.11 节 Visitor "实现"小节对"双分派与重载在编译期/运行期解析"的讨论。

*可选延伸：可运行示例见 examples/29_polymorphism/。*

---

上一章：[28 访问者](28-visitor.md) · 下一章：[30 类型擦除](30-typeerasure.md)
