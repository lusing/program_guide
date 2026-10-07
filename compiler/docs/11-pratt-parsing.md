# 第 11 章　Pratt 分析：运算符优先级爬升

> 取材：匠书（Crafting Interpreters）§6.2–6.3（jlox 的分层递归下降与结合性
> 陷阱）、§17.5（clox 的 Pratt 分析器：`parsePrecedence`、规则表与
> `getRule`）。两处材料在本章自包含蒸馏，不需要翻原书。
> 本章示例：`examples/11_pratt_parsing`（无 ANTLR，简单程序对账协议）。

**两分钟速览**（赶时间的读者看完这段可跳 9.5 看实验）：Pratt 分析器 =
一张规则表 + 一个循环。表把每个 token 映射到四个字段：前缀回调（它
开头时怎么办）、中缀回调（它出现在左操作数之后时怎么办）、优先级
（比谁紧）、结合性（同级先绑左还是右）。循环 `parseExpression(minPrec)`
只做三件事：吃一个前缀起步；看下一个 token，查表取中缀回调与优先级；
优先级低于 minPrec 就返回（让权），否则执行回调并滚环。结合性的全部
秘密在回调里给右操作数选的递归下限——左结合选"高一级"（同级回到
外层循环），右结合选"同级"（递归先吃右边）。三个断言锁死理解：
`2-3-4 = -5`（左结合）、`2^3^2 = 512`（右结合）、把减号那格布尔翻转
后 `2-3-4 = 3`（结合性住在表里的实验证据）。

## 11.0　本章要解决的问题与位置

教程的前端三部曲到此收束：第 6 章给了 LL(1)——预测表驱动、每层优先级
一对函数；第 7、8 章给了 LR 家族——构造器从文法自动算出移进归约表；
本章给第三条路：**Pratt 分析（运算符优先级爬升）**——人写一张运算符
规则表，机器滚一个循环。三条路解决同一个问题（把带优先级的表达式文本
变成树），但"表从哪来、结合性住哪、加运算符动多大"三问的答案各不相同
（§9.7 有对照总表）。

为什么前两条路之后还需要第三条？一个数字就能说明分量：工业界手写的
编译器与解释器前端（GCC、Clang、V8、rustc 这一级别）几乎没有用 LL 或
LR 生成器做表达式解析的，主流做法恰恰是"递归下降负责语句骨架 + Pratt
负责表达式"。读懂这一章，读者就掌握了从教科书通往工业前端的那块
跳板。

本章的写作结构与前两章不同：不是"先理论后实现"，而是**改造记**——

```text
9.0 问题与位置
9.1 改造前：llref（第 6 章分层法副本）——三个痛点
9.2 改造的主意：优先级住进表  ——  9.2.1 文法 ↔ 表机械互译
9.3 实现：循环 + 表 + 回调   ——  词法 / 主循环 / 表 / 结合性 / 回调 / 求值 / 清单
9.4 陷阱巡礼：形状语料说话（双角色 token 的位置行为）
9.5 驱动与对账：63 项断言（值 + 形状双保险）
9.6 期望输出逐行导读
9.7 家族定位（jlox 映射 / LR 深照 / 三路对照 / FAQ）——  9.8 小结与练习
```

9.1 把第 6 章的方法原样搬来当"改造前"参照物，摆出它的三个痛点；
9.2–9.4 逐个痛点给出 Pratt 的回答（优先级进表、结合性进表、记号类别
进表）；9.5–9.6 用 63 项机器断言把"两法等价、结合性可翻、陷阱有形状"
逐条签收；9.7–9.8 收束定位。读完读者应当能：手推任意一条语料在 Pratt
循环里的完整生涯；往表里加一个新运算符；解释为什么 `2^3^2` 是 512 而
`(2^3)^2` 是 64。

验证协议上本章也是一个小转折：它是教程第一个**双实现等价对账**章——
同一语料喂给两个独立实现的解析器（llref 与 pratt），断言值与形状双
相等。此前各章的证人都是"实现 vs 期望输出"，本章多了一层"实现 vs
实现"。这条线在本轮扩充会一路铺下去：第 15 章树遍历解释器、第 57–60
章字节码虚拟机，同一程序将在三种执行方式下互为证人——多实现等价，
是比单实现对账强一档的正确性证据。

## 11.1　回看第 6 章：每层优先级一个函数的代价

第 6 章用 LL(1) 预测分析啃下了表达式文法。它的解析器是**分层**的：优先级每
高一级，就多一个函数——比较层调加法层、加法层调乘法层、乘法层调一元层、
一元层落到主表达式。匠书在 jlox（书的第二部分，树遍历解释器）里用的正是
这个结构：`equality()` 调 `comparison()` 调 `term()` 调 `factor()` 调
`unary()` 调 `primary()`，六个函数一级压一级。本章把这个结构原样复制成了
`llref.hpp` / `llref.cpp`（与第 6 章示例同型的最小副本），作为"改造前"的
参照物：

```cpp
// file: src/llref.hpp
// file: src/llref.hpp
// 第 11 章参照物：第 6 章 LL(1) 分层递归下降的最小副本。
// 每层优先级一个函数（cmp → add → mul → unary → primary），
// 与 Pratt 规则表产出同一形状的 AST、共用同一求值器——
// 解析策略是唯一变量，两法对同一语料必须算出同一个数。
#ifndef TIP_LLREF_HPP
#define TIP_LLREF_HPP

#include "pratt.hpp"

namespace tip {

// 文法（左递归已消除，与第 6 章同型）：
//   cmp    → add cmp'
//   cmp'   → (LE|LE|GT|GE|EQ|NE) add cmp' | ε
//   add    → mul add'
//   add'   → (PLUS|MINUS) mul add' | ε
//   mul    → unary mul'
//   mul'   → (STAR|SLASH) unary mul' | ε
//   unary  → MINUS unary | primary          // STAR 前缀（解引用）不进交集语料
//   primary→ INT | IDENT | LPAREN cmp RPAREN
class LlParser {
  public:
    explicit LlParser(std::vector<Token> toks);
    ExprP parse();  // = cmp()，出错返回 nullptr

    bool hadError() const { return !errs_.empty(); }
    const std::vector<ParseError> &errors() const { return errs_; }

  private:
    ExprP cmp();
    ExprP cmpRest(ExprP lhs);
    ExprP add();
    ExprP addRest(ExprP lhs);
    ExprP mul();
    ExprP mulRest(ExprP lhs);
    ExprP unary();
    ExprP primary();

    const Token &peek() const { return toks_[pos_]; }
    Token advance();
    bool match(Tok t);
    Token expect(Tok t, const std::string &msg);

    std::vector<Token> toks_;
    size_t pos_ = 0;
    std::vector<ParseError> errs_;
};

ExprP parseLl(const std::string &src, std::vector<ParseError> &errs);

}  // namespace tip

#endif  // TIP_LLREF_HPP
```

```cpp
// file: src/llref.cpp
// file: src/llref.cpp
#include "llref.hpp"

namespace tip {

LlParser::LlParser(std::vector<Token> toks) : toks_(std::move(toks)) {}

Token LlParser::advance() {
    if (toks_[pos_].t != Tok::Eof) ++pos_;
    return toks_[pos_ - 1];
}

bool LlParser::match(Tok t) {
    if (peek().t != t) return false;
    advance();
    return true;
}

Token LlParser::expect(Tok t, const std::string &msg) {
    if (peek().t == t) return advance();
    errs_.push_back({msg + "，但看到 '" + peek().text + "'", peek().line});
    return peek();
}

ExprP LlParser::parse() { return cmp(); }

// 每层一个函数：层的先后就是优先级，函数体里的 while 循环就是左结合，
// unary 里递归 unary 才容得下 --x——结合性全部焊死在调用图里（§09.1 的痛）。
ExprP LlParser::cmp() {
    ExprP lhs = add();
    return lhs ? cmpRest(std::move(lhs)) : nullptr;
}

ExprP LlParser::cmpRest(ExprP lhs) {
    Tok t = peek().t;
    if (t == Tok::Lt || t == Tok::Le || t == Tok::Gt || t == Tok::Ge ||
        t == Tok::Eq || t == Tok::Ne) {
        Token op = advance();
        ExprP rhs = add();
        if (!rhs) return nullptr;
        return cmpRest(std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs)));
    }
    return lhs;  // ε
}

ExprP LlParser::add() {
    ExprP lhs = mul();
    return lhs ? addRest(std::move(lhs)) : nullptr;
}

ExprP LlParser::addRest(ExprP lhs) {
    Tok t = peek().t;
    if (t == Tok::Plus || t == Tok::Minus) {
        Token op = advance();
        ExprP rhs = mul();
        if (!rhs) return nullptr;
        return addRest(std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs)));
    }
    return lhs;
}

ExprP LlParser::mul() {
    ExprP lhs = unary();
    return lhs ? mulRest(std::move(lhs)) : nullptr;
}

ExprP LlParser::mulRest(ExprP lhs) {
    Tok t = peek().t;
    if (t == Tok::Star || t == Tok::Slash) {
        Token op = advance();
        ExprP rhs = unary();
        if (!rhs) return nullptr;
        return mulRest(std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs)));
    }
    return lhs;
}

ExprP LlParser::unary() {
    if (match(Tok::Minus)) {
        ExprP sub = unary();  // 一元负号递归自身：允许 --x
        return sub ? std::make_unique<Unary>(Tok::Minus, std::move(sub)) : nullptr;
    }
    return primary();
}

ExprP LlParser::primary() {
    if (peek().t == Tok::Int) {
        Token t = advance();
        return std::make_unique<IntLit>(t.num);
    }
    if (peek().t == Tok::Ident) {
        Token t = advance();
        return std::make_unique<VarRef>(t.text);
    }
    if (match(Tok::LParen)) {
        ExprP inner = cmp();
        if (!inner) return nullptr;
        expect(Tok::RParen, "期望 ')'");
        return inner;
    }
    errs_.push_back({"期望表达式，但看到 '" + peek().text + "'", peek().line});
    return nullptr;
}

ExprP parseLl(const std::string &src, std::vector<ParseError> &errs) {
    std::vector<Token> toks = lex(src, errs);
    LlParser p(std::move(toks));
    ExprP e = p.parse();
    if (p.hadError()) {
        errs.insert(errs.end(), p.errors().begin(), p.errors().end());
        return nullptr;
    }
    return e;
}

}  // namespace tip
```

头文件里的文法注释值得先读一遍：`cmp → add cmp'`、`add → mul add'`、
`mul → unary mul'`——每个非终结符对应一对函数（本体与"余部"），余部函数
（`cmpRest` 等）的存在就是为了在消除左递归的同时保住左结合。实现里每个
余部函数都是同一个模板的实例：看一眼 token，属于本层就吃掉运算符、调用
下一层取右操作数、递归自身继续。六层函数，一种模板。

先把这个参照物的痛点摆清楚，因为 Pratt 分析的全部设计都是对着这些痛点
去的。

动手前一句阅读建议：把 `llref.cpp` 与 9.3 的 `pratt.cpp` 并排打开，
对同一个构造（比如左结合链）各读一遍——两份代码**产出同一棵树**
（9.5 的形状对账会机器签收这一点），所以它们是同一算法事实的两种
排版。并排读的收获不是"谁短"，而是清楚地看见**决策信息住在哪**：
llref 里住在调用图（读代码要跳转），pratt 里住在表（读代码看一行）。
本章所有论证归根结底就是这一个差别。

拿 `a-b-c` 做一次并排推演，两边的"剧本"对照如下——左列 llref、
右列 pratt，中间是 token 位置：

| 时刻 | llref 的动作 | pratt 的动作 |
|---|---|---|
| 吃 `a` | `cmp → add → mul → unary → primary` 五连降，`primary` 吃 `a` 后五连升 | 前缀回调 `variable` 一步吃 `a` |
| 见 `-`① | 控制权在 `addRest`（回到加法层余部），它认得 `-` | 主循环查表：Minus 中缀列是 `binary`，Term ≥ None |
| 吃右部 | `addRest` 调 `mul`（**下一层**）→ … → 吃 `b` | `binary` 以 up(Term)=Factor 为下限递归 → 吃 `b` |
| 见 `-`② | `mul` 一路返回到 `addRest`（层下降即让权） | 递归层见 `-`，Term < Factor，**一行比较即让权** |
| 合成 | `addRest` 组 `(a-b)` 后循环再见 `-`②，重复上一行 | 递归返回 `(a-b)`，外层滚环再见 `-`②，重复 |
| 结果 | `addRest( addRest(a,b), c )` | `binary( binary(a,b), c )`——同一棵树 |

剧本逐格对齐：**每一行的"谁决定"不同（层 vs 表），"决定成什么"相同**。
这张表就是"两法等价"的微缩胶片，9.5 第三段的 30 条断言是它的机器
放大版。

**痛点一：加一个运算符，要动三处。** 匠书 jlox 的六层函数各管一级：
`equality`（== !=）、`comparison`（< <= > >=）、`term`（+ -）、`factor`
（* /）、`unary`（! -）、`primary`（字面量/标识符/括号），另设 `call`
处理调用与字段。假如要在比较层和加法层之间插一个
按位与层 `&`，分层法需要：新写一对函数 `bitwise()` 与 `bitwiseRest()`；
把 `cmpRest` 里调用 `add` 的两处位置改成调用 `bitwise`；把 `add` 的调用
方（也就是 `bitwise`）接上……一层插进去，上下两个邻居都要改。更糟的是
**优先级信息没有住在数据里，而是住在函数调用图的拓扑里**：读代码的人
想知道"`*` 和 `+` 谁绑得紧"，必须沿"`mul` 在 `add` 体内被调用"这个事实
去推断。文法文档与代码结构一旦漂移，谁也说不清哪边是对的。

**痛点二：结合性焊死在代码形状里。** 看 `addRest`：吃到 `+` 之后递归
调用 `mul`——**同级不再递归进自己**，而是回到 `addRest` 的循环，于是
`a-b-c` 先结合成 `(a-b)-c`，这是左结合。而 `unary` 里 `MINUS` 递归调用
`unary` 自身——同级递归，于是 `--x` 是 `-(-x)`。左结合与"循环 + 低一级
递归"绑在一起，右结合与"同级递归"绑在一起：**这不是一个可以配置的决定，
而是两种恰好不同的代码形状**。

匠书 §6.3.4 给过一个著名的翻车现场，本章直接把它做成实验（§9.5 第四段）。
jlox 的 `equality` 层最初照抄下层模板。模板本身有两种抄法：照抄 `term`
的写法得到左结合，照抄 `unary` 的写法得到右结合——两种抄法在文法层面都
合法，编译器不报任何错。于是 `a == b == c` 被默默解析成 `a == (b == c)`
——右结合。对相等比较这是错的（甚至多数语言该直接报错），可解析照常
完成、求值照常进行，错误只能靠测试用例兜住。结合性出错不会崩，只会
静默给错答案，这是它比语法错误更危险的地方。

**痛点三：一元、调用、字段各占一层，层与层之间只有顺序关系。** `primary`
里的括号处理、`unary` 里的负号，各自有存在理由；想在表达式里支持后缀
调用 `f(1)(2)` 还得再堆一层"后缀层"，想支持下标 `a[i][j]` 再堆一层。
每层的存在理由是"它比邻居紧"，而不是"它是这类记号"——记号的**类别**
（前缀/中缀/后缀）与记号的**优先级**（比谁紧）被搅在同一个维度里。

分层法当然有它的好：每层函数短小直白，与文法产生式一一对应，第 6 章讲
FIRST/FOLLOW 时它是最合适的教学载体；LL(1) 的表驱动实现（第 6 章的
另一条线）甚至完全不用递归。但当一门语言的表达式运算符多到十几种（C
语言光优先级就有十五级），每层一函数就变成了纯粹的事故面：十五层函数、
十五个余部函数，插层改三处，结合性靠人肉保持模板一致。

本章要回答的问题因此非常具体：**能不能把"优先级"与"结合性"从代码拓扑
里搬出来，放进一张可以一行行读、一格格改的表里？**

## 11.2　Pratt 的主意：让优先级住进表里

1973 年 Vaughan Pratt 在 POPL 上发表《Top Down Operator Precedence》，
给出了一个反直觉的回答：**表达式解析根本不需要"层"，只需要一个循环和
一张表**。这套方法后来被 Doug Crockford 在《Top Down Operator
Precedence》（他写 JSLint 时的复盘文章）里重新发掘并命名 TDOP，再后来
成了手写工业编译器表达式前端的标配。匠书在 clox（书第三部分的字节码
解释器）里完整实现了它——这也是为什么本章同时取材两处：jlox 的痛点
（§6.3）与 clox 的解法（§17.5）。

先辨析三个常被混用的名字。**Pratt 分析器**（本节主角）指 1973 年那套
"前缀/中缀回调 + 优先级表"的完整架构；**优先级爬升**（precedence
climbing）指它的核心循环机制（下一小节的 `parseExpression`）——很多
文献与编译器源码（GCC、rustc）用这个词自称，实现上是 Pratt 架构的
精简形态（通常只有双目运算符走表，叶子与调用写死在骨架里）；
**TDOP**（top-down operator precedence）是 Crockford 复刻时的叫法，
与 1973 年原版同义。三者实现规模递减、思想同一：**记号自带优先级，
递归按表爬升**。教程行文统称 Pratt，读到别处三个名字时按此对应。

Pratt 对 token 只问三件事：

1. **这个 token 出现在"操作数位"（一开头）时怎么办？**——前缀回调
   （prefix）。数字、标识符是天然的操作数；`(` 开头是分组；`-`、`*`、
   `&` 开头是一元前缀运算。
2. **这个 token 出现在"运算符位"（左操作数已在手）时怎么办？**——中缀
   回调（infix，含后缀）。`+ - * / ^ < ==` 是双目；`(` 在左操作数之后
   是**调用**；`.` 之后是**字段**。
3. **它比谁紧？**——一个优先级数字。

"前缀/中缀"这个二分把痛点三的"类别"维度接走了；"优先级数字"把痛点一的
"顺序"维度接走了；剩下痛点二的"结合性"，答案是右操作数的递归下限取
同级还是高一级——一格布尔（§9.3）。三者装进一条规则，全部 token 的规则
摆成一张表。解析器本体只剩一个函数，本章 `pratt.hpp` 里它叫
`parseExpression(Prec minPrec)`（匠书叫 `parsePrecedence`）：

```cpp
// file: src/pratt.hpp
// file: src/pratt.hpp
// 第 11 章：Pratt 分析——运算符优先级爬升（precedence climbing）。
// 词法共享（llref 也用它）；AST 与第 14 章 TIP 表达式节点同名同形；
// 解析策略是本章唯一变量，求值器两法共用，输出必须一致。
#ifndef TIP_PRATT_HPP
#define TIP_PRATT_HPP

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

namespace tip {

// ---------- 词法 ----------
enum class Tok {
    Int, Ident, Plus, Minus, Star, Slash, Caret,  // Caret（^）是教学扩展：TIP 无幂
    LParen, RParen, Lt, Le, Gt, Ge, Eq, Ne, Amp, Dot, Comma, Eof,
};

struct Token {
    Tok t;
    std::string text;   // 原文（标识符/多字符运算符）
    long long num = 0;  // Int 时有效
    int line = 1;
};

struct ParseError {
    std::string msg;
    int line;
};

// 共享词法器：跳过空白，识别多字符运算符（<= >= == !=）。
std::vector<Token> lex(const std::string &src, std::vector<ParseError> &errs);

// ---------- AST（形状与第 14 章一致，便于读者前后对照） ----------
struct Expr;
using ExprP = std::unique_ptr<Expr>;

struct Expr {
    virtual ~Expr() = default;
};
struct IntLit : Expr { long long v = 0; explicit IntLit(long long x) : v(x) {} };
struct VarRef : Expr { std::string name; explicit VarRef(std::string n) : name(std::move(n)) {} };
// 一元三种：负号 -、解引用 *、取址 &（op 记 Tok）
struct Unary : Expr {
    Tok op;
    ExprP sub;
    Unary(Tok o, ExprP s) : op(o), sub(std::move(s)) {}
};
struct Binop : Expr {
    Tok op;
    ExprP l, r;
    Binop(Tok o, ExprP a, ExprP b) : op(o), l(std::move(a)), r(std::move(b)) {}
};
struct CallE : Expr {  // 被调表达式本身是任意表达式（TIP 一等函数）
    ExprP callee;
    std::vector<ExprP> args;
    CallE(ExprP c, std::vector<ExprP> a) : callee(std::move(c)), args(std::move(a)) {}
};
struct FieldA : Expr {  // 记录字段访问
    ExprP rec;
    std::string field;
    FieldA(ExprP r, std::string f) : rec(std::move(r)), field(std::move(f)) {}
};

// 括号化形状打印：(- 2 3) 式 S-表达式，嵌套一目了然。
std::string showAst(const Expr &e);

// ---------- Pratt 规则表（匠书 §17.5 的 Rule/getRule） ----------
enum class Prec {
    None = 0,    // 最低：完整表达式
    Equality,    // == !=
    Comparison,  // < <= > >=
    Term,        // + -
    Factor,      // * /
    Power,       // ^（教学扩展，右结合）
    Unary,       // 一元 -、*、&（前缀）
    Call,        // 调用 ( 与字段 .（后缀，最高）
};

// 一条规则 = 前缀回调 + 中缀回调 + 优先级 + 结合性（匠书表加一列）。
// 前缀回调：此 token 出现在"操作数位"时怎么起步；
// 中缀回调：此 token 出现在"运算符位"时左操作数已在手。
struct PrattParser;
using PrefixFn = ExprP (PrattParser::*)();
using InfixFn = ExprP (PrattParser::*)(ExprP);

struct Rule {
    PrefixFn prefix = nullptr;
    InfixFn infix = nullptr;
    Prec prec = Prec::None;
    bool rightAssoc = false;  // 右结合：递归用同级而不是高一级（见 §09.2）
};

class PrattParser {
  public:
    explicit PrattParser(std::vector<Token> toks);

    // 匠书 parsePrecedence：先吃一个前缀，再按表滚中缀循环，
    // 直到撞见优先级低于 minPrec 的运算符（或无中缀）。
    ExprP parseExpression(Prec minPrec);

    const Rule &rule(Tok t) const;         // 匠书 getRule
    void setRightAssoc(Tok t);             // 结合性实验：把某运算符改成右结合
    bool hadError() const { return !errs_.empty(); }
    const std::vector<ParseError> &errors() const { return errs_; }

  private:
    // 前缀回调
    ExprP number();      // IntLit
    ExprP variable();   // VarRef
    ExprP grouping();   // ( expr )
    ExprP unaryExpr();  // - * & 前缀
    // 中缀回调
    ExprP binary(ExprP lhs);   // 双目
    ExprP callExpr(ExprP callee);  // callee ( args )
    ExprP fieldExpr(ExprP rec);    // rec . field

    const Rule &lookup(Tok t) const;  // 先查实例覆盖（结合性实验），再查全局表

    const Token &peek() const { return toks_[pos_]; }
    Token advance();
    bool match(Tok t);
    Token expect(Tok t, const std::string &msg);

    std::vector<Token> toks_;
    size_t pos_ = 0;
    std::vector<ParseError> errs_;
    std::map<Tok, Rule> override_;  // 结合性实验的实例级改写
};

// 高一级优先级（左结合的右操作数下限）。
Prec up(Prec p);

// 一步到位：词法 + 语法。失败时返回 nullptr 并写 errs。
ExprP parsePratt(const std::string &src, std::vector<ParseError> &errs);

// ---------- 共享求值器 ----------
// env：变量值；builtins：内建函数（abs/max）。求值与解析策略无关，
// 两个解析器产出同一形状的 AST，在这里必须算出同一个数。
using BuiltinFn = std::function<long long(std::vector<long long>)>;
long long evalExpr(const Expr &e,
                   const std::map<std::string, long long> &env,
                   const std::map<std::string, BuiltinFn> &builtins,
                   std::string *err = nullptr);

}  // namespace tip

#endif  // TIP_PRATT_HPP
```

头文件较长，先标出读它的路标，再进实现细节。

**读路标一：枚举 `Prec` 从松到紧排列。** `None < Equality < Comparison
< Term < Factor < Power < Unary < Call`。这与 C 语言优先级表同向：等号
最松、乘除紧于加减、调用与字段最紧（任何东西都先于调用结合）。幂 `^`
是本章的**教学扩展**——TIP 本身没有幂运算，但讲右结合性必须有一个天然
右结合的运算符（C 的赋值 `=` 是右结合但它是语句；字符串拼接不便演示数值
对照），幂是教科书标准选择。它插在 Factor 与 Unary 之间，这个位置与 C
语言异或 `^` 的优先级区段相近，也让 §9.4 的 `-2^2` 约定讨论有戏可唱。

**读路标二：规则结构体 `Rule` 四个字段。** 前缀回调指针、中缀回调指针、
优先级、右结合标志。匠书原表（clox 的 `rules[]` 数组）只有前三个字段，
右结合性作为 §17.5 章末练习留给读者——原话大意是："现在 `+` 是左结合的。
如果给 `parsePrecedence` 传 `rule->precedence` 而不是加一，会发生什么？
挑一个真的该右结合的运算符试试。"本章把这一列显式加进表里，把练习变成
正文与机器断言（§9.5 第四段翻的就是这一格）。

**读路标三：AST 节点与第 14 章同名同形。** `IntLit/Binop/Unary/VarRef/
CallE/FieldA` 刻意与第 14 章（名字与作用域）的 TIP 表达式节点保持一致。
这不是偷懒：本章的产物会一路喂给后面的章节，形状一致意味着读者在第 14 章学到的遍历方式在这里原样适用；本章结尾的链式调用 `CallE(CallE(...))`
形状，正是第 51 章闭包分析里"被调表达式可以是任意表达式"的语法基础。

**读路标四：两个解析器、一套外围。** 头文件把词法（`lex`）、AST
（六个节点）、形状打印（`showAst`）、求值（`evalExpr`）全部放在共享层，
`PrattParser` 类只负责"token 流进、AST 出"。`llref.hpp` 只 include 这一个
头就够用——对照实验的**唯一变量**是解析策略，其余全部共用，这是实验
设计的合法性所在（§9.5 第三段展开）。

**读路标五：错误带行号走完全程。** `ParseError` 只有 `msg` 与 `line`
两个成员——词法层发现意外字符、解析层发现"期望表达式""期望 ')'"
都填它，两处来源在 `parsePratt` 的聚合处汇成一份清单。本章语料不构造
深度错误（那是第 58 章单遍编译"错误即终止"口径的对照面），但接口
从第一天就是全教程通用的"诊断 + 行号"形状，第 14 章的语义诊断将
直接复用这一协议。

### 11.2.1　从文法到表：一行产生式一行规则

把本章语言的表达式文法写成 EBNF（右递归形式，`^` 右结合单独处理）：

```text
expr     → equality
equality → comparison ( (==|!=) comparison )*
cmp      → term ( (<|<=|>|>=) term )*
term     → factor ( (+|-) factor )*
factor   → power ( (*|/) power )*
power    → unary ( ^ power )?          ← 右结合：递归在右侧
unary    → (-|*|&) unary | postfix
postfix  → primary ( "(" args ")" | "." IDENT )*
primary  → INT | IDENT | "(" expr ")"
```

现在把每条产生式**机械翻译**成表行，翻译规则只有三条：

| 文法形状 | 表格动作 |
|---|---|
| 产生式右部**开头**的 token | 成为此行的**前缀**回调 |
| 产生式右部**中部**的 token（左操作数已解析） | 成为此行的**中缀**回调，优先级 = 所在层 |
| 右递归 `power → unary ( ^ power )?` | 右结合位 = 真（递归落在右侧） |

逐行翻译的结果就是 9.3.3 那张表——文法与表是同一事实的两种记法。这个
对应有两点值得咀嚼。**第一点：分层法的"层"在表里变成"优先级档位"。**
EBNF 里六个产生式首部（equality/cmp/term/factor/power/unary）在表里
只剩六个数字，产生式本体消失，被"中缀回调 + 滚环"取代——这正是压缩的
来源：分层法每层一个函数是因为每层要写一遍"吃运算符、取右部、递归
自身"的模板，Pratt 发现这个模板对所有双目运算符**完全相同**，于是只写
一次（`binary`），差异全部参数化进表。拿一条产生式做完整的翻译示范，
其余各条同法：取 `term → factor ( (+|-) factor )*`——星号循环说明
"同级可重复"（左结合）；循环体里的 `(+|-)` 两个 token 各得一行表行，
前缀列空（它们不出现在操作数位）、中缀列填 `binary`、优先级填 Term；
`factor` 出现在操作数位，对应"右操作数下限取 up(Term) = Factor"。
一行 EBNF 翻成两行表加一条下限规则，反向亦然——建议读者对其余五层
各做一次双向翻译，这是把"表即文法"从口号变成手感的最快路径。
**第二点：右结合在文法里是"递归
在右"这一书写位置的差异**，在表里是"递归下限取同级"这一格布尔的差异
——两种记法互相印证，就再也不怕"抄错模板"：想验证表的结合性列，把
表翻译回 EBNF 看一眼递归在哪侧即可，比读十层函数快得多。

反方向的翻译同样成立：拿到任何一张 Pratt 表（比如后文第 58 章字节码
编译器的发码表），先按优先级列排序、再看每行的回调类型，就能机械恢复
出 EBNF——**表即文法，文法即表**。这也是"文法是分析器的第一份合同"
（第 4 章口号）在 Pratt 语境下的形态：合同从文法文件变成了源代码里
一张可读、可 diff、可测试的表。

## 11.3　实现：一个循环、一张表、两类回调

```cpp
// file: src/pratt.cpp
// file: src/pratt.cpp
#include "pratt.hpp"

#include <cctype>
#include <sstream>

namespace tip {

// ---------- 词法 ----------
std::vector<Token> lex(const std::string &src, std::vector<ParseError> &errs) {
    std::vector<Token> out;
    size_t i = 0;
    int line = 1;
    auto push2 = [&](Tok t, std::string s) { out.push_back({t, std::move(s), 0, line}); };
    while (i < src.size()) {
        char c = src[i];
        if (c == '\n') { ++line; ++i; continue; }
        if (std::isspace(static_cast<unsigned char>(c))) { ++i; continue; }
        if (std::isdigit(static_cast<unsigned char>(c))) {
            std::string s;
            while (i < src.size() && std::isdigit(static_cast<unsigned char>(src[i]))) s += src[i++];
            long long v = 0;
            std::istringstream(s) >> v;
            out.push_back({Tok::Int, s, v, line});
            continue;
        }
        if (std::isalpha(static_cast<unsigned char>(c)) || c == '_') {
            std::string s;
            while (i < src.size() &&
                   (std::isalnum(static_cast<unsigned char>(src[i])) || src[i] == '_'))
                s += src[i++];
            push2(Tok::Ident, std::move(s));
            continue;
        }
        // 双字符运算符先行
        if (i + 1 < src.size()) {
            std::string two = src.substr(i, 2);
            if (two == "<=") { push2(Tok::Le, two); i += 2; continue; }
            if (two == ">=") { push2(Tok::Ge, two); i += 2; continue; }
            if (two == "==") { push2(Tok::Eq, two); i += 2; continue; }
            if (two == "!=") { push2(Tok::Ne, two); i += 2; continue; }
        }
        switch (c) {
            case '+': push2(Tok::Plus, "+"); break;
            case '-': push2(Tok::Minus, "-"); break;
            case '*': push2(Tok::Star, "*"); break;
            case '/': push2(Tok::Slash, "/"); break;
            case '^': push2(Tok::Caret, "^"); break;
            case '(': push2(Tok::LParen, "("); break;
            case ')': push2(Tok::RParen, ")"); break;
            case '<': push2(Tok::Lt, "<"); break;
            case '>': push2(Tok::Gt, ">"); break;
            case '=': push2(Tok::Eq, "="); break;   // 语料只用 ==
            case '&': push2(Tok::Amp, "&"); break;
            case '.': push2(Tok::Dot, "."); break;
            case ',': push2(Tok::Comma, ","); break;
            default:
                errs.push_back({"意外字符 '" + std::string(1, c) + "'", line});
                break;
        }
        ++i;
    }
    out.push_back({Tok::Eof, "", 0, line});
    return out;
}

// ---------- 形状打印 ----------
std::string showAst(const Expr &e) {
    if (auto *n = dynamic_cast<const IntLit *>(&e)) return std::to_string(n->v);
    if (auto *n = dynamic_cast<const VarRef *>(&e)) return n->name;
    if (auto *n = dynamic_cast<const Unary *>(&e)) {
        std::string op = n->op == Tok::Minus ? "-" : (n->op == Tok::Star ? "*" : "&");
        return "(" + op + " " + showAst(*n->sub) + ")";
    }
    if (auto *n = dynamic_cast<const Binop *>(&e)) {
        std::string op;
        switch (n->op) {
            case Tok::Plus: op = "+"; break;   case Tok::Minus: op = "-"; break;
            case Tok::Star: op = "*"; break;   case Tok::Slash: op = "/"; break;
            case Tok::Caret: op = "^"; break;  case Tok::Lt: op = "<"; break;
            case Tok::Le: op = "<="; break;    case Tok::Gt: op = ">"; break;
            case Tok::Ge: op = ">="; break;    case Tok::Eq: op = "=="; break;
            default: op = "!="; break;
        }
        return "(" + op + " " + showAst(*n->l) + " " + showAst(*n->r) + ")";
    }
    if (auto *n = dynamic_cast<const CallE *>(&e)) {
        std::string s = "(call " + showAst(*n->callee);
        for (const auto &a : n->args) s += " " + showAst(*a);
        return s + ")";
    }
    if (auto *n = dynamic_cast<const FieldA *>(&e))
        return "(. " + showAst(*n->rec) + " " + n->field + ")";
    return "?";
}

// ---------- Pratt 解析器 ----------
PrattParser::PrattParser(std::vector<Token> toks) : toks_(std::move(toks)) {}

Prec up(Prec p) { return static_cast<Prec>(static_cast<int>(p) + 1); }

// 规则表本体：一张表就是整门语言的表达式文法。
// 对比第 6 章 LL(1)：那里每层优先级一个函数（cmp/add/mul/unary/primary），
// 这里每层只是表里的一行；加运算符 = 加/改一格，函数一个不动。
static Rule makeRule(PrefixFn p, InfixFn i, Prec prec, bool right = false) {
    return Rule{p, i, prec, right};
}

const Rule &PrattParser::rule(Tok t) const {
    // 匠书把表写成 Parser 类里的 static 数组；C++ 成员函数指针表这里用
    // 进程级单例 map（线程安全局部 static，本教程单线程）。
    struct Tables {
        std::map<Tok, Rule> map;
        Tables() {
            auto P = &PrattParser::number, V = &PrattParser::variable;
            auto G = &PrattParser::grouping, U = &PrattParser::unaryExpr;
            auto B = &PrattParser::binary, C = &PrattParser::callExpr, F = &PrattParser::fieldExpr;
            map[Tok::Int]    = makeRule(P, nullptr, Prec::None);
            map[Tok::Ident]  = makeRule(V, nullptr, Prec::None);
            map[Tok::LParen] = makeRule(G, C, Prec::Call);   // 前缀=分组，中缀=调用
            map[Tok::Minus]  = makeRule(U, B, Prec::Term);   // 前缀=负号，中缀=减
            map[Tok::Star]   = makeRule(U, B, Prec::Factor); // 前缀=解引用，中缀=乘
            map[Tok::Amp]    = makeRule(U, nullptr, Prec::None);
            map[Tok::Plus]   = makeRule(nullptr, B, Prec::Term);
            map[Tok::Slash]  = makeRule(nullptr, B, Prec::Factor);
            map[Tok::Caret]  = makeRule(nullptr, B, Prec::Power, /*right=*/true);
            map[Tok::Eq]     = makeRule(nullptr, B, Prec::Equality);
            map[Tok::Ne]     = makeRule(nullptr, B, Prec::Equality);
            map[Tok::Lt]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Le]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Gt]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Ge]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Dot]    = makeRule(nullptr, F, Prec::Call);
        }
    };
    static const Tables tbl;
    static const Rule kNone{};  // 不在表里的 token（) , EOF）无前缀无中缀
    auto it = tbl.map.find(t);
    return it != tbl.map.end() ? it->second : kNone;
}

void PrattParser::setRightAssoc(Tok t) {
    Rule r = lookup(t);  // 拷贝一份进实例覆盖表——结合性实验只动这个实例
    r.rightAssoc = true;
    override_.insert_or_assign(t, r);
}

Token PrattParser::advance() {
    if (toks_[pos_].t != Tok::Eof) ++pos_;
    return toks_[pos_ - 1];
}

bool PrattParser::match(Tok t) {
    if (peek().t != t) return false;
    advance();
    return true;
}

Token PrattParser::expect(Tok t, const std::string &msg) {
    if (peek().t == t) return advance();
    errs_.push_back({msg + "，但看到 '" + peek().text + "'", peek().line});
    return peek();
}

ExprP PrattParser::parseExpression(Prec minPrec) {
    const Rule &start = rule(peek().t);
    if (start.prefix == nullptr) {
        errs_.push_back({"期望表达式，但看到 '" + peek().text + "'", peek().line});
        return nullptr;
    }
    ExprP lhs = (this->*start.prefix)();
    if (!lhs) return nullptr;
    while (true) {
        const Rule &r = lookup(peek().t);  // 先看实例覆盖（结合性实验），再查全局表
        if (r.infix == nullptr || static_cast<int>(r.prec) < static_cast<int>(minPrec)) break;
        lhs = (this->*r.infix)(std::move(lhs));
        if (!lhs) return nullptr;
    }
    return lhs;
}

const Rule &PrattParser::lookup(Tok t) const {
    if (auto it = override_.find(t); it != override_.end()) return it->second;
    return rule(t);
}

ExprP PrattParser::number() {
    Token t = advance();
    return std::make_unique<IntLit>(t.num);
}

ExprP PrattParser::variable() {
    Token t = advance();
    return std::make_unique<VarRef>(t.text);
}

ExprP PrattParser::grouping() {
    advance();  // 吃掉 (
    ExprP inner = parseExpression(Prec::None);  // 分组回到最低优先级：括号内是完整表达式
    expect(Tok::RParen, "期望 ')'");
    return inner;
}

ExprP PrattParser::unaryExpr() {
    Token op = advance();                       // - * & 三种前缀
    ExprP sub = parseExpression(Prec::Unary);   // 操作数允许更高优先级的前缀链：- - x、* * p
    if (!sub) return nullptr;
    return std::make_unique<Unary>(op.t, std::move(sub));
}

ExprP PrattParser::binary(ExprP lhs) {
    Token op = advance();
    // 结合性在此一行分岔（第 6 章把它焊死在函数调用图里）：
    //   左结合：右操作数用"高一级"minPrec —— 同级运算符回到外层循环，左边先结合；
    //   右结合：右操作数用"同级"minPrec —— 递归先吃掉右边的同级运算符。
    const Rule &r = lookup(op.t);
    Prec rhsMin = r.rightAssoc ? r.prec : up(r.prec);
    ExprP rhs = parseExpression(rhsMin);
    if (!rhs) return nullptr;
    return std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs));
}

ExprP PrattParser::callExpr(ExprP callee) {
    advance();  // 吃掉 (
    std::vector<ExprP> args;
    if (peek().t != Tok::RParen) {
        args.push_back(parseExpression(Prec::None));
        while (match(Tok::Comma)) args.push_back(parseExpression(Prec::None));
        for (const auto &a : args) if (!a) return nullptr;
    }
    expect(Tok::RParen, "期望 ')'");
    return std::make_unique<CallE>(std::move(callee), std::move(args));
}

ExprP PrattParser::fieldExpr(ExprP rec) {
    advance();  // 吃掉 .
    if (peek().t != Tok::Ident) {
        errs_.push_back({"期望字段名", peek().line});
        return nullptr;
    }
    Token f = advance();
    return std::make_unique<FieldA>(std::move(rec), f.text);
}

ExprP parsePratt(const std::string &src, std::vector<ParseError> &errs) {
    std::vector<Token> toks = lex(src, errs);
    PrattParser p(std::move(toks));
    ExprP e = p.parseExpression(Prec::None);
    if (p.hadError()) {
        errs.insert(errs.end(), p.errors().begin(), p.errors().end());
        return nullptr;
    }
    return e;
}

// ---------- 求值 ----------
long long evalExpr(const Expr &e,
                   const std::map<std::string, long long> &env,
                   const std::map<std::string, BuiltinFn> &builtins,
                   std::string *err) {
    auto fail = [&](const std::string &m) {
        if (err) *err = m;
        return 0;
    };
    if (auto *n = dynamic_cast<const IntLit *>(&e)) return n->v;
    if (auto *n = dynamic_cast<const VarRef *>(&e)) {
        auto it = env.find(n->name);
        if (it == env.end()) return fail("未定义变量 " + n->name);
        return it->second;
    }
    if (auto *n = dynamic_cast<const Unary *>(&e)) {
        long long v = evalExpr(*n->sub, env, builtins, err);
        if (err && !err->empty()) return 0;
        if (n->op == Tok::Minus) return -v;
        return fail("解引用/取址只在形状语料出现，不求值");
    }
    if (auto *n = dynamic_cast<const Binop *>(&e)) {
        long long a = evalExpr(*n->l, env, builtins, err);
        if (err && !err->empty()) return 0;
        long long b = evalExpr(*n->r, env, builtins, err);
        if (err && !err->empty()) return 0;
        switch (n->op) {
            case Tok::Plus: return a + b;
            case Tok::Minus: return a - b;
            case Tok::Star: return a * b;
            case Tok::Slash:
                if (b == 0) return fail("除零");
                return a / b;
            case Tok::Caret: {  // 幂（教学扩展）：小指数整数幂
                long long r = 1;
                if (b < 0) return fail("负指数");
                for (long long k = 0; k < b; ++k) r *= a;
                return r;
            }
            case Tok::Lt: return a < b;
            case Tok::Le: return a <= b;
            case Tok::Gt: return a > b;
            case Tok::Ge: return a >= b;
            case Tok::Eq: return a == b;
            default: return a != b;
        }
    }
    if (auto *n = dynamic_cast<const CallE *>(&e)) {
        auto *f = dynamic_cast<const VarRef *>(n->callee.get());
        if (!f) return fail("被调者必须是标识符（语料口径）");
        auto it = builtins.find(f->name);
        if (it == builtins.end()) return fail("未定义函数 " + f->name);
        std::vector<long long> args;
        for (const auto &a : n->args) {
            long long v = evalExpr(*a, env, builtins, err);
            if (err && !err->empty()) return 0;
            args.push_back(v);
        }
        return it->second(std::move(args));
    }
    return fail("字段访问只在形状语料出现，不求值");
}

}  // namespace tip
```

实现共三百余行，按读的顺序分六块讲。前三块是算法本体，后三块是支撑
设施——但支撑设施里也有几处值得专程看的设计。

### 11.3.1　词法器：共享层的第一件

`lex` 跳空白、记行号、认双字符运算符（`<= >= == !=` 先于单字符判断——
最长匹配原则，与第 5 章多模式 scanner 的口径一致）、数字与标识符。两个
细节：其一，`=` 单字符被映射到 `Tok::Eq` 是防御性设计——语料里只该出现
`==`，若手滑写了单等号，解析层会把它当等号处理而不是抛"意外字符"，
错误信息更接近笔误本相；其二，行号 `line` 一路带进 `ParseError`，这是
第 4 章以来诊断行号传统的延续，本章错误不多，但习惯从词法层就养成。

拿 `(1<=2)` 手推一遍词法，检验最长匹配的落点：读到 `(`，不与任何双
字符前缀匹配，单字符规则发出 `LParen`；读到 `1`，数字循环吞完 `1` 发出
`Int(1)`；读到 `<`，先查双字符表——`<=` 命中，一次前进两位发出 `Le`
（**注意这次没有先发 `<` 再发 `=`**：双字符判断在单字符 switch 之前，
这就是最长匹配在顺序上的实现）；读到 `2` 发出 `Int(2)`；读到 `)` 发出
`RParen`；末尾补 `Eof` 哨兵。六字符进、六个 token 出，行号全程为 1。
若把双字符表挪到 switch 之后，`<=` 会裂成 `Lt` 加一个"意外字符'='"——
练习 8 请读者亲手做这个破坏实验。

错误信息的三条措辞也值得读一眼："意外字符"、"期望表达式"、"期望
')'"——全部**名词化**（说看到了什么、缺什么），不说"语法错误"这种
分类词。这是诊断措辞的家规（第 4 章 ANTLR 的诊断同款）：分类词让
读者去查表，名词化让读者直接看到事故现场。词法层还把出事字符原样
带进消息（`'&'`），配合行号，一条消息即一处现场。

词法器放在共享层而不是 PrattParser 内部，直接原因是对照实验需要 LL
参照物吃到同一串 token；更深一层的原因是：**词法与语法是两个独立的责任**
（第 4 章文法是分析器的合同，词法是合同里的字汇表），Pratt 化只动语法
层，词法层没有理由跟着动。第 58 章会看到反例的妙处：单遍编译器把词法
做成"即取即用"协程式的三函数（advance/peek/match），那时词法与语法
重新贴紧——但那是**部署形态**的贴紧，不是**责任**的合并。

### 11.3.2　主循环：十行核心

`parseExpression` 是全部算法的居所，值得逐行抄下来盘问：

```cpp
ExprP lhs = (this->*start.prefix)();       // ① 先吃一个前缀
while (true) {
    const Rule &r = lookup(peek().t);      // ② 看下一个 token 的规则
    if (r.infix == nullptr ||              //    不是中缀，或
        static_cast<int>(r.prec) < static_cast<int>(minPrec))  // 比下限松
        break;                             //    就把控制权交还给调用者
    lhs = (this->*r.infix)(std::move(lhs));  // ③ 否则吃运算符，滚环继续
}
```

第①步：表达式一定从操作数位开始，所以查当前 token 的**前缀**回调；没有
前缀（比如一开头就是 `)` 或 `,`）就报"期望表达式"。注意报错的是**位置**
不是 token——同一个 `(`，在操作数位是分组（合法），在运算符位之後才是
调用；同一个 `*`，在操作数位是解引用，在运算符位是乘法。Pratt 的前缀/
中缀二分天然把"一个记号多种用法"编码进了两条回调，不需要额外的上下文
状态。

第③步：左操作数在手，查当前 token 的**中缀**回调，让回调自己去吃右
操作数并合成更大的节点。回调返回后滚环继续——**循环每滚一轮，表达式就
往左多长一格**（新节点把旧 `lhs` 吃进左子树）。

退出条件是整个算法的灵魂：**"低于我的下限，我做不了主"**。`minPrec` 是
调用者授权这个调用能处理的最低优先级：顶层调用传 `None`（什么都管）；
双目运算符吃右操作数时会抬高下限（右结合取同级、左结合取高一级，见
9.3.4）；于是"优先级爬升"（precedence climbing——这个方法的另一个名字）
由此得名——优先级一路往上爬，爬到松于下限的运算符就停下来，把控制权
还给上一层调用者。

算法的两条基本性质值得用两句话论证，它们是后面一切推演的地基。
**终止性**：滚环每迭代一次至少消耗一个 token（中缀回调必吃运算符
本身），前缀起步消耗一个，而 token 有限——循环必然停，解析必然返回。
**恰好性**（对下限归纳）：命题"parseExpression(p) 恰好识别'以不低于 p
的优先级开始'的表达式"。归纳基础是 p 最高（Call）时只容最紧的后缀链；
归纳步看滚环——遇到松于 p 的运算符让权（保证不越界），遇到不低于 p 的
运算符按其规则展开（保证不漏）。两条性质合起来：**输入是文法语言中的
串时产出唯一正确的树；输入不是时在最早的可判定处报"期望表达式"或
"期望 ')'"**。第 6 章 LL(1) 的等价性质靠 FIRST/FOLLOW 定理保证，Pratt
的靠这两句归纳——短得多，代价是它只覆盖"运算符优先级可表达"的文法
（语句结构没有优先级可言，仍归递归下降管）。

顺带把第 6 章的**表驱动预测分析器**也拉进来，三方对照才完整：LL(1)
表驱动用"栈 + M[A, a] 产生式表"模拟最左推导——栈里放符号，表里放
"非终结符 × 终结符 → 产生式右部"；Pratt 用"调用栈 + 运算符规则表"
做同样的事——调用栈里放"待完成的部分"，表里放"token × 位置 → 回调"。
两块表的内容不同（产生式 vs 运算符规则），但**结构同构**：都是"查表
决定下一步动作，动作更新栈，栈空即接受"。真正的分野在表的**来源**：
LL(1) 的表由 FIRST/FOLLOW 从文法算出（所以有 LL(1) 资格审查），Pratt
的表由人写（所以没有资格审查、也就没有冲突报告）。理解了这一点，
"LL 表驱动 / LR 表驱动 / Pratt 表驱动"三兄弟的关系就齐了：**表驱动
是共同的外形，表的自动性与覆盖面是各家的立场**。

用 `2-3-4` 走一遍完整生涯（`-` 是 Term 级、左结合）：

| 步 | 动作 | 栈上视角 | 说明 |
|---|---|---|---|
| 1 | 顶层 `parseExpression(None)`：前缀吃 `2` | `2` | `IntLit(2)` |
| 2 | 见 `-`，Term ≥ None，进 `binary` | `2` | 中缀回调激活 |
| 3 | `binary` 吃 `-`，右操作数下限 = up(Term) = Factor | | 左结合抬一级 |
| 4 | 递归 `parseExpression(Factor)`：前缀吃 `3` | `3` | 新的一层 |
| 5 | 该层见 `-`，Term < Factor，**停** | `3` | 让权：这是外层的运算符 |
| 6 | `binary` 合成 `(2-3)`，回到顶层循环 | `2-3` | 左边先结合 |
| 7 | 又见 `-`，Term ≥ None，再滚一轮 | `2-3` | 右操作数 `4` |
| 8 | 合成 `((2-3)-4)`，无后续，返回 | `2-3-4` | 求值 -5 |

对照第 6 章分层法对同一输入的调用序列：`cmp → add → mul → unary →
primary`（吃 2）→ 返回到 `addRest`（吃 `-`）→ `mul → unary → primary`
（吃 3）→ `addRest` 再循环（吃 `-`）……**两种方法吃 token 的顺序完全
相同，产出完全相同的树，区别只在"谁决定下一步"**——分层法由调用图决定，
Pratt 由表与下限决定。

再看两个必须亲手走一遍才能内化的追踪。第一个是 `1+2*3`——"爬升"之名
的出处：

| 步 | 层（下限） | 动作 | 让权判断 |
|---|---|---|---|
| 1 | 顶层（None） | 前缀吃 `1` | |
| 2 | 顶层 | 见 `+`（Term ≥ None）→ `binary` | 授权范围内 |
| 3 | 递归（Factor） | 前缀吃 `2` | 左结合抬了一级 |
| 4 | 递归 | 见 `*`（Factor ≥ Factor）→ `binary` | **不让权**：正好压线 |
| 5 | 递归（Power） | 前缀吃 `3` | 又抬一级 |
| 6 | 递归 | 无中缀，返回 `(2*3)` | |
| 7 | 顶层 | `binary` 合成 `(1+(2*3))`，滚环无后续 | |

第 4 步是关键：`*` 的优先级 Factor 与递归层下限 Factor 相等，条件用的是
**大于等于**——压线不让权，乘法得以进入 `+` 的右操作数。若条件误写为
严格大于，`1+2*3` 会解析成 `(1+2)*3`：一个比较符号之差，整套优先级
坍塌为"全部左结合"。这个边界在写 Pratt 循环时最容易笔误，值得用一条
语料锁死（练习 1 的 `%` 与既有 `*` 同级，正好压线）。

第二个是 `f(1)(2)`——两个最紧的中缀轮流滚环：

| 步 | 动作 | 结果 |
|---|---|---|
| 1 | 前缀 `variable` 吃 `f` | `VarRef(f)` |
| 2 | 见 `(`，规则是 Call 级中缀 `callExpr` | 左操作数 = `f` |
| 3 | `callExpr` 收集实参 `[1]`，吃 `)` | `CallE(f, 1)` |
| 4 | 滚环：又见 `(`，还是 `callExpr` | 左操作数 = `CallE(f,1)` |
| 5 | 收集实参 `[2]` | `CallE(CallE(f,1), 2)` |

注意第 4 步不需要任何"这已经是第二次调用"的状态——循环天然支持任意
长度的后缀链。这与第 7 章 LR 状态栈形成对照：LR 里每一步移进都由状态
决定，链式调用的每一步是一个新状态；Pratt 里每一步由"运算符位查表"
决定，链的长度不增加任何机制。

`1+2*3` 再走一遍看"爬升"如何体现：顶层吃 `1`，见 `+`（Term）≥ None，
`binary` 吃 `+`，右操作数下限 Factor；递归层吃 `2` 后见 `*`（Factor ≥
Factor，**不**让权），进 `binary` 吃 `*`，右操作数下限 up(Factor) =
Power，吃到 `3`；合成 `(2*3)` 返回；外层合成 `(1+(2*3))`。乘法之所以
先结合，不是因为有一个叫 `mul` 的函数被 `add` 调用，而是因为 Factor ≥
Factor 这一比较**允许递归层继续做主**。`(1+2)*3` 则由括号改写牌桌：
`grouping` 前缀回调吃 `(` 后以 `None` 为下限递归，括号内 `1+2` 完整
结合后交还，随后的 `*` 在括号外与 `(1+2)` 合成——括号没有优先级，
它只是**重置**优先级博弈的下限。

### 11.3.3　规则表：一张表读出整门文法

表本体在 `rule()` 函数的 `Tables` 单例里。匠书用 C 的静态数组
（下标即 token 枚举），C++ 版本有两处语言适配：其一，回调是**成员函数
指针**（`ExprP (PrattParser::*)()`），取地址 `&PrattParser::number` 不
需要实例（成员指针是"偏移量"语义）；其二，表用 `std::map<Tok, Rule>`
配合 `find` 而不是数组下标——不在表里的 token（`)`、`,`、EOF）返回
全空的默认 `Rule{}`，前缀中缀皆空，自然被主循环当"不认识"处理。这两处
是语言适配，不是算法差异；匠书的 C 版本把"不在表里"表示为数组里的
`NULL, NULL, PREC_NONE` 行，语义相同。

把表抄成文字版，一行行读——**这张表就是本章语言的表达式文法全文**：

| token | 前缀 | 中缀 | 优先级 | 右结合 |
|---|---|---|---|---|
| `Int` / `Ident` | 字面量/变量 | — | — | — |
| `(` | 分组 | 调用 | Call | 否 |
| `-` | 负号 | 减 | Term | 否 |
| `*` | 解引用 | 乘 | Factor | 否 |
| `&` | 取址 | — | — | — |
| `+` `/` | — | 双目 | Term / Factor | 否 |
| `^` | — | 双目 | Power | **是** |
| `==` `!=` | — | 双目 | Equality | 否 |
| `< <= > >=` | — | 双目 | Comparison | 否 |
| `.` | — | 字段 | Call | 否 |

读表的三条收获，对应 9.1 的三个痛点：**优先级列**就是痛点一的答案——
插一个 `&` 双目运算符只需在表里加一行、给它挑一个位置，任何函数都不用
动；**右结合列**就是痛点二的答案——结合性是一格数据；**前缀/中缀两列**
就是痛点三的答案——`-` 的一元与双目、`(` 的分组与调用，各自是同一行的
两个指针，记号的类别不再需要"层"来表达。

表的构造时机是 C++ 语言细节里值得一笔的地方：`Tables` 是函数内的局部
静态（Meyers 单例惯用法）——首次调用 `rule()` 时构造一次，此后全程
共享。为什么不放全局静态？成员函数指针表依赖 `PrattParser` 类完整
定义，放类外全局容易踩初始化顺序坑；局部静态把构造时机推迟到首次
使用，顺序问题消失。另一个家规级细节：`lookup` 对覆盖表用 `find`
而不是 `operator[]`——本教程的 map 铁律（查询语义绝不 `[]`，它会给
不存在的键凭空造默认值），本章覆盖表恰好永远先写后读，铁律在这里
是"保险带没扣但还是要扣"。

一 token 双角色值得多看两眼。`LParen` 行的前缀是 `grouping`（吃 `(` 后
递归取完整表达式再吃 `)`），中缀是 `callExpr`（左操作数是被调者，吃 `(`
收集实参）。`2*(3+4)` 里的 `(` 出现在操作数位走前缀，`f(3)` 里的 `(`
出现在 `f` 之后走中缀——**位置决定角色**，这正是 Pratt"自顶向下"的含义：
树从操作数位自顶向下长出来，每长一层都由当前位置查表决定下一步。第 7 章 LR 分析里这两个 `(` 是两个不同的移进动作、由状态区分；Pratt 由"等号
左边是不是已有操作数"区分——同一个信息，两种编码。

### 11.3.4　结合性：一行分岔

`binary` 回调里，右操作数的下限怎么定，就决定了结合性：

```cpp
const Rule &r = lookup(op.t);
Prec rhsMin = r.rightAssoc ? r.prec : up(r.prec);  // 右结合=同级，左结合=高一级
```

左结合取**高一级**（`up(prec)`）：递归层见同级即让权，同级运算符永远
回到外层循环，左边的先结合——9.3.2 的 `2-3-4` 推演就是这条路。右结合
取**同级**：递归层见同级**不让权**，继续吃，于是右边先结合。`2^3^2`
走一遍：

| 步 | 动作 | 说明 |
|---|---|---|
| 1 | 顶层吃 `2`，见 `^`（Power ≥ None），进 `binary` | |
| 2 | 右操作数下限 = Power（同级，不抬） | 右结合的关键一步 |
| 3 | 递归 `parseExpression(Power)`：吃 `3`，又见 `^` | |
| 4 | Power ≥ Power，**不让权**，再进 `binary` | 递归层自己做主 |
| 5 | 右操作数 `2`，合成 `(3^2)` 逐层返回 | 右边先结合 |
| 6 | 外层合成 `2^(3^2)` = 512 | 对照 `(2^3)^2` = 64 |

这两行代码同时解释了匠书 jlox 的翻车原理：jlox 每层函数的模板把"吃右
操作数"写死成调用**下一层**（等价于恒取 `up(prec)`，即左结合模板），
`==` 层照抄模板没错；但只要有一层照抄错了对象——或像 `unary` 那样递归
自身（同级，即右结合形状）——结合性就静默翻转。分层法里这个决定分散在
十几层函数的模板一致性里；Pratt 把它收进表里的一格布尔。实验里翻它
只需 `setRightAssoc(Tok::Minus)`：这个成员函数把全局表里那条规则拷贝
一份、改掉右结合位、存进实例级覆盖表 `override_`——注意为什么需要
覆盖表：全局表是进程级单例（所有解析器实例共享），实验要"只动这个
实例"，所以改写必须发生在实例自己的 `override_` 里，`lookup` 先查覆盖
再查全局。小设计，但它是"表可编辑"从口号变成机制的一步。

结合性翻转在真实语言里的分量，值得多列三个事实。**其一，赋值链是右
结合的正当用户**：`a = b = c` 的惯用义是"a 取（b 取 c）"，若按左结合
`(a = b) = c` 则要求 `a = b` 这个表达式可被赋值——C 把赋值表达式当右值
用、甚至允许 `(a = b) = c` 编译（实为未定义行为），就是两种结合都能写
下去的语法沼泽；多数新语言直接砍掉嵌套赋值。**其二，幂的右结合有数学
理由**：`a^b^c` 在数学排版里就读作 a 的 b^c 次方（右结合），Haskell 的
`^`、Python 的 `**`、MATLAB 的 `^` 全部右结合。**其三，比较链是"非
结合"的第三种可能**：`a < b < c` 若左结合是 `(a<b)<c`——布尔与整数
相斗，类型上就讲不通；Python 专门把它定义成 `a<b and b<c` 的语法糖，
C 则按左结合给出"能编译但多半不是你想要的"结果。本章口径与 C 一致
（比较按左结合、真 1 假 0），练习 2 会展示同值巧合如何掩盖这个问题。
结合性三态（左/右/非）里，Pratt 表那格布尔覆盖前两态，第三态需要回调
里显式报错——第 58 章的字节码编译器会看到完整光谱。

### 11.3.5　前缀回调四种、中缀回调三种

**`number` / `variable`**：各吃一个 token 造叶子，无需多言。值得一提的
是它们不检查后续——叶子造完立即回到主循环，后续 token 归循环裁决。

**`grouping`**：吃 `(` 后以 `None` 为下限递归——括号内是完整表达式。
练习 4 会问：这个下限若改成 `Term`，`(1+2)*3` 会发生什么（提示：递归层
见到 `+`（Term ≥ Term）会继续吃，但更松的运算符会让权——对 `(1 == 2)`
这类括号内是 Equality 级的式子，递归层在 `==` 之前就停了，把 `==` 留给
外层循环，而外层的下限是 None 也能吃——结果竟可能"碰巧"对，但对
`(1+2)+3` 与更松的运算符组合就会产生形状漂移。答案留给练习，这里指出
**下限的语义是"授权"而不是"要求"**：传 None 表示"低于 None 的都不存在，
你可以处理一切"，不是"你必须处理到 None"）。

**`unaryExpr`**：吃掉 `-`/`*`/`&` 后以 `Unary` 为下限递归取操作数。下限
是 Unary 意味着操作数可以继续是前缀（`--x`、`* * p`）或最紧的 Call 级
后缀（`-f(3)`、`*p.f`），但不能是双目左结合的松运算——`-a+b` 里负号只
管 `a`，因为递归层见到 `+`（Term < Unary）会让权。一元运算符"很紧"是
C 家族的通行约定，但也有语言（如 Haskell 的 `$`、Unix 管道思想）把一元
做得极松——在 Pratt 表里这都只是 `unaryExpr` 递归下限的一个数字。

**`binary`**：9.3.4 已详述，双目通用回调。注意它是**无状态**的：不记
"我已经吃了几个运算符"，滚环的计数由主循环隐式维护——每滚一轮恰好
一个运算符。

**`callExpr`**：把左操作数当被调者，吃 `(` 后按 `表达式 (, 表达式)*`
收集实参直到 `)`。实参之间允许 `)` 出现在主循环退出条件里（`)` 无中缀
规则，让权），`match(Tok::Comma)` 驱动下一个实参。每个实参以 `None` 为
下限——实参是完整表达式。

`abs(3-8)*2` 值得整段追踪，因为它同时展示了**嵌套的 parseExpression
调用栈**——三个层次各持各的下限，互不越权：

| 调用层 | 下限 | 做的事 |
|---|---|---|
| 顶层 | None | 前缀吃 `abs`；见 `(`（Call ≥ None）进 `callExpr` |
| callExpr 内 | None（每实参） | 解析实参 `3-8`：前缀 3、见 `-`（Term）滚环、吃 8、合成 `(3-8)`；随后 `)` 终止实参表 |
| 顶层（续） | None | `callExpr` 返回 `CallE(abs, [3-8])`；滚环见 `*`（Factor）进 `binary` |
| binary 内 | Factor | 前缀吃 `2`，无后续，返回；合成 `(CallE * 2)` |

最深时刻调用栈上有三层 parseExpression（顶层、实参层、右操作数层），
分别拿着 None、None、Factor 三张授权书。`3-8` 里的 `-` 对实参层合法
（Term ≥ None），对右操作数层就未必（若它是 `1-2` 会因 Term < Factor
让权）——**同一条规则在不同下限面前有不同裁决**，这是理解 Pratt 的
分水岭：优先级不是 token 的属性，是 token 与下限的**关系**。

**`fieldExpr`**：吃 `.` 后要求一个标识符做字段名，合成 `FieldA`。字段名
**不进 AST 的表达式层**（它是标签不是子表达式，与第 14 章名字解析时
"字段名不参与变量解析"的口径一致）。

调用与字段的优先级是 `Call`——全表最紧。于是 `f(1)(2)` 顺理成章解析成
`(call (call f 1) 2)`：链式调用在分层法里需要专门的"后缀层"（jlox 的
`call()` 函数恰是干这个的），在表里只是"中缀 `(` 的回调滚了两轮"。
`f(1).g(2)` 这类"调用-字段-再调用"的混链也不需要任何新机制——两张最紧
的规则轮流滚环而已。

### 11.3.6　求值器：与解析策略彻底解耦

`evalExpr` 遍历 AST 逐节点求值：双目算术（int64，TIP 整数口径）、比较
（真为 1 假为 0，延续 TIP 把布尔当整数的传统——第 3 章）、调用查内建表、
除零与负指数报错、幂用小指数循环乘（教学扩展的配套简化，不追求快速幂）。

两个设计决定值得说明。**其一，解引用与字段访问不求值**：它们只在"形状
语料"（§9.4）出现，求值器遇到即报错。本章只关心**解析**，指针与记录的
运行时语义在第 18 章之后才存在；让求值器对它们报错而不是返回 0，能把
"语料越界"从静默错误变成显式诊断。**其二，错误用出参 `err` 字符串而不是
异常**：求值器可能被对照实验在循环里调几百次，异常的栈展开对教学程序
是噪音；`err` 非空即失败，调用方 `evalStr` 统一翻译成"错误:…"字符串，
让错误本身成为可对账的输出行。

求值器与解析策略完全无关，这正是对照实验的合法性所在：两个解析器产出
同构的树，喂进同一个求值器，出来的数字若有不同，只能是解析的锅——
反之，数字全部相同（§9.5 第三段十五条全平），就构成"两法等价"在语料
覆盖范围内的机器证人。

`showAst` 的 S-表达式格式（`(+ 1 (* 2 3))`）是给形状语料用的：中缀记号
前置化后，**嵌套深度即结合方向**，`(- (- 2 3) 4)` 与 `(- 2 (- 3 4))`
一眼可辨，比对逐字符精确。

### 11.3.7　回调与函数清单总览

实现读完后，把全部成员排成一张清单收口——每个回调一行，标注角色、
触发的 token、下限决定，这张表就是 `pratt.hpp`/`pratt.cpp` 的可检索
目录：

| 函数 | 角色 | 触发 token | 递归下限 | 产出 |
|---|---|---|---|---|
| `number` | 前缀 | `Int` | — | `IntLit` |
| `variable` | 前缀 | `Ident` | — | `VarRef` |
| `grouping` | 前缀 | `(` | None（完整表达式） | 透传内部 |
| `unaryExpr` | 前缀 | `-` `*` `&` | Unary（容前缀链与后缀） | `Unary` |
| `binary` | 中缀 | 十种双目 | 左结合 up(prec) / 右结合 prec | `Binop` |
| `callExpr` | 中缀 | `(`（运算符位） | 每实参 None | `CallE` |
| `fieldExpr` | 中缀 | `.` | —（字段名是标签） | `FieldA` |
| `parseExpression` | 主循环 | — | 入参即下限 | 滚环合成 |
| `lookup` / `rule` | 表访问 | — | — | 覆盖表优先 |
| `setRightAssoc` | 实验接口 | — | — | 改写覆盖表 |
| `lex` | 词法 | — | — | token 流 |
| `evalExpr` / `showAst` | 共享层 | — | — | 值 / 形状 |

十二个函数各司一职，没有一个超过四十行——Pratt 代码的短小不是风格
选择，而是**职责分配的结果**：优先级与结合性进了表，模板进了唯一一个
`binary`，位置判断进了主循环的两行条件，剩下的回调全都只做"吃 token、
递归、包一层"。对比 9.1 的分层法（六对函数写同一模板），代码量的差
别就是模板复用次数的差别。

## 11.4　陷阱巡礼：形状语料说话

`main.cpp` 第二组语料专门收集"同一串字符、两种合法括号化"的构造。这些
构造之所以是陷阱，是因为**人读表达式靠的是"从左到右"的扫描习惯，而
解析器裁决靠的是"当前位置查表"**——两者在双角色 token 上必然分歧。

先把本章语言的全部双角色 token 的位置行为列成表，后面每条陷阱都能在
表里查到出处：

| token | 操作数位（前缀） | 运算符位（中缀） | 优先级 |
|---|---|---|---|
| `(` | 分组：`( expr )` | 调用：`callee ( args )` | Call（中缀侧） |
| `-` | 负号：`- expr` | 减法：`l - r` | Unary（前缀）/ Term（中缀） |
| `*` | 解引用：`* p` | 乘法：`l * r` | Unary（前缀）/ Factor（中缀） |

三个 token、六种行为，全部由"扫描到它时等号左边有没有操作数"裁决。

为什么人会被这些构造绊倒？因为两套裁决系统的口径不同。**人**读表达式
是线性扫描加局部配对：看到 `-r.f`，眼睛先锁定最左边的 `-`，倾向于把
它和紧随的 `r` 配对（"负号贴着数字"的阅读习惯）；**解析器**裁决依据是
全局规则表：`-` 的操作数下限是 Unary，字段是 Call 级——比 Unary 紧，
于是字段"抢走"了 `r`。人与机器在"谁离得近"（文本距离）与"谁绑得紧"
（优先级）之间做了不同的裁决。语言设计者能做的不是消灭分歧（那需要
删掉双角色记号），而是**让表的裁决可以被预测**——这也是 C 与 Pascal
在 `*p.f` 上分道扬镳却各自自洽的原因：两家的表都印在手册里，分歧只是
两行数字的先后。

| 构造 | C 家族（本章） | Pascal 家族 | 谁对 |
|---|---|---|---|
| `*p.f` / `p^.f` | `*(p.f)` 字段紧 | `(p*).f` 解引用紧 | 都对，表不同 |
| `-a*b` | `(-a)*b` | `(-a)*b` | 两家一致 |
| `-2^2` | `(-2)^2`（C 无幂，类推） | `-（2^2）` | 各有拥趸 |

逐条看陷阱：

**`-r.f` → `(- (. r f))`。** 扫描到 `-` 时它在操作数位，走前缀负号；
负号以 Unary 为下限取操作数，递归层吃 `r` 后见 `.`（Call ≥ Unary）继续
滚——字段先绑。想要负号先绑？写 `(-r).f`：括号让 `(-r)` 成为一个完整
叶子后，`.` 才与它合成。**优先级不是"谁在左边"，是"谁的规则更紧"**。

**`*p.f` → `(* (. p f))`，同构。** 想要"解引用后再取字段"须写 `(*p).f`。
匠书 §6.3 讲 jlox 时用的是 `a.b.c` 与一元组合的同款例子——C 语言标准里
`*p.f` 恰恰定义为 `*(p.f)`（字段紧于解引用），本章表与 C 一致；Pascal
则相反（解引用最紧，`^` 记号）。两种语言都对，差异全在表的两行相对
位置——这是"表达式语义是表数据"的又一例证。

**`-2^2` → 4，即 `(-2)^2`。** 这是**约定**，不是定理：本章表把 Unary
放在 Power 之上（C 语言传统：一元运算符压过多数双目），负号先结合；
Python 的 `**` 则压过一元负号，`-2**2` 是 `-4`。两张表都自洽，数学上
都讲得通（"负二是常数"vs"先幂后取反"）。语言设计者在这里做的决定，
最终落成表里两行的先后——练习 3 让读者亲手交换并观察语料翻转。

**`f(1)(2)` → `(call (call f 1) 2)`。** 链式调用无需新机制（9.3.5 已
述）。这个形状在第 51 章（0-CFA）会回来——"被调表达式的值可能是任何
函数"正是调用图需要分析才存在的原因。

**`--x` → `(- (- x))`。** 前缀链，与分层法在此完全一致（`unary` 递归
自身 = Pratt 前缀下限 Unary 容许下一层还是前缀）。词法层注意：`--` 不是
一个 token（没有 `--` 自减），两个 `-` 各自独立——**词法的最长匹配在
这里故意不做**，因为语言里没有 `--` 运算符，两个 Minus 分别查表恰好
各自走前缀，结果正确。

**读者自证**：以上八条陷阱全部可以单点复验——运行二进制后在 9.6
第二组里找到对应行，再改表里相应一格（或加括号）重跑，观察那一行的
变化。陷阱之所以值得亲手翻一遍，是因为"知道 `*p.f` 是 `*(p.f)`"与
"亲眼看着它变 `(*p).f`"之间隔着一次可迁移的经验：下一次遇到自己语言
的优先级 bug，第一反应会是"去查表的那一行"，而不是盯着调用栈发呆。

## 11.5　驱动与对账实验

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 11 章驱动（无参运行，走"简单程序"对账协议）：
//   一、Pratt 语料求值（含幂右结合/调用/一元链）；
//   二、陷阱构造的 AST 形状（-a.b、*p+1、f(1)(2)——只看形状不求值）；
//   三、与 LL(1) 分层法对同一语料对账（同一词法、同一 AST、同一求值器）；
//   四、结合性实验：把减号改成右结合的"坏表"，2-3-4 从 -5 变 3；
//   五、断言汇总。
#include "llref.hpp"
#include "pratt.hpp"

#include <iostream>
#include <string>
#include <vector>

namespace {

using Env = std::map<std::string, long long>;

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

std::string evalStr(const tip::Expr &e, const Env &env,
                    const std::map<std::string, tip::BuiltinFn> &builtins) {
    std::string err;
    long long v = tip::evalExpr(e, env, builtins, &err);
    return err.empty() ? std::to_string(v) : "错误:" + err;
}

}  // namespace

int main() {
    // 语料变量：x=4, y=3, a=10, b=2, p=100, r=7
    Env env{{"x", 4}, {"y", 3}, {"a", 10}, {"b", 2}, {"p", 100}, {"r", 7}};
    std::map<std::string, tip::BuiltinFn> builtins{
        {"abs", [](std::vector<long long> v) { return v[0] < 0 ? -v[0] : v[0]; }},
        {"max", [](std::vector<long long> v) { return v[0] > v[1] ? v[0] : v[1]; }},
        {"gcd", [](std::vector<long long> v) {
             while (v[1] != 0) { long long t = v[0] % v[1]; v[0] = v[1]; v[1] = t; }
             return v[0];
         }},
    };

    auto evalPratt = [&](const std::string &src) {
        std::vector<tip::ParseError> errs;
        tip::ExprP e = tip::parsePratt(src, errs);
        if (!e) return "解析错误:" + (errs.empty() ? "?" : errs[0].msg);
        return evalStr(*e, env, builtins);
    };

    std::cout << "== 一、Pratt 语料求值 ==\n";
    struct Item { const char *src; const char *want; };
    const Item corpus[] = {
        {"1+2*3", "7"},           {"(1+2)*3", "9"},
        {"10-3-2", "5"},          {"100/10/5", "2"},
        {"2*3/4", "1"},           {"1+2==3", "1"},
        {"4-1>1+0", "1"},         {"3>=3", "1"},
        {"2<=1", "0"},            {"1!=2", "1"},
        {"-3+5", "2"},            {"-(2-5)", "3"},
        {"x+y*2", "10"},          {"a-b-1", "7"},
        {"abs(3-8)*2", "10"},     {"max(2,7)+1", "8"},
        {"gcd(12,18)+2", "8"},    {"2^3^2", "512"},
        {"(2^3)^2", "64"},        {"-2^2", "4"},
    };
    for (const auto &it : corpus) check(it.src, evalPratt(it.src), it.want);

    std::cout << "\n== 二、陷阱构造的 AST 形状 ==\n";
    struct Shape { const char *src; const char *want; };
    const Shape shapes[] = {
        // 一元负号先结合还是字段先结合？表说字段（Call 级）高于负号（Unary 级）
        {"-r.f", "(- (. r f))"},
        // 解引用同理：*p.f 是 *(p.f)，要 (*p).f 得写括号——匠书 §6.3 同款陷阱
        {"*p.f", "(* (. p f))"},
        {"(*p).f", "(. (* p) f)"},
        {"*p+1", "(+ (* p) 1)"},
        {"&x", "(& x)"},
        // 调用是后缀：f(1)(2) = (f(1))(2)，Pratt 的中缀 "(" 天然支持链式调用
        {"f(1)(2)", "(call (call f 1) 2)"},
        {"-f(3)", "(- (call f 3))"},
        {"--x", "(- (- x))"},
    };
    for (const auto &s : shapes) {
        std::vector<tip::ParseError> errs;
        tip::ExprP e = tip::parsePratt(s.src, errs);
        check(s.src, e ? tip::showAst(*e) : "解析错误", s.want);
    }

    std::cout << "\n== 三、与 LL(1) 分层法对账（共同语料）==\n";
    // 交集 = 两法都能接受的文法：算术/比较/一元负号/括号/变量（无幂、无调用、无字段）
    // 对账双保险：值相等（喂同一求值器）+ 形状相等（S-表达式逐字符）。
    const char *shared[] = {
        "1+2*3", "(1+2)*3", "10-3-2", "100/10/5", "2*3/4",
        "1+2==3", "4-1>1+0", "3>=3", "2<=1", "1!=2",
        "-3+5", "-(2-5)", "x+y*2", "a-b-1", "--x",
    };
    for (const char *src : shared) {
        std::vector<tip::ParseError> e1, e2;
        tip::ExprP p1 = tip::parsePratt(src, e1);
        tip::ExprP p2 = tip::parseLl(src, e2);
        std::string v1 = p1 ? evalStr(*p1, env, builtins) : "解析错误";
        std::string v2 = p2 ? evalStr(*p2, env, builtins) : "解析错误";
        check(std::string(src) + "（pratt=ll 值）", v1, v2);
        std::string s1 = p1 ? tip::showAst(*p1) : "解析错误";
        std::string s2 = p2 ? tip::showAst(*p2) : "解析错误";
        check(std::string(src) + "（pratt=ll 形状）", s1, s2);
    }

    std::cout << "\n== 四、结合性实验 ==\n";
    // 坏表：把减号改成右结合。左结合 2-3-4=(2-3)-4=-5；右结合=2-(3-4)=3。
    // 同一构造、只翻表里一格布尔值，结果就分岔——结合性住在表里，不住在代码里。
    check("2-3-4 左结合", evalPratt("2-3-4"), "-5");
    {
        std::vector<tip::ParseError> errs;
        std::vector<tip::Token> toks = tip::lex("2-3-4", errs);
        tip::PrattParser bad(std::move(toks));
        bad.setRightAssoc(tip::Tok::Minus);
        tip::ExprP e = bad.parseExpression(tip::Prec::None);
        check("2-3-4 右结合（坏表）", e ? evalStr(*e, env, builtins) : "解析错误", "3");
        check("坏表形状", e ? tip::showAst(*e) : "?", "(- 2 (- 3 4))");
    }
    check("2^3^2 右结合", evalPratt("2^3^2"), "512");
    check("(2^3)^2 括号强制", evalPratt("(2^3)^2"), "64");

    std::cout << "\n== 五、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（" << (sizeof(corpus) / sizeof(corpus[0]) +
                                      sizeof(shapes) / sizeof(shapes[0]) +
                                      2 * (sizeof(shared) / sizeof(shared[0])) + 5)
                  << " 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
```

驱动分五段，每段都是一层证人。先说两个贯穿的机制，再逐段过。

**`check` 协议。** 每项检查打印 `ok 名字 = 实算值`，期望值只在失败时
显示；失败计数进 `g_failures`，末段据此决定退出码。于是期望输出文件
（§9.6）本身成为"可执行讲义"——每行都是解析器对自己裁决的签字，而
退出码守住"任何一项失败即整体失败"的底线。这个协议与第 8 章一脉相承。

失败传导的细节值得读实现的人留意：`g_failures` 只增不减，任何一项
FAIL 都不会中断后续语料——把全部失败一次看尽，排错效率高于首错即停；
末段据计数决定退出码，**stdout 给人读**（含所有失败细节与期望值对照），
**退出码给脚本读**（红绿二元判决）。`check_example.py` 两边都核，于是
"人误删一行期望"与"实现悄悄改了行为"都不能悄悄溜过去。

**语料的环境。** 变量 `x=4, y=3, a=10, b=2, p=100, r=7`，内建函数
`abs`（单参）、`max`/`gcd`（双参，考逗号与实参递归）。`p`/`r` 只在形状
语料出现（解引用与字段的求值器会报错），数值语料只用 `x y a b`。

**第一段：二十条数值语料。** 每条都有明确的考点，设计表如下：

| # | 语料 | 考点 | # | 语料 | 考点 |
|---|---|---|---|---|---|
| 1 | `1+2*3` | Factor 压线 Term | 11 | `-3+5` | 一元松于 Term：只管 3 |
| 2 | `(1+2)*3` | 括号重置下限 | 12 | `-(2-5)` | 一元吃整个括号 |
| 3 | `10-3-2` | 同级左结合链 | 13 | `x+y*2` | 变量与混排（env） |
| 4 | `100/10/5` | 除法整除口径 | 14 | `a-b-1` | 变量左结合链 |
| 5 | `2*3/4` | 同级混运算符链 | 15 | `abs(3-8)*2` | 单参调用+实参为表达式 |
| 6 | `1+2==3` | 松层在最后结合 | 16 | `max(2,7)+1` | 双参调用+逗号 |
| 7 | `4-1>1+0` | 两侧各自先算 | 17 | `gcd(12,18)+2` | 内建表第三员 |
| 8 | `3>=3` | 双字符：真 | 18 | `2^3^2` | 幂右结合 |
| 9 | `2<=1` | 双字符：假 | 19 | `(2^3)^2` | 括号强制左先 |
| 10 | `1!=2` | 双字符：不等 | 20 | `-2^2` | Unary 高于 Power 的约定 |

语料的排列也有讲究：1–2 是"优先级+括号"的最小对，3–5 是左结合链
（同级不同运算符混排是"滚环"最直接的考法），6–7 考松层（比较）如何
在外层收尾，8–10 把四个双字符运算符全走一遍（词法最长匹配的对账），
13–14 是一元负号与括号的攻防，15–16 引入变量，17–19 是调用三连（单参、
双参、实参复杂度递增），20–23 是幂三连（右结合、括号强制、与一元的
相对位置）。二十条不多不少，每条至少锁死表里的一格或主循环的一行。

**为什么是二十条而不是两百条**：语料设计的目标是**覆盖裁决**而不是
覆盖输入空间。裁决空间（9.6 导读表的五行类目）是有限的，每类一条
最小代表即可锁死；随机海量语料（property 路线）在本章性价比低，因为
两个解析器共享词法与求值器，随机串大多死在词法层，测不到表。真正
受益于随机语料的是"Pratt 与 llref 在任意中缀串上等价"这种性质——
练习 7 的错误恢复与练习 1 的新运算符，读者可自行把语料生成器接上
（第 5 章正则对抗测试的随机骨架可以直接搬）。覆盖表先行、性质测试
殿后，这是教程全书对账设计的通用次序。

**第二段：八条形状语料**（§9.4 逐条讲过），打印 S-表达式与手写期望串
逐字符比对。形状对优先级的裁决比数值更直接——数值对了形状错了的可能
（如 `&&` 之类的短路算符）在这里被单独锁死。

**第三段：与第 6 章分层法对账。** 同一字符串，`parsePratt` 与 `parseLl`
各解析一遍，做**双保险**对账：值相等（两棵树分别喂进同一个求值器，数
必须相同）与**形状相等**（两棵树的 S-表达式逐字符相同——树同构是比值
相等强得多的命题，它意味着两种方法对每个 token 的每次裁决都一致）。
共同语料十五条，取两法文法的**交集**：算术、比较、一元负号、括号、
变量。幂、调用、字段不在交集——LL 参照物（最小副本）没有实现它们，
这正是"分层法每加一类记号要加一层"的活体现：参照物保持最小，反而让
交集的边界本身成为论据。三十条断言（15 值 + 15 形状）全平后才有资格
进入第四段——**等价性先于实验**。

**第四段：结合性实验。** 先验证正常表下 `2-3-4` = -5（左结合）；然后
`setRightAssoc(Tok::Minus)` 只翻减号一格，同一字符串算出 3，形状打印
`(- 2 (- 3 4))`——**翻表里一格布尔值，结合方向翻转，其余代码一行
未动**。这就是痛点二的正式回答：结合性不再是"代码形状的副产物"，
而是表数据。右结合的"正版"由幂验证（512 对 64），坏表实验证明的
不是"右结合是错的"（幂就是右结合且正确），而是**结合性必须住在可
声明的数据里**，否则它会以模板抄写错误的形态静默出错——jlox 的
`==` 教训。

**第五段：汇总。** 63 项断言（20 数值 + 8 形状 + 30 对账 + 5 结合性）
全过打印"全部通过"并退出 0。

## 11.6　期望输出解读

```text
; expected: expected/output.txt
== 一、Pratt 语料求值 ==
ok   1+2*3 = 7
ok   (1+2)*3 = 9
ok   10-3-2 = 5
ok   100/10/5 = 2
ok   2*3/4 = 1
ok   1+2==3 = 1
ok   4-1>1+0 = 1
ok   3>=3 = 1
ok   2<=1 = 0
ok   1!=2 = 1
ok   -3+5 = 2
ok   -(2-5) = 3
ok   x+y*2 = 10
ok   a-b-1 = 7
ok   abs(3-8)*2 = 10
ok   max(2,7)+1 = 8
ok   gcd(12,18)+2 = 8
ok   2^3^2 = 512
ok   (2^3)^2 = 64
ok   -2^2 = 4

== 二、陷阱构造的 AST 形状 ==
ok   -r.f = (- (. r f))
ok   *p.f = (* (. p f))
ok   (*p).f = (. (* p) f)
ok   *p+1 = (+ (* p) 1)
ok   &x = (& x)
ok   f(1)(2) = (call (call f 1) 2)
ok   -f(3) = (- (call f 3))
ok   --x = (- (- x))

== 三、与 LL(1) 分层法对账（共同语料）==
ok   1+2*3（pratt=ll 值） = 7
ok   1+2*3（pratt=ll 形状） = (+ 1 (* 2 3))
ok   (1+2)*3（pratt=ll 值） = 9
ok   (1+2)*3（pratt=ll 形状） = (* (+ 1 2) 3)
ok   10-3-2（pratt=ll 值） = 5
ok   10-3-2（pratt=ll 形状） = (- (- 10 3) 2)
ok   100/10/5（pratt=ll 值） = 2
ok   100/10/5（pratt=ll 形状） = (/ (/ 100 10) 5)
ok   2*3/4（pratt=ll 值） = 1
ok   2*3/4（pratt=ll 形状） = (/ (* 2 3) 4)
ok   1+2==3（pratt=ll 值） = 1
ok   1+2==3（pratt=ll 形状） = (== (+ 1 2) 3)
ok   4-1>1+0（pratt=ll 值） = 1
ok   4-1>1+0（pratt=ll 形状） = (> (- 4 1) (+ 1 0))
ok   3>=3（pratt=ll 值） = 1
ok   3>=3（pratt=ll 形状） = (>= 3 3)
ok   2<=1（pratt=ll 值） = 0
ok   2<=1（pratt=ll 形状） = (<= 2 1)
ok   1!=2（pratt=ll 值） = 1
ok   1!=2（pratt=ll 形状） = (!= 1 2)
ok   -3+5（pratt=ll 值） = 2
ok   -3+5（pratt=ll 形状） = (+ (- 3) 5)
ok   -(2-5)（pratt=ll 值） = 3
ok   -(2-5)（pratt=ll 形状） = (- (- 2 5))
ok   x+y*2（pratt=ll 值） = 10
ok   x+y*2（pratt=ll 形状） = (+ x (* y 2))
ok   a-b-1（pratt=ll 值） = 7
ok   a-b-1（pratt=ll 形状） = (- (- a b) 1)
ok   --x（pratt=ll 值） = 4
ok   --x（pratt=ll 形状） = (- (- x))

== 四、结合性实验 ==
ok   2-3-4 左结合 = -5
ok   2-3-4 右结合（坏表） = 3
ok   坏表形状 = (- 2 (- 3 4))
ok   2^3^2 右结合 = 512
ok   (2^3)^2 括号强制 = 64

== 五、断言汇总 ==
全部通过（63 项）
```

六十三行 `ok` 分五组，逐组读要点：

**第一组（前 20 行）**是数值签字。考点已在 9.5 的设计表列明，这里给
逐行导读的补充列——每行的"裁决落点"（表里哪一行或循环里哪个判断
决定了它）：

| 输出行 | 裁决落点 |
|---|---|
| `1+2*3 = 7` | Factor 压线：递归层（Factor）见 `*` 不让权 |
| `(1+2)*3 = 9` | `grouping` 重置下限到 None |
| `10-3-2 = 5` | 左结合：`binary` 右操作数取 up(Term) |
| `100/10/5 = 2` | 同上（Factor 级）+ 整数除法 |
| `2*3/4 = 1` | 同级异运算符混链，滚环无差别处理 |
| `1+2==3 = 1` | Equality 最松：外层收尾 |
| `4-1>1+0 = 1` | Comparison 松于 Term：两子树先缩 |
| `3>=3 = 1` | 词法双字符 `>=` 命中 |
| `2<=1 = 0` | 词法双字符 `<=` 命中 |
| `1!=2 = 1` | 词法双字符 `!=` 命中 |
| `-3+5 = 2` | `unaryExpr` 下限 Unary：`+`（Term）让权 |
| `-(2-5) = 3` | 一元吃整个分组 |
| `x+y*2 = 10` | env 查 `x`、`y`；混排同第 1 行 |
| `a-b-1 = 7` | 变量版左结合链 |
| `abs(3-8)*2 = 10` | `callExpr` 实参下限 None，嵌套层各持授权 |
| `max(2,7)+1 = 8` | 双参逗号协议 |
| `gcd(12,18)+2 = 8` | 内建表第三员 |
| `2^3^2 = 512` | 幂右结合：右操作数取同级 Power |
| `(2^3)^2 = 64` | 括号强制先结合 |
| `-2^2 = 4` | Unary 档高于 Power 档的落点 |

表里 20 行只有 5 类裁决（压线/重置/抬级/同级/档位先后），却覆盖了
全部语料——Pratt 的决策空间就是这样小而完备。

**第二组（8 行）**是形状签字。逐行导读：`-r.f = (- (. r f))` 与
`(*p).f = (. (* p) f)` 两行并排读——同一批 token 集合，括号改变牌桌，
负号/解引用与字段的相对优先级在两行里各执一词；`*p.f = (* (. p f))`
在两者中间，展示**不加括号时表的默认裁决**（与 C 一致、与 Pascal 相反）；
`*p+1 = (+ (* p) 1)` 是前缀进双目的常规形状；`&x = (& x)` 最平，作为
取址前缀的基线；`f(1)(2)` 的双层 `call` 嵌套是链式调用的形状（后缀链
不需要状态的证据）；`-f(3)` 见证调用紧于一元；`--x` 的双层一元嵌套是
前缀链的形状。

**第三组（30 行）**是两法对账的双保险，每条语料出两行：`（pratt=ll 值）`
行打印共同算出的数，`（pratt=ll 形状）`行打印共同的 S-表达式。值行
证明"喂同一求值器结果相同"，形状行证明"两棵树逐节点同构"——后者
把等价性从数值巧合（比如两法恰好都算错成同一个数）的可能性里彻底
剥离。挑三行细读：`10-3-2（形状） = (- (- 10 3) 2)`——左结合链的
嵌套方向一目了然；`--x（形状） = (- (- x))`——分层法靠 `unary` 递归
自身、Pratt 靠前缀下限 Unary，机制不同、树同构；`4-1>1+0（形状） =
(> (- 4 1) (+ 1 0))`——松层（比较）作为树根，两个紧层（Term）各自
缩成子树，层级结构在形状里完全显形。

**第四组（5 行）**是实验记录，逐行读：`2-3-4 左结合 = -5`——正常表
基线；`2-3-4 右结合（坏表） = 3`——同一字符串、翻一格布尔的产出差异；
`坏表形状 = (- 2 (- 3 4))`——差异的树形状证据（右嵌套）；`2^3^2
右结合 = 512` 与 `(2^3)^2 括号强制 = 64`——右结合的正版与括号覆写。
五行的叙事结构是"基线 → 干预 → 形状证据 → 正版验证"，这是教程
实验段的固定套路（第 7 章 prefer-shift、第 8 章同心合并同款）。

**第五段汇总行**"全部通过（63 项）"收口，退出码 0——`check_example`
同时核这两者，任何一行 FAIL 都会让整章变红。

把五组连起来读的收获：第一组给"每个数字对不对"，第二组给"每棵树对
不对"，第三组给"两个解析器等不等价"，第四组给"结合性是不是数据"，
第五组给"整体红绿"。**数值 → 形状 → 等价 → 可变性 → 汇总**，这五层
证人从弱到强排成一个完整的证据链——它比任何一段论述都更有说服力地
回答了本章开头的问题：优先级与结合性确实可以、而且应该住进表里。

## 11.7　Pratt 在解析器家族里的位置

先把匠书 jlox 的六层函数与本章表行做成一一映射——读过 9.1 痛点再看
这张表，"折叠"二字就有了精确含义：

| jlox 层函数（匠书 §6.3） | 本章表行 | 折叠后去哪了 |
|---|---|---|
| `equality()` | `==` `!=` 两行 | 优先级列 Equality |
| `comparison()` | `< <= > >=` 四行 | 优先级列 Comparison |
| `term()` | `+` `-` 两行（中缀侧） | 优先级列 Term |
| `factor()` | `*` `/` 两行、`-`/`*` 前缀侧 | 优先级列 Factor/Unary |
| `unary()` | `-` `*` `&` 前缀回调 | `unaryExpr` 一个函数 |
| `primary()` | `Int`/`Ident`/`(` 前缀回调 | 三个叶子回调 |
| （jlox 另设 `call()`） | `(` 中缀回调 | `callExpr` 滚环 |

六对函数（十二个）折成七个回调与一列数字；jlox 里"层内模板 + 层间
调用"的全部信息，压缩成表的三列（前缀、中缀、优先级）加一格布尔。

与 LR 家族（第 7–8 章）的对照还可以再挖一层，超出对照表的一句话容量。
**冲突处理**：第 7 章的悬挂 else 在 LR 表里是移进-归约冲突，要靠
prefer-shift 消解；在"递归下降骨架 + Pratt 表达式"的架构里，if/else
归语句层管——语句解析器解析完 if 体后**显式问一句**"有 else 吗"（就是
`match(ELSE)`），歧义根本不进入表达式层。两种架构把歧义放在不同的
地方解决：LR 把它放进表构造时的冲突报告（集中但抽象），手写骨架把它
放进语句代码的书写顺序（分散但直白）。**能力边界**：运算符优先文法
（OPG，Floyd 1963）是 Pratt 的形式化近亲，OPG 是 CFG 的真子集（它表达
不了既有前缀又有中缀角色的同类运算符间的某些组合）；但工程上的 Pratt
因为回调是任意代码，实际能力**超出** OPG——`callExpr` 这种"收集一串
实参"的回调早已不是"运算符"所能描述。所以准确定位是：**Pratt 的表
部分管住 OPG 能管的（优先级与结合性），回调部分逃逸出去接管剩下的**
（调用、切片、强制转换这类"长得像运算符的结构"）。这也解释了它为何
能与 LR 生成器长期并存：各有各的表达力舒适区。

**工业实例的落点**（此处只举三个源码可查的）：GCC 的 C++ 前端
（`cp_parser_binary_expression`）以优先级阶梯递归下降解析二元表达式；
rustc 的表达式解析（`parse_assoc_expr_with` 一族）是教科书式的优先级
爬升；V8 的解析器以"递归下降骨架 + 优先级表"处理赋值与二元链。三者
都没有用 yacc 一族的生成器表做表达式——不是巧合，是§9.7 表里"错误
恢复可定制"那一行的现实投影。

把三条路摆在一起收束本章：

| | LL(1) 分层（第 6 章） | LR/LALR（第 7–8 章） | Pratt（本章） |
|---|---|---|---|
| 优先级住在哪 | 函数调用图拓扑 | ACTION/GOTO 表（项集族算出） | 规则表（人写） |
| 表从哪来 | 手写每层函数 | 构造器从文法自动生成 | 手写一张 |
| 结合性 | 代码形状（循环/递归） | 文法 + 冲突消解策略 | 表中一格布尔 |
| 加运算符 | 加函数改邻居 | 改文法重跑构造器 | 改表一格 |
| 一 token 多角色 | 分散在不同层函数 | 由状态区分 | 同一行的两个指针 |
| 错误恢复 | 每层可定制 | 表驱动难定制 | 每回调可定制 |
| 适合谁 | 教学小文法 | 生成器（yacc/ANTLR 走此路） | 手写工业前端 |

"加运算符"一行可以做个思想实验：在三条路上各加一个 `&`（按位与，
插在 Equality 与 Comparison 之间）。分层法：新写一对函数、改两处调用，
约十五行、动三个文件位置；LR：文法加两条产生式，重跑第 7/8 章的构造器
（项集族、ACTION/GOTO 全部重算——这正是生成器的价值，也是它的重量）；
Pratt：表里加一行 `map[Tok::Amp] = makeRule(nullptr, B, Prec::Comparison
与 Term 之间新档位)`——若复用现有档位则连枚举都不用改，一行，函数零
改动。三者的差别不是代码量，是**变更的半径**：分层法动拓扑（影响邻居），
LR 动全局（重算整表），Pratt 动一格（影响恰是该 token 自己）。

变更半径决定的是**维护的心理学**。分层法加运算符要碰邻居函数——改
别人的代码永远比加自己的代码危险，review 时"你动了 cmpRest"比"你加了
一行表"需要多看十倍；LR 全局重算后冲突表可能变样（第 7 章 prefer-shift
那类消解要重新审），等于每次加运算符都要重考一次文法资格；Pratt 的
变更被表行天然圈住——新增行只在新 token 出现时才被查到，老 token 的
行为路径一行未变，回归测试只需覆盖新运算符。这也是大语言前端动辄
几十个运算符还敢频繁调整优先级（C++ 的 spaceship、Swift 的 nil 合并）
的底气所在：他们的优先级表是独立文件里的一列数字，改表不碰代码。

最后一行是本章存在的现实理由：GCC、Clang、V8、rustc 的表达式解析几乎
都是 Pratt 或其变体（递归下降负责语句骨架、Pratt 负责表达式），因为
工业前端要的是**对每类记号的错误恢复与诊断有完全控制权**——这恰是
表驱动 LR 的弱项（错误时栈状态难以翻译成人话）、每回调一段代码的
Pratt 的强项（回调里想怎么报、怎么恢复都行）。匠书自己的对照也有说服
力：jlox 六层函数约两百行解析代码；clox 换成 Pratt 后，核心十几行循环
加一张表，还多扛了赋值、按位、属性访问一大排运算符。

**何时仍应选 LR**——为公平起见把天平摆平。LR 不可替代的场景有三：
其一，**文法由用户/外部提供**（IDL、查询语言、配置语言）——文法文件
就是产品接口， yacc/ANTLR 的"文法即规范"不可替代；其二，**要 LALR 的
冲突报告当 lint 用**——文法演化时冲突报告能机械指出歧义（第 7 章的
prefer-shift 警示），手写解析器的歧义要靠人脑证明不存在；其三，
**增量重析**（IDE 场景）需要表驱动才能做局部回放——回调式递归的
调用栈状态难以序列化保存。教程自身就是活例子：第 4 章 ANTLR 走
生成器路线（TIP 是教程的"外部接口"），本章手写 Pratt（表达式是教程
的"内部器官"）——两条路线在同一个项目里各就其位。

**关于"Pratt 只能做表达式"的常见误解**：匠书在 clox 里用 `canAssign`
布尔参数把赋值也塞进了表——赋值是右结合的最低优先级中缀，`a = b = c`
照样滚环解决；语句层（if、while、块）仍由普通递归下降负责。所以准确
的说法是：**Pratt 负责"运算符优先级可表达"的那部分文法，与递归下降
是配合关系而非替代关系**。第 58 章会把这套配合完整搬进字节码编译器：
中缀回调从"合成 AST 节点"换成"发一条字节码"，表一行都不用改。

**第二个常见误解："Pratt 不用文法"。** 9.2.1 已经正面回答：表与 EBNF
机械互译，表就是文法。持这个误解的人多半是把"没有文法文件"当成了
"没有文法"——Pratt 的文法以源码内数据的形式存在，牺牲了"一个文件
喂给生成器"的自动化（第 7–8 章的构造器因此不适用于它），换来了"每条
规则旁边就能写代码"的控制力。鱼与熊掌的取舍，不是有没有文法。

**第三个常见误解："优先级数字必须连续/等距"。** 表里的数字只参与
**比较**，从不参与算术（除了左结合的 `up(prec)` 取"下一档"——这正是
枚举相邻而非数值相邻的原因）。所以插入新档位（练习 1 的 `<<`）不必
重排全部数字，在枚举里加一个名字即可；同理，删掉一档也不会留下"空洞"
问题。数字的语言（C 里 1..15）与档位的语言（本章枚举）表达力相同，
但档位没有"跳号"的伪问题。

**一段简史收束**：Pratt 1973 年的原始论文标题是《Top Down Operator
Precedence》，发表在当年的 POPL；此后二十年它几乎是隐学的状态——
生成器路线（yacc 一族）占据了主流教材与工业实践。转机来自脚本语言
时代：Crockford 复盘 JSLint 时写了那篇著名的《Top Down Operator
Precedence》短文，指出 JSON 与 JS 表达式用几百行 Pratt 就能啃下来；
此后 V8、rustc、Swift 的前端相继采用"递归下降骨架 + Pratt 表达式"
的组合。匠书是第一本把 Pratt 作为**教学主线**之一的主流编译原理书
（jlox 分层、clox Pratt 的对照设计别具匠心），本章的取材结构正是
这个对照的延续。

### 常见问题（FAQ）

**问：滚环每轮一个递归调用，深表达式会不会栈溢出？** 会。递归深度与
表达式长度同阶：一万个加号的链就有一万层 `parseExpression`。工业解法
有三：给表达式长度设语法上限（多数语言限在几百到几千项）；把左结合
滚环改成**显式栈**迭代（滚环本来就在维护"左链"，把 `lhs` 压进
vector 再统一折叠，递归就只剩右操作数一层）；或将最常见的平坦长链
（`a+b+c+…`）在词法后先做平坦化预处理。教学上保留递归，因为递归形状
即树形状，最利于推演。

**问：规则表为什么运行期查（map），不编译期展开成 switch？** 查表与
跳转在语义上等价，差别在两处可维护性：表可以**整体打印**（排错时把
整张表 dump 出来人审）而 switch 散在代码里；表可以在运行时改（本章
`override_` 的结合性实验正靠这一点）。性能上查表每 token 一次指针
比较，在解析总成本里占比极小——解析的瓶颈从来在内存分配与错误路径，
不在规则查找。练习 6 的 array 版是把查表推到极限的对照。

**问：多个双字符运算符与表怎么交互？** 完全解耦。词法层把 `<=` 收成
单个 token，表只见到 `Tok::Le` 一个键——双字符在表里没有任何特殊
待遇。反过来，想加三字符运算符（`<<=`）也只动词法与枚举，表加一行。
"记号怎么拼"与"记号怎么用"两层的责任切分（§9.3.1）在此兑现。

**问：为什么本章的 `binary` 不区分运算符类型（算术/比较）？** 因为
解析层不关心语义——`+` 与 `==` 在树上只是 `Binop` 的两个枚举值，
类型检查（第 21 章起）与求值（`evalExpr`）才关心。这是"语法层只管
形状"的又一致力于解耦的选择；第 58 章发码版 `binary` 会开始关心
（不同运算符发不同 opcode），那时职责随消费者一起迁移。

**问：AST 为什么用继承体系而不用 `std::variant`？** 两者都能做：variant
版是值语义、无虚分派，遍历用 `std::visit`；继承版与第 14 章既有 AST
形状一致（本章"读路标三"的要求），visitor 协议与教程后续所有章节的
遍历代码同构。真正的权衡点是**扩展方向**：后续章节会往同一套节点上
加行为（第 12 章属性、第 14 章绑定），继承+visitor 让"加操作"不动
节点定义；variant 让"加节点种类"不动操作。教程选择前者，因为教程
的演化方向是"同一棵树、越来越多遍"。匠书的 jlox 用生成器产出继承式
节点类（附录 II 的 AstGenerator），也是同一判断。

**问：表可以表达任何文法吗？** 不能，也不应该。表表达"运算符优先级
可描述"的子文法；语句结构（块的嵌套、声明的顺序）没有优先级概念，
交给递归下降骨架。硬把语句塞进表（比如给 `{` 一个前缀回调）技术上
可行，但读表的人会失去"这张表=表达式文法"的清晰预期——匠书把
`canAssign` 塞进表已经算激进的折中，再进一步就要付出可读性代价。

**问：怎么给"表本身"写测试？** 本章的答案是三层：语料锁行为（数值/
形状断言）、对账锁等价（与 llref 双保险）、实验锁可变性（坏表翻转）。
三者合起来，表里任何一格的任何一次意外改动都会打破至少一条断言——
这就是"表即文法"语境下的回归网。工业前端常见的加强版是**表生成测试**
：从表机械恢复 EBNF（§9.2.1 反向翻译），再用文法工具检查_LL/LR_性质
或生成随机语料做 property 测试——教程第 5 章的正则对抗测试思想在此
完全移植。

与前后章的关系：本章的 AST 与第 14 章名字解析共用节点形状；第 12 章
（语法制导翻译）把"解析时顺手做事"推广成属性文法的系统理论；第 58 章（单遍编译）直接复用本章的表结构。读者此刻拥有的"一张表 + 一个
循环"，是后两章反复回来借用的地基。

## 11.8　小结与练习

**小结**：Pratt 分析把表达式文法从"每层一个函数"折叠成"一张
（前缀，中缀，优先级，结合性）规则表 + 一个滚环"。前缀回调起步、中缀
回调滚环、优先级低于下限即让权；左结合 = 右操作数抬高一级 + 外层循环，
右结合 = 右操作数同级递归。优先级与结合性都成为**表数据**而非代码拓扑；
一 token 双角色由同一行的两个回调指针表达；变更半径从"动邻居"缩到
"动一格"。两法（分层、Pratt）在同一语料上机器对账等价，结合性翻转
成为可重放实验。

本章术语速查（配合自查清单使用，按出场顺序）：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| 前缀回调 | token 出现在操作数位时的处理函数 | §9.2 |
| 中缀回调 | token 出现在运算符位时的处理函数（含后缀） | §9.2 |
| 下限（minPrec） | 调用者授权本层处理的最低优先级 | §9.3.2 |
| 让权 | 见到低于下限的运算符，交还控制权 | §9.3.2 |
| 滚环 | 主循环每轮吃一个中缀运算符、树左长一格 | §9.3.2 |
| 压线 | 运算符优先级恰等于下限，大于等于不让权 | §9.3.2 |
| 双角色 token | 同一 token 前缀中缀各有回调（`(` `-` `*`） | §9.4 |
| 重置牌桌 | 括号把内部表达式当作一个全新起点 | §9.4 |
| 覆盖表 | 实例级规则改写，实验只动一个解析器实例 | §9.3.4 |

**承上启下**：至此前端三部曲（LL、LR/LALR、Pratt）齐备——同一门
表达式语言在三条路上各走了一遍，产出同一棵树。接下来第 12 章问"解析
时能顺手做什么"（属性文法），第 14 章问"树上的名字指谁"（作用域），
而 Pratt 的表与循环将在第 58 章以"边解析边发码"的形态全员回归。读者
如果只从本章带走一句话：**优先级和结合性是数据，不是代码形状**。

**自查清单**——以下十个问题若能不看书回答，本章就算学会了
（每题背面即对应小节，答不出就回炉那节）：

1. `parseExpression(p)` 的参数 p 是谁授予的？授权的语义是什么？
2. 滚环的退出条件有两个，分别防住什么？
3. 压线（`>=`）与让权（`<`）各对应什么程序现象？把 `>=` 误写成 `>`
   会发生什么？
4. 左结合与右结合在 `binary` 里的差别是哪一行代码？
5. `(` 的两种角色分别在哪两种"位置"触发？谁在裁决？
6. 为什么 `grouping` 的递归下限必须是 None？改成 Term 会破坏哪类
   语料？
7. `-2^2 = 4` 是表里哪两行的相对位置决定的？怎么翻成 `-4`？
8. 结合性实验翻的是全局表还是覆盖表？为什么必须这样设计？
9. 对账实验为什么除"值相等"外还要断言"形状相等"？后者强在哪里？
10. 在三条路（分层/LR/Pratt）上加一个新运算符，各自的变更半径是
    多大？维护心理学上的差别是什么？

**练习**：

做练习的姿势建议：每题先在纸上写出预期的输出行（含树形状），再动
代码、跑对账、核对——"先预测后验证"把这个题集从抄写劳动变成微型
研究。练习 1、3、4、5 各只需要改一到两行；练习 7、8 是破坏性实验，
务必在 git 干净的工作区做，跑完 `git checkout` 还原。

1. 在规则表里加 C 风格的 `%`（与 `/` 同级同结合）与 `<<`（插在
   Comparison 与 Term 之间），各补两条语料验证优先级归属。先在纸上
   写出目标形状，再改表、跑实验核对。
2. 匠书 §17.5 章末练习的完整版：把 `==` 改成右结合
   （`setRightAssoc(Tok::Eq)`），构造 `1 == 1`、`0 == 1 == 0` 两组语料，
   观察第二组左结合（`(0==1)==0` → `0==0` → 1）与右结合（`0==(1==0)` →
   `0==0` → 1）**居然同值**的巧合，再构造一组两版答案**不同**的比较链，
   并解释为什么"同值巧合"反而更危险（提示：错误实现可能长期不被语料
   抓住）。
3. 给 `unaryExpr` 的递归下限从 `Prec::Unary` 改成 `Prec::Power`，重跑
   `-2^2`，解释结果为何翻转（`-` 的操作数下限降到 Power，于是 `^` 能
   进操作数，负号反而变松），并指出这等价于把表里哪两行的相对位置
   交换（Unary 档与 Power 档）。
4. `grouping` 里递归下限用的是 `Prec::None`。若改成 `Prec::Term`，
   `(1==2)` 还能解析对吗？构造失败语料并解释：下限是"授权处理到多松"，
   传 Term 意味着递归层见到 `==`（Equality < Term）会让权，`==` 被留在
   括号外的主循环里吃——形状从 `(grouping (== 1 2))` 变成什么？
5. 中缀 `(`（调用）与前缀 `(`（分组）共用一个 token。若把调用的优先级
   从 `Call` 降到 `Term`，`f(1)+2` 与 `-f(1)` 的形状各变成什么？先笔推
   再实验（提示：降到 Term 后，`binary` 的右操作数下限 Factor 高于
   Term，调用进不了 `+` 的右操作数——形状会怎样裂开？）。
6. （进阶）匠书把 clox 的规则表做成静态数组、以 token 枚举为下标，本章
   用 `std::map` 加默认空规则。把本章表改成 `std::array<Rule, kTokCount>`
   以枚举值为下标，比较两版 `lookup` 的代码量与错误面（越界 vs 缺键），
   并说明哪种更接近匠书 C 版的"表即文档"理想。
7. （错误恢复）在 `binary` 里加"右操作数解析失败则同步到下一个分号"
   的恢复逻辑（吃 token 直到 `Eof` 或运算符表外），构造两条坏语料
   （`1+` 与 `1+*2`），对比恢复前后错误条数与继续解析的能力。这是
   Pratt"每回调可定制恢复"卖点（§9.7 表）的亲手验证。
8. （词法破坏实验）把 `lex` 里双字符判断整块挪到单字符 `switch` 之后，
   重跑全部语料：哪些行从 `ok` 变成 FAIL/解析错误？最长匹配的破坏半径
   恰好是四个双字符运算符——用 `git diff` 圈出受影响语料，说明为什么
   词法与语法的责任切分（§9.3.1）能让破坏如此局部。

（第 11 章完——下一章：语法制导翻译，把"解析时顺手做事"变成理论。）

---

上一章：[10 错误恢复与校正](10-error-recovery.md) · 下一章：[12 AST](12-ast.md)
