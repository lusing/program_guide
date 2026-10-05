# 第 41 章　SSA 形式：支配边界、φ 插入与改名

## 41.1 问题：一个名字，一个值

回看第 18 章以来的
所有 TAC：
变量 a 在循环里
被反复重定义，
要问"a 在这点
  到底是哪次的值"，
得追 ud 链、
跑数据流。
第 36 章
常量传播的教训
更是尖锐：
汇合点一 meet，
路径里的联合信息
就没了。

**静态单赋值形式**
（SSA，
static single assignment）
一刀解决问题：

> 改写程序，
> 使**每个名字
> 只被定义一次**。

定义一次的名字
天生带着完整的
身世：
它是什么、
从哪来、
谁用它——
全部静态可见。
UD 链变成
名字上的显式边；
第 36 章的
常量传播
在 SSA 上
变身高效的
稀疏条件常量传播
（SCCP）；
第 43 章的
公共子表达式、
第 45 章的
归纳变量，
每个优化
在 SSA 上
都轻快一截。

LLVM IR
是 SSA 的
工业标准实现
（第 17 章
  见过的
  `%3 = add i32 %1, %2`
  ——指令即值，
  名字即定义）；
本章在 TAC 之上
手工构造 SSA，
并与
`opt -mem2reg`
的输出对账。

## 41.2 φ：汇合处的选择性赋值

不同路径给
同一个变量
带来不同的值，
汇合后要用谁？
SSA 引入
**φ 函数**
（phi）：

```
i1 = phi(i0, i2)
```

读法：
"从**第一个前驱**
  进来取 i0，
  从**第二个前驱**
  进来取 i2"。
φ 的参数表
与前驱表
一一对应。

两条纪律：

1. **φ 是并行赋值**。
   块头若有多个 φ，
   它们**同时**取值、
   同时写值——
   
```
a1 = phi(b1, ...)
b2 = phi(a1, ...)
```
   
   b2 的参数 a1 指
   **块外旧值**，
   不是本块
   刚写的新 a1。
   顺序执行会
   错读新值；
   并行语义
   一如第 13 章
   属性文法的
   "先全部求值
    再全部赋值"。
   （我们的实现
    先收齐
    全部 φ 的
    右端再写，
    并为 SSA
    名字互不相同
    这个事实
    留了顺序版
    也正确的注脚。）
2. **φ 挂在块头**，
   与前驱绑定。
   没有"块中间
    的 φ"——
   汇合点的语义
   只存在于
   块的入口。

## 41.3 支配边界：φ 该插在哪

哪些块需要 φ？
直观：变量 v
在多条路径上
有不同定值、
且这些路径
在块 c 汇合——
c 需要
`v = φ(...)`。

精确化的工具是
第 40 章的
支配树。
**支配边界**：

> DF(b) =
> { c | b 支配 c 的
>   某个前驱，
>   但 b 不
>   严格支配 c }

直觉：b 的势力
沿支配树下行，
DF(b) 是
"够得着、管不到"
的汇合点。
循环头 B1 的 DF
含循环头的
汇合候选——
正是 φ 的家。

**CHK 算法**
（Cooper–Harvey–Kennedy）
只需三行：

```
对每个汇合点 c（前驱 ≥ 2）：
    对 c 的每个前驱 p：
        runner 从 p 出发沿 idom 上行，
        直到 idom[c]：
            每站 DF[runner] += c
```

为什么对：
runner 沿 idom 上行
恰好经过
"支配 p 但不
 严格支配 c"
的所有块
——DF 定义的
逐字遍历。

**φ 插入**
（iterated DF）：
变量 v 的
定值块集合 D_v；
把 D_v 里所有块
的 DF 并起来，
新加入的 φ 块
本身也是 v 的
（新）定值，
继续传播——
工作表到不动点。
我们的实现
对**每个**
多定值变量
（含临时 t）
都插 φ
——朴素 SSA；
用活跃信息
过滤"入口处
不活跃"的变量
得到**修剪 SSA**
（pruned），
φ 更少。
LLVM 的
mem2reg
是修剪版：
对账输出里
LLVM 只为
s 和 i 生成 phi，
我们还有
t3..t6 的
（首入循环取
 0 初值的那些）
——这个差集
就是两种策略的
肉眼对比。

## 41.4 改名：支配树先序 + 版本栈

φ 就位后，
把每个变量的
每次定值
改成新名字
（v0, v1, v2…），
使用点改成
"当前版本"：

1. 按支配树
   **先序**
   遍历块；
2. 每块：
   先给块头 φ 的
   目标发新版本；
   再逐指令：
   **先**把操作数
   换成当前版本，
   **后**给本条
   定值发新版本
   （顺序保证
    `i1 = i0 + 1`
    读的是旧 i0）；
3. 块尾：
   给每个后继的
   φ 填一个实参
   （按本块在
    后继前驱表中的
    位置）——
   用本块出口处的
   当前版本；
4. 递归孩子；
   返回前
   弹出本块压过的
   全部版本。

**版本栈 = 
支配性质的应用**：
进入块 b 时，
栈里的版本
恰好是
"b 的支配者们
  留下的版本"——
因为按支配树先序走，
任何使用点
能看到的定值
必然支配它
（不然它不该
  读到这个值），
而栈顶就是
最近的那个。
正确性的钥匙
还是第 40 章：
**使用被支配者的
定义所定义**。

改名器遇到
"从未定值就读"
的名字
（理论上不该有，
  临时上的 φ 首参
  会造出来）
标记为
`vu`（⊥），
解释器按
全 0 初值口径
处理
（与第 70 章
α(全 0 环境)
一致）。

## 41.5 期望输出解读

**phi.tip 段**
（while 累加）：

```
B1:
    i1 = phi(i0, i2)
    s1 = phi(s0, s2)
    t30 = phi(t3u, t31)
    ...
    t31 = 5
    if t31 > i1 goto B3
B3:
    t41 = s1 + i1
    s2 = t41
    ...
    i2 = t61
    goto B1
B4:
    output s1
```

三处看点：

1. **循环线程**：
   `i1 = phi(i0, i2)`
   ——头节点把
   "入口侧的 i0"
   和"回边侧的 i2"
   焊在一起；
   B4 读 s1
   （出口侧的 φ 结果），
   与循环语义
   严丝合缝；
2. **单定值**：
   `single-def: yes`——
   每个名字
   全程序恰定义一次，
   机器自检；
3. **对账**：
   tac 输出 10
   == ssa 输出 10
   （0+0+1+2+3+4=10），
   变换保义的
   证人证言。

**if.tip 段**：
菱形分支给 b
插 φ：
`b1 = phi(b0, b1')`
式的双参汇合
（具体版本号
  见输出）——
无循环也能
需要 φ，
只要多路径
多定值。

**opt 段**
（expected/opt/）：
`tipa --emit-ir
 phi.tip |
 opt -passes=mem2reg -S`
过滤 phi 行：

```
%s.0 = phi i32 [ 0, %entry ], [ %3, %wh.body ]
%i.0 = phi i32 [ 0, %entry ], [ %4, %wh.body ]
```

与我们手造的
`s1 = phi(s0, s2)`、
`i1 = phi(i0, i2)`
**结构逐字对应**
（[ 0, %entry ]
= 入口侧初值 0；
%3/%4 =
回边侧的新值）。
LLVM 只为
s、i 出 phi
而我们有
t3..t6 的——
修剪 SSA
与朴素 SSA
的差集
就在眼前。

## 41.6 工程注意点

- **SSA 的进出**。
  进
  （本章程）：
  φ 插入 + 改名；
  出
  （若目标机
    不要 SSA）：
  φ 拆成
  前驱块尾的
  并行复制，
  再串行化为
  临时。
  LLVM 后端
  在指令选择前
  做这件事。
- **critical edge**。
  "一个前驱
    有两个后继、
    一个后继有
    两个前驱"的边
  上没法放 φ 的
  拆解复制
  （放前块伤别人，
    放后块没位置）——
  预先**分裂**
  critical edge
  是 SSA 世界的
  标准卫生。
  结构化 TIP
  的模板恰好
  有跳板块
  （goto 弹簧）
  天然消解了
  大多数
  critical edge。
- **φ 的并行性
  在 lowering 时
  咬人**。
  拆 φ 时
  先复制到
  临时再互换，
  否则经典的
  swap 悖论
  （a,b 互换
    变成全等 b）
  上门。
- **版本号的
  确定性**。
  改名按支配树
  先序 + 定序孩子，
  版本号
  可复现——
  期望输出
  可对账的前提。
- **为什么
  LLVM 选 SSA**。
  优化 pass
  的输入输出
  都是显式
  def-use 链；
  mem2reg/
  SCCP/GVN/
  indvars
  全家吃这碗饭。
  第 17 章
  的 alloca/load/store
  形态
  只是 SSA 的
  "进城检查站"。

## 41.7 本章配套文件

### 41.7.1 文法 TIP.g4

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

### 41.7.2 新件：ssa.hpp 与 ssa.cpp

CHK 支配边界、
iterated DF 的
φ 插入、
版本栈改名、
单定值自检、
SSA 解释器。

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

### 41.7.3 支配者基座：dom.hpp 与 dom.cpp

第 40 章原样。

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

### 41.7.4 驱动 main.cpp

--check 全流程、
--emit-ir 供 opt
取材。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 41 章驱动：
//   --check FILE：TAC → 块图 → 支配边界 → SSA（φ 插入 + 改名）→
//                 SSA 打印 → 单定值自检 → SSA 解释 vs TAC 解释对账；
//   --emit-ir FILE：吐 LLVM IR（opt mem2reg 对账的取材口）。
#include "ssa.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "irgen.hpp"

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
    if (argc == 3 && std::string(argv[1]) == "--emit-ir") {
        Parsed p = parseFile(argv[2]);
        tip::IRGen gen;
        gen.gen(*p.ast, p.bindings);
        if (!gen.verify()) {
            std::cerr << "generated module failed verification\n";
            return 1;
        }
        std::cout << gen.dump();
        return 0;
    }
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE | tipa --emit-ir FILE\n";
        return 2;
    }
    Parsed p = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*p.ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    size_t n = blocks.size();

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';

    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    tip::DomInfo di = tip::dominators(adj);
    auto preds = tip::predsOf(adj);
    auto df = tip::dominanceFrontiers(adj, di, preds);
    std::cout << "== dominance frontiers ==\n";
    for (size_t b = 0; b < n; ++b) {
        std::cout << "  DF(B" << b << ") = {";
        bool first = true;
        for (int d : df[b]) {
            std::cout << (first ? "" : ",") << d;
            first = false;
        }
        std::cout << "}\n";
    }

    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA ==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }
    std::cout << "== 单定值自检 ==\n";
    std::cout << "  single-def: " << (ok ? "yes" : "NO") << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> tac = tip::tacInterp(code, {}).outputs;
    std::vector<int> ss = tip::ssaRun(ssa);
    std::cout << "  tac outputs:";
    for (int v : tac) std::cout << ' ' << v;
    std::cout << "\n  ssa outputs:";
    for (int v : ss) std::cout << ' ' << v;
    std::cout << "\n  tac==ssa: " << (tac == ss ? "yes" : "NO") << '\n';
    return (ok && tac == ss) ? 0 : 1;
}
```

### 41.7.5 TAC 基座：tacgen、tacblocks、tacinterp

第 18 章原样。

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

### 41.7.6 执行台：irgen 与 jitrun

第 17 章原样
（--emit-ir 的后端）。

```cpp
// file: src/irgen.hpp
// LLVM IR 生成：把 AST 翻译成 LLVM Module。
// 本章只覆盖整数核心：算术、比较、input/output、if/while、直接函数调用；
// 指针、记录、间接调用在第 53 章以后扩展，遇到时直接报错。
#pragma once

#include <map>
#include <memory>
#include <string>

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

#include "ast.hpp"
#include "symtab.hpp"

namespace tip {

struct IRGen {
    // 三者均以 unique_ptr 持有：JIT 需要接管 Module 与 Context 的所有权。
    std::unique_ptr<llvm::LLVMContext> ctx;
    std::unique_ptr<llvm::Module> mod;
    std::unique_ptr<llvm::IRBuilder<>> b;

    const Bindings *bindings = nullptr;
    const FunDecl *cur = nullptr;
    std::map<const Symbol *, llvm::AllocaInst *> locals;

    IRGen();

    // 生成全部 TIP 函数 + C main（main 改名 tip_main）。
    // 结束后模块必须通过 verify。
    void gen(const ProgramA &program, const Bindings &resolved);

    llvm::Value *expr(const Expr *e);
    void stmt(const Stmt *s);

    bool verify() const;
    std::string dump() const;

  private:
    llvm::FunctionCallee rtInput_, rtOutput_;

    void genFun(const FunDecl *f, Scope *scope);
    void genWrapper(const FunDecl *mainFun);
};

}  // namespace tip
```

```cpp
// file: src/irgen.cpp
#include "irgen.hpp"

#include <stdexcept>
#include <utility>
#include <vector>

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace tip {

IRGen::IRGen()
    : ctx(std::make_unique<LLVMContext>()),
      mod(std::make_unique<Module>("tip", *ctx)),
      b(std::make_unique<IRBuilder<>>(*ctx)) {
    // 运行时入口先声明：input 无参返回 i32，output 吃一个 i32。
    auto *i32 = Type::getInt32Ty(*ctx);
    rtInput_ = mod->getOrInsertFunction(
        "tip_input", FunctionType::get(i32, false));
    rtOutput_ = mod->getOrInsertFunction(
        "tip_output", FunctionType::get(Type::getVoidTy(*ctx), {i32}, false));
}

namespace {

// TIP 的 main 改名 tip_main：真正的 @main 是我们生成的 C 入口。
std::string emitName(const std::string &name) {
    return name == "main" ? "tip_main" : name;
}

}  // namespace

void IRGen::gen(const ProgramA &program, const Bindings &resolved) {
    bindings = &resolved;

    // 先创建全部函数（含类型），函数体互相前向调用时也能查到声明。
    auto *i32 = Type::getInt32Ty(*ctx);
    for (const auto &f : program.funs) {
        std::vector<Type *> args(f->params.size(), i32);
        auto *ft = FunctionType::get(i32, args, false);
        Function::Create(ft, Function::ExternalLinkage,
                         emitName(f->name), *mod);
    }

    for (size_t i = 0; i < program.funs.size(); ++i) {
        const auto &f = program.funs[i];
        cur = f.get();
        genFun(f.get(), resolved.scopes[i].get());
    }

    const FunDecl *mainFun = nullptr;
    for (const auto &f : program.funs)
        if (f->name == "main") mainFun = f.get();
    if (!mainFun) throw std::runtime_error("program has no main");
    genWrapper(mainFun);
}

void IRGen::genFun(const FunDecl *f, Scope *scope) {
    auto *fn = llvm::cast<Function>(mod->getFunction(emitName(f->name)));
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    // 形参：alloca 槽位 + 存入实参；var 局部：alloca + 零初始化。
    for (size_t j = 0; j < f->params.size(); ++j) {
        const Symbol *s = &scope->table.at(f->params[j]);
        auto *slot = b->CreateAlloca(b->getInt32Ty(), nullptr, f->params[j]);
        b->CreateStore(fn->getArg(j), slot);
        locals[s] = slot;
    }
    for (const std::string &v : f->vars) {
        const Symbol *s = &scope->table.at(v);
        auto *slot = b->CreateAlloca(b->getInt32Ty(), nullptr, v);
        b->CreateStore(b->getInt32(0), slot);
        locals[s] = slot;
    }

    stmt(f->body.get());
    b->CreateRet(expr(f->ret->e.get()));
}

Value *IRGen::expr(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e))
        return ConstantInt::get(b->getInt32Ty(), x->v, true);

    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        const Symbol *s = bindings->uses.at(x);
        return b->CreateLoad(b->getInt32Ty(), locals.at(s), x->name);
    }

    if (dynamic_cast<const InputE *>(e))
        return b->CreateCall(rtInput_);

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        Value *l = expr(x->l.get());
        Value *r = expr(x->r.get());
        switch (x->op) {
            case BOp::Add: return b->CreateAdd(l, r);
            case BOp::Sub: return b->CreateSub(l, r);
            case BOp::Mul: return b->CreateMul(l, r);
            case BOp::Div: return b->CreateSDiv(l, r);
            case BOp::Gt: {
                Value *p = b->CreateICmpSGT(l, r);
                return b->CreateZExt(p, b->getInt32Ty());
            }
            case BOp::Eq: {
                Value *p = b->CreateICmpEQ(l, r);
                return b->CreateZExt(p, b->getInt32Ty());
            }
        }
    }

    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        const auto *nameUse = dynamic_cast<const VarRef *>(x->callee.get());
        if (!nameUse)
            throw std::runtime_error("ch17: 间接调用留待第 53 章");
        const Symbol *s = bindings->uses.at(nameUse);
        if (s->kind != Symbol::Fun)
            throw std::runtime_error("ch17: 间接调用留待第 53 章");
        auto *callee = mod->getFunction(emitName(s->name));
        std::vector<Value *> args;
        for (const auto &a : x->args) args.push_back(expr(a.get()));
        return b->CreateCall(callee, args);
    }

    throw std::runtime_error("ch17: 指针与记录构造留待第 53 章");
}

void IRGen::stmt(const Stmt *s) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        const auto *target = dynamic_cast<const VarRef *>(x->target.get());
        if (!target)
            throw std::runtime_error("ch17: 经指针/字段写入留待第 53 章");
        const Symbol *sym = bindings->uses.at(target);
        b->CreateStore(expr(x->value.get()), locals.at(sym));
        return;
    }

    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        b->CreateCall(rtOutput_, {expr(x->e.get())});
        return;
    }

    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *thenBB = BasicBlock::Create(*ctx, "then", fn);
        auto *elseBB = BasicBlock::Create(*ctx, "else", fn);
        auto *mergeBB = BasicBlock::Create(*ctx, "merge", fn);

        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, thenBB, elseBB);

        b->SetInsertPoint(thenBB);
        stmt(x->then.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);

        b->SetInsertPoint(elseBB);
        if (x->els) {
            stmt(x->els.get());
            if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);
        } else {
            b->CreateBr(mergeBB);
        }
        b->SetInsertPoint(mergeBB);
        return;
    }

    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *header = BasicBlock::Create(*ctx, "wh.cond", fn);
        auto *bodyBB = BasicBlock::Create(*ctx, "wh.body", fn);
        auto *exitBB = BasicBlock::Create(*ctx, "wh.exit", fn);

        b->CreateBr(header);
        b->SetInsertPoint(header);
        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, bodyBB, exitBB);

        b->SetInsertPoint(bodyBB);
        stmt(x->body.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(header);

        b->SetInsertPoint(exitBB);
        return;
    }

    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        for (const auto &st : x->ss) stmt(st.get());
        return;
    }

    if (const auto *x = dynamic_cast<const ReturnS *>(s))
        b->CreateRet(expr(x->e.get()));
}

void IRGen::genWrapper(const FunDecl *mainFun) {
    // C 入口：按 TIP main 形参数目读 input，再调用 tip_main。
    // 不命名为 main——MinGW 目标会向 main 注入对 CRT 符号 __main 的调用。
    auto *fn = Function::Create(FunctionType::get(b->getInt32Ty(), false),
                                Function::ExternalLinkage, "tip_entry", *mod);
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    std::vector<Value *> args;
    for (size_t j = 0; j < mainFun->params.size(); ++j)
        args.push_back(b->CreateCall(rtInput_));
    Value *r = b->CreateCall(mod->getFunction("tip_main"), args);
    b->CreateRet(r);
}

bool IRGen::verify() const {
    std::string err;
    llvm::raw_string_ostream os(err);
    bool bad = llvm::verifyModule(*mod, &os);
    os.str();
    return !bad;
}

std::string IRGen::dump() const {
    std::string out;
    llvm::raw_string_ostream os(out);
    mod->print(os, nullptr);
    return os.str();
}

}  // namespace tip
```

```cpp
// file: src/jitrun.hpp
// ORC JIT 执行：把 IRGen 的模块交给 LLJIT，注入 tip_input/tip_output
// 两个宿主 C 函数，真实执行 main，收集输出序列。
#pragma once

#include <vector>

#include "irgen.hpp"

namespace tip {

// 一次执行：inputs 按出现顺序被 tip_input 消费，返回 output 值序列。
// 模块所有权随 IRGen 一起移入 JIT。
std::vector<int> runJit(IRGen gen, const std::vector<int> &inputs);

}  // namespace tip
```

```cpp
// file: src/jitrun.cpp
#include "jitrun.hpp"

#include <cstdint>
#include <stdexcept>

#include "llvm/ExecutionEngine/JITSymbol.h"
#include "llvm/ExecutionEngine/Orc/Core.h"
#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/ExecutionEngine/Orc/ThreadSafeModule.h"
#include "llvm/Support/TargetSelect.h"

using llvm::StringRef;
using llvm::JITSymbolFlags;
using llvm::orc::ExecutorSymbolDef;
using llvm::JITTargetAddress;
using llvm::jitTargetAddressToFunction;
using llvm::pointerToJITTargetAddress;
using llvm::orc::LLJITBuilder;
using llvm::orc::SymbolMap;
using llvm::orc::ThreadSafeModule;
using llvm::orc::absoluteSymbols;

namespace tip {
namespace {

// JIT 模块通过这两个宿主函数与外界交换数据。
const std::vector<int> *inQueue = nullptr;
std::vector<int> *outQueue = nullptr;
size_t inPos = 0;

extern "C" int32_t tip_input() {
    if (inPos >= inQueue->size()) return 0;
    return (*inQueue)[inPos++];
}

extern "C" void tip_output(int32_t value) {
    outQueue->push_back(value);
}

void initNative() {
    // 进程内只初始化一次。
    static const bool ready = [] {
        llvm::InitializeNativeTarget();
        llvm::InitializeNativeTargetAsmPrinter();
        return true;
    }();
    (void)ready;
}

[[noreturn]] void fail(llvm::Error e) {
    std::string text = llvm::toString(std::move(e));
    throw std::runtime_error(text);
}

}  // namespace

std::vector<int> runJit(IRGen gen, const std::vector<int> &inputs) {
    initNative();
    std::vector<int> outputs;
    inQueue = &inputs;
    outQueue = &outputs;
    inPos = 0;

    auto jitOrErr = LLJITBuilder().create();
    if (!jitOrErr) fail(jitOrErr.takeError());
    auto jit = std::move(*jitOrErr);

    auto defineHost = [&](StringRef name, void *addr) {
        SymbolMap symbols;
        symbols[jit->mangleAndIntern(name)] = ExecutorSymbolDef(
            llvm::orc::ExecutorAddr::fromPtr(addr), JITSymbolFlags());
        if (llvm::Error e =
                jit->getMainJITDylib().define(absoluteSymbols(symbols)))
            fail(std::move(e));
    };
    defineHost("tip_input", reinterpret_cast<void *>(&tip_input));
    defineHost("tip_output", reinterpret_cast<void *>(&tip_output));

    ThreadSafeModule tsm(std::move(gen.mod), std::move(gen.ctx));
    if (llvm::Error e = jit->addIRModule(std::move(tsm)))
        fail(std::move(e));

    auto mainAddr = jit->lookup("tip_entry");
    if (!mainAddr) fail(mainAddr.takeError());
    auto *entry = jitTargetAddressToFunction<int (*)()>(mainAddr->getValue());
    entry();

    return outputs;
}

}  // namespace tip
```

### 41.7.7 前端基础件：ast、ast_build、symtab

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

### 41.7.8 程序与期望输出

```text
// file: programs/if.tip
main() {
  var a, b;
  a = 7;
  if (a > 3) b = 1; else b = 2;
  output b + a;
  return 0;
}
```

```text
// file: programs/phi.tip
main() {
  var i, s;
  i = 0;
  s = 0;
  while (5 > i) {
    s = s + i;
    i = i + 1;
  }
  output s;
  return 0;
}
```

```text
; expected: expected/output.txt
== if.tip ==
== TAC ==
  0: t1 = 7
  1: a = t1
  2: t2 = 3
  3: if a > t2 goto L5
  4: goto L8
  5: t3 = 1
  6: b = t3
  7: goto L10
  8: t4 = 2
  9: b = t4
  10: t5 = b + a
  11: output t5
  12: t6 = 0
  13: return t6
== dominance frontiers ==
  DF(B0) = {}
  DF(B1) = {4}
  DF(B2) = {4}
  DF(B3) = {4}
  DF(B4) = {}
== SSA ==
  B0:
    t10 = 7
    a0 = t10
    t20 = 3
    if a0 > t20 goto B2
  B1:
    goto B3
  B2:
    t30 = 1
    b1 = t30
    goto B4
  B3:
    t40 = 2
    b0 = t40
  B4:
    b2 = phi(b1, b0)
    t31 = phi(t30, t3u)
    t41 = phi(t4u, t40)
    t50 = b2 + a0
    output t50
    t60 = 0
    return t60
== 单定值自检 ==
  single-def: yes
== 对账 ==
  tac outputs: 8
  ssa outputs: 8
  tac==ssa: yes
== phi.tip ==
== TAC ==
  0: t1 = 0
  1: i = t1
  2: t2 = 0
  3: s = t2
  4: t3 = 5
  5: if t3 > i goto L7
  6: goto L13
  7: t4 = s + i
  8: s = t4
  9: t5 = 1
  10: t6 = i + t5
  11: i = t6
  12: goto L4
  13: output s
  14: t7 = 0
  15: return t7
== dominance frontiers ==
  DF(B0) = {}
  DF(B1) = {1}
  DF(B2) = {}
  DF(B3) = {1}
  DF(B4) = {}
== SSA ==
  B0:
    t10 = 0
    i0 = t10
    t20 = 0
    s0 = t20
  B1:
    i1 = phi(i0, i2)
    s1 = phi(s0, s2)
    t30 = phi(t3u, t31)
    t40 = phi(t4u, t41)
    t50 = phi(t5u, t51)
    t60 = phi(t6u, t61)
    t31 = 5
    if t31 > i1 goto B3
  B2:
    goto B4
  B3:
    t41 = s1 + i1
    s2 = t41
    t51 = 1
    t61 = i1 + t51
    i2 = t61
    goto B1
  B4:
    output s1
    t70 = 0
    return t70
== 单定值自检 ==
  single-def: yes
== 对账 ==
  tac outputs: 10
  ssa outputs: 10
  tac==ssa: yes
```

```text
; expected: expected/opt/mem2reg.cmd
export PATH=/g/scoop/apps/msys2/current/ucrt64/bin:$PATH
./build/41_ssa/tipa.exe --emit-ir examples/41_ssa/programs/phi.tip | opt -passes=mem2reg -S | grep -E '^\s*%' | grep 'phi' | sed 's/^[[:space:]]*//'
```

```text
; expected: expected/opt/mem2reg.out
%s.0 = phi i32 [ 0, %entry ], [ %3, %wh.body ]
%i.0 = phi i32 [ 0, %entry ], [ %4, %wh.body ]
```

## 41.8 小结与练习

本章给 IR 换了
一套身份证系统：

- φ 在汇合处
  做选择性赋值，
  并行语义是
  安全底线；
- 支配边界 =
  "够得着管不到"，
  CHK 三行算法；
- iterated DF
  定 φ 位，
  版本栈 +
  支配树先序
  完成改名——
  正确性钥匙
  是
  "使用被
   定义点支配"；
- 单定值自检 +
  tac==ssa 对账 +
  opt mem2reg
  结构对照，
  三重验收。

下一章回到
TAC 做块内优化：
DAG 把
基本块折叠成
值图，
公共子表达式
就地消失。

练习：

1. 手工对 phi.tip
   算 DF(B0..B4)，
   与输出对照；
   再按 iterated DF
   复原 φ 位置
   （应为哪些变量？）。
2. 证明版本栈改名的
   正确性
   （归纳：
   处理块 b 时，
   栈顶恰为
   b 处可见的
   最近定值——
   用支配性质）。
3. 给 ssa.cpp 加
   "修剪 SSA"开关：
   插 φ 前检查
   变量是否
   在 DF 块入口
   活跃
   （复用第 36 章
    live 实例），
   重跑 phi.tip
   观察 t3..t6 的
   φ 消失、
   与 LLVM 对账
   完全同形。
4. 实现 φ 的
   拆解
   （SSA →
   非 SSA）：
   在每个前驱
   块尾插并行复制
   （用临时串行化），
   用解释器对账
   往返变换
   （SSA→拆→跑
    == 直接跑）。
5. 构造一个
   critical edge
   的例子
   （提示：
    if 无 else、
    其中一支
    直接进入
    循环头），
   说明为何
   拆 φ 会遇阻、
   边分裂怎么救。
