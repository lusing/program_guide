# 第 7 章　LR 分析：项集、SLR 表与移进-归约

## 7.1 换个方向：从叶子往上长

第 6 章的自顶向下分析
从开始符号出发，
一路**猜**到输入。
本章掉转炮口：
从输入的第一个 token 出发，
一路把已经看清的部分
**归约**成非终结符，
直到只剩开始符号。
这叫自底向上分析，
工业界语法分析的主流
（yacc、bison 及其无数后裔）。

自底向上的钥匙概念是**句柄**：
在最右推导的某个中间形态里，
那个"下一步将被替换"的
产生式右部。
自底向上分析
= 不断在栈顶找到句柄并归约。
全部难点浓缩成一个问题：

> 栈顶这串符号，
> 现在是不是一个句柄？
> 如果是，是哪条产生式的？

本章讲 LR 家族中最平易的
一支——SLR(1)。
材料取自绿龙第 6 章
与紫龙 4.5–4.8 节，
定义、算法、反例全部自包含。
配套示例
`examples/07_lr_parsing`
实现了完整的
项集构造 → SLR 造表 →
移进-归约驱动，
并把第 6 章的悬挂 else
重新审一遍。

## 7.2 移进-归约：栈上的左右互搏

LR 分析器的硬件
（绿龙 Fig 6.2）四件套：

- 输入（末尾补 $）；
- **状态栈**（栈底是状态 0）；
- 配套的符号栈（纯展示用，
  真正干活的是状态栈）；
- ACTION 与 GOTO 两张表。

每一步看栈顶状态 i
与当前输入 a，
查 ACTION[i, a]：

- **s j**（shift）：
  把 j 压栈，吃掉 a；
- **r k**（reduce，
  按第 k 条产生式 A → β）：
  弹掉 |β| 个状态，
  露出的状态 i' 配 A
  查 GOTO[i', A] 得 j，
  把 j 压栈
  （注意：归约**不看** a，
  a 只是许可证）；
- **acc**：接受；
- 空格：报错。

GOTO 表回答
"归约出 A 之后去哪"，
它与非终结符对应，
所以单独一张。
ACTION 与 GOTO
合称 LR 分析表。

绿龙 Fig 6.4
对 `id * id + id` 的
十四步 moves
是这门课的传家练习；
本章示例对
`x + 21 * y` 输出的
moves 表与之逐行同构：

```
(1) 0 | IDENT PLUS INT STAR IDENT $ | shift 2
(2) 0 IDENT 2 | PLUS INT STAR IDENT $ | reduce factor -> IDENT
(3) 0 factor 6 | PLUS INT STAR IDENT $ | reduce term -> factor
(4) 0 term 7 | PLUS INT STAR IDENT $ | reduce expr -> term
(5) 0 expr 5 | PLUS INT STAR IDENT $ | shift 9
...
(13) 0 expr 5 PLUS 9 term 12 | $ | reduce expr -> expr PLUS term
(14) 0 expr 5 | $ | accept
```

读两遍就能看出节奏：
实符号进栈（shift），
凑齐一个右部就
连符号带状态一起
弹掉、换上新非终结符（reduce）。
把 reduce 用到的产生式
**倒着**记下来，
恰好得到**最右推导**——
自顶向下产出最左推导、
自底向上产出最右推导，
两个方向在此对称。

## 7.3 LR(0) 项：把“期望”编码进状态

怎么知道栈顶是不是句柄？
绿龙的洞察：
造一台识别"活前缀"
（viable prefix——
最右句型里
句柄以左的那一段）
的有限自动机，
让栈顶状态
就是这台自动机
读完整个栈后的状态。

这台自动机的状态
叫 **LR(0) 项**：
一条产生式右部
加一个点。
产生式 `A → XYZ`
生成四个项：

```
A → ·XYZ    还什么都没想到，期望整个 XYZ
A → X·YZ    已见到 X，期望 YZ
A → XY·Z    已见到 XY，期望 Z
A → XYZ·    已见齐，A → XYZ 可作归约候选
```

ε 产生式只有一个项
`A → ·`。
项 = "这条产生式
进行到什么程度了"。
把很多项装进一个集合，
项集就是分析器的状态；
栈顶状态因此同时
记着所有"正在进行中"的
产生式进度——
这就是"栈的历史"
被压缩成的形态。

## 7.4 CLOSURE 与 GOTO：子集构造的还魂

两个函数把项集变成自动机。

**CLOSURE(I)**
（绿龙 Fig 6.5）：
对 I 里每个
点右边是非终结符 B 的项
`A → α·Bβ`，
把 B 的所有产生式
以 `B → ·γ` 的形态加进来，
反复到饱和。
直觉：
"期望看到 Bβ"
意味着"期望看到
B 推导出的任何东西"，
于是 B 的每条产生式
都处于"即将开始"的状态。

**GOTO(I, X)**：
把 I 里点右边是 X 的项
移点（`A → α·Xβ` 变
`A → αX·β`），
再取闭包。
直觉：
符号 X 到货后，
所有相关产生式前进一格。

**规范项集族**
（绿龙 Fig 6.6 的 ITEMS）：
从 `CLOSURE({S' → ·S})`
出发（S'→S 是**增广产生式**，
专门为"接受"提供一个
可识别的时机），
对每个项集、每个文法符号
求 GOTO，
新集合入列，
直到不动点。

绿龙在这里说破了天机：
**这套构造就是第 5 章的
子集构造**。
把每个项看成 NFA 的状态：
移点是实符号边，
"点后非终结符引入其产生式"
是 ε 扇出；
CLOSURE 就是 ε-CLOSURE，
ITEMS 就是从起点出发的
不动点扩张。
第 5 章的字符自动机
识别 token，
这里的项集自动机识别活前缀——
同一台数学机器，
两次装机。

配套实现的 `closure`
用了绿龙提示的
ADDED 布尔表：
某非终结符的全部产生式
一旦加入过就不再扫它，
让闭包代价
与文法规模线性相关。

## 7.5 SLR 造表：给归约发许可证

有了项集族，
造 ACTION/GOTO 只剩
六条规则
（绿龙 Algorithm 6.1）。
设状态 i 来自项集 Iᵢ：

1. `A → α·aβ ∈ Iᵢ`，
   a 是终结符，
   GOTO(Iᵢ,a)=Iⱼ：
   ACTION[i,a] := shift j；
2. `A → α· ∈ Iᵢ`（点在末尾）：
   对每个 a ∈ FOLLOW(A)：
   ACTION[i,a] := reduce A→α；
3. `S' → S· ∈ Iᵢ`：
   ACTION[i,$] := accept；
4. GOTO(Iᵢ,A)=Iⱼ：
   GOTO[i,A] := j；
5. 未定义者皆 error；
6. 初始状态是含
   `S' → ·S` 的项集对应的状态。

规则 2 是"Simple"的出处：
点走到头时，
并不对所有输入都归约，
只在 **FOLLOW(A)** 里放 r——
用第 6 章的 FOLLOW
当作归约的许可证。
这个一刀切有时
许可得太多（下一节的反例），
但对付大多数
程序语言文法绰绰有余。

对经典表达式文法
（绿龙文法 6.1），
这套规则产出
绿龙 Fig 6.3 的名表；
本章示例的表与之同构，
只是 factor 多了 INPUT
第四个候选，
项集从书上的 12 个
长到 14 个。

若某格子被塞进
两种不同动作，
文法就不是 SLR(1)。
冲突分两类：
**移进-归约**（shift 撞 reduce）
与**归约-归约**
（两条 reduce 相撞）。

## 7.6 非 SLR 的文法：绿龙的 L=R 反例

绿龙 Example 6.8 的文法
（原文照录的口径）：

```
S → L = R | R
L → * R | id
R → L
```

L、R 可读作左值/右值，
\* 是"取内容"。
它无二义，
却不是 SLR(1)。
项集 I₂ 同时含有

```
S → L · = R      （规则 1：action[2, =] = shift 6）
R → L ·           （规则 2：FOLLOW(R) ∋ =，action[2, =] = reduce R → L）
```

action[2, =]
双定义——移进-归约冲突。
病根：
FOLLOW(R) 把 "=" 算进来
是因为 S ⇒ L=R ⇒ R=R；
但栈上是 `… L` 时
如果这个 L 其实是
`L = R` 里**等号左边**的 L，
下一步必须 shift。
SLR 的 FOLLOW
是"全局可能"，
不是"此处可行"——
一刀切的许可证
在这里发宽了。

两张药方
（本章只开处方、不抓药）：

- **规范 LR(1)**：
  给每个项配上**搜索符**
  ——把"何时归约"的许可
  从 FOLLOW(A) 收窄到
  "这个项在这个上下文里
  后面真正能跟什么"。
  精度换规模：
  状态数可能暴涨；
- **LALR(1)**：
  把"同核不同搜索符"的
  LR(1) 状态**合并**，
  规模回到 SLR 量级、
  精度几乎追平 LR(1)。
  yacc/bison 用的就是它。

## 7.7 悬挂 else：LR 世界再审

第 6 章的老冤家
换成 LR 文法再来一遍
（绿龙 6.1 节的非 LR 构造）：

```
stmt → if ( IDENT ) stmt
     | if ( IDENT ) stmt else stmt
     | IDENT
```

当栈上是 `… if (x) stmt`
而输入是 `else` 时：

- 归约第一条
  （"then 部分到此为止"），
  else 留给外层；
- 或移进 else，
  让它属于这层 if。

栈（以及一个前瞻符号）
无法区分两者——
绿龙据此证明
这个文法不是 LR(1)
（任何二义文法
对任何 k 都不 LR(k)）。

出路与第 6 章同款：
**冲突照报，裁决 prefer-shift**。
移进 else
= else 配最近的 then。
示例输出里：

```
== conflicts ==
  action[7, ELSE]: shift-reduce（移进 8 vs 归约 [1]）-> prefer-shift（最近 else）
```

而 moves 表的最后几步
把裁决的语义
演成了铁证：

```
(13) … stmt 7 ELSE 8 IDENT 2 | $ | reduce stmt -> IDENT
(14) … stmt 7 ELSE 8 stmt 9 | $ | reduce stmt -> if (ID) stmt ELSE stmt
(15) … stmt 7 | $ | reduce stmt -> if (ID) stmt
(16) 0 stmt 3 | $ | accept
```

第 (14) 步先归约的是
**内层**带 else 的 stmt，
第 (15) 步才轮到外层——
else 被最内层 then
先下手为强。
yacc 处理悬挂 else 的
默认裁决
与此一字不差。

## 7.8 左递归：LR 的甜点

对照第 6 章：
同样的表达式文法，
LL 世界要先动
消左递归的手术；
LR 世界原样上桌：

```
expr → expr PLUS term | term
```

不但能吃，
左递归还**恰好**给出
左结合——
`a - b - c` 归约成
`(a-b)-c`，
因为栈上凑齐
`expr - term` 就地归约，
先来先得。
方向决定口味：
自顶向下的最左推导
怕左递归（无限递归），
自底向上的最右推导
与左递归天然亲善。
这也是真实编译器
偏爱 LR 系的一大战术理由：
文法可以保持
语言手册里的
直觉形态，不必整形。

## 7.9 期望输出解读

输出五段，逐段读。

**tokens 与 grammar**：
ANTLR 词法器供弹
（与第 6 章相同）；
八条产生式——
注意它们带着左递归，
原汁原味。

**canonical LR(0) collection**：
14 个项集 I₀…I₁₃。
I₀ 是
`CLOSURE({expr' → ·expr})`
的九项全展：
点在 expr 前，
于是 expr/term/factor 的
所有产生式
全部以起点形态入场。
书上的文法 6.1
只有 12 个状态，
因为它的 factor
只有 id 和 (E) 两个候选，
我们的 INPUT 候选
多造了两个状态——
比较两份表格
是熟悉"项集怎么长"
的最快方式。

**SLR table**：
ACTION 列是七个终结符加 $，
GOTO 列是三个非终结符。
行 0 的 `s1 s2 s3 s4`
对应 I₀ 里四个
`factor → ·…` 候选
（INT/IDENT/INPUT/LPAREN
各自 shift）；
行 5 的 `acc`
来自 `expr' → expr ·`。
归约格 r1…r8 的分布
可以对着 FOLLOW
逐行验算
（FOLLOW(expr) = {$, RPAREN, PLUS}……
等等，PLUS 在不在？
动手算一遍，
这是本章练习一的题面）。

**moves**：
7.2 节已逐行读过。
数一遍 shift 与 reduce
的次数，
和输入 token 数、
产生式右部长度
对账。

**悬挂 else 段**：
项集 + 表 + 一个冲突
+ 十六步 moves，
7.7 节全部讲完。

## 7.10 工程注意点

- **yacc/bison 是 LALR(1)**。
  生成器读文法、
  造 LALR 表、
  把冲突如实写进
  y.output 报告，
  让写文法的人裁决——
  本章的 conflicts
  输出就是它的袖珍版。
- **ANTLR 是 LL 家族**。
  ANTLR 4 的 ALL(\*)
  用前瞻到决策唯一为止，
  免去手工整形；
  两大家族的现实分野
  是"文法友好度
  vs 错误消息友好度"的
  权衡，不是谁取代谁。
- **表的压缩**。
  LALR 表常以
  稀疏矩阵压缩存放
  （每状态一行
  压缩数组），
  紫龙 4.7.6 有专论。
- **错误恢复**。
  LR 的状态天然知道
  "此刻期望哪些符号"，
  恢复时可以把
  期望集合直接写进
  错误消息——
  "expecting ';' or '}'"
  这类诊断的出处。
  恐慌式丢弃
  （跳到能走的符号）
  与 LL 版同理。
- **为什么状态栈够了**。
  7.3 的活前缀定理
  （绿龙原书）
  说栈内容的一切
  相关信息都浓缩在
  栈顶状态里——
  分析器从不需要
  回头翻栈。
  这也是 LR
  每步 O(1) 的原因。

## 7.11 本章配套文件

本章示例
`examples/07_lr_parsing`：
词法复用 ANTLR，
语法分析自研 SLR。

### 7.11.1 文法 TIP.g4

与第 4 章相同；
只用词法器。

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

### 7.11.2 文法数据 grammar.hpp 与 grammar.cpp

左递归表达式文法
与悬挂 else 文法。

```cpp
// file: src/grammar.hpp
// file: src/grammar.hpp
// 第 7 章配套：LR 分析用的文法数据。
// 与第 6 章的关键对照：这里的表达式文法保留左递归——
// LR 分析不但不怕左递归，左递归还天然给出左结合，
// 正是绿龙文法 (6.1) 的原味。
#ifndef TIP_LR_GRAMMAR_HPP
#define TIP_LR_GRAMMAR_HPP

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
    std::vector<std::string> terms;   // 不含 "$"
    std::vector<Production> prods;

    bool isTerm(const std::string &s) const;
    bool isNonterm(const std::string &s) const;
    std::string show(const Production &p) const;
};

// 经典表达式文法（绿龙 6.1 的 TIP 化身，左递归原样保留）：
//   expr → expr + term | term ; term → term * factor | factor
//   factor → INT | IDENT | INPUT | ( expr )
Grammar exprGrammarLR();

// 悬挂 else 文法（绿龙 S → iCtS | iCtSeS 的 TIP 化身）：
//   stmt → if ( IDENT ) stmt
//        | if ( IDENT ) stmt else stmt
//        | IDENT
// SLR 造表必然在 ELSE 上出移进-归约冲突，prefer-shift 即“最近 else”。
Grammar danglingElseGrammar();

}  // namespace tip

#endif  // TIP_LR_GRAMMAR_HPP
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
    if (p.rhs.empty()) os << " ε";
    else for (const auto &x : p.rhs) os << ' ' << x;
    return os.str();
}

Grammar exprGrammarLR() {
    Grammar g;
    g.start = "expr";
    g.nonterms = {"expr", "term", "factor"};
    g.terms = {"INT", "IDENT", "INPUT", "LPAREN", "RPAREN", "PLUS", "STAR"};
    g.prods = {
        {"expr", {"expr", "PLUS", "term"}},            // 1
        {"expr", {"term"}},                            // 2
        {"term", {"term", "STAR", "factor"}},          // 3
        {"term", {"factor"}},                          // 4
        {"factor", {"INT"}},                           // 5
        {"factor", {"IDENT"}},                         // 6
        {"factor", {"INPUT"}},                         // 7
        {"factor", {"LPAREN", "expr", "RPAREN"}},      // 8
    };
    return g;
}

Grammar danglingElseGrammar() {
    Grammar g;
    g.start = "stmt";
    g.nonterms = {"stmt"};
    g.terms = {"IF", "LPAREN", "IDENT", "RPAREN", "ELSE"};
    g.prods = {
        {"stmt", {"IF", "LPAREN", "IDENT", "RPAREN", "stmt"}},                   // 1
        {"stmt", {"IF", "LPAREN", "IDENT", "RPAREN", "stmt", "ELSE", "stmt"}},   // 2
        {"stmt", {"IDENT"}},                                                     // 3
    };
    return g;
}

}  // namespace tip
```

### 7.11.3 SLR 引擎 lr.hpp 与 lr.cpp

项、闭包、GOTO、
规范项集族、
Algorithm 6.1 造表
（含冲突记录与
prefer-shift 裁决）、
移进-归约驱动器。

```cpp
// file: src/lr.hpp
// file: src/lr.hpp
// 第 7 章配套：LR(0) 项集族、SLR 造表（绿龙 Algorithm 6.1）、
// 移进-归约驱动器（绿龙 Fig 6.2/6.4 的模型）。
#ifndef TIP_LR_HPP
#define TIP_LR_HPP

#include "grammar.hpp"

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

inline const std::string LR_DOLLAR = "$";

// LR(0) 项 = (产生式下标, 点位)。绿龙：两个整数就够存一个项。
struct Item {
    int prod, dot;
    bool operator<(const Item &o) const {
        return prod != o.prod ? prod < o.prod : dot < o.dot;
    }
    bool operator==(const Item &o) const {
        return prod == o.prod && dot == o.dot;
    }
};

enum class Act { Err, Shift, Reduce, Accept };

struct Action {
    Act kind = Act::Err;
    int target = -1;   // Shift: 目标状态；Reduce: 产生式下标
};

struct Conflict {
    int state;
    std::string look;
    std::string kind;   // "shift-reduce" / "reduce-reduce"
    int shiftTarget = -1;
    std::vector<int> reduceProds;
    std::string resolution;
};

class SLR {
public:
    const Grammar &g;
    std::vector<Production> aug;                 // aug[0] = 增广开始产生式
    std::vector<std::set<Item>> states;          // 规范 LR(0) 项集族
    std::map<std::pair<int, std::string>, int> gotof;   // GOTO(状态, 符号)
    std::map<std::pair<int, std::string>, Action> action;
    std::map<std::string, std::set<std::string>> follow;
    std::vector<Conflict> conflicts;

    explicit SLR(const Grammar &g);

    std::string showItem(const Item &it) const;         // expr -> expr · PLUS term
    std::set<Item> closure(std::set<Item> i) const;     // 绿龙 Fig 6.5
    std::set<Item> goTo(const std::set<Item> &i, const std::string &X) const;   // 移点+闭包
    void buildItems();                                   // 绿龙 Fig 6.6 ITEMS
    void buildTable(bool preferShift);                   // 绿龙 Algorithm 6.1

    // 移进-归约驱动。输出 moves 到 os；返回 (成功?, 诊断)。
    struct RunResult { bool ok; std::string error; };
    RunResult run(const std::vector<std::string> &input,
                  std::ostringstream &os) const;
    std::string stackText(const std::vector<int> &s,
                          const std::vector<std::string> &sym) const;
    std::string inputText(const std::vector<std::string> &input, size_t ip) const;
};

}  // namespace tip

#endif  // TIP_LR_HPP
```

```cpp
// file: src/lr.cpp
// file: src/lr.cpp
// 第 7 章配套：SLR 引擎实现。
#include "lr.hpp"

#include <cassert>
#include <sstream>

namespace tip {

SLR::SLR(const Grammar &g) : g(g) {
    // 增广文法：新产生式 0 号 = <start>' -> start。
    // 它的唯一使命是给“接受”一个可以识别的时机。
    aug.push_back({g.start + "'", {g.start}});
    for (const auto &p : g.prods) aug.push_back(p);
}

std::string SLR::showItem(const Item &it) const {
    const auto &p = aug[it.prod];
    std::ostringstream os;
    os << p.lhs << " ->";
    for (size_t k = 0; k < p.rhs.size(); ++k) {
        os << ' ';
        if (static_cast<int>(k) == it.dot) os << "· ";
        os << p.rhs[k];
    }
    if (static_cast<int>(p.rhs.size()) == it.dot) os << " ·";
    if (p.rhs.empty() && it.dot == 0) os << " ·";
    return os.str();
}

// ---------- CLOSURE（绿龙 Fig 6.5） ----------
// 点右边的非终结符“期望看到它推导的东西”，
// 于是它的所有产生式以点在最左端的形态加入。
// 绿龙提示用 ADDED[非终结符] 布尔表避免重复扫——
// 一旦某非终结符的全部产生式已加入，就不必再看它。
std::set<Item> SLR::closure(std::set<Item> i) const {
    std::map<std::string, bool> added;
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &it : i) {
            const auto &rhs = aug[it.prod].rhs;
            if (it.dot >= static_cast<int>(rhs.size())) continue;
            const std::string &B = rhs[it.dot];
            if (!g.isNonterm(B) || added[B]) continue;
            added[B] = true;
            for (size_t pi = 0; pi < aug.size(); ++pi)
                if (aug[pi].lhs == B) {
                    Item ni{static_cast<int>(pi), 0};
                    if (!i.count(ni)) { i.insert(ni); changed = true; }
                }
        }
    }
    return i;
}

std::set<Item> SLR::goTo(const std::set<Item> &i, const std::string &X) const {
    std::set<Item> moved;
    for (const auto &it : i) {
        const auto &rhs = aug[it.prod].rhs;
        if (it.dot < static_cast<int>(rhs.size()) && rhs[it.dot] == X)
            moved.insert({it.prod, it.dot + 1});
    }
    return moved;   // 调用方需要再取 closure
}

// ---------- ITEMS（绿龙 Fig 6.6）：规范 LR(0) 项集族 ----------
// 眼尖的读者会认出这就是第 5 章的子集构造：
// 项是 NFA 的状态（点移动=实边、点后非终结符=ε 扇出），
// CLOSURE 就是 ε 闭包，ITEMS 就是不动点扩张。
void SLR::buildItems() {
    states.clear();
    gotof.clear();
    states.push_back(closure({{0, 0}}));
    for (size_t si = 0; si < states.size(); ++si) {
        std::vector<std::string> syms = g.terms;
        for (const auto &n : g.nonterms) syms.push_back(n);
        for (const auto &X : syms) {
            std::set<Item> t = closure(goTo(states[si], X));
            if (t.empty()) continue;
            int idx = -1;
            for (size_t k = 0; k < states.size(); ++k)
                if (states[k] == t) { idx = static_cast<int>(k); break; }
            if (idx < 0) {
                states.push_back(t);
                idx = static_cast<int>(states.size()) - 1;
            }
            gotof[{static_cast<int>(si), X}] = idx;
        }
    }
}

// ---------- FOLLOW（SLR 规则 2 需要，算法与第 6 章相同） ----------
namespace {
void computeFirst(const std::vector<Production> &aug, const Grammar &g,
                  std::map<std::string, std::set<std::string>> &first) {
    for (const auto &A : g.nonterms) first[A] = {};
    auto firstOfSeq = [&](const std::vector<std::string> &beta) {
        std::set<std::string> out;
        bool allEps = true;
        for (const auto &x : beta) {
            std::set<std::string> fx;
            if (g.isTerm(x)) fx = {x};
            else if (first.count(x)) fx = first[x];
            for (const auto &t : fx)
                if (t != "ε") out.insert(t);
            if (!fx.count("ε")) { allEps = false; break; }
        }
        if (allEps) out.insert("ε");
        return out;
    };
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : aug) {
            if (!g.isNonterm(p.lhs)) continue;
            auto &F = first[p.lhs];
            size_t before = F.size();
            for (const auto &t : firstOfSeq(p.rhs)) F.insert(t);
            if (F.size() != before) changed = true;
        }
    }
}
}  // namespace

void SLR::buildTable(bool preferShift) {
    conflicts.clear();
    action.clear();
    // FOLLOW（用增广产生式一并算，起始符号的 FOLLOW 恒含 $）
    std::map<std::string, std::set<std::string>> first;
    computeFirst(aug, g, first);
    for (const auto &A : g.nonterms) follow[A] = {};
    follow[g.start].insert(LR_DOLLAR);
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : aug) {
            for (size_t i = 0; i < p.rhs.size(); ++i) {
                const auto &B = p.rhs[i];
                if (!g.isNonterm(B)) continue;
                auto &FB = follow[B];
                size_t before = FB.size();
                std::vector<std::string> rest(p.rhs.begin() + i + 1, p.rhs.end());
                auto fr = [&] {
                    std::set<std::string> out;
                    bool allEps = true;
                    for (const auto &x : rest) {
                        std::set<std::string> fx;
                        if (g.isTerm(x)) fx = {x};
                        else if (first.count(x)) fx = first[x];
                        for (const auto &t : fx)
                            if (t != "ε") out.insert(t);
                        if (!fx.count("ε")) { allEps = false; break; }
                    }
                    if (allEps) out.insert("ε");
                    return out;
                }();
                for (const auto &t : fr)
                    if (t != "ε") FB.insert(t);
                if (fr.count("ε") || rest.empty())
                    for (const auto &t : follow[p.lhs]) FB.insert(t);
                if (FB.size() != before) changed = true;
            }
        }
    }
    // Algorithm 6.1 的六条规则：
    auto put = [&](int st, const std::string &a, Action act, const std::string &kind) {
        auto key = std::make_pair(st, a);
        auto it = action.find(key);
        if (it == action.end()) { action[key] = act; return; }
        if (it->second.kind == act.kind && it->second.target == act.target) return;
        // 冲突：记录；preferShift 时移进胜出。
        Conflict cf;
        cf.state = st;
        cf.look = a;
        std::vector<int> reds;
        if (it->second.kind == Act::Reduce) reds.push_back(it->second.target);
        if (act.kind == Act::Reduce) reds.push_back(act.target);
        cf.reduceProds = reds;
        cf.kind = kind;
        if (it->second.kind == Act::Shift) cf.shiftTarget = it->second.target;
        if (act.kind == Act::Shift) cf.shiftTarget = act.target;
        if (preferShift && act.kind == Act::Shift) {
            it->second = act;
            cf.resolution = "prefer-shift（最近 else）";
        } else if (preferShift && it->second.kind == Act::Shift) {
            cf.resolution = "prefer-shift（最近 else）";
        } else {
            cf.resolution = "保留先到者";
        }
        conflicts.push_back(cf);
    };
    for (size_t si = 0; si < states.size(); ++si) {
        int st = static_cast<int>(si);
        for (const auto &it : states[si]) {
            const auto &rhs = aug[it.prod].rhs;
            if (it.dot < static_cast<int>(rhs.size())) {
                const std::string &X = rhs[it.dot];
                if (g.isTerm(X)) {   // 规则 1：shift
                    Action a{Act::Shift, gotof.at({st, X})};
                    put(st, X, a, "shift-reduce");
                }
            } else {
                if (it.prod == 0) {   // 规则 3：accept
                    put(st, LR_DOLLAR, {Act::Accept, -1}, "accept");
                } else {              // 规则 2：对 FOLLOW(A) reduce
                    const std::string &A = aug[it.prod].lhs;
                    for (const auto &a : follow[A])
                        put(st, a, {Act::Reduce, it.prod}, "reduce-reduce");
                }
            }
        }
    }
}

// ---------- 移进-归约驱动（绿龙 Fig 6.2/6.4） ----------
SLR::RunResult SLR::run(const std::vector<std::string> &input,
                        std::ostringstream &os) const {
    std::vector<int> sstack = {0};          // 状态栈
    std::vector<std::string> sym;           // 符号栈（只作展示）
    size_t ip = 0;
    int step = 0;
    while (true) {
        int st = sstack.back();
        std::string a = ip < input.size() ? input[ip] : LR_DOLLAR;
        auto it = action.find({st, a});
        Action act = (it == action.end()) ? Action{} : it->second;
        // 打印 move 行
        os << "(" << ++step << ") " << stackText(sstack, sym)
           << " | " << inputText(input, ip) << " | ";
        switch (act.kind) {
        case Act::Shift:
            os << "shift " << act.target << "\n";
            sstack.push_back(act.target);
            sym.push_back(a);
            ++ip;
            break;
        case Act::Reduce: {
            const auto &p = aug[act.target];
            os << "reduce " << p.lhs << " ->";
            if (p.rhs.empty()) os << " ε";
            else for (const auto &x : p.rhs) os << ' ' << x;
            os << "\n";
            for (size_t k = 0; k < p.rhs.size(); ++k) { sstack.pop_back(); sym.pop_back(); }
            int nt = gotof.at({sstack.back(), p.lhs});
            sstack.push_back(nt);
            sym.push_back(p.lhs);
            break;
        }
        case Act::Accept:
            os << "accept\n";
            return {true, ""};
        case Act::Err:
            os << "error\n";
            return {false, "状态 " + std::to_string(st) + " 遇到 " + a + " 无动作"};
        }
    }
}

std::string SLR::stackText(const std::vector<int> &s,
                            const std::vector<std::string> &sym) const {
    std::ostringstream os;
    os << s[0];
    for (size_t k = 0; k < sym.size(); ++k)
        os << ' ' << sym[k] << ' ' << s[k + 1];
    return os.str();
}

std::string SLR::inputText(const std::vector<std::string> &input, size_t ip) const {
    std::ostringstream os;
    for (size_t k = ip; k < input.size(); ++k) os << input[k] << ' ';
    os << LR_DOLLAR;
    return os.str();
}

}  // namespace tip
```

### 7.11.4 驱动 main.cpp

词法 → 项集 → 表 →
moves → 悬挂 else 全流程。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 7 章驱动：--check FILE
//   1) 左递归表达式文法（绿龙 6.1 的 TIP 化身）：
//      规范 LR(0) 项集族 -> SLR 表 -> 对 FILE 的移进-归约全程；
//   2) 悬挂 else 文法：SLR 冲突现场 + prefer-shift 消解。
#include "grammar.hpp"
#include "lr.hpp"

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
        if (t->getType() == antlr4::Token::EOF) continue;
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

void dumpItems(const tip::SLR &s) {
    std::cout << "== canonical LR(0) collection ==\n";
    for (size_t i = 0; i < s.states.size(); ++i) {
        std::cout << "  I" << i << ":\n";
        for (const auto &it : s.states[i])
            std::cout << "    " << s.showItem(it) << '\n';
    }
}

void dumpTable(const tip::SLR &s) {
    std::cout << "== SLR table ==\n";
    std::vector<std::string> cols = s.g.terms;
    cols.push_back(tip::LR_DOLLAR);
    std::cout << "  state";
    for (const auto &c : cols) std::cout << '\t' << c;
    for (const auto &n : s.g.nonterms) std::cout << '\t' << n;
    std::cout << '\n';
    for (size_t st = 0; st < s.states.size(); ++st) {
        std::cout << "  " << st;
        for (const auto &c : cols) {
            auto it = s.action.find({static_cast<int>(st), c});
            if (it == s.action.end()) std::cout << "\t.";
            else switch (it->second.kind) {
                case tip::Act::Shift: std::cout << "\ts" << it->second.target; break;
                case tip::Act::Reduce: std::cout << "\tr" << it->second.target; break;
                case tip::Act::Accept: std::cout << "\tacc"; break;
                default: std::cout << "\t.";
            }
        }
        for (const auto &n : s.g.nonterms) {
            auto it = s.gotof.find({static_cast<int>(st), n});
            if (it == s.gotof.end()) std::cout << "\t.";
            else std::cout << '\t' << it->second;
        }
        std::cout << '\n';
    }
    if (s.conflicts.empty()) {
        std::cout << "== conflicts ==\n  none\n";
    } else {
        std::cout << "== conflicts ==\n";
        for (const auto &cf : s.conflicts) {
            std::cout << "  action[" << cf.state << ", " << cf.look << "]: "
                      << cf.kind << "（移进 " << cf.shiftTarget;
            for (int r : cf.reduceProds) std::cout << " vs 归约 [" << r << "]";
            std::cout << "）-> " << cf.resolution << '\n';
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

    tip::Grammar eg = tip::exprGrammarLR();
    std::cout << "== grammar: 左递归表达式文法（绿龙 6.1 的 TIP 化身）==\n";
    dumpGrammar(eg);
    tip::SLR slr(eg);
    slr.buildItems();
    slr.buildTable(false);
    dumpItems(slr);
    dumpTable(slr);

    std::cout << "== moves ==\n";
    std::ostringstream os;
    tip::SLR::RunResult r = slr.run(input, os);
    std::cout << os.str();
    if (!r.ok) {
        std::cerr << "syntax error: " << r.error << '\n';
        return 1;
    }

    // ---------- 悬挂 else ----------
    tip::Grammar dg = tip::danglingElseGrammar();
    std::cout << "== grammar: 悬挂 else 文法 ==\n";
    dumpGrammar(dg);
    tip::SLR dslr(dg);
    dslr.buildItems();
    dslr.buildTable(true);
    dumpTable(dslr);
    std::cout << "== moves: if (a) if (b) c else d ==\n";
    std::vector<std::string> demo = {"IF", "LPAREN", "IDENT", "RPAREN",
                                     "IF", "LPAREN", "IDENT", "RPAREN",
                                     "IDENT", "ELSE", "IDENT"};
    std::ostringstream dos;
    tip::SLR::RunResult dr = dslr.run(demo, dos);
    std::cout << dos.str();
    if (!dr.ok) std::cerr << "syntax error: " << dr.error << '\n';
    return dr.ok ? 0 : 1;
}
```

### 7.11.5 程序与错误样例

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

### 7.11.6 期望输出

```text
; expected: expected/output.txt
== add.tip ==
== tokens ==
IDENT('x') PLUS('+') INT('21') STAR('*') IDENT('y') $
== grammar: 左递归表达式文法（绿龙 6.1 的 TIP 化身）==
  [1] expr -> expr PLUS term
  [2] expr -> term
  [3] term -> term STAR factor
  [4] term -> factor
  [5] factor -> INT
  [6] factor -> IDENT
  [7] factor -> INPUT
  [8] factor -> LPAREN expr RPAREN
== canonical LR(0) collection ==
  I0:
    expr' -> · expr
    expr -> · expr PLUS term
    expr -> · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I1:
    factor -> INT ·
  I2:
    factor -> IDENT ·
  I3:
    factor -> INPUT ·
  I4:
    expr -> · expr PLUS term
    expr -> · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
    factor -> LPAREN · expr RPAREN
  I5:
    expr' -> expr ·
    expr -> expr · PLUS term
  I6:
    expr -> term ·
    term -> term · STAR factor
  I7:
    term -> factor ·
  I8:
    expr -> expr · PLUS term
    factor -> LPAREN expr · RPAREN
  I9:
    expr -> expr PLUS · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I10:
    term -> term STAR · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I11:
    factor -> LPAREN expr RPAREN ·
  I12:
    expr -> expr PLUS term ·
    term -> term · STAR factor
  I13:
    term -> term STAR factor ·
== SLR table ==
  state	INT	IDENT	INPUT	LPAREN	RPAREN	PLUS	STAR	$	expr	term	factor
  0	s1	s2	s3	s4	.	.	.	.	5	6	7
  1	.	.	.	.	r5	r5	r5	r5	.	.	.
  2	.	.	.	.	r6	r6	r6	r6	.	.	.
  3	.	.	.	.	r7	r7	r7	r7	.	.	.
  4	s1	s2	s3	s4	.	.	.	.	8	6	7
  5	.	.	.	.	.	s9	.	acc	.	.	.
  6	.	.	.	.	r2	r2	s10	r2	.	.	.
  7	.	.	.	.	r4	r4	r4	r4	.	.	.
  8	.	.	.	.	s11	s9	.	.	.	.	.
  9	s1	s2	s3	s4	.	.	.	.	.	12	7
  10	s1	s2	s3	s4	.	.	.	.	.	.	13
  11	.	.	.	.	r8	r8	r8	r8	.	.	.
  12	.	.	.	.	r1	r1	s10	r1	.	.	.
  13	.	.	.	.	r3	r3	r3	r3	.	.	.
== conflicts ==
  none
== moves ==
(1) 0 | IDENT PLUS INT STAR IDENT $ | shift 2
(2) 0 IDENT 2 | PLUS INT STAR IDENT $ | reduce factor -> IDENT
(3) 0 factor 7 | PLUS INT STAR IDENT $ | reduce term -> factor
(4) 0 term 6 | PLUS INT STAR IDENT $ | reduce expr -> term
(5) 0 expr 5 | PLUS INT STAR IDENT $ | shift 9
(6) 0 expr 5 PLUS 9 | INT STAR IDENT $ | shift 1
(7) 0 expr 5 PLUS 9 INT 1 | STAR IDENT $ | reduce factor -> INT
(8) 0 expr 5 PLUS 9 factor 7 | STAR IDENT $ | reduce term -> factor
(9) 0 expr 5 PLUS 9 term 12 | STAR IDENT $ | shift 10
(10) 0 expr 5 PLUS 9 term 12 STAR 10 | IDENT $ | shift 2
(11) 0 expr 5 PLUS 9 term 12 STAR 10 IDENT 2 | $ | reduce factor -> IDENT
(12) 0 expr 5 PLUS 9 term 12 STAR 10 factor 13 | $ | reduce term -> term STAR factor
(13) 0 expr 5 PLUS 9 term 12 | $ | reduce expr -> expr PLUS term
(14) 0 expr 5 | $ | accept
== grammar: 悬挂 else 文法 ==
  [1] stmt -> IF LPAREN IDENT RPAREN stmt
  [2] stmt -> IF LPAREN IDENT RPAREN stmt ELSE stmt
  [3] stmt -> IDENT
== SLR table ==
  state	IF	LPAREN	IDENT	RPAREN	ELSE	$	stmt
  0	s1	.	s2	.	.	.	3
  1	.	s4	.	.	.	.	.
  2	.	.	.	.	r3	r3	.
  3	.	.	.	.	.	acc	.
  4	.	.	s5	.	.	.	.
  5	.	.	.	s6	.	.	.
  6	s1	.	s2	.	.	.	7
  7	.	.	.	.	s8	r1	.
  8	s1	.	s2	.	.	.	9
  9	.	.	.	.	r2	r2	.
== conflicts ==
  action[7, ELSE]: shift-reduce（移进 8 vs 归约 [1]）-> prefer-shift（最近 else）
== moves: if (a) if (b) c else d ==
(1) 0 | IF LPAREN IDENT RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 1
(2) 0 IF 1 | LPAREN IDENT RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 4
(3) 0 IF 1 LPAREN 4 | IDENT RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 5
(4) 0 IF 1 LPAREN 4 IDENT 5 | RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 6
(5) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 | IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 1
(6) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 | LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 4
(7) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 | IDENT RPAREN IDENT ELSE IDENT $ | shift 5
(8) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 | RPAREN IDENT ELSE IDENT $ | shift 6
(9) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 | IDENT ELSE IDENT $ | shift 2
(10) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IDENT 2 | ELSE IDENT $ | reduce stmt -> IDENT
(11) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 | ELSE IDENT $ | shift 8
(12) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 ELSE 8 | IDENT $ | shift 2
(13) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 ELSE 8 IDENT 2 | $ | reduce stmt -> IDENT
(14) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 ELSE 8 stmt 9 | $ | reduce stmt -> IF LPAREN IDENT RPAREN stmt ELSE stmt
(15) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 | $ | reduce stmt -> IF LPAREN IDENT RPAREN stmt
(16) 0 stmt 3 | $ | accept
== paren.tip ==
== tokens ==
LPAREN('(') IDENT('a') PLUS('+') IDENT('b') RPAREN(')') STAR('*') LPAREN('(') IDENT('c') PLUS('+') INPUT('input') RPAREN(')') $
== grammar: 左递归表达式文法（绿龙 6.1 的 TIP 化身）==
  [1] expr -> expr PLUS term
  [2] expr -> term
  [3] term -> term STAR factor
  [4] term -> factor
  [5] factor -> INT
  [6] factor -> IDENT
  [7] factor -> INPUT
  [8] factor -> LPAREN expr RPAREN
== canonical LR(0) collection ==
  I0:
    expr' -> · expr
    expr -> · expr PLUS term
    expr -> · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I1:
    factor -> INT ·
  I2:
    factor -> IDENT ·
  I3:
    factor -> INPUT ·
  I4:
    expr -> · expr PLUS term
    expr -> · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
    factor -> LPAREN · expr RPAREN
  I5:
    expr' -> expr ·
    expr -> expr · PLUS term
  I6:
    expr -> term ·
    term -> term · STAR factor
  I7:
    term -> factor ·
  I8:
    expr -> expr · PLUS term
    factor -> LPAREN expr · RPAREN
  I9:
    expr -> expr PLUS · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I10:
    term -> term STAR · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I11:
    factor -> LPAREN expr RPAREN ·
  I12:
    expr -> expr PLUS term ·
    term -> term · STAR factor
  I13:
    term -> term STAR factor ·
== SLR table ==
  state	INT	IDENT	INPUT	LPAREN	RPAREN	PLUS	STAR	$	expr	term	factor
  0	s1	s2	s3	s4	.	.	.	.	5	6	7
  1	.	.	.	.	r5	r5	r5	r5	.	.	.
  2	.	.	.	.	r6	r6	r6	r6	.	.	.
  3	.	.	.	.	r7	r7	r7	r7	.	.	.
  4	s1	s2	s3	s4	.	.	.	.	8	6	7
  5	.	.	.	.	.	s9	.	acc	.	.	.
  6	.	.	.	.	r2	r2	s10	r2	.	.	.
  7	.	.	.	.	r4	r4	r4	r4	.	.	.
  8	.	.	.	.	s11	s9	.	.	.	.	.
  9	s1	s2	s3	s4	.	.	.	.	.	12	7
  10	s1	s2	s3	s4	.	.	.	.	.	.	13
  11	.	.	.	.	r8	r8	r8	r8	.	.	.
  12	.	.	.	.	r1	r1	s10	r1	.	.	.
  13	.	.	.	.	r3	r3	r3	r3	.	.	.
== conflicts ==
  none
== moves ==
(1) 0 | LPAREN IDENT PLUS IDENT RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | shift 4
(2) 0 LPAREN 4 | IDENT PLUS IDENT RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | shift 2
(3) 0 LPAREN 4 IDENT 2 | PLUS IDENT RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce factor -> IDENT
(4) 0 LPAREN 4 factor 7 | PLUS IDENT RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce term -> factor
(5) 0 LPAREN 4 term 6 | PLUS IDENT RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce expr -> term
(6) 0 LPAREN 4 expr 8 | PLUS IDENT RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | shift 9
(7) 0 LPAREN 4 expr 8 PLUS 9 | IDENT RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | shift 2
(8) 0 LPAREN 4 expr 8 PLUS 9 IDENT 2 | RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce factor -> IDENT
(9) 0 LPAREN 4 expr 8 PLUS 9 factor 7 | RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce term -> factor
(10) 0 LPAREN 4 expr 8 PLUS 9 term 12 | RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce expr -> expr PLUS term
(11) 0 LPAREN 4 expr 8 | RPAREN STAR LPAREN IDENT PLUS INPUT RPAREN $ | shift 11
(12) 0 LPAREN 4 expr 8 RPAREN 11 | STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce factor -> LPAREN expr RPAREN
(13) 0 factor 7 | STAR LPAREN IDENT PLUS INPUT RPAREN $ | reduce term -> factor
(14) 0 term 6 | STAR LPAREN IDENT PLUS INPUT RPAREN $ | shift 10
(15) 0 term 6 STAR 10 | LPAREN IDENT PLUS INPUT RPAREN $ | shift 4
(16) 0 term 6 STAR 10 LPAREN 4 | IDENT PLUS INPUT RPAREN $ | shift 2
(17) 0 term 6 STAR 10 LPAREN 4 IDENT 2 | PLUS INPUT RPAREN $ | reduce factor -> IDENT
(18) 0 term 6 STAR 10 LPAREN 4 factor 7 | PLUS INPUT RPAREN $ | reduce term -> factor
(19) 0 term 6 STAR 10 LPAREN 4 term 6 | PLUS INPUT RPAREN $ | reduce expr -> term
(20) 0 term 6 STAR 10 LPAREN 4 expr 8 | PLUS INPUT RPAREN $ | shift 9
(21) 0 term 6 STAR 10 LPAREN 4 expr 8 PLUS 9 | INPUT RPAREN $ | shift 3
(22) 0 term 6 STAR 10 LPAREN 4 expr 8 PLUS 9 INPUT 3 | RPAREN $ | reduce factor -> INPUT
(23) 0 term 6 STAR 10 LPAREN 4 expr 8 PLUS 9 factor 7 | RPAREN $ | reduce term -> factor
(24) 0 term 6 STAR 10 LPAREN 4 expr 8 PLUS 9 term 12 | RPAREN $ | reduce expr -> expr PLUS term
(25) 0 term 6 STAR 10 LPAREN 4 expr 8 | RPAREN $ | shift 11
(26) 0 term 6 STAR 10 LPAREN 4 expr 8 RPAREN 11 | $ | reduce factor -> LPAREN expr RPAREN
(27) 0 term 6 STAR 10 factor 13 | $ | reduce term -> term STAR factor
(28) 0 term 6 | $ | reduce expr -> term
(29) 0 expr 5 | $ | accept
== grammar: 悬挂 else 文法 ==
  [1] stmt -> IF LPAREN IDENT RPAREN stmt
  [2] stmt -> IF LPAREN IDENT RPAREN stmt ELSE stmt
  [3] stmt -> IDENT
== SLR table ==
  state	IF	LPAREN	IDENT	RPAREN	ELSE	$	stmt
  0	s1	.	s2	.	.	.	3
  1	.	s4	.	.	.	.	.
  2	.	.	.	.	r3	r3	.
  3	.	.	.	.	.	acc	.
  4	.	.	s5	.	.	.	.
  5	.	.	.	s6	.	.	.
  6	s1	.	s2	.	.	.	7
  7	.	.	.	.	s8	r1	.
  8	s1	.	s2	.	.	.	9
  9	.	.	.	.	r2	r2	.
== conflicts ==
  action[7, ELSE]: shift-reduce（移进 8 vs 归约 [1]）-> prefer-shift（最近 else）
== moves: if (a) if (b) c else d ==
(1) 0 | IF LPAREN IDENT RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 1
(2) 0 IF 1 | LPAREN IDENT RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 4
(3) 0 IF 1 LPAREN 4 | IDENT RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 5
(4) 0 IF 1 LPAREN 4 IDENT 5 | RPAREN IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 6
(5) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 | IF LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 1
(6) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 | LPAREN IDENT RPAREN IDENT ELSE IDENT $ | shift 4
(7) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 | IDENT RPAREN IDENT ELSE IDENT $ | shift 5
(8) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 | RPAREN IDENT ELSE IDENT $ | shift 6
(9) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 | IDENT ELSE IDENT $ | shift 2
(10) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IDENT 2 | ELSE IDENT $ | reduce stmt -> IDENT
(11) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 | ELSE IDENT $ | shift 8
(12) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 ELSE 8 | IDENT $ | shift 2
(13) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 ELSE 8 IDENT 2 | $ | reduce stmt -> IDENT
(14) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 ELSE 8 stmt 9 | $ | reduce stmt -> IF LPAREN IDENT RPAREN stmt ELSE stmt
(15) 0 IF 1 LPAREN 4 IDENT 5 RPAREN 6 stmt 7 | $ | reduce stmt -> IF LPAREN IDENT RPAREN stmt
(16) 0 stmt 3 | $ | accept
```

```text
; expected: expected/errors/bad.txt
== tokens ==
INT('1') PLUS('+') STAR('*') INT('2') $
== grammar: 左递归表达式文法（绿龙 6.1 的 TIP 化身）==
  [1] expr -> expr PLUS term
  [2] expr -> term
  [3] term -> term STAR factor
  [4] term -> factor
  [5] factor -> INT
  [6] factor -> IDENT
  [7] factor -> INPUT
  [8] factor -> LPAREN expr RPAREN
== canonical LR(0) collection ==
  I0:
    expr' -> · expr
    expr -> · expr PLUS term
    expr -> · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I1:
    factor -> INT ·
  I2:
    factor -> IDENT ·
  I3:
    factor -> INPUT ·
  I4:
    expr -> · expr PLUS term
    expr -> · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
    factor -> LPAREN · expr RPAREN
  I5:
    expr' -> expr ·
    expr -> expr · PLUS term
  I6:
    expr -> term ·
    term -> term · STAR factor
  I7:
    term -> factor ·
  I8:
    expr -> expr · PLUS term
    factor -> LPAREN expr · RPAREN
  I9:
    expr -> expr PLUS · term
    term -> · term STAR factor
    term -> · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I10:
    term -> term STAR · factor
    factor -> · INT
    factor -> · IDENT
    factor -> · INPUT
    factor -> · LPAREN expr RPAREN
  I11:
    factor -> LPAREN expr RPAREN ·
  I12:
    expr -> expr PLUS term ·
    term -> term · STAR factor
  I13:
    term -> term STAR factor ·
== SLR table ==
  state	INT	IDENT	INPUT	LPAREN	RPAREN	PLUS	STAR	$	expr	term	factor
  0	s1	s2	s3	s4	.	.	.	.	5	6	7
  1	.	.	.	.	r5	r5	r5	r5	.	.	.
  2	.	.	.	.	r6	r6	r6	r6	.	.	.
  3	.	.	.	.	r7	r7	r7	r7	.	.	.
  4	s1	s2	s3	s4	.	.	.	.	8	6	7
  5	.	.	.	.	.	s9	.	acc	.	.	.
  6	.	.	.	.	r2	r2	s10	r2	.	.	.
  7	.	.	.	.	r4	r4	r4	r4	.	.	.
  8	.	.	.	.	s11	s9	.	.	.	.	.
  9	s1	s2	s3	s4	.	.	.	.	.	12	7
  10	s1	s2	s3	s4	.	.	.	.	.	.	13
  11	.	.	.	.	r8	r8	r8	r8	.	.	.
  12	.	.	.	.	r1	r1	s10	r1	.	.	.
  13	.	.	.	.	r3	r3	r3	r3	.	.	.
== conflicts ==
  none
== moves ==
(1) 0 | INT PLUS STAR INT $ | shift 1
(2) 0 INT 1 | PLUS STAR INT $ | reduce factor -> INT
(3) 0 factor 7 | PLUS STAR INT $ | reduce term -> factor
(4) 0 term 6 | PLUS STAR INT $ | reduce expr -> term
(5) 0 expr 5 | PLUS STAR INT $ | shift 9
(6) 0 expr 5 PLUS 9 | STAR INT $ | error
syntax error: 状态 9 遇到 STAR 无动作
```

## 7.12 小结与练习

本章把"从叶子归约"
做成了确定性算法：

- 项集自动机识别活前缀，
  栈顶状态浓缩栈史——
  构造本身就是
  第 5 章的子集构造；
- SLR 用 FOLLOW
  给归约发许可证，
  六条规则造出
  ACTION/GOTO；
- 冲突即文法的报警：
  L=R 反例暴露
  SLR 许可证发宽的病根，
  引出 LR(1) 搜索符
  与 LALR 合并；
- 悬挂 else 的
  prefer-shift 裁决
  与第 6 章"最近 else"
  是同一条语义
  在两个世界的投影；
- 左递归在 LR 世界
  不是病，是甜点。

至此前端三部曲
（自动机、LL、LR）齐了；
第 12 章回到主线，
看 AST 怎么从
语法树上长出来。

练习：

1. 手工算出
   表达式文法的
   FOLLOW(expr)、FOLLOW(term)、
   FOLLOW(factor)，
   对照表里 r 项的分布
   逐格验证。
2. 手工跑 ITEMS：
   从 I₀ 出发
   画出全部 14 个项集的
   GOTO 转移图，
   与输出比对；
   标出书上 12 状态版
   少掉的是哪些。
3. 对 `paren.tip`
   手工执行 moves，
   复原最右推导
   （reduce 序列倒排），
   再与第 6 章
   同文件的最左推导
   并排对照。
4. 把绿龙 6.2 文法
   （S→L=R|R 等）
   加进 grammar.cpp，
   重跑，观察
   action 冲突的输出
   与 7.6 节的分析
   是否一致。
5. 实现一个
   reduce-reduce
   冲突的检测报告
   （提示：构造一个
   两条产生式右部相同
   的文法），
   并解释为什么
   工程上它几乎总是
   文法写坏了。

---

上一章：[06 LL 分析](06-ll-parsing.md) · 下一章：[08 LR(1) 与 LALR](08-lr1-lalr.md)
