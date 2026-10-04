# 第 13 章　三地址码与基本块：优化的通用货币

## 13.1 问题：AST 与优化之间缺一层

第 11 章的 CFG
长在 AST 上，
第 12 章的 LLVM IR
直接从 AST 降落。
两步都合法，
但"优化"这个即将
占据本教程半壁江山
的主角，
需要一个自己的家：

- 它要**机器无关**——
  不被任何目标指令集绑架
  （LLVM IR 太接近
  真实机器了）；
- 它要**粒度合适**——
  比树扁平、
  比机器码抽象，
  一眼看得出
  "谁定义了谁、谁用了谁"；
- 它要**可解释执行**——
  任何变换改了它，
  都能立刻跑一遍
  验证语义没变。

这一层就是**三地址码**
（three-address code，TAC），
编译器历史上
最长寿的中间表示。
本章把它从 AST 里
生出来，
切成**基本块**，
给每个块算好
**next-use** 信息，
再配上一台
**TAC 解释器**——
后者是本教程后半部
所有代码变换的
"具体语义证人"：
第 26 章的复制传播、
第 34 章的局部公共子表达式、
第 35 章的循环优化、
第 36 章的部分冗余消除、
第 43 章的寄存器分配，
每一个都靠它
证明"变换前后行为不变"。

材料取自绿龙第 7 章、
紫龙 6.2 与 8.4 节，
自包含展开。

## 13.2 三地址码：每条指令至多一次运算

TAC 的名字来自它的
铁律：

> 每条指令的右端
> 至多有一个运算符。

`x + y * z` 必须拆成
`t = y * z ; x = x + t`
——没有嵌套、
没有优先级、
没有结合性的藏身处。
一切"程序在算什么"
被摊平成一条条
原子事实。

指令族
（绿龙 §7.6 的清单，
本章示例的实现口径）：

```
x = y              复制（y 可为数字字面量）
x = y op z         二元：+ - * / > ==
t = input          读输入
output x           写输出
return x           返回
if x > y goto L    条件真则跳（比较嵌在跳转里）
if x == y goto L
goto L             无条件跳
```

三件事值得停下来看。

**比较不落地为值**。
`if (a > b) …`
不生成
`t = a > b ; if t goto L`，
而是直接
`if a > b goto L`——
布尔值只活在跳转里，
不占变量名额
（绿龙 §7.8-7.9 的口径）。
当然赋值语境里的
比较（`b = a > 3`）
仍是普通二元指令，
两种待遇各得其所。

**常量也入临时**。
`x = 2 * 3 + 1`
生成
`t1 = 2 ; t2 = 3 ; t3 = t1*t2 ;
t4 = 1 ; t5 = t3+t4 ; x = t5`——
字面量先落入临时，
"每指令一次运算"
才真正不破。
（代价是看起来啰嗦；
第 34 章的 DAG
会把这份啰嗦
连同真正的冗余
一起收走。）

**跳转目标是下标**。
`goto L5` 的 5
是 TAC 数组的下标。
标签不是独立指令，
是**位置的同义词**——
这让"跳转目标必是 leader"
（13.4 节）成为
一眼可见的事实。

### 13.2.1 四元组、三元组与间接三元组

TAC 有三种经典存储形态
（紫龙 6.2.2–6.2.3）：

- **四元组**
  （quadruple）：
  每条指令四个栏位
  （op, 目标, 左元, 右元）。
  本章实现即此——
  `struct Quad { TOp op; string dst, a, b; int target; }`。
  栏位规整、
  临时名显式，
  但结果要占名字；
- **三元组**
  （triple）：
  没有临时名，
  指令的**序号**
  就是它的结果，
  后续指令用
  `(3)` 这样的引用
  当操作数。
  省名字，
  但指令一旦移动
  （优化家常事）
  全部引用要改号；
- **间接三元组**：
  再加一层指针表
  指向三元组，
  移动指令只动指针。

工业 IR 几乎都选
四元组谱系
（LLVM 的 SSA 指令
本质是"每个值一条指令"
的四元组极端形态）：
优化的世界
指令要搬来搬去，
**名字比序号稳定**。
本章从众。

## 13.3 生成：从树到原子事实

`tacGen` 是一台
标准的语法制导翻译机
（第 9 章的学以致用）：
每个表达式节点
求值到"一个地址"
（变量名或临时名），
每个语句节点
发射若干条指令。

`addr`（求值到地址）：

- 字面量 → 新临时 + 复制；
- 变量 → 名字本身；
- 二元 → 递归求两边、
  发射 `t = l op r`；
- input → `t = input`；
- 指针、记录、调用 →
  抛异常注明去向
  （第 37/42 章家族）——
  与第 12 章 irgen
  同一纪律：
  不假装支持。

`stmt`（语句发射）里
最值得看的是两个
控制流模板：

```
if c then S else S'
    if c goto L_then
    goto L_else
L_then:  S
    goto L_end
L_else:  S'
L_end:

while c do S
L_head:  if c goto L_body
    goto L_end
L_body:  S
    goto L_head
L_end:
```

每个模板用三个标签、
跳转目标先占位
（`patches` 清单）
发射完再统一回填
——单遍生成、
二遍补数，
是绿龙 §7.9
"backpatching"思想的
单词级预演
（真正的回填技术
处理布尔表达式的
短路求值，
见 13.9 的注记）。

对照期望输出里
`flow.tip` 的 TAC：
`if` 模板产出第
3–4 行
（`if a > t2 goto L5` +
`goto L8`），
`while` 模板产出
第 10–12 行与
第 16 行的回边
`goto L10`。
模板与产物
一行行对得上。

## 13.4 基本块：leader 三规则

有了平铺的指令流，
"块"就可以定义了。

**基本块**
（basic block）：
一段**只能从第一条进入、
从最后一条离开**
的极大指令序列。
块内没有跳进来，
也没有跳出去——
所以块内指令
要么全部执行，
要么一条不执行；
对块内指令做
任何满足依赖的
重排都不改语义。
这个性质是
第 34 章（块内 DAG）、
第 45 章（指令调度）
的立身之本。

划分算法
（绿龙 §7.9 / 紫 8.4.1）
只需认出**leader**——
每块的第一条：

1. 第一条指令；
2. **跳转的目标**；
3. **紧跟跳转的指令**
   （跳转可能不发生，
    落下来的是新入口）。

leader 之间一切两断，
块的后继看块尾：
`goto` 的后继
只有目标；
条件跳转的后继
是目标**和**落点；
普通结尾的后继
是下一条（若存在）。

期望输出里
`flow.tip` 分成八块：

```
B0 [0,4)   succs: 4 5     if 的正半场（含条件跳转）
B1 [4,5)   succs: 8       goto L8——纯跳板
B2 [5,8)   succs: 10      then 分支体
B3 [8,10)  succs: 10      else 分支体
B4 [10,12) succs: 12 13   while 头（条件跳转）
B5 [12,13) succs: 17      循环出口跳板
B6 [13,17) succs: 10      循环体——注意后继是 10：回边！
B7 [17,21) succs:         收尾
```

B6 的后继是 10
而不是 B7：
**回边**第一次
以裸数据出现。
第 32 章
（支配者与自然循环）
将从这里出发
把"循环"变成
可计算的数学对象。

（succs 打印的是
TAC 下标而非块号，
保持"块是什么"
与"块连到哪"
两层信息的分离——
下标是块的
`begin`，读者一行
即可换算。）

## 13.5 next-use：块内反向一趟

寄存器是稀缺资源。
指令 `t3 = t1 * t2`
执行完，
t1、t2、t3 里
哪些还占着寄存器？
答案由 **next-use**
给出：

> 变量 x 在指令 i 处的
> next-use，
> 是块内 i **之后**
> 下一次读 x 的行号；
> 没有则"无下一使用"。

计算是教科书级的
**反向一趟**
（紫龙 8.4.2）：

```
从块尾向块头扫描：
  对指令 "x = y op z"：
    把符号表里 y、z 的当前信息
      记到这条指令上
    把 x 的当前信息
      也记到这条指令上（定义处）
    置 x 的信息为"死"（重定义）
    置 y、z 的 next-use = 本行
```

两个容易被略过的
口径问题：

1. **定义处也要登记**。
   `t1 = 5` 这一行
   对 t1 的信息
   （下一使用是第 1 行）
   必须记在行上——
   "刚定义的值
   有没有人用"
   正是"结果值不值得
   留在寄存器"的判据。
   本章实现最初
   漏了这条，
   期望输出里
   `t1 = 5 | -`
   看不出 t1 的去向，
   修正后是
   `t1 = 5 | t1 next@1`。
2. **字面量不算变量**。
   操作数以数字开头的
   不进表
   （常量没有
   "下一次使用"的
   寄存器问题）。

next-use 是**局部**信息
（只看块内）：
跨块的信息要等
第 25 章
（活跃变量分析）
的全局版。
局部版先出场
是因为它免费
（一趟扫描）
而够用
（下一章起的
诸多局部变换）。

## 13.6 TAC 解释器：造一位证人

`tacInterp` 是一台
60 行的直线解释器：
`map<string,int>` 存值，
pc 走指令数组，
跳转改 pc，
output 收集进向量。

它的存在意义
不在功能而在**契约**：

- 语义口径与
  LLVM JIT 对齐：
  同一程序、
  同一输入序列，
  两者 outputs
  必须逐元素相等。
  期望输出的
  `interp==jit: yes`
  把这条契约
  写进对账脚本——
  从本章起，
  任何对 TAC 的变换
  （后续章节），
  都要过这一关：
  变换前 interp==jit，
  变换后仍 interp==jit，
  且变换前后
  interp 的 outputs
  彼此相等。
- `steps` 计数器
  记录执行指令数：
  它给"优化有没有
  真的少做事"
  提供量化口径
  （第 34/35/36 章
  会对比
  变换前后的 steps）。

解释器碰上
未初始化变量
读、input 耗尽
都会抛异常
（fail fast，
不留静默垃圾值）；
本章示例程序
不使用 input，
异常路径留给
错误样例去踩。

## 13.7 期望输出解读

**fold.tip 段**。
9 条 TAC 的直线程序：
两个常量各自入临时
（第 0、1 行）、
乘（第 2 行）、
1 再入临时（第 3 行）、
加（第 4 行）、
存 x、输出、
0 入临时、返回。
单块 B0 [0,9)、无后继。
next-use 表里
每行至多两三个条目：
`t1 = 2 | t1 next@1`——
t1 出生即被安排；
`t3 = t1 * t2 | t1 next@- | t2 next@- | t3 next@4`
——t1、t2 用完即死
（正是 13.5 的判据），
t3 还有第 4 行的约会。
interp 输出 7、
9 步执行；
JIT 输出 7；
对账 yes。

**flow.tip 段**。
21 条 TAC、八块
（13.4 节已逐块读）。
next-use 只在
块内有意义——
跨块的 a 在 B0 内
`next@3` 之后
没有条目，
但它在 B6 里
被 `t7 = a - t6`
使用：
这正是"局部信息
看不见块外"的
直观展示，
也是全局活跃分析
（第 25 章）
的动机预告。
interp 输出 1
（b=1、a 循环到 0）、
44 步；
JIT 同输出；
对账 yes。

## 13.8 两种 IR 的对照

同一个 flow.tip，
第 12 章的
`--emit-ir` 吐出
LLVM IR，
本章吐出 TAC。
并排看三处差异：

1. **临时值**：
   TAC 用 t1、t2 计数命名；
   LLVM IR 里
   每条指令
   `%3 = mul i32 %1, %2`
   的 `%3`
   就是"指令即值"
   ——SSA 的影子
   （第 33 章）；
2. **变量**：
   TAC 的 a 在
   循环里被反复
   重定义
   （第 1、15 行）；
   LLVM IR 里
   a 是一个 alloca 槽，
   load/store 访问
   ——`mem2reg`
   （第 33 章对照）
   会把它变成 φ；
3. **控制流**：
   TAC 的标签是下标、
   块是隐式的
   （要靠 leader 划）；
   LLVM IR 的块
   是一等公民，
   每块有名字、
   terminator 收尾。

三种差异其实是
同一句话：
TAC 是
"给分析用的 IR"，
LLVM IR 是
"给真实编译器用的 IR"；
前者把结构降到
最少，
后者把结构备到最足。
本教程让它们
在 `interp==jit`
的契约下共生。

## 13.9 工程注意点

- **临时命名的稳定性**。
  计数器顺序分配，
  同一程序
  生成序列确定——
  这是期望输出
  可对账的前提。
  真实编译器
  会重用临时名
  （减少名字压力），
  但那要在
  生命周期分析
  之后（第 43 章）。
- **布尔短路**。
  TIP 的比较
  只出现在
  if/while 条件里，
  没有 `&&`/`||`，
  本章"比较嵌进跳转"
  的简化不损失什么。
  有短路运算的
  语言要生成
  翻转嵌套的跳转链，
  那时回填
  （backpatching）
  才真正登场
  （紫龙 6.7）。
- **leader 规则的第三条**。
  漏掉"跳转的下一指令
  也是 leader"
  会把顺序落入的
  代码并进前块，
  块的"单出口"性质
  即被破坏——
  下一章起的
  块内重排将
  静默改变语义。
  三条规则
  各自拦一种
  入口方式，
  少一条都不行。
- **succs 存下标还是块号**。
  本章存 TAC 下标，
  打印与换算
  保持"位置"本位；
  若后续章节
  频繁做块级算法，
  可再包一层
  块号视图
  （第 32 章会这么做）。
- **解释器的分工**。
  它不是给用户跑程序的
  （那是 JIT 的事），
  是给变换对账的。
  所以它追求
  简单直白
  （每步一条指令、
  计数器累加），
  而非性能——
  证人的美德是
  忠实，不是快。

## 13.10 本章配套文件

### 13.10.1 文法 TIP.g4

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

### 13.10.2 新件之一：tacgen.hpp 与 tacgen.cpp

TAC 指令族、
show 打印、
语法制导的降落器
（含 if/while 模板与
标签回填）。

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

### 13.10.3 新件之二：tacblocks.hpp 与 tacblocks.cpp

leader 三规则、
块划分与后继表、
next-use 反向一趟。

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

### 13.10.4 新件之三：tacinterp.hpp 与 tacinterp.cpp

语义证人：
值表 + pc 循环 +
outputs/steps。

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

### 13.10.5 驱动 main.cpp

解析 → TAC → 块 →
next-use → interp →
JIT → 对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 13 章驱动：--check FILE
//   TAC 全文 → 基本块划分 → 每块 next-use 表 →
//   TAC 解释器执行 → LLVM JIT 执行 → interp==jit 对账。
#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"

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

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty())
        throw std::runtime_error("名字解析错误: " + result.bindings.errors.front().text);
    return result;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    Parsed p = parseFile(argv[2]);
    const tip::FunDecl &fn = *p.ast->funs.front();
    if (p.ast->funs.size() > 1 || fn.name != "main") {
        std::cerr << "本章示例只处理单 main 函数\n";
        return 2;
    }

    std::vector<tip::Quad> code = tip::tacGen(fn);

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';

    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    std::cout << "== blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << " " << s;
        std::cout << '\n';
    }

    std::cout << "== next-use ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << ":\n";
        auto nu = tip::nextUse(code, b);
        for (int i = b.begin; i < b.end; ++i) {
            std::cout << "    " << i << ": " << tip::show(code[i]);
            bool any = false;
            for (const auto &kv : nu) {
                if (kv.first.first != i) continue;
                std::cout << "  | " << kv.first.second
                          << " next@" << (kv.second < 0 ? std::string("-") : std::to_string(kv.second));
                any = true;
            }
            if (!any) std::cout << "  | -";
            std::cout << '\n';
        }
    }

    // ---------- 解释器 vs JIT ----------
    std::cout << "== interp ==\n";
    tip::TacRun run = tip::tacInterp(code, {});
    std::cout << "  outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << " ; steps = " << run.steps << '\n';

    std::cout << "== jit ==\n";
    tip::IRGen gen;
    gen.gen(*p.ast, p.bindings);
    if (!gen.verify()) {
        std::cerr << "generated module failed verification\n";
        return 1;
    }
    std::vector<int> jout = tip::runJit(std::move(gen), {});
    std::cout << "  outputs:";
    for (int v : jout) std::cout << ' ' << v;
    std::cout << '\n';

    std::cout << "== 对账 ==\n";
    std::cout << "  interp==jit: " << (run.outputs == jout ? "yes" : "NO") << '\n';
    return run.outputs == jout ? 0 : 1;
}
```

### 13.10.6 前端基础件：ast 与 ast_build

第 8 章原样
（本示例只消费 AST，
不建 CFG）。

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

### 13.10.7 前端基础件：symtab

第 10 章原样。

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

### 13.10.8 执行台：irgen 与 jitrun

第 12 章原样；
JIT 为对账线服务。

```cpp
// file: src/irgen.hpp
// LLVM IR 生成：把 AST 翻译成 LLVM Module。
// 本章只覆盖整数核心：算术、比较、input/output、if/while、直接函数调用；
// 指针、记录、间接调用在第 41 章以后扩展，遇到时直接报错。
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
            throw std::runtime_error("ch12: 间接调用留待第 41 章");
        const Symbol *s = bindings->uses.at(nameUse);
        if (s->kind != Symbol::Fun)
            throw std::runtime_error("ch12: 间接调用留待第 41 章");
        auto *callee = mod->getFunction(emitName(s->name));
        std::vector<Value *> args;
        for (const auto &a : x->args) args.push_back(expr(a.get()));
        return b->CreateCall(callee, args);
    }

    throw std::runtime_error("ch12: 指针与记录构造留待第 41 章");
}

void IRGen::stmt(const Stmt *s) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        const auto *target = dynamic_cast<const VarRef *>(x->target.get());
        if (!target)
            throw std::runtime_error("ch12: 经指针/字段写入留待第 41 章");
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

### 13.10.9 程序与期望输出

```text
// file: programs/flow.tip
main() {
  var a, b;
  a = 5;
  if (a > 3) b = 1; else b = 0;
  while (a > 0) a = a - 1;
  output b + a;
  return 0;
}
```

```text
// file: programs/fold.tip
main() {
  var x;
  x = 2 * 3 + 1;
  output x;
  return 0;
}
```

```text
; expected: expected/output.txt
== flow.tip ==
== TAC ==
  0: t1 = 5
  1: a = t1
  2: t2 = 3
  3: if a > t2 goto L5
  4: goto L8
  5: t3 = 1
  6: b = t3
  7: goto L10
  8: t4 = 0
  9: b = t4
  10: t5 = 0
  11: if a > t5 goto L13
  12: goto L17
  13: t6 = 1
  14: t7 = a - t6
  15: a = t7
  16: goto L10
  17: t8 = b + a
  18: output t8
  19: t9 = 0
  20: return t9
== blocks ==
  B0 [0,4) succs: 4 5
  B1 [4,5) succs: 8
  B2 [5,8) succs: 10
  B3 [8,10) succs: 10
  B4 [10,12) succs: 12 13
  B5 [12,13) succs: 17
  B6 [13,17) succs: 10
  B7 [17,21) succs:
== next-use ==
  B0:
    0: t1 = 5  | t1 next@1
    1: a = t1  | a next@3  | t1 next@-
    2: t2 = 3  | t2 next@3
    3: if a > t2 goto L5  | a next@-  | t2 next@-
  B1:
    4: goto L8  | -
  B2:
    5: t3 = 1  | t3 next@6
    6: b = t3  | b next@-  | t3 next@-
    7: goto L10  | -
  B3:
    8: t4 = 0  | t4 next@9
    9: b = t4  | b next@-  | t4 next@-
  B4:
    10: t5 = 0  | t5 next@11
    11: if a > t5 goto L13  | a next@-  | t5 next@-
  B5:
    12: goto L17  | -
  B6:
    13: t6 = 1  | t6 next@14
    14: t7 = a - t6  | a next@-  | t6 next@-  | t7 next@15
    15: a = t7  | a next@-  | t7 next@-
    16: goto L10  | -
  B7:
    17: t8 = b + a  | a next@-  | b next@-  | t8 next@18
    18: output t8  | t8 next@-
    19: t9 = 0  | t9 next@20
    20: return t9  | t9 next@-
== interp ==
  outputs: 1 ; steps = 44
== jit ==
  outputs: 1
== 对账 ==
  interp==jit: yes
== fold.tip ==
== TAC ==
  0: t1 = 2
  1: t2 = 3
  2: t3 = t1 * t2
  3: t4 = 1
  4: t5 = t3 + t4
  5: x = t5
  6: output x
  7: t6 = 0
  8: return t6
== blocks ==
  B0 [0,9) succs:
== next-use ==
  B0:
    0: t1 = 2  | t1 next@2
    1: t2 = 3  | t2 next@2
    2: t3 = t1 * t2  | t1 next@-  | t2 next@-  | t3 next@4
    3: t4 = 1  | t4 next@4
    4: t5 = t3 + t4  | t3 next@-  | t4 next@-  | t5 next@5
    5: x = t5  | t5 next@-  | x next@6
    6: output x  | x next@-
    7: t6 = 0  | t6 next@8
    8: return t6  | t6 next@-
== interp ==
  outputs: 7 ; steps = 9
== jit ==
  outputs: 7
== 对账 ==
  interp==jit: yes
```

## 13.11 小结与练习

本章为优化修好了
全部跑道：

- TAC 把程序摊平成
  "每条一次运算"的
  原子事实，
  四元组形态、
  比较嵌跳转、
  常量入临时；
- leader 三规则
  切出基本块——
  "全执行或全不执行"
  的单位；
- next-use 反向一趟
  给出局部的
  "值还有没有下家"；
- TAC 解释器
  与 LLVM JIT
  立下 outputs 相等的
  语义契约，
  从此一切变换
  皆有证人。

数据流分析的
经典四大分析
（第 25 章两个、
第 26 章两个）
都将在这层 TAC 上
展开；
在那之前，
先在下一章
进入运行时的世界——
栈、帧与活动记录。

练习：

1. 手工对 fold.tip
   跑 leader 三规则，
   复现单块结论；
   再对 flow.tip
   复现八块与
   各块 succs。
2. 给 TAC 加一条
   一元负指令
   `x = - y`
   （TOp::Neg），
   扩展 tacgen/interp/
   show 三处与
   next-use 的
   reads 集合，
   重新生成期望输出。
3. 在 flow.tip 的
   while 体里加一条
   `output a`，
   观察 steps
   增加多少
   （答：恰好循环次数），
   并解释为什么
   interp 的 steps
   恰好是
   "执行历史长度"。
4. 把 succs 的打印
   改成块号
   （需要在 partitionBlocks
   里维护下标→块号映射），
   重生成期望输出，
   比较两种可读性。
5. 实现三元组版本
   的 TAC 生成器
   （结果用 (i) 引用），
   对 fold.tip
   产出同语义的
   三元组序列，
   并列举两处
   让你立刻明白
   "为什么优化器
   偏爱四元组"
   的体验。
