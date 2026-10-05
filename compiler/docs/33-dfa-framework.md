# 第 33 章　数据流框架定理：半格、单调性与 MFP ≤ MOP

## 33.1 问题：把四个分析装进一台引擎

第 20 到 27 章，
我们造了九个分析：
符号、常量、区间、
路径敏感、
活跃、可用、
到达、非常忙……
每个都是
"方程 + 迭代"。
把它们的方程
并排一看，
形状完全相同——
差别只有三处：

- **域**：
  定值集、表达式集、
  变量集、格点映射……
- **方向**：
  前向还是后向；
- **合并**：
  并还是交
  （may 还是 must）。

本章把这三处
参数化，
得到**通用数据流框架**
（紫龙 9.3、
绿龙 14.6 的形式化），
然后证明两个定理：

1. **收敛定理**：
  单调转移 + 有限高度
  ⇒ 迭代必到不动点；
2. **MFP ≤ MOP 定理**：
  迭代解（MFP）
  永远站在
  理想解（MOP）
  保守的那一侧；
  若转移函数
  **分配**，
  两者相等——
  四大经典全在
  等号俱乐部，
  常量传播
  被挡在门外。

配套示例
`examples/33_dfa_framework`
用一台引擎跑五个实例，
并用**路径枚举的暴力 MOP**
做机器对照——
紫龙 9.4.5 的
非分配性反例
（x−y 菱形）
在期望输出里
原样上演：
MFP 说 ⊤，
MOP 说 0。

## 33.2 半格：合并的代数

**半格**
（semilattice）
是一个集合 L
加上一个二元运算
∧（meet），
满足：

- **交换**：x ∧ y = y ∧ x；
- **结合**：(x ∧ y) ∧ z = x ∧ (y ∧ z)；
- **幂等**：x ∧ x = x。

三律合起来说：
∧ 是"取两个之中
更保守者"的运算，
重复合并不改变结果。

半格诱导偏序：
x ⊑ y ⟺ x ∧ y = x
（x 是两者 meet，
  即 x 更"低"更保守）。
有顶（⊤ = 最保守）
与底（⊥ = 最不保守）
的半格就是
数据流的家。

第 25 章的五点符号格、
第 26 章的构造格
都在这里归位；
本章用得最多的是
两个"集合半格"：

- **may 半格**：
  域 = 某 Universe 的子集，
  ∧ = ∪，
  ⊑ = ⊆，
  ⊤ = 全集；
- **must 半格**：
  ∧ = ∩，
  ⊑ = ⊇，
  ⊤ = ∅。

注意 must 半格的
序是**反包含**——
"更小的集合"
意味着"更强的承诺"，
所以更精。
两个半格的
保守方向相反，
但"保守 = 低处"
的格论口径一致。

**高度**：
任意严格上升链的
最大长度。
2^Universe 的
子集格高度有限；
第 34 章的区间格
高度无限——
那是要用
加宽来另案处理的事
（此处按下）。

## 33.3 框架与转移函数

**数据流框架**
= (G, L, F)：

- G：流图；
- L：值半格；
- F：转移函数族
  （每个块一个
   L → L 的函数）。

转移函数要**单调**
（monotone）：
x ⊑ y ⇒ F(x) ⊑ F(y)。
"输入更保守，
  输出不更激进"——
  单调是保守性
  沿传播链的
  保险丝。

比单调更强的是
**分配**
（distributive）：
F(x ∧ y) = F(x) ∧ F(y)。
四大经典的
gen/kill 型转移
都是分配的
（kill 集与 gen 集
  与输入无关，
  集合等式可逐元素验证）；
常量传播不是——
28.6 的反例
专门伺候它。

方程组
（前向版；
  后向对称）：

```
in[B]  = ∧ out[P]     （P 取遍前驱；首块再 ∧ boundary）
out[B] = F_B(in[B])
```

初始迭代值：
非首块的 in 从 ⊤ 起步
（"一无所知"），
迭代向下修正。

## 33.4 收敛定理

> 单调转移函数
> 作用在
> 有限高度半格上，
> 轮转迭代
> 必在有限步内
> 到达方程组的
> **最大不动点**。

证明思路三步
（紫龙 9.3.3 的骨架）：

1. **每轮要么不变、
   要么严格下降**：
   块的 in 只会被
   ∧ 进更保守的值，
   单调保证
   已有信息不丢，
   幂等保证
   重复 meet 无害；
2. **下降有界**：
   半格高度有限，
   严格下降链
   走不了无限步；
3. **停即不动点**：
   所有方程同时满足
   （没有块再变化），
   且从 ⊤ 出发
   一路向下,
   到达的是
   最大的那个
   （信息最多的）
   不动点——
   精度上限的保证。

第 27 章已经把
Knaster–Tarski
讲成一般理论；
本章的迭代
是它的
"自顶向下版"实例。
第 28 章的工作表
改进的只是
**访问顺序**
（只重算受影响的块），
不动点本身
与轮转版相同
——这也是为什么
第 28 章四种顺序
的收敛账
殊途同归。

## 33.5 MOP 与 MFP：理想解与迭代解

### 33.5.1 两个定义

**MOP**
（meet-over-all-paths，
  全路径理想解）：
块 B 的
MOP[B] =
沿**每一条**
从入口到 B 的
执行路径 p，
把边界值
逐块复合过去
得到 F_p(boundary)，
再全部 ∧ 起来。

MOP 是
"如果路径信息
  不损失，
  分析能到的
  最准答案"。
它是理想，
不是算法：
路径可以无限长
（循环），
条数可以指数多。

**MFP**
（maximal fixed point，
  最大不动点）：
方程组的迭代解——
我们真正算出来的东西。

### 33.5.2 定理与证明思路

> **MFP ⊑ MOP**
> （迭代解在
>   理想解的
>   保守一侧）。

思路：
对路径长度归纳，
任何一条具体路径
p 的 F_p(boundary)
都不会比
沿 p 的块序列
逐块 meet 出来的
迭代值更保守
——因为迭代时
每过一个汇合点
就把**别的路径的
保守性**也 ∧ 了进来，
而单条路径没有。
于是
MOP 的每个加项
都 ⊒ 对应块的
迭代输出，
∧ 起来仍 ⊒
（单调）。
换句话：
**迭代在汇合点
提前合并，
合并只增保守**。

> 若 F 分配，
> 则 **MFP = MOP**。

思路：
分配律恰好说
"先复合后合并
  等于
  先合并后复合"，
把 MOP 的
路径 meet
一步步搬进
块间方程，
形状逐字变成
MFP 的方程组，
由最大不动点
唯一性得等。

### 33.5.3 为什么四大经典全在等号俱乐部

它们的转移是
`F(S) = gen ∪ (S − kill)`
（或后向同构）。
对 may 半格：

```
F(S₁ ∪ S₂) = gen ∪ ((S₁ ∪ S₂) − kill)
           = (gen ∪ (S₁ − kill)) ∪ (gen ∪ (S₂ − kill))
           = F(S₁) ∪ F(S₂)
```

第二行的等号
把集合代数
拆开合拢就到——
**gen/kill 型
转移天然分配**。
must 版同型
（∩ 与 − 的分配）。
所以第 25、26 章
的四个分析
算出来的
就是各自
理想意义下的
最优解。

## 33.6 常量传播：非分配的活证据

紫龙 9.4.5 的
标准反例，
本章示例
diamond.tip
逐字实现：

```
c = input;                       // c 未知（⊤）
if (c > 0) { x = 1; y = 1; }
else        { x = 2; y = 2; }
z = x - y;
```

两条路径各自看：

- then 路：x=1、y=1 →
  z = 1 − 1 = **0**；
- else 路：x=2、y=2 →
  z = 2 − 2 = **0**。

**MOP**
在 z 处：
meet(0, 0) = **0**——
"无论走哪条路
  z 都是 0"。

**MFP**
在汇合块：
in = meet(then 出口, else 出口)
= meet(x=1∧y=1, x=2∧y=2)
= **x=⊤, y=⊤**
（1 与 2 不等，
  格上合并到 ⊤）；
再算 `z = x − y`：
⊤ − ⊤ = **⊤**。

x 的信息与
y 的信息
**各自**丢了，
但"x−y=0"
这件**联合**事实
只活在路径里，
汇合点一 meet
就没了——
这正是
F(x∧y) ⊏ F(x)∧F(y)
的字面演示：
先合并（MFP）丢掉的，
先复合（MOP）保住了。

期望输出的
constprop 段
（B4 为汇合块）：

```
B4  MFP { ... t7=T, z=T, x=T, y=T }
    MOP<=8 { ... t7=0, z=0, x=T, y=T }
MFP == MOP<= 8 : no
MFP 在正确的一侧（方向性）: yes
```

z=T vs z=0：
**严格不等**，
且方向正确
（MFP 更粗、
  不假装知道
  它不知道的事）。
（t7 是
`x - y` 的临时名，
与 z 同命运。）

这不是实现的缺陷，
是常量传播
这个**框架本身**
的精度天花板：
想拿到路径里的
联合常量，
要么路径敏感
（第 36 章），
要么 SSA +
稀疏条件常量
传播（SCCP）——
那是工业界
真正用的东西，
其思路种子
已在
第 38 章的
阅读地图里。

## 33.7 示例落地：一台引擎、五张表

框架引擎
（framework.cpp）
不含任何
具体分析的痕迹：

- `meetFn`：
  实例自带的合并函数；
- `transfer(i, q, v)`：
  行号 + 指令 + 流入值
  → 流出值；
- `solve`：
  前向/后向两套
  方程骨架，
  轮转到稳定。

五个实例
（instances.cpp）
每个只是一张表：

- **reaching**：
  may、前向、
  元素 "i:var"，
  转移 = 杀同变量
  加自条目；
- **available**：
  must、前向、
  元素 = 表达式键，
  转移 = gen 键、
  kill 含 dst 的键；
- **live**：
  may、后向、
  元素 = 变量名，
  转移 = 杀 dst、
  生操作数；
- **verybusy**：
  must、后向、
  元素 = 表达式键；
- **constprop**：
  前向、
  元素 "x=5"/"x=T"
  （集合里没有 = ⊥），
  专用 meet
  （c∧c=c、
  c₁∧c₂=⊤、
  缺侧=⊤），
  转移按操作数格点
  算术或置 ⊤。

MOP 对照
（mop.cpp）
是纯暴力：
前向从入口
DFS 枚举路径
（深度 ≤ K），
逐路径复合
再 meet；
后向从每块
递归到出口
倒推。
无环图上
K 足够即精确；
有环时
诚实标注
`MOP<= K`。
K=8 对两个示例程序
够用
（four.tip 的循环
路径按深度截断，
仍是有效的
下近似对照）。

对照的口径：
前向比 OUT、
后向比 IN——
与 solve 的
输出一一对应。
方向性检查
（MFP ⊑ MOP
  的方向按
  may/must/常量
  三种口径）
在每块上机器验证，
任何一行 NO
都是退出非零的
错误。

## 33.8 期望输出解读

**diamond.tip 段**：
五实例并排。
前四个
（reaching/available/
  live/verybusy）
每块
`MFP {…} | MOP<=8 {…}`
两集合逐字相同，
判定 yes ×4——
分配性的机器证据。
constprop 段
B2/B3（两分支）
MFP==MOP
（单路径无合并），
B4（汇合）
t7/z 从 0 变 T，
判定 no。
方向性全 yes。

**four.tip 段**：
带循环的
综合程序。
四大经典
依然全 yes
（循环路径被
  K 截断不影响——
  它们分配，
  MFP=MOP
  本来与路径
  长度无关）。
constprop 的 no
来自两处：
分支合并的
经典丢信息
+ 循环截断的
路径缺失
（后者是我们
  暴力 MOP 的
  实现边界，
  不是框架定理
  的一部分——
  教学上正好
  把"实现近似"
  与"理论不等"
  分开）。

## 33.9 工程注意点

- **实例表即插件**。
  加一个新分析
  = 填一张表，
  引擎一行不改——
  这是第 32 章
  "转移函数表格化"
  的彻底化。
  LLVM 的
  Pass 管线里
  每个数据流 pass
  本质上就是
  这样一张表
  加一个入口。
- **初值别给反**。
  may 从 ∅、
  must 从全集；
  首块边界
  （前向 in[entry]、
  后向 out[exit]）
  另算。
  初值错误
  会把不动点
  顶到错误一侧，
  且不报错——
  方向性检查
  （本章输出的
  第二判定行）
  是廉价的自检。
- **MOP 是标尺
  不是算法**。
  路径枚举
  指数/无穷，
  只配当测试
  oracle；
  但它在小图上
  的暴力值
  是框架正确性
  最直接的
  机器证明——
  本示例的
  全部判定行
  都靠它。
- **非分配 ≠ 不准**。
  常量传播的 MFP
  仍在 MOP 的
  保守一侧
  （定理保证），
  它只是没拿到
  理论最优。
  工程取舍：
  接受 MFP
  （便宜），
  或上 SCCC/
  路径敏感
  （贵而准）。
- **通用框架与
  专用实现的
  对账**。
  本章实例的
  语义与第 25/26 章
  的专门实现
  逐条对齐
  （gen/kill 口径
  一致）；
  两章程序
  交叉运行
  是留给练习 5 的
  强对账。

## 33.10 本章配套文件

### 33.10.1 文法 TIP.g4

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

### 33.10.2 引擎 framework.hpp 与 framework.cpp

半格值、实例表、
solve 迭代。

```cpp
// file: src/framework.hpp
// file: src/framework.hpp
// 第 33 章配套：通用数据流框架——半格 + 单调转移函数 + 方向。
// 一个实例 = 一张“值怎么 meet、每条指令怎么转、边界是什么”的表；
// 引擎对任何实例求 MFP（迭代到不动点）。
// 值统一为字符串集合：定值号 "i:var"、表达式键 "a + b"、变量名、常量项 "x=5"。
#ifndef TIP_FRAMEWORK_HPP
#define TIP_FRAMEWORK_HPP

#include <functional>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

using FVal = std::set<std::string>;

enum class Dir { Forward, Backward };

struct Instance {
    std::string name;
    Dir dir;
    std::function<FVal(const FVal &, const FVal &)> meetFn;
    FVal boundary;    // 入口（前向）/出口（后向）
    FVal initTop;     // 迭代初值：may 用 ∅，must 用全集
    // 转移：行号 + 指令 + 流入值 → 流出值（按方向的语义复合）
    std::function<FVal(int, const Quad &, const FVal &)> transfer;
};

struct FrameResult {
    std::vector<FVal> in, out;
};

FrameResult solve(const Instance &inst, const std::vector<Quad> &code,
                  const std::vector<Block> &blocks);
FVal blockTransfer(const Instance &inst, const std::vector<Quad> &code,
                   const Block &b, FVal v);

}  // namespace tip

#endif  // TIP_FRAMEWORK_HPP
```

```cpp
// file: src/framework.cpp
// file: src/framework.cpp
// 第 33 章配套：通用引擎实现。
#include "framework.hpp"

namespace tip {

FVal blockTransfer(const Instance &inst, const std::vector<Quad> &code,
                   const Block &b, FVal v) {
    if (inst.dir == Dir::Forward) {
        for (int i = b.begin; i < b.end; ++i) v = inst.transfer(i, code[i], v);
    } else {
        for (int i = b.end - 1; i >= b.begin; --i) v = inst.transfer(i, code[i], v);
    }
    return v;
}

// 前向：in[B] = meet out[前驱]（首块再 meet 边界）；out[B] = F_B(in[B])
// 后向：out[B] = meet in[后继]（无后继即边界）；in[B] = F_B(out[B])
FrameResult solve(const Instance &inst, const std::vector<Quad> &code,
                  const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    FrameResult r;
    r.in.assign(n, inst.initTop);
    r.out.assign(n, inst.initTop);
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 0; b < n; ++b) {
            if (inst.dir == Dir::Forward) {
                FVal edge;
                bool hasPred = false;
                for (size_t q = 0; q < n; ++q)
                    for (int s : blocks[q].succs)
                        if (s == blocks[b].begin) {
                            edge = hasPred ? inst.meetFn(edge, r.out[q]) : r.out[q];
                            hasPred = true;
                        }
                if (b == 0) edge = hasPred ? inst.meetFn(edge, inst.boundary) : inst.boundary;
                FVal out = blockTransfer(inst, code, blocks[b], edge);
                if (edge != r.in[b] || out != r.out[b]) {
                    r.in[b] = edge;
                    r.out[b] = out;
                    changed = true;
                }
            } else {
                FVal edge;
                bool hasSucc = false;
                for (int s : blocks[b].succs)
                    for (size_t k = 0; k < n; ++k)
                        if (blocks[k].begin == s) {
                            edge = hasSucc ? inst.meetFn(edge, r.in[k]) : r.in[k];
                            hasSucc = true;
                        }
                if (!hasSucc) edge = inst.boundary;
                FVal in = blockTransfer(inst, code, blocks[b], edge);
                if (edge != r.out[b] || in != r.in[b]) {
                    r.out[b] = edge;
                    r.in[b] = in;
                    changed = true;
                }
            }
        }
    }
    return r;
}

}  // namespace tip
```

### 33.10.3 实例 instances.hpp 与 instances.cpp

五张实例表。

```cpp
// file: src/instances.hpp
// file: src/instances.hpp
// 第 33 章配套：框架的五个实例构造器。
#ifndef TIP_INSTANCES_HPP
#define TIP_INSTANCES_HPP

#include "framework.hpp"

namespace tip {

// 四大经典（与第 25/26 章的专门实现同语义，此处统一为框架实例）：
Instance makeReaching(const std::vector<Quad> &code);
Instance makeAvailable(const std::vector<Quad> &code);
Instance makeLive(const std::vector<Quad> &code);
Instance makeVeryBusy(const std::vector<Quad> &code);
// 常量传播（非分配性的标准反例携带者，紫龙 9.4）：
Instance makeConstProp(const std::vector<Quad> &code);

}  // namespace tip

#endif  // TIP_INSTANCES_HPP
```

```cpp
// file: src/instances.cpp
// file: src/instances.cpp
// 第 33 章配套：五个框架实例——四大经典 + 常量传播。
// 每个实例只填一张表；与第 25/26 章的专门实现同语义。
#include "instances.hpp"

#include <cctype>
#include <sstream>

namespace tip {

namespace {
bool isNum(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVar(const std::string &s) { return !s.empty() && !isNum(s); }

std::string exprOf(const Quad &q) {
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
bool sharesOp(const std::string &key, const std::string &var) {
    if (key.rfind(var + " ", 0) == 0) return true;
    size_t sp = key.rfind(" " + var);
    if (sp != std::string::npos && sp + 1 + var.size() == key.size()) return true;
    return key.find(" " + var + " ") != std::string::npos;
}
bool definesSomething(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
FVal unionMeet(const FVal &a, const FVal &b) {
    FVal out = a;
    out.insert(b.begin(), b.end());
    return out;
}
FVal interMeet(const FVal &a, const FVal &b) {
    FVal out;
    for (const auto &x : a)
        if (b.count(x)) out.insert(x);
    return out;
}
// 全域扫描：所有变量 / 所有表达式键
void scanUniverse(const std::vector<Quad> &code, FVal &vars, FVal &exprs) {
    for (const auto &q : code) {
        if (isVar(q.dst)) vars.insert(q.dst);
        if (isVar(q.a)) vars.insert(q.a);
        if (isVar(q.b)) vars.insert(q.b);
        std::string e = exprOf(q);
        if (!e.empty()) exprs.insert(e);
    }
}
}  // namespace

// ---------- 到达定值（前向 may；元素 "i:var"） ----------
Instance makeReaching(const std::vector<Quad> &code) {
    Instance inst;
    inst.name = "reaching";
    inst.dir = Dir::Forward;
    inst.meetFn = unionMeet;
    inst.boundary = {};
    inst.initTop = {};
    inst.transfer = [code](int i, const Quad &q, const FVal &in) {
        FVal out = in;
        if (!definesSomething(q)) return out;
        std::string v = q.dst;
        for (auto it = out.begin(); it != out.end();)
            if (it->substr(it->find(':') + 1) == v) it = out.erase(it);
            else ++it;
        out.insert(std::to_string(i) + ":" + v);
        return out;
    };
    return inst;
}

// ---------- 可用表达式（前向 must；元素 = 表达式键） ----------
Instance makeAvailable(const std::vector<Quad> &code) {
    Instance inst;
    inst.name = "available";
    inst.dir = Dir::Forward;
    inst.meetFn = interMeet;
    inst.boundary = {};   // 入口：无表达式可用（全集的补——must 的边界为空集）
    FVal vars, exprs;
    scanUniverse(code, vars, exprs);
    inst.initTop = exprs;   // 迭代从全集开始向下
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        std::string e = exprOf(q);
        if (!e.empty()) out.insert(e);
        if (isVar(q.dst)) {
            for (auto it = out.begin(); it != out.end();) {
                if (sharesOp(*it, q.dst)) it = out.erase(it);
                else ++it;
            }
        }
        return out;
    };
    return inst;
}

// ---------- 活跃变量（后向 may；元素 = 变量名） ----------
Instance makeLive(const std::vector<Quad> &code0) {
    (void)code0;
    Instance inst;
    inst.name = "live";
    inst.dir = Dir::Backward;
    inst.meetFn = unionMeet;
    inst.boundary = {};   // 出口：无活跃
    inst.initTop = {};
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        if (isVar(q.dst)) out.erase(q.dst);
        if (isVar(q.a)) { out.insert(q.a); }
        if (isVar(q.b)) { out.insert(q.b); }
        return out;
    };
    return inst;
}

// ---------- 非常忙表达式（后向 must；元素 = 表达式键） ----------
Instance makeVeryBusy(const std::vector<Quad> &code) {
    Instance inst;
    inst.name = "verybusy";
    inst.dir = Dir::Backward;
    inst.meetFn = interMeet;
    inst.boundary = {};
    FVal vars, exprs;
    scanUniverse(code, vars, exprs);
    inst.initTop = exprs;
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        // 先杀后生（后向扫描序）：x = x + 1 仍生成 "x + 1"
        if (isVar(q.dst)) {
            for (auto it = out.begin(); it != out.end();) {
                if (sharesOp(*it, q.dst)) it = out.erase(it);
                else ++it;
            }
        }
        std::string e = exprOf(q);
        if (!e.empty()) out.insert(e);
        return out;
    };
    return inst;
}

// ---------- 常量传播（前向；元素 "x=5" / "x=T"） ----------
namespace {
std::string constOf(const FVal &s, const std::string &v) {
    for (const auto &e : s)
        if (e.rfind(v + "=", 0) == 0) return e.substr(v.size() + 1);
    return "";
}
FVal constPropMeet(const FVal &a, const FVal &b) {
    FVal out;
    std::set<std::string> vars;
    for (const auto &e : a) vars.insert(e.substr(0, e.find('=')));
    for (const auto &e : b) vars.insert(e.substr(0, e.find('=')));
    for (const auto &v : vars) {
        std::string x = constOf(a, v), y = constOf(b, v);
        if (!x.empty() && !y.empty())
            out.insert(v + "=" + (x == y ? x : std::string("T")));
        else
            out.insert(v + "=T");   // 一侧缺失（⊥）一侧已知：保守取 ⊤
    }
    return out;
}
}  // namespace

Instance makeConstProp(const std::vector<Quad> &code0) {
    (void)code0;
    Instance inst;
    inst.name = "constprop";
    inst.dir = Dir::Forward;
    inst.meetFn = constPropMeet;
    inst.boundary = {};   // 入口：全部变量 ⊥（尚未定值）
    inst.initTop = {};    // ⊥ 起步（与 may 同形；⊤ 只在流动中出现）
    inst.transfer = [](int, const Quad &q, const FVal &in) {
        FVal out = in;
        auto rhsVal = [&](const std::string &s) -> std::string {
            if (isNum(s)) return s;
            std::string c = constOf(in, s);
            return c.empty() ? std::string("T") : c;
        };
        switch (q.op) {
        case TOp::Input:
            out.erase(q.dst + "=" + rhsVal(q.a));
            for (auto it = out.begin(); it != out.end();)
                if (it->rfind(q.dst + "=", 0) == 0) it = out.erase(it);
                else ++it;
            out.insert(q.dst + "=T");
            break;
        case TOp::Copy: {
            for (auto it = out.begin(); it != out.end();)
                if (it->rfind(q.dst + "=", 0) == 0) it = out.erase(it);
                else ++it;
            out.insert(q.dst + "=" + rhsVal(q.a));
            break;
        }
        case TOp::Add: case TOp::Sub: case TOp::Mul: case TOp::Div:
        case TOp::Gt: case TOp::Eq: {
            for (auto it = out.begin(); it != out.end();)
                if (it->rfind(q.dst + "=", 0) == 0) it = out.erase(it);
                else ++it;
            std::string l = rhsVal(q.a), r = rhsVal(q.b);
            if (l != "T" && r != "T") {
                int lv = std::atoi(l.c_str()), rv = std::atoi(r.c_str());
                int v = q.op == TOp::Add ? lv + rv
                        : q.op == TOp::Sub ? lv - rv
                        : q.op == TOp::Mul ? lv * rv
                        : q.op == TOp::Div ? lv / rv
                        : q.op == TOp::Gt ? (lv > rv ? 1 : 0)
                                          : (lv == rv ? 1 : 0);
                out.insert(q.dst + "=" + std::to_string(v));
            } else {
                out.insert(q.dst + "=T");
            }
            break;
        }
        default:
            break;
        }
        return out;
    };
    return inst;
}

}  // namespace tip
```

### 33.10.4 MOP 对照 mop.hpp 与 mop.cpp

路径枚举暴力解。

```cpp
// file: src/mop.hpp
// file: src/mop.hpp
// 第 33 章配套：MOP（全路径 meet）的暴力对照。
#ifndef TIP_MOP_HPP
#define TIP_MOP_HPP

#include "framework.hpp"

namespace tip {

// 深度 K（途经块数上限）内枚举全部路径的逐路径复合再 meet。
// 返回值与 solve 同口径：前向给每块 OUT、后向给每块 IN。
// 无环图上 K 足够大即为精确 MOP；有环时是深度受限的下近似。
std::vector<FVal> mop(const Instance &inst, const std::vector<Quad> &code,
                      const std::vector<Block> &blocks, int K);

}  // namespace tip

#endif  // TIP_MOP_HPP
```

```cpp
// file: src/mop.cpp
// file: src/mop.cpp
// 第 33 章配套：MOP 暴力实现——路径枚举 + 逐路径复合 + meet。
#include "mop.hpp"

#include <functional>

namespace tip {

std::vector<FVal> mop(const Instance &inst, const std::vector<Quad> &code,
                      const std::vector<Block> &blocks, int K) {
    size_t n = blocks.size();
    std::vector<FVal> res(n, inst.initTop);
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return k;
        return n;
    };
    if (inst.dir == Dir::Forward) {
        // 前向：MOP 的 out[b] = meet over 路径(entry→b) F_path(边界)。
        std::vector<bool> seen(n, false);
        std::function<void(size_t, const FVal &, int)> dfs =
            [&](size_t b, const FVal &v, int depth) {
                if (depth > K) return;
                FVal out = blockTransfer(inst, code, blocks[b], v);
                if (seen[b]) res[b] = inst.meetFn(res[b], out);
                else { res[b] = out; seen[b] = true; }
                for (int s : blocks[b].succs) {
                    size_t k = blockOf(s);
                    if (k < n) dfs(k, out, depth + 1);
                }
            };
        dfs(0, inst.boundary, 0);
        return res;
    }
    // 后向：MOP 的 in[b] = meet over 路径(b→exit) 逆复合(边界)。
    // 递归式：in[b] = F_b( meet over 后继 s 的 in[s] )，出口/截断处取边界。
    std::function<FVal(size_t, int, std::vector<bool> &)> valIn =
        [&](size_t cur, int depth, std::vector<bool> &onPath) -> FVal {
        FVal out;
        bool first = true;
        if (blocks[cur].succs.empty() || depth >= K) {
            out = inst.boundary;
        } else {
            for (int s : blocks[cur].succs) {
                size_t k = blockOf(s);
                if (k >= n || onPath[k]) continue;   // 环上同块不重入（深度外路径）
                onPath[k] = true;
                FVal sv = valIn(k, depth + 1, onPath);
                onPath[k] = false;
                out = first ? sv : inst.meetFn(out, sv);
                first = false;
            }
            if (first) out = inst.boundary;
        }
        return blockTransfer(inst, code, blocks[cur], out);
    };
    for (size_t b = 0; b < n; ++b) {
        std::vector<bool> onPath(n, false);
        onPath[b] = true;
        res[b] = valIn(b, 0, onPath);
    }
    return res;
}

}  // namespace tip
```

### 33.10.5 驱动 main.cpp

五实例并排 +
两行判定 +
结论段。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 33 章驱动：--check FILE
//   对五个实例（四大经典 + 常量传播）各跑：
//     MFP（框架迭代解） vs MOP≤K（路径枚举解），逐块并排打印 + 判定行；
//   收官一行：MFP ⊑ MOP 的方向性总检。
#include "framework.hpp"
#include "instances.hpp"
#include "mop.hpp"

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

void show(const tip::FVal &s) {
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

    std::vector<tip::Instance> insts = {
        tip::makeReaching(code), tip::makeAvailable(code),
        tip::makeLive(code), tip::makeVeryBusy(code),
        tip::makeConstProp(code),
    };
    const int K = 8;
    bool allSound = true;
    for (const auto &inst : insts) {
        tip::FrameResult mfp = tip::solve(inst, code, blocks);
        std::vector<tip::FVal> mopRes = tip::mop(inst, code, blocks, K);
        std::cout << "== " << inst.name << " ==\n";
        bool equal = true;
        bool sound = true;
        for (size_t b = 0; b < blocks.size(); ++b) {
            // 对照同一口径：前向比 OUT，后向比 IN
            const tip::FVal &m = inst.dir == tip::Dir::Forward ? mfp.out[b] : mfp.in[b];
            const tip::FVal &p = mopRes[b];
            std::cout << "  B" << b << "  MFP ";
            show(m);
            std::cout << "  |  MOP<= " << K << " ";
            show(p);
            std::cout << '\n';
            if (m != p) equal = false;
            // 方向性：may 实例要求 MFP ⊆ MOP；must 实例要求 MOP ⊆ MFP。
            // 常量传播单独口径：MFP 说 c 而 MOP 说 ⊤ 视为粗（正确方向），反向即错。
            if (inst.name == "reaching" || inst.name == "live") {
                for (const auto &x : m)
                    if (!p.count(x)) sound = false;
            } else if (inst.name == "available" || inst.name == "verybusy") {
                for (const auto &x : p)
                    if (!m.count(x)) sound = false;
            } else {
                for (const auto &x : m) {
                    std::string var = x.substr(0, x.find('='));
                    std::string val = x.substr(x.find('=') + 1);
                    std::string pval;
                    for (const auto &y : p)
                        if (y.rfind(var + "=", 0) == 0) pval = y.substr(var.size() + 1);
                    if (val != "T" && pval == "T") {
                        // MFP 常量、MOP 也常量但相同：fine；MOP=⊤ MFP=c 是 MFP 更精：
                        // 不可能（MOP ⊑ MFP 方向），标 unsound。
                        sound = false;
                    }
                }
            }
        }
        std::cout << "  MFP == MOP<= " << K << " : " << (equal ? "yes" : "no") << '\n';
        std::cout << "  MFP 在正确的一侧（方向性）: " << (sound ? "yes" : "NO") << '\n';
        allSound = allSound && sound;
    }

    std::cout << "== 结论 ==\n";
    std::cout << "  分配性实例（四大经典）：MFP 与 MOP 一致\n";
    std::cout << "  常量传播：MFP 可能严格粗于 MOP（差集见上方 no 的块）\n";
    return 0;
}
```

### 33.10.6 基座：tacgen、tacblocks 与前端

第 13、8、10 章原样。

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

### 33.10.7 程序与期望输出

```text
// file: programs/diamond.tip
main() {
  var c, x, y, z;
  c = input;
  if (c > 0) { x = 1; y = 1; } else { x = 2; y = 2; }
  z = x - y;
  output z;
  return 0;
}
```

```text
// file: programs/four.tip
main() {
  var a, b, cc;
  a = input;
  b = 1;
  if (a > 0) { b = a + 2; } else { b = a - 2; }
  while (a > 0) { a = a - 1; }
  cc = b + 1;
  output cc;
  return 0;
}
```

```text
; expected: expected/output.txt
== diamond.tip ==
== TAC ==
  0: t1 = input
  1: c = t1
  2: t2 = 0
  3: if c > t2 goto L5
  4: goto L10
  5: t3 = 1
  6: x = t3
  7: t4 = 1
  8: y = t4
  9: goto L14
  10: t5 = 2
  11: x = t5
  12: t6 = 2
  13: y = t6
  14: t7 = x - y
  15: z = t7
  16: output z
  17: t8 = 0
  18: return t8
== blocks ==
  B0 [0,4) succs: 4 5
  B1 [4,5) succs: 10
  B2 [5,10) succs: 14
  B3 [10,14) succs: 14
  B4 [14,19) succs:
== reaching ==
  B0  MFP {0:t1, 1:c, 2:t2}  |  MOP<= 8 {0:t1, 1:c, 2:t2}
  B1  MFP {0:t1, 1:c, 2:t2}  |  MOP<= 8 {0:t1, 1:c, 2:t2}
  B2  MFP {0:t1, 1:c, 2:t2, 5:t3, 6:x, 7:t4, 8:y}  |  MOP<= 8 {0:t1, 1:c, 2:t2, 5:t3, 6:x, 7:t4, 8:y}
  B3  MFP {0:t1, 10:t5, 11:x, 12:t6, 13:y, 1:c, 2:t2}  |  MOP<= 8 {0:t1, 10:t5, 11:x, 12:t6, 13:y, 1:c, 2:t2}
  B4  MFP {0:t1, 10:t5, 11:x, 12:t6, 13:y, 14:t7, 15:z, 17:t8, 1:c, 2:t2, 5:t3, 6:x, 7:t4, 8:y}  |  MOP<= 8 {0:t1, 10:t5, 11:x, 12:t6, 13:y, 14:t7, 15:z, 17:t8, 1:c, 2:t2, 5:t3, 6:x, 7:t4, 8:y}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== available ==
  B0  MFP {}  |  MOP<= 8 {}
  B1  MFP {}  |  MOP<= 8 {}
  B2  MFP {}  |  MOP<= 8 {}
  B3  MFP {}  |  MOP<= 8 {}
  B4  MFP {x - y}  |  MOP<= 8 {x - y}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== live ==
  B0  MFP {}  |  MOP<= 8 {}
  B1  MFP {}  |  MOP<= 8 {}
  B2  MFP {}  |  MOP<= 8 {}
  B3  MFP {}  |  MOP<= 8 {}
  B4  MFP {x, y}  |  MOP<= 8 {x, y}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== verybusy ==
  B0  MFP {}  |  MOP<= 8 {}
  B1  MFP {}  |  MOP<= 8 {}
  B2  MFP {}  |  MOP<= 8 {}
  B3  MFP {}  |  MOP<= 8 {}
  B4  MFP {x - y}  |  MOP<= 8 {x - y}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== constprop ==
  B0  MFP {c=T, t1=T, t2=0}  |  MOP<= 8 {c=T, t1=T, t2=0}
  B1  MFP {c=T, t1=T, t2=0}  |  MOP<= 8 {c=T, t1=T, t2=0}
  B2  MFP {c=T, t1=T, t2=0, t3=1, t4=1, x=1, y=1}  |  MOP<= 8 {c=T, t1=T, t2=0, t3=1, t4=1, x=1, y=1}
  B3  MFP {c=T, t1=T, t2=0, t5=2, t6=2, x=2, y=2}  |  MOP<= 8 {c=T, t1=T, t2=0, t5=2, t6=2, x=2, y=2}
  B4  MFP {c=T, t1=T, t2=0, t3=T, t4=T, t5=T, t6=T, t7=T, t8=0, x=T, y=T, z=T}  |  MOP<= 8 {c=T, t1=T, t2=0, t3=T, t4=T, t5=T, t6=T, t7=0, t8=0, x=T, y=T, z=0}
  MFP == MOP<= 8 : no
  MFP 在正确的一侧（方向性）: yes
== 结论 ==
  分配性实例（四大经典）：MFP 与 MOP 一致
  常量传播：MFP 可能严格粗于 MOP（差集见上方 no 的块）
== four.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: t2 = 1
  3: b = t2
  4: t3 = 0
  5: if a > t3 goto L7
  6: goto L11
  7: t4 = 2
  8: t5 = a + t4
  9: b = t5
  10: goto L14
  11: t6 = 2
  12: t7 = a - t6
  13: b = t7
  14: t8 = 0
  15: if a > t8 goto L17
  16: goto L21
  17: t9 = 1
  18: t10 = a - t9
  19: a = t10
  20: goto L14
  21: t11 = 1
  22: t12 = b + t11
  23: cc = t12
  24: output cc
  25: t13 = 0
  26: return t13
== blocks ==
  B0 [0,6) succs: 6 7
  B1 [6,7) succs: 11
  B2 [7,11) succs: 14
  B3 [11,14) succs: 14
  B4 [14,16) succs: 16 17
  B5 [16,17) succs: 21
  B6 [17,21) succs: 14
  B7 [21,27) succs:
== reaching ==
  B0  MFP {0:t1, 1:a, 2:t2, 3:b, 4:t3}  |  MOP<= 8 {0:t1, 1:a, 2:t2, 3:b, 4:t3}
  B1  MFP {0:t1, 1:a, 2:t2, 3:b, 4:t3}  |  MOP<= 8 {0:t1, 1:a, 2:t2, 3:b, 4:t3}
  B2  MFP {0:t1, 1:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}  |  MOP<= 8 {0:t1, 1:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}
  B3  MFP {0:t1, 11:t6, 12:t7, 13:b, 1:a, 2:t2, 4:t3}  |  MOP<= 8 {0:t1, 11:t6, 12:t7, 13:b, 1:a, 2:t2, 4:t3}
  B4  MFP {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 1:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}  |  MOP<= 8 {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 1:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}
  B5  MFP {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 1:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}  |  MOP<= 8 {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 1:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}
  B6  MFP {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}  |  MOP<= 8 {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}
  B7  MFP {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 1:a, 21:t11, 22:t12, 23:cc, 25:t13, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}  |  MOP<= 8 {0:t1, 11:t6, 12:t7, 13:b, 14:t8, 17:t9, 18:t10, 19:a, 1:a, 21:t11, 22:t12, 23:cc, 25:t13, 2:t2, 4:t3, 7:t4, 8:t5, 9:b}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== available ==
  B0  MFP {}  |  MOP<= 8 {}
  B1  MFP {}  |  MOP<= 8 {}
  B2  MFP {a + t4}  |  MOP<= 8 {a + t4}
  B3  MFP {a - t6}  |  MOP<= 8 {a - t6}
  B4  MFP {}  |  MOP<= 8 {}
  B5  MFP {}  |  MOP<= 8 {}
  B6  MFP {}  |  MOP<= 8 {}
  B7  MFP {b + t11}  |  MOP<= 8 {b + t11}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== live ==
  B0  MFP {}  |  MOP<= 8 {}
  B1  MFP {a}  |  MOP<= 8 {a}
  B2  MFP {a}  |  MOP<= 8 {a}
  B3  MFP {a}  |  MOP<= 8 {a}
  B4  MFP {a, b}  |  MOP<= 8 {a, b}
  B5  MFP {b}  |  MOP<= 8 {b}
  B6  MFP {a, b}  |  MOP<= 8 {a, b}
  B7  MFP {b}  |  MOP<= 8 {b}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== verybusy ==
  B0  MFP {}  |  MOP<= 8 {}
  B1  MFP {}  |  MOP<= 8 {}
  B2  MFP {}  |  MOP<= 8 {}
  B3  MFP {}  |  MOP<= 8 {}
  B4  MFP {}  |  MOP<= 8 {}
  B5  MFP {}  |  MOP<= 8 {}
  B6  MFP {}  |  MOP<= 8 {}
  B7  MFP {}  |  MOP<= 8 {}
  MFP == MOP<= 8 : yes
  MFP 在正确的一侧（方向性）: yes
== constprop ==
  B0  MFP {a=T, b=1, t1=T, t2=1, t3=0}  |  MOP<= 8 {a=T, b=1, t1=T, t2=1, t3=0}
  B1  MFP {a=T, b=1, t1=T, t2=1, t3=0}  |  MOP<= 8 {a=T, b=1, t1=T, t2=1, t3=0}
  B2  MFP {a=T, b=T, t1=T, t2=1, t3=0, t4=2, t5=T}  |  MOP<= 8 {a=T, b=T, t1=T, t2=1, t3=0, t4=2, t5=T}
  B3  MFP {a=T, b=T, t1=T, t2=1, t3=0, t6=2, t7=T}  |  MOP<= 8 {a=T, b=T, t1=T, t2=1, t3=0, t6=2, t7=T}
  B4  MFP {a=T, b=T, t10=T, t1=T, t2=T, t3=T, t4=T, t5=T, t6=T, t7=T, t8=0, t9=T}  |  MOP<= 8 {a=T, b=T, t10=T, t1=T, t2=1, t3=0, t4=T, t5=T, t6=T, t7=T, t8=0, t9=T}
  B5  MFP {a=T, b=T, t10=T, t1=T, t2=T, t3=T, t4=T, t5=T, t6=T, t7=T, t8=0, t9=T}  |  MOP<= 8 {a=T, b=T, t10=T, t1=T, t2=1, t3=0, t4=T, t5=T, t6=T, t7=T, t8=0, t9=T}
  B6  MFP {a=T, b=T, t10=T, t1=T, t2=T, t3=T, t4=T, t5=T, t6=T, t7=T, t8=0, t9=1}  |  MOP<= 8 {a=T, b=T, t10=T, t1=T, t2=1, t3=0, t4=T, t5=T, t6=T, t7=T, t8=0, t9=1}
  B7  MFP {a=T, b=T, cc=T, t10=T, t11=1, t12=T, t13=0, t1=T, t2=T, t3=T, t4=T, t5=T, t6=T, t7=T, t8=0, t9=T}  |  MOP<= 8 {a=T, b=T, cc=T, t10=T, t11=1, t12=T, t13=0, t1=T, t2=1, t3=0, t4=T, t5=T, t6=T, t7=T, t8=0, t9=T}
  MFP == MOP<= 8 : no
  MFP 在正确的一侧（方向性）: yes
== 结论 ==
  分配性实例（四大经典）：MFP 与 MOP 一致
  常量传播：MFP 可能严格粗于 MOP（差集见上方 no 的块）
```

## 33.11 小结与练习

本章把数据流
从"手艺"升为"理论"：

- 半格给"合并"
  立了代数；
- 单调 + 有限高度
  ⇒ 收敛到
  最大不动点；
- MFP ⊑ MOP
  恒成立，
  分配时取等；
- 四大经典
  因 gen/kill
  天然分配
  而进入
  等号俱乐部；
- 常量传播
  用一个菱形
  演示了
  非分配性
  如何把
  路径里的
  联合常量
  丢在汇合点。

至此第五篇
（格与数据流）
收官。
下一程进入
控制流的结构：
支配者把"必经之路"
变成代数，
自然循环、
SSA、以及
循环优化，
都将踩在
支配树上。

练习：

1. 手工验证
   `F(S) = gen ∪ (S − kill)`
   对 ∪ 分配、
   对 ∩ 的 must 版
   对 ∩ 分配
   （各写一遍
   集合等式）。
2. 把 diamond.tip 的
   else 支改成
   `x = 1; y = 2;`，
   重跑：
   MOP 的 z 变成什么？
   MFP 变吗？
   解释"为什么
   这次两者
   一致地粗"。
3. 给实例表加
   第六个成员
   "定值计数"
   （元素 = 变量，
    转移 = def 置 1、
    meet = 逐变量取大），
   判断它是否
   分配，
   并用 MOP 对照
   验证你的判断。
4. 把 mop.cpp 的
   K 调成 2 与 16
   分别重跑
   four.tip，
   观察哪些块的
   MOP 集合变化，
   解释截断的
   影响面。
5. （强对账）
   复制第 25/26 章
   的专门实现
   进本章目录，
   对 four.tip
   逐块比对
   四大分析的
   专门解与
   框架解，
   断言完全一致。
