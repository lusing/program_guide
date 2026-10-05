# 第 13 章　树遍历解释器与环境链

> 取材：匠书（Crafting Interpreters）§7（表达式求值）、§8.1–8.4（语句、
> 环境与赋值）、§9（控制流与块作用域）、§10（函数、闭包与原生函数——
> return 非局部退出的两方案对比）、§11（Resolving and Binding：静态检查
> 在解释器里的第一次实战）。全部材料在本章自包含蒸馏，不需要翻原书。
> 本章示例：`examples/13_tree_walk_interp`（ANTLR 前端，简单程序对账
> 协议）。
>
> **语言口径**：TIP 原文法只有顶层函数（一等函数值靠 `&f`），没有函数
> 字面量——而环境链与闭包的故事必须以函数字面量为舞台。本章在本地
> `TIP.g4` 副本中加入 `fun (参数) { 语句* return 表达式; }` 字面量
> （**教学扩展**，与第 9 章给 TIP 加幂运算符同一性质），正文如实标注
> 每处与匠书 Lox 语义的差异。

## 13.0　第三条执行路：不建任何 IR

本教程至今已有两条"让 TIP 程序跑起来"的路：第 15 章（LLVM 执行台）
把 AST 编译成 LLVM IR 再 JIT；第 16 章（三地址码与基本块）先把 AST
降成 TAC 再解释。两条路都要**先变换、后执行**。本章给出第三条——
**树遍历（tree-walking）**：拿到 AST 直接求值，一行中间表示都不建。
匠书把这条路完整地走了一遍（它的第二部分 jlox 正是一个树遍历解释器），
本章蒸馏它的三件核心资产：

1. **环境链**（environment chain）：作用域在运行期的形态——一个节点
   一个作用域，取值沿链爬、赋值沿链写回。这是本章的主角。
2. **闭包的极简定义**：函数身体 + 定义时环境指针，仅此而已。捕获、
   共享、可变状态回流全部从这两样东西里自然长出来。
3. **求值前的静态检查**（匠书 §11）：解释器不是"拿到就跑"——名字
   解析、确定赋值、元数检查发生在任何求值之前。对一本静态分析教程
   而言，这一节是匠书与本书主题贴得最近的地方：**解释器自己就是
   静态分析的第一个用户**。

与前两轮扩充章一致，本章延续"双实现等价对账"的证人思路（第 9 章
开线）：本章的静态检查器拒绝/放行由语料逐条签收；解释输出与手算期望
逐行对账；环境链的**结构账**（创建了多少个节点）也进入断言——这个
账在第 57 章上值实现时会被拿来对照（上值正是为了消灭环境链的浪费）。

读者带着什么离开本章：**实现者带走**一个能跑闭包的完整解释器
（约三百行）与它的静态检查器（约一百五十行）——这两块代码是后
续第 54–57 章字节码线的"语义基准实现"，那些章的一切优化都以本章
输出为准绳；**语言设计者带走**三份对照——return 位置与运行时机制、
声明位置与检查机制、值宇宙与解释器体量（文法每处限制都在买运行时
的便宜）；**分析者带走**确定赋值这个"活的数据流"——集合、交集、
拷贝传播、保守方向，第 25–31 章的格与不动点是它的理论化，读到那里
时回来摸一眼这块热身代码，会认出所有老朋友。

从第 9 章一路读来的读者会认出两条对称的弧线：第 9 章是"同一语义
（表达式文法）的两种解析"，本章是"同一语义（闭包程序）的多执行
路线之第一站"；第 9 章的证人是"值 + 形状"双对账，本章的证人加码
到"输出 + 环境账"。**匠书线的每一章都在既有的证人网上加一条边**
——这是它作为第五轮扩充的写法自觉：不另起炉灶，只加密印证网。

三条执行路先立个总表，本篇（13–20 章）会逐步填满它：

| 执行路 | 变换 | 首次出现 | 语义证人 |
|---|---|---|---|
| 树遍历 | 无（AST 直接求值） | 本章 | 手算期望 + 环境节点账 |
| LLVM JIT | AST → LLVM IR → 机器码 | 第 15 章 | JIT 输出 vs 解释输出 |
| TAC 解释器 | AST → TAC → 解释 | 第 16 章 | 解释输出 vs LLVM 输出 |
| 字节码 VM | AST →（第 55 章起无 AST）字节码 → 栈机 | 第 54–57 章 | 与本章/15/16 三方全等 |

表的最后一列是教程的"证人网"：每条新路出场，都要与已有路对同一
程序算出同一答案——**语义没有独裁者，只有相互印证的实现共同体**。
本章是网里的第二个节点（第一个是第 9 章的双解析器）。

双证人思路的操作含义值得点破，它不是口号而是三条流程规则：其一，
**语料共享**——同一批程序（计数器、加法器链）在两个实现里跑，
不是各跑各的顺手例子；其二，**期望单一来源**——对账的"标准答案"
来自手推（正文逐帧表），两个实现各自对它负责，谁也不以谁为准；
其三，**结构账独立断言**——环境节点数这类实现相关量不进对账
（两实现天然不同），单独成断言并写明属于哪个实现。三条规则让
"等价"有可执行的形状：跑同一语料、对同一手推、账各记各的。

```text
13.1 求值的骨架：eval 与 exec
13.2 环境链：作用域即节点
13.3 闭包：身体 + 定义时环境
13.4 return 的两种世界（Lox 与 TIP 的文法差异）
13.5 求值前的静态检查（§11 精要）
13.6 驱动与语料设计
13.7 期望输出解读
13.8 环境节点的手推账
13.9 小结与练习
```

三种读者的读法建议：**赶时间者**读 13.2（环境链三操作与不变式）、
13.3（闭包一行定义与 P1 逐帧表）、13.5 的四项清单与归位表——约十
分钟拿到骨架；**实现者**按序全读，重点 13.2.1 的环境走读与 13.5.5
的检查器走读（两节是"代码地图"）；**对照匠书原书者**按这张映射
读——§7（表达式求值）→ 13.1，§8（环境与赋值）→ 13.2，§9（控制
流）→ 13.1 的 exec 表，§10（函数与 return）→ 13.3/13.4，§11
（Resolver）→ 13.5——原书的 jlox 是 Java、语言是 Lox，本章换 C++23
与 TIP+fun，机制一一对应、语义差异处正文逐条标注（四陷阱归位表
是差异的总目录）。

先看共享的前端。本章与第 12 章共用 TIP 的 ANTLR 文法与 AST 构建器
（本地副本），只加了函数字面量与行号两处：

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
           | FUN LPAREN params? RPAREN LBRACE varDecls? stmt* RETURN expr SEMI RBRACE # funExpr
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
FUN        : 'fun' ;
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
    int line = 0;  // 诊断行号（本章起静态检查要报行）
    explicit VarRef(std::string n, int ln = 0) : name(std::move(n)), line(ln) {}
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
    int line = 0;  // 直接调用的元数诊断用
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
struct Stmt;  // 前置声明：FunLit 体内是语句，Stmt 在本文件后部定义

// 函数字面量（教学扩展，匠书 fun 语法）：一个"待调用的身体 + 定义时环境"。
struct FunLit : Expr {
    std::vector<std::string> params;
    std::vector<std::string> vars;
    std::unique_ptr<Stmt> body;
    std::unique_ptr<Expr> ret;
    int line = 0;
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
    int line = 0;
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
    int line = 0;
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
    f->line = static_cast<int>(ctx->getStart()->getLine());
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
        return std::make_unique<VarRef>(c->IDENT()->getText(),
                                        static_cast<int>(ctx->getStart()->getLine()));
    if (auto *c = dynamic_cast<TIPParser::FunExprContext *>(ctx)) {
        auto f = std::make_unique<FunLit>();
        f->line = static_cast<int>(ctx->getStart()->getLine());
        if (c->params())
            for (auto *p : c->params()->IDENT()) f->params.push_back(p->getText());
        if (c->varDecls())
            for (auto *v : c->varDecls()->IDENT()) f->vars.push_back(v->getText());
        std::vector<std::unique_ptr<Stmt>> body;
        for (auto *sc : c->stmt()) body.push_back(buildStmt(sc));
        f->body = std::make_unique<BlockS>(std::move(body));
        f->ret = buildExpr(c->expr());
        return f;
    }
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
        auto call = std::make_unique<CallE>(buildExpr(c->expr()), std::move(args));
        call->line = static_cast<int>(ctx->getStart()->getLine());
        return call;
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
    if (auto *c = dynamic_cast<TIPParser::AssignStmtContext *>(ctx)) {
        auto s = std::make_unique<AssignS>(buildLvalue(c->lvalue()), buildExpr(c->expr()));
        s->line = static_cast<int>(ctx->getStart()->getLine());
        return s;
    }
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

文法层面的变化只有一行：expr 的备选里多出 `# funExpr`（以及词法里的
`FUN` 关键字）。AST 层面多了 `FunLit` 节点、`VarRef/CallE/AssignS`
多了行号字段、`FunDecl` 多了行号——行号是静态检查的家当（§13.5），
AST 其余形状与第 12 章完全一致，读者在那里学过的遍历方式在这里原样
适用。构建器里 `funExpr` 的处理与顶层函数同型（形参、变量组、语句、
尾 return），这为解释器"顶层函数与字面量一视同仁"铺了路（§13.3）。

值得说明的一个构建细节：`NegExpr`（一元负号）在构建阶段就被改写成
`0 - E`——这是第 12 章以来的既有口径（TIP 没有负号节点），本章求值器
因此不需要处理任何一元运算符。文法里保留 `-E` 只是书写便利。

## 13.1　求值的骨架：eval 与 exec

```cpp
// file: src/interp.hpp
// file: src/interp.hpp
// 第 13 章：树遍历解释器与环境链（匠书 §7–§10 精要 + §11 静态检查蒸馏）。
// 两层结构：SemCheck 求值前的静态检查（未声明/重复声明/确定赋值/直接调用
// 元数）+ Interpreter 环境链求值（闭包 = 函数身体 + 定义时环境指针）。
#ifndef TIP_INTERP_HPP
#define TIP_INTERP_HPP

#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

struct Environment;
struct Closure;

// ---------- 值：本章宇宙只有整数与闭包（指针/记录不求值，正文说明） ----------
struct Value {
    enum class Tag { Int, Closure } tag = Tag::Int;
    long long i = 0;
    std::shared_ptr<Closure> clo;

    static Value num(long long v) { Value x; x.tag = Tag::Int; x.i = v; return x; }
    static Value fun(std::shared_ptr<Closure> c) {
        Value x; x.tag = Tag::Closure; x.clo = std::move(c); return x;
    }
};

// 闭包：身体（FunDecl=顶层函数 或 FunLit=字面量）+ 定义时环境。
// 捕获即共享——两个闭包指向同一 Environment 时，经链的写会互相可见。
struct Closure {
    const FunDecl *decl = nullptr;  // 顶层函数（环境=全局）
    const FunLit *lit = nullptr;    // 函数字面量（环境=定义处）
    std::shared_ptr<Environment> env;

    int paramCount() const { return decl ? int(decl->params.size()) : int(lit->params.size()); }
};

// 环境：一个作用域一个节点。取值沿链查、赋值沿链写回（找定义处）。
struct Environment : std::enable_shared_from_this<Environment> {
    std::map<std::string, Value> values;
    std::shared_ptr<Environment> enclosing;

    explicit Environment(std::shared_ptr<Environment> parent) : enclosing(std::move(parent)) {}

    void define(const std::string &name, Value v) { values[name] = std::move(v); }
    Value *find(const std::string &name);  // 沿链；未命中返回 nullptr
};

// ---------- 诊断与运行时错误 ----------
struct Diag {
    std::string msg;
    int line = 0;
};

struct InterpError {
    std::string msg;
    int line = 0;
};

// ---------- 静态检查（求值前，§11 精要） ----------
// 1) 未声明使用 / 同层重复声明（作用域化栈式遍历，jlox Resolver 同型）
// 2) 确定赋值（definite assignment）：每个局部变量在每次使用前必已赋值
//    —— 匠书 "var a = a" 初始化窗口在 TIP 的对应物（TIP 声明与赋值
//    分离，窗口一般化为"声明到首次赋值之间的任何读取"）
// 3) 直接调用的元数（被调是全局函数名时静态可查；闭包调用留运行时兜底）
class SemCheck {
  public:
    std::vector<Diag> run(ProgramA &prog);

  private:
    void declare(const std::string &name, int line);   // 当前层登记，撞名即诊断
    int resolve(const std::string &name);              // 返回层数（0=全局函数），-1 未命中
    void checkStmt(const Stmt &s, std::set<std::string> &assigned);
    void checkExpr(const Expr &e, std::set<std::string> &assigned);
    void collectCapturedExpr(const Expr &e, int myDepth);
    void collectCapturedStmt(const Stmt &s, int myDepth);
    void checkFunBody(const std::vector<std::string> &params,
                      const std::vector<std::string> &vars, const Stmt &body,
                      const Expr &ret, int line);

    std::vector<Diag> diags_;
    std::vector<std::set<std::string>> scopes_;  // 作用域栈（字符串集合即可：
                                                 // 层内只问"在不在"，深度即索引）
    std::map<std::string, const FunDecl *> funs_;  // 全局函数表
    std::set<std::string> captured_;  // 被内嵌 FunLit 捕获的外层名字（豁免确定赋值）
};

// ---------- 解释器（环境链求值） ----------
class Interpreter {
  public:
    explicit Interpreter(ProgramA &prog);

    // 跑入口函数；output 语句写到 out。返回函数返回值。
    Value run(const std::string &entry, std::vector<Value> args, std::ostream &out);

    int envCreated() const { return envCreated_; }

  private:
    Value eval(const Expr &e, Environment &env);
    void exec(const Stmt &s, Environment &env);
    Value callClosure(const Closure &c, std::vector<Value> args, int line);
    std::shared_ptr<Environment> newEnv(std::shared_ptr<Environment> parent);

    ProgramA &prog_;
    std::shared_ptr<Environment> globals_;
    std::ostream *out_ = &std::cout;  // output 语句的去处（run 时切换）
    int envCreated_ = 0;
};

}  // namespace tip

#endif  // TIP_INTERP_HPP
```

```cpp
// file: src/interp.cpp
// file: src/interp.cpp
#include "interp.hpp"

#include <algorithm>
#include <iterator>

namespace tip {

// ---------- 环境链 ----------
Value *Environment::find(const std::string &name) {
    for (Environment *e = this; e; e = e->enclosing.get()) {
        auto it = e->values.find(name);
        if (it != e->values.end()) return &it->second;
    }
    return nullptr;
}

// ---------- 静态检查 ----------
std::vector<Diag> SemCheck::run(ProgramA &prog) {
    scopes_.assign(1, {});  // 第 0 层 = 全局函数表
    for (const auto &f : prog.funs) {
        if (funs_.count(f->name)) diags_.push_back({"全局函数重名：" + f->name, 0});
        funs_[f->name] = f.get();
        scopes_[0].insert(f->name);
    }
    for (const auto &f : prog.funs) {
        captured_.clear();  // 捕获豁免按顶层函数积累（嵌套字面量的捕获都算它的）
        checkFunBody(f->params, f->vars, *f->body, *f->ret->e, f->line);
    }
    return std::move(diags_);
}

void SemCheck::declare(const std::string &name, int line) {
    if (scopes_.back().count(name)) {
        diags_.push_back({"同层重复声明：" + name, line});
        return;  // 先声明者保留（与第 12 章口径一致）
    }
    scopes_.back().insert(name);
}

int SemCheck::resolve(const std::string &name) {
    for (int d = int(scopes_.size()) - 1; d >= 0; --d)
        if (scopes_[size_t(d)].count(name)) return d;
    return -1;
}

// 一个函数（顶层或字面量）体的完整检查：作用域栈压一层，确定赋值从
// "形参全部已赋值"起算，var 声明的变量从空起算。
void SemCheck::checkFunBody(const std::vector<std::string> &params,
                            const std::vector<std::string> &vars, const Stmt &body,
                            const Expr &ret, int line) {
    scopes_.push_back({});
    for (const auto &p : params) declare(p, line);  // 形参即"已赋值的局部"
    for (const auto &v : vars) declare(v, line);

    std::set<std::string> assigned(params.begin(), params.end());
    checkStmt(body, assigned);
    checkExpr(ret, assigned);
    scopes_.pop_back();
    // 捕获豁免的方向说明（正文 §13.5 详述）：captured_ 里的名字读值发生在
    // 未来某次闭包调用，检查的保守方向是"不误报"——豁免它们，宁漏报。
}

void SemCheck::checkStmt(const Stmt &s, std::set<std::string> &assigned) {
    if (const auto *x = dynamic_cast<const AssignS *>(&s)) {
        checkExpr(*x->value, assigned);
        if (auto *t = dynamic_cast<const VarRef *>(x->target.get())) {
            if (resolve(t->name) < 0) diags_.push_back({"未声明：" + t->name, t->line});
            assigned.insert(t->name);  // 直写变量：从此确定已赋值
        } else {
            checkExpr(*x->target, assigned);  // FieldA/Deref 目标：先查内部使用
        }
    } else if (const auto *x = dynamic_cast<const OutputS *>(&s)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const IfS *>(&s)) {
        checkExpr(*x->cond, assigned);
        std::set<std::string> a1 = assigned, a2 = assigned;
        checkStmt(*x->then, a1);
        if (x->els) checkStmt(*x->els, a2);
        // 汇合 = 交集：两支都赋了值，汇合点才确定已赋值
        std::set<std::string> join;
        std::set_intersection(a1.begin(), a1.end(), a2.begin(), a2.end(),
                              std::inserter(join, join.begin()));
        assigned = std::move(join);
    } else if (const auto *x = dynamic_cast<const WhileS *>(&s)) {
        checkExpr(*x->cond, assigned);
        std::set<std::string> body = assigned;
        checkStmt(*x->body, body);
        // 循环可能零次：汇合 = 进循环前 ∩ 循环后
        std::set<std::string> join;
        std::set_intersection(assigned.begin(), assigned.end(), body.begin(), body.end(),
                              std::inserter(join, join.begin()));
        assigned = std::move(join);
    } else if (const auto *x = dynamic_cast<const BlockS *>(&s)) {
        // 块不声明变量（TIP 声明只在函数头），语句顺序传播
        for (const auto &st : x->ss) checkStmt(*st, assigned);
    }
}

void SemCheck::checkExpr(const Expr &e, std::set<std::string> &assigned) {
    if (const auto *x = dynamic_cast<const VarRef *>(&e)) {
        int d = resolve(x->name);
        if (d < 0) {
            diags_.push_back({"未声明：" + x->name, x->line});
        } else if (d > 0) {  // 局部（含参数）才受确定赋值约束；全局函数恒有值
            if (!assigned.count(x->name) && !captured_.count(x->name))
                diags_.push_back({"使用前未赋值：" + x->name, x->line});
        }
    } else if (const auto *x = dynamic_cast<const Binop *>(&e)) {
        checkExpr(*x->l, assigned);
        checkExpr(*x->r, assigned);
    } else if (const auto *x = dynamic_cast<const CallE *>(&e)) {
        checkExpr(*x->callee, assigned);
        for (const auto &a : x->args) checkExpr(*a, assigned);
        // 直接调用全局函数：元数静态可查（闭包调用留运行时兜底）
        if (auto *fn = dynamic_cast<const VarRef *>(x->callee.get())) {
            auto it = funs_.find(fn->name);
            if (it != funs_.end() && it->second->params.size() != x->args.size())
                diags_.push_back({"元数不符：" + fn->name + " 期望 " +
                                      std::to_string(it->second->params.size()) + " 实得 " +
                                      std::to_string(x->args.size()),
                                  x->line});
        }
    } else if (const auto *x = dynamic_cast<const Deref *>(&e)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const AllocE *>(&e)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const RecLit *>(&e)) {
        for (const auto &f : x->fields) checkExpr(*f.second, assigned);
    } else if (const auto *x = dynamic_cast<const FieldA *>(&e)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const FunLit *>(&e)) {
        // 次序关键：先收集捕获（体内引用的外层局部名 → 豁免外层确定赋值），
        // 再进字面量自己的作用域做诊断——否则对合法捕获会误报"未赋值"。
        scopes_.push_back({});
        for (const auto &p : x->params) scopes_.back().insert(p);
        for (const auto &v : x->vars) scopes_.back().insert(v);
        int myDepth = int(scopes_.size()) - 1;
        collectCapturedStmt(*x->body, myDepth);
        collectCapturedExpr(*x->ret, myDepth);
        scopes_.pop_back();

        checkFunBody(x->params, x->vars, *x->body, *x->ret, x->line);
    }
    // IntLit/InputE/NullE/AddrOf：无局部使用（AddrOf 的名字是全局函数引用）
}

// 捕获收集：在字面量作用域（已压栈）视角下，凡是解析到更外层"局部"
// （层数 1..myDepth-1）的名字都是捕获——字面量创建时不读值，读值发生在
// 未来调用，因此外层的确定赋值对它们放行。
void SemCheck::collectCapturedExpr(const Expr &e, int myDepth) {
    if (const auto *x = dynamic_cast<const VarRef *>(&e)) {
        int d = resolve(x->name);
        if (d >= 1 && d < myDepth) captured_.insert(x->name);
    } else if (const auto *x = dynamic_cast<const Binop *>(&e)) {
        collectCapturedExpr(*x->l, myDepth);
        collectCapturedExpr(*x->r, myDepth);
    } else if (const auto *x = dynamic_cast<const CallE *>(&e)) {
        collectCapturedExpr(*x->callee, myDepth);
        for (const auto &a : x->args) collectCapturedExpr(*a, myDepth);
    } else if (const auto *x = dynamic_cast<const Deref *>(&e)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const AllocE *>(&e)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const RecLit *>(&e)) {
        for (const auto &f : x->fields) collectCapturedExpr(*f.second, myDepth);
    } else if (const auto *x = dynamic_cast<const FieldA *>(&e)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const FunLit *>(&e)) {
        scopes_.push_back({});
        for (const auto &p : x->params) scopes_.back().insert(p);
        for (const auto &v : x->vars) scopes_.back().insert(v);
        collectCapturedStmt(*x->body, int(scopes_.size()) - 1);
        collectCapturedExpr(*x->ret, int(scopes_.size()) - 1);
        scopes_.pop_back();
    }
}

void SemCheck::collectCapturedStmt(const Stmt &s, int myDepth) {
    if (const auto *x = dynamic_cast<const AssignS *>(&s)) {
        collectCapturedExpr(*x->value, myDepth);
        if (auto *t = dynamic_cast<const VarRef *>(x->target.get())) {
            int d = resolve(t->name);  // 写捕获同样算捕获（计数器靠它）
            if (d >= 1 && d < myDepth) captured_.insert(t->name);
        } else {
            collectCapturedExpr(*x->target, myDepth);
        }
    } else if (const auto *x = dynamic_cast<const OutputS *>(&s)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const IfS *>(&s)) {
        collectCapturedExpr(*x->cond, myDepth);
        collectCapturedStmt(*x->then, myDepth);
        if (x->els) collectCapturedStmt(*x->els, myDepth);
    } else if (const auto *x = dynamic_cast<const WhileS *>(&s)) {
        collectCapturedExpr(*x->cond, myDepth);
        collectCapturedStmt(*x->body, myDepth);
    } else if (const auto *x = dynamic_cast<const BlockS *>(&s)) {
        for (const auto &st : x->ss) collectCapturedStmt(*st, myDepth);
    }
}

// ---------- 解释器 ----------
Interpreter::Interpreter(ProgramA &prog) : prog_(prog) {
    globals_ = newEnv(nullptr);
    for (const auto &f : prog_.funs) {
        auto clo = std::make_shared<Closure>();
        clo->decl = f.get();
        clo->env = globals_;
        globals_->define(f->name, Value::fun(std::move(clo)));
    }
}

std::shared_ptr<Environment> Interpreter::newEnv(std::shared_ptr<Environment> parent) {
    ++envCreated_;
    return std::make_shared<Environment>(std::move(parent));
}

Value Interpreter::run(const std::string &entry, std::vector<Value> args, std::ostream &out) {
    out_ = &out;
    Value *v = globals_->find(entry);
    if (!v || v->tag != Value::Tag::Closure)
        throw InterpError{"入口函数不存在：" + entry, 0};
    return callClosure(*v->clo, std::move(args), 0);
}

Value Interpreter::callClosure(const Closure &c, std::vector<Value> args, int line) {
    if (int(args.size()) != c.paramCount())
        throw InterpError{"元数不符（运行时）：期望 " + std::to_string(c.paramCount()) +
                              " 实得 " + std::to_string(args.size()),
                          line};
    auto env = newEnv(c.env);  // 新帧：父链指向"定义时环境"，不是调用者！
    const auto &params = c.decl ? c.decl->params : c.lit->params;
    const auto &vars = c.decl ? c.decl->vars : c.lit->vars;
    for (size_t k = 0; k < params.size(); ++k) env->define(params[k], args[k]);
    for (const auto &v : vars) env->define(v, Value::num(0));  // 声明即占位（0）
    const Stmt &body = c.decl ? *c.decl->body : *c.lit->body;
    const Expr &ret = c.decl ? *c.decl->ret->e : *c.lit->ret;
    // 函数体本身就是 BlockS（构建器保证）——它就是本次调用的作用域环境，
    // 语句直接在 env 里执行，不再为体包一层块环境（否则每次调用双重建链）。
    auto *bb = dynamic_cast<const BlockS *>(&body);
    if (bb) {
        for (const auto &st : bb->ss) exec(*st, *env);
    } else {
        exec(body, *env);
    }
    return eval(ret, *env);
}

void Interpreter::exec(const Stmt &s, Environment &env) {
    if (const auto *x = dynamic_cast<const AssignS *>(&s)) {
        Value v = eval(*x->value, env);
        if (auto *t = dynamic_cast<const VarRef *>(x->target.get())) {
            Value *slot = env.find(t->name);  // 赋值沿链写回：找定义处
            if (!slot) throw InterpError{"未定义变量：" + t->name, t->line};
            *slot = v;  // 就地写——闭包共享由此而来
        } else {
            throw InterpError{"字段/指针赋值本章不支持（语料口径）", x->line};
        }
    } else if (const auto *x = dynamic_cast<const OutputS *>(&s)) {
        Value v = eval(*x->e, env);
        *out_ << v.i << "\n";
    } else if (const auto *x = dynamic_cast<const IfS *>(&s)) {
        if (eval(*x->cond, env).i != 0) exec(*x->then, env);
        else if (x->els) exec(*x->els, env);
    } else if (const auto *x = dynamic_cast<const WhileS *>(&s)) {
        while (eval(*x->cond, env).i != 0) exec(*x->body, env);
    } else if (const auto *x = dynamic_cast<const BlockS *>(&s)) {
        auto block = newEnv(env.shared_from_this());  // 块即子环境：进建退弃
        // 块内没有声明（TIP 声明在函数头）；块环境的意义见正文 §13.2
        for (const auto &st : x->ss) exec(*st, *block);
    }
}

Value Interpreter::eval(const Expr &e, Environment &env) {
    if (const auto *x = dynamic_cast<const IntLit *>(&e)) return Value::num(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(&e)) {
        Value *v = env.find(x->name);  // 取值沿链：从当前层向定义处爬
        if (!v) throw InterpError{"未定义变量：" + x->name, x->line};
        return *v;
    }
    if (dynamic_cast<const InputE *>(&e)) return Value::num(0);  // 确定性桩
    if (const auto *x = dynamic_cast<const Binop *>(&e)) {
        long long l = eval(*x->l, env).i, r = eval(*x->r, env).i;
        switch (x->op) {
            case BOp::Add: return Value::num(l + r);
            case BOp::Sub: return Value::num(l - r);
            case BOp::Mul: return Value::num(l * r);
            case BOp::Div:
                if (r == 0) throw InterpError{"除零", 0};
                return Value::num(l / r);
            case BOp::Gt: return Value::num(l > r ? 1 : 0);
            case BOp::Eq: return Value::num(l == r ? 1 : 0);
        }
    }
    if (const auto *x = dynamic_cast<const CallE *>(&e)) {
        Value callee = eval(*x->callee, env);
        std::vector<Value> args;
        for (const auto &a : x->args) args.push_back(eval(*a, env));
        if (callee.tag != Value::Tag::Closure)
            throw InterpError{"被调者不是函数", x->line};
        return callClosure(*callee.clo, std::move(args), x->line);
    }
    if (const auto *x = dynamic_cast<const FunLit *>(&e)) {
        auto clo = std::make_shared<Closure>();
        clo->lit = x;
        clo->env = env.shared_from_this();  // 定义时环境——闭包的全部秘密在此一行
        return Value::fun(std::move(clo));
    }
    throw InterpError{"本章不求值该表达式种类", 0};
}

}  // namespace tip
```

解释器只有两个核心函数：`eval`（表达式 → 值）与 `exec`（语句 → 效果）。
这个二分是所有树遍历解释器的公共骨架，匠书 §7–§9 用了三章把它长出来，
本章一次拿全，但骨架的**设计理由**值得逐条说清——它们不是风格偏好，
而是语义的直接投影。

**表达式有值、语句有效果。** `IntLit` 求值成它自己；`VarRef` 求值成
环境里槽位上的值；`Binop` 先左后右递归再合并。语句那边：赋值语句先
求右侧的值、再把它写进目标；`output` 求值后把整数送往输出流；`if`
按条件的真假走支；`while` 循环求条件、执行体。求值顺序（先左后右、
先右值后目标）在整数宇宙里没有可观察差异，但口径从第一章就定死：
**确定性的求值顺序是日后一切对账的前提**（第 16 章 TAC 解释器、
第 15 章 LLVM 各有自己的顺序约定，届时对照）。

**值宇宙只有两样**：整数与闭包（`Value::Tag::{Int, Closure}`）。TIP
的指针、记录、`alloc`、`null` 在文法里仍然存在，但本章解释器遇到即
报"本章不求值该表达式种类"——指针与记录的运行时是第 16 章（TAC）
与第 20 章（堆与回收）的领地。**让不支持的东西显式报错而不是悄悄
给 0**，是教程一路的家规（第 9 章同款）：语料越界从静默错误变成
一行诊断。

**求值错误用异常抛**：`InterpError{msg, line}`。与第 9 章用出参
字符串不同，这里的错误要**穿透任意深的递归**回到驱动层——闭包调用
嵌套十几层时，一层层手动传错误码会让每个 `eval/exec` 的签名都长出
错误参数。异常的栈展开恰好是"非局部退出"，这个性质 §13.4 会专门
讨论（它是 Lox `return` 语句的标准实现载体，TIP 却不需要——那节的
对照是本章最有趣的文法课）。

**`input()` 是确定性桩**：求值恒为 0。真实解释器接标准输入，教学
对账需要确定输出——桩化输入是教程从第 3 章以来的固定手法（第 27 章
soundness 采样也是这么做的）。

两个分派函数的全部行为压成两张表，读者按行核对实现：

**eval（表达式 → 值）**：

| 节点 | 行为 | 备注 |
|---|---|---|
| IntLit | 返回常量 | |
| VarRef | `env.find` 沿链取槽 | miss 抛（防御位） |
| InputE | 返回 0 | 确定性桩 |
| Binop | 先左后右、按 op 合并 | 除零抛 |
| CallE | 求被调、求实参表、`callClosure` | 元数在调用入口查 |
| FunLit | 造 Closure{身体, env} | **唯一分配堆对象的 eval 分支** |
| 其余 | 抛"本章不求值" | 指针/记录归后章 |

**exec（语句 → 效果）**：

| 节点 | 行为 | 备注 |
|---|---|---|
| AssignS | 先右值、再写目标槽 | 写回沿链 |
| OutputS | 求值、写 `*out_` | 输出重定向点 |
| IfS | 条件非零走 then | TIP 无布尔：整数即真假 |
| WhileS | 循环"求条件-执行体" | |
| BlockS | 子环境内顺序执行 | 进建退弃 |

两张表各有一行值得多看：eval 表的 FunLit 行是**唯一**分配堆对象的
分支（解释器里"函数式特性"的全部运行时足迹就这一个分支）；exec
表的 OutputS 行的 `out_` 指针是**输出重定向**的落点——`run` 把
ostream 传进来存在成员里，output 语句统一写它，期望输出的捕获与
子程序输出的隔离全靠这一行。**找"哪个分支有分配、哪个分支有 IO"**
是读任何解释器的第一动作——分配与 IO 是性能与副作用的两个源头。

骨架说完，再把这个骨架的四个设计决定各拧开一圈，然后进入本章的两个
主角。

**决定一：eval 与 exec 为什么必须分开。** 有些语言允许表达式出现在
语句位（C 的 `x = y = 0;`、JS 的 `console.log(x = 1)`），那些语言的
解释器语句层也要"求值"——但**接口**上仍然是二分的：表达式返回值、
语句产生效果，语句位上的表达式只是"求值后丢弃结果"。把两者捏成一个
函数（返回值兼当效果标志）是新手解释器的常见做法，代价是每个调用点
都要问"我拿到的到底是值还是没用的东西"——类型系统帮不上忙，注释
满天飞。二分之后，`eval` 是纯函数形状（除了 output 与闭包创建，无
可观察效果——严格说闭包创建分配了堆对象，但对外不可见），`exec`
是效果形状（返回 void），读者扫一眼签名就知道哪半边会改变世界。
第 10 章 visitor 的"按节点类型分派"在这里落地为两个 visitor：表达式
一棵树、语句一棵树，分野与文法的 expr/stmt 产生式一一对应——**文法
的形状决定遍历器的形状**，这是自第 9 章以来反复出现的对应律。

"表达式能不能当语句用"在各语言里是一张小光谱，摆出来帮读者定位
TIP 的位置：

| 语言 | 表达式语句 | 典型形态 | 解释器负担 |
|---|---|---|---|
| TIP（本教程） | 无 | 语句就是语句 | exec 全 void，最干净 |
| C/C++/JS | 有 | `x = 5;`、`f();`、`a && b;` | exec 需"求值后丢弃"分支 |
| Scheme/Lisp | 全表达式 | `(begin (print x) y)` | 只需 eval，exec 消失 |
| Rust | 有但分号有意义 | `x` 与 `x;` 类型不同 | 语句/表达式双重类型检查 |

四个位置各有代价与回报：TIP 的"无"把赋值做成语句（**赋值无值**，
`a = b = c` 直接不合法——第 9 章说过的结合性沼泽被文法排干）；
C 的"有"换来了紧凑也带来 `=`/`==` 笔误的经典温床；Lisp 的"全
表达式"让 exec 整个消失（树遍历只剩一个函数——本章读者可以想象
那个版本多简洁，代价是效果与值的界线全靠约定）；Rust 的分号语义
是最精细的取舍（块值 = 末表达式）。**TIP 站最左**，与 SPA 的教学
取向一致——本章的 eval/exec 二分在"全表达式"语言里会退化成单
函数，而在 TIP 里两棵树各有各的遍历协议。

**决定二：求值顺序为什么显式定死。** `Binop` 先左后右、赋值先右值
后目标、实参从左到右——这些顺序在整数宇宙里不可观察（无副作用
表达式），但本章语料里已经有可观察的顺序：P6 的 `s = s + bump()`
右侧有两个子表达式（s 读取、bump() 调用），若先调 bump 再读 s，
输出就成了 9 而不是 6。C/C++ 把这类顺序留给未定义行为，Java 与
Python 定死从左到右——解释器实现者**总要**选一个顺序（递归遍历的
书写顺序就是选择），区别只在有没有写进语言规范。教程选从左到右并
在正文声明，此后一切对账（第 16 章 TAC 解释器、第 57 章上值 VM）
都以它为基准。

**决定三：Value 为什么只有两样东西。** jlox 的值宇宙有五样（bool、
nil、number、string、对象），TIP 的类型系统（第 19–22 章）只有整数、
函数、记录、指针。本章解释器取**最小可用子集**：整数与闭包——
P1 到 P6 与 R1 全部语料只用这两样。多塞进任何一样都要连带实现它的
运行时（字符串要驻留池、记录要堆、指针要 null 检查），那些各有
专章（第 19 章、第 56 章值表示、第 20 章）。**值宇宙的大小决定
解释器的一半体量**——这个观察反过来读就是第 56 章的主题：值宇宙
不变，表示方式（带标签联合 → NaN 装箱）也能砍一半内存。

**决定四：错误为什么用异常。** `InterpError` 从任意深的递归抛出、
在驱动层 `journey` 的 try/catch 落地成一行"运行时错误"。对比第 9
章的出参字符串：那里求值器不被嵌套调用（语料单层），出参够用；这里
闭包调用嵌套任意深（P2 三层、P3 递归五层），出参会污染全部签名。
异常的栈展开恰好是"非局部退出"——同一个机制在 §13.4 里正好承载
Lox 的 return 语义，一物两用（错误路径与控制流合流也是真实解释器
的选择，jlox 的 Return 就继承自 RuntimeException）。

## 13.2　环境链：作用域即节点

第 12 章解决的是"名字**指**谁"——静态绑定表，在求值之前就算好。
本章解决的是"值**住**在哪"——运行期的存储组织。两者是同一枚硬币
的两面：绑定表说"`x` 的这个使用点指向 3 号符号"，环境链说"3 号
符号的值此刻存在这条链的第几层"。匠书 §8.2 的 Environment 类是后者
的教学范本，本章完整实现：

```cpp
struct Environment : std::enable_shared_from_this<Environment> {
    std::map<std::string, Value> values;
    std::shared_ptr<Environment> enclosing;
    ...
};
```

一个作用域一个节点：`values` 是本层名字到值的映射，`enclosing` 指向
外层。三个操作构成全部协议：

- **`define(name, v)`**：在**当前层**登记。函数调用时形参逐个 define、
  变量组逐个 define（占位 0——声明即占位，值等赋值语句来填）。
- **取值 `find(name)`**：从当前层沿 `enclosing` 向外爬，命中即返回
  槽位指针。找不到返回空——静态检查过后这不该发生，防御性抛错。
- **赋值**：同样 `find` 找到**定义处的槽位**，就地写。注意赋值**不
  在当前层新建条目**——写的是定义处，这正是"沿链写回"。

"占位 0"这个细节藏着解释器与检查器的分工：若没有确定赋值检查，
占位 0 会**冒充实值**混进计算（V1 的推演正是这个风险的画面）；有
了检查，占位永远不会被读到——它只是让槽位对象先存在（shared_ptr
的生存期管理需要槽位有主人）。**占位值的存在理由是实现的整齐，
不是语义的允许**：读它 = 程序有错，而"有错读不到"由检查保证。
两层的责任边界在 V1 一行诊断里看得分明。

三个操作合起来维持着环境链的两条**不变式**，任何一步破坏它们，
闭包语义立刻走样：

1. **归属唯一**：任一使用点经 resolve 只命中一个槽（最近包围层的
   那个）。遮蔽合法（跨层同名），歧义非法（同层同名——V5 抓的就是
   它）。不变式由静态侧（作用域栈）与运行侧（爬链取第一个命中）
   双岗值守。
2. **槽位稳定**：一个变量在其生存期内的读写永远落在同一个槽位
   对象上。定义处不会中途搬家（不像第 57 章的 close——那是换实现
   不换语义）；赋值改槽里的**值**，不改槽的**身份**。

P1 的三连输出 `1 2 1` 其实就是两条不变式的可观察投影：归属唯一使
inc1/inc2 永远分别指向 E1/E2；槽位稳定使 E1.c 的两次写都落在同一
格上。**断言输出即不变式的证词**——这个视角在第 20 章（GC 的不变
式）与第 57 章（上值的槽位搬家）都会回来。

**为什么取值和赋值都要找定义处？** 因为作用域的语义就是"一个使用点
只属于一个声明"：第 12 章的静态绑定决定它属于谁，环境链在运行期执行
这个决定——不管当前执行到多深的嵌套，`x = 5` 永远写进**那一个** x
的槽。如果赋值在当前层就近新建条目，外层变量就永远改不动了，闭包的
可变共享（§13.3 的计数器）立刻崩塌。匠书 §8.4 把这对操作叫
assignment（赋给已有变量）与 definition（新变量诞生）——**两者必须
分开**是环境设计的第一个正确性要件。

把 P1 运行到一半时的环境链画出来（`inc1(1)` 第二次调用刚结束），
读者应当能在脑子里生成这张图：

```text
全局 G ── counter:闭包(身体=counter, env=G)   main:闭包(…)
   ↑
main 调用环境 M{inc1: C1, inc2: C2}        ← main 的局部都在这层
   ↑
E1{c: 2}  （counter 首调环境，被 C1 捕获而长存）
   ↑
inc1 第二次调用环境 N2{n: 1}               ← 调用即建、返回即弃
```

C1 的 `env` 指着 E1——所以 E1 不会随 counter 调用结束而销毁（M 与
N2 都会被回收，E1 因被 C1 引用而活）。`c = c + n` 的取值路径是
N2 →（无 c）→ E1（命中），写回同一条路——图上数得清的几步就是
`find` 循环的循环次数：**环境链把作用域查找的成本变成"离定义处几
层"**。第 12 章的静态绑定其实免费附赠了这个距离（resolve 的层数），
jlox 的 Resolver 把它记下来让解释器直接索引（免去运行时爬链）——
本章故意保留爬链，因为爬链**就是**环境链语义的可读定义；索引优化
留给第 55 章（编译期槽位）正面处理。

读链图的三条规则（后面各章的链图同款）：**箭头读作 enclosing**，
谁指向谁是"父"，与调用关系无关（N2 的父是 E1 不是"调用 inc1 的
main 环境 M"——词法作用域三连问里的"父是谁"永远答定义处）；
**盒子里的名字只在定义层出现**（c 只画在 E1，M 与 N2 里没有 c 的
副本——共享就是"只有一份"）；**虚线不说就是不存在**（图中 M 与
E1 之间没有箭头：main 环境和 counter 调用环境互不认识，它们只共享
父亲 G）。三条规则读完，读者对着任何一段闭包程序应当能自己画出
这张图——画得出来 = 环境链毕业。

顺带两个工程选型，读者换语言实现时会再遇到：其一，`values` 用
`std::map`（有序树）而不是 `unordered_map`——查找 O(log n) 对
O(1)，但本章变量数是个位数，且 map 的迭代序确定（调试打印稳定），
教学取稳定；工业解释器（V8 的上下文对象）干脆用**槽数组**——名字
编译期已解析成槽位号，正是第 55 章的路线图。其二，链用
`shared_ptr` 而非裸指针——闭包让环境的生存期脱离调用栈（E1 是活
证），所有权必须交给引用计数；代价是循环引用（环境持有闭包、闭包
持有环境）会泄漏，真实解释器配分代 GC 解决（第 20 章补分代注记），
教学语料无循环、随进程回收。

**块即子环境**：`exec` 遇到 `BlockS`，`newEnv` 造一个子节点、语句
在子节点里执行、块结束节点随之销毁（`shared_ptr` 引用归零即回收）。
进建退弃四个字就是块作用域的全部运行时语义。本章语料里块内没有声明
（TIP 的 `var` 只在函数头），块环境的价值主要在两点：其一，它让
"块"这个语法概念有了真实的运行时对应物，读者在支持块级声明的语言
（jlox、C、Java）里看到的环境创建模式与此同型；其二，它为 §13.3
的闭包提供"捕获的环境可能在块结束后仍被引用"的直觉——`shared_ptr`
的生存期语义保证了被捕获的块环境不会随块退出而销毁（引用计数不清
零）。这一点正是第 57 章"上值"要优化的浪费来源，届时回看。

### 13.2.2　静态栈与运行链：一张双账表

把"谁在什么时候压/弹作用域"与"谁在什么时候建/弃环境"并排记账，
本章两套机制的镜像关系就完全显形了：

| 构造 | 静态侧（SemCheck 的 scopes_） | 运行侧（Interpreter 的环境链） |
|---|---|---|
| 顶层函数表 | 第 0 层登记全部函数名 | 全局环境 define 全部函数闭包 |
| 函数调用 | `checkFunBody` 压一层（形参+变量） | `callClosure` 建节点（绑形参+占位变量） |
| 显式块 | （无声明——层不变，块透明） | `BlockS` 建子节点（跳板） |
| fun 字面量创建 | ——（创建不查不建） | **只存 env 指针，不建节点** |
| fun 字面量调用 | 收集时压字面量层算捕获 | 调用时建节点、父=定义处 |
| 函数结束 | `pop_back` | 节点引用归零即弃（被捕获则长存） |

六行里最值得盯的是**fun 字面量创建**那一行：静态侧什么都不做、
运行侧只存一个指针——创建闭包是全章最便宜的操作（一次堆分配，
Closure 两三个字段）。而它的**调用**与普通函数一样贵（环境全套）。
"创建便宜、调用同价"这个不对称是闭包性能讨论的基准事实——第 57
章上值的全部工作就是把"调用同价"里父链那部分砍掉。

双账的最后一行还藏着一个不对称：静态侧的层**严格随遍历进出**（遍
历器走完就弹，无残留），运行侧的节点**可能不弃**（被捕获则长存）。
静态栈是遍历的局部状态，环境链是程序的全局历史——**一个记"结构"，
一个记"生存"**。分清这两个视角，读者就不会问出"为什么检查器算
的层和运行期的环境对不上"这类问题：它们本来就不必一一对应，对应
的只是"构造 → 动作"这半张表。

**一个真实的设计决定：函数体不再包一层块环境。** 读 `callClosure`
的注释：函数体本身就是 `BlockS`（构建器保证），它**就是**本次调用的
作用域环境——`callClosure` 已经为形参和变量造好了这个环境，直接把
体的语句在同一个环境里执行即可。最初的实现顺手把体当普通块执行，
结果每次调用创建**两个**环境节点（调用环境 + 体块环境），功能没错、
账面翻倍——§13.8 的环境节点数断言把这个 bug 抓了出来。教学代码的
结构账不是装饰：**当"创建了几个节点"成为断言时，多余的环境分配
就无处藏身**。这也是工业解释器（CPython 的帧、V8 的上下文）都要
做"帧与环境去重"的同源压力。

最后看全局层：`Interpreter` 构造时创建 `globals_`，把所有顶层函数
登记成闭包（环境即全局——顶层函数的"定义时环境"就是全局环境）。
`run("main", …)` 从全局表里取 `main` 调用。全局环境永生，是所有链
的共同祖先。

### 13.2.1　全语料的环境走读

把六段解释语料的环境创建各走一遍——每段的"环境账"是该段语义的
剖面，读表时留意父链指向与节点数：

**P2（`adder(1)(2)(3)`）**：全局 G + main 调用 M + adder 调用 E1{x:1}
+ 第一字面量调用 E2{y:2}（父=E1）+ 第二字面量调用 E3{z:3}（父=E2）
——共 5 个节点。求 `x+y+z` 时 x 爬两格、y 爬一格、z 本格：**链的
深度就是捕获的代数**。字面量本身的两次**创建**（在 adder 里、在
E2 里）不建节点——只存指针。

**P3（阶乘，递归 5 层）**：G + main M + fact 五次调用 F5…F1（每次
父=G、各含 n 与 r）——共 7 个节点。递归在这里毫无特殊：每层调用
一个节点、各自有 r，`r = n * fact(n-1)` 的递归发生在 r 赋值之前——
但注意**确定赋值怎么看它**：递归调用在赋值右侧，检查只看"赋值
语句执行完 r 就算已赋值"，不在乎右侧算多久。静态检查与运行时的
时间观不同，这是第一次显形（第 25 章不动点的"时间"观是它的理论
版）。边界帧也值得单看：fact(0) 的调用 F0 里，if 走 then 支
（n == 0），r=1，else 支整支不执行——**运行时只走一支，静态检查
却要求两支都交代 r**（V2/P3 的规则差在运行时的"实际"与检查的
"可能"之间，交集规则站在"可能"一边——这又是保守方向的一次
出场）。

**P4（遮蔽）**：G + M{f:3}——2 个节点。`output f` 在 M 命中局部 f，
一次都不爬——**遮蔽不但不花钱，还省了爬链**。全局函数 f 的闭包仍
在 G 里躺着，没人引用它也不消失（全局表不是垃圾——语义上函数
永远可回，实现上全局表就是根集的一部分，第 20 章 GC 的根集概念
在此埋线）。P4 还顺带演示了**检查器与解释器的遮蔽一致性**：
resolve 在 M 层命中 f（局部）所以不做"函数元数"一类与函数相关的
检查，解释器取值同样停在 M——静态裁决与动态取值"停在同一层"，
是作用域实现正确性的最低要求；若两层停得不一样（比如检查器看
全局、解释器看局部），程序会在检查与运行之间精神分裂——这类
bug 的标准症状是"同一名字检查过了、运行却报未定义"。

**P5（立即调用）**：G + M{x:1} + 字面量调用 L{x:5}（父=M！）——
3 个节点。立即调用的括号只是普通的 CallE，环境照建——**"(fun
(x){…})(5)" 与 "先赋给变量再调用"在环境账上完全一样**，语法糖
不改变运行时形状。

**P6（while + bump）**：G + M{i,s,bump} + bump 三次调用 N1、N2、N3
（父都是 M）——5 个节点。N1…N3 各自一次性（无参数无局部——嗯，
bump 的字面量无参数，调用环境里只有……什么都没有？看实现：
无参数则 define 零个、无 vars 也零个——**空环境节点**。空节点的
意义只剩"父链的跳板"：i 的读写经它爬到 M。第 57 章会指出这类
跳板节点是纯浪费（上值方案里 bump 直接持 M 里 i 的盒子地址，
跳板消失）。**一个"空但不可删"的节点，就是下一次优化的靶子**。

**R1（运行时元数）**：诊断抛在 define 形参之前——环境建了、参数
没绑上。错误路径的资源账不需要精确（进程即将打印诊断），但值得
知道：异常栈展开会正确回收半初始化的 `shared_ptr`——**构造到一半
抛异常不留垃圾**，这是 RAII 的承诺，也是解释器敢用异常的底气。

## 13.3　闭包：身体 + 定义时环境

`FunLit` 的求值只有一行有内容：

```cpp
clo->env = env.shared_from_this();  // 定义时环境——闭包的全部秘密在此一行
```

闭包 = 身体（AST 子树）+ 定义时环境（shared_ptr）。没有第三样东西。
匠书 §10.2 用一整节论证这个定义的充分性，本章用三个语料程序当证人：

**P1 计数器——捕获即共享、跨调用保状态。**

```text
counter() { var c; c = 0; return fun (n) { c = c + n; return c; }; }
main()   { var inc1, inc2; inc1 = counter(); inc2 = counter();
           output inc1(1); output inc1(1); output inc2(1); }
```

逐帧推演：`counter()` 第一次调用 → 新环境 E1（父=全局）→ `c` define
+ 赋 0 → 求值 `fun…` 得闭包 C1 = {字面量身体, E1} → 返回。第二次
调用同理得 C2 = {身体, E2}——**同名函数两次调用，两个环境节点**。
`inc1(1)`：C1 的身体在"新环境（父=E1，绑定 n=1）"里执行：`c = c + n`
的取值沿链爬到 E1 的 c，赋值沿链写回 E1 的 c——E1 的 c 从 0 变 1，
返回 1。第二次 `inc1(1)` 又建新环境（父仍是 E1！）读到 c=1、写回 2。
`inc2(1)` 走 E2，输出 1。三行输出 `1 2 1` 就是三条证词：**同一闭包
跨调用保状态**（1→2）、**两个闭包各持各的环境**（inc2 仍是 1）、
**赋值确实写回定义处**（不是当前调用层）。

注意"父 = E1"这个细节：`callClosure` 造新环境时父亲是 `c.env`
（闭包的定义时环境），**不是调用者当时的环境**。这一行就是词法作用
域在运行期的全部体现——如果父亲换成调用者环境，语言就变成动态作用
域（第 12 章 §12.2 讲过两种作用域的分野，这里是它们在实现上的分岔
点：**一个指针指向谁，决定了语言是哪一种**）。

把 P1 的关键几步排成逐帧表（帧号对应正文推演，env 列是当次调用的
环境与父链）：

| 帧 | 动作 | 环境（父链） | c 的值 | 输出 |
|---|---|---|---|---|
| 1 | `counter()` 首调 | E1(→G) | 0→（返回闭包后定格 0） | |
| 2 | `counter()` 再调 | E2(→G) | 0 | |
| 3 | `inc1(1)` | N1(→E1)，n=1 | E1.c: 0→1 | 1 |
| 4 | `inc1(1)` | N2(→E1)，n=1 | E1.c: 1→2 | 2 |
| 5 | `inc2(1)` | N3(→E2)，n=1 | E2.c: 0→1 | 1 |

表里能看到两件正文说过的事的"帧级证据"：E1 在帧 1 结束后仍然活着
（帧 3、4 还在写它）；N1、N2 是**两次**调用环境（不共享——inc1 的
n 每次都是新槽），共享的只是它们共同的父亲 E1。**调用环境一次一命、
捕获环境与闭包同寿**——环境链的生存期语义就这两句。逐帧表还有一个
容易被忽略的读法：**每一行的"环境（父链）"列恰好对应一个环境节点**
——把五行的节点串起来就是 §13.2 那张链图的动画版。读者合上书后，
能从"程序文本 + 环境链规则"复原这张表，就等于能把任何闭包程序
在纸上跑起来——这是本章动手部分的全部要求。

**P2 嵌套捕获三层——链的深度。** `adder(1)(2)(3)`：adder 调用环境
E1{x=1}；第一个字面量闭包捕获 E1，调用后建 E2{y=2}（父=E1）；第二个
字面量在 E2 里创建、捕获 E2；再调用建 E3{z=3}（父=E2）；求 `x+y+z`
沿链爬两格取 x、一格取 y、本格取 z——6。链图：

```text
G ← E1{x:1} ← E2{y:2} ← E3{z:3}      （← 即 enclosing）
     ↑第一层闭包捕获   ↑第二层闭包捕获   当前调用环境
x 的取值路径：E3 → E2 → E1，两跳
```

**每层环境只存自己声明的变量，外层变量靠链共享**——这就是 19 章
（活动记录的访问链）在堆上的镜像，也是第 57 章上值"按变量搬家"
要替代的整链保留。**链的深度就是捕获的代数**：x 隔两代、每次取值
两跳——回调金字塔式的深嵌套里，最外层变量的取值成本随深度线性
增长，这是环境链实现给"深捕获"场景画出的性能画像。

**P6 while 里的 bump——闭包改写外层的循环变量。** 循环体内 `s = s +
bump()`，`bump` 的身体执行 `i = i + 1`——写的是 main 环境里的 i。
输出 `6 3`：s 累加 1+2+3，i 终值 3。闭包不是只读快照（那是一种实现
选择——复制式捕获），**共享式捕获**让状态回流，这是 TIP、Lox、JS、
Python、Lua 共同的语义口径，也是第 53 章闭包转换"装箱单"要静态复
现的行为（那章把捕获变量装进堆盒子；本章直接共享环境节点——两种
实现、一个语义）。

### 13.3.1　求值顺序变成可观察量的那一行

P6 的 `s = s + bump()` 是全章唯一一处**求值顺序可观察**的语句：
右侧两个子表达式，一个读 s、一个调 bump（副作用改 i——不影响 s，
但循环计数变）。按本章"先左后右"的顺序：

| 步 | 子表达式 | 值 | 副作用 |
|---|---|---|---|
| 1 | 左：读 s | 当前 s | 无 |
| 2 | 右：调 bump() | 新 i | M.i += 1 |
| 3 | 合并 s + 新 i | 存入 s | |

三轮循环的账：s ← 0+1, 1+2, 3+3 → 6。**若顺序反过来**（先 bump
再读 s）：s 的读仍发生在赋值前——s 的值不变！只有当副作用作用于
**右侧自己要读的变量**时顺序才真正可观察。构造那真正可观察的反例
留给读者（把 bump 改成改 s 自己），届时两种顺序会给出 6 与 9 的
分岔——**求值顺序的规范之所以重要，不是因为每行都受影响，而是
因为写程序的人无法事先知道哪行属于"不受影响"**。C++ 在 C++17 前
连 `f(a, b)` 的实参求值顺序都未指定（P2 的 `adder(1)(2)(3)` 跨
调用链不在此列，但同规则的旁支）；Java 定死从左到右。教程定死它，
是为了让 P6 的 6 可以被逐格推演——**每个输出数字都能落到格子上，
对账才有意义**。

三种"闭包实现"在教程里将三次出场，先把它们的对照表立起来，后两
章回来对号入座：

| | 环境链（本章 13） | 装箱单（第 53 章） | 上值（第 57 章） |
|---|---|---|---|
| 捕获粒度 | 整条环境链 | 编译期算出的捕获集 | 单变量、按需 |
| 谁搬家 | 没人搬（共享节点） | 编译期装箱进堆 | 运行期 close 时搬 |
| 无关变量 | 也被拖着（整层常驻） | 不装（精确清单） | 不捕（精确） |
| 帧回收后 | 链节点还在（计数撑着） | 盒子独立 | 盒子独立 |
| 静态信息量 | 几乎为零 | 全静态 | 半静态（捕获表） |

第一行的"粒度"是三种方案的分水岭：本章的实现最省事也最浪费——
哪怕闭包只用外层一个变量，整层环境（连带层里所有别的变量）都得
陪葬常驻；装箱单最精确但要编译器算清单；上值折中——运行期谁被
捕获谁搬家。第 57 章会拿 P1 同一语料实测三种实现的"堆上常驻对象"
账，本章先把概念坐标立好。

**顶层函数与字面量一视同仁。** `Closure` 结构体里 `decl` 与 `lit`
二选一，`callClosure` 对两者的处理路径完全对称。对称性的落点是
四组字段的平行取用：

| 调用步骤 | FunDecl 路径 | FunLit 路径 |
|---|---|---|
| 元数 | `decl->params.size()` | `lit->params.size()` |
| 新环境父指针 | `c.env`（=全局） | `c.env`（=定义处） |
| 绑定形参 | `decl->params` | `lit->params` |
| 执行 | `decl->body` / `decl->ret->e` | `lit->body` / `lit->ret` |

每行都是同一个表达式在两个分支里各写一遍——有人会想把 FunDecl
在构造期就包装成"无捕获的 FunLit"来消掉分支（统一表示，只差一个
env 指针），那是漂亮的改法，练习 5 的变体。统一的价值在第 48 章
（0-CFA）已经用过：函数值可以来自任何地方（全局名、参数、闭包调用
结果——P2 的 `adder(1)(2)(3)` 链式调用是活例），调用协议必须不看出身。

顺带一个语义边角：**两个闭包什么时候"相等"？** P1 的 inc1 与 inc2
是同一个字面量的两次求值产物——身体相同、环境不同。本章 Value 没有
相等比较（语料不比闭包）；若要定义，工业语言的分裂正是教科书素材：
JS 按引用比（不同闭包对象恒不等）、Python 按对象身份、Scheme 按
`eq?`。**"值相等"对闭包天然含糊**——环境算不算身份的一部分？
多数语言只给引用相等。这个含糊在第 56 章字符串驻留处会正面回来：
字符串选"值相等即指针相等"是为了把比较变便宜；闭包没这么选，因为
它的"值"（环境）天然可变——**可变性破坏值语义**，第 51 章 thunk
与本节是同一主题的两面。

`callClosure` 的六步序列值得完整读一遍，因为它是本章所有机制的
汇流处：查元数 → 建环境（父=c.env）→ 绑形参 → 声明变量占位 →
执行体（BlockS 语句直接跑）→ 求值 return 表达式。六步里三步在
造环境（建、绑、占位）、两步在递归（体与返回值）、一步在防御
（元数）——**一次函数调用的运行时，就是"环境准备 + 递归下降"**，
这句话在第 54 章字节码 VM 里会逐字对应到 CallFrame 的构造序列。

## 13.4　return 的两种世界

匠书 §10.1 遇到一个本章必须正面讨论的问题：**Lox 的 return 是语句，
可以出现在函数体任何位置**（`if (c) return 1; return 0;`）。树遍历
求值是深度优先递归——return 发生在五层 eval/exec 嵌套深处时，如何
让"带回返回值、立刻终止函数"立即生效？

方案光谱有三档。**标志位层层检查**：每个 exec 返回 `optional<Value>`，
每层调用后检查——正确但每个语句分支都要写检查，代码噪音极大。**
结果参数**：传一个 `ReturnSignal*` 出参，return 语句填它、每层检查
提前退出——比标志位整洁，仍是显式传播。**异常**：`throw
ReturnSignal{v}`，C++ 的栈展开自动"穿透"任意深度，`callClosure`
里 `catch`——return 语义与异常机制天然同构：**都是非局部退出**。
匠书选了第三种（Java 实现，异常顺手）；jlox 的 `Return` 类直接继承
`RuntimeException`。

**TIP 不需要其中任何一种。** 看本章文法：函数体是 `stmt* RETURN
expr SEMI`——return 只能出现在体的**末尾**，文法保证了它必然最后
执行。于是 `callClosure` 的实现是朴素的顺序：执行体语句、求值
return 表达式、返回——没有任何非局部退出机制。这不是偷懒，而是
**文法设计消掉了运行时机制**的干净例子：SPA 的 TIP 为教学简洁把
return 定为尾置；Lox 为表达力允许任意位置。代价对照表：

| | Lox（return 任意处） | TIP（尾 return） |
|---|---|---|
| 文法复杂度 | return 进 stmt 备选 | return 固定在尾部 |
| 运行时机制 | 异常/信号非局部退出 | 无 |
| 表达力 | 提前返回、多出口 | 单出口（要靠 if/else 给变量赋值） |
| 求值顺序 | 提前终止可跳过副作用 | 全语句必执行 |

表逐行讲评。**文法行**：Lox 的 stmt 多一个备选（`RETURN expr SEMI`），
AST 多一个 ReturnS 语句节点——本章 AST 里 ReturnS 其实存在但只作为
函数的尾部构件（`FunDecl::ret`），不进语句树；**运行时行**就是本节
主角，下面两段展开；**表达力行**的单出口不是纯劣势——单出口函数
的阅读者永远知道"出口在哪"，多出口函数的读者要在脑内维护一个
"已返回？"标志，这是软件工程里"单一出口原则"争论的编译器投影
（现代共识不再教条，但重构成单出口常常让逻辑更清楚）；**求值顺
序行**最微妙：提前 return 跳过的语句里若有副作用（output、闭包
调用），两语言的同一"意图程序"会产生不同可观察行为——**多出口
不只是方便，它改变程序的含义空间**，第 16 章 TAC 的基本块切分将
把每个出口显式化为跳转目标，届时"出口"从文法概念变成图论概念。

TIP 强制单出口的深层红利要到 SSA 才完全兑现：单出口 + 单一 return
变量意味着"函数返回值 = return 变量在函数末尾的值"——这个变量
天然是 SSA 化时的统一 φ 汇聚点。多出口函数降 SSA 时要在每个出口
插 φ（或引入合成变量），单出口函数免费得到汇聚点。**文法在源头
买好的东西，下游每个阶段都在收利息**——这是"文法设计即预算"
（§13.4 前段）最完整的一个例证，第 38 章 SSA 构造时请回来对账。

"文法设计消掉运行时机制"不是孤例，把 TIP 的三个限制排成一列，读者
能看到同一种设计哲学的三次出手：**尾 return** 消掉非局部退出（本节）；
**varDecls 只在函数头、只许一组**消掉块级作用域的运行时（块环境退
化为无名字的跳板——§13.2.1 的 P6 账）；**比较只有 `>` 与 `==`** 让
第 9 章的优先级表少两行。每次"少一个文法便利"都换掉一类运行时或
检查机制——SPA 把 TIP 设计成这样是为了让**分析**章节的主角（格、
不动点、上下文）不被运行时细节淹没；匠书把 Lox 设计成那样（return
任意处、块级 var）是为了让**运行时机制**（异常退出、环境链）有戏可
唱。两种教学语言对着同一批机制做了相反的取舍——**语言设计即课程
设计的注意力预算**。本教程拿 TIP 当主线、用 fun 字面量按需借来
Lox 的戏台（本章），两边的课都上齐。

P3 的阶乘就是这个对照的活标本：Lox 写 `if (n == 0) return 1;`，TIP
必须 `if (n == 0) { r = 1; } else { r = n * fact(n-1); } return r;`——
把"提前返回"翻译成"给结果变量赋值"。顺带一提，这个翻译恰好是
**静态单赋值（SSA）思想**的雏形：多出口控制流改写成"每条路径都给
同一个名字赋值、汇合后读它"——第 38 章 φ 节点处理的是同一个问题的
一般形态。文法的限制把读者提前推向了那个方向。

把异常方案的形状留个底稿（练习 4 会亲手实现它的出参变体）：Lox 的
解释器里 `Return` 是一个只用于控制流的异常类型，`return e;` 的求值
就是 `throw Return(eval(e))`；`callClosure` 的身体执行包一层
`try { exec(body) } catch (Return &r) { return r.value; }`。三行代码
换来"任意位置 return"的全部表达力——**栈展开恰好实现了"终止本
函数、忽略中间所有层"的语义**。代价藏在不可见处：C++ 异常的展开
路径性能不佳（真实实现常改用 setjmp/longjmp 或返回码），且异常
混用控制流与错误会让调试器在错误的视角断下（jlox 用
`printStackTrace` 时要跳过 Return）。工程与教学的取舍再一次同题：
**同一机制，两处使用，各有账单**。

## 13.5　求值前的静态检查：匠书 §11 精要

到此为止的解释器有一个洞：`output x` 在 x 未赋值时输出占位 0（声
明即占位的副作用）；`f(1)` 对两参函数 f 静静传错元数，直到运行时
才炸（甚至不炸）。匠书 §11 的开场白正对着这个洞："我们的解释器把
变量解析推迟到运行期……我们可以做得更好"——**Resolving and
Binding** 一章给 jlox 加了一个静态遍历器，在求值前回答"每个名字
指谁、合不合法"。这一节是匠书与"静态分析"主题的交汇点，本章把它
蒸馏成四项检查，全部跑在任何求值之前。

先看结构。`SemCheck` 是一个独立的遍历器（与解释器分居两个类）：
`run` 产出一列 `Diag{msg, line}`，非空即拒绝运行。**检查与求值分离**
不是洁癖：检查可能被不同的消费者复用（第 19 章类型推断要先于本章
的检查还是之后？分开才能回答），且拒绝的语义是"整个程序不跑"——
混在求值里做不到。

**第一项：未声明与同层重复。** `scopes_` 是作用域栈（每层一个名字
集合，第 0 层是全局函数表），`resolve` 从栈顶向下找。声明（`declare`）
撞同层同名即诊断"同层重复声明"，先声明者保留——与第 12 章口径
一致。与第 12 章的差别在**嵌套**：那章的 resolver 只有两层（全局
扁平 + 函数局部），本章因函数字面量必须做真正的栈式嵌套——字面量
的身体是新的作用域层，字面量里的字面量再叠层。jlox 的 Resolver 与
此同型（它用 `Map<String, Boolean>` 的 `scopes` 栈 + beginScope/
endScope，匠书 §11.3）。V4（未声明）、V5（参数与变量同层重名）
是这一项的两个违规证人。

V5（参数与变量同层重名）背后有个跨语言的口径问题值得一小节：
**形参和局部变量是同一个作用域吗？** 本章与 jlox、C（C23 前的
实践）、Java 一致——同层，`f(x) { var x; }` 重名非法；也有语言
分两层（参数层在内、声明层更内，或反之），重名变成遮蔽。同层的
理由是**它们的生命期相同**（整个函数体）且**用途对称**（都是调用
开始就有值的局部——参数靠实参、变量靠占位），分两层只会让"遮蔽
了自己的参数"这种几乎必错的程序合法化。Python 更彻底：连赋值都
是声明（函数级），`def f(x): x = 1` 里两个 x 是同一个——**语言把
"作用域结构"做成什么样，这类诊断就长什么样**；本章选最保守的
同层口径，V5 的诊断就是它的影子。

与 jlox Resolver 的机制对照值得摆开（左栏是原书 §11.3 的骨架）：

| 环节 | jlox Resolver | 本章 SemCheck |
|---|---|---|
| 作用域栈 | `Deque<Map<String,Boolean>>`（值=已初始化） | `vector<set<string>>`（初始化另有账） |
| 进出作用域 | beginScope / endScope | `scopes_.push_back` / `pop_back` |
| 声明 | declare（先记"未初始化"） | declare（只查重登记） |
| 初始化 | markInitialized（赋值表达式左值处） | 确定赋值集 insert |
| 使用检查 | resolve 查栈 + 未初始化窗口 | resolve 查栈 + 未赋值集 |
| 输出 | locals 映射（供解释器索引） | 诊断清单（解释器自己爬链） |

两列的差异里藏着两个设计维度：其一，jlox 把"已初始化"编码在栈的
**值**里（Boolean），本章单独建集合——因为 TIP 的初始化是**时间段**
（跨语句传播）而 Lox 是**时刻**（声明行内完成）；其二，jlox 的
Resolver 顺手产出 locals 深度表供解释器**免爬链**，本章检查完即扔、
解释器照爬——保留爬链是教学选择（§13.2 说过），工程上两栏迟早会
合在"索引化"（第 55 章）。**同一功能两种架构，差异点都长在语言
语义的差别上**——读对照表时请拿"窗口形状"当索引。

**第二项：确定赋值（definite assignment）。** 先说为什么必须查：
本章解释器"声明即占位 0"——不查的话，`var x; output x;` 静默输出
0，错误不会爆发在这里，而是**顺着计算传播下去**（想想 x 是导弹
落点的角度）。未初始化读是最阴的 bug 家族：值"看着挺合理"，错在
来源。Java 把它升格为编译错误（JLS 第 16 章"Definite Assignment"，
整整一章讲这个检查的规则）；C 没查（未初始化读是未定义行为的经典
成员）；Go 仿 Java（"declared and not used"连没用都管）。教程站
Java 一侧，因为这是**数据流分析第一次真正出场**的舞台——

匠书 §11 最精彩的
一分钟是它的四个 bug 搜捕之一："var a = a; 必须被抓到"——jlox 的
环境在声明时就有名字了，`a = a` 右边的 a 能查到（指向未初始化的
槽）。解法是在 resolver 里区分"已声明"与"已定义"（declare 后
markInitialized 前，同名使用即诊断）。TIP 的对应物是什么？TIP 声明
与赋值彻底分离（`var x;` 之后随便哪句才 `x = 5;`），"初始化窗口"
不是一行代码而是一段时间——**从声明到首次赋值之间的任何读取都该
被抓**。这恰好是 Java 的 definite assignment 检查（JLS 16 章），
也是数据流分析的第一课：

- 赋值语句 `x = E`：先检查 E 里的读取，然后 x 进入"确定已赋值"集。
- `if (C) S1 else S2`：C 在当前集下检查；S1、S2 各拿一份**拷贝**分
  别传播；汇合点取**交集**——两支都赋了，汇合后才算确定赋值。
- `while (C) S`：S 在拷贝下传播；循环可能零次执行，汇合 = 进循环前
  ∩ 循环后。
- 块：语句顺序传播。

V1（声明后直接读）、V2（if 单支赋值后读）被抓，P3（if/else 两支都
赋值）通过——V2 与 P3 恰好构成交集规则的一对证人。读者会认出这套
"集合 + 交集 + 拷贝传播"的形状：它是一个**前向、交集为 join 的
数据流框架**（第 31 章的定理管它的正确性），域是名字子集格。第 25
章的工作表算法将在同型框架上求不动点；本章的传播是单遍的（没有
循环回边重访——while 的交集规则就是为单遍收敛准备的保守近似）。
**在解释器里先遇到数据流**，是匠书给静态分析读者的礼物。

把 V2 的传播过程逐语句过一遍，交集规则的"账本"就摊开了：

| 语句 | 传播后的确定赋值集 | 说明 |
|---|---|---|
| `var x;` | {} | 声明不赋值 |
| `if (input() > 0)` | {} | 条件读取 input，不涉及 x |
| ↳ then 支 `{ x = 1; }` | 支内 {x}，出支 {x} | 拷贝传播 |
| ↳ else 支（缺） | {} | 无 else：拿进入时的 {} 走完 |
| 汇合 | {} ∩ {x} = {} | **交集**：两支都赋了才算 |
| `output x;` | 读 x——不在集合 | 诊断：使用前未赋值 |

对比 P3：then 与 else 分别给 r 赋 1 与 n*fact(n-1)，汇合 {r} ∩ {r}
= {r}，`return r` 无罪。**交集是"必须每条路都保险"的数学化**——
这一点上确定赋值与第 28 章可用表达式（也是交集 join）同型，而与
第 28 章活跃变量（并集）相反；为什么一个取交一个取并，第 31 章
框架定理给统一答案（"证明所有路径都成立"用交，"存在一条路径就
成立"用并）。

**捕获豁免与保守方向。** 内嵌字面量引用外层变量（P1 的 c）时，
外层的确定赋值检查怎么办？字面量**创建**时不读值，读值发生在未来
某次调用——那时外层多半已赋值，但也未必。本章选择：**被捕获的
名字豁免检查**（`captured_` 集合）。方向务必想清楚：确定赋值检查
拒绝的程序是"**可能**读未赋值"的程序；豁免让这一类不再被拒绝——
检查保持"不误报"（拒绝必有理），付出"可能漏报"的代价。**宁漏报
不误报**是诊断类检查（lint）的通行取向；反过来"宁误报不漏报"是
安全类检查（类型系统）的取向——第 19 章起会站到另一边。同一个人
格在两种检查里的不同偏向，是静态分析工程观的分水岭之一。

捕获收集的实现（`collectCapturedExpr/Stmt`）值得读两遍：先压入
字面量自己的作用域（让**遮蔽**正确——字面量参数与外层同名时不算
捕获），再走身体，凡 `resolve` 到**更外层的局部**（层数在 1 与
myDepth 之间）的名字进豁免集；嵌套字面量递归处理。**收集必须先于
诊断**（代码注释里的"次序关键"）——若先查后收，对合法捕获会误报
"未赋值"。

拿 P1 的字面量 `fun (n) { c = c + n; return c; }` 走一遍收集：
压栈后作用域栈是 [全局]{counter, main} ⊕ [counter 层]{c} ⊕ [main
层]{inc1, inc2} ⊕ [字面量层]{n}（示意，实际栈只含路径上的层）；
`resolve("c")` 从栈顶向下，在字面量层 miss、在 counter 层命中——
命中层数 < myDepth，c 进豁免集；`resolve("n")` 在本层命中，不算。
`c` 的写目标（`collectCapturedStmt` 的 AssignS 分支）同样检查——
**写捕获也算捕获**，否则计数器的写回就逃过检查了。收集完毕，
`checkFunBody` 再进字面量诊断时，外层 c 已在豁免集里——`c = c + n`
右侧的 c 读取放行。次序颠倒的话，这行会在"收集"之前被判"未赋值"
——次序约束的必要性就在这一个反例里。

**第三项：元数——静态查得到的静态查，查不到的运行时兜底。** 直接
调用全局函数（`fact(5)`、`f(1)`）时被调者的形参数**静态可知**（查
函数表），元数不匹配在求值前诊断（V3）。经闭包变量调用（`inc1(1)`、
`g(1,2)`）时被调者是个运行时的值——形参数要到拿到闭包才知道，这类
只能运行时检查（R1：`callClosure` 入口的 throw）。**同一类错误按
信息可得性分两段拦截**，这是匠书 §10.1（运行时检查）与 §11（静态
化）两章合起来的教训：能静态化的部分静态化，剩下的留给运行时——
分界线画在"被调表达式是否直接绑定到已知函数声明"。第 48 章 0-CFA
会把这条线往静态侧推一大步（调用图分析能算出间接调用的目标集），
推不动的地方（分析的不精确）永远有运行时兜底的位置。

"分界线"值得再挖半锹，因为它预告了整个第八篇（跨函数分析）的动机
结构。静态检查的本质是**提前回答运行期才会问的问题**；能提前多少，
取决于分析愿意保守到什么程度。本章对 `g(1,2)`（g 是闭包变量）不做
静态元数检查——不是因为做不到，而是因为**做得起的前提是知道 g 可
能指向哪些函数**：0-CFA 会给出"g ∈ {那个字面量}"这样的集合，集合
里所有成员都接受 1 个参数时静态检查即可升级。但 0-CFA 自己也有算
不准的时候（间接调用经参数传来传去），那时还有 上下文敏感（k-CFA，
第 47 章）……静态分析的能力阶梯没有顶点，运行时兜底因此不是权宜
之计，而是**架构里的常设部门**。教程后面每一个分析章节都在回答
同一类问题："这一段错误，我们能不能提前到求值之前？"——本章把
这个问题第一次摆上台面。

**第四项：jlox 四陷阱在 TIP 的归位表。** 匠书 §11 的四个 bug 搜捕
在本章语言里的对应与差异，一张表说清：

| 匠书陷阱（Lox） | 本章对应（TIP+fun） | 处置 |
|---|---|---|
| `var a = a;` 声明未初始化窗口 | 声明到首次赋值的读取窗口 | 确定赋值（第二项） |
| 块级遮蔽合法性 | 参数遮蔽外层（P5：`x` 形参遮蔽 `x` 局部） | 合法，语料演示 |
| 函数与变量声明次序（名字不同时刻指不同实体） | 局部遮蔽全局函数名（P4） | 合法，语料演示 |
| `return` 出现在顶层 | TIP 文法无顶层语句，结构不可能 | §13.4 文法课 |

P4 与 P5 是"合法但值得演示"的两条：P4 里 `var f` 遮蔽全局函数 f，
`output f` 输出 3——名字的归属由**最近的包围作用域**定，函数名没有
特权；P5 里字面量形参 x 遮蔽外层同名变量，立即调用输出 15、外层 x
仍是 1——遮蔽是作用域栈的天然行为，`resolve` 从栈顶向下找到第一
个就停。jlox 在这两处会给出与 TIP 一致的行为；差异在 jlox 还允许
块内 `var`（真块级作用域），TIP 的声明只在函数头——**读者若把本章
`declare` 的调用点从函数头挪进块语句，就得到了 jlox 的完整语义**，
这个扩展留作练习 3。

四条陷阱逐条再说两句"为什么它值得一个专章位置"——它们共同示范了
**语义陷阱的解剖法**：先找到"窗口"（程序执行中名字处于中间状态的
时间段），再决定由谁关窗（文法、静态检查、运行时）。第一条的窗口
是"声明到初始化"（jlox 用 declare/markInitialized 两步走显式建模，
TIP 一般化为确定赋值的时间段）；第三条的窗口是"声明前"（jlox 的
函数声明与变量声明绑定时机不同——函数名在声明语句执行时立即绑定，
变量名要到初始化才绑定，于是 `var f = f;` 里右边的 f 若外层有函数
就静默指向函数！TIP 的 varDecls 在函数头整体声明，窗口不存在——
**两种文法对同一个坑的两种回避**）；第二条与第四条在 TIP 里干脆
结构不可能（同层重复被抓、顶层无语句）。四种窗口、四种关法，没有
一种靠"程序员小心"——**语言的语义安全从不托付给注意力**。

### 13.5.5　检查器的实现走读

`SemCheck` 的四个成员按依赖序读：

**`run` 是装配线**。第一步把全局函数表建进第 0 层作用域（顺手抓
全局重名）；第二步对每个顶层函数**清空豁免集后**调 `checkFunBody`。
"按顶层函数清空"这个粒度值得注意：嵌套字面量的捕获都记到最外层
函数头上——因为确定赋值检查只对"函数的局部变量"有意义，字面量
捕获的必然是某个外层函数的局部，账记到谁的头上就查谁的身体。

**`declare` / `resolve` 是作用域栈的全部协议**。declare 只管本层查
重与登记；resolve 从栈顶向下，返回**层数**（这个返回值在两处消费：
确定赋值判断"是不是全局函数"用 `d > 0`，捕获判断"是不是外层"用
`d < myDepth`）。两个消费者、一个层数——**解析的输出是"深度"而
不是"是/否"**，这是作用域栈与扁平名字表的本质差异，也是 jlox
Resolver 输出（locals 到深度的映射）的同型物。

**`checkStmt` 是数据流传播**。赋值是 gen（目标进集合）、if/while 是
join（交集）、块是顺序复合、output 是纯 use 检查。二十行代码是一个
微型数据流引擎——第 28 章把它一般化（kill/gen 的表格化），第 31 章
给它正确性定理。这里值得读慢一点的是**集合的值语义**：`std::set`
的拷贝赋值 `a1 = assigned` 就是"分支各拿一份快照"——数据流传播
在命令式代码里的落点就是集合拷贝，没有魔法。

**`checkExpr` 是规则挂载点**。VarRef 处消费深度（未声明/未赋值）、
CallE 处消费函数表（元数）、FunLit 处先收集后递归（次序约束，
§13.5 第二项讲过）。三种检查共用同一次遍历——**遍历一次、多查
并发**是静态检查器的标准经济结构（第 19 章类型约束收集同款），
分开三遍遍历语义等价但 AST 走三遍。

最后算一笔代码量的账：`SemCheck` 约 150 行，`Interpreter` 约 170
行——**静态检查器与解释器几乎等重**。这个比例对初学者往往出乎
意料（"检查不是附赠的小功能吗"），在工业前端却是常识：Clang 的
Sema 与 CodeGen 同量级，rustc 的类型检查远比代码生成重。原因
在本章已经现过：检查要对付"可能"（所有路径、所有未来调用），
解释只需对付"实际"（眼前这一条路）——**保守性是按代码行数付费
的**。这笔账在读者为自己的语言权衡"查多少"时是最实用的参考系：
每加一项检查，先估它是"窗口型"（一条规则）还是"传播型"（一套
数据流），前者十行、后者起步百行。

## 13.6　驱动与语料设计

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 13 章驱动（无参运行，简单程序对账协议）：
//   一、静态检查（求值前）：四类违规程序被拒 + 诊断行号；
//   二、解释执行：闭包计数器、嵌套捕获、递归（if/else 两支都赋值才过检）、
//      遮蔽、立即调用——输出逐行对账；
//   三、环境链观测：Environment 节点创建数与手推一致；
//   四、运行时兜底：闭包元数不符在运行时被抓（静态查不到的那类）；
//   五、断言汇总。
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "interp.hpp"

namespace {

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    std::string syntaxError;
};

// 语法错误收集（第 12 章同款）：ANTLR 默认打印并容错继续，坏树不能进
// 后续阶段——收集到即判"语法错误"，不再 buildAst。
class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line, size_t column,
                     const std::string &msg, std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

Parsed parseProgram(const std::string &src) {
    Parsed r;
    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);
    CollectErrorListener errs;
    parser.removeErrorListeners();
    parser.addErrorListener(&errs);
    if (errs.messages.empty()) r.ast = tip::buildAst(parser.program());
    if (!errs.messages.empty()) r.syntaxError = errs.messages.front();
    return r;
}

// 一段程序的完整旅程：解析 → 静态检查 →（过检才）解释。
// 返回三元组的字符串化：检查结论 / 输出+返回 / 环境节点数。
struct RunResult {
    std::string verdict;  // "拒绝" + 诊断行 / "通过"
    std::string output;   // 解释输出（含返回行）
    int envs = 0;
};

RunResult journey(const std::string &src) {
    RunResult r;
    Parsed p = parseProgram(src);
    if (!p.ast) {
        r.verdict = "语法错误：" + p.syntaxError;
        return r;
    }
    tip::SemCheck sem;
    std::vector<tip::Diag> diags = sem.run(*p.ast);
    if (!diags.empty()) {
        std::ostringstream os;
        os << "拒绝（" << diags.size() << " 条）：";
        for (const auto &d : diags) os << "[行" << d.line << "] " << d.msg << "；";
        r.verdict = os.str();
        return r;
    }
    r.verdict = "通过";
    tip::Interpreter interp(*p.ast);
    std::ostringstream os;
    try {
        tip::Value v = interp.run("main", {}, os);
        os << "=> 返回 " << v.i;
    } catch (const tip::InterpError &e) {
        os << "运行时错误[行" << e.line << "] " << e.msg;
    }
    r.output = os.str();
    r.envs = interp.envCreated();
    return r;
}

}  // namespace

int main() {
    std::cout << "== 一、静态检查（求值前）==\n";
    // V1 确定赋值：声明到首次赋值之间读取（匠书 var a = a 窗口的 TIP 对应物）
    {
        RunResult r = journey(
            "main() { var x; output x; return 0; }");
        check("V1 使用前未赋值", r.verdict,
              "拒绝（1 条）：[行1] 使用前未赋值：x；");
    }
    // V2 确定赋值的流敏感：if 一支赋值——汇合交集为空
    {
        RunResult r = journey(
            "main() { var x; if (input() > 0) { x = 1; } output x; return 0; }");
        check("V2 分支部分赋值", r.verdict,
              "拒绝（1 条）：[行1] 使用前未赋值：x；");
    }
    // V3 元数：直接调用全局函数，静态可查
    {
        RunResult r = journey(
            "f(a, b) { return a; }\nmain() { output f(1); return 0; }");
        check("V3 直接调用元数", r.verdict,
              "拒绝（1 条）：[行2] 元数不符：f 期望 2 实得 1；");
    }
    // V4 未声明（第 12 章口径在本章作用域化版本里复现）
    {
        RunResult r = journey("main() { output y; return 0; }");
        check("V4 未声明", r.verdict, "拒绝（1 条）：[行1] 未声明：y；");
    }
    // V5 同层重复声明（参数与变量同层）
    {
        RunResult r = journey("f(x) { var x; return x; }\nmain() { return f(1); }");
        check("V5 同层重复声明", r.verdict,
              "拒绝（1 条）：[行1] 同层重复声明：x；");
    }

    std::cout << "\n== 二、解释执行（过检后才运行）==\n";
    // P1 闭包计数器：两个闭包各持各的环境；同一闭包跨调用保状态
    {
        RunResult r = journey(
            "counter() {\n"
            "  var c;\n"
            "  c = 0;\n"
            "  return fun (n) { c = c + n; return c; };\n"
            "}\n"
            "main() {\n"
            "  var inc1, inc2;\n"
            "  inc1 = counter();\n"
            "  inc2 = counter();\n"
            "  output inc1(1);\n"
            "  output inc1(1);\n"
            "  output inc2(1);\n"
            "  return 0;\n"
            "}\n");
        check("P1 判定", r.verdict, "通过");
        check("P1 输出", r.output, "1\n2\n1\n=> 返回 0");
        check("P1 环境节点数", std::to_string(r.envs), "7");
    }
    // P2 嵌套捕获三层 + 调用链
    {
        RunResult r = journey(
            "adder(x) {\n"
            "  return fun (y) { return fun (z) { return x + y + z; }; };\n"
            "}\n"
            "main() {\n"
            "  var p;\n"
            "  p = adder(1)(2)(3);\n"
            "  output p;\n"
            "  return 0;\n"
            "}\n");
        check("P2 判定", r.verdict, "通过");
        check("P2 输出", r.output, "6\n=> 返回 0");
    }
    // P3 递归 + if/else 两支都赋值（V2 的合法对照）
    {
        RunResult r = journey(
            "fact(n) {\n"
            "  var r;\n"
            "  if (n == 0) { r = 1; } else { r = n * fact(n - 1); }\n"
            "  return r;\n"
            "}\n"
            "main() {\n"
            "  output fact(5);\n"
            "  return 0;\n"
            "}\n");
        check("P3 判定", r.verdict, "通过");
        check("P3 输出", r.output, "120\n=> 返回 0");
    }
    // P4 局部遮蔽全局函数名（名字在不同时刻指向不同实体）
    {
        RunResult r = journey(
            "f(x) { return x + 1; }\n"
            "main() {\n"
            "  var f;\n"
            "  f = 3;\n"
            "  output f;\n"
            "  return 0;\n"
            "}\n");
        check("P4 判定", r.verdict, "通过");
        check("P4 输出", r.output, "3\n=> 返回 0");
    }
    // P5 立即调用 + 形参遮蔽外层变量（遮蔽合法的活证）
    {
        RunResult r = journey(
            "main() {\n"
            "  var x;\n"
            "  x = 1;\n"
            "  output (fun (x) { return x + 10; })(5);\n"
            "  output x;\n"
            "  return 0;\n"
            "}\n");
        check("P5 判定", r.verdict, "通过");
        check("P5 输出", r.output, "15\n1\n=> 返回 0");
    }
    // P6 while 循环（含计数闭包改写外层值；TIP 比较只有 > 与 ==，条件用 3 > i）
    {
        RunResult r = journey(
            "main() {\n"
            "  var i, s, bump;\n"
            "  i = 0;\n"
            "  s = 0;\n"
            "  bump = fun () { i = i + 1; return i; };\n"
            "  while (3 > i) { s = s + bump(); }\n"
            "  output s;\n"
            "  output i;\n"
            "  return 0;\n"
            "}\n");
        check("P6 判定", r.verdict, "通过");
        check("P6 输出", r.output, "6\n3\n=> 返回 0");
    }

    std::cout << "\n== 三、运行时兜底 ==\n";
    // 闭包调用的元数静态查不到（被调者的值运行时才定）——运行时兜底
    {
        RunResult r = journey(
            "main() {\n"
            "  var g;\n"
            "  g = fun (a) { return a; };\n"
            "  output g(1, 2);\n"
            "  return 0;\n"
            "}\n");
        check("R1 判定", r.verdict, "通过");
        check("R1 运行时元数", r.output, "运行时错误[行4] 元数不符（运行时）：期望 1 实得 2");
    }

    std::cout << "\n== 四、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（21 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
```

驱动把每段语料的旅程装进 `journey` 函数：**解析 →（无语法错）静态
检查 →（无诊断）解释**——三段瀑布，每段失败即止，后面的段不执行。
这个形状本身就是本章的论点：检查先于运行，拒绝有理由、运行有前提。

`journey` 五步走读（实现约二十行，结构与语义的对应关系如下）：
①`parseProgram` 收集语法错（ANTLR 错误监听器），非空即以"语法错误"
返程——**坏树不进任何后续阶段**（本条规则在最初实现缺席时，一段
坏语料把空指针送进了求值器，崩溃于 `unique_ptr` 断言——教训与
第 12 章相同：容错解析产出的残树必须当错误处理）；②`SemCheck::run`
产诊断清单，非空即"拒绝"返程（带全部诊断，不只第一条——排错要
看全景）；③`Interpreter` 构造（全局环境+函数表）；④`run("main")`
求值，输出进 `ostringstream`（**先收全、后比对**，中间不打印——
判定与输出两条断言才互不干扰）；⑤`catch (InterpError)` 把运行时
错误翻译成受控文本行。五步各自产出的** verdict 前缀**不同（语法
错误 / 拒绝 / 通过 / 运行时错误），期望输出因此可分类扫读。

语料十二段的考点表：

| 段 | 语料 | 考点 |
|---|---|---|
| V1 | `var x; output x;` | 确定赋值：声明即读 |
| V2 | if 单支赋值后读 | 交集规则：部分赋值不算数 |
| V3 | 两参函数传一参 | 直接调用元数静态查 |
| V4 | `output y;` | 未声明（作用域化 resolver） |
| V5 | 参数与变量同名 | 同层重复声明 |
| P1 | 双计数器 | 捕获即共享/跨调用保状态/各持各的环境/环境节点账 |
| P2 | `adder(1)(2)(3)` | 嵌套捕获三层 + 链式调用 |
| P3 | 阶乘（if/else 都赋值） | 交集规则的合法对照 + 递归 |
| P4 | 局部遮蔽全局函数名 | 绑定次序（名字不同时刻不同实体） |
| P5 | 立即调用 + 形参遮蔽 | 遮蔽合法的活证 |
| P6 | while + bump 闭包改外层 | 循环 + 可变共享回流 |
| R1 | 闭包传错元数 | 运行时兜底（静态查不到的那类） |

设计上有两个刻意的对称：V2 与 P3 同为"if 后读变量"，一拒一收，把
交集规则的两面各给一个证人；V3 与 R1 同为元数错误，一静一动，把
拦截分界线画给读者看。P1 一段身兼四职（判定、输出、环境节点数、
正文逐帧推演的素材）——**语料宁少而每段多重证人，不多而单薄**。

### 13.6.1　期望输出的生成与字节一致契约

`expected/output.txt` 由二进制实跑重定向生成（`tipa > expected/
output.txt`），不经手改。这背后是三层字节契约：其一，**生成侧**——
期望文件只能由实跑产生；其二，**对账侧**——`check_example` 比对
stdout+stderr 合并与退出码；其三，**内嵌侧**——`check_docs` 校验
正文里嵌的期望块与仓库文件**逐字节**一致（`; expected:` 围栏由
`renumber4.py embed` 阶段从文件重灌，正文谁手改一行，embed 一跑就
打回原形）。三层契约都指向同一个纪律：**期望输出是证据，不是文档**
——它的一切变更都必须能追溯到二进制的变更（改语料、改实现、改诊
断文案，都重跑生成）。反向操作（手改期望迁就实现）在教程流程里没
有入口，这就是"机器证人"四个字的制度保证。顺带一条家规：重定向
生成在 MSYS2 bash 里做（行尾 LF，仓库统一）；若在别处生成出
CRLF，`check_docs` 的字节比对立刻红——**编码与行尾问题在这条契约
面前无藏身处**（run-all 的历史教训，家规皆有出处）。

`check` 协议与第 9 章同款：打印实算值、失败才显期望、末段退出码
守红绿。期望输出文件因此仍是"可执行讲义"。

`journey` 的三段瀑布值得读实现：语法错（ANTLR 错误监听器收集，第
12 章同款 CollectErrorListener）→ 静态诊断（SemCheck）→ 解释
（try/catch InterpError）。**每段的失败形态不同**：语法错打印
ANTLR 原文、静态诊断打印 `[行N] 消息`、运行时错误打印
`运行时错误[行N]`——三种前缀让期望输出一眼可分类，读者扫读时能
立刻知道每行属于哪一段的管辖。这个"输出即分层数据"的习惯在教程
后续章节（第 20 章堆账、第 65 章定理输出）会越用越重。

语料设计的两条原则也交代给读者，方便自己扩语料时保持同款风格：
**对称出证人**（V2/P3 与 V3/R1 两对，一拒一收或一静一动，规则的两
面各配一个）；**一段多证**（P1 一段身兼四职）。反面是"一段一证"
的碎片化——二十段语料各查一件事，输出膨胀而信息密度下降。读者
为练习扩语料时，先问"这段能不能再兼任一个考点"，答案通常是有。

## 13.7　期望输出解读

读这份输出的地图：四个分组对应旅程的四道闸门（静态检查 → 判定 →
输出 → 运行时兜底），每行"= "后面是**实算值**（不是期望值的回声
——期望只在 FAIL 时显示），所以每个数字背后都应能指认出正文的
一处推演（哪一节哪张表）；指认不出的行，就是值得回去补的洞。

```text
; expected: expected/output.txt
== 一、静态检查（求值前）==
ok   V1 使用前未赋值 = 拒绝（1 条）：[行1] 使用前未赋值：x；
ok   V2 分支部分赋值 = 拒绝（1 条）：[行1] 使用前未赋值：x；
ok   V3 直接调用元数 = 拒绝（1 条）：[行2] 元数不符：f 期望 2 实得 1；
ok   V4 未声明 = 拒绝（1 条）：[行1] 未声明：y；
ok   V5 同层重复声明 = 拒绝（1 条）：[行1] 同层重复声明：x；

== 二、解释执行（过检后才运行）==
ok   P1 判定 = 通过
ok   P1 输出 = 1
2
1
=> 返回 0
ok   P1 环境节点数 = 7
ok   P2 判定 = 通过
ok   P2 输出 = 6
=> 返回 0
ok   P3 判定 = 通过
ok   P3 输出 = 120
=> 返回 0
ok   P4 判定 = 通过
ok   P4 输出 = 3
=> 返回 0
ok   P5 判定 = 通过
ok   P5 输出 = 15
1
=> 返回 0
ok   P6 判定 = 通过
ok   P6 输出 = 6
3
=> 返回 0

== 三、运行时兜底 ==
ok   R1 判定 = 通过
ok   R1 运行时元数 = 运行时错误[行4] 元数不符（运行时）：期望 1 实得 2

== 四、断言汇总 ==
全部通过（21 项）
```

第一组五行是静态检查的签收单。V1、V2 的行号都是 1——两段语料的
使用点都写在第 1 行；V3 的行号 2 说明**跨函数的诊断也带准行号**
（f 在第 1 行、违规调用在第 2 行）；V5 的行号 1 是函数头声明所在的
行（`FunDecl::line`）。每条诊断"行号 + 名词化消息"（未声明：y /
使用前未赋值：x / 元数不符：f 期望 2 实得 1），与第 4 章 ANTLR、
第 12 章 resolver 的诊断风格一脉。

第二组十二行是解释执行的签收。P1 的三行输出 `1 2 1` 是闭包语义的
三连证（§13.3 逐帧推演过）；P1 环境节点数 7 的账在 §13.8 单独算；
P2 的 6 是三层链 `x+y+z` 的和；P3 的 120 是五层递归的阶乘；P4 的 3
（不是函数）证明局部遮蔽静态裁决 + 动态取值一致；P5 的 `15 1` 两行
并排——内层读到形参、外层未被波及，遮蔽的隔离性一目了然；P6 的
`6 3`——s 累了 1+2+3，i 被闭包推到 3，共享回流的账面。

第二组十三行的输出值与推演对照（推演细节都在 §13.2/13.3，这里是
总账）：

| 断言行 | 值 | 语义要点 |
|---|---|---|
| P1 判定/输出 | `1 2 1` | 共享、保状态、各持各的 |
| P1 环境节点数 | 7 | §13.8 的账 |
| P2 输出 | 6 | 三层链各取所长 |
| P3 输出 | 120 | 递归 + if/else 双赋值过检 |
| P4 输出 | 3 | 局部遮蔽全局函数 |
| P5 输出 | `15 1` | 形参遮蔽 + 外层无恙 |
| P6 输出 | `6 3` | bump 改外层 i、s 累加 |

第三组 R1 一行：运行时错误带行号 4（调用发生处）。注意它的判定行
是"通过"——静态检查无话可说（g 的值运行时才定），这才是"兜底"
的准确含义：**不是检查失败，是检查无权发言**。

末行"全部通过（21 项）"收口。逐行导读补充两处容易看漏的细节：P1
的"判定 = 通过"与"输出 = 1 2 1"是**两条独立断言**——前者签字
"静态检查没话说"，后者签字"解释器算对了"，V 系列的存在让"通过"
一词有了可检验的含义（不是没跑，是查过没事）；R1 的判定同样是
"通过"——第 13.5 节说过的"检查无权发言"，在输出里就长这样。

二十一项按组清点：静态 5（V1–V5）+ 解释 13（P1×3、P2–P6 各 2）+
运行时兜底 2（R1 的判定与输出）+ 汇总 1（末行）——5+13+2+1=21，
对账表的行数与断言计数一致，这是 `check` 协议的自检性质：**汇总
行声称的数字必须能被逐行数出来**。

再给静态组五行一份"诊断解剖"导读——每条诊断的消息结构都是
`[行N] 检查名：名字（+参数）`：

| 行 | 诊断 | 窗口在哪儿 | 谁关的窗 |
|---|---|---|---|
| V1 | 使用前未赋值：x | 声明到首次赋值 | 确定赋值 |
| V2 | 使用前未赋值：x | if 汇合后（交集空） | 确定赋值 |
| V3 | 元数不符：f 期望 2 实得 1 | 调用点对声明 | 函数表静态查 |
| V4 | 未声明：y | 全程序 | 作用域栈 |
| V5 | 同层重复声明：x | 函数头声明组 | 作用域栈 |

五行恰好覆盖 §13.5 说的四种窗口形态（时间段、路径汇合、声明-使用
对照、命名空间结构）——**静态检查的分类学就是"窗口的分类学"**。

## 13.8　环境节点的手推账

P1 断言 `envCreated() == 7`。账目逐项列：

| # | 节点 | 由谁创建 |
|---|---|---|
| 1 | 全局环境 | Interpreter 构造 |
| 2 | main 调用环境 | run → callClosure |
| 3 | counter 第一次调用的 E1 | 同上 |
| 4 | counter 第二次调用的 E2 | 同上 |
| 5 | inc1 第一次调用（父=E1，n=1） | 求值 inc1(1) |
| 6 | inc1 第二次调用（父=E1，n=1） | 同上 |
| 7 | inc2 调用（父=E2，n=1） | 同上 |

恰好 7。注意两个"不是节点"的东西：**闭包本身不创建环境**（创建时
只存指针）；**P1 没有显式内层块**（块才建块环境）。若把这两个"不"
反过来写错，账就会多——最初的实现确实多出了 6 个（每次调用的体块
环境，§13.2 的设计决定），断言红掉后修好。这个账的教学价值在预告：
第 57 章的上值实现里，同样的程序**一个环境链节点都不建**——捕获
变量搬进堆上的小盒子，环境链被彻底消灭；届时请回来对照 P1 在两种
实现下的节点数（7 对 0）与输出（相同）。**实现可以天差地别，语义
由对账统一**——这是双实现等价证人思路的完整形态。

**异常方案的第二张账单**（§13.4 底稿之外的工程细节）：栈展开本身
有成本（C++ 的零成本异常模型只在"不抛"时零成本，抛一次比一次函数
返回贵一到两个数量级）；调试器在异常断点上看不到"这是控制流不是
错误"的标注（jlox 的 Return 会被误当成崩溃，匠书专门提示读者在
IDE 里忽略它）；混用后**真错误**的栈展开路径与 return 的展开路径
重合，性能剖析无法区分。三条都是"用异常做控制流"的既有代价，
教程语料无感（无性能断言、无调试器交互），但读者写真解释器时会
逐条遇到——届时回看这一段，按需换成返回码或 longjmp。

环境链与第 19 章（活动记录）的预算对照也在这里立好：环境链的每个
节点都是堆对象（`shared_ptr` 分配），名字查找爬链 O(深度)；活动
记录的帧在**栈**上、访问链/display 也在栈上，帧随返回消失——所以
纯栈式语言（无闭包）不需要本章的任何机制。**闭包把"变量的家"从
栈上搬到了堆上**，这是函数式特性给运行时下的最大一笔税单；三种
缴税方式（整链常驻/装箱单/上值）就是上一节那张对照表的另一面。
第 20 章（垃圾回收）接的正是这笔税的下游：堆上的环境与闭包谁没
人引用了、谁来回收。

环境账还有个"可加性"性质，读者可以用它自测推演功力：每段程序的
节点数 = 1（全局）+ 每次函数调用 1 + 每个显式块 1。P2 算 5、P3 算
7（递归五层）、P5 算 3、P6 算 5——正文走读过，现在遮住答案自己推
一遍，再改一行语料（比如 P6 的 while 体加一层块）预测增量，跑
`envCreated()` 验证。**账目规则三句话、程序千变万化**——能对任意
改写的语料预测账，才算真正把"哪一步建环境"内化了。

### 13.8.1　回望与接驳

本章兑现了 §13.0 开出的三张支票：环境链（13.2，含双账表与不变
式）、闭包一行定义（13.3，三个语料三面语义）、求值前静态检查
（13.5，四项 + 保守方向）。向后看，本章在三条线上埋了接驳点：
**第 54–57 章**（字节码线）以本章为语义基准——同一批语料（计数
器、加法器链）将在栈机与上值实现下重跑，输出必须与本章逐行全等，
环境节点账 7 对 0 的对照是那条线的收官断言；**第 20 章**（GC）的
根集概念已经在"全局表不是垃圾"与"被捕获环境长存"两处埋线；
**第 19 章**（类型）将与本章检查器共用"遍历一次、多查并发"的
经济结构。读者若中途跳章，从任何一处接回来都能找到路标。

给后续章节的接口也清点一下（"冻结"自第 12 章延续）：本章**新增**
的公共资产是 `FunLit` 节点（AST 家族 +1，其行所有分析章节都要在
遍历里加一个 case——这是文法扩展的真实成本，第 13.6 FAQ 说过）
与"诊断 + 行号"协议（第 19 章类型错误沿用）；本章**没有**冻结的
是 Environment/Closure 的内部形状——54 章起换成帧与上值，语义
由对账统一、实现各章自便。**接口冻结的是"语料与期望输出"，不是
实现**——这是教程用机器证人换来的自由度。

## 13.9　小结与练习

**小结**：树遍历解释器 = eval/exec 骨架 + 环境链 + 闭包一行定义 +
求值前静态检查。环境链让"作用域"成为运行时的一等公民：一个节点
一个作用域，取值沿链爬、赋值沿链写**定义处**，块进建退弃，被捕获
的环境因引用计数而长存。闭包 = 身体 + 定义时环境，捕获即共享、
赋值即回流——计数器、嵌套捕获、循环改外层三个语料把语义三面全部
签收。return 的位置是文法课：Lox 的任意位置 return 需要非局部退出
（异常），TIP 的尾 return 什么都不需要——文法设计消掉了运行时机制，
代价是把提前返回翻译成给结果变量赋值（SSA 的雏形）。静态检查四项
（未声明/重复、确定赋值、直接调用元数、运行时兜底）在求值前拦截，
其中确定赋值是数据流分析的第一次出场：集合、交集、拷贝传播，保守
方向"不误报宁漏报"。环境节点数进入断言——结构账与输出账同权。

如果只允许带三句话离开本章：**闭包是"身体 + 定义时环境"两个词的
组合，环境链是"一个作用域一个节点、读写都找定义处"两句话的协议，
静态检查是"窗口分类学 + 保守方向"一对概念的反复应用**——语料会
忘，这三句会留下，后面的章节全盖在这三句上。

### 13.9.1　伏笔索引：本章埋向全书的十个接点

| # | 本章埋点 | 后文兑现 | 距离 |
|---|---|---|---|
| 1 | 环境链节点数断言（P1=7） | 第 57 章上值同语料 0 节点 | 第十篇 |
| 2 | 闭包 = 身体 + 环境指针 | 第 57 章上值改"身体 + 捕获盒" | 第十篇 |
| 3 | 确定赋值（集合/交集/拷贝） | 第 25 章工作表、第 28 章交集 join、第 31 章框架定理 | 第五篇 |
| 4 | "宁漏报不误报"的保守方向 | 第 19 章类型检查的反向取舍、第 59 章抽象解释的可靠性定理 | 第四/十二篇 |
| 5 | 元数的静态/运行时分界线 | 第 48 章 0-CFA 推线、第 47 章上下文敏感 | 第八篇 |
| 6 | 全局表 = GC 根集的一部分 | 第 20 章标记清除的根集枚举 | 第三篇 |
| 7 | 被捕获环境长存（堆分配） | 第 20 章可达性、第 57 章存活分析 | 第三/十篇 |
| 8 | FunLit 进 AST（消费者 +1 规则） | 第 19 章约束收集、第 48 章闭包分析各加一个 case | 第四/八篇 |
| 9 | 闭包相等性含糊（可变破坏值语义） | 第 56 章字符串驻留的反面参照 | 第十篇 |
| 10 | 函数体 BlockS 不再包环境（账面修正） | 第 54 章 CallFrame 布局的同源设计决定 | 第十篇 |

表按"埋点 → 兑现章 → 距离"组织，距离越远的伏笔越容易忘——读者
读到第五篇做数据流时若感到"似曾相识"，回来查这张表；反过来，从
第 57 章回望的读者也能从这里找到本章的原文位置。**教程的结构本质
上就是一张伏笔画布**，每轮扩充（龙/虎/鲸/匠四书）都在旧画布上添
新接点，本章作为匠书线的第一章，埋的十个点分布在七篇里——这正是
"取材一本书、消化进全教程结构"的写法本身。

本章文件与角色清单（全部字节级内嵌于上文，此处是检索表）：

| 文件 | 行数 | 角色 |
|---|---|---|
| `TIP.g4` | 64 | 文法（+fun 字面量扩展） |
| `src/ast.hpp` | 123 | AST（+FunLit、五处行号） |
| `src/ast_build.hpp/.cpp` | 31+145 | ANTLR 树 → AST 构建器 |
| `src/interp.hpp/.cpp` | 119+312 | SemCheck + Interpreter |
| `src/main.cpp` | 256 | 十二段语料与 21 项断言 |
| `expected/output.txt` | 38 | 期望输出（二进制实跑生成） |

九个文件、一千一百余行——其中四分之三是与第 12 章共用的前端资产
的本地副本，本章真正的新代码（SemCheck 与 Interpreter）约四百行。
**"新代码四百行 + 共享资产复用"**是教程多轮扩充的标准经济结构：
每一章都站在前一章的文件上，只写自己主角的部分。这也是读者评估
自己实现时的换算表：若你的树遍历解释器远超四百行，多半是把前端
（词法/语法/AST 构建）也算进去了——那部分在工业界同样是复用
生成器的，与逻辑无关。

### 常见问题（FAQ）

**问：为什么用 `dynamic_cast` 链分派而不用 visitor？** 第 10 章的
visitor 是"一次造访、全家受益"的正排——加一种遍历要给所有节点加
方法；本章的遍历有两棵树（表达式/语句）且每类节点的动作差异大，
`if (auto *x = dynamic_cast<…>) return;` 的直排与"读一类节点做
一件事"的心智对齐。两种都是工具箱常客：第 10 章定型 visitor 的
场合（属性文法），本章定型直排的场合（求值器）。匠书 jlox 用
visitor（Java 生态成熟），clox 干脆没有 AST（单遍）——**分派方式
跟着架构走，不跟着品味走**。

**问：`shared_from_this` 是什么，为什么需要？** `FunLit` 求值要
"把当前环境存进闭包"——当前环境是以 `Environment&` 引用的形态
到达的，而闭包要持**所有权的** `shared_ptr`。
`enable_shared_from_this` 让被 shared_ptr 管理的对象在成员函数里
拿到管理自己的那份指针（`shared_from_this()`）。代价是必须保证
对象**确实**活在 shared_ptr 里（本实现的环境一律经 `newEnv` 创建，
满足）。这是 C++ 特有的沟坎——Java/JS 的对象引用天然"可存"，
垃圾回收兜底；C++ 要把"引用"翻译成"共享所有权"，多出来的这两
行样板就是那次翻译的手续费。

**问：SemCheck 与 Interpreter 为什么分成两个类？** 三个理由：
拒绝的粒度（检查不过整程序不跑——求值器里做不了这个决定）；
复用（第 19 章类型检查要跑在确定赋值前还是后？分开才能编排）；
测试（诊断的期望输出与解释输出的期望输出是两组不同的断言——
本章 V 系列与 P 系列天然分治）。jlox 的 Resolver 与 Interpreter
分开是匠书的原设计，理由同款。

**问：环境查找爬链，性能不是 O(深度) 吗？** 是。三层嵌套里取最外
层变量要过两跳 map 查找。工业级解法即"把深度静态算好、把 map 换
成槽位数组"——第 55 章的编译期槽位正是这一步（届时环境链整个退
役，取值变成"帧基 + 常量偏移"一次寻址）。本章保留爬链是把语义
写在明面上：**先正确、再快，快的那版另有专章对账**。

**问：为什么 fun 字面量加了、块级 var 不加？** 两者都是文法扩展，
但成本结构不同：fun 是**表达式**——进 AST 一个节点、进环境一个
闭包值，其他章节能无视它；块级 var 要动声明语句的 AST、动
`declare` 的调用点、动确定赋值的初始集（每块一个新的"已赋值"
边界），牵动面大而教学增量小（遮蔽语义 P5 已演示）。**扩展的
准入标准是"新增语义与既有章节的接口面最小"**——幂（第 9 章）与
fun（本章）都过了这道门，块级 var 没过，留作练习 3 让读者亲手做，
做完会体会到这条标准的意义。

**问：递归没有深度保护，深递归会怎样？** P3 只递归五层；把语料改成
`fact(100000)`，C++ 解释器自己的调用栈先爆（eval/exec 的递归深度
约等于 TIP 程序的调用深度乘个常数），现象是进程崩溃而非诊断。第
54 章的 VM 有显式的 `FRAMES_MAX` 上限与"栈溢出"诊断——**把宿主
的栈换成自己的帧数组，才谈得上保护**；树遍历解释器借宿主的栈，
也就继承了宿主的崩溃方式。这是"树遍历简单"的隐性账单之一（另一
张见下一问）。

**问：output 为什么是语句不是内建函数？** TIP 把 IO 做成语句，
求值器就不需要"内建函数"这个概念（jlox 的 clock、Python 的 print
都要内建注册表）——少一张表、少一层"用户函数/内建函数"的分派。
代价是 output 不能当值传递（不能 `map(output, xs)`）。教学口径下
这是笔好买卖：**把语言做小，把机制做少，每个机制才教得透**——
输出重定向已经用 `out_` 指针解决了对账需求（§13.6），内建函数表
的功能等第 56 章的散列表再正式上。

**问：Value 为什么没有 nil/bool/string？** jlox 的值宇宙有它们，
每个都拖着语义坑：nil 与 false 在 Lox 里都算假（匠书专门写了一节
"Truthiness and Falsiness"讨论这选择的是非）；string 引出驻留与
相等语义（第 56 章主角）；bool 在 TIP 里就是整数（比较返回 0/1，
第 3 章口径）。本章取"整数 + 闭包"最小宇宙，正是为了让环境链与
闭包这两个主角**没有配角抢戏**——值宇宙每加一员，运行时账面都
会多一列，那一列留给值表示专章去算。

**问：这套解释器与后面的分析章节怎么复用？** AST 是全教程的公共
IR（自第 12 章冻结接口），本章给 AST 配了"带语义的消费者"（解释
器）与"带诊断的消费者"（检查器）——第 19 章类型约束收集是第三个
消费者、第 48 章 0-CFA 是第四个。**消费者越多，AST 接口冻结得越
值钱**；反过来，读者给自己写分析时的第一反应也应该是"能不能作
为又一个消费者插上去"，而不是另起一套表示。

**问：行号为什么进 AST（VarRef/CallE/AssignS/FunLit/FunDecl 五处），
而不是诊断时反查源码位置？** 反查需要保留 token 流到 AST 之外的
位置映射（每个节点 ↔ 区间），表更重、生命周期更长；把行号**随着
需要的节点走**是"按需携带"——本章五类诊断（未声明、重复声明、
未赋值、元数、运行时错误）各只需要一处行号。代价是 AST 长了几个
int 字段、构建器多几行赋值。工业前端通常走完整的"节点带区间"
路线（诊断要画波浪线需要列跨度），教学取最小够用——**元数据跟着
消费者需求走，不跟着完备主义走**。

**问：诊断清单为什么保持发现顺序、不去重、不设上限？** 顺序 =
遍历序 = 源码序，读者按行读程序时诊断也按行到达（V 系列每段恰
一条是语料设计，不是检查器保证——一个程序可以吐多条）；去重会
把"同一名字两处未赋值"折叠掉（排错时两处都要看）；上限（如
"最多报 20 条"）是大型编译器的降噪手段，教学语料永远不到量。
三条都遵循同一原则：**诊断的形态服务排错，不服务美观**。

**问：为什么所有检查在 `run` 里一次性跑完，而不是"解释到哪儿查到
哪儿"？** 一次性跑完保证"拒绝的程序绝不动解释器半步"——V1 那
种未赋值读取如果靠运行时拦截，占位 0 可能已经流进了一半计算再
报错，诊断现场离病灶十万八千里。先全体检查、后整体运行，把**所有
静态可见的错误**在求值前曝光，这是"求值前"三个字在流程上的严格
含义（§13.0 第 3 条资产）。代价是"第一条错误后面的检查继续跑"（有
些工程编译器第一条 fatal 即停）——教学取舍偏向曝光量：诊断是
读者看清规则的窗口，多一条多一分教材。

### 自查清单与术语表

**自查清单**（不看书能答即过关；答不出的题号即回炉小节号，与上面
十题一一对应——这是本教程自查清单的固定形态：**问题与出处双向
可检索**，清单不是测验，是目录的另一种排法）：

1. define 与赋值的差别是什么？各自写进环境链的哪一层？
2. `callClosure` 造新环境时父指针指向谁？换成调用者会变成什么
   作用域规则？
3. P1 的第 7 个环境节点是哪次调用建的？E1 为什么不随 counter 返回
   而销毁？
4. 确定赋值在 if 汇合处取什么集合运算？为什么？
5. "被捕获的变量豁免确定赋值"是宁漏报还是宁误报？这个方向的
   取舍对 lint 类与类型类检查分别怎么选？
6. V3 静态查、R1 运行时查——分界线的判据是什么？
7. TIP 为什么不需要 ReturnSignal？Lox 靠什么实现它？
8. P5 的立即调用在环境账上建了几个节点？其中几个是"跳板"？
9. 环境链、装箱单、上值三种闭包实现的捕获粒度各是什么？
10. 本章的静态检查与第 12 章的名字解析是什么关系？（分工：指谁
    vs 值在哪；嵌套：扁平两层 vs 作用域栈。）

**术语表**：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| 环境链 | 作用域的运行时形态：节点+父指针 | §13.2 |
| 沿链写回 | 赋值找到定义处槽位就地写 | §13.2 |
| 跳板节点 | 仅为提供父链而存在的空环境 | §13.2.1 |
| 闭包 | 身体 + 定义时环境的值 | §13.3 |
| 共享式捕获 | 捕获者与被捕获层共用槽位（可变回流） | §13.3 |
| 复制式捕获 | 创建时拷贝值的对立方案 | §13.3 |
| 非局部退出 | 一步穿透多层调用返回的机制 | §13.4 |
| 确定赋值 | 每次使用前必有先前赋值的静态检查 | §13.5 |
| 捕获豁免 | 被捕获名字免受确定赋值检查 | §13.5 |
| 运行时兜底 | 静态查不到的错误交给运行时拦 | §13.5 |
| 环境节点账 | 环境创建数作为结构断言 | §13.8 |
| 真值口径 | 非零为真（TIP 无布尔类型） | §13.1 |
| 窗口 | 名字处于中间状态的程序时间段 | §13.5 |
| 归属唯一 | resolve 只命中最近包围层一个槽 | §13.2 |
| 槽位稳定 | 变量生存期内读写同一槽位对象 | §13.2 |

**练习**（难度三档：★ 改一行看涟漪、★★ 扩展一个机制、★★★ 全流程）：

1. ★：沿链写回改成就地 define——P1 的输出会变成什么？
2. ★：加"未使用变量"检查——方向取舍与被捕获算不算使用。
3. ★★★：块级 var 扩展（文法 → AST → 构建 → 检查 → 解释五处）。
4. ★★：结果参数实现任意位置 return，对照 §13.4 底稿。
5. ★：P1 加一行调用的环境账增量（恰一个节点）。
6. ★★：构造"循环保证至少一圈"语料证明 while 交集规则的盲区。
7. ★★：P2 环境链图与上值版对照图（第 57 章预告）。
8. ★★：FunDecl 统一包装成 FunLit 消除调用分支。
9. ★★：values 换 vector 的性能直觉题（预测先于测量）。

1. 把 `Exec` 的赋值分支改成"当前层若无此名则 define"（不沿链写回），
   重跑 P1：输出变成什么？解释为什么闭包共享消失了，并指出这与动态
   作用域的差异（提示：改的不是父亲指针，是写回策略——两件事都
   能破坏共享，但破坏的语义不同）。
2. 给 `SemCheck` 加"未使用变量"检查（声明后从未读取即诊断）。它
   该学确定赋值的哪个方向——宁漏报还是宁误报？写两段语料各证明
   一个方向的选择后果（提示：被捕获的变量算"使用"吗？）。
3. 把 `declare` 的调用点从函数头挪进块语句（文法加 `varDecls` 进
   blockStmt，AST 加声明语句节点）：P5 的遮蔽语义会因此发生什么
   变化？写出新的违规语料"块内同名声明遮蔽外层"并给诊断。（这
   就是 jlox 的完整块级作用域。）
4. 用结果参数（`ReturnSignal*` 出参）重写一个支持任意位置 `return`
   语句的最小扩展（文法 stmt 加 `RETURN expr SEMI`）：每个 exec 分支
   需要多少处检查？与异常方案对比代码量后，解释匠书为什么选异常。
5. P1 的环境账是 7。若 main 里再加一行 `output inc1(1);`，账变几？
   先手推再跑（提示：闭包调用每次一个节点；E1 不会因新调用而增加）。
6. （进阶）确定赋值的 while 规则用"进循环前 ∩ 循环后"保守处理零次
   执行。构造一段语料，其中变量在循环体内赋值、循环后读取、且循环
   条件保证至少执行一次——本章检查会拒绝还是放行？这说明该规则
   丢掉了哪类信息？（第 34 章路径敏感分析正是为了找回这类信息。）
7. （对照）把 P2 的 `adder` 链在纸上画成环境链图（E1→E2→E3 与全局
   的父子关系），标注每个变量的槽位与每次取值走的步数；再画第 57
   章将给出的上值版本（无环境链、三个盒子）。两图输出相同——
   这就是"语义由对账统一"的图景。
8. （统一表示）在 `Interpreter` 构造时把每个 `FunDecl` 包装成一个
   "无捕获的等价 FunLit"（身体与返回表达式复用原 AST 节点指针），
   让 `Closure` 只剩 `lit` 一个来源。改完后 `callClosure` 少了几个
   分支？P1–P6 全绿吗？（提示：FunDecl 的 ret 是 ReturnS 节点，
   FunLit 的 ret 是裸表达式——包装时记得解一层。）
9. （性能直觉）把 `Environment::values` 换成 `std::vector<std::pair<
   std::string, Value>>`（线性扫描），在 P6 上跑一万次循环对比
   耗时。解释为什么"变量数是个位数"时线性扫描反而可能赢（缓存
   友好、无树节点分配），以及这个结论什么时候反转（变量上百、
   查找频繁——正是 V8 用槽位数组的理由）。

做题姿势与第 9 章同款：先纸上预测（输出行、环境账、诊断文本），
再改代码跑对账。练习 1、2、8 是"改一处看涟漪"；3 是文法扩展全
流程；9 是本章唯一性能题——**预测数字先于测量**，错了才知道直觉
哪里歪。逐题提示：题 1 改完先预测 P1 的输出形态（两个 inc 还独立
吗？跨调用还保状态吗？两个答案组合出四种可能，先押一种）；题 2
想清楚"被捕获算不算使用"会翻转哪段语料的判定方向；题 5 的增量恰
是一个节点；题 6 的语料要构造"循环内赋值、循环后读取、且条件保证
至少一圈"——本章检查必拒（while 交集规则看不见"至少一圈"），
被拒绝这件事本身就是答案的一半。

---

（第 13 章完——下一章：控制流图，树摊成图，分析与优化才真正开场。）

**一句收束**：环境链是作用域的运行时肉身，闭包是它不肯死的那部分——
后续四十章都在这两句话的延长线上工作。
