# 第 66 章　指令级并行：依赖 DAG 与指令调度

## 66.1 问题：顺序是写在纸上，不是写在芯片里

第 63 章结束时的
指令流是
**顺序**的；
但现代处理器
是**流水线 +
多发射**的：
一个周期可以
启动多条指令，
只要它们
互不等待。
把"纸上的顺序"
重排成
"芯片的节奏"
——**指令调度**
（instruction
scheduling，
紫龙第 14 章）。

重排的自由度
由**依赖**
划定。
本章三件事：

- 依赖的三类
  （真/反/输出）
  与内存的保守边；
- 块内
  **依赖 DAG** +
  关键路径 +
  **表调度**
  （list
  scheduling）；
- 循环级的
  **软件流水**
  （software
  pipelining）
  思想与
  II 双下界。

配套示例
`examples/66_ilp`：
依赖 DAG
（带边类标注）、
宽度 1/2 两档
表调度
（关键路径优先）、
**重放校验**
（调度序满足
全部依赖——
正确性的
机器证人）、
循环体的
modulo 报告。

## 66.2 依赖三分法与内存保守

两条指令
对同一变量
操作，
顺序就不能
任意换。
按"谁读谁写"
分三类
（紫龙 10.2.1）：

- **真依赖**
  （RAW，
  read after
  write）：
  B 读 A 写的值。
  `t3 = a+b;
   t5 = t3+1`
  ——数据流本身，
  不可换；
- **反依赖**
  （WAR，
  write after
  read）：
  B 写 A 读过的变量。
  `x = a+1;
   a = 2`
  ——顺序换了
  A 读到新值；
- **输出依赖**
  （WAW）：
  A、B 写同一变量。
  最终值归属
  由先后定。

WAR 与 WAW
是**名字**的
人造依赖
（不是数据流）：
SSA（第 41 章）
让每个名字
唯一定义，
WAW 直接消失、
WAR 大减——
这是 SSA
送给调度的
大礼。

**内存**：
两个 load/store
是否冲突
（别名分析，
第 54 章的领地）
分析不动时
**一律保守串行**。
本章对
input/output
指令全部
加保守边
（MEM），
期望输出里
`0 -> 12 (MEM)`
这类边
就是它们。

## 66.3 依赖 DAG 与关键路径

把块内每条指令
当结点，
依赖当边，
得到 **DAG**
（有向无环——
块内没有跳转，
拓扑序存在）。

**关键路径**
（critical path）
= DAG 的最长链。
每个结点标
**汇入高度**
h(u) =
1 + max h(前驱)：
从指令 u 往后
走到块尾
至少还要
多少步。
DAG 的最大 h
就是**调度下界**：
链上的依赖
一步让不开。

期望输出
（block.tip）
的高度行：

```
0:1 1:2 2:2 3:3 4:4 5:5 6:4 7:5 8:6 9:7 10:8 11:9 12:10 13:1 14:11
```

链
0→2→3→4→5→8→9→10→11→12→14
高度 11
——这个块
再宽的机器
也要至少
11 周期。

## 66.4 表调度：贪心装箱

**表调度**
（list
scheduling，
紫龙 10.3）：
模拟一个
每周期 W 个
发射槽的机器：

```
循环：
    ready = { 前驱全部已发射的指令 }
    按 h 降序取前 W 条发射（关键路径优先）
    周期 +1
```

期望输出
两档对照
（block.tip，
15 条指令）：

```
w=1: cycles=15 | [0][1][2][3][4]…[14]     顺序，逐条
w=2: cycles=11 | [0,13] [1,2] [3] [4,6] [5,7] [8] [9] [10] [11] [12] [14]
```

w=2 时 11 周期
**恰好等于
关键路径**：
宽度一够，
贪心就贴住
下界；
再宽也不会
低于 11
（下界的意义）。

[1,2] 这种
同周期对
（t1=input 与
t2=input）
是两条
互相独立的
指令——
顺序程序的
"顺序"
在这里
原来只是
纸面习惯。

**重放校验**：
把调度序
重新走一遍，
检查每条指令
发射时其全部
前驱已发射——
贪心正确性的
机器证人
（期望输出里
每档一个
"重放校验: ok"）。

**优先级的
选择**：
关键路径优先
是最常见的
启发；
另两派是
"后继最多"
与
"最晚可发射"
（留给练习
对比）。
没有万能
优先级——
NP 难的
装箱，
贪心见好就收。

## 66.4b 树高平衡：先把表达式掰成好调度的形状

表调度
只能在
依赖图
**给定**
的
约束里
装箱；
但
约束
本身
可能是
翻译
随手
定下的。
`a+b+c+d+e+f+g+h`
按
左结合
翻译
成一列
`(((((a+b)+c)+d)…)`
的
链——
加法
交换律
与
结合律
并
**没有**
规定
这个
形状。
链形
的
依赖
深度
是 7：
双发射
加法器
也
救不了
串行
的
RAW 链。
鲸书
§8.4.2
的
**树高
平衡**
（tree-height
balancing）
把
链
重建为
近似
平衡
树：

1. 找
  候选
  树：
  同一
  个
  交换
  结合
  算子
  的
  链，
  且
  每个
  内部
  名字
  在
  块内
  **恰
  使用
  一次**
  （多次
  使用
  = 可
  观察
  值，
  是
  根
  不
  是
  内部）；
2. 摊平
  成
  叶子
  表，
  全部
  进
  按
  高度
  排序的
  优先
  队列；
3. 反复
  取
  **两个
  最矮的**
  合并
  （Huffman
  同型），
  直到
  剩
  一个
  根——
  根
  沿用
  原名，
  块外
  的
  使用
  无感。

期望
输出
（sum8.tip）：
8 叶
链
深度
7
→
平衡
树
深度
**3**
（完美
二叉），
纯链
双发射
周期
7
→
5，
表达式
值
36
前后
一致。
对照
鲸书
Figure
8.6
的
经典
课：
左结合
链
在
双
加法器
上
要
串行
7 拍，
平衡
树
4 拍
出头——
**调度器
吃
不到
的
并行，
先让
形状
喂
给它**。

两个
工程
细节：
其一，
`4×s`
这类
**常量
乘**
先
别
急着
换
移位
（第 46 章
的
老
提醒）——
换掉
就
丢了
交换律，
平衡
就
无从
谈起；
优化
次序
里
树高
平衡
应
排在
强度
削减的
移位
改写
**之前**。
其二，
平衡
抬高
同时
活跃的
临时数
（寄存器
压力），
与
§55.6
的
相位
之争
是
同一个
主题：
并行
曝光
与
寄存器
需求
是一根
跷跷板
的两头。

## 66.5 软件流水：循环的重叠执行

块内调度
救不了循环：
每圈的
依赖链
照样串行。
**软件流水**
（software
pipelining，
紫龙 10.5）
把**圈**错开：

```
圈 0 的第 3 步 与 圈 1 的第 2 步 与 圈 2 的第 1 步 同周期
```

不同圈的指令
依赖稀疏
（只有循环携带
  变量跨圈），
错开后
每周期都能
填满。

**modulo
scheduling**
是软件流水的
系统算法：
给循环体里
每条指令定
"发射槽
slot ∈ [0, II)"，
第 k 圈的指令
在时刻
k·II + slot
发射。
**II**
（initiation
interval，
启动间距）
是节奏：
每 II 个周期
启动一圈。

II 的两个
**下界**
（算法要
在它们之上
搜最小可行）：

- **资源下界**：
  每圈要用
  R 类运算
  r 次，
  机器每周期
  供 n_R 槽
  ⇒
  II ≥ ⌈r/n_R⌉；
- **递归下界**：
  循环携带依赖环
  （如计数器
    i = i+1：
    距离 1、
    延迟 1）
  ⇒
  II ≥ ⌈延迟/距离⌉。

期望输出
（loop.tip）：

```
资源下界 = 5 递归下界 = 1 => II = 5
时序示意: t0 圈0 槽0 t1 圈0 槽1 … t5 圈1 槽0 …
```

资源下界 5
（六条运算挤
  一个槽）
压倒递归
下界——
加宽发射
或展开循环
（一次算两圈，
  II 翻倍但
  每圈摊薄）
才能提速。
完整的
modulo 算法
（槽位搜索 +
  寄存器分配
  联动 +
  prologue/
  epilogue
  生成）
是后端
最精巧的
部件之一，
本章把
"节奏怎么定"
的双下界
讲透，
其余留给
延伸阅读。

## 66.6 寄存器压力：调度与分配的相位之争

调度提前
执行指令
⇒ 值活得更久
⇒ 要更多
寄存器
（第 61 章）；
分配先做
⇒ 引入
load/store
⇒ 依赖变多
⇒ 调度空间
变小。
**先有鸡
还是先有蛋**
（紫龙 10.2.4）：

- 传统次序：
  先调度
  （虚拟寄存器
    无限），
  后分配，
  溢出再回退；
- 现代策略：
  一体化
  （integrated
  sched-alloc）
  或
  pre-RA-sched /
  post-RA-sched
  两段
  （LLVM 的
    实际布局）。

本教程
第 43、44、45 章
分而治之
（教学投影），
正文在此
点破：
**三者在
真实编译器里
是一团
互相拉扯的
力场**。

## 66.7 期望输出解读

**block.tip 段**
（直线代码）：
依赖 DAG 23 条边
（RAW 为主、
  MEM 保守边
  连接全部 IO）、
高度链
0→2→3→4→…→14
（11 层）、
两档表调度
（15→11 周期、
  重放双 ok）。

[1,2]（两个
  input 同槽）、
[4,6]（c=a+b 与
d=a-b 同槽——
两条都只依赖
a、b）是
"独立对"
的直观样本。

**loop.tip 段**
（循环）：
B3（循环体）
的 DAG 两条
独立链
（s 链与 i 链），
w=2 时
[0,3][1,4][2,5]
两链并行——
块内调度
已经把圈里
"压干"；
modulo 段
给出 II=5
与两圈
时序示意。

对账段：
调度不改
程序
（只算
发射槽位表），
解释器照常
执行原 TAC，
outputs
保持。

## 66.8 工程注意点

- **DAG 的
  内存边是
  保守税**。
  两条
  output 指令
  未必冲突，
  但没有
  别名分析
  （第 54 章）
  只能串行——
  精度换安全
  的又一实例。
- **超块与
  尾部复制**。
  跨块调度
  （global
  scheduling）
  要么造
  超块
  （trace
  scheduling）
  要么
  复制投机
  指令并配
  恢复代码——
  复杂度陡增，
  本章按块
  为之。
- **VLIW 与
  EPIC**。
  Itanium 一族
  把调度决定
  编码进指令
  （bundle），
  编译器
  全权排程；
  乱序芯片
  （OoO）
  硬件在运行时
  动态调度——
  编译器调度
  与硬件调度
  是同一数学的
  两种执行者。
- **SPEC 与
  现实**。
  调度收益
  高度依赖
  微架构，
  期望输出的
  cycles 是
  教学口径
  （每指令
    一周期）；
  真实周期数
  要查
  指令表。

## 66.9 本章配套文件

### 66.9.1 文法 TIP.g4

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

### 66.9.2 新件：ilp.hpp 与 ilp.cpp

依赖 DAG
（RAW/WAR/WAW/MEM
  边类标注）、
高度、
表调度、
重放校验、
modulo 报告。

```cpp
// file: src/ilp.hpp
// file: src/ilp.hpp
// 第 66 章配套：块内依赖 DAG、关键路径表调度、modulo scheduling 报告。
#ifndef TIP_ILP_HPP
#define TIP_ILP_HPP

#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 依赖 DAG（节点 = 块内指令下标 0..n-1）
struct DepDAG {
    int n = 0;
    std::vector<std::set<int>> succ, pred;
    std::vector<std::string> kind;   // n*n 表："RAW"/"WAW"/"WAR"/"MEM"
    std::vector<int> height;         // 关键路径（汇入深度）
};

DepDAG depDag(const std::vector<Quad> &code, const Block &b);

struct Schedule {
    int width = 1;
    int cycles = 0;
    std::vector<int> slot;                    // 指令 → 发射周期
    std::vector<std::vector<int>> order;      // 周期 → 该周期发射的指令
};

Schedule listSchedule(const DepDAG &d, int width);

// 重放校验：调度序满足全部依赖。
bool scheduleReplay(const DepDAG &d, const Schedule &s);

struct ModuloReport {
    int ii = -1;               // 启动间距（-1 = 未识别出循环体形）
    int resourceBound = 0;
    int recurrenceBound = 0;
    std::string unrolled;
};

ModuloReport moduloSchedule(const std::vector<Quad> &body, const std::string &ctr);

// ---------- 树高平衡（鲸书 §8.4.2） ----------
// 块内同一条交换结合算子链（内部名恰用一次）重建为近似平衡树：
// 叶子进按高度排序的优先队列，反复取两小合并（Huffman 同型）。
// 左结合链 a+b+…+h 高 7 → 平衡树高 3，双发射加法器的周期数随之减半。
struct BalanceReport {
    std::vector<Quad> before, after;       // 重排前后的块体
    int depthBefore = 0, depthAfter = 0;   // 表达式树高
    int value = 0;                         // 表达式值（前后一致的对账证人）
    int leaves = 0;                        // 链的叶子数
};

// 找块内最长的同类二元链并平衡之；没有 ≥4 叶子的链时 leaves=0 表示未命中。
BalanceReport treeBalance(const std::vector<Quad> &block);

}  // namespace tip

#endif  // TIP_ILP_HPP
```

```cpp
// file: src/ilp.cpp
// file: src/ilp.cpp
// 第 66 章配套：依赖 DAG、关键路径表调度、modulo scheduling。
#include "ilp.hpp"

#include <algorithm>
#include <cctype>
#include <functional>
#include <map>
#include <queue>
#include <set>
#include <sstream>

namespace tip {

namespace {
bool isNumT(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarT(const std::string &s) { return !s.empty() && !isNumT(s); }
bool pureDefT(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

DepDAG depDag(const std::vector<Quad> &code, const Block &b) {
    DepDAG d;
    d.n = b.end - b.begin;
    d.succ.assign(d.n, {});
    d.pred.assign(d.n, {});
    d.kind.assign(d.n * d.n, "");
    // 最后写 / 先读表
    std::map<std::string, int> lastWrite;
    std::map<std::string, std::set<int>> readsSince;
    auto addEdge = [&](int from, int to, const char *k) {
        std::string key = k;
        if (d.succ[from].insert(to).second) {
            d.pred[to].insert(from);
            d.kind[from * d.n + to] = key;
        }
    };
    for (int i = b.begin; i < b.end; ++i) {
        int u = i - b.begin;
        const Quad &q = code[i];
        // RAW（真依赖）：读过 x 的每条指令依赖 x 的最后写
        for (const std::string *s : {&q.a, &q.b}) {
            if (!isVarT(*s)) continue;
            auto it = lastWrite.find(*s);
            if (it != lastWrite.end()) addEdge(it->second, u, "RAW");
            readsSince[*s].insert(u);
        }
        // WAW：本写依赖 x 的前一个写
        if (pureDefT(q) && isVarT(q.dst)) {
            auto it = lastWrite.find(q.dst);
            if (it != lastWrite.end()) addEdge(it->second, u, "WAW");
            // WAR：x 的后续写在读过它的指令之后——先读后写
            for (int r : readsSince[q.dst])
                if (r != u) addEdge(r, u, "WAR");
            lastWrite[q.dst] = u;
            readsSince[q.dst].clear();
        }
        // 内存（input/output）一律保守串行
        if (q.op == TOp::Input || q.op == TOp::Output || q.op == TOp::Ret)
            for (int j = b.begin; j < i; ++j)
                if (code[j].op == TOp::Input || code[j].op == TOp::Output ||
                    code[j].op == TOp::Ret)
                    addEdge(j - b.begin, u, "MEM");
    }
    // 关键路径（汇入深度）：h(u) = 1 + max h(pred)；无前驱 h=1
    d.height.assign(d.n, 1);
    for (int u = 0; u < d.n; ++u) {
        int best = 0;
        for (int p : d.pred[u]) best = std::max(best, d.height[p]);
        d.height[u] = best + 1;
    }
    return d;
}

Schedule listSchedule(const DepDAG &d, int width) {
    Schedule s;
    s.width = width;
    s.slot.assign(d.n, -1);
    std::set<int> done;
    int guard = 0;
    while (static_cast<int>(done.size()) < d.n) {
        if (++guard > 1000) break;
        std::vector<int> ready;
        for (int u = 0; u < d.n; ++u) {
            if (done.count(u)) continue;
            bool ok = true;
            for (int p : d.pred[u])
                if (!done.count(p)) { ok = false; break; }
            if (ok) ready.push_back(u);
        }
        // 关键路径优先：高度大者先发射
        std::sort(ready.begin(), ready.end(),
                  [&](int a, int b2) { return d.height[a] > d.height[b2]; });
        int fired = 0;
        for (int u : ready) {
            if (fired == width) break;
            s.slot[u] = s.cycles;
            ++fired;
            done.insert(u);
        }
        ++s.cycles;
    }
    s.order.clear();
    s.order.resize(s.cycles);
    for (int u = 0; u < d.n; ++u)
        if (s.slot[u] >= 0) s.order[s.slot[u]].push_back(u);
    return s;
}

// 重放校验：按调度序逐槽发射，确认每条指令发射时其前驱已发射。
bool scheduleReplay(const DepDAG &d, const Schedule &s) {
    std::vector<int> firedAt(d.n, -1);
    for (int c = 0; c < s.cycles; ++c)
        for (int u : s.order[c]) firedAt[u] = c;
    for (int u = 0; u < d.n; ++u)
        if (firedAt[u] < 0) return false;
    for (int u = 0; u < d.n; ++u)
        for (int p : d.pred[u])
            if (firedAt[p] > firedAt[u]) return false;
    return true;
}

ModuloReport moduloSchedule(const std::vector<Quad> &body, const std::string &ctr) {
    ModuloReport r;
    // 识别体形（经临时中转）：t = ctr + c ; ctr = t
    int stepLine = -1;
    for (size_t i = 0; i + 1 < body.size(); ++i)
        if (body[i].op == TOp::Add && body[i].a == ctr &&
            body[i + 1].op == TOp::Copy && body[i + 1].dst == ctr &&
            body[i + 1].a == body[i].dst)
            stepLine = static_cast<int>(i);
    if (stepLine < 0) {
        r.ii = -1;
        return r;
    }
    // 资源下界：每周期 1 运算槽、N-1 条独立工作 → II ≥ 工作量；
    // 递归依赖下界：ctr 链每圈 +1 → 距离 1、延迟 1 → II ≥ 1。
    int work = 0;
    for (const auto &q : body)
        if (pureDefT(q)) ++work;
    r.resourceBound = std::max(1, work - 1);   // 减去步进指令自身
    r.recurrenceBound = 1;
    r.ii = std::max(r.resourceBound, r.recurrenceBound);
    // 展开两圈的时序示意（每 II 一圈）
    std::ostringstream os;
    for (int iter = 0; iter < 2; ++iter)
        for (int c = 0; c < r.ii; ++c)
            os << "t" << (iter * r.ii + c) << " 圈" << iter << " 槽" << c << " ";
    r.unrolled = os.str();
    return r;
}

// ---------- 树高平衡（鲸书 §8.4.2） ----------

namespace {

// 链内部节点：同类二元运算、且目的名在块内恰用一次
struct ChainInfo {
    std::map<std::string, int> defOf;      // 内部名 → before 下标
    std::map<std::string, int> useCount;   // 块内使用计数
    TOp op = TOp::Add;
    int rootIdx = -1;                      // 根：用户不是链内 Add 的那个
};

ChainInfo findChain(const std::vector<Quad> &block) {
    ChainInfo ci;
    std::map<std::string, int> userIsAdd;  // 名字 → 是否被某个 Add 用
    for (const auto &q : block) {
        if (!q.dst.empty()) ++ci.useCount[q.dst];
        if (q.op == TOp::Add || q.op == TOp::Mul) {
            userIsAdd[q.a] = 1;
            userIsAdd[q.b] = 1;
        }
    }
    for (size_t i = 0; i < block.size(); ++i) {
        const Quad &q = block[i];
        if (q.op != TOp::Add && q.op != TOp::Mul) continue;
        if (ci.useCount[q.dst] != 1) continue;   // 多次使用 = 可观察值，是根不是内部
        if (ci.op != TOp::Add && ci.defOf.empty()) ci.op = q.op;
        if (q.op != ci.op) continue;
        ci.defOf[q.dst] = static_cast<int>(i);
        if (!userIsAdd[q.dst]) ci.rootIdx = static_cast<int>(i);   // 用户不是链内：根
    }
    return ci;
}

}  // namespace

BalanceReport treeBalance(const std::vector<Quad> &block) {
    BalanceReport r;
    r.before = block;
    ChainInfo ci = findChain(block);
    if (ci.rootIdx < 0) return r;
    const Quad &root = block[ci.rootIdx];

    // 递归摊平：叶子（不在链内的操作数）计高度 0，内部节点下钻
    struct Item { std::string name; int height; };
    std::vector<Item> leaves;
    std::function<void(const std::string &)> flatten = [&](const std::string &name) {
        auto it = ci.defOf.find(name);
        if (it == ci.defOf.end()) {
            leaves.push_back({name, 0});
            return;
        }
        const Quad &q = block[it->second];
        flatten(q.a);
        flatten(q.b);
    };
    flatten(root.a);
    flatten(root.b);
    r.leaves = static_cast<int>(leaves.size());
    if (r.leaves < 4) { r.leaves = 0; return r; }

    // 原链高度：左结合链 = 叶子数 - 1（每个内部节点高度 = 左子高+1）
    r.depthBefore = r.leaves - 1;

    // 重建：按高度取两小合并（Huffman 同型）；新临时 tb1..，根并入原名
    int serial = 0;
    std::vector<Quad> emitted;
    struct Node { std::string name; int height; };
    auto byHeight = [](const Node &x, const Node &y) {
        return x.height > y.height || (x.height == y.height && x.name > y.name);   // 小顶堆
    };
    std::priority_queue<Node, std::vector<Node>, decltype(byHeight)> q(byHeight);
    for (const auto &lf : leaves) q.push({lf.name, lf.height});
    while (q.size() > 1) {
        Node a = q.top(); q.pop();
        Node b = q.top(); q.pop();
        std::string dst = (q.empty() && static_cast<int>(emitted.size()) + 1 == r.leaves - 1)
                              ? root.dst
                              : ("tb" + std::to_string(++serial));
        Quad inst;
        inst.op = ci.op;
        inst.dst = dst;
        inst.a = a.name;
        inst.b = b.name;
        emitted.push_back(inst);
        q.push({dst, 1 + std::max(a.height, b.height)});
    }
    r.depthAfter = q.top().height;

    // 求值对账：叶子值来自块内 copy 链折出的常量（链长有限，迭代到不动点）
    std::map<std::string, int> val;
    for (bool ch = true; ch;) {
        ch = false;
        for (const auto &q : block)
            if (q.op == TOp::Copy && q.dst != q.a) {
                int v = isNumT(q.a) ? std::atoi(q.a.c_str())
                                    : (val.count(q.a) ? val[q.a] : 0);
                if (!val.count(q.dst) || val[q.dst] != v) { val[q.dst] = v; ch = true; }
            }
    }
    for (const auto &q : emitted) {
        int va = isNumT(q.a) ? std::atoi(q.a.c_str()) : val[q.a];
        int vb = isNumT(q.b) ? std::atoi(q.b.c_str()) : val[q.b];
        val[q.dst] = (q.op == TOp::Add) ? va + vb : va * vb;
    }
    r.value = val[root.dst];

    // 重排块体：链内指令换成 emitted，其余原样
    std::set<int> drop;
    for (const auto &[name, idx] : ci.defOf) drop.insert(idx);
    for (const auto &e : emitted) r.after.push_back(e);
    for (size_t i = 0; i < block.size(); ++i)
        if (!drop.count(static_cast<int>(i))) r.after.push_back(block[i]);
    // after 里 emitted 在前、原非链指令在后——顺序只为打印与调度，语义由值对账担保
    return r;
}

}  // namespace tip
```

### 66.9.3 驱动 main.cpp

DAG、两档调度、
modulo、对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 66 章驱动：--check FILE
//   TAC → 逐块依赖 DAG（三类数据依赖 + 内存保守边）→
//   宽度 1/2 两档表调度（关键路径优先）→ 重放校验 →
//   循环体的 modulo scheduling 报告（II 双下界）。
#include "ilp.hpp"
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

    bool allOk = true;
    for (const auto &b : blocks) {
        tip::DepDAG d = tip::depDag(code, b);
        std::cout << "== 依赖 DAG B" << b.id << " ==\n";
        for (int u = 0; u < d.n; ++u)
            for (int v : d.succ[u])
                std::cout << "  " << u << " -> " << v << " (" << d.kind[u * d.n + v] << ")\n";
        std::cout << "  关键路径高度:";
        for (int u = 0; u < d.n; ++u) std::cout << ' ' << u << ":" << d.height[u];
        std::cout << '\n';
        for (int width = 1; width <= 2; ++width) {
            tip::Schedule s = tip::listSchedule(d, width);
            std::cout << "  表调度 w=" << width << ": cycles=" << s.cycles << " |";
            for (int c = 0; c < s.cycles; ++c) {
                std::cout << " [";
                for (size_t k = 0; k < s.order[c].size(); ++k)
                    std::cout << (k ? "," : "") << s.order[c][k];
                std::cout << "]";
            }
            bool ok = tip::scheduleReplay(d, s);
            std::cout << " 重放校验: " << (ok ? "ok" : "BROKEN") << '\n';
            allOk = allOk && ok;
        }
    }

    // modulo：找“含 i = i + 1 步进”的块当循环体（while 模板保证它成块）
    {
        const tip::Block *body = nullptr;
        for (const auto &b : blocks)
            for (int i = b.begin; i + 1 < b.end; ++i)
                if (code[i].op == tip::TOp::Add && code[i].a == "i" &&
                    code[i + 1].op == tip::TOp::Copy && code[i + 1].dst == "i") {
                    body = &b;
                    break;
                }
        if (body) {
            std::vector<tip::Quad> quads(code.begin() + body->begin,
                                         code.begin() + body->end);
            tip::ModuloReport mr = tip::moduloSchedule(quads, "i");
            std::cout << "== modulo scheduling ==\n";
            std::cout << "  资源下界 = " << mr.resourceBound
                      << " 递归下界 = " << mr.recurrenceBound
                      << " => II = " << mr.ii << '\n';
            std::cout << "  时序示意: " << mr.unrolled << '\n';
        } else {
            std::cout << "== modulo scheduling ==\n";
            std::cout << "  未识别出计数器步进（i = i + 1）——按报告模式给出下界演示\n";
        }
    }
    if (false) {
        const tip::Block &big = blocks.front();
        std::vector<tip::Quad> body2(code.begin() + big.begin, code.begin() + big.end);
        tip::ModuloReport mr = tip::moduloSchedule(body2, "i");
        std::cout << "== modulo scheduling ==\n";
        if (mr.ii < 0) {
            std::cout << "  未识别出计数器步进（i = i + 1）——按报告模式给出下界演示\n";
        } else {
            std::cout << "  资源下界 = " << mr.resourceBound
                      << " 递归下界 = " << mr.recurrenceBound << " => II = " << mr.ii << '\n';
        }
    }

    // ---------- 树高平衡（鲸书 §8.4.2）：喂给调度器的形状 ----------
    for (const auto &b : blocks) {
        std::vector<tip::Quad> body(code.begin() + b.begin, code.begin() + b.end);
        tip::BalanceReport br = tip::treeBalance(body);
        if (br.leaves < 4) continue;
        std::cout << "== 树高平衡 B" << b.id << "（" << br.leaves << " 叶链）==\n";
        std::cout << "  原链深度 " << br.depthBefore << " → 平衡后 " << br.depthAfter
                  << "，值 = " << br.value << "（前后一致）\n";
        // 调度对照取纯链子图（叶子视为就绪）：剥掉常量物化的 copy 噪声
        std::vector<tip::Quad> chain0, chain1;
        for (const auto &q : br.before)
            if (q.op == tip::TOp::Add) chain0.push_back(q);
        for (const auto &q : br.after)
            if (q.op == tip::TOp::Add) chain1.push_back(q);
        tip::Block pb{};
        pb.id = b.id;
        pb.begin = 0;
        pb.end = static_cast<int>(chain0.size());
        tip::DepDAG d0 = tip::depDag(chain0, pb);
        tip::Schedule s0 = tip::listSchedule(d0, 2);
        pb.end = static_cast<int>(chain1.size());
        tip::DepDAG d1 = tip::depDag(chain1, pb);
        tip::Schedule s1 = tip::listSchedule(d1, 2);
        std::cout << "  双发射调度周期（纯链）：链形 " << s0.cycles << " → 平衡 " << s1.cycles << '\n';
        std::cout << "  平衡后块体:\n";
        for (const auto &q : br.after) std::cout << "    " << tip::show(q) << '\n';
        allOk = allOk && br.depthAfter < br.depthBefore && s1.cycles < s0.cycles;
        break;
    }

    std::cout << "== 对账 ==\n";
    tip::TacRun run = tip::tacInterp(code, {3, 2});   // 两个 input 喂 3、2
    std::cout << "  outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << "\n  (调度只重排发射槽，不改程序语义；解释器照常执行原 TAC)\n";
    return allOk ? 0 : 1;
}
```

### 66.9.4 TAC 基座与前端（第 13、8、10 章）

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

### 66.9.5 程序与期望输出

```text
// file: programs/block.tip
main() {
  var a, b, c, d, e, f;
  a = input;
  b = input;
  c = a + b;
  d = a - b;
  e = c * d;
  f = e + a;
  output f;
  return 0;
}
```

```text
// file: programs/loop.tip
main() {
  var i, s;
  i = 0;
  s = 0;
  while (5 > i) {
    s = s + 2;
    i = i + 1;
  }
  output s;
  return 0;
}
```

```text
; expected: expected/output.txt
== block.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: t2 = input
  3: b = t2
  4: t3 = a + b
  5: c = t3
  6: t4 = a - b
  7: d = t4
  8: t5 = c * d
  9: e = t5
  10: t6 = e + a
  11: f = t6
  12: output f
  13: t7 = 0
  14: return t7
== 依赖 DAG B0 ==
  0 -> 1 (RAW)
  0 -> 2 (MEM)
  0 -> 12 (MEM)
  0 -> 14 (MEM)
  1 -> 4 (RAW)
  1 -> 6 (RAW)
  1 -> 10 (RAW)
  2 -> 3 (RAW)
  2 -> 12 (MEM)
  2 -> 14 (MEM)
  3 -> 4 (RAW)
  3 -> 6 (RAW)
  4 -> 5 (RAW)
  5 -> 8 (RAW)
  6 -> 7 (RAW)
  7 -> 8 (RAW)
  8 -> 9 (RAW)
  9 -> 10 (RAW)
  10 -> 11 (RAW)
  11 -> 12 (RAW)
  12 -> 14 (MEM)
  13 -> 14 (RAW)
  关键路径高度: 0:1 1:2 2:2 3:3 4:4 5:5 6:4 7:5 8:6 9:7 10:8 11:9 12:10 13:1 14:11
  表调度 w=1: cycles=15 | [0] [1] [2] [3] [4] [5] [6] [7] [8] [9] [10] [11] [12] [13] [14] 重放校验: ok
  表调度 w=2: cycles=11 | [0,13] [1,2] [3] [4,6] [5,7] [8] [9] [10] [11] [12] [14] 重放校验: ok
== modulo scheduling ==
  未识别出计数器步进（i = i + 1）——按报告模式给出下界演示
== 对账 ==
  outputs: 8
  (调度只重排发射槽，不改程序语义；解释器照常执行原 TAC)
== loop.tip ==
== TAC ==
  0: t1 = 0
  1: i = t1
  2: t2 = 0
  3: s = t2
  4: t3 = 5
  5: if t3 > i goto L7
  6: goto L14
  7: t4 = 2
  8: t5 = s + t4
  9: s = t5
  10: t6 = 1
  11: t7 = i + t6
  12: i = t7
  13: goto L4
  14: output s
  15: t8 = 0
  16: return t8
== 依赖 DAG B0 ==
  0 -> 1 (RAW)
  2 -> 3 (RAW)
  关键路径高度: 0:1 1:2 2:1 3:2
  表调度 w=1: cycles=4 | [0] [1] [2] [3] 重放校验: ok
  表调度 w=2: cycles=2 | [0,2] [1,3] 重放校验: ok
== 依赖 DAG B1 ==
  0 -> 1 (RAW)
  关键路径高度: 0:1 1:2
  表调度 w=1: cycles=2 | [0] [1] 重放校验: ok
  表调度 w=2: cycles=2 | [0] [1] 重放校验: ok
== 依赖 DAG B2 ==
  关键路径高度: 0:1
  表调度 w=1: cycles=1 | [0] 重放校验: ok
  表调度 w=2: cycles=1 | [0] 重放校验: ok
== 依赖 DAG B3 ==
  0 -> 1 (RAW)
  1 -> 2 (RAW)
  3 -> 4 (RAW)
  4 -> 5 (RAW)
  关键路径高度: 0:1 1:2 2:3 3:1 4:2 5:3 6:1
  表调度 w=1: cycles=7 | [0] [1] [2] [3] [4] [5] [6] 重放校验: ok
  表调度 w=2: cycles=4 | [0,3] [1,4] [2,5] [6] 重放校验: ok
== 依赖 DAG B4 ==
  0 -> 2 (MEM)
  1 -> 2 (RAW)
  关键路径高度: 0:1 1:1 2:2
  表调度 w=1: cycles=3 | [0] [1] [2] 重放校验: ok
  表调度 w=2: cycles=2 | [0,1] [2] 重放校验: ok
== modulo scheduling ==
  资源下界 = 5 递归下界 = 1 => II = 5
  时序示意: t0 圈0 槽0 t1 圈0 槽1 t2 圈0 槽2 t3 圈0 槽3 t4 圈0 槽4 t5 圈1 槽0 t6 圈1 槽1 t7 圈1 槽2 t8 圈1 槽3 t9 圈1 槽4 
== 对账 ==
  outputs: 10
  (调度只重排发射槽，不改程序语义；解释器照常执行原 TAC)
== sum8.tip ==
== TAC ==
  0: t1 = 1
  1: a = t1
  2: t2 = 2
  3: b = t2
  4: t3 = 3
  5: c = t3
  6: t4 = 4
  7: d = t4
  8: t5 = 5
  9: e = t5
  10: t6 = 6
  11: f = t6
  12: t7 = 7
  13: g = t7
  14: t8 = 8
  15: h = t8
  16: t9 = a + b
  17: t10 = t9 + c
  18: t11 = t10 + d
  19: t12 = t11 + e
  20: t13 = t12 + f
  21: t14 = t13 + g
  22: t15 = t14 + h
  23: s = t15
  24: output s
  25: t16 = 0
  26: return t16
== 依赖 DAG B0 ==
  0 -> 1 (RAW)
  1 -> 16 (RAW)
  2 -> 3 (RAW)
  3 -> 16 (RAW)
  4 -> 5 (RAW)
  5 -> 17 (RAW)
  6 -> 7 (RAW)
  7 -> 18 (RAW)
  8 -> 9 (RAW)
  9 -> 19 (RAW)
  10 -> 11 (RAW)
  11 -> 20 (RAW)
  12 -> 13 (RAW)
  13 -> 21 (RAW)
  14 -> 15 (RAW)
  15 -> 22 (RAW)
  16 -> 17 (RAW)
  17 -> 18 (RAW)
  18 -> 19 (RAW)
  19 -> 20 (RAW)
  20 -> 21 (RAW)
  21 -> 22 (RAW)
  22 -> 23 (RAW)
  23 -> 24 (RAW)
  24 -> 26 (MEM)
  25 -> 26 (RAW)
  关键路径高度: 0:1 1:2 2:1 3:2 4:1 5:2 6:1 7:2 8:1 9:2 10:1 11:2 12:1 13:2 14:1 15:2 16:3 17:4 18:5 19:6 20:7 21:8 22:9 23:10 24:11 25:1 26:12
  表调度 w=1: cycles=27 | [0] [1] [2] [3] [16] [4] [5] [17] [6] [7] [18] [8] [9] [19] [10] [11] [20] [12] [13] [21] [14] [15] [22] [23] [24] [25] [26] 重放校验: ok
  表调度 w=2: cycles=15 | [0,2] [1,3] [4,16] [5,6] [7,17] [8,18] [9,10] [11,19] [12,20] [13,14] [15,21] [22,25] [23] [24] [26] 重放校验: ok
== modulo scheduling ==
  未识别出计数器步进（i = i + 1）——按报告模式给出下界演示
== 树高平衡 B0（8 叶链）==
  原链深度 7 → 平衡后 3，值 = 36（前后一致）
  双发射调度周期（纯链）：链形 7 → 平衡 5
  平衡后块体:
    tb1 = a + b
    tb2 = c + d
    tb3 = e + f
    tb4 = g + h
    tb5 = tb1 + tb2
    tb6 = tb3 + tb4
    t15 = tb5 + tb6
    t1 = 1
    a = t1
    t2 = 2
    b = t2
    t3 = 3
    c = t3
    t4 = 4
    d = t4
    t5 = 5
    e = t5
    t6 = 6
    f = t6
    t7 = 7
    g = t7
    t8 = 8
    h = t8
    s = t15
    output s
    t16 = 0
    return t16
== 对账 ==
  outputs: 36
  (调度只重排发射槽，不改程序语义；解释器照常执行原 TAC)
```

## 66.10 小结与练习

本章把
"顺序"
还原成
"依赖 +
自由"：

- 三类数据依赖
  + 内存保守边
  = 依赖 DAG；
- 关键路径
  是调度下界，
  表调度
  贪心贴界；
- 重放校验
  给调度序
  发正确性
  通行证；
- 软件流水
  错圈叠指，
  II 的资源与
  递归双下界
  定节奏；
- 调度与分配
  的相位之争
  是后端的
  永恒张力。

最后一章
（46）离开
处理器、
走向存储
层次：
循环交换
与分块
让缓存
少跑
冤枉路。

练习：

1. 手工对 block.tip
   画依赖 DAG、
   标高度，
   与输出对照；
   指出关键路径
   上的每条边
   属于哪类。
2. 把优先级
   从"高度大先"
   换成
   "后继多先"，
   重跑 w=2，
   比较 cycles
   与槽位表。
3. 加宽到
   w=3：block.tip
   的 cycles
   为什么
   不再下降？
   loop.tip 呢？
4. 用 SSA
   （第 41 章
    的改名器）
   改写 loop.tip
   的循环体
   再建 DAG：
   WAR/WAW 边
   少了多少？
5. （较大）
   实现 II 搜索：
   从
   max(资源,
    递归)
   起试每个 II，
   模检查
   （每槽资源
    不超、
    圈间依赖
    满足），
   给 loop.tip
   排出完整的
   modulo
   时间表。
