# 第 40 章　支配者与自然循环：控制流的代数骨架

## 40.1 问题：循环到底是什么

第 18 章的块图上
"循环"只是
一个回边加一堆块；
第 28–36 章的分析
对循环无能为力时
只能靠 widening
硬着陆。
要**优化**循环
（下一章的外提、
  强度削减；
  第 45 章的正餐），
先得回答：
哪些块构成
一个循环？
循环的头是谁？
循环能不能嵌套？

答案是一套
漂亮的图论
（绿龙 13.1–13.3、
紫龙 9.6，
自包含展开）：

- **支配者**
  （dominator）
  给"必经之路"
  立定义；
- **支配树**
  把必经关系
  收成一棵树；
- **DFS 边分类**
  从遍历顺序里
  淘出回边；
- **自然循环**
  = 回边 + 反向可达，
  干净得像定理；
- **可归约性**
  一句话判别
  "这图是不是
  结构化程序
  摊出来的"。

## 40.2 支配者：必经之路的代数

d **支配** b
（记 d dom b），
如果**每条**
从入口到 b 的
路径都经过 d。
约定每个块
支配自己。

三个立刻可验的
性质：
自反（b dom b）、
传递
（a dom b、b dom c
  ⇒ a dom c）、
**反对称**
（互相支配即相等）
——偏序。
更关键的一条：
入口到 b 的
任何路径上，
b 的支配者们
**全体出现，
且按同一个
"支配序"排列**
——这保证
"直接支配者"
idom(b)
（b 的严格支配者中
  最贴近 b 的那个）
唯一存在。
全体 idom 边
构成一棵
以入口为根的
**支配树**：
树的形态说
"必经关系
没有网、只有链"。

迭代求法
（与数据流分析
  互为镜像）：

```
dom[entry] = {entry}
dom[b]     = {b} ∪ ⌂ dom[p]     （p 取遍 b 的前驱）
```

初值：
非入口块从
**全集**出发
（"人人可能支配"），
迭代只做
**交**
（逐步证伪），
单调收缩、
有限高度 ⇒
收敛（第 30 章
骨架的
"自顶向下版"——
must 家族的
活亲戚）。

期望输出
（loop.tip，
九块带分支的
while 程序）：

```
dom(B0) = {0}  idom=-1
dom(B1) = {0,1}  idom=0
dom(B2) = {0,1,2}  idom=1
dom(B4) = {0,1,3,4}  idom=3
...
```

读两个点：
B8 的支配集
是 {0,1,2,8}——
它住在
"if 分支的
then 侧"
（B2 子树），
于是 then 侧
的祖先链
全数在列；
`domTreeCheck: yes`
——示例用
"从树推回支配集"
做了机器自检，
idom 的唯一性
不是空口白话。

## 40.3 DFS 与边分类：从遍历顺序里淘结构

给块图做一遍
深度优先遍历，
每块记两个时间戳：
发现 d 与完成 f
（白灰黑三色：
  白=没碰过、
  灰=在栈上、
  黑=子树完成）。
每条边 (u,v)
按 v 的颜色
与时间戳分四类：

- **树边**：
  v 白——
  遍历真正走的边；
- **后退边**
  （back）：
  v 灰——
  指向仍在栈上的
  祖先；
  循环的候选；
- **前向边**：
  v 黑且
  d[v] > d[u]——
  抄近路到
  自己的后代；
- **交叉边**：
  v 黑且
  d[v] < d[u]——
  跨越两棵
  已完成的子树。

分类只依赖
一遍 DFS 的
局部信息，
O(V+E)。

## 40.4 自然循环：回边的领地

**回边**：
后退边 n → h
且 h **支配** n
（这是"真回边"的
判别式——
后退只是
遍历的观感，
支配才是语义）。

回边 n → h 的
**自然循环**：

```
loop = {h} ∪ { 不经过 h 就能到达 n 的所有块 }
```

求法两步：
从 n 沿**反向边**
做可达性
（遇 h 即停，
  h 只作为成员
  不再穿过），
得到的集合
加上 h 本身。
反向可达 =
"这些块在循环里
  真的会转回来"；
h 挡驾 =
"循环体不可能
  从内部漏出去
  绕过头"。

性质（每条都值
  一分钟琢磨）：

- h **支配**循环
  全部成员
  （进循环必过头）；
- 成员到 n 的
  路径全在循环内
  （不然就经过了 h）；
- 两个自然循环
  要么不相交、
  要么一个含另一个
  ——**嵌套**，
  永不"半重叠"
  （半重叠的两个环
  会合成一个
  更大的环）。

期望输出：

```
back 7->1 header=1 body={1,3,4,5,6,7}
```

while 的回边
（循环尾跳回头）
领出六块领地，
if 分支
（B4/B5）整个
住在领地里——
循环体嘛。

## 40.5 可归约性：结构化控制流的图论化身

**可归约图**：
存在一种 DFS
使得所有
后退边都是回边
（目标支配源）。
等价判别
（教学口径）：
任意深度优先序下，
"后退方向"的边
若**每一条**
目标都支配源，
图可归约。

为什么在意？
因为
while/if/序列
拼出来的程序
**必然**可归约：
结构化语法
就是
"可归约图的发生器"。
可归约图上，
循环 = 自然循环
（没有冒牌货），
支配树 + 回边
就**完全**刻画了
控制流——
区域分析、
循环优化、
第 41 章 SSA 的
支配边界
全都吃这张饭。

**不可归约**长什么样？
经典款：
一个环有
**两个入口**。

```
B0 → B1, B0 → B2     （分岔进环的两半）
B1 → B2, B2 → B1     （环）
```

TIP 的结构化语法
**造不出**它
（goto 才行），
所以示例里
这张图是内置的
（ch23 演示图的同款待遇）。
跑出来：

```
edge 2->1 : back
dom(B2) = {0,2}        ← 1 不在其中！
natural loops: back 2->1 header=1 body={0,1,2}
reducible: no
```

两个病征一目了然：
后退边 2→1 的
目标 1 **不支配**
源 2
（B0 可以绕过 1
  直达 2）；
"自然循环"的
领地被迫吞下
**入口 B0**
——环没有唯一的头，
循环的概念
在这张图上
瓦解。
真实编译器遇到
不可归约图
（通常来自
  goto 或优化撕裂）
要么复制代码
把它"归约化"，
要么退回
保守算法。

## 40.5b CHK 快支配与稀疏集：把集合换成一条链

迭代法
抱着
**支配集**
做
交集，
每个
节点
一个
集合、
每轮
全量
重算——
鲸书
§9.5.2
指出
这里
有一间
可以
搬空的
储藏室：
支配集
的全部
信息
其实
压缩在
**idom**
（直接
支配者）
一条
链上：

- dom(b)
  =
  idom 链
  从 b
  一路
  上行
  到根的
  节点
  序列——
  **集合
  读自
  树**；
- 两个
  支配集
  的
  交集
  =
  两条
  idom 链
  的
  **公共
  后缀**。
  公共
  后缀
  怎么
  找？
  给节点
  编上
  **RPO 号**
  （逆
  后序），
  两个
  指针
  沿
  链
  上行，
  谁的
  RPO 号
  大谁
  走——
  大者
  离根
  更远——
  相遇处
  即
  交。

于是
方程
变成：
按
RPO 序
扫块，
`idom[b] =
intersect(各
已编号
前驱)`，
扫到
不动点。
这就是
Cooper–
Harvey–
Kennedy
的
"简单
快速
支配
算法"
（CHK）：
内存
从
O(n²)
的
集合
跌回
O(n)
的
父指针
数组，
轮数
经验上
2~4
（期望
输出：
两个
图都
"迭代
2 轮
vs
CHK
2 轮，
支配集
一致"——
小图
打平，
大图
的
每轮
成本
差
才是
主场）。

配套
登场的
还有
鲸书
附录
B.2.3 的
**稀疏集**
（sparse
set）：
dense/
sparse
双数组
加
游标。
clear
只把
游标
归零
（O(1)，
数组
不碰）；
成员
测试
靠
"双向
互指"
（`dense[sparse[i]]
==
i`
且
游标
之内）；
遍历
沿
dense
走
O(|S|)
而非
位向量的
O(|U|)。
CHK 的
DFS
编号
集、
第 69 章
布局的
工作表
去重、
寄存器
分配的
节点
标记——
编译器
里
"反复
建集、
整批
清空"
的
场景
都
是
它的
主场；
CHK
论文
当年
的
卖点
之一
就是
用它
装
工作表。

## 40.6 示例落地

三个文件的分工：

- `dom.cpp`：
  迭代支配集
  （全集起步、
   逐前驱取交）、
  idom 归纳
  （严格支配者中
   支配集最大者）、
  支配树孩子表、
  `domTreeCheck`
  （树推回集合 ==
   迭代解）；
- `dfs.cpp`：
  三色 DFS +
  时间戳 +
  四类边分类；
  自然循环 =
  反向可达 +
  header 挡驾；
  可归约性 =
  "后退边目标
   支配源"逐条检查；
- `main.cpp`：
  TIP 程序 →
  TAC → 块图 →
  邻接表 →
  全套分析打印；
  末尾内置
  不可归约三块图
  跑同一套流程
  （同一份代码，
  两种命运——
  对照即教学）。

所有算法以
**邻接表**
为接口
（块号 → 块号表），
与 TAC 的细节
解耦——
第 41 章
（支配边界）
与第 45 章
（循环优化）
将直接复用
这套接口。

## 40.7 工程注意点

- **迭代支配者
  不是最快的**。
  精确算法
  （Lengauer–Tarjan
  近似+修正，
  近线性）
  是工业标配；
  Cooper–Harvey–Kennedy
  的"逆后序倒序"
  迭代在实践中
  两三轮收敛，
  也广为使用
  （LLVM 用的就是它）。
  教学迭代版的
  价值在
  "与数据流框架
   同一骨架"。
- **支配树的
  一切用途**。
  SSA 改名
  沿支配树走
  （第 41 章）、
  支配边界
  从树算
  （同前）、
  循环嵌套森林
  供外提
  （第 45 章）、
  作用域提升……
  支配树是
  中端的
  "骨架 CT 片"。
- **不可达块**。
  迭代方程里
  无前驱块
  的支配集
  收缩到
  {自己}
  （示例对
  不可达块的处理）；
  真实编译器
  会先做
  不可达代码删除
  （第 43 章 DAG
  的顺带收益）。
- **回边 vs
  后退边**。
  命名常混用；
  本章口径：
  后退=遍历观感
  （灰→灰），
  回边=语义
  （目标支配源）。
  可归约图上
  两者重合，
  不可归约图上
  的差集
  正是病根。

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

### 40.8.2 dom.hpp 与 dom.cpp

支配集迭代、
idom、支配树、
自检。

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
    int sweeps = 0;                      // 全图扫描轮数（对照 CHK 用）
};

// 前驱表（邻接表反推）。
std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj);

DomInfo dominators(const std::vector<std::vector<int>> &adj);

// 自检：由支配树推导的支配集 == 迭代解（idom 唯一性的机器验证）。
bool domTreeCheck(const DomInfo &di);

// ---------- 稀疏集（鲸书附录 B.2.3）----------
// dense/sparse 双数组 + 游标：clear 是 O(1)（游标归零，不必清数组）；
// 成员测试靠"双向互指"：0 ≤ sparse[i] < next 且 dense[sparse[i]] == i。
// 建在 |U| 已知的离线场景（编译器的节点全集恰是）；遍历 O(|S|) 而非 O(|U|)。
class SparseSet {
public:
    explicit SparseSet(int universe);
    void clear();
    bool insert(int i);
    bool contains(int i) const;
    std::vector<int> items() const;
    int size() const { return next_; }

private:
    std::vector<int> sparse_, dense_;
    int next_ = 0;
};

// ---------- CHK 快支配（鲸书 §9.5.2）----------
// 只存 idom（不存支配集），交运算 = 沿 idom 链上行到 RPO 号相同处
// （两链的公共后缀就是交集）；按 RPO 序扫描，通常 2~4 轮收敛。
struct FastDomResult {
    DomInfo di;
    int passes = 0;
};
FastDomResult fastDominators(const std::vector<std::vector<int>> &adj);

}  // namespace tip

#endif  // TIP_DOM_HPP
```

```cpp
// file: src/dom.cpp
// file: src/dom.cpp
// 第 40 章配套：支配者实现。
#include "dom.hpp"

#include <functional>

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
        ++di.sweeps;
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

// ---------- 稀疏集（鲸书附录 B.2.3） ----------

SparseSet::SparseSet(int universe) : sparse_(universe, 0), dense_(universe, 0) {}

void SparseSet::clear() { next_ = 0; }   // O(1)：数组不碰，旧数据靠互指校验失效

bool SparseSet::insert(int i) {
    if (contains(i)) return false;
    sparse_[i] = next_;
    dense_[next_++] = i;
    return true;
}

bool SparseSet::contains(int i) const {
    return i >= 0 && i < static_cast<int>(sparse_.size()) &&
           sparse_[i] >= 0 && sparse_[i] < next_ && dense_[sparse_[i]] == i;
}

std::vector<int> SparseSet::items() const {
    return std::vector<int>(dense_.begin(), dense_.begin() + next_);
}

// ---------- CHK 快支配（鲸书 §9.5.2） ----------

FastDomResult fastDominators(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    FastDomResult fr;
    if (n == 0) return fr;
    // 1) RPO：DFS 后序的逆（visited 用稀疏集——clear 后可整批复用）
    SparseSet visited(static_cast<int>(n));
    std::vector<int> postorder;
    std::function<void(int)> dfs = [&](int u) {
        visited.insert(u);
        for (int s : adj[u])
            if (!visited.contains(s)) dfs(s);
        postorder.push_back(u);
    };
    dfs(0);
    std::vector<int> rpo(postorder.rbegin(), postorder.rend());
    std::vector<int> rpoNo(n, -1);
    for (size_t i = 0; i < rpo.size(); ++i) rpoNo[rpo[i]] = static_cast<int>(i);
    // 2) idom 迭代：交 = 沿 idom 链上行到 RPO 号相等的公共节点
    auto preds = predsOf(adj);
    std::vector<int> idom(n, -1);
    idom[0] = 0;
    auto intersect = [&](int b1, int b2) {
        int f1 = b1, f2 = b2;
        while (f1 != f2) {
            while (rpoNo[f1] > rpoNo[f2]) f1 = idom[f1];
            while (rpoNo[f2] > rpoNo[f1]) f2 = idom[f2];
        }
        return f1;
    };
    int passes = 0;
    for (bool changed = true; changed;) {
        changed = false;
        ++passes;
        for (int b : rpo) {
            if (b == 0) continue;
            int newIdom = -1;
            for (int p : preds[b]) {
                if (idom[p] < 0) continue;   // 前驱未编号（不可达/未处理）
                newIdom = (newIdom < 0) ? p : intersect(p, newIdom);
            }
            if (newIdom >= 0 && idom[b] != newIdom) {
                idom[b] = newIdom;
                changed = true;
            }
        }
    }
    // 3) 组装 DomInfo：支配集由 idom 链读出（树到集合）
    DomInfo &di = fr.di;
    di.idom = idom;
    di.sweeps = passes;
    di.dom.assign(n, {});
    for (size_t b = 0; b < n; ++b) {
        if (idom[b] < 0) {   // 入口或不可达：只支配自己
            di.dom[b] = {static_cast<int>(b)};
            continue;
        }
        std::set<int> s = {static_cast<int>(b)};
        int cur = idom[b];
        while (cur >= 0 && cur != static_cast<int>(b)) {
            s.insert(cur);
            cur = (cur == 0) ? -1 : idom[cur];
        }
        di.dom[b] = s;
    }
    di.children.assign(n, {});
    for (size_t b = 1; b < n; ++b)
        if (idom[b] > 0) di.children[idom[b]].push_back(static_cast<int>(b));
        else if (idom[b] == 0 && b != 0) di.children[0].push_back(static_cast<int>(b));
    fr.passes = passes;
    return fr;
}

}  // namespace tip
```

### 40.8.3 dfs.hpp 与 dfs.cpp

三色 DFS、
边分类、
自然循环、
可归约性。

```cpp
// file: src/dfs.hpp
// file: src/dfs.hpp
// 第 40 章配套之二：DFS 边分类、自然循环、可归约性。
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
// 第 40 章配套：DFS 分类、自然循环、可归约性实现。
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

### 40.8.4 驱动 main.cpp

程序块图 + 
内置不可归约图
双演示。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 40 章驱动：--check FILE
//   块图 → 支配集/支配树 → DFS 边分类 → 自然循环 → 可归约性；
//   末尾内置不可归约小图（TIP 结构化语法造不出它）演示判定失败。
#include "dom.hpp"
#include "dfs.hpp"

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

std::vector<std::vector<int>> adjOf(const std::vector<tip::Block> &blocks) {
    size_t n = blocks.size();
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    return adj;
}

void runGraph(const std::vector<std::vector<int>> &adj, const std::string &title) {
    std::cout << "== " << title << " ==\n";
    // 简易图打印
    for (size_t b = 0; b < adj.size(); ++b) {
        std::cout << "  B" << b << " ->";
        for (int s : adj[b]) std::cout << ' ' << s;
        std::cout << '\n';
    }
    tip::DomInfo di = tip::dominators(adj);
    std::cout << "== dominators ==\n";
    for (size_t b = 0; b < adj.size(); ++b) {
        std::cout << "  dom(B" << b << ") = {";
        bool first = true;
        for (int d : di.dom[b]) {
            std::cout << (first ? "" : ",") << d;
            first = false;
        }
        std::cout << "}  idom=" << di.idom[b] << '\n';
    }
    std::cout << "== dom tree ==\n";
    for (size_t b = 0; b < adj.size(); ++b)
        if (!di.children[b].empty()) {
            std::cout << "  B" << b << " :";
            for (int c : di.children[b]) std::cout << " B" << c;
            std::cout << '\n';
        }
    std::cout << "  domTreeCheck: " << (tip::domTreeCheck(di) ? "yes" : "NO") << '\n';
    tip::FastDomResult fd = tip::fastDominators(adj);
    bool same = fd.di.dom == di.dom;
    std::cout << "== fast dominators (CHK) ==\n";
    std::cout << "  迭代法扫描 " << di.sweeps << " 轮 vs CHK " << fd.passes
              << " 轮；支配集一致: " << (same ? "yes" : "NO") << '\n';
    tip::DfsInfo df = tip::dfsClassify(adj);
    std::cout << "== DFS ==\n";
    for (size_t b = 0; b < adj.size(); ++b)
        std::cout << "  B" << b << " d=" << df.discover[b] << " f=" << df.finish[b] << '\n';
    for (const auto &[u, v, kind] : df.classified)
        std::cout << "  edge " << u << "->" << v << " : " << kind << '\n';
    auto loops = tip::naturalLoops(adj, df, di);
    std::cout << "== natural loops ==\n";
    if (loops.empty()) std::cout << "  none\n";
    for (const auto &L : loops) {
        std::cout << "  back " << L.from << "->" << L.header << " header=" << L.header
                  << " body={";
        bool first = true;
        for (int m : L.body) {
            std::cout << (first ? "" : ",") << m;
            first = false;
        }
        std::cout << "}\n";
    }
    std::cout << "== reducible ==\n";
    std::cout << "  " << (tip::reducible(adj, df, di) ? "yes" : "no") << '\n';
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
    std::cout << "== TAC blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << ' ' << s;
        std::cout << '\n';
    }
    // ---------- 稀疏集自测（鲸书附录 B.2.3） ----------
    std::cout << "== sparse set ==\n";
    tip::SparseSet ss(1000);
    ss.insert(3);
    ss.insert(500);
    ss.insert(999);
    std::cout << "  插入 {3,500,999} 后 size=" << ss.size()
              << " 含 500: " << (ss.contains(500) ? "yes" : "no")
              << " 含 501: " << (ss.contains(501) ? "yes" : "no") << '\n';
    ss.clear();   // O(1)：游标归零，数组不碰
    std::cout << "  clear 后 size=" << ss.size()
              << " 含 3: " << (ss.contains(3) ? "yes" : "no") << '\n';
    ss.insert(7);
    std::cout << "  复用后遍历:";
    for (int v : ss.items()) std::cout << ' ' << v;
    std::cout << '\n';

    runGraph(adjOf(blocks), "程序块图");

    // 不可归约经典图：两个入口互相跳进对方的“环”。
    // B0→B1, B0→B2, B1→B2, B2→B1（1↔2 的环有两个入口）
    std::cout << "== 不可归约演示 ==\n";
    runGraph({{1, 2}, {2}, {1}}, "内置块图");
    return 0;
}
```

### 40.8.5 基座：tacgen、tacblocks 与前端

第 13、8、10 章原样。

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
// file: programs/loop.tip
main() {
  var a, s;
  a = 3;
  s = 0;
  while (a > 0) {
    if (a > 1) s = s + a; else s = s + 1;
    a = a - 1;
  }
  output s;
  return 0;
}
```

```text
; expected: expected/output.txt
== loop.tip ==
== TAC blocks ==
  B0 [0,4) succs: 4
  B1 [4,6) succs: 6 7
  B2 [6,7) succs: 20
  B3 [7,9) succs: 9 10
  B4 [9,10) succs: 13
  B5 [10,13) succs: 16
  B6 [13,16) succs: 16
  B7 [16,20) succs: 4
  B8 [20,23) succs:
== sparse set ==
  插入 {3,500,999} 后 size=3 含 500: yes 含 501: no
  clear 后 size=0 含 3: no
  复用后遍历: 7
== 程序块图 ==
  B0 -> 1
  B1 -> 2 3
  B2 -> 8
  B3 -> 4 5
  B4 -> 6
  B5 -> 7
  B6 -> 7
  B7 -> 1
  B8 ->
== dominators ==
  dom(B0) = {0}  idom=-1
  dom(B1) = {0,1}  idom=0
  dom(B2) = {0,1,2}  idom=1
  dom(B3) = {0,1,3}  idom=1
  dom(B4) = {0,1,3,4}  idom=3
  dom(B5) = {0,1,3,5}  idom=3
  dom(B6) = {0,1,3,4,6}  idom=4
  dom(B7) = {0,1,3,7}  idom=3
  dom(B8) = {0,1,2,8}  idom=2
== dom tree ==
  B0 : B1
  B1 : B2 B3
  B2 : B8
  B3 : B4 B5 B7
  B4 : B6
  domTreeCheck: yes
== fast dominators (CHK) ==
  迭代法扫描 2 轮 vs CHK 2 轮；支配集一致: yes
== DFS ==
  B0 d=0 f=17
  B1 d=1 f=16
  B2 d=2 f=5
  B3 d=6 f=15
  B4 d=7 f=12
  B5 d=13 f=14
  B6 d=8 f=11
  B7 d=9 f=10
  B8 d=3 f=4
  edge 0->1 : tree
  edge 1->2 : tree
  edge 2->8 : tree
  edge 1->3 : tree
  edge 3->4 : tree
  edge 4->6 : tree
  edge 6->7 : tree
  edge 7->1 : back
  edge 3->5 : tree
  edge 5->7 : cross
== natural loops ==
  back 7->1 header=1 body={1,3,4,5,6,7}
== reducible ==
  yes
== 不可归约演示 ==
== 内置块图 ==
  B0 -> 1 2
  B1 -> 2
  B2 -> 1
== dominators ==
  dom(B0) = {0}  idom=-1
  dom(B1) = {0,1}  idom=0
  dom(B2) = {0,2}  idom=0
== dom tree ==
  B0 : B1 B2
  domTreeCheck: yes
== fast dominators (CHK) ==
  迭代法扫描 2 轮 vs CHK 2 轮；支配集一致: yes
== DFS ==
  B0 d=0 f=5
  B1 d=1 f=4
  B2 d=2 f=3
  edge 0->1 : tree
  edge 1->2 : tree
  edge 2->1 : back
  edge 0->2 : forward
== natural loops ==
  back 2->1 header=1 body={0,1,2}
== reducible ==
  no
```

## 40.9 小结与练习

本章把"循环"
从直觉变成
可计算对象：

- 支配 =
  必经之路，
  偏序 + 唯一 idom
  ⇒ 支配树；
- 迭代方程与
  must 数据流
  同骨架
  （全集起步、
   交、单调收缩）；
- DFS 三色四类边；
- 回边 =
  后退 + 支配；
- 自然循环 =
  回边领地，
  只嵌套不半叠；
- 可归约性 =
  结构化程序
  的图论签名，
  双入口环是
  标准反例。

下一章在
支配树上盖
第二层楼：
支配边界与
φ 插入——
SSA 形式。

练习：

1. 手工对 loop.tip
   算一遍
   dom(B6)，
   与输出对照；
   再画出完整
   支配树，
   与 children 表
   比对。
2. 证明自然循环的
   "只嵌套不半叠"
   性质
   （提示：
   反设半重叠，
   推出 header
   之间支配矛盾）。
3. 给内置不可归约图
   再加一条边
   B1→B3、B3→B2，
   判断新的图
   是否可归约，
   用程序验证。
4. 实现
   "逆后序倒序"
   的迭代顺序
   （DFS 逆后序的
   反向访问前驱），
   数一数
   loop.tip 上
   收敛轮数
   与朴素轮转
   的差。
5. 在 loop.tip 的
   while 体里
   再嵌一层 while，
   观察两个
   自然循环的
   嵌套关系
   在输出里的
   呈现
   （body 集合的
   包含关系）。

---

上一章：[39 路径敏感](39-path-sens.md) · 下一章：[41 SSA 形式](41-ssa.md)
