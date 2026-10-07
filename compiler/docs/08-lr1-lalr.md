# 第 8 章　LR(1) 与 LALR：把归约的许可证发准

## 8.1 回望 SLR：许可证发宽了

第 7 章
把移进-归约
分析器造了
出来：
LR(0) 项
把"期望"
编码进
状态，
SLR 用
FOLLOW 集
给归约
发许可证。
但那张
许可证
常常
**发宽了**——
FOLLOW(A)
是"全局
可能跟在
A 后面的
终结符"，
而分析器
在某个
具体状态里
需要的
是"**这条
路径上**
可能跟在
后面的
终结符"。

第 7 章
末尾的
绿龙反例
文法：

```
S → L = R
S → R
L → * R
L → id
R → L
```

SLR 在
状态
{S→L·=R, R→L·}
上冲突：
看到 `=`
时，
S→L·=R
要求**移进**，
而 FOLLOW(R)
里有 `=`
（因为
S→L=R
里 R
后面跟 `=`？
不——R
在句尾；
是 L=R
中 L
后面跟 `=`，
而 R→L
使 FOLLOW(L)
⊆ FOLLOW(R)，
又 L
后可跟 `=`，
故 FOLLOW(R)
∋ `=`），
于是
R→L·
也领到了
在 `=`
上归约的
许可证。
**全局
看 `=`
确实可能
跟在 R
后面；
但在这条
路径上
（S 刚刚
要展开成
L=R 的
左臂），
R 后面
永远不跟
`=`**。

规范
LR(1)
的动机
就这一句：
把归约
许可证的
发放条件
从"全局
可能"
收紧到
"**此情此景
可能**"。
做法是
把许可
发放的
粒度
从非终结符
（A 的
全部归约
共享
FOLLOW(A)）
细化到
**项**
（每个
归约项
带自己的
lookahead
集合）。
材料取自
鲸书
§3.4.2 与
§3.6.2、
§3.7 的
谱系讨论，
自包含
展开。

## 8.2 LR(1) 项：把上下文写进项里

LR(1) 项
在 LR(0) 项
上加一个
**lookahead**
终结符：

> [A → α · β, a]
> 含义：
> 期望在
> 接下来的
> 输入里
> 看到β，
> **并且
> β 之后
> 跟着
> a**；
> 若 β
> 已空
> （圆点
> 到头），
> 则"在
> a 上
> 归约
> A→α"。

关键
直觉：
lookahead
只对
**圆点
到头的项**
（归约项）
起裁决
作用；
对还有
期望的项
（移进项），
它只是
**随附
信息**，
等待
后续
传播。

为什么
这就把
许可证
发准了？
回到
冲突状态。
在 LR(1)
里，
同一个
LR(0) 核心
{S→L·=R, R→L·}
会带着
精确的
lookahead
出现：

- [S→L·=R, **$**]
  ——从
  开始符号
  一路
  展开到
  这里，
  后面
  是文件
  结尾；
- [R→L·, **$**]
  ——这个
  L 是
  R 的
  身，
  R 又是
  S 的
  身，
  后面
  还是
  文件
  结尾。

于是
在 `=`
上只有
移进
一个动作：
R→L·
的归约
许可证
是 **$**，
不是
FOLLOW(R)
全集。
冲突
消失。
lookahead
哪来的？
它由
闭包
规则
**传播**：
对项
[A→α·Bβ, a]，
为每个
产生式
B→γ 与
每个
b ∈ FIRST(βa)
加入
[B→·γ, b]。

注意
这个
FIRST
的参数
是 **βa
连写**：
β 非空时
lookahead
由 β
决定
（a 被
挡在
后面）；
β 可空时
才轮到
a 透传。
这就是
代码里
`firstOfSeq(g, beta, it.la)`
一次
调用
同时
处理
两种
情形
的原因。

## 8.3 CLOSURE 与 GOTO：lookahead 的传播

LR(0) 的
CLOSURE
只看
圆点
右边的
**非终结符**；
LR(1) 的
CLOSURE
多干
一件事：
算出
给新项
配发的
lookahead。
对照
`closure`
实现：

```cpp
std::set<Item> closure(const Grammar &g, std::set<Item> is) {
    for (bool ch = true; ch;) {
        ch = false;
        std::set<Item> add;
        for (const auto &it : is) {
            const auto &[lhs, rhs] = g.prods[it.prod];
            if (it.dot >= static_cast<int>(rhs.size())) continue;
            const std::string &b = rhs[it.dot];
            if (isTerm(g, b)) continue;
            std::vector<std::string> beta(rhs.begin() + it.dot + 1, rhs.end());
            std::set<std::string> las;
            if (it.la.empty()) las.insert("");   // LR(0)：无 lookahead
            else las = firstOfSeq(g, beta, it.la);
            ...
```

`la`
为空串
是 **LR(0)
口径**
的开关：
同一份
代码
既造
第 7 章
的 LR(0)
族（SLR
用），
也造
本章的
LR(1)
族。
教学上
省一份
实现，
也逼我们
把"差别
只在
lookahead"
这件事
写成
代码
事实。

GOTO
不变：
圆点
移过
符号 X、
再闭包。
lookahead
跟着
项走，
不多
不少。

规范
LR(1)
项集族
的构造
与 LR(0)
完全
同型：
从
closure([S'→·S, $])
出发，
对每个
状态
试每个
符号，
新项集
入队，
直到
不动点。
差别
只在
项的
身份
从
(产生式，
圆点)
变成
(产生式，
圆点，
lookahead)
——
**项变多，
状态
随之
变多**。

## 8.4 规范 LR(1) 造表：分裂的状态

ACTION/GOTO
填表
规则
（对照
`fill`）：

- 移进项
  [A→α·**a**β, b]
  （a 是
  终结符）：
  ACTION[s, a] = shift GOTO(I, a)；
- 归约项
  [A→α**·**, a]
  （A ≠ S'）：
  ACTION[s, **a**] = reduce A→α；
- [S'→S·, $]：
  ACTION[s, $] = accept。

对照
SLR：
归约
动作的
终结符
维度
从
FOLLOW(A)
换成
**项自身的
lookahead**。
就这一处
不同，
文法
接受面
立刻
扩大。

**状态
分裂**
是 LR(1)
族的
标志性
现象。
我们的
例子
文法：
LR(0)/SLR
族 10 个
状态，
规范
LR(1)
族 14 个
状态——
多出的
4 个
来自
4 个
核心
各分裂
成两。
期望输出
里打印了
两例：

例一，
核心
{L→·*R,
L→*·R,
L→·id,
R→·L}
分裂成：

- 状态 1：
  全部项
  带 {
  $, =
  } 两种
  lookahead
  （从
  开始
  状态
  直接
  移进
  `*`
  到达——
  开始
  状态里
  这个
  核心
  的项
  两种
  la
  都有）；
- 状态 7：
  同样的
  核心、
  只带
  { $ }
  （从
  "="
  右边的
  R 期望
  处到达——
  那里
  只有
  $ 一种
  上下文）。

例二更
干脆：
核心
{L→*R·}
这个
纯归约
核心
分裂成
[11]
（只带 $）
与
[13]
（带
{ $, = }）——
**同一个
归约
动作，
在不同
上下文里
领不同的
许可证**，
这正是
8.1 节
想要的
粒度。

`t.splits`
把
"核心 →
所有
同核
LR(1)
状态"
记成表，
就是
给
LALR
准备的
原料。

## 8.5 LALR：同心合并与它的代价

规范
LR(1)
的代价
是状态
数膨胀。
鲸书
§3.6.2
给了
实感：
经典
表达式
文法的
规范
表有
三十多行，
而其中
大量
状态
**只有
lookahead
不同、
期望
结构
完全
相同**。
LALR(1)
（lookahead
LR(1)）
的思路：

> 把
> 核心
> 相同的
> LR(1)
> 状态
> 合并成
> 一个，
> lookahead
> 求并。

**核心
（core，
"心"）**
= 项集
去掉
lookahead
后的
(产生式，
圆点)
集合。
合并
不改变
移进
结构：
移进
只看
圆点
右边的
终结符，
与
lookahead
无关；
GOTO
表按
核心
照旧
接续。
归约
许可证
是各
来源
状态
lookahead
的并集，
介于
"最窄的
单状态"
与
"最宽的
FOLLOW"
之间。

对我们的
文法：
14 个
LR(1)
状态
合并回
**10 个**
——
恰是
LR(0)/SLR
族的
状态数。
这不是
巧合：
**LALR
的状态
与
LR(0)
族一一
对应**
（每个
LR(0)
状态
就是
一族
同核
LR(1)
状态的
心），
断言三
把
这个
对应
做成了
机器
检查。

**合并的
语义
风险**
（鲸书
§3.7）：
同心
合并
**永不
制造
移进-归约
冲突**
（移进
不看
lookahead，
合并
前后
移进
格局
不变），
但**可能
制造
归约-归约
冲突**
（两个
归约项
的
lookahead
并集
相交了）。
另有一个
温和的
副作用：
对**错误
输入**，
LALR
可能比
LR(1)
多做
几次
注定
无效的
归约
才报错
（错误
发现点
被
lookahead
并集
放宽了），
但**对
合法
输入
两者
行为
完全
一致**
——断言四
用
五个
测试串
验证
了这
一点。

实现里
有个
值得
单说的
坑：
合并态
的
GOTO
**不能**
按"项集
成员
查表"
解析。
从
合并态
M6 出发
经 `*`
的转移，
落到的
项集
只是
目标
核心的
**半边**
（$ lookahead
那半），
它不是
任何
合并态
本身。
正确
做法
是把
转移
目标
按**核心**
索引回
合并态
——
"同心的
GOTO
同心"。
`fill`
的
`coreLookup`
参数
就是
这条
规则的
代码化：
SLR/LR(1)
传
nullptr
（按
项集
身份查），
LALR
传
"核心→
合并态"
表。

## 8.6 三张表的谱系与工程选择

把
三张表
并排
（鲸书
§3.7）：

| | 状态数 | 归约许可证 | 文法接受面 |
|---|---|---|---|
| SLR(1) | 最少（=LR(0) 族） | FOLLOW(A)，全局 | 最窄 |
| LALR(1) | 同 SLR | 同核 lookahead 的并 | 居中 |
| 规范 LR(1) | 最多 | 项自身 lookahead | 最广 |

三者的
**语言**
接受面
却有一件
反直觉
的定理：
任何
有 LR(1)
文法的
语言
也必有
LALR(1)
文法与
SLR(1)
文法——
限制
造表
算法
不限制
语言，
只是
可能要
**改写
文法**
（鲸书
§3.7）。
工程
上这
解释了
Yacc/Bison
几十年的
LALR
霸权：
状态少、
表小、
够用，
偶尔
文法
要迁就
一下
（比如
拆产生式、
提公因子）。

**表压缩**
（鲸书
§3.6.2）
是 LALR
之外的
另一路：
找
ACTION
表中
**完全
相同的
行或列**
合并，
配一张
"分析器
状态→
行号"
的映射；
更激进
的还有
收缩文法
（合并
单用途
非终结符）。
本章
不实现
压缩，
但 `fill`
把
ACTION
存成
`map<int, map<string, Action>>`
的
稀疏
形状
已经
给出
了
直觉：
大量
(state, term)
格是
空的，
行/列出
现
大量
重复。

现代
工具的
选择
也值得
一提：
Bison
仍是
LALR(1)；
**ANTLR 4
不用
LR 族**，
改用
ALL(*)
（对
每条
规则
自适应
地做
LL
分析，
等价于
为每条
规则
现造
DFA），
回避了
造表
期的
冲突
协商。
第 4 章
我们
用
ANTLR
写
文法
从没
遇到过
"冲突"，
现在
你知道
那不是
运气，
是
ALL(*)
把
冲突
处理
推迟到
了
每个
输入
的
现场。

## 8.7 期望输出解读与对账

五段
输出、
四条
断言：

1. **文法**：
  增广后
  六条
  产生式
  （0 号
  S'→S
  是
  增广）；
2. **SLR**：
  10 状态、
  **1 处
  冲突**——
  状态 2
  上 `=`：
  S→L·=R
  要移进、
  R→L·
  凭
  FOLLOW(R)
  ∋ `=`
  要归约，
  与
  8.1 的
  手推
  一致；
3. **规范
  LR(1)**：
  14 状态、
  **0 冲突**；
  分裂
  核心数
  4，
  打印了
  两个
  分裂例
  （纯归约
  核心
  {L→*R·}
  的分裂
  最有
  教育意义）；
4. **LALR**：
  14→10
  状态
  （回到
  LR(0)
  族规模）、
  0 冲突；
5. **分析
  对账**：
  三个
  合法串
  两表
  同接受、
  步数
  相同；
  两个
  非法串
  同拒绝
  且
  错误
  发现
  步数
  相同
  （本
  文法
  连
  "延迟
  归约"
  副作用
  都没
  出现）。

四断言：
SLR
有冲突
而 LR(1)
无（断言一）、
LALR
状态数
下降
（断言二）、
LALR
状态数
恰等
SLR
（断言三，
同心的
定义级
事实）、
两表
接受性
一致
（断言四）。

## 8.8 工程注意点

- **冲突
  上报的
  惯例**：
  Yacc
  系工具
  遇到
  移进-归约
  冲突
  默认
  **选移进**
  并警告；
  归约-归约
  冲突
  默认选
  **先写
  的产生式**。
  我们
  的
  `setAct`
  改为
  **记下
  冲突、
  保留
  先到者**
  ——
  教学上
  要的
  是"看见
  冲突"，
  不是
  "静默
  消化
  冲突"。
- **增广
  产生式**
  的意义：
  S'→S
  让"接受"
  成为
  一个
  独立
  动作
  （只在
  [S'→S·, $]
  发生），
  避免与
  S 的
  其他
  归约
  混淆。
  没有它，
  "$ 上
  归约
  S→…"
  与
  "接受"
  无法
  区分。
- **ε
  产生式**：
  本章
  文法
  没有 ε，
  但
  `firstOne`/`firstOfSeq`
  已按
  可空
  传播
  写全
  （FIRST(βa)
  的 a
  只有
  β 全可空
  才透传）。
  有 ε 的
  文法
  LR(1)
  项会
  显著
  变多，
  分裂
  也更
  剧烈。
- ** FIRST/
  FOLLOW
  的
  复用**：
  FOLLOW
  只服务
  SLR
  对照；
  LR(1)
  造表
  **不需要
  FOLLOW**，
  只要
  FIRST。
  这也是
  鲸书
  先讲
  FIRST
  后讲
  FOLLOW
  的
  原因。
- **编译
  期成本**：
  规范
  LR(1)
  状态数
  最坏
  可到
  LR(0)
  的
  指数倍
  （每个
  核心
  的
  lookahead
  子集
  都可能
  单独
  成态）；
  LALR
  的
  合并
  把它
  拉回
  线性
  规模——
  这是
  Yacc
  时代
  内存
  紧张
  下
  的
  现实
  选择。

## 8.9 本章配套文件

本示例
无 ANTLR——
造表与
分析
自包含，
走"简单
程序"
对账
协议。

### 8.9.1 lr1.hpp 与 lr1.cpp

文法
结构、
FIRST/FOLLOW、
LR(1) 项
与
核心、
SLR/LR(1)/LALR
三张表
的
构造、
表驱动
分析器。

```cpp
// file: src/lr1.hpp
// file: src/lr1.hpp
// 第 8 章配套：规范 LR(1) 造表与 LALR 同心合并（鲸书 §3.4.2 + §3.6.2）。
#ifndef TIP_LR1_HPP
#define TIP_LR1_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 文法 ----------
// 产生式 0 恒为增广开始产生式 S'→S；rhs 空串表示 ε。
struct Grammar {
    std::vector<std::pair<std::string, std::vector<std::string>>> prods;
    std::set<std::string> terms;     // 终结符（含 "$"）
    std::set<std::string> nonterms;  // 非终结符
    std::string start = "S'";
};

// FIRST(符号串)。终结符出现即止；非终结符含 ε 则继续看下一个。
std::set<std::string> firstOfSeq(const Grammar &g, const std::vector<std::string> &seq,
                                 const std::string &tail = "");

// FOLLOW 集（SLR 的归约许可证，鲸书 §3.4.2 之 SLR 视角）
std::map<std::string, std::set<std::string>> followSets(const Grammar &g);

// ---------- LR 项 ----------
struct Item {
    int prod = 0;         // 产生式编号
    int dot = 0;          // 圆点位置 0..|rhs|
    std::string la;       // lookahead；空串 = LR(0)/SLR 口径
    friend bool operator<(const Item &a, const Item &b) {
        if (a.prod != b.prod) return a.prod < b.prod;
        if (a.dot != b.dot) return a.dot < b.dot;
        return a.la < b.la;
    }
    friend bool operator==(const Item &a, const Item &b) {
        return a.prod == b.prod && a.dot == b.dot && a.la == b.la;
    }
};

// 项的核心（去掉 lookahead）——同心合并的"心"
using Core = std::set<std::pair<int, int>>;

// ---------- 表 ----------
struct Action {
    enum Kind { Err, Shift, Reduce, Acc } kind = Err;
    int target = -1;   // Shift: 目标状态；Reduce: 产生式号
    friend bool operator==(const Action &x, const Action &y) {
        return x.kind == y.kind && x.target == y.target;
    }
};

struct Table {
    std::string kind;                                   // "SLR(1)" / "LR(1)" / "LALR(1)"
    std::vector<std::set<Item>> states;                 // 规范族（SLR/LALR 为合并后状态）
    std::map<int, std::map<std::string, Action>> action; // 状态 -> 终结符 -> 动作
    std::map<int, std::map<std::string, int>> gotos;     // 状态 -> 非终结符 -> 状态
    std::vector<std::pair<int, std::string>> conflicts;  // (状态, 终结符)
    // LR(1) 独有：每个 LR(0) 核心分裂出的 LR(1) 状态（讲"精确 lookahead 分裂状态"用）
    std::map<Core, std::vector<int>> splits;
};

// SLR 造表：LR(0) 项集族 + FOLLOW 发归约许可证（第 7 章口径，此处作对照）
Table buildSLR(const Grammar &g);

// 规范 LR(1) 造表：项带 lookahead [A→α·β, a]，CLOSURE 用 FIRST(βa) 传播
Table buildLR1(const Grammar &g);

// LALR(1)：规范族按核心合并、lookahead 求并（同心合并）
Table buildLALR(const Grammar &g, const Table &lr1);

// ---------- 表驱动分析器 ----------
struct ParseResult {
    bool accept = false;
    int steps = 0;
};

ParseResult tableParse(const Grammar &g, const Table &t, const std::vector<std::string> &words);

}  // namespace tip

#endif  // TIP_LR1_HPP
```

```cpp
// file: src/lr1.cpp
// file: src/lr1.cpp
// 第 8 章配套：FIRST/FOLLOW、CLOSURE/GOTO（带 lookahead）、规范 LR(1) 造表、
// SLR 对照表、LALR 同心合并、表驱动分析器（鲸书 §3.4.2 + §3.6.2 + §3.7）。
#include "lr1.hpp"

namespace tip {

namespace {

bool isTerm(const Grammar &g, const std::string &s) { return g.terms.count(s) > 0; }

// 单符号的 FIRST（含 ε 传播标记：返回集合里带 "" 表示可空）
std::set<std::string> firstOne(const Grammar &g, const std::string &sym,
                               std::map<std::string, std::set<std::string>> &memo) {
    if (auto it = memo.find(sym); it != memo.end()) return it->second;
    std::set<std::string> out;
    if (isTerm(g, sym) || sym.empty()) {
        out.insert(sym);   // 空串符号 "" 表示 ε
        return out;
    }
    bool nullable = false;
    for (const auto &[lhs, rhs] : g.prods) {
        if (lhs != sym) continue;
        if (rhs.empty()) { nullable = true; continue; }
        bool allNullable = true;
        for (const auto &x : rhs) {
            std::set<std::string> f = firstOne(g, x, memo);
            for (const auto &t : f)
                if (!t.empty()) out.insert(t);
            if (!f.count("")) { allNullable = false; break; }
        }
        if (allNullable) nullable = true;
    }
    if (nullable) out.insert("");
    memo[sym] = out;
    return out;
}

}  // namespace

std::set<std::string> firstOfSeq(const Grammar &g, const std::vector<std::string> &seq,
                                 const std::string &tail) {
    static std::map<std::string, std::set<std::string>> memo;
    memo.clear();
    std::set<std::string> out;
    bool allNullable = true;
    auto feed = [&](const std::vector<std::string> &part) {
        for (const auto &x : part) {
            std::set<std::string> f = firstOne(g, x, memo);
            for (const auto &t : f)
                if (!t.empty()) out.insert(t);
            if (!f.count("")) { allNullable = false; return; }
        }
    };
    feed(seq);
    if (allNullable && !tail.empty()) feed({tail});
    if (out.empty()) out.insert("");   // 全可空 ⇒ ε
    return out;
}

std::map<std::string, std::set<std::string>> followSets(const Grammar &g) {
    std::map<std::string, std::set<std::string>> fol;
    fol[g.start].insert("$");
    for (bool ch = true; ch;) {
        ch = false;
        for (const auto &[lhs, rhs] : g.prods) {
            for (size_t i = 0; i < rhs.size(); ++i) {
                if (isTerm(g, rhs[i])) continue;
                std::vector<std::string> rest(rhs.begin() + i + 1, rhs.end());
                std::set<std::string> f = firstOfSeq(g, rest);
                bool nullable = f.count("") > 0;
                for (const auto &t : f)
                    if (!t.empty() && !fol[rhs[i]].count(t)) { fol[rhs[i]].insert(t); ch = true; }
                if (nullable)
                    for (const auto &t : fol[lhs])
                        if (!fol[rhs[i]].count(t)) { fol[rhs[i]].insert(t); ch = true; }
            }
        }
    }
    return fol;
}

// ---------- CLOSURE / GOTO ----------

namespace {

// CLOSURE：LR(1) 口径传播 lookahead——[A→α·Bβ, a] 为每个 B→γ 与 b∈FIRST(βa) 加项；
// la 为空串（LR(0)/SLR 口径）时不传播 lookahead。
std::set<Item> closure(const Grammar &g, std::set<Item> is) {
    for (bool ch = true; ch;) {
        ch = false;
        std::set<Item> add;
        for (const auto &it : is) {
            const auto &[lhs, rhs] = g.prods[it.prod];
            if (it.dot >= static_cast<int>(rhs.size())) continue;
            const std::string &b = rhs[it.dot];
            if (isTerm(g, b)) continue;
            std::vector<std::string> beta(rhs.begin() + it.dot + 1, rhs.end());
            std::set<std::string> las;
            if (it.la.empty()) las.insert("");   // LR(0)：无 lookahead
            else las = firstOfSeq(g, beta, it.la);
            for (size_t p = 0; p < g.prods.size(); ++p) {
                if (g.prods[p].first != b) continue;
                for (const auto &a : las) {
                    Item ni{static_cast<int>(p), 0, it.la.empty() ? "" : a};
                    if (!is.count(ni)) { add.insert(ni); ch = true; }
                }
            }
        }
        is.insert(add.begin(), add.end());
    }
    return is;
}

Core coreOf(const std::set<Item> &is) {
    Core c;
    for (const auto &it : is) c.insert({it.prod, it.dot});
    return c;
}

// GOTO(I, X)：圆点移过 X 再闭包
std::set<Item> goTo(const Grammar &g, const std::set<Item> &is, const std::string &x) {
    std::set<Item> moved;
    for (const auto &it : is) {
        const auto &rhs = g.prods[it.prod].second;
        if (it.dot < static_cast<int>(rhs.size()) && rhs[it.dot] == x)
            moved.insert(Item{it.prod, it.dot + 1, it.la});
    }
    return moved.empty() ? moved : closure(g, std::move(moved));
}

// 规范族：BFS；lr1=false 时为 LR(0) 族（SLR 用）
std::vector<std::set<Item>> collection(const Grammar &g, bool lr1) {
    std::vector<std::set<Item>> states;
    std::map<std::set<Item>, int> index;
    std::vector<std::set<Item>> work;
    auto push = [&](std::set<Item> s) -> int {
        auto it = index.find(s);
        if (it != index.end()) return it->second;
        index[s] = static_cast<int>(states.size());
        states.push_back(s);
        work.push_back(s);
        return static_cast<int>(states.size()) - 1;
    };
    push(closure(g, {{0, 0, lr1 ? "$" : ""}}));
    std::set<std::string> symbols = g.terms;
    symbols.insert(g.nonterms.begin(), g.nonterms.end());
    while (!work.empty()) {
        std::set<Item> cur = work.back();
        work.pop_back();
        for (const auto &x : symbols) {
            std::set<Item> nx = goTo(g, cur, x);
            if (!nx.empty()) push(std::move(nx));
        }
    }
    return states;
}

// 填表的公共骨架：遍历项集，移进项发 shift、归约项按 permit 发 reduce 许可证
// （SLR 的 permit=FOLLOW(A)，LR(1) 的 permit=项自身 lookahead）。
// coreLookup 非空时（LALR）：转移目标按"项集的核心"解析——合并态出发的 GOTO
// 只落在核心的某半边项集上，必须按核心回到合并态（同心态的 GOTO 同心）。
void fill(Table &t, const Grammar &g, const std::vector<std::set<Item>> &states,
          const std::map<std::string, std::set<std::string>> *permit,
          const std::map<Core, int> *coreLookup = nullptr) {
    t.states = states;
    std::map<std::set<Item>, int> index;
    for (size_t i = 0; i < states.size(); ++i) index[states[i]] = static_cast<int>(i);
    auto setAct = [&](int s, const std::string &a, Action act) {
        Action &cell = t.action[s][a];
        if (cell == Action{} || cell == act) { cell = act; return; }
        t.conflicts.push_back({s, a});   // 同格两异动作：记冲突，保留先到者
    };
    auto targetOf = [&](const std::set<Item> &nx) -> int {
        if (nx.empty()) return -1;   // 无此转移（如对 S' 的 GOTO）
        if (coreLookup) {
            auto cit = coreLookup->find(coreOf(nx));
            return cit == coreLookup->end() ? -1 : cit->second;
        }
        return index.at(nx);
    };
    for (size_t si = 0; si < states.size(); ++si) {
        for (const auto &it : states[si]) {
            const auto &[lhs, rhs] = g.prods[it.prod];
            if (it.dot < static_cast<int>(rhs.size())) {
                const std::string &x = rhs[it.dot];
                if (!isTerm(g, x)) continue;
                int tgt = targetOf(goTo(g, states[si], x));
                if (tgt >= 0)
                    setAct(static_cast<int>(si), x, Action{Action::Shift, tgt});
            } else if (it.prod == 0) {
                setAct(static_cast<int>(si), "$", Action{Action::Acc, -1});
            } else if (it.prod != 0) {
                // 归约许可证来源：SLR 用 FOLLOW(A)，LR(1) 用 lookahead
                if (permit) {
                    const auto &f = permit->at(lhs);
                    for (const auto &a : f) setAct(static_cast<int>(si), a, Action{Action::Reduce, it.prod});
                } else {
                    setAct(static_cast<int>(si), it.la, Action{Action::Reduce, it.prod});
                }
            }
        }
        for (const auto &b : g.nonterms) {
            int tgt = targetOf(goTo(g, states[si], b));
            if (tgt >= 0)
                t.gotos[static_cast<int>(si)][b] = tgt;
        }
    }
}

}  // namespace

Table buildSLR(const Grammar &g) {
    Table t;
    t.kind = "SLR(1)";
    // SLR：LR(0) 项集族 + FOLLOW(A) 给归约发许可证（第 7 章口径，此处作对照）
    auto fol = followSets(g);
    fill(t, g, collection(g, false), &fol);
    return t;
}

Table buildLR1(const Grammar &g) {
    Table t;
    t.kind = "LR(1)";
    fill(t, g, collection(g, true), nullptr);
    // 记录核心分裂：同一核心对应多少个 LR(1) 状态
    for (size_t i = 0; i < t.states.size(); ++i) t.splits[coreOf(t.states[i])].push_back(static_cast<int>(i));
    return t;
}

Table buildLALR(const Grammar &g, const Table &lr1) {
    Table t;
    t.kind = "LALR(1)";
    // 1) 按核心分组合并，lookahead 求并
    std::map<Core, int> coreId;
    std::vector<std::set<Item>> merged;
    for (const auto &st : lr1.states) {
        Core c = coreOf(st);
        auto it = coreId.find(c);
        if (it == coreId.end()) {
            coreId[c] = static_cast<int>(merged.size());
            merged.push_back(st);
        } else {
            merged[it->second].insert(st.begin(), st.end());
        }
    }
    // 2) 用"核心 → 合并态"索引重建 GOTO/ACTION：转移按核心解析（见 fill 注释）
    fill(t, g, merged, nullptr, &coreId);
    return t;
}

ParseResult tableParse(const Grammar &g, const Table &t, const std::vector<std::string> &words) {
    ParseResult r;
    std::vector<int> stack{0};
    std::vector<std::string> input = words;
    input.push_back("$");
    size_t ip = 0;
    for (;;++r.steps) {
        if (r.steps > 1000) return r;   // 保险丝
        int s = stack.back();
        auto it = t.action.find(s);
        if (it == t.action.end() || !it->second.count(input[ip])) return r;   // 错误
        const Action &a = it->second.at(input[ip]);
        if (a.kind == Action::Shift) {
            stack.push_back(a.target);
            ++ip;
        } else if (a.kind == Action::Reduce) {
            const auto &rhs = g.prods[a.target].second;
            for (size_t k = 0; k < rhs.size(); ++k) stack.pop_back();
            int top = stack.back();
            auto git = t.gotos.find(top);
            if (git == t.gotos.end() || !git->second.count(g.prods[a.target].first)) return r;
            stack.push_back(git->second.at(g.prods[a.target].first));
        } else if (a.kind == Action::Acc) {
            r.accept = true;
            return r;
        } else {
            return r;
        }
    }
}

}  // namespace tip
```

### 8.9.2 驱动 main.cpp

一个
文法、
三张表、
五个
测试串、
四断言。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 8 章驱动（无参运行，走"简单程序"对账协议）：
//   绿龙 L=R 文法 → SLR 造表（冲突对照）→ 规范 LR(1) 造表（无冲突）→
//   LALR 同心合并（状态数下降）→ 两表分析对账（接受/拒绝一致）。
#include "lr1.hpp"

#include <iostream>

namespace {

// 绿龙的 L=R 文法：S→L=R | R; L→*R | id; R→L
// 第 7 章用它演示"SLR 的 FOLLOW 许可证太宽"——本章看 LR(1) 如何精确化。
tip::Grammar lrdGrammar() {
    tip::Grammar g;
    g.prods = {
        {"S'", {"S"}},          // 0: 增广开始
        {"S", {"L", "=", "R"}}, // 1
        {"S", {"R"}},           // 2
        {"L", {"*", "R"}},      // 3
        {"L", {"id"}},          // 4
        {"R", {"L"}},           // 5
    };
    g.terms = {"=", "*", "id", "$"};
    for (const auto &p : g.prods) g.nonterms.insert(p.first);
    return g;
}

std::string showItem(const tip::Grammar &g, const tip::Item &it) {
    const auto &[lhs, rhs] = g.prods[it.prod];
    std::string s = lhs + " → ";
    for (size_t i = 0; i <= rhs.size(); ++i) {
        if (static_cast<int>(i) == it.dot) s += "·";
        if (i < rhs.size()) s += rhs[i] + " ";
    }
    if (!it.la.empty()) s += ", " + it.la;
    return s;
}

std::vector<std::string> split(const std::string &s) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : s) {
        if (c == ' ') { if (!cur.empty()) out.push_back(cur); cur.clear(); }
        else cur += c;
    }
    if (!cur.empty()) out.push_back(cur);
    return out;
}

}  // namespace

int main() {
    tip::Grammar g = lrdGrammar();

    std::cout << "== 文法（增广后）==\n";
    for (size_t i = 0; i < g.prods.size(); ++i) {
        const auto &[lhs, rhs] = g.prods[i];
        std::cout << "  " << i << ": " << lhs << " →";
        for (const auto &x : rhs) std::cout << " " << x;
        std::cout << "\n";
    }

    // ---------- SLR：FOLLOW 发证 ----------
    tip::Table slr = tip::buildSLR(g);
    std::cout << "== SLR(1)（LR(0) 族 + FOLLOW 许可证）==\n";
    std::cout << "  状态数=" << slr.states.size()
              << " 冲突=" << slr.conflicts.size() << "\n";
    for (const auto &[s, a] : slr.conflicts) {
        std::cout << "  状态 " << s << " 上 '" << a << "' 冲突，状态项:\n";
        for (const auto &it : slr.states[s]) std::cout << "    " << showItem(g, it) << "\n";
    }

    // ---------- 规范 LR(1) ----------
    tip::Table lr1 = tip::buildLR1(g);
    std::cout << "== 规范 LR(1)（项带 lookahead）==\n";
    std::cout << "  状态数=" << lr1.states.size()
              << " 冲突=" << lr1.conflicts.size() << "\n";
    int splitCores = 0, shown = 0;
    for (const auto &[core, ids] : lr1.splits) {
        if (ids.size() < 2) continue;
        ++splitCores;
        if (shown < 2) {
            std::cout << "  核心分裂例（同一 LR(0) 核心被 lookahead 拆成 "
                      << ids.size() << " 个 LR(1) 状态）:\n";
            for (int id : ids)
                for (const auto &it : lr1.states[id])
                    std::cout << "    [" << id << "] " << showItem(g, it) << "\n";
            ++shown;
        }
    }
    std::cout << "  分裂核心数=" << splitCores << "\n";

    // ---------- LALR：同心合并 ----------
    tip::Table lalr = tip::buildLALR(g, lr1);
    std::cout << "== LALR(1)（同心合并，lookahead 求并）==\n";
    std::cout << "  合并前状态数=" << lr1.states.size()
              << " 合并后=" << lalr.states.size()
              << " 冲突=" << lalr.conflicts.size() << "\n";

    // ---------- 分析对账 ----------
    std::cout << "== 分析对账（LR(1) vs LALR）==\n";
    struct Case { const char *s; bool want; };
    const Case cases[] = {
        {"id = id", true}, {"id = * id", true}, {"* id = id", true},
        {"id =", false}, {"id id", false},
    };
    bool agree = true;
    for (const auto &c : cases) {
        auto words = split(c.s);
        tip::ParseResult a = tip::tableParse(g, lr1, words);
        tip::ParseResult b = tip::tableParse(g, lalr, words);
        bool ok = a.accept == c.want && b.accept == c.want && a.accept == b.accept;
        agree = agree && ok;
        std::cout << "  \"" << c.s << "\" 期望=" << (c.want ? "接受" : "拒绝")
                  << "  LR(1)=" << (a.accept ? "接受" : "拒绝") << "(" << a.steps << "步)"
                  << "  LALR=" << (b.accept ? "接受" : "拒绝") << "(" << b.steps << "步)"
                  << (ok ? "" : "  ←不一致!") << "\n";
    }

    // ---------- 断言 ----------
    std::cout << "== 对账 ==\n";
    bool ok1 = !slr.conflicts.empty() && lr1.conflicts.empty();
    bool ok2 = lalr.states.size() < lr1.states.size();
    bool ok3 = lalr.states.size() == slr.states.size();   // 同心 ⇒ 状态数回到 LR(0)/SLR
    bool ok4 = agree;
    std::cout << "  SLR 有冲突而 LR(1) 无冲突: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  LALR 状态数 < LR(1): " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  LALR 状态数 == SLR(同心回到 LR(0) 族): " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  LR(1) 与 LALR 接受性一致: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
```

### 8.9.3 期望输出 expected/output.txt

```text
; expected: expected/output.txt
== 文法（增广后）==
  0: S' → S
  1: S → L = R
  2: S → R
  3: L → * R
  4: L → id
  5: R → L
== SLR(1)（LR(0) 族 + FOLLOW 许可证）==
  状态数=10 冲突=1
  状态 2 上 '=' 冲突，状态项:
    S → L ·= R 
    R → L ·
== 规范 LR(1)（项带 lookahead）==
  状态数=14 冲突=0
  核心分裂例（同一 LR(0) 核心被 lookahead 拆成 2 个 LR(1) 状态）:
    [1] L → ·* R , $
    [1] L → ·* R , =
    [1] L → * ·R , $
    [1] L → * ·R , =
    [1] L → ·id , $
    [1] L → ·id , =
    [1] R → ·L , $
    [1] R → ·L , =
    [7] L → ·* R , $
    [7] L → * ·R , $
    [7] L → ·id , $
    [7] R → ·L , $
  核心分裂例（同一 LR(0) 核心被 lookahead 拆成 2 个 LR(1) 状态）:
    [11] L → * R ·, $
    [13] L → * R ·, $
    [13] L → * R ·, =
  分裂核心数=4
== LALR(1)（同心合并，lookahead 求并）==
  合并前状态数=14 合并后=10 冲突=0
== 分析对账（LR(1) vs LALR）==
  "id = id" 期望=接受  LR(1)=接受(7步)  LALR=接受(7步)
  "id = * id" 期望=接受  LR(1)=接受(10步)  LALR=接受(10步)
  "* id = id" 期望=接受  LR(1)=接受(10步)  LALR=接受(10步)
  "id =" 期望=拒绝  LR(1)=拒绝(3步)  LALR=拒绝(3步)
  "id id" 期望=拒绝  LR(1)=拒绝(1步)  LALR=拒绝(1步)
== 对账 ==
  SLR 有冲突而 LR(1) 无冲突: yes
  LALR 状态数 < LR(1): yes
  LALR 状态数 == SLR(同心回到 LR(0) 族): yes
  LR(1) 与 LALR 接受性一致: yes
```

## 8.10 小结与练习

本章把
移进-归约
分析器的
最后一块
地基
打完：

- LR(1) 项
  把
  "归约后
  允许跟
  什么"
  写进项，
  许可证
  从
  FOLLOW(A)
  的全局
  口径
  收紧到
  此情此景；
- 规范
  LR(1)
  族靠
  lookahead
  精确化
  消冲突，
  代价是
  状态
  分裂
  与膨胀；
- LALR
  同心
  合并
  把状态
  数拉回
  LR(0)
  规模，
  对合法
  输入
  行为
  与 LR(1)
  一致，
  只在
  错误
  输入上
  可能
  延迟
  报错；
- 三张表
  构成
  谱系：
  状态数
  与接受面
  此消
  彼长，
  语言
  层面
  三者
  等价。

下一章
（9）
回到
ANTLR
身边，
看语法树
怎么从
分析器
手里
安全地
长出来。

练习：

1. 把
   第 6 章
   的
   悬挂
   else
   文法
   写成
   LR(1)
   造表
   输入，
   验证
   LR(1)
   对它
   无冲突
   （鲸书
   §3.4.3
   的
   结论：
   悬挂
   else
   在
   prefer-shift
   口径下
   LR(1)
   可解）。
2. 构造
   一个
   文法：
   SLR
   无冲突、
   规范
   LR(1)
   状态数
   恰为
   SLR 的
   两倍
   （提示：
   让每个
   LR(0)
   状态
   都分裂）。
3. 给
   `buildLALR`
   加
   "延迟
   归约"
   演示：
   构造
   一个
   错误
   串，
   使
   LALR
   的
   拒绝
   步数
   大于
   LR(1)
   （鲸书
   §3.7
   的
   副作用）。
4. 实现
   §3.6.2
   的
   行合并
   压缩：
   统计
   经典
   表达式
   文法
   LR(1)
   ACTION
   表的
   重复行，
   报告
   压缩率。
5. 把
   `closure`
   的
   lookahead
   传播
   改成
   "先造
   LR(0)
   族、
   再沿
   边
   传播
   lookahead
   到
   不动点"
   （自发生成
   式
   LALR
   算法，
   不经过
   规范
   LR(1)
   族），
   对比
   两路
   的
   中间
   数据
   结构
   规模。

---

上一章：[07 LR 分析](07-lr-parsing.md) · 下一章：[09 Lex 与 Yacc 心脏](09-lex-yacc.md)
