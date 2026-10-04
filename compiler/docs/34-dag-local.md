# 第 34 章　基本块 DAG：局部公共子表达式与代数化简

## 34.1 问题：一个块内的重复劳动

第 13 章的 TAC
为"每指令一次运算"
付出了啰嗦的代价：

```
t2 = a * a
t3 = a * a      ← 又算了一遍
```

第 26 章的可用表达式
能**报告**这种冗余，
但变换要跨块统筹；
而块内冗余
有更直接的武器：
**基本块 DAG**
（绿龙 12.3、
紫龙 8.5/6.1.2）——
把块的每一次运算
登记进一张值图，
重复运算自然
落到同一个结点上。

DAG 是**局部**优化的
满级形态：
不碰控制流、
不需要迭代不动点、
一遍构造一遍收获。
它与第 33 章的 SSA
遥相呼应
（结点=唯一定值的值、
  多名一结=共享），
工程界的
GVN（全局值编号）
正是两者思想
在全程序尺度的合流。

## 34.2 DAG：把块折叠成值图

**结点**两类：

- **叶**：
  常量
  （或块外流入的
    初始变量值——
    "此刻的 a"）；
- **运算结点**：
  op 加两个孩子指针。

**标签表**：
名字 → 结点。
当前"名字里装着
哪个结点的值"。

构造算法
（逐条扫块内指令）：

```
x = a op b：
    A ← nodeFor(a)，B ← nodeFor(b)
    （取当前绑定；未绑定者落成"流入叶"）
    n ← 已有 (op, A, B) 结点？有则复用（CSE 命中），
       没有则新建
    x 的标签改挂 n
x = y：
    x 的标签改挂 y 当前绑定的结点
    （复制在 DAG 里天然消失）
```

两个关键细节：

1. **取数走当前绑定**。
   `t1 = input; a = t1`
   之后 nodeFor(a)
   给的是 t1 绑定的结点，
   不是新造的"a 叶"——
   Copy 由此穿透，
   名字的搬运在图里
   不产生任何结点；
2. **交换律规范键**。
   `a + b` 与 `b + a`
   在建 (op, A, B) 前
   把孩子按编号排序——
   交换律成立才允许，
   减法除法不许。
   规范键让
   "看起来不同"的
   重复无可遁形。

期望输出里
cse.tip 的
明星结点：

```
n1 = *  kids(0,0) labels: t2 t3 t5 x
```

**四个名字挂一个结点**：
源程序里 `a * a`
写了三遍
（b 的两个加数、x），
DFA 之后它们
是同一个值——
公共子表达式
不是被"检测"出来，
是被"登记"出来。

## 34.3 代数恒等式：构造期的折叠

运算结点创建前
先过一张恒等式表
（绿龙 12.4 的精选）：

```
x + 0 → x        0 + x → x
x − 0 → x
x × 1 → x        1 × x → x
x × 0 → 0        0 × x → 0
x ÷ 1 → x
c1 + c2 → c      c1 × c2 → c
```

命中即不建结点，
直接绑定右（或左）
操作数的结点
（x×0 直取常量 0 叶）。
两张常量折叠规则
（c₁+c₂、c₁×c₂）
让纯常量子表达式
在块内彻底蒸发。

algebra.tip 的现场：

```
v = u * 1 + u * 0
```

三连命中
（u×1→u、
 u×0→0、
 u+0→u），
发射结果：

```
0: t1 = input
1: u = t1
2: v = t1
3: output t1
4: return 0
```

`v = t1`——
v 与 u、t1
全指着同一个结点；
11 条指令
缩成 5 条，
`algebraHits = 3`。

恒等式的正确性
按整数语义逐条成立；
除法对 0 的例外
（x/0 不能折）
提醒我们：
**每条恒等式都是
一条编译器必须
替语义背书的定理**。

## 34.4 死结点与重发射

构造完的 DAG
是一张"块内值谱"。
重发射三步：

1. **定根**：
   仍有标签的结点
   全是根；
   从根向下标记
   可达结点——
   不可达的运算结点
   （算出来没人用）
   不发射，
   **局部死代码
   顺带消失**；
2. **拓扑序发射**：
   结点数组按
   创建序天然拓扑
   （孩子先于父亲）。
   每个运算结点发射
   `代表名 = 左 op 右`；
   结点上的**额外**
   标签各补一条复制
   `别名 = 代表名`；
3. **收尾**：
   块尾的跳转、
   output、return
   原样接回，
   操作数若引用
   被剪掉的绑定，
   改写为其叶
   （`return t7`
    变 `return 0`）。

**input 前置**：
input 有副作用，
不进值图；
发射时统一放到
块首——
块内 TAC 的
定义先于使用
保证前置安全。

**t 系临时的特赦**：
重发射只给
**非临时名字**
补叶绑定复制——
t 系是表达式草稿
（tacgen 一条语句内
  生灭），
块外无读者，
死绑定不补是
"局部优化没有
全局活跃信息"
的现实里
唯一稳赚的一刀。
真正的全局版
（哪个名字块后
还有人用）
要等活跃分析
（第 25 章）
来发通行证——
那是 GVN 的
组合方式。

## 34.5 期望输出解读

**cse.tip 段**：
构造统计
`nodes=5 labels=11 cseHits=2`；
n1（a×a）四标签、
n2/n3 加法结点
各双标签。
重发射：

```
0: t1 = input
1: t2 = t1 * t1     ← a*a 只此一处
2: t3 = t2          ← 后续全部改为共享
3: t5 = t2
4: x = t2
5: t4 = t2 + t2
6: b = t4
7: t6 = t2 + t4
8: y = t6
9: a = t1
10: output y
11: return 0
```

13 → 12 条：
省下的是两次乘法
（13 条原指令里
  a*a 有三条），
换来几条复制——
**净收益在真实机器上
更大**：
乘法多周期、
复制常零开销
（寄存器重命名即可）。
对账：
outputs 27
（3×3+3×3=18、
 x=9、
 18+9=27）前后一致。

**algebra.tip 段**：
34.3 已逐行读。
值得再看的
是 `output t1`——
output 的操作数
本来是 v，
经绑定链
v→u→t1，
直接落到叶 t1：
**引用链的压缩**
是 DAG 送的
又一份小礼。

## 34.6 工程注意点

- **DAG 与 SSA
  是同一家族**。
  结点 = 值的唯一身份；
  标签 = 名字。
  SSA 把这件事
  做到全程序，
  DAG 只在块内。
  GVN（全局值编号）
  用哈希规范键
  （op + 值编号孩子）
  把"同值同结点"
  推广到支配树全域——
  LLVM 的
  early-cse/gvn
  就是它的工程化。
- **规范键的选取**。
  交换律只是开始：
  结合律
  （(a+b)+c ↔ a+(b+c)）
  需要"表达式树"
  而非二元结点；
  对取整环上的
  x×0、x−x 等
  "零化恒等式"
  要防浮点 NaN
  推翻
  （x−x 在浮点下
    可能是 NaN 而非 0）——
  我们的整数世界
  暂时免俗。
- **重发射的自由度**。
  同一张 DAG
  有多种发射序
  （拓扑序不唯一）；
  调度压力、
  寄存器压力
  （第 43/45 章）
  会反过来挑顺序——
  本章按创建序
  发射，
  确定性优先。
- **副作用结点**。
  input/call 这类
  不可折叠指令
  必须保持相对顺序。
  本章的"input 前置"
  是块内安全的
  特例；
  通用规则是
  在 DAG 里给它们
  建有序的
  "屏障结点"。
- **局部最优的边界**。
  跨块的 a×a
  （先算后跳）
  DAG 无能为力——
  那是
  可用表达式+搬移
  （第 26 章）
  或 PRE
  （第 36 章）的
  领地。
  各章武器射程
  如此分界：
  块内看 DAG，
  全程看数据流。

## 34.7 本章配套文件

### 34.7.1 文法 TIP.g4

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

### 34.7.2 新件：dag.hpp 与 dag.cpp

结点/标签模型、
恒等式表、
死结点剔除、
重发射
（input 前置、
  收尾改写）。

```cpp
// file: src/dag.hpp
// file: src/dag.hpp
// 第 34 章配套：基本块 DAG——局部公共子表达式、代数恒等式、死节点剔除、重发射。
// 结点 = 叶（常量/名字）或运算（op + 孩子指针）；名字标签表把名字绑到结点。
// 多个名字绑同一结点 = 公共子表达式的机器证据。
#ifndef TIP_DAG_HPP
#define TIP_DAG_HPP

#include <map>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

struct DagNode {
    bool isLeaf = true;
    std::string leaf;                 // 叶：常量串或变量名
    TOp op = TOp::Copy;               // 运算结点
    int kid0 = -1, kid1 = -1;         // 孩子下标
    std::vector<std::string> labels;  // 绑定的名字（首个为代表名）
};

struct DagResult {
    std::vector<DagNode> nodes;
    std::map<std::string, int> labelOf;    // 名字 → 结点（当前绑定）
    int algebraHits = 0;                   // 代数恒等式命中次数
    int cseHits = 0;                       // 结点复用（含多标签）次数
};

// 构造一个块的 DAG（块尾跳转/输出/返回的引用作为根登记）。
DagResult dagBuild(const std::vector<Quad> &code, const Block &b);

// 重发射：按拓扑序输出“够用”的指令——只发射有标签或被引用的结点；
// 额外标签用复制绑定。返回新指令序列（不含块尾跳转，跳转原样接回）。
std::vector<Quad> dagEmit(const DagResult &dag, const std::vector<Quad> &code,
                          const Block &b);

}  // namespace tip

#endif  // TIP_DAG_HPP
```

```cpp
// file: src/dag.cpp
// file: src/dag.cpp
// 第 34 章配套：DAG 构造与重发射实现。
#include "dag.hpp"

#include <cctype>
#include <set>

namespace tip {

namespace {
bool isNumD(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool commutative(TOp op) {
    return op == TOp::Add || op == TOp::Mul || op == TOp::Eq;
}
}  // namespace

DagResult dagBuild(const std::vector<Quad> &code, const Block &b) {
    DagResult d;
    auto newLeaf = [&](const std::string &s) {
        DagNode n;
        n.isLeaf = true;
        n.leaf = s;
        d.nodes.push_back(n);
        return static_cast<int>(d.nodes.size()) - 1;
    };
    auto leafFor = [&](const std::string &s) {
        for (int k = 0; k < static_cast<int>(d.nodes.size()); ++k)
            if (d.nodes[k].isLeaf && d.nodes[k].leaf == s) return k;
        return newLeaf(s);
    };
    // 取数走“当前绑定”：名字 → 它绑定的结点（Copy 由此穿透到值）；
    // 未绑定的名字（块外进来的值）才落成新叶。
    auto nodeFor = [&](const std::string &s) {
        if (isNumD(s)) return leafFor(s);
        auto it = d.labelOf.find(s);
        if (it != d.labelOf.end()) return it->second;
        return leafFor(s);
    };
    auto findOrCreate = [&](TOp op, int a, int bb) {
        for (int k = 0; k < static_cast<int>(d.nodes.size()); ++k) {
            const auto &n = d.nodes[k];
            if (!n.isLeaf && n.op == op && n.kid0 == a && n.kid1 == bb) {
                ++d.cseHits;
                return k;
            }
        }
        DagNode n;
        n.isLeaf = false;
        n.op = op;
        n.kid0 = a;
        n.kid1 = bb;
        d.nodes.push_back(n);
        return static_cast<int>(d.nodes.size()) - 1;
    };
    auto bind = [&](const std::string &name, int node) {
        auto it = d.labelOf.find(name);
        if (it != d.labelOf.end()) {
            // 旧绑定解除：把名字从旧结点的标签里摘掉（重定义）
            auto &old = d.nodes[it->second].labels;
            for (auto x = old.begin(); x != old.end();)
                if (*x == name) x = old.erase(x);
                else ++x;
        }
        d.labelOf[name] = node;
        d.nodes[node].labels.push_back(name);
    };
    // 结点取值表达式（代数恒等式的判定基础）：
    // 叶且是常量 → 值；否则无。
    auto constOf = [&](int k, int *val) {
        if (!d.nodes[k].isLeaf) return false;
        if (!isNumD(d.nodes[k].leaf)) return false;
        *val = std::atoi(d.nodes[k].leaf.c_str());
        return true;
    };
    for (int i = b.begin; i < b.end; ++i) {
        const Quad &q = code[i];
        switch (q.op) {
        case TOp::Copy: {
            bind(q.dst, nodeFor(q.a));
            break;
        }
        case TOp::Input: {
            // input 有副作用：不折叠成纯值叶；名字绑到“自身名叶”，
            // 让 a = t1 这类复制把 input 结果引下去（发射时 input 前置）。
            bind(q.dst, leafFor(q.dst));
            break;
        }
        case TOp::Add: case TOp::Sub: case TOp::Mul:
        case TOp::Div: case TOp::Gt: case TOp::Eq: {
            int lhs = nodeFor(q.a), rhs = nodeFor(q.b);
            // 交换律规范键：小的孩子下标在左，a+b 与 b+a 同结点
            if (commutative(q.op) && lhs > rhs) std::swap(lhs, rhs);
            // 代数恒等式（绿龙 12.4 的一小张表）：
            int lv = 0, rv = 0;
            bool lc = constOf(lhs, &lv), rc = constOf(rhs, &rv);
            int result = -1;
            if (q.op == TOp::Add && lc && lv == 0) { result = rhs; ++d.algebraHits; }
            else if (q.op == TOp::Add && rc && rv == 0) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && lc && lv == 1) { result = rhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && rc && rv == 1) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && (lc && lv == 0)) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Mul && (rc && rv == 0)) { result = rhs; ++d.algebraHits; }
            else if (q.op == TOp::Sub && rc && rv == 0) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Div && rc && rv == 1) { result = lhs; ++d.algebraHits; }
            else if (q.op == TOp::Add && lc && rc) {
                DagNode n;
                n.isLeaf = true;
                n.leaf = std::to_string(lv + rv);
                d.nodes.push_back(n);
                result = static_cast<int>(d.nodes.size()) - 1;
                ++d.algebraHits;
            }
            else if (q.op == TOp::Mul && lc && rc) {
                DagNode n;
                n.isLeaf = true;
                n.leaf = std::to_string(lv * rv);
                d.nodes.push_back(n);
                result = static_cast<int>(d.nodes.size()) - 1;
                ++d.algebraHits;
            }
            if (result < 0) result = findOrCreate(q.op, lhs, rhs);
            bind(q.dst, result);
            break;
        }
        default:
            break;   // 跳转/输出/返回：根引用在 emit 时登记
        }
    }
    return d;
}

std::vector<Quad> dagEmit(const DagResult &dag, const std::vector<Quad> &code,
                          const Block &b) {
    // 根：块尾跳转/输出/返回引用的操作数（保活），加上全部仍有标签的名字。
    std::set<int> live;
    for (const auto &kv : dag.labelOf) live.insert(kv.second);
    // 从根向下标记可达结点
    std::set<int> keep = live;
    std::vector<int> stack(live.begin(), live.end());
    while (!stack.empty()) {
        int k = stack.back();
        stack.pop_back();
        if (dag.nodes[k].isLeaf) continue;
        for (int kid : {dag.nodes[k].kid0, dag.nodes[k].kid1})
            if (kid >= 0 && !keep.count(kid)) {
                keep.insert(kid);
                stack.push_back(kid);
            }
    }
    // 拓扑序：结点数组天然按创建序，孩子先于父亲（构造保证），正向扫即可。
    std::vector<Quad> out;
    for (int k = 0; k < static_cast<int>(dag.nodes.size()); ++k) {
        if (!keep.count(k) || dag.nodes[k].isLeaf) continue;
        const auto &n = dag.nodes[k];
        Quad q;
        q.op = n.op;
        q.dst = n.labels.empty() ? "d" + std::to_string(k) : n.labels.front();
        q.a = dag.nodes[n.kid0].isLeaf ? dag.nodes[n.kid0].leaf
                                       : (!dag.nodes[n.kid0].labels.empty()
                                              ? dag.nodes[n.kid0].labels.front()
                                              : "d" + std::to_string(n.kid0));
        q.b = dag.nodes[n.kid1].isLeaf ? dag.nodes[n.kid1].leaf
                                       : (!dag.nodes[n.kid1].labels.empty()
                                              ? dag.nodes[n.kid1].labels.front()
                                              : "d" + std::to_string(n.kid1));
        out.push_back(q);
        // 额外标签：复制绑定
        for (size_t li = 1; li < n.labels.size(); ++li)
            out.push_back(Quad{TOp::Copy, n.labels[li], n.labels.front(), "", -1});
    }
    // 名字绑定到叶（常量/变量）的：以复制形式补发射（保持名字语义）。
    // t 系临时是块内草稿（tacgen 的表达式暂存），块外无读者，死绑定不补——
    // 这是“局部优化无全局活跃信息”下的保守规则里唯一安全的一刀。
    for (const auto &kv : dag.labelOf) {
        const auto &n = dag.nodes[kv.second];
        if (n.isLeaf && n.leaf != kv.first && kv.first[0] != 't')
            out.push_back(Quad{TOp::Copy, kv.first, n.leaf, "", -1});
    }
    // input 前置（副作用先行，定义先于使用），控制流/IO 收尾（它们不是值结点）。
    // 收尾指令引用死临时（如 return t7）时，把操作数改写为其绑定的叶。
    auto rewriteOperand = [&](std::string &x) {
        auto it = dag.labelOf.find(x);
        if (it != dag.labelOf.end() && dag.nodes[it->second].isLeaf)
            x = dag.nodes[it->second].leaf;
    };
    std::vector<Quad> inputs, tail;
    for (int i = b.begin; i < b.end; ++i) {
        Quad q = code[i];
        if (q.op == TOp::Input) {
            inputs.push_back(q);
        } else if (q.op == TOp::Output || q.op == TOp::Ret) {
            rewriteOperand(q.a);
            tail.push_back(q);
        } else if (q.op == TOp::IfGt || q.op == TOp::IfEq) {
            rewriteOperand(q.a);
            rewriteOperand(q.b);
            tail.push_back(q);
        } else if (q.op == TOp::Goto) {
            tail.push_back(q);
        }
    }
    out.insert(out.begin(), inputs.begin(), inputs.end());
    out.insert(out.end(), tail.begin(), tail.end());
    return out;
}

}  // namespace tip
```

### 34.7.3 驱动 main.cpp

逐块构造与发射、
统计、对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 34 章驱动：--check FILE
//   TAC → 逐块 DAG（结点/标签/命中统计）→ 重发射 → 指令数对账 → 解释器 outputs 对账。
#include "dag.hpp"
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

    // 逐块建 DAG、重发射，拼回新程序
    std::vector<tip::Quad> rebuilt;
    int algebra = 0, cse = 0;
    for (const auto &b : blocks) {
        tip::DagResult d = tip::dagBuild(code, b);
        algebra += d.algebraHits;
        cse += d.cseHits;
        std::cout << "== DAG B" << b.id << " ==\n";
        std::cout << "  nodes=" << d.nodes.size() << " labels=" << d.labelOf.size()
                  << " algebraHits=" << d.algebraHits << " cseHits=" << d.cseHits << '\n';
        for (size_t k = 0; k < d.nodes.size(); ++k) {
            const auto &n = d.nodes[k];
            if (n.isLeaf) continue;
            std::cout << "    n" << k << " = " << tip::show(tip::Quad{n.op, "", "", "", -1})
                      << " kids(" << n.kid0 << "," << n.kid1 << ") labels:";
            for (const auto &l : n.labels) std::cout << ' ' << l;
            std::cout << '\n';
        }
        std::vector<tip::Quad> part = tip::dagEmit(d, code, b);
        rebuilt.insert(rebuilt.end(), part.begin(), part.end());
    }

    std::cout << "== after DAG ==\n";
    for (size_t i = 0; i < rebuilt.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(rebuilt[i]) << '\n';

    std::cout << "== stats ==\n";
    std::cout << "  instructions: " << code.size() << " -> " << rebuilt.size() << '\n';
    std::cout << "  algebraHits = " << algebra << "  cseHits = " << cse << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::tacInterp(code, {3}).outputs;   // input 喂 3
    std::vector<int> after = tip::tacInterp(rebuilt, {3}).outputs;
    std::cout << "  outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before == after ? "yes" : "NO") << '\n';
    return (before == after && rebuilt.size() <= code.size()) ? 0 : 1;
}
```

### 34.7.4 基座：tacgen、tacblocks、tacinterp 与前端

第 13、8、10 章原样。

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

### 34.7.5 程序与期望输出

```text
// file: programs/algebra.tip
main() {
  var u, v;
  u = input;
  v = u * 1 + u * 0;
  output v;
  return 0;
}
```

```text
// file: programs/cse.tip
main() {
  var a, b, x, y;
  a = input;
  b = a * a + a * a;
  x = a * a;
  y = b + x;
  output y;
  return 0;
}
```

```text
; expected: expected/output.txt
== algebra.tip ==
== TAC ==
  0: t1 = input
  1: u = t1
  2: t2 = 1
  3: t3 = u * t2
  4: t4 = 0
  5: t5 = u * t4
  6: t6 = t3 + t5
  7: v = t6
  8: output v
  9: t7 = 0
  10: return t7
== DAG B0 ==
  nodes=3 labels=9 algebraHits=3 cseHits=0
== after DAG ==
  0: t1 = input
  1: u = t1
  2: v = t1
  3: output t1
  4: return 0
== stats ==
  instructions: 11 -> 5
  algebraHits = 3  cseHits = 0
== 对账 ==
  outputs: 3
  outputs preserved: yes
== cse.tip ==
== TAC ==
  0: t1 = input
  1: a = t1
  2: t2 = a * a
  3: t3 = a * a
  4: t4 = t2 + t3
  5: b = t4
  6: t5 = a * a
  7: x = t5
  8: t6 = b + x
  9: y = t6
  10: output y
  11: t7 = 0
  12: return t7
== DAG B0 ==
  nodes=5 labels=11 algebraHits=0 cseHits=2
    n1 =  =  *  kids(0,0) labels: t2 t3 t5 x
    n2 =  =  +  kids(1,1) labels: t4 b
    n3 =  =  +  kids(1,2) labels: t6 y
== after DAG ==
  0: t1 = input
  1: t2 = t1 * t1
  2: t3 = t2
  3: t5 = t2
  4: x = t2
  5: t4 = t2 + t2
  6: b = t4
  7: t6 = t2 + t4
  8: y = t6
  9: a = t1
  10: output y
  11: return 0
== stats ==
  instructions: 13 -> 12
  algebraHits = 0  cseHits = 2
== 对账 ==
  outputs: 27
  outputs preserved: yes
```

## 34.8 小结与练习

本章把块的
重复劳动登记成图：

- DAG 结点 = 值，
  标签 = 名字，
  Copy 穿透、
  交换律规范键，
  公共子表达式
  在登记处现形；
- 恒等式表
  在建点前折叠
  （含常量运算），
  每条恒等式都是
  编译器替语义
  背书的定理；
- 不可达结点
  不发射，
  局部死代码
  顺带清场；
  重发射的
  input 前置与
  收尾改写
  是副作用与
  死绑定的
  两处卫生。

下一章把优化
推上循环：
不变式外提、
归纳变量、
强度削减——
分析家族的
火力终于
对准了
程序里
最热的那
一段。

练习：

1. 手工构造
   cse.tip 的 DAG，
   列出全部结点
   与标签变迁
   （逐指令），
   与输出的
   n1/n2/n3 对照。
2. 加恒等式
   `x − x → 0` 与
   `x ÷ x → 1`
   （提示后者要防
    x=0 的除零——
    所以它其实
    **不**成立，
    解释为什么，
    并写出一个
    反例输入）。
3. 给发射加
   "复制合并"：
   连续的
   `t3 = t2; x = t2`
   可并成对同一
   代表名的
   多名绑定，
   观察指令数
   进一步下降。
4. 把 cse.tip 改成
   a×a 出现在
   两个**不同块**
   （if 的两侧），
   重跑并解释
   为什么 DAG
   无能为力、
   哪一章的武器
   能接手。
5. （承 34.6）
   陈述浮点语义下
   哪些整数恒等式
   失效
   （至少三条），
   并说明
   "每条折叠规则
    都要标注
    语义前提"
   的工程含义。
