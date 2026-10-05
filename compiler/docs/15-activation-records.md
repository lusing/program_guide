# 第 15 章　栈与活动记录：函数调用的运行时之家

## 15.1 问题：函数调用需要一个“家”

到本章为止，
程序的执行台
是 LLVM JIT
（第 12 章）和
两台 TAC 解释器
（第 13 章起）。
它们都把"函数调用"
当作现成的东西。
但调用本身
需要存储：

- 实参从调用者
  传到被调者，
  放在哪？
- 被调者的局部变量
  与别人同名也不打架，
  靠什么隔离？
- 递归第五层的 fact
  与第二层的 fact
  同时"活着"，
  各自的 n 存在哪？
- 算完之后
  回到哪里继续？

这些问题的标准答案
是**运行时存储组织**
（绿龙第 10 章、
紫龙第 7 章）：
数据按生命周期
分三类安置——

- **静态存储**：
  编译期就定地址
  （全局变量、字面量池）；
- **栈**：
  与函数活动同生共死，
  调用即压、返回即弹
  ——本章主角；
- **堆**：
  生命周期由数据自身决定
  （alloc 出来的记录），
  第 16 章专门讨论
  它死后的清运。

本章在 TAC 之上
加两条指令
（param、call），
再造一台
**显式活动记录的栈机器**，
让"调用"这件事
从 JIT 的黑盒里
走出来，
变成看得见、
打得印的帧栈。

## 15.2 活动树与活动记录

**活动**
（activation）
是函数的一次执行。
main 调 fact、
fact 递归调 fact：
每次调用产生一个活动。
所有活动按
"谁调用谁"组织成**活动树**——
它是调用树在
**某一次具体执行中**
的投影：
兄弟活动**绝不重叠**
（一个返回了
另一个才开始），
父子活动**嵌套**
（被调者的整段生命期
落在调用者之内）。

这条"不重叠"性质
就是栈的许可证：
给每个活动一块
**后进先出**的存储，
活动开始时压栈、
结束时弹栈，
任意时刻栈里的活动
恰好是活动树上
从根到当前结点的
一条路径。
递归不过是
活动树上同名结点
排成一列，
栈里同时存着
同函数的不同活动——
第二层 fact 的 n=4
与第五层的 n=1
各住各的帧，
互不认识。

每个活动的那块存储
叫**活动记录**
（activation record，
也叫帧 frame）。
本章 VM 的布局
（绿龙 §10.1 的教学版）：

```
[ 返回地址 | 控制链 | 实参槽… | 局部变量槽… | 临时槽… ]
```

- **返回地址**：
  本活动结束后
  回到调用者 TAC 的
  哪一条；
- **控制链**
  （control link）：
  调用者帧的下标——
  调试用回溯、
  深度统计、
  （嵌套语言里的）
  非局部访问都靠它；
- **实参槽**：
  调用序列放实参的位置，
  名字就是形参名；
- **局部变量槽**与**临时槽**：
  声明的 var 与
  TAC 生成的 t 系临时，
  各占一槽。

一个细节：
帧布局在**执行前
完全确定**
（形参+局部来自声明，
临时来自对 TAC 的
一次预扫描，
按首次出现序编号）。
"每个变量住哪个槽"
是编译期知识——
这正是真实编译器
把变量编译成
`fp+8`、`fp+12`
这样的偏移的底气。
第 48 章的寄存器分配
做的事本质上是
"把最常用的槽
从帧里搬进寄存器"。

## 15.3 调用序列与返回序列

紫龙 §7.2.3 把调用拆成
两段**序列**
（sequence）——
一段在调用者、
一段在被调者，
分工明确：

**调用序列**（caller 侧）：

1. 求值实参
   （我们的 TAC：
   每个实参一条
   `param x`，
   左到右压入
   待传区）；
2. 存返回地址、
   建立控制链、
   把实参写进新帧的
   形参槽；
3. 跳进被调者代码
   （我们的 TAC：
   `t = call f k`，
   k 个实参、
   返回值将写入 t）。

**返回序列**（callee 侧）：

1. 把返回值放进
   约定位置
   （我们：
   `return x` 的 x）；
2. 弹帧、
   恢复调用者的
   代码指针与 pc；
3. 返回值写进
   调用点 call 指令的
   目的槽。

VM 里这两段
就是 `pushFrame`
与 `Ret` 分支的
十几行代码；
对照 calls.tip
的 TAC 与轨迹：

```
fun main:
  0: t1 = 2
  1: param t1        ← 实参 1 就位
  2: t2 = 3
  3: param t2        ← 实参 2 就位
  4: t3 = call add 2 ← 调用序列的发射扳机
```

执行到第 4 条时
VM 的轨迹：

```
push add depth=2 ret=5 slots=[a:2 b:3]
```

ret=5——
返回地址就是
call 的下一条；
slots 里 a:2 b:3——
两个 param
按序落进形参槽。
`add` 的 `return t1`
触发返回序列：

```
pop  add depth=2 ret->5 value=5
```

value=5 回到 main，
写进 t3。
一去一回，
param/call/return
三个语言构件
与两段序列
严丝合缝。

**返回值经 call.dst 交接**
是本实现的约定；
真实机器用
寄存器（rax/x0）或
栈顶槽传值，
思路相同：
约定一个位置，
两侧都认识它。
"约定"这个词的
正式名字叫
**调用约定**
（calling convention），
它是一切
跨函数世界
（第 40 章起）的地基。

## 15.4 TIP 的扁平世界，与它没有的访问链

TIP 的文法是
`program : function+`——
函数平铺、
不许嵌套声明。
于是 TIP 的帧里
不需要**访问链**
（access link）：
任何变量
要么在本帧，
要么不存在。

但"嵌套过程语言"
（Pascal 谱系）里，
内层函数要读
外层函数的变量，
帧与帧怎么打通？
把紫龙 §7.3 的
两套方案自包含讲清：

**访问链**：
每帧加一格，
指向**定义上**
包围自己的那个
函数的**最近活动**的帧。
读非局部变量 x：
沿访问链爬
（x 在第 k 层外
就爬 k 跳），
到帧后按偏移取 x。
爬链的代价
与嵌套深度成正比。

**display**：
一个全局数组
d[0..最大深度]，
d[i] 恒指向
当前最内层的
"第 i 层函数"活动帧。
读第 k 层的变量：
一跳到 d[k]，
再按偏移取——
常数跳。
代价是
每次调用/返回
要维护 display
（进出内层函数时
保存/恢复被遮蔽项）。

两案的取舍是
"访问慢 vs 维护贵"
的经典对偶。
现代语言主流
干脆不给嵌套过程：
C 家族全扁平，
需要"带走环境"时
用**闭包**——
把访问链
（连同它指到的帧）
装箱到堆上，
函数值走到哪
环境跟到哪。
TIP 的闭包
（第 3 章提过、
第 44 章的 0-CFA
要认真对待）
正是这个思路，
而它的堆侧后勤
就是下一章的
垃圾回收。

## 15.5 期望输出解读

**calls.tip 段**。
TAC 区展示
两个函数的
完整降落：
add 两行
（求和、返回）、
main 十四行
（两组
param/param/call）。
帧布局区两行：

```
add: [ret | ctrl | a b ]  共 2 槽
main: [ret | ctrl | x y t1..t6 ]  共 8 槽
```

（打印只列形参与
局部变量，
临时槽在 VM
内部登记——
布局的完整形态
见 push 行。）
VM 轨迹五进五出：
两次 add
（depth=2）+
main 自身；
每次 push 行的
slots 完整展示
"这一帧出生时
都带了什么"。
vm==interp: yes。

**fact.tip 段**。
递归的教材现场：

```
push main  depth=1 ret=-1 slots=[x:0 t1..t3]
push fact  depth=2 ret=3  slots=[n:4 r:0 t1..t6]
push fact  depth=3 ret=7  slots=[n:3 ...]
push fact  depth=4 ret=7  slots=[n:2 ...]
push fact  depth=5 ret=7  slots=[n:1 ...]
pop  fact  depth=5 ret->7 value=1
pop  fact  depth=4 ret->7 value=2
pop  fact  depth=3 ret->7 value=6
pop  fact  depth=2 ret->3 value=24
pop  main  depth=1 ret->-1 value=0
```

读三个细节：

1. depth=3/4/5 的
   ret=7 而 depth=2 的
   ret=3：
   递归调用点
   （fact 体内的 call）
   与初等调用点
   （main 里的 call）
   是 TAC 里
   两个不同的位置——
   返回地址把
   "从哪来回哪去"
   写得明明白白；
2. n 逐层 4→3→2→1，
   五个 fact 活动
   同帧异主；
3. value 逐层
   1→2→6→24：
   返回序列把
   每层的乘积
   交还给上一层，
   弹出顺序
   与压入严格相反
   ——栈的纪律。

interp 侧
steps = 43，
与 VM 输出
逐元素相等，
对账 yes。

## 15.6 工程注意点

- **哈希帧 vs 槽帧**。
  本章同时给了
  两台执行器：
  `TacInterp`
  用 map<string,int>
  （名字即地址）、
  `Vm` 用编号槽
  （布局先行）。
  前者写起来快，
  后者才是
  "活动记录"的
  忠实模型。
  两者 outputs
  对账（vm==interp）
  是一次微型的
  "两套实现互证"——
  语义契约
  （第 13 章
  interp==jit 的
  家族成员）。
- **param 的顺序**。
  实参求值顺序
  （左到右）与
  写槽顺序
  （按 param 出现序）
  在此绑定为约定。
  C/C++ 把
  实参求值顺序
  留给实现，
  是著名的
  未定义行为
  温床；
  把它写进契约
  永远是好主意。
- **真实的帧还有更多格**：
  保存的寄存器、
  溢出区、
  对齐填充、
  变长数组区。
  本章教学版
  只留了
  语义必需的
  ret/ctrl/数据三件。
  读真编译器的
  `-fstack-protector`
  或栈回溯库时，
  记得核心结构
  就是这三件的
  工程化加宽。
- **栈溢出**。
  无界递归
  压垮栈帧
  是真实世界的
  常见崩溃；
  教学 VM
  用 vector
  不会"溢"，
  但第 22 章的
  区间分析
  会以不动点
  的方式
  "预演"循环次数，
  那是分析视角
  对同一问题的
  另一种介入。
- **谁清扫弹出的帧****
  栈帧弹掉即弃，
  但帧里如果有
  指向堆的指针，
  堆上的记录
  就成了
  "没人认领的家当"——
  下一章
  （垃圾回收）
  从这里接棒。

## 15.7 本章配套文件

### 15.7.1 文法 TIP.g4

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

### 15.7.2 新件之一：vm.hpp 与 vm.cpp

显式活动记录的
栈机器：
帧布局、
调用/返回序列、
帧轨迹。

```cpp
// file: src/vm.hpp
// file: src/vm.hpp
// 第 15 章配套：显式活动记录的 TAC 栈机器。
// 每个帧 = [返回地址 | 控制链 | 实参槽… | 局部变量槽…]（绿龙 §10.1 的布局）。
// TIP 的函数是平铺的（文法无嵌套声明），所以没有访问链——
// 嵌套语言要补的 access link / display 见正文 14.5 的自包含讨论。
#ifndef TIP_VM_HPP
#define TIP_VM_HPP

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "tacgen.hpp"

namespace tip {

struct Frame {
    std::string func;
    int retAddr = -1;              // 返回地址（TAC 下标；最外层为 -1）
    int controlLink = -1;          // 控制链：调用者的帧下标
    std::vector<std::string> slotName;
    std::vector<int> slot;
    int depth = 0;
};

struct VmRun {
    std::vector<int> outputs;
    std::vector<std::string> trace;   // 帧轨迹（进入对账契约）
};

class Vm {
public:
    // funcs: 函数名 → (声明, TAC)
    void define(const FunDecl &fn, std::vector<Quad> code);
    VmRun run(const std::vector<int> &inputs);

private:
    // 函数名 → (声明, TAC, 临时槽序)
    std::map<std::string,
             std::tuple<const FunDecl *, std::vector<Quad>, std::vector<std::string>>> funcs_;
    std::vector<Frame> stack_;
    std::vector<int> outputs_;
    std::vector<std::string> trace_;
    std::vector<int> inputs_;
    size_t nextInput_ = 0;

    int &slot(Frame &f, const std::string &name);
    int read(Frame &f, const std::string &a);
};

}  // namespace tip

#endif  // TIP_VM_HPP
```

```cpp
// file: src/vm.cpp
// file: src/vm.cpp
// 第 15 章配套：栈机器实现。
// 调用序列与返回序列（紫龙 §7.2.3）在 pushFrame/popFrame 两段里分步落地。
#include "vm.hpp"

#include <cctype>
#include <cstdlib>
#include <sstream>
#include <stdexcept>

namespace tip {

namespace {
bool isNum(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
}  // namespace

void Vm::define(const FunDecl &fn, std::vector<Quad> code) {
    // 帧布局 = [ret | ctrl | 形参 | 局部变量 | 临时槽]。
    // 临时槽按在 TAC 中首次出现的顺序编号登记——
    // 布局在执行前完全确定，这是“活动记录”一词的本义。
    std::vector<std::string> temps;
    auto isNum = [](const std::string &s) {
        return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
    };
    auto add = [&](const std::string &n) {
        if (n.empty() || isNum(n)) return;
        bool known = false;
        for (const auto &v : fn.params)
            if (v == n) known = true;
        for (const auto &v : fn.vars)
            if (v == n) known = true;
        for (const auto &v : temps)
            if (v == n) known = true;
        if (!known) temps.push_back(n);
    };
    for (const auto &q : code) {
        switch (q.op) {
        case TOp::Copy: case TOp::Add: case TOp::Sub:
        case TOp::Mul: case TOp::Div: case TOp::Gt: case TOp::Eq:
        case TOp::Input: case TOp::Call:
            add(q.dst);
            break;
        default: break;
        }
        switch (q.op) {
        case TOp::Copy: case TOp::Output: case TOp::Ret: case TOp::Param:
            add(q.a);
            break;
        case TOp::Add: case TOp::Sub: case TOp::Mul: case TOp::Div:
        case TOp::Gt: case TOp::Eq: case TOp::IfGt: case TOp::IfEq:
            add(q.a);
            add(q.b);
            break;
        default: break;
        }
    }
    funcs_[fn.name] = {&fn, std::move(code), std::move(temps)};
}

int &Vm::slot(Frame &f, const std::string &name) {
    for (size_t k = 0; k < f.slotName.size(); ++k)
        if (f.slotName[k] == name) return f.slot[k];
    throw std::runtime_error("帧 " + f.func + " 无槽位 " + name);
}

int Vm::read(Frame &f, const std::string &a) {
    if (isNum(a)) return std::atoi(a.c_str());
    return slot(f, a);
}

VmRun Vm::run(const std::vector<int> &inputs) {
    inputs_ = inputs;
    // 代码指针栈：与帧栈平行——返回时既要弹帧、也要回到调用者的指令数组。
    std::vector<const std::vector<Quad> *> codeStack;
    // 最外层帧：main，参数槽存在但本教程恒以 0 填充（与 JIT 口径一致）。
    auto pushFrame = [&](const std::string &name, std::vector<int> args, int retAddr) {
        auto it = funcs_.find(name);
        if (it == funcs_.end()) throw std::runtime_error("未定义函数 " + name);
        const FunDecl &fn = *std::get<0>(it->second);
        Frame f;
        f.func = name;
        f.retAddr = retAddr;
        f.controlLink = stack_.empty() ? -1 : static_cast<int>(stack_.size()) - 1;
        f.depth = static_cast<int>(stack_.size()) + 1;
        for (size_t k = 0; k < fn.params.size(); ++k) {
            f.slotName.push_back(fn.params[k]);
            f.slot.push_back(k < args.size() ? args[k] : 0);
        }
        for (const auto &v : fn.vars) {
            f.slotName.push_back(v);
            f.slot.push_back(0);
        }
        for (const auto &v : std::get<2>(it->second)) {
            f.slotName.push_back(v);
            f.slot.push_back(0);
        }
        std::ostringstream os;
        os << "push " << name << " depth=" << f.depth
           << " ret=" << retAddr << " slots=[";
        for (size_t k = 0; k < f.slotName.size(); ++k)
            os << (k ? " " : "") << f.slotName[k] << ":" << f.slot[k];
        os << "]";
        trace_.push_back(os.str());
        stack_.push_back(std::move(f));
        codeStack.push_back(&std::get<1>(it->second));
    };

    std::vector<int> pendingParams;
    pushFrame("main", {}, -1);
    int pc = 0;
    while (true) {
        const std::vector<Quad> &code = *codeStack.back();
        const Quad &q = code[pc];
        switch (q.op) {
        case TOp::Copy:  slot(stack_.back(), q.dst) = read(stack_.back(), q.a); ++pc; break;
        case TOp::Add:   slot(stack_.back(), q.dst) = read(stack_.back(), q.a) + read(stack_.back(), q.b); ++pc; break;
        case TOp::Sub:   slot(stack_.back(), q.dst) = read(stack_.back(), q.a) - read(stack_.back(), q.b); ++pc; break;
        case TOp::Mul:   slot(stack_.back(), q.dst) = read(stack_.back(), q.a) * read(stack_.back(), q.b); ++pc; break;
        case TOp::Div:   slot(stack_.back(), q.dst) = read(stack_.back(), q.a) / read(stack_.back(), q.b); ++pc; break;
        case TOp::Gt:    slot(stack_.back(), q.dst) = read(stack_.back(), q.a) > read(stack_.back(), q.b) ? 1 : 0; ++pc; break;
        case TOp::Eq:    slot(stack_.back(), q.dst) = read(stack_.back(), q.a) == read(stack_.back(), q.b) ? 1 : 0; ++pc; break;
        case TOp::Input:
            if (nextInput_ >= inputs_.size()) throw std::runtime_error("input 序列耗尽");
            slot(stack_.back(), q.dst) = inputs_[nextInput_++];
            ++pc;
            break;
        case TOp::Output: outputs_.push_back(read(stack_.back(), q.a)); ++pc; break;
        case TOp::Goto:   pc = q.target; break;
        case TOp::IfGt:   pc = read(stack_.back(), q.a) > read(stack_.back(), q.b) ? q.target : pc + 1; break;
        case TOp::IfEq:   pc = read(stack_.back(), q.a) == read(stack_.back(), q.b) ? q.target : pc + 1; break;
        case TOp::Param:
            pendingParams.push_back(read(stack_.back(), q.a));
            ++pc;
            break;
        case TOp::Call: {
            int retAddr = pc + 1;
            std::vector<int> args;
            args.swap(pendingParams);
            pushFrame(q.a, std::move(args), retAddr);
            pc = 0;
            break;
        }
        case TOp::Ret: {
            int value = read(stack_.back(), q.a);
            std::string callee = stack_.back().func;
            Frame f = std::move(stack_.back());
            stack_.pop_back();
            codeStack.pop_back();
            std::ostringstream os;
            os << "pop  " << callee << " depth=" << (f.depth) << " ret->" << f.retAddr
               << " value=" << value;
            trace_.push_back(os.str());
            if (stack_.empty()) {
                VmRun r;
                r.outputs = outputs_;
                r.trace = trace_;
                return r;
            }
            pc = f.retAddr;
            // 返回值写进 call 指令的目的槽（call 恰在返回地址前一条）
            const Quad &call = (*codeStack.back())[pc - 1];
            slot(stack_.back(), call.dst) = value;
            break;
        }
        }
    }
}

}  // namespace tip
```

### 15.7.3 改件：tacgen.hpp 与 tacgen.cpp

第 13 章版本
加 Param/Call
两条指令
与 CallE 的降落。

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
                 Goto, IfGt, IfEq, Param, Call };
// Param: "param x"——实参入栈；Call: "x = call f k"——调用 f、k 个实参、结果入 x。
// 第 13 章的指令族在此加两条：有了它们才有“调用序列”可讲。

struct Quad {
    TOp op;
    std::string dst;    // Copy/Bin/Input 的目的
    std::string a, b;   // 操作数
    int target = -1;    // 跳转目标（TAC 下标；打印为 L<n>）
};

std::string show(const Quad &q);

// 单函数 TAC：把函数体降落到四元组序列（本章含 param/call）。
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
    case TOp::Param:  os << "param " << q.a; break;
    case TOp::Call:   os << q.dst << " = call " << q.a << " " << q.b; break;
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
        if (auto *c = dynamic_cast<const CallE *>(&e)) {
            auto *fn = dynamic_cast<const VarRef *>(c->callee.get());
            if (!fn) unsupported("间接调用（闭包）", 41);
            for (const auto &arg : c->args) {
                std::string v = addr(*arg);
                emit({TOp::Param, "", v, "", -1});
            }
            std::string t2 = newTmp();
            emit({TOp::Call, t2, fn->name, std::to_string(c->args.size()), -1});
            return t2;
        }
        unsupported("该表达式构造（指针/记录）", 42);
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

### 15.7.4 改件：tacinterp.hpp 与 tacinterp.cpp

哈希帧的
多函数解释器
（对账的另一边）。

```cpp
// file: src/tacinterp.hpp
// file: src/tacinterp.hpp
// 第 15 章配套：多函数 TAC 解释器（第 13 章证人版加调用栈）。
// 与 Vm 的分工：本件用哈希帧（名字→值）执行，
// Vm 用显式活动记录（编号槽）执行，两者 outputs 对账。
#ifndef TIP_TACINTERP_HPP
#define TIP_TACINTERP_HPP

#include <map>
#include <string>
#include <vector>

#include "tacgen.hpp"

namespace tip {

struct TacRun {
    std::vector<int> outputs;
    int steps = 0;
};

class TacInterp {
public:
    void define(const std::string &name, const std::vector<std::string> &params,
                std::vector<Quad> code);
    TacRun run(const std::vector<int> &inputs);

private:
    std::map<std::string, std::pair<std::vector<std::string>, std::vector<Quad>>> code_;
};

}  // namespace tip

#endif  // TIP_TACINTERP_HPP
```

```cpp
// file: src/tacinterp.cpp
// file: src/tacinterp.cpp
// 第 15 章配套：多函数 TAC 解释器实现（哈希帧，与 Vm 的显式槽帧对账）。
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

void TacInterp::define(const std::string &name, const std::vector<std::string> &params,
                       std::vector<Quad> code) {
    code_[name] = {params, std::move(code)};
}

TacRun TacInterp::run(const std::vector<int> &inputs) {
    TacRun r;
    struct Frame {
        std::map<std::string, int> val;
        int retAddr;
        const std::vector<Quad> *code;
    };
    std::vector<Frame> stack;
    auto start = [&](const std::string &name, int retAddr, const std::vector<int> &args) {
        auto it = code_.find(name);
        if (it == code_.end()) throw std::runtime_error("未定义函数 " + name);
        stack.push_back(Frame{{}, retAddr, &it->second.second});
        for (size_t k = 0; k < it->second.first.size(); ++k)
            stack.back().val[it->second.first[k]] = k < args.size() ? args[k] : 0;
    };
    start("main", -1, {});
    std::vector<int> pending;
    size_t nextInput = 0;
    int pc = 0;
    while (true) {
        const Quad &q = (*stack.back().code)[pc];
        ++r.steps;
        auto &V = stack.back().val;
        auto rd = [&](const std::string &a) -> int {
            if (isNum(a)) return std::atoi(a.c_str());
            auto it = V.find(a);
            if (it == V.end()) throw std::runtime_error("读未初始化变量 " + a);
            return it->second;
        };
        switch (q.op) {
        case TOp::Copy:  V[q.dst] = rd(q.a); ++pc; break;
        case TOp::Add:   V[q.dst] = rd(q.a) + rd(q.b); ++pc; break;
        case TOp::Sub:   V[q.dst] = rd(q.a) - rd(q.b); ++pc; break;
        case TOp::Mul:   V[q.dst] = rd(q.a) * rd(q.b); ++pc; break;
        case TOp::Div:   V[q.dst] = rd(q.a) / rd(q.b); ++pc; break;
        case TOp::Gt:    V[q.dst] = rd(q.a) > rd(q.b) ? 1 : 0; ++pc; break;
        case TOp::Eq:    V[q.dst] = rd(q.a) == rd(q.b) ? 1 : 0; ++pc; break;
        case TOp::Input:
            if (nextInput >= inputs.size()) throw std::runtime_error("input 序列耗尽");
            V[q.dst] = inputs[nextInput++];
            ++pc;
            break;
        case TOp::Output: r.outputs.push_back(rd(q.a)); ++pc; break;
        case TOp::Goto:   pc = q.target; break;
        case TOp::IfGt:   pc = rd(q.a) > rd(q.b) ? q.target : pc + 1; break;
        case TOp::IfEq:   pc = rd(q.a) == rd(q.b) ? q.target : pc + 1; break;
        case TOp::Param:  pending.push_back(rd(q.a)); ++pc; break;
        case TOp::Call: {
            std::vector<int> args;
            args.swap(pending);
            start(q.a, pc + 1, args);
            pc = 0;
            break;
        }
        case TOp::Ret: {
            int value = rd(q.a);
            int retAddr = stack.back().retAddr;
            stack.pop_back();
            if (stack.empty()) return r;
            pc = retAddr;
            // call 指令恰在返回地址前一条；返回值写进它的目的槽。
            const Quad &call = (*stack.back().code)[pc - 1];
            stack.back().val[call.dst] = value;
            break;
        }
        }
    }
}

}  // namespace tip
```

### 15.7.5 驱动 main.cpp

TAC → 帧布局 →
VM 轨迹 →
interp → 对账。

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 15 章驱动：--check FILE
//   各函数 TAC → 帧布局 → VM 执行（帧轨迹）→ 哈希版解释器执行 → 对账。
#include "tacgen.hpp"
#include "tacinterp.hpp"
#include "vm.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"

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

    std::cout << "== TAC ==\n";
    tip::Vm vm;
    tip::TacInterp interp;
    for (const auto &fn : p.ast->funs) {
        std::vector<tip::Quad> code = tip::tacGen(*fn);
        std::cout << "  fun " << fn->name << ":\n";
        for (size_t i = 0; i < code.size(); ++i)
            std::cout << "    " << i << ": " << tip::show(code[i]) << '\n';
        vm.define(*fn, code);
        interp.define(fn->name, fn->params, code);
    }

    std::cout << "== 帧布局 ==\n";
    for (const auto &fn : p.ast->funs) {
        std::cout << "  " << fn->name << ": [ret | ctrl |";
        for (const auto &v : fn->params) std::cout << ' ' << v;
        for (const auto &v : fn->vars) std::cout << ' ' << v;
        std::cout << " ]  共 "
                  << (fn->params.size() + fn->vars.size()) << " 槽\n";
    }

    std::cout << "== VM 轨迹 ==\n";
    tip::VmRun vr = vm.run({});
    for (const auto &t : vr.trace) std::cout << "  " << t << '\n';
    std::cout << "== outputs (vm) ==\n ";
    for (int v : vr.outputs) std::cout << ' ' << v;
    std::cout << '\n';

    std::cout << "== outputs (interp) ==\n ";
    tip::TacRun tr = interp.run({});
    for (int v : tr.outputs) std::cout << ' ' << v;
    std::cout << " ; steps = " << tr.steps << '\n';

    std::cout << "== 对账 ==\n";
    std::cout << "  vm==interp: " << (vr.outputs == tr.outputs ? "yes" : "NO") << '\n';
    return vr.outputs == tr.outputs ? 0 : 1;
}
```

### 15.7.6 前端基础件：ast、ast_build、symtab

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

### 15.7.7 程序与期望输出

```text
// file: programs/calls.tip
add(a, b) {
  return a + b;
}
main() {
  var x, y;
  x = add(2, 3);
  y = add(x, 4);
  output y;
  return 0;
}
```

```text
// file: programs/fact.tip
fact(n) {
  var r;
  if (n > 1) r = n * fact(n - 1); else r = 1;
  return r;
}
main() {
  var x;
  x = fact(4);
  output x;
  return 0;
}
```

```text
; expected: expected/output.txt
== calls.tip ==
== TAC ==
  fun add:
    0: t1 = a + b
    1: return t1
  fun main:
    0: t1 = 2
    1: param t1
    2: t2 = 3
    3: param t2
    4: t3 = call add 2
    5: x = t3
    6: param x
    7: t4 = 4
    8: param t4
    9: t5 = call add 2
    10: y = t5
    11: output y
    12: t6 = 0
    13: return t6
== 帧布局 ==
  add: [ret | ctrl | a b ]  共 2 槽
  main: [ret | ctrl | x y ]  共 2 槽
== VM 轨迹 ==
  push main depth=1 ret=-1 slots=[x:0 y:0 t1:0 t2:0 t3:0 t4:0 t5:0 t6:0]
  push add depth=2 ret=5 slots=[a:2 b:3 t1:0]
  pop  add depth=2 ret->5 value=5
  push add depth=2 ret=10 slots=[a:5 b:4 t1:0]
  pop  add depth=2 ret->10 value=9
  pop  main depth=1 ret->-1 value=0
== outputs (vm) ==
  9
== outputs (interp) ==
  9 ; steps = 18
== 对账 ==
  vm==interp: yes
== fact.tip ==
== TAC ==
  fun fact:
    0: t1 = 1
    1: if n > t1 goto L3
    2: goto L10
    3: t2 = 1
    4: t3 = n - t2
    5: param t3
    6: t4 = call fact 1
    7: t5 = n * t4
    8: r = t5
    9: goto L12
    10: t6 = 1
    11: r = t6
    12: return r
  fun main:
    0: t1 = 4
    1: param t1
    2: t2 = call fact 1
    3: x = t2
    4: output x
    5: t3 = 0
    6: return t3
== 帧布局 ==
  fact: [ret | ctrl | n r ]  共 2 槽
  main: [ret | ctrl | x ]  共 1 槽
== VM 轨迹 ==
  push main depth=1 ret=-1 slots=[x:0 t1:0 t2:0 t3:0]
  push fact depth=2 ret=3 slots=[n:4 r:0 t1:0 t2:0 t3:0 t4:0 t5:0 t6:0]
  push fact depth=3 ret=7 slots=[n:3 r:0 t1:0 t2:0 t3:0 t4:0 t5:0 t6:0]
  push fact depth=4 ret=7 slots=[n:2 r:0 t1:0 t2:0 t3:0 t4:0 t5:0 t6:0]
  push fact depth=5 ret=7 slots=[n:1 r:0 t1:0 t2:0 t3:0 t4:0 t5:0 t6:0]
  pop  fact depth=5 ret->7 value=1
  pop  fact depth=4 ret->7 value=2
  pop  fact depth=3 ret->7 value=6
  pop  fact depth=2 ret->3 value=24
  pop  main depth=1 ret->-1 value=0
== outputs (vm) ==
  24
== outputs (interp) ==
  24 ; steps = 43
== 对账 ==
  vm==interp: yes
```

## 15.8 小结与练习

本章给函数调用
安了家：

- 活动树的不重叠性
  证明栈足够；
- 活动记录
  [ret | ctrl | 数据]
  是家的户型图，
  布局在执行前定死；
- 调用/返回两段序列
  把 param/call/return
  三个语言构件
  落成帧的生灭；
- 嵌套世界需要
  访问链或 display，
  扁平的 TIP 不需要，
  但闭包
  （把链装箱上堆）
  把这份需求
  转送给了下一章。

练习：

1. 手工画出
   fact(4) 的活动树，
   与 VM 轨迹的
   五进五出逐行对照；
   指出栈内
   任意时刻的活动
   恰是树上一条
   根到叶路径。
2. 把 calls.tip 改成
   `output add(add(1,2), add(3,4));`
   （嵌套调用），
   重新生成期望输出，
   观察四组
   param/call 的
   嵌套轨迹与
   ret 地址的
   差别。
3. 给 VM 加
   "栈深度上限 4"，
   超限抛
   stack overflow，
   在 fact(5) 上
   演示崩溃
   （放 errors/）。
4. （较大）给 TIP
   加嵌套函数声明的
   文法支持，
   VM 帧加访问链，
   写一个读外层变量的
   嵌套程序，
   轨迹里打印
   沿链爬行的跳数。
5. 解释为什么
   "实参槽"放在
   返回地址与
   控制链之后、
   局部变量之前，
   而不是最后
   （提示：被调者
   以固定偏移
   访问形参，
   参数个数
   调用者知道、
   局部个数
   被调者知道；
   两侧各自负责
   自己的那段布局，
   是谁在生成代码？）。
