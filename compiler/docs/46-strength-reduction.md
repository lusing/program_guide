# 第 46 章　强度削减与线性函数测试替换：循环里的乘法

## 46.1 问题：循环里的乘法按次付费

第 45 章
把循环
不变量
外提了。
但有一类
开销
外提
不了：
**依赖
循环变量
的计算**——

```
for (i = 1; i < n; i++)
    s = s + i * 4;
```

`s + i*4`
每次
迭代
都要
乘一次，
而 i
每圈
只加 1。
`i*4`
取值
4, 8, 12, …——
**等差
数列**。
等差
数列
有个
天生的
便宜
更新：
**加
固定
步长**。
操作符
强度削减
（operator
strength
reduction，
OSR）
就是把
"每圈
一次
乘法"
换成
"每圈
一次
加法"：

```
t = 4;                     ← 循环前乘一次（初值）
for (...)
    s = s + t;
    t = t + 4;             ← 每圈加步长
```

这个
变换
的
历史
地位
极高：
数组
下标
寻址
（第 19 章
的
`(i−low)×w`）
在
循环里
批量
制造
`i×4`，
早期
机器
乘法
极贵，
OSR
曾是
循环
优化的
头号
红利。
现代
机器
乘法
便宜了，
但
削减后的
形状
还有
第二重
红利：
**自增
寻址
模式**
（`load t; t += 4`
折进
访存
指令）、
更短的
依赖链
（喂给
第 64 章
调度器）。
材料
取自
鲸书
§10.7.2，
自包含
展开。

## 46.2 归纳变量与 region constant：SSA 图上的环

两个
定义
撑起
整个
变换：

**归纳
变量**
（induction
variable）：
值在
循环内
**成
等差
数列**
的量。
鲸书
的
操作化
定义
出人
意料
地
代数：
在
SSA 图
（名字
为点、
use→def
为边）
上，
归纳
变量
是一个
**强连通
分量**，
且
分量里
每个
定义
都是
四类
**合法
更新**
之一：

1. φ
  （循环
  头
  合并
  初值
  与
  上圈）；
2. copy
  自
  链内
  或
  链外；
3. 链内
  名字
  **加**
  字面量；
4. 链内
  名字
  **减**
  字面量。

我们的
while
循环
在
SSA
下
天然
长成
一个
环：
`i1 =
φ(i0,
i2)`、
`i2 =
t111`、
`t111
= i1
+ 1`——
i1 →
t111 →
i2 →
(φ)
→ i1。
乘、除、
比较
出现在
环上
即
否决——
它们
不产生
等差
数列。

**region
constant**：
相对于
某循环
不变的
量。
字面量
是最
平凡
的
一种；
一般的
判定
是
"定义
支配
归纳
变量
的
header"——
第 40 章
的
支配
概念
在
这里
收账。
本章
实现
取
窄化
口径
（只认
字面量），
一般
判定
留作
练习。

**候选**
操作
五型：
`c×i、
i×c、
c+i、
i+c、
i−c`
（c 是
region
constant、
i 是
归纳
变量）。
我们
实现
乘法
一型
（最有
代表性；
加法型
留给
练习）。

## 46.3 Tarjan SCC：让候选"用前先分类"

OSR 的
骨架
是
一次
**Tarjan
DFS**
（鲸书
Figure
10.13）：
在
SSA 图上
跑
强连通
分量，
SCC
从栈上
弹出时
交给
`Process`：

- 单节点
  SCC：
  是候选
  就地
  削减
  （`Replace`），
  不是
  则
  标记
  "非
  归纳"；
- 多节点
  SCC：
  `ClassifyIV`
  判定
  是否
  归纳
  链——
  是则
  全员
  登记
  header，
  否则
  逐个
  再试
  候选。

鲸书
点出
的
巧思：
**DFS
的弹栈
次序
保证
操作数
先于
使用
被分类**。
因为
边
从
use
指向
def，
一个
候选
被弹出
时，
它的
操作数
所属
SCC
已经
处理
完毕——
"i 是
不是
归纳
变量"
这个
问题
在
问出
时
已有
答案。
一次
DFS
同时
完成
识别
与
改写，
不需要
两遍。

实现里
还有
一个
前置
小关：
我们的
TACGen
给
每个
常量
开
临时槽
（`t71
= 4`），
候选
与
合法
更新
看到
的是
临时名
而非
字面量。
先跑
一遍
**常量
穿透**
（把
"x =
字面量"
的
临时
折进
操作数，
含
copy
链与
φ 实参），
图就
干净了。
第 44 章
DVNT
的
值编号
也能
做
这件事——
这里
只要
直译版。

## 46.4 削减：克隆一条新链

找到
候选
`t81
= i1
× 4`
后，
`Reduce`/`Apply`
的
直译
是
**克隆
整条
链**
（`Clone`
绕
SCC
一圈），
但配好
新
初值
与
新
步长：
三
部件
（期望
输出
里
看得到
每一件）：

1. **初值**
  （循环前）：
  `t81#sr0
  = i0
  × 4`
  ——初值
  乘
  一次，
  摊到
  循环
  外；
  初值
  是
  字面量
  则
  编译期
  折掉；
2. **新 φ**
  （header）：
  `t81#sr
  = φ(t81#sr0,
  t81#sr1)`；
3. **新步长**
  （latch，
  原
  i 更新
  之后）：
  `t81#sr1
  = t81#sr
  + 4`
  ——新
  步长
  = 原
  步长
  × c
  （1×4，
  编译期
  算好）。

然后
候选
本身
删除，
全程序
把
旧名
改写
成
新 φ
名。
鲸书
用
全局
哈希表
防
重复
克隆
（同一
(iv, c)
组合
只造
一次
新链）——
我们的
示例
每链
至多
一个
候选，
从简
省去，
正文
记录
这个
工程
差异。

## 46.5 LFTR：把测试也搬过去

削减完
有个
收尾
问题：
旧链
`i`
的
**唯一
残存
用途**
可能
只剩
循环
测试
`if
n >
i`。
线性
函数
测试
替换
（linear
function
test
replacement）
把
测试
也
搬到
新链
上：

> `n > i`
> ⇒ `n×c >
> t81#sr`

界
乘 c：
字面量
直接
折
（100×4
= 400），
名字
则
循环
外
造
一次
乘法
`lim
= n×4`。
换完
测试，
旧链
**彻底
无用电**，
DCE
全链
清走——
期望
输出的
削减后
程序里
`i1/i2/t111`
整条
消失。

LFTR 的
前置
条件
"链
只剩
测试
一个
链外
用途"
数起来
有个
陷阱：
**保守 φ**
（第 41 章
buildSsa
给
单臂
定义
名字
插的
占位
φ）
会
挂着
链名
当
"用途"。
所以
我们的
顺序
是
**先
DCE
一遍、
再
LFTR、
再
DCE
一遍**——
死代码
不清，
"只剩"
永远
数
不对。

## 46.6 DCE 与削减的配合：死环要靠根可达

DCE 本身
也有
一课。
朴素
DCE
按
"引用
计数
为零"
删指令，
但旧链
是
**环**：
φ 用
更新、
更新
用 φ，
计数
永远
≥1，
谁也
死不
透。
解法
是
**根可达
标记
清扫**：

- 根 =
  控制指令
  （output/
  return/
  跳转，
  它们
  永远
  活）；
- 从根
  的操作数
  出发
  沿
  use→def
  反向
  传播
  "活"；
- 环上
  没有根
  入口
  就整环
  死。

这与
GC
的
标记
清扫
同构——
编译器
里的
死代码
就是
内存
里的
垃圾。

## 46.7 期望输出解读与对账

示例
程序
osr.tip
两个
循环
对照
设计：

- **循环一**：
  `s
  = s
  + i*4`
  ——i 链、
  因子 4
  字面量：
  完整
  走
  识别→
  削减→
  LFTR→
  DCE
  全流程；
- **循环二**：
  `u
  = u
  + k*s`
  ——s 是
  循环一
  的
  结果
  （φ），
  **非
  字面量**：
  非候选，
  必须原样
  保留。

期望
输出的
账：

1. **归纳
  变量**：
  两条链
  （i1、
  k1）
  各自
  识别
  成 SCC；
2. **削减**：
  仅
  `t81
  × 4
  →
  t81#sr`
  （循环二
  的
  t121
  因子
  非字面量，
  不动）；
3. **LFTR**：
  `i1
  与
  100
  的
  测试
  →
  t81#sr
  与
  400`；
4. **削减后**
  程序：
  循环一
  只剩
  `s
  = s
  +
  t81#sr；
  t81#sr
  +=
  4`，
  测试
  `if
  400
  >
  t81#sr`——
  i 链
  整条
  消失；
  循环二
  原样
  （含
  `k1
  *
  s1`）；
5. **乘法
  账**：
  循环一
  体内
  乘法
  **1→0**
  （初值
  乘法
  在
  循环外
  B0），
  循环二
  保持
  1；
6. **对账**：
  outputs
  削减
  前后
  相等
  （19800
  与
  98010000），
  四断言
  全绿。

值得
盯一眼
B0：
循环外
只剩
`t81#sr0
= 4`——
初值
乘法
被
字面量
折叠
吃掉
了；
若初值
是
运行期
值，
这里
会是
一次
真正的
Mul。

## 46.8 工程注意点

- **先
  常量
  穿透**：
  没有
  它，
  一切
  候选
  都被
  常量
  临时
  挡住。
  生产
  编译器
  把
  OSR
  排在
  常量
  传播、
  DVNT
  之后
  （鲸书
  原话：
  它们
  能
  "暴露
  更多
  region
  constant"）。
- **过早
  移位
  的
  反例**：
  把
  `4×s`
  改写成
  `s
  <<
  2`
  会
  锁死
  交换律，
  剥夺
  后续
  重结合
  （第 64 章
  树高
  平衡）
  的
  机会——
  削减
  产出
  **加法**，
  正是
  给
  下游
  留的
  活口。
- **寄存
  器
  压力**：
  每条
  新链
  占
  一个
  寄存器。
  循环
  里
  削减
  多个
  候选
  可能
  把
  第 61 章
  分配器
  逼向
  溢出——
  鲸书
  的
  建议：
  削减
  后跑
  一遍
  "归纳
  变量
  清扫"
  （删除
  LFTR
  后
  无用的
  旧链），
  我们
  的
  第二遍
  DCE
  就是
  它的
  近亲。
- **与
  循环
  不变
  代码
  外提
  的
  分工**：
  LICM
  （第 45 章）
  搬
  **不依赖
  循环
  变量**
  的
  计算，
  OSR
  改写
  **依赖
  循环
  变量**
  的
  计算——
  一搬
  一改，
  合起来
  才是
  完整的
  循环
  火力。
- **modulo
  调度
  的
  前置**：
  软件
  流水
  （第 64 章）
  假设
  循环
  体是
  紧凑
  的
  加法
  链——
  那正是
  OSR
  交付
  的
  形状。

## 46.9 本章配套文件

## 46.9 本章配套文件

示例复用第 41 章（SSA）的基座本地副本，新增 osr.hpp/osr.cpp 与驱动。

### 46.9.1 文法 TIP.g4

```text
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

### 46.9.2 新件：osr.hpp 与 osr.cpp

常量穿透、Tarjan SCC、克隆三部件、LFTR、根可达 DCE（正文 41.3–41.6 逐段讲解）。

```cpp
// file: src/osr.hpp
// file: src/osr.hpp
// 第 46 章配套：操作符强度削减（OSR）与线性函数测试替换（LFTR）（鲸书 §10.7.2）。
#ifndef TIP_OSR_HPP
#define TIP_OSR_HPP

#include <set>
#include <string>
#include <vector>

#include "ssa.hpp"

namespace tip {

struct OsrReport {
    std::vector<std::string> ivs;       // 识别出的归纳变量 SCC（φ 名作代表）
    std::vector<std::string> reduced;   // 削减记录（旧名 ×c → 新名）
    std::vector<std::string> lftr;      // 测试替换记录
    int mulLoopBefore = 0;              // 第一个循环体内的乘法数（削减前）
    int mulLoopAfter = 0;               // 削减 + LFTR + DCE 后
    int mulUntouched = 0;               // 非候选乘法（j 非字面量）——必须原样保留
    int deadRemoved = 0;                // DCE 清走的死指令
};

struct OsrResult {
    OsrReport rep;
    SsaProgram prog;
};

// SSA 图上的 OSR：
//   1) Tarjan SCC 找归纳变量（合法更新：φ / copy / ±字面量）；
//   2) 候选 x = iv × c（c 字面量）克隆出新的加法归纳变量；
//   3) LFTR：iv 只剩测试用途时把测试换成新变量的同界测试；
//   4) DCE 扫掉死透的旧链。
OsrResult runOSR(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds);

}  // namespace tip

#endif  // TIP_OSR_HPP
```

```cpp
// file: src/osr.cpp
// file: src/osr.cpp
// 第 46 章配套：操作符强度削减的实现
// （常量穿透 → Tarjan SCC 归纳变量识别 → 克隆新链 → LFTR → 根可达 DCE，
// 鲸书 §10.7.2）。
#include "osr.hpp"

#include <map>

namespace tip {

namespace {

bool isLiteral(const std::string &s) {
    if (s.empty()) return false;
    size_t k = (s[0] == '-' && s.size() > 1) ? 1 : 0;
    if (k >= s.size()) return false;
    for (; k < s.size(); ++k)
        if (!isdigit(static_cast<unsigned char>(s[k]))) return false;
    return true;
}

// 名字 → 定义（块号，体内下标）。未定义（字面量/占位）不在表里。
using DefMap = std::map<std::string, std::pair<int, int>>;

DefMap defMapOf(const SsaProgram &p) {
    DefMap d;
    for (size_t b = 0; b < p.blocks.size(); ++b)
        for (size_t i = 0; i < p.blocks[b].body.size(); ++i)
            d[p.blocks[b].body[i].dst] = {static_cast<int>(b), static_cast<int>(i)};
    return d;
}

// 一条指令的操作数（含 φ 实参）
std::vector<std::string> operandsOf(const SsaInst &inst) {
    if (!inst.phiArgs.empty()) return inst.phiArgs;
    std::vector<std::string> out;
    if (!inst.a.empty()) out.push_back(inst.a);
    if (!inst.b.empty()) out.push_back(inst.b);
    return out;
}

void rewriteOperands(SsaInst &inst, const std::map<std::string, std::string> &m) {
    auto f = [&](std::string &x) {
        auto it = m.find(x);
        if (it != m.end()) x = it->second;
    };
    if (!inst.phiArgs.empty()) {
        for (auto &arg : inst.phiArgs) f(arg);
        return;
    }
    f(inst.a);
    f(inst.b);
}

// 常量穿透：TACGen 为每个常量开临时槽（t71 = 4），候选与归纳链看到的是
// 临时名而非字面量。把"x = 字面量"的临时整条穿透（含 φ 实参与 copy 链），
// 让 Mul/Add 的操作数直接是字面量。DVNT 也能做这件事——这里只要直译版。
void materializeLiterals(SsaProgram &p) {
    std::map<std::string, std::string> lit;
    for (bool ch = true; ch;) {
        ch = false;
        for (auto &blk : p.blocks) {
            std::vector<SsaInst> live;
            for (auto inst : blk.body) {
                if (inst.op == TOp::Copy && inst.phiArgs.empty() && isLiteral(inst.a)) {
                    lit[inst.dst] = inst.a;   // 槽位退役，登记字面量
                    ch = true;
                    continue;
                }
                if (inst.op == TOp::Copy && inst.phiArgs.empty() && lit.count(inst.a)) {
                    lit[inst.dst] = lit[inst.a];   // copy 链继续穿透
                    ch = true;
                    continue;
                }
                live.push_back(inst);
            }
            blk.body = live;
        }
    }
    for (auto &blk : p.blocks)
        for (auto &inst : blk.body) rewriteOperands(inst, lit);
}

// 在块内终结符之前插入（无终结符则追加）
void insertBeforeTerm(std::vector<SsaInst> &body, SsaInst inst) {
    size_t at = body.size();
    for (size_t k = body.size(); k-- > 0;)
        if (body[k].op == TOp::Goto || body[k].op == TOp::IfGt || body[k].op == TOp::IfEq) {
            at = k;
            break;
        }
    body.insert(body.begin() + at, std::move(inst));
}

// ---------- Tarjan SCC（鲸书 Figure 10.13 的 DFS 骨架）----------
// 图：名字为节点，边 name → 其操作数的定义名（use 到 def）。
// DFS 弹 SCC 的次序保证：候选遇到时其操作数已分类（鲸书的巧思）。
struct SccFinder {
    const SsaProgram &p;
    const DefMap &def;
    std::map<std::string, int> num, low;
    std::map<std::string, bool> onStack, visited;
    std::vector<std::string> stack;
    std::vector<std::vector<std::string>> sccs;
    int nextNum = 0;

    SccFinder(const SsaProgram &prog, const DefMap &d) : p(prog), def(d) {}

    void run() {
        for (const auto &blk : p.blocks)
            for (const auto &inst : blk.body)
                if (!inst.dst.empty() && !visited.count(inst.dst)) dfs(inst.dst);
    }
    void dfs(const std::string &n) {
        num[n] = low[n] = nextNum++;
        visited[n] = true;
        stack.push_back(n);
        onStack[n] = true;
        auto it = def.find(n);
        if (it != def.end()) {
            const SsaInst &inst = p.blocks[it->second.first].body[it->second.second];
            for (const auto &o : operandsOf(inst)) {
                if (!def.count(o)) continue;   // 字面量/占位：无边
                if (!visited.count(o)) {
                    dfs(o);
                    low[n] = std::min(low[n], low[o]);
                } else if (onStack[o]) {
                    low[n] = std::min(low[n], num[o]);
                }
            }
        }
        if (low[n] == num[n]) {
            std::vector<std::string> scc;
            for (;;) {
                std::string x = stack.back();
                stack.pop_back();
                onStack[x] = false;
                scc.push_back(x);
                if (x == n) break;
            }
            sccs.push_back(std::move(scc));
        }
    }
};

// 归纳变量判定（ClassifyIV 的窄化版）：SCC 成环且每个成员的定义是
// φ / copy / 与字面量的加减（另一操作数在 SCC 内）。
bool classifyIv(const SsaProgram &p, const DefMap &def,
                const std::set<std::string> &scc) {
    if (scc.size() < 2) return false;   // 环至少两个节点（φ → 更新 → φ）
    bool hasPhi = false;
    for (const auto &n : scc) {
        const SsaInst &inst = p.blocks[def.at(n).first].body[def.at(n).second];
        if (!inst.phiArgs.empty()) { hasPhi = true; continue; }
        if (inst.op == TOp::Copy) continue;   // copy 自链内或链外均可
        if (inst.op == TOp::Add || inst.op == TOp::Sub) {
            bool litA = isLiteral(inst.a), litB = isLiteral(inst.b);
            if (litA == litB) return false;               // 必须恰一个字面量
            const std::string &other = litA ? inst.b : inst.a;
            if (!scc.count(other)) return false;          // 另一操作数要在链内
            continue;
        }
        return false;   // 乘/除/比较不是合法更新
    }
    return hasPhi;      // 我们的形态：链上必有 φ（header）
}

}  // namespace

OsrResult runOSR(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds) {
    OsrResult res;
    res.prog = ssa;
    SsaProgram &p = res.prog;

    // ---------- 0) 常量穿透 ----------
    materializeLiterals(p);
    DefMap def = defMapOf(p);

    // ---------- 1) SCC 与归纳变量 ----------
    SccFinder finder(p, def);
    finder.run();
    std::map<std::string, std::string> ivOf;               // 名 → 所属链（φ 名）
    std::map<std::string, std::set<std::string>> chainOf;  // φ 名 → 链成员
    for (const auto &scc : finder.sccs) {
        std::set<std::string> s(scc.begin(), scc.end());
        if (!classifyIv(p, def, s)) continue;
        std::string phi = *s.begin();
        for (const auto &n : s) {
            const SsaInst &inst = p.blocks[def.at(n).first].body[def.at(n).second];
            if (!inst.phiArgs.empty()) { phi = n; break; }
        }
        for (const auto &n : s) ivOf[n] = phi;
        chainOf[phi] = s;
        res.rep.ivs.push_back(phi);
    }

    // ---------- 2) 候选削减：x = iv × c（c 字面量）----------
    // 克隆三部件（Reduce/Apply 的直译）：初值乘一次（循环外）、header 新 φ、
    // latch 在 iv 更新后加 step×c。
    // 遍历用深拷贝快照：插入会落在（可能正是遍历中的）块里，绝不能边走边改。
    std::map<std::string, std::string> rewrite;                  // 旧名 → 新 φ 名
    std::map<std::string, std::pair<std::string, int>> newOf;    // 链 φ → (新 φ 名, c)
    {
        SsaProgram scan = p;
        for (const auto &blk : scan.blocks)
            for (const auto &inst : blk.body) {
                if (inst.op != TOp::Mul || !inst.phiArgs.empty()) continue;
                bool litA = isLiteral(inst.a), litB = isLiteral(inst.b);
                std::string ivName, cstr;
                if (litB && ivOf.count(inst.a) && !litA) { ivName = inst.a; cstr = inst.b; }
                else if (litA && ivOf.count(inst.b) && !litB) { ivName = inst.b; cstr = inst.a; }
                if (ivName.empty()) continue;
                std::string phi = ivOf[ivName];
                const auto &chain = chainOf[phi];
                auto pd = def.at(phi);
                const SsaInst &phiInst = p.blocks[pd.first].body[pd.second];
                // step 与更新位置：链内 Add/Sub 的字面量
                int step = 0;
                auto updDef = def.end();
                for (const auto &n : chain) {
                    const SsaInst &d = p.blocks[def.at(n).first].body[def.at(n).second];
                    if (d.op == TOp::Add || d.op == TOp::Sub) {
                        const std::string &lit = isLiteral(d.a) ? d.a : d.b;
                        step = (d.op == TOp::Sub) ? -std::stoi(lit) : std::stoi(lit);
                        updDef = def.find(n);
                    }
                }
                if (updDef == def.end()) continue;
                int c = std::stoi(cstr);
                std::string newName = inst.dst + "#sr";
                SsaInst init;                       // 初值：循环前乘一次（字面量则折）
                init.dst = newName + "0";
                if (isLiteral(phiInst.phiArgs[0])) {
                    init.op = TOp::Copy;
                    init.a = std::to_string(std::stoi(phiInst.phiArgs[0]) * c);
                } else {
                    init.op = TOp::Mul;
                    init.a = phiInst.phiArgs[0];
                    init.b = cstr;
                }
                SsaInst newPhi;                     // header 新 φ
                newPhi.dst = newName;
                newPhi.phiArgs = {init.dst, newName + "1"};
                SsaInst upd;                        // latch 新步长
                upd.op = TOp::Add;
                upd.dst = newName + "1";
                upd.a = newName;
                upd.b = std::to_string(step * c);
                int initBlock = 0;
                auto initDef = def.find(phiInst.phiArgs[0]);
                if (initDef != def.end()) initBlock = initDef->second.first;
                insertBeforeTerm(p.blocks[initBlock].body, init);
                auto &hb = p.blocks[pd.first].body;
                size_t phiEnd = 0;
                while (phiEnd < hb.size() && !hb[phiEnd].phiArgs.empty()) ++phiEnd;
                hb.insert(hb.begin() + phiEnd, newPhi);
                auto &lb = p.blocks[updDef->second.first].body;
                lb.insert(lb.begin() + updDef->second.second + 1, upd);
                rewrite[inst.dst] = newName;
                newOf[phi] = {newName, c};
                res.rep.reduced.push_back(inst.dst + " × " + cstr + " → " + newName +
                                          "（初值乘一次，步长 " + std::to_string(step * c) + "）");
                def = defMapOf(p);   // 插入挪位，全表重建
            }
        // 删除候选本体（按目的名精确匹配，避免下标漂移）
        for (auto &b : p.blocks) {
            std::vector<SsaInst> live;
            for (const auto &inst : b.body)
                if (rewrite.count(inst.dst) && inst.op == TOp::Mul) continue;
                else live.push_back(inst);
            b.body = live;
        }
    }
    for (auto &blk : p.blocks)
        for (auto &inst : blk.body) rewriteOperands(inst, rewrite);
    def = defMapOf(p);

    // ---------- 3) DCE：根可达标记清扫 ----------
    // 引用计数删不动死环（φ → 更新 → φ 互相引用）；从控制根（output/return/
    // 跳转）反向可达才留。纯定义不在可达集即删。
    // LFTR 的前置条件是"链只剩测试一个链外用途"——保守 φ 等死代码不清，
    // 这个条件永远数不对，所以先清一遍、换完测试再清一遍。
    auto dce = [&]() {
        std::set<std::string> live;
        std::vector<std::string> work;
        for (const auto &blk : p.blocks)
            for (const auto &inst : blk.body) {
                bool root = inst.op == TOp::Output || inst.op == TOp::Ret ||
                            inst.op == TOp::Goto || inst.op == TOp::IfGt ||
                            inst.op == TOp::IfEq;
                if (!root) continue;
                for (const auto &o : operandsOf(inst))
                    if (def.count(o) && !live.count(o)) { live.insert(o); work.push_back(o); }
            }
        while (!work.empty()) {
            std::string n = work.back();
            work.pop_back();
            auto it = def.find(n);
            if (it == def.end()) continue;
            for (const auto &o : operandsOf(p.blocks[it->second.first].body[it->second.second]))
                if (def.count(o) && !live.count(o)) { live.insert(o); work.push_back(o); }
        }
        for (auto &blk : p.blocks) {
            std::vector<SsaInst> keep;
            for (const auto &inst : blk.body) {
                bool ctrl = inst.op == TOp::Output || inst.op == TOp::Ret ||
                            inst.op == TOp::Goto || inst.op == TOp::IfGt ||
                            inst.op == TOp::IfEq;
                if (!ctrl && !inst.dst.empty() && !live.count(inst.dst)) {
                    ++res.rep.deadRemoved;
                    continue;
                }
                keep.push_back(inst);
            }
            blk.body = keep;
        }
        def = defMapOf(p);
    };
    dce();

    // ---------- 4) LFTR：链只剩测试这一个链外用途时，换测试 ----------
    for (const auto &kv : chainOf) {
        const std::string &phi = kv.first;
        const auto &chain = kv.second;
        auto nit = newOf.find(phi);
        if (nit == newOf.end()) continue;   // 本链没有削减产物，无从换测试
        std::vector<std::pair<int, int>> outside;   // (块, 指令) 链外使用点
        for (size_t b = 0; b < p.blocks.size(); ++b)
            for (size_t i = 0; i < p.blocks[b].body.size(); ++i) {
                const SsaInst &inst = p.blocks[b].body[i];
                if (chain.count(inst.dst)) continue;   // 链内定义不算
                bool usesChain = false;
                for (const auto &o : operandsOf(inst))
                    if (chain.count(o)) { usesChain = true; break; }
                if (usesChain) outside.push_back({static_cast<int>(b), static_cast<int>(i)});
            }
        if (outside.size() != 1) continue;
        int ub = outside[0].first, ui = outside[0].second;
        if (p.blocks[ub].body[ui].op != TOp::IfGt &&
            p.blocks[ub].body[ui].op != TOp::IfEq) continue;
        const std::string newName = nit->second.first;
        const int c = nit->second.second;
        // 拷贝取操作数——界侧插乘法可能挪动指令向量，禁止持有引用
        std::string opIv = chain.count(p.blocks[ub].body[ui].a) ? p.blocks[ub].body[ui].a
                                                                : p.blocks[ub].body[ui].b;
        std::string bound = chain.count(p.blocks[ub].body[ui].a) ? p.blocks[ub].body[ui].b
                                                                 : p.blocks[ub].body[ui].a;
        std::string scaled;
        if (isLiteral(bound)) {
            scaled = std::to_string(std::stoi(bound) * c);
        } else {
            std::string lim = bound + "*" + std::to_string(c);
            SsaInst mul;
            mul.op = TOp::Mul;
            mul.dst = lim;
            mul.a = bound;
            mul.b = std::to_string(c);
            auto bd = def.at(bound);
            insertBeforeTerm(p.blocks[bd.first].body, mul);
            def = defMapOf(p);
            scaled = lim;
        }
        res.rep.lftr.push_back(opIv + " 与 " + bound + " 的测试 → " + newName +
                               " 与 " + scaled + "（界 ×" + std::to_string(c) + "）");
        if (p.blocks[ub].body[ui].a == opIv) p.blocks[ub].body[ui].a = newName;
        else p.blocks[ub].body[ui].b = newName;
        if (p.blocks[ub].body[ui].a == bound) p.blocks[ub].body[ui].a = scaled;
        else p.blocks[ub].body[ui].b = scaled;
        def = defMapOf(p);
    }
    // ---------- 5) 再清一遍：换测试后旧链死透 ----------
    dce();

    // ---------- 统计：循环体内乘法 ----------
    // while 形态：header 块 + 其后继块计为一个循环的"体"（不含循环前的前驱块）。
    auto mulCount = [&](const SsaProgram &q, int header) {
        int cnt = 0;
        std::set<int> region{header};
        for (int s : adj[header]) region.insert(s);
        for (int b : region)
            for (const auto &inst : q.blocks[b].body)
                if (inst.op == TOp::Mul && inst.phiArgs.empty()) ++cnt;
        return cnt;
    };
    std::vector<int> headers;
    for (size_t b = 0; b < p.blocks.size(); ++b) {
        bool hasIf = false;
        for (const auto &inst : p.blocks[b].body)
            if (inst.op == TOp::IfGt || inst.op == TOp::IfEq) hasIf = true;
        if (hasIf && preds[b].size() >= 2) headers.push_back(static_cast<int>(b));
    }
    if (headers.size() >= 2) {
        res.rep.mulLoopBefore = mulCount(ssa, headers[0]);
        res.rep.mulLoopAfter = mulCount(p, headers[0]);
        res.rep.mulUntouched = mulCount(p, headers[1]);
    }
    return res;
}

}  // namespace tip
```

### 46.9.3 驱动 main.cpp

削减前后程序对照、乘法账、解释器对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 46 章驱动：
//   --check FILE：TIP → TAC → SSA → OSR（SCC 找归纳变量 → 削减 → LFTR → DCE）→
//   前后程序对照 + 循环乘法账 + SSA 解释器对账。
#include "osr.hpp"

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

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
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
    Parsed p;
    p.ast = tip::buildAst(tree);
    p.bindings = tip::resolveNames(*p.ast);
    if (!p.bindings.errors.empty())
        throw std::runtime_error("名字解析错误: " + p.bindings.errors.front().text);
    return p;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    Parsed p = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*p.ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    size_t n = blocks.size();
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    auto preds = tip::predsOf(adj);

    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA（削减前）==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    tip::OsrResult r = tip::runOSR(ssa, adj, preds);
    std::cout << "== 归纳变量（SSA 图 SCC）==\n";
    for (const auto &iv : r.rep.ivs) std::cout << "  链头 φ: " << iv << "\n";
    std::cout << "== 削减 ==\n";
    for (const auto &s : r.rep.reduced) std::cout << "  " << s << "\n";
    std::cout << "== LFTR ==\n";
    for (const auto &s : r.rep.lftr) std::cout << "  " << s << "\n";
    std::cout << "== DCE ==\n  清走死指令 " << r.rep.deadRemoved << " 条\n";

    std::cout << "== SSA（削减后）==\n";
    for (size_t b = 0; b < r.prog.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : r.prog.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    std::cout << "== 乘法账 ==\n";
    std::cout << "  循环一乘法：削减前 " << r.rep.mulLoopBefore
              << " → 削减后 " << r.rep.mulLoopAfter << "\n";
    std::cout << "  循环二乘法（k×j，j 非字面量）：保持 " << r.rep.mulUntouched << "\n";

    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::ssaRun(ssa);
    std::vector<int> after = tip::ssaRun(r.prog);
    std::cout << "  削减前 outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  削减后 outputs:";
    for (int v : after) std::cout << ' ' << v;
    std::cout << "\n  前后一致: " << (before == after ? "yes" : "NO") << "\n";

    bool ok1 = r.rep.mulLoopBefore >= 1 && r.rep.mulLoopAfter == 0;
    bool ok2 = before == after;
    bool ok3 = r.rep.mulUntouched >= 1;
    bool ok4 = !r.rep.reduced.empty() && !r.rep.lftr.empty();
    std::cout << "  循环一乘法 1→0: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  outputs 相等: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  非候选（j 非字面量）原样保留: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  削减与 LFTR 都发生: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok && ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
```

### 46.9.4 基座：前端、TAC 家族、支配与 SSA（本地副本）

与第 41 章同源：AST 构建、符号表、TAC 生成与基本块、支配者、SSA 构造
（含 SSA 解释器 ssaRun）。

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

// ---------- SSA 解释器（对账证人） ----------
std::vector<int> ssaRun(const SsaProgram &p);

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

std::vector<int> ssaRun(const SsaProgram &p) {
    std::vector<int> outputs;
    std::map<std::string, int> env;
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
            case TOp::Input: throw std::runtime_error("示例程序不含 input");
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


### 46.9.5 程序与期望输出

```text
// file: programs/osr.tip
main() {
  var i, s, u, j, n, k;
  n = 100;
  j = 7;
  s = 0;
  u = 0;
  i = 1;
  k = 1;
  while (n > i) {
    s = s + i * 4;
    i = i + 1;
  }
  while (n > k) {
    u = u + k * s;
    k = k + 1;
  }
  output s;
  output u;
  return 0;
}
```

```text
// file: expected/output.txt
== osr.tip ==
== SSA（削减前）==
  B0:
    t10 = 100
    n0 = t10
    t20 = 7
    j0 = t20
    t30 = 0
    s0 = t30
    t40 = 0
    u0 = t40
    t50 = 1
    i0 = t50
    t60 = 1
    k0 = t60
  B1:
    i1 = phi(i0, i2)
    s1 = phi(s0, s2)
    t100 = phi(t10u, t101)
    t110 = phi(t11u, t111)
    t70 = phi(t7u, t71)
    t80 = phi(t8u, t81)
    t90 = phi(t9u, t91)
    if n0 > i1 goto B3
  B2:
    goto B4
  B3:
    t71 = 4
    t81 = i1 * t71
    t91 = s1 + t81
    s2 = t91
    t101 = 1
    t111 = i1 + t101
    i2 = t111
    goto B1
  B4:
    k1 = phi(k0, k2)
    t120 = phi(t12u, t121)
    t130 = phi(t13u, t131)
    t140 = phi(t14u, t141)
    t150 = phi(t15u, t151)
    u1 = phi(u0, u2)
    if n0 > k1 goto B6
  B5:
    goto B7
  B6:
    t121 = k1 * s1
    t131 = u1 + t121
    u2 = t131
    t141 = 1
    t151 = k1 + t141
    k2 = t151
    goto B4
  B7:
    output s1
    output u1
    t160 = 0
    return t160
== 归纳变量（SSA 图 SCC）==
  链头 φ: i1
  链头 φ: k1
== 削减 ==
  t81 × 4 → t81#sr（初值乘一次，步长 4）
== LFTR ==
  i1 与 100 的测试 → t81#sr 与 400（界 ×4）
== DCE ==
  清走死指令 12 条
== SSA（削减后）==
  B0:
    t81#sr0 = 4
  B1:
    s1 = phi(0, s2)
    t81#sr = phi(t81#sr0, t81#sr1)
    if 400 > t81#sr goto B3
  B2:
    goto B4
  B3:
    t91 = s1 + t81#sr
    s2 = t91
    t81#sr1 = t81#sr + 4
    goto B1
  B4:
    k1 = phi(1, k2)
    u1 = phi(0, u2)
    if 100 > k1 goto B6
  B5:
    goto B7
  B6:
    t121 = k1 * s1
    t131 = u1 + t121
    u2 = t131
    t151 = k1 + 1
    k2 = t151
    goto B4
  B7:
    output s1
    output u1
    return 0
== 乘法账 ==
  循环一乘法：削减前 1 → 削减后 0
  循环二乘法（k×j，j 非字面量）：保持 1
== 对账 ==
  削减前 outputs: 19800 98010000
  削减后 outputs: 19800 98010000
  前后一致: yes
  循环一乘法 1→0: yes
  outputs 相等: yes
  非候选（j 非字面量）原样保留: yes
  削减与 LFTR 都发生: yes
```

## 46.10 小结与练习

本章把
循环里
最贵的
一类
重复
劳动
换成了
加法：

- 归纳
  变量
  = SSA
  图上
  由
  四类
  合法
  更新
  构成
  的
  SCC，
  Tarjan
  DFS
  一遍
  同时
  识别
  与
  分类；
- 削减
  = 克隆
  新链：
  初值
  乘
  一次、
  header
  插
  新 φ、
  latch
  加
  步长×c；
- LFTR
  把
  测试
  搬到
  新链
  （界×c），
  让
  旧链
  死透；
- 死环
  要靠
  根可达
  DCE——
  编译器
  里的
  标记
  清扫
  GC。

下一章
（42）
用
guard
的
插入
与
消除
处理
数组
越界——
那里
会
再次
遇到
"循环
变量的
线性
推理"。

练习：

1. 实现
   加法型
   候选
   `t =
   i +
   c`
   的
   削减
   （新链
   步长
   仍是
   step，
   初值
   加 c），
   在
   `s
   = s
   +
   (i
   +
   3)`
   的
   循环上
   验证。
2. 把
   region
   constant
   从
   "字面量"
   放宽
   到
   "定义
   支配
   归纳
   变量
   header
   的
   名字"
   （需要
   支配树），
   构造
   循环外
   计算
   `w
   =
   x*4`
   循环内
   `t
   = i*w`
   的
   程序，
   验证
   削减
   触发。
3. 实现
   鲸书
   的
   **防重复
   哈希**：
   同一
   (iv,
   c)
   的
   两个
   候选
   共享
   一条
   新链——
   在
   循环里
   放
   `a
   = i*4`
   与
   `b
   = i*4`
   两个
   候选，
   验证
   只克隆
   一次。
4. 削减
   可能
   增大
   寄存器
   压力：
   构造
   一个
   6 候选
   循环，
   在
   第 61 章
   分配器
   上
   对比
   削减
   前后的
   溢出
   数，
   讨论
   削减
   的
   盈亏
   平衡点。
5. 把
   DCE
   的
   根
   从
   "控制
   指令"
   扩展到
   "被
   内联
   展开
   保留
   的
   副作用"——
   若
   TIP
   加入
   output
   表达式
   求值
   顺序
   语义，
   根集
   要
   怎么改？
