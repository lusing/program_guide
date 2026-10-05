# 第 40 章　循环优化：不变式外提与归纳变量

## 40.1 问题：把火力对准最热的一段

经验法则：
程序 90% 的时间
花在 10% 的代码里，
那 10% 几乎总是
**循环**。
对循环的每一次
冗余计算，
都要乘上迭代次数——
循环里的优化
是放大器。

本章两个经典武器
（绿龙 13.4–13.5、
紫龙 9.1.6–9.1.8）：

- **循环不变式外提**
  （LICM，
  loop-invariant
  code motion）：
  把循环里
  "每次算出
   同一个值"的
  计算搬到循环外，
  一次算完；
- **归纳变量家族**
  （induction
  variables）：
  识别
  "每圈加一个常数"的
  变量，
  为强度削减
  （乘法换加法）
  与变量消减
  铺路。

配套示例
`examples/40_loop_opt`
实现 LICM（两轮迭代）
与归纳变量识别，
收益与保义
双双进入对账契约：
**steps 下降、
outputs 不变**。

## 40.2 preheader：外提的容器

外提到哪？
循环头**之前**
要有一个
"循环必经、
且只执行一次"的
位置——
**preheader**
（前置头）。

严格做法是
新造一个块
挂在循环头前面；
我们的 while 模板
有个天然福利：
循环头的
**唯一非循环前驱**
（while 之前的
  直线代码块）
就是现成的 preheader——
往它的块尾
（跳转指令之前）
插入即可，
**块边界与
全部跳转目标
分毫不动**。

这个"天然福利"
值得多看一眼：
它是
"结构化控制流
  对优化友好"的
又一次显形
（对照第 35 章
  可归约性）。
非结构化跳转
进循环头
（多入口）
会毁掉
preheader 的唯一性——
又是不可归约图
的罪状清单
添一笔。

## 40.3 LICM：三条安全判据

指令
`d: x = a op b`
在循环 L 里
**不变**，
如果 a、b 的值
在整个循环里
不变。
"不变"的判定
用第 29 章的
到达定值口径：
操作数在循环内
**没有任何定值**
（它们的到达定值
  全在循环外，
  或是常量）。

判定不变
只是**资格**，
外提还要过
**安全**关。
完整的经典判据
（紫龙 9.1.7）
有三条：

1. d 是 x 在循环内的
   **唯一定值**；
2. d 所在块
   **支配循环的所有出口**
   （或 x 在循环外
    无使用——
    出口后没人读，
    提前算不越权）；
3. 操作数不变。

为什么每条都必要？
各有一个
删掉就出事的反例：

- 违反 (1)：
  两条路都定义 x、
  各提一次，
  出口值取决于路径
  ——提到循环外
  只剩一个值，
  语义翻车；
- 违反 (2)：
  x 的块不支配出口
  （比如在
    只有一半迭代
    执行的分支里），
  循环可能
  一次都不执行 d，
  出口后读 x
  读到的是
  **外提前
    没算过的** x
  ——凭空造值；
- 违反 (3)：
  提出去算的
  是旧操作数，
  圈内值早变了。

教学实现取
安全子集：
(1) 唯一定值 +
(3) 操作数循环内无定值 +
(2) 的"或"分支
（t 系临时天然
  循环外无使用；
  命名变量
  检查循环外引用）。
图论版（支配出口）
留作练习——
需要第 35 章
的出口支配计算。

## 40.4 迭代的外提：一轮解锁一轮

判据 (3)
有个自反馈：
`t6 = c * t5`
在第一轮里
**不**合格
——t5 的定值
（`t5 = 2`）
还在循环**内**；
第一轮把
t5 提出去之后，
第二轮再看 t6，
操作数全在循环外了，
资格到手。

所以 LICM
天然是
**迭代到不动点**
的变换：
外提改变
"循环内定值"集合，
新集合又解锁
新的候选。
示例驱动里
明跑两轮：

```
第一轮：t4 = 5, t5 = 2, t8 = 1   （常量临时；t6 因 t5 在环内出局）
第二轮：t6 = c * t5               （t5 已在环外，资格到手）
hoisted = 4
```

对账：
steps 67 → 50
（省下的是
  每圈一次的
  c×t5 与三次
  常量装载，
  乘以迭代数）、
outputs 30
（(3×2)×5）
前后一致。

（工程实现
把迭代做进
单趟工作表；
两轮明跑
是为了让
"不动点"肉眼可见——
与第 26 章
工作表的
教学取舍同款。）

## 40.5 归纳变量：循环的等差数列

**基本归纳变量**：
循环里
形如
`i = i + c`
（c 是循环不变量）
的唯一定值变量。
i 的取值序列
是等差数列：
i₀,
i₀+c,
i₀+2c, …

TAC 上的识别
要穿透一层：
tacgen 把
`i = i + 1`
降成两连
`t9 = i + t8;
 i = t9`
（常量先进临时）。
识别模式：

```
Add(t, i, c常量) 且同块随后 Copy(i, t)
且 i 在循环内无其它定值
```

期望输出：

```
i : line 15 (i = i + 1)
```

找到基本归纳变量
能干什么？
两张牌：

- **强度削减**
  （strength
  reduction）：
  若循环里
  还有
  `j = i * c`
  （c 不变），
  则 j 也是等差
  （步长 c×c′）——
  用
  "循环前
   j₀ = i₀ × c；
   循环内
   j = j + c×c′"
  替换乘法为加法。
  乘法多周期、
  加法单周期，
  热循环里
  这是真金白银；
- **归纳变量消减**
  （induction
  variable
  elimination）：
  若 i 的**唯一**
  剩余用途
  是数圈
  （判 `5 > i`），
  而别的用途
  都已换成 j，
  则 i 本身可删
  ——少一个变量，
  第 52 章
  的寄存器压力
  就松一格。

本章实现
识别与报告；
变换
（插入 j₀、
  改写乘法、
  判定 i 可删）
是练习的主菜——
它的每一步
都要过
"outputs 不变"
的证人关。

正确性的核心
是一句不变式：

> 循环体的每次
> 执行开始时，
> j ≡ i × c。

对迭代次数
归纳即得；
j 的更新
`j += c×c′`
维持它，
j 的初值
启动它。
这是本章版的
"循环不变式"——
词源正在这里：
优化的安全性
从来都靠
不变式陈述。

## 40.6 期望输出解读

**inv.tip 段**
（c 为输入、
  循环累加
  c×2）：

- TAC 区：
  21 条，
  循环体里
  躺着
  `t4 = 5、t5 = 2、
   t8 = 1、t6 = c * t5`
  四条候选；
- loops 区：
  `back 17->9`
  领出循环体
  （第 35 章
    的输出
    换了个舞台）；
- after LICM：
  四条全数
  搬进 preheader
  （第 6-9 行，
    紧贴
    `if t4 > i`
    之前），
  循环体只剩
  真正每圈变化
  的四条；
- induction：
  i 的识别行；
- 对账：
  steps 67→50、
  outputs 30
  保持。

顺带一提
steps 的账：
67 步里
循环占 5 圈 ×
（4 条不变 +
  4 条真活）+
直线段；
50 步 =
直线段多了
4 条（外提落地）、
每圈省 4 条
——**收益与
迭代数成正比**，
这正是
循环优化的
放大器效应，
也是为什么
判据 (2)
值得那么较真。

## 40.7 工程注意点

- **外提不总是赚**。
  外提拉长了
  preheader、
  增加寄存器
  存活距离
  （第 52 章
    的压力）；
  若循环
  根本不执行，
  外提白算。
  现代编译器
  用循环轮廓
  （执行次数
    估计）与
  寄存器压力
  模型权衡。
- **除法的外提
  要防错**。
  `x = a / b`
  外提后
  若原本
  循环零次，
  除零异常
  凭空出现——
  可能触发的
  指令外提
  是语义变更。
  教学判据
  只覆盖纯算术；
  工程版
  把"可能陷阱"
  单列一类。
- **preheader
  的规范化**。
  真实编译器
  显式创建
  preheader 块
  （loop-rotate、
  loop-simplify
  一族 pass），
  而不是依赖
  结构化源码
  的天然福利；
  我们省掉它
  是因为
  TIP 的 while
  模板已经
  "被规范化"。
- **归纳变量
  与 SSA**。
  在 SSA 上
  （第 36 章），
  归纳变量
  是 φ 的
  线性函数，
  SCEV
  （scalar
  evolution）
  把它做成
  闭式表达式
  `i₀ + k·c`——
  LLVM 的
  indvars
  家族
  吃这碗饭。
- **两轮与不动点**。
  变换的迭代性
  与分析
  （第 26 章）
  同构：
  改写程序
  →重分析→
  再改写，
  直到没有
  新候选。
  级联变换的
  收敛一般
  由"每轮严格
  减少循环内
  定值数"保证。

## 40.8 本章配套文件

### 40.8.1 文法 TIP.g4

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

### 40.8.2 新件：licm.hpp 与 licm.cpp

自然循环装配、
三判据外提
（含两遍重建与
  目标重贴）、
归纳变量识别
（常量穿透）。

```cpp
// file: src/licm.hpp
// file: src/licm.hpp
// 第 40 章配套：循环不变式外提（LICM）与归纳变量家族。
//   循环来自第 35 章的自然循环；外提位置 = 唯一非循环前驱（preheader）的块尾。
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
// 第 40 章配套：LICM 与归纳变量实现。
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

### 40.8.3 驱动 main.cpp

两轮外提 +
归纳变量 +
steps/outputs
双对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 40 章驱动：--check FILE
//   TAC → 自然循环 → LICM（外提计数 + 前后 TAC + steps/outputs 对账）
//   → 归纳变量识别（报告 i = i + c）。
#include "licm.hpp"
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

    tip::LoopInfo li = tip::loopsOf(code, blocks);
    std::cout << "== loops ==\n";
    for (const auto &L : li.loops) {
        std::cout << "  back " << L.from << "->" << L.header << " body={";
        bool first = true;
        for (int b : L.body) {
            std::cout << (first ? "" : ",") << b;
            first = false;
        }
        std::cout << "}\n";
    }

    // 两轮外提：第一轮提出 t5=2 后，t6=c*t5 的操作数即全部循环外（迭代的直观演示）
    auto [h1, n1] = tip::licm(code, blocks, li);
    std::vector<tip::Quad> hoistedCode = h1;
    int nHoist = n1;
    {
        std::vector<tip::Block> b2 = tip::partitionBlocks(hoistedCode);
        tip::LoopInfo li2 = tip::loopsOf(hoistedCode, b2);
        auto [h2, n2] = tip::licm(hoistedCode, b2, li2);
        hoistedCode = h2;
        nHoist += n2;
    }
    std::cout << "== after LICM (两轮) ==\n";
    for (size_t i = 0; i < hoistedCode.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(hoistedCode[i]) << '\n';
    std::cout << "  hoisted = " << nHoist << '\n';

    std::cout << "== induction variables ==\n";
    for (const auto &L : li.loops) {
        auto ivs = tip::indVars(code, blocks, L);
        for (const auto &iv : ivs)
            std::cout << "  " << iv.var << " : line " << iv.incrLine
                      << " (" << iv.var << " = " << iv.var << " + " << iv.incr << ")\n";
    }

    std::cout << "== 对账 ==\n";
    tip::TacRun before = tip::tacInterp(code, {3});
    tip::TacRun after = tip::tacInterp(hoistedCode, {3});
    std::cout << "  steps: " << before.steps << " -> " << after.steps << '\n';
    std::cout << "  outputs:";
    for (int v : before.outputs) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before.outputs == after.outputs ? "yes" : "NO") << '\n';
    return (before.outputs == after.outputs && after.steps <= before.steps) ? 0 : 1;
}
```

### 40.8.4 基座：支配者与 DFS（第 35 章）

```cpp
// file: src/dom.hpp
// file: src/dom.hpp
// 第 35 章配套之一：支配者（dominators）与支配树。
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
// 第 35 章配套：支配者实现。
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
// 第 35 章配套之二：DFS 边分类、自然循环、可归约性。
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
// 第 35 章配套：DFS 分类、自然循环、可归约性实现。
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

### 40.8.5 TAC 基座与前端（第 13、8、10 章）

```cpp
// file: src/tacgen.hpp
// file: src/tacgen.hpp
// 第 14 章配套：AST → 三地址码（TAC）。
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
// 第 14 章配套：TAC 生成与打印。
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
// 第 14 章配套：leader 划分基本块 + 块内 next-use 信息。
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
// 第 14 章配套：leader 划分与 next-use。
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
// 第 14 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
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
// 第 14 章配套：TAC 解释器——后续一切变换的“具体语义证人”。
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

### 40.8.6 程序与期望输出

```text
// file: programs/inv.tip
main() {
  var c, i, s, t;
  c = input;
  s = 0;
  i = 0;
  while (5 > i) {
    t = c * 2;
    s = s + t;
    i = i + 1;
  }
  output s;
  return 0;
}
```

```text
; expected: expected/output.txt
== inv.tip ==
== TAC ==
  0: t1 = input
  1: c = t1
  2: t2 = 0
  3: s = t2
  4: t3 = 0
  5: i = t3
  6: t4 = 5
  7: if t4 > i goto L9
  8: goto L18
  9: t5 = 2
  10: t6 = c * t5
  11: t = t6
  12: t7 = s + t
  13: s = t7
  14: t8 = 1
  15: t9 = i + t8
  16: i = t9
  17: goto L6
  18: output s
  19: t10 = 0
  20: return t10
== loops ==
  back 3->1 body={1,3}
== after LICM (两轮) ==
  0: t1 = input
  1: c = t1
  2: t2 = 0
  3: s = t2
  4: t3 = 0
  5: i = t3
  6: t4 = 5
  7: t5 = 2
  8: t8 = 1
  9: t6 = c * t5
  10: if t4 > i goto L12
  11: goto L18
  12: t = t6
  13: t7 = s + t
  14: s = t7
  15: t9 = i + t8
  16: i = t9
  17: goto L10
  18: output s
  19: t10 = 0
  20: return t10
  hoisted = 4
== induction variables ==
  i : line 15 (i = i + 1)
== 对账 ==
  steps: 67 -> 50
  outputs: 30
  outputs preserved: yes
```

## 40.9 小结与练习

本章把分析的
火力对准循环：

- preheader
  是外提的
  唯一安全落点，
  结构化控制流
  天然奉送；
- 三条判据
  （唯一定值、
    操作数不变、
    出口可见性）
  各自拦一种
  语义翻车，
  少一条都不行；
- 外提是
  迭代变换：
  一轮的成果
  解锁下一轮的
  资格；
- 归纳变量
  是循环里的
  等差数列，
  强度削减
  把乘法换成
  加法，
  消减把
  纯数圈的变量
  送走；
- 一切收益
  以 steps 下降
  计账、
  以 outputs
  不变担保。

下一章是
数据流分析的
集大成者：
部分冗余消除
用六条方程
把"最晚算、
只算一次"
写成一套
完整的几何。

练习：

1. 手工对 inv.tip
   验证三条判据
   如何放行
   t4/t5/t8、
   第一轮拦下
   t6、
   第二轮放行；
2. 构造违反判据 (2)
   的反例
   （提示：
    if 分支内
    定义、
    分支条件
    让某些迭代
    跳过它），
   说明外提
   如何凭空造值；
3. 实现强度削减：
   识别
   `j = i × c`
   （c 循环不变）
   后插入
   preheader 的
   j₀ 与圈内的
   `j = j + c`，
   删除乘法，
   对账
   steps 与 outputs；
4. 实现判据 (2)
   的图论版：
   用支配信息
   判定
   "d 所在块支配
    所有出口"，
   放行一个
   循环外使用
   的变量外提；
5. 把 inv.tip 的
   循环改成嵌套
   （内圈乘外圈
    不变量），
   观察两轮 LICM
   各提到哪一层、
   steps 收益
   如何按
   迭代数放大。
