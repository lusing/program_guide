## 26.19 真实输出解读

手工演算的结论必须接受机器核对。本节逐段阅读
`expected/output.txt`——这是 tipa 对 programs/ 下三个示例
依次执行 `--check` 的真实标准输出，验证时逐字节比对。

### 26.19.1 输出的整体结构

文件分三段，每段对应一个程序：

- `== arith.tip ==` 等标题行标明程序；
- 每个程序的输出以 `solution:` 开头，随后每个有解的类型
  变量占一行：`tN -> 类型`；
- 三段拼接时段间空行分隔。

箭头读作"该变量在最终代换下归一化后的类型项"。输出只列
**已确定的**变量：归一化结果仍是未绑定 TyVar 的空位不打印。
本章三个程序恰好把所有变量都约束到了具体类型，因此编号
连续出现；一般情况下，未出现的编号意味着程序对该位置不
加约束——那不是信息缺失，而是"此处任意类型皆可"的
精确记录，与 11.3.3 节主解保留空位的性质一致。

### 26.19.2 arith：一片 int 中的函数类型

arith 段列出 t1 到 t21，其中 t1 至 t16 与 t18 至 t21 全部
`-> int`，唯一例外：

```
t17 -> (int) -> int
```

t17 是调用处被调位置对 add1 名字的使用变量，它与阶段 A
登记的函数类型共享结构；参数 t3 经实参 x、返回 t4 经
`n + 1` 先后钉成 int，归一化后得到 `(int) -> int`。这一行
是整段输出中信息密度最高的地方：它同时报告了 add1 的参数
个数（1）、参数类型与返回类型。它也是 26.14 节手工结论的
逐字兑现——21 个变量、函数型落在 t17。

### 26.19.3 ptr：三层构造子同框

ptr 段的 16 行呈现三种形状：

```
t2 -> ptr(int)
t3 -> ptr(ptr(int))
```

以及散布在各节点上的 `ptr(int)`、`ptr(ptr(int))` 与 int。
t2 是 p：alloc 给出 `ptr(int)`；t3 是 q：`&p` 的规则把 p 的
类型整个包进 ptr，因 p 持指针而成双重指针。读这一段的
要领在 11.15.6 已说：每一层 ptr 都要能向程序文本回索。
例如 t7、t8、t16 三处 `ptr(ptr(int))` 分别对应取地址节点、
q 的赋值目标、双重解引用中对 q 的使用——同一事实在三条
等式里的三个投影，归一化后形状相同，彼此印证。t1（返回
值）为 int，对应 `**q` 两次穿 ptr 到底。

### 26.19.4 rec：按名归一的记录

rec 段 12 行，反复出现 `{x: int, y: int}`：

```
t2 -> {x: int, y: int}
t7 -> int
t12 -> int
```

t2 是 r 的声明，保留记录字面量的字段次序与载荷类型；t7、
t12 是两次字段访问中"其他字段"的占位变量，被按名对账
填满为 int；t10（return 节点）为 int，带动返回变量 t1。
输出里看不到 11.16.3 那些 `{y: ..., x: ...}` 的临时排列——
它们只是合一过程中的读取对象，最终答案只保留规范形状。
这从经验一面展示了"按名、与次序无关"：输入侧的排列
变化没有在结论里留下任何痕迹。

### 26.19.5 手工与机器的逐行核对

把三节手工演算的结论与输出对账：

- arith：手工给出"21 变量、t17 为 (int)->int、其余 int"——
  与 arith 段 21 行逐一相符；
- ptr：手工给出 t1=int、t2=ptr(int)、t3=ptr(ptr(int))，
  以及全部中间节点形状——与 ptr 段 16 行相符；
- rec：手工给出 12 变量、t2 记录、t7/t10/t12 为 int——
  与 rec 段相符。

没有任何一行需要读者借助源码另行猜测：每个编号的来历都在
11.14–11.16 交代过，最终项的语义都有规则对应。这正是本
教程要求"代码全部在正文引用"的意图——输出是用来读的，
不是用来和源文件对谜的。

### 26.19.6 输出确定性的意义

最后指出一个验证层面的事实：这份输出是**确定性**的——
同样输入反复运行，变量编号、排列、次序逐字节不变。其
保障有二：收集器对 AST 的遍历次序固定；合一器在同构
造子分量上按固定顺序处理（函数参数按下标、记录字段按
左表顺序查名）。确定性使"真实输出"可以直接作为回归
基线：任何对分析器的改动一旦改变结论，字节比对立刻
暴露。它也让 26.13 节的论证有了经验落脚点——论证声称
算法对每个有解等式给出主解，而主解在固定编号约定下
是一个唯一的、可复现的文本。
## 26.20 理论谱系与变体

合一不是孤立的算法。理解它在理论地图上的位置，既有助于
记住它的能力边界，也能解释此后章节里若干设计的来历。本节
做一次横向的梳理，仍然只讲原理，不做工具盘点。

### 26.20.1 历史的起点：归结与逻辑程序

合一随 Robinson 1965 年的归结原理（resolution principle）
进入计算机科学。归结是一阶逻辑的一条推理规则：从两个含
互补文字的子句推出新子句；而互补性的判定要求把两个谓词
项"对上"——这正是合一的工作。Robinson 的贡献是给出一个
机械过程，为可对上的项构造最一般合一元。此前推理规则的
应用依赖人的巧思，合一让"寻找实例"这一步第一次可以由
机器完成。自动定理证明由此获得了一个系统的搜索引擎。

这条线后来直接长成了逻辑式程序设计：Prolog 的求解就是
在程序子句上反复做归结与合一，合一同时承担了参数传递、
模式匹配、数据构作解构三重职能。本章的类型应用是另一条
线，但内核是同一个算法：**在自由项代数上求解有限等式**。

### 26.20.2 类型推断中的合一

类型方向的标志性应用是 ML 系语言的类型重建。Hindley–Milner
类型系统把"程序是否良类型"同样归约为类型项等式的可解
性：算法为每个语法结构发类型变量，按类型规则收集等式，
再用合一求解。本章实现的就是这条路线的一个教学版本，
差别仅在：TIP 只有顶层多态（函数本身不被泛型实例化），
没有 let-多态的泛化与实例化步骤。

理解这一层谱系有助于看清"为什么是等式而不是别的"。类型
规则在逻辑形式上是"前提成立则结论成立"的推断；若只沿
程序文本正向推断，遇到无类型标注的变量便无从起步。等式
表示把所有方向的依赖**同时**写下——某变量等于什么、某
位置须为什么形状——求解再统一安排次序。约束式分析"先
收集、后求解"的两段结构，根源就是推断的方向性与程序
文本的方向性不必一致。

### 26.20.3 合一与匹配的区别

一个常被混淆的概念是模式匹配（matching）。匹配要求把
**模式** P 与项 T 对上，且代换只作用于 P 中的变量：
寻找 σ 使 σ P = T，T 中的变量不被绑定。合一则对称：两侧
的变量都可以被绑，σ T₁ = σ T₂。

例如 P = ptr(α) 匹配 T = ptr(int)，得 α=int；但若 T 中也
含变量，匹配不允许动它。本章函数调用处需要的恰恰是对称
的：实参可能是复杂表达式、被调类型也可能尚未确定，信息
必须双向流动（11.14.5 的分量递归两侧都含变量）。switch 式
语言构造（模式与固定值对上）用匹配即可，类型推断非用
合一不可。算法上匹配是合一的特例：先把一侧变量冻结即可
得到。

### 26.20.4 复杂性：朴素做法与近线性实现

本章实现是朴素 Robinson 过程，最坏情况可以达到指数时间：
反复在深层结构上代换，同一个大项可能被遍历、重建很多次。
这对教学无碍（类型项通常很小），但值得知道理论与工程
各自的结论：

- 一阶项合一的**决策问题**在线性时间内可解；
- 实际高效实现以 **union-find（不相交集合）**表示变量
  等价类，路径压缩与按秩合并使等价类维护近常数摊销；
  分量结构用显式指针链接，occurs 与构造子比较沿链接
  进行；
- 采用 union-find 后，"先展开再判定"不再是沿映射链的
  行走，而是一次 find 操作；绑定是 union。算法的逻辑
  （六情形）原封不动，变的只是数据结构。

这是一个好的"原理稳定、实现演进"的例子：26.13 节的
正确性论证针对六情形的逻辑，任何保持该逻辑的表示优化
都自动继承论证，无须重证。

### 26.20.5 递归类型：放开 occurs 之后

11.13.6 已声明本章只承认有限树。若语言承认递归类型，
世界如何变化？以 μ 记法表示：`μ α. ptr(α)` 是"折叠的
无穷类型"，配一对 fold/unfold 规则把它与
`ptr(μ α. ptr(α))` 互认为同型。在这种**等递归**
（equirecursive）语义下，`α = ptr(α)` 有解，occurs 检查
改为"检查是否形成新的循环等价类"，而循环本身允许。

但放开不是免费的：两个 μ 类型是否相等需要检查无穷展开
后的一致性（实践中用"结"的双模拟算法），类型项也不再
是简单有限树。本章拒绝这类等式，是因为 TIP 的类型语义
不含 μ——11.17.3 的程序在 TIP 里确实错误。规则的取舍
由语言定义决定，合一器忠实执行，不自行宽容。另一条路线
是把递归显式化（程序里写出 fold），那类语言里合一仍可
保持简单，复杂性移到了源程序。

### 26.20.6 子类型：合一不再适用的方向

若类型之间存在"是一种"关系（如区间更小者可用于更大者
的位置），等式就被换成不等式 T <: U。不等式不能用合一
求解：合一只回答"能否相同"，而子类型问"能否一边满足
另一边"。对应算法是产生约束后用子类型化的闭包运算
（沿子类型格传播、对上界/下界取交并），其理论形态更
接近后面章节的单调数据流与格上不动点。本教程此后处理
区间、符号等抽象域时，用的正是格与不动点而不是合一——
这不是工具偏好，而是约束性质决定的：**等式用合一，
偏序约束用不动点**。

还有居中的形态：行多态（row polymorphism）给记录字段
集合发变量，字段访问产生"该行至少含此字段"的约束，
求解仍是一种合一，但项里多了带尾变量的行构造子；它
以等式方式精确表达了"字段可增、按名对应"，是记录分析
的另一经典路线。Haskell 类型类、Rust trait 的求解则在
合一之上叠加"约束蕴涵"——先合一、再解限定条件，两个
阶段层次分明。

### 26.20.7 自由项代数之外：E-合一与同余闭包

最后把视野放到一般等式理论。本章合一是在**自由**项代数
上工作：构造子之间除了等式本身给出的关系外没有任何
公理。若存在额外公理（如交换律、结合律），合一问题
变成 E-合一，难度剧增——仅含交换律的理论中算法就复杂
得多，一般 E-合一甚至不可判定。

一个对静态分析极重要的相邻概念是**同余闭包**
（congruence closure）：给定一组"这些项相等"的事实，
在"同构造子、分量分别相等则整体相等"的同余规则下求
全部等价类。它不处理变量绑定，而是合并固定项的等价
关系，是 SMT 求解器中等式理论的核心过程，也是 e-graph
数据结构的原理基础。本教程第 71 章回顾工业级分析时会
再遇这一家族。届时读者可以对照：合一回答"代换后能否
相同"，同余闭包回答"在已知相等事实下谁与谁同余"，
两者共享"构造子相容性"这条脊梁，服务于不同的问题。

### 26.20.8 谱系小结

把这张地图收成一句话：凡问题能表述为"有限项上的等式、
构造子无额外公理"，Robinson 合一是规范解答；换上限制定
则是格与不动点，换上公理理论则是 E-合一或同余闭包，
换上无穷类型则是循环类型的一致性检查。**先认清约束的
代数形状，再选求解框架**——这是本章留给全书的方法论，
比算法本身更耐用。
## 26.26 本章代码

本章示例 `11_unify` 在前几章基础上新增了 unify.hpp /
unify.cpp 两个文件，并把 main.cpp 的 `--check` 扩展为
"收集 → 合一 → 打印解"的完整流程。其余文件——文法、
AST、名字解析、约束收集、IR 生成与 JIT——沿用上一章快照，
本章未作改动，仍全部嵌入以便示例自包含、可独立构建。

下列代码块按"文法 → 类型与约束 → 合一器 → 主程序 →
支撑模块 → 期望输出"排列。每个代码块首行的标记给出文件
在示例目录中的相对路径，块内文本与磁盘文件逐字节一致；
阅读时建议对照 26.4 节的判定树：unify.cpp 的分支顺序就是
判定树本身。

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

```cpp
// file: src/unify.hpp
// Robinson 合一：求解第 25 章收集的类型等式。
// Substitution 把类型变量编号映射到类型；apply 沿映射反复走到非变量。
// 合一失败抛 TypeError，由 main 转成"类型错误"诊断（退出码 3）。
#pragma once

#include <map>
#include <stdexcept>
#include <string>

#include "type.hpp"

namespace tip {

class TypeError : public std::runtime_error {
public:
    explicit TypeError(const std::string &msg) : std::runtime_error(msg) {}
};

using Subst = std::map<int, Tp>;

// 反复代换直到 t 不是映射中的变量；变量间的别名也会被走穿。
Tp apply(const Subst &s, Tp t);

// 深度归一：顶层与结构内部的变量全部展开，重建为只含未约束变量的类型。
// --check 打印最终类型时使用，避免出现 ptr(t5) 这样的嵌套别名。
Tp normalize(const Subst &s, Tp t);

// 把等式 a = b 的信息并入 s；失败抛 TypeError。
void unify(Tp a, Tp b, Subst &s);

}  // namespace tip
```

```cpp
// file: src/unify.cpp
#include "unify.hpp"

#include <algorithm>

namespace tip {
namespace {

// 沿替换反复走到非变量。文件内统一用这个名字，避免与 std::apply 冲突。
Tp applySubst(const Subst &s, Tp t) {
    while (const auto *v = dynamic_cast<const TyVar *>(t.get())) {
        auto it = s.find(v->id);
        if (it == s.end()) break;
        t = it->second;
    }
    return t;
}

// occurs 检查：结构 t（先展开别名）中是否出现编号 id 的变量。
bool containsVar(const Subst &s, int id, Tp t) {
    t = applySubst(s, t);
    if (const auto *v = dynamic_cast<TyVar *>(t.get())) return v->id == id;
    if (const auto *p = dynamic_cast<TyPtr *>(t.get()))
        return containsVar(s, id, p->to);
    if (const auto *f = dynamic_cast<TyFun *>(t.get())) {
        for (const Tp &a : f->params)
            if (containsVar(s, id, a)) return true;
        return containsVar(s, id, f->ret);
    }
    if (const auto *r = dynamic_cast<TyRec *>(t.get()))
        for (const auto &kv : r->fields)
            if (containsVar(s, id, kv.second)) return true;
    return false;
}

void doUnify(Tp aa, Tp bb, Subst &s) {
    Tp a = applySubst(s, aa), b = applySubst(s, bb);
    auto *va = dynamic_cast<TyVar *>(a.get());
    auto *vb = dynamic_cast<TyVar *>(b.get());

    // 同一变量：恒等，成功。
    if (va && vb && va->id == vb->id) return;

    if (va) {
        if (containsVar(s, va->id, b))
            throw TypeError("occurs check: t" + std::to_string(va->id) +
                            " occurs in " + b->show());
        s[va->id] = b;
        return;
    }
    if (vb) {
        // 交换参数，复用上面的变量绑定分支。
        doUnify(b, a, s);
        return;
    }

    // 两侧都是构造类型：构造子必须相同。
    if (typeid(*a) != typeid(*b))
        throw TypeError("type mismatch: " + a->show() + " vs " + b->show());

    if (const auto *p = dynamic_cast<TyPtr *>(a.get())) {
        doUnify(p->to, dynamic_cast<TyPtr *>(b.get())->to, s);
    } else if (const auto *f = dynamic_cast<TyFun *>(a.get())) {
        auto *g = dynamic_cast<TyFun *>(b.get());
        if (f->params.size() != g->params.size())
            throw TypeError("arity mismatch: " + a->show() + " vs " + b->show());
        for (size_t i = 0; i < f->params.size(); ++i)
            doUnify(f->params[i], g->params[i], s);
        doUnify(f->ret, g->ret, s);
    } else if (const auto *r = dynamic_cast<TyRec *>(a.get())) {
        auto *q = dynamic_cast<TyRec *>(b.get());
        if (r->fields.size() != q->fields.size())
            throw TypeError("record shape: " + a->show() + " vs " + b->show());
        for (const auto &kv : r->fields) {
            auto it = std::find_if(q->fields.begin(), q->fields.end(),
                                   [&](const auto &x) { return x.first == kv.first; });
            if (it == q->fields.end())
                throw TypeError("no field '" + kv.first + "' in " + q->show());
            doUnify(kv.second, it->second, s);
        }
    }
}

// 递归重建：结构内部每个分量先展开别名再重建。
Tp rebuild(const Subst &s, Tp t) {
    t = applySubst(s, t);
    if (dynamic_cast<TyInt *>(t.get()) || dynamic_cast<TyVar *>(t.get()))
        return t;
    if (const auto *p = dynamic_cast<TyPtr *>(t.get()))
        return std::make_shared<TyPtr>(rebuild(s, p->to));
    if (const auto *f = dynamic_cast<TyFun *>(t.get())) {
        std::vector<Tp> ps;
        for (const Tp &a : f->params) ps.push_back(rebuild(s, a));
        return std::make_shared<TyFun>(std::move(ps), rebuild(s, f->ret));
    }
    if (const auto *r = dynamic_cast<TyRec *>(t.get())) {
        std::vector<std::pair<std::string, Tp>> fs;
        for (const auto &kv : r->fields) fs.emplace_back(kv.first, rebuild(s, kv.second));
        return std::make_shared<TyRec>(std::move(fs));
    }
    return t;
}

}  // namespace

Tp apply(const Subst &s, Tp t) { return applySubst(s, t); }

Tp normalize(const Subst &s, Tp t) { return rebuild(s, t); }

void unify(Tp a, Tp b, Subst &s) { doUnify(a, b, s); }

}  // namespace tip
```

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

```cpp
// file: src/main.cpp
// 第 26 章配套程序：约束收集 + Robinson 合一。
//   --check FILE    : 收集等式 -> 逐个合一 -> 打印每个变量的解
//   --emit-ir FILE  : 打印未优化的 LLVM 模块
//   --run FILE INPUTS: 每行输入真实执行一次
#include <fstream>
#include <iostream>
#include <memory>
#include <set>
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
#include "unify.hpp"

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

// 收集一个类型结构中出现的全部变量编号。
void idsOf(const tip::Tp &t, std::set<int> &out) {
    if (const auto *v = dynamic_cast<tip::TyVar *>(t.get())) {
        out.insert(v->id);
        return;
    }
    if (const auto *p = dynamic_cast<tip::TyPtr *>(t.get()))
        idsOf(p->to, out);
    if (const auto *f = dynamic_cast<tip::TyFun *>(t.get())) {
        for (const tip::Tp &a : f->params) idsOf(a, out);
        idsOf(f->ret, out);
    }
    if (const auto *r = dynamic_cast<tip::TyRec *>(t.get()))
        for (const auto &kv : r->fields) idsOf(kv.second, out);
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

        tip::Subst s;
        try {
            for (const tip::Con &k : c.cons) tip::unify(k.a, k.b, s);
        } catch (const tip::TypeError &e) {
            std::cout << "type error: " << e.what() << '\n';
            return 3;
        }

        // 收集约束中出现的全部变量，按编号打印已确定的解。
        std::set<int> all;
        for (const tip::Con &k : c.cons) {
            idsOf(k.a, all);
            idsOf(k.b, all);
        }
        for (const auto &kv : c.decl) idsOf(kv.second, all);

        std::cout << "solution:\n";
        for (int id : all) {
            tip::Tp t = tip::normalize(s, std::make_shared<tip::TyVar>(id));
            if (dynamic_cast<tip::TyVar *>(t.get()) == nullptr)
                std::cout << "t" << id << " -> " << t->show() << '\n';
        }
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

```text
; expected: expected/output.txt
== arith.tip ==
solution:
t1 -> int
t2 -> int
t3 -> int
t4 -> int
t5 -> int
t6 -> int
t7 -> int
t8 -> int
t9 -> int
t10 -> int
t11 -> int
t12 -> int
t13 -> int
t14 -> int
t15 -> int
t16 -> int
t17 -> (int) -> int
t18 -> int
t19 -> int
t20 -> int
t21 -> int
== ptr.tip ==
solution:
t1 -> int
t2 -> ptr(int)
t3 -> ptr(ptr(int))
t4 -> ptr(int)
t5 -> int
t6 -> ptr(int)
t7 -> ptr(ptr(int))
t8 -> ptr(ptr(int))
t9 -> int
t10 -> int
t11 -> ptr(int)
t12 -> int
t13 -> ptr(int)
t14 -> int
t15 -> ptr(int)
t16 -> ptr(ptr(int))
== rec.tip ==
solution:
t1 -> int
t2 -> {x: int, y: int}
t3 -> {x: int, y: int}
t4 -> int
t5 -> int
t6 -> {x: int, y: int}
t7 -> int
t8 -> {x: int, y: int}
t9 -> int
t10 -> int
t11 -> {x: int, y: int}
t12 -> int
```

## 26.27 工程注意点

原理之外，记录五条实现层面的注意点。它们是上述原理在
工程中的直接推论，而不是与原理并列的"经验清单"。

1. **递归调用 doUnify 前必须先展开两个操作数。** 展开是
   所有判定的前提；漏掉任一侧，轻则走到错误的交换分支，
   重则对已绑定变量重复写入、静默覆盖既有结论（11.6.1）。

2. **绑定表只增不改，occurs 是唯一的"守门员"。** 不要
   试图在冲突时"改绑"另一个项——已绑变量背后往往已有
   其他等式依赖它。任何无解情形都应以异常显式失败，
   绝不能吞掉异常继续求解，否则后续答案全部失真。

3. **打印与求解使用不同的代换深度。** 求解中顶层展开
   即可；对用户呈现的类型必须深度归一化，否则内部变量
   编号泄漏，输出不可读。归一化是纯观察操作，放在求解
   完成之后做一次。

4. **保持遍历与处理次序固定。** 分量按确定顺序递归
   （参数按下标、记录按左字段查名），使诊断与输出可
   复现；输出确定性是回归验证以字节比对为基线的前提。

5. **类型项以 shared_ptr 共享，绑定写入 map、不写对象。**
   同一类型变量被多处引用是常态；任何"就地修改类型
   对象"的做法都会在看似无关的位置引发别名问题。可
   变状态集中在一张表上，正确性论证才有着力点。

## 26.28 小结

本章从第 25 章留下的等式出发，回答了"程序的类型要求能否
同时满足、满足时每个变量是什么"。

- 直觉上，解类型等式与解算术等式同构：绑定变量、沿绑定
  代换、在构造子对不上处发现冲突；
- 形式化上，类型构成自由项代数，解是使等式两侧作用后
  相同的代换，而主解（mgu）是承诺最少、任何其他解都可
  由它复合得到的那一个；
- 算法上，Robinson 过程是六情形的判定树——恒等、绑定、
  occurs、交换、构造子冲突、分量递归——其穷尽性使"失败"
  成为可靠的判定；
- 正确性上，由无循环不变量、字典序度量的终止性、绑定
  保持旧等式的可靠性、以及"任意解都能表为 τ∘s"的主解
  性质，得到总结论：**成功当且仅当等式有解，成功给出
  主解，失败确无救**；
- 经验上，arith、ptr、rec 三个程序的手工演算与机器输出
  逐行相符：函数类型、双重指针、按名记录都不是凭启发式
  的猜测，而是等式强迫的唯一答案。

合一器的位置至此明确：它是约束式分析的求解内核，也是
"可靠"与"完备"这两个词第一次可以机械核查的地方。第 27 章把这套类型分析总装成形——补入 null 规则、按表达式输出
类型、并以一个错误矩阵系统检验全部失败出口；再往后，当
约束从等式变为偏序，我们将放下合一、走进格与不动点的
世界。
# 第 26 章　Robinson 合一：求解类型等式

## 26.1 从第 25 章的产物说起

上一章我们为 TIP 程序收集了一叠类型等式：每个表达式持有一个类型
变量，程序结构把这些变量用 `=` 连起来。收集器只回答了"程序要求
什么"，还没有回答"这些要求能不能同时满足、满足时每个变量究竟是
什么类型"。本章回答后半个问题。

先回顾一个小例子，看清待解对象的形状。表达式 `3 + 4 * 2` 产生的
等式大意是：`τ(3) = int`、`τ(4) = int`、`τ(2) = int`、
`τ(4*2) = int`、`τ(3+4*2) = int`。这些等式一望便知全部可解，
答案清一色是 int。真正有趣的是另外两类情形。

**第一类，等式给出非平凡的结构。** 对 `p = alloc 5`，收集器写出
`τ(p) = ptr(τ(5))`、`τ(5) = int`；单独看第一个等式，`τ(p)` 还
带着一个未知分量，必须把第二个等式的信息"传进去"才能得到
`τ(p) = ptr(int)`。这说明求解不是逐行独立的：等式之间通过共同
变量耦合，一条等式的解会改写另一条等式的形状。

**第二类，等式可能无解。** `x = &x` 产生 `τ(x) = ptr(τ(x))`。
任何熟悉类型系统的读者都会警铃大作：它要求一个类型等于"指向
自己的指针"，而有限的类型结构不可能填得满这个自我嵌套。求解器
必须发现这种无解并报告，而不是无限循环或产出一个残缺的答案。

本章的算法——Robinson 合一（unification）——正是对这一叠等式
系统地"传播结构、发现矛盾"，它一次处理一条等式，维护一张"已经
确定的变量绑定表"，直到全部等式处理完毕（此时得到每个变量的
最终类型），或在某一步发现矛盾（此时报告类型错误）。

为什么这件事值得用一整章来讨论？因为合一是整个约束式分析的求解
内核：第 24–27 章的类型分析靠它出答案，而它给出的不只是"一个
解"，而是**最一般的解**——凡是程序允许的类型形状，这个解一个
不多地保留；凡是程序禁止的形状，这个解一个不放地排除。理解合一，
就理解了类型分析"凭什么既不放过错误、又不冤枉正确程序"。

## 26.2 直觉：用"代换"解等式

### 26.2.1 与算术等式的类比

先借一个熟悉的场景建立直觉。解算术方程时，`x = 3` 这样的等式
直接给出 x 的值；随后在任何出现 x 的地方都可以**代换**成 3，
`x + y = 5` 因此变成 `3 + y = 5`，再解出 y。解类型等式用完全
相同的两个动作：

1. **绑定**：遇到 `变量 = 项` 且项不引起循环时，记下
   "该变量由该项代替"；
2. **代换**：此后任何地方见到这个变量，都用所绑的项替换，再
   继续化简其余等式。

例如 `τ(p) = ptr(τ(5))` 先记下绑定 `τ(p) ↦ ptr(τ(5))`；
随后解出 `τ(5) ↦ int`；当我们最后要报告 τ(p) 时，沿绑定层层
代换：`τ(p) → ptr(τ(5)) → ptr(int)`。答案是沿绑定链走出来的。

### 26.2.2 绑定的方向：为什么不损失信息

等式在逻辑上是对称的：`a = b` 与 `b = a` 同义。但算法处理时却
似乎有方向——总是把"变量"绑到"另一个项"，从不反过来把一个
复合结构绑到变量。这不是任意的偏倚，而是由两类对象的性质决定的：

- 变量是**未定物**，它本来就代表"某个尚未确定的类型"，把它
  绑到一个具体项上，正是在消除这种未定；
- 复合结构（int、ptr(…)、(…)→…、{…}）是**已定物**，它的构造
  子和分量已经写明，不能被"重新定义"。

把未定绑到已定，信息是单向增长的：每一步，世界上"尚未确定的
变量"减少一个，而已确定的结构不被破坏。若反过来试图把复合项
"绑到"变量，等于声称一个已经写明的构造子可以被另一个东西替换，
那将破坏此前的全部结论。因此算法的方向不是偏好，而是"信息从不
流失"这一要求的直接表达。

### 26.2.3 冲突是怎样被发现的

代换会把耦合的等式彼此化简，冲突于是无处藏身。考虑对整数做
解引用的错误程序：`x = 1; output *x;`。相关等式大致是
`τ(x) = int` 与 `τ(x) = ptr(τ(*x))`。第一条先绑定 `τ(x) ↦ int`；
处理第二条时先把 τ(x) 代换成 int，等式变成 `int = ptr(…)`。
这时两侧的**最外层构造子**不同：一侧是 int，一侧是 ptr。任何
代换都改变不了最外层构造子——代换只作用于变量，不作用于构造子，
因此矛盾是绝对的，程序在此处类型错误。

这个小例子展示了合一的全部戏剧元素：绑定让信息流动，代换让隐
藏在变量背后的构造子现形，而构造子对不上就是无解。算法只是把
这三个动作组织成确定的次序。

## 26.3 形式化：类型项、代换与解

直觉需要一个精确的落脚点，否则"解"与"最一般"都无从谈起。
本节给出本章使用的形式化对象，后续算法的每一步都在操作这里
定义的东西。

### 26.3.1 类型项的语法

类型构成一个**项代数**（term algebra）。以第 24 章的类型变量
集合为原子，按下列语法构造类型项：

```
T ::= int | ptr(T) | (T, …, T) -> T | {f1: T, …, fn: T} | α
```

其中 α 取自身份互不相同的类型变量。每个项都可以画成一棵有限
树：int 与变量是叶子；ptr 有一个子树；函数类型有若干参数子树
和一个返回子树；记录类型在每个字段上有一个子树，并在边上标着
字段名。"有限"二字很要紧：本章只承认有限树，这正是
`α = ptr(α)` 无解的根由——它要求一棵沿 ptr 无限展开的树。

注意项里有两类叶子不能混淆：int 是一个**构造子**（它已经确定
自己是什么），α 是一个**空位**（它等待被某个项填充）。算法的
全部工作就是处理空位；一旦空位被填，它就不再是空位。

### 26.3.2 代换及其复合

**代换**（substitution）是从类型变量到类型项的有限映射：
`σ = {α1 ↦ T1, …, αn ↦ Tn}`。把代换作用于项，记作 `σ T`，
含义是把项中出现的每个被映射的变量同时替换成对应项，未被映射
的变量保持不变。

本章实现中的 `Subst`（即 `std::map<int, Tp>`）就是这样一张
映射表；`apply` 实现"作用"这一操作，并且会**反复**代换：
若 `α ↦ β`、`β ↦ int`，则对 α 作用代换应直接得到 int，而不是
停在中间的 β。反复代换之所以正确，是因为绑定表在任何时刻都
不包含循环（26.7 节的 occurs 检查负责这一点），沿映射行走
必然在有限步内停住。

代换可以**复合**：先做 σ、再做 τ 得到新代换 τ∘σ，满足
`(τ∘σ) T = τ (σ T)`。本章算法并不显式构造复合代换，而是把新
绑定直接写进同一张表；由于每次写入后所有读取都沿表现行，
"逐步扩充的一张表"与"反复复合的一族代换"在效果上完全等价。
这是一种实现上的简化，论证时我们仍以代换的语言叙述。

### 26.3.3 等式的解与主解

一叠等式 `E = {T1 = U1, …, Tn = Un}` 的**解**是一个代换 σ，
使得对每一条等式都有 `σ Ti = σ Ui`——代换之后两侧在语法上
完全相同。解可能不存在（int = ptr(α)），存在时也往往不止一个。

关键概念是**主解**（most general unifier，mgu，最一般合一元）：
若 σ 是解，并且对**任意**另一个解 ρ，都存在某个代换 τ 使得
`ρ = τ ∘ σ`，则 σ 是主解。换句话说，主解是"承诺最少"的解：
它只做等式**强迫**它做的识别，其余一切可能的形状一概保留；
任何更"具体"的解（比如把某个剩下的变量再钉成 int）都能由主解
再追加代换得到。

举例：等式 `α = ptr(β)` 的主解是 `{α ↦ ptr(β)}`——注意 β 被
保留为空位。代换 `{α ↦ ptr(int), β ↦ int}` 也是解，但它不是
主解，因为它擅自把 β 钉死了；而它恰好等于在主解之后再做
`{β ↦ int}`，即由主解"复合"出来。主解把"程序允许 β 是任意
类型"这一事实原样保留，这正是类型分析精确性的形式含义。

### 26.3.4 合解在类型系统可靠性中的位置

最后交代合解与第 2 章"可靠"概念的衔接，明确本章在证明什么、
不在证明什么。第 24 章的类型规则是一套关于程序的断言
（"在这些前提下，这个表达式有这个类型"）；第 25 章的约束收集
把规则应用机械化——可以论证：**程序按类型规则可推出类型，当且
仅当收集的等式有解，且解给出的类型与推出的类型一致**。本章
负责这个当且仅当的"求解"一半：合一把等式的解（以及无解）确定
下来。

因此本章对合一自身的正确性要求是双重的：算法声称有解时，给出
的代换必须真是等式的解（**可靠**）；等式只要有解，算法就必须
找到，且找到的是主解（**完备**）。26.13 节给出这两条的论证。
注意本章**不**证明"类型良好的程序不会在运行时出错"——那是
类型规则相对于具体语义的可靠性（soundness），属于把类型规则、
约束收集与本章合解三者接起来之后的总体结论；本章是其中机械
可查、可独立验证的一环。

## 26.4 算法总览：六个情形的判定树

合一的全部逻辑可以画成一棵判定树。给定待处理的等式 `a = b`：

1. 先把两侧沿当前绑定表展开（applySubst）；
2. 两侧都是变量且编号相同 → **恒等**，无事可做；
3. 左侧是变量 → 做 **occurs 检查**后**绑定**；
4. 右侧是变量（左侧不是）→ **交换**两侧，回到情形 3；
5. 两侧都是复合项而构造子不同 → **冲突**，无解；
6. 构造子相同 → 在**分量**上递归合一。

这六种情形穷尽了"两个项"的所有可能：展开后的项要么是变量、
要么是某个构造子打头的复合项；两个项的组合就是"变量/变量、
变量/复合、复合/变量、复合/复合"四类，最后一类再按构造子
同异细分。算法没有第七个出口——这种穷尽性是论证"失败即无
解"的基础。

下面六节逐一讨论每个情形，全部对照 26.16 节给出的 unify.cpp
真实代码。读者会看到，代码的分支顺序与上面的判定树严格一致。
## 26.5 情形一：同一变量恒等

判定树的第一个出口处理 `α = α`。这看似废话，实则必须显式处理：
展开别名之后，两个写法不同的变量可能指回同一个编号，例如绑定
表里已有 `α ↦ β`，等式 `α = β` 展开后两侧都是 β。此时绑定表
已经表达了等式的全部要求，什么都不用做，成功返回即可。

为什么不能把它落到后面的"绑定"分支（比如记一句 `β ↦ β`）？
因为绑定表只该容纳"变量到另一个项"的映射，而 `β ↦ β` 是自我
映射，apply 沿它行走时会原地不动——虽然当前实现靠"代换到同一个
变量"也能停住，但给绑定表引入自指条目会让"表无循环"的不变量
变得含糊。显式识别恒等、什么都不写，是保持绑定表干净的做法。

## 26.6 情形二：变量绑定

### 26.6.1 先展开，再判定

doUnify 的第一件事是把两个操作数都沿当前表展开
（`a = applySubst(s, aa)`）。这一步绝不能省，它决定了后续所有
判断的对象是"变量当前真正代表的项"，而不是它最初的空名。

考虑表中已有 `α ↦ ptr(γ)` 时处理等式 `α = β`：若不展开 α，
算法会草率地写下 `α ↦ β`，与既有绑定 α ↦ ptr(γ) 冲突——同一个
变量在表中出现两次，后写覆盖先写，此前的结论静默丢失。展开后
等式实际是 `ptr(γ) = β`，于是走右侧变量分支、交换，得到
`β ↦ ptr(γ)`：β 与 α 从此共享同一个结构，既有结论完好。展开
把"变量的当前身份"查清，是绑定不丢失信息的前提。

### 26.6.2 为什么绑定后立即返回

occurs 检查通过后，算法写下 `s[α] = b` 并立即返回，不尝试对 b
做任何进一步化简。理由是 b 在进入本分支前已经过展开，它要么是
一个复合项、要么是一个不在表中的变量；无论哪种，等式 `α = b`
的全部信息就是这条绑定本身。对 b 的进一步处理将发生在**后续
等式**里——若别的等式约束了 b 内部的变量，代换自会把信息带
进来。提前深入 b 等于替别的等式做决定，违背"只做被强迫之事"。

绑定后立即返回还有一个技术后果：每处理一条等式，表至多增加
一条映射。这个"一步一至多绑定"的性质让算法的步数可以直接按
等式数与新增绑定数计数，11.13.2 的终止性论证会用到它。

## 26.7 情形三：occurs 检查

### 26.7.1 为什么 α = ptr(α) 没有有限解

绑定变量之前，必须先检查该变量是否**出现在**右侧项中。若出现，
绑定将造成自我嵌套，必须拒绝。这里给出"为什么必然无解"的严格
直觉。

假设存在代换 σ 解开 `α = ptr(α)`，则按解的定义有
`σ α = σ (ptr(α)) = ptr(σ α)`：某个有限类型项 T 满足
`T = ptr(T)`。但任何有限项都有一个确定的**树大小**（节点总数），
而 ptr(T) 的树大小 = T 的树大小 + 1，严格大于 T。一个数不可能
等于自身加一，矛盾。因此不存在有限项 T，等式无解。对更深的
嵌套同理：`α = ptr(ptr(α))` 要求 |T| = |T| + 2，依然矛盾。
occurs 检查拒绝的不是"少见的写法"，而是数学上可证明的无解
情形——这正是它与一般"运行时防御"的区别。

### 26.7.2 occurs 检查的递归实现

containsVar 判定一个变量编号是否出现在项中：项先经展开（项可能
是某个被绑定变量的别名），然后按构造子递归——变量比较编号，
ptr 检查其指向，函数检查全部参数与返回值，记录检查每个字段。
注意检查在**展开之后**进行，因此别名链背后藏着的出现也逃不掉：
若 `β ↦ ptr(α)`，检查 α 是否出现在 β 中时，β 先展开为 ptr(α)，
检查深入后发现 α，正确报告。

为什么检查要覆盖函数的参数、记录的字段等全部分量？因为自我嵌套
可以藏在任意深度：`α = (ptr(α)) -> int` 同样无解（树大小论证
一字不差地成立）。漏检任何一类分量，算法就会在这类等式上写下
循环绑定，此后 apply 沿表行走时永远走不到头——一次漏检换来
一个挂死，而不是一个错误答案，这是 occurs 检查必须完整的原因。

## 26.8 情形四：交换参数

等式是对称的，因此"左侧是复合项、右侧是变量"与"左侧是变量、
右侧是复合项"本质相同。算法不为右侧变量另写一套逻辑，而是
**交换两个参数后递归调用自己**（doUnify(b, a, s)），让交换后的
左侧变量走统一的绑定分支。

这个小设计的意义不只是少写几行代码。变量绑定只有一处实现，
意味着"展开 → occurs → 写入"这套动作只有一份，不可能出现
两侧逻辑日后改得不一致。对称性由"交换"这一个动作显式承担，
代码的结构直接对应等式的数学性质。递归调用仍然终止于其他
情形——交换后左侧必为变量，不会无限交换。

## 26.9 情形五：构造子冲突

两个复合项相遇，先比较最外层构造子：int、ptr、函数类型、记录
类型是四种互不相通的构造方式，构造子不同则等式无解。代码用
`typeid(*a) != typeid(*b)` 做这一比较，不同则抛 TypeError。

为什么构造子不同是**绝对的**矛盾，而不是"也许别的代换能补救"？
回顾代换的作用方式：代换只替换项中的**变量**，从不改变构造子。
因此无论用什么代换作用于 `int`，它永远是 int；作用于 `ptr(T)`，
最外层永远是 ptr。两个最外层不同的项，在任何代换下最外层依然
不同，不可能变成相同的项。构造子冲突因此是"无解"的可靠信号，
算法在此处失败不会冤枉任何有解的等式。

错误信息同时打印两侧的类型（`type mismatch: ptr(…) vs int`），
让矛盾的两端直接可见。类型分析器的诊断义务到此为止：指出哪两种
构造方式在哪个变量上短兵相接；至于源程序哪一行造成的，可以由
变量编号回溯到对应的表达式（第 27 章的输出把这种回溯做成了
正文表格）。

## 26.10 情形六：分量递归

构造子相同还不等于项相同——还要检查内部。算法在两个同构造子
项的**对应分量**上递归，把"大树相等"化整为零成一组"子树相等"。
三种构造子各有分量形状。

### 26.10.1 ptr：一条边

`ptr(T) = ptr(U)` 当且仅当 `T = U`，因此唯一的动作就是对指向
分量递归。递归的对象严格变小（少了一层 ptr），这是终止性论证
中"项尺寸下降"的基本情形之一。

### 26.10.2 函数类型：参数按序、返回值，以及 arity

两个函数类型相等，要求参数个数相同（**arity 检查**）、参数按
位置逐一相等、返回值相等。个数不同立刻失败：缺少或多出的参数
找不到任何对应分量，与构造子冲突同属绝对矛盾——代换改变不了
参数的个数。

参数为什么**按位置**匹配？因为函数类型的参数是有序序列：第 1
个参数将与第 1 个实参对应，位置承载语义，交换两个不同类型的
参数会改变函数类型。这与下面记录字段按名匹配形成对照。全部
参数合一后再合一返回值；次序在此无关正确性（各分量等式共同
可解才可解），但按固定次序处理让诊断具有确定性——总是报告
第一个碰到的矛盾。

### 26.10.3 记录：按字段名匹配，以及为什么不按位置

记录类型的字段是**按名**对应的：`{x: T, y: U}` 与
`{y: U', x: T'}` 相等当且仅当同名字段的类型逐一相等，字段的
书写次序无关。代码因此对左侧每个字段名，在右侧字段中**查找
同名者**；查不到则报 "no field"；查到则在两个字段类型上递归。

这与函数参数按位置匹配的差别不是记法问题，而是两种构造的语义
差别：函数参数的位置决定实参怎样流入，而记录字段是一个以名字
索引的有限映射，`r.x` 靠名字取用、与字段声明的排列无关。若
按位置比较两个字段次序不同的记录，就会把一个正确程序误判为
错误——按名匹配是语言定义的直接要求。字段总数不同同样先报
"record shape"：一个记录多出的字段在另一个里无处可寻。

分量递归全部成功后，等式的信息才算完全并入绑定表。注意递归过程
中表会持续增长（内层等式先被处理），因此当算法最后回到外层时，
分量的内部变量往往已被新绑定确定——整棵判定树天然按"先内层、
后外层"的次序消化信息。
## 26.11 Substitution 的表示与 apply

前面各节以数学语言使用代换，这里看它在程序中的具体形状。
`Subst` 是 `std::map<int, Tp>`：键是类型变量的编号（TyVar 的 id），
值是该变量当前绑定的类型项。一张表在 doUnify 中被反复读取、
逐步扩充，合一全程只有这一份可变状态。

读取统一经 applySubst：拿到一个项，只要它是变量且编号在表中，
就取出绑定项继续；直到它成为未绑定变量或复合项。这个"一路走
到底"的循环实现了数学上的反复代换。两个实现细节值得点出：

- **为什么用循环而不是单次查找**：变量可能被绑到另一个变量
（α ↦ β、β ↦ γ、γ ↦ int），单次查找只给别名、不给答案；绑定
表的无循环不变量保证循环必然终止，而终止时的项就是 α 的当前
所指。
- **为什么不直接在绑定时"就地更新所有引用"**：类型项以
shared_ptr 共享，同一个变量对象可能被很多结构引用，绑定时遍历
全部引用既昂贵又无法穷尽可能后建的结构；"表 + 读取时展开"把
代换推迟到读取点，新绑定对所有旧引用即时生效，无须回填。

这是一种经典的实现取舍：用读取时的一次沿表行走，换取绑定时
的 O(1) 写入与引用方的零维护。代换表只增不改（一个变量一旦
绑定不再被改写——先展开保证了不会对已绑定变量再次写入），
因此表中信息单调累积，论证时可以把每一步的表看作上一步代换的
扩张。

## 26.12 normalize：为什么还需要深度归一

applySubst 只保证把**顶层**变量走到底。考虑合一后的函数符号：
add1 的类型在表中经历过 `(t3) -> t4` 的形状，其中 t3、t4 各自
又被绑成 int。若打印前只对顶层做一次代换，顶层是函数构造子
（不是变量），代换立即停住，打印出 `(t3) -> t4`——一个内部
塞满别名、无法阅读的结果。

normalize（代码中的 rebuild）解决这个问题：它**递归遍历整个
类型结构**，对每个分量先展开、再重建，产出一棵内部不含任何已
绑定变量的新树。规则是：int 与未绑定变量原样返回；ptr 重建其
指向；函数重建所有参数与返回值；记录按字段重建。打印时一律先
normalize，于是：

- `(t3) -> t4`（t3、t4 已绑 int）呈现为 `(int) -> int`；
- `ptr(t5)`（t5 已绑 int）呈现为 `ptr(int)`。

为什么不把 normalize 做进 apply，让代换天然是深度的？两者用途
不同：合一**过程中**只需要顶层展开——判断构造子、查 occurs，
深入未绑定变量的内部没有意义，且每次处理都深度重建会平白制造
大量对象；归一只是**观察**（打印最终类型）时的需要，做一次即可。
把"求解用的浅展开"与"呈现用的深归一"分成两个函数，各按使用
场景取最简单的形式。

还有一层语义上的理由值得说明：normalize 不改变类型信息，只改变
写法。重建出的项与原项在当前代换下"作用后相同"，因此它纯粹是
表示变换，把它放在求解完成之后，不会干扰合一的任何不变量。

## 26.13 正确性论证

本章算法有四条必须兑现的承诺：处理等式时它会**终止**；报告成功
时所给代换真是等式的**解**；等式有解时它**一定找得到**，且找到
的是**主解**；报告失败时等式**确无**解。下面分五小段给出论证
思路，论证全部以 26.3 节的形式化为对象。

### 26.13.1 贯穿全程的不变量

算法的每一步（进入 doUnify 之前与返回之后）维持一个不变量：

> 当前绑定表 s 是**已经处理过的等式**的一个解；且 s 不包含循环
> （沿任何变量的绑定链行走必然终止）。

初始时表为空，空等式集以空代换为解、空表自然无循环，不变量成立。
后续论证只需说明每个情形处理后不变量仍然保持——绑定分支加入的
映射解开了当前等式且不引入循环（occurs 检查负责后者）；恒等、
交换、冲突分支不写表或直接失败；分量递归把当前等式的要求拆成
子等式，按归纳假设子等式的解保持不变量。这是一个按算法步骤的
归纳，也是其余三条论证的共同骨架。

### 26.13.2 终止性

要证明递归的 doUnify 不会无限进行。定义一个严格下降的度量。
每次绑定一个变量 α：

1. 世界上**未被绑定的变量数**减少 1（α 从此被绑，先展开保证
   不会对已绑变量再写）；
2. 分量递归处理的项严格小于外层项（少了一层构造子）。

用字典序度量 `(未绑定变量数, 当前等式两侧项的大小之和)`：绑定
分支使第一项下降；occurs/冲突分支直接结束；交换分支不改变度量
但交换后必走绑定或结束，不会连续交换；分量递归保持第一项而使
第二项严格下降（项每深入一个构造子，节点数减少至少 1）。度量
是自然数上的良序，不能无限下降，因此算法必然终止——要么成功
返回，要么抛出 TypeError。

这里 occurs 检查扮演了不可或缺的角色：没有它，`α = ptr(α)` 会
写入自指环，沿表行走的循环永不终止。拒绝无解等式同时也是终止性
的保障，两件事在这一点上是同一件事。

### 26.13.3 可靠性：成功即真解

假设算法对等式集 E 成功，最终表为 s，要证明 s 是 E 的解。按处理
次序逐式论证，核心是验证**绑定分支**：在表 s' 之下把 α 绑到 b
（b 已展开且 α 不出现于其中），要证明新表解开当前等式 α = b。

按新表作用，α 被替换为 b、两侧作用后相同，等式成立。还要验证
新绑定不破坏**此前已解**的等式：新表只对 α 增加了映射，而此前的
等式经 s' 已化为相同项；唯一可能受影响的情形是此前等式中含有 α
——但 α 在此前处理时若是未绑定变量，此前等式的成立不依赖 α 的
具体值（α 在两侧保持同一空位即可），给空位填上一个不含 α 的项，
两侧依然同步。因此旧等式继续成立，新等式被解开，按归纳 s 是
全部已处理等式的解。

分量递归的可靠性直接由此推出：`ptr(T) = ptr(U)` 的解恰好要求
T = U 可解；函数、记录的分量条件同理——构造子相同的两个项，其
相等在数学上就**定义为**对应分量逐一相等，递归处理的子等式与
原等式等价。

### 26.13.4 完备性与主解性质

可靠性只保证"说有解时有解"，还要证明两个更强的结论。

**完备性**：若等式集 E 存在任何解 ρ，算法不会失败。逐情形考察：
ρ 能解开当前等式，则展开后的两侧在 ρ 下相同。于是：两侧最外层
构造子必然一致（ρ 不改变构造子），算法不会走冲突分支；若等式
一侧是未绑定变量 α、另一侧是项 b，则 ρ 必把 α 映到 ρ b，α 不
可能出现在 b 中（否则 ρ α 是一棵包含自身的有限树，与树大小矛盾），
occurs 检查通过；分量递归遇到的子等式同样被 ρ 解开。按等式结构
归纳，算法的每一步都与某个解的存在相容，故全程不失败。

**主解性质**：设算法给出的表为 s，ρ 是 E 的任意解，要构造 τ 使
`ρ = τ ∘ s`——即 ρ 只是在 s 之上再追加约束。τ 可以直接定义：
对每个 s 未绑定的变量 α，令 τ 把 α 映到 ρ α。验证：对 s 中
α ↦ b 的绑定，(τ∘s) 把 α 映到 τ (s b)；由算法中 b 的构造（只含
此前已处理部分）及 ρ 解开等式这一事实，τ (s b) = ρ b = ρ α。
即两种代换对每个变量给出相同项。直观含义是：算法绑定的每一条
都是等式**逻辑上强迫**的识别（任何解都必须把 α 与 b 等同），而
s 对其余变量一概不动；任何解额外做的钉死，恰好由 τ 承担。
s 因此比 ρ 更一般——这就是 11.3.3 主解定义的兑现。

### 26.13.5 失败即无解

最后论证失败分支的可靠：算法在冲突、arity、字段缺失、occurs 四类
失败上抛出错误时，等式确实无解。逐一对应：

- **构造子冲突 / arity 不符**：11.9、11.10.2 已论证，代换不改变
  最外层构造子与参数个数，两侧在任何代换下都不可能相同；
- **字段缺失**：一个记录要求的字段名在另一个记录中不存在，而
  代换不增删字段，按名对应永远无法完成；
- **occurs**：11.7.1 的树大小论证，有限项不可能等于自身外多包
  一层的项。

四类失败穷尽了算法的所有报错出口，且每一类拒绝的都是可独立证明
的无解等式。结合完备性（有解则不失败），得到干脆的总结论：
**算法成功当且仅当等式有解；成功时给出主解，失败时等式无解。**
合一器作为"解的判定者"的资格由此完整。

### 26.13.6 论证的边界

诚实标明这套论证的适用范围。其一，项是**有限类型树**；若语言
承认递归类型（如 `μ α. ptr(α)`，用显式 μ 折叠/展开规则的无穷
类型），occurs 失败的等式在那种语义下可能有解——本章不承认 μ，
拒绝是正确的。其二，类型项不含等式之外的理论（没有"int 也可以
当 ptr 用"之类的子类型规则）；合一只在自由项代数上工作，混入
子类型需要不同的求解框架。其三，论证针对算法的逻辑，不针对
具体实现的笔误——11.14 的真实运行与第 27 章错误矩阵负责后者。
把边界写明，结论才不是空头支票。
## 26.14 手工演算（一）：arith.tip

理论讲完之后，最好的消化方式是亲手做一遍。本节起的三节，我们把
收集器吐出的等式逐组摊开，模拟合一器的行走，直到推出最终类型。
读者将看到 26.13 节的论证对象不是抽象摆设：每条绑定、每次交换、
每回分量递归，都能在真实等式上找到落点。

### 26.14.1 程序与它提出的问题

arith.tip 有两个函数：无参的 main 与一元 add1。main 计算
`3 + 4 * 2`，拿结果和 10 比较，按分支输出，最后返回 `add1(x)`；
add1 返回 `n + 1`。从程序文本出发，我们对类型分析有三问：

1. 全部表达式是否都被正确识别为 int？
2. 前向调用 `add1(x)`——add1 定义在 main 之后——能否拿到
   add1 的函数类型，并核出参数个数、参数与返回类型？
3. main 的返回值经由 add1 确定，它自己的返回类型会不会被
   正确地"间接"推成 int？

第二问之所以特别，是因为收集器在 main 的函数体里就遇到了 add1
这个名字；若等到走进 add1 定义才登记它的类型，前向调用处将无
物可查。11.14.2 会看到两阶段设计如何处理。

### 26.14.2 阶段 A 先备好的四个变量

收集器在走任何函数体之前，先为每个函数造好函数类型。对 arith：

- main 无参数；它的返回类型变量是 `t1`；局部变量 x 的声明类型
  变量是 `t2`。main 的函数类型为 `() -> t1`。
- add1 的形参 n 取得 `t3`；返回类型变量是 `t4`。add1 的函数
  类型为 `(t3) -> t4`。

注意编号顺序：先返回变量、再 var 声明；下一函数的形参接在
后面。函数名 main、add1 在全局符号表里各指向上面两个函数类型，
于是 main 体内提到 add1 时，收集器立刻能引用 `(t3) -> t4`。
前向调用问题在阶段 A 已经消解——这正是 11.6.1 "先展开、再
判定"思想在收集层面的对应：先把身份查清，后面的每一步才不
落空。

此刻四个变量全是空位，没有任何等式约束它们；它们的答案要等
函数体里的等式来填。

### 26.14.3 赋值语句的等式组

第一条语句是 `x = 3 + 4 * 2`。收集器先处理右值表达式树，为
沿途每个节点发变量并写等式。按生成顺序，与这条语句相关的
等式（去掉完全重复者）是：

- `t6 == int`：字面量 3；
- `t8 == int`：字面量 4；`t9 == int`：字面量 2；
- `t7 == int`：`4 * 2` 的结果；
- `t5 == int`：`3 + 4 * 2` 的结果；
- `t10 == t2`：赋值目标位置上对 x 的使用，类型等于 x 的声明；
- `t10 == t5`：赋值左右类型相同。

`t5` 是外层加法节点自己的变量，在生成子表达式之前就已发出，
因此编号排在 children 之前。可以看到"字面量"规则与"二元
运算操作数为 int"规则产生了重复等式（如 `t6 == int` 出现
两次）；重复无害，合一时第二次走恒等出口，什么都不做。

模拟合一到这一组结束：表中添了 `t6 ↦ int`、`t8 ↦ int`、
`t9 ↦ int`、`t7 ↦ int`、`t5 ↦ int`，以及 `t10 ↦ t2` 与
`t10 ↦ t5`。后两条看似要给同一个 t10 两个绑定——实际过程是：
处理 `t10 == t2` 时 t10 未绑，写入 `t10 ↦ t2`；处理
`t10 == t5` 时先展开 t10 得 t2（未绑空位），右侧 t5 展开为
int，于是走"右侧非变量、左侧变量"——交换后把 t2 绑到 int。
最终效果是 t2、t10 同指 int。x 的声明类型在此首次被确定。

这一步值得停一停：算法没有"改写"t10 的旧绑定，而是沿
`t10 → t2` 找到真正的空位，把新信息加在空位上。11.6.1 节
预言的"展开防止静默覆盖"在此真实发生。

### 26.14.4 条件语句的等式组

第二条语句是 `if (x > 10) output x; else output 0;`。生成的
等式为：

- `t12 == t2`：比较左侧 x 的使用；`t13 == int`：字面量 10；
- `t11 == int`：比较结果（0/1）；
- `t11 == int`：if 条件必须为 int；
- `t14 == t2` 与 `t14 == int`：then 分支 `output x`；
- `t15 == int`：else 分支 `output 0`。

合一时，t12 沿 t2 展开已是 int，与 int 恒等；t14 同理。所有
新变量 t11..t15 全部钉到 int。这里没有新的结构信息，只有
反复核验：比较的两侧、条件、两个 output 的载荷，规则要求
它们是 int，事实也是 int。**正确程序在分析器面前的样子，就是
一路恒等、无冲突**——这正是可靠性与完备性共同追求的"不
冤枉"。

### 26.14.5 前向调用与返回类型

main 的 `return add1(x);` 是这一章的重头戏。相关等式三条：

- `t17 == (t3) -> t4`：被调位置的 add1 使用，类型等于阶段 A
  登记的 add1 函数类型；
- `t18 == t2`：实参 x 的类型；
- `t17 == (t18) -> t16`：被调表达式必须是一个"接受这些实参、
  返回 t16"的函数，t16 是调用表达式自己的变量；
- `t1 == t16`：return 表达式确定 main 的返回类型。

模拟合一第三条等式时，两侧的最外层构造子都是函数箭头，参数
个数都是 1，于是分量递归：参数位置 `t3 = t18`、返回位置
`t4 = t16`。t18 已指向 int，故 t3 绑到 int——add1 的形参
类型被这次调用"用尽信息地"确定；t4 与 t16 此时互为别名。
`t17 == (t3)->t4` 一条则早早走了恒等（两侧本是同一个类型
结构的共享表示）。

注意：合一刻画的 t3=int 并不是因为"调用处传了 int"这一个
事实就完事——add1 自己的函数体还会独立地约束 n。下一小节
就会看到两边的信息一致。若不一致（设想 add1 对 n 做了解
引用），分量递归处就会爆发构造子冲突。**跨函数的类型矛盾，
正是在共享变量 t3 上短兵相接的。**

### 26.14.6 add1 函数体：独立的印证

走到第二个函数，`return n + 1` 产生：

- `t20 == t3`：n 的使用；`t21 == int`：字面量 1；
- `t19 == int`：加法结果；
- `t4 == t19`：return 确定 add1 的返回类型。

t20 沿 t3 展开已是 int，等式恒等；t19 钉 int；`t4 == t19`
把返回变量 t4（以及与它别名的 t16）全部确定为 int。最后
`t1 == t16` 使 main 的返回变量 t1 也是 int。

至此 21 个变量各有所归（无遗漏、无冲突）：

- x、n 的声明（t2、t3）为 int；
- 两个返回变量（t1、t4）为 int；
- 调用节点 t16 为 int；
- **add1 名字的使用处 t17 为 `(int) -> int`**——它是这份
  程序里唯一非 int 的答案。

26.19 节会把这份手工结果与机器输出逐行对照。

### 26.14.7 这一遍演算说明了什么

收个小尾。arith 的求解过程没有发生任何失败，却展示了三个
不寻常的机制：其一，信息沿别名链流动（t10→t2→int），绑定
从不需要改写；其二，前向调用靠阶段 A 的预登记拿到函数类型，
再经函数构造子的分量递归把实参信息传进形参；其三，返回类型
可以隔函数确定（main 的 t1 经 t16、t4、t19 落到 int）。

这三点对应 26.2 节直觉的三个动作——绑定、代换、冲突发现——
而冲突在此备而未发。下面看指针程序，结构信息会复杂得多。
## 26.15 手工演算（二）：ptr.tip

arith 里的类型项只有一层 int，分量递归只是"进去看一眼"。
ptr.tip 把指针的三种构造全用上了：`alloc`、取地址 `&`、解
引用 `*`。类型项将出现两层嵌套，而最有教益的一幕是：一个
变量的类型在被访问的那一刻还只是"ptr(空位)"，空位里填什么
必须等后续等式——合一处理这种"结构带着未知"的方式，是
本节的重点。

### 26.15.1 程序与四条信息流

程序只有 main 一个函数：

> main() {
>   var p, q;
>   p = alloc 5;
>   q = &p;
>   *p = 1;
>   output *p;
>   return **q;
> }

从文本可以预判四条信息流：alloc 让 p 指向一个整数单元；&p
让 q 指向"p 这个变量本身"，而 p 自己持有指针，所以 q 应当
是双重指针；`*p = 1` 与 `output *p` 要求 p 的载荷是 int；
`**q` 两次解引用后同样应得到 int，而它正是 main 的返回值。
分析器必须独立地推出全部四条，并发现它们彼此一致。

阶段 A 给出三个空位：返回变量 `t1`，p 的声明 `t2`，q 的
声明 `t3`。

### 26.15.2 alloc：结构先到，分量后填

前两条等式来自 `p = alloc 5`：

- `t5 == int`：字面量 5；
- `t4 == ptr(t5)`：alloc 的类型规则 `τ(alloc E) = ptr(τ(E))`；
- `t6 == t2`、`t6 == t4`：目标 p 与右值同型。

模拟时，t5 先钉 int，于是 t4 成为 `ptr(int)`；t6 先绑 t2，
再与 t4 合一时沿 t6 找到空位 t2，把 t2 绑到 `ptr(int)`。
p 的声明类型由此确定。

注意绑定发生的**次序与形状**。若等式的顺序反过来——先遇到
`t6 == t4`、此刻 t4 已完整是 ptr(int)，结论相同；若当时
`t4` 还只是 `ptr(t5)`、t5 未定，t2 就会被绑成 `ptr(t5)`——
一个内部仍为空位的结构。合一不要求右侧"完全知情"才肯绑定；
它忠实地把当前已知的结构记下，把未知的分量留作共享变量，等
未来的等式去填。这正是 11.2.1 节"答案沿绑定链走出来"的
精确含义。

### 26.15.3 &p：双重指针的诞生

`q = &p` 的等式组：

- `t7 == ptr(t2)`：`&Id` 的类型是"指向该声明类型"的指针；
- `t8 == t3`、`t8 == t7`。

这里出现了本章最值得品味的嵌套。规则直接把 p 的**声明类型**
t2 放进 ptr 构造子；而 t2 此刻已经是 `ptr(int)`，于是
`t7 = ptr(ptr(int))`，t3、t8 同指此型。q 是双重指针——不是
因为规则"知道"q 将被二次解引用，而是因为 p 恰好持有指针：
`&p` 指的是一个"指针变量"，指向指针的指针，型如
ptr(ptr(int))。

假设文本稍作变动：p 若声明用途是整数（比如程序里写
`p = 5`），同一条规则就会给 q 推出 `ptr(int)`。规则只有
一条，嵌套深度完全由被取地址变量的实际类型决定。这种"构造
子随信息自然堆叠"的性质，来自类型项的递归定义，而不是为
每种深度写的特判——这也是 11.3.1 节坚持用项代数统一刻画的
回报。

### 26.15.4 解引用：从 ptr(T) 里取出 T

`*p = 1` 一组展示反向的信息流：

- `t9 == int`：字面量 1；
- `t11 == t2`：解引用表达式中对 p 的使用；
- `t11 == ptr(t10)`：规则 `τ(*E) = τ` 当 `τ(E) = ptr(τ)`，
  t10 是解引用节点自己的变量；
- `t10 == t9`：赋值把载荷钉为 int。

合一时 t11 展开为 t2、再展开为 `ptr(int)`，与 `ptr(t10)`
构造子相同，分量递归给出 `int = t10`，t10 绑 int。随后
t10 与 t9 恒等。

这一步在做的事，用 11.10.1 的语言说就是：**ptr 是一条单
边，ptr(T)=ptr(U) 当且仅当 T=U**。解引用规则先把"p 是
指针"写成等式，合一再沿这条边走到载荷；载荷的类型既是
"p 所指单元的内容类型"，又被赋值钉成 int。两条独立来路
给出同一个答案，彼此核验。

`output *p` 的一组（`t13 == t2`、`t13 == ptr(t12)`、
`t12 == int`）是完全相同的戏码：t12 再次被推出为 int。
重复的核验不产生新绑定，只走恒等——正确的程序经得起反复
追问。

### 26.15.5 双重解引用与返回值

最后三等式处理 `return **q`：

- `t16 == t3`：内层 q 的使用；
- `t16 == ptr(t15)`：内层 `*q` 的规则，t15 为内层节点变量；
- `t15 == ptr(t14)`：外层 `**q` 的规则，t14 为外层节点；
- `t1 == t14`：返回类型。

模拟：t16 沿 t3 展开已是 `ptr(ptr(int))`，与 `ptr(t15)` 分量
合一，得 `t15 = ptr(int)`；再与 `ptr(t14)` 合一，得
`t14 = int`；t1 随之绑 int。

这是分量递归在一份等式里连续下降两层的真实例子：每遇到
一个 ptr 构造子，算法就向类型树深处走一步，两步之后触底
int。11.13.2 终止性论证所说的"项尺寸严格下降"在此清晰
可见——t16 含 3 个节点，处理后等式落在含 2 个节点的 t15
结构上，再落到 1 个节点的 int。

### 26.15.6 最终绑定表的读法

全部 18 条等式处理完毕，16 个变量无一剩余为空：

- t1（main 返回）int；
- t2（p）`ptr(int)`；t3（q）`ptr(ptr(int))`；
- t4（alloc 节点）`ptr(int)`；t5 int；
- t6、t11、t13、t15 为各中间节点，按其位置为 ptr(int) 或
  ptr(ptr(int))；t7、t8、t16 为双重指针；
- t9、t10、t12、t14 为 int。

机器输出（26.19 节）与此一字不差。这里先点出读这张表的
方法：**看到 `ptr(ptr(int))`，就向程序文本回索"取地址的对象
自己持有指针"；看到一串 `ptr(int)`，就核验它们是否都指向
同一个载荷形状**。类型表不是终点，它是程序事实的压缩，每
一层构造子都回指一段具体语义。

### 26.15.7 若载荷对不上会怎样

借这个例子预告失败。设想把 `*p = 1` 错写成 `p = 1`——直接
给指针赋整数。相关等式变成 `t2 == int`，而 t2 已被 alloc
绑成 `ptr(int)`；合一时先展开，等式实际是
`ptr(int) == int`，构造子冲突，算法在这条等式上抛出
"type mismatch: ptr(...) vs int"。冲突不需要等到运行、不
依赖任何输入，它在等式并置的瞬间就是绝对的。第 27 章的
错误矩阵把这类情形系统地摆出来；26.17 节先现场走两次失败。
## 26.16 手工演算（三）：rec.tip

指针只有一种分量，记录则在同一层构造子里带着**多个以名字
索引**的分量。rec.tip 展示记录构造与字段访问的协作，本节
还要兑现 11.10.3 的承诺：字段按名匹配、与书写次序无关——
这件事在真实等式里的样子，比语言本身更有说服力。

### 26.16.1 程序与待解问题

> main() {
>   var r;
>   r = {x: 1, y: 2};
>   output r.x;
>   return r.y;
> }

三个问题：记录字面量给 r 的形状能否传播到全部使用点？
`r.x`、`r.y` 两次字段访问能否各取到 int？main 的返回类型
经 `r.y` 确定是否为 int？另外，这里藏着一个工程层面的
细节：字段访问发生时，分析器只"看见"被访问的那一个字段，
对其他字段一无所知，它该如何描述 r 应有的形状？

阶段 A：返回变量 `t1`，r 的声明变量 `t2`。

### 26.16.2 记录字面量：形状的诞生

前三等式：

- `t4 == int`：字段 x 的载荷 1；`t5 == int`：字段 y 的载荷 2；
- `t3 == {x: t4, y: t5}`：记录构造逐字段对应；
- `t6 == t2`、`t6 == t3`：赋值同型。

合一刻画 t4、t5 为 int，t3 成为 `{x: int, y: int}`，t6 带
t2 一起绑到这个记录形状。**r 的规范形状从此确立**：两个
字段、名分别为 x 和 y、载荷皆 int。后续所有对 r 的约束都
将与这个规范形状按名对账。

### 26.16.3 字段访问：只看见一个字段时怎样写约束

`output r.x` 产生：

- `t8 == t2`：记录表达式 r 的使用；
- `t8 == {y: t9, x: t7}`：字段访问约束，t7 是 `r.x` 节点
  自己的变量；
- `t7 == int`：output 的值须为 int。

这里解释 11.16.1 留下的问题。收集器在生成这条约束时，并
不知道 r 还有哪个字段；它在第一遍扫描里把**整个程序**出现
过的字段名汇总成表（本例为 x、y），然后为被访问字段 x
放上节点变量 t7，为其余每个名字各发一个新鲜变量占位
（t9 代表"r 的 y 字段，此处不关心但必须存在"）。于是约束
读作：r 必须是一个至少含 x、y 两字段的记录，x 的类型就是
访问结果的类型。

约束文本里字段按 `{y, x}` 排列（汇总顺序先遇到 return 里的
y、后遇到字面量里的 x），只是内部向量的排列；合一按名
对账，与次序无关。模拟：t8 展开为 t2 的规范形状
`{x: int, y: int}`，与 `{y: t9, x: t7}` 同构造子、同字段集；
按名找到 x，合一 `int = t7`；找到 y，合一 `int = t9`。
两个占位变量同时被填满——t9 也成了 int，尽管这条语句根本
没有使用 y。**"不关心"不等于"无约束"**：字段必须存在、
类型必须与 r 的真实形状相容，这是记录按名语义的硬性要求。

### 26.16.4 返回 r.y：再走一次

最后一组：

- `t11 == t2`；
- `t11 == {y: t10, x: t12}`：t10 为 `r.y` 节点变量；
- `t1 == t10`：返回类型。

合一同构：y 位 `int = t10`，x 位 `int = t12`；t1 随 t10
钉为 int。12 个变量全部有解，无冲突。

值得对照的是：两次字段访问生成的临时记录形状里，字段排列
都是 `{y, x}`，而最终打印 r 的类型（t2 归一化后）是
`{x: int, y: int}`——保留的是记录字面量 t3 的字段次序。
原因是 t2 直接绑到了 t3 那个对象，归一化沿 t2 取到的就是
t3 的结构；临时形状只在合一时被读取、不作为最终答案保留。
次序的"无关"由此在实现层面也得到了印证：它从不参与判定，
自然也不出现在结论里。

### 26.16.5 按名与按位：再谈一次根本差别

借这份等式把 11.10.3 的论证压实。设想收集器错误地按位置
比较字段：临时形状 `{y: t9, x: t7}` 的第一位是 y，规范形状
第一位是 x，按位合一将要求"y 字段的 t9 等于 x 字段的 int"
——本例恰好两型皆 int，错误不显；但若把字面量换成
`{x: alloc 1, y: 2}`（x 为 ptr(int)、y 为 int），按位比较
就会把 x 当 y、在 int 与 ptr(int) 之间报冲突，一个完全
正确的程序被误判。**按名不是风格选择，而是避免这类误判的
唯一正确做法**：字段是有限映射，映射的相等由同名键值决定，
键的排列从不承载语义。

反之，函数参数不可按名：实参按书写位置流入形参，位置就是
语义。同一个算法在两种构造子上采取两种对应方式，恰好镜像
语言对"有序序列"与"有名映射"的区分。

### 26.16.6 若字段不存在

若程序写成 `output r.z`，汇总表将包含 z，临时形状变成三个
字段；它与 r 的真实形状 `{x: int, y: int}` 相遇时，z 在其
中找不到同名字段，合一刻画 "no field 'z'" 并失败。若两侧
字段总数不同则更早报 "record shape"。第 27 章把 bad-field
程序的精确诊断纳入了错误矩阵。失败的根据依然是 11.13.5：
代换不增删字段，缺名永远无法弥补。

### 26.16.7 三遍演算的总收获

arith、ptr、rec 三遍走下来，合一器的形象已经完整：它接收
任何形状的类型项，以固定的六情形判定树应对——int 与 int
恒等，变量在展开、occurs 之后绑定，复合项比较构造子，
同构造子则按分量的语义（单边、按位、按名）递归。正确程序
的全部等式被串成一张无循环绑定表；每个变量沿表走到底就
得到答案。接下来补上最后一块经验：失败是什么样子。
## 26.17 失败现场：两次错误的完整推演

前面三遍演算都以成功收场，但合一器真正的资格体现在失败上：
它必须在**无解之处**失败，且报出的信息足以定位矛盾。本节
现场推演两类错误——构造子冲突与 occurs 失败，全部使用第 27 章总装版本的程序（合一逻辑与本章完全相同，仅多了 null
规则，不影响这两例）。

### 26.17.1 构造子冲突：把指针当整数加

程序 binop-ptr.tip：

```
main() {
  var p;
  p = alloc 1;
  output p + 1;
  return 0;
}
```

第一条语句让 p 持有 `alloc 1` 的类型：规则依次给出字面量
int、alloc 节点 `ptr(int)`，再经赋值把 p 的声明绑到这个
指针类型。此刻 p 在绑定表中的所指是一个 ptr 构造子打头的
复合项。

第二条语句是加法 `p + 1`。二元运算规则要求两侧操作数都为
int：右操作数 1 立刻满足；处理左操作数时，收集器把"p 的
使用"变量与 p 的声明相连。合一器沿别名链把该变量展开——
链的尽头不是 int，而是 `ptr(…)`。于是待解等式实际形如
`ptr(…) == int`。

此后的判定没有任何转圜：

1. 两侧都不是未绑定变量，交换无意义；
2. 最外层构造子一侧是 ptr、一侧是 int；
3. 代换只替换变量、从不改变构造子（26.9 节），因此不存在
   任何代换能让两侧相同。

算法在此抛出 TypeError，机器的精确输出是：

```
type error: type mismatch: ptr(t4) vs int
```

错误信息里的 t4 是指针载荷位置上仍保留的变量编号；它提示
矛盾两端的来历：左侧带着指针的内部结构，右侧是整数。分析
到此终止，`--check` 以退出码 3 报告类型错误。注意程序的
语法、作用域都没有任何问题——p 已声明、1 是合法操作数——
唯一的矛盾是"ptr 构造子被用在只接受 int 的位置"。这正是
静态分析的价值：错误不需要一次运行、不需要任何输入数据，
在程序文本并置的瞬间就已注定。

### 26.17.2 同类的另一现场：解引用整数

为说明分量递归也能引爆同类冲突，看 deref-int.tip：

```
main() {
  var x;
  x = 1;
  output *x;
  return 0;
}
```

x 先被钉成 int。解引用规则要求 x 的类型等于 `ptr(τ)`——
待解等式为 `int == ptr(…)`。机器输出：

```
type error: type mismatch: int vs ptr(t5)
```

与 11.17.1 方向相反（这次 int 在左、ptr 在右），性质完全
相同。解引用是一种只能作用于指针的操作：`*E` 的语义是
"沿 E 所指地址取载荷"，一个整数不携带地址，规则上无处
可去。合一器不需要理解"地址"的运行时含义；它只做项的
结构判定，而语言设计者已把"可解引用当且仅当 ptr 型"
编进了约束规则。**分析的正确性 = 规则的语义适当性 + 求解
的逻辑可靠性**，两者分工在此清晰可见。

### 26.17.3 occurs 失败：自己指向自己

第二个大类用 occurs.tip：

```
main() {
  var x;
  x = &x;
  return 0;
}
```

取地址规则给出 `τ(&x) = ptr(声明 x 的类型)`；赋值再要求
x 的声明与右值同型。两条等式合在一起就是：

```
t2 == ptr(t2)
```

（机器编号中 x 的声明为 t2。）合一器走到变量绑定分支，
先执行 occurs 检查：containsVar 沿 ptr 的分量递归，立刻
发现 t2 出现在右侧项内部。检查拒绝绑定，抛出：

```
type error: occurs check: t2 occurs in ptr(t2)
```

11.7.1 节已给出它无解的严格直觉：若有解，则存在有限项 T
满足 T = ptr(T)，而 |ptr(T)| = |T| + 1，一个自然数不等于
自身加一，矛盾。这里把"数学上矛盾"与"算法上拒绝"对上：
算法拒绝的不是某种启发式的"可疑形状"，而是被树大小论证
独立证明的无解等式。若不拒绝呢？写入 `t2 ↦ ptr(t2)` 后，
applySubst 的展开循环沿 t2 → ptr(t2) → t2 永远行走，分析
器挂死——occurs 检查同时是终止性的守护者（11.13.2）。

### 26.17.4 失败信息的诊断义务

两次失败的报错格式相同：`type error: ` 后接矛盾的结构描述。
这个格式有意保持克制：它报告"哪两种类型项、以何种方式
不相容"，不猜测程序员的意图（"你是不是想写……"）。从
变量编号还可以回索到具体表达式——t4、t5 等编号由收集器
在遍历 AST 时按序发出，第 27 章的 `--check` 输出把每个
编号直接对应到源表达式文本，于是"ptr(t4) vs int"中的
t4 可以一键还原成 `alloc 1` 之类的现场。本章只负责把矛盾
本身精确陈述；定位辅助是下一章的事。

### 26.17.5 为什么失败不需要"运行过才知道"

结束本节前点出这与测试的根本差别。要发现 binop-ptr 的
错误，靠测试也可以：编译、运行、观察非法内存访问或错误
结果——但测试只能覆盖被执行的路径，且指针错误的症状往往
远离病因。静态分析问的是另一个问题：**存在任何一种运行
情形使这段构造合法吗？** 对 ptr+int、对 int 的解引用、对
自指取地址，答案由类型项的代数结构直接给出，与输入无关，
因此一次分析覆盖全部运行。这就是 11.3.4 节所说的，类型
规则的可靠性最终兑现为"分析过的程序不会发生某类运行时
错误"；而合一器是这条链路上负责"判定有解/无解"的、
机械可核查的一环。
## 26.18 失败现场（续）：元数与字段形状

11.17 看了构造子冲突与 occurs 两类失败。合一本章实现还有
两个失败出口——函数元数不符、记录形状不符；它们都发生在
分量递归的入口处，逻辑仍然是"代换改变不了计数/字段集"。
本节各走一遍，以穷尽全部失败出口，呼应 11.13.5 的总结论。

### 26.18.1 元数不符：两个实参对一个形参

程序 arity.tip：

```
main() {
  return f(1, 2);
}

f(x) {
  return x;
}
```

阶段 A 为两个函数备好类型：main 返回 t1；f 的形参 x 为 t2、
返回 t3，函数型 `(t2) -> t3`。main 的 return 表达式是调用
`f(1, 2)`：调用节点变量 t4；被调位置 f 的使用 t5 与
`(t2) -> t3` 相连；两个实参 1、2 各有变量 t6、t7（皆钉
int）；调用规则再写一条：

```
t5 == (t6, t7) -> t4
```

处理这一条时，t5 展开为 `(t2) -> t3`：两侧最外层同为函数
构造子，进入分量递归，而分量递归的第一步就是元数检查——
左侧 1 个参数，右侧 2 个。机器报错：

```
type error: arity mismatch: (t2) -> t3 vs (t6, t7) -> t4
```

为什么元数不符是绝对矛盾？函数型 `(…) -> T` 的参数个数是
构造子 arity 的一部分，与箭头本身一样不可由代换改变：
代换只替换括号**内**的变量，不增删括号里的位置。1 个位置
永远无法与 2 个位置逐项对上——第 2 个实参在左侧找不到对应，
且没有任何公理说"多余参数可忽略"。因此失败可靠：该程序
在任何代换下都没有类型解。

语义上这也恰如其分：调用时实参按位置流入形参，多出来的
实参无处可去、缺失的形参无值可取。语言不规定"丢弃多余
实参"之类的惯例，类型检查在调用处拒绝就是对语言定义的
执行。设想一种确实允许变参的语言——它会把函数型本身设计
成带剩余参数的形状（如带尾的参数行），那时合一处理的项
结构不同，检查规则也相应改变；TIP 函数型是定长序列，
拒绝是唯一正确动作。

### 26.18.2 处理顺序与诊断的确定性

注意报错发生在参数**内容**被比较之前：元数检查先于分量
合一。因此即使两个实参的类型都恰好正确（本例正是如此，
皆 int），错误依旧——错误在形状层，不在载荷层。这个顺序
也让诊断确定：总是报告第一个失败的检查，重复运行得到同
一句文本。若先比对载荷、再查元数，诊断会随实参内容漂移，
破坏 11.19.6所述的输出确定性。

### 26.18.3 字段形状不符：访问不存在的字段

程序 bad-field.tip：

```
main() {
  var r;
  r = {x: 1};
  output r.z;
  return 0;
}
```

赋值使 r 的类型绑成 `{x: int}`。程序范围字段汇总表为
x、z（z 来自下面的字段访问）。处理 `output r.z` 时，
字段访问规则写出的临时形状含两个字段：被访问的 z 放
访问节点变量，x 放占位变量。于是待合一的两侧为：

```
{x: int}  与  {x: ?, z: ?}
```

记录分量递归的第一步是字段总数检查：一侧 1 个、一侧 2 个，
机器报：

```
type error: record shape: {x: t4} vs {x: t8, z: t6}
```

（变量编号随遍历次序而定，文本是机器的原样输出。）

论证与元数一例平行：记录类型中的字段名集合是构造子形状的
一部分，代换只替换字段上的类型变量，不增删字段键。r 只有
键 x，而规则要求它同时具备键 z；键不会因任何代换而出现，
等式无解。若字段总数相同但缺某个具体名字（如两侧各两字段、
名字集合不同），检查则深入到按名查找一步，报 "no field"；
两种报错对应同一矛盾的两种发现时机。

### 26.18.4 为什么"先计数、再查名"

记录递归先查字段数，再逐字段按名寻找。这与函数型"先查
元数、再对参数"同构：先在**形状骨架**上排除不可能，再处理
分量内容。多一层早退有两个好处：诊断不依赖载荷类型、保持
稳定；避免把不兼容的结构部分合一后才失败——合一没有回滚
机制（表只增），越晚发现越可能在表中留下虽不影响正确性、
但会让后续诊断混乱的绑定。**把绝对矛盾在递归入口处结清**，
是六情形算法结构上的一条隐含原则。

### 26.18.5 四个失败出口总览

至此，本章实现的全部失败出口都已现场推演：

- 构造子冲突（11.17.1、11.17.2）；
- occurs 失败（11.17.3）；
- 元数不符（11.18.1）；
- 记录形状 / 字段缺失（11.18.3）。

它们无一例外都是"在等式并置之处、由项的代数结构独立证明
的无解"，也无一依赖程序的具体输入。按 11.13.5，这穷尽
性加上完备性，使合一器成为解的判定者：它说有解，主解
可查；它说无解，矛盾可证。下一节回到成功一侧，逐行阅读
机器给出的真实解。
## 26.21 多态的边界：为什么 TIP 停在顶层函数

Robinson 合一给出主解，但"主解"的表达能力受类型项语法
限制。本节讨论一个经典的边界问题：多态。它解释了 TIP
（以及本章实现）为什么只让函数名携带函数型、而不做泛型
实例化，也为理解工业语言的类型推断复杂度提供标尺。

### 26.21.1 单型合一对重复使用的要求

本章合一中，同一个变量的所有出现必须共享**同一个**类型项。
考虑一个看似无害的函数 `id(x){ return x; }`：合一给出
`(t) -> t`，t 是一个空位；主解承诺最少——t 可以是任何类型。
在 TIP 程序里，若只有一处调用 `id(3)`，t 被钉为 int，万事
大吉。但如果程序中既有 `id(3)`、又有 `id(alloc 1)`，两处
调用共享 t，等式同时要求 t=int 与 t=ptr(int)，冲突报错。

这个结果在 TIP 语义下是**正确**的：TIP 函数只有一个类型，
不随调用点变化。而在 ML 系语言里，同一个 id 可以被多处按
不同类型使用——那需要一个额外机制：let-多态。

### 26.21.2 let-多态：泛化与实例化两段动作

let-多态在类型上增加两个操作：

- **泛化**（generalize）：当一个绑定在其类型中含有"不受
  其他约束牵连"的空位时，把这些空位提升为受限量词：
  `id : ∀α. (α) -> α`；
- **实例化**（instantiate）：每个使用点把受限量词的 α 换成
  **该处专属的新鲜变量**：调用 id(3) 处得到 `(t100)->t100`，
  调用 id(alloc 1) 处得到 `(t200)->t200`，两处从此独立。

关键在于：合一算法本身不变，变的是**使用点拿到的项**——
不再是共享的原类型，而是每次复制一份新鲜拷贝。26.13 节的
正确性论证逐字继承，因为每次实例化后的求解仍是普通合一；
新增的论证义务是"泛化只提升真正不受约束的变量"（泛化了
与外部共享的空位会让不同使用点错误地彼此独立）。

### 26.21.3 TIP 为什么止步于此

TIP 没有 let 绑定、函数声明即定义，且 spa 的类型分析有意
保持单型：函数在整个程序中拥有一个类型，指针与控制流分析
得以直接把函数当作单一实体。加入 let-多态会改变分析的
多个下游假设（同一个函数名不再对应单一类型点）。本章实现
忠实于这一选择：函数型经阶段 A 构造一次，所有使用点共享。
这不是实现的简化，而是语言定义的刻画。

### 26.21.4 多态递归：泛化遇到不动点

更微妙的边界是多态递归。若希望递归函数在每一层递归中按
不同类型被调用（按调用深度变换类型），泛化必须发生在
"函数自己的定义还未求解完成"之处——而此时哪些变量真正
自由往往无法确定。ML 的经典结论是：无标注的多态递归
类型推断不可判定（或在限制下方才可行），因此主流语言
要求递归绑定默认单型、或要求显式类型标注来支持多态递归。

这件事与本章主题的联系值得点出：普通（非递归）绑定的类型
是一个**有限项**，合一在有限树上有判定过程；递归绑定要求
类型是自身的不动点，回到了 11.20.5 的循环类型世界。有限
树、显式 μ、受限量词三者的表达力阶梯，在此再次出现。

### 26.21.5 边界意识的用处

知道这些边界不是为了扩充教程范围，而是防止一个常见的
误判：当合一拒绝"同一函数两处不同用法"时，不应怀疑
合一器出了错——在单型语言里那是正确拒绝；反过来，在
支持 let-多态的语言里若编译器仍报错，排查点应在泛化
时机（变量是否真的已脱离约束），而不在合一逻辑。**算法
的行为由类型项语法与绑定策略共同决定**，这是 26.26 节
"先认清约束形状"方法论的又一次应用。

## 26.22 完整绑定表演练：arith 的 31 条等式

26.14 节按语句分组推演了 arith 的求解。本节做一次更细的
演练：按收集器吐出等式的**真实次序**，记录绑定表的逐步
状态，使"不变量"从一句话变成可以逐行核对的过程。为
避免把状态写成代码、本节一律用行内记号叙述。

### 26.22.1 初始状态

阶段 A 之后，表为空（严格说函数类型已构造，但 t1..t4 均
未绑定），待处理等式 31 条。未绑定变量计数为 21。

### 26.22.2 右值树生成的九等式

第一等式 `t6 == int`：t6 是变量、int 是构造子，occurs 平凡
通过，写 `t6 ↦ int`。第二、第三等式分别为 `t8 ↦ int`、
`t9 ↦ int`。第四、第五等式 `t8 == int`、`t9 == int` 展开后
两侧皆 int，走恒等出口，表无变化——这是重复等式的典型
归宿。第六等式 `t7 == int` 写 `t7 ↦ int`（乘法结果）。第七
等式 `t6 == int` 再次恒等。第八等式 `t7 == int` 恒等。第九
等式 `t5 == int` 写 `t5 ↦ int`。

此刻可以核对不变量：已处理的 9 条全部为"某变量=int"，
表显然解开它们；表中无任何变量到变量的链，无循环。

### 26.22.3 目标与右值合流

第十等式 `t10 == t2`：t10 未绑，写 `t10 ↦ t2`——第一次出现
变量到变量的绑定。第十一等式 `t10 == t5`：展开 t10 得 t2，
t5 展开得 int；等式实际为 `t2 == int`，写 `t2 ↦ int`。

这一小步是全表最关键的两跳。它展示了三件事：其一，
t10 的旧绑定没有被改写，信息加在链底；其二，x 的声明
类型 t2 在此被确定，此后所有 t2 的别名（包括第十等式前的
t10）读取时都得到 int；其三，若第十一等式先到、第十等式
后到，处理 `t10==t5` 时会写 `t10 ↦ int`，随后
`t10==t2` 展开为 `int == t2`，交换后 `t2 ↦ int`——终态
相同。算法对等式次序不敏感（在可解范围内），这是主解
唯一性的经验表现。

### 26.22.4 条件组的十等式

第十二等式 `t12 == t2`：展开 t2 为 int，写 `t12 ↦ int`。
第十三 `t13 ↦ int`。第十四、十五（t12/t13 与 int）皆
恒等。第十六 `t11 == int` 写绑定（比较结果）。第十七
`t11 == int` 恒等。第十八 `t14 == t2` → t14 钉 int。第十九
`t14 == int` 恒等。第二十 `t15 == int` 写绑定。第二十一
`t15 == int` 恒等。

至此前 21 等式处理完毕。新确定 t11..t15，全部 int；未绑定
变量从 21 降到 10（t1、t3、t4、t16..t21）。注意计数：每
写一条变量→非变量绑定，计数恰减一；恒等等式不减——与
11.13.2 的度量分析严格对应。

### 26.22.5 调用三等式

第二十二等式 `t17 == (t3) -> t4`：写 `t17 ↦ (t3) -> t4`
（occurs：复合项内只有 t3、t4，无 t17）。第二十三等式
`t18 == t2`：t2 为 int，写 `t18 ↦ int`。第二十四等式
`t17 == (t18) -> t16`：展开左侧为 `(t3) -> t4`；函数构造子
相同、元数相同，分量递归：参数位 `t3 == t18`，t18 展开为
int，写 `t3 ↦ int`；返回位 `t4 == t16`，两侧皆未绑变量，
按左变量规则写 `t4 ↦ t16`。

第二十五等式 `t1 == t16`：展开两侧皆变量，写 `t1 ↦ t16`。
注意此时 t16 仍为空位：main 返回类型的最终答案尚未到手，
它要等 add1 函数体。信息以别名形式暂存，这正是 26.11 节
"代换推迟到读取点"的含义——表不需要在每一刻都给出
int，只需要在读取时能走到答案。

### 26.22.6 add1 组与终态

第二十六等式 `t20 == t3`：t3 已是 int，写 `t20 ↦ int`。
第二十七 `t21 ↦ int`。第二十八、二十九恒等。第三十等式
`t19 == int` 写绑定。第三十一等式分两步：先 `t4 == t19`，
t4 展开沿 `t4 → t16`（空位），t19 为 int，写 `t16 ↦ int`；
至此 t1、t4、t16 三个别名同指 int。

最终未绑定变量计数为 0（全部 21 个变量都有非变量归宿）。
逐变量读取：t1 int、t2 int、……、t17 归一化时递归进入
函数型，参数 t3 重建为 int、返回 t4 经 t16 重建为 int，
得 `(int) -> int`；t18..t21 为 int。与 26.19 节机器输出
逐行一致。

### 26.22.7 演练的方法论收获

这次逐式演练把 26.13 节论证的每个构件都激活了：未绑定
计数的单调下降对应终止性度量；"绑定解开当前式、旧式不
受扰"对应可靠性；链底空位接受后来信息而不覆盖，对应
完备性所依赖的 occurs 前提；t16 长期悬空、最后一填皆准，
对应主解"只做被强迫之事"。读其他程序（包括失败程序）
时，照此列表即可独立推演，不必运行机器——而机器的价值
在于防止推演者自欺。下一节给出本章全部代码。
## 26.23 处理顺序与合流性：为什么按什么顺序都一样

到目前为止，我们的求解器严格按收集器产出的顺序处理等式：
先 pass A 登记的函数与变量形状，再按语句顺序展开的语句等式。
一个自然的疑问随之而来：**换一种顺序处理同一叠等式，结果会
不同吗？** 答案是不会——而且"不会"不是实现上的巧合，是合一
算法本身的数学性质。本节给出这一性质的直观论证，它在教科书中
称为合流性（confluence）或交换性引理。

把合一看作一个重写系统：当前状态是一张绑定表加一叠待解等式，
每应用一次判定树的某个情形，状态就重写一步。Martelli 与
Montanari 在 1982 年正是以这种形式给出合一算法的——他们不规定
"先处理哪条"，只给出六条重写规则，并证明：**无论按什么顺序
应用规则，只要能应用就继续应用，最终要么到达同一个标准形
（在变量改名意义下唯一的合一子），要么无解。** 这个性质的
名字是 Church–Rosser 性质，重写系统文献里也叫合流性。我们的
实现是该无序系统的"最左最下"一种确定化策略：固定从第一条
等式开始、固定先展开哪一侧、固定记录字段按名字查找。确定性
策略是原理的选择，不是原理的约束。

交换性为什么成立？分两类情形看。第一类，两次重写作用在
**不同**的等式上：等式甲的处理只可能绑定甲中出现的变量，
等式乙的处理只可能绑定乙中的变量（构造子分量的递归是对
当前等式两侧的分解，不触及别的等式）。两条重写互不读取
对方的结果，先做哪个后做哪个显然殊途同归。第二类，两次
重写**共享**变量：甲绑定了 α，乙随后展开时沿绑定表走穿了
α——但反过来先处理乙也一样，因为乙在绑定发生前的展开
得到的是 α 本身，绑定时写入的正是"α 对应的当前项"。
更形式化地说，我们的绑定表实现的是"非循环、-idempotent"的
代换：任何时刻，绑定表作用在任何项上的结果，等于此时已
处理等式的合取所要求的最一般信息。已经写入的绑定在后续
处理中不会被改写（11.6.2 的"绑定后立即返回"、11.13.1 的
无循环不变量），这保证了"先来的信息不会被后来的覆盖"。

合流性对教程读者的实际意义有三层。第一，它解释了为什么
第 25 章的收集器可以随便安排等式的生成顺序——生成顺序
不影响可解性，也不影响主解的内容（主解在变量改名意义下
唯一）。第二，它解释了为什么我们敢用"逐条等式顺序处理"
这个最朴素的驱动循环：从无序系统到有序策略，损失的只是
"并行度"之类的效率属性，正确性分毫不损。第三，它给调试
定了规矩：若求解结果依赖等式顺序，**实现必有错**——最常见
的错法就是允许对已绑定变量改绑，等价于引入了一条原系统
没有的、破坏合流性的规则。

顺带把复杂度补完。11.20.4 讲过近线性实现（union-find 加
路径压缩）可以把总代价压到近乎线性；本章实现选择了"每步
完整展开"的朴素形态，最坏是立方级的，但对教学程序规模
绰绰有余。选择朴素的理由不是偷懒：展开式实现（每步显式
重写操作数）与合流性论证一一对应，读者可以逐步手推每个
中间状态；union-find 实现的中间状态是压缩路径的碎片，
恰恰失去了"每一步都能在纸上重演"的可讲性。11.22 的绑定
表演练之所以可能，正是因为我们选了透明换掉了速度。

## 26.24 solution 输出的读法

求解成功后，`tipa --check` 打印一张绑定表。输出以一行
`solution:` 起头，随后每个已确定的类型变量一行，格式为
`tN -> 类型`。这看似平淡的几行，每一处都对应一个明确的设计
决定，值得逐条读透。

**行的范围：哪些变量出现在表里。** 主程序先从约束表收集
全部出现过的变量编号——每条等式两侧的类型树中递归找
TyVar——再把声明类型（函数的 TyFun）中的变量也并入，最后
按编号升序逐个打印。升序来自集合的天然有序性：变量编号
是 fresh 单调计数器（第 24 章），编号序就是创建序，也就是
"约束第一次提到它"的大致顺序。于是 arith.tip 的表从 t1
顺排到 t21，中间无缺号——21 个变量全部有确定类型，没有
一个悬空。若有变量最终仍是 TyVar（normalize 后未变），它
不会打印：这类变量在约束系统中无任何等式约束，任何类型
都满足等式，打印一个 tN 反而误导。

**行的内容：为什么必须 normalize。** 绑定表里存的是
"变量 → 项"，且项的分量中可能嵌着其他变量（26.12 节的主题）。
直接打印 `s[t]` 得到的是 `(t3) -> t4` 这样的半成品：构造子
骨架出来了，分量还是编号。normalize 沿绑定表深度重建，
把每个内部变量都走到底，`(t3) -> t4` 才变成 `(int) -> int`。
对照 arith 输出的第 17 行 `t17 -> (int) -> int`：t17 是 add1
的函数类型变量，pass A 建形时它是 `(α_n) -> α_ret`，求解把
两个分量都钉在 int 上，normalize 再把嵌套展开收拢成一行
可读文本。三个要素——顶层构造子、参数、返回值——在同一行
里齐备，这是手工演算（11.14）与机器输出逐行对照的格式基础。

**缺席的行：哪些信息不在表里。** 表只回答"每个变量是什么"，
不回答"为什么"。理由与箭头的方向一致：绑定表是证据的
压缩形态，证据的展开形态是第 25 章的等式清单——想知道
t17 为什么是 `(int) -> int`，回到 10.16.2 的逐条对接即可。
把"是什么"与"为什么"分置两章、以变量编号为钥匙互相引用，
是本书组织类型篇材料的基本手法：编号稳定（fresh 计数器
只由程序文本决定），两份材料就能精确对位。

**三个程序、三类形状。** arith 的表 21 行里 20 行是 int，
唯一的非平凡行是函数类型——算术程序的类型世界本来就窄，
表的价值在于"确认没有意外"。ptr 的表里 ptr(int) 出现在
t2、t4、t6、t11、t13 五行，ptr(ptr(int)) 出现在 t3、t7、
t8、t16 四行：同一类型被多个变量共享，正是"结构在等式间
传播"的直观证据。rec 的表里 {x: int, y: int} 占了五行
（t2、t3、t6、t8、t11），与 11.16.5 讲的按名匹配互相印证：
记录形状一旦在字面量处诞生，就沿赋值与使用流复制到每个
触碰它的变量上。三张表并排读，约束式分析的"全局一致
赋值"本质一目了然——没有任何一行是孤立的猜测，每一行
都能沿等式清单回索到具体语法位置。
## 26.25 失败的对外形态：TypeError 文本与退出码协议

前几节关心"失败如何被发现"，本节关心"失败如何被报告"。
报告机制的每个细节——异常类型、消息前缀、退出码——都不是
表面功夫，它们共同构成一条从求解器内部直达命令行用户的
可靠通道，也是第 27 章错误矩阵能以文件对账方式自动回归的
前提。

**异常类型：TypeError。** unify.hpp 声明的
`class TypeError : public std::runtime_error` 只有一个构造
函数，接受一条消息。选异常而不是错误码，理由在 11.6.2 已
露出一半：判定树的每个失败出口都发生在递归的最深处，多层
调用栈上的每一层都需要"立即停止并向上传播"的语义；若用
返回码，每一层都要写一遍检查与转发，任何一层忘了检查，
失败就会被吞掉、后续答案全部失真。异常把这个义务交给语言
运行时：抛出点与捕获点之间不许有旁观者。捕获点只有一处
——main 的 `--check` 分支把整叠等式的求解包在一个 try
里，这正是"求解是原子的"这一抽象在错误路径上的投影。

**消息文本：五类失败出口的固定前缀。** unify.cpp 抛出的
消息有五个固定前缀，各自对应判定树的一个出口：
`occurs check:`（变量出现在自身右端）、`type mismatch:`
（两个不同构造子相遇）、`arity mismatch:`（函数类型参数
个数不等）、`record shape:`（两侧字段名集合不一致）、
`no field '...' in ...`（记录字面量缺字段）。前缀之后以
人类可读的类型文本收尾，如 `type mismatch: ptr(t4) vs int`
——注意类型一侧可能是**未归一**的变量编号，这与打印路径
不同：报告失败要紧的是速度与现场（此刻哪些变量还叫 t4），
归一化是求解完成后的观察操作，失败时绑定表可能残缺、
归一反而失真。固定前缀让第 27 章得以按"前缀 + 两侧类型"
核对诊断，而不是对整段自由文本做匹配。

**退出码：3。** 第 24 章为 tipa 立下退出码协议：0 成功、
1 用法或文件错、2 语法错、3 类型错。TypeError 到达 main
后打印 `type error: <消息>` 并返回 3。退出码把"分析结论"
编码为进程可见状态，构建脚本与回归工具不解析文本就能
分诊失败类别；文本则为人类读者保留细节。两条通道并行、
互不替代——这是命令行工具设计里久经考验的分工。

**为什么第 26 章不配错误程序。** 本章的示例目录只有
arith、ptr、rec 三个正确程序，五类失败出口一行代码示例
都没有给——它们全部推迟到第 27 章的错误矩阵。这个安排
有两个理由。其一，第 27 章的 --check 输出格式（按表达式
列出最终类型）与错误路径共用同一条"收集—合一—报告"
流水线，把失败样例放在总装章，恰好能一次覆盖全部出口，
避免本章先放一遍、下章再重复一遍。其二，本章的主题是
算法本身：失败出口在 11.17、11.18 已作过完整的纸上推演，
配上 26.9 节的构造子冲突源码解读，原理的覆盖已经完整；
把机器可核对的错误现场留给下一章，读者在两章之间正好
经历一遍"从推演到对账"的完整闭环。

顺带一提 `no field` 与 `record shape` 的分工。前者在
构造 TyRec 时检查"字面量自带全部字段"（全字段集展开后
不允许缺字段），后者在合一两个 TyRec 时检查"两侧字段名
集合一致"。同一种用户错误（访问不存在的字段）可能从
任一出口冒出，取决于记录形状先在字面量处还是在访问处
成形——第 27 章的 bad-field 例会演示具体走哪条路。两个
出口并存不是冗余：它们守卫的是不同的不变量，合掉任何一个
都会让另一侧的假设失去保障。

---

上一章：[25 约束生成](25-constraints.md) · 下一章：[27 记录与边界](27-records-limits.md)
