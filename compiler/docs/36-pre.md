# 第 36 章　部分冗余消除：六方程与惰性代码移动

## 36.1 问题：冗余的完整地形图

到此为止的
冗余歼灭战
各有射程：

- 第 34 章 DAG：
  块内重复——
  登记即消除；
- 第 26 章可用表达式
  （全局 CSE）：
  "每条路都已算好"
  的**完全**冗余——
  直接复用；
- 第 35 章 LICM：
  循环内
  "每圈同样"的
  不变计算——
  提出去。

剩下的死角：
**部分冗余**——
**部分**路径上
已经算过、
**部分**路径上
还没算。
经典形态：

```
if (p) x = a * b; else x = 0;
y = a * b;          ← then 路上冗余、else 路上新鲜
```

完全冗余分析
（must 语义）
在汇合点看见
else 路没算过，
只能放弃；
什么也不做，
then 路就白算了一次。

**部分冗余消除**
（PRE，
partial redundancy
elimination）
的野心：
把"算过一次的路径
  上的计算"
**搬**到没算的路径上，
让所有路径
都只算一次。
紫龙 9.5 的
**惰性代码移动**
（lazy code motion）
用六条数据流方程
把这个"搬哪儿"
解成几何问题——
它是数据流分析
的集大成之作：
一个变换
同时消费
前向 must、
后向 must、
后向 may
三种分析。

## 36.2 冗余的四象限

先把"冗余"分类说清
（紫龙 9.5.1）。
在点 p 看表达式 e：

| | p 处要用 e | p 处不用 e |
|---|---|---|
| **所有路径都已算** | 完全冗余（可复用） | 死计算（可删） |
| **部分路径算过** | 部分冗余（PRE 靶子） | 部分死（懒算） |

两个目标合起来
就是 LCM 的
双螺旋：

> **尽量晚地算**
> （lazy）：
> 不用的路径
> 永远不算；
> **只算一次**
> （once）：
> 要用的路径
> 至多一次。

"尽量晚"为什么重要？
早算占寄存器、
加长值存活距离
（第 43 章）；
路径分支后
可能根本不用。
"晚"是安全性
换来的工程红利。

## 36.3 六方程

记 e_gen[B] /
e_kill[B]
与第 26 章
同义
（块内先生后杀的
  表达式 /
  操作数改写杀掉的
  表达式）。
六个集合，
每块一对或一个：

**① anticipated**
（后向 must，
  出口 ∅）：

```
antic.in[B] = e_gen[B] ∪ (antic.out[B] − e_kill[B])
antic.out[B] = ∩ in[S]     （S ∈ 后继）
```

"从 B 入口出发
每条路都会
在操作数改写前
用到 e"——
第 26 章
非常忙表达式的
孪生
（kill 的口径
  更精细：
  改写之前用）。

**② available**
（前向 must，
  入口 ∅）：
与第 26 章
同式。

**③ earliest[B] =
antic.in[B] − avail.in[B]**：
e 在此"必须开始
被考虑"，
且不能更早——
再早它
既不必然被用
（antic 不成立）、
也无既有值
可蹭（avail 无）。

**④ postponable**
（后向 must，
  出口 ∅）：

```
post.in[B] = (earliest[B] ∪ post.out[B]) − e_gen[B]
post.out[B] = ∩ post.in[S]
```

"从 earliest 起，
  还能往后推"。
e_gen 像阀门：
块内自己算了 e，
推迟到此为止。

**⑤ used**
（后向 may，
  出口 ∅）：

```
used.in[B] = e_gen[B] ∪ (used.out[B] − e_kill[B])
```

"往后某条路
  真的用了"——
不用的表达式
不值得插临时。

**⑥ latest[B]**：

```
latest[B] = (earliest[B] ∪ post.out[B])
            ∩ (e_gen[B] ∪ ¬antic.out[B])
            ∩ used.in[B]
```

读法：
候选集
（earliest 或
  推迟到的位置）
∩
"再不算就没机会"
（本块要算，
  或出口后不再
  anticipated）
∩
"算了有用"
（后续真用）。

**变换**：
在每个 latest 块
插入 `t = e`；
从 earliest 到
该点的路径上
删掉/改写
原有计算；
后续所有计算点
换成 `… = t`。
三个性质
（证明骨架
  按六方程的
  must/may 语义
  逐条归纳）：

- 安全：插入点的
  操作数必已定值
  （anticip 保证
   用前无改写 ⇒
   插入点同样合法）；
- 只算一次：
  earliest 到 latest
  之间不再有
  原计算
  （postponable
   覆盖区间）；
- 保义：
  删除的计算
  与插入的等值
  （available
   维持区间）。

## 36.4 为什么"最晚"与"只一次"会打架

直觉上
"算一次"想早算
（大家好复用），
"别白算"想晚算
（没人用就别算）——
两个目标
在**分支**上
顶牛。
紫龙的反例形态：

```
if (p) { x = a * b; ……用 x…… }
```

早派在 p 前插
`t = a * b`：
else 路白算一次；
晚派不插：
then 路原有的
计算留在原地，
但 if 之后
若还要用 a*b，
两路都得有——
协调的解
正是六方程的
几何：
earliest 画下界，
postponable 画上界，
latest 落在
"恰好还来得及"
的位置。
**分析替我们
解了优化**——
这是把"求解"
外包给
不动点定理的
典范。

## 36.5 期望输出解读

partial.tip
（部分冗余标准款）：
if 分支算 a*b、
else 不算、
join 处算两次
（y 与 z 各一次）。

六方程段
逐块读四行：

- **B1（分支跳板）**：
  earliest {a \* b}、
  post.out {a \* b}——
  "必须在此开始考虑，
    且还能推"；
- **B2（then 块）**：
  latest {a \* b}——
  e_gen 阀门关闭
  （本块自己要算），
  推无可推；
- **else 块**：
  earliest {a \* b}
  但 egen 空、
  antic.out 仍含 e
  ——latest 空：
  这里**不**该插
  （插了 else 路上
    就是新计算，
  而它本可以蹭
    join 处的）；
- **join 块**：
  latest {a \* b}——
  两次 e_gen 的
  宿命位置。

变换段
（教学版范围：
  块内完全去重
  + latest 摆位
  报告）：

```
6: pe1 = a * b        ← then 块首计算改名
7: t3 = pe1
...
12: pe2 = a * b       ← join 首计算改名
13: t5 = pe2
...
15: t6 = pe2          ← join 第二次计算 → 复制（同块去重）
```

join 里 a\*b
从**两次**收敛为
**一次**（t6 = pe2
是复制不是乘法）；
stats 行
inserted=2
replaced=1。
完整 LCM 还会在
earliest（分支点）
插一次、
删掉 then 块的
pe1——
那个跨块搬移
需要"从插入点
  到各用点的
  支配关系 + 
  删除集合"账本，
是练习三的
主菜；
本章把它
留给六方程的
摆位输出：
latest 的落点
就是答案的
坐标。

对账段：
outputs 46
（5>3 走 then：
  x=15、y=15、z=16、
  46=15+15+16）✓
前后一致。
steps 19→21：
**诚实记账**——
教学版用复制
换掉了重复乘法，
路径上净增
两条复制；
真实机器的
账要按周期算
（乘法多周期、
  复制常零开销，
  第 34 章同一口径）。
完整 LCM 的
steps 收益
（一次计算
  吃下所有用点）
同样留给练习
的验收线。

## 36.6 工程注意点

- **PRE 是集大成**：
  六方程里
  前向 must（avail）、
  后向 must（antic、
  post）、
  后向 may（used）
  三种分析同台，
  第 28 章的框架
  视角在此
  收拢成一张
  调度表。
- **关键边再访**。
  跨块插入要经
  "一个前驱多个
  后继 ↔
  多个前驱一个
  后继"的边时
  （第 33 章的
    critical edge），
  没有安全的
  插入位——
  边分裂是 PRE 的
  标准预处理。
  本示例的
  if 模板自带
  跳板块，
  天然避开了
  大多数关键边
  （与第 35 章
    preheader 的
    福利同源）。
- **寄存器压力
  与相位次序**。
  晚算省了白算、
  却拉长了
  某些值的
  存活区间——
  PRE 与
  寄存器分配
  （第 43 章）
  的次序之争
  是后端的老话题；
  一般 PRE 在前，
  压力爆表时
  回退部分插入。
- **工业实现**：
  LLVM 的
  MachineLICM/
  GVN-PR
  走 SSA 上的
  等价路线
  （SSA 的
    支配性质让
    "可用"天然
    全局成立，
    PRE 退化成
    部分情况的
    路径补插）；
  六方程版
  仍是教科书
  最清晰的
  陈述。
- **讲给谁听**：
  六方程的
  每一条都能在
  前面各章找到
  单独的影子
  （26 章 antic/avail、
  35 章 latest 的
  preheader 直觉）。
  PRE 的教学价值
  正是这声
  "合流"。

## 36.7 本章配套文件

### 36.7.1 文法 TIP.g4

与第 4 章相同。

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

### 36.7.2 新件：pre.hpp 与 pre.cpp

六方程求解
（含 e_gen/e_kill、
  邻接与前驱）
与教学版变换
（块内去重 +
  latest 摆位）。

```cpp
// file: src/pre.hpp
// file: src/pre.hpp
// 第 36 章配套：部分冗余消除——六方程分析与教学版变换。
#ifndef TIP_PRE_HPP
#define TIP_PRE_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

using FValS = std::set<std::string>;

std::string exprKeyP(const Quad &q);

struct PreInfo {
    const std::vector<Quad> *code = nullptr;
    const std::vector<Block> *blocks = nullptr;
    std::vector<FValS> egen, ekill;
    std::vector<std::vector<int>> adj;
    std::vector<FValS> anticIn, anticOut;   // ① anticipated
    std::vector<FValS> availIn, availOut;   // ② available
    std::vector<FValS> earliest;            // ③
    std::vector<FValS> postIn, postOut;     // ④ postponable
    std::vector<FValS> usedIn, usedOut;     // ⑤ used
    std::vector<FValS> latest;              // ⑥
};

PreInfo preAnalyse(const std::vector<Quad> &code, const std::vector<Block> &blocks);

struct PreStats {
    int inserted = 0;   // 改写为 pe = e 的首计算位（含紧随复制）
    int replaced = 0;   // 改写为复制的重复计算位
};

std::pair<std::vector<Quad>, PreStats> preTransform(const std::vector<Quad> &code,
                                                    const std::vector<Block> &blocks,
                                                    const PreInfo &p);

}  // namespace tip

#endif  // TIP_PRE_HPP
```

```cpp
// file: src/pre.cpp
// file: src/pre.cpp
// 第 36 章配套：部分冗余消除（惰性代码移动，紫龙 9.5 六方程）。
// 六个集合（元素 = 表达式键）：
//   anticipated  后向 must：往后每条路都会在操作数改写前用到；
//   available    前向 must：从入口起每条路都已算好且未失效；
//   earliest     anticipated ∧ ¬available：第一次“必须开始考虑”的位置；
//   postponable  后向 must：从 earliest 起还能继续推迟的位置；
//   latest       推无可推：本块不算就再没机会/自己本来就要算；
//   used         后向 may：某条路上真被用了（决定临时值是否有归宿）。
// 变换：在 latest 处插入 t = e；其余被覆盖的计算点改写为 t 的复制。
#include "pre.hpp"

#include <cctype>
#include <sstream>

namespace tip {

namespace {
bool isNumP(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarP(const std::string &s) { return !s.empty() && !isNumP(s); }
bool sharesOpP(const std::string &key, const std::string &var) {
    if (key.rfind(var + " ", 0) == 0) return true;
    size_t sp = key.rfind(" " + var);
    if (sp != std::string::npos && sp + 1 + var.size() == key.size()) return true;
    return key.find(" " + var + " ") != std::string::npos;
}
}  // namespace

std::string exprKeyP(const Quad &q) {
    const char *op = nullptr;
    switch (q.op) {
    case TOp::Add: op = " + "; break;
    case TOp::Sub: op = " - "; break;
    case TOp::Mul: op = " * "; break;
    case TOp::Div: op = " / "; break;
    case TOp::Gt:  op = " > "; break;
    case TOp::Eq:  op = " == "; break;
    default: return "";
    }
    std::ostringstream os;
    os << q.a << op << q.b;
    return os.str();
}

PreInfo preAnalyse(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    PreInfo p;
    p.code = &code;
    p.blocks = &blocks;
    // 全域：所有表达式键
    FValS universe;
    for (const auto &q : code) {
        std::string e = exprKeyP(q);
        if (!e.empty()) universe.insert(e);
    }
    // 每块 e_gen / e_kill（gen：块内先算后杀的；kill：操作数被改写所杀）
    p.egen.assign(n, {});
    p.ekill.assign(n, {});
    for (size_t b = 0; b < n; ++b) {
        FValS s;
        for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
            const Quad &q = code[i];
            if (isVarP(q.dst)) {
                for (auto it = s.begin(); it != s.end();) {
                    if (sharesOpP(*it, q.dst)) it = s.erase(it);
                    else ++it;
                }
            }
            std::string e = exprKeyP(q);
            if (!e.empty()) s.insert(e);
        }
        p.egen[b] = s;
        FValS k;
        for (int i = blocks[b].begin; i < blocks[b].end; ++i)
            if (isVarP(code[i].dst))
                for (const auto &e : universe)
                    if (sharesOpP(e, code[i].dst)) k.insert(e);
        p.ekill[b] = k;
    }
    // 后继/前驱
    p.adj.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) p.adj[b].push_back(static_cast<int>(k));
    auto succBlocks = [&](size_t b, auto &&f) {
        for (int s : p.adj[b]) f(static_cast<size_t>(s));
    };
    // 前驱按“块号”反推（adj 里存的就是块号，别与 TAC 下标混比）
    std::vector<std::vector<int>> radj(n);
    for (size_t q = 0; q < n; ++q)
        for (int s : p.adj[q]) radj[s].push_back(static_cast<int>(q));
    auto predsOf = [&](size_t b) {
        std::vector<size_t> out;
        for (int q : radj[b]) out.push_back(static_cast<size_t>(q));
        return out;
    };
    auto inter = [](const FValS &a, const FValS &b2) {
        FValS out;
        for (const auto &x : a)
            if (b2.count(x)) out.insert(x);
        return out;
    };
    // ① anticipated（后向 must；出口 ∅）
    p.anticIn.assign(n, {});
    p.anticOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            FValS out;
            bool first = true;
            bool hasSucc = false;
            succBlocks(b, [&](size_t s) {
                hasSucc = true;
                out = first ? p.anticIn[s] : inter(out, p.anticIn[s]);
                first = false;
            });
            (void)hasSucc;
            FValS in = p.egen[b];
            for (const auto &e : out)
                if (!p.ekill[b].count(e)) in.insert(e);
            if (in != p.anticIn[b] || out != p.anticOut[b]) {
                p.anticIn[b] = in;
                p.anticOut[b] = out;
                ch = true;
            }
        }
    }
    // ② available（前向 must；入口 ∅）
    p.availIn.assign(n, {});
    p.availOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = 0; b < n; ++b) {
            FValS in;
            auto ps = predsOf(b);
            if (b == 0) in = FValS{};
            else if (!ps.empty()) {
                bool first = true;
                for (size_t q : ps) {
                    in = first ? p.availOut[q] : inter(in, p.availOut[q]);
                    first = false;
                }
            } else {
                in = universe;   // 不可达块前驱空：交全集（不影响后续）
            }
            FValS out = p.egen[b];
            for (const auto &e : in)
                if (!p.ekill[b].count(e)) out.insert(e);
            if (in != p.availIn[b] || out != p.availOut[b]) {
                p.availIn[b] = in;
                p.availOut[b] = out;
                ch = true;
            }
        }
    }
    // ③ earliest = anticipIn − availIn
    p.earliest.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        for (const auto &e : p.anticIn[b])
            if (!p.availIn[b].count(e)) p.earliest[b].insert(e);
    // ④ postponable（后向 must；出口 ∅）：in = (earliest ∪ out) − egen
    p.postIn.assign(n, {});
    p.postOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            FValS out;
            bool first = true;
            succBlocks(b, [&](size_t s) {
                out = first ? p.postIn[s] : inter(out, p.postIn[s]);
                first = false;
            });
            FValS in = p.earliest[b];
            for (const auto &e : out) in.insert(e);
            for (const auto &e : p.egen[b]) in.erase(e);
            if (in != p.postIn[b] || out != p.postOut[b]) {
                p.postIn[b] = in;
                p.postOut[b] = out;
                ch = true;
            }
        }
    }
    // ⑤ used（后向 may；出口 ∅）：in = egen ∪ (out − ekill)
    p.usedIn.assign(n, {});
    p.usedOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            FValS out;
            succBlocks(b, [&](size_t s) {
                out.insert(p.usedIn[s].begin(), p.usedIn[s].end());
            });
            FValS in = p.egen[b];
            for (const auto &e : out)
                if (!p.ekill[b].count(e)) in.insert(e);
            if (in != p.usedIn[b] || out != p.usedOut[b]) {
                p.usedIn[b] = in;
                p.usedOut[b] = out;
                ch = true;
            }
        }
    }
    // ⑥ latest = (earliest ∪ postOut) ∩ (egen ∪ ¬anticOut) ∩ usedIn 有用的部分
    p.latest.assign(n, {});
    for (size_t b = 0; b < n; ++b) {
        FValS cand = p.earliest[b];
        for (const auto &e : p.postOut[b]) cand.insert(e);
        for (auto it = cand.begin(); it != cand.end();) {
            bool genOrNoFuture = p.egen[b].count(*it) || !p.anticOut[b].count(*it);
            bool useful = p.usedIn[b].count(*it);
            if (!(genOrNoFuture && useful)) it = cand.erase(it);
            else ++it;
        }
        p.latest[b] = cand;
    }
    return p;
}

// ---------- 变换 ----------
std::pair<std::vector<Quad>, PreStats> preTransform(const std::vector<Quad> &code,
                                                    const std::vector<Block> &blocks,
                                                    const PreInfo &p) {
    // 教学版变换（保真范围：块内完全去重 + 跨块摆位报告）：
    //   对每个键 e 与每个“latest 块”：块内首次计算改写为 pe = e + dst = pe，
    //   块内后续重复计算一律改为复制——同块多次计算收敛为一次（真消除）；
    //   跨块的插入/删除由六方程的 latest 集合给出摆位方案，正文 36.6 详述，
    //   完整实现是练习三的主菜。
    PreStats st;
    size_t n = blocks.size();
    // 决定插入哪些（块, 表达式）：latest 且 egen 命中（本块本来就算）
    std::map<std::pair<size_t, std::string>, std::string> tempOf;
    int tmpN = 0;
    for (size_t b = 0; b < n; ++b)
        for (const auto &e : p.latest[b])
            if (p.egen[b].count(e))
                tempOf[{b, e}] = "pe" + std::to_string(++tmpN);
    // 标注：老行号 → 动作（0 不动 / 1 改写为 te=/复制）
    std::map<int, std::pair<int, std::string>> action;   // 行 → (kind, te)
    for (size_t b = 0; b < n; ++b)
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            std::string e = exprKeyP(code[i]);
            if (e.empty()) continue;
            auto it = tempOf.find({b, e});
            if (it == tempOf.end()) continue;
            bool first = true;
            for (int j = blocks[b].begin; j < i; ++j)
                if (exprKeyP(code[j]) == e) first = false;
            action[i] = {first ? 1 : 2, it->second};
        }
    // 重建：first 位改写 + 插入复制；其余改复制；跳转目标经 oldToNew 重贴
    std::vector<Quad> out;
    std::vector<int> oldToNew(code.size() + 1, -1);
    for (size_t i = 0; i < code.size(); ++i) {
        oldToNew[i] = static_cast<int>(out.size());
        auto it = action.find(static_cast<int>(i));
        if (it == action.end()) {
            out.push_back(code[i]);
            continue;
        }
        if (it->second.first == 1) {
            Quad model = code[i];
            out.push_back(Quad{model.op, it->second.second, model.a, model.b, -1});
            out.push_back(Quad{TOp::Copy, model.dst, it->second.second, "", -1});
            ++st.inserted;
        } else {
            out.push_back(Quad{TOp::Copy, code[i].dst, it->second.second, "", -1});
            ++st.replaced;
        }
    }
    oldToNew[code.size()] = static_cast<int>(out.size());
    for (auto &q : out)
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
            q.target = oldToNew[q.target];
    return {out, st};
}

}  // namespace tip
```

### 36.7.3 驱动 main.cpp

六方程逐块打印 +
变换 +
steps/outputs
对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 36 章驱动：--check FILE
//   TAC → 六方程逐块打印 → latest 摆位报告 → 块内去重变换 → 解释器对账。
#include "pre.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "tacgen.hpp"
#include "tacblocks.hpp"

#include <fstream>
#include <iostream>
#include <vector>

namespace {

struct CollectErrorListener : antlr4::BaseErrorListener {
    std::vector<std::string> messages;
    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

std::unique_ptr<tip::ProgramA> parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) throw std::runtime_error("打不开 " + path);
    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);
    CollectErrorListener errors;
    lexer.removeErrorListeners();
    parser.removeErrorListeners();
    lexer.addErrorListener(&errors);
    parser.addErrorListener(&errors);
    TIPParser::ProgramContext *tree = parser.program();
    if (!errors.messages.empty())
        throw std::runtime_error("词法/语法错误: " + errors.messages.front());
    auto ast = tip::buildAst(tree);
    auto binds = tip::resolveNames(*ast);
    if (!binds.errors.empty())
        throw std::runtime_error("名字解析错误: " + binds.errors.front().text);
    return ast;
}

void showS(const tip::FValS &s) {
    std::cout << "{";
    bool first = true;
    for (const auto &x : s) {
        std::cout << (first ? "" : ", ") << x;
        first = false;
    }
    std::cout << "}";
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto ast = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';
    std::cout << "== blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << ' ' << s;
        std::cout << '\n';
    }

    tip::PreInfo p = tip::preAnalyse(code, blocks);
    std::cout << "== 六方程 ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        std::cout << "    antic.in  "; showS(p.anticIn[b]); std::cout << '\n';
        std::cout << "    avail.in  "; showS(p.availIn[b]); std::cout << '\n';
        std::cout << "    earliest  "; showS(p.earliest[b]); std::cout << '\n';
        std::cout << "    post.out  "; showS(p.postOut[b]); std::cout << '\n';
        std::cout << "    used.in   "; showS(p.usedIn[b]); std::cout << '\n';
        std::cout << "    latest    "; showS(p.latest[b]); std::cout << '\n';
    }

    auto [out, st] = tip::preTransform(code, blocks, p);
    std::cout << "== after PRE（块内去重）==\n";
    for (size_t i = 0; i < out.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(out[i]) << '\n';
    std::cout << "  stats: inserted=" << st.inserted << " replaced=" << st.replaced << '\n';

    std::cout << "== 对账 ==\n";
    tip::TacRun before = tip::tacInterp(code, {5, 3});
    tip::TacRun after = tip::tacInterp(out, {5, 3});
    std::cout << "  steps: " << before.steps << " -> " << after.steps << '\n';
    std::cout << "  outputs:";
    for (int v : before.outputs) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before.outputs == after.outputs ? "yes" : "NO") << '\n';
    return before.outputs == after.outputs ? 0 : 1;
}
```

### 36.7.4 TAC 基座与前端（第 13、8、10 章）

```cpp
// file: src/tacgen.hpp
// file: src/tacgen.hpp
// 第 13 章配套：AST → 三地址码（TAC）。
// 指令形态取绿龙 §7.6 的四元组风格：
//   x = y          （复制，y 可以是数字字面量）
//   x = y op z     （op ∈ + - * / > ==）
//   t? = input ; output x ; return x
//   if x > y goto L ; if x == y goto L ; goto L
// 布尔值不落地：比较直接嵌在条件跳转里（绿龙 §7.8/7.9 的口径）。
// 每条指令至多一次运算——“三地址”的名字就是这么来的。
#ifndef TIP_TACGEN_HPP
#define TIP_TACGEN_HPP

#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

enum class TOp { Copy, Add, Sub, Mul, Div, Gt, Eq, Input, Output, Ret,
                 Goto, IfGt, IfEq };

struct Quad {
    TOp op;
    std::string dst;    // Copy/Bin/Input 的目的
    std::string a, b;   // 操作数
    int target = -1;    // 跳转目标（TAC 下标；打印为 L<n>）
};

std::string show(const Quad &q);

// 单函数 TAC：把函数体降落到四元组序列。
// 不支持的构造（指针、记录、调用）抛异常并注明去向章节。
std::vector<Quad> tacGen(const FunDecl &fn);

}  // namespace tip

#endif  // TIP_TACGEN_HPP
```

```cpp
// file: src/tacgen.cpp
// file: src/tacgen.cpp
// 第 13 章配套：TAC 生成与打印。
#include "tacgen.hpp"

#include <map>
#include <sstream>
#include <stdexcept>
#include <utility>

namespace tip {

std::string show(const Quad &q) {
    std::ostringstream os;
    switch (q.op) {
    case TOp::Copy:   os << q.dst << " = " << q.a; break;
    case TOp::Add:    os << q.dst << " = " << q.a << " + " << q.b; break;
    case TOp::Sub:    os << q.dst << " = " << q.a << " - " << q.b; break;
    case TOp::Mul:    os << q.dst << " = " << q.a << " * " << q.b; break;
    case TOp::Div:    os << q.dst << " = " << q.a << " / " << q.b; break;
    case TOp::Gt:     os << q.dst << " = " << q.a << " > " << q.b; break;
    case TOp::Eq:     os << q.dst << " = " << q.a << " == " << q.b; break;
    case TOp::Input:  os << q.dst << " = input"; break;
    case TOp::Output: os << "output " << q.a; break;
    case TOp::Ret:    os << "return " << q.a; break;
    case TOp::Goto:   os << "goto L" << q.target; break;
    case TOp::IfGt:   os << "if " << q.a << " > " << q.b << " goto L" << q.target; break;
    case TOp::IfEq:   os << "if " << q.a << " == " << q.b << " goto L" << q.target; break;
    }
    return os.str();
}

namespace {

struct Gen {
    std::vector<Quad> code;
    int tmp = 0, nlabels = 0;
    std::map<int, int> labelHere;               // 标签号 → TAC 下标
    std::vector<std::pair<int, int>> patches;   // (指令下标, 标签号)

    std::string newTmp() { return "t" + std::to_string(++tmp); }
    int newLabel() { return nlabels++; }
    void setLabel(int l) { labelHere[l] = static_cast<int>(code.size()); }
    void emit(Quad q) { code.push_back(std::move(q)); }
    void jump(TOp op, const std::string &a, const std::string &b, int l) {
        patches.emplace_back(static_cast<int>(code.size()), l);
        emit({op, "", a, b, -1});
    }
    void finish() {
        for (const auto &p : patches) code[p.first].target = labelHere.at(p.second);
    }

    [[noreturn]] void unsupported(const char *what, int ch) {
        std::ostringstream os;
        os << "TAC 生成不支持 " << what << "（留待第 " << ch << " 章家族）";
        throw std::runtime_error(os.str());
    }

    // 表达式求值到“地址”：变量名或临时名。常量也先落入临时——
    // 让“每条指令至多一次运算”成为不破的铁律（绿龙 §7.7 的约定）。
    std::string addr(const Expr &e) {
        if (auto *n = dynamic_cast<const IntLit *>(&e)) {
            std::string t = newTmp();
            emit({TOp::Copy, t, std::to_string(n->v), "", -1});
            return t;
        }
        if (auto *v = dynamic_cast<const VarRef *>(&e)) return v->name;
        if (dynamic_cast<const InputE *>(&e)) {
            std::string t = newTmp();
            emit({TOp::Input, t, "", "", -1});
            return t;
        }
        if (auto *b = dynamic_cast<const Binop *>(&e)) {
            std::string l = addr(*b->l), r = addr(*b->r), t = newTmp();
            TOp op = b->op == BOp::Add ? TOp::Add
                    : b->op == BOp::Sub ? TOp::Sub
                    : b->op == BOp::Mul ? TOp::Mul
                    : b->op == BOp::Div ? TOp::Div
                    : b->op == BOp::Gt ? TOp::Gt : TOp::Eq;
            emit({op, t, l, r, -1});
            return t;
        }
        unsupported("该表达式构造（指针/记录/调用）", 42);
    }

    // 条件跳转：比较不落地，直接嵌进跳转（绿龙 §7.9 的控制流翻译）。
    void condJump(const Expr &cond, int target) {
        auto *b = dynamic_cast<const Binop *>(&cond);
        if (!b || (b->op != BOp::Gt && b->op != BOp::Eq))
            unsupported("非常规条件（if/while 条件请用 > 或 ==）", 13);
        std::string l = addr(*b->l), r = addr(*b->r);
        jump(b->op == BOp::Gt ? TOp::IfGt : TOp::IfEq, l, r, target);
    }

    void stmt(const Stmt &s) {
        if (auto *a = dynamic_cast<const AssignS *>(&s)) {
            std::string v = addr(*a->value);
            if (auto *tv = dynamic_cast<const VarRef *>(a->target.get())) {
                emit({TOp::Copy, tv->name, v, "", -1});
            } else {
                unsupported("非变量赋值目标（指针/字段写）", 42);
            }
        } else if (auto *o = dynamic_cast<const OutputS *>(&s)) {
            std::string v = addr(*o->e);
            emit({TOp::Output, "", v, "", -1});
        } else if (auto *i = dynamic_cast<const IfS *>(&s)) {
            // if c then S else S'：
            //   if c goto L_then ; goto L_else ; L_then: S ; goto L_end ;
            //   L_else: S' ; L_end:
            int lThen = newLabel(), lElse = newLabel(), lEnd = newLabel();
            condJump(*i->cond, lThen);
            jump(TOp::Goto, "", "", lElse);
            setLabel(lThen);
            stmt(*i->then);
            jump(TOp::Goto, "", "", lEnd);
            setLabel(lElse);
            if (i->els) stmt(*i->els);
            setLabel(lEnd);
        } else if (auto *w = dynamic_cast<const WhileS *>(&s)) {
            // L_head: if c goto L_body ; goto L_end ; L_body: S ;
            // goto L_head ; L_end:
            int lHead = newLabel(), lBody = newLabel(), lEnd = newLabel();
            setLabel(lHead);
            condJump(*w->cond, lBody);
            jump(TOp::Goto, "", "", lEnd);
            setLabel(lBody);
            stmt(*w->body);
            jump(TOp::Goto, "", "", lHead);
            setLabel(lEnd);
        } else if (auto *blk = dynamic_cast<const BlockS *>(&s)) {
            for (const auto &st : blk->ss) stmt(*st);
        } else if (auto *r = dynamic_cast<const ReturnS *>(&s)) {
            std::string v = addr(*r->e);
            emit({TOp::Ret, "", v, "", -1});
        } else {
            unsupported("未知语句", 42);
        }
    }
};

}  // namespace

std::vector<Quad> tacGen(const FunDecl &fn) {
    Gen g;
    g.stmt(*fn.body);
    g.stmt(*fn.ret);
    g.finish();
    return g.code;
}

}  // namespace tip
```

```cpp
// file: src/tacblocks.hpp
// file: src/tacblocks.hpp
// 第 13 章配套：leader 划分基本块 + 块内 next-use 信息。
// 两条规则都出自绿龙 §7.9 / 紫 §8.4 的经典表述：
//   leader = 首指令 | 跳转目标 | 跳转的下一指令；
//   next-use = 块内反向一趟，写 kills、读 gens。
#ifndef TIP_TACBLOCKS_HPP
#define TIP_TACBLOCKS_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"

namespace tip {

struct Block {
    int id;
    int begin, end;   // [begin, end) 的 TAC 下标
    std::set<int> succs;
};

// 基本块划分 + 后继表（后继由块尾跳转/顺序落入决定）。
std::vector<Block> partitionBlocks(const std::vector<Quad> &code);

// next-use：tac[i] 处变量 v 的下一次使用下标（块内），无则 -1。
// 返回 map[(i, var)] -> 下标。
std::map<std::pair<int, std::string>, int> nextUse(const std::vector<Quad> &code,
                                                   const Block &b);

}  // namespace tip

#endif  // TIP_TACBLOCKS_HPP
```

```cpp
// file: src/tacblocks.cpp
// file: src/tacblocks.cpp
// 第 13 章配套：leader 划分与 next-use。
#include "tacblocks.hpp"

#include <algorithm>

namespace tip {

namespace {
bool isJump(const Quad &q) {
    return q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq;
}
}  // namespace

std::vector<Block> partitionBlocks(const std::vector<Quad> &code) {
    // leader 三规则（绿龙 §7.9）：
    //   1) 首指令；2) 跳转目标；3) 紧跟跳转的指令。
    std::vector<bool> leader(code.size(), false);
    if (!code.empty()) leader[0] = true;
    for (size_t i = 0; i < code.size(); ++i) {
        if (isJump(code[i])) {
            leader[code[i].target] = true;
            if (i + 1 < code.size()) leader[i + 1] = true;
        }
    }
    std::vector<int> heads;
    for (size_t i = 0; i < code.size(); ++i)
        if (leader[i]) heads.push_back(static_cast<int>(i));
    std::vector<Block> blocks;
    for (size_t k = 0; k < heads.size(); ++k) {
        int b = heads[k];
        int e = (k + 1 < heads.size()) ? heads[k + 1] : static_cast<int>(code.size());
        Block blk{static_cast<int>(k), b, e, {}};
        const Quad &last = code[e - 1];
        if (last.op == TOp::Goto) {
            blk.succs.insert(last.target);
        } else if (last.op == TOp::IfGt || last.op == TOp::IfEq) {
            blk.succs.insert(last.target);
            if (e < static_cast<int>(code.size())) blk.succs.insert(e);
        } else if (e < static_cast<int>(code.size())) {
            blk.succs.insert(e);
        }
        blocks.push_back(blk);
    }
    return blocks;
}

// 块内反向一趟（紫龙 §8.4.2 的 next-use 算法）：
// 读操作数：把“它下一次被用的行”记在当前行，然后登记自己；
// 写目的：先记当前信息，再清空（重定义使旧信息失效）。
std::map<std::pair<int, std::string>, int> nextUse(const std::vector<Quad> &code,
                                                   const Block &b) {
    std::map<std::string, int> nu;   // 变量 → 下一次使用的行号
    std::map<std::pair<int, std::string>, int> out;
    auto reads = [](const Quad &q) {
        std::vector<std::string> r;
        switch (q.op) {
        case TOp::Copy:
        case TOp::Output:
        case TOp::Ret:
            if (!q.a.empty() && !isdigit(q.a[0])) r.push_back(q.a);
            break;
        case TOp::Add: case TOp::Sub: case TOp::Mul:
        case TOp::Div: case TOp::Gt: case TOp::Eq:
        case TOp::IfGt: case TOp::IfEq:
            for (const std::string &s : {q.a, q.b})
                if (!s.empty() && !isdigit(s[0])) r.push_back(s);
            break;
        default: break;
        }
        return r;
    };
    auto isDigitStr = [](const std::string &s) {
        return !s.empty() && isdigit(s[0]);
    };
    for (int i = b.end - 1; i >= b.begin; --i) {
        const Quad &q = code[i];
        for (const auto &v : reads(q))
            out[{i, v}] = nu.count(v) ? nu[v] : -1;
        // 定义处也登记：被定义变量“在此之后”的下一使用——
        // 它是“结果占着寄存器值不值”的判据（紫龙 §8.4.2 的完整口径）。
        if (!q.dst.empty() && !isDigitStr(q.dst))
            out[{i, q.dst}] = nu.count(q.dst) ? nu[q.dst] : -1;
        if (!q.dst.empty() && !isDigitStr(q.dst))
            nu[q.dst] = -1;   // 定义即清空
        for (const auto &v : reads(q))
            nu[v] = i;        // 本次使用登记
    }
    return out;
}

}  // namespace tip
```

```cpp
// file: src/tacinterp.hpp
// file: src/tacinterp.hpp
// 第 13 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
// 语义口径与 LLVM JIT 对齐：main 的形参取 0，output 收集为序列。
#ifndef TIP_TACINTERP_HPP
#define TIP_TACINTERP_HPP

#include <string>
#include <vector>

#include "tacgen.hpp"

namespace tip {

struct TacRun {
    std::vector<int> outputs;
    int steps = 0;      // 执行的指令数（给第 34/35/36 章的收益对账用）
};

TacRun tacInterp(const std::vector<Quad> &code, const std::vector<int> &inputs);

}  // namespace tip

#endif  // TIP_TACINTERP_HPP
```

```cpp
// file: src/tacinterp.cpp
// file: src/tacinterp.cpp
// 第 13 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
#include "tacinterp.hpp"

#include <cctype>
#include <cstdlib>
#include <map>
#include <stdexcept>

namespace tip {

namespace {
bool isNum(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
}  // namespace

TacRun tacInterp(const std::vector<Quad> &code, const std::vector<int> &inputs) {
    TacRun r;
    std::map<std::string, int> val;
    size_t nextInput = 0;
    int pc = 0;
    auto rd = [&](const std::string &a) {
        if (isNum(a)) return std::atoi(a.c_str());
        auto it = val.find(a);
        if (it == val.end()) throw std::runtime_error("读未初始化变量 " + a);
        return it->second;
    };
    while (pc >= 0 && pc < static_cast<int>(code.size())) {
        const Quad &q = code[pc];
        ++r.steps;
        switch (q.op) {
        case TOp::Copy:  val[q.dst] = rd(q.a); ++pc; break;
        case TOp::Add:   val[q.dst] = rd(q.a) + rd(q.b); ++pc; break;
        case TOp::Sub:   val[q.dst] = rd(q.a) - rd(q.b); ++pc; break;
        case TOp::Mul:   val[q.dst] = rd(q.a) * rd(q.b); ++pc; break;
        case TOp::Div:   val[q.dst] = rd(q.a) / rd(q.b); ++pc; break;
        case TOp::Gt:    val[q.dst] = rd(q.a) > rd(q.b) ? 1 : 0; ++pc; break;
        case TOp::Eq:    val[q.dst] = rd(q.a) == rd(q.b) ? 1 : 0; ++pc; break;
        case TOp::Input:
            if (nextInput >= inputs.size())
                throw std::runtime_error("input 序列耗尽");
            val[q.dst] = inputs[nextInput++];
            ++pc;
            break;
        case TOp::Output: r.outputs.push_back(rd(q.a)); ++pc; break;
        case TOp::Ret:    return r;
        case TOp::Goto:   pc = q.target; break;
        case TOp::IfGt:   pc = rd(q.a) > rd(q.b) ? q.target : pc + 1; break;
        case TOp::IfEq:   pc = rd(q.a) == rd(q.b) ? q.target : pc + 1; break;
        }
    }
    return r;
}

}  // namespace tip
```

```cpp
// file: src/ast.hpp
// AST 定义：AST 是去掉了括号、分号等语法噪音的程序结构。
// 接口自本章起冻结，后续所有分析（名字、CFG、类型、格……）都在此之上工作。
#pragma once

#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace tip {

enum class BOp { Add, Sub, Mul, Div, Gt, Eq };

struct Expr {
    virtual ~Expr() = default;
};
struct IntLit : Expr {
    int v;
    explicit IntLit(int value) : v(value) {}
};
struct VarRef : Expr {
    std::string name;
    explicit VarRef(std::string n) : name(std::move(n)) {}
};
struct InputE : Expr {};
struct Binop : Expr {
    BOp op;
    std::unique_ptr<Expr> l, r;
    Binop(BOp o, std::unique_ptr<Expr> lhs, std::unique_ptr<Expr> rhs)
        : op(o), l(std::move(lhs)), r(std::move(rhs)) {}
};
struct CallE : Expr {
    std::unique_ptr<Expr> callee;
    std::vector<std::unique_ptr<Expr>> args;
    CallE(std::unique_ptr<Expr> fn, std::vector<std::unique_ptr<Expr>> as)
        : callee(std::move(fn)), args(std::move(as)) {}
};
struct Deref : Expr {
    std::unique_ptr<Expr> e;
    explicit Deref(std::unique_ptr<Expr> p) : e(std::move(p)) {}
};
struct AddrOf : Expr {                       // spa: & Id
    std::string name;
    explicit AddrOf(std::string n) : name(std::move(n)) {}
};
struct AllocE : Expr {
    std::unique_ptr<Expr> e;
    explicit AllocE(std::unique_ptr<Expr> init) : e(std::move(init)) {}
};
struct NullE : Expr {};
struct RecLit : Expr {
    std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
    explicit RecLit(std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fs)
        : fields(std::move(fs)) {}
};
struct FieldA : Expr {
    std::unique_ptr<Expr> e;
    std::string field;
    FieldA(std::unique_ptr<Expr> record, std::string f)
        : e(std::move(record)), field(std::move(f)) {}
};

struct Stmt {
    virtual ~Stmt() = default;
};
// target 只会是 VarRef / FieldA / Deref，文法 lvalue 已限定。
struct AssignS : Stmt {
    std::unique_ptr<Expr> target, value;
    AssignS(std::unique_ptr<Expr> t, std::unique_ptr<Expr> v)
        : target(std::move(t)), value(std::move(v)) {}
};
struct OutputS : Stmt {
    std::unique_ptr<Expr> e;
    explicit OutputS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};
struct IfS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> then, els;
    IfS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> t, std::unique_ptr<Stmt> e)
        : cond(std::move(c)), then(std::move(t)), els(std::move(e)) {}
};
struct WhileS : Stmt {
    std::unique_ptr<Expr> cond;
    std::unique_ptr<Stmt> body;
    WhileS(std::unique_ptr<Expr> c, std::unique_ptr<Stmt> b)
        : cond(std::move(c)), body(std::move(b)) {}
};
struct BlockS : Stmt {
    std::vector<std::unique_ptr<Stmt>> ss;
    explicit BlockS(std::vector<std::unique_ptr<Stmt>> v) : ss(std::move(v)) {}
};
struct ReturnS : Stmt {
    std::unique_ptr<Expr> e;
    explicit ReturnS(std::unique_ptr<Expr> x) : e(std::move(x)) {}
};

struct FunDecl {
    std::string name;
    std::vector<std::string> params;
    std::vector<std::string> vars;
    std::unique_ptr<Stmt> body;
    std::unique_ptr<ReturnS> ret;
};

struct ProgramA {
    std::vector<std::unique_ptr<FunDecl>> funs;
};

}  // namespace tip
```

```cpp
// file: src/ast_build.hpp
// AST 构建器：在 ANTLR 生成的 parse-tree 上下文节点上手工递归下降。
// （本工具链 C++ runtime 的 visitor 以 std::any 传值，而 std::any 不能持有
// unique_ptr，因此不使用 visitor 机制：parse-tree 的上下文类本身信息完整，
// 用 dynamic_cast 区分 #标签备选，自己做一次结构化遍历同样直接。）
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "TIPParser.h"
#include "antlr4-runtime.h"
#include "ast.hpp"

namespace tip {

struct AstBuilder {
    std::unique_ptr<ProgramA> build(TIPParser::ProgramContext *tree);

private:
    std::unique_ptr<FunDecl> buildFun(TIPParser::FunctionContext *ctx);
    std::unique_ptr<Expr> buildExpr(TIPParser::ExprContext *ctx);
    std::unique_ptr<Stmt> buildStmt(TIPParser::StmtContext *ctx);
    // lvalue 翻译成赋值目标表达式：VarRef / Deref，可再包一层 FieldA。
    std::unique_ptr<Expr> buildLvalue(TIPParser::LvalueContext *lv);
};

// 便捷入口：parse tree 的 program 节点 -> 完整 AST。
std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree);

}  // namespace tip
```

```cpp
// file: src/ast_build.cpp
#include "ast_build.hpp"

#include <utility>
#include <vector>

namespace tip {

std::unique_ptr<ProgramA> AstBuilder::build(TIPParser::ProgramContext *tree) {
    auto program = std::make_unique<ProgramA>();
    for (auto *fc : tree->function()) program->funs.push_back(buildFun(fc));
    return program;
}

std::unique_ptr<FunDecl> AstBuilder::buildFun(TIPParser::FunctionContext *ctx) {
    auto f = std::make_unique<FunDecl>();
    f->name = ctx->IDENT()->getText();
    if (ctx->params()) {
        for (auto *p : ctx->params()->IDENT()) f->params.push_back(p->getText());
    }
    if (ctx->varDecls()) {
        for (auto *v : ctx->varDecls()->IDENT()) f->vars.push_back(v->getText());
    }

    std::vector<std::unique_ptr<Stmt>> body;
    for (auto *sc : ctx->stmt()) body.push_back(buildStmt(sc));
    f->body = std::make_unique<BlockS>(std::move(body));

    f->ret = std::make_unique<ReturnS>(buildExpr(ctx->expr()));
    return f;
}

std::unique_ptr<Expr> AstBuilder::buildLvalue(TIPParser::LvalueContext *lv) {
    std::unique_ptr<Expr> base;
    std::string field;
    if (auto *d = dynamic_cast<TIPParser::DirectLvalueContext *>(lv)) {
        base = std::make_unique<VarRef>(d->IDENT(0)->getText());
        if (d->IDENT().size() == 2) field = d->IDENT(1)->getText();
    } else {
        auto *p = dynamic_cast<TIPParser::PointerLvalueContext *>(lv);
        base = std::make_unique<Deref>(buildExpr(p->expr()));
        if (p->IDENT()) field = p->IDENT()->getText();
    }
    if (!field.empty())
        return std::make_unique<FieldA>(std::move(base), std::move(field));
    return base;
}

std::unique_ptr<Expr> AstBuilder::buildExpr(TIPParser::ExprContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::IntExprContext *>(ctx))
        return std::make_unique<IntLit>(std::stoi(c->INT()->getText()));
    if (auto *c = dynamic_cast<TIPParser::VarExprContext *>(ctx))
        return std::make_unique<VarRef>(c->IDENT()->getText());
    if (dynamic_cast<TIPParser::InputExprContext *>(ctx))
        return std::make_unique<InputE>();
    if (dynamic_cast<TIPParser::NullExprContext *>(ctx))
        return std::make_unique<NullE>();
    if (auto *c = dynamic_cast<TIPParser::ParenExprContext *>(ctx))
        return buildExpr(c->expr());

    if (auto *c = dynamic_cast<TIPParser::AddExprContext *>(ctx)) {
        const BOp op = c->PLUS() ? BOp::Add : BOp::Sub;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::MulExprContext *>(ctx)) {
        const BOp op = c->STAR() ? BOp::Mul : BOp::Div;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::CmpExprContext *>(ctx)) {
        const BOp op = c->GT() ? BOp::Gt : BOp::Eq;
        return std::make_unique<Binop>(op, buildExpr(c->expr(0)), buildExpr(c->expr(1)));
    }
    if (auto *c = dynamic_cast<TIPParser::NegExprContext *>(ctx)) {
        // TIP 没有负数字面量 token，-E 即 0-E。
        return std::make_unique<Binop>(BOp::Sub, std::make_unique<IntLit>(0),
                                       buildExpr(c->expr()));
    }
    if (auto *c = dynamic_cast<TIPParser::CallExprContext *>(ctx)) {
        std::vector<std::unique_ptr<Expr>> args;
        if (c->args())
            for (auto *a : c->args()->expr()) args.push_back(buildExpr(a));
        return std::make_unique<CallE>(buildExpr(c->expr()), std::move(args));
    }
    if (auto *c = dynamic_cast<TIPParser::FieldExprContext *>(ctx))
        return std::make_unique<FieldA>(buildExpr(c->expr()), c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::DerefExprContext *>(ctx))
        return std::make_unique<Deref>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::AddrExprContext *>(ctx))
        return std::make_unique<AddrOf>(c->IDENT()->getText());
    if (auto *c = dynamic_cast<TIPParser::AllocExprContext *>(ctx))
        return std::make_unique<AllocE>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::RecExprContext *>(ctx)) {
        std::vector<std::pair<std::string, std::unique_ptr<Expr>>> fields;
        for (auto *fc : c->field())
            fields.emplace_back(fc->IDENT()->getText(), buildExpr(fc->expr()));
        return std::make_unique<RecLit>(std::move(fields));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<Stmt> AstBuilder::buildStmt(TIPParser::StmtContext *ctx) {
    if (auto *c = dynamic_cast<TIPParser::AssignStmtContext *>(ctx))
        return std::make_unique<AssignS>(buildLvalue(c->lvalue()), buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::OutputStmtContext *>(ctx))
        return std::make_unique<OutputS>(buildExpr(c->expr()));
    if (auto *c = dynamic_cast<TIPParser::IfStmtContext *>(ctx)) {
        std::unique_ptr<Stmt> els;
        if (c->stmt().size() == 2) els = buildStmt(c->stmt(1));
        return std::make_unique<IfS>(buildExpr(c->expr()), buildStmt(c->stmt(0)),
                                     std::move(els));
    }
    if (auto *c = dynamic_cast<TIPParser::WhileStmtContext *>(ctx))
        return std::make_unique<WhileS>(buildExpr(c->expr()), buildStmt(c->stmt()));
    if (auto *c = dynamic_cast<TIPParser::BlockStmtContext *>(ctx)) {
        std::vector<std::unique_ptr<Stmt>> ss;
        for (auto *sc : c->stmt()) ss.push_back(buildStmt(sc));
        return std::make_unique<BlockS>(std::move(ss));
    }
    return nullptr;  // 解析成功时不会到达
}

std::unique_ptr<ProgramA> buildAst(TIPParser::ProgramContext *tree) {
    return AstBuilder{}.build(tree);
}

}  // namespace tip
```

```cpp
// file: src/symtab.hpp
// 符号表与名字解析：把 AST 上的每个 VarRef 绑定到它的声明
// （函数 / 参数 / 局部变量），同时产出未声明、重复声明诊断。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

struct Symbol {
    enum Kind { Fun, Param, Local } kind;
    std::string name;
    const FunDecl *fun;          // Fun: 指向自身声明; Param/Local: 指向所属函数
};

struct Scope {
    Scope *parent;
    std::map<std::string, Symbol> table;

    explicit Scope(Scope *p = nullptr) : parent(p) {}
    const Symbol *lookup(const std::string &name) const;
};

struct Diag {
    std::string text;
};

struct Bindings {
    Scope global;                                  // 函数名所在的全局作用域
    // 各函数作用域由 Bindings 持有所有权：uses 中的 Symbol* 才不会悬垂。
    std::vector<std::unique_ptr<Scope>> scopes;
    std::vector<Diag> errors;
    std::map<const VarRef *, const Symbol *> uses;  // 解析成功的使用点
};

// 两遍解析：先注册全部函数名（支持前向调用），再逐函数解析函数体。
Bindings resolveNames(ProgramA &program);

}  // namespace tip
```

```cpp
// file: src/symtab.cpp
#include "symtab.hpp"

#include <utility>

namespace tip {

namespace {

// 解析器在遍历 AST 的同时完成绑定与诊断收集。
struct Resolver {
    Bindings bindings;
    Scope *current = nullptr;
    const FunDecl *owner = nullptr;

    void declare(const std::string &name, Symbol::Kind kind) {
        if (current->table.count(name)) {
            bindings.errors.push_back({"error: redeclared '" + name + "'"});
            return;  // 保留先声明者，后声明被忽略
        }
        current->table.emplace(name, Symbol{kind, name, owner});
    }

    void resolveExpr(const Expr *e) {
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            const Symbol *s = current->lookup(x->name);
            if (!s) {
                bindings.errors.push_back({"error: undeclared '" + x->name + "'"});
            } else {
                bindings.uses[x] = s;
            }
            return;
        }
        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            resolveExpr(x->l.get());
            resolveExpr(x->r.get());
            return;
        }
        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            resolveExpr(x->callee.get());
            for (const auto &a : x->args) resolveExpr(a.get());
            return;
        }
        if (const auto *x = dynamic_cast<const Deref *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const AllocE *>(e)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            resolveExpr(x->e.get());  // 字段名不是变量，无需解析
            return;
        }
        if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            for (const auto &f : x->fields) resolveExpr(f.second.get());
            return;
        }
        // IntLit / InputE / AddrOf / NullE：无变量使用。
    }

    void resolveStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            resolveExpr(x->target.get());
            resolveExpr(x->value.get());
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) return resolveExpr(x->e.get());
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->then.get());
            if (x->els) resolveStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            resolveExpr(x->cond.get());
            resolveStmt(x->body.get());
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) resolveStmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const ReturnS *>(s)) return resolveExpr(x->e.get());
    }
};

}  // namespace

const Symbol *Scope::lookup(const std::string &name) const {
    auto it = table.find(name);
    if (it != table.end()) return &it->second;
    return parent ? parent->lookup(name) : nullptr;
}

Bindings resolveNames(ProgramA &program) {
    Resolver resolver;
    resolver.bindings.global = Scope(nullptr);
    Scope *global = &resolver.bindings.global;

    // 第一遍：所有函数名进入全局作用域。
    for (const auto &f : program.funs) {
        if (global->table.count(f->name)) {
            resolver.bindings.errors.push_back({"error: redeclared '" + f->name + "'"});
            continue;
        }
        global->table.emplace(f->name, Symbol{Symbol::Fun, f->name, f.get()});
    }

    // 第二遍：每个函数开自己的作用域，父作用域是全局表；
    // 作用域所有权交给 Bindings，遍历结束后符号依然存活。
    for (const auto &f : program.funs) {
        auto functionScope = std::make_unique<Scope>(global);
        resolver.current = functionScope.get();
        resolver.owner = f.get();

        for (const std::string &p : f->params) resolver.declare(p, Symbol::Param);
        for (const std::string &v : f->vars) resolver.declare(v, Symbol::Local);

        resolver.resolveStmt(f->body.get());
        resolver.resolveStmt(f->ret.get());

        resolver.current = nullptr;
        resolver.bindings.scopes.push_back(std::move(functionScope));
    }
    return std::move(resolver.bindings);
}

}  // namespace tip
```

### 36.7.5 程序与期望输出

```text
// file: programs/partial.tip
main() {
  var a, b, x, y, z;
  a = input;
  b = input;
  if (a > b) x = a * b; else x = 0;
  y = a * b;
  z = a * b + 1;
  output x + y + z;
  return 0;
}
```

```text
; expected: expected/output.txt
== partial.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: t2 = input
  3: b = t2
  4: if a > b goto L6
  5: goto L9
  6: t3 = a * b
  7: x = t3
  8: goto L11
  9: t4 = 0
  10: x = t4
  11: t5 = a * b
  12: y = t5
  13: t6 = a * b
  14: t7 = 1
  15: t8 = t6 + t7
  16: z = t8
  17: t9 = x + y
  18: t10 = t9 + z
  19: output t10
  20: t11 = 0
  21: return t11
== blocks ==
  B0 [0,5) succs: 5 6
  B1 [5,6) succs: 9
  B2 [6,9) succs: 11
  B3 [9,11) succs: 11
  B4 [11,22) succs:
== 六方程 ==
  B0:
    antic.in  {}
    avail.in  {}
    earliest  {}
    post.out  {}
    used.in   {}
    latest    {}
  B1:
    antic.in  {a * b}
    avail.in  {}
    earliest  {a * b}
    post.out  {a * b}
    used.in   {a * b}
    latest    {}
  B2:
    antic.in  {a * b}
    avail.in  {}
    earliest  {a * b}
    post.out  {}
    used.in   {a * b}
    latest    {a * b}
  B3:
    antic.in  {a * b}
    avail.in  {}
    earliest  {a * b}
    post.out  {}
    used.in   {a * b}
    latest    {}
  B4:
    antic.in  {a * b}
    avail.in  {}
    earliest  {a * b}
    post.out  {}
    used.in   {a * b}
    latest    {a * b}
== after PRE（块内去重）==
  0: t1 = input
  1: a = t1
  2: t2 = input
  3: b = t2
  4: if a > b goto L6
  5: goto L10
  6: pe1 = a * b
  7: t3 = pe1
  8: x = t3
  9: goto L12
  10: t4 = 0
  11: x = t4
  12: pe2 = a * b
  13: t5 = pe2
  14: y = t5
  15: t6 = pe2
  16: t7 = 1
  17: t8 = t6 + t7
  18: z = t8
  19: t9 = x + y
  20: t10 = t9 + z
  21: output t10
  22: t11 = 0
  23: return t11
  stats: inserted=2 replaced=1
== 对账 ==
  steps: 19 -> 21
  outputs: 46
  outputs preserved: yes
```

## 36.8 小结与练习

本章是
经典数据流
优化的封顶：

- 部分冗余是
  完全冗余分析的
  剩余地形，
  PRE 用"搬计算"
  而非"复用值"
  攻坚；
- 六方程
  （antic/avail/
   earliest/
   post/used/
   latest）
  把"最晚 +
  只一次"
  的双目标
  解成
  一组不动点；
- latest 的
  落点由
  e_gen 阀门与
  anticip 出口
  共同决定——
  分支几何
  就是优化几何；
- 教学版
  变换做了
  块内去重与
  摆位报告，
  跨块搬移的
  完整账本
  留给练习。

至此第七篇
（控制流的
  结构与变换）
收官。
下一篇进入
目标代码世界：
寄存器分配、
指令选择、
指令级并行
——分析终于
要兑换成
机器的周期。

练习：

1. 手工对 partial.tip
   解六方程，
   逐块与输出对照；
   特别验证
   else 块的
   latest 为空
   的两步推理。
2. 把 else 支改成
   `x = a * b + 1;`，
   重跑：
   earliest/latest
   怎么移动？
   join 的
   部分冗余
   变成什么？
3. **完整 LCM**：
   在 earliest
   （分支点）插入
   `pe0 = a * b`，
   删除 then 块的
   原计算与
   join 的
   全部 a\*b 计算，
   改写为
   pe0 的复制；
   验收线：
   outputs 不变、
   steps 下降、
   乘法计数
   每条路径
   恰一次。
4. 构造一个
   "部分死"程序
   （某分支算了
    e 但之后
    两路都不用），
   观察 used
   方程如何
   阻止无用的
   插入。
5. 证明
   earliest ≤
   latest ≤
   用点
   （全集包含序）
   ——即
   "摆位区间
    一定存在"
   ——并指出
   哪个方程
   承担了
   哪一段边界。
