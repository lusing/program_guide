# 第 54 章　字节码与栈式虚拟机

> 取材：匠书（Crafting Interpreters）§14.1–14.4（字节码块、常量池、
> 行号表）、§15.1–15.5（虚拟机大循环、栈式求值、反汇编）、§18.1–18.2
>（带标签联合值）、§24.1–24.4（调用帧、调用序列、原生函数）。全部
> 材料在本章自包含蒸馏，不需要翻原书。
> 本章示例：`examples/54_bytecode_vm`（无 ANTLR，简单程序对账协议）。

**两分钟速览**：字节码 VM 只有四样东西——chunk（字节流 + 常量池 +
行号表）、反汇编（把字节读回人话）、大循环（`for(;;) switch(op)`，
FETCH-DECODE-EXECUTE 一体）、调用帧（fn/ip/base 三字段）。栈式求值
一句话：操作数隐式在栈顶，后缀序即求值序（`3 4 ADD` = 7）。调用
一句话：被调者与实参先压栈，Call 建帧（base 指被调者），Return 清
帧并把返回值压在被调者的位置。三个断言锁定理解：`-(3+4)*2` = -14
（栈账逐格可推）、fact(5) 帧深恰 7（帧深 = 链长）、input() 走旁路
不建帧。第 55 章的编译器将替你写本章手编的一切。

## 54.0　第三条执行路收官：树变成字节流

第 13 章的树遍历解释器把 AST 直接求值——简单，但每次执行同一个函数
都要重新走过"类型分派 + 递归下降"的全过程：每个节点的 `dynamic_cast`
链、每层求值的函数调用开销，都在为"第一次之后就不再需要的发现"付
账。匠书用 clox（书第三部分）给出了工程答案：**先把树编码成线性
字节流（编译一次），再让一个极简的循环执行字节流（执行 N 次）**。
控制流从"递归调用图"变成"ip 的加减"，数据流从"AST 节点指针"变成
"一个值栈"。这就是字节码虚拟机——JVM、CPython、V8 的 JavaScriptCore
前代、Lua 的共同形态。

本章是这个形态的最小完整实现，四件资产：

1. **chunk**（§14）：操作码流 + 常量池 + 行号表——程序在内存里的
   最终形态；
2. **反汇编**（§15.1）：把字节流读回人类可读文本——调试与教学的第一
   工具；
3. **大循环**（§15.2–15.4）：FETCH–DECODE–EXECUTE 一个 switch——
   全部的"执行引擎"只有一百多行；
4. **调用帧**（§24.1–24.3）：CallFrame 三字段与 Call/Return 指令的
   配合——函数调用在栈机上的完整形态；原生函数走 C++ 直调旁路
   （§24.4）。

与前两章的证人关系：本章的手编字节码程序输出与手算对账；**第 55
章的编译器会把 TIP 源程序编成本章的 chunk 格式、跑在本章的 VM 上**
——那时"编译器产出"与"本章手编"要产出**逐字节同构**的反汇编；
第 57 章再给 VM 加上值（upvalue）机制跑闭包。Op 枚举在本章冻结
（§54.1），后两章只追加不修改——这是三章共用地基的接口约定。

"为什么字节码比树遍历快"值得一段诚实的性能直觉（不引数字，只讲
机制）：树遍历的每次"做一件事"要经过 ①dynamic_cast 链定位节点类型
（平均半个链长）②递归调用（建栈帧）③返回后聚合；字节码的每次是
①一次数组读 ②一次 switch（编译器把密集枚举优化成跳转表，一次
间接跳）③一两条栈顶操作。**差别不在单条指令的复杂度，而在"发现
做什么"的成本**：树遍历每步都要重新发现（cast），字节码把发现
提前到了编译期（switch 的跳转表就是预先算好的发现）。顺着这个
直觉还能理解真实引擎的下一层：字节码再编译成机器码（JIT）消灭的
是 switch 本身——**每一层编译都在消灭一层"运行期发现"**。

三条执行路到此齐了，对照表更新（第 13 章立过初版）：

| 执行路 | 变换 | 代表 | 何时选择 |
|---|---|---|---|
| 树遍历 | 无 | 第 13 章、jlox | 原型期、语义探索期 |
| 寄存器机 IR | AST→TAC | 第 16 章、gcc 中端 | 要做分析与优化 |
| 栈机字节码 | AST→chunk | 本章、clox/JVM/Lua | 要紧凑、快启动、可移植 |

表的第三列都是活着的工业实现——三条路没有一条是教学玩具；选哪条
不是技术优劣，是"你要给谁当消费者"（第 13 章 FAQ 的老问题）。

```text
54.1 chunk：字节流、常量池与行号表
54.2 反汇编即文档
54.3 大循环与栈式求值（含每指令栈深账）
54.4 值：带标签联合起步版
54.5 调用帧：Call/Return 的六步序列（含递归帧深账、原生旁路）
54.6 与第 16 章 TAC 寄存器机对照
54.7 驱动、语料与期望输出解读
54.8 FAQ、小结与练习
```

三种读者的读法：**赶时间者**读两分钟速览 + §54.3 栈效应表 + §54.5
调用前后图——五分钟拿到模型；**实现者**重点 §54.1 三决定、§54.5
六步与快照、§54.8 FAQ（选型问题都在那里）；**从匠书来的读者**先看
小结后的映射表再按序读——本章与 clox 的差异集中在值宇宙（int64 vs
double）与错误处理（防御位措辞），都已在正文标注。

本章与前两轮扩充章的文体差异顺带说明：第 9 章是"双实现等价"
（解析对照）、第 13 章是"语义基准"（后续一切执行路的准绳）、本章
是"地基与规范"（接口冻结 + 手编审计能力）——三章三种立意，共同
点是把"读者能验证什么"放在设计首位。第 55 章将是第四种："机器
产物审计"——读者拿手编（本章）审机器编（55 章）的反汇编，两版
必须同构。四种立意连起来，就是匠书线的完整教学主张：**每一层
都让上一层的产物可被人工检验**。
## 54.1　chunk：字节流、常量池与行号表

```cpp
// file: src/chunk.hpp
// file: src/chunk.hpp
// 第 54 章：字节码块——操作码流 + 常量池 + 行号表（匠书 §14）。
// Op 枚举在本章冻结：第 55 章追加全局/局部与跳转的日常使用，
// 第 57 章追加 Closure/GetUpvalue/SetUpvalue——签名不变。
#ifndef TIP_CHUNK_HPP
#define TIP_CHUNK_HPP

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace tip {

// ---------- 操作码全集（本章机 + 后两章扩展位） ----------
enum class Op : uint8_t {
    // 栈式求值（§15.2）
    Constant,   // u8 常量索引：压常量
    Add, Sub, Mul, Div,  // 弹二压一（后缀序即求值序）
    Gt, Eq,               // 比较：真 1 假 0（TIP 整数口径）
    Negate,               // 弹一压其相反数
    Print,                // 弹一打印
    Pop,                  // 弹弃（语句值丢弃）
    // 局部变量（§22）：u8 槽位，相对帧基
    GetLocal,   // 压 stack[base+slot]
    SetLocal,   // stack[base+slot] = 栈顶（不弹，赋值表达式有值）
    // 跳转（§23）：u16 偏移（高字节在前，与匠书一致）
    JumpIfFalse,  // 栈顶假（0）则跳，不弹？——弹（条件消费）
    Jump,         // 无条件跳（前向：回填）
    Loop,         // 向后跳（while 回边）
    // 调用（§24）：u8 实参数；被调者在栈上、实参紧随其上
    Call,
    CloseUpvalue,  // 第 57 章启用：栈收缩时关闭上值
    // 函数返回：弹返回值、拆帧、压回调用者栈
    Return,
};

// ---------- 值：带标签联合起步版（§18；第 56 章 NaN 装箱升级） ----------
struct Obj {
    virtual ~Obj() = default;  // 多态基：本章派生 ObjFn/ObjNative，56 章加 ObjString
};
struct Value {
    enum class Tag : uint8_t { Int, Obj } tag = Tag::Int;
    long long i = 0;                 // Tag::Int
    std::shared_ptr<Obj> obj;        // Tag::Obj（本章只有 ObjFn/ObjNative）

    static Value num(long long v) { Value x; x.i = v; return x; }
    static Value ref(std::shared_ptr<Obj> o);
    bool isObj() const { return tag == Tag::Obj; }
};
std::string showValue(const Value &v);  // 反汇编/打印用

// 函数对象：名字 + 元数 + 代码体（共享 Chunk 所有权，常量池可互相引用）
struct ObjFn : Obj {
    std::string name;
    int arity = 0;
    std::shared_ptr<struct Chunk> code;
};
// 原生函数：C++ 直调旁路（§24.4 input 桩）
struct ObjNative : Obj {
    std::string name;
    int arity = 0;
    Value (*fn)(std::vector<Value> args);
};

// ---------- chunk 本体 ----------
struct Chunk {
    std::vector<uint8_t> code;    // 操作码与内联操作数
    std::vector<Value> consts;    // 常量池
    std::vector<int> lines;       // 与 code 等长：每字节所在源码行

    int addConstant(const Value &v);  // 去重：同值返回同索引（§17.6）
    void write(Op op, int line);
    void writeByte(uint8_t b, int line);
    void writeU16(uint16_t x, int line);  // 高字节在前
};

// 反汇编：人类可读回读每条指令（§15.1"反汇编即文档"）。
// 返回指令的字节长度（调用方借此推进地址）。
int disassembleInstruction(const Chunk &c, size_t offset, std::ostream &os);
void disassembleChunk(const Chunk &c, const std::string &title, std::ostream &os);

}  // namespace tip

#endif  // TIP_CHUNK_HPP
```

```cpp
// file: src/chunk.cpp
// file: src/chunk.cpp
#include "chunk.hpp"

#include <ostream>
#include <sstream>

namespace tip {

Value Value::ref(std::shared_ptr<Obj> o) {
    Value x;
    x.tag = Tag::Obj;
    x.obj = std::move(o);
    return x;
}

std::string showValue(const Value &v) {
    if (v.isObj()) {
        if (auto *f = dynamic_cast<const ObjFn *>(v.obj.get()))
            return "<fn " + f->name + "/" + std::to_string(f->arity) + ">";
        if (auto *n = dynamic_cast<const ObjNative *>(v.obj.get()))
            return "<native " + n->name + ">";
        return "<obj>";
    }
    return std::to_string(v.i);
}

int Chunk::addConstant(const Value &v) {
    for (size_t k = 0; k < consts.size(); ++k)
        if (consts[k].tag == v.tag && consts[k].i == v.i &&
            consts[k].obj == v.obj)
            return int(k);  // 去重：字节码里同名函数/同值整数只存一份
    consts.push_back(v);
    return int(consts.size()) - 1;
}

void Chunk::write(Op op, int line) {
    code.push_back(static_cast<uint8_t>(op));
    lines.push_back(line);
}

void Chunk::writeByte(uint8_t b, int line) {
    code.push_back(b);
    lines.push_back(line);
}

void Chunk::writeU16(uint16_t x, int line) {  // 高字节在前（网络序习惯）
    writeByte(static_cast<uint8_t>(x >> 8), line);
    writeByte(static_cast<uint8_t>(x & 0xFF), line);
}

// ---------- 反汇编 ----------
static const char *opName(Op op) {
    switch (op) {
        case Op::Constant: return "CONSTANT";
        case Op::Add: return "ADD";
        case Op::Sub: return "SUB";
        case Op::Mul: return "MUL";
        case Op::Div: return "DIV";
        case Op::Gt: return "GT";
        case Op::Eq: return "EQ";
        case Op::Negate: return "NEGATE";
        case Op::Print: return "PRINT";
        case Op::Pop: return "POP";
        case Op::GetLocal: return "GET_LOCAL";
        case Op::SetLocal: return "SET_LOCAL";
        case Op::JumpIfFalse: return "JUMP_IF_FALSE";
        case Op::Jump: return "JUMP";
        case Op::Loop: return "LOOP";
        case Op::Call: return "CALL";
        case Op::CloseUpvalue: return "CLOSE_UPVALUE";
        case Op::Return: return "RETURN";
    }
    return "?";
}

int disassembleInstruction(const Chunk &c, size_t off, std::ostream &os) {
    char buf[16];
    std::snprintf(buf, sizeof buf, "%04zu ", off);
    os << buf;
    if (off > 0 && c.lines[off] == c.lines[off - 1]) os << "   | ";
    else os << (c.lines[off] < 10 ? "  " : c.lines[off] < 100 ? " " : "") << c.lines[off] << " ";
    Op op = static_cast<Op>(c.code[off]);
    switch (op) {
        case Op::Constant: {
            uint8_t k = c.code[off + 1];
            os << opName(op) << " " << int(k) << "  ; " << showValue(c.consts[k]) << "\n";
            return 2;
        }
        case Op::GetLocal: case Op::SetLocal: case Op::Call: {
            os << opName(op) << " " << int(c.code[off + 1]) << "\n";
            return 2;
        }
        case Op::JumpIfFalse: case Op::Jump: case Op::Loop: {
            uint16_t x = uint16_t(c.code[off + 1]) << 8 | c.code[off + 2];
            // 前向跳转打印目标地址、后向（Loop）打印起点，与匠书同款
            if (op == Op::Loop) os << opName(op) << " -> " << (off - x) << "\n";
            else os << opName(op) << " -> " << (off + 3 + x) << "\n";
            return 3;
        }
        default:
            os << opName(op) << "\n";
            return 1;
    }
}

void disassembleChunk(const Chunk &c, const std::string &title, std::ostream &os) {
    os << "== " << title << " ==\n";
    for (size_t off = 0; off < c.code.size();)
        off += static_cast<size_t>(disassembleInstruction(c, off, os));
}

}  // namespace tip
```

一个 chunk 是一段可执行代码的完整容器：`code` 是字节流（操作码与
内联操作数混居，**指令定长头 + 变长操作数**——`Constant` 一字节操作
数、`GetLocal` 一字节、跳转两字节，见 §54.2 的长度表）；`consts` 是
常量池（整数与函数对象都在这里，字节流里只放**索引**——u8 上限
256 个常量，教学够用，匠书同款限制）；`lines` 与 code 等长，**每个
字节**记它所属的源码行。

三个设计决定值得逐一盘问。

**决定一：为什么操作数内联在字节流里，而不是并列表？** 备选方案是
"指令数组 + 独立操作数数组"（或结构体数组 `{op, a, b}`）。内联字节的
好处是**ip 只有一个**：取指、取操作数、推进都是同一个下标的算术，
跳转目标就是一个字节地址——大循环里没有任何"指令号换算成字节号"
的换算。结构体数组版的循环更"整洁"，但每条指令多占三倍内存、跳转
要乘以结构体大小。把两版大循环的取指行并排看：字节版 `op =
code[ip++]`，结构版 `ins = insArray[ip++]; op = ins.op; a = ins.a;`
——后者每次多两次访存（结构体跨缓存行时更多），而**热路径上一次
多余访存就是一次真实代价**。字节码 VM 的全部巧妙都建立在"**代码
就是字节数组，ip 就是下标**"这个朴素事实上：缓存局部性（顺序字节
几乎总是同行预取）、跳转算术（偏移即字节偏移）、序列化（内存形态
即磁盘形态，落盘零翻译）三件红利都从这一条来。

**决定二：常量池为什么要去重（`addConstant`）？** 同一个整数 1 在
`fact` 里出现两次就去池里查两次，命中即返回旧索引。收益一：字节码
更小（不必重复入池——池子本身也省）。收益二：**第 56 章的字符串
驻留正是这一思想在"值层"的重演**——`==` 比较退化为指针比较的前提
就是"相等的值只存一份"；本章在常量层先做一次小规模排练。匠书
§17.6 的原话把这条列为"微小优化"，但在语义上它埋着驻留的种子。

常量池里最值得驻足的一格是**函数自引用**：fact 的常量池里有
指向 fact 自己的 Value（递归调用的被调者）——**递归在表示层就是
"池子里有自己"**，一个 shared_ptr 的环。这与第 13 章递归走全局
函数表不同：那里名字解析在运行期查表，这里名字在编译期（55 章）
或手编时已落成常量索引——**递归没有特殊机制，只是普通常量恰好
指向自己**。顺带一提 shared_ptr 的环不泄漏的原因：ObjFn 持有的
是 shared_ptr<Chunk>，而 Value 持 ObjFn——fact 常量池经 Chunk 持
fact……环在脚本函数值、ObjFn、Chunk 三者之间；驱动里 script 与
fact 都有独立持有的 shared_ptr 从外部压住整团对象（"外部根"），
环内引用计数不清零也不影响正确回收——**环 + 外部根 = 活，无根
环 = 泄漏**，第 20 章可达性的直觉预演。

**决定三：行号为什么按字节记而不是按指令记？** 每个操作数字节都
重复记行号看起来浪费（`lines` 与 `code` 等长）。替代方案是"指令表
+ 区间二分"。按字节记的理由：**运行期错误的行号查询是 O(1)**——
VM 报错时手上只有字节偏移 ip，直接 `lines[ip]`；区间二分要维护结构、
错误路径（最不该复杂的路径）变复杂。内存上重复的行号相邻且相同，
对压缩极友好（真实引擎把行号表压缩成差分变长编码）。**为最热路径
（错误报告）与最简路径（一次数组访问）买单**——这是个典型的"数据
结构为查询模式定制"的小案例，第 20 章堆账本、第 57 章上值链都会
再见到同款思路。

Op 枚举十八个成员的分组即本章到第 57 章的路线图：栈式求值十一个
（本章主角）、局部槽两个（55 章日常使用，本章 fact 已用）、跳转
三个（55 章回填的主角，本章手编直接写目标）、Call/CloseUpvalue/
Return 三个（Call 本章、CloseUpvalue 是 57 章的**冻结占位**——枚举
值分配了但 VM 一执行到就报"未启用"）。**占位指令**是三章共享 Op
枚举的接口技术：57 章的示例复制本章 VM 后"启用"它，枚举顺序与
数值不变，反汇编文本不变。

u8 常量索引的 256 上限值得多说两句——它是**格式契约的一部分**
而不是随便的数。真实引擎的选择谱系：Lua 5.1 用双格式（小函数 u8、
大函数 u8×2 编码），JVM 用变长（短指令与宽指令两套助记符，编译器
负责在超限时重发宽版），CPython 3.11 起给大常量池发
`EXTENDED_ARG` 前缀指令（占一个操作数字节位、可叠加）。三种方案
的共同点是**短指令保密度、宽编码按需启用**——绝大多数函数的常量
数远小于 256，为极少数大函数全员买单不划算。本章恒用 u8：教学
语料的常量数个位数，55 章驱动若超限会在 addConstant 的返回值上
自然暴露（练习 1 的追问点）。**上限不是缺陷，是格式设计的一格**。

行号表的"每字节一行号"在内存上看着最浪费（相邻同值重复），恰好
是最易压缩的形态：相邻差分 + 变长编码后，一段同行的连续字节缩成
"重复 N 次"一个记号——真实引擎（V8 的 source position 表、JVM 的
LineNumberTable）全都这么存。**先存最易查询的形态，再为存储压一层
编码**——查询路径（错误报告）永远只碰解码后形态，压缩对它透明。
这个"形态与编码分层"的手法，第 56 章的 NaN 装箱在值上又演一遍
（值形态 8 字节，编码把 tag 藏进指位）。

## 54.2　反汇编即文档

`disassembleChunk` 把字节流逐指令读回文本。输出四列：**字节地址**
（四位十六进制风格）、**行号**（与前一字节同行则打 `|` 折叠——源码
行是给读者的，不是给机器的）、**操作码名**、**操作数与注释**（常量
索引带值预览 `CONSTANT 0  ; 3`、跳转带目标地址 `JUMP -> 25`）。

四列的每一列都在为一个具体读者服务：地址列服务"跳转目标核对"
（fact 布局注释里的 `->13` 拿这列就能对）；行号列服务"回源码"
（运行期错误的行号同源）；操作码名列服务"模式识别"（熟了以后扫
一眼 `CONSTANT CONSTANT ADD` 就知道在算和）；注释列服务"语义
速读"（不必回查常量池第 0 项是什么）。**格式即界面**——反汇编
的读者是"正在排错的人"，界面按他的扫读习惯排，这是它区别于
hexdump 的全部原因。

"反汇编即文档"不是修辞：本章正文的每一份"手推"（栈账、帧账）都以
反汇编文本为底稿，读者核对推演时的第一动作就是看反汇编；第 55 章
的编译器断言"产出与手编同构"也拿它当对账面。写一个 VM 而不写
disassembler，等于写书不排版——匠书 §14.4 的建议（"你会在调试器上
度过很多小时，先把反汇编写好"）值得原样转述。

一个容易低估的工程事实：`disassembleInstruction` 返回**本指令字节
长度**，这个返回值同时服务两个消费者——disassembler 自己的推进
（for 循环 `off += 长度`）与"长度知识"的唯一权威。若 VM 的取操作数
逻辑另写一份长度判断，两处漂移的瞬间（55 章加新指令只改了一边），
反汇编就会与执行**错位解读同一段字节**——那是所有字节码调试里最
阴的坑（你看的反汇编和跑的代码不是一回事）。**长度、格式、语义
三件事收口在一个函数**，是字节码工具链的第一条纪律。

读反汇编的练习法（本章学习的主要手段）：把期望输出第一段的九行
盖住注释列，自己口算每行——CONSTANT 的值从哪来（池索引）、ADD
弹了谁（上两行压的）、PRINT 弹掉后栈剩什么；再进阶到 fact 的
布局注释（main.cpp 里那二十行逐地址标注），对着反汇编逐跳转核对
目标。**能在反汇编里"看见栈"的读者，55 章的回填与 57 章的上值
读起来就是白话**；看不见栈的读者，那两章的每张图都要重啃。

指令长度表（反汇编函数返回"本指令字节数"，调用方借此推进——
**长度知识住在一处**，VM 的取操作数与 disassembler 的推进共享同
一张表）：

| 指令 | 字节 | 操作数 |
|---|---|---|
| CONSTANT / GET_LOCAL / SET_LOCAL / CALL | 2 | u8 |
| JUMP_IF_FALSE / JUMP / LOOP | 3 | u16（高字节在前） |
| ADD … RETURN（无操作数单字节组） | 1 | — |

两字节操作数"高字节在前"（网络序）是匠书选择，无所谓对错，但
**读写两端必须同序**——`readU16` 与 `writeU16` 是仅有的两个知道
这件事的地方，这种"约定局部化"正是字节码格式设计的基本功。

## 54.3　大循环与栈式求值

```cpp
// file: src/vm.hpp
// file: src/vm.hpp
// 第 54 章：栈式虚拟机——FETCH-DECODE-EXECUTE 大循环 + 调用帧（匠书 §15/§24）。
// 第 55 章的编译器与第 57 章的上值扩展复用本类（本地副本 + 追加指令）。
#ifndef TIP_VM_HPP
#define TIP_VM_HPP

#include <ostream>
#include <vector>

#include "chunk.hpp"

namespace tip {

// 调用帧（§24.1）：ip 与 frameBase 捕捉"一个函数调用"的全部现场。
// base 是本帧局部槽在值栈上的起点：实参在调用前已被压栈，
// 被调函数的槽 0..arity-1 恰与实参重合（匠书的巧妙省拷贝）。
struct Frame {
    ObjFn *fn = nullptr;
    size_t ip = 0;    // 指令指针（chunk 内字节偏移）
    size_t base = 0;  // 帧基（值栈下标）
};

struct VmError {
    std::string msg;
};

class VM {
  public:
    explicit VM(std::ostream &out) : out_(&out) {}

    // 运行一个函数体（脚本也是函数）。抛 VmError 报运行期错误。
    Value run(const std::shared_ptr<ObjFn> &fn);

    void setTrace(bool on) { trace_ = on; }  // 开：记录每指令后栈深

    // —— 供断言的结构账（第 55/57 章对照用）——
    int maxFrames() const { return maxFrames_; }     // 帧深峰值
    int maxStack() const { return maxStack_; }       // 栈深峰值
    const std::vector<int> &depthTrace() const { return depthTrace_; }  // 每指令后栈深

  private:
    uint8_t readByte();                // 取操作数并推进 ip
    uint16_t readU16();
    Value pop();
    void push(Value v);
    Value &peek(int down);

    std::vector<Value> stack_;
    std::vector<Frame> frames_;
    std::ostream *out_;
    int maxFrames_ = 0;
    int maxStack_ = 0;
    std::vector<int> depthTrace_;
    bool trace_ = false;
};

}  // namespace tip

#endif  // TIP_VM_HPP
```

```cpp
// file: src/vm.cpp
// file: src/vm.cpp
#include "vm.hpp"

#include <stdexcept>

namespace tip {

static constexpr int kStackMax = 256;   // 值栈上限（匠书 STACK_MAX）
static constexpr int kFramesMax = 64;   // 帧上限（栈溢出保护，§24.1）

void VM::push(Value v) {
    if (int(stack_.size()) >= kStackMax) throw VmError{"值栈溢出"};
    stack_.push_back(std::move(v));
    if (int(stack_.size()) > maxStack_) maxStack_ = int(stack_.size());
}

Value VM::pop() {
    if (stack_.empty()) throw VmError{"值栈下溢（指令序列有错）"};
    Value v = std::move(stack_.back());
    stack_.pop_back();
    return v;
}

Value &VM::peek(int down) {
    if (down >= int(stack_.size())) throw VmError{"值栈下溢（peek）"};
    return stack_[stack_.size() - 1 - size_t(down)];
}

uint8_t VM::readByte() {
    Frame &f = frames_.back();
    if (f.ip >= f.fn->code->code.size()) throw VmError{"指令指针越界"};
    return f.fn->code->code[f.ip++];
}

uint16_t VM::readU16() {
    uint16_t hi = readByte();
    uint16_t lo = readByte();
    return uint16_t(hi << 8 | lo);
}

Value VM::run(const std::shared_ptr<ObjFn> &fn) {
    stack_.clear();
    frames_.clear();
    maxFrames_ = maxStack_ = 0;
    depthTrace_.clear();

    // 脚本帧：把函数值压栈再建帧——槽 0 被被调函数自己占位（clox 同款，
    // 后续脚本级"局部槽 0 保留"贯穿第 55 章）
    push(Value::ref(fn));
    frames_.push_back(Frame{fn.get(), 0, 0});
    maxFrames_ = 1;

    for (;;) {
        Frame &f = frames_.back();
        if (f.ip >= f.fn->code->code.size()) throw VmError{"代码耗尽未遇 RETURN"};
        Op op = static_cast<Op>(f.fn->code->code[f.ip++]);
        switch (op) {
            case Op::Constant: {
                uint8_t k = readByte();
                push(f.fn->code->consts[k]);
                break;
            }
            case Op::Add: case Op::Sub: case Op::Mul:
            case Op::Div: case Op::Gt: case Op::Eq: {
                Value b = pop(), a = pop();
                if (a.isObj() || b.isObj()) throw VmError{"算术遇非整数"};
                long long r = 0;
                switch (op) {
                    case Op::Add: r = a.i + b.i; break;
                    case Op::Sub: r = a.i - b.i; break;
                    case Op::Mul: r = a.i * b.i; break;
                    case Op::Div:
                        if (b.i == 0) throw VmError{"除零"};
                        r = a.i / b.i; break;
                    case Op::Gt: r = a.i > b.i ? 1 : 0; break;
                    default: r = a.i == b.i ? 1 : 0; break;
                }
                push(Value::num(r));
                break;
            }
            case Op::Negate: {
                Value a = pop();
                if (a.isObj()) throw VmError{"负号遇非整数"};
                push(Value::num(-a.i));
                break;
            }
            case Op::Print: {
                Value a = pop();
                *out_ << (a.isObj() ? showValue(a) : std::to_string(a.i)) << "\n";
                break;
            }
            case Op::Pop:
                pop();
                break;
            case Op::GetLocal: {
                uint8_t slot = readByte();
                push(stack_[frames_.back().base + slot]);
                break;
            }
            case Op::SetLocal: {
                uint8_t slot = readByte();
                stack_[frames_.back().base + slot] = peek(0);  // 不弹：赋值表达式有值
                break;
            }
            case Op::JumpIfFalse: {
                uint16_t off = readU16();
                Value c = pop();  // 条件被消费
                if (!c.isObj() && c.i == 0) frames_.back().ip += off;
                break;
            }
            case Op::Jump:
                frames_.back().ip += readU16();
                break;
            case Op::Loop:
                frames_.back().ip -= readU16();
                break;
            case Op::Call: {
                uint8_t argc = readByte();
                Value callee = peek(argc);  // 被调者在实参之下
                if (!callee.isObj()) throw VmError{"被调者不是函数"};
                if (auto *native = dynamic_cast<ObjNative *>(callee.obj.get())) {
                    // 原生旁路：C++ 直调，不建帧（§24.4）。
                    // 实参按入栈序取（左实参在前），随后连被调者一起让位给返回值。
                    if (int(argc) != native->arity)
                        throw VmError{"native 元数不符"};
                    std::vector<Value> args(stack_.end() - argc, stack_.end());
                    stack_.resize(stack_.size() - size_t(argc) - 1);
                    push(native->fn(std::move(args)));
                    break;
                }
                auto *target = dynamic_cast<ObjFn *>(callee.obj.get());
                if (!target) throw VmError{"被调者不可调用"};
                if (int(argc) != target->arity)
                    throw VmError{"元数不符：" + target->name};
                if (int(frames_.size()) >= kFramesMax)
                    throw VmError{"帧栈溢出（递归过深）"};
                frames_.push_back(Frame{target, 0, stack_.size() - argc - 1});
                if (int(frames_.size()) > maxFrames_) maxFrames_ = int(frames_.size());
                break;
            }
            case Op::CloseUpvalue:
                // 第 57 章启用（Op 枚举冻结位）：本章手编语料不出现
                throw VmError{"CLOSE_UPVALUE 未启用（第 57 章）"};
            case Op::Return: {
                Value result = pop();
                size_t base = frames_.back().base;
                frames_.pop_back();
                if (frames_.empty()) return result;  // 脚本帧返回：run 结束
                stack_.resize(base);                 // 弹掉本帧全部槽位
                push(result);                        // 返回值落在被调者位置
                break;
            }
        }
        if (trace_) depthTrace_.push_back(int(stack_.size()));
    }
}

}  // namespace tip
```

VM 的全部形态：一个值栈 `stack_`、一个帧栈 `frames_`、一个
`out_` 指针（输出重定向，第 13 章同款协议），加上三个结构账
（maxFrames/maxStack/depthTrace——供断言，§54.7）。大循环的骨架：

```text
for (;;) {
    op = code[ip++];        // FETCH（顺带 DECODE）
    switch (op) { … }       // EXECUTE
}
```

骨架之下有三处实现细节值得读慢。**其一，`Frame &f = frames_.back()`
每轮重取**——不是缓存在循环外：Call/Return 会增删帧，引用随时
失效，每轮开头重绑是唯一安全的写法（真实引擎为此把当前帧缓存进
局部变量并在 Call/Return 处手动换装——快但要小心，教学取永远正确
的版本）。**其二，操作数读取走成员函数 `readByte/readU16`**——
它们内部也用 `frames_.back()`，于是"ip 属于哪个帧"的知识只住在
这两个函数里；若 case 里直接写下标算术，57 章给帧加字段时处处
要改。**其三，循环退出只有一条路**——脚本帧的 Return（`frames_
empty() return result`）：没有"跑完退出"（代码耗尽是错误，防御位
会抓），**正常终止与错误终止一眼可辨**，驱动层的 try/catch 与
返回值各自干净。

没有递归、没有虚分派、没有 AST 节点——**执行一个操作的全部开销
是一次数组读、一次 switch 跳转、一两条栈操作**。与第 13 章树遍历
的"每节点一次 dynamic_cast 链 + 递归调用"对照，这就是"编译一次、
执行 N 次"在微观上的兑现。匠书 §15.2 的原话：虚拟机的核心就是
"an infinite loop and a switch statement"。

**栈式求值的规则一句话：操作数隐式在栈顶，后缀序即求值序。**
`-(3+4)*2` 的字节码是 `3 4 ADD NEG 2 MUL`——正是第 9 章说过的
后缀（逆波兰）序；`ADD` 不需要知道操作数在哪，弹二压一即可。把
九条指令的栈账逐格列出（f = 脚本帧槽 0，常驻）：

| 指令 | 执行后栈（左底右顶） | 深度 |
|---|---|---|
| CONSTANT 3 | f, 3 | 2 |
| CONSTANT 4 | f, 3, 4 | 3 |
| ADD | f, 7 | 2 |
| NEGATE | f, -7 | 2 |
| CONSTANT 2 | f, -7, 2 | 3 |
| MUL | f, -14 | 2 |
| PRINT | f（打印并弹） | 1 |
| CONSTANT 0 | f, 0 | 2 |
| RETURN | （弹 0 返回，run 结束） | — |

这八行就是驱动第三组的"手推数组"（depthTrace 逐项对账 `{2,3,2,2,3,
2,1,2}`）。**栈深账是栈机的血流图**：每条指令对深度的净效应是一
个常量（+1/-1/-2+1/0），整段代码的峰值深度在编译期就可静态算出
——这个事实是第 55 章"槽位编译期分配"与真实引擎"栈帧大小静态
确定"的共同根基。

把十八个 case 的栈效应排成总表（0 表示不变；"读"指隐式读栈顶
若干、"写"指压入）：

| 指令 | 读 | 写 | 深度净效应 | 防御 |
|---|---|---|---|---|
| CONSTANT | 0 | 1 | +1 | 索引查池（编译期保证） |
| ADD/…/EQ | 2 | 1 | −1 | 两操作数非对象 |
| NEGATE | 1 | 1 | 0 | 非对象 |
| PRINT | 1 | 0 | −1 | 对象打印 showValue |
| POP | 1 | 0 | −1 | 下溢查 |
| GET_LOCAL | 0 | 1 | +1 | 槽号在帧内（编译期） |
| SET_LOCAL | 0(读1) | 0 | 0 | peek 下溢查 |
| JUMP_IF_FALSE | 1 | 0 | −1 | 条件是对象按真处理 |
| JUMP / LOOP | 0 | 0 | 0 | 越界由循环头兜 |
| CALL | argc+1 | 1(返回值) | −argc | 元数/类型/帧深 |
| RETURN | 1 | 1(调用方) | 帧清空 | 帧空即结束 |

表读完应能回答两个检验性问题：为什么 SET_LOCAL 是 0 而不是 −1？
（赋值表达式有值，栈顶保留——第 13 章 exec 表同款语义的字节码版。）
为什么 JUMP_IF_FALSE 是 −1？（条件是**消费品**，跳与不跳都弹——
若设计成"不弹"，每个 if 都要配一条 POP，匠书选择了消费式。）
**栈效应表是字节码设计的会计报表**——每加一条新指令（55/57 章就
要加），先填这一行，实现时照行写防御。

循环里三个防御位值得一提：**值栈溢出**（kStackMax=256，push 里查）
——教学语料碰不到，但"上限存在"本身是教学内容（无限栈是宿主递归
才有的奢侈，第 13 章的反面）；**帧栈溢出**（kFramesMax=64，Call 里
查）——深递归在这里变成一条诊断而不是进程崩溃，这是第 13 章 FAQ
"宿主栈爆炸"问题的正式回答；**代码耗尽未遇 RETURN**（循环头查
ip 越界）——手编字节码写错（跳转飞出代码区）时的兜底，**错误消息
按"最可能的作者错误"措辞**（"指令序列有错"而非"非法访问"）。

`trace_` 开关打开时，每条指令执行后记一笔栈深——匠书的
DEBUG_TRACE_EXECUTION 在每步打印整个栈，教学版记成数组（输出更
干净、可对账），用途相同：**让"看不见的栈"变成看得见的账**。

栈深账还有一个远比调试重要的身份：**可验证性**。既然每条指令的
栈效应是常量（§54.3 效应表），一段字节码在**任何输入下**的栈深
轨迹都唯一确定——JVM 的字节码验证器（class 文件装载时跑的那遍
检查）正是沿着这个事实做的**抽象解释**：不运行代码，只用效应表
推每个跳转目标处的栈深，检查"任何路径到达任何指令时栈深都恰如
声明、类型都吻合"。恶意或损坏的字节码（跳到指令中间、栈下溢、
类型错位）在**执行前**被拒——第 13 章的"求值前检查"哲学在字节码
世界的最高规格应用。教程第 31 章（数据流框架）与第 65 章（抽象
解释）讲的理论，就是这台验证器的数学内核；本章读者已经摸过它的
原材料（效应表）。

调试文化的一段实话：栈机是最"可观察"的执行模型——效应表静态
可知（本节）、栈深可逐拍记（depthTrace）、反汇编可逐字节读
（§54.2），三者合起来，**任何一次错误执行都能在纸上完整重演**。
树遍历解释器做不到这一点（递归调用图是隐式的），机器码更做不到
（乱序、缓存、优化抹平了抽象层）。教程把 54–57 章的每个语料都
做成"可纸上重演"的规模，正是吃这份可观察性红利——**学习者最该
要的不是快，是每一次跑飞都能看见它飞到哪**。

## 54.4　值：带标签联合起步版

`Value` 目前是 `Tag + long long + shared_ptr<Obj>` 的三字段结构
（§18 起步版）。两个成员里必有一个是"死重"：整数值拖着空指针、
对象值拖着零的整数。**这个浪费是故意的**——它是第 56 章 NaN 装箱
的靶子：那一章把 16 字节的带标签联合压回 8 字节（double 的静默
NaN 位模式里藏 tag 与指针），全部改动收在 Value 的构造/判断函数
族里，VM 的 switch 一行不动。本章先把"值宇宙"立起来：整数与对象
两类，对象派生 `ObjFn`（函数：名字 + 元数 + chunk 指针）与
`ObjNative`（原生：C++ 函数指针）。

`showValue` 的反汇编表示（`<fn fact/1>`、`<native input>`）让常量
池注释列能直接读出"这个常量是什么"——值的三种身份（运行时值、
反汇编文本、调试文本）在同一函数里收口，第 56 章加 ObjString 时
只需要在此处加一行。

值宇宙的跨章谱系摆开（教程在值上要做的事，一张表看完）：

| 章 | 值形态 | 宇宙 | 关键问题 |
|---|---|---|---|
| 13（树遍历） | Tag + int + Closure | 整数 + 闭包 | 环境链共享 |
| 54（本章） | Tag + int + Obj* | 整数 + 函数对象 | 帧与槽位 |
| 56 | uint64_t（NaN 装箱） | 数/布尔/空/串/对象 | 表示的内存账 |
| 57 | 本章 + 捕获盒 | + 上值 | 逃逸后的家 |

四行宇宙几乎不变、形态三次换代——**语义由语料对账统一，表示各章
自便**（第 13 章接口纪律的值层版）。读者若在别的项目里选值表示，
这张表的问法可以直接搬走：宇宙里有什么（决定 Tag 集）、谁最热
（决定表示的主位）、可变不可变（决定共享还是拷贝）。

函数值持有 `shared_ptr<Chunk>` 而不是裸指针——**代码的生存期跟着
最后一个引用走**（递归函数 fact 的常量池里有指向自己的引用，第
55 章的脚本常量池里可能有指向多个函数的引用）。这与第 13 章
Environment 用 shared_ptr 的理由同构：**闭包/引用让生存期脱离
调用栈**。第 20 章的 GC 接管这层所有权的下游（谁没用了谁来收）。

ObjFn 与 ObjNative 的字段清单各自够用且止于够用：函数要"名字 +
元数 + chunk"（名字给反汇编与错误消息、元数给 Call 检查、chunk
给执行）；原生要"名字 + 元数 + 函数指针"（前两件同款理由，第三件
是宿主入口）。两者**不共享基类字段**（除 Obj 的虚析构）——没有
造一个"共同函数接口"的 abstract Callable，因为分派点只有 Call
一处、dynamic_cast 链两条就够；等 57 章加闭包（ObjClosure：捕获
表 + 指回 ObjFn）时这条链长到三条，仍然不需要抽象基类。**等分派
点真的多了再抽象**——三条 cast 换一个基类，那是练习 8 的思考题
方向。

## 54.5　调用帧：Call/Return 的六步序列

`Frame` 只有三个字段：`fn`（在执行哪个函数体）、`ip`（执行到哪个
字节）、`base`（本帧的局部槽从值栈哪里开始）。**帧 = 函数调用的
全部现场**——三个字段复原一切，这是栈机优雅的顶点。匠书 §24.1
把 clox 的 CallFrame 直接嵌进 VM 的数组 `frames[FRAMES_MAX]`，本章
用 `std::vector<Frame>`（同理）。

Call 指令的约定（55 章编译器按此发码，本章 fact 手编已示范）：
**被调者先压栈、实参紧随其上、操作数记实参数**。执行序列六步：

1. 读操作数 argc；`peek(argc)` 取到被调者（在实参之下）；
2. 类型检查（不是函数 → 错；元数不符 → 错，**运行时兜底**——第 13
   章 V3/R1 分界线在字节码世界的同款）；
3. 建帧：`base = stack.size() - argc - 1`——**正好指向被调者自己**；
4. （被调函数体执行……局部槽 base+1.. 是实参、base+2.. 是局部
   变量——55 章的槽位约定在此成形）；
5. Return：弹出返回值、`stack_.resize(base)`（**整帧连人带槽清空**）、
   帧出栈；
6. 返回值压在 base 位置——恰是"被调者的位置"，调用者视角里
   "函数值变成了返回值"，无缝。

六步配一张调用前后的值栈图（fact(5) 的最外层调用为例）：

```text
Call 执行前：[scriptFn] [factFn] [5]        ← 脚本帧段 + 被调者 + 实参
                          ↑ peek(1) 取到被调者
Call 执行后：[scriptFn] [factFn] [5]        ← 同一段，但新帧 base 指向 factFn
              脚本帧挂起     新帧（槽1 = 实参 n=5）
…fact 体执行（GetLocal 1 读的正是 5）…
Return 后：  [scriptFn] [120]               ← 整帧段清空，返回值落被调者位
```

图的要点有三。**调用不改值栈布局**——Call 只压了一个 Frame 结构
（fn/ip/base 三字段），值栈一个元素都不动：实参"变成"新帧的槽位
纯粹因为 base 划线划在那里，**零拷贝传参**。**返回是 resize 不是
逐个弹**——`stack_.resize(base)` 一次清段，无论帧里有多少槽；
清完 push(result)，被调者位换成返回值，调用者的栈深净变化 −argc
（弹掉实参，函数值换返回值）。**挂起与恢复不需要保存任何额外
现场**——脚本帧的 ip 停在 Call 后面那条指令，新帧 Return 后
`frames_.back()` 自动变回脚本帧，循环下一轮取指就从那里继续：
**帧栈本身就是"断点寄存器栈"**，协程、生成器、异常展开都建在这
个结构上（第 57 章的逃逸闭包会挑战"帧没了"这个前提——正是上值
的起点）。

**base 指向被调者的巧思**（clox 同款）：局部槽从 base+1 起编号，
槽 0 被"函数自己"占位。看似浪费一格，实则解决了两个问题：其一，
GetLocal 的槽号在**编译期**就是纯静态算术（声明序号），不需要为
"实参与局部变量分属两段"做特判；其二，脚本帧（第 55 章）自己的
槽 0 恰好放脚本函数值，**帧内协议从脚本到函数完全统一**。一格里
放两重身份（被调者占位 + 返回值落点），是"数据布局消灭特判"的
教科书案例。

把这一格的三重身份排开更清楚：**调用瞬间**它是被调者（Call 靠它
定位类型与元数）；**执行期间**它是占位（槽号从 1 起的静态约定的
锚点）；**返回瞬间**它是返回值落点（resize 后 push 的位置）。三个
阶段三个身份、零搬移——若 base 指向实参首格（另一派设计），调用
时被调者要从栈上"摘出来"另存帧里，返回时返回值要找地方放：两次
搬移换一格"看起来不浪费"的整齐。**字节码设计里最常见的权衡就是
这种"一格多用 vs 格格分明"**——clox 选前者（省指令），某些教学
VM 选后者（省解释），都对，账不同。

**fact(5) 的帧账**：脚本帧（槽 0 = script 函数）→ Call 压 fact 帧
（n=5）→ …递归到 n=0 → 逐层 Return。帧深峰值 = 1（脚本）+ 6
（fact 5..0）= 7——驱动的断言。取三个时刻给帧栈拍快照（值栈只画
相关段）：

| 时刻 | 帧栈（顶在右） | 值栈快照 |
|---|---|---|
| 深入到 n=3 | script, fact(5), fact(4), fact(3) | …[f3][f4,3][f5,4,5]（每帧=被调者+实参） |
| 谷底 n=0 | script, fact(5..0) 共 7 帧 | 递归链每帧占 2 格（函数+参数） |
| 回弹到 n=5 返回 | script | [script, 120]（返回值落在被调者位） |

快照第二列能看见"帧"与"值栈段"的对应：**每个帧占值栈一段连续
槽位，段的起点就是 base**。与第 19 章活动记录的正式对照：

| | 19 章活动记录（编译式） | 本章调用帧（解释式） |
|---|---|---|
| 帧的位置 | 进程栈（call 指令硬件压栈） | VM 自己的 frames 数组 |
| 帧的大小 | 编译期定死（slotCount 写进帧布局） | 执行期由值栈切分 |
| 局部寻址 | 帧指针 + 常量偏移（机器指令） | base + 槽号（GetLocal 指令） |
| 跨帧访问 | 访问链/display（嵌套函数） | 本章无嵌套；57 章上值 |
| 溢出保护 | 操作系统栈保护页 | kFramesMax 显式检查 |

两列在 57 章前不会相遇（TIP 无嵌套函数时跨帧访问不存在），相遇时
（上值）第 19 章的"访问链在栈上"失效——帧是解释式数组、随时会被
清空，上值必须把"跨帧的家"搬到堆上。**先有栈机的帧，才懂堆上的
上值为什么非搬不可**——这是 54→57 章伏笔（伏笔表第 10 行）的完整
读法。fib(10)
的调用树更宽（177 次调用）但**帧深只由最深的链决定**（峰值 11）——
"调用次数与帧深无关、帧深只看链长"是调用栈语义的核心直觉，第
19 章活动记录与第 65 章尾调用话题都会回来对账。

给帧账配一条**内存画像**：每帧占值栈格数 = 1（被调者占位）+
arity（实参）+ 局部变量数——fact 是 1+1+0 = 2 格，七帧峰值就是
脚本 1 格 + 6×2 = 13 格。这条画像在 55 章升级成**帧预算**：编译器
为每个函数静态算出 slotCount，Call 时检查 `栈余量 ≥ slotCount`
——值栈上限从"全局 256 粗查"细化成"按帧精确记账"。内存画像的
一般式（**峰值 = Σ 最深链上每帧格数**）在手编任何递归前先算一遍，
是"纸上跑通再动手"传统的栈机版。

Return 一词在本章有两种含义值得分清：**字节码指令 RETURN**（帧退
出协议）与 **C++ 函数 `VM::run` 的 return**（驱动拿到脚本返回值）。
前者执行几十次（每次函数调用一次），后者恰好一次（脚本帧退出时
`frames_.empty()` 分支）——**指令的 Return 是协议步骤，run 的
return 是协议终点**。55 章的"每个函数体末尾必发 RETURN"规则建立
在前者上；驱动断言"脚本返回值"消费的是后者。名字撞车但层级分明，
读代码时留意 switch 里的 case 与函数末尾的 return 各归其主。

**原生函数旁路**（§24.4）：`input` 桩是 `ObjNative`——Call 发现
被调者是原生时，**不建帧**：直接收集实参、调 C++ 函数、压回返回
值。旁路的意义：宿主能力（时钟、IO、数学库）进入语言不需要字节
码化；匠书用 `clock()` 给 Lox 做基准测试正是走这条路。旁路与正路
的**分界写在 Call 的 dynamic_cast 链里**——"是不是 ObjFn"一个
问题决定走哪条路，第 56 章加 ObjString 后这条链再加一员。

两条路的成本对照摆开（原生 vs 字节码函数）：

| | ObjFn（正路） | ObjNative（旁路） |
|---|---|---|
| 帧开销 | 建帧 + 基址重定位 | 无 |
| 实参去向 | 留栈上成为槽位 | 拷进 vector 传给 C++ |
| 返回 | Return 指令清帧压值 | 调用即返回，直接 push |
| 元数检查 | Call 处查 | Call 处查（同一处！） |

最后一行是设计的小亮点：**元数检查不分家**——无论走哪条路，
"实参数对不对"都在 Call 一个地方问。若旁路自带一套检查，55 章
的编译器就要面对"两套调用协议"的分裂——把公共判断留在分岔点
**之前**，分岔后各自只做"怎么执行"的差异部分。这个原则（分岔点
后置）在第 55 章的编译器里还会出现（表达式与语句的公共发码路径）。

## 54.6　与第 16 章 TAC 寄存器机对照

第 16 章的三地址码是**寄存器机**（更准确说：临时变量机）——每条
指令的操作数是显式名字（`t3 = t1 + t2`）；本章字节码是**栈机**——
操作数隐式在栈顶（`ADD`）。同一表达式两边的对照：

| | TAC（第 16 章） | 字节码（本章） |
|---|---|---|
| 操作数定位 | 名字查表 | 栈顶偏移 |
| 指令密度 | 一条管一件事，名字重复出现 | 短（无名字），密度高 |
| 求值顺序 | 写在临时变量的数据依赖里 | 写在指令序（后缀序）里 |
| 局部变量 | 名字空间（符号表） | 帧基 + 槽号 |
| 跳转目标 | 基本块编号 | 字节地址 |
| 解释开销 | 每条查一次名字表 | 每条几次栈操作 |
| 翻译到机器码 | 每个名字要分寄存器（第 58 章） | 逆波兰直译栈机（push/pop） |

表逐行讲评。**操作数定位行**是两种 IR 的定义性差异：TAC 的名字要
查符号表（或哈希表）才能落到位置，字节码根本无名字；这条差异向
下贯穿一切——**指令密度行**（TAC 的 `t3 = t1 + t2` 十来个字符、
字节码 ADD 一字节）、**求值顺序行**（TAC 靠依赖隐含顺序、可重排
（第 61 章 ILP 的原料），字节码序即序、重排要改代码）、**跳转行**
（块号给人读、字节地址给机器跳）。最后两行是各自的下游：TAC 的
名字在寄存器分配（第 58 章）时"物归原主"，字节码的栈操作在 JIT
时直接映射到物理栈或寄存器对。**没有一行分胜负，每行都在说
"给谁用"**。

两条路线没有胜负：TAC 为**分析与优化**而生（名字稳定、依赖显式、
基本块天然），字节码为**紧凑与快执行**而生（指令短、解码简、
可移植）。真实编译器常常两者都要——先把高层 IR 优化完，再降成
字节码或机器码（JVM 的 C1/C2、V8 的 Ignition/TurboFan 都是"优化
IR + 快执行字节码"的双层）。教程也两者都要：第 16 章喂分析（第
25 章起全用 TAC/CFG），本章喂执行（第 55–57 章的编译线）——
**IR 的选择跟着消费者走**，这句话在第 13 章 FAQ 里出现过，这里
是它最重要的一次应用。

双层结构的 tiering 细节值得展开半页，因为它是"本章 + 教程第十篇"
在工业界的完整形态。以 V8 为例：Ignition（字节码解释器，本章的
放大版）先跑一切；某函数热了（调用计数超阈），TurboFan 把字节码
连同**类型反馈**（Ignition 顺手记录的"这个加法实际见过什么类型"）
编译成机器码；中途类型假设破了就**去优化**（deopt）回字节码重跑。
三层形态各司其职：字节码保启动速度与内存紧凑，机器码保峰值吞吐，
反馈保"优化不盲猜"。教程对应关系：本章 = Ignition 的骨架；第
55–57 章 = 生成字节码的前端；第 58 章及以后的代码生成篇 = 向
机器码层交棒。**读者手里的三百行 VM，就是那台万亿瓦引擎的第一
块积木**——这不是修辞，Ignition 的解释器循环与本章的 switch 骨架
同型，只是每个 case 背后多几条记账。

栈机的家谱也值得三行：逆波兰记法（Łukasiewicz 1920s）→ Forth
（1960s，程序员手写后缀）→ PostScript（1982，打印机里的栈机）→
JVM（1995，验证器让"传送字节码"变得安全）→ JavaScriptCore/
Ignition/Lua VM（当代）。家谱的共同主题是**后缀序免语法分析**：
栈机执行不需要任何"分析"——顺序读字节即可，这在"代码要被不可信
信道传输"（打印机、浏览器、applet）的场景里是决定性优点。读者在
第 5 章（正则）见过"自动机免回溯"，此处再见"免分析"——**把困难
前移到编译期**是整个编译领域的母题。

## 54.7　驱动、语料与期望输出解读

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 54 章驱动（无参运行，简单程序对账协议）：
//   一、反汇编即文档：手编 chunk 的反汇编文本逐行对账；
//   二、栈式求值：-(3+4)*2 与手算对账；
//   三、每指令栈深账：depthTrace 与手推数组逐项对账；
//   四、调用帧：fact(5) 帧深峰值 = 脚本 + 6 层递归 = 7；fib(10) 同型；
//   五、原生函数旁路：input 桩（恒 0）经 Call 调用；
//   六、断言汇总。
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "chunk.hpp"
#include "vm.hpp"

namespace {

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

std::shared_ptr<tip::ObjFn> makeFn(std::string name, int arity) {
    auto f = std::make_shared<tip::ObjFn>();
    f->name = std::move(name);
    f->arity = arity;
    f->code = std::make_shared<tip::Chunk>();
    return f;
}

// 便捷发码小链
struct Emit {
    tip::Chunk *c;
    Emit &op(tip::Op o, int line) { c->write(o, line); return *this; }
    Emit &byte(uint8_t b, int line) { c->writeByte(b, line); return *this; }
    Emit &u16(uint16_t x, int line) { c->writeU16(x, line); return *this; }
    Emit &konst(const tip::Value &v, int line) {
        c->write(tip::Op::Constant, line);
        c->writeByte(uint8_t(c->addConstant(v)), line);
        return *this;
    }
};

}  // namespace

int main() {
    // ---------- 程序一：-(3+4)*2 ----------
    // 栈账（脚本帧槽 0 = 脚本函数自己，常驻）：
    //   C3 [f,3] C4 [f,3,4] ADD [f,7] NEG [f,-7] C2 [f,-7,2] MUL [f,-14]
    //   PRINT（打印并弹）[f] C0 [f,0] RETURN（弹 0 返回）
    auto expr = makeFn("expr", 0);
    {
        Emit e{expr->code.get()};
        e.konst(tip::Value::num(3), 1);     // 0000
        e.konst(tip::Value::num(4), 1);     // 0002
        e.op(tip::Op::Add, 1);              // 0004
        e.op(tip::Op::Negate, 1);           // 0005
        e.konst(tip::Value::num(2), 1);     // 0006
        e.op(tip::Op::Mul, 1);              // 0008
        e.op(tip::Op::Print, 1);            // 0009
        e.konst(tip::Value::num(0), 1);     // 0010（脚本返回值占位）
        e.op(tip::Op::Return, 1);           // 0012
    }

    std::cout << "== 一、反汇编即文档 ==\n";
    {
        std::ostringstream os;
        tip::disassembleChunk(*expr->code, "expr", os);
        std::cout << os.str();
        std::string want =
            "== expr ==\n"
            "0000   1 CONSTANT 0  ; 3\n"
            "0002    | CONSTANT 1  ; 4\n"
            "0004    | ADD\n"
            "0005    | NEGATE\n"
            "0006    | CONSTANT 2  ; 2\n"
            "0008    | MUL\n"
            "0009    | PRINT\n"
            "0010    | CONSTANT 3  ; 0\n"
            "0012    | RETURN\n";
        check("反汇编逐行", os.str(), want);
    }

    std::cout << "\n== 二、栈式求值 ==\n";
    {
        std::ostringstream os;
        tip::VM vm(os);
        tip::Value r = vm.run(expr);
        check("-(3+4)*2", os.str(), "-14\n");
        check("脚本返回值", std::to_string(r.i), "0");
    }

    std::cout << "\n== 三、每指令栈深账 ==\n";
    {
        std::ostringstream os;
        tip::VM vm(os);
        vm.setTrace(true);
        vm.run(expr);
        // 手推（每条指令执行"后"的栈深；脚本帧槽 0 常驻计 1）：
        std::vector<int> want{2, 3, 2, 2, 3, 2, 1, 2};
        std::vector<int> got = vm.depthTrace();
        std::string gs, ws;
        for (int d : got) gs += std::to_string(d) + " ";
        for (int d : want) ws += std::to_string(d) + " ";
        check("栈深轨迹", gs, ws);
    }

    std::cout << "\n== 四、调用帧 ==\n";
    // fact(n) = n==0 ? 1 : n*fact(n-1)
    // 帧内槽位：base+0 = 被调函数值（clox 占位），实参 n 在 base+1。
    // 布局（偏移以字节计；JumpIfFalse/Jump 的操作数 = 目标地址 - 下一指令地址）：
    //   0000 GetLocal 1        n
    //   0002 Constant 0        0
    //   0004 Eq                n==0
    //   0005 JumpIfFalse ->13  假：走递归支（13-8=5）
    //   0008 Constant 1        1
    //   0010 Jump ->25         汇合到 Return 前（25-13=12）
    //   0013 Constant fact     被调者
    //   0015 GetLocal 1        n
    //   0017 Constant 1        1
    //   0019 Sub               n-1
    //   0020 Call 1            fact(n-1)
    //   0022 GetLocal 1        n
    //   0024 Mul               n*fact(n-1)
    //   0025 Return            栈上恰一个结果
    auto fact = makeFn("fact", 1);
    {
        Emit e{fact->code.get()};
        e.op(tip::Op::GetLocal, 2), e.byte(1, 2);
        e.konst(tip::Value::num(0), 2);
        e.op(tip::Op::Eq, 2);
        e.op(tip::Op::JumpIfFalse, 2), e.u16(5, 2);
        e.konst(tip::Value::num(1), 3);
        e.op(tip::Op::Jump, 3), e.u16(12, 3);
        e.konst(tip::Value::ref(fact), 4);
        e.op(tip::Op::GetLocal, 4), e.byte(1, 4);
        e.konst(tip::Value::num(1), 4);
        e.op(tip::Op::Sub, 4);
        e.op(tip::Op::Call, 4), e.byte(1, 4);
        e.op(tip::Op::GetLocal, 5), e.byte(1, 5);
        e.op(tip::Op::Mul, 5);
        e.op(tip::Op::Return, 6);
    }
    {
        auto script = makeFn("script", 0);
        Emit e{script->code.get()};
        e.konst(tip::Value::ref(fact), 8);
        e.konst(tip::Value::num(5), 8);
        e.op(tip::Op::Call, 8), e.byte(1, 8);
        e.op(tip::Op::Print, 8);
        e.konst(tip::Value::num(0), 8);
        e.op(tip::Op::Return, 8);

        std::ostringstream os;
        tip::VM vm(os);
        tip::Value r = vm.run(script);
        check("fact(5)", os.str(), "120\n");
        check("帧深峰值（脚本 + 6 层递归）", std::to_string(vm.maxFrames()), "7");
        (void)r;
    }
    // fib(n) = n<2 ? n : fib(n-1)+fib(n-2)
    // 布局（Gt 弹栈序：a=先压者。要算 2>n，须先压 2 再压 n）：
    //   0000 Constant 2 / 0002 GetLocal 1 / 0004 Gt（2>n 即 n<2）
    //   0005 JumpIfFalse ->13（偏移 5）/ 0008 GetLocal 1（n）
    //   0010 Jump ->32（偏移 19，越过递归支直达 Return）
    //   0013.. 递归支：fib(n-1)、fib(n-2)、Add
    //   0031 Add / 0032 Return
    auto fib = makeFn("fib", 1);
    {
        Emit e{fib->code.get()};
        e.konst(tip::Value::num(2), 2);              // 0000
        e.op(tip::Op::GetLocal, 2), e.byte(1, 2);    // 0002
        e.op(tip::Op::Gt, 2);                        // 0004
        e.op(tip::Op::JumpIfFalse, 2), e.u16(5, 2);  // 0005 -> 0013
        e.op(tip::Op::GetLocal, 3), e.byte(1, 3);    // 0008（n 即结果）
        e.op(tip::Op::Jump, 3), e.u16(19, 3);        // 0010 -> 0032
        e.konst(tip::Value::ref(fib), 4);            // 0013
        e.op(tip::Op::GetLocal, 4), e.byte(1, 4);    // 0015
        e.konst(tip::Value::num(1), 4);              // 0017
        e.op(tip::Op::Sub, 4);                       // 0019
        e.op(tip::Op::Call, 4), e.byte(1, 4);        // 0020
        e.konst(tip::Value::ref(fib), 5);            // 0022
        e.op(tip::Op::GetLocal, 5), e.byte(1, 5);    // 0024
        e.konst(tip::Value::num(2), 5);              // 0026
        e.op(tip::Op::Sub, 5);                       // 0028
        e.op(tip::Op::Call, 5), e.byte(1, 5);        // 0029
        e.op(tip::Op::Add, 5);                       // 0031
        e.op(tip::Op::Return, 6);                    // 0032
    }
    {
        auto script = makeFn("script", 0);
        Emit e{script->code.get()};
        e.konst(tip::Value::ref(fib), 9);
        e.konst(tip::Value::num(10), 9);
        e.op(tip::Op::Call, 9), e.byte(1, 9);
        e.op(tip::Op::Print, 9);
        e.konst(tip::Value::num(0), 9);
        e.op(tip::Op::Return, 9);

        std::ostringstream os;
        tip::VM vm(os);
        vm.run(script);
        check("fib(10)", os.str(), "55\n");
    }

    std::cout << "\n== 五、原生函数旁路 ==\n";
    {
        auto input = std::make_shared<tip::ObjNative>();
        input->name = "input";
        input->arity = 0;
        input->fn = [](std::vector<tip::Value>) { return tip::Value::num(0); };
        // input() + 40 + 2（桩值 0，结果 42）
        auto script = makeFn("script", 0);
        Emit e{script->code.get()};
        e.konst(tip::Value::ref(input), 10);
        e.op(tip::Op::Call, 10), e.byte(0, 10);
        e.konst(tip::Value::num(40), 10);
        e.op(tip::Op::Add, 10);
        e.konst(tip::Value::num(2), 10);
        e.op(tip::Op::Add, 10);
        e.op(tip::Op::Print, 10);
        e.konst(tip::Value::num(0), 10);
        e.op(tip::Op::Return, 10);

        std::ostringstream os;
        tip::VM vm(os);
        vm.run(script);
        check("input()+40+2", os.str(), "42\n");
    }

    std::cout << "\n== 六、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（7 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
```

语料五段、断言七项，先看考点总表（设计原则在表后）：

| 段 | 语料 | 考点 |
|---|---|---|
| 一 | expr 的反汇编 | 指令长度表、注释列、行号折叠 |
| 二 | `-(3+4)*2` = -14 | 栈式求值、PRINT 弹栈、返回占位 |
| 三 | 栈深轨迹 8 项 | 每指令净效应的手推 |
| 四 | fact(5)=120 帧深 7；fib(10)=55 | 手编跳转（JIF/J 偏移账）、帧深=链长、双递归 |
| 五 | input()+40+2=42 | 原生旁路、零参 Call |

表的三列读法：语料列是"跑什么"、考点列是"证明什么"——每段至少
两考、每考至少一段；第四段双语料（fact/fib）是因为帧深账有两种
（链式递归与树形递归），单语料锁不全。

驱动代码三件小事值得读：`Emit` 小链（op/byte/u16/konst 四个方法
把"写字节 + 记行号"的重复收进一处——手编可读性的全部需求）；
`makeFn` 工厂（名字/元数/空 chunk 三件套，fact 与 fib 各用一次、
递归自引用经 shared_ptr 自然成环）；断言的**值字符串化**（栈深
数组拼成空格分隔串再比对——容器断言的通用手法，第 13 章 R1 同
款）。本章代码的读码顺序（实现者向）：chunk.hpp → chunk.cpp 的
addConstant/disassemble → vm.hpp 的 Frame → vm.cpp 大循环（先读
Constant/Add/Return 三个 case，再读 Call/JumpIfFalse）→ main.cpp
的 fact 布局注释——每步只引入一个新概念。语料设计的两个原则照例交代。**最少段数覆盖全部机制**：五段各考
一块互不重叠的机制，没有一段是"再跑一遍类似的东西"——expr 一段
同时锁死反汇编格式与栈求值，fact 同时锁死跳转与帧账，input 锁死
旁路。**断言密度优先于语料数量**：九条指令的 expr 贡献三条断言
（反汇编、输出、栈轨迹），一条不贡献断言的语料不如不进——期望
输出文件的每一行都该有"它证明了什么"的答案。这两个原则与第
13 章"一段多证"一脉相承，是教程对账写作的通用度量衡。

两处手编细节最见功夫。**fact 的跳转偏移**：`JumpIfFalse` 的操作数
= 目标地址 − 下一指令地址（不是当前地址！）——正文布局注释里
`0005 JumpIfFalse ->13（13-8=5）` 把这笔账逐个写了出来，读者手编
时最常错的就是这里（减错了基准）。**fib 的比较方向**：Gt 弹栈后
算的是"先压者 > 后压者"，要表达 `2 > n` 必须**先压 2 再压 n**——
实现的第一版把顺序写反，fib(10) 直接返回 10（每层都走了"基础
情形"），被断言当场抓住。

fib 那个 bug 值得完整复盘一遍，因为它是"栈机思维的典型翻车"。
写 `2 > n` 时手自然抄源码顺序：先 GetLocal n、再 Constant 2——
中缀习惯。但 Gt 的语义是弹栈后 `a > b`，a 是**先压**的——于是
算成了 `n > 2`，对 n=10 恒真，每层都走"返回 n"支，输出 10。
断言红掉后，修法不是改 Gt（改语义 = 破坏所有既有指令），而是
**换压栈序**：先 Constant 2、再 GetLocal n。教训抽象一层：**栈机
的操作数序与源码序不同——源码是中缀（左操作数在左），栈机是
"弹的次序"（右操作数在顶）**。第 55 章编译器的 binary 发码回调
里有一行注释专门对应这个坑：先发左、后发右，ADD 弹序自动正确
——编译器把"序"的思考一次性做完，人就不用每次想。**手编翻过
的车，就是编译器存在的理由**——这句话是 54→55 两章之间的门轴。
复盘的元教训也值得点破：断言把"感觉不对"变成"数字不对"（输出
10 而非 55），定位从"读全部代码"缩到"这一条语料"——**对账驱动
的调试不是更快地找错，是让错误自己带地址上门**。第 55 章编译器
的开发会完全依赖这个循环：改一版、跑语料、看断言红在哪。

期望输出的读法与前两章同构：`ok 名字 = 实算值` 逐行签收，FAIL
显示期望对照，末行汇总。逐段导读：

**第一段**（九行反汇编全文 + 一行断言）是**被断言的文本**而非
装饰性打印——期望与输出逐字符相等，意味着"指令长度表 + 操作数
打印 + 注释格式"三件事被九行输出一次性锁死；行号列只有第一行是
数字（后续全 `|` 折叠），因为九条指令写在同一源码行——折叠规则
顺带被锁。**第二段**两行：-14 是栈账的终值，返回值 0 是"脚本
占位"约定的可见面。**第三段**的八格数组逐项对应正文栈账表——
每一格都是一条指令净效应的签字。**第四段**四行：120 与 55 各是
一个递归语料；帧深 7 的账 = 1 脚本 + 6 层；fib 只断言值不断言帧
深（读者练习 2/6 自己算）。**第五段**的 42 是 input 桩（0）+ 40
+ 2——旁路返回值与常量一样进栈、后续指令不辨出处的证据。

七项断言的分布：格式 1 + 求值 2 + 栈账 1 + 帧账 2 + 旁路 1——
没有一项是"重复证明已知事实"的凑数。

本章手编与第 55 章编译的分工边界，最后画一次：**凡是"结构性的
决定"（跳转目标、槽位号、常量索引、压栈序），本章已经暴露在人
眼前；55 章的编译器就是把这些决定交给机器算**——回填算跳转、
作用域表算槽位、常量池算索引、Pratt 序算压栈。读者若问"55 章有
什么新理论"，答案是：几乎没有——新的是**把本章的算术自动化**，
外加"边扫描边发码"的单遍纪律。带着这份清醒进下一章，它读起来
会快一倍。

期望输出的读法与前两章同构：`ok 名字 = 实算值` 逐行签收，FAIL
显示期望对照，末行汇总。第一段的反汇编全文是**被断言的**（不是
装饰性打印）——期望文本与输出逐字符相等，意味着"指令长度表 +
操作数打印 + 注释格式"三件事被九行输出一次性锁死。

```text
; expected: expected/output.txt
== 一、反汇编即文档 ==
== expr ==
0000   1 CONSTANT 0  ; 3
0002    | CONSTANT 1  ; 4
0004    | ADD
0005    | NEGATE
0006    | CONSTANT 2  ; 2
0008    | MUL
0009    | PRINT
0010    | CONSTANT 3  ; 0
0012    | RETURN
ok   反汇编逐行 = == expr ==
0000   1 CONSTANT 0  ; 3
0002    | CONSTANT 1  ; 4
0004    | ADD
0005    | NEGATE
0006    | CONSTANT 2  ; 2
0008    | MUL
0009    | PRINT
0010    | CONSTANT 3  ; 0
0012    | RETURN


== 二、栈式求值 ==
ok   -(3+4)*2 = -14

ok   脚本返回值 = 0

== 三、每指令栈深账 ==
ok   栈深轨迹 = 2 3 2 2 3 2 1 2 

== 四、调用帧 ==
ok   fact(5) = 120

ok   帧深峰值（脚本 + 6 层递归） = 7
ok   fib(10) = 55


== 五、原生函数旁路 ==
ok   input()+40+2 = 42


== 六、断言汇总 ==
全部通过（7 项）
```

## 54.8　FAQ、小结与练习

**问：为什么 switch 而不是函数指针表（跳转表）？** 教学可读性优先
（每个 case 一段直白代码）；性能上现代编译器会把密集枚举的 switch
编译成跳转表，与手写函数指针表差距很小，而 case 内联还能吃到
CPU 分支预测的局部性。匠书同款选择。第 55 章继续 switch。

**问：为什么值栈用 vector 而不是预分配数组？** 匠书用定长数组 +
stackTop 指针（C 风格、零分配）。教学用 vector：溢出检查逻辑相同
（size 对 kStackMax），省掉手工内存管理；性能差异在断言语料里不可
测。**表示方式服务于教学目标**——本章目标是"看懂执行模型"，
不是跑分。

**问：ip 为什么是 chunk 内偏移而不是全局指针？** 偏移 + 帧.base
让"代码位置"与"数据位置"两个坐标系分离：ip 属于 chunk，栈深属于
VM。混用（比如直接存 Value*）会让帧切换时的指针算术外露。分坐标
系的代价是 GetLocal 一点加法（base+slot）——**一次加法买坐标清白**。

**问：字节码能跨平台吗？** 本章的 chunk 在内存里就执行，不落盘，
无所谓跨平台；真实引擎落盘字节码（JVM class、Python pyc）要冻结
**格式契约**（枚举值、操作数序、常量池编码）——本章"高字节在前"
与枚举冻结就是这个契约的教学缩影。改一个枚举值 = 破坏一次兼容，
这是给"为什么 Op 枚举要冻结"的工程答案。Python 的真实教训可以
佐证：3.11 重排了字节码（自适应解释器），pyc 直接不兼容旧版——
连"魔法数 + 版本号"的防御机制都成了必需品；JVM 则三十年不敢动
一条指令的编号（新特性走 CONSTANT 动态那类常量池扩展）。**格式
契约的刚性，是"简单接口冻结越久越值钱"的极端案例**。

**问：CloseUpvalue 为什么本章就占枚举位？** 三个示例共享一套 Op
编号：55 章复制本章 VM 加指令，57 章再复制再加。若 57 章才插入
枚举，前面章的反汇编文本会因枚举值移位而漂移。**提前占位 = 三章
的字节码文本稳定**——与"冻结接口"同一条纪律的具体应用。

**问：CONSTANT 的常量可以是函数、函数的 chunk 里又有常量——递归
引用会不会让反汇编死循环？** 不会。disassembleChunk 只走 code 不
递归进常量池（常量注释列只打 showValue 的单行表示），**chunk 之间
的引用图是运行期的（Call 时走）、不是反汇编期的**——工具的遍历
范围决定它看到图还是看到树。若要"全程序反汇编"（每个函数各打一
份），外层驱动按函数表枚举即可（本章驱动打了两份：expr 一份、
fact/fib 由断言隐式覆盖）。

**问：为什么不把 main.cpp 里的 Emit 工具放进库？** 手编驱动专用的
糖。55 章的编译器有自己的发码接口（带回填、带作用域表），Emit 的
四个方法只覆盖"顺序写"——把它抽进 chunk.hpp 会诱导两章共用一个
不够用的接口。**工具跟着使用者住**（main.cpp 匿名命名空间），
等两章的真实需求重合了再上提——"上提时机看第二用户出现"是教程
代码组织的家规，第 13 章的 SymCheck/Interpreter 分离同款。

**问：VM 的错误为什么又用异常了（第 13 章不是讨论过出参吗）？**
第 13 章的结论是"嵌套深才需要异常"；本章的"嵌套"不是递归调用而
是**帧深**——一个 while 循环跑十万次迭代，错误发生在第 99999 次，
从大循环深处传到驱动层。大循环自己不递归，但错误跨越的"轮次"
同样任意远。异常在这里的另一个好处：**防御位不污染热路径**——
switch 的 case 里一行 throw，正常轮次零开销（C++ 异常的零成本
模型）。出参方案则要求每轮循环后查一次返回码，热路径上永久多
一次分支。

**问：PRINT 直接写 ostream，是不是把 IO 焊死在 VM 里了？** 是——
教学取舍。工业做法是 IO 走原生函数旁路（§54.5），PRINT 指令根本
不存在（jlox 的 print 是语句、clox 连语句都不印——clox 用
nativePrint）。本章保留 PRINT 指令是为了让最小语料（expr）不经
原生机制就能出值；55 章的 output 语句编译成 PRINT，读者可自行
改造成"编译 output → Call nativePrint"的对照练习，体会**指令 vs
原生**两种 IO 挂载的取舍。

**问：kFramesMax 为什么是 64？** 匠书 FRAMES_MAX 同数——够 Lox
的教学递归（fib(24) 级别）。真实引擎的帧上限是**内存预算除以帧
大小**，Lua 级别的小帧可以到几十万帧。教学值的选择标准是"语料
最深 + 余量"：本章 fib(10) 峰值 11，64 是六倍余量。练习 9 会让你
亲手把它改爆一次——**上限的意义在被触到的那一刻才具体**。

**问：值栈溢出上限 256 太小了吧？** 是教学值（匠书 STACK_MAX 同
数）。真实的考虑维度是"一次表达式求值最多同时在栈上多少值"——
编译器（55 章）**静态知道**每段代码的峰值栈深，所以引擎可以按
帧预算栈空间（帧头记 slotCount，进帧时检查余量）。本章手编没有
帧预算信息，全局 256 是最粗粒度的保护。55 章加帧预算后这个上限
就变成了"每帧可声明、总量可控制"的账——又是"静态信息换取运行
时精确"的一课。

**小结**：字节码 VM = chunk（字节流+常量池+行号表）+ 反汇编 +
大循环（一个 switch）+ 调用帧（三字段）。栈效应表给出十八指令的
会计报表、调用快照给出帧栈与值栈的对应、内存画像给出帧预算的
雏形——本章的"账本三件套"与值/输出并列成为断言对象，供后两章
扩展时逐项复验。栈式求值的全部规则是
"操作数在栈顶、后缀序即求值序"；调用的全部序列是"压被调者与实参
→ 建帧（base 指被调者）→ 执行 → Return 清帧压回返回值"。帧深只看
链长；值宇宙的浪费（带标签联合）是 56 章的靶子；与 TAC 的分工是
"分析要名字、执行要紧凑"。两个手编坑（跳转基准、Gt 压栈序）是
第 55 章编译器存在的全部理由。

三句话带走：**代码就是字节数组、ip 就是下标；操作数在栈顶、后缀
序即求值序；帧 = fn + ip + base 三字段，base 指被调者**。54–57 章
的一切展开都悬在这三句上。

与匠书原章的映射（拿原书对照阅读的读者用）：§14.1–14.3 → §54.1；
§14.4（反汇编）→ §54.2；§15.2–15.4 → §54.3；§15.5（错误处理）
→ §54.3 防御位三段；§18.1 → §54.4；§24.1–24.3 → §54.5；§24.4
（native clock）→ §54.5 旁路表。差异处：clox 的值从 double 起步
（Lox 是动态类型）、本章从 int64 起步（TIP 整数宇宙）——§54.4
谱系表标注了这条分岔的走向。

**术语表**：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| chunk | 操作码流+常量池+行号的代码容器 | §54.1 |
| 常量池 | 值的表，字节流只放索引（去重） | §54.1 |
| ip | 指令指针：chunk 内字节偏移 | §54.3 |
| 帧基 base | 本帧槽 0 在值栈上的下标（指被调者） | §54.5 |
| 后缀序 | 求值序即指令序（逆波兰） | §54.3 |
| 栈深账 | 每指令净效应与峰值的静态可算性 | §54.3 |
| 栈效应表 | 十八指令的读/写/防御会计报表 | §54.3 |
| 原生旁路 | ObjNative 不建帧、C++ 直调 | §54.5 |
| 冻结占位 | 提前分配枚举位保三章文本稳定 | §54.1 |
| 消费式条件 | JUMP_IF_FALSE 弹掉条件（不弹需配 POP） | §54.3 |
| tiering | 字节码起步、热点升机器码的双层策略 | §54.6 |
| 值栈段 | 每帧占据的连续槽位，起点即 base | §54.5 |
| 帧预算 | 编译期算出的每帧槽位数（55 章启用） | §54.5 |
| 外部根 | 从环外压住引用计数的那份持有 | §54.1 |
| 验证器 | 用效应表在执行前推栈深的装载期检查（JVM） | §54.3 |
| 调用快照 | 帧栈+值栈在某个时刻的静态照片 | §54.5 |
| 零拷贝传参 | base 划线使实参即槽位，无搬运 | §54.5 |

**练习**：

做题姿势与前两章同款（先预测后对账）：先纸上预测（栈账、帧账、反汇编文本），再
动代码跑对账。逐题提示：题 1 的常量索引去重在只有三个不同常量时
看不出收益，把 10 与 2 换成重复值试试；题 2 的帧深账要算"两参
递归的链长"；题 3 的答案在冻结纪律的措辞里（"追加"的定义）；题
5 的布局注释是本题的主体——写出 fact 那种逐地址标注，发码只是
誊抄；题 6 用第 55 章之前的手段（手编循环体里 Call）。

1. ★ 手编 `(10-3)*(2+5)` 的字节码（先写栈账再发码），加进驱动
   断言 49。注意常量池索引因去重而连号的条件。
2. ★ 把 fact 改成尾递归形状 `facttail(n, acc)`，手编两参版本，
   帧深峰值还是 7 吗？（尾递归不改帧深——栈机会照建帧；第 65 章
   尾调用优化正是消除这笔。）
3. ★★ 给 VM 加 `Op::Not`（逻辑非：0↔1）与 `Op::Ne`（不等），枚举
   **追加在 Return 前**还是后？为什么？（提示：§54.1 的冻结纪律——
   想想反汇编文本稳定性。）
4. ★★ depthTrace 记录的是"每指令后"。改成"每指令前"要动几行？
   手推两种口径下 expr 的数组差异。
5. ★★★ 手编 `while` 循环版累加 `1+2+…+10`（Loop 指令向后跳、
   槽位放累加器与计数器）：先写布局注释（像 fact 那样逐地址标注），
   再发码、断言 55 与帧深 1（**循环不加深帧**）。
6. ★★ 帧深峰值 7 的账在 fib 上变成 11。构造一个**帧深 5 但调用
   次数任意多**的程序（提示：非递归的循环里反复 Call）——验证
   "帧深与调用次数无关"。
7. ★（对照）把本章 `-(3+4)*2` 的九条指令与第 16 章同表达式的 TAC
   并排写出（临时变量名自定），数一数两版各要多少"名字查找/栈
   操作"，填进 §54.6 表的最后一列。
8. ★★（伏笔）把 fact 的 `Call 1` 改成错误元数 `Call 2`，运行观察
   错误文本；再对照第 13 章 V3（静态）与 R1（运行时）——本章的
   元数错误属于哪类？55 章的编译器能把它提前吗？（能——直接
   调用静态查；但闭包调用仍走本章的兜底。）
9. ★★（实验）把 kStackMax 临时改成 4，跑 expr 观察哪条指令先爆；
   恢复后把 kFramesMax 改成 3 跑 fact(5)——两个上限保护的边界各
   在哪一刻触发？这组实验让你对"上限是教学值但检查是真实机制"
   有手感。
10. ★（伏笔预习）翻回本章 fact 的布局注释，用红笔圈出三处第 55
   章将由机器代劳的决定（跳转偏移、槽位号、常量索引）——圈完
   它们，你已经列出了 55 章编译器的三条主要需求。

**伏笔索引**（本章埋向后文的接点，第 13 章开的传统）：

| # | 埋点 | 后文兑现 |
|---|---|---|
| 1 | Op 枚举冻结 + CloseUpvalue 占位 | 55/57 章复制扩展、文本稳定 |
| 2 | 常量池去重 | 56 章驻留（值层的同思想） |
| 3 | Value 带标签联合的浪费 | 56 章 NaN 装箱（8 字节化） |
| 4 | base 指被调者/槽位约定 | 55 章编译期槽位分配 |
| 5 | 跳转偏移从"下一指令"算起 | 55 章回填（占位 0xFFFF） |
| 6 | 栈深峰值静态可算 | 55 章帧预算 slotCount |
| 7 | 帧深只看链长 | 65 章尾调用消除的收益表 |
| 8 | 行号表 O(1) 查询 | 55 章错误行号（编译期写入） |
| 9 | 原生旁路 ObjNative | 56 章 input/clock 家族与散列表 |
| 10 | "帧没了"的前提 | 57 章上值挑战它 |

**自查清单**（不看书能答即过关；每题背面对应小节，答不出回炉）：

十题之外的一条实操自查：**合上书写出 `-(3+4)*2` 的九条指令与八格
栈账，再对照期望输出第一段**——全对者本章毕业，有错者错误位置即
回炉小节。这个"默写检验"比十问更快更狠，因为它是产出型回忆而非
再认型回忆。

1. chunk 三件套各服务谁？（字节流/ip、常量池/索引、行号表/错误行）
2. 操作数为什么内联？u8 上限为什么是格式契约的一部分？
3. `-(3+4)*2` 的九条指令与八格栈账，现在能默写吗？
4. SET_LOCAL 的栈效应为什么是 0？JUMP_IF_FALSE 为什么是 −1？
5. JumpIfFalse 的偏移从哪里减到哪里？写错基准的症状是什么？
6. Gt 的"先压者 > 后压者"怎么反咬 fib 的手编？
7. 帧的三字段各是什么？base 为什么指向被调者？
8. 为什么说"零拷贝传参"？"返回值落在被调者位"怎么做到的？
9. 帧深与调用次数的关系？fib(10) 为什么是 11 不是 177？
10. 本章与第 16 章 TAC 的分工一句话？tiering 的三层各管什么？

**与匠书原文的进一步对照**（映射表之外的细节，拿原书对读的读者
留意三处即可，其余逐节同构）：clox 的
readConstant 在 §14 就引入了"常量即值"的表示（与本章同）；clox
的栈追踪（traceStack）在错误时打印整个值栈（本章 depthTrace 的
连续版）；clox 的 FRAMES_MAX 溢出消息 "Stack overflow."（本章
"帧栈溢出（递归过深）"带因）——教学口径的措辞差异都有出处，读者
不必逐字对齐。

### 本章在字节码线上的位置

三章主线（54 VM → 55 编译 → 57 上值）里，本章是**地基与规范**：
Op 枚举与指令语义在这里冻结，后两章的一切扩展都以此为基准对账
（反汇编文本稳定、值栈行为一致、帧协议不变）。本章也是三章里
唯一"手写代码"的一章——55 章起手写的是文法与策略，字节码本身
交给机器；**亲手编过字节码的人才能审计机器编出的字节码**，这是
本章存在于教学序列里（而非直接从编译器讲起）的理由。

本章与教程其余各篇的挂点收拢：第三篇（13–20）拿到了执行侧的
对应物（54 章的帧对照 19 章活动记录、值栈段对照堆布局、原生旁路
对照内建注册）；第十篇内部（55/56/57）以本章为共享地基；第十一篇
（58–64）的代码生成会回头引用本章的栈效应表（"栈机指令的效应
常量"是表调度的约束来源之一）。**一章两用**——既向前接住运行时
篇的问题（帧怎么布局、调用怎么序列），又向后铺好执行线的地基。

（第 54 章完——下一章：单遍编译器，把手编的这一切交给机器来写。
届时读者会反复翻回本章的布局注释与栈效应表：**手编是编译器的
规格说明书**，55 章的每条发码规则都能在本章语料里找到先例。）

**一句收束**：栈机把执行压成"一个数组、一个下标、一个栈"——余下的三章，
都只是往这三样里加内容：55 章往数组里写字节、56 章换栈上元素的表示、
57 章让栈里的家搬进堆。地基不变，楼往上盖——而验收标准始终是本章的三个账本与七项断言。

（补记：本章全部断言的期望值都来自手推，无一来自"跑出来再抄"——这是机器证人
制度的另一面：人先算，机器后证，人机互为审计。）
