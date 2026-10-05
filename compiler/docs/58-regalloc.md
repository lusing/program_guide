# 第 58 章　寄存器分配：干涉图与图着色

## 58.1 问题：把无限的名字塞进有限的盒子

TAC 的世界里
变量名字无限；
真实机器的
寄存器
一只手数得过来
（x86-64 通用
  整数寄存器
  16 个，
  分给编译器
  可自由调度的
  更少）。
把 N 个变量
装进 k 个盒子——
这就是
**寄存器分配**，
后端第一场硬仗。

好消息：
这个问题有
漂亮的组合化身
（绿龙 15.5、
紫龙 8.8）：

> 两个变量的
> **活跃区间重叠**
> ⟺ 不能同盒
> ⟺ 干涉图上
> 有边。
> 分配 = 给
> 干涉图着色，
> 色数 ≤ k。

图着色
是 NP 完全的，
但 Chaitin 与
Briggs 的
**启发式栈算法**
在实践中近乎
无往不利——
本章实现它，
并让"相邻异色"
成为机器校验的
对账断言。

## 58.2 活跃与干涉：从分析到图

**活跃**
（第 30 章）：
变量的值
从定值到
最后一次使用
之间"活着"。
块级方程：

```
in[B]  = use[B] ∪ (out[B] − def[B])
out[B] = ∪ in[S]     （后向 may）
```

**干涉图**
的构造
（经典规则）：

```
对每条指令 "d = a op b"：
    对定义后仍活跃的每个变量 v：
        加边 (d, v)
    （move 指令 "d = a" 的 a 例外——见 43.4）
```

为什么是
"定义点"加边？
定义 d 的
那一刻起
d 的值开始活，
与"此后仍活"的
v 抢同一个
时间窗——
两值必须同时
有处安放，
故不能同盒。

为什么
move 源例外？
`d = a` 之后
a 若死了，
d 与 a
**可以**共盒
（盒子里的值
  原封传给新主人，
  连搬运都省了）——
这条例外是
**合并**
（coalescing）
的门票：
把 move 两端
染成同色，
move 指令
整个消失。
本章把
move 边单独
登记为
合并候选
（`moves:` 行），
合并本体
留作练习
（它和着色性
  的张力见
  43.4）。

期望输出
（reg.tip）
的干涉段：

```
a -- b     a 与 b 同时活（都等 d = a - b 用）
a -- c     c 活到 e = c * d，a 活到 d 定义
c -- d     乘法的两个操作数
...
```

每条边
都能指着源程序
说出门道——
构造干涉图的
过程就是把
程序的
"重叠时间表"
画成图。

## 58.3 Chaitin–Briggs：压栈与弹栈的着色戏法

k 色着色
NP 完全，
但有一个
近乎万能的
启发式：

**simplify（压栈）**：
反复找
**度 < k** 的点，
从图上摘下、
压入栈。
摘掉一个点，
邻居的度
跟着降，
又会露出
新的低度点——
雪崩式瓦解。

**select（弹栈）**：
按出栈序
把点放回去，
每个点从
**当时已回图的
邻居未占用**的
颜色里
任挑一个。

**为什么可行**：
度 < k 的点
无论邻居
怎么染，
至少剩一色
留给它——
弹栈时
永远有解。
这正是
"摘下时度 < k"
买到的承诺。

**溢出**：
如果压栈阶段
卡住——
剩下的点
度都 ≥ k
（一个
k+1 团：
  k+1 个变量
  互相重叠）——
启发式失败。
Briggs 的
乐观处理：
挑一个点
标记为
**溢出候选**
强行摘除，
继续游戏；
弹栈时若
它其实
染得上
（邻居凑不齐
  k 色），
就白捡；
真染不上，
它就得
"住到内存里"
——每次使用
load 进寄存器、
定义后
store 回内存，
程序变慢
但正确。

溢出的
连锁反应：
被溢变量的
全部使用点
拆成无数
小活跃区间
（各自 load/store），
图重画、
重新着色——
迭代到
全部装下为止。
工程口诀：
**溢出代价
  与使用次数
  成正比**，
所以挑
"使用少、
  度数高"的
  点下手
（我们的教学版
  按度最大挑）。

期望输出的
两个结局：

- reg.tip：
  `spill-free: yes`，
  7 个变量
  装进 3 个寄存器
  ——b、d、t2、t4
  **共享 r0**：
  生命周期
  完全错开的
  四个名字
  轮流用
  同一个盒子，
  这正是分配器
  的日常工作；
- pressure.tip：
  a、b、c、d
  四个输入
  同时活跃到
  最后一个大表达式
  ——4 团撞上
  k=3，
  `spilled: a b`，
  干涉图的
  硬边界
  如实显形。

校验段
`相邻异色且色域<=k: yes`
不是装饰：
它对
**每条边**
检查两端
异色——
分配器的
正确性
从"信我"
变成
"机器替你
 逐边复查"。

## 58.4 工程注意点

- **合并的代价**。
  无脑合并
  move 两端
  可能造出
  度数飙升的
  团，
  把原本
  可着色的图
  逼向溢出。
  Briggs 准则：
  合并后
  度 < k 的
  **邻居数**
  不减，
  才算安全；
  George 准则
  更宽。
  合并与着色性
  的这场拉锯
  是分配器
  调参的主轴。
- **寄存器合租**。
  调用约定
  （第 19 章）
  钦定某些
  寄存器的
  用途
  （传参、
    返回值、
    栈指针）——
  它们是图上
  预着色的
  固定居点，
  与它们干涉
  的变量
  天生少一色。
- **活跃区间
  vs 活跃点集**。
  我们用
  "定义后活跃"
  的点集口径
  建边；
  区间口径
  （线段树）
  在直线代码
  上等价，
  循环里
  点集更准
  （活跃
    "绕回边"）。
- **分裂**。
  除了溢出，
  还有第三条路：
  把一个
  长命变量的
  生命周期
  拆成几段
  （每段
    独立着色），
  live range
  splitting
  是现代分配器
  （LLVM greedy）
  的主力武器。
- **为什么
  k=3 起**：
  教学取
  最小的
  有意义压力；
  真实目标
  从
  ~10 到 30+
  （含向量
    寄存器），
  算法不变，
  只是团更大、
  合并更凶。

## 58.5 本章配套文件

### 58.5.1 文法 TIP.g4

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

### 58.5.2 新件：ra.hpp 与 ra.cpp

块级活跃、
干涉图构造
（move 例外）、
Chaitin–Briggs
压弹栈着色、
合法性校验。

```cpp
// file: src/ra.hpp
// file: src/ra.hpp
// 第 58 章配套：活跃分析 → 干涉图 → Chaitin–Briggs 图着色。
//   块级 in/out（后向 may）+ 块内逐指令活跃（活跃区间边源）；
//   干涉边：定义点处“同时活跃”的变量对（move 的源例外——合并候选）；
//   着色：simplify 栈（度 < k 入栈）+ select（弹出时挑邻居未占色）；
//   无法着色即溢出候选——本章如实报告，改写留作练习。
#ifndef TIP_RA_HPP
#define TIP_RA_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 块级活跃（第 30 章同式），另给每块的 liveOut。
struct LiveInfo {
    std::vector<std::set<std::string>> in, out;
};

LiveInfo liveness(const std::vector<Quad> &code, const std::vector<Block> &blocks);

// 干涉图：邻接表 + 度。边 (x,y)：x 定义处 y 活跃（或反），
// move（Copy）的源与目的例外。
struct InterfGraph {
    std::map<std::string, std::set<std::string>> adj;
    std::set<std::pair<std::string, std::string>> edges;   // 规范序 (a<b)
    std::vector<std::pair<std::string, std::string>> moveEdges;   // 合并候选
};

InterfGraph buildInterf(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                        const LiveInfo &lv);

// 图着色（k 色）。ok=false 表示有溢出候选（spilled 列出）。
struct ColorResult {
    bool ok;
    std::map<std::string, int> color;      // 变量 → 色（0..k-1）
    std::vector<std::string> stackOrder;   // simplify 出栈序
    std::vector<std::string> spilled;      // 溢出候选
    int coalesced = 0;                     // Briggs 安全合并次数
};

ColorResult colorGraph(const InterfGraph &g, int k);

// 校验：相邻异色、色域合法。返回 true 即合法着色。
bool colorValid(const InterfGraph &g, const std::map<std::string, int> &color, int k);

}  // namespace tip

#endif  // TIP_RA_HPP
```

```cpp
// file: src/ra.cpp
// file: src/ra.cpp
// 第 58 章配套：活跃、干涉图、着色实现。
#include "ra.hpp"

#include <cctype>

namespace tip {

namespace {
bool isNumR(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarR(const std::string &s) { return !s.empty() && !isNumR(s); }
bool pureDefR(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

LiveInfo liveness(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    LiveInfo lv;
    lv.in.assign(n, {});
    lv.out.assign(n, {});
    auto adjOf = [&](size_t b) {
        std::vector<size_t> out;
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) out.push_back(k);
        return out;
    };
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            // in = use ∪ (out − def)；逐条后向扫块内
            std::set<std::string> s = lv.out[b];
            for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
                const Quad &q = code[i];
                if (pureDefR(q) && isVarR(q.dst)) s.erase(q.dst);
                if (isVarR(q.a)) s.insert(q.a);
                if (isVarR(q.b)) s.insert(q.b);
            }
            std::set<std::string> o;
            for (auto s2 : adjOf(b)) o.insert(lv.in[s2].begin(), lv.in[s2].end());
            if (s != lv.in[b] || o != lv.out[b]) {
                lv.in[b] = s;
                lv.out[b] = o;
                ch = true;
            }
        }
    }
    return lv;
}

InterfGraph buildInterf(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                        const LiveInfo &lv) {
    InterfGraph g;
    auto addEdge = [&](const std::string &x, const std::string &y) {
        if (x == y || x.empty() || y.empty()) return;
        g.adj[x].insert(y);
        g.adj[y].insert(x);
        g.edges.insert({std::min(x, y), std::max(x, y)});
    };
    size_t n = blocks.size();
    for (size_t b = 0; b < n; ++b) {
        // 块内逐指令活跃（从 liveOut 倒推）
        std::set<std::string> live = lv.out[b];
        for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
            const Quad &q = code[i];
            // 定义 d 与“定义后仍活跃”的每个变量互相干涉；
            // Copy 的源例外（它们可以共寄存器——coalescing 的候选）
            if (pureDefR(q) && isVarR(q.dst)) {
                for (const auto &v : live) {
                    if (q.op == TOp::Copy && q.a == v) {
                        g.moveEdges.push_back({q.dst, v});
                        continue;
                    }
                    addEdge(q.dst, v);
                }
                live.erase(q.dst);
            }
            if (isVarR(q.a)) live.insert(q.a);
            if (isVarR(q.b)) live.insert(q.b);
        }
    }
    return g;
}

ColorResult colorGraph(const InterfGraph &g, int k) {
    ColorResult r;
    r.ok = false;
    std::set<std::string> nodes;
    for (const auto &kv : g.adj) nodes.insert(kv.first);

    // ---------- Briggs 安全合并（虎书 §11.2）----------
    // move 边 (a,b) 合并条件：合并后 a 的邻居中度 < k 的个数
    // 不少于 a、b 两邻居集（去掉对方）中度 < k 的个数——
    // 保证合并后的图仍可被 simplify 化简（保守不伤着色性）。
    std::map<std::string, std::set<std::string>> adj = g.adj;
    // deg 用 find 不用 operator[]——后者会给已删除的节点“复活”出空邻接表！
    auto deg = [&](const std::string &v) {
        auto it = adj.find(v);
        return it == adj.end() ? 0 : static_cast<int>(it->second.size());
    };
    for (int round = 0; round < 10; ++round) {   // 合并到不动点（上限保险）
        bool merged = false;
        for (const auto &pr : g.moveEdges) {
            const std::string &a = pr.first, &b = pr.second;
            if (deg(a) == 0 || deg(b) == 0) continue;
            if (!adj.count(a) || !adj.count(b)) continue;
            if (adj[a].count(b)) continue;   // 已干涉，不可合并
            // Briggs 准则
            std::set<std::string> unionN;
            unionN.insert(adj[a].begin(), adj[a].end());
            unionN.insert(adj[b].begin(), adj[b].end());
            unionN.erase(a);
            unionN.erase(b);
            int significant = 0;
            for (const auto &n : unionN)
                if (deg(n) >= k) ++significant;
            if (significant >= k) continue;   // 合并会产生度 ≥ k 的显著邻居过多
            // 执行合并：b 并入 a
            for (const auto &n : adj[b]) {
                if (n == a) continue;
                adj[n].erase(b);
                adj[n].insert(a);
                adj[a].insert(n);
            }
            adj.erase(b);
            ++r.coalesced;
            merged = true;
            break;   // 一轮一合并（教学清晰；工作表版整轮扫）
        }
        if (!merged) break;
    }

    fprintf(stderr, "[coalesce done] keys:");
    for (const auto &kv : adj) fprintf(stderr, " %s", kv.first.c_str());
    fprintf(stderr, "\n");
    // simplify：反复把度 < k 的点压栈（从图上摘下）；
    // 摘不掉且还有点 → 记溢出候选（度最大者）并继续。
    std::map<std::string, std::set<std::string>> adjMerge = adj;   // select 用合并图
    std::set<std::string> remaining;
    for (const auto &kv : adj) remaining.insert(kv.first);
    while (!remaining.empty()) {
        bool progressed = false;
        for (const auto &v : remaining) {
            if (static_cast<int>(adj[v].size()) < k) {
                r.stackOrder.push_back(v);
                for (const auto &u : adj[v]) adj[u].erase(v);
                adj.erase(v);
                remaining.erase(v);
                progressed = true;
                break;   // 一次摘一个，重扫（教学清晰优先）
            }
        }
        if (progressed) continue;
        // 无低度点：挑度最大者作溢出候选，强行摘除
        std::string best;
        int bestDeg = -1;
        for (const auto &v : remaining)
            if (static_cast<int>(adj[v].size()) > bestDeg) {
                bestDeg = static_cast<int>(adj[v].size());
                best = v;
            }
        r.spilled.push_back(best);
        for (const auto &u : adj[best]) adj[u].erase(best);
        adj.erase(best);
        remaining.erase(best);
    }
    // select：按栈序（后进先出）归还节点，挑邻居未占色
    for (auto it = r.stackOrder.rbegin(); it != r.stackOrder.rend(); ++it) {
        const std::string &v = *it;
        std::set<int> used;
        for (const auto &u : adjMerge.at(v)) {
            auto cit = r.color.find(u);
            if (cit != r.color.end()) used.insert(cit->second);
        }
        int c = 0;
        while (c < k && used.count(c)) ++c;
        if (c >= k) return r;   // 理论上 simplify 保证不会走到（除非溢出摘点后仍拥挤）
        r.color[v] = c;
    }
    for (const auto &s : r.spilled) r.color.erase(s);
    r.ok = r.spilled.empty();
    return r;
}

bool colorValid(const InterfGraph &g, const std::map<std::string, int> &color, int k) {
    // 已着色子图上相邻必异色；端点被溢出（无色）的边免责——溢出正是绕行它的手段。
    for (const auto &e : g.edges) {
        auto a = color.find(e.first), b = color.find(e.second);
        if (a == color.end() || b == color.end()) continue;
        if (a->second == b->second) return false;
    }
    for (const auto &kv : color)
        if (kv.second < 0 || kv.second >= k) return false;
    return true;
}

}  // namespace tip
```

### 58.5.3 驱动 main.cpp

活跃/图/着色
三段打印 +
相邻异色断言 +
双结局程序。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 58 章驱动：--check FILE
//   TAC → 块级活跃 → 干涉图 → k=3 图着色 →
//   合法性断言（相邻异色）+ 寄存器映射表 + outputs 对账（TAC 未改，解释器走原程序）。
#include "ra.hpp"
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

    tip::LiveInfo lv = tip::liveness(code, blocks);
    std::cout << "== liveness ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << " in={";
        bool first = true;
        for (const auto &v : lv.in[b]) {
            std::cout << (first ? "" : ",") << v;
            first = false;
        }
        std::cout << "} out={";
        first = true;
        for (const auto &v : lv.out[b]) {
            std::cout << (first ? "" : ",") << v;
            first = false;
        }
        std::cout << "}\n";
    }

    tip::InterfGraph g = tip::buildInterf(code, blocks, lv);
    std::cout << "== interference ==\n";
    for (const auto &e : g.edges) std::cout << "  " << e.first << " -- " << e.second << '\n';
    std::cout << "  moves:";
    for (const auto &m : g.moveEdges) std::cout << ' ' << m.first << "<->" << m.second;
    std::cout << '\n';

    const int K = 3;
    tip::ColorResult cr = tip::colorGraph(g, K);
    std::cout << "== coloring (k=" << K << ") ==\n";
    for (const auto &v : cr.stackOrder) (void)v;
    for (const auto &kv : cr.color)
        std::cout << "  " << kv.first << " -> r" << kv.second << '\n';
    if (!cr.spilled.empty()) {
        std::cout << "  spilled:";
        for (const auto &s : cr.spilled) std::cout << ' ' << s;
        std::cout << "（溢出改写留作练习；本表未含溢出者）\n";
    }
    std::cout << "  spill-free: " << (cr.ok ? "yes" : "no") << '\n';
    std::cout << "  coalesced = " << cr.coalesced << '\n';

    std::cout << "== 校验 ==\n";
    // 两种正确结局：无溢出且合法着色；或有溢出（如实报告、改写留作练习）。
    bool valid = tip::colorValid(g, cr.color, K) && (cr.ok || !cr.spilled.empty());
    std::cout << "  已着色子图相邻异色且色域<=k: " << (tip::colorValid(g, cr.color, K) ? "yes" : "NO") << '\n';

    std::cout << "== 对账 ==\n";
    tip::TacRun run = tip::tacInterp(code, {4, 7, 5, 2});
    std::cout << "  outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << "\n  (着色是分配方案，不改程序；解释器照常执行原 TAC)\n";
    return valid ? 0 : 1;
}
```

### 58.5.4 TAC 基座与前端（第 13、8、10 章）

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

### 58.5.5 程序与期望输出

```text
// file: programs/pressure.tip
main() {
  var a, b, c, d, e;
  a = input;
  b = input;
  c = input;
  d = input;
  e = (a + b) + ((c + d) * (a - b));
  output e;
  return 0;
}
```

```text
// file: programs/reg.tip
main() {
  var a, b, c, d, e;
  a = input;
  b = input;
  c = a + b;
  d = a - b;
  e = c * d;
  output e;
  return 0;
}
```

```text
; expected: expected/output.txt
== moves.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: b = a
  3: t2 = a + b
  4: c = t2
  5: t3 = b * c
  6: d = t3
  7: t4 = d + a
  8: output t4
  9: t5 = 0
  10: return t5
== liveness ==
  B0 in={} out={}
== interference ==
  a -- c
  a -- d
  a -- t2
  a -- t3
  b -- c
  b -- t2
  moves: b<->a
== coloring (k=3) ==
  b -> r1
  c -> r0
  d -> r0
  t2 -> r0
  t3 -> r0
  spill-free: yes
  coalesced = 1
== 校验 ==
  已着色子图相邻异色且色域<=k: yes
== 对账 ==
  outputs: 36
  (着色是分配方案，不改程序；解释器照常执行原 TAC)
[coalesce done] keys: b c d t2 t3
== pressure.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: t2 = input
  3: b = t2
  4: t3 = input
  5: c = t3
  6: t4 = input
  7: d = t4
  8: t5 = a + b
  9: t6 = c + d
  10: t7 = a - b
  11: t8 = t6 * t7
  12: t9 = t5 + t8
  13: e = t9
  14: output e
  15: t10 = 0
  16: return t10
== liveness ==
  B0 in={} out={}
== interference ==
  a -- b
  a -- c
  a -- d
  a -- t2
  a -- t3
  a -- t4
  a -- t5
  a -- t6
  b -- c
  b -- d
  b -- t3
  b -- t4
  b -- t5
  b -- t6
  c -- d
  c -- t4
  c -- t5
  d -- t5
  t5 -- t6
  t5 -- t7
  t5 -- t8
  t6 -- t7
  moves:
== coloring (k=3) ==
  c -> r2
  d -> r1
  t2 -> r0
  t3 -> r0
  t4 -> r0
  t5 -> r0
  t6 -> r1
  t7 -> r2
  t8 -> r1
  spilled: a b（溢出改写留作练习；本表未含溢出者）
  spill-free: no
  coalesced = 0
== 校验 ==
  已着色子图相邻异色且色域<=k: yes
== 对账 ==
  outputs: -10
  (着色是分配方案，不改程序；解释器照常执行原 TAC)
[coalesce done] keys: a b c d t2 t3 t4 t5 t6 t7 t8
== reg.tip ==
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
  10: output e
  11: t6 = 0
  12: return t6
== liveness ==
  B0 in={} out={}
== interference ==
  a -- b
  a -- c
  a -- t2
  a -- t3
  b -- c
  b -- t3
  c -- d
  c -- t4
  moves:
== coloring (k=3) ==
  a -> r2
  b -> r0
  c -> r1
  d -> r0
  t2 -> r0
  t3 -> r1
  t4 -> r0
  spill-free: yes
  coalesced = 0
== 校验 ==
  已着色子图相邻异色且色域<=k: yes
== 对账 ==
  outputs: -33
  (着色是分配方案，不改程序；解释器照常执行原 TAC)
[coalesce done] keys: a b c d t2 t3 t4
```

## 58.6 小结与练习

本章把
存储分配
化成图论：

- 活跃重叠
  ⟺ 干涉边，
  分配 =
  k 着色；
- Chaitin–Briggs：
  低度压栈
  买保险，
  弹栈挑色
  兑现保险，
  团撞墙则
  溢出到内存；
  move 源的
  边例外
  为合并留门；
  相邻异色
  逐边机器校验。

下一章
跨过分配、
直抵指令：
树覆盖选指令、
窥孔扫尾——
TAC 变成
目标机的
汇编。

练习：

1. 手工对 reg.tip
   画干涉图、
   跑压弹栈，
   与输出对照；
   验证 b/d/t2/t4
   共享 r0 的
   生命周期依据。
2. 实现 Briggs
   安全合并：
   moves 清单里
   两端合并后
   度 < k 的
   邻居数不减
   才合并，
   观察 move
   指令消除数。
3. 实现溢出改写：
   spilled 变量的
   定值后插
   store、
   使用前插
   load
   （用 TAC 的
    Copy 模拟），
   拆分后的
   区间重着色，
   验收线：
   outputs 不变、
   k 色装下。
4. 把 k 改成
   4 与 2，
   分别跑两个
   程序，
   观察着色与
   溢出的边界
   怎么移动。
5. 构造一个
   需要 5 团的
   程序
   （五个变量
    同时活跃），
   在 k=3 下
   数溢出迭代
   轮数，
   并讨论
   "挑度最大者"
   与
   "挑使用最少者"
   两种策略的
   差异。
