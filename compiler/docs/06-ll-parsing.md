# 第 6 章　LL 分析：FIRST、FOLLOW 与预测分析表

## 6.1 问题：token 流之上怎么长出树

第 5 章结束时，
我们手里有了一条
清清爽爽的 token 流。
接下来的问题是语法分析：
这串 token 是不是一个
合法的 TIP 程序？
如果是，
它的结构是什么——
谁是谁的操作数、
谁套着谁？

第 4 章把这件事整个交给了
ANTLR 生成的 TIPParser。
本章和下一章
把语法分析拆开讲：
本章是**自顶向下**阵营的
正统传人——LL(1) 预测分析；
第 7 章是**自底向上**阵营的
王者——LR 分析。
两章共用同一份理论地基
（文法、推导、分析树），
示例代码则各写各的引擎。

材料取自绿龙第 4、5 章
与紫龙 4.2、4.4 节，
所有定义与算法自包含。

## 6.2 地基：文法、推导与分析树

（这一节把第 4 章匆匆
用过的概念正式化。）

**上下文无关文法**（CFG）
由四件东西组成：
非终结符集合、
终结符集合、
产生式集合、
开始符号。
每条产生式形如

```
A → β
```

其中 A 是非终结符，
β 是终结符与非终结符
排成的任意序列
（可以是空序列，即 ε）。
"上下文无关"的意思是：
A 可以被替换成 β，
**不问左右邻居是谁**——
替换的合法性只取决于
被替换者本身。
第 5 章的泵引理直觉
恰好划出了这条边界：
aⁿbⁿ 需要"记得配了多少"
这种上下文，
正则做不到，
CFG 一条
`S → aSb | ε`
就做到了。

从开始符号出发，
反复把最左的非终结符
用某条产生式右部替换，
得到**最左推导**；
每次替换最右的，
得到**最右推导。
把推导过程里
出现过的符号
按层次摆开，
就是**分析树**：
内部节点是非终结符，
叶子是终结符，
每个内部点的孩子
恰好是它那次替换的右部。

一个文法是**二义的**，
如果某个串有两棵
不同的分析树
（等价地，
有两个不同的最左推导）。
二义不是语言的性质
而是文法的性质——
同一门语言
常有二义与非二义两种文法。
但有的语言
天生只能用二义文法描述
（下一节的悬挂 else
就是惯犯），
这时的出路不是换文法，
而是给冲突定消解规则。

自顶向下分析
= 从开始符号出发
**猜**一个最左推导，
使它最终匹配输入。
"猜"怎么不瞎猜？
这就是本章的主线。

## 6.3 递归下降与回溯之痛

最朴素的自顶向下
是带回溯的递归下降：
为每个非终结符写一个函数，
函数体按产生式逐个尝试——
选中一条产生式后，
逐符号匹配：
终结符就直接比对，
非终结符就递归调用。
失败就回溯换下一条。

回溯的代价是指数级的：
同一个非终结符
可能在同一条路径上
被反复尝试。
更糟的是**左递归**直接
让朴素递归下降死循环：

```
expr → expr PLUS term | term
```

`expr()` 一进门
第一件事又是调 `expr()`，
连一个 token 都没消费，
栈就爆了。

两个标准的预处理
能救大部分文法
（绿龙 4.3 节的两把手术刀）：

**消除左递归**。
对

```
A → A α₁ | A α₂ | β₁ | β₂
```

改写为

```
A  → β₁ A' | β₂ A'
A' → α₁ A' | α₂ A' | ε
```

直觉：
原来是"先算 β，
再不断往**左边**贴 α"，
改写后变成
"先拿出 β，
再不断往**右边**贴 α"。
贴的方向翻转，
推导的每一步
至少消费一个 β 里的符号，
递归就有了出口。
绿龙对经典表达式文法
`E → E+T | T, T → T*F | F, F → (E)|id`
动这把刀，
得到本章示例用的

```
expr  → term expr'
expr' → PLUS term expr' | ε
term  → factor term'
term' → STAR factor term' | ε
factor→ INT | IDENT | INPUT | LPAREN expr RPAREN
```

**提取左公因子**。
对 `A → αβ₁ | αβ₂`
（两个候选开头相同），
改写为
`A → α A', A' → β₁ | β₂`。
把"分岔"从开头
推迟到消费完公共前缀之后，
让"看一个符号做决定"
成为可能。

## 6.4 FIRST 与 FOLLOW：一眼看穿下一步

预处理之后，
剩下的决定是：
非终结符 A 面对当前输入 a，
该用哪条产生式？
答案由两个函数给出。

**FIRST(α)**
= α 能推导出的串
**开头**可能出现的终结符集合；
若 α ⇒* ε，
则 ε 也在 FIRST(α) 里。

**FOLLOW(A)**
= 某个句型里
紧跟在 A **右边**的
终结符集合；
若 A 可以是
某个句型的最右符号，
则 $（输入结束符）入列。

语义直白：
A 的某条产生式右部 α
适用于当前输入 a，
当且仅当
a ∈ FIRST(α)；
若 α 可推空，
则"α 消失后露出来的东西"
——FOLLOW(A)——
也能触发这条产生式。

两个函数都按规则
**迭代到不动点**计算：

FIRST 的规则
（对每条产生式 A → X₁X₂…Xₖ）：

1. 终结符的 FIRST 是它自己；
2. 把 FIRST(X₁) 的非 ε 部分
   并入 FIRST(A)；
   若 X₁ 可推空，
   继续看 X₂，依此类推；
3. 全体 Xᵢ 都可推空，
   ε 才进 FIRST(A)。

FOLLOW 的规则：

1. $ ∈ FOLLOW(开始符号)；
2. 产生式 A → αBβ
   且 β 不推空：
   FIRST(β)\\{ε} ⊆ FOLLOW(B)；
3. 产生式 A → αB
   或 β ⇒* ε：
   FOLLOW(A) ⊆ FOLLOW(B)
   （"B 待在句尾，
   就继承 A 的身后"）。

每条规则只往集合里
**加东西**，
集合有限，
迭代必然停止——
第 27 章不动点骨架
在词法（ε 闭包）、
本章（FIRST/FOLLOW）、
后面第 28 章（工作表）
一再重演，
这是本教程
最值得认出的旋律。

绿龙 Example 5.19
对本章文法的标准答案
（示例输出原样复现）：

```
FIRST(expr) = FIRST(term) = FIRST(factor) = {IDENT, INPUT, INT, LPAREN}
FIRST(expr') = {PLUS, ε}
FIRST(term') = {STAR, ε}
FOLLOW(expr) = FOLLOW(expr') = {$, RPAREN}
FOLLOW(term) = FOLLOW(term') = {$, PLUS, RPAREN}
FOLLOW(factor) = {$, PLUS, RPAREN, STAR}
```

验算一条：
`expr → term expr'` 中
term 后面跟 expr'，
FIRST(expr')\\{ε} = {PLUS}
进 FOLLOW(term)；
expr' 可推空，
所以 FOLLOW(expr)
也整批传给 term——
于是 {$, RPAREN} ∪ {PLUS}
= FOLLOW(term) ✓。

## 6.5 LL(1) 表与预测分析器

### 6.5.1 造表

**预测分析表** M[A, a]
的格子放"A 面对 a
该用的产生式"。
构造算法
（绿龙 Algorithm 5.4）
只有三步：

对每条产生式 A → α：

1. 对每个 a ∈ FIRST(α)\\{ε}：
   M[A, a] := A → α；
2. 若 ε ∈ FIRST(α)：
   对每个 b ∈ FOLLOW(A)
   （含 $）：
   M[A, b] := A → α；
3. 没填的格子是错误入口。

如果某个格子
被塞了**两条不同的产生式**，
文法就不是 LL(1) 的
——冲突是文法的性质，
不是算法的失误。

LL(1) 文法的等价刻画
（三条，对着同一非终结符的
两条不同产生式 A → α | β 讲）：

1. α 与 β 不能推导出
   同一终结符开头的串
   （FIRST 交叉即冲突）；
2. 至多一个可推空；
3. 若 β 可推空，
   α 推导出的串
   不能以 FOLLOW(A)
   里的终结符开头。

"LL(1)"这个名字：
第一个 L =
**从左到右**扫输入，
第二个 L =
产出**最左**推导，
1 =
每步**看一个**符号决策。

### 6.5.2 表驱动：把递归下降压平成栈

预测分析器
（绿龙 Fig 5.22/5.23）
用一张显式的栈
替代递归调用：

- 栈底压 $，
  再压开始符号；
- 输入末尾补 $；
- 循环：
  看栈顶 X 与当前输入 a——
  - X = a = $：接受；
  - X 是终结符：
    匹配则双双弹掉/前移，
    不匹配报错；
  - X 是非终结符：
    查 M[X, a]，
    把 X 换成产生式右部
    （**逆序压栈**，
    使右部第一个符号在顶），
    并把这条产生式记进输出。

输出的产生式序列
恰好是**最左推导**；
已扫过的输入加上
栈中内容（自顶向下读）
恰好是推导过程中的
句型。
递归下降的函数调用栈
与这张符号栈
是同一台机器的两种皮：
每个非终结符一个函数
（调用即入栈），
对应每个非终结符
一行的表。

示例对 `x + 21 * y`
输出的推导序列是

```
1 4 8 6 2 4 7 5 8 6 3
```

逐条查产生式编号
即可复原完整最左推导；
对照绿龙 Fig 5.25
对 id+id*id 的 moves 表
逐行同构。

## 6.6 悬挂 else：冲突的教科书现场

绿龙 Example 5.21
的文法
（本章示例的 TIP 化身）：

```
stmt  → IF LPAREN IDENT RPAREN stmt stmt'
stmt' → ELSE stmt | ε
```

算出 FOLLOW(stmt') ∋ ELSE
（else 可出现在
stmt 的身后），
于是 M[stmt', ELSE]
被 Algorithm 5.4
塞进两条产生式：
`stmt' → ELSE stmt`
（FIRST 规则）
与 `stmt' → ε`
（FOLLOW 规则）。
文法二义，
表必然双定义——
这正是二义性
在 LL 世界里的显影。

消解选谁？
绿龙的裁决：
**选 ELSE stmt**。
论证干脆利落：
若选 ε，
else 永远不会被
任何产生式消费掉，
输入里的 ELSE
成了扫不掉的多余符号，
分析注定失败；
选 ELSE stmt
意味着"看见 else
就把它吞进最近的 then"，
即 else 与**最内层**
未闭合的 then 配对。
所有主流工具
（yacc 的 prefer-shift、
ANTLR 的贪婪可选项）
都做同样的选择，
第 4 章 `TIP.g4` 里
`(ELSE stmt)?`
的贪婪语义
也是它的化身。

示例把这个裁决
做成了 `pickWinner`：
候选中若有
右端以当前终结符 a
开头的产生式
（"愿意吃掉 a 的那一个"），
选它；
并如实在输出里
报告冲突与裁决：

```
M[stmt', ELSE]: 候选 {3, 4} -> 取 [3]（最近 else 策略）
```

对 `if (a) if (b) c else d`
的分析结果
`accept（else 归属最内层 then）`
与推导 `1 1 2 3 2 4`
可以在纸上一遍展开验证。

## 6.7 期望输出解读

`--check` 一次跑出五段。

**tokens 段**：
ANTLR 词法器
（第 4 章的 TIP.g4，
本章原样复用）
把文件切成
`IDENT('x') PLUS('+') … $`。
词法外包、语法自研，
正好衔接第 5 章。

**表达式文法段**：
十条产生式带编号；
FIRST/FOLLOW
与 6.4 节的绿龙标准答案
逐行一致；
表里 `expr` 行的
四个 1 说的是：
任何"能开始一个项"的
token 都让 expr
走唯一的产生式
`expr → term expr'`——
**选择度高
不是坏事，
是这条文法
结构清晰的表现**。
`term'` 行的
`6 6 5 6`：
面对 +、)、$ 收工，
面对 \* 再来一轮。

**parse 段**：
`leftmost derivation`
是 6.5.2 讲的
最左推导产生式序列。

**悬挂 else 文法段**：
四条产生式、
五行小表、
一个冲突与裁决。

**bad.tip**（errors 对账）：
`1 + * 2`
在第 3 个 token
（STAR）处被拒：
栈顶是非终结符 term，
表里 M[term, STAR]
是错误格子
（STAR 不能开始一个 factor），
诊断文本
`syntax error: 第 3 个 token 处 无 term 的产生式可匹配 STAR`
与退出码 1
一起进期望文件——
错误路径与成功路径
同样是对账契约的一部分。

## 6.8 工程注意点

- **递归下降就是 LL**。
  为每个非终结符
  手写一个函数、
  函数体里 switch 当前 token——
  这是把表"织进"控制流的
  表驱动分析器。
  ANTLR 生成的
  自适应 LL(\*)（ALL(\*)）
  是这个家族的现代外推：
  一个 token 看不定
  就多看几个，
  直到决策唯一。
- **左递归不必手消**。
  `TIP.g4` 的 expr 规则
  满是直接左递归
  （`expr → expr PLUS expr`），
  ANTLR 4 起内置
  左递归消除与改写，
  所以文法可以
  保持"数学直觉形态"。
  本章手消一遍的意义
  在于知道工具在替你做什么。
- **错误恢复：恐慌模式**。
  真实分析器报错后
  不能一死了之：
  朴素的恐慌模式
  丢弃输入 token
  直到进入
  出错非终结符的 FOLLOW 集，
  然后弹出栈顶继续——
  一次恢复可能
  连带丢掉一段程序，
  但能保证
  一遍扫描报出
  多个不纠缠的错误。
  本章示例报错即退，
  恢复留给练习。
- **表的形状**。
  预测表通常极稀疏
  （本章 5×8 的表
  一半是点），
  实现里常压成
  每非终结符一个
  switch 或跳转表。
- **LL(1) 的势力范围**。
  表达式、语句这类
  "骨架语言"几乎都
  能整理成 LL(1)；
  需要看两个以上符号
  才能决策、或需要
  从右端归约的语言
  （下一章的主角）
  则不行。
  选 LL 还是 LR
  从来不是宗教问题，
  是文法性质问题。

## 6.9 本章配套文件

本章示例
`examples/06_ll_parsing`：
词法复用 ANTLR
（TIP.g4 与第 4 章相同），
语法分析自研。

### 6.9.1 文法 TIP.g4

与第 4 章相同；
本章只用它的词法器。

```cpp
// file: TIP.g4
grammar TIP;

program    : function+ EOF ;
singleExpr : expr EOF ;
function   : IDENT LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE ;
params     : IDENT (COMMA IDENT)* ;
varDecls   : VAR IDENT (COMMA IDENT)* SEMI ;

stmt       : lvalue ASSIGN expr SEMI                # assignStmt
           | OUTPUT expr SEMI                      # outputStmt
           | IF LPAREN expr RPAREN stmt (ELSE stmt)? # ifStmt
           | WHILE LPAREN expr RPAREN stmt         # whileStmt
           | LBRACE stmt* RBRACE                   # blockStmt
           ;
lvalue     : IDENT (DOT IDENT)?                    # directLvalue
           | STAR expr (DOT IDENT)?                # pointerLvalue
           ;

expr       : expr LPAREN args? RPAREN              # callExpr
           | expr DOT IDENT                        # fieldExpr
           | STAR expr                             # derefExpr
           | AND IDENT                             # addrExpr
           | ALLOC expr                            # allocExpr
           | MINUS expr                            # negExpr
           | expr (STAR|DIV) expr                   # mulExpr
           | expr (PLUS|MINUS) expr                # addExpr
           | expr (GT|EQ) expr                     # cmpExpr
           | INT                                   # intExpr
           | IDENT                                 # varExpr
           | INPUT                                 # inputExpr
           | NULL                                  # nullExpr
           | LPAREN expr RPAREN                    # parenExpr
           | LBRACE field (COMMA field)* RBRACE    # recExpr
           ;
field      : IDENT COLON expr ;
args       : expr (COMMA expr)* ;

WS         : [ \t\r\n]+ -> skip ;
BLOCK_CMT  : '/*' .*? '*/' -> skip ;
LINE_CMT   : '//' ~[\r\n]* -> skip ;
INPUT      : 'input' ;
OUTPUT     : 'output' ;
IF         : 'if' ;
ELSE       : 'else' ;
WHILE      : 'while' ;
VAR        : 'var' ;
RETURN     : 'return' ;
ALLOC      : 'alloc' ;
NULL       : 'null' ;
IDENT      : [a-zA-Z_][a-zA-Z0-9_]* ;
INT        : [0-9]+ ;
ASSIGN     : '=' ;
EQ         : '==' ;
GT         : '>' ;
PLUS       : '+' ;
MINUS      : '-' ;
STAR       : '*' ;
AND        : '&' ;
DIV        : '/' ;
LPAREN     : '(' ; RPAREN : ')' ;
LBRACE     : '{' ; RBRACE : '}' ;
SEMI       : ';' ; COMMA : ',' ; DOT : '.' ; COLON : ':' ;
```

### 6.9.2 文法数据 grammar.hpp 与 grammar.cpp

两个内置文法
都是绿龙原装货的
TIP 化身。

```cpp
// file: src/grammar.hpp
// file: src/grammar.hpp
// 第 6 章配套：LL(1) 分析的“文法即数据”。
// 两个内置文法都是绿龙第 5 章的原装货：
//   expr  —— 文法 (5.9)，消除了左递归的经典表达式文法；
//   stmt  —— 文法 (5.11) 的 TIP 风格化身，自带悬挂 else 冲突。
#ifndef TIP_LL_GRAMMAR_HPP
#define TIP_LL_GRAMMAR_HPP

#include <string>
#include <vector>

namespace tip {

struct Production {
    std::string lhs;
    std::vector<std::string> rhs;   // 空向量 = ε 产生式
};

struct Grammar {
    std::string start;
    std::vector<std::string> nonterms;
    std::vector<std::string> terms;   // 不含 "$"；"$" 是输入与栈的公共同界符
    std::vector<Production> prods;

    bool isTerm(const std::string &s) const;
    bool isNonterm(const std::string &s) const;
    std::string show(const Production &p) const;
};

// E → T E' ; E' → + T E' | ε ; T → F T' ; T' → * F T' | ε ; F → INT|IDENT|INPUT|( E )
// 与绿龙 (5.9) 同构，只是 id 换成了 TIP 的 INT/IDENT/INPUT 三种“原子”。
Grammar exprGrammar();

// stmt  → if ( IDENT ) stmt stmt'
// stmt' → else stmt | ε
// 对应绿龙 (5.11)：M[stmt', else] 双定义——悬挂 else 的教科书现场。
Grammar stmtGrammar();

}  // namespace tip

#endif  // TIP_LL_GRAMMAR_HPP
```

```cpp
// file: src/grammar.cpp
// file: src/grammar.cpp
#include "grammar.hpp"

#include <sstream>

namespace tip {

bool Grammar::isTerm(const std::string &s) const {
    for (const auto &t : terms)
        if (t == s) return true;
    return false;
}

bool Grammar::isNonterm(const std::string &s) const {
    for (const auto &t : nonterms)
        if (t == s) return true;
    return false;
}

std::string Grammar::show(const Production &p) const {
    std::ostringstream os;
    os << p.lhs << " ->";
    if (p.rhs.empty()) {
        os << " ε";
    } else {
        for (const auto &x : p.rhs) os << ' ' << x;
    }
    return os.str();
}

Grammar exprGrammar() {
    Grammar g;
    g.start = "expr";
    g.nonterms = {"expr", "expr'", "term", "term'", "factor"};
    g.terms = {"INT", "IDENT", "INPUT", "LPAREN", "RPAREN", "PLUS", "STAR"};
    g.prods = {
        {"expr", {"term", "expr'"}},                    // 1
        {"expr'", {"PLUS", "term", "expr'"}},           // 2
        {"expr'", {}},                                  // 3
        {"term", {"factor", "term'"}},                  // 4
        {"term'", {"STAR", "factor", "term'"}},         // 5
        {"term'", {}},                                  // 6
        {"factor", {"INT"}},                            // 7
        {"factor", {"IDENT"}},                          // 8
        {"factor", {"INPUT"}},                          // 9
        {"factor", {"LPAREN", "expr", "RPAREN"}},       // 10
    };
    return g;
}

Grammar stmtGrammar() {
    Grammar g;
    g.start = "stmt";
    g.nonterms = {"stmt", "stmt'"};
    g.terms = {"IF", "LPAREN", "IDENT", "RPAREN", "ELSE"};
    g.prods = {
        {"stmt", {"IF", "LPAREN", "IDENT", "RPAREN", "stmt", "stmt'"}},  // 1
        {"stmt", {"IDENT"}},                                             // 2
        {"stmt'", {"ELSE", "stmt"}},                                     // 3
        {"stmt'", {}},                                                   // 4
    };
    return g;
}

}  // namespace tip
```

### 6.9.3 LL(1) 引擎 ll1.hpp 与 ll1.cpp

FIRST/FOLLOW 不动点、
Algorithm 5.4 造表、
冲突记录与"最近 else"消解、
Fig 5.23 预测分析器。

```cpp
// file: src/ll1.hpp
// file: src/ll1.hpp
// 第 6 章配套：FIRST/FOLLOW 的不动点计算、LL(1) 表构造与冲突检测。
#ifndef TIP_LL1_HPP
#define TIP_LL1_HPP

#include "grammar.hpp"

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

inline const std::string EPS = "ε";   // FIRST 集里的空串标记
inline const std::string DOLLAR = "$";

struct LL1 {
    const Grammar &g;
    std::map<std::string, std::set<std::string>> first;    // 非终结符 → FIRST
    std::map<std::string, std::set<std::string>> follow;   // 非终结符 → FOLLOW
    // (非终结符, 终结符或$) → 产生式下标（0 起）。多定义时保留胜者并记入 conflicts。
    std::map<std::pair<std::string, std::string>, int> table;
    // 冲突清单：(格子, 候选产生式下标们, 胜者)
    struct Conflict {
        std::string A, a;
        std::vector<int> candidates;
        int winner;
    };
    std::vector<Conflict> conflicts;

    explicit LL1(const Grammar &g);

    // FIRST(序列)：逐项吸收，遇 ε 项继续，全 ε 则含 ε。
    std::set<std::string> firstOf(const std::vector<std::string> &beta) const;

    void computeFirst();    // 规则迭代到不动点（工作表思想的又一现身）
    void computeFollow();
    void buildTable(bool resolveClosestElse);
};

// 表驱动预测分析器（绿龙 Fig 5.23 的程序化）。
struct ParseResult {
    bool ok = false;
    std::vector<int> usedProds;      // 最左推导所用的产生式序列
    std::string error;               // 失败时的诊断（供 expected/errors 对账）
    size_t consumed = 0;             // 失败时已消耗的 token 数
};

ParseResult predict(const LL1 &ll, const std::vector<std::string> &input);

}  // namespace tip

#endif  // TIP_LL1_HPP
```

```cpp
// file: src/ll1.cpp
// file: src/ll1.cpp
// 第 6 章配套：LL(1) 引擎实现——FIRST/FOLLOW/表/冲突/预测分析。
#include "ll1.hpp"

#include <cassert>

namespace tip {

LL1::LL1(const Grammar &g) : g(g) {}

// ---------- FIRST ----------
// 绿龙的口径：对每个非终结符反复套用三条规则，直到没有任何集合再变大。
// 这是“从下界出发、单调上升、有限高度”的迭代——第 27 章的不动点骨架。
std::set<std::string> LL1::firstOf(const std::vector<std::string> &beta) const {
    std::set<std::string> out;
    bool allEps = true;
    for (const auto &x : beta) {
        std::set<std::string> fx;
        if (g.isTerm(x) || x == DOLLAR) {
            fx = {x};
        } else {
            auto it = first.find(x);
            if (it != first.end()) fx = it->second;
        }
        for (const auto &t : fx)
            if (t != EPS) out.insert(t);
        if (!fx.count(EPS)) {
            allEps = false;
            break;
        }
    }
    if (allEps) out.insert(EPS);
    return out;
}

void LL1::computeFirst() {
    for (const auto &A : g.nonterms) first[A] = {};
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : g.prods) {
            auto &F = first[p.lhs];
            size_t before = F.size();
            for (const auto &t : firstOf(p.rhs)) F.insert(t);
            if (F.size() != before) changed = true;
        }
    }
}

// ---------- FOLLOW ----------
void LL1::computeFollow() {
    for (const auto &A : g.nonterms) follow[A] = {};
    follow[g.start].insert(DOLLAR);
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : g.prods) {
            for (size_t i = 0; i < p.rhs.size(); ++i) {
                const auto &B = p.rhs[i];
                if (!g.isNonterm(B)) continue;
                auto &FB = follow[B];
                size_t before = FB.size();
                // 规则 2：后面紧跟的串的 FIRST（去掉 ε）进 FOLLOW
                std::vector<std::string> rest(p.rhs.begin() + i + 1, p.rhs.end());
                auto fr = firstOf(rest);
                for (const auto &t : fr)
                    if (t != EPS) FB.insert(t);
                // 规则 3：尾部可推空，则左部的 FOLLOW 传递下来
                if (fr.count(EPS) || rest.empty()) {
                    for (const auto &t : follow[p.lhs]) FB.insert(t);
                }
                if (FB.size() != before) changed = true;
            }
        }
    }
}

// ---------- 表构造（绿龙 Algorithm 5.4） ----------
namespace {
// “最近 else”消解：候选里若有右端以 a 开头者（即会吃掉当前 token 的产生式，
// 相当于移进 else），选它——绿龙对文法 (5.11) 的经典裁决：
// 选 S'→eS 让 else 与最内层 then 配对；选 ε 会让 else 永远无法被消费。
int pickWinner(const tip::Grammar &g, const std::string &a,
               int oldIdx, int newIdx, bool resolveClosestElse) {
    if (!resolveClosestElse) return oldIdx;
    if (!g.prods[oldIdx].rhs.empty() && g.prods[oldIdx].rhs[0] == a) return oldIdx;
    if (!g.prods[newIdx].rhs.empty() && g.prods[newIdx].rhs[0] == a) return newIdx;
    return oldIdx;
}
}  // namespace

void LL1::buildTable(bool resolveClosestElse) {
    auto put = [&](const std::string &A, const std::string &a, int idx) {
        auto cell = std::make_pair(A, a);
        auto it = table.find(cell);
        if (it == table.end()) {
            table[cell] = idx;
        } else if (it->second != idx) {
            int winner = pickWinner(g, a, it->second, idx, resolveClosestElse);
            conflicts.push_back({A, a, {it->second, idx}, winner});
            it->second = winner;
        }
    };
    for (size_t idx = 0; idx < g.prods.size(); ++idx) {
        const auto &p = g.prods[idx];
        auto fs = firstOf(p.rhs);
        for (const auto &a : fs)
            if (a != EPS) put(p.lhs, a, static_cast<int>(idx));
        if (fs.count(EPS))
            for (const auto &b : follow[p.lhs])
                put(p.lhs, b, static_cast<int>(idx));
    }
}

// ---------- 预测分析器（绿龙 Fig 5.23） ----------
ParseResult predict(const LL1 &ll, const std::vector<std::string> &input) {
    ParseResult r;
    std::vector<std::string> stack = {DOLLAR, ll.g.start};
    size_t ip = 0;
    while (true) {
        std::string X = stack.back();
        std::string a = ip < input.size() ? input[ip] : DOLLAR;
        if (X == DOLLAR && a == DOLLAR) {
            r.ok = true;
            return r;
        }
        if (ll.g.isTerm(X) || X == DOLLAR) {
            if (X == a) {
                stack.pop_back();
                ++ip;
            } else {
                r.error = "栈顶 " + X + " 期待 " + a;
                r.consumed = ip;
                return r;
            }
        } else {
            auto it = ll.table.find({X, a});
            if (it == ll.table.end()) {
                r.error = "无 " + X + " 的产生式可匹配 " + a;
                r.consumed = ip;
                return r;
            }
            stack.pop_back();
            const auto &rhs = ll.g.prods[it->second].rhs;
            for (auto rit = rhs.rbegin(); rit != rhs.rend(); ++rit) stack.push_back(*rit);
            r.usedProds.push_back(it->second);
        }
    }
}

}  // namespace tip
```

### 6.9.4 驱动 main.cpp

ANTLR 词法 →
表达式文法全流程 →
悬挂 else 冲突演示。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 6 章驱动：--check FILE
//   1) 表达式文法（绿龙 5.9）：FIRST/FOLLOW/表 + 对 FILE 的 token 流做预测分析；
//   2) 悬挂 else 文法（绿龙 5.11）：冲突现场 + “最近 else”消解 + 内嵌样例的推导。
// 词法外包给 ANTLR（第 4 章的 TIP.g4），语法分析完全自研——正好对上
// “词法是自动机（第 5 章），语法是下推自动机（本章）”的分工。
#include "grammar.hpp"
#include "ll1.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"

#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>

namespace {

struct Tok {
    std::string type, text;
};

std::vector<Tok> lexTip(const std::string &path) {
    std::ifstream stream(path);
    if (!stream) throw std::runtime_error("打不开 " + path);
    antlr4::ANTLRInputStream input(stream);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    tokens.fill();
    std::vector<Tok> out;
    for (antlr4::Token *t : tokens.getTokens()) {
        if (t->getType() == antlr4::Token::EOF) continue;   // 结尾的 $ 由调用方补
        std::string name(lexer.getVocabulary().getSymbolicName(t->getType()));
        out.push_back({name, t->getText()});
    }
    return out;
}

void dumpGrammar(const tip::Grammar &g) {
    int i = 0;
    for (const auto &p : g.prods)
        std::cout << "  [" << ++i << "] " << g.show(p) << '\n';
}

void dumpSets(const tip::LL1 &ll) {
    std::cout << "== FIRST ==\n";
    for (const auto &A : ll.g.nonterms) {
        std::cout << "  " << A << ": {";
        bool first = true;
        for (const auto &t : ll.first.at(A)) {
            if (!first) std::cout << ", ";
            std::cout << t;
            first = false;
        }
        std::cout << "}\n";
    }
    std::cout << "== FOLLOW ==\n";
    for (const auto &A : ll.g.nonterms) {
        std::cout << "  " << A << ": {";
        bool first = true;
        for (const auto &t : ll.follow.at(A)) {
            if (!first) std::cout << ", ";
            std::cout << t;
            first = false;
        }
        std::cout << "}\n";
    }
}

void dumpTable(const tip::LL1 &ll) {
    std::cout << "== table ==\n";
    std::vector<std::string> cols = ll.g.terms;
    cols.push_back(tip::DOLLAR);
    std::cout << "  ";
    for (const auto &c : cols) std::cout << '\t' << c;
    std::cout << '\n';
    for (const auto &A : ll.g.nonterms) {
        std::cout << "  " << A;
        for (const auto &c : cols) {
            auto it = ll.table.find({A, c});
            if (it == ll.table.end()) std::cout << "\t.";
            else std::cout << '\t' << (it->second + 1);
        }
        std::cout << '\n';
    }
    if (ll.conflicts.empty()) {
        std::cout << "== conflicts ==\n  none\n";
    } else {
        std::cout << "== conflicts ==\n";
        for (const auto &cf : ll.conflicts) {
            std::cout << "  M[" << cf.A << ", " << cf.a << "]: 候选 {";
            for (size_t i = 0; i < cf.candidates.size(); ++i)
                std::cout << (i ? ", " : "") << (cf.candidates[i] + 1);
            std::cout << "} -> 取 [" << (cf.winner + 1) << "]（最近 else 策略）\n";
        }
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    std::vector<Tok> toks = lexTip(argv[2]);
    std::vector<std::string> input;
    std::cout << "== tokens ==\n";
    for (const auto &t : toks) {
        std::cout << t.type << "('" << t.text << "') ";
        input.push_back(t.type);
    }
    std::cout << "$\n";

    tip::Grammar eg = tip::exprGrammar();
    std::cout << "== grammar: 表达式文法（绿龙 5.9 的 TIP 化身）==\n";
    dumpGrammar(eg);
    tip::LL1 el(eg);
    el.computeFirst();
    el.computeFollow();
    el.buildTable(false);
    dumpSets(el);
    dumpTable(el);

    std::cout << "== parse ==\n";
    tip::ParseResult r = tip::predict(el, input);
    if (r.ok) {
        std::cout << "  leftmost derivation: ";
        for (size_t i = 0; i < r.usedProds.size(); ++i)
            std::cout << (i ? " " : "") << (r.usedProds[i] + 1);
        std::cout << '\n';
        std::cout << "  result: accept\n";
    } else {
        std::cout << "  result: reject\n";
        std::cerr << "syntax error: 第 " << (r.consumed + 1) << " 个 token 处 "
                  << r.error << '\n';
        return 1;
    }

    // ---------- 悬挂 else ----------
    tip::Grammar sg = tip::stmtGrammar();
    std::cout << "== grammar: 悬挂 else 文法（绿龙 5.11 的 TIP 化身）==\n";
    dumpGrammar(sg);
    tip::LL1 sl(sg);
    sl.computeFirst();
    sl.computeFollow();
    sl.buildTable(true);
    dumpTable(sl);
    std::cout << "== parse: if (a) if (b) c else d ==\n";
    std::vector<std::string> demo = {"IF", "LPAREN", "IDENT", "RPAREN",
                                     "IF", "LPAREN", "IDENT", "RPAREN",
                                     "IDENT", "ELSE", "IDENT"};
    tip::ParseResult dr = tip::predict(sl, demo);
    if (dr.ok) {
        std::cout << "  leftmost derivation: ";
        for (size_t i = 0; i < dr.usedProds.size(); ++i)
            std::cout << (i ? " " : "") << (dr.usedProds[i] + 1);
        std::cout << '\n';
        std::cout << "  result: accept（else 归属最内层 then）\n";
    } else {
        std::cout << "  result: reject " << dr.error << '\n';
    }
    return 0;
}
```

### 6.9.5 程序与错误样例

`add.tip` 与 `paren.tip`
是两个纯表达式文件；
`errors/bad.tip`
在 STAR 处触发
错误格子。

```text
// file: programs/add.tip
x + 21 * y
```

```text
// file: programs/paren.tip
(a + b) * (c + input)
```

```text
// file: programs/errors/bad.tip
1 + * 2
```

### 6.9.6 期望输出 expected/output.txt 与 expected/errors/bad.txt

```text
; expected: expected/output.txt
== add.tip ==
== tokens ==
IDENT('x') PLUS('+') INT('21') STAR('*') IDENT('y') $
== grammar: 表达式文法（绿龙 5.9 的 TIP 化身）==
  [1] expr -> term expr'
  [2] expr' -> PLUS term expr'
  [3] expr' -> ε
  [4] term -> factor term'
  [5] term' -> STAR factor term'
  [6] term' -> ε
  [7] factor -> INT
  [8] factor -> IDENT
  [9] factor -> INPUT
  [10] factor -> LPAREN expr RPAREN
== FIRST ==
  expr: {IDENT, INPUT, INT, LPAREN}
  expr': {PLUS, ε}
  term: {IDENT, INPUT, INT, LPAREN}
  term': {STAR, ε}
  factor: {IDENT, INPUT, INT, LPAREN}
== FOLLOW ==
  expr: {$, RPAREN}
  expr': {$, RPAREN}
  term: {$, PLUS, RPAREN}
  term': {$, PLUS, RPAREN}
  factor: {$, PLUS, RPAREN, STAR}
== table ==
  	INT	IDENT	INPUT	LPAREN	RPAREN	PLUS	STAR	$
  expr	1	1	1	1	.	.	.	.
  expr'	.	.	.	.	3	2	.	3
  term	4	4	4	4	.	.	.	.
  term'	.	.	.	.	6	6	5	6
  factor	7	8	9	10	.	.	.	.
== conflicts ==
  none
== parse ==
  leftmost derivation: 1 4 8 6 2 4 7 5 8 6 3
  result: accept
== grammar: 悬挂 else 文法（绿龙 5.11 的 TIP 化身）==
  [1] stmt -> IF LPAREN IDENT RPAREN stmt stmt'
  [2] stmt -> IDENT
  [3] stmt' -> ELSE stmt
  [4] stmt' -> ε
== table ==
  	IF	LPAREN	IDENT	RPAREN	ELSE	$
  stmt	1	.	2	.	.	.
  stmt'	.	.	.	.	3	4
== conflicts ==
  M[stmt', ELSE]: 候选 {3, 4} -> 取 [3]（最近 else 策略）
== parse: if (a) if (b) c else d ==
  leftmost derivation: 1 1 2 3 2 4
  result: accept（else 归属最内层 then）
== paren.tip ==
== tokens ==
LPAREN('(') IDENT('a') PLUS('+') IDENT('b') RPAREN(')') STAR('*') LPAREN('(') IDENT('c') PLUS('+') INPUT('input') RPAREN(')') $
== grammar: 表达式文法（绿龙 5.9 的 TIP 化身）==
  [1] expr -> term expr'
  [2] expr' -> PLUS term expr'
  [3] expr' -> ε
  [4] term -> factor term'
  [5] term' -> STAR factor term'
  [6] term' -> ε
  [7] factor -> INT
  [8] factor -> IDENT
  [9] factor -> INPUT
  [10] factor -> LPAREN expr RPAREN
== FIRST ==
  expr: {IDENT, INPUT, INT, LPAREN}
  expr': {PLUS, ε}
  term: {IDENT, INPUT, INT, LPAREN}
  term': {STAR, ε}
  factor: {IDENT, INPUT, INT, LPAREN}
== FOLLOW ==
  expr: {$, RPAREN}
  expr': {$, RPAREN}
  term: {$, PLUS, RPAREN}
  term': {$, PLUS, RPAREN}
  factor: {$, PLUS, RPAREN, STAR}
== table ==
  	INT	IDENT	INPUT	LPAREN	RPAREN	PLUS	STAR	$
  expr	1	1	1	1	.	.	.	.
  expr'	.	.	.	.	3	2	.	3
  term	4	4	4	4	.	.	.	.
  term'	.	.	.	.	6	6	5	6
  factor	7	8	9	10	.	.	.	.
== conflicts ==
  none
== parse ==
  leftmost derivation: 1 4 10 1 4 8 6 2 4 8 6 3 5 10 1 4 8 6 2 4 9 6 3 6 3
  result: accept
== grammar: 悬挂 else 文法（绿龙 5.11 的 TIP 化身）==
  [1] stmt -> IF LPAREN IDENT RPAREN stmt stmt'
  [2] stmt -> IDENT
  [3] stmt' -> ELSE stmt
  [4] stmt' -> ε
== table ==
  	IF	LPAREN	IDENT	RPAREN	ELSE	$
  stmt	1	.	2	.	.	.
  stmt'	.	.	.	.	3	4
== conflicts ==
  M[stmt', ELSE]: 候选 {3, 4} -> 取 [3]（最近 else 策略）
== parse: if (a) if (b) c else d ==
  leftmost derivation: 1 1 2 3 2 4
  result: accept（else 归属最内层 then）
```

```text
; expected: expected/errors/bad.txt
== tokens ==
INT('1') PLUS('+') STAR('*') INT('2') $
== grammar: 表达式文法（绿龙 5.9 的 TIP 化身）==
  [1] expr -> term expr'
  [2] expr' -> PLUS term expr'
  [3] expr' -> ε
  [4] term -> factor term'
  [5] term' -> STAR factor term'
  [6] term' -> ε
  [7] factor -> INT
  [8] factor -> IDENT
  [9] factor -> INPUT
  [10] factor -> LPAREN expr RPAREN
== FIRST ==
  expr: {IDENT, INPUT, INT, LPAREN}
  expr': {PLUS, ε}
  term: {IDENT, INPUT, INT, LPAREN}
  term': {STAR, ε}
  factor: {IDENT, INPUT, INT, LPAREN}
== FOLLOW ==
  expr: {$, RPAREN}
  expr': {$, RPAREN}
  term: {$, PLUS, RPAREN}
  term': {$, PLUS, RPAREN}
  factor: {$, PLUS, RPAREN, STAR}
== table ==
  	INT	IDENT	INPUT	LPAREN	RPAREN	PLUS	STAR	$
  expr	1	1	1	1	.	.	.	.
  expr'	.	.	.	.	3	2	.	3
  term	4	4	4	4	.	.	.	.
  term'	.	.	.	.	6	6	5	6
  factor	7	8	9	10	.	.	.	.
== conflicts ==
  none
== parse ==
  result: reject
syntax error: 第 3 个 token 处 无 term 的产生式可匹配 STAR
```

## 6.10 小结与练习

本章把"从根猜推导"
做成了确定性算法：

- 消左递归与提左公因子
  把文法整形成
  "看一个符号能决策"的形态；
- FIRST/FOLLOW
  用不动点迭代
  算出决策依据；
- Algorithm 5.4
  把依据编译成一张表，
  预测分析器
  用一张栈把表跑起来，
  产出的正是最左推导；
- 冲突即二义的显影，
  悬挂 else 的
  "最近配对"消解
  是全行业的标准答案。

下一章换到底座：
不再从根往下猜，
而是从叶子往上**归约**，
句柄、项集、
移进-归约的斗争
——LR 的世界。

练习：

1. 手工对表达式文法
   算一遍 FIRST/FOLLOW，
   与期望输出比对；
   再造表，与输出的
   表逐格核对。
2. 对 `paren.tip`
   手工跑预测分析器，
   复原它的最左推导，
   与程序输出比对。
3. 把 `MINUS` 加入文法
   （expr' 与 term' 各一条），
   重新生成期望输出，
   观察 FIRST/FOLLOW
   与表的变化。
4. 给 stmt 文法加
   `stmt → LBRACE stmt RBRACE`，
   重算 FOLLOW，
   解释冲突为什么消失
   （或为什么不消失）。
5. 实现恐慌模式恢复：
   报错后丢弃 token
   直到 FOLLOW(栈顶非终结符)
   命中，弹出后继续；
   在 bad.tip 上
   展示"一次扫描多个错误"。
