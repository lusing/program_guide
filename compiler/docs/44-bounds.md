# 第 44 章　边界检查消除与循环展开：让安全免税

## 44.1 问题：安全检查是隐形的税

安全的语言
在每次数组访问
`a[i]` 前查
`0 ≤ i < n`、
每次除法前查
分母非零、
每次解引用前查
非空——
这些 **guard**
（守卫指令）
是语义的承诺，
也是性能的税：

- 每个.guard
  是一条比较 +
  一条条件跳转，
  热循环里
  乘以迭代数；
- guard 打断
  基本块——
  36 章 DAG、
  50 章调度的
  块内自由度
  被它切碎。

**边界检查消除**
（bounds-check
elimination，
虎书 §18.4）
的宣言：
**能证明安全的，
  一条都不留；
  证明不了的，
  一条也不删**。
它最强的引擎
正是 37 章的
归纳变量推理。
本章顺带讲
**循环展开**
（§18.5）——
另一个"用
  静态知识换
  动态开销"的
  循环变换。

教学替身说明：
TIP 没有数组，
本章用**除零
guard**当替身
——`x = a / b`
前插
`if b == 0 goto fail`
与 `a[i]` 前插
`if i >= n goto fail`
**完全同构**：
都是"异常条件
驱动的条件
跳转"，
都吃同一套
归纳变量推理。
真实的数组
界检查见
练习四。

## 44.2 guard 的插入与两规则消除

**插入器**：
每条 `Div`
前插一条
`if 分母 == 0 goto fail`
（fail 用负数
目标编码占位，
消除阶段统一
回填）。
插入改变行号，
**两遍平移**：
先记 Div 位，
目标的重贴量 =
目标位置之前
的 guard 数——
"动指令必重贴"
的老纪律
（26/14/35 章
  第三次出场）。

**消除器**
（对每个循环）：

**规则 (a)
——不变分母**：
分母在循环内
无定值 ⇒
guard 是
循环不变式
（37 章 LICM
  判据直接复用）。
教学口径：
计数为
`invariantHoisted`
（外提到
preheader 后
只查一次；
本章示例
直接删除并
计数——
程序保证
分母非零，
对账线上
outputs 不变）。

**规则 (b)
——归纳分母**：
分母恰是
**单调递增的
归纳变量**
（i = i + 1、
循环内唯一
定值）⇒
"i ≠ 0 一次
则永不回 0"——
整数步长 1
的单调性
保证。
循环前查一次
初值即够；
教学口径同上
计数为
`ivEliminated`。

虎书 18.4
的完整版还有
第三级：
**区间推理**
（i ∈ [0, n)
由循环条件
与步长推出，
界 n 不变 ⇒
0 ≤ i < n
全程成立，
guard 整体
冗余）——
那是 33–34 章
区间分析的
直接应用，
练习二给出
实现路线。

期望输出
（div.tip，
n 为输入、
循环体内
`s = s + 100/n`）：

```
guard 插入:  if n == 0 goto L-2   ← 1 条（分母 n 循环不变）
消除:       invariantHoisted = 1
guards:     1 -> 0
outputs:    96 preserved: yes     ← 6 圈 × (100/6=16) = 96 ✓
```

分母 n 是
循环不变量，
规则 (a) 一击
命中；
除法本身的
语义（整除）
由解释器
背书，
guard 的存在
与否不改变
合法输入下的
outputs——
对账的正是
这一点。

## 44.3 循环展开：摊薄循环的开销

**循环展开**
（loop
unrolling，
虎书 §18.5）：
把循环体
复制 k 份、
步长乘 k、
循环条件
改半频：

```
; 原始（步长 1，判 6 次、跳 6 次、增 6 次）
L: if n > i goto B else goto E
B: body(i); i = i + 1; goto L
E:

; 展开 ×2（步长 2，判 3 次、跳 3 次、增 6 次但指令在体内连排）
L: if n > i+1 goto B else goto T   ← 剩余处理见下
B: body(i); body(i+1); i = i + 2; goto L
T: if n > i goto B1                ← 尾巴：奇数迭代补一次
B1: body(i); i = i + 1
E:
```

**收益账**：

- 循环头的
  判断与跳转
  从 n 次降为
  n/k 次——
  分支开销
  摊薄 k 倍；
- 体内 k 份
  连排：
  36 章 DAG
  的作用域
  变大
  （跨迭代的
    公共子表达式
    现在同居
    一块），
  50 章调度
  的指令窗口
  变大；
- **代价**：
  代码膨胀
  k 倍
  （I-cache
    压力）、
  尾巴处理
  增加复杂度、
  与 48 章
  寄存器分配
  抢盒子
  （展开后
    活跃变量
    更多）。

**展开因子 k
的选择**是
典型 的
工程权衡：
指令缓存
容量、
函数调用
密度、
后续优化
的吸收能力
都进账。
现代编译器
把展开当
"给其它优化
  喂料"的
  预处理
（LLVM 的
  loop-unroll
  在向量化
  之前），
而非独立的
赢利点。

**迭代次数
不确定时的
尾巴**：
n mod k 次
剩余迭代
要么补一个
小循环
（上面的 T
分支），
要么**守卫
展开体**
（先判
"至少剩 k 次"
再进展开块，
否则走原版
体）——
虎书给的
正是第二种
（guard the
unrolled
body），
与本章主题
形成闭环：
**守卫的
  艺术既用于
  安全检查，
  也用于
  变换的
  正确性**。

本章的
机器实现
聚焦 guard
消除（完整
对账）；
展开以
"手工推演 +
练习实现"
呈现——
它的每一步
（复制体、
改步长、
补守卫）
都过
outputs
不变线。

## 44.4 期望输出解读

div.tip 段
四部曲：

1. **TAC**：
  19 条，
  循环体里
  `t5 = t4 / n`
  一条 Div
  等着被
  guard；
2. **guard
  插入后**：
  20 条，
  `9: if n == 0 goto L-2`
  一条负目标
  占位；
3. **消除后**：
  回到 19 条
  （与原 TAC
    同形——
    guard
    全灭），
  `invariantHoisted = 1`；
4. **对账**：
  outputs 96
  （6 圈 × 16）
  前后一致。

值得注意的
是"消除后 ==
原 TAC"
这个巧合：
一条 guard
被删、
代码回到
插入前的
字节——
**如果消除器
  什么都不做，
  这就是天然的
  回归测试**：
  插入再删除
  应当是无损
  往返。
（一般情形
  不一定回到
  原样——
  外提到
  preheader 的
  guard 会留下
  一条循环前
  检查；
  本章的
  "直接删除"
  口径让
  往返严格
  恒等，
  练习三让
  preheader
  版落地。）

## 44.5 工程注意点

- **fail 路径
  也是语义**。
  删 guard
  的前提是
  "证明它永不
   触发"；
  外提的前提
  是"触发条件
   循环不变"。
  真实语言里
  fail 路径
  抛异常——
  异常的
  可见副作用
  （栈展开、
    finally）
  让"删掉
   永不触发的
   检查"也要
  谨慎
  （证明必须
    覆盖浮点
    陷阱等
    边角）。
- **guard 与
  基本块**。
  一条 guard
  切一刀块。
  消除后块数
  下降，
  36 章 DAG
  与 50 章
  调度的
  粒度立刻
  变粗——
  安全优化
  是其它优化
  的地基，
  这就是它
  排在循环
  优化家族
  里的原因。
- **区间分析
  是完全体**。
  规则 (a)/(b)
  是"点推理"；
  33–34 章
  的区间域
  给出
  "i ∈ [l, u]"
  的连续
  推理，
  界检查
  `0 ≤ i < n`
  变成一次
  区间包含
  判断。
  工业界
  （ASAP、
    LLVM 的
    guard
    widening）
  都走这条线。
- **展开的
  相位次序**。
  展开应在
  LICM 与
  归纳变量
  处理**之后**
  （先榨干
    环内冗余
    再复制，
    免得把
    冗余也
    翻倍），
  在向量化、
  调度**之前**
  （给它们
    喂大块）。
  37 → 38 →
  50 的章序
  就是这个
  次序。

## 44.6 本章配套文件

### 44.6.1 文法 TIP.g4

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

### 44.6.2 新件：bounds.hpp 与 bounds.cpp

guard 插入
（两遍目标
  平移）、
两规则消除、
循环展开
报告位。

```cpp
// file: src/bounds.hpp
// file: src/bounds.hpp
// 第 44 章配套：guard 插入、边界检查消除（虎书 §18.4）与循环展开报告（§18.5）。
// TIP 没有数组——用除零 guard 当教学替身（与 a[i] 越界检查同构：
// 都是"异常条件驱动的条件跳转"，都能用归纳变量推理消除/外提）。
#ifndef TIP_BOUNDS_HPP
#define TIP_BOUNDS_HPP

#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "licm.hpp"

namespace tip {

// 为每条 Div 插入 guard：`if 分母 == 0 goto fail`（目标负数编码，待消除器回填）。
std::vector<Quad> insertGuards(const std::vector<Quad> &code);

struct BoundsResult {
    std::vector<Quad> code;
    int invariantHoisted = 0;   // 规则 (a)：分母循环不变 ⇒ guard 可外提（计删）
    int ivEliminated = 0;       // 规则 (b)：分母是单调归纳变量 ⇒ guard 可删
};

// 消除/外提：循环内的 guard 按两规则处置；保留者回填到末尾 fail 序列。
BoundsResult eliminateGuards(const std::vector<Quad> &guarded,
                             const std::vector<Block> &blocks,
                             const LoopInfo &li);

struct UnrollResult {
    int unrolled = 0;
};

// 循环展开（教学口径：正文手工推演 + 练习实现）。
UnrollResult unroll2(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                     const LoopInfo &li);

}  // namespace tip

#endif  // TIP_BOUNDS_HPP
```

```cpp
// file: src/bounds.cpp
// file: src/bounds.cpp
// 第 44 章配套：边界检查消除与循环展开（虎书 §18.4–18.5）。
#include "bounds.hpp"


namespace tip {

namespace {
bool pureDefB(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

// TIP 无数组——本章用记录访问 a.f 的 Lower 检查当替身：
// tacgen 里字段访问留待 42 章，所以我们改用 input 前置检查的形态。
// 更直接的教学替身：除零检查。`x = a / b` 前插 `if b == 0 goto fail`
// 与数组 `a[i]` 前插 `if i >= n goto fail` 同构：
// 都由"越界/异常条件"驱动的 guard，都可以用同一套归纳变量推理消除。
// bounds.cpp 的插入器：为每条 Div 生成 guard（确定性编号）。

std::vector<Quad> insertGuards(const std::vector<Quad> &code) {
    // 两遍：先记 Div 位（guard 插在它们前面），再重建——
    // 目标平移量 = 目标位置之前的 guard 数（老纪律：动指令必重贴）。
    std::vector<int> guardBefore(code.size() + 1, 0);
    int g = 0;
    for (size_t i = 0; i < code.size(); ++i) {
        if (code[i].op == TOp::Div) ++g;
        guardBefore[i + 1] = g;
    }
    std::vector<Quad> out;
    for (size_t i = 0; i < code.size(); ++i) {
        if (code[i].op == TOp::Div) {
            Quad guard{TOp::IfEq, "", code[i].b, "0", -1};
            guard.target = -2 - guardBefore[i];   // 负数编码：guard 槽位（待消除/回填）
            out.push_back(guard);
        }
        Quad q = code[i];
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
            q.target += guardBefore[q.target];
        out.push_back(q);
    }
    return out;
}

BoundsResult eliminateGuards(const std::vector<Quad> &guarded,
                             const std::vector<Block> &blocks,
                             const LoopInfo &li) {
    BoundsResult r;
    // 对每个循环：找归纳变量 i（i = i + c，c 常量、循环内唯一定值）
    // 与"分母与 i 的仿射关系"。教学子集：分母就是 i 本身或循环不变量。
    // 消除规则（虎书 18.4 的精神）：
    //   (a) 分母循环不变 ⇒ guard 外提到 preheader（LICM 判据）；
    //   (b) 分母 = 归纳变量 i，且循环条件形如 k > i（i 从初值只增不减）⇒
    //       guard 只需在循环前查一次 i 初值 ≠ 0——若步长 c 满足
    //       "i ≠ 0 后每步 +1 不可能跨回 0"（整数 c=1 单调），全程安全。
    // 本章实现 (a) 与 (b) 的单变量情形；报告两类命中数。
    std::vector<bool> removed(guarded.size(), false);
    r.code = guarded;
    for (const auto &L : li.loops) {
        auto ivs = indVars(guarded, blocks, L);
        std::set<std::string> definedInLoop;
        std::set<int> loopLines;
        for (int b : L.body)
            for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
                loopLines.insert(i);
                if (pureDefB(guarded[i])) definedInLoop.insert(guarded[i].dst);
            }
        for (int i : loopLines) {
            const Quad &q = guarded[i];
            if (q.op != TOp::IfEq || q.target >= -1) continue;   // 只看 guard 槽
            const std::string &denom = q.a;
            if (!definedInLoop.count(denom)) {
                ++r.invariantHoisted;   // 规则 (a)：分母循环不变（此处直接计为可外提/删除）
                removed[i] = true;
            } else {
                // 规则 (b)：分母是归纳变量且循环头条件是 k > i（单调递增）⇒
                // guard 可降级为循环前查一次——教学版直接删除并计数
                for (const auto &iv : ivs)
                    if (iv.var == denom && iv.incr > 0) {
                        ++r.ivEliminated;
                        removed[i] = true;
                    }
            }
        }
    }
    // 未在循环里的 guard（直线 Div）：保留（直线代码没有"多次执行摊薄"收益，
    // 教学口径不消除）——但把负目标回填为程序末尾。
    // 目标回填：guard 槽 -2-k → 末尾 return -1 序列的位置。
    // 简化：所有保留的 guard 目标指向最后一条指令（return 处）。
    std::vector<Quad> rebuilt;
    std::vector<int> oldToNew(guarded.size() + 1, -1);
    for (size_t i = 0; i < guarded.size(); ++i)
        if (!removed[i]) oldToNew[i] = static_cast<int>(rebuilt.size()), rebuilt.push_back(guarded[i]);
    oldToNew[guarded.size()] = static_cast<int>(rebuilt.size());
    for (size_t i = guarded.size(); i-- > 0;)
        if (oldToNew[i] == -1) oldToNew[i] = oldToNew[i + 1];
    for (auto &q : rebuilt) {
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq) {
            if (q.target < -1) q.target = static_cast<int>(rebuilt.size()) - 1;   // → return
            else q.target = oldToNew[q.target];
        }
    }
    // 末尾补 fail 序列：g0 = -1 ; return g0（guard 命中即返回 -1）
    if (r.invariantHoisted + r.ivEliminated <
        static_cast<int>(guarded.size()) - static_cast<int>(rebuilt.size()) + 1) {
        // 仍有 guard 保留时才需要 fail 尾巴
    }
    bool anyGuard = false;
    for (const auto &q : rebuilt)
        if (q.op == TOp::IfEq && q.a != "" && q.b == "0" && q.target == static_cast<int>(rebuilt.size()) - 1)
            anyGuard = true;
    if (anyGuard) {
        rebuilt.push_back(Quad{TOp::Copy, "gf", "-1", "", -1});
        rebuilt.push_back(Quad{TOp::Ret, "", "gf", "", -1});
        // 重贴：guard 目标本就指 rebuilt.size()-1（补尾前的 return 位置）——
        // 补尾后 return 移位，guard 需指 fail 首条。统一再修一轮：
        int failAt = static_cast<int>(rebuilt.size()) - 2;
        for (auto &q : rebuilt)
            if (q.op == TOp::IfEq && q.b == "0" && q.target == failAt + 1)
                q.target = failAt;
    }
    r.code = std::move(rebuilt);
    return r;
}

UnrollResult unroll2(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                     const LoopInfo &li) {
    UnrollResult r;
    (void)code;
    (void)blocks;
    (void)li;
    // 教学口径：循环展开以"概念演示"呈现——37 章的 while 模板把体复制两份、
    // 步长翻倍、循环头改半频，涉及块结构手术；正文 38.5 给完整手工推演，
    // 机器实现留作练习（步骤/输出对账线现成）。
    r.unrolled = 0;
    return r;
}

}  // namespace tip
```

### 44.6.3 改件：tacblocks.cpp（本地副本）

负目标豁免
（guard 占位
  不当 leader
  下标）。

```cpp
// file: src/tacblocks.hpp
// file: src/tacblocks.hpp
// 第 16 章配套：leader 划分基本块 + 块内 next-use 信息。
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
// 第 16 章配套：leader 划分与 next-use。
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
            if (code[i].target >= 0 && code[i].target < static_cast<int>(code.size()))
                leader[code[i].target] = true;   // 负目标 = guard 占位（本章 38），豁免
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

### 44.6.4 驱动 main.cpp

插入/消除/
对账四段。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 44 章驱动：--check FILE
//   TAC → guard 插入（每 Div 一条 if 分母==0）→ 消除（两规则计数）
//   → 保留 guard 回填 fail 序列 → 解释器 outputs 对账（保义）。
#include "bounds.hpp"
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

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';

    std::vector<tip::Quad> guarded = tip::insertGuards(code);
    std::cout << "== guard 插入后 ==\n";
    for (size_t i = 0; i < guarded.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(guarded[i]) << '\n';

    std::vector<tip::Block> blocks = tip::partitionBlocks(guarded);
    tip::LoopInfo li = tip::loopsOf(guarded, blocks);
    std::cout << "== loops ==\n";
    for (const auto &L : li.loops) {
        std::cout << "  back " << L.from << "->" << L.header << " body={";
        for (int b : L.body) std::cout << b << ' ';
        std::cout << "}\n";
    }

    tip::BoundsResult res = tip::eliminateGuards(guarded, blocks, li);
    std::cout << "== 消除后 ==\n";
    for (size_t i = 0; i < res.code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(res.code[i]) << '\n';

    std::cout << "== stats ==\n";
    std::cout << "  invariantHoisted = " << res.invariantHoisted
              << "  ivEliminated = " << res.ivEliminated << '\n';
    int guardsBefore = 0, guardsAfter = 0;
    for (const auto &q : guarded)
        if (q.op == tip::TOp::IfEq && q.b == "0") ++guardsBefore;
    for (const auto &q : res.code)
        if (q.op == tip::TOp::IfEq && q.b == "0") ++guardsAfter;
    std::cout << "  guards: " << guardsBefore << " -> " << guardsAfter << '\n';

    tip::UnrollResult ur = tip::unroll2(res.code, blocks, li);
    std::cout << "  unrolled = " << ur.unrolled << "（概念推演见正文 38.5）\n";

    std::cout << "== 对账 ==\n";
    // guard 命中（分母实为 0）时原程序解释器会除零崩溃——教学程序分母非零，
    // 消除前后 outputs 必须一致；guard 版本分母非零时 guard 不触发。
    std::vector<int> o1 = tip::tacInterp(code, {6}).outputs;
    std::vector<int> o2 = tip::tacInterp(res.code, {6}).outputs;
    std::cout << "  outputs:";
    for (int v : o1) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (o1 == o2 ? "yes" : "NO") << '\n';
    return (o1 == o2 && guardsAfter <= guardsBefore) ? 0 : 1;
}
```

### 44.6.5 基座：licm 家族（37 章）与 TAC/前端

```cpp
// file: src/licm.hpp
// file: src/licm.hpp
// 第 42 章配套：循环不变式外提（LICM）与归纳变量家族。
//   循环来自第 37 章的自然循环；外提位置 = 唯一非循环前驱（preheader）的块尾。
//   判据用紫龙 9.1.7 的安全子集：
//     (1) 指令的 dst 在循环内是唯一定值；
//     (2) 操作数在循环内无定值（全部来自循环外或常量）；
//     (3) dst 在循环外无使用（t 系临时天然满足；变量需检查）——
//         这条回避了“支配所有出口”的图论判据，教学版更稳。
#ifndef TIP_LICM_HPP
#define TIP_LICM_HPP

#include <set>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "dom.hpp"
#include "dfs.hpp"

namespace tip {

struct LoopInfo {
    std::vector<NaturalLoop> loops;
    std::vector<std::vector<int>> adj;
    DomInfo di;
};

LoopInfo loopsOf(const std::vector<Quad> &code, const std::vector<Block> &blocks);

// 外提：返回 (新指令序列, 外提条数)。preheader 末尾插入（跳转目标零改动）。
std::pair<std::vector<Quad>, int> licm(const std::vector<Quad> &code,
                                       const std::vector<Block> &blocks,
                                       const LoopInfo &li);

// 归纳变量分析：找 (i, c) —— 循环内唯一自增 i = i + c、循环外有初值。
struct IndVar {
    std::string var;
    int incrLine;      // i = i + c 的行号
    int incr;          // c
};
std::vector<IndVar> indVars(const std::vector<Quad> &code,
                            const std::vector<Block> &blocks,
                            const NaturalLoop &loop);

}  // namespace tip

#endif  // TIP_LICM_HPP
```

```cpp
// file: src/licm.cpp
// file: src/licm.cpp
// 第 42 章配套：LICM 与归纳变量实现。
#include "licm.hpp"

#include <cctype>
#include <cstdlib>

namespace tip {

namespace {
bool isNumL(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarL(const std::string &s) { return !s.empty() && !isNumL(s); }
bool pureDef(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

LoopInfo loopsOf(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    (void)code;   // 循环结构只看块图
    size_t n = blocks.size();
    LoopInfo li;
    li.adj.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) li.adj[b].push_back(static_cast<int>(k));
    li.di = dominators(li.adj);
    DfsInfo df = dfsClassify(li.adj);
    li.loops = naturalLoops(li.adj, df, li.di);
    return li;
}

std::pair<std::vector<Quad>, int> licm(const std::vector<Quad> &code,
                                       const std::vector<Block> &blocks,
                                       const LoopInfo &li) {
    size_t n = blocks.size();
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return static_cast<int>(k);
        return -1;
    };
    std::vector<bool> removed(code.size(), false);
    int hoisted = 0;
    for (const auto &L : li.loops) {
        // 循环内定值的变量集合 + 循环内指令区间
        std::set<std::string> definedInLoop;
        std::set<int> loopLines;
        for (int b : L.body)
            for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
                loopLines.insert(i);
                if (pureDef(code[i])) definedInLoop.insert(code[i].dst);
            }
        // 循环外的使用（dst 循环外被读 → 保守不提）
        auto usedOutside = [&](const std::string &v) {
            for (int i = 0; i < static_cast<int>(code.size()); ++i) {
                if (loopLines.count(i)) continue;
                const Quad &q = code[i];
                if (q.a == v || q.b == v) return true;
            }
            return false;
        };
        // preheader：header 的非循环前驱（while 模板保证唯一）
        int preheader = -1;
        for (size_t q = 0; q < n; ++q) {
            if (L.body.count(static_cast<int>(q))) continue;
            for (int s : li.adj[q])
                if (s == L.header) { preheader = static_cast<int>(q); break; }
            if (preheader >= 0) break;
        }
        if (preheader < 0) continue;
        // 单遍扫描循环体：满足三条件即标提
        std::vector<int> toHoist;
        for (int i : loopLines) {
            const Quad &q = code[i];
            if (!pureDef(q)) continue;
            bool opOk = true;
            for (const std::string *s : {&q.a, &q.b}) {
                if (!isVarL(*s)) continue;
                if (definedInLoop.count(*s)) { opOk = false; break; }
            }
            if (!opOk) continue;
            int defCount = 0;
            for (int j : loopLines)
                if (pureDef(code[j]) && code[j].dst == q.dst) ++defCount;
            if (defCount != 1) continue;
            if (q.dst[0] != 't' && usedOutside(q.dst)) continue;   // 变量被循环外使用则不提
            toHoist.push_back(i);
        }
        if (toHoist.empty()) continue;
        // preheader 尾（块尾跳转之前）插入；被提指令在原位删除
        int insertAt = blocks[preheader].end;
        for (int k = insertAt - 1; k >= blocks[preheader].begin; --k)
            if (code[k].op == TOp::Goto || code[k].op == TOp::IfGt ||
                code[k].op == TOp::IfEq) {
                insertAt = k;
                break;
            }
        // 行号策略：先收集后统一重排——用稳定重建而非原地搬移
        std::vector<Quad> hoistedQuads;
        for (int i : toHoist) {
            hoistedQuads.push_back(code[i]);
            removed[i] = true;
            ++hoisted;
        }
        (void)insertAt;
        // 重建（两段拼装，目标重贴）：因 preheader 内插入不改变块边界
        // 与任何跳转目标（插入点在块内、目标都指向块首），
        // 这里直接以“先提走再在 preheader 尾补”的方式重排行号。
        std::vector<Quad> rebuilt;
        // 两遍：先算满 oldToNew（含前瞻目标），再重贴跳转目标
        std::vector<int> oldToNew(code.size() + 1, -1);
        {
            int k = 0;
            for (size_t i = 0; i < code.size(); ++i)
                if (!removed[i]) oldToNew[i] = k++;
            oldToNew[code.size()] = k;
            for (size_t i = code.size(); i-- > 0;)
                if (oldToNew[i] == -1) oldToNew[i] = oldToNew[i + 1];
        }
        for (size_t i = 0; i < code.size(); ++i)
            if (!removed[i]) {
                Quad q = code[i];
                if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
                    q.target = oldToNew[q.target];
                rebuilt.push_back(q);
            }
        // preheader 尾 = 块 end 首条保留指令的新位置（preheader 行不会被提走）
        int ph = oldToNew[blocks[preheader].end];
        // 插入点之后的跳转目标整体 +n
        for (auto &q : rebuilt)
            if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
                if (q.target >= ph) q.target += static_cast<int>(hoistedQuads.size());
        rebuilt.insert(rebuilt.begin() + ph, hoistedQuads.begin(), hoistedQuads.end());
        return {rebuilt, hoisted};
    }
    (void)blockOf;
    return {code, 0};
}

std::vector<IndVar> indVars(const std::vector<Quad> &code,
                            const std::vector<Block> &blocks,
                            const NaturalLoop &loop) {
    std::vector<IndVar> out;
    std::set<std::string> defined;
    for (int b : loop.body)
        for (int i = blocks[b].begin; i < blocks[b].end; ++i)
            if (pureDef(code[i])) defined.insert(code[i].dst);
    // 基本归纳变量：TAC 形态是两连“t = i + c ; i = t”（增量经临时中转）。
    // 识别：Add(t, i, c) 且同块随后 Copy(i, t)，且 i 在循环内无其它定值。
    // 常量解析：b 是字面量直接用；是临时则追它的唯一 Copy 定值（t8 = 1 形态）
    auto constOf = [&](const std::string &s) -> int {
        if (isNumL(s)) return std::atoi(s.c_str());
        for (const auto &q : code)
            if (q.op == TOp::Copy && q.dst == s && isNumL(q.a))
                return std::atoi(q.a.c_str());
        return 0;
    };
    auto isConst = [&](const std::string &s) {
        if (isNumL(s)) return true;
        for (const auto &q : code)
            if (q.op == TOp::Copy && q.dst == s && isNumL(q.a)) return true;
        return false;
    };
    for (int b : loop.body)
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            const Quad &q = code[i];
            if (q.op != TOp::Add && q.op != TOp::Sub) continue;
            if (!isConst(q.b)) continue;
            if (q.a.empty() || q.a[0] == 't') continue;   // 左操作数应是变量
            // 找紧随的 i = t
            bool chained = false;
            for (int j = i + 1; j < blocks[b].end; ++j)
                if (code[j].op == TOp::Copy && code[j].dst == q.a && code[j].a == q.dst) {
                    chained = true;
                    break;
                }
            if (!chained) continue;
            // i 在循环内恰好一次定值（就是那 Copy）
            int count = 0;
            for (int b2 : loop.body)
                for (int k2 = blocks[b2].begin; k2 < blocks[b2].end; ++k2)
                    if (pureDef(code[k2]) && code[k2].dst == q.a) ++count;
            if (count != 1) continue;
            int c = constOf(q.b);
            if (q.op == TOp::Sub) c = -c;
            out.push_back(IndVar{q.a, i, c});
        }
    return out;
}

}  // namespace tip
```

```cpp
// file: src/dom.hpp
// file: src/dom.hpp
// 第 37 章配套之一：支配者（dominators）与支配树。
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
// 第 37 章配套：支配者实现。
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
// file: src/dfs.hpp
// file: src/dfs.hpp
// 第 37 章配套之二：DFS 边分类、自然循环、可归约性。
// 边分类用发现/完成区间（白灰黑三色）：
//   树边（灰→白）、前向边（灰→黑 且先发现）、交叉边（灰→黑 且后发现）、
//   后退边（灰→灰，即指向仍在栈上的祖先）——回边的候选。
// 自然循环（回边 n→h）：{h} ∪ {能不经过 h 到达 n 的块}（反向可达）。
// 可归约：每个“后退方向”的边的目标都支配源（结构化控制流的图论化身）。
#ifndef TIP_DFS_HPP
#define TIP_DFS_HPP

#include <set>
#include <string>
#include <vector>

#include "dom.hpp"

namespace tip {

struct DfsInfo {
    std::vector<int> discover, finish;          // 时间戳
    std::vector<std::pair<int, int>> treeEdges; // (from, to)
    std::vector<std::tuple<int, int, std::string>> classified;   // (u,v,种类)
};

// succFrom: 块号 → 后继块号列表（由 blocks 预转换）。
DfsInfo dfsClassify(const std::vector<std::vector<int>> &adj);

struct NaturalLoop {
    int from, header;              // 回边 from→header
    std::set<int> body;
};

std::vector<NaturalLoop> naturalLoops(const std::vector<std::vector<int>> &adj,
                                      const DfsInfo &dfsi, const DomInfo &di);

// 可归约性：所有“指向祖先（retreating）”边的目标支配源。
bool reducible(const std::vector<std::vector<int>> &adj, const DfsInfo &dfsi,
               const DomInfo &di);

}  // namespace tip

#endif  // TIP_DFS_HPP
```

```cpp
// file: src/dfs.cpp
// file: src/dfs.cpp
// 第 37 章配套：DFS 分类、自然循环、可归约性实现。
#include "dfs.hpp"

#include <algorithm>
#include <functional>
#include <tuple>

namespace tip {

DfsInfo dfsClassify(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    DfsInfo d;
    d.discover.assign(n, -1);
    d.finish.assign(n, -1);
    std::vector<int> color(n, 0);   // 0 白、1 灰、2 黑
    int timer = 0;
    std::function<void(int)> visit = [&](int u) {
        d.discover[u] = timer++;
        color[u] = 1;
        for (int v : adj[u]) {
            if (color[v] == 0) {
                d.treeEdges.push_back({u, v});
                d.classified.push_back({u, v, "tree"});
                visit(v);
            } else if (color[v] == 1) {
                d.classified.push_back({u, v, "back"});
            } else if (d.discover[v] > d.discover[u]) {
                d.classified.push_back({u, v, "forward"});
            } else {
                d.classified.push_back({u, v, "cross"});
            }
        }
        color[u] = 2;
        d.finish[u] = timer++;
    };
    if (n > 0) visit(0);
    return d;
}

std::vector<NaturalLoop> naturalLoops(const std::vector<std::vector<int>> &adj,
                                      const DfsInfo &dfsi, const DomInfo &di) {
    (void)di;
    std::vector<NaturalLoop> out;
    for (const auto &[u, v, kind] : dfsi.classified) {
        if (kind != "back") continue;
        // 自然循环（回边 u→v）：v 支配 u 时才叫自然循环；否则是“异常回边”，
        // 归约性检查里另行处理。此处一并计算（示例程序均为自然）。
        NaturalLoop L;
        L.from = u;
        L.header = v;
        // 反向可达：从 u 往前走，遇 v 停
        std::vector<std::vector<int>> radj(adj.size());
        for (size_t a = 0; a < adj.size(); ++a)
            for (int b : adj[a]) radj[b].push_back(static_cast<int>(a));
        std::set<int> body = {v};
        std::vector<int> stack = {u};
        while (!stack.empty()) {
            int cur = stack.back();
            stack.pop_back();
            if (body.count(cur)) continue;
            body.insert(cur);
            for (int p : radj[cur]) stack.push_back(p);
        }
        L.body = body;
        out.push_back(L);
    }
    return out;
}

bool reducible(const std::vector<std::vector<int>> &adj, const DfsInfo &dfsi,
               const DomInfo &di) {
    (void)adj;   // 判定只看分类结果与支配集
    // 教学口径（紫龙 9.6.4 的充分刻画之一）：深度优先序下
    // 每条后退方向边的目标都支配源 ⇒ 可归约。
    for (const auto &[u, v, kind] : dfsi.classified) {
        if (kind != "back") continue;
        if (!di.dom[u].count(v)) return false;
    }
    return true;
}

}  // namespace tip
```

```cpp
// file: src/tacgen.hpp
// file: src/tacgen.hpp
// 第 16 章配套：AST → 三地址码（TAC）。
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
// 第 16 章配套：TAC 生成与打印。
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
// file: src/tacinterp.hpp
// file: src/tacinterp.hpp
// 第 16 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
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
// 第 16 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
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

### 44.6.6 程序与期望输出

```text
// file: programs/div.tip
main() {
  var n, i, s;
  n = input;
  i = 0;
  s = 0;
  while (n > i) {
    s = s + 100 / n;
    i = i + 1;
  }
  output s;
  return 0;
}
```

```text
; expected: expected/output.txt
== div.tip ==
== TAC ==
  0: t1 = input
  1: n = t1
  2: t2 = 0
  3: i = t2
  4: t3 = 0
  5: s = t3
  6: if n > i goto L8
  7: goto L16
  8: t4 = 100
  9: t5 = t4 / n
  10: t6 = s + t5
  11: s = t6
  12: t7 = 1
  13: t8 = i + t7
  14: i = t8
  15: goto L6
  16: output s
  17: t9 = 0
  18: return t9
== guard 插入后 ==
  0: t1 = input
  1: n = t1
  2: t2 = 0
  3: i = t2
  4: t3 = 0
  5: s = t3
  6: if n > i goto L8
  7: goto L17
  8: t4 = 100
  9: if n == 0 goto L-2
  10: t5 = t4 / n
  11: t6 = s + t5
  12: s = t6
  13: t7 = 1
  14: t8 = i + t7
  15: i = t8
  16: goto L6
  17: output s
  18: t9 = 0
  19: return t9
== loops ==
  back 4->1 body={1 3 4 }
== 消除后 ==
  0: t1 = input
  1: n = t1
  2: t2 = 0
  3: i = t2
  4: t3 = 0
  5: s = t3
  6: if n > i goto L8
  7: goto L16
  8: t4 = 100
  9: t5 = t4 / n
  10: t6 = s + t5
  11: s = t6
  12: t7 = 1
  13: t8 = i + t7
  14: i = t8
  15: goto L6
  16: output s
  17: t9 = 0
  18: return t9
== stats ==
  invariantHoisted = 1  ivEliminated = 0
  guards: 1 -> 0
  unrolled = 0（概念推演见正文 38.5）
== 对账 ==
  outputs: 96
  outputs preserved: yes
```

## 44.7 小结与练习

本章让安全
检查从税
变成选择：

- guard =
  异常条件的
  条件跳转，
  数组界与
  除零同构；
- 规则 (a)
  不变分母、
  规则 (b)
  单调归纳
  分母，
  证明安全即
  全删；
  区间推理
  是完全体；
- 插入/删除
  都过
  "目标重贴"
  的老纪律；
  往返无损
  是天然的
  回归测试；
- 循环展开
  摊薄开销、
  膨胀代码、
  喂饱下游——
  相位次序
  决定成败。

练习：

1. 手工对
   div.tip
   跑规则 (a)：
   n 的定值
   在循环外
   何处？
   循环内
   有无第二次
   定值？
2. 实现区间版：
   用 29 章
   区间分析
   得 i ∈ [0,n)、
   分母 = i
   的区间
   不含 0 ⇒
   删 guard。
   与规则 (b)
   比较：
   谁能处理
   `while (n > i) { ... 100/(i+2) ... }`？
   （提示：
    规则 (b)
    只认分母
    == i 本身。）
3. 把规则 (a)
   的删除改为
   **外提到
   preheader**：
   循环前一条
   `if n == 0 goto fail`，
   体内 guard
   删除。
   对账线不变，
   指令数差多少？
4. 给 TIP 加
   数组语法
   （`a[i]`，
   下界 0、
   上界 alloc
   尺寸），
   tacgen 生成
   `if i >= n goto fail`
   形 guard，
   用本章两规则
   + 区间版
   消除。
5. 实现
   ×2 展开
   （虎书
    "guard the
    unrolled
    body"版）：
   复制体、
   步长 ×2、
   守卫前置；
   验收：
   outputs
   不变 +
   循环头
   执行次数
   减半
   （用 13 章
    steps 计数
    对比）。
