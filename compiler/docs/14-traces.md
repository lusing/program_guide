# 第 14 章　规范化与跟踪：让跳转少到只剩必要

## 14.1 问题：块是好东西，顺序还是烂的

第 13 章把 TAC 切成了
基本块，
块与块之间
靠跳转缝合。
但**块以什么顺序
摆进最终的
指令流**，
第 13 章没管——
它按源代码顺序
原样铺开。

顺序为什么重要？
看真实机器的
两条事实：

1. **条件跳转
   只有一个目标**：
   条件为真跳走、
   为假"直落"到
   **下一条指令**。
   IR 里的
   `if a > b goto L`
   天生就是
   单目标 + 直落；
   编译期把哪个块
   摆在跳转后面，
   就选定了
   "假臂走直落"——
   这是个**布局决策**，
   不是语义；
2. **直落免费、
   跳转花钱**：
   直落零指令、
   零周期；
   每条多余跳转
   都是实打实的
   取指中断与
   分支开销。

于是目标成型：
**重排块的顺序，
让尽量多的跳转
变成直落**——
虎书 §8.2 的
跟踪（trace）
调度做的正是这件事。
它顺带解决
"每个条件跳转的
假臂必须紧随其后"
这个机器落地的
格式要求。

本章材料取自
Appel《Modern
Compiler
Implementation
in C》第 8 章
（下称"虎书"），
自包含展开；
配套示例
`examples/14_traces`
实现贪心跟踪线性化，
用"消掉几条跳转"
当收益对账。

## 14.2 规范形态：TAC 已经交卷

虎书的规范 Tree
要求三件事：
每指令单运算、
CALL 不嵌在
表达式里、
无 ESEQ
（表达式内嵌
  语句的记法）。
第 13 章的 TAC
降临时**已经
全中**：

- 单运算：
  `t5 = t3 + t4`
  一条一算——
  常量先落临时
  正是为此；
- 无嵌套调用：
  call 独立成条
  （虎书靠
    "返回值立即
     搬进新临时"
    的改写达成
    同样效果）；
- 无 ESEQ：
  TAC 根本没有
  这个记法——
  表达式与语句
  在类型上就分了家。

所以本章跳过
虎书 8.1 的
ESEQ 消除战役，
直接进 8.2 的
主菜。
（虎书的 ESEQ
  规则——
  "常量与一切
   语句交换"的
  commute 保守
  判定——
  值得一读，
  但对 TAC 谱系
  是历史背景：
  我们的 IR
  生来规范。）

## 14.3 跟踪：可能连续执行的块序列

**跟踪**
（trace）：
一段**可能**
被连续执行的
块序列——
块尾跳到块头、
块尾跳到块头，
一路串下来。
跟踪可以含
条件跳转
（我们不知道
  条件真假，
  但"假设
   某次执行
   走这条路"）。

**覆盖集**：
一组跟踪，
每个块恰好
属于一条——
把整个程序
"覆盖"住。

**虎书
Algorithm 8.3**
（贪心生成覆盖集）：

```
把所有块放进队列 Q。
while Q 非空：
    取队首 b，开一条新跟踪 T
    while b 未标记：
        标记 b；追加到 T
        看 b 的后继里有没有未标记的 c：
            有 → b ← c（跟着跳转走）
            无 → 本条跟踪收尾
```

直觉：
从某块出发，
"顺着跳转
  一直走"，
  走到
  所有后继
  都已被别的
  跟踪收编，
  就收尾换下家。
  走哪条后继？
算法不挑——
任选一条
（我们的实现
  按后继序号
  取第一个，
  保证确定性）。

为什么正确？
覆盖性：
每块入队、
必被某条跟踪
标记一次；
块的全跳转
语义不变：
我们只**摆顺序**，
不动任何
跳转的目标——
目标的重贴
是"新位置下
  同一块的
  新起点"，
  语义等价。

期望输出里
flow.tip 的
跟踪表：

```
T0: 0 1 3 4 5 6 8     ← 主干：入口→判断→else 臂→循环出口→收尾
T1: 2                  ← then 臂（被主跟踪跳过，单独成条）
T2: 7                  ← 循环体（同上）
```

主跟踪 T0
一路"跟着
第一个后继"，
把 else 臂与
出口链全串起来；
then 臂（块 2）
与循环体（块 7）
各自落单。

## 14.4 顺直链：三种终结符的处置

块序定了以后，
逐块看**终结符**
与"新序里下一块"
的关系——
虎书 "finishing up"
的三条规则
（TAC 化）：

设块 b 的终结符，
N = 新序中 b 的
下一块（没有则
  程序尾）：

**规则一（无条件跳转）**：
`goto L` 且
L 的块 == N
⇒ **删除**这条
goto——直落
就到 N，
跳转白给。
这是跟踪的
主要收益源。

**规则二（条件，
  假臂顺直）**：
`if a > b goto L`
的**直落语义**
本来就是
"假了走下一条"。
若 N 恰是
**假臂块**
（原顺序里
  b 的直落后继）
⇒ 保持原样：
真臂跳走、
假臂直落，
两臂全对。

**规则三（条件，
  真臂顺直）**：
若 N 恰是
**真臂块**
（跳转目标）
⇒ **翻转条件**：
换成否定运算
`if a <= b goto 假臂`
——现在
真臂（原目标）
直落、
假（≤）跳走，
两臂依旧全对。
翻转需要
否定条件可用：
这就是本章
本地 TAC 副本
加 `IfLe`（≤）、
`IfNe`（≠）
两条指令的原因
（虎书原话
  "negate the
   condition"）。

**规则四（条件，
  两臂皆不顺直）**：
N 既不是真臂
也不是假臂
（跟踪在此
  换了道）
⇒ 条件跳转后
**补一条显式
goto 假臂**：
真臂跳走、
假臂显式跳、
N 留给别的路。
这是唯一
"添指令"的情形。

实现分两遍：
第一遍做**块级
决策**（下一块
是谁只看覆盖序，
与位置无关）；
第二遍按
"删除短一、
补跳长一"的
**最终长度表**
重贴全部跳转
目标——
一遍写完位置
就不再漂移。

## 14.5 期望输出解读

flow.tip 的
线性化结果
（25 → 23 条）：

```
0–3   直线序幕（两 input）
4     if a > b goto L16        ← 真臂跳去 16（then 臂被挪后）
5–9   else 臂 + y = x + 1      ← 假臂直落：规则二的标准形态
10–11 if a > t7 goto L19       ← 循环判断：体（19）被挪后
12–15 收尾（output/return）    ← 循环出口直落
16–17 then 臂（T1 落位于此）
18    goto L7                  ← 接回汇合点：规则四的显式跳
19–21 循环体（T2）
22    goto L10                 ← 回循环头
```

stats 行：

```
gotosDeleted = 2   flips = 0   fixups = 0
gotos: 4 -> 2
```

四条原 goto
消掉两条：
`goto else`（else 臂
  已直落）与
`goto 出口`（出口
  已直落）。
剩下的两条
是绕不开的：
then 臂跳回汇合、
循环体跳回头。
**指令数 25→23，
跳转数 4→2，
而 outputs
保持 2**——
收益与保义
同时进对账。

then 臂块 2
为什么排在
主跟踪后面
而不是紧跟
块 1？
贪心从块 1 的
后继里选了
**第一个未标记**
（else 臂 3），
then 臂就被
留给了下一条
跟踪——
这正体现
"走哪条后继
不影响正确性、
只影响布局质量"：
若编译器有
 профили
（profile）信息
知道 then 更热，
可以优先跟
热臂——
虎书 8.2 末尾
"optimal traces"
说的就是这件事，
 Fisher 的
 trace scheduling
 是完全体。

## 14.6 工程注意点

- **布局影响
  一切下游**。
  顺序定下来后，
  指令调度
  （第 50 章）
  的块边界、
  预取
  （第 51 章）的
  直落假设、
  甚至反汇编
  可读性都吃
  这碗饭——
  "块序是后端的
   地基"。
- **翻转条件的
  语义边界**。
  翻转只对
  纯比较合法；
  若条件带
  副作用
  （调用、
    自增），
  翻转改变
  求值时机——
  TAC 的比较
  操作数早已
  求值完毕
  （三地址
    单运算律），
  天然安全。
- **跟踪与
  循环**。
  贪心对循环
  不敏感：
  循环体可能
  与入口断开
  （本例 T2
    就落单）。
  优版会把
  回边的头尾
  拉进同一条
  跟踪
  （热路径
    内聚），
  减少迭代内
  跳转——
  虎书图 8.4(c)
  的形态。
- **为什么
  IR 不直接
  定序**：
  优化阶段
  （20–39 章）
  需要自由地
  移动、复制、
  删除块；
  布局是
  **最后一刻**
  的决策，
  放在指令
  选择之前
  一步刚刚好
  （虎书把它
    排在
    instruction
    selection
    之前）。
- **删除跳转的
  对账哲学**。
  "gotos 下降 +
  outputs 不变"
  是本章的
  双证人——
  布局变换的
  正确性没有
  定理可引，
  全靠解释器
  逐值核对；
  这与
  13 章以来的
  一切变换
  同一纪律。

## 14.7 本章配套文件

### 14.7.1 文法 TIP.g4

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

### 14.7.2 新件：trace.hpp 与 trace.cpp

贪心跟踪
（Algorithm 8.3）、
块级四规则决策、
两遍线性化
（最终长度表
  重贴目标）。

```cpp
// file: src/trace.hpp
// file: src/trace.hpp
// 第 14 章配套：贪心跟踪（trace）线性化与顺直链消跳转（虎书 §8.2 Algorithm 8.3）。
// 本示例的 TAC 副本在 13 章指令族上加了 IfLe / IfNe 两个否定条件跳转——
// 翻转 CJUMP 的真假臂必须能写出条件的否定（虎书 “negate the condition”）。
#ifndef TIP_TRACE_HPP
#define TIP_TRACE_HPP

#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 本地指令族扩展：IfLe = a <= b，IfNe = a != b（仅本章使用）。
// 通过给 Quad 的 op 用 TOp 值 + 一个说明表达成；show/interp 在 main 里按章内口径处理。

// 贪心跟踪：把块集划分成若干条 trace（每块恰属一条）。
//   队列取首块开一条 trace；沿“任一未标记后继”延伸；后继全标记则收尾。
struct TracePlan {
    std::vector<std::vector<int>> traces;   // 每条 trace 的块号序列
    std::vector<int> order;                 // 线性化块序（traces 拼接）
};

TracePlan buildTraces(const std::vector<Block> &blocks);

struct LinearResult {
    std::vector<Quad> code;
    int gotosDeleted = 0;   // 无条件跳转被顺直链吞掉
    int flips = 0;          // 条件翻转（真假臂对调，用否定运算）
    int fixups = 0;         // 两臂都不顺直：补显式 goto
};

// 线性化 + 终结符重写：
//   Goto 的目标恰为下一块起点 ⇒ 删；
//   条件跳转的“假臂”（原顺序直落块）恰为下一块 ⇒ 保持；
//   真臂恰为下一块 ⇒ 翻转条件、跳假臂；
//   两臂都不顺直 ⇒ 条件跳转后补显式 goto 假臂。
LinearResult linearize(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                       const TracePlan &plan);

}  // namespace tip

#endif  // TIP_TRACE_HPP
```

```cpp
// file: src/trace.cpp
// file: src/trace.cpp
// 第 14 章配套：跟踪线性化实现（两遍：块级决策 → 按最终位置重贴目标）。
#include "trace.hpp"

#include <map>
#include <set>

namespace tip {

TracePlan buildTraces(const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    TracePlan plan;
    std::vector<bool> marked(n, false);
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    // Algorithm 8.3：队列按块号（确定性）；沿任一未标记后继延伸。
    for (size_t start = 0; start < n; ++start) {
        int b = static_cast<int>(start);
        if (marked[b]) continue;
        std::vector<int> trace;
        while (!marked[b]) {
            marked[b] = true;
            trace.push_back(b);
            int next = -1;
            for (int c : adj[b])
                if (!marked[c]) { next = c; break; }
            if (next < 0) break;
            b = next;
        }
        plan.traces.push_back(trace);
        plan.order.insert(plan.order.end(), trace.begin(), trace.end());
    }
    return plan;
}

LinearResult linearize(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                       const TracePlan &plan) {
    size_t n = blocks.size();
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    auto blockAt = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (blocks[k].begin == idx) return static_cast<int>(k);
        return -1;
    };
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return static_cast<int>(k);
        return -1;
    };
    // 每块的终结符信息（只在块尾一条）
    struct Term {
        bool isGoto = false, isCond = false;
        int trueBlock = -1;    // Goto：目标块；条件：真臂块
        int fallBlock = -1;    // 条件：原直落块（假臂）
    };
    std::vector<Term> term(n);
    for (size_t b = 0; b < n; ++b) {
        const Quad &q = code[blocks[b].end - 1];
        if (q.op == TOp::Goto) {
            term[b].isGoto = true;
            term[b].trueBlock = blockAt(q.target);
        } else if (q.op == TOp::IfGt || q.op == TOp::IfEq) {
            term[b].isCond = true;
            term[b].trueBlock = blockAt(q.target);
            term[b].fallBlock = blockOf(blocks[b].end);
        }
    }
    // 第一遍：块级决策（只看“新序里下一块是谁”，与位置无关）
    enum class Act { Keep, Delete, Flip, Fixup };
    std::vector<Act> act(n, Act::Keep);
    LinearResult res;
    for (size_t oi = 0; oi < plan.order.size(); ++oi) {
        int b = plan.order[oi];
        int next = oi + 1 < plan.order.size() ? plan.order[oi + 1] : -1;
        if (term[b].isGoto) {
            if (term[b].trueBlock == next && next >= 0) {
                act[b] = Act::Delete;
                ++res.gotosDeleted;
            }
        } else if (term[b].isCond) {
            if (term[b].fallBlock == next) {
                act[b] = Act::Keep;            // 假臂恰为下一块
            } else if (term[b].trueBlock == next) {
                act[b] = Act::Flip;            // 真臂是下一块：翻条件跳假臂
                ++res.flips;
            } else {
                act[b] = Act::Fixup;           // 两臂皆不顺直
                ++res.fixups;
            }
        }
    }
    // 第二遍：最终位置表（Delete 短 1、Fixup 长 1）→ 发射并重贴目标
    std::map<int, int> pos;
    int cursor = 0;
    for (int b : plan.order) {
        pos[b] = cursor;
        int len = blocks[b].end - blocks[b].begin;
        if (act[b] == Act::Delete) --len;
        if (act[b] == Act::Fixup) ++len;
        cursor += len;
    }
    auto newTarget = [&](int blk) { return blk >= 0 && pos.count(blk) ? pos[blk] : -1; };
    std::vector<Quad> out;
    for (size_t oi = 0; oi < plan.order.size(); ++oi) {
        int b = plan.order[oi];
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            Quad q = code[i];
            if (i == blocks[b].end - 1) {
                if (act[b] == Act::Delete) continue;
                if (q.op == TOp::Goto) {
                    q.target = newTarget(term[b].trueBlock);
                } else if (q.op == TOp::IfGt || q.op == TOp::IfEq) {
                    if (act[b] == Act::Flip) {
                        q.op = q.op == TOp::IfGt ? TOp::IfLe : TOp::IfNe;
                        q.target = newTarget(term[b].fallBlock);
                    } else {
                        q.target = newTarget(term[b].trueBlock);
                        if (act[b] == Act::Fixup) {
                            out.push_back(q);
                            Quad g{TOp::Goto, "", "", "", newTarget(term[b].fallBlock)};
                            out.push_back(g);
                            continue;
                        }
                    }
                }
            }
            out.push_back(q);
        }
    }
    res.code = std::move(out);
    return res;
}

}  // namespace tip
```

### 14.7.3 改件：tacgen 与 tacinterp（本地副本）

加 IfLe（≤）与
IfNe（≠）——
翻转条件的前提。

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
                 Goto, IfGt, IfEq, IfLe, IfNe };
// IfLe = a <= b、IfNe = a != b：跟踪章为“翻转条件”补的否定运算（虎书 §8.2）。

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
    case TOp::IfLe:   os << "if " << q.a << " <= " << q.b << " goto L" << q.target; break;
    case TOp::IfNe:   os << "if " << q.a << " != " << q.b << " goto L" << q.target; break;
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
        case TOp::IfLe:   pc = rd(q.a) <= rd(q.b) ? q.target : pc + 1; break;
        case TOp::IfNe:   pc = rd(q.a) != rd(q.b) ? q.target : pc + 1; break;
        }
    }
    return r;
}

}  // namespace tip
```

### 14.7.4 驱动 main.cpp

跟踪表、线性化、
跳转计数、对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 14 章驱动：--check FILE
//   TAC → 块 → 贪心跟踪表 → 线性化（消跳/翻转/补跳计数）→
//   跳转数前后对比 → 解释器 outputs 对账。
#include "trace.hpp"
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

    tip::TracePlan plan = tip::buildTraces(blocks);
    std::cout << "== traces ==\n";
    for (size_t k = 0; k < plan.traces.size(); ++k) {
        std::cout << "  T" << k << ":";
        for (int b : plan.traces[k]) std::cout << ' ' << b;
        std::cout << '\n';
    }

    tip::LinearResult lin = tip::linearize(code, blocks, plan);
    std::cout << "== after traces ==\n";
    for (size_t i = 0; i < lin.code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(lin.code[i]) << '\n';

    int jumpsBefore = 0, jumpsAfter = 0;
    for (const auto &q : code)
        if (q.op == tip::TOp::Goto) ++jumpsBefore;
    for (const auto &q : lin.code)
        if (q.op == tip::TOp::Goto) ++jumpsAfter;
    std::cout << "== stats ==\n";
    std::cout << "  gotosDeleted = " << lin.gotosDeleted
              << "  flips = " << lin.flips
              << "  fixups = " << lin.fixups << '\n';
    std::cout << "  instructions: " << code.size() << " -> " << lin.code.size() << '\n';
    std::cout << "  gotos: " << jumpsBefore << " -> " << jumpsAfter << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::tacInterp(code, {3, 1}).outputs;   // a=3, b=1
    std::vector<int> after = tip::tacInterp(lin.code, {3, 1}).outputs;
    std::cout << "  outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before == after ? "yes" : "NO") << '\n';
    return (before == after && jumpsAfter <= jumpsBefore) ? 0 : 1;
}
```

### 14.7.5 基座：tacblocks 与前端

第 13、8、10 章
原样。

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

### 14.7.6 程序与期望输出

```text
// file: programs/flow.tip
main() {
  var a, b, x, y;
  a = input;
  b = input;
  if (a > b) x = 1; else x = 2;
  y = x + 1;
  while (a > 0) a = a - 1;
  output y + a;
  return 0;
}
```

```text
; expected: expected/output.txt
== flow.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: t2 = input
  3: b = t2
  4: if a > b goto L6
  5: goto L9
  6: t3 = 1
  7: x = t3
  8: goto L11
  9: t4 = 2
  10: x = t4
  11: t5 = 1
  12: t6 = x + t5
  13: y = t6
  14: t7 = 0
  15: if a > t7 goto L17
  16: goto L21
  17: t8 = 1
  18: t9 = a - t8
  19: a = t9
  20: goto L14
  21: t10 = y + a
  22: output t10
  23: t11 = 0
  24: return t11
== blocks ==
  B0 [0,5) succs: 5 6
  B1 [5,6) succs: 9
  B2 [6,9) succs: 11
  B3 [9,11) succs: 11
  B4 [11,14) succs: 14
  B5 [14,16) succs: 16 17
  B6 [16,17) succs: 21
  B7 [17,21) succs: 14
  B8 [21,25) succs:
== traces ==
  T0: 0 1 3 4 5 6 8
  T1: 2
  T2: 7
== after traces ==
  0: t1 = input
  1: a = t1
  2: t2 = input
  3: b = t2
  4: if a > b goto L16
  5: t4 = 2
  6: x = t4
  7: t5 = 1
  8: t6 = x + t5
  9: y = t6
  10: t7 = 0
  11: if a > t7 goto L19
  12: t10 = y + a
  13: output t10
  14: t11 = 0
  15: return t11
  16: t3 = 1
  17: x = t3
  18: goto L7
  19: t8 = 1
  20: t9 = a - t8
  21: a = t9
  22: goto L10
== stats ==
  gotosDeleted = 2  flips = 0  fixups = 0
  instructions: 25 -> 23
  gotos: 4 -> 2
== 对账 ==
  outputs: 2
  outputs preserved: yes
```

## 14.8 小结与练习

本章把"块序"
从一个随意决策
变成一次
有账可查的优化：

- 跟踪 =
  可能连续执行的
  块序列，
  贪心 Algorithm 8.3
  生成覆盖集；
- 四规则处置
  终结符：
  顺直删跳、
  假臂保持、
  真臂翻转
  （要否定运算）、
  都不顺直补显式跳；
- 两遍实现：
  块级决策先定
  性、最终长度表
  再定量——
  位置漂移的
  经典防治；
- gotos 4→2、
  outputs 不变，
  收益保义双证。

下一章进
运行时世界：
活动记录给
函数调用安家。

练习：

1. 手工对 flow.tip
   跑 Algorithm 8.3，
   复现三条跟踪的
   块序；
   再逐块套四规则，
   与线性化输出
   对照。
2. 把贪心的
   "第一个未标记
    后继"改成
   "最后一个"，
   重跑：
   跟踪形状变吗？
   gotos 数变吗？
3. 构造一个
   触发规则三
   （真臂顺直、
    条件翻转）
   的程序
   （提示：
    让贪心跟到
    then 臂——
    把 then 写在
    else 前面并
    让块号顺序
    有利），
   观察 flips ≥ 1
   的输出。
4. 实现"回边
   优先"：后继
   选择时优先
   回边目标
   （循环头），
   在带 while 的
   程序上对比
   迭代内跳转数。
5. （较大）
   把线性化输出
   喂给第 49 章
   的指令选择：
   验证直落形态
   （规则二）不再
   生成显式跳转
   指令——
   两章衔接的
   端到端对账。
