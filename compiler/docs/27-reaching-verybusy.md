# 第 27 章　到达定值与非常忙表达式：四大经典的补全

## 27.1 问题：还缺的两块拼图

第 26 章拿下了
四大经典数据流分析
中的两个：
活跃变量（后向 may）、
可用表达式（前向 must）。
本章补齐另外两个：

- **到达定值**
  （reaching definitions）：
  前向 **may**——
  "某定值可能流到某点"；
- **非常忙表达式**
  （very busy expressions）：
  后向 **must**——
  "从某点出发
   每条路径都会
   在改操作数之前
   用到某表达式"。

四个分析按
**方向 × 合并方式**
排成一张 2×2 表
（绿龙 §14.6 的
经典总结，
完整转写）：

| 分析 | 方向 | 合并 | 域 | 询问 |
|---|---|---|---|---|
| 到达定值 | 前向 | 并（may） | 定值集合 | 哪些定值**可能**到达 |
| 可用表达式 | 前向 | 交（must） | 表达式集合 | 哪些表达式**必定**已算好 |
| 活跃变量 | 后向 | 并（may） | 变量集合 | 哪些变量的值**还可能**被用 |
| 非常忙表达式 | 后向 | 交（must） | 表达式集合 | 哪些表达式**必定**将被用 |

may 行回答
"有没有可能"
（over-approximate，
并出更多可能），
must 行回答
"是不是一定"
（同样 over-approximate，
交出更少承诺）。
两行共用同一套
方程骨架，
差别只在
方向与 meet。
本章还会给每个新分析
配一个应用：
复制传播（吃到达定值）、
代码提升（吃非常忙）——
分析的价值
永远在使用它的
变换里兑现。

## 27.2 到达定值

### 27.2.1 定义与方程

定值
（definition）=
一条给变量赋值的指令。
定值 d（变量 v 的）
**到达**点 p，
如果存在一条
从 d 到 p 的执行路径，
路径上**没有**
对 v 的其它定值。

注意"可能"：
只要存在一条路径
就算到达——
这是 may 语义，
分支会让两路的定值
**都**到达汇合点。

方程
（前向，
in 从前驱来）：

```
in[B]  = ∪ out[P]        （P 取遍 B 的前驱）
out[B] = gen[B] ∪ (in[B] − kill[B])
```

- **gen[B]**：
  块内"向下冒出来"的
  定值——
  同块后面有同变量的
  更晚定值时，
  早的被遮蔽；
- **kill[B]**：
  块内定值变量的
  **其它一切定值**
  （全程序的）——
  无论它们在哪个块。

kill 的"全域"口径
是到达定值的特征：
一次定值杀掉的是
同变量历史上
所有竞争者。

### 27.2.2 正确性的直觉

对路径长度归纳：
out 方程说的正是
"沿这条路流过来
  没被中途杀死
  的定值集合"；
汇合点的 ∪
把所有来路
的集合并起来
——"可能到达"
的语义被
方程逐字复述。
精度损失
同样来自 ∪：
两条路各杀了
一个定值的不同副本时，
并起来会多报
"可能到达"
——保守方向的错，
错得安全。

### 27.2.3 ud 链

到达定值的
直接产品是
**ud 链**
（use-definition chain）：
使用点 u（用了变量 v）
的 ud 链 =
到达 u 的
v 的定值集合。
求法：
块 IN 里 v 的定值，
加上块内 u 之前
v 的最后定值
（它遮蔽 IN 里的）。

期望输出里的
ud-chains 段：

```
4: use y <- 2
```

"第 4 行用 y，
  能到达它的
  只有第 2 行的定值"——
单一元素的链
正是复制传播
要下钩的地方。

## 27.3 复制传播：到达定值的第一份工资

**复制传播**
（copy propagation，
绿龙 §14.3）：
对 `y = x` 这类
纯复制定值，
若某使用点 y 的
ud 链**恰好只有
这条复制**，
则该处 y 可换成 x。

三条注意：

1. **链必须唯一**。
   两条定值到达
   （一条是 y=x，
    一条是别的路径
    重新赋了 y），
   换就换错了。
   链的"恰好一条"
   是安全阀；
2. **copy 的源不换**：
   `x = x` 这类自喂
   不在传播之列；
3. **删除要看使用**：
   传播完后，
   若某 copy 的左值
   再无任何使用
   （操作数里
    一处也不出现），
   这条 copy 就是死代码，
   可以删——
   右端是纯变量读，
   无副作用，
   删除保义。

期望输出
（copy.tip）：

```
before: 0: t1 = 4 ; 1: x = t1 ; 2: y = x ; 3: t2 = 1 ;
        4: t3 = y + t2 ; 5: z = t3 ; 6: output z ; ...
after:  0: t1 = 4 ; 1: x = t1 ; 2: t2 = 1 ; 3: t3 = x + t2 ;
        4: output t3 ; ...
stats: replaced=2 deleted=2
```

replaced=2：
`t3 = y + t2` 的 y
换成 x、
`output z` 的 z
换成 t3；
deleted=2：
`y = x` 与 `z = t3`
双双失去使用者
而被删。
九行变七行，
对账行
`outputs(before) == outputs(copy-prop): yes`
——TAC 解释器
（第 13 章的证人）
按字面验收。

**删除的重映射**：
指令删了，
行号全体前移，
所有跳转目标
必须重贴。
实现里的一步：
被删指令的
"入跳"
落到其后
第一条保留指令
（oldToNew 的
逆序回填），
尾哨兵挂新末尾。
漏了这步，
程序会在
错位的标签上
跳进沟里。

## 27.4 非常忙表达式

### 27.4.1 定义与方程

表达式 e
在点 p **非常忙**，
如果从 p 出发的
**每条**路径
都会在
e 的操作数被
重新定值**之前**
求值 e。

"每条"= must；
"之前被用"——
与活跃变量的
"将来被用"
神似，
只是把对象
从变量换成表达式，
把 may 换成 must。

方程
（后向，
out 从后继来）：

```
out[B] = ∩ in[S]           （S 取遍 B 的后继）
in[B]  = (out[B] − kill[B]) ∪ gen[B]
```

- **gen[B]**：
  块内先被求值、
  之后才谈得上杀的
  表达式
  （后向扫描时
   先记 kill 后记 gen
   ——顺序保证
   `x = x + 1` 这类
   "边算边杀"
   仍算 gen）；
- **kill[B]**：
  操作数被重定义
  所杀死的一切
  含该操作数的
  表达式。

出口块约定
out = ∅：
出口之后
没有任何计算，
"每条路径都会用"
无从谈起。

must 语义的
保守方向：
交不出来就少报
——说"非常忙"
而其实不忙，
是变换可能
白算一次；
绝不说"不忙"
而其实忙
（那是漏报，
会改语义）。
迭代从
"全忙"的顶
单调下降到
不动点
（与第 26 章
可用表达式
同款）。

### 27.4.2 一个真实的调试：in[B] 为什么救不了提升

本章实现时
踩过一个
值得留档的坑。
最初的提升判据
写成
"e ∈ verybusy(**in[B]**)，
  且 B 的两个后继
  都先算 e"。
跑 hoist.tip：
分析输出完全正确
（分支块的 IN 里
明明白白躺着
`{a * b}`），
提升却始终为零。

病根：
判据里那个 B
是**含条件跳转的块**，
而 B 自己
刚刚定义了
a 和 b
（`a = 7; b = 3; if (a > b)…`）。
按定义，
`a * b` 在 B 的
**入口**当然不非常忙
——操作数还没定值呢！
真正描述
"分支分岔前那一刻"
的集合是
**out[B]**：
B 内的定值已经做完、
后继的承诺即将生效。

把判据换成
e ∈ verybusy(**out[B]**)，
提升立刻落位。
教训泛化：
**选择 in 还是 out，
  不是风格问题，
  是"你问的是
  哪个时刻"**——
  每个数据流结果
  都带着隐式的
  时间戳，
  用错时刻的分析
  会让变换静默失效
  （幸好这次是
  "什么都不做"，
  而不是
  "做错"）。

## 27.5 代码提升：非常忙的第一份工资

**代码提升**
（code hoisting，
绿龙 §14.5）：
若表达式 e
在分支点非常忙
（两条后继路
  都马上要算它），
  就把它提到
  分支**之前**算一次，
  两条路共用结果。

正确性一句话：
very busy 保证
"无论走哪条路
  这笔计算都跑不掉"，
提前算不白算；
操作数在
分支前到分支后
没被改写
（不然它就不忙了），
提前算的值
与原地算的
相同。

本章实现抓
if 模板的
典型形态：
分岔块 B
（块尾条件跳转）
的两个后继路径
——穿过纯跳板的
那路和直进的
那路——
第一个真实计算
是同一个表达式。
变换三步：

1. 在 B 的条件跳转
   之前插
   `th1 = t1 * t2`；
2. 两处原计算改成
   `t3 = th1`、
   `t6 = th1`（复制）；
3. 插入点之后的
   全部跳转目标 +1。

期望输出
（hoist.tip，
copy-prop 之后）：

```
before: 2: if t1 > t2 goto L4 ; ... 4: t3 = t1 * t2 ... 9: t6 = t1 * t2 ...
after:  2: th1 = t1 * t2
        3: if t1 > t2 goto L5
        4: goto L10
        5: t3 = th1 ...
        10: t6 = th1 ...
stats: hoisted=1 (t1 * t2 -> th1)
```

对账行两连 yes。
注意第 3 条的
目标移位
（L4→L5、L9→L10、
L13→L14）——
与复制传播的
删除重映射同属
"动了指令就要
重贴标签"的
纪律。

（实现只做
单处提升即收工：
结构化模板里
每次至多一个
候选，
通用版需要
对候选集合
迭代到不动点——
那是第 39 章
部分冗余消除
的正餐。）

## 27.6 期望输出解读

**copy.tip 段**：
单块直线程序。
reaching OUT
一行列全七条定值
（直线块，
  无遮蔽）；
ud-chains
每用一链、
全部单元素；
very busy 全空
（没有分支，
  后继为空，
  out 从 ∅ 起步）；
copy-prop
replaced=2 deleted=2；
hoist 无候选；
对账两 yes。

**hoist.tip 段**：
五块菱形。
reaching OUT
逐块累进——
B2 加进 then 侧的
四条定值，
B3 加进 else 侧的，
B4 并成全集：
**同一变量 c 的
两路定值同时
到达出口**
（9:c 与 14:c
并肩在列），
may 语义的
"多报不漏报"
肉眼可见。
very busy 的
IN 在 B1/B2/B3
都是 {a * b}
（初版实现用的
正是这个集合，
26.4.2 的坑
就埋在这里），
提升判据换到
out 后落位。
copy-prop
在这个程序上
replaced=6
（常量临时
  与变量之间的
  复制链条
  被整段拉直）、
deleted=2；
hoist 后 th1
立在分支前。
对账两 yes。

## 27.7 工程注意点

- **定值的标识**。
  本章用
  "TAC 行号"
  标识定值
  ——最细粒度、
  无歧义；
  真实编译器
  常用
  (指令指针，
    SSA 编号)
  或直接上
  SSA（第 34 章）
  让 ud 链
  变成显式边。
- **kill 的匹配**。
  表达式键
  以空格分界
  （`a + b`），
  杀操作数时
  按整词匹配
  ——若用朴素
  子串匹配，
  变量 t1 会
  误杀含 t12 的
  表达式。
  文本表示的
  边界纪律，
  一处都不能松。
- **may 与 must
  的初始化**。
  迭代初值：
  may 用 ∅
  （从"无"爬上来），
  must 用全集
  （从"全"落下去）；
  入口边界：
  到达定值 in[entry]=∅，
  非常忙
  out[exit]=∅。
  初值给反了
  会把不动点
  顶到错误的
  那一侧。
- **变换后的重分析**。
  copy-prop 改了
  程序，
  后续 hoist 用的是
  **新程序上重算**
  的 very busy
  （blocks2/vb2），
  而不是旧结果
  ——级联变换的
  铁律：
  每步变换后
  分析必须重跑
  或证明
  不受影响。
- **对账即回归**。
  每个变换
  配一条
  outputs 前后相等
  的机器断言，
  本章两条；
  第 34/35/36 章
  会把这条纪律
  用到
  收益计数
  （steps 下降）
  上。

## 27.8 本章配套文件

### 27.8.1 文法 TIP.g4

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

### 27.8.2 新件：reach.hpp 与 reach.cpp

gen/kill、
前向 may 方程、
ud 链。

```cpp
// file: src/reach.hpp
// file: src/reach.hpp
// 第 27 章配套之一：到达定值（reaching definitions）——四大经典之三。
// 域 = 定值集合（TAC 行号）；方向 = 前向；合并 = 并（may）。
// in[B] = ∪ out[P]（前驱）；out[B] = gen[B] ∪ (in[B] - kill[B])。
#ifndef TIP_REACH_HPP
#define TIP_REACH_HPP

#include <map>
#include <set>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 每块的 gen/kill 与不动点解。定值用“行号:变量”标识。
struct ReachInfo {
    std::vector<std::set<int>> in, out;          // 每块的 IN/OUT 定值行号集
    std::vector<std::set<int>> gen, kill;        // gen：块内“冒出来”的定值
    std::map<int, std::string> defVar;           // 行号 → 被定值的变量
};

// 迭代到不动点（第 24 章工作表骨架的又一实例化：这里用轮转直到稳定）。
ReachInfo reaching(const std::vector<Quad> &code, const std::vector<Block> &blocks);

// ud 链：指令 i 处变量 v 的使用，能到达它的定值行号集。
std::set<int> udChain(const ReachInfo &ri, const std::vector<Block> &blocks,
                      int i, const std::string &v);

}  // namespace tip

#endif  // TIP_REACH_HPP
```

```cpp
// file: src/reach.cpp
// file: src/reach.cpp
// 第 27 章配套：到达定值实现。
#include "reach.hpp"

#include <cctype>

namespace tip {

namespace {
bool defInstr(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

ReachInfo reaching(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    ReachInfo ri;
    size_t n = blocks.size();
    ri.in.assign(n, {});
    ri.out.assign(n, {});
    ri.gen.assign(n, {});
    ri.kill.assign(n, {});
    for (int i = 0; i < static_cast<int>(code.size()); ++i)
        if (defInstr(code[i])) ri.defVar[i] = code[i].dst;
    // gen[B]：块内“向下冒出来”的定值（同块更晚的同变量定值会遮蔽更早的）；
    // kill[B]：块内定值变量的其它全部定值。
    for (size_t b = 0; b < n; ++b) {
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            auto it = ri.defVar.find(i);
            if (it == ri.defVar.end()) continue;
            const std::string &v = it->second;
            ri.gen[b].insert(i);
            for (int j = blocks[b].begin; j < i; ++j)
                if (ri.defVar.count(j) && ri.defVar.at(j) == v) ri.gen[b].erase(j);
            for (const auto &d : ri.defVar)
                if (d.second == v && d.first != i) ri.kill[b].insert(d.first);
        }
    }
    // 前向 may：in = ∪ 前驱 out；out = gen ∪ (in − kill)。迭代至稳定——
    // 值只会增（may 半格上单调上升），有限高度保证终止（第 23 章的论证）。
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 0; b < n; ++b) {
            std::set<int> in;
            for (size_t q = 0; q < n; ++q)
                for (int s : blocks[q].succs)
                    if (s == blocks[b].begin)
                        in.insert(ri.out[q].begin(), ri.out[q].end());
            std::set<int> out = ri.gen[b];
            for (int d : in)
                if (!ri.kill[b].count(d)) out.insert(d);
            if (in != ri.in[b] || out != ri.out[b]) {
                ri.in[b] = in;
                ri.out[b] = out;
                changed = true;
            }
        }
    }
    return ri;
}

std::set<int> udChain(const ReachInfo &ri, const std::vector<Block> &blocks,
                      int i, const std::string &v) {
    // IN 里的 v 定值，加上块内 i 之前 v 的最后定值（它遮蔽 IN）。
    std::set<int> out;
    size_t b = 0;
    for (size_t k = 0; k < blocks.size(); ++k)
        if (i >= blocks[k].begin && i < blocks[k].end) { b = k; break; }
    for (int d : ri.in[b])
        if (ri.defVar.at(d) == v) out.insert(d);
    for (int j = blocks[b].begin; j < i; ++j)
        if (ri.defVar.count(j) && ri.defVar.at(j) == v) {
            out.clear();
            out.insert(j);
        }
    return out;
}

}  // namespace tip
```

### 27.8.3 新件：verybusy.hpp 与 verybusy.cpp

表达式键、
后向 must 方程。

```cpp
// file: src/verybusy.hpp
// file: src/verybusy.hpp
// 第 27 章配套之二：非常忙表达式（very busy expressions）——四大经典之四。
// 域 = 表达式集合（规范化键 "a + b"）；方向 = 后向；合并 = 交（must）。
// 表达式 e 在点 p 非常忙 ⟺ 从 p 出发的**每条**路径都会
// 在操作数被重定义之前求值 e。
#ifndef TIP_VERYBUSY_HPP
#define TIP_VERYBUSY_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

std::string exprKey(const Quad &q);   // "a + b" / "a > b" / 复制与其它返回 ""

struct VeryBusyInfo {
    std::vector<std::set<std::string>> in, out;
};

VeryBusyInfo veryBusy(const std::vector<Quad> &code, const std::vector<Block> &blocks);

}  // namespace tip

#endif  // TIP_VERYBUSY_HPP
```

```cpp
// file: src/verybusy.cpp
// file: src/verybusy.cpp
// 第 27 章配套：非常忙表达式实现。
#include "verybusy.hpp"

#include <sstream>

namespace tip {

std::string exprKey(const Quad &q) {
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

namespace {
// 表达式键以空格分界操作数（“a + b”），整词判定才不误伤（t1 不得匹配 t12）。
bool sharesOperand(const std::string &key, const std::string &var) {
    if (key.rfind(var + " ", 0) == 0) return true;             // 左操作数
    size_t sp = key.rfind(" " + var);
    if (sp != std::string::npos &&
        sp + 1 + var.size() == key.size()) return true;        // 右操作数
    return key.find(" " + var + " ") != std::string::npos;     // 中缀位置（不出现，保险）
}
}  // namespace

VeryBusyInfo veryBusy(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    VeryBusyInfo vb;
    vb.in.assign(n, {});
    vb.out.assign(n, {});
    // 块内逐条传递（后向）：e_gen = 本块先被使用、后才被杀的表达式；
    // e_kill = 操作数被重定义所杀掉的表达式。
    auto transfer = [&](size_t b, std::set<std::string> s) {
        for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
            const Quad &q = code[i];
            // 先杀：本条重定义 dst → 含 dst（作为整操作数）的表达式出局
            if (!q.dst.empty()) {
                for (auto it = s.begin(); it != s.end();) {
                    if (sharesOperand(*it, q.dst)) it = s.erase(it);
                    else ++it;
                }
            }
            // 再生：本条若是表达式，键入集
            std::string k = exprKey(q);
            if (!k.empty()) s.insert(k);
        }
        return s;
    };
    // 后向 must：out[B] = ∩ in[S]，S 取遍 B 的后继块（begin == B 的 succ 下标）；
    // 无后继（出口块）约定 out = ∅——出口之后没有计算，没有“非常忙”可言。
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = n; b-- > 0;) {
            std::set<std::string> out;
            bool first = true;
            for (int s : blocks[b].succs) {
                size_t c = 0;
                for (size_t k = 0; k < n; ++k)
                    if (blocks[k].begin == s) { c = k; break; }
                if (first) { out = vb.in[c]; first = false; }
                else {
                    std::set<std::string> keep;
                    for (const auto &e : out)
                        if (vb.in[c].count(e)) keep.insert(e);
                    out = keep;
                }
            }
            std::set<std::string> in = transfer(b, out);
            if (in != vb.in[b] || out != vb.out[b]) {
                vb.in[b] = in;
                vb.out[b] = out;
                changed = true;
            }
        }
    }
    return vb;
}

}  // namespace tip
```

### 27.8.4 新件：apps.hpp 与 apps.cpp

复制传播
（含删除与
目标重映射）
与代码提升
（含插入与
目标移位）。

```cpp
// file: src/apps.hpp
// file: src/apps.hpp
// 第 27 章配套之三：两个应用变换。
//   copyProp：复制传播（到达定值/ud 链驱动）+ 死 copy 删除；
//   hoist   ：代码提升（非常忙驱动）——把分支两侧重复的“分支后立刻要”
//             的表达式提到条件跳转之前。
// 两者都改写 TAC 并重映射跳转目标；验收由驱动用 TAC 解释器对账。
#ifndef TIP_APPS_HPP
#define TIP_APPS_HPP

#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "reach.hpp"
#include "verybusy.hpp"

namespace tip {

struct CopyPropResult {
    int replaced = 0;
    int deleted = 0;
};

struct HoistResult {
    int inserted = 0;   // 同时兼作临时计数器
    int hoisted = 0;
    std::vector<std::string> detail;
};

CopyPropResult copyProp(std::vector<Quad> &code, const ReachInfo &ri,
                        const std::vector<Block> &blocks);
HoistResult hoist(std::vector<Quad> &code, const VeryBusyInfo &vb,
                  const std::vector<Block> &blocks);

}  // namespace tip

#endif  // TIP_APPS_HPP
```

```cpp
// file: src/apps.cpp
// file: src/apps.cpp
// 第 27 章配套：复制传播与代码提升的实现。
#include "apps.hpp"

#include <cctype>

namespace tip {

namespace {
bool isNumA(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVar(const std::string &s) { return !s.empty() && !isNumA(s); }

}  // namespace

CopyPropResult copyProp(std::vector<Quad> &code, const ReachInfo &ri,
                        const std::vector<Block> &blocks) {
    CopyPropResult r;
    // 第一遍：使用点替换——ud 链唯一且那条定值是 copy x = s 时，用 s 替换 x。
    for (size_t i = 0; i < code.size(); ++i) {
        Quad &q = code[i];
        bool usesA = q.op == TOp::Add || q.op == TOp::Sub || q.op == TOp::Mul ||
                     q.op == TOp::Div || q.op == TOp::Gt || q.op == TOp::Eq ||
                     q.op == TOp::IfGt || q.op == TOp::IfEq ||
                     q.op == TOp::Output || q.op == TOp::Ret;
        bool usesB = q.op == TOp::Add || q.op == TOp::Sub || q.op == TOp::Mul ||
                     q.op == TOp::Div || q.op == TOp::Gt || q.op == TOp::Eq ||
                     q.op == TOp::IfGt || q.op == TOp::IfEq;
        if (q.op == TOp::Copy) usesA = false;   // copy 的源不替换，防 x = x 自喂
        if (usesA && isVar(q.a)) {
            std::set<int> chain = udChain(ri, blocks, static_cast<int>(i), q.a);
            if (chain.size() == 1) {
                const Quad &d = code[*chain.begin()];
                if (d.op == TOp::Copy && isVar(d.a) && d.a != q.a) {
                    q.a = d.a;
                    ++r.replaced;
                }
            }
        }
        if (usesB && isVar(q.b)) {
            std::set<int> chain = udChain(ri, blocks, static_cast<int>(i), q.b);
            if (chain.size() == 1) {
                const Quad &d = code[*chain.begin()];
                if (d.op == TOp::Copy && isVar(d.a) && d.a != q.b) {
                    q.b = d.a;
                    ++r.replaced;
                }
            }
        }
    }
    // 第二遍：删除死 copy。判定用变量级保守口径：
    // 变量→变量 copy，且其左值不再出现在任何操作数里。
    std::set<std::string> usedVars;
    for (const auto &q : code) {
        if (isVar(q.a) && !(q.op == TOp::Copy)) usedVars.insert(q.a);
        if (q.op == TOp::Copy && isVar(q.a)) usedVars.insert(q.a);   // copy 也算“使用”了源
        if (isVar(q.b)) usedVars.insert(q.b);
    }
    std::vector<bool> keep(code.size(), true);
    for (size_t i = 0; i < code.size(); ++i) {
        if (code[i].op == TOp::Copy && isVar(code[i].a) &&
            !usedVars.count(code[i].dst)) {
            keep[i] = false;
            ++r.deleted;
        }
    }
    // 重映射：被删指令的“入跳”落到其后第一条保留指令；哨兵挂新末尾。
    std::vector<int> oldToNew(code.size() + 1, -1);
    int n2 = 0;
    for (size_t i = 0; i < code.size(); ++i)
        if (keep[i]) oldToNew[i] = n2++;
    oldToNew[code.size()] = n2;
    for (size_t i = code.size(); i-- > 0;)
        if (oldToNew[i] == -1) oldToNew[i] = oldToNew[i + 1];
    std::vector<Quad> rebuilt;
    for (size_t i = 0; i < code.size(); ++i)
        if (keep[i]) rebuilt.push_back(code[i]);
    for (auto &q : rebuilt) {
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
            q.target = oldToNew[q.target];
    }
    code = std::move(rebuilt);
    return r;
}

HoistResult hoist(std::vector<Quad> &code, const VeryBusyInfo &vb,
                  const std::vector<Block> &blocks) {
    HoistResult r;
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < blocks.size(); ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return k;
        return blocks.size();
    };
    // 从某条路径出发，跳过“纯跳转块”（if 模板的 goto 弹簧），
    // 找到第一个真实计算指令；返回其下标，找不到返回 -1。
    auto firstComputation = [&](int start) -> int {
        int guard = 0;
        size_t k = blockOf(start);
        while (k < blocks.size() && guard++ < 100) {
            for (int i = blocks[k].begin; i < blocks[k].end; ++i) {
                if (exprKey(code[i]).empty()) continue;
                return i;   // 首个表达式计算（跳转指令 exprKey 为空，天然跳过）
            }
            // 本块全是跳转/非计算：沿唯一后继走
            if (blocks[k].succs.size() != 1) return -1;
            int s = *blocks[k].succs.begin();
            k = blockOf(s);
        }
        return -1;
    };
    for (size_t b = 0; b < blocks.size(); ++b) {
        if (blocks[b].succs.size() != 2) continue;
        // 判据用“块出口”的非常忙（out[B]）：提升点在分支之前、
        // B 内定值之后——正是 out[B] 描述的位置（in[B] 会被 B 自己的
        // 操作数定值合法地排除，见正文 26.5 的讨论）。
        for (const std::string &e : vb.out[b]) {
            std::vector<int> sites;
            bool ok = true;
            for (int s : blocks[b].succs) {
                int site = firstComputation(s);
                if (site < 0 || exprKey(code[site]) != e) { ok = false; break; }
                sites.push_back(site);
            }
            if (!ok || sites.size() != 2) continue;
            int insertAt = blocks[b].end - 1;   // 条件跳转之前
            std::string tH = "th" + std::to_string(r.hoisted + 1);
            Quad nq = code[sites[0]];
            nq.dst = tH;
            code.insert(code.begin() + insertAt, nq);
            // 插入点之后的跳转目标整体 +1；两处使用改写为复制。
            for (auto &q : code)
                if ((q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq) &&
                    q.target > insertAt)
                    ++q.target;
            for (int site : sites)
                code[site + 1] = Quad{TOp::Copy, code[site + 1].dst, tH, "", -1};
            ++r.hoisted;
            r.inserted = r.hoisted;
            r.detail.push_back(e + " -> " + tH);
            return r;   // 结构化模板每次至多一处候选，见正文 26.6 的说明
        }
    }
    return r;
}

}  // namespace tip
```

### 27.8.5 驱动 main.cpp

分析、变换、
两级对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 27 章驱动：--check FILE
//   TAC → 到达定值（逐块 OUT + ud 链）→ 非常忙（逐块 IN）→
//   复制传播变换 → 代码提升变换 → 每步变换后解释器 outputs 对账。
#include "reach.hpp"
#include "verybusy.hpp"
#include "apps.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"

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

void dumpCode(const std::vector<tip::Quad> &code, const std::string &title) {
    std::cout << "== " << title << " ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';
}

void dumpBlocks(const std::vector<tip::Block> &blocks) {
    std::cout << "== blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << ' ' << s;
        std::cout << '\n';
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto ast = parseFile(argv[2]);
    const tip::FunDecl &fn = *ast->funs.front();
    std::vector<tip::Quad> code = tip::tacGen(fn);
    dumpCode(code, "TAC");
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    dumpBlocks(blocks);

    // ---------- 到达定值 ----------
    tip::ReachInfo ri = tip::reaching(code, blocks);
    std::cout << "== reaching (OUT) ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << ":";
        for (int d : ri.out[b]) std::cout << ' ' << d << ':' << ri.defVar.at(d);
        std::cout << '\n';
    }
    std::cout << "== ud-chains ==\n";
    for (size_t i = 0; i < code.size(); ++i) {
        const tip::Quad &q = code[i];
        bool shown = false;
        for (const std::string *s : {&q.a, &q.b}) {
            if (s->empty() || isdigit((*s)[0])) continue;
            if (q.op == tip::TOp::Goto) continue;
            std::set<int> ch = tip::udChain(ri, blocks, static_cast<int>(i), *s);
            std::cout << "  " << i << ": use " << *s << " <-";
            for (int d : ch) std::cout << ' ' << d;
            std::cout << '\n';
            shown = true;
        }
        (void)shown;
    }

    // ---------- 非常忙 ----------
    tip::VeryBusyInfo vb = tip::veryBusy(code, blocks);
    std::cout << "== very busy (IN) ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << ":";
        for (const auto &e : vb.in[b]) std::cout << " {" << e << "}";
        std::cout << '\n';
    }

    // ---------- 变换与对账 ----------
    std::vector<int> before = tip::tacInterp(code, {}).outputs;

    std::vector<tip::Quad> cp = code;
    tip::CopyPropResult cr = tip::copyProp(cp, ri, blocks);
    dumpCode(cp, "after copy-prop");
    std::cout << "  stats: replaced=" << cr.replaced << " deleted=" << cr.deleted << '\n';
    std::vector<int> afterCp = tip::tacInterp(cp, {}).outputs;

    std::vector<tip::Block> blocks2 = tip::partitionBlocks(cp);
    tip::VeryBusyInfo vb2 = tip::veryBusy(cp, blocks2);
    std::vector<tip::Quad> hs = cp;
    tip::HoistResult hr = tip::hoist(hs, vb2, blocks2);
    dumpCode(hs, "after hoist");
    std::cout << "  stats: hoisted=" << hr.hoisted;
    for (const auto &d : hr.detail) std::cout << " (" << d << ")";
    std::cout << '\n';
    std::vector<int> afterHs = tip::tacInterp(hs, {}).outputs;

    std::cout << "== 对账 ==\n";
    std::cout << "  outputs(before) == outputs(copy-prop): "
              << (before == afterCp ? "yes" : "NO") << '\n';
    std::cout << "  outputs(before) == outputs(hoist): "
              << (before == afterHs ? "yes" : "NO") << '\n';
    return (before == afterCp && before == afterHs) ? 0 : 1;
}
```

### 27.8.6 基座：tacgen、tacblocks、tacinterp

第 13 章原样
（本示例单函数，
  不含调用）。

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

### 27.8.7 前端基础件：ast、ast_build、symtab

第 8、10 章原样。

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

### 27.8.8 程序与期望输出

```text
// file: programs/copy.tip
main() {
  var x, y, z;
  x = 4;
  y = x;
  z = y + 1;
  output z;
  return 0;
}
```

```text
// file: programs/hoist.tip
main() {
  var a, b, c;
  a = 7;
  b = 3;
  if (a > b) c = a * b + 1; else c = a * b + 2;
  output c;
  return 0;
}
```

```text
; expected: expected/output.txt
== copy.tip ==
== TAC ==
  0: t1 = 4
  1: x = t1
  2: y = x
  3: t2 = 1
  4: t3 = y + t2
  5: z = t3
  6: output z
  7: t4 = 0
  8: return t4
== blocks ==
  B0 [0,9) succs:
== reaching (OUT) ==
  B0: 0:t1 1:x 2:y 3:t2 4:t3 5:z 7:t4
== ud-chains ==
  1: use t1 <- 0
  2: use x <- 1
  4: use y <- 2
  4: use t2 <- 3
  5: use t3 <- 4
  6: use z <- 5
  8: use t4 <- 7
== very busy (IN) ==
  B0:
== after copy-prop ==
  0: t1 = 4
  1: x = t1
  2: t2 = 1
  3: t3 = x + t2
  4: output t3
  5: t4 = 0
  6: return t4
  stats: replaced=2 deleted=2
== after hoist ==
  0: t1 = 4
  1: x = t1
  2: t2 = 1
  3: t3 = x + t2
  4: output t3
  5: t4 = 0
  6: return t4
  stats: hoisted=0
== 对账 ==
  outputs(before) == outputs(copy-prop): yes
  outputs(before) == outputs(hoist): yes
== hoist.tip ==
== TAC ==
  0: t1 = 7
  1: a = t1
  2: t2 = 3
  3: b = t2
  4: if a > b goto L6
  5: goto L11
  6: t3 = a * b
  7: t4 = 1
  8: t5 = t3 + t4
  9: c = t5
  10: goto L15
  11: t6 = a * b
  12: t7 = 2
  13: t8 = t6 + t7
  14: c = t8
  15: output c
  16: t9 = 0
  17: return t9
== blocks ==
  B0 [0,5) succs: 5 6
  B1 [5,6) succs: 11
  B2 [6,11) succs: 15
  B3 [11,15) succs: 15
  B4 [15,18) succs:
== reaching (OUT) ==
  B0: 0:t1 1:a 2:t2 3:b
  B1: 0:t1 1:a 2:t2 3:b
  B2: 0:t1 1:a 2:t2 3:b 6:t3 7:t4 8:t5 9:c
  B3: 0:t1 1:a 2:t2 3:b 11:t6 12:t7 13:t8 14:c
  B4: 0:t1 1:a 2:t2 3:b 6:t3 7:t4 8:t5 9:c 11:t6 12:t7 13:t8 14:c 16:t9
== ud-chains ==
  1: use t1 <- 0
  3: use t2 <- 2
  4: use a <- 1
  4: use b <- 3
  6: use a <- 1
  6: use b <- 3
  8: use t3 <- 6
  8: use t4 <- 7
  9: use t5 <- 8
  11: use a <- 1
  11: use b <- 3
  13: use t6 <- 11
  13: use t7 <- 12
  14: use t8 <- 13
  15: use c <- 9 14
  17: use t9 <- 16
== very busy (IN) ==
  B0:
  B1: {a * b}
  B2: {a * b}
  B3: {a * b}
  B4:
== after copy-prop ==
  0: t1 = 7
  1: t2 = 3
  2: if t1 > t2 goto L4
  3: goto L9
  4: t3 = t1 * t2
  5: t4 = 1
  6: t5 = t3 + t4
  7: c = t5
  8: goto L13
  9: t6 = t1 * t2
  10: t7 = 2
  11: t8 = t6 + t7
  12: c = t8
  13: output c
  14: t9 = 0
  15: return t9
  stats: replaced=6 deleted=2
== after hoist ==
  0: t1 = 7
  1: t2 = 3
  2: th1 = t1 * t2
  3: if t1 > t2 goto L5
  4: goto L10
  5: t3 = th1
  6: t4 = 1
  7: t5 = t3 + t4
  8: c = t5
  9: goto L14
  10: t6 = th1
  11: t7 = 2
  12: t8 = t6 + t7
  13: c = t8
  14: output c
  15: t9 = 0
  16: return t9
  stats: hoisted=1 (t1 * t2 -> th1)
== 对账 ==
  outputs(before) == outputs(copy-prop): yes
  outputs(before) == outputs(hoist): yes
```

## 27.9 小结与练习

四大经典至此齐装：

- 到达定值
  （前向 may）
  产出 ud 链，
  喂饱复制传播；
- 非常忙表达式
  （后向 must）
  给出"逃不掉的计算"，
  喂饱代码提升；
- 2×2 总表里
  四格各就各位，
  方程骨架
  只剩最后一步
  形式化——
  第 29 章
  把骨架抽象成
  半格 + 单调函数
  的通用框架，
  并证明
  MFP ≤ MOP。

练习：

1. 手工对 hoist.tip
   算 B4 的
   reaching OUT，
   与输出对照；
   解释 9:c 与 14:c
   并存的原因。
2. 把 hoist.tip 的
   else 支改成
   `c = a + b;`，
   重跑：
   very busy 变成什么？
   提升还成立吗？
   （提示：
   两个不同的表达式
   各自忙各的。）
3. 给 copy-prop 加
   "常量传播"
   （copy 源是数字时
    也替换），
   重新生成期望输出，
   数 replaced 的增量。
4. 构造一个
   "very busy 说忙
    而提升会白算"
   的程序
   （提示：让两条路径
    各算一次同一个
    表达式是必要的，
    但若表达式
    本来无副作用
    且廉价，
    提升只是搬位置），
   讨论收益的
   度量该用什么。
5. （承 26.4.2）
   复述"in 还是 out"
   的时刻语义，
   然后检查第 26 章
   可用表达式的
   使用点
   （CSE 判据）
   应该用 in 还是 out，
   给出论证。
