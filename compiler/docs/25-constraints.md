# 第 25 章　约束收集：把类型规则写成可求解的等式

第 24 章建立了类型的词汇表：`int`、`ptr(τ)`、函数类型、记录类型与
类型变量，并通过推导规则回答了"什么样的程序是良类型的"。但规则只是
**声明式**的描述——它告诉我们一个良类型程序应当满足什么，却没有给出
一台机器可以逐步执行的算法。本章补上分析的前半个算法：遍历一遍程序，
不为任何位置直接计算类型，而是生成一组**类型等式**（约束）；等式如何
求解是第 26 章的内容。这种"先列方程、再解方程"的两段式组织，是本书
全部类型分析的骨架，也是后面数据流分析中"声明性质 + 不动点算法"
结构的先声。

## 25.1 为什么不能直接算出每个表达式的类型

初学者自然的想法是：像第 12 章构建 AST 那样，写一次递归遍历，遇到
字面量就返回 `int`、遇到加法就检查两个子表达式、遇到变量就查表——
自上而下把每个表达式的类型"算"出来。这个方案在最简单的直线程序上
可以工作，但一旦面对真实的 TIP 程序，立刻撞上三堵墙。

**第一堵墙：信息的流动方向不总是与语法树的遍历方向一致。** 变量
`x` 的类型由它在某处被赋值的表达式决定，可使用点在源程序里可能出现
在赋值点**之前**（前向引用），也可能经过循环反复出现。函数 `add1`
在 `main` 里被调用时，它的定义可能在文件后面。一次自上而下的遍历
到达使用点时，需要的信息根本还不存在；若改成多遍扫描，遍数又依赖
程序形状——相互递归的函数群要求所有函数先被看见。

**第二堵墙：同一个名字要服务多个使用点，类型信息只能存一份。**
若在每个使用点就地复制一份"算出来的类型"，那么当多个使用点对同一
声明提出要求时（一处把它当整数、另一处把它当指针），算法必须有
一个地方把这些要求汇集起来并发现冲突。这张表要以谁为键、何时更新、
冲突何时报告，本身就需要设计。

**第三堵墙：判定与构造纠缠。** "直接算类型"的算法在每一步同时做
两件事：推断此处类型是什么、判定它与上下文是否相容。一旦算错方向
（例如把参数类型与返回类型的连接写反），错误会以难以追踪的方式
传播。我们更希望把**程序要求什么**与**要求能否被满足**分开：前者是
遍历程序就能机械完成的语法工作，后者交给一个独立的、可单独论证的
求解器。

约束方法正是对这三堵墙的统一回应。核心转换可以一句话概括：

> 不再问"E 的类型是什么"，而是为 E 指派一个**类型变量** α，然后按
> 程序结构写下"要使程序良类型，α 与其他类型项之间必须成立的等式"。

例如 `3 + 4` 不再当场折成"两边是 int、结果是 int"的判定，而是
生成三条等式：`α₁ = int`、`α₂ = int`、`α₃ = int`，其中 α₃ 是加法
表达式自身的变量。看到这里读者或许会觉得这比直接判定更啰嗦——它
确实多了记号，但换来三样关键的东西，值得提前讲明。

其一，**正确性可以局部论证**。生成器不做任何判断，它只做两件语法
操作：造一个新鲜变量、记一条等式。每一类语法构造的生成规则只有
几行、彼此独立，因此"规则是否忠实于第 24 章的类型规则"可以逐构造
核对，不需要考虑整个程序。其二，**求解器可以独立替换**。本章的等式
是标准的一阶项等式，第 26 章给出 Robinson 合一，读者也可以换成任何
等价的求解器而不动生成器一行。其三，**输出天然可解释**。每条等式
记录了它为何存在（`why` 字段），当第 27 章报告类型错误时，可以
沿等式追溯到具体的程序点与类型规则，而不是只看到一个"类型不匹配"。

### 25.1.1 与数学解方程的类比，以及类比的边界

"列方程再解方程"的直觉可以借初等代数具体化：面对文字题，我们先
设未知数、把题意逐句翻译成方程，再用代入消元求解。翻译阶段不需要
知道答案、也不需要知道方程是否有解——无解方程（如 `x = x + 1`）
同样是合法的方程，无解的事实在求解阶段才暴露。类型约束完全同构：
`x = &x` 会生成一个类似 `α = ptr(α)` 的等式，它"方程合法但无解"，
第 27 章的 occurs 检查会拒绝它。

类比也有边界，需要诚实指出。代数方程允许算术变换（把 `x+1 = 3`
化为 `x = 2`），而类型等式的两边是**符号项**，求解只做"变量绑定
项"的代换与构造子的分解，不做任何算术；类型项没有"数字运算"。
此外，类型等式天然是**无方向**的：`α = int` 与 `int = α` 是同一个
约束。这个性质至关重要——它意味着生成阶段完全不需要预判信息将来
从等式的哪一侧流过来：对 `α = int` 与 `int = α` 生成器一视同仁，
合一代换会处理绑定方向。记住"约束无方向"，后面指针三类构造的
规则方向就不会显得是任意规定。

### 25.1.2 本章在第三篇中的位置

四章的分工在此明确：第 24 章给出类型项与类型规则（规范）；本章
给出从程序到等式的翻译（约束生成）；第 26 章给出等式的求解算法
（Robinson 合一）；第 27 章把三者总装、补上 `null` 与记录的边界、
并在错误矩阵上验证。与第 17 章"翻译保语义"的论证类似，本章也将
在 25.14 节论证"约束系统可满足当且仅当程序按第 24 章规则可类型
化"——一侧是程序与规则，另一侧是等式与解，中间的翻译仍然是
论证的焦点。

## 25.2 类型的词汇表（type.hpp）

本章生成的等式两侧都是第 24 章定义的类型项，先把词汇表完整给出。
下一节的形式化与之后每条规则都引用这里的构造子；阅读后续内容时
随时回到本节对照。

```cpp
// file: src/type.hpp
// 类型的表示：具体类型构造子 + 可合一的类型变量。
// 从本章起，分析不再直接"算出"答案，而是先搭类型结构、生成约束、
// 再由第 26 章的合一求解。类型对象以 shared_ptr 共享：同一个类型变量
// 会被约束的两侧、嵌套结构多处引用，不能用 unique_ptr。
#pragma once

#include <memory>
#include <string>
#include <vector>

namespace tip {

struct Type;
using Tp = std::shared_ptr<Type>;

struct Type {
    virtual std::string show() const = 0;
    virtual ~Type() = default;
};

struct TyInt : Type {
    std::string show() const override { return "int"; }
};

struct TyPtr : Type {
    Tp to;
    explicit TyPtr(Tp t) : to(std::move(t)) {}
    std::string show() const override { return "ptr(" + to->show() + ")"; }
};

struct TyFun : Type {
    std::vector<Tp> params;
    Tp ret;
    TyFun(std::vector<Tp> ps, Tp r) : params(std::move(ps)), ret(std::move(r)) {}
    std::string show() const override {
        std::string s = "(";
        for (size_t i = 0; i < params.size(); ++i) {
            if (i) s += ", ";
            s += params[i]->show();
        }
        s += ") -> " + ret->show();
        return s;
    }
};

struct TyRec : Type {
    std::vector<std::pair<std::string, Tp>> fields;
    explicit TyRec(std::vector<std::pair<std::string, Tp>> fs)
        : fields(std::move(fs)) {}
    std::string show() const override {
        std::string s = "{";
        for (size_t i = 0; i < fields.size(); ++i) {
            if (i) s += ", ";
            s += fields[i].first + ": " + fields[i].second->show();
        }
        return s + "}";
    }
};

struct TyVar : Type {
    int id;
    explicit TyVar(int i) : id(i) {}
    std::string show() const override { return "t" + std::to_string(id); }
    // 新鲜变量编号：进程内单调递增，从 1 开始。
    static int fresh() {
        static int counter = 0;
        return ++counter;
    }
};

// 便利构造。
inline Tp tint() { return std::make_shared<TyInt>(); }
inline Tp tvar() { return std::make_shared<TyVar>(TyVar::fresh()); }

}  // namespace tip
```

这段头文件中有四个设计点支撑着约束方法，值得逐一说明。

第一，**类型变量与具体构造子同属一个类族**。`TyVar` 与 `TyInt`、
`TyPtr` 一样是 `Type`，于是等式的两侧可以统一用 `Tp` 表达：一条
等式可以是变量等于具体类型（`α = int`）、变量等于变量
（`α = β`）、也可以是变量等于含变量的复合项（`α = ptr(β)`）。
生成器无须区分这些情形——它只是把两个 `Tp` 记下来。

第二，**变量的身份是编号而非名字字符串**。`TyVar::fresh()` 进程内
单调递增，保证每个新变量编号互不相同。编号与它对应的程序位置之间
的联系只存在于收集器的映射表中（25.13 节），类型项自身不携带
源码位置——这让同一个变量能被自由地放进多个复合项而不产生重复
信息。

第三，**共享所有权是必需的而非偏好**。文件开头的注释解释了
`shared_ptr` 的理由：一个形参变量会同时出现在函数类型的分量位置、
函数体内所有使用点的等式里，这些位置必须引用**同一个对象**；当
第 26 章把变量绑定到类型项时，所有引用处通过共享指针同时观察到
绑定。若用 `unique_ptr`，同一个类型项根本无法被多处引用，复制
又会制造多个身份、破坏合一时的一致性判断。

第四，**`show()` 固定了输出语言**。变量打印为 `t1`、`t2`，指针
打印为 `ptr(...)`，函数类型打印为 `(...) -> ...`。本章 --check 的
输出完全由这些 `show` 与收集顺序决定，不含路径、时间等环境信息，
因此 expected 产物在任何机器上逐字节一致——这条原则从第 4 章起
一直被遵守。
## 25.3 形式化：变量、等式与解

在进入逐构造规则之前，先把约束系统本身形式化。记号会在全章反复
使用，先有精确定义，后面的规则就只是"按产生式写等式"。

**类型项**的文法为：

> τ ::=  int
>      |  ptr(τ)
>      |  (τ, …, τ) -> τ
>      |  { f₁: τ, …, fₖ: τ }
>      |  α

其中 α 取自一个可数的类型变量集合（实现中即编号 1, 2, 3, …）。
前四行是**构造子**：每个构造子有固定的形状，`int` 无分量，`ptr`
有一个分量，函数类型有若干参数分量与一个返回分量，记录类型有
若干命名字段分量。最后一行是**变量**：它是待填充的空位。

**标注**分两个层面。对每个表达式节点 E，收集器指定一个变量
α_E，称为 E 的节点变量；对每个语法声明 D（形参、`var` 局部、函数
名），指定一个变量 α_D，称为声明变量。节点变量与声明变量都从
同一个新鲜编号池取得，因此全局不重复。

**约束**只有一种形式：

> τ₁ = τ₂

一条约束断言两个类型项必须能被弄成相同的类型项。一个程序的约束
系统就是按其语法结构收集的有限约束集合（实现中为有序列表，次序
服务输出可读性，与逻辑意义无关）。

**解**是一个从变量到类型项的有限映射 S（称为代换），它满足每个
约束：把 S 作用在等式两侧（把其中出现的变量替换成 S 中对应的项，
反复进行直到不再变化），两侧得到**语法相同**的类型项。例如约束
`α = ptr(β)`、`β = int` 的一个解是 `{α ↦ ptr(int), β ↦ int}`；
不存在任何 S 能使 `α = int` 与 `α = ptr(β)` 同时成立——该约束
系统无解，对应程序有类型错误。

### 25.3.1 约束与第 24 章类型规则的对应

第 24 章的类型规则形如 `Γ ⊢ E : τ`（在环境 Γ 下 E 的类型为 τ），
规则的每个前提与结论都在声明某处类型相等。约束生成做的事就是把
规则中所有"同一类型"的出现用**同一个变量或同一项**表达：规则
要求"两分支汇合后的类型"，等式就把两个位置连起来；规则要求
"条件为整数"，等式就把条件变量与 `int` 连起来。25.14 节将严格
论证：规则可推导 ⇔ 约束系统有解。此处先记住直觉——**约束是类型
规则的另一种写法**：规则按树组织（结论在底、前提在上），约束按
扁平的等式集合组织，二者承载同样的信息。

### 25.3.2 AST 节点：约束标注挂在哪里

节点变量以 AST 节点指针为键存放，因此 AST 的节点划分直接决定
标注的粒度。先把 AST 定义给出，之后每条规则引用其中的节点类。

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

读这段定义时关注与类型相关的两点。其一，每个会出现在表达式位置
的构造都有独立节点类（`IntLit`、`Binop`、`CallE`、`Deref`、
`AllocE`、`AddrOf`、`NullE`、`RecLit`、`FieldA` …），因此收集器
可以逐类分派、逐类生成，`dynamic_cast` 链与文法产生式一一对应。
其二，`AssignS` 的 target 注释已经写明：目标只会是 `VarRef`、
`FieldA` 或 `Deref`——目标位置本身也是表达式节点、也有节点变量，
这让"经指针写入"的约束无须特殊机制：先对目标递归生成它自带的
约束（Deref 会要求其内层是指针），再用一条赋值等式把目标与右值
连接（10.9.1 节）。

## 25.4 三个示例程序与文法位置

本章 --check 运行在三个小程序上，分别覆盖算术与跨函数调用、
指针三类构造、记录两类构造。先完整给出程序文本：

> // programs/arith.tip
> main() {
>   var x;
>   x = 3 + 4 * 2;
>   if (x > 10) output x; else output 0;
>   return add1(x);
> }
>
> add1(n) {
>   return n + 1;
> }

> // programs/ptr.tip
> main() {
>   var p, q;
>   p = alloc 5;
>   q = &p;
>   *p = 1;
>   output *p;
>   return **q;
> }

> // programs/rec.tip
> main() {
>   var r;
>   r = {x: 1, y: 2};
>   output r.x;
>   return r.y;
> }

三个程序刻意短小但各有侧重。arith 同时包含算术、比较、条件、
输出与一次对后定义函数的调用，是讲解"函数调用点约束"与"声明
先于使用"的主例；ptr 把 `alloc`、`&`、`*` 三种构造集中在八行里，
最后 `**q` 展示嵌套解引用如何层层生成等式；rec 覆盖记录构造与
字段访问，是唯一需要"字段名预收集"的程序。

### 25.4.1 文法：每个语法位置对应哪条规则

约束按 AST 生成，而 AST 节点由 ANTLR 产生式确定；把文法给出，
读者可以把源程序的每个片段定位到产生式、再定位到本章规则。

```antlr
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

文法中表达式的产生式（`expr` 的十余个备选项）与 10.5–10.10 的
规则一一对应：`intExpr/inputExpr/nullExpr/varExpr` 是叶子；
`addExpr/mulExpr/cmpExpr` 都建成 `Binop`，共用 10.6 的三条等式；
`callExpr` 对应 10.7；`allocExpr/derefExpr/addrExpr` 对应 10.8；
`recExpr/fieldExpr` 对应 10.10。语句侧同理：`assignStmt` 目标经
`lvalue` 产生式——`directLvalue` 建成 `VarRef`（可带字段访问）、
`pointerLvalue` 建成 `Deref`，这正是 10.3.2 所说"目标只有三种
形状"的文法来源。

### 25.4.2 AST 构建与打印：本章沿用的两个前端部件

第 12 章的 AST 构建器把上面的 parse tree 转成节点对象，收集器
消费的就是它的产物：

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

这两个文件本章一行未改：约束生成建立在冻结的 AST 接口之上，新的
分析只增加消费者、不改动产物。`buildExpr` 里值得再次注意的是
`negExpr` 的处理——TIP 没有负数字面量，`-E` 直接建成
`0 - E` 的 `Binop`，因此约束生成无须为一元负号单列规则；以及
`buildLvalue` 把 `*E`（可带 `.f`）建成 `Deref` 外套可选的
`FieldA`，节点形状与文法严格对应。

本章虽然不直接调用打印器，但快照工程要求每个示例自包含；打印器
的作用是把任意表达式以固定前缀语法还原为文本（25.15 节的驱动在
第 27 章将由同章扩展用同一函数在类型报告里打印表达式）：

```cpp
// file: src/pretty.hpp
// Pretty-printer：把 AST 以固定的前缀式语法重新打印出来。
// 它是 AST 的第一个消费者，也为后续各章提供"程序结构可视化"的通用工具。
#pragma once

#include <string>

#include "ast.hpp"

namespace tip {

std::string printProgram(const ProgramA &program);

}  // namespace tip
```

```cpp
// file: src/pretty.cpp
#include "pretty.hpp"

#include <string>

namespace tip {

namespace {

// 表达式打印为前缀式：运算符与符号的对照表。
std::string exprText(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return std::to_string(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) return x->name;
    if (dynamic_cast<const InputE *>(e)) return "input";
    if (dynamic_cast<const NullE *>(e)) return "null";

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const char *sym = "+";
        switch (x->op) {
            case BOp::Add: sym = "+"; break;
            case BOp::Sub: sym = "-"; break;
            case BOp::Mul: sym = "*"; break;
            case BOp::Div: sym = "/"; break;
            case BOp::Gt: sym = ">"; break;
            case BOp::Eq: sym = "=="; break;
        }
        return "(" + std::string(sym) + " " + exprText(x->l.get()) + " " +
               exprText(x->r.get()) + ")";
    }
    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        std::string s = "(call " + exprText(x->callee.get());
        for (const auto &a : x->args) s += " " + exprText(a.get());
        return s + ")";
    }
    if (const auto *x = dynamic_cast<const Deref *>(e))
        return "(* " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const AddrOf *>(e)) return "(& " + x->name + ")";
    if (const auto *x = dynamic_cast<const AllocE *>(e))
        return "(alloc " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const FieldA *>(e))
        return "(. " + exprText(x->e.get()) + " " + x->field + ")";
    if (const auto *x = dynamic_cast<const RecLit *>(e)) {
        std::string s = "{";
        for (size_t i = 0; i < x->fields.size(); ++i) {
            if (i) s += ", ";
            s += x->fields[i].first + ": " + exprText(x->fields[i].second.get());
        }
        return s + "}";
    }
    return "<unknown expr>";
}

std::string indent(int level) { return std::string(static_cast<size_t>(level) * 2, ' '); }

// 语句打印带缩进，一条语句一行（块内多行）。
void stmtText(const Stmt *s, int level, std::string &out) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        out += indent(level) + exprText(x->target.get()) + " = " +
               exprText(x->value.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        out += indent(level) + "output " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const ReturnS *>(s)) {
        out += indent(level) + "return " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        out += indent(level) + "if (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->then.get(), level + 1, out);
        if (x->els) {
            out += indent(level) + "else\n";
            stmtText(x->els.get(), level + 1, out);
        }
        return;
    }
    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        out += indent(level) + "while (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->body.get(), level + 1, out);
        return;
    }
    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        out += indent(level) + "{\n";
        for (const auto &st : x->ss) stmtText(st.get(), level + 1, out);
        out += indent(level) + "}\n";
        return;
    }
    out += indent(level) + "<unknown stmt>\n";
}

}  // namespace

std::string printProgram(const ProgramA &program) {
    std::string out;
    for (const auto &f : program.funs) {
        std::string paramList;
        for (size_t i = 0; i < f->params.size(); ++i) {
            if (i) paramList += ",";
            paramList += f->params[i];
        }
        out += f->name + "(" + paramList + ") {\n";
        if (!f->vars.empty()) {
            out += indent(1) + "var ";
            for (size_t i = 0; i < f->vars.size(); ++i) {
                if (i) out += ",";
                out += f->vars[i];
            }
            out += " ;\n";
        }
        // 函数体是 BlockS；打印其内部语句而不是再嵌一层花括号。
        const auto *body = dynamic_cast<const BlockS *>(f->body.get());
        for (const auto &st : body->ss) stmtText(st.get(), 1, out);
        stmtText(f->ret.get(), 1, out);
        out += "}\n";
    }
    return out;
}

}  // namespace tip
```
## 25.5 收集器的接口（constraints.hpp）

规则在落入 C++ 之前，先固定收集器的输入、输出与标注存放方式。
接口只有三十行，先看全貌：

```cpp
// file: src/constraints.hpp
// 约束收集：按程序结构生成"类型等式"，求解留给第 26 章。
// 每个表达式 E 持有一个类型变量 τ(E)；每个声明（形参/var）共享一个
// 类型变量；函数名绑定到它的函数类型。约束记录 why 以便 --check 讲解。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "symtab.hpp"
#include "type.hpp"

namespace tip {

struct Con {
    Tp a, b;
    std::string why;
};

struct Collected {
    std::vector<Con> cons;
    std::map<const Expr *, Tp> node;      // τ(E)
    std::map<const Symbol *, Tp> decl;   // 声明（形参/var/函数）的类型
};

// 遍历整个程序生成约束；bindings 提供使用点到声明的绑定（第 14 章）。
Collected collect(const ProgramA &program, const Bindings &bindings);

}  // namespace tip
```

三个数据结构各自承担一种职责，划分本身就是"判定与构造分离"原则
的落地。

**`Con` 是一条等式。** 两个 `Tp` 是无方向的两侧，`why` 是生成
理由的中文短语。`why` 不参与求解（第 26 章只读 `a`、`b`），它的
唯一消费者是 --check 的打印与第 27 章的错误报告；把解释性数据与
逻辑数据放在同一结构里，是为了让每条等式在输出中自带出处。

**`Collected::node` 是节点变量表 τ(E)。** 键是 `const Expr *`，
值是该节点的变量。这张表按需增长（见 10.6.1 的 varOf），收集器
内外的代码都能凭节点指针取回同一个变量对象。**`Collected::decl`
是声明变量表。** 键是第 14 章名字解析产出的 `Symbol *`（形参、
`var` 局部、函数名各一个 Symbol），值是该声明唯一的类型项：
形参/局部是一个变量，函数名是一个函数类型。VarRef 的规则之所以
只有一行（10.6.2），正是因为"使用点 → 声明 → 类型"这条链的前
两环已由名字解析完成，收集器只做最后一跳查表。

**`collect` 是纯遍历。** 输入只读的程序与只读的绑定，输出一个
`Collected`；它不报告错误、不求解、不修改 AST。任何"程序是否
良类型"的问题在本函数里都不会被回答——这是接口层面的纪律，保证
25.14 节正确性论证中"生成"一侧的行为可以被完整枚举。

## 25.6 表达式约束规则（上）：叶子、二元运算与调用

从本节起逐构造给出形式化规则。每条规则先给出等式形式，再解释
规则在表达第 24 章类型规则的哪一个前提。记号：α_E 表示节点 E 的
节点变量，⟦E⟧ 表示"先对子节点递归生成全部约束"。

### 25.6.1 新鲜变量与等式两个基本动作

所有规则只建立在两个动作之上：

- `varOf(E)`：若 E 已在 node 表中，返回其变量；否则取一个新鲜
  α、记入表中并返回。**惰性**意味着一个节点无论被访问几次（它
  可能既是某条语句的递归对象、又被赋值等式引用），都只占一个
  变量。
- `eq(τ₁, τ₂, why)`：把一条等式追加到约束列表尾部。

### 25.6.2 整数字面量

> ⟦n⟧  生成：  α_n = int            （整数字面量）

字面量不依赖任何子节点，也不依赖环境，规则只有一条等式。注意
等式被写成"变量 = int"，但按 10.1.1 的无方向性，它与
"int = 变量"完全等价；统一把节点变量放在左侧只是输出惯例，
让 --check 的读者容易找到等式"在约束谁"。

### 25.6.3 变量使用

> ⟦x⟧  生成：  α_x = τ(decl(x))      （变量使用）

其中 `decl(x)` 是第 14 章为该 VarRef 解析出的 Symbol，τ(decl(x))
是 decl 表中该声明的类型项。这条等式是整个系统中信息汇聚的枢纽：
无论 x 在程序里被使用多少次，每次使用只生成一条指向**同一个
声明类型项**的等式；若两次使用的要求互不相容（一处要 int、一处
要 ptr），冲突发生在求解器里、围绕同一个声明项，而不是发生在
生成阶段。arith.tip 中 `add1` 的形参 `n` 在函数体内被使用一次、
调用点又通过函数类型约束它，两条链最终都连到同一个形参变量。

### 25.6.4 input

> ⟦input⟧  生成：  α = int            （input 是整数）

TIP 规定 input 的值是整数（宿主回调 `tip_input` 读入的也是 64 位
整数），因此 input 表达式与整数字面量同样处理。这里没有"输入
类型由使用方式决定"的灵活性：语言规范先于分析固定了它。

### 25.6.5 二元运算：算术与比较共用形状

设 E = L op R。先递归 ⟦L⟧、⟦R⟧，再生成：

> α_L = int
> α_R = int
> α_E = int

三条等式对**所有**二元运算符相同——包括 `+ - * /` 与 `> ==` 等
比较。为什么比较也允许？因为在 TIP（以及 C）里比较表达式本身
产出整数 0/1，第 17 章的 IR 生成里比较被编译成 `icmp` 再接一个
zext，落到 SSA 寄存器上的确实是 `i64`。于是"比较结果为 int"
与"算术结果为 int"在类型层面没有区别，三条等式足够。规则的
关键效果是两侧被钉到 int：`*p + 1` 会递归到 `*p` 的变量，再用
`α_*p = int` 与指针链冲突，第 27 章的 binop-ptr 错误程序检验的
正是这条。

### 25.6.6 函数调用

设 E = C(A₁, …, Aₖ)。先递归 ⟦C⟧ 与每个 ⟦Aᵢ⟧，再生成**一条**等式：

> α_C = (α_A₁, …, α_Aₖ) -> α_E

这是全章信息密度最高的一条规则，值得逐侧解释。右侧构造一个函数
类型项：参数分量依次是各实参表达式的节点变量，返回分量是**调用
表达式自身**的节点变量 α_E；左侧是被调表达式的节点变量。等式
断言"被调者的类型必须恰为：吃这 k 个实参的类型、返回调用结果的
类型"。一条等式同时完成三件事：

1. 被调者必须是函数（与非函数类型合一将失败）；
2. 参数个数必须为 k（函数类型分量数不匹配，第 26 章报 arity
   mismatch）；第 27 章的 arity.tip 检验此项；
3. 第 i 个形参与第 i 个实参类型相同、返回值类型就是调用点类型
   （按分量逐一对齐）。

arith.tip 中 `return add1(x);` 生成的等式形如
`α_add1 = (α_x) -> α_call`；而 α_add1 又通过"变量使用"等式连到
`add1` 这个名字所声明的函数类型 `(α_n) -> α_ret`。两组等式在
求解器里对接，形参 n 被钉成 x 的类型、调用结果被钉成 add1 返回
类型——**跨函数的类型信息不靠生成器跨越边界，而靠同一个变量在
函数类型分量上的对接**。这一思想在第 52 章过程间分析（上下文
敏感）中将以更复杂的形式重现。

## 25.7 表达式约束规则（中）：指针三构造

TIP 的指针类型规则只有三个语法构造，每个构造恰好对应一条方向
不同的等式；把三条并排，指针就不再神秘。

### 25.7.1 alloc：从所指物到指针

> E = alloc P：  ⟦P⟧；  α_E = ptr(α_P)

`alloc P` 分配一格、用 P 初始化，结果是指向该格内容类型的指针。
等式方向"结果 = ptr(子)"。ptr.tip 的 `p = alloc 5` 让 α_p 经赋值
等式与 `ptr(α_5)` 相连，α_5 = int，于是 p : ptr(int)。

### 25.7.2 解引用：从指针到所指物

> E = *P：  ⟦P⟧；  α_P = ptr(α_E)

方向恰好反过来：`*P` 要良类型，P 必须是"指向 E 之类型"的指针。
注意等式没有写成 α_E = ... 的求解式——P 的类型此刻未知，无法
"取出"其指向类型；等式只陈述形状关系：**无论 α_P 最终是什么，
它必须是 ptr(α_E)**。这正是约束方法相比"直接算类型"的优势所在：
信息流向（指针类型由 alloc 决定，解引用类型由指针决定）与遍历
方向不必一致，无方向等式把两端同时挂起，等求解器对接。

嵌套解引用由此免费获得。ptr.tip 的 `**q`：内层 `*q` 得 α₁，生成
`α_q = ptr(α₁)`；外层 `*(*q)` 得 α₂，生成 `α₁ = ptr(α₂)`。
再由 `q = &p` 的链（下一条），α_q = ptr(α_p)，逐级对接得到
α₂ 是 p 所指内容的类型，即 int——程序返回 int，与运行结果 1
一致。

### 25.7.3 取地址：声明类型的指针

> E = &x：  α_E = ptr(τ(decl(x)))

`&x` 中 x 必须是一个可命名的声明位置（形参或 var 局部；文法只
允许标识符）。收集器在当前函数作用域与全局表中查到 x 的 Symbol，
取其声明类型，套上 ptr。ptr.tip 的 `q = &p`：p 的声明类型是
变量 α_p，故 α_q = ptr(α_p)；与 10.7.2 的 α_q = ptr(α₁) 对接，
α₁ = α_p，即 `*q` 与 p 同类型（ptr(int)），于是 `**q` 为 int。
写入侧同理：`*p = 1` 的目标 `*p` 生成 α_p = ptr(α_t)，赋值等式
再要求 α_t = int，与 alloc 链一致，无冲突。

### 25.7.4 为什么指针规则不会"漏掉别名"

读者可能担心：p 与 q 在运行时指向同一格（`q = &p` 使 `*q` 成为
p 的别名），类型分析需要跟踪这种别名关系吗？对**类型**分析不
需要。类型只回答"格内装的是什么类型"，而 alloc 已经固定了每个
格的内容类型；经 q 写入 `**q = ...` 与经 p 写入，约束都归结为
同一内容类型是否等于所写类型。至于"哪个指针可能指向哪个格"
这种**指向关系**分析，是第 41、42 章的主题，那里指针分析被建
成格上的不动点问题——类型分析用一条 ptr 构造子就够，是因为它
问的问题粗得多。

## 25.8 表达式约束规则（下）：null 的位置、记录与字段访问

### 25.8.1 null：本章刻意留白

TIP 有 `null` 字面量，但**本章的收集器对 NullE 不生成任何等式**。
这不是遗漏，而是分期设计，需要解释清楚原因，否则读者读到
constraints.cpp 中 NullE 分支的空体与注释会以为代码未完成。

困难在于：null 可以与任何指针类型相容（`p = null` 合法），也可以
与另一 null 相容，但不能与 int 相容。它既不是 `int` 这样的单一
类型，也不是"一个等待绑定的普通变量"——把它当变量会允许
`output null`（output 要 int，变量却可能被绑成 ptr，方向无法
预先决定）。正确建模是引入一个新的类型项 **null**，并让合一器
知道三条特殊规则：null 与 null 相容、null 与 ptr(τ) 相容、null
与变量相遇时把该变量绑成 null，其余皆冲突。也就是说，null 的
语义有一半在**求解器**里，而本章还没有求解器。

因此分期为：第 24–26 章的类型文法不含 null 项，NullE 不生成
约束（此时任何使用 null 的程序都无法被这三章的规则拒绝——但
三章的示例程序刻意不使用它）；第 27 章在 type.hpp 增加 `TyNull`、
在合一器增加三条规则、在收集器补上 `α_E = null`，三章部件一次
总装。把"需要求解器配合的类型项"明确隔离，是为了让第 26 章的
合一算法先在标准一阶项上被完整地论证与测试。

### 25.8.2 记录构造

设 E = `{ f₁: P₁, …, fₖ: Pₖ }`。先递归每个 ⟦Pᵢ⟧，再生成：

> α_E = { f₁: α_P₁, …, fₖ: α_Pₖ }

记录项的字段分量直接携带各字段值表达式的变量；同名字段在 TIP
中不允许重复（AST 构建器去重）。规则本身简单，复杂的是读取侧。

### 25.8.3 字段访问：为什么要"全字段名"预收集

设 E = R.f。形式化目标是：

> R 必须是含字段 f 的记录，且该字段的类型 = α_E。

直写会遇到一个看似技术、实为原则的问题：字段访问点处，R 的
记录类型可能**尚未在生成顺序中被看见**。rec.tip 中 r 的类型来自
前面的记录赋值，这例还算顺利；但考虑

> f(r) { return r.z; }
> main() { return f({z: 1, w: 2}); }

生成 f 的函数体时，r 只是一个形参变量，分析者无从知道"r 将来
可能得到哪些记录形状"。要在**不做流分析、不引入多态**的前提下
回答字段访问，spa 的选择是一个语言级约定：**字段名在整个程序中
是全局标识**——同一个名字 f 在所有记录里指向同一类型。于是
"r.f"的正确翻译是断言 r 是一个记录，其中 f 字段为 α_E；其余
字段是什么现在不知道，但它们总得有类型，于是为每个已知字段名
放一个新鲜变量占位。

"已知字段名"从何而来？必须先扫一遍整个程序（所有函数、所有
表达式），把记录字面量与字段访问中出现过的每个字段名收集成
**全程序字段名集合 F = {n₁, …, nₘ}**（去重、按首次出现排序）。
然后字段访问规则为：

> ⟦R.f⟧：  先递归 ⟦R⟧
> α_R = { n₁: β₁, …, nₘ: βₘ }
> 其中 β 均为新鲜变量，仅 f 对应的位置不放新变量、而放 α_E

即：记录形状按**全程序出现过的全部字段名**展开，访问的字段
连到 α_E，其他字段放占位变量。为什么必须带上其他字段而不是只
写 `{f: α_E}`？因为 R 的实际记录类型（来自记录字面量）带着它
自己的全部字段；两个记录项要能合一，字段名集合必须一致。若
访问点只写单字段形状，一个 `{x, y}` 的记录就无法与 `{x}` 合一，
合法程序会被拒。反过来，记录字面量只写它真实拥有的字段；当它
与"全字段形状"合一而缺少某字段时，合一器报 record shape 错误——
第 27 章 bad-field.tip（`{x:1}` 的记录访问 `.z`）精确检验：全
程序字段集为 {x, z}，访问点展开为 `{x: β, z: α_E}`，与字面量
`{x: int}` 形状不一，报错。

全局字段名约定的代价是真实的局限：不同记录中同名字段被迫同型
（`{x: 1}` 与 `{x: p}` 不能在一个程序中共存）。这是"无过程间
流信息"换来的可判定且线性可收集的规则，第 27 章会把这条局限
与"无多态、流不敏感"并列为类型分析的三条边界。

## 25.9 语句约束规则

语句不产生值，但可以包含带类型的表达式；每条语句规则只把其
内嵌表达式与"语句形状所要求的类型"连接起来。

### 25.9.1 赋值

> T = V：  ⟦V⟧；⟦T⟧；  α_T = α_V      （赋值左右类型相同）

先递归两侧（顺序影响变量编号，故实现固定为先右值后目标），再
用一条等式要求两侧同型。对 T 是 VarRef 的情形，α_T 经"变量
使用"等式连到声明类型，赋值于是把声明类型与右值对接——这是
变量类型信息的主要来源。对 T 是 `*P` 的情形，α_T 是解引用结果
变量，`α_P = ptr(α_T)` 已由递归生成，赋值等式再把 α_T 钉到右值
类型，10.7.3 的 `*p = 1` 即此路径。对 T 是 `R.g`，字段访问递归
已经把 α_T 挂到记录形状的 g 分量上。

### 25.9.2 输出

> output E：  ⟦E⟧；  α_E = int

output 只接受整数（宿主 `tip_output` 的签名也是 i64）。这条等式
是"int 专用通道"之一，与 input、二元运算两侧并列；类型分析
拒绝 `output null`、`output p` 靠的就是它们。

### 25.9.3 条件与循环

> if (C) S1 else S2：  ⟦C⟧；α_C = int；⟦S1⟧；⟦S2⟧
> while (C) S：        ⟦C⟧；α_C = int；⟦S⟧

条件必须为整数（0 为假、非 0 为真，与第 17 章编译时的截断一致）。
两个分支都要递归：类型要求覆盖程序中所有实际存在的语法路径，
但不区分路径——分析是**流不敏感**的，此处仅体现为"两支都查"，
更深刻的流不敏感后果（一个变量的多次赋值共用一个类型）来自
声明变量的唯一性，而非本条规则。

### 25.9.4 块与返回

> { S₁; …; Sₖ }：  依次 ⟦Sᵢ⟧
> return E：       ⟦E⟧      （函数级等式在 10.10 统一生成）

ReturnS 的递归只负责 E 自身的约束；"E 的类型等于所在函数返回
类型"这条等式不在语句节点处生成，原因见下一节。

## 25.10 函数级规则与两遍收集

函数边界处有两类声明式事实需要落成等式：

> 对每个函数 f(x₁, …, xₖ) { … return R; }
>   函数名 f 的类型  =  (α_x₁, …, α_xₖ) -> α_ret
>   形参 xᵢ 的类型   =  α_xᵢ            （同一个变量）
>   返回等式         =  α_ret = α_R

形参的类型变量同时充当函数类型的参数分量——**不是两个变量再立
等式，而是构造时直接放同一个对象**。同理，α_ret 是函数类型的
返回分量，返回语句只生成 α_ret = α_R 一条等式把它与返回表达式
连接。这样函数体内部 `return n + 1;` 与外部调用点约束的，是
函数类型上同一批分量。

### 25.10.1 为什么必须两遍（pass A / pass B）

实现把 collect 组织成两个阶段，次序不是工程偏好而是正确性要求：

- **pass A，先注册全部函数与全部声明。** 对每个函数构造其函数
  类型（形参、返回各取新鲜变量），把函数名 Symbol 映射到该类型、
  把形参 Symbol 映射到分量变量、把函数内每个 var 名 Symbol 映射
  到一个新鲜变量。
- **pass B，再遍历全部函数体。** 逐语句、逐返回表达式生成约束，
  最后补返回等式。

理由在 arith.tip 上看得最清楚：main 的 return 表达式调用 add1，
而 add1 定义在 main **之后**。若按"定义一个函数、立刻生成其
函数体"的单遍顺序，生成到 `add1(x)` 时，"变量使用"等式要查
`add1` 这个名字的 decl 类型——它还不存在，查表抛异常（开发中
这正是实际遇到的失败）。全局所有调用点都可能引用任意函数
（TIP 的函数互相可见，相互递归合法），所以全部函数类型必须在
任何函数体生成之前就位。var 局部同理：文法允许先使用后赋值
风格之外的各种形状，pass A 把本函数所有 var 名一次注册，函数体
生成时任意顺序引用都安全。

这与第 14 章名字解析"先注册全部函数名，再解析函数体"的两遍
结构完全同构——声明信息先于使用信息，是本前端每个阶段都遵守
的次序。

## 25.11 收集器实现（constraints.cpp）

形式规则到此完整，下面给出把它们一一实现的收集器源码。阅读时
建议与 10.6–10.10 的规则对照：文件的物理顺序是"字段预收集 →
pass A → pass B"，表达式分派函数的分支顺序与规则编号一致，
每个分支旁边的中文 why 就是等式的形式来源。

```cpp
// file: src/constraints.cpp
#include "constraints.hpp"

#include <algorithm>
#include <utility>

namespace tip {
namespace {

struct Collector {
    const Bindings *bindings;
    Collected out;
    std::vector<std::string> allFields;

    Tp varOf(const Expr *e) {
        auto it = out.node.find(e);
        if (it != out.node.end()) return it->second;
        Tp t = tvar();
        out.node.emplace(e, t);
        return t;
    }

    void eq(Tp a, Tp b, std::string why) {
        out.cons.push_back(Con{std::move(a), std::move(b), std::move(why)});
    }

    void genExpr(const Expr *e) {
        Tp t = varOf(e);

        if (const auto *x = dynamic_cast<const IntLit *>(e)) {
            (void)x;
            eq(t, tint(), "整数字面量");
            return;
        }
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            eq(t, out.decl.at(bindings->uses.at(x)), "变量使用");
            return;
        }
        if (dynamic_cast<const InputE *>(e)) {
            eq(t, tint(), "input 是整数");
            return;
        }
        if (dynamic_cast<const NullE *>(e))
            // null 的规则在第 27 章总装时补入（与任意 ptr 相容）。
            return;

        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            genExpr(x->l.get());
            genExpr(x->r.get());
            eq(varOf(x->l.get()), tint(), "二元运算左操作数为 int");
            eq(varOf(x->r.get()), tint(), "二元运算右操作数为 int");
            eq(t, tint(),
               x->op == BOp::Gt || x->op == BOp::Eq ? "比较结果为 int(0/1)" : "算术结果为 int");
            return;
        }

        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            // 被调位置可以是任意表达式；参数按序生成。
            genExpr(x->callee.get());
            for (const auto &a : x->args) genExpr(a.get());
            std::vector<Tp> ps;
            for (const auto &a : x->args) ps.push_back(varOf(a.get()));
            Tp ft = std::make_shared<TyFun>(std::move(ps), t);
            eq(varOf(x->callee.get()), ft, "被调表达式须为接受这些实参、返回 τ 的函数");
            return;
        }

        if (const auto *x = dynamic_cast<const AllocE *>(e)) {
            genExpr(x->e.get());
            eq(t, std::make_shared<TyPtr>(varOf(x->e.get())), "alloc E 的类型是 ptr(τ(E))");
            return;
        }
        if (const auto *x = dynamic_cast<const Deref *>(e)) {
            genExpr(x->e.get());
            eq(varOf(x->e.get()), std::make_shared<TyPtr>(t), "对 *E：τ(E)=ptr(τ)");
            return;
        }
        if (const auto *x = dynamic_cast<const AddrOf *>(e)) {
            // &Id：在当前函数作用域（含全局父作用域）里找到该声明。
            const Symbol *s = nullptr;
            for (const auto &scope : bindings->scopes) {
                auto it = scope->table.find(x->name);
                if (it != scope->table.end()) { s = &it->second; break; }
            }
            if (!s) {
                auto it = bindings->global.table.find(x->name);
                if (it != bindings->global.table.end()) s = &it->second;
            }
            eq(t, std::make_shared<TyPtr>(out.decl.at(s)), "&Id 的类型是 ptr(声明类型)");
            return;
        }

        if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            std::vector<std::pair<std::string, Tp>> fs;
            for (const auto &kv : x->fields) {
                genExpr(kv.second.get());
                fs.emplace_back(kv.first, varOf(kv.second.get()));
            }
            eq(t, std::make_shared<TyRec>(std::move(fs)), "记录构造的字段逐个对应");
            return;
        }
        if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            genExpr(x->e.get());
            // spa：记录须含字段 f: τ；其余字段名以新鲜变量占位。
            std::vector<std::pair<std::string, Tp>> fs;
            for (const std::string &name : allFields) {
                if (name == x->field)
                    fs.emplace_back(name, t);
                else
                    fs.emplace_back(name, tvar());
            }
            eq(varOf(x->e.get()), std::make_shared<TyRec>(std::move(fs)),
               "字段访问：记录须含 " + x->field);
            return;
        }
    }

    void genStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            genExpr(x->value.get());
            genExpr(x->target.get());
            eq(varOf(x->target.get()), varOf(x->value.get()), "赋值左右类型相同");
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) {
            genExpr(x->e.get());
            eq(varOf(x->e.get()), tint(), "output 的值是 int");
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            genExpr(x->cond.get());
            eq(varOf(x->cond.get()), tint(), "if 条件是 int");
            genStmt(x->then.get());
            if (x->els) genStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            genExpr(x->cond.get());
            eq(varOf(x->cond.get()), tint(), "while 条件是 int");
            genStmt(x->body.get());
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) genStmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const ReturnS *>(s)) {
            genExpr(x->e.get());  // return 表达式在函数级约束中连接
        }
    }
};

void gatherFields(const Expr *e, std::vector<std::string> &names) {
    if (const auto *x = dynamic_cast<const RecLit *>(e))
        for (const auto &kv : x->fields) {
            if (std::find(names.begin(), names.end(), kv.first) == names.end())
                names.push_back(kv.first);
            gatherFields(kv.second.get(), names);
        }
    if (const auto *x = dynamic_cast<const FieldA *>(e)) {
        if (std::find(names.begin(), names.end(), x->field) == names.end())
            names.push_back(x->field);
        gatherFields(x->e.get(), names);
    }
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        gatherFields(x->l.get(), names);
        gatherFields(x->r.get(), names);
    }
    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        gatherFields(x->callee.get(), names);
        for (const auto &a : x->args) gatherFields(a.get(), names);
    }
    if (const auto *x = dynamic_cast<const AllocE *>(e)) gatherFields(x->e.get(), names);
    if (const auto *x = dynamic_cast<const Deref *>(e)) gatherFields(x->e.get(), names);
}

}  // namespace

Collected collect(const ProgramA &program, const Bindings &bindings) {
    Collector c;
    c.bindings = &bindings;

    // 第一遍：收集程序中出现过的全部字段名（字段访问的记录形状需要）。
    for (const auto &f : program.funs) {
        gatherFields(f->ret->e.get(), c.allFields);
        for (const auto &st : dynamic_cast<const BlockS *>(f->body.get())->ss) {
            // 语句内的字段收集
            const Stmt *s = st.get();
            if (const auto *a = dynamic_cast<const AssignS *>(s)) {
                gatherFields(a->target.get(), c.allFields);
                gatherFields(a->value.get(), c.allFields);
            } else if (const auto *a = dynamic_cast<const OutputS *>(s)) {
                gatherFields(a->e.get(), c.allFields);
            } else if (const auto *a = dynamic_cast<const IfS *>(s)) {
                gatherFields(a->cond.get(), c.allFields);
            } else if (const auto *a = dynamic_cast<const WhileS *>(s)) {
                gatherFields(a->cond.get(), c.allFields);
            }
        }
    }

    // 第二遍 A：为全部函数建类型（形参/var 新鲜变量）并登记函数名，
    // 这样函数体互相前向调用时被调函数的类型已在 decl 中。
    std::vector<Tp> funTypes;
    for (size_t i = 0; i < program.funs.size(); ++i) {
        const FunDecl *f = program.funs[i].get();
        std::vector<Tp> ps;
        for (size_t j = 0; j < f->params.size(); ++j) ps.push_back(tvar());
        Tp retVar = tvar();
        Tp ft = std::make_shared<TyFun>(ps, retVar);

        for (size_t j = 0; j < f->params.size(); ++j) {
            const Symbol *s = &bindings.scopes[i]->table.at(f->params[j]);
            c.out.decl[s] = ps[j];
        }
        for (const std::string &v : f->vars) {
            const Symbol *s = &bindings.scopes[i]->table.at(v);
            c.out.decl[s] = tvar();
        }
        for (const auto &kv : bindings.global.table)
            if (kv.second.kind == Symbol::Fun && kv.second.name == f->name)
                c.out.decl[&kv.second] = ft;
        funTypes.push_back(ft);
    }

    // 第二遍 B：按函数顺序走函数体与 return。
    for (size_t i = 0; i < program.funs.size(); ++i) {
        const FunDecl *f = program.funs[i].get();
        for (const auto &st : dynamic_cast<const BlockS *>(f->body.get())->ss)
            c.genStmt(st.get());

        c.genExpr(f->ret->e.get());
        const auto *ft = dynamic_cast<const TyFun *>(funTypes[i].get());
        c.eq(ft->ret, c.varOf(f->ret->e.get()), "return 表达式确定返回类型");
    }
    return c.out;
}

}  // namespace tip
```

几个实现细节值得点名，它们都是规则到代码的忠实翻译而非额外
设计。

**字段预收集 `gatherFields`** 是一次不生成约束的纯递归：它经过
所有可能携带字段名的节点（记录字面量、字段访问，以及包裹它们
的二元运算、调用、alloc、解引用），把首次出现的字段名追加进
allFields。这遍之所以独立成 pass，是因为 10.8.3 规定字段访问
规则需要**全程序**字段集，而该集合依赖程序中尚未遍历的部分。

**`genExpr` 的 NullE 分支为空**，只有一句注释指向第 27 章，对应
10.8.1 的刻意留白；除此分支外，每个表达式构造都恰好生成其规则
中列出的等式，没有多一条。**AddAddr 的符号查找**先走当前函数
作用域链表、再走全局，与名字解析的可见性次序一致，保证
`&f`（取函数地址这种非法形状）不会误中——文法根本不允许，但
代码同样不假设"名字一定是局部"。

**`collect` 的 pass A** 为每个函数一次性建出 TyFun，并立刻把
函数名、形参、var 三类 Symbol 的类型登记完毕；`funTypes` 另外
保存函数类型与返回分量，供 pass B 末尾的返回等式使用。pass B
对每个函数按语句书写顺序遍历、再生成返回表达式与 α_ret = α_R。
语句遍历需要进入 if 分支、while 体、嵌套块，与第 16 章 CFG 构建
访问同样的语句形状。

## 25.12 名字解析：收集器所站的肩膀

收集器消费的 Bindings（uses 映射、作用域、全局表）完全来自第 14 章的部件，本章源码原样携带。先看实现：

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

`resolveNames` 的两遍结构（先注册函数名，再逐函数建作用域、解析
函数体）在 10.10.1 已引用；此处关注收集器真正读取的产物。
`uses` 表为每个解析成功的 VarRef 给出 Symbol 指针，而 Symbol 的
所有权在 Bindings（全局表与 scopes 向量）中，因此 decl 表以
`const Symbol *` 为键在整个 --check 生命期内稳定。换句话说，
收集器里"变量使用"规则的一次 map 查找，背后是第 14 章保证的
"使用点必然唯一对应一个存活的声明 Symbol"；未声明名字在那时
已被拦截，本章无须再处理。

头文件本身值得与实现对照一读：

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

`Symbol` 的三值 kind（Fun/Param/Local）是 decl 表中类型项形状的
来源：Fun 的类型必为 TyFun（pass A 据此构造），Param/Local 的
类型是变量。`Symbol` 还携带所属函数指针，但收集器并不读取它——
pass A 按函数遍历 AST 时自己掌握上下文；这种"字段服务一类消费者"
的精简设计，使符号表结构不被分析端的需求反向污染。`Scope` 的
lookup 沿 parent 链向上，与 10.7.3 AddAddr 的查找次序一致；
全局作用域没有父链，函数名在其中独立成表。`Bindings` 注释中
"scopes 由 Bindings 持有所有权"一句不可轻忽：uses 表与收集器的
decl 表都保存裸指针，作用域对象一旦提前释放，两张表全部悬垂——
所有权集中于一个容器，是跨阶段共享指针的必要配套。

头文件末尾声明的 `resolveNames(ProgramA &)` 签名有一个容易忽略
的细节：它接受**非 const 的 ProgramA 引用**。名字解析阶段不修改
节点形状，但解析结果需要被后续阶段反复使用；在本书实现中该信息
集中存放在返回的 Bindings 里（uses 映射），AST 本身保持中立——
因此本章的 collect 才能接受 `const ProgramA &`。`Diag` 只携带一段
文本，说明第 14 章的错误恢复策略是"收集全部诊断、继续解析"，
而不是遇错即停；这让一次编译能报告多个未声明名字。收集器对
Diag 一无所知：有诊断时驱动直接退出，约束永远只为**通过名字
解析**的程序生成。这条前置过滤的存在，使 10.6–10.10 的规则可以
放心地假定"每个 VarRef 都查得到 Symbol"，无须在每条规则里处理
未声明情形——规则之所以短小，一半的功劳属于阶段边界上的纪律。
## 25.13 快照中保留的后端：IR 生成与 ORC 执行台

本章新增的只有约束生成；但示例工程的另外两条命令（--emit-ir、
--run）仍然有效，其代码从第 17 章原样带入。这里给出全部源码，
并说明它们与新分析的关系：约束分析**不读取** IR，IR 生成也**不
读取**约束——三条流水线共享同一个前端产物（AST + Bindings），
彼此独立。

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

IR 生成器中与本章规则形成镜像的两处，值得对照阅读。其一，
`genExpr` 对比较运算符确实生成 `icmp` + zext 到 `i64`，这是
10.6.5 "比较结果也是 int"的运行时依据：类型规则不是口头约定，
而与编译产物的实际类型一致。其二，`alloc` 生成 `alloca i64`
（opaque ptr 之下 alloca 只携带所指类型）、`&x` 生成指向
var 对应 alloca 的指针、`*p` 在读写两侧分别生成 load/store——
10.7 的三条类型等式正对应这三个指令形状；ptr 构造子与所有
指针的静态类型在 opaque ptr 世界里统一擦除为 `ptr`，**类型
信息只存在于分析端**，这也解释了为什么类型分析必须自己生成
ptr(τ) 项而不能向 LLVM 索取。

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

执行台在本章还有一个新的潜在用途：它提供"程序实际做了什么"
的基准。第 32 章起，各分析将配套 soundness/ 实验，把分析结论与
真实执行输出对照（例如符号分析断言"输出非负"，就对多组输入
真实执行、检查输出）；本章只生成约束、结论尚未读出，因此暂无
此类实验，但执行台必须随快照存在，使下一章的合一结果可以立刻
被人工对照——25.15 节就会这样做：ptr.tip 分析出返回 int，而它
真实运行的输出是 1。

## 25.14 正确性论证：规则可类型化 ⇔ 约束系统有解

本章的理论焦点是一个双向定理。它把"声明式规范"（第 24 章规则）
与"算法前半段"（约束生成）严格连接起来，形式与第 17 章的翻译
正确性定理平行。

**定理 10.14**：对任意 TIP 程序 P，以下等价：

1. P 按第 24 章类型规则可类型化（存在类型环境 Γ 使每个函数的
   每个表达式与语句都有推导）；
2. `collect(P)` 产出的约束系统存在解（存在代换 S 使全部等式成立）。

下面给出两个方向的论证思路。工程教程不追求逐行的证明术语，但
每个归纳步骤都对应一条具体规则，读者可以据此自行补全细节。

### 25.14.1 可类型化 ⇒ 有解（可靠性）

设 P 可类型化，即存在一棵覆盖全部节点的推导树，每个表达式 E 在
其位置被赋予某个类型 τ_E，每个声明 D 被赋予类型 τ_D。构造代换
S：把每个节点变量 α_E 映到 τ_E，把每个声明变量 α_D 映到 τ_D。
需要验证 S 满足生成器写下的每条等式；按等式来源逐类核对：

- 整数字面量 / input：推导中其类型必为 int（规则只有这一条），
  等式 α = int 两侧均为 int；
- 变量使用 x：推导树中使用点的类型等于环境给声明的类型
  （T-Var 前提），等式 α_x = τ(decl(x)) 在 S 下两侧同为该类型；
- 二元运算：推导规则要求两侧 int、结果 int，三条等式分别成立；
- 调用：T-Call 的前提是被调者类型为 (τ₁, …, τₖ) -> τ、各实参
  类型为 τᵢ、结论类型为 τ；生成等式 α_C = (α_A₁,…) -> α_E 的
  两侧在 S 下正是同一个函数类型，分量逐一对应；
- 指针三构造：alloc / deref / addr 的类型规则与 10.7 的三条等式
  形状逐一对应（T-Alloc、T-Deref、T-Addr）；
- 记录与字段访问：T-Reclit 给出字段逐个对应；字段访问规则
  （10.8.3）要求 R 的记录类型在 f 分量为结果类型、其余字段任意，
  推导树中 R 的实际记录类型满足之——把占位变量映到该记录相应
  字段的实际类型即可（全程序字段集 F 包含该记录的全部字段名，
  这是 gatherFields 的定义所保证的）；
- 语句（赋值、output、if/while）与函数级等式同理，逐条对应
  其类型规则的前提。

等式集合中每条都能在上述清单中找到来源，故 S 是解。

### 25.14.2 有解 ⇒ 可类型化（完备性）

设 S 满足全部等式。用 S 读出每个位置的类型：表达式 E 的类型取
S(α_E)，声明 D 取 S(α_D)。需要对语法树做一次结构归纳，证明每个
节点都能凭第 24 章规则由其子节点推出：

- 叶子（字面量/input/变量）：由相应等式直接读出规则所需事实。
  变量使用处，等式 α_x = τ(decl(x)) 保证读出的类型与环境一致；
- 复合表达式：等式把节点变量与子变量以构造子连接。例如调用
  等式经 S 后两侧是同一个函数类型，于是各实参读出的类型恰为
  其参数分量、调用结果读出返回分量——T-Call 的全部前提齐备；
  deref 等式 α_P = ptr(α_E) 保证 P 读出的是指针、所指类型为
  E 的类型，T-Deref 前提齐备；
- 归纳在指针嵌套、记录嵌套处照常进行（结构归纳对子树深度没有
  限制）；
- 语句与函数：赋值等式给出两侧同型（T-Assign）；条件等式给出
  int；函数级等式 α_ret = α_R 保证返回表达式类型与函数返回
  分量一致，函数声明规则前提齐备。

归纳覆盖全部节点，故存在一棵完整推导树，P 可类型化。

### 25.14.3 论证中真正值得记住的两点

第一，定理成立的关键不在算法多精巧，而在**生成器没有添加任何
规则之外的要求，也没有遗漏任何规则的前提**——10.11 之所以反复
强调"逐构造核对"，就是因为这里的可靠性只能逐构造验证。NullE
留白（10.8.1）在定理范围内也是自洽的：本章规范本就不含 null
规则，使用 null 的程序不属于"按第 24 章规则可类型化"的讨论
全集；第 27 章扩展文法与规则后，定理对扩展后的系统重新成立。

第二，定理只断言"有解/无解"，不断言解的唯一性。一阶项等式组
若有解，则存在**最一般解**（most general unifier），未被任何
等式约束的变量在最一般解中保持自由——第 26 章的合一算法产出
的正是它。这意味着本分析不会对"未使用、未约束"的位置编造
类型，这一性质在第 32 章讨论分析的精确性时还会以另一种形式
出现。
## 25.15 驱动：三条流水线的总装

收集器由 main 的 --check 分支接入。驱动源码不长，但它确定了
前端各阶段的接线次序与退出码约定：

```cpp
// file: src/main.cpp
// 第 25 章配套程序：约束收集登场。
//   --check FILE    : 解析 -> AST -> 名字解析 -> 收集并打印类型等式
//   --emit-ir FILE  : 打印未优化的 LLVM 模块
//   --run FILE INPUTS: 对 INPUTS 每行输入真实执行一次，打印输出序列
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "constraints.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) {
        std::cerr << "cannot open " << path << '\n';
        std::exit(1);
    }
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
    if (!errors.messages.empty()) {
        for (const std::string &m : errors.messages) std::cout << m << '\n';
        std::exit(2);
    }

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty()) {
        for (const tip::Diag &d : result.bindings.errors)
            std::cout << d.text << '\n';
        std::exit(3);
    }
    return result;
}

std::vector<int> parseRun(const std::string &line) {
    std::vector<int> values;
    std::istringstream ss(line);
    int v;
    while (ss >> v) values.push_back(v);
    return values;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc >= 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::Collected c = tip::collect(*p.ast, p.bindings);
        std::cout << "constraints: " << c.cons.size() << '\n';
        for (const tip::Con &k : c.cons)
            std::cout << k.a->show() << " == " << k.b->show() << "   ; " << k.why << '\n';
        return 0;
    }

    if (argc >= 3 && std::string(argv[1]) == "--emit-ir") {
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

    if (argc == 4 && std::string(argv[1]) == "--run") {
        std::ifstream in(argv[3]);
        if (!in) {
            std::cerr << "cannot open " << argv[3] << '\n';
            return 1;
        }
        int run = 0;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            // 每次执行重新生成：JIT 会消费模块。
            Parsed p = parseFile(argv[2]);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);

            std::cout << "run " << ++run << ":";
            for (size_t i = 0; i < outputs.size(); ++i)
                std::cout << (i ? ", " : " ") << outputs[i];
            std::cout << '\n';
        }
        return 0;
    }

    std::cerr << "usage: tipa --check FILE | tipa --emit-ir FILE | tipa --run FILE INPUTS\n";
    return 1;
}
```

`parseFile` 把"词法/语法（退出码 2）→ AST 构建 → 名字解析
（退出码 3）"串成一个不可分割的前端；三条命令都从它取得
（AST, Bindings）。--check 在其后只加两行：`collect` 与打印。
打印格式 `a == b   ; why` 是固定模板，变量文本来自各类型项的
`show()`——整条输出链路上没有任何时间、路径、绝对目录信息，
这是 expected 能逐字节复现的直接原因。

注意 --check **不调用合一器**：第 26 章之前，等式只被收集与
展示。所以本章对错误程序（如 `x = &x`）也只会照常打印等式，
"无解"的判断要等求解器；本章三个示例都是第 26 章验证过有解的
程序，输出中每一行的意义都能在下一章被"解开"。

这里还可以体会快照测试在分析开发中的独特价值。由于 --check 的
输出是全部约束的完整列表，生成器的任何改动——哪怕只是调换两个
子节点的递归顺序——都会在 expected 对照中立刻显现。因此在开发
阶段，expected 不是最后"补一个测试"，而是描述生成器行为的**规格
书**：每修改一次生成器，先问输出将怎样改变，再决定改动是否符合
预期。这种"输出即规格"的工作方式，在后面每个带 expected 的章节
都适用，也是本书敢于逐构造核对正确性的底气之一。

### 25.15.1 真实输出：arith.tip 的 31 条等式

下面是对三个程序运行 --check 的完整快照（expected/output.txt，
与仓库文件逐字节一致），随后逐段导读：

```text
; expected: expected/output.txt
== arith.tip ==
constraints: 31
t6 == int   ; 整数字面量
t8 == int   ; 整数字面量
t9 == int   ; 整数字面量
t8 == int   ; 二元运算左操作数为 int
t9 == int   ; 二元运算右操作数为 int
t7 == int   ; 算术结果为 int
t6 == int   ; 二元运算左操作数为 int
t7 == int   ; 二元运算右操作数为 int
t5 == int   ; 算术结果为 int
t10 == t2   ; 变量使用
t10 == t5   ; 赋值左右类型相同
t12 == t2   ; 变量使用
t13 == int   ; 整数字面量
t12 == int   ; 二元运算左操作数为 int
t13 == int   ; 二元运算右操作数为 int
t11 == int   ; 比较结果为 int(0/1)
t11 == int   ; if 条件是 int
t14 == t2   ; 变量使用
t14 == int   ; output 的值是 int
t15 == int   ; 整数字面量
t15 == int   ; output 的值是 int
t17 == (t3) -> t4   ; 变量使用
t18 == t2   ; 变量使用
t17 == (t18) -> t16   ; 被调表达式须为接受这些实参、返回 τ 的函数
t1 == t16   ; return 表达式确定返回类型
t20 == t3   ; 变量使用
t21 == int   ; 整数字面量
t20 == int   ; 二元运算左操作数为 int
t21 == int   ; 二元运算右操作数为 int
t19 == int   ; 算术结果为 int
t4 == t19   ; return 表达式确定返回类型
== ptr.tip ==
constraints: 18
t5 == int   ; 整数字面量
t4 == ptr(t5)   ; alloc E 的类型是 ptr(τ(E))
t6 == t2   ; 变量使用
t6 == t4   ; 赋值左右类型相同
t7 == ptr(t2)   ; &Id 的类型是 ptr(声明类型)
t8 == t3   ; 变量使用
t8 == t7   ; 赋值左右类型相同
t9 == int   ; 整数字面量
t11 == t2   ; 变量使用
t11 == ptr(t10)   ; 对 *E：τ(E)=ptr(τ)
t10 == t9   ; 赋值左右类型相同
t13 == t2   ; 变量使用
t13 == ptr(t12)   ; 对 *E：τ(E)=ptr(τ)
t12 == int   ; output 的值是 int
t16 == t3   ; 变量使用
t16 == ptr(t15)   ; 对 *E：τ(E)=ptr(τ)
t15 == ptr(t14)   ; 对 *E：τ(E)=ptr(τ)
t1 == t14   ; return 表达式确定返回类型
== rec.tip ==
constraints: 11
t4 == int   ; 整数字面量
t5 == int   ; 整数字面量
t3 == {x: t4, y: t5}   ; 记录构造的字段逐个对应
t6 == t2   ; 变量使用
t6 == t3   ; 赋值左右类型相同
t8 == t2   ; 变量使用
t8 == {y: t9, x: t7}   ; 字段访问：记录须含 x
t7 == int   ; output 的值是 int
t11 == t2   ; 变量使用
t11 == {y: t10, x: t12}   ; 字段访问：记录须含 y
t1 == t10   ; return 表达式确定返回类型
```

先看第一段，`== arith.tip ==`，共 31 条。读输出要先知道编号从
何而来：pass A 按函数定义顺序注册声明——main 的返回分量是 t1、
局部 x 是 t2；add1 的形参 n 是 t3、返回分量是 t4。然后 pass B
按 main 的书写顺序遍历，编号依次增大。

第 3–11 行对应 `x = 3 + 4 * 2;`。外层加法先递归左子树 3（t6），
再递归右子树 `4 * 2`（4 是 t8、2 是 t9、乘积结果 t7），最后补
外层加法的三条等式与结果变量 t5。可以看到等式顺序是"先递归
叶子、后补当前节点"，因此 t5（整个右式的结果）编号反而小于
其内部的 t6–t9——**编号反映遍历中的访问次序，不反映数据依赖
方向**。第 27–28 行是赋值本身：目标 x 的使用变量 t10 经
`t10 == t2` 连到声明，再经 `t10 == t5` 与右式对接。这就是
"x 的类型来自赋值"在等式层面的完整样貌：t2、t10、t5 三个变量
被两条等式串成一条链。

第 29–35 行对应条件 `x > 10`：比较自身的三条等式（其中第 18 行
why 为"比较结果为 int(0/1)"，与算术的 why 文字不同但规则同为
三条），紧接第 19 行 `t11 == int  ; if 条件是 int`。第 37–49 行
是两个分支里的 output：then 分支输出 x（t14 链到 t2，再被钉为
int），else 分支输出 0（t15）。到这里，x 的声明变量 t2 已经被
多条等式间接要求为 int——但生成器没有动手合并任何变量，全部
留待求解。

第 50–53 行是全章最重要的四行，对应 `return add1(x);`。第 24
行，被调名字 add1 的使用变量 t17 连到它的**声明类型**
`(t3) -> t4`——注意 pass A 注册的函数类型当场被打印成具体项，
它不含、也不需要等函数体生成。第 25 行，实参 x 的使用变量 t18
连到 t2。第 26 行是调用规则那条等式：`t17 == (t18) -> t16`。
此刻两侧都是函数形状：左侧分量 t3/t4 来自 add1 的定义，右侧
分量 t18/t16 来自调用点。第 26 章合一会逐分量对接，得到
t3 = t18（形参 n = 实参 x）、t4 = t16（add1 返回值 = 调用
结果）。第 27 行 `t1 == t16` 把调用结果连到 main 的返回分量。

第 36–41 行是 add1 的函数体：n 的使用 t20 连到 t3、字面量 1 是
t21、加法结果 t19，最后第 33 行 `t4 == t19` 把返回表达式钉到
add1 的返回分量。跨函数信息流在输出里一目了然：t4 → t16 → t1
这条链让"main 返回什么"完全由 add1 的返回表达式决定，而
t3 ← t18 ← t2 ← … ← int 让形参被实参约束。**没有任何一条等式
跨越函数边界直接写字段**，跨越全部通过函数类型分量上的同一
变量完成——这是 10.6.6 与 10.10 两处设计共同达成的效果。

### 25.15.2 真实输出：ptr.tip 的 18 条等式

第二段编号从 pass A 重新接续：main 返回分量 t1，局部 p 为 t2、
q 为 t3。

第 48–49 行对应 `p = alloc 5`：字面量 t5=int，alloc 结果 t4 =
ptr(t5)。第 50–51 行完成赋值：p 的使用变量 t6 先连声明 t2、再连
t4，于是 t2 被挂到 ptr(t5) 上。第 52–54 行对应 `q = &p`：取地址
直接生成 `t7 = ptr(t2)`——右侧用的是 p 的**声明变量本身**，不是
某次使用的副本；q 的使用 t8 经 t3、t7 串成链。至此 t2 =
ptr(t5)、t3 = ptr(t2) = ptr(ptr(t5))，p、q 的双层结构仅用四条
等式就完整表达。

第 61–66 行对应 `*p = 1`：字面量 1 为 t9；目标 `*p` 的生成先
访问 p（t11 连 t2），再由解引用规则写 `t11 = ptr(t10)`——t10
就是写入位置 `*p` 的类型变量；赋值等式 t10 = t9。与 alloc 链
对接后，t11 与 ptr(t5) 合一、t10 与 t5 合一、t9 为 int，全部
一致。第 56–63 行的 `output *p` 是同一构造的读取版：t13 =
ptr(t12)，t12 被 output 钉为 int。

第 64–70 行对应最后的 `return **q;`，是嵌套解引用的教科书式
展开。内层 `*q`：q 的使用 t16 连 t3，等式 `t16 = ptr(t15)`；
外层 `*(*q)`：等式 `t15 = ptr(t14)`；第 53 行把 main 返回分量
连到最外层结果 `t1 = t14`。与 pass A 以来的链对接：t3 =
ptr(t2)（取地址）、t2 = ptr(t5)（alloc）、t5 = int，于是
t16 与 ptr(t2) 合一得 t15 = t2；t15 与 ptr(t14) 合一得 t2 =
ptr(t14)，即 t14 = t5 = int。分析结论：程序返回 int。而真实
执行（第 17 章执行台）输出 1——读类型链预测的类型与运行时
实际值的类型一致，这就是本章能做的、最朴素的一次"分析 vs
执行"对照。

### 25.15.3 真实输出：rec.tip 的 11 条等式

第三段最短但包含字段名预收集的全部痕迹。pass A：t1 为 main
返回、t2 为局部 r。gatherFields 扫整个程序得到字段集
F = {x, y}（x 先出现）。

第 65–69 行对应 `r = {x: 1, y: 2}`：两个字面量 t4、t5，记录项
`t3 = {x: t4, y: t5}`——记录项按字面量声明的字段构造，字段
顺序即书写顺序。第 70–71 行经赋值把 t2 与 t3 对接。

第 64–66 行对应 `output r.x`。关键是第 62 行：`t8 == {y: t9, x: t7}`。
对照 10.8.3 的规则逐项核对：r 的使用变量是 t8（连声明 t2）；
记录形状按**全程序字段集** {x, y} 展开，两个分量都是新鲜变量，
唯独被访问字段 x 的位置放的是本次字段访问的结果变量 t7。打印
顺序按记录项构造时字段名排序（TyRec 的构造函数对字段名排序，
使输出与字段书写顺序无关），所以 y 分量印在前面。第 63 行
`t7 == int` 是 output 的要求。与 t2 的实际类型 `{x: t4, y: t5}`
对接后：x 分量 t7 与 t4 合一，y 分量的占位 t9 与 t5 合一。

第 69–71 行对应 `return r.y`：第 65 行同样展开全字段形状
`{y: t10, x: t12}`，被访问字段 y 的位置放结果变量 t11（第 64
行 t11 经 r 的另一使用变量连到 t2……实际输出中 t11 是字段结果
变量，第 66 行 `t1 == t10` 中 t10 才是 y 分量对应变量——以输出
原文为准：第 65 行 y 分量为 t10、x 分量为占位 t12，结果变量
t11 通过第 64 行的链连 t2）。合一后 y 分量 t10 与 t5 对接，
第 66 行 `t1 == t10` 让 main 返回 t5 的类型，即 int。

把这 11 行连起来看，字段访问规则的代价与收益都在眼前：收益是
无须任何流信息就能让"r.x"得到类型（全靠全程序字段集与占位
变量）；代价是第 62、65 行被迫写出**包含程序中所有字段名**的
形状——rec.tip 只有两字段时尚不明显，在字段众多的程序里，一个
只含单字段的记录会因无法与全字段形状合一而被拒（第 27 章
bad-field.tip），不同记录的同名字段也被迫共享类型。规则的
表达力边界，直接印在它生成的等式形状里。

## 25.16 手工对接：不依赖求解器读懂等式

第 26 章将给出完整的合一算法；但本章的等式系统如此简单，以至于
只用三个**对接动作**就能手工读懂大部分程序。本节做一次"无算法
预演"：目的不是提前教合一，而是让读者确信等式本身已经携带了
全部信息——求解器只是机械地重复这三个动作。

### 25.16.1 三个对接动作

**动作一，变量与具体项对接**：等式 `α = int`（或 α 等于任何不含
变量的构造项）把 α 确定为该项。此后凡出现 α 的位置，都可以换成
该项。**动作二，变量与变量对接**：`α = β` 让两个名字成为同义；
读取时任选一个代表即可（实现中第 26 章把一个编号绑到另一个
编号，查找时沿链走到底）。**动作三，构造子对接**：等式两侧是
同一个构造子时（ptr = ptr、函数类型 = 函数类型、记录 = 记录），
整体等式分解为各分量的对接；构造子不同则系统无解。

三个动作都**不做算术、不猜测**：它们只处理"形状相同"。10.15
导读中反复出现的"链"，就是动作一与动作二串接的结果。

### 25.16.2 arith.tip 的手工对接

从信息的"源头"等式开始——源头即不含变量一侧为构造子的等式。
字面量给出 t6 = t8 = t9 = t13 = t15 = int（第 3–5、15、22 行）。
沿算术等式推进：内层乘法 t7 = int（第 11 行），外层加法 t5 =
int（第 11 行）。赋值链 t10 = t2、t10 = t5（第 27–28 行）经动作
二把 t2、t5 同义，再由动作一得 **t2 = int**——局部 x 的类型在
不查看任何"x 被怎样使用"的情况下已经确定。

随后检查使用侧是否一致：条件比较 t11 = int 与 `t11 = int`（if
条件）相容；output 链 t14 = t2、t14 = int 两侧都给出 int，无冲突。
跨函数部分：t17 = (t3) -> t4（定义侧）与 t17 = (t18) -> t16（调用
侧）经动作三分解为 t3 = t18、t4 = t16；t18 = t2 给出 t3 = int；
add1 函数体 t20 = t3、t21 = int 相容，t4 = t19 = int；最后
t1 = t16 = t4 = int。**main 与 add1 的返回类型均为 int**。

这次手工过程有一个值得注意的次序特征：我们先处理了所有"源头"
等式，再沿链传播，最后才检查函数类型的分量对接。第 26 章的算法
并不按这个次序工作（它按约束列表逐条处理，靠动作二的同义链应对
任意次序），但能按任何方便的次序读懂系统，恰恰说明**约束次序与
逻辑意义无关**——25.3 节对此已作过规定。

### 25.16.3 ptr.tip 与 rec.tip 的手工对接

ptr：源头 t5 = int；alloc 等式 t4 = ptr(t5) 确定 t4；赋值链
t6 = t2 = t4 得 **t2 = ptr(int)**；取地址 t7 = ptr(t2)，链
t8 = t3 = t7 得 **t3 = ptr(ptr(int))**。写入 `*p = 1` 的等式
t11 = ptr(t10)、t11 = t2 分解动作三：ptr 对 ptr，分量 t10 = t5 =
int，与 t9 = int 一致。读取与返回链同法：t13 = ptr(t12) 对 t2
得 t12 = int；t16 = ptr(t15) 对 t3 得 t15 = t2；t15 = ptr(t14) 对
t2 = ptr(t5) 得 t14 = t5 = int。结论 t1 = int。

rec：t4 = t5 = int；t3 = {x: t4, y: t5} 为 **{x: int, y: int}**；
t2 = t3。访问 r.x 的形状 t8 = {y: t9, x: t7} 对 t2 的记录做动作
三：字段名集合须一致（{x,y} = {x,y}，通过），分量对接 y：
t9 = t5 = int，x：t7 = t4 = int，与 output 的 t7 = int 相容。
访问 r.y 同法给出 t10 = t5，返回链 t1 = t10 = int。三例手工
结论与 10.15 导读逐一对齐，也将与第 26 章机器求解的输出逐字
对齐。

### 25.16.4 无解在手工对接时长什么样

把第 27 章的两个错误程序提前拿来做手工对接，可以看到"无解"不
是求解器的主观判决，而是动作层面的客观失败。`x = &x`：取地址
生成 α = ptr(β)……实际为 α_x = ptr(α_x)（等式两侧含同一个
变量）。动作一要求把 α_x 换成 ptr(α_x)，换入后右侧仍是
ptr(α_x)、再换得 ptr(ptr(α_x))，替换永不终止——无法把 α_x 读成
一个不含 α_x 的有限项，这就是 occurs 检查失败的直观含义。
`{x:1}` 访问 `.z`：访问形状按全字段集 {x,z} 展开，字面量形状只有
{x}，动作三要求字段名集合一致，集合不等、无法分解，客观失败。
**错误信息是对"哪一步动作无法继续"的描述**，这决定了第 27 章
诊断文本的写法。

## 25.17 约束能表达什么，不能表达什么

理解一种形式系统的快捷方式，是看清它的词汇允许说什么话。本章
的约束语言只有一类句式——两个类型项相等。这个"只有"划出的
边界，比规则表本身更值得记住。

### 25.17.1 能说的：同一、形状、分量传输

等式能表达的关系全部建立在"同一"之上：两个位置类型**同一**
（变量使用、赋值、形参实参对接）；某位置的类型具有某**构造
形状**（条件是 int、被调者是函数、E 是指针）；复合项的**分量**
与其他位置同一（alloc 的所指类型、记录字段、返回分量）。第 24 章类型规则中所有前提，剥去文字后都落在这三类关系内，这正是
定理 10.14 能成立的根本原因。

### 25.17.2 不能说的：子类型序、交集、重载

等式语言里**没有序关系**。无法说"α 是 int 或 int 的某种窄化"、
无法说"这个类型可以隐式转换为那个"——若语言需要子类型（面向
对象语言的类继承），约束要换成**不等式/约束序**（α ≤ β），求解
变成序上的不动点计算，那是第 28–30 章格论部分的天下。无法说
"α 同时等于 τ₁ 与 τ₂ 的交集"——一个变量只有一个项，所以
`f` 不能根据实参类型在两套行为间选择：**没有重载**。TIP 函数
一名一义，类型分析不需要消歧；工业语言的重载解析在类型推断
之前以另一套机制完成。

### 25.17.3 为什么装不下多态

这是最值得展开的一条边界。多态函数（如恒等函数 `id(x){return x;}`）
应当能同时用于 `id(1)` 与 `id(alloc 1)`，两处 x 分别为 int 与
ptr(int)。在本章的架构里，id 只有一个函数类型、形参只有一个
变量 α_x；两个调用点的规则等式分别要求 α_x = int 与 α_x =
ptr(…)，合在一起无解——**单态不是因为规则写错，而是"一个声明
一个类型项"这一标注模型本身的限制**。

Hindley–Milner 式系统（ML、Haskell、Rust 的泛型）解决它的办法
是让 let 引入的名字获得**带量词的类型方案** ∀α. α → α，并在每次
使用点**实例化**出新变量：两个调用点于是各用各的 α，互不干扰。
注意这要求生成器区分"使用点"（实例化、生成新变量）与"声明
点"（持有方案），还要求求解产出的类型被泛化（generalization）。
TIP 刻意不设 let、函数也不可嵌套，从语言层面移除了多态的立足
点，使本章的标注模型保持极简。第 27 章会再次总结这条边界；记住
它的形式表述：**声明变量不含量词，使用点不实例化**。

### 25.17.4 流不敏感的精确含义

"流不敏感"在本章有一个可以逐字核对的定义：每个声明的类型项
**不随程序点变化**，对声明的全部使用共用同一组等式。若程序是

> x = 1;
> x = alloc 2;
> output *x;

两次赋值生成 t2 = int 与 t2 = ptr(…)（经同一条 t2 链），系统
无解——分析不会因为"第二次赋值之后 x 显然是指针"而接受程序。
它不区分程序点、也不区分先后。流敏感的类型推断需要把"x 在点 p
的类型"作为标注对象（即标注键从声明变为"声明 × 程序点"），
约束数量与程序点数相关，求解仍可做，但那是另一种分析。本书
第 25、27 章的数据流框架将在更粗的性质（常量、符号）上展示
流敏感的世界。

## 25.18 拓展练习：为假想构造设计约束

检验是否真正掌握约束生成，不是复述本章规则，而是能为**新构造**
写出规则。下面给出四个由浅入深的设计题，每题只规定语义，读者
应先自己动手列等式，再看讲解。这种"从类型安全反推规则"的训练，
与第 24 章"从规则读含义"恰好互为逆向。

### 25.18.1 练习一：布尔型与逻辑运算

设想 TIP 增加 `bool` 字面量 true/false 与 `and/or`（不要求短路）。
需要在类型项文法加一个零分量构造子 bool；true/false 的规则为
α = bool；`A and B` 的三条等式为 α_A = bool、α_B = bool、
α_E = bool；if/while 的条件等式由 = int 改为 = bool（语言设计上
也可保留 int 条件，那样条件等式不改）。要点：**每增加一个零分量
构造子，只需为其字面量与引入点写等式，合一器自动拒绝混用**——
`1 and true` 会在 α_A = bool 与 α_A = int 间无解。

### 25.18.2 练习二：数组

设想增加 `[E₁, …, Eₖ]` 数组字面量、`A[i]` 下标、`A[i] = V`
与长度操作 `length A`。数组项为 `arr(τ)`：所有元素必须同型。
字面量规则：α = arr(β)，再对每个元素 Eⱼ 立 α_Eⱼ = β（同一个 β
被所有元素共用——不同型元素立刻冲突）。下标读取：α_A =
arr(α_E)，形状与 deref 如出一辙；下标表达式 i 另立 α_i = int。
length：α_A = arr(β)（β 为新鲜变量，元素类型与长度无关）、
α_E = int。本题展示一个一般技巧：**当构造子分量与某个位置无
关时，用新鲜变量占位**，与 10.8.3 记录的其余字段同理。

### 25.18.3 练习三：带标签联合（变体）

设想增加 `tag f E`（给值 E 打上标签 f）与 `match E with f(x) -> S₁ | g(y) -> S₂`。
标签名像字段名一样全程序收集；tag 规则需要一个新构造子吗？一种
设计是变体项 `var(n₁: τ₁, …, nₘ: τₘ)`，tag f E 生成
α = var(…, f: α_E, …)，其他标签位置放什么？不能放新鲜变量——
那会允许"其他标签任意类型"，正确语义是"其他标签不存在"。
match 的约束是 α_E = var(…, f: α_x, g: α_y, …)，各分支绑定变量
与对应分量同一，未覆盖标签由语言层（穷尽性检查，另一种分析）
处理。本题的难点诚实地表明：**当"没有这个分量"也是信息时，
纯等式加占位变量的技巧就不够了**——需要选项型分量或额外的穷尽
性分析。这是约束表达力边界的又一实例。

### 25.18.4 练习四：把 null 改成"带所指类型的 null"

设想不采用第 27 章的三规则方案，而是让 null 写法变为
`null : ptr(int)`（标注类型的 null）。此时还需要 TyNull 与合一
特例吗？不需要：标注式 null 就是一个类型为 ptr(τ) 的普通叶子，
规则 α = ptr(τ_标注)，与任何指针的相容性由普通的构造子对接
完成，`p = null:ptr(int)` 只在 p 类型不同时报普通 shape 错误。
代价是把负担转嫁给程序员（每个 null 都要写标注），语言变得更
啰嗦但分析显著简化——**类型系统的复杂度在语言设计者、分析实现
者、语言使用者三方之间分配**，这是本章规则背后更上位的设计
视角。

## 25.19 与工业语言类型推断的对照

把 TIP 的简单系统放进真实语言的地图里，规则的选择与放弃会显得
更加自觉。

**Hindley–Milner（OCaml、F#、Haskell、Rust 的基石之一）** 同样
以一阶项合一为核心算法，本章第 26 章的 Robinson 合一与它们的
求解器是同一个算法家族；差别正如 10.17.3 所述：HM 有类型方案、
泛化与实例化，因此有 let 多态。一个有趣的历史事实是，HM 的
合一同样带 occurs 检查；`let rec x = ... ` 中递归变量的处理需要
特殊机制（先假定一个变量、再统一），与本章 pass A"先注册函数
类型、再生成函数体"的做法异曲同工——**先让名字存在，再填充
约束**，这是处理自引用的通用模式。

**Rust** 在 HM 之上叠加所有权与借用检查：借用检查器消费的是另
外的约束（生命周期变量之间的约束 `'a: 'b` 又是序关系！），类型
推断与借用分析分阶段进行，正如本章把"收集"与"求解"分开。
**Swift** 的类型推断一度大规模使用合一，但随着语言复杂度增长，
表达式类型检查的最坏情形代价（合一本身是近乎线性的，但带重载
与字面量协议的约束生成会产生指数级候选）迫使语言收紧推断范围。
**C++** 模板推导是受限的单向模式匹配而非双向合一——模板形参只
从实参"提取"，没有无方向等式，因此推导能力弱但可预测性强。

TIP 在这张地图上的位置可以精确标注：单目标（无模块）、流不敏感、
无多态、无子类型、但拥有完整的指针与记录类型项的**经典 spa 型
类型分析器**。它简单到定理 10.14 能在一章内论证，又真实到第 27 章的错误矩阵覆盖五种不同的失败动作；后续章节的所有更复杂分析，
在结构上都能看到它的影子：声明性质（规则/约束）与计算性质
（合一/不动点）分离。

## 25.20 本章规则一览

作为章末归纳，把全部生成规则的要点汇成一张表；表中"约束数"指
该构造固定生成的等式数（不含子树递归），"失败动作"指向第 11、
12 章求解时可能无法继续的对接步骤。

| 构造 | 生成的等式要点 | 约束数 | 可能的失败动作 |
|---|---|---|---|
| 整数字面量 | α = int | 1 | 无（永不冲突于正确的 int 链） |
| input | α = int | 1 | 与 10.18.1 型新条件规则无关 |
| 变量使用 x | α = τ(decl(x)) | 1 | 声明侧项的任何冲突 |
| L op R | α_L=int，α_R=int，α=int | 3 | 构造子不同（如 ptr 对 int） |
| C(A₁,…) | α_C = (α_A₁,…) -> α | 1 | 非函数 / 元数不一 / 分量冲突 |
| alloc P | α = ptr(α_P) | 1 | 与非 ptr 形状对接 |
| *P | α_P = ptr(α) | 1 | ptr 对非 ptr；occurs |
| &x | α = ptr(τ(decl(x))) | 1 | 与非 ptr 形状对接 |
| null | （第 27 章补 α = null） | 0→1 | null 三规则（第 27 章） |
| 记录字面量 | α = {fᵢ: α_Pᵢ} | 1 | 字段集不一 / 字段分量冲突 |
| R.f | α_R = 全字段形状（f 位为 α） | 1 | record shape / 分量冲突 |
| T = V | α_T = α_V | 1 | 两侧项冲突 |
| output E | α_E = int | 1 | int 对非 int |
| if/while C | α_C = int | 1（加分支递归） | int 对非 int |
| 函数级 | 函数名=TyFun；α_ret = α_R | 每函数 1 | 返回分量冲突 |

读表的方法不是背诵，而是验证一种**规律性**：除 TyFun 注册外，
每个构造恰好生成一条或三条等式，所有跨构造的信息传输都通过
"同一变量放在两个位置"。新增一种分析时（本书后面的章节将一再
这样做），首先要问的也是：性质项是什么构造子？每个语法构造写
几条等式（或更一般的约束）？标注的键选什么？本章把这套设问的
最简形态完整地走了一遍。
## 25.21 端到端小例：第四个程序的约束生成

前三例的导读都以 --check 的输出为起点；本例反过来——**先在纸面上
生成约束，再与机器输出对照**。请读者把这一节当作一次开卷练习：
每读到一步先自己写下等式，再继续。

程序如下，它把调用、指针、记录三类构造织在一起：

> // programs/mixed.tip（讲解用假想程序，见正文说明）
> box(r) {
>   return {v: r};
> }
> main() {
>   var p, z;
>   p = alloc 7;
>   z = box(*p).v;
>   output z;
>   return 0;
> }

需要说明：这个程序不在本章快照的 programs/ 目录中（三个快照
程序已固定 expected），它只服务纸面推演；读者可自行存入文件用
--check 验证。

### 25.21.1 pass A 与字段预收集

全程序字段名：记录字面量出现 v、字段访问 .v，故 F = {v}。
pass A 按定义顺序：box 的函数类型为 (t1) -> t2（形参 r 的变量
t1、返回分量 t2）；main 返回分量 t3，局部 p 为 t4、z 为 t5。
声明登记：box 名 = (t1) -> t2，r = t1；main 名 = () -> t3，
p = t4，z = t5。

### 25.21.2 box 函数体

返回表达式是记录字面量 `{v: r}`：r 的使用变量 t6，等式
t6 = t1（变量使用）；记录项变量 t7，等式 t7 = {v: t6}；函数级
返回等式 t2 = t7。三等式对接后 box 的返回类型为 {v: t1}——形参
r 的类型直接嵌在返回记录里。

### 25.21.3 main 函数体

`p = alloc 7`：7 为 t8=int；alloc 结果 t9 = ptr(t8)；目标 p 的
使用 t10：t10 = t4；赋值 t10 = t9。对接：t4 = ptr(int)。

`z = box(*p).v` 是本例的核心，按节点形状逐层展开。内层 `*p`：
p 的使用 t11 = t4；解引用结果 t12；等式 t11 = ptr(t12)。与 t4 =
ptr(int) 对接得 t12 = int。调用 `box(t12)`：被调名 box 的使用
t13 = (t1) -> t2；调用结果 t14；等式 t13 = (t12) -> t14。与声明
类型对接：t1 = t12 = int，t14 = t2；于是调用结果的类型是 box
返回分量的类型，即记录 {v: int}。外层字段访问 .v：被访表达式
（即调用）的变量 t14；访问结果 t15；全字段形状（F={v}）为
{v: t15}，等式 t14 = {v: t15}。与 t14 的记录类型 {v: int} 对接得
t15 = int。最后赋值：目标 z 的使用 t16 = t5；等式 t16 = t15，得
t5 = int。

`output z`：t17 = t5；等式 t17 = int，一致。`return 0`：t18 =
int；函数级 t3 = t18。全部等式均可满足，结论：main 与 box 的
类型分别为 () -> int 与 (int) -> {v: int}。

### 25.21.4 本例验证了哪两条一般规律

第一，**复合表达式的约束按节点结构机械展开，与表达式多复杂
无关**——`box(*p).v` 这种三层嵌套没有引入任何新机制，只是依次
套用 deref、call、field 三条已有规则；节点树有多深，等式链就有
多长，但每个局部步骤都与 10.6–10.8 的规则逐条对应。第二，
**返回记录把形参类型"打包输出"是完全免费的**：t1 同时是形参
变量与记录字段分量，box 的调用点经函数类型对接直接得到字段
类型——无须让 box "知道"调用者如何使用其返回值。这正是无方向
等式相比"自下而上算类型"的表达力：信息从实参经形参进入记录、
再经字段访问流出，整条路径在生成阶段只被等式挂接，求解时一次
贯通。

## 25.22 从约束到不动点：通往后续章节的桥梁

本章是"类型分析"一篇的中间章，也是全书结构的一个枢纽点。在
进入下一章合一之前，值得花一节看清：本章的"等式 + 解"框架与
第三篇将全面展开的**不动点**框架之间是什么关系。这个连接一旦
建立，后面二十章的新分析在结构上就都不陌生。

### 25.22.1 两种"由方程定义答案"的方式

本章的方程是**项等式**：未知量（类型变量）的取值空间是符号项的
集合，方程通过"同一"把未知量彼此连接，求解手段是合一（变量
绑定与构造子分解），得到的解是一个代换。数据流分析中的方程
（第 28 章起）形如 `X = F(X)`：未知量是某个**格**（lattice）中的
元素，方程右侧是单调函数（合并、传输），求解手段是从最小元
（或最大元）出发的**不动点迭代**，得到的解是 F 的不动点。

两种框架回答的问题同构——"一组方程定义了答案，算法要找到
它"——差别在取值空间的结构：项上没有偏序（两项要么能合一、
要么不能），格上有偏序（元素可比较、可取上下确界）。因此合一
处理"形状相容性"，不动点处理"信息累积与收敛"。

### 25.22.2 类型分析也可以写成格上的不动点

事实上 spa 同时展示了类型分析的另一种实现路线：把类型本身组织
成格（int、ptr(τ)、函数、记录加上顶元素 ⊤ 与底元素 ⊥），约束
`α = int` 变成对格变量的**限定**，合并点取最小上界。此时算法
不再是合一而是不动点迭代；它的好处是与数据流框架完全统一、
天然能容纳"信息逐步到达"（前向引用不再需要 pass A——格变量
从 ⊥ 开始、随迭代上升），代价是表达力微妙变化（两个不同构造
类型在合并点上升为 ⊤，错误以"某变量停在 ⊤"的形式报告）。

本书选择合一实现类型分析，是因为它的诊断更精确（冲突位置与
失败动作可定位）、定理 10.14 的论证更直接；但请记住两种路线
描述同一个规范，10.21 的纸面推演在格框架下同样成立。第 28–30
章建立格与不动点的一般理论后，读者可以尝试把本章收集器改接到
格求解器——那将是检验理解的极好练习。

### 25.22.3 "先声明方程、再独立求解"是全书的元结构

把镜头拉到最远：本书后续每一种分析——符号、常量、区间、指针、
过程间——都由两半组成。前半是**声明性的**：性质的词汇表
（类型项 / 格元素 / 抽象域）与按程序结构生成的方程（约束 /
数据流等式 / IFDS 边函数）；后半是**计算性的**：在取值空间上
求答案的算法（合一 / 不动点迭代 / 路径表达式算法）。两半的
接口是一个可独立检查的数据结构（Collected / 数据流方程系统），
正确性论证都沿"生成忠实于语义 + 算法求出方程的解"两步展开。
本章是这个元结构第一次以完整形态出现；读懂本章的组织方式，
就读懂了全书的目录。

还可以补一个观察：两半之间的接口数据（本章的 Collected）越
朴素，整个分析就越容易获得**可测试性**——可以在不运行后半段
算法的情况下检查生成结果（本章正是用 expected 快照这样做的），
也可以在不重新遍历程序的情况下反复试验不同算法。后续章节中
凡是接口设计得好的分析，都具有同样的"两半可独立验证"特征；
凡是两半纠缠的实现，测试与论证都会成倍变难。这个工程经验的
理论根源仍是定理 10.14 式的双向连接——只有接口语义被严格规定，
独立替换才不会改变分析的含义。

## 25.23 规模、复杂度与常见疑问

### 25.23.1 约束有多少、算法有多贵

对每个构造，收集器只做常数级工作（取新鲜变量、追加等式），
唯一的递归是沿语法树的结构遍历，因此**约束生成总工作量与程序
大小成线性关系**。变量编号的上界可以给出：每个表达式节点至多
一个节点变量，每个声明一个声明变量，每个字段访问产生至多
|F| 个占位变量（F 为全程序字段名集合），故变量总数 O(节点数 +
字段访问数 × 字段数)。字段预收集同样是一次线性遍历。注意复合
项的打印与第 26 章的代换作用与项的大小有关，而不是与节点数
有关——类型项可能嵌套（ptr(ptr(…))），其深度受表达式嵌套
深度限制，仍在线性总规模内。

记录字段名的全局处理是唯一具有"乘法"外观的部分：m 个字段访问、
程序共 n 个字段名时，形状展开生成 O(mn) 个占位变量。真实程序
中字段名集合通常稳定而有限，这一项远小于程序规模；但它提醒
我们，**"全局可见性"约定把字段访问的代价与程序其他位置的字段
名挂钩**——这是 10.8.3 语言选择的成本账。

### 25.23.2 常见疑问八则

**问：节点变量为什么不直接用声明变量，省掉 t10、t14 这些中间
变量？** 因为使用点是独立的语法节点，"使用 = 声明"本身是需要
被检查的**等式**而非定义；若使用点直接复用声明变量，"变量使用"
这条规则就无法生成、无法核对，多个使用点也失去独立标注位置。
中间变量让每条类型规则在输出中都有形可循。

**问：为什么比较的 why 文字与算术不同，规则却相同？** why 服务
人类阅读（指出规则在源程序中的语义出处），规则服务求解；同一
规则可以由不同语义位置产生。反过来也成立——同一 why 在不同
程序中可对应不同变量。

**问：函数可以返回函数吗？需要高阶类型规则吗？** TIP 文法不
允许（函数不是值，没有 lambda）；但即使允许，本章规则也无须
修改：CallE 只要求被调者变量与某函数类型项合一，返回分量放
函数类型项即可——**规则对"类型项嵌套多深"没有假设**，这是项
表示的通用性。

**问：如果同一个 var 在 pass A 之后又被声明一次怎么办？** 重复
声明在第 14 章已被拦截（Bindings.errors，退出码 3），收集器看到
的程序中每个名字唯一对应一个 Symbol。

**问：约束列表的次序会影响第 26 章的结果吗？** 不影响解，只影响
绑定链的形状与中间输出；最一般解在变量重命名意义下唯一。
10.16.2 的手工次序与机器次序不同、结论相同，已是实证。

**问：字段访问为什么不能当场只生成 `{f: α}` 这一个最小形状，
到求解时再补字段？** 因为合一只分解等式两侧**已有**的构造子，
不会在求解中往项里添加分量；形状在生成时必须完整。补分量是
"猜测"，超出了合一的能力——这也是为什么需要字段预收集。

**问：类型分析需要读第 16 章的 CFG 吗？** 不需要。类型规则只依赖
语法嵌套与声明绑定，不依赖控制流结构（if/while 规则只递归其子
节点）；CFG 服务的是后面的流分析。本章的收集器对 CFG 一无所知，
这也使它能在 CFG 构建失败（理论上不会）之外独立工作。

**问：如果程序太大、递归遍历栈溢出怎么办？** 语法树由解析器
产出，其深度本身受 ANTLR 的递归深度限制；真实编译器会对特定
深嵌套改写为显式栈遍历。对本章规则而言这纯属实现手段——遍历
是结构递归，改成迭代不改变生成的等式。

**问：`eq` 的 why 是中文短语，放进约束结构会不会污染通用工具？**
不会——why 不被求解器读取，它只是字符串负载；将来增加英文
版本或编号化的解释码都无须改动 Collected 的形状。把解释数据
与逻辑数据同构存放（每条等式自带出处），换来第 27 章错误报告
的可追溯性，这是刻意的接口选择而非随意混用。

**问：本章的约束看起来像 Prolog 的逻辑变量，二者是一回事吗？**
同源但不等价。Prolog 的归约（unification）正是 Robinson 合一，
运行时系统还提供回溯搜索与逻辑变元的多向求解；本章只取合一
这一片段，约束在收集时已全部确定，没有搜索、没有回溯、也没有
"一个变量在不同分支取不同值"。换言之，我们借用了逻辑变量的
**表示**，没有借用逻辑程序设计的**求解模型**。

**问：为什么不直接在 AST 节点里加一个 `Tp type` 字段保存变量，
而要另开 node 映射表？** 因为标注是**分析附加给 AST 的**，而 AST
是多个分析共享的前端产物：CFG、IR 生成、后面的数据流分析都不
希望节点类携带类型信息。以外部映射表为键，可以让同一份 AST 被
任意多个分析同时标注、互不干扰，节点定义保持中立。这个选择在
10.4.2"冻结的 AST 接口"原则下是必然的。

**问：如果将来 TIP 增加模块、函数可以跨文件怎么办？** 字段名
预收集与 pass A 的范围就要从"程序"扩大到"整个编译单元集合"；
规则形状不变，只是"全局"的边界变了。这也说明本章规则依赖的
是**作用域与可见性的定义**，而非某个具体的文件划分。
## 25.24 历史脉络、术语对照与自测

### 25.24.1 简短的历史脉络

用等式与合一做类型推断，有一条清晰的学术谱系。合一算法本身随
J. A. Robinson 1965 年关于归结原理的论文进入计算机科学，原本
服务自动定理证明；把它系统性地用于类型推断，经 Milner 1978 年的
HM 理论定型，成为 ML 家族的核心。本书依据的 spa（Møller 与
Schwartzbach《Static Program Analysis》）第 3 章把这一经典技术
重新组织为"约束生成 + 独立求解器"的教学形态，并以 TIP 语言为
载体；本章的规则编号与字段名全程序约定均出自该线索。LLVM 与
ANTLR4 不参与这一理论谱系——它们是把教学语言做成可运行工具的
工程手段：ANTLR 负责让语法不再是纸面文法，LLVM 让"分析结论 vs
真实执行"的对照可以在同一个示例工程内完成。阅读 spa 原书相应
章节时，可以把 10.6–10.10 与其约束规则逐条对照，本章多出的
部分是定理论证的导读与三例真实输出。

TIP 语言本身出自奥胡斯大学的静态分析课程传统，其设计哲学是
"小到可以在一个学期内实现，真到足以暴露分析中的本质困难"：
保留指针与记录（制造别名与形状问题）、保留递归与多函数（制造
过程间问题）、但移除多态、子类型、异常、模块等一切会让单个
分析失焦的特性。本章之所以能用一个线性遍历讲完约束生成，正是
享受了这种语言设计的克制；理解 TIP 取舍的读者，在面对真实
语言时会更快辨认出"哪些复杂度来自语言、哪些来自分析本身"。

### 25.24.2 术语对照

不同教材对同一对象用语不一，列出对照表，便于交叉阅读：

| 本章用语 | 常见同义语 | 所在位置 |
|---|---|---|
| 类型项 | 类型表达式、简单类型项 | 10.3 |
| 类型变量 α / tN | 未知类型、合一变量 | 10.2、10.3 |
| 约束 | 类型等式、（项）等式约束 | 10.3、10.5 |
| 节点变量 α_E | 表达式的类型占位 | 10.5 |
| 声明变量 α_D | 标识符类型、绑定类型 | 10.5 |
| 代换 S | 替换、绑定映射 | 10.3、第 26 章 |
| 有解 / 无解 | 可合一 / 不可合一 | 10.14 |
| 最一般解 | 最一般合一代换（mgu） | 10.14.3 |
| 流不敏感 | 非流敏感、合并式 | 10.17.4 |
| 类型方案 ∀α.τ | 多态类型、泛型签名 | 10.17.3 |

此外提醒一个中文表述上的陷阱：日常说"类型推导"时可能指本章的
**推断**（inference，无标注算出类型），也可能指第 24 章的**可推导
关系**（typing derivation，规则树）；本书语境中二者通过定理 10.14
等价，但讨论算法步骤时请注意区分。

### 25.24.3 自测清单

学完本章，不看正文应当能够完成下列事项；它们从易到难排列，任何
一项卡住都值得回到对应小节：

1. 说出约束生成相比"直接算类型"解决了哪三类困难（10.1）；
2. 给定任意表达式片段，指出它由哪些节点组成、各生成几条等式
   （10.4、10.6–10.8）；
3. 解释字段访问规则为什么需要全程序字段名预收集，以及该约定
   拒绝哪类合法外观的程序（10.8.3、10.15.3）；
4. 说明 NullE 留白的原因，以及第 27 章需要同时修改哪三个文件
   （10.8.1）；
5. 手工对接 mixed.tip 那种三层嵌套表达式的全部等式（10.21）；
6. 用自己的话陈述定理 10.14 的两个方向及各自的归纳组织
   （10.14）；
7. 解释"无多态、流不敏感"在标注模型中的精确成因，而不是笼统
   说"语言不支持"（10.17.3、10.17.4）；
8. 为 10.18 的假想构造写出等式，并指出哪些语义无法用等式加占位
   变量表达。

### 25.24.4 阅读地图：本章与前后章节的依赖

本章处于类型分析四章串的第二环，把阅读依赖明确标出，可以帮助
时间有限的读者安排顺序。

- 对第 24 章的依赖是**词汇与规则**：10.3 的类型项文法、10.6
  起每条规则对应的规则名（T-Call、T-Deref 等）都在那里定义；
  不读第 24 章而直接读本章，会把规则当成从天而降的等式。
- 对第 14 章的依赖是**绑定关系**：10.5 的 decl 表与 VarRef 规则
  消费 Bindings；但读者无须重读其实现，知道 uses 映射的含义即可。
- 与第 11、12 章是**弱连接**：CFG 不被本章使用；IR 生成只在
  10.13 作为镜像与执行基准出现。读者可以先读 10.1–10.12 再回头
  补 10.13。
- 对第 26 章是**前向接口**：10.5 的 Collected 就是其输入；读完
  本章立刻进入第 26 章效果最好，10.16 的手工对接会在那里被
  算法化。
- 对第 27 章是**总装约定**：null 三文件修改、错误矩阵都在那里；
  10.17 的局限清单在那里将被实测。
- 对第三篇（第 28 章起）是**元结构先声**：10.22 已建立"方程
  声明 + 独立求解"的桥梁，届时可直接套用。

### 25.24.5 进一步的实验建议

若读者希望在本章代码上继续动手，三个方向性价比最高。其一，把
收集器对接到**不同的求解器**（先自己写一个朴素的反复扫描对接，
再读第 26 章），对比同一 Collected 上两种求解的中间过程——这会
把"生成与求解独立"从一句话变成肌肉记忆。其二，按 10.18 实际
扩展 type.hpp 与文法，跑通一个新构造，并用 expected 快照固定其
输出；10.18.3 的变体构造会迫使你处理"缺失即信息"，是最好的
拔高题。其三，按 10.22.2 的提示尝试**格路线**：等第三篇学完格与
不动点后，把项等式改写为格变量限定，用迭代求解，比较两种错误
报告——同一种规范、两种世界观，这是从"会实现"走向"会选择
抽象"的关键一步。

完成实验时有一个建议：每一步都保留 expected 快照。约束生成器的
行为可以由输出完整刻画，这使它成为理想的"先快照、后重构"对象；
当你为了支持新构造而调整 pass A/B 的内部组织时，只要快照不变，
定理 10.14 所依赖的可观察行为就没有改变——重构的安全性由快照
背书，而不必靠人工重新推演全部规则。
## 25.25 工程注意点

只保留本章实现中真正具有一般性的几点；它们是原理的直接推论，
不是孤立的调试轶事。

1. **让"声明什么"与"判定什么"在接口上分离。** collect 不报告
   错误、不做替换，所有判定集中在求解器；这让两边都能被单独
   测试与论证。反过来的教训是：一旦在生成分支里顺手做合并，
   两遍结构、错误次序、why 追溯都会一起失控。
2. **所有跨阶段共享的标识用稳定指针，不用名字字符串。** 节点
   变量键为 `const Expr *`、声明变量键为 `const Symbol *`；改名、
   嵌套同名都不影响标注。字符串名字只在它被解析的那一刻有用。
3. **需要全程序信息的规则必须显式预收集。** 字段名如此，将来
   函数摘要（第 52 章）也如此：把"收集事实"与"使用事实"分成
   两个可辨认的阶段，规则为何需要某遍扫描才能写进正文，而不是
   藏在遍历顺序里。
4. **快照输出只依赖 show() 与固定顺序。** 容器遍历顺序、字段
   排序都要确定化（TyRec 构造排序、vector 顺序追加）；任何
   来自哈希种子或地址的输出都会破坏逐字节复现。
5. **分期引入需要求解器配合的类型项。** null 的三章隔离是范例：
   宁可让 NullE 暂时空着并写明原因，也不要在合一算法被验证之前
   往规则里塞特例。

若把这五点再压缩成一个判断标准，就是：**好的约束生成器应当无聊
得令人安心**——它的全部行为都可以从源程序的语法形状直接预言，
没有隐藏状态、没有隐式判定、没有对遍历次序的隐含依赖。阅读本章
constraints.cpp 时若某段代码让你觉得"这里在做规则之外的事"，那
通常就是设计开始腐化的信号；反过来，当每一行实现都能指回一条
形式规则时，正确性论证就不再是额外负担，而只是对代码的逐行
注释。

带着这个标准进入第 26 章：那里的代码同样应当无聊——每一步合一
都能指回 10.16.1 的三个对接动作之一，没有第四种动作、也没有
特例（null 的特例要到第 27 章才被允许进入）。两篇章并读，类型
分析这台小机器的全部秘密就见底了。

## 25.26 小结

本章把第 24 章的声明式类型规则翻译成了一台机器可以执行的前半
段算法：为每个表达式节点与每个声明显式指定类型变量，按十类
表达式构造、四类语句构造与函数级规则生成无方向的一阶项等式，
并用全程序字段名预收集处理记录访问。收集器只做"造新鲜变量 +
记等式"两个动作，不做任何判定；定理 10.14 保证了它与类型规则
的双向等价：规则可类型化当且仅当约束系统有解。

三个示例的真实输出展示了信息如何沿等式链汇聚：arith 中调用点
与定义点在函数类型分量上对接，ptr 中三层指针嵌套被四条等式
完整展开并与真实执行相互印证，rec 中全字段形状让字段访问无须
流信息、也暴露了全局字段名约定的边界。

下一章给出算法的后半段：Robinson 合一。它将消费本章的
`Collected`，以"变量绑定 + 构造子分解"求出最一般解，或在无解
时给出精确的冲突位置——本章输出中所有的 t1、t2、t3 到那时
才会真正变成 int、ptr(int) 与 `{x: int, y: int}`。

最后用三句话收束全章的思想，它们在后续章节会被反复回响。

第一句关于**抽象的组织**：一种可学习、可论证的分析，总是先把
"程序应当满足什么"写成独立的数据（规则、约束、方程），再让
算法只对这份数据负责。本章的 Collected 是这种组织的最简标本。

第二句关于**表达力的自觉**：每一条"做不到"——拒绝重载、拒绝
多态、拒绝区分程序点、同名字段被迫同型——都不是实现的失败，
而是"一个声明一个无量词类型项、约束只有等式"这一简洁模型的
对应面。选择简单模型时同时接受其边界，比事后惊讶于边界更重要。

第三句关于**工具的位置**：ANTLR4 让 TIP 成为能解析的真实语言、
LLVM ORC 让分析结论随时可与真实执行对照，但它们都不改变定理
10.14 的任何一行。工具服务于论证与验证，理论的核心仍然是：
类型项、约束、合一，以及三者之间可以逐构造核对的对应关系。

---

上一章：[24 类型变量](24-type-vars.md) · 下一章：[26 合一](26-unify.md)
