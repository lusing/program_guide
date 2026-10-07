# 第 42 章　控制依赖与 SSA 往返：分岔的骨架与回家的路

## 42.1 问题：谁听谁的，以及怎么回去

第 41 章把程序
搬进了 SSA——
但有两件事
没做完：

1. **分岔的结构**
   还埋在 CFG 里。
   "B1 的执行与否
    取决于 B0 的
    条件"——
   这种**控制依赖**
   关系是一类
   优化的直接燃料
   （if 变换、
     条件常量、
    投机执行），
   值得一张显式的图；
2. **SSA 是单程票**：
   寄存器分配
   （第 61 章）与
   大多数真机
   不认 φ。
   优化做完要
   **拆回去**——
   而拆 φ 有个
   著名的坑
   （并行复制）。

本章一次做完
两件事
（虎书 §19.5–19.6）：
**后支配者** →
**控制依赖图
（CDG）**；
**SSA 退出**
（φ 拆解 +
并行复制的
环处理）。
顺带用一小节
讲虎书 §19.7 的
函数式 IR
（思想不实现）。

配套示例
`examples/42_cdg`
在 TAC 上实现
全套，
验收线是
**三方对账**：
原 TAC、
SSA、
拆回的 TAC
三个解释器
outputs
逐值相等
（tAC==ssa==back）。

## 42.2 后支配：支配的镜像

**后支配**
（post-dominance）
是支配的
时间倒影：
d 后支配 b，
如果每条
**从 b 到出口**
的路径都
经过 d。

方程与 33 章
完全同型，
只是"入口/前驱"
换成
"出口/后继"：

```
pdom[exit] = {exit}
pdom[b]    = {b} ∪ ⌂ pdom[s]     （s 取遍 b 的后继）
```

初值全集、
迭代取交、
单调收缩——
同一台不动点
机器的
又一次通电。
（工程实现里
"倒序一遍支配"
即得：
把边全部反向、
出口当入口，
跑 33 章
Cooper–Harvey–Kennedy；
我们的教学版
直接按上式
迭代。）

期望输出
（cfg.tip，
八块：
判断 + while）：

```
pdom(B7) = {7}           ← 出口只后支配自己
pdom(B5) = {5,7}         ← 收尾块：到出口必经自己
pdom(B1) = {1,3,4,5,7}   ← then 臂：出口必经 else 跳板与循环
```

读一条：
B1（then 臂）
到出口要过
B3（else 跳板）
——因为 then
臂跳到汇合，
而"汇合"在
TAC 里是
else 路的
goto 目标。
图不会说谎。

**ipdom**
（直接后支配者）
同样存在且
构成**后支配树**——
它是 CDG
构造的阶梯。

## 42.3 控制依赖图：FOW 算法

**n 控制依赖 c**
（记 n →cd c）：

> c 的某个后继
> 被 n 后支配，
> 而 n 不
> 严格后支配 c。

直觉：
c 是分岔点
（条件判断），
n 是"只有
  c 的某条臂
  选中了才会
  执行"的块；
n 未必在
c 的任何
一条到出口的
必经路上
（它可能
  根本不执行），
但它执行与否
**由 c 裁决**。

**Ferrante–
Ottenstein–
Warren 算法**
（与支配边界的
CHK 算法
惊人同型）：

```
对每条边 c → s：
    runner 从 s 出发沿后支配树上行，
    直到 runner 后支配 c（runner ∈ pdom[c]）：
        途经每个节点都记“依赖 c”
```

为什么对？
runner 沿
后支配树
从 s 上行，
恰好经过
"后支配 s
但**不**后支配
c"的所有节点
——这正是
控制依赖的
定义。
CHK 沿**支配**
树上行管
**汇合**，
FOW 沿**后支配**
树上行管
**分岔**：
一枚硬币
的两面。

期望输出：

```
B1 依赖 B0     ← then 臂听命于 if 判断
B2 依赖 B0     ← 判断跳板
B3 依赖 B0     ← else 跳板
B6 依赖 B4     ← 循环体听命于循环头
```

B5（收尾）
不依赖任何人：
无论怎么分岔，
它**必经**
（被 B4 后支配），
没有"听命"
可言——
必经者无主，
分岔者无定。

**CDG 的用途**
（正文点到、
练习展开）：
if-conversion
（用 select/条件
  移动把分支
  拉平）、
条件常量传播
（SCCP 的
  执行条件沿
  CDG 传播）、
投机执行
（把控制依赖的
  块提前算、
  错了丢弃）。
PTA（程序依赖图）
= CDG ∪ 数据依赖，
指令级并行的
老地基。

## 42.4 SSA 退出：φ 的三笔账

**问题**：
把每个 φ
`x = φ(a₁,…,aₙ)`
（前驱 p₁…pₙ）
拆成"在前驱
pᵢ 的块尾
插复制
x = aᵢ"。

**第一笔账
（位置）**：
复制必须在
前驱块的
**尾部、
跳转之前**
——φ 的语义
是"沿这条边
  进来时取
  这条边的值"，
块中间的值
可能还没算。
开发本示例时
实踩此坑：
账发在块首，
else 块的
`b2 = b1`
抢在
`b1 = a + 1`
之前执行，
解释器当场
吐"读未初始化"。

**第二笔账
（并行语义）**：
同一块尾的
多个复制是
**并行**的：

```
x = y
y = x     ← 并行：互换！
```

顺序执行会
把两个都变成
y 的旧值。
**串行化规则**：
若某名字同时
出现在左端
（它要被写）
和右端
（它要被读），
先把它搬进
临时：

```
t = x
x = y
y = t
```

虎书 §19.6
称之为
**critical
edge 之外**
最容易踩的
坑（swap 问题）。
本示例的
`swaps = 1`
就是一处环
被临时断开
的实录。

**第三笔账
（目标重贴）**：
块内加行
改变全部
下标——
老朋友了
（26 章删除、
  37 章外提、
  14 章线性化，
  三处同款纪律）。
本示例按
"最终长度表"
先定位后发射。

**⊥ 名**：
φ 的首入参
可能是改名器
标的未定值名
（`vu` 形态），
拆解时落成
常量 0——
与第 56 章
"全 0 初值"
口径一致。

## 42.5 期望输出解读

cfg.tip 的
SSA 退出段
（55 条，
原 TAC 33 条）：

- `copies = 27`：
  八个 φ
  （未修剪 SSA
    给 t 系
    也插了）
  乘前驱数
  累加；
- `swaps = 1`：
  循环头处
  存在
  a↔t 之类的
  环形复制，
  被临时断开；
- 对账段：

```
tac   : 10
ssa   : 10
back  : 10
tac==ssa==back: yes
```

**10 = 5×2 + 0**
（input=5：
then 臂取
5*2=10、
循环 5 圈
减到 0）。
三方逐值相等：
构造
（34 章）与
拆解（本章）
都是保义变换，
证人一票通过。

指令数
33 → 55 的
膨胀主要来自
t 系 φ 的
复制——
这正是
**修剪 SSA**
（34 章练习三、
LLVM mem2reg
的实战形态）
要消的东西：
不活跃就别插 φ，
拆回去也就
没这笔账。

## 42.6 函数式 IR：一页纸的亲戚

虎书 §19.7
给 SSA 介绍
一位"函数式"
表亲：
把每个基本块
看作一个
**函数**，
块尾跳转是
**尾调用**，
φ 参数是
**形参**——

```
B1(x0, y0) {
    ...
    if (a > b) return B2(x1, y0) else return B3(x0, y1)
}
```

CPS
（continuation-
passing style）
是它的完全体。
为什么在意？

- φ 的并行
  语义在函数
  调用语义下
  **免费**：
  实参求值
  本来就在
  绑定形参
  之前全部
  完成；
- 函数式的
  一等公民
  地位让
  "块"可以像
  值一样被
  内联、复制、
  重组——
  ANF/CPS
  中端
  （MLton、
    Racket 的
    家底）的
  立身之本。

我们的
TAC + φ
是这套思想的
命令式投影；
知道血缘，
读现代函数式
编译器不再
迷路。

## 42.7 工程注意点

- **CDG 与
  支配边界
  是对偶**。
  33 章的 DF
  服务 φ 插入
  （必经结构里
    找汇合），
  本章的 CDG
  服务条件分析
  （分岔结构里
    找裁决者）。
  两张图都从
  "树上行走"
  线性时间构造——
  结构计算的
  美，一个
  模子两件产品。
- **拆 φ 与
  关键边**。
  若前驱块
  有多个后继、
  后继块有
  多个前驱
  （critical
  edge），
  复制插在
  前驱尾会
  **污染别的
  后继**。
  通用解：
  先分裂
  关键边。
  TIP 的
  if 模板
  自带跳板块，
  大多数边
  天然安全。
- **破坏性
  退出**。
  工业编译器
  常不显式拆：
  LLVM 的
  寄存器分配
  直接消费 φ
  （parallel
  copy 在
  分配器内部
  化解）；
  显式拆解
  出现在
  要导出
  非 SSA 的
  场景。
- **CDG 的
  一致性检验**。
  本示例的
  CDG 没有
  独立对账——
  FOW 输出的
  边集就是
  定义式遍历。
  练习二给
  "按定义
  逐块暴力复核"
  的机器证人
  方案。

## 42.8 本章配套文件

### 42.8.1 文法 TIP.g4

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

### 42.8.2 新件：cdg.hpp 与 cdg.cpp

后支配迭代、
FOW 控制依赖、
SSA 退出
（块尾结算 +
  环临时 +
  目标重贴）。

```cpp
// file: src/cdg.hpp
// file: src/cdg.hpp
// 第 42 章配套：后支配者、控制依赖图（CDG）、SSA 退出（虎书 §19.5–19.6）。
#ifndef TIP_CDG_HPP
#define TIP_CDG_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "dom.hpp"
#include "ssa.hpp"

namespace tip {

// ---------- 后支配（pdom）：逆图上的支配 ----------
// pdom[b] = { d | 每条 b→exit 的路径都经过 d }。出口块的角色同入口。
// 实现：把邻接表反转（后继变前驱），出口块当“入口”，复用 33 章迭代。
// 出口块 = 无后继的块（多个则各算一份——教学程序单出口）。
DomInfo postDominators(const std::vector<std::vector<int>> &adj);

// ---------- 控制依赖图（CDG，Ferrante-Ottenstein-Warren） ----------
// 节点 n 控制依赖 c ⟺
//   (a) c 有后继 s 使 n ∈ pdom[s]（n 后支配某个 c 的后继），且
//   (b) n ∉ strict_pdom[c]（n 不严格后支配 c 本身）。
// 实现遍历每条边 c→s，从 s 沿 pdom 链上行到首个后支配 c 的节点止，
// 途经皆控制依赖 c（与支配边界的 CHK 同型！）。
struct CdgInfo {
    std::vector<std::set<int>> preds;   // 每块的 CDG 前驱（它依赖谁）
    std::vector<std::set<int>> succs;   // 每块的 CDG 后继（谁依赖它）
};

CdgInfo controlDependence(const std::vector<std::vector<int>> &adj, const DomInfo &pdom);

// ---------- SSA 退出（虎书 §19.6）：φ 拆成前驱块尾的复制 ----------
// 并行复制 → 串行：若有环（x↔y 互换），用临时断环。
// 返回非 SSA 的 TAC（跳转目标重贴），供解释器对账。
struct SsaBackResult {
    std::vector<Quad> code;
    int copies = 0;        // 拆出的复制数
    int swaps = 0;         // 用临时断环的环数
};

SsaBackResult ssaBack(const SsaProgram &ssa);

}  // namespace tip

#endif  // TIP_CDG_HPP
```

```cpp
// file: src/cdg.cpp
// file: src/cdg.cpp
// 第 42 章配套：后支配、控制依赖、SSA 退出实现。
#include "cdg.hpp"

namespace tip {

DomInfo postDominators(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    // 出口块（无后继者；教学程序单出口）
    std::vector<int> exits;
    for (size_t b = 0; b < n; ++b)
        if (adj[b].empty()) exits.push_back(static_cast<int>(b));
    // 迭代：pdom[exit]={exit}；pdom[b]={b} ∪ ⌂ pdom[s∈后继]。
    // 与 33 章支配同骨架，方向相 反：交的角色对“往后走”的后继取。
    std::set<int> all;
    for (size_t k = 0; k < n; ++k) all.insert(static_cast<int>(k));
    DomInfo di;
    di.dom.assign(n, all);
    for (int e : exits) di.dom[e] = {e};
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 0; b < n; ++b) {
            bool isExit = false;
            for (int e : exits)
                if (e == static_cast<int>(b)) isExit = true;
            if (isExit) continue;
            std::set<int> acc = all;
            for (int s : adj[b]) {
                std::set<int> keep;
                for (int x : acc)
                    if (di.dom[s].count(x)) keep.insert(x);
                acc = keep;
            }
            acc.insert(static_cast<int>(b));
            if (acc != di.dom[b]) {
                di.dom[b] = acc;
                changed = true;
            }
        }
    }
    // idom（此处即“直接后支配者”）：严格后支配者中最贴近的
    di.idom.assign(n, -1);
    for (size_t b = 0; b < n; ++b) {
        int best = -1;
        size_t bestSize = 0;
        for (int d : di.dom[b]) {
            if (d == static_cast<int>(b)) continue;
            if (di.dom[d].size() >= bestSize) {
                bestSize = di.dom[d].size();
                best = d;
            }
        }
        di.idom[b] = best;
    }
    di.children.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        if (di.idom[b] >= 0) di.children[di.idom[b]].push_back(static_cast<int>(b));
    return di;
}

CdgInfo controlDependence(const std::vector<std::vector<int>> &adj, const DomInfo &pdom) {
    size_t n = adj.size();
    CdgInfo cdg;
    cdg.preds.assign(n, {});
    cdg.succs.assign(n, {});
    // Ferrante–Ottenstein–Warren：对每条边 c→s，
    // runner 从 s 沿后支配树上行到“后支配 c”为止，途经节点都控制依赖 c。
    // 与支配边界（CHK）完全同型——一个沿支配树上行管“汇合”，
    // 一个沿后支配树上行管“分岔”。
    for (size_t c = 0; c < n; ++c) {
        for (int s : adj[c]) {
            int runner = s;
            while (runner >= 0) {
                if (runner == static_cast<int>(c)) break;             // c 后支配自己：到站
                if (pdom.dom[c].count(runner)) break;                 // runner 严格后支配 c：到站
                cdg.preds[runner].insert(static_cast<int>(c));        // runner 依赖 c
                cdg.succs[c].insert(runner);                          // c 支配 runner
                runner = pdom.idom[runner];
            }
        }
    }
    return cdg;
}

SsaBackResult ssaBack(const SsaProgram &ssa) {
    SsaBackResult res;
    size_t n = ssa.blocks.size();
    // φ 拆账：前驱 p 的块尾要交的复制（dst, arg）
    std::vector<std::vector<std::pair<std::string, std::string>>> bills(n);
    for (size_t b = 0; b < n; ++b)
        for (const auto &inst : ssa.blocks[b].body) {
            if (inst.phiArgs.empty()) continue;
            for (size_t p = 0; p < ssa.preds[b].size(); ++p)
                bills[ssa.preds[b][p]].push_back({inst.dst, inst.phiArgs[p]});
        }
    // 并行复制串行化：右值 ∩ 左值 = 环名 → 先搬临时（虎书 §19.6 的 swap 问题）
    auto clashOf = [&](size_t b) {
        std::set<std::string> dsts, srcs, clash;
        for (const auto &kv : bills[b]) {
            dsts.insert(kv.first);
            srcs.insert(kv.second);
        }
        for (const auto &d : dsts)
            if (srcs.count(d)) clash.insert(d);
        return clash;
    };
    // 最终长度表（块内加行 ⇒ 目标重贴要不漂移）
    std::vector<int> len(n, 0);
    for (size_t b = 0; b < n; ++b) {
        int phiCount = 0;
        for (const auto &inst : ssa.blocks[b].body)
            if (!inst.phiArgs.empty()) ++phiCount;
        len[b] = static_cast<int>(ssa.blocks[b].body.size()) - phiCount
                 + static_cast<int>(bills[b].size())
                 + static_cast<int>(clashOf(b).size());
    }
    std::vector<int> pos(n, 0);
    int cursor = 0;
    for (size_t b = 0; b < n; ++b) {
        pos[b] = cursor;
        cursor += len[b];
    }
    // 发射：先结算前驱账（环名走临时），再发原体（φ 略去），目标重贴
    std::vector<Quad> out;
    for (size_t b = 0; b < n; ++b) {
        // 顺序：体（除终结符）→ φ 账（含环临时）→ 终结符。
        // 账必须在块尾、跳转之前结算：φ 实参读的是块出口处的值，
        // 放块首会读到本块体还没写的新值（开发时踩过的实坑）。
        const SsaInst *term = nullptr;
        for (const auto &inst : ssa.blocks[b].body) {
            if (!inst.phiArgs.empty()) continue;
            if (inst.op == TOp::Goto || inst.op == TOp::IfGt || inst.op == TOp::IfEq) {
                term = &inst;
                continue;
            }
            Quad q;
            q.op = inst.op;
            q.dst = inst.dst;
            q.a = inst.a;
            q.b = inst.b;
            out.push_back(q);
        }
        auto clash = clashOf(b);
        std::map<std::string, std::string> shadow;
        if (!clash.empty()) {
            ++res.swaps;
            for (const auto &d : clash) {
                shadow[d] = "sb" + std::to_string(res.swaps) + "_" + d;
                out.push_back(Quad{TOp::Copy, shadow[d], d, "", -1});
            }
        }
        for (const auto &kv : bills[b]) {
            std::string src = kv.second;
            if (clash.count(src)) src = shadow[src];
            if (!src.empty() && src.back() == 'u') src = "0";   // ⊥ 名按全 0 初值
            out.push_back(Quad{TOp::Copy, kv.first, src, "", -1});
            ++res.copies;
        }
        if (term) {
            Quad q;
            q.op = term->op;
            q.dst = term->dst;
            q.a = term->a;
            q.b = term->b;
            q.target = pos[term->target];   // SSA 的 target 是块号
            out.push_back(q);
        }
    }
    res.code = std::move(out);
    return res;
}

}  // namespace tip
```

### 42.8.3 改件：ssa.hpp 与 ssa.cpp（本地副本）

ssaRun 支持
input 流
（对账证人
  升级为
  可喂输入）。

```cpp
// file: src/ssa.hpp
// file: src/ssa.hpp
// 第 41 章配套：支配边界（CHK）、φ 插入、支配树改名——SSA 构造全套。
#ifndef TIP_SSA_HPP
#define TIP_SSA_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "dom.hpp"

namespace tip {

// ---------- 支配边界（Cooper–Harvey–Kennedy） ----------
// DF[b] = { c | b 支配 c 的某个前驱，但 b 不严格支配 c }。
// 直觉：“b 的影响沿支配树下行，DF 是它‘管不到’却‘够得着’的汇合点”。
std::vector<std::set<int>> dominanceFrontiers(const std::vector<std::vector<int>> &adj,
                                              const DomInfo &di,
                                              const std::vector<std::set<int>> &preds);

// ---------- SSA ----------
struct SsaInst {
    TOp op = TOp::Copy;
    std::string dst, a, b;
    int target = -1;                    // 跳转目标 = 块号
    std::vector<std::string> phiArgs;   // φ 专用：按前驱次序的实参
};

struct SsaBlock {
    std::vector<SsaInst> body;          // φ 在最前
};

struct SsaProgram {
    std::vector<SsaBlock> blocks;
    std::vector<std::vector<int>> preds;   // 每块前驱（块号，定序）
};

// 构造：φ 插入（iterated DF 的不动点）+ 支配树先序改名（版本栈）。
// 单定值自检：每个 SSA 名字恰好定义一次（返回 false 即违例）。
SsaProgram buildSsa(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                    bool &singleDefOk);

std::string show(const SsaInst &q);

// ---------- SSA 解释器（对账证人；本地副本支持 input 流） ----------
std::vector<int> ssaRun(const SsaProgram &p, const std::vector<int> &inputs = {});

}  // namespace tip

#endif  // TIP_SSA_HPP
```

```cpp
// file: src/ssa.cpp
// file: src/ssa.cpp
// 第 41 章配套：SSA 构造与解释实现。
#include "ssa.hpp"

#include <cctype>
#include <deque>
#include <functional>
#include <sstream>
#include <stdexcept>

namespace tip {

namespace {
bool isNumS(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarS(const std::string &s) { return !s.empty() && !isNumS(s); }
bool defInstrS(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

std::vector<std::set<int>> dominanceFrontiers(const std::vector<std::vector<int>> &adj,
                                              const DomInfo &di,
                                              const std::vector<std::set<int>> &preds) {
    size_t n = adj.size();
    std::vector<std::set<int>> df(n);
    // CHK：只看汇合点（前驱 ≥ 2）。runner 从每个前驱沿 idom 上行，
    // 直到碰到 idom[c]——沿途每站都把 c 记入 DF。
    for (size_t c = 0; c < n; ++c) {
        if (preds[c].size() < 2) continue;
        for (int p : preds[c]) {
            int runner = p;
            while (runner >= 0 && runner != di.idom[c]) {
                df[runner].insert(static_cast<int>(c));
                runner = di.idom[runner];
            }
        }
    }
    return df;
}

std::string show(const SsaInst &q) {
    std::ostringstream os;
    if (!q.phiArgs.empty()) {
        os << q.dst << " = phi(";
        for (size_t k = 0; k < q.phiArgs.size(); ++k)
            os << (k ? ", " : "") << q.phiArgs[k];
        os << ")";
        return os.str();
    }
    switch (q.op) {
    case TOp::Copy:   os << q.dst << " = " << q.a; break;
    case TOp::Add:    os << q.dst << " = " << q.a << " + " << q.b; break;
    case TOp::Sub:    os << q.dst << " = " << q.a << " - " << q.b; break;
    case TOp::Mul:    os << q.dst << " = " << q.a << " * " << q.b; break;
    case TOp::Div:    os << q.dst << " = " << q.a << " / " << q.b; break;
    case TOp::Gt:     os << q.dst << " = " << q.a << " > " << q.b; break;
    case TOp::Eq:     os << q.dst << " = " << q.a << " == " << q.b; break;
    case TOp::Output: os << "output " << q.a; break;
    case TOp::Ret:    os << "return " << q.a; break;
    case TOp::Goto:   os << "goto B" << q.target; break;
    case TOp::IfGt:   os << "if " << q.a << " > " << q.b << " goto B" << q.target; break;
    case TOp::IfEq:   os << "if " << q.a << " == " << q.b << " goto B" << q.target; break;
    case TOp::Input:  os << q.dst << " = input"; break;
    }
    return os.str();
}

SsaProgram buildSsa(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                    bool &singleDefOk) {
    size_t n = blocks.size();
    // 块邻接与前驱（定序）
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    std::vector<std::vector<int>> preds(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : adj[b]) preds[s].push_back(static_cast<int>(b));

    DomInfo di = dominators(adj);
    auto predsSet = predsOf(adj);
    std::vector<std::set<int>> df = dominanceFrontiers(adj, di, predsSet);

    // ---------- φ 插入 ----------
    // 变量 → 定值块集合；iterated DF 的不动点；φ 挂块头。
    std::map<std::string, std::set<int>> defBlocks;
    std::set<std::string> vars;
    for (const auto &q : code) {
        if (isVarS(q.dst)) vars.insert(q.dst);
        if (isVarS(q.a)) vars.insert(q.a);
        if (isVarS(q.b)) vars.insert(q.b);
    }
    for (int i = 0; i < static_cast<int>(code.size()); ++i)
        if (defInstrS(code[i]) && isVarS(code[i].dst))
            for (size_t b = 0; b < n; ++b)
                if (i >= blocks[b].begin && i < blocks[b].end)
                    defBlocks[code[i].dst].insert(static_cast<int>(b));
    std::map<std::pair<int, std::string>, bool> hasPhi;   // (块, 变量)
    for (const auto &v : vars) {
        std::deque<int> work(defBlocks[v].begin(), defBlocks[v].end());
        std::set<int> enqueued(work.begin(), work.end());
        while (!work.empty()) {
            int b = work.front();
            work.pop_front();
            for (int c : df[b]) {
                if (!hasPhi[{c, v}]) {
                    hasPhi[{c, v}] = true;
                    if (!enqueued.count(c)) {
                        enqueued.insert(c);
                        work.push_back(c);   // φ 本身是新定值，其 DF 也要传播
                    }
                }
            }
        }
    }

    // ---------- 改名（支配树先序 + 版本栈） ----------
    std::map<std::string, int> counter;          // 变量 → 下一版本号
    std::map<std::string, std::vector<std::string>> stack;   // 变量 → 版本名栈
    auto freshName = [&](const std::string &v) {
        int k = counter[v]++;
        std::string name = v + std::to_string(k);
        stack[v].push_back(name);
        return name;
    };
    auto curName = [&](const std::string &v) -> std::string {
        auto it = stack.find(v);
        if (it == stack.end() || it->second.empty()) return v + "u";   // u = 未定义（⊥）
        return it->second.back();
    };
    SsaProgram out;
    out.blocks.resize(n);
    out.preds = preds;

    // 先给每块的 φ 占位（目标名先定，实参改名时回填）
    std::map<std::pair<int, std::string>, size_t> phiSlot;
    for (size_t b = 0; b < n; ++b)
        for (const auto &v : vars)
            if (hasPhi[{static_cast<int>(b), v}]) {
                SsaInst phi;
                phi.dst = v + "#phi";   // 临时占位，改名时替换
                out.blocks[b].body.push_back(phi);
                phiSlot[{static_cast<int>(b), v}] = out.blocks[b].body.size() - 1;
            }

    std::function<void(int)> renameBlock = [&](int b) {
        std::vector<std::string> pushed;   // 本块压栈的名字（离开时弹出）
        // φ 目标先改名（φ 是本块第一条“定值”）
        for (const auto &v : vars)
            if (hasPhi[{b, v}]) {
                size_t slot = phiSlot.at({b, v});
                out.blocks[b].body[slot].dst = freshName(v);
                pushed.push_back(v);
            }
        auto renameUse = [&](std::string &x) {
            if (isVarS(x)) x = curName(x);
        };
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            SsaInst si;
            si.op = code[i].op;
            si.a = code[i].a;
            si.b = code[i].b;
            si.dst = code[i].dst;
            si.target = code[i].target;
            renameUse(si.a);
            renameUse(si.b);
            if (defInstrS(code[i]) && isVarS(si.dst)) {
                si.dst = freshName(si.dst);
                pushed.push_back(code[i].dst);
            }
            // 跳转目标换块号
            if (si.op == TOp::Goto || si.op == TOp::IfGt || si.op == TOp::IfEq)
                for (size_t k = 0; k < n; ++k)
                    if (si.target == blocks[k].begin) si.target = static_cast<int>(k);
            out.blocks[b].body.push_back(si);
        }
        // 给后继的 φ 填实参：沿本块在后继前驱表中的位置
        for (int s : adj[b])
            for (const auto &v : vars)
                if (hasPhi[{s, v}]) {
                    size_t slot = phiSlot.at({s, v});
                    size_t pos = 0;
                    for (size_t k = 0; k < preds[s].size(); ++k)
                        if (preds[s][k] == b) { pos = k; break; }
                    while (out.blocks[s].body[slot].phiArgs.size() < preds[s].size())
                        out.blocks[s].body[slot].phiArgs.push_back(v + "u");
                    out.blocks[s].body[slot].phiArgs[pos] = curName(v);
                }
        // 支配树孩子先序递归
        for (int c : di.children[b]) renameBlock(c);
        for (auto it = pushed.rbegin(); it != pushed.rend(); ++it)
            stack[*it].pop_back();
    };
    renameBlock(0);

    // ---------- 单定值自检 ----------
    singleDefOk = true;
    std::map<std::string, int> defs;
    for (const auto &blk : out.blocks)
        for (const auto &inst : blk.body) {
            if (!inst.dst.empty()) defs[inst.dst]++;
            for (const auto &arg : inst.phiArgs)
                if (arg.empty()) singleDefOk = false;
        }
    for (const auto &kv : defs)
        if (kv.second > 1) singleDefOk = false;
    return out;
}

std::vector<int> ssaRun(const SsaProgram &p, const std::vector<int> &inputs) {
    std::vector<int> outputs;
    std::map<std::string, int> env;
    size_t nextInput = 0;
    auto rd = [&](const std::string &s) -> int {
        if (isNumS(s)) return std::atoi(s.c_str());
        if (!s.empty() && s.back() == 'u')
            return 0;   // 未定值名（改名器的 ⊥ 记号）：按全 0 初值口径（第 70 章同款）
        auto it = env.find(s);
        if (it == env.end()) throw std::runtime_error("SSA 读未定义 " + s);
        return it->second;
    };
    int b = 0;
    int from = -1;
    int guard = 0;
    while (b >= 0 && b < static_cast<int>(p.blocks.size())) {
        if (++guard > 100000) throw std::runtime_error("SSA 解释超步数");
        const SsaBlock &blk = p.blocks[b];
        // φ：并行语义——先取全部实参再赋值（SSA 名字互不相同，顺序亦同，
        // 但按定义写成两段，正文 33.3 讲原因）
        std::vector<std::pair<std::string, int>> phiVals;
        for (const auto &inst : blk.body) {
            if (inst.phiArgs.empty()) continue;
            if (from < 0) continue;   // 入口块没有前驱，φ 不该有实参
            size_t pos = 0;
            for (size_t k = 0; k < p.preds[b].size(); ++k)
                if (p.preds[b][k] == from) { pos = k; break; }
            phiVals.push_back({inst.dst, rd(inst.phiArgs[pos])});
        }
        for (const auto &kv : phiVals) env[kv.first] = kv.second;
        int next = -1;
        int nextFrom = b;
        for (const auto &inst : blk.body) {
            if (!inst.phiArgs.empty()) continue;   // φ 已在入块时并行处理
            switch (inst.op) {
            case TOp::Copy:  env[inst.dst] = rd(inst.a); break;
            case TOp::Add:   env[inst.dst] = rd(inst.a) + rd(inst.b); break;
            case TOp::Sub:   env[inst.dst] = rd(inst.a) - rd(inst.b); break;
            case TOp::Mul:   env[inst.dst] = rd(inst.a) * rd(inst.b); break;
            case TOp::Div:   env[inst.dst] = rd(inst.a) / rd(inst.b); break;
            case TOp::Gt:    env[inst.dst] = rd(inst.a) > rd(inst.b) ? 1 : 0; break;
            case TOp::Eq:    env[inst.dst] = rd(inst.a) == rd(inst.b) ? 1 : 0; break;
            case TOp::Input:
                if (nextInput >= inputs.size())
                    throw std::runtime_error("SSA input 序列耗尽");
                env[inst.dst] = inputs[nextInput++];
                break;
            case TOp::Output: outputs.push_back(rd(inst.a)); break;
            case TOp::Ret:    return outputs;
            case TOp::Goto:   next = inst.target; break;
            case TOp::IfGt:   next = rd(inst.a) > rd(inst.b) ? inst.target : -1; break;
            case TOp::IfEq:   next = rd(inst.a) == rd(inst.b) ? inst.target : -1; break;
            }
            if (next != -1) break;
        }
        if (next == -1) next = b + 1;
        b = next;
        from = nextFrom;
    }
    return outputs;
}

}  // namespace tip
```

### 42.8.4 驱动 main.cpp

后支配/CDG/SSA
往返/三方对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 42 章驱动：--check FILE
//   TAC → 块图 → 后支配树 → CDG → SSA（34 章）→ 拆回 TAC → 解释器三方对账。
#include "cdg.hpp"
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
    std::fprintf(stderr, "[main entered]\n");
    std::cout.setf(std::ios::unitbuf);
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto ast = parseFile(argv[2]);
    std::fprintf(stderr, "[parsed]\n");
    std::vector<tip::Quad> code = tip::tacGen(*ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    size_t n = blocks.size();

    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';
    std::cout << "== blocks ==\n";
    for (size_t b = 0; b < n; ++b) {
        std::cout << "  B" << b << " succs:";
        for (int s : adj[b]) std::cout << ' ' << s;
        std::cout << '\n';
    }

    tip::DomInfo pdom = tip::postDominators(adj);
    std::cout << "== 后支配 ==\n";
    for (size_t b = 0; b < n; ++b) {
        std::cout << "  pdom(B" << b << ") = {";
        bool first = true;
        for (int d : pdom.dom[b]) {
            std::cout << (first ? "" : ",") << d;
            first = false;
        }
        std::cout << "}  ipdom=" << pdom.idom[b] << '\n';
    }

    tip::CdgInfo cdg = tip::controlDependence(adj, pdom);
    std::cout << "== 控制依赖图 ==\n";
    bool any = false;
    for (size_t b = 0; b < n; ++b)
        for (int s : cdg.succs[b]) {
            std::cout << "  B" << s << " 依赖 B" << b << '\n';
            any = true;
        }
    if (!any) std::cout << "  （无——直线程序没有分岔）\n";

    // ---------- SSA 往返 ----------
    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA ==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }
    tip::SsaBackResult back = tip::ssaBack(ssa);
    std::cout << "== SSA 退出 ==\n";
    for (size_t i = 0; i < back.code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(back.code[i]) << '\n';
    std::cout << "  copies = " << back.copies << "  swaps = " << back.swaps << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> o1 = tip::tacInterp(code, {5}).outputs;
    std::vector<int> o2 = tip::ssaRun(ssa, {5});
    std::vector<int> o3 = tip::tacInterp(back.code, {5}).outputs;
    std::cout << "  tac   :";
    for (int v : o1) std::cout << ' ' << v;
    std::cout << "\n  ssa   :";
    for (int v : o2) std::cout << ' ' << v;
    std::cout << "\n  back  :";
    for (int v : o3) std::cout << ' ' << v;
    std::cout << "\n  tac==ssa==back: "
              << (o1 == o2 && o2 == o3 ? "yes" : "NO") << '\n';
    return (o1 == o2 && o2 == o3) ? 0 : 1;
}
```

### 42.8.5 基座：dom（33 章）、tac 家族（13 章）与前端

```cpp
// file: src/dom.hpp
// file: src/dom.hpp
// 第 40 章配套之一：支配者（dominators）与支配树。
// dom[b] = { d | 每条 entry→b 的路径都经过 d }——
// 迭代方程：dom[entry]={entry}；dom[b]={b} ∪ ∩ dom[pred]。
// 这是“从全集出发、单调收缩”的不动点（与 may 分析方向相反的镜像）。
#ifndef TIP_DOM_HPP
#define TIP_DOM_HPP

#include <map>
#include <set>
#include <vector>


namespace tip {

struct DomInfo {
    std::vector<std::set<int>> dom;      // 每块（块号）的支配集
    std::vector<int> idom;               // 直接支配者（-1 = 无/入口）
    std::vector<std::vector<int>> children;   // 支配树孩子表
};

// 前驱表（邻接表反推）。
std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj);

DomInfo dominators(const std::vector<std::vector<int>> &adj);

// 自检：由支配树推导的支配集 == 迭代解（idom 唯一性的机器验证）。
bool domTreeCheck(const DomInfo &di);

}  // namespace tip

#endif  // TIP_DOM_HPP
```

```cpp
// file: src/dom.cpp
// file: src/dom.cpp
// 第 40 章配套：支配者实现。
#include "dom.hpp"

namespace tip {

std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    std::vector<std::set<int>> preds(n);
    for (size_t q = 0; q < n; ++q)
        for (int s : adj[q]) preds[s].insert(static_cast<int>(q));
    return preds;
}

DomInfo dominators(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    DomInfo di;
    // 初值：入口只含自己，其余从全集出发（“人人可能支配”，逐步证伪）。
    std::set<int> all;
    for (size_t k = 0; k < n; ++k) all.insert(static_cast<int>(k));
    di.dom.assign(n, all);
    if (n > 0) di.dom[0] = {0};
    auto preds = predsOf(adj);
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 1; b < n; ++b) {
            std::set<int> acc = all;
            bool hasPred = false;
            for (int p : preds[b]) {
                std::set<int> keep;
                for (int x : acc)
                    if (di.dom[p].count(x)) keep.insert(x);
                acc = keep;
                hasPred = true;
            }
            acc.insert(static_cast<int>(b));
            if (!hasPred) acc = {static_cast<int>(b)};   // 不可达块：只支配自己
            if (acc != di.dom[b]) {
                di.dom[b] = acc;
                changed = true;
            }
        }
    }
    // idom：b 的严格支配者中，支配集最大（最靠近 b）的那个。
    di.idom.assign(n, -1);
    for (size_t b = 1; b < n; ++b) {
        int best = -1;
        size_t bestSize = 0;
        for (int d : di.dom[b]) {
            if (d == static_cast<int>(b)) continue;
            if (di.dom[d].size() >= bestSize) {
                bestSize = di.dom[d].size();
                best = d;
            }
        }
        di.idom[b] = best;
    }
    // 支配树
    di.children.assign(n, {});
    for (size_t b = 1; b < n; ++b)
        if (di.idom[b] >= 0) di.children[di.idom[b]].push_back(static_cast<int>(b));
    return di;
}

bool domTreeCheck(const DomInfo &di) {
    size_t n = di.dom.size();
    // 由树推导支配集：dom'(b) = 路径上祖先 ∪ {b}
    std::vector<std::set<int>> fromTree(n);
    for (size_t b = 0; b < n; ++b) {
        std::set<int> s = {static_cast<int>(b)};
        int cur = di.idom[b];
        while (cur >= 0) {
            s.insert(cur);
            cur = di.idom[cur];
        }
        fromTree[b] = s;
    }
    for (size_t b = 0; b < n; ++b)
        if (fromTree[b] != di.dom[b]) return false;
    return true;
}

}  // namespace tip
```

```cpp
// file: src/tacgen.hpp
// file: src/tacgen.hpp
// 第 18 章配套：AST → 三地址码（TAC）。
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
// 第 18 章配套：TAC 生成与打印。
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
// 第 18 章配套：leader 划分基本块 + 块内 next-use 信息。
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
// 第 18 章配套：leader 划分与 next-use。
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
// 第 18 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
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
// 第 18 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
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

### 42.8.6 程序与期望输出

```text
// file: programs/cfg.tip
main() {
  var a, b;
  a = input;
  if (a > 3) b = a * 2; else b = a + 1;
  while (a > 0) a = a - 1;
  output b + a;
  return 0;
}
```

```text
; expected: expected/output.txt
== cfg.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: t2 = 3
  3: if a > t2 goto L5
  4: goto L9
  5: t3 = 2
  6: t4 = a * t3
  7: b = t4
  8: goto L12
  9: t5 = 1
  10: t6 = a + t5
  11: b = t6
  12: t7 = 0
  13: if a > t7 goto L15
  14: goto L19
  15: t8 = 1
  16: t9 = a - t8
  17: a = t9
  18: goto L12
  19: t10 = b + a
  20: output t10
  21: t11 = 0
  22: return t11
== blocks ==
  B0 succs: 1 2
  B1 succs: 3
  B2 succs: 4
  B3 succs: 4
  B4 succs: 5 6
  B5 succs: 7
  B6 succs: 4
  B7 succs:
== 后支配 ==
  pdom(B0) = {0,4,5,7}  ipdom=4
  pdom(B1) = {1,3,4,5,7}  ipdom=3
  pdom(B2) = {2,4,5,7}  ipdom=4
  pdom(B3) = {3,4,5,7}  ipdom=4
  pdom(B4) = {4,5,7}  ipdom=5
  pdom(B5) = {5,7}  ipdom=7
  pdom(B6) = {4,5,6,7}  ipdom=4
  pdom(B7) = {7}  ipdom=-1
== 控制依赖图 ==
  B1 依赖 B0
  B2 依赖 B0
  B3 依赖 B0
  B6 依赖 B4
== SSA ==
  B0:
    t10 = input
    a0 = t10
    t20 = 3
    if a0 > t20 goto B2
  B1:
    goto B3
  B2:
    t30 = 2
    t40 = a0 * t30
    b1 = t40
    goto B4
  B3:
    t50 = 1
    t60 = a0 + t50
    b0 = t60
  B4:
    a1 = phi(a0, a0, a2)
    b2 = phi(b1, b0, b2)
    t31 = phi(t30, t3u, t31)
    t41 = phi(t40, t4u, t41)
    t51 = phi(t5u, t50, t51)
    t61 = phi(t6u, t60, t61)
    t70 = phi(t7u, t7u, t71)
    t80 = phi(t8u, t8u, t81)
    t90 = phi(t9u, t9u, t91)
    t71 = 0
    if a1 > t71 goto B6
  B5:
    goto B7
  B6:
    t81 = 1
    t91 = a1 - t81
    a2 = t91
    goto B4
  B7:
    t100 = b2 + a1
    output t100
    t110 = 0
    return t110
== SSA 退出 ==
  0: t10 = input
  1: a0 = t10
  2: t20 = 3
  3: if a0 > t20 goto L5
  4: goto L18
  5: t30 = 2
  6: t40 = a0 * t30
  7: b1 = t40
  8: a1 = a0
  9: b2 = b1
  10: t31 = t30
  11: t41 = t40
  12: t51 = 0
  13: t61 = 0
  14: t70 = 0
  15: t80 = 0
  16: t90 = 0
  17: goto L30
  18: t50 = 1
  19: t60 = a0 + t50
  20: b0 = t60
  21: a1 = a0
  22: b2 = b0
  23: t31 = 0
  24: t41 = 0
  25: t51 = t50
  26: t61 = t60
  27: t70 = 0
  28: t80 = 0
  29: t90 = 0
  30: t71 = 0
  31: if a1 > t71 goto L33
  32: goto L51
  33: t81 = 1
  34: t91 = a1 - t81
  35: a2 = t91
  36: sb1_b2 = b2
  37: sb1_t31 = t31
  38: sb1_t41 = t41
  39: sb1_t51 = t51
  40: sb1_t61 = t61
  41: a1 = a2
  42: b2 = sb1_b2
  43: t31 = sb1_t31
  44: t41 = sb1_t41
  45: t51 = sb1_t51
  46: t61 = sb1_t61
  47: t70 = t71
  48: t80 = t81
  49: t90 = t91
  50: goto L30
  51: t100 = b2 + a1
  52: output t100
  53: t110 = 0
  54: return t110
  copies = 27  swaps = 1
== 对账 ==
  tac   : 10
  ssa   : 10
  back  : 10
  tac==ssa==back: yes
[main entered]
[parsed]
```

## 42.9 小结与练习

本章补上
SSA 世界的
两块拼图：

- 后支配 =
  支配的镜像，
  同一台不动点
  机器反向通电；
- CDG =
  FOW 沿后支配
  树上行，
  与 CHK 的
  支配边界
  同型对偶——
  汇合与分岔
  一体两面；
- SSA 退出 =
  φ 拆到前驱
  块尾的
  并行复制，
  环用临时断；
- 三方对账
  tac==ssa==back
  给构造与拆解
  双向背书。

下一章把
DAG 搬进
基本块做
局部优化。

练习：

1. 手工对 cfg.tip
   算 pdom(B2)
   与 B2 的
   CDG 前驱，
   与输出对照。
2. 给 CDG 加
   暴力复核：
   按定义枚举
   每对 (n,c)
   检验
   "c 有后继被
    n 后支配 ∧
    n 不严格
    后支配 c"，
   与 FOW 输出
   集合相等。
3. 构造一个
   显式 swap 环
   （x 与 y 在
    汇合处互换），
   观察 swaps ≥ 1
   的临时名
   与语义保持。
4. 实现
   "先拆 φ 再
    复制传播"
    的清扫：
    拆解产生的
    `b2 = b1`
    直接用 26 章
    copyProp 吃掉，
    数指令回落
    多少。
5. （承 35.6）
    把 cfg.tip 的
    SSA 手工改写成
    "块即函数"
    形态（尾调用 +
    块参数），
    验证 φ 的
    并行语义
    被调用语义
    免费覆盖。

---

上一章：[41 SSA 形式](41-ssa.md) · 下一章：[43 基本块 DAG](43-dag-local.md)
