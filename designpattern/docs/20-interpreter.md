# 20 · 解释器

行为型篇里最"冷"的一个模式，却直指编译原理的心脏。GoF 5.3 节的定义：**给定一个语言，定义它的文法的一种表示，并定义一个解释器，这个解释器使用该表示来解释语言中的句子**。注意定义里的三个词各对应一种代码构件——"语言"是一类问题（布尔表达式、正则、SQL 片段），"文法的一种表示"是一棵**对象树**（每个文法规则一个类），"解释器"是对这棵树的**一次遍历**。本章用布尔小语言把这三层对应全部落地。

## 意图与动机

假设业务规则引擎要支持 `(v0 and (not v1)) or v2` 这样的条件表达式。朴素写法是字符串解析 + switch 求值——所有文法知识挤在一个大函数里，加一条规则（比如 xor）就要改求值核心。解释器模式把**每条文法规则变成一个类**：and 是一个类、or 是一个类、变量是一个类。规则与类一一对应后，"加规则"就是"加类"，而"加操作"（求值、打印、化简）是对同一棵树的另一次遍历——文法稳定、操作多变的场景正是它的甜区。

## 经典写法：布尔表达式树

示例 `interp.hpp`。抽象表达式与终结符：

```cpp
// AbstractExpression：所有语法节点的统一求值接口。
struct BoolExpr {
    virtual ~BoolExpr() = default;
    [[nodiscard]] virtual bool eval(std::span<const bool> vars) const = 0;
    [[nodiscard]] virtual std::string name() const = 0;
};

// TerminalExpression：变量——查环境（vars 数组按位对应 v0, v1, ...）。
struct Var final : BoolExpr {
    explicit Var(size_t idx) : idx_(idx) {}
    [[nodiscard]] bool eval(std::span<const bool> vars) const override {
        return vars[idx_];                       // 叶节点：查环境即求值
    }
    // name() 略：format("v{}", idx_)
private:
    size_t idx_;
};
```

三个非终结符各对应一条文法规则（and/or/not）：

```cpp
// NonterminalExpression：三种组合子，各对应一条文法规则。
struct And final : BoolExpr {
    And(std::unique_ptr<BoolExpr> l, std::unique_ptr<BoolExpr> r)
        : l_(std::move(l)), r_(std::move(r)) {}
    [[nodiscard]] bool eval(std::span<const bool> vars) const override {
        return l_->eval(vars) && r_->eval(vars);   // 规则体的直接翻译
    }
private:
    std::unique_ptr<BoolExpr> l_, r_;
};
// Or / Not 同构：eval 分别是 || 和 !，略
```

看 `And::eval` 那一行：它几乎就是文法产生式 `expr and expr` 的 C++ 直译——**递归下降的求值结构被类结构原样承载**。这就是解释器模式的"文法即类层次"。运行侧组装 `(or (and v0 (not v1)) v2)` 并穷举验证（`main.cpp`）：

```cpp
auto expr = std::make_unique<Or>(
    std::make_unique<And>(
        std::make_unique<Var>(0),
        std::make_unique<Not>(std::make_unique<Var>(1))),
    std::make_unique<Var>(2));

// 手算表：v0 && !v1 || v2，8 组真值穷举比对
for (int bits = 0; bits < 8; ++bits) {
    std::array<bool, 3> env{static_cast<bool>(bits & 1),
                            static_cast<bool>(bits & 2),
                            static_cast<bool>(bits & 4)};
    assert(expr->eval(env) == expected[bits]);   // 树求值 == 手算表
}
```

运行输出：

```text
组合7: v0=1 v1=1 v2=1 -> 1
variant: 8 组真值与继承版逐项同值
化简: not not v0 -> v0（语义保持）
```

8 组真值逐组与手算表一致——树求值的语义被穷举钉死。`name()` 方法顺带演示了"加操作零成本"：同一个类层次，第二个虚函数就是"打印表达式"这个新解释。

## 模式结构（ASCII 类图）

```text
        BoolExpr (AbstractExpression)
        +eval(vars)=0  +name()=0
       ┌──────┬─────────┬──────────┐
      Var    And       Or         Not
 (Terminal) (Nonterminal ×3，各对应一条产生式)
       │       │ l_,r_  │ l_,r_    │ e_
       └───────┴────────┴──────────┘
          unique_ptr<BoolExpr>：组合即树

  Context = vars 环境（span<const bool>，按位对应变量）
  Client  = main：组装树（"解析器"的位置）+ 穷举求值
```

GoF 五角色里最容易被忽略的是 **Client**：它既负责建树（真实系统里这活属于解析器——解释器模式只管"树已建好之后"），又持有环境。本例用 `make_unique` 链手工建树，第 36 章 evaluator 会换成真的递归下降解析器建树。

## 现代写法：递归 variant + visit

继承树换成 variant：文法节点 = 备选项，求值/化简 = visit 函数（`variant_interp.hpp`）。递归类型要先拆环：

```cpp
struct AndV; struct OrV; struct NotV;          // 前置声明

using BExprV = std::variant<VarV,
                            std::unique_ptr<AndV>,   // unique_ptr 打断递归
                            std::unique_ptr<OrV>,
                            std::unique_ptr<NotV>>;

struct AndV { std::unique_ptr<BExprV> l, r; };  // BExprV 完整后才能定义成员
```

求值是一次 visit：

```cpp
inline bool veval(const BExprV& e, std::span<const bool> vars) {
    return std::visit([&](const auto& v) -> bool {
        using T = std::decay_t<decltype(v)>;
        if constexpr (std::is_same_v<T, VarV>)          return vars[v.idx];
        else if constexpr (std::is_same_v<T, std::unique_ptr<AndV>>)
            return veval(*v->l, vars) && veval(*v->r, vars);
        else if constexpr (std::is_same_v<T, std::unique_ptr<OrV>>)
            return veval(*v->l, vars) || veval(*v->r, vars);
        else                                            return !veval(*v->e, vars);
    }, e);
}
```

variant 版真正的红利在**第二类操作**——化简。继承版加"化简"要给每个类加虚函数；variant 版只写一个新函数 `vsimplify`，规则 `not not x -> x` 一目了然：

```cpp
} else if constexpr (std::is_same_v<T, std::unique_ptr<NotV>>) {
    auto inner = vsimplify(*v->e);
    if (auto* p = std::get_if<std::unique_ptr<NotV>>(inner.get()))
        return std::move((*p)->e);        // 内层还是 Not：剥掉双重否定
    return make_not(std::move(inner));
}
```

运行输出第二、三行钉死两件事：variant 版 8 组真值与继承版逐项同值（两形态语义等价）；`not not v0` 化简后与 `v0` 语义一致。两版取舍：继承版加**节点类型**方便（加类），variant 版加**操作**方便（加函数）——这恰是表达式问题（Expression Problem）的两难两面，第 25 章观察者与第 34 章 visitor 会再回到这个天平。

## 从手工建树到真解析器

本例的树是 `make_unique` 链手工组装的——**建树与求值是两个世界**。GoF 在"实现"节第一句就点名：抽象语法树通常由解析器创建。看清这两层的边界：

```cpp
// 建树层（Client 的活）：手工 = 教学版；真实系统 = 解析器
auto expr = std::make_unique<Or>(
    std::make_unique<And>(std::make_unique<Var>(0),
                          std::make_unique<Not>(std::make_unique<Var>(1))),
    std::make_unique<Var>(2));
```

手工建树的问题不是能不能用，而是**树的合法形状完全靠人保证**——`make_and` 可以接任何 `BoolExpr`，包括悬空的、语义错误的组合。真解析器（递归下降，第 36 章 evaluator 展开）在建树的同时完成合法性检查：文法不允许的形状根本建不出来。一条清晰的分界线：**解释器模式管"树已建好之后"的一切（求值、化简、打印），解析器管"字符串到树"**。两者常被混为一谈，但解释器模式的书里（含三本书）从不包含词法分析——模式只对树形数据负责。这也解释了为什么第 7 章外观里的 `Parser` 产出"节点数"而本章 `Parser` 产出"节点树"：前者是零件封装，后者是文法落地。

## 终结符共享：与享元的握手

变量节点 `Var(0)` 在大表达式里会出现很多次——每个 `v0` 都是一个独立对象。刘伟 19.5 与 GoF"实现"节都点了这一手：**终结符节点用享元共享**（第 16 章）：

```cpp
// 享元工厂思路：同一 idx 的 Var 全局唯一
class VarFactory {
public:
    [[nodiscard]] const Var* get(size_t idx) const {
        auto [it, inserted] = pool_.emplace(idx, std::make_unique<Var>(idx));
        return it->second.get();
    }
private:
    mutable std::map<size_t, std::unique_ptr<Var>> pool_;
};
```

可行性论证：`Var` 是不可变的（`idx_` 构造后不变、`eval` 是 const），共享无副作用——这正是享元"内部状态不可变、外部状态现场传"的判定在本章的翻版。收益边界也要说清：`Var` 只有 `size_t` 一个成员，共享省的内存有限；真正的意义在**节点数量级**——含一百万个变量的规则表里，去重后工厂只持 64 个（假设 64 变量），百万次引用全是指针。非终结符（And/Or/Not）不能这样共享：它们的子树不同，等价子树的去重要靠哈希合并（hash-consing），那是函数式编译器的领域，超出模式范畴。

## 与组合、访问者的三角关系

解释器与第 13 章组合同构：都是递归的树 + 统一接口，GoF 甚至说"解释器是组合的特例"。分界在**语义**：组合表达"部分-整体"的容器语义（文件夹求大小），解释器表达"文法规则"的语言语义（子表达式求值）。解释器又天然是访问者（第 34 章）的主战场——对同一棵语法树做多种遍历（求值、打印、化简、类型检查），树稳定而操作爆炸时，visitor 比"每个节点塞一堆虚函数"干净得多。本章有意不加 visitor，让读者先感受"每节点一个 eval 虚函数"的原始形态，第 34 章再来拆它。

## 陷阱清单

1. **文法复杂度失控**（现象：30 条产生式 30 个类，类层次比语言本身还难读；原因：解释器适合小语言，GoF 明说"文法规则数量大时不适用"；后果：维护成本指数化。对策：规则超过一打就上真正的解析器生成器（ANTLR、bison），别手搓类层次）。
2. **表达式树的所有权混乱**（现象：裸指针建树，父子都 delete；原因：递归结构 + 手工内存管理；后果：double free 或泄漏。对策：`unique_ptr` 单向持有——父持子，析构递归自动完成；注意 `unique_ptr<未完整类型>` 的析构函数要在完整类型可见处定义）。
3. **visit 传错参数**（现象：把 `unique_ptr<BExprV>` 传给 `std::visit`；原因：visit 只吃 variant 本体；后果：编译错误——还算幸运，运行期错才可怕。对策：递归函数签名收 `const BExprV&`，进入子节点时 `*v->l` 解引用一层）。
4. **环境与变量错位**（现象：vars 数组三个元素，表达式引用了 v3；原因：无越界检查；后果：UB。对策：Var 构造时校验 idx 上界（编程错误抛异常），或环境改用 `map<string,bool>` 以名字寻址）。
5. **把"解释"写成第二棵树**（现象：求值逻辑里嵌 switch 判断表达式形状，等于在函数里又造了一遍类层次；原因：从过程式思路硬翻译；后果：两份文法知识并存，改文法要改两处。对策：每个节点自己知道怎么求值——规则即类（继承版）或 visit 分支（variant 版），别让知识搬家）。

## 三书对应

- 之禅：第 27 章"解释器模式"（27.2 定义、27.3 应用——音乐解释器/MIDI 模拟的例子、27.4 最佳实践——明确指出"解释器模式实际使用率很低，脚本语言解析基本不用它"，与本章陷阱 1 呼应）。
- 刘伟：第 19 章"解释器模式"（19.1 动机与定义、19.2 结构与分析、19.3 实例——数学运算表达式解释器、19.5 扩展——与享元结合共享终结符节点）。
- GoF：第 5 章 5.3 节 Interpreter——布尔表达式例（正是本章选择布尔语言的原因：与 GoF 原例同源，可对照阅读），"实现"节讨论"抽象语法树的创建（解析器/工厂）、共享终结符、迭代遍历"。

*可选延伸：可运行示例见 examples/20_interpreter/。*
