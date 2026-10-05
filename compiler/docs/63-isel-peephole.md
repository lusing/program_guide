# 第 63 章　指令选择与窥孔：从 IR 到汇编的最后一级

## 63.1 问题：同一棵树，多种拼法

寄存器分好了
（第 61 章），
最后一问：
TAC 的运算
换成**哪几条**
机器指令？

```
z = y * 1 + 11
```

至少三种拼法：

```
A: loadi r1 1        B: （什么都不发）    C: loadi r1 11
   mul  r0 y,r1          ...                mov  r0 y
   loadi r2 11                               add  r0 r0,r1
   add  r0 r0,r2
```

B 最优（乘一免费）、
A 最笨。
**指令选择**
（instruction
selection）
就是在
机器指令集的
"拼图库"里
给表达式树
挑一套
代价最小的覆盖。

本章武器两件
（绿龙 15.3/15.7、
紫龙 8.9/8.7）：

- **树覆盖 /
  maximal munch**：
  把指令集看成
  "瓦片"（tile）
  的集合，
  贪心地用
  大瓦片盖树；
- **窥孔优化**：
  选完再扫一遍，
  局部模式重写
  到不动点——
  兜底的安全网。

配套示例
`examples/63_isel_peephole`
把 TAC 的
临时链重新
长成表达式树、
打 Ershov 标号、
瓦片覆盖到
一台八指令的
迷你 RISC、
窥孔清扫、
最后用
RISC 解释器
与 TAC 解释器
对账。

## 63.2 树重建：把临时链长回去

tacgen（第 18 章）
把表达式
拆成临时链；
指令选择
要的是**树**
——先长回去。

规则：
临时 t 若在
块内**恰好
被用一次**，
它的定义
就"融进"
使用处；
命名变量
（用户声明的）
永远是叶子
（它们的名字
  是对外接口，
  不许融化）。
`x = 2*3+4`
的长回：

```
op +  [E2]
    op *  [E2]
        const 2
        const 3
    const 4
```

每个节点旁的
**E 标号**是
Ershov 数
（紫龙 8.10）：

> 求值该子树
> 所需的最少
> 寄存器数。

递归式：
叶子 E=1；
`E(node) =
两孩子相等 ?
E+1 :
max(E_l, E_r)`
——一边算着，
另一边占着
一个寄存器
等结果，
相等时
天平加一格，
不等时
宽者为主。
`x` 的树 E2
（`+` 下挂
  乘法与常量：
  乘要 2 格，
  常量 1 格，
  不等取宽）；
`z` 的树 E3
（两侧都是 E2）。
E 标号是
第 61 章
分配器的
**天然上限**：
树的着色
不可能需要
超过
Ershov 数的
盒子。

## 63.3 迷你 RISC 与瓦片库

目标机
八条指令
（够教学、
  不失真）：

```
loadi rD imm        装立即数
mov   rD rS         寄存器间搬运
add/sub/mul/div     二元（rD, rA,rB）
gt/eq               比较（产 0/1）
output rS           输出
```

**瓦片**
= 树的局部形状
+ 生成它的指令
+ 代价。
本章瓦片库
（精选三档）：

| 瓦片 | 形状 | 发射 | 代价 |
|---|---|---|---|
| 常量折叠 | `c1 op c2` | `loadi rD 结果` | 1 |
| 叶子 | `const c` | `loadi rD c` | 1 |
| 一般二元 | `l op r` | 左右递归 + `op rD,…` | 1+子 |

**maximal munch**
（贪心覆盖）：
在树根先试
**最大**的瓦片
——常量折叠
整棵吞掉
`2*3`、`5+6`；
命中即发射、
不再下钻；
不中再试小的。

期望输出里
两发命中
（瓦片 [loadi …]）：
`2*3` 折成
`loadi r0 6`、
`5+6` 折成
`loadi r7 11`——
**编译期就算完**，
运行期一指令。

**注意一条
刻意的缺席**：
`x+0`、`y*1`
的恒等瓦片
**不设**——
它们会被
选成
`loadi r 0;
 add …,r`，
留给窥孔
去扫。
这是分工的
教学示范：
瓦片管
**结构选择**
（哪种指令形），
窥孔管
**局部垃圾**
（选完留下的
  可简化序列）；
真实编译器
两者都做、
边界同样模糊
（SelectionDAG
  的合并pass
  一锅端）。

## 63.4 Ershov 的求值序

有了树，
生成代码的
**顺序**：
经典 Sethi–Ullman
（Ershov 的
  代码化）：
先评 E 大的
孩子——
它需要更多
寄存器，
先算先释放；
后算的孩子
结果留在
寄存器里
直接当
运算的右元。
本章实现
简化为
"左右固定序"，
E 标号作为
**需求预报**
打印在树上——
它是
寄存器压力的
静态画像，
第 61 章
分配器的输入。

## 63.5 窥孔：局部模式重写的安全网

**窥孔优化**
（peephole）：
透过一个
只有几条指令的
"窥孔"看代码，
模式匹配、
局部重写、
反复扫描
直到不动点。

本章模式表
（绿龙 15.7、
紫龙 8.7 的
教学子集）：

```
p1  mov rX rX                → 删除（自复制）
p2  loadi rX 0 ; add rD A,rX → mov rD A（加零）
p3  loadi rX 1 ; mul rD A,rX → mov rD A（乘一）
```

期望输出：
两条命中
（pattern add-0 ×1、
  mul-1 ×1），
14 → 12 条。

模式重写的
**安全性**
要逐条论证：
p2/p3 依赖
"rX 装的是
  0/1 且此后
  只被这一条
  用"——
严格版要查
rX 的后续使用
（我们的小程序
  天然满足；
  通用窥孔
  配合死代码
  信息）。
经典的
模式族还有：
冗余
load/store 对、
跳到跳转
（jump-to-jump
  链条缩短）、
强度削减
（乘 2 → 左移）、
机器习语
（lea 代加）。
共同点：
**局部、
廉价、
幂等**
——扫到
不动点为止，
每轮只做
"明确更优"
的重写。

## 63.6 期望输出解读

expr.tip 段
四部曲：

1. **树**：
  x 的树
  （E2，含折叠
    候选 2\*3）、
  y 的树
  （x + 0——
    恒等候选
    刻意留给
    窥孔）、
  z 的树
  （E3 双侧）；
2. **选择**：
  `loadi r0 6`
  （瓦片吞掉
    2\*3）+ … +
  `loadi r3 0;
   add r4 x,r3`
  （+0 未吞，
    留给窥孔）…；
3. **窥孔**：
  add-0 把
  `loadi r3 0;
   add r4 x,r3`
  折成
  `mov r4 x`、
  mul-1 同款；
4. **对账**：
  14→12 条、
  tac outputs
  21 10 ==
  risc outputs
  21 10——
  **两级解释器
    逐值相等**，
  从 TAC 到
  汇编的语义
  交接有证人。

## 63.7 工程注意点

- **瓦片库的
  完备与最优**。
  maximal munch
  贪心不保证
  全局最优
  （树dp/
    dynamic
    programming
    版可以，
    紫龙 8.11）；
  真实指令集
  （x86 的
    寻址模式
    组合爆炸）
  用自动生成
  的瓦片库
  （Burg/IBurg
    一族）。
- **窥孔的
  幂等与终止**。
  每条模式
  严格减指令数
  或减代价
  ⇒ 不动点必达；
  会"搬动"
  指令的模式
  要小心环
  （A 改成 B、
    B 又改成 A）。
- **窥孔与
  分配的次序**。
  窥孔在
  分配前扫
  IR 层（模式多）、
  分配后再扫
  机器层
  （load/store
    对、
    move 合并）；
  两层都有
  收益。
- **解释器
  即模拟器**。
  riscRun 用
  map 当寄存器
  堆——
  真实的
  交叉验证
  应该是
  qemu/真机，
  但对教学 ISA，
  一个 30 行的
  直线解释器
  就是足够
  忠实的
  证人。
- **为什么不
  直接从 AST
  选指令**：
  可以
  （编译器史
    早期如此），
  但 IR 层的
  优化
  （18–48 章）
  已经把树
  整理过；
  从 TAC 重建
  的树带着
  全部优化
  成果。

## 63.8 本章配套文件

### 63.8.1 文法 TIP.g4

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

### 63.8.2 新件：isel.hpp 与 isel.cpp

树重建（Copy
  穿透、
  独占临时融合）、
Ershov 标号、
maximal munch、
窥孔三模式、
RISC 解释器。

```cpp
// file: src/isel.hpp
// file: src/isel.hpp
// 第 63 章配套：指令选择（树覆盖 + Ershov 标号）与窥孔优化。
#ifndef TIP_ISEL_HPP
#define TIP_ISEL_HPP

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

struct TreeNode {
    char kind = 'v';       // 'c' 常量 / 'v' 变量名 / 'o' 运算
    int value = 0;
    std::string name;
    TOp op = TOp::Copy;
    std::unique_ptr<TreeNode> l, r;
    int ershov = 0;        // Ershov 标号：求值所需最少寄存器
    std::string result;    // munch 后的结果寄存器
};

struct Tree {
    std::string dst;
    TreeNode root;
};

// 重建表达式树（临时独占使用 → 融合），只对“根”（结果交给命名变量）建树。
std::vector<Tree> fuseTrees(const std::vector<Quad> &code, const Block &b);

int ershov(TreeNode &n);

struct Risc {
    std::string mnemonic, rd, rs;
    int target = -1;
};

std::vector<Risc> munchTree(TreeNode &n, std::vector<std::string> &notes);
std::string showRisc(const Risc &r);

std::pair<std::vector<Risc>, std::map<std::string, int>> peephole(std::vector<Risc> in);

std::vector<int> riscRun(const std::vector<Risc> &code);

}  // namespace tip

#endif  // TIP_ISEL_HPP
```

```cpp
// file: src/isel.cpp
// file: src/isel.cpp
// 第 63 章配套：表达式树重建、Ershov 标号、maximal munch 指令选择、
// 迷你 RISC、窥孔清扫、RISC 解释器。
#include "isel.hpp"

#include <cctype>
#include <map>
#include <sstream>
#include <stdexcept>

namespace tip {

namespace {
bool isNumI(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarI(const std::string &s) { return !s.empty() && !isNumI(s); }
}  // namespace

// ---------- 树重建：把“临时只在下一处使用”的链重新长成树 ----------
std::vector<Tree> fuseTrees(const std::vector<Quad> &code, const Block &b) {
    // 使用计数（块内）
    std::map<std::string, int> uses;
    for (int i = b.begin; i < b.end; ++i) {
        if (isVarI(code[i].a)) ++uses[code[i].a];
        if (isVarI(code[i].b)) ++uses[code[i].b];
    }
    std::map<std::string, int> defAt;   // 名字 → 定义行（块内）
    for (int i = b.begin; i < b.end; ++i)
        if (!code[i].dst.empty()) defAt[code[i].dst] = i;
    // 递归取节点：叶子（常量/外部名）或独占定义的子树
    std::function<bool(const std::string &, int, TreeNode &)> grab =
        [&](const std::string &name, int before, TreeNode &out2) {
            if (isNumI(name)) {
                out2.kind = 'c';
                out2.value = std::atoi(name.c_str());
                return true;
            }
            auto it = defAt.find(name);
            if (it == defAt.end() || it->second >= before) {
                out2.kind = 'v';
                out2.name = name;
                return true;   // 外部流入（或定义在使用之后——按叶子处理，正常不出现）
            }
            int d = it->second;
            // 独占条件：块内只被用一次、且是临时
            if (name[0] != 't' || uses[name] != 1) {
                out2.kind = 'v';
                out2.name = name;
                return true;
            }
            const Quad &q = code[d];
            if (q.op == TOp::Copy) {
                // Copy 在链中同样穿透（ munch 不该见到单孩子节点）
                return grab(q.a, d, out2);
            }
            out2.kind = 'o';
            out2.op = q.op;
            TreeNode l, r;
            if (!grab(q.a, d, l)) return false;
            if (!grab(q.b, d, r)) return false;
            out2.l = std::make_unique<TreeNode>(std::move(l));
            out2.r = std::make_unique<TreeNode>(std::move(r));
            return true;
        };
    std::vector<Tree> out;
    // 从“定义行”直接建节点（Copy 穿透到源），供根与 grab 共用
    std::function<bool(int, TreeNode &)> grabAt = [&](int d, TreeNode &out2) {
        const Quad &q = code[d];
        if (q.op == TOp::Copy) return grab(q.a, d, out2);   // Copy 在根处穿透
        out2.kind = 'o';
        out2.op = q.op;
        TreeNode l, r;
        if (!grab(q.a, d, l)) return false;
        if (!grab(q.b, d, r)) return false;
        out2.l = std::make_unique<TreeNode>(std::move(l));
        out2.r = std::make_unique<TreeNode>(std::move(r));
        return true;
    };
    (void)grabAt;
    for (int i = b.begin; i < b.end; ++i) {
        const Quad &q = code[i];
        if (q.op != TOp::Copy && q.op != TOp::Add && q.op != TOp::Sub &&
            q.op != TOp::Mul && q.op != TOp::Div && q.op != TOp::Gt &&
            q.op != TOp::Eq)
            continue;
        // 只对“根”建树：目的不是临时（结果交给命名变量），或临时被多次用
        if (q.dst[0] == 't' && uses[q.dst] == 1) continue;
        Tree t;
        t.dst = q.dst;
        TreeNode root;
        if (!grabAt(i, root)) continue;
        t.root = std::move(root);
        out.push_back(std::move(t));
    }
    return out;
}

// ---------- Ershov 标号：求值该子树所需的最少寄存器数 ----------
int ershov(TreeNode &n) {
    if (n.kind != 'o') {
        n.ershov = 1;
        return 1;
    }
    int l = ershov(*n.l);
    int r = n.r ? ershov(*n.r) : 1;
    n.ershov = l == r ? l + 1 : std::max(l, r);
    return n.ershov;
}

// ---------- maximal munch：贪心覆盖 ----------
// 瓦片表（教学精选）：常量立即数乘、恒等加零/乘一折叠为 mov、二元运算。
static int riscN = 0;
std::string newReg() { return "r" + std::to_string(riscN++ % 8); }

std::vector<Risc> munchTree(TreeNode &n, std::vector<std::string> &notes) {
    std::vector<Risc> out;
    // 先试“大瓦片”：c1 op c2（两常量孩子）→ loadi
    if (n.kind == 'o' && n.l->kind == 'c' && n.r && n.r->kind == 'c') {
        int v = 0;
        int a = n.l->value, b2 = n.r->value;
        switch (n.op) {
        case TOp::Add: v = a + b2; break;
        case TOp::Sub: v = a - b2; break;
        case TOp::Mul: v = a * b2; break;
        case TOp::Div: v = a / b2; break;
        case TOp::Gt:  v = a > b2 ? 1 : 0; break;
        case TOp::Eq:  v = a == b2 ? 1 : 0; break;
        default: break;
        }
        std::string rd = newReg();
        out.push_back({"loadi", rd, std::to_string(v), -1});
        n.result = rd;
        notes.push_back("瓦片 [loadi c1 op c2] 命中");
        return out;
    }
    // 注：x+0 / x*1 这类恒等式刻意“不”设瓦片——留给窥孔（p2/p3 模式）去扫，
    // 正文 44.6 讲“瓦片管结构、窥孔兜底”的分工。
    // 叶子
    if (n.kind == 'c') {
        std::string rd = newReg();
        out.push_back({"loadi", rd, std::to_string(n.value), -1});
        n.result = rd;
        return out;
    }
    if (n.kind == 'v') {
        n.result = n.name;   // 变量视为已“在盒子里”——教学抽象
        return out;
    }
    // 一般二元：左右递归 + 一条指令
    std::vector<Risc> sub = munchTree(*n.l, notes);
    out.insert(out.end(), sub.begin(), sub.end());
    if (n.r) {
        sub = munchTree(*n.r, notes);
        out.insert(out.end(), sub.begin(), sub.end());
    }
    std::string rd = newReg();
    const char *mn = n.op == TOp::Add ? "add" : n.op == TOp::Sub ? "sub"
                       : n.op == TOp::Mul ? "mul" : n.op == TOp::Div ? "div"
                       : n.op == TOp::Gt ? "gt" : "eq";
    out.push_back({mn, rd, n.l->result + "," + n.r->result, -1});
    n.result = rd;
    return out;
}

std::string showRisc(const Risc &r) {
    std::ostringstream os;
    os << "  " << r.mnemonic << " " << r.rd;
    if (r.rs.find(',') != std::string::npos || !r.rs.empty())
        os << " " << r.rs;
    return os.str();
}

// ---------- 窥孔清扫 ----------
std::pair<std::vector<Risc>, std::map<std::string, int>> peephole(std::vector<Risc> in) {
    std::map<std::string, int> hits;
    auto isImm = [](const std::string &s) {
        return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
    };
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t i = 0; i < in.size(); ++i) {
            // p1: 自复制 mov rX rX 删除
            if (in[i].mnemonic == "mov" && in[i].rd == in[i].rs) {
                in.erase(in.begin() + i);
                ++hits["mov-self"];
                ch = true;
                break;
            }
            // p2: loadi rX 0 ; add rD A,rX → mov rD A（加零恒等；右源是刚载入的 0）
            if (i + 1 < in.size() && in[i].mnemonic == "loadi" && in[i].rs == "0" &&
                in[i + 1].mnemonic == "add" &&
                in[i + 1].rs.size() > in[i].rd.size() &&
                in[i + 1].rs.substr(in[i + 1].rs.size() - in[i].rd.size()) == in[i].rd) {
                in[i] = {"mov", in[i + 1].rd,
                         in[i + 1].rs.substr(0, in[i + 1].rs.size() - in[i].rd.size() - 1),
                         -1};
                in.erase(in.begin() + i + 1);
                ++hits["add-0"];
                ch = true;
                break;
            }
            // p3: loadi rX 1 ; mul rD A,rX → mov rD A（乘一恒等）
            if (i + 1 < in.size() && in[i].mnemonic == "loadi" && in[i].rs == "1" &&
                in[i + 1].mnemonic == "mul" &&
                in[i + 1].rs.size() > in[i].rd.size() &&
                in[i + 1].rs.substr(in[i + 1].rs.size() - in[i].rd.size()) == in[i].rd) {
                in[i] = {"mov", in[i + 1].rd,
                         in[i + 1].rs.substr(0, in[i + 1].rs.size() - in[i].rd.size() - 1),
                         -1};
                in.erase(in.begin() + i + 1);
                ++hits["mul-1"];
                ch = true;
                break;
            }
            (void)isImm;
        }
    }
    return {in, hits};
}

// ---------- RISC 解释器（对账证人） ----------
std::vector<int> riscRun(const std::vector<Risc> &code) {
    std::map<std::string, int> reg;
    std::vector<int> outputs;
    auto val = [&](const std::string &s) -> int {
        if (!s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1)))
            return std::atoi(s.c_str());
        return reg[s];
    };
    for (const auto &r : code) {
        if (r.mnemonic == "loadi") reg[r.rd] = std::atoi(r.rs.c_str());
        else if (r.mnemonic == "output") outputs.push_back(val(r.rd));
        else if (r.mnemonic == "mov") reg[r.rd] = val(r.rs);
        else {
            size_t comma = r.rs.find(',');
            std::string a = r.rs.substr(0, comma), b2 = r.rs.substr(comma + 1);
            int x = val(a), y = val(b2);
            if (r.mnemonic == "add") reg[r.rd] = x + y;
            else if (r.mnemonic == "sub") reg[r.rd] = x - y;
            else if (r.mnemonic == "mul") reg[r.rd] = x * y;
            else if (r.mnemonic == "div") reg[r.rd] = x / y;
            else if (r.mnemonic == "gt") reg[r.rd] = x > y ? 1 : 0;
            else if (r.mnemonic == "eq") reg[r.rd] = x == y ? 1 : 0;
        }
    }
    return outputs;
}

}  // namespace tip
```

### 63.8.3 驱动 main.cpp

树/标号/选择/
清扫/对账
五段。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 63 章驱动：--check FILE
//   TAC → 表达式树（Ershov 标号）→ maximal munch 选指令（瓦片命中报告）
//   → 窥孔清扫（模式命中计数）→ 指令数对账 → RISC 解释器 outputs 对账。
#include "isel.hpp"
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

void dumpTree(const tip::TreeNode &n, int depth) {
    for (int i = 0; i < depth; ++i) std::cout << "    ";
    if (n.kind == 'c') std::cout << "const " << n.value;
    else if (n.kind == 'v') std::cout << "var " << n.name;
    else {
        const char *op = n.op == tip::TOp::Add ? "+"
                       : n.op == tip::TOp::Sub ? "-"
                       : n.op == tip::TOp::Mul ? "*"
                       : n.op == tip::TOp::Div ? "/"
                       : n.op == tip::TOp::Gt ? ">" : "==";
        std::cout << "op " << op;
    }
    std::cout << "  [E" << n.ershov << "]\n";
    if (n.l) dumpTree(*n.l, depth + 1);
    if (n.r) dumpTree(*n.r, depth + 1);
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

    std::cout << "== 表达式树（含 Ershov 标号）==\n";
    std::vector<tip::Risc> sel;
    std::vector<std::string> notes;
    for (const auto &b : blocks) {
        std::vector<tip::Tree> trees = tip::fuseTrees(code, b);
        for (auto &t : trees) {
            std::cout << "  " << t.dst << " =\n";
            tip::ershov(t.root);
            dumpTree(t.root, 1);
            std::vector<tip::Risc> part = tip::munchTree(t.root, notes);
            // 先发射计算，再把树结果 mov 到目的名字
            sel.insert(sel.end(), part.begin(), part.end());
            sel.push_back({"mov", t.dst, t.root.result, -1});
        }
        // 控制流/IO 原样降一条
        for (int i = b.begin; i < b.end; ++i) {
            if (code[i].op == tip::TOp::Output) sel.push_back({"output", code[i].a, "", -1});
            else if (code[i].op == tip::TOp::Input) sel.push_back({"loadi", code[i].dst, "0", -1}),
                notes.push_back("input 按 0 装载（示例不读输入）");
        }
    }

    std::cout << "== 指令选择（maximal munch）==\n";
    for (const auto &r : sel) std::cout << tip::showRisc(r) << '\n';
    for (const auto &n : notes) std::cout << "  (" << n << ")\n";

    auto [clean, hits] = tip::peephole(sel);
    std::cout << "== 窥孔清扫后 ==\n";
    for (const auto &r : clean) std::cout << tip::showRisc(r) << '\n';

    std::cout << "== stats ==\n";
    std::cout << "  instructions: " << sel.size() << " -> " << clean.size() << '\n';
    for (const auto &kv : hits)
        std::cout << "  pattern " << kv.first << " x" << kv.second << '\n';

    std::cout << "== 对账 ==\n";
    tip::TacRun run = tip::tacInterp(code, {});
    std::vector<int> rout = tip::riscRun(clean);
    std::cout << "  tac outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << "\n  risc outputs:";
    for (int v : rout) std::cout << ' ' << v;
    std::cout << "\n  tac==risc: " << (run.outputs == rout ? "yes" : "NO") << '\n';
    return (run.outputs == rout && clean.size() <= sel.size()) ? 0 : 1;
}
```

### 63.8.4 TAC 基座与前端（第 13、8、10 章）

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

### 63.8.5 程序与期望输出

```text
// file: programs/expr.tip
main() {
  var x, y, z;
  x = 2 * 3 + 4;
  y = x + 0;
  z = y * 1 + (5 + 6);
  output z;
  output y;
  return 0;
}
```

```text
; expected: expected/output.txt
== expr.tip ==
== TAC ==
  0: t1 = 2
  1: t2 = 3
  2: t3 = t1 * t2
  3: t4 = 4
  4: t5 = t3 + t4
  5: x = t5
  6: t6 = 0
  7: t7 = x + t6
  8: y = t7
  9: t8 = 1
  10: t9 = y * t8
  11: t10 = 5
  12: t11 = 6
  13: t12 = t10 + t11
  14: t13 = t9 + t12
  15: z = t13
  16: output z
  17: output y
  18: t14 = 0
  19: return t14
== 表达式树（含 Ershov 标号）==
  x =
    op +  [E2]
        op *  [E2]
            const 2  [E1]
            const 3  [E1]
        const 4  [E1]
  y =
    op +  [E2]
        var x  [E1]
        const 0  [E1]
  z =
    op +  [E3]
        op *  [E2]
            var y  [E1]
            const 1  [E1]
        op +  [E2]
            const 5  [E1]
            const 6  [E1]
== 指令选择（maximal munch）==
  loadi r0 6
  loadi r1 4
  add r2 r0,r1
  mov x r2
  loadi r3 0
  add r4 x,r3
  mov y r4
  loadi r5 1
  mul r6 y,r5
  loadi r7 11
  add r0 r6,r7
  mov z r0
  output z
  output y
  (瓦片 [loadi c1 op c2] 命中)
  (瓦片 [loadi c1 op c2] 命中)
== 窥孔清扫后 ==
  loadi r0 6
  loadi r1 4
  add r2 r0,r1
  mov x r2
  mov r4 x
  mov y r4
  mov r6 y
  loadi r7 11
  add r0 r6,r7
  mov z r0
  output z
  output y
== stats ==
  instructions: 14 -> 12
  pattern add-0 x1
  pattern mul-1 x1
== 对账 ==
  tac outputs: 21 10
  risc outputs: 21 10
  tac==risc: yes
```

## 63.9 小结与练习

本章打通
最后一厘米：

- 临时链
  长回表达式树，
  独占使用
  是融合的
  唯一依据；
- Ershov 标号
  是寄存器
  需求的
  静态预报；
- maximal munch
  用瓦片库
  贪心覆盖，
  大瓦片
  （常量折叠）
  优先；
- 窥孔
  在选完后
  扫局部模式
  到不动点——
  兜底的安全网；
- 两级解释器
  对账，
  IR 到汇编的
  语义交接
  有证人。

第九篇还剩
并行两章：
指令调度
把独立指令
塞进
多发射的槽位，
循环变换
让缓存
少跑冤枉路。

练习：

1. 手工画出
   expr.tip 三棵树、
   标 Ershov 数，
   与输出对照；
   指出哪棵树
   触发了
   常量折叠瓦片。
2. 给瓦片库加
   "左移瓦片"
   （\*2^n →
    shl 一条），
   在
   `y = x * 8`
   上验证；
   再讨论
   它与
   第 45 章
   强度削减的
   关系
   （提示：
    一个在
    循环级、
    一个在
    树级）。
3. 加窥孔模式
   p4：
   `mov rA rB;
    mov rB rA`
   → 保留一条；
   p5：
   `jump L;
    L:`
   → 删跳转
   （提示：
    先给 RISC
    加 label/jump）。
4. 实现
   Sethi–Ullman
   求值序：
   E 大的孩子
   先算，
   数一数
   求值 z 的树
   实际同时
   占用的
   寄存器峰值，
   与 E3 对照。
5. 把
   maximal munch
   换成树dp
   最优覆盖：
   每个节点
   记
   "以我为根的
    最小代价"，
   比较 expr.tip
   上两版的
   指令数差。
