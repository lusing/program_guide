# 36 · 表达式求值器实战：四模式一条流水线

实战篇收官章。前 35 章把模式一个个讲、两两混编，本章把四个模式装进同一条流水线：**解释器**（文法规则即类）、**组合**（表达式树即对象结构）、**variant + visit**（节点的现代形态）、**备忘录**（变量求值缓存）。一个二百行的表达式求值器——词法、递归下降、AST、求值、缓存五段——恰好是"模式如何在真实系统里各占一段"的完整标本。学完它，再回头看第 20 章解释器，就能看清教学版与实战版之间隔着什么。

## 意图与动机

要解析并求值 `2*x + y` 这类表达式：先切 token（词法），再按文法建树（递归下降），最后带着环境遍历树算值（求值）。每一段对应的模式职责：**AST 的节点结构**是组合模式——叶子（Num/Var）与容器（Add/Mul）统一接口、递归成树；**"文法规则即类"**是解释器模式的本义——Add 类"解释"加法、Mul 类"解释"乘法；**C++23 的现实化**是 variant——四个备选项就是四种节点，visit 就是解释；**重复子表达式的缓存**是备忘录——`x*x` 里 x 求值两次，第二次走 memo。流水线全景：

```text
   源码 "2*x + y" ──lex──> token 流 ──递归下降──> Ast（variant 树）
                                                  │
                            eval（visit 分派）<───┘  env={x:3, y:4} -> 10.0
                            eval_cached（同 + Memo：Var 结果缓存）
```

## 经典写法：variant 节点 + 递归下降

示例 `eval.hpp`。AST 节点与递归拆环：

```cpp
// ---- 文法四类：数字、变量、加、乘（递归：Add/Mul 持两棵子树）----
struct Num { double v; };
struct Var { std::string name; };

struct Ast;
struct Add { std::unique_ptr<Ast> l, r; };
struct Mul { std::unique_ptr<Ast> l, r; };

struct Ast {
    std::variant<Num, Var, Add, Mul> node;   // unique_ptr<未完整 Ast>：variant 拆环的标准手法
};
```

这里用上了第 20 章埋过的伏笔：variant 想装"自己的容器"，直接 `variant<Num, Var, Add, Mul>` 递归引用会编不过（variant 要求备选项完整）；`Add` 里放 `unique_ptr<Ast>` 而 Ast 还没定义完——**unique_ptr 是允许持未完整类型的智能指针**，环被拆开。词法与递归下降（`Parser` 结构体）：

```cpp
// ---- 递归下降：expr := term ('+' term)*; term := factor ('*' factor)*;
//       factor := num | ident | '(' expr ')' ----
struct Parser {
    const std::vector<Tok>& toks;
    std::size_t pos = 0;

    std::expected<std::unique_ptr<Ast>, std::string> parse_expr() {
        auto lhs = parse_term();
        if (!lhs) return lhs;
        while (peek().kind == Tok::Kind::plus) {
            eat();
            auto rhs = parse_term();
            if (!rhs) return rhs;
            lhs = std::make_unique<Ast>(Ast{Add{std::move(*lhs), std::move(*rhs)}});
        }
        return lhs;
    }
    // parse_term / parse_factor 同构，略
};
```

文法三条规则对应三个函数，**优先级由调用层次表达**（expr 调 term、term 调 factor——乘法在更深层，天然绑得更紧）；错误处理全走 `std::expected`（第 13 章的成果），解析失败携带位置信息而不是异常逃逸。求值与备忘录版：

```cpp
inline std::expected<double, std::string> eval(const Ast& a, Env env) {
    return std::visit([&](const auto& n) -> std::expected<double, std::string> {
        using T = std::decay_t<decltype(n)>;
        if constexpr (std::is_same_v<T, Num>) {
            return n.v;
        } else if constexpr (std::is_same_v<T, Var>) {
            for (const auto& [k, v] : env)
                if (k == n.name) return v;
            return std::unexpected("undefined variable: " + n.name);
        } else {   // Add / Mul：先算左子树，成功再算右子树
            auto l = eval(*n.l, env);
            if (!l) return l;
            auto r = eval(*n.r, env);
            if (!r) return r;
            if constexpr (std::is_same_v<T, Add>) return *l + *r;
            else return *l * *r;
        }
    }, a.node);
}

struct Memo {
    std::map<std::string, double> var_vals;
    int hits = 0;   // 命中计数：同一 Var 第二次出现走缓存
};
// eval_cached：同 eval，Var 分支先查 memo.var_vals，命中 ++memo.hits
```

运行侧（`main.cpp`）五段断言：

```cpp
auto ast = parse("2*x + y");
auto r = eval(*ast, env);            // env = {x:3, y:4}
assert(*r == 10.0);

auto bad = parse("2+*");
assert(!bad.has_value());            // 语法错误走 expected
assert(bad.error().find("unexpected") != std::string::npos);

Memo memo;
auto r4 = eval_cached(*parse("x * x + y"), env, memo);
assert(*r4 == 13.0);
assert(memo.hits == 1);              // 第二个 x 命中缓存
```

`memo.hits == 1` 是备忘录价值的直接计量：`x*x+y` 里 x 出现两次，第二次不查环境直接命中。真实表达式里变量被反复引用（`x*a*x + x*b`），命中率随表达式复杂度增长。运行输出：

```text
求值线: 2*x + y 在 x=3,y=4 上 = 10
结构线: ( x + 1 ) * y = 16，括号与空格均按合同处理
错误线: 2+* 被拒，error 含 unexpected 位置信息
错误线: 未定义变量 z 报 undefined variable，错误可断言
缓存线: x*x+y 求值 13，memo 命中 1 次
对拍线: eval 与 eval_cached 结果一致
自检通过
```

## 模式结构（四模式占位图）

```text
   词法 lex            （无模式：纯过程，token 流）
      │
   递归下降 Parser      （解释器的"结构"半边：文法规则即函数）
      │
   Ast variant 节点     （组合模式：叶子 Num/Var + 容器 Add/Mul 统一成树）
      │
   eval / eval_cached   （解释器的"解释"半边：visit 分派即求值）
      │
   Memo                 （备忘录：Var 求值结果按名缓存，hits 计数）
```

四模式各管一段、互不越界：组合管**数据形状**，解释器管**遍历语义**，备忘录管**重复消除**，expected 管**错误通道**（它不是 GoF 模式，是现代 C++ 对"错误即值"的设施化——正好补上 GoF 时代缺席的一环）。

## 与第 20 章对照：教学版升级了什么

第 20 章教学版是"每个文法规则一个类、interpret() 一个虚函数"的最小骨架；本章四处升级各有名目：**节点从类层次变 variant**（第 29 章三副面孔的选择——节点集合封闭、visit 一跳、exhaustive 检查免费）；**错误从异常/哨兵变 expected**（错误路径类型化，调用方被编译器逼着处理）；**环境从全局 map 变显式参数**（eval 的可测性、可重入性）；**求值加备忘录**（备忘录从"快照撤销"变"缓存"——第 23 章备忘录的另一个用途面向）。四条升级全部来自前面章节的积累——实战篇的意义就在验证：**前 35 章的工具箱，确实能拼出一个完整的系统**。

## 词法层的两条工程纪律

词法看着无模式，工程上却有两定生死。**纪律一：错误与解析层同通道**。lex 返回 `std::expected<std::vector<Tok>, std::string>`，坏字符带位置报错——如果词法层用异常或静默跳过，"2+*" 之外的第 6 类错误（如 `2$3`）就会绕过 expected 合同直冲调用方；本章把 bad char 收进 unexpected，全部错误保持一条通道。数字转换同理：std::stod 对畸形输入可能抛异常，生产版应 try/catch 收编或手写解析——**词法是错误信息的源头，源头的通道不齐，下游全乱**。**纪律二：token 要自包含**。Tok 结构体里存了原始文本和已转换的数值——解析器报错时能打印 "unexpected token '*'"、factor 直接取 `peek().num`，两处消费各取所需；若 token 只存一个 char 指针，解析器就得回头重新转换（错误路径上的重复劳动与再出错风险）。两条纪律合起来就是词法层的合同：**进字符串、出 token 流，一切失败皆为 expected 值**——与解析层、求值层同一错误哲学，整条流水线没有异常逃逸的口子。

## 本章示例的断言面

main.cpp 五段断言的覆盖面：

- 正路径两棵树：`2*x+y` = 10（无括号优先级）、`( x + 1 ) * y` = 16（括号 + 空格容忍）；
- 语法错误："2+*" 拒收，error 含 unexpected 位置信息；
- 语义错误：未定义变量 z，error 含变量名——expected 的两条失败通道各钉一条；
- 缓存行为：`x*x+y` = 13 且 memo.hits == 1——结果正确与命中计数双断言；
- 双实现对拍：eval 与 eval_cached 同表达式同环境结果一致。

## 陷阱清单

1. **variant 递归直装**（现象：`std::variant<Num, Add>` 里 Add 直接持 Ast 值，编译器报"备选项类型不完整"或递归大小无限；原因：variant 要求备选项完整且有限大小；后果：编不过。对策：unique_ptr<Ast> 拆环（本章），或改用前向声明的类层次（第 20 章写法））。
2. **visit 中改树**（现象：eval 的 visit 里对子树做优化替换（如常数折叠就地改节点），行为不定或崩溃；原因：visit 进行中被访对象可能失效——第 25 章 variant 状态机的同款纪律；后果：UB。对策：visit 返回新值/新树、visit 后再赋回；优化遍历单独成趟）。
3. **备忘录缓存了不该缓存的**（现象：env 是引用，eval_cached 第一趟后改 env 再跑第二趟，memo 里还是旧值；原因：Memo 的 key 是变量名、value 是首趟值，环境变化不触发失效；后果：缓存"正确性"依赖环境不变这一隐含前提。对策：合同写明"同一 env 才可复用"，或 key 换成 (名字， 环境版本)；缓存语义必须显式）。
4. **优先级层次漏一层**（现象：加个减法直接塞进 expr 的 while 里，`a-b+c` 变成 a-(b+c)；原因：左结合靠循环保证，新运算符层次放错；后果：结果错但常常"看起来对"。对策：新运算符先定结合性与优先级，再决定进哪层（同级左结合进现有 while，不同级新开一层））。
5. **stod 之类宽转换吞错误**（现象："1.2.3" 被 stod 悄悄截成 1.2，或非常长数字抛 out_of_range 越过 expected 通道；原因：词法用库函数转换，异常逃出 expected 合同；后果：错误路径断裂。对策：转换处 try/catch 收进 unexpected，或手写数字解析——词法层是错误信息的源头，必须与解析层同一错误纪律）。

## 扩展练习清单

本章骨架留了几处"顺理成章的下一步"，每处都对应一个已学模式的深化：

- **减法/除法**：expr 层 while 加 '-'（左结合进现有循环）、除零走 unexpected——优先级层次与错误通道的巩固；
- **一元负号**：factor 层加 unary 分支，`-x+1` 的优先级陷阱（负号只绑 factor）；
- **常数折叠**：parse 后跑一趟"Num op Num → Num"的优化遍历——visit 返回新树、visit 后赋回（陷阱 2 的正面演练）；
- **环境版本化**：Memo 加代数计数，env 每改一代、缓存按键带代——备忘录失效合同的升级；
- **多类型求值**：节点加字符串字面量，eval 返回 variant<double, string>——第 28 章"visit 返回类型一致"约束的实战体现。

每条练习都能在不动骨架的前提下长出——这是本章作为收官章的自检：**前 35 章的模式工具箱，扩一个功能不需要重构**。

## 测试法

- **手算对拍**：`2*x+y` 在 {x:3,y:4} 上 = 10、`(x+1)*y` = 16——两棵结构不同的树覆盖加乘与括号。
- **负例双段**：语法错误（"2+*"，error 含 unexpected）与语义错误（未定义变量 z，error 含变量名）各一条——expected 的两条失败通道都要有断言。
- **缓存命中计数**：`x*x+y` 的 hits==1——备忘录不是"结果对"就完，命中次数是它的行为面。
- **双实现对拍**：eval 与 eval_cached 同表达式同环境结果一致（13.0）——加缓存不得改语义，与全书双形态对拍同一纪律。
- **结合性探针**：左结合运算序列（如 `x+x+x` 应为 (x+x)+x 而非 x+(x+x)）在乘法上数值不可辨（乘法结合可交换），扩展减法/除法后此断言即成必要——开发期就用 doubles 除法（`8/4/2` 左结合 =1、右结合 =4）埋探针。
- **空输入与单 token**：parse("") 与 parse("x") 的行为断言（空输入报错、单变量合法）——边界输入是递归下降最常见的漏网处。

## 三书对应

- 之禅：第 20 章"解释器模式"（20.x 解释器"脚本语言/规则引擎"的定位——本章就是一个小规则引擎的完整形态）；另见第 17 章备忘录 17.x"备份黑箱化"的缓存变体、第 8 章组合模式 8.x"树形结构与统一接口"。
- 刘伟：第 20 章"解释器模式"20.3 节"抽象语法树的构建与求值"（刘伟版直接以 AST + 环境求值为实例，与本章同构）；第 14 章组合模式 14.2 节"透明性与安全性"的权衡——本章 variant 版是"安全式组合"（类型层面保证叶子/容器的区别）。
- GoF：第 5 章 5.3 Interpreter——"实现"小节对"用解释器模式表达文法、TerminalExpression 与 NonterminalExpression 的分野"的完整讨论，以及 2.x 节组合模式作为解释器的基座（"Interpreter 大量使用 Composite 来表示文法树"）；本章 variant 化正是把 Terminal/Nonterminal 两个基类折叠成备选项的集合。

*可选延伸：可运行示例见 examples/36_evaluator/。*

---

上一章：[35 自注册插件框架](35-plugins.md) · 下一章：[37 文档导出：桥与外观的合体](37-docexport.md)
