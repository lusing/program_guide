# 第 58 章　单遍编译与跳转回填

> 取材：匠书（Crafting Interpreters）§16.1–16.3（即取即用扫描器）、
> §17.1–17.6（Pratt 直接发码、常量去重）、§21.1–21.4（全局变量迟
> 绑定）、§22.1–22.4（局部变量编译期槽位）、§23.1–23.6（跳转与
> 回填、短路电路）。全部材料在本章自包含蒸馏，不需要翻原书。
> 本章示例：`examples/58_single_pass`（无 ANTLR，简单程序对账协议）。

**两分钟速览**：单遍编译器 = 扫描器（即取即用三函数）+ Pratt
发码表（第 11 章的表原样回归，回调从建树改发字节码）+ 局部槽位表
（声明即占位压栈、出块 POP 回收）+ 迟绑定全局表（前向引用的
救赎）+ 跳转回填（emitJump 占位 0xFFFF、patchJump 兑现）。五个
断言锁定理解：错误即终止带行号（D 组）、fact 与第 15 章同源
语料同答 120（三方对账）、块遮蔽槽位峰值恰 3、短路的 7/8 缺席、
前向引用 ret 20。四个开发期真 bug 全部留档当教材——单遍的坑
全在"位置与差一"，反汇编逐行断言是制度性克星。

## 58.0　无 AST 之路：单遍编译的取舍

第 57 章的驱动里，读者手写了 fact 与 fib 的字节码——逐地址标注跳转
目标、逐格推演栈账。本章把这份工作交给机器：**扫描、语法分析、发码
在一次遍历里完成，中间不建任何 AST**。源字符流进，字节码出，这是
"单遍编译器"（single-pass compiler）的完整定义。

先把单遍与多遍的账摆开（这是本章一切设计的总纲）：

| | 多遍流水线（第 4–15 章的路线） | 单遍（本章） |
|---|---|---|
| 中间产物 | token 流 → AST →（可再降 IR） | 无（token 即取即用） |
| 内存 | 整棵 AST 常驻 | 峰值 = 一个函数的局部表 |
| 错误恢复 | 每遍可定制（第 4 章 ANTLR、第 14 章） | 错误即终止（一遍见底，无处恢复） |
| 优化空间 | AST/IR 上任意多轮（第 41–48 章全部建立在它上） | 发码即终态，无回头路 |
| 前向引用 | 名字解析在独立遍，天然支持 | 局部变量不支持、全局靠迟绑定 |
| 速度 | 慢（多遍）但编译质量上限高 | 快（一遍）适合 REPL/脚本 |

表的逐行讲评（取舍无一行是免费的）：**中间产物行**——AST 的
存在不是为了执行而是为了"再看几遍"（分析、优化、变换都要看），
单遍省掉它等于宣布"我只看一遍"；**内存行**——见 §55.7 内存轴
的展开；**错误恢复行**——多遍的恢复策略（第 4 章见过 ANTLR 的
同步集）以"结构在手"为前提；**优化行**——本教程第 41–48 章的
全部魔法都发生在 AST/IR 的"第二遍之后"，单遍没有舞台；**前向
引用行**——单遍的天然短板，§55.4 用迟绑定赎回（赎金：运行期
查表）；**速度行**——单遍的原始动机，今天仍是 REPL 与流式的
门槛需求。

表的第三行是单遍的命门：**一遍扫过去，扫过的 token 就扔了**——发现
错误时既回不了头（重新扫要再开一遍），也没法"先把后面的看完再回来
报"（那也是两遍）。所以匠书给 clox 的口径是"错误即终止、报行号即
止"，本章照办（§55.6 第一组语料）。第五行（前向引用）是单遍最有趣
的工程题：`main` 调用 `later` 而 `later` 定义在后面——编译 `main`
时 `later` 的代码还不存在，槽位、常量索引全都无从谈起。解法在
§55.4（迟绑定），它同时解释了动态语言"函数随便前后引用"的实现
代价。

在本教程的执行路线图（第 57 章 §54.0 三条路）里，本章补上了"源
程序 → 字节码"的最后一段：第 15 章树遍历（无变换）、第 15/16 章
（LLVM/TAC 两级）、本章起（源 → chunk → 栈机）。**第 57 章手编的
每一条规则，本章都写成代码**：跳转偏移的计算、槽位号、常量索引、
压栈序——四个"手编时最见功夫的决定"（第 57 章 §54.7）在本章各有
一节正面处理。读者可以把本章当作"第 57 章的自动化续篇"来读。

```text
55.1 即取即用扫描器
55.2 Pratt 直接发码：从建树到发字节
55.3 局部变量：槽位的编译期分配
55.4 全局与迟绑定：名字的两个世界
55.5 跳转与回填：前向目标不存在怎么办
55.6 驱动、语料与期望输出解读
55.7 单遍的代价与所得
55.8 FAQ、小结与练习
```

（各节之间没有硬依赖，可以按兴趣跳读后回串。）三种读者的读法：**赶时间者**读两分钟速览 + §55.5（回填三步与
差一复盘）+ 伏笔索引——十分钟拿到骨架；**实现者**按底座四文件
→ scanner → compiler 的 function/parsePrecedence/emitJump →
驱动走码，四个真 bug 复盘是必读（它们就是你的未来）；**从匠书
来的读者**先看 clox 对照表与映射表再按序读——本章与 clox 的
差异全部标了原因（六行同构一行岔路）。
先交代底座。本章的 `chunk` 与 `vm` 四个文件是第 57 章的**本地副本
加增量**——增量共四处：Op 枚举尾部追加六个指令（GET_GLOBAL/
SET_GLOBAL 与 NOT/NE/GE/LE，见 §55.4 与 FAQ）、Chunk 增名字表
`names`（迟绑定用，§55.4）、VM 增全局映射 `globals`、大循环增六个
case。**追加全部在枚举尾部**——54 章的既有编号一动不动，两章反汇编
文本互认（54 章冻结纪律的第一次实践）。

```cpp
// file: src/chunk.hpp
// file: src/chunk.hpp
// 第 57 章：字节码块——操作码流 + 常量池 + 行号表（匠书 §14）。
// Op 枚举在本章冻结：第 58 章追加全局/局部与跳转的日常使用，
// 第 60 章追加 Closure/GetUpvalue/SetUpvalue——签名不变。
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
    CloseUpvalue,  // 第 60 章启用：栈收缩时关闭上值
    // 函数返回：弹返回值、拆帧、压回调用者栈
    Return,
    // ——第 58 章追加（枚举尾部追加，54 章既有编号不动）——
    GetGlobal,  // u8 名字常量索引：运行期查全局表（迟绑定）
    SetGlobal,  // u8 名字常量索引：写全局表
    // ——比较补全与逻辑非（本语言面的完整比较集）——
    Not,        // 弹一压其逻辑反（0↔1）
    Ne, Ge, Le, // 不等/不小于/不大于
};

// ---------- 值：带标签联合起步版（§18；第 59 章 NaN 装箱升级） ----------
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
    // 第 58 章追加：名字表（迟绑定用）。名字不进常量池——值宇宙的
    // 字符串是第 59 章 ObjString 的领地，此处独立成表（同样去重）。
    std::vector<std::string> names;

    int addConstant(const Value &v);  // 去重：同值返回同索引（§17.6）
    int addName(const std::string &n);
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

int Chunk::addName(const std::string &n) {
    for (size_t k = 0; k < names.size(); ++k)
        if (names[k] == n) return int(k);
    names.push_back(n);
    return int(names.size()) - 1;
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
        case Op::GetGlobal: return "GET_GLOBAL";
        case Op::SetGlobal: return "SET_GLOBAL";
        case Op::Not: return "NOT";
        case Op::Ne: return "NE";
        case Op::Ge: return "GE";
        case Op::Le: return "LE";
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
        case Op::GetGlobal: case Op::SetGlobal: {  // 操作数是名字表索引
            uint8_t k = c.code[off + 1];
            os << opName(op) << " " << int(k) << "  ; " << c.names[k] << "\n";
            return 2;
        }
        case Op::JumpIfFalse: case Op::Jump: case Op::Loop: {
            uint16_t x = uint16_t(c.code[off + 1]) << 8 | c.code[off + 2];
            // 前向跳转打印目标地址、后向（Loop）打印起点，与匠书同款
            if (op == Op::Loop) os << opName(op) << " -> " << (off + 3 - x) << "\n";
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

```cpp
// file: src/vm.hpp
// file: src/vm.hpp
// 第 57 章：栈式虚拟机——FETCH-DECODE-EXECUTE 大循环 + 调用帧（匠书 §15/§24）。
// 第 58 章的编译器与第 60 章的上值扩展复用本类（本地副本 + 追加指令）。
#ifndef TIP_VM_HPP
#define TIP_VM_HPP

#include <map>
#include <ostream>
#include <string>
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

    std::map<std::string, Value> globals;  // 迟绑定名表（函数注册处）

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
    // 后续脚本级"局部槽 0 保留"贯穿第 58 章）
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
            case Op::GetGlobal: {
                uint8_t k = readByte();
                // 迟绑定：名字到运行期才解析——前向引用因此合法
                auto it = globals.find(f.fn->code->names[k]);
                if (it == globals.end())
                    throw VmError{"未定义全局：" + f.fn->code->names[k]};
                push(it->second);
                break;
            }
            case Op::SetGlobal: {
                uint8_t k = readByte();
                globals[f.fn->code->names[k]] = peek(0);  // 不弹：赋值表达式有值
                break;
            }
            case Op::Not: {
                Value a = pop();
                push(Value::num(a.isObj() || a.i != 0 ? 0 : 1));
                break;
            }
            case Op::Ne: {
                Value b = pop(), a = pop();
                push(Value::num(a.i == b.i ? 0 : 1));
                break;
            }
            case Op::Ge: {
                Value b = pop(), a = pop();
                push(Value::num(a.i >= b.i ? 1 : 0));
                break;
            }
            case Op::Le: {
                Value b = pop(), a = pop();
                push(Value::num(a.i <= b.i ? 1 : 0));
                break;
            }
            case Op::CloseUpvalue:
                // 第 60 章启用（Op 枚举冻结位）：本章手编语料不出现
                throw VmError{"CLOSE_UPVALUE 未启用（第 60 章）"};
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

增量四件各值得一句话走读：**枚举尾部追加**——六个新指令的编号
接在 Return 之后（20–26），54 章的 0–17 原封不动，两章共存的
字节码可以互相反汇编（若追问"为什么不按类分组插入"，答案就是
冻结纪律：插入即漂移）；**名字表 names**——独立于常量池的去重
字符串表，操作数是表索引；为什么不并进常量池？因为值宇宙（Value）
还没有字符串——那是第 59 章 ObjString 的戏，提前演会剧透（§55.4
光谱表的注脚）；**globals 映射**——VM 的公开成员（驱动注册用），
map 而非散列表是教学选型，56 章手写开放定址表时它正是被替换的
靶子；**六个新 case**——GET/SET_GLOBAL 各读名字表索引，NOT/NE/
GE/LE 是纯栈顶运算（第 57 章练习 3 的答案在此落地）。逐个走读
一行：GET_GLOBAL 查 globals 映射、未命中抛"未定义全局"（迟绑定
的运行期错误面——错误消息按"最可能作者错误"措辞：名字拼错或
顺序问题）；SET_GLOBAL 用 peek 不弹（赋值表达式有值的通用性，
FAQ 有专问）；NOT 对非零取 0、零取 1（含对象按真——防御位）；
NE/GE/LE 与 54 章的 GT/EQ 完全同构（弹二压一）。六行 case 的
共同点：**没有一个碰帧**——它们全是"帧内或全局"的操作，帧协议
（Call/Return）54 章已定稿，本章不越界。

"第 57 章手编四决定 → 本章自动化对照"先立总表（每章正文各有
专节展开）：

| 手编决定（54 章） | 本章的自动化 | 节 |
|---|---|---|
| 跳转偏移逐地址手算 | emitJump/patchJump/emitLoop | §55.5 |
| 槽位号人脑分配 | locals_ 表 + resolveLocal | §55.3 |
| 常量池索引人肉去重 | addConstant/addName | §55.2 |
| 压栈序凭直觉（fib 翻车处） | Pratt 回调的递归结构 | §55.2 |

源码量分布表（九文件合计约 1340 行）：

| 文件 | 行数 | 性质 |
|---|---|---|
| scanner.hpp/cpp | ~170 | 新（§55.1） |
| compiler.hpp/cpp | ~450 | 新（本章主角） |
| chunk/vm 四件 | ~640 | 54 章副本 + 六指令 |
| main.cpp | ~230 | 驱动与语料 |

主角只占三分之一——**单遍编译器本体比它的地基还小**，这个
比例与 clox（编译器 ~1000 行、VM ~1000 行）惊人地一致。

九个文件的依赖结构一图（箭头 = include）：

```text
main.cpp → compiler.hpp → scanner.hpp
                       → chunk.hpp ←── vm.hpp ← vm.cpp
   └────────────────────→ vm.hpp
```

三条依赖链各管一段：compiler→scanner 是"词法供语法"、
compiler→chunk 是"发码目标"、vm→chunk 是"执行对象"——
main 驱动把三链接成程序。**没有环**（vm 不认识 compiler、
chunk 谁都不认识）——这是"编译器与 VM 可分别演化"的结构保证
（57 章 vm.cpp 加上值、compiler.cpp 加 Closure，互不越界）。

四行的右列加起来不到一百行代码——**这就是"编译器"的全部秘密：
它不是魔法，是把四类算术搬到扫过的那一刻做掉**。读者带着这张
表读 compiler.cpp 的任何一个函数，都能立刻定位"它在替我做 54
章的哪件事"。

本章两处**教学扩展**照例如实标注：块级 `var` 语句（jlox 有、TIP 无
——第 15 章练习 3 预告过，本章正式实现）与 `&&`/`||` 短路运算符
（C 风格布尔化，真 1 假 0）。比较运算符带全 `< <= > >= == !=`（与
第 11 章同一扩展口径，TIP 原文法只有 `>` 与 `==`）。

## 58.1　即取即用扫描器

```cpp
// file: src/scanner.hpp
// file: src/scanner.hpp
// 第 58 章：即取即用扫描器（匠书 §16）——无 token 缓冲，编译器
// 要一个取一个。advance/peek/match 三函数即全部协议。
#ifndef TIP_SCANNER_HPP
#define TIP_SCANNER_HPP

#include <cstdint>
#include <string>
#include <vector>

namespace tip {

enum class Tok : uint8_t {
    Int, Ident,
    KwVar, KwReturn, KwOutput, KwIf, KwElse, KwWhile,
    Plus, Minus, Star, Slash,
    Eq, Ne, Gt, Ge, Lt, Le,        // 双字符优先
    AndAnd, OrOr,                  // && ||（教学扩展，C 风格布尔化）
    Assign,                        // '='（单字符；'==' 已被上面吃掉）
    LParen, RParen, LBrace, RBrace, Semi, Comma,
    Eof,
};

struct Token {
    Tok t = Tok::Eof;
    std::string text;   // 标识符/数字原文
    long long num = 0;  // Int 有效
    int line = 1;
};

struct ScanError {
    std::string msg;
    int line = 0;
};

class Scanner {
  public:
    Scanner() = default;  // Compiler 按值持有时需要（compile 时再喂源）
    explicit Scanner(std::string src) : src_(std::move(src)) {}

    // 三函数协议（匠书 makeToken/advance/peek 同型）
    Token scanToken();           // 取下一个 token（跳过空白与注释）
    char peekChar() const { return cur_ < src_.size() ? src_[cur_] : '\0'; }
    char peekNext() const { return cur_ + 1 < src_.size() ? src_[cur_ + 1] : '\0'; }
    int line() const { return line_; }

  private:
    char advanceChar();
    void skipWhitespaceAndComments();
    bool matchChar(char expect);  // 条件消费：匹配则前进

    std::string src_;
    size_t cur_ = 0;
    int line_ = 1;
};

}  // namespace tip

#endif  // TIP_SCANNER_HPP
```

```cpp
// file: src/scanner.cpp
// file: src/scanner.cpp
#include "scanner.hpp"

namespace tip {

char Scanner::advanceChar() {
    char c = src_[cur_++];
    if (c == '\n') ++line_;
    return c;
}

void Scanner::skipWhitespaceAndComments() {
    for (;;) {
        char c = peekChar();
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
            advanceChar();
        } else if (c == '/' && peekNext() == '/') {
            // 行注释：吃到行尾（换行留给空白处理记账行号）
            while (peekChar() != '\0' && peekChar() != '\n') advanceChar();
        } else {
            return;
        }
    }
}

bool Scanner::matchChar(char expect) {
    if (peekChar() != expect) return false;
    advanceChar();
    return true;
}

Token Scanner::scanToken() {
    skipWhitespaceAndComments();
    Token tk;
    tk.line = line_;
    char c = peekChar();
    if (c == '\0') {
        tk.t = Tok::Eof;
        return tk;
    }
    auto two = [&](Tok t, const char *s) {
        advanceChar();
        advanceChar();
        tk.t = t;
        tk.text = s;
    };
    auto one = [&](Tok t, const char *s) {
        advanceChar();
        tk.t = t;
        tk.text = s;
    };
    // 双字符运算符先于单字符（最长匹配，与第 11 章口径一致）
    if (c == '=' && peekNext() == '=') return two(Tok::Eq, "=="), tk;
    if (c == '!' && peekNext() == '=') return two(Tok::Ne, "!="), tk;
    if (c == '>' && peekNext() == '=') return two(Tok::Ge, ">="), tk;
    if (c == '<' && peekNext() == '=') return two(Tok::Le, "<="), tk;
    if (c == '&' && peekNext() == '&') return two(Tok::AndAnd, "&&"), tk;
    if (c == '|' && peekNext() == '|') return two(Tok::OrOr, "||"), tk;

    if (c >= '0' && c <= '9') {
        std::string s;
        while (peekChar() >= '0' && peekChar() <= '9') s += advanceChar();
        tk.t = Tok::Int;
        tk.text = s;
        tk.num = 0;
        for (char d : s) tk.num = tk.num * 10 + (d - '0');
        return tk;
    }
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_') {
        std::string s;
        for (;;) {
            char p = peekChar();
            if ((p >= 'a' && p <= 'z') || (p >= 'A' && p <= 'Z') ||
                (p >= '0' && p <= '9') || p == '_')
                s += advanceChar();
            else break;
        }
        tk.text = s;
        if (s == "var") tk.t = Tok::KwVar;
        else if (s == "return") tk.t = Tok::KwReturn;
        else if (s == "output") tk.t = Tok::KwOutput;
        else if (s == "if") tk.t = Tok::KwIf;
        else if (s == "else") tk.t = Tok::KwElse;
        else if (s == "while") tk.t = Tok::KwWhile;
        else tk.t = Tok::Ident;
        return tk;
    }
    switch (c) {
        case '+': return one(Tok::Plus, "+"), tk;
        case '-': return one(Tok::Minus, "-"), tk;
        case '*': return one(Tok::Star, "*"), tk;
        case '/': return one(Tok::Slash, "/"), tk;
        case '>': return one(Tok::Gt, ">"), tk;
        case '<': return one(Tok::Lt, "<"), tk;
        case '=': return one(Tok::Assign, "="), tk;
        case '(': return one(Tok::LParen, "("), tk;
        case ')': return one(Tok::RParen, ")"), tk;
        case '{': return one(Tok::LBrace, "{"), tk;
        case '}': return one(Tok::RBrace, "}"), tk;
        case ';': return one(Tok::Semi, ";"), tk;
        case ',': return one(Tok::Comma, ","), tk;
        default:
            // 即取即用扫描的错误口径：报出事字符与行号即止（单遍，
            // 错误恢复没有多遍可依赖——匠书 §16.2 的取舍同款）
            throw ScanError{std::string("意外字符 '") + c + "'", line_};
    }
}

}  // namespace tip
```

多遍编译器的词法层是一台独立机器：整串源码进、整条 token 流出
（第 5 章的 DFA、第 15 章 ANTLR 的 lexer 都是）。单遍编译器的词法
层退化成**三个函数的协议**：`scanToken`（取下一个）、`peekChar/
peekNext`（看不吃）、内部 `advanceChar/matchChar`（条件消费）。
匠书 §16.2 的原话：编译器要一个 token，扫描器就产一个——**没有
缓冲、没有流，只有供需的即时握手**。

协议三函数先立表（手写扫描器的全部对外形状）：

| 函数 | 职责 | 谁调它 |
|---|---|---|
| scanToken | 产下一个 token（跳空白注释） | 编译器的 advance |
| peekChar/peekNext | 看不吃 | scanToken 内部（双字符判断） |
| advanceChar/matchChar | 消费（含行号记账） | scanToken 内部 |

四行表对应匠书 §16 的 makeToken/advance/peek 家族——**协议的
小是刻意**的：函数越少，"扫描器可以被整体替换"的承诺越可信
（FAQ 首问的依据）。

实现要点四条。**最长匹配先双字符**：`==`、`<=`、`&&` 先于单字符
判断——与第 5 章多模式 scanner、第 11 章词法器同一原则，单遍只是
把它写进 scanToken 的 if 链顶部。**注释在词法层跳过**：行注释吃到
行尾（换行留给空白处理记账行号）——注释不产 token，语法层根本
不知道注释存在过。**行号在扫描器里记账**：`advanceChar` 每过换行
加一，每个 token 出厂自带行号——单遍没有"回头查位置表"的机会，
**行号必须在 token 产生的时刻就贴上**。**错误即抛**：意外字符抛
`ScanError`（带行号）——与编译错误同一出口（驱动都翻译成"编译
错误[行N]"），单遍的词法错与语法错在用户眼里没有区别，也不必有。

`scanToken` 内部按"先跳白、再认双、再认字、再认词"的固定次序走，
拿 `x1 <= 10` 的扫描过一遍：skipWhitespace 无事；c='x' 落进标识符
分支，循环吞 `x1` 出 `Ident("x1")`；下一轮 c='<'，查双字符表——
`<=` 命中（peekNext='='），`two()` 一次前进两位出 `Le`；下一轮
'1' 走数字循环出 `Int(10, num=10)`。四类字（空白/双字符/词/字）
各有各的分支，**没有回退**——单字符认错不退回（双字符先行保证
不会认错），这是手写扫描器比 DFA 简单的全部原因：**语言的设计者
已经保证每个前缀唯一可分**，扫描器只管顺着走。

关键字的识别走"先拼整个词、再查保留字表"的路线——`while` 不是
六个字符的六次分岔，而是拼出 "while" 后一次比对（六个 if）。这与
第 5 章多模式 DFA"关键字与标识符共用状态机、末尾加环"的经典问题
是同一件事的两种解法：DFA 里关键字路径要在终态上"回头看是不是
还有字母"（else 环），手写里靠"拼完再查"天然正确。**拼完再查的
代价是每个标识符都拼一遍**——对保留字少的教学语言无所谓；C++ 的
扫描器反着来（首字符分派表直达），因为它的保留字太多了。

行号的三问三答：谁记（advanceChar 过换行时）、贴给谁（每个 token
出厂自带）、谁消费（编译错误用 cur_.line、发码行号用 prev_.line
——发码行号的完整传播链是**四级携带**：advanceChar 记账 →
scanToken 贴在 Token 上 → 编译器 prev_ 转存 → emit 写进
Chunk.lines。四级里任何一级断链（比如某处直接 write 而忘传
line()），运行期错误的行号就漂移——54 章说"错误路径只碰解码后
形态"，本章补上"行号的产生路径同样要单一"。诊断行号的三种
携带形态（token 行、指令行、名字表行——名字表本版不带行号，
57 章捕获表诊断时要补）在三章里的分布，读者可以自己数一数。
——**发码归 prev**：一条指令的行号是"产生它的那个 token"的行号，
比如 SET_LOCAL 归 '=' 所在行还是右值所在行？实现取 prev_（最近消费
的 token）——赋值语句发完时 prev_ 恰是右值末 token，诊断语义最
接近"这一行算到哪了"）。

与第 5 章的对照值得一段：那章的 scanner 是**表驱动的多模式 DFA**
（ Thompson 构造 → 子集构造），它回答"给定正则集合，如何机械地造
扫描器"；本章是**手写的单字符状态机**，它回答"一个具体语言的扫描
器长什么样"。工业实践里两者并存：生成器路线（lex/ANTLR）吃文法、
产表；手写路线（本章、clox、V8）吃语言规格、产 switch。选择逻辑
与解析器三章（第 6/8/9 章）的对照完全同构——**生成器买自动化，
手写买控制**，第 11 章 §9.7 的结论原样适用于词法层。

三方词法对照的大表（把第 5、13 章与本章放平）：

| | DFA 生成（第 5 章） | ANTLR lexer（第 15 章） | 手写（本章） |
|---|---|---|---|
| 输入 | 正则集合 | 文法里的 lexer 规则 | 语言规格（人脑） |
| 产物 | 转移表 + 驱动器 | 生成代码 | switch/if 链 |
| 最长匹配 | 表构造保证 | 工具保证 | 双字符先行的次序保证 |
| 行号 | 外挂位置表 | 工具内建 | advanceChar 记账 |
| 错误恢复 | 死状态报错 | 工具策略 | 即抛（单遍口径） |
| 换实现成本 | 重跑生成器 | 重跑生成器 | 重写文件（scanner 独立的回报） |

扫描器的测试法（本章语料之外的手段）：**对偶断言**——任取合法
程序，扫描后再从 token 重组文本，应当与原文本空白无关地相等
（`x1<=10` 与 `x1 <= 10` 同流）；**边界断言**——单字符 `=`、
`==`、文件末尾恰好双字符的截断、空注释 `//`。教程第 5 章的
对抗测试思想（随机串喂扫描器、只断言"要么报错要么合法"）在
这里完全适用——单遍扫描器的正确率比多遍更要紧，因为**它没有
第二遍替它兜错**。

## 58.2　Pratt 直接发码：从建树到发字节

```cpp
// file: src/compiler.hpp
// file: src/compiler.hpp
// 第 58 章：单遍编译器——扫描、语法、发码一次完成，无 AST
//（匠书 §16–§17、§21–§23）。Pratt 表来自第 11 章，回调从
// "合成 AST 节点"换成"发一条字节码"——表一行不用改。
#ifndef TIP_COMPILER_HPP
#define TIP_COMPILER_HPP

#include <memory>
#include <string>
#include <vector>

#include "chunk.hpp"
#include "scanner.hpp"

namespace tip {

struct CompileError {
    std::string msg;
    int line = 0;
};

// 编译产物：函数表（名字 → ObjFn），供驱动注册进 VM 全局表。
struct Program {
    std::vector<std::shared_ptr<ObjFn>> fns;
};

class Compiler {
  public:
    // 编译整个源文件（函数序列）。出错抛 CompileError（单遍口径：
    // 第一处错误即终止——没有后续遍历可依赖，恢复无从谈起）。
    Program compile(const std::string &src);

    // 断言用：各函数的槽位峰值（§22 编译期账）
    int lastSlotPeak() const { return lastSlotPeak_; }

  private:
    // Pratt 规则表（私有静态：表要取本类成员指针）
    struct CRule;
    static CRule ruleFor(Tok t);

    // —— 词法层（即取即用三函数 + 一个前看缓冲）——
    Token advance();
    bool check(Tok t) const;
    bool match(Tok t);
    Token consume(Tok t, const char *msg);

    // —— 声明与作用域（§22）——
    struct Local {
        std::string name;
        int depth;
    };
    void beginScope();
    void endScope();          // 弹出本层局部并按数发 POP（槽位回收）
    int resolveLocal(const std::string &name) const;  // -1 = 不在本函数
    void declareLocal(const std::string &name, int line);

    // —— 语句层（递归下降骨架）——
    void function();          // IDENT ( params ) { varDecls? stmt* return expr ; }
    void statement();
    void blockStmt();
    void varStmt();           // 块级 var（教学扩展，jlox 同款）
    void exprStmt();          // 赋值语句：lvalue = expr ;（lvalue 仅 IDENT）
    void ifStmt();            // §23.3：双跳转模板 + 回填
    void whileStmt();         // §23.5：Loop 回边
    void outputStmt();
    void returnStmt();

    // —— 表达式层（Pratt，§17.5）——
    void expression();        // parseExpression(Prec::None) 的入口
    void parsePrecedence(int minPrec);
    // 前缀回调
    void numberFn();
    void identFn();           // 局部 → GET_LOCAL；否则 GET_GLOBAL（迟绑定）
    void groupingFn();
    void unaryFn();
    // 中缀回调
    void binaryFn();          // 双目：左右已发，此处发运算符
    void andFn();             // 短路（C 风格布尔化）
    void orFn();
    void callFn();            // 被调者已发；发实参 + CALL

    // —— 发码与回填（§23.1）——
    void emit(Op op);
    void emitByte(uint8_t b);
    void emitConstant(const Value &v);
    int emitJump(Op op);          // 占位 0xFFFF，返回 Patch 位置
    void patchJump(int at);       // 前向跳转目标此刻才存在——回填
    void emitLoop(int loopStart); // 向后跳：目标已知，直接写

    int line() const { return prev_.line; }  // 行号随"上一 token"走

    Scanner sc_;
    Token prev_{};   // 刚消费的 token（发码行号的来源）
    Token cur_{};    // 前看一个（即取即用的最小缓冲）
    std::vector<Local> locals_;
    int scopeDepth_ = 0;
    std::shared_ptr<ObjFn> fn_;   // 正在编译的函数
    Program prog_;
    int lastSlotPeak_ = 0;
};

}  // namespace tip

#endif  // TIP_COMPILER_HPP
```

```cpp
// file: src/compiler.cpp
// file: src/compiler.cpp
#include "compiler.hpp"


namespace tip {

// ---------- Pratt 规则表（第 11 章的表，回调换成发码） ----------
// 优先级从松到紧（枚举值即比较序），与第 11 章 Prec 同序。
enum class Prec {
    None = 0, OrOr, AndAnd, Equality, Comparison, Term, Factor, Unary, Call,
};

struct Compiler::CRule {
    void (Compiler::*prefix)() = nullptr;
    void (Compiler::*infix)() = nullptr;
    Prec prec = Prec::None;
};

Compiler::CRule Compiler::ruleFor(Tok t) {
    using C = Compiler;
    switch (t) {
        case Tok::Int:    return {&C::numberFn, nullptr, Prec::None};
        case Tok::Ident:  return {&C::identFn, nullptr, Prec::None};
        case Tok::LParen: return {&C::groupingFn, &C::callFn, Prec::Call};
        case Tok::Minus:  return {&C::unaryFn, &C::binaryFn, Prec::Term};
        case Tok::OrOr:   return {nullptr, &C::orFn, Prec::OrOr};
        case Tok::AndAnd: return {nullptr, &C::andFn, Prec::AndAnd};
        case Tok::Eq: case Tok::Ne:
            return {nullptr, &C::binaryFn, Prec::Equality};
        case Tok::Gt: case Tok::Ge: case Tok::Lt: case Tok::Le:
            return {nullptr, &C::binaryFn, Prec::Comparison};
        case Tok::Plus: return {nullptr, &C::binaryFn, Prec::Term};
        case Tok::Star: case Tok::Slash:
            return {nullptr, &C::binaryFn, Prec::Factor};
        default: return {};
    }
}

// ---------- 词法层 ----------
Token Compiler::advance() {
    prev_ = cur_;
    for (;;) {
        cur_ = sc_.scanToken();
        return prev_;
    }
}
bool Compiler::check(Tok t) const { return cur_.t == t; }
bool Compiler::match(Tok t) {
    if (!check(t)) return false;
    advance();
    return true;
}
Token Compiler::consume(Tok t, const char *msg) {
    if (check(t)) return advance();
    throw CompileError{std::string(msg) + "，但看到 '" + cur_.text + "'", cur_.line};
}

// ---------- 作用域 ----------
void Compiler::beginScope() { ++scopeDepth_; }
void Compiler::endScope() {
    --scopeDepth_;
    int pop = 0;
    while (!locals_.empty() && locals_.back().depth > scopeDepth_) {
        locals_.pop_back();
        ++pop;
    }
    // 槽位回收：每弹一个局部发一条 POP（§22.3）
    for (; pop > 0; --pop) emit(Op::Pop);
}
int Compiler::resolveLocal(const std::string &name) const {
    for (int i = int(locals_.size()) - 1; i >= 0; --i)
        if (locals_[size_t(i)].name == name) return i;
    return -1;
}
void Compiler::declareLocal(const std::string &name, int line) {
    // 同层重名拒绝（跨层遮蔽合法——第 15 章 V5 的口径）
    for (int i = int(locals_.size()) - 1; i >= 0; --i) {
        const Local &l = locals_[size_t(i)];
        if (l.depth != scopeDepth_) break;  // 更外层不必再查
        if (l.name == name)
            throw CompileError{"同层重复声明：" + name, line};
    }
    locals_.push_back(Local{name, scopeDepth_});
    if (int(locals_.size()) > lastSlotPeak_) lastSlotPeak_ = int(locals_.size());
}

// ---------- 发码与回填 ----------
void Compiler::emit(Op op) { fn_->code->write(op, line()); }
void Compiler::emitByte(uint8_t b) { fn_->code->writeByte(b, line()); }
void Compiler::emitConstant(const Value &v) {
    emit(Op::Constant);
    emitByte(uint8_t(fn_->code->addConstant(v)));
}
int Compiler::emitJump(Op op) {
    emit(op);
    fn_->code->writeU16(0xFFFF, line());  // 占位：目标此刻不存在
    return int(fn_->code->code.size()) - 2;  // 记住偏移字段的位置
}
void Compiler::patchJump(int at) {
    // 回填：目标 = 当前代码末尾（then 支编译完成后恰是要跳到的地方）
    size_t target = fn_->code->code.size();
    uint16_t off = uint16_t(target - at - 2);  // 读操作数后 ip=at+2
    fn_->code->code[at] = uint8_t(off >> 8);
    fn_->code->code[at + 1] = uint8_t(off & 0xFF);
}
void Compiler::emitLoop(int loopStart) {
    emit(Op::Loop);
    // 向后跳。emit 已写下操作码，here = Loop 地址 + 1；VM 读码后
    // ip = Loop地址 + 3，要回到 loopStart：偏移 = here - loopStart + 2。
    size_t here = fn_->code->code.size();
    fn_->code->writeU16(uint16_t(here - loopStart + 2), line());
}

// ---------- 程序与函数 ----------
Program Compiler::compile(const std::string &src) {
    sc_ = Scanner(src);
    advance();  // 填充 cur_
    while (!check(Tok::Eof)) function();
    return std::move(prog_);
}

void Compiler::function() {
    Token name = consume(Tok::Ident, "期望函数名");
    fn_ = std::make_shared<ObjFn>();
    fn_->name = name.text;
    fn_->code = std::make_shared<Chunk>();

    // 槽 0 = 函数自己占位（第 57 章帧协议），随后形参逐个入槽
    locals_.clear();
    scopeDepth_ = 0;
    locals_.push_back(Local{name.text, 0});

    consume(Tok::LParen, "期望 '('");
    if (!check(Tok::RParen)) {
        for (;;) {
            Token p = consume(Tok::Ident, "期望形参名");
            declareLocal(p.text, p.line);
            ++fn_->arity;
            if (!match(Tok::Comma)) break;
        }
    }
    consume(Tok::RParen, "期望 ')'");
    consume(Tok::LBrace, "期望 '{'");

    // 函数头 var 声明（TIP 原味：声明组）。声明即发占位压栈
    //（CONSTANT 0）——槽位必须在代码执行到使用点前已在栈上成形
    //（clox 的 var 发 OP_NIL 同款；第 15 章"声明即占位"的编译版）。
    if (match(Tok::KwVar)) {
        for (;;) {
            Token v = consume(Tok::Ident, "期望变量名");
            declareLocal(v.text, v.line);
            emitConstant(Value::num(0));
            if (!match(Tok::Comma)) break;
        }
        consume(Tok::Semi, "期望 ';'");
    }

    beginScope();
    while (!check(Tok::KwReturn) && !check(Tok::RBrace) && !check(Tok::Eof))
        statement();
    endScope();

    consume(Tok::KwReturn, "期望 'return'");
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Return);
    consume(Tok::RBrace, "期望 '}'");

    prog_.fns.push_back(fn_);
}

// ---------- 语句层 ----------
void Compiler::statement() {
    if (match(Tok::KwVar)) varStmt();
    else if (match(Tok::KwOutput)) outputStmt();
    else if (match(Tok::KwIf)) ifStmt();
    else if (match(Tok::KwWhile)) whileStmt();
    else if (match(Tok::LBrace)) blockStmt();
    else exprStmt();
}

void Compiler::blockStmt() {
    beginScope();               // 块即作用域（第 15 章块环境的编译版）
    while (!check(Tok::RBrace) && !check(Tok::Eof)) statement();
    endScope();                 // 出块发 POP：槽位回收
    consume(Tok::RBrace, "期望 '}'");
}

void Compiler::varStmt() {
    // 块级 var（教学扩展，jlox 同款）：声明即占槽并压占位 0
    //（确定赋值检查是第 15 章的领地——单遍编译器不做，如实说明）
    for (;;) {
        Token v = consume(Tok::Ident, "期望变量名");
        declareLocal(v.text, v.line);
        emitConstant(Value::num(0));
        if (!match(Tok::Comma)) break;
    }
    consume(Tok::Semi, "期望 ';'");
}

void Compiler::exprStmt() {
    Token name = consume(Tok::Ident, "期望语句");
    consume(Tok::Assign, "期望 '='");
    expression();
    // 赋值目标：局部 → SET_LOCAL；否则 SET_GLOBAL（迟绑定写）
    int slot = resolveLocal(name.text);
    if (slot >= 0) {
        emit(Op::SetLocal);
        emitByte(uint8_t(slot));
    } else {
        emit(Op::SetGlobal);
        emitByte(uint8_t(fn_->code->addName(name.text)));
    }
    emit(Op::Pop);  // 语句值丢弃（TIP 赋值是语句）
    consume(Tok::Semi, "期望 ';'");
}

void Compiler::ifStmt() {
    // §23.3 双跳转模板：then/else 各占一个前向跳转，支编译完回填
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jElse = emitJump(Op::JumpIfFalse);
    statement();               // then 支
    int jEnd = emitJump(Op::Jump);
    patchJump(jElse);          // else 支从这里开始
    if (match(Tok::KwElse)) statement();
    patchJump(jEnd);           // 汇合点
}

void Compiler::whileStmt() {
    int loopStart = int(fn_->code->code.size());  // 条件的位置：回边目标
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jExit = emitJump(Op::JumpIfFalse);
    statement();
    emitLoop(loopStart);       // 向后跳：目标已知，直接写
    patchJump(jExit);
}

void Compiler::outputStmt() {
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Print);
}

void Compiler::returnStmt() {
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Return);
}

// ---------- 表达式层（Pratt） ----------
void Compiler::expression() { parsePrecedence(int(Prec::None)); }

void Compiler::parsePrecedence(int minPrec) {
    advance();  // 当前 token 进 prev_（回调通过 prev_ 知道自己是谁）
    CRule r = ruleFor(prev_.t);
    if (!r.prefix) throw CompileError{"期望表达式，但看到 '" + prev_.text + "'", prev_.line};
    (this->*r.prefix)();
    while (true) {
        r = ruleFor(cur_.t);
        if (int(r.prec) < minPrec || r.infix == nullptr) break;
        (this->*r.infix)();
    }
}

void Compiler::numberFn() { emitConstant(Value::num(prev_.num)); }

void Compiler::identFn() {
    // 名字的两个世界：函数局部（编译期已解析 → 槽位）与全局（迟绑定）
    int slot = resolveLocal(prev_.text);
    if (slot >= 0) {
        emit(Op::GetLocal);
        emitByte(uint8_t(slot));
    } else {
        emit(Op::GetGlobal);
        emitByte(uint8_t(fn_->code->addName(prev_.text)));
    }
}

void Compiler::groupingFn() {
    expression();
    consume(Tok::RParen, "期望 ')'");
}

void Compiler::unaryFn() {
    // 一元负号：先发操作数，再发 NEGATE（后缀序！——第 57 章的教训）
    parsePrecedence(int(Prec::Unary));
    emit(Op::Negate);
}

void Compiler::binaryFn() {
    advance();  // 吃掉运算符 token（与第 11 章 binary 开头的 advance 同位）
    // 左操作数已在栈上（调用者发的）；先发右操作数，再发运算符。
    // 压栈序即求值序（后缀序）——第 57 章 fib 手编翻车的机器版教训：
    // 编译器把"序"一次性想清楚，人从此不用每次想。
    Tok op = prev_.t;
    CRule r = ruleFor(op);
    parsePrecedence(int(r.prec) + 1);  // 左结合：右操作数抬一级
    switch (op) {
        case Tok::Plus: emit(Op::Add); break;
        case Tok::Minus: emit(Op::Sub); break;
        case Tok::Star: emit(Op::Mul); break;
        case Tok::Slash: emit(Op::Div); break;
        case Tok::Gt: emit(Op::Gt); break;
        case Tok::Eq: emit(Op::Eq); break;
        case Tok::Ne: emit(Op::Ne); break;
        case Tok::Ge: emit(Op::Ge); break;
        case Tok::Le: emit(Op::Le); break;
        default: break;
    }
}

void Compiler::andFn() {
    advance();  // 吃掉 && 
    // C 风格布尔化（真 1 假 0，TIP 整数宇宙口径）：
    //   a; JIF Lf; b; JIF Lf; CONST 1; JMP Le; Lf: CONST 0; Le:
    // a 假 → 0（b 的发码完全不执行：短路）；a 真 b 假 → 0；双真 → 1。
    int jf1 = emitJump(Op::JumpIfFalse);
    parsePrecedence(int(Prec::AndAnd) + 1);   // 右操作数
    int jf2 = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je = emitJump(Op::Jump);
    patchJump(jf1);   // 两处假出口汇到 CONST 0
    patchJump(jf2);
    emitConstant(Value::num(0));
    patchJump(je);    // 真出口越过 CONST 0
}

void Compiler::orFn() {
    advance();  // 吃掉 ||
    // a || b：a; JIF Lr; CONST 1; JMP Le; Lr: b; JIF Lf; CONST 1; JMP Le;
    //         Lf: CONST 0; Le:
    // a 真 → 1（b 不执行）；a 假 → 看 b。
    int jr = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je1 = emitJump(Op::Jump);
    patchJump(jr);                        // Lr：右侧从这开始
    parsePrecedence(int(Prec::OrOr) + 1);
    int jf = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je2 = emitJump(Op::Jump);
    patchJump(jf);                        // Lf：假出口
    emitConstant(Value::num(0));
    patchJump(je1);                       // Le：两个真出口都越过 CONST 0
    patchJump(je2);
}

void Compiler::callFn() {
    // 被调者已在栈上（identFn/groupingFn 发的）；发实参后 CALL
    consume(Tok::LParen, "期望 '('");
    int argc = 0;
    if (!check(Tok::RParen)) {
        expression();
        ++argc;
        while (match(Tok::Comma)) {
            expression();
            ++argc;
        }
    }
    consume(Tok::RParen, "期望 ')'");
    emit(Op::Call);
    emitByte(uint8_t(argc));
}

}  // namespace tip
```

第 11 章的 Pratt 规则表在此全员回归，**一行不改**——改的只是回调
的身体：第 11 章的回调"吃 token、递归、合成 AST 节点"，本章的回调
"吃 token、递归、**发一条字节码**"。逐个回调对照：

| 回调 | 第 11 章（建树） | 本章（发码） |
|---|---|---|
| `numberFn` | 造 `IntLit` | `CONSTANT 常量索引` |
| `identFn` | 造 `VarRef` | 局部 → `GET_LOCAL 槽位`；全局 → `GET_GLOBAL 名字`（§55.4） |
| `groupingFn` | 透传内部节点 | 透传（括号零发码——栈机不需要括号！） |
| `unaryFn` | 造 `Unary` | 先发操作数再 `NEGATE`（后缀序） |
| `binaryFn` | 造 `Binop` | 先发右操作数再发运算符 opcode |
| `callFn` | 造 `CallE` | 被调者已发；发实参 + `CALL argc` |

第二行是全表的题眼：**第 11 章 `identFn` 只造一种节点，本章要分流**
——名字的解析结果决定发哪条指令。这个分流（编译期查局部表，命中
走槽位、不命中走全局表）就是第 14 章名字解析的编译器形态，§55.3
正面展开。回调表逐行讲评（按表的次序）：

**numberFn** 是最短回调（一行）——数字字面量是唯一"不需要递归
就完整"的表达式。它经 emitConstant 走去重池，两个 `1` 在池里
是同一格（P2 反汇编的 0004 与 0032 行都是 `CONSTANT 1  ; 1`——
索引 0 里那个 0 是占位、1 是 i 的初值，两处共享索引 1 的 `1`，
肉眼可验）。

**identFn** 是全表唯一"一进两出"的回调：resolveLocal 命中走
GET_LOCAL（快路），否则 GET_GLOBAL（慢路）。**分流点就是名字
解析的全部语义**——第 14 章用一张绑定表说清的事，这里用两条
指令说清。注意两条路发码后都不弹栈：名字求值 = 把值压栈，消费
者是后续运算。

**groupingFn** 递归后吃 ')'——括号的意义在 Pratt 循环里已被
优先级消费，这里只剩"让解析继续"的语法义务。

**unaryFn** 先递归后发 NEGATE——**后缀序的教科书位**：操作数
的代码必须先落地，一元运算符殿后弹它。若写反（先发 NEGATE 再
递归），NEGATE 会弹到还没压上来的东西——单遍里这种错误在第
一条一元表达式上就炸，比中缀的漏吃更容易发现。

**binaryFn** 的三行结构（吃运算符、递归右操作数、发运算符）是
全部双目运算的公共模板，switch 只是选 opcode。**andFn/orFn**
不进这个模板（它们要控制流不是运算符）——表里它们的 infix 列
指向自己，prec 列把它们排在最松两档：**优先级就是"谁能把谁
圈进自己身体"的边界**（第 11 章 §9.2 的定义在发码语境下的直接
后果：&& 的右操作数里可以有 ||，反之不行）。

**callFn** 吃 '(' 后循环发实参（每参一次 expression，逗号驱动），
最后发 `CALL argc`——被调者的代码在它之前已由 identFn/groupingFn
压上。回调的栈效应收成一张表（编译器视角的 54 章 §54.3）：

| 回调 | 发码后的栈变化 | 语义 |
|---|---|---|
| numberFn | +1 | 字面量压栈 |
| identFn | +1 | 取值压栈 |
| groupingFn | ±0 | 透传 |
| unaryFn | +1-1 = 0 | 换栈顶 |
| binaryFn | -1 | 弹二压一 |
| callFn | -argc | 函数值换返回值 |
| andFn/orFn | 0 | 恒压一个 0/1 |

七行合计覆盖全部表达式形态——**表达式求值的栈守恒律**：任何
合法表达式序列执行后净效应恰是 +1（一个值），中间的波动即第 57 章的栈深账。编译器只要每回调照表发码，守恒自动成立——
**表驱发的纪律替代了逐例证明**。链式调用 `f(1)(2)` 自然工作：第二个 '(' 时左操作数（第一
次调用的产物）已在栈上，callFn 照发不误——**第 11 章"链式调用
不需要新机制"的结论在字节码层原样成立**。

第 11 章表到本章表的逐列对照（"没改什么"的精确版）：

| 列 | 第 11 章 | 本章 | 改动 |
|---|---|---|---|
| 前缀回调 | 返回 ExprP | 返回 void（发码） | 签名 |
| 中缀回调 | 吃左树返回新树 | 栈上已有左值 | 签名 |
| 优先级 | Prec 枚举 | Prec 枚举 | **零改动** |
| 结合性 | rightAssoc 布尔 | 左结合恒真（本语言无右结合） | 简化 |
| 表载体 | map&lt;Tok, Rule&gt; | switch 函数 | 载体（FAQ） |

五列里只有"优先级"零改动——**优先级是表的本质，其余都是
产物的包装**。三个里程碑章的表回归总览（第 9/54/55 章）：
第 11 章表上岗（建树，证等价于 LL 分层）；第 57 章表缺席（手编者
用人脑执行表的语义——fib 翻车就是人脑版表的 bug）；本章表复岗
（发码，证忠实于手编规格）。**一章定义、一章人演、一章机演**
——三步把"表"从教学概念变成生产构件，这条弧线是匠书线前半
部的叙事主脊。结合性简化（本章语言无幂无赋值表达式，全部左
结合）是表的瘦身；57 章 fun 字面量若带回结合（如 `x = fun…`
式赋值）要恢复该列。

同一张 Pratt 表在教程里已服务三个消费者，三代形态并排：

| 章 | 回调产物 | 表的用途 |
|---|---|---|
| 9 | AST 节点 | 结构（后续一切遍历的底座） |
| 13 | （ANTLR 建 AST，Pratt 未用） | —（对照组：生成器路线） |
| 54 | （人肉发码） | 手编者的心智模型 |
| 本章 | 字节码 | 执行（栈机的直接输入） |

三代里表本身一字未改（前缀/中缀/优先级/结合性四列），改的只有
回调身体的八行——**好接口的寿命比实现长**，这张表从第 11 章活
到本章、还将在第 60 章再上岗一次（fun 字面量的 Closure 发码）。

第三行藏着单遍的礼物：**括号在字节码里没有对应物**——
优先级已经在编译期被 Pratt 循环消费掉了，`(a+b)*c` 与 `a+b*c` 的
字节码差异只在于发码顺序。AST 时代的 `parenExpr` 节点（第 15 章
文法有、构建器透明处理）在字节码时代**彻底消失**——表示越低级，
语法糖的痕迹越少。

`parsePrecedence` 的十行循环是第 11 章 §9.3.2 的原样搬 运，值得
再走一遍因为它现在跑在"发码模式"下：进入即 `advance()` 把当前
token 吃进 prev_（回调靠 prev_ 自报家门）；查表取前缀回调执行
——**此刻操作数的全部代码已落地**；while 循环看 cur_ 的中缀规则，
优先级够就执行——回调内部先 `advance()` 吃掉运算符（**本节 bug
的主角**）再递归右操作数。循环每滚一轮，字节码往左长一截。与
建树模式的唯一差别是"落地"的形态：那章长的是 AST 节点（一次性
挂树），本章长的是字节（顺序进数组）——**递归结构不变，产物
从树变流**。

`binaryFn` 开头那行 `advance()` 值得单独说——它正是本章开发过程中
的第一个真 bug：中缀回调进入时，**运算符 token 还在 cur_ 没被吃**
（Pratt 循环只负责看，不负责吃；第 11 章的 `binary` 以 `advance()`
开头，移植时漏了）。症状是 `n == 0` 解析到 `==` 时把 `==` 当操作数
开头，报"期望表达式，但看到 '=='"。全程时间线留档：移植 Pratt
循环时照抄了"循环里查表执行回调"，漏抄了第 11 章 binary 首行的
`Token op = advance()` → 编译 P1 → 断言红在"判定"行（编译错误
而非通过）→ 读消息定位到行 3 的 `==` → 对照第 11 章 binary 签名
（它带 lhs 参数、内部先吃运算符）发现缺吃 → 补 advance → 全绿。
**十分钟的一生，浓缩了单遍调试的标准节奏：断言指路、消息定位、
对照先例（第 11 章）、最小修复**——四个真 bug 全走同一条路。**单遍编译器的 bug 全都长在
"token 流的位置"上**——因为没有 AST 可以对着查，位置错了就是全错。
这也解释了为什么单遍编译器的标准调试手段是"打印发码序列对照手推"
——本章反汇编断言（§55.6 第三组）就是制度化的这个手段。

**发码序即后缀序**（第 57 章 §54.3 的规则在编译器侧的自然满足）：
`binaryFn` 先递归发右操作数、再发运算符——递归保证右操作数的
全部代码先落地，运算符殿后，恰是 `左 右 OP` 的后缀序。第 57 章
fib 手编时"压栈序写反"的坑，在编译器里被**递归结构天然防住**
——只要回调按"先递归后发码"写，序就不可能错。把易错的决定交给
结构而不是注意力，这是编译器对手编的全部优越性所在。

**常量去重**：`emitConstant` 走 `addConstant`（第 57 章 §54.1 的
去重池）——`i = 1` 与 `i + 1` 里的 `1` 共享索引 0，反汇编里两行
`CONSTANT 0  ; 1` 一眼可验。名字表 `addName` 同样去重（`fact` 出现
两次只占一格）。两张表的对照：

| | 常量池 consts | 名字表 names |
|---|---|---|
| 存什么 | 值（整数、函数对象） | 字符串（名字） |
| 消费者 | CONSTANT 指令 | GET/SET_GLOBAL 指令 |
| 生命周期 | 与 chunk 同寿 | 同左 |
| 为什么分家 | 值宇宙（Value）没有字符串 | 56 章 ObjString 后可并 |

P2 里常量 0 承担三重身份，值得停一拍：**声明占位**（i、s 的
初始槽值）、**返回值占位**（return 0 的右值）、**去重锚点**
（三处引用共享池格 0）。一个字节码常量在程序生命周期里被三种
语法构造引用——**池的共享性把"值相等"上升为"格相等"**，这是
56 章驻留思想（值相等 ⇔ 指针相等）在常量层的又一次预演
（第 57 章埋的种子、本章发芽、56 章开花）。

顺带算一笔**常量池余量**：u8 上限 256 格，P2 只用 3 格（0、1、
10）。什么程序会爆？整数种类超过 254 个（每个不同字面量占一格）
或函数引用超 254 个——教学语料远不可及，但**爆了的行为**值得
预告：addConstant 返回的索引截断成 uint8_t 时静默回绕（取低
8 位），两个常量开始共享索引——**不是崩溃，是静默的常量串台**
（比崩溃更难查）。工业对策是 54 章说过的 EXTENDED_ARG 前缀或
宽索引变体；教学对策是"知道边界在哪，语料离边界远一点"。

分家的理由最后一行是诚实账：**表示能力不足导致的临时分表**，
56 章驻留表登场后两张表理论上可并（名字也是值）——届时"并还是
不并"变成纯粹的性能/清晰度取舍（分开保留各有专属操作数语义
也完全正当）。教学上先分后议，比先合后拆的教学曲线平缓。

从文法到发码表的翻译，第 11 章 §9.2.1 的三规则原样适用（开头
token→前缀、中部 token→中缀、右递归→右结合），本章只多一条
**第四规则：每个回调的"发码义务"表**——前缀回调负责把操作数的
值压上栈（CONSTANT/GET_LOCAL/GET_GLOBAL/递归），中缀回调负责消费
栈上已有值再压新值（运算符/调用/短路跳转）。四条规则在手，读者
可以给任意的运算符扩展做"编译器侧设计"：先填表（前缀还是中缀、
优先级、结合性），再写回调的发码义务，最后回填栈效应表（第 57 章 §54.3）——**三张表填完，实现是誊抄**。这套流程在练习 6
（JS 风格 &&）、第 60 章（Closure 指令）会各用一次。

**理论回扣**：第 12 章说过"**L 属性文法的翻译方案可以单遍求值**
——继承属性从左从上流入、综合属性一次向上归约"。本章编译器正是
这条定理的工程实证：Pratt 回调的"递归返回时发码"就是综合属性
的归约（子表达式的代码先合成、父运算符后发），语句嵌套的
"进入时 beginScope、离开时 endScope"就是继承属性的流动（作用域
深度从父语句传给子语句）。**单遍可行的文法条件（无左递归、无
需右侧信息的继承属性）与本章语言的形状一一对应**——读者若给
语言加"所有局部变量必须在使用前声明"的检查（单遍可做，直线
版），仍是 L 属性；而加"函数末尾必须 return"（需要看到函数尾
才知道——其实单遍也能做，编译到尾自然知道）；真正不可单遍的
是"函数调用的元数必须匹配"跨函数检查（被调函数在另一棵子树，
信息不在继承链上）——第 15 章四检查里恰好这一项在本章缺位，
**理论边界与实践缺口严丝合缝**。

本章的错误消息四条（D1–D3 加"期望表达式"）全部名词化带现场
（第 15 章家规），单遍特有的第四条家规是**消息必须可从"停在哪"
直接读懂**——用户拿到诊断时的第一反应是看光标位置，消息里的
"看到 'x'"正是那位置上的东西。多遍编译器可以给跨行上下文
（"该函数在此定义"），单遍没有回头路，**就地诊断是唯一形态**。

## 58.3　局部变量：槽位的编译期分配

第 57 章的帧协议说：局部变量住在"帧基 + 槽号"的值栈段里。本章
回答编译器侧的问题：**槽号从哪来**。答案是 `locals_`——一张编译
期的栈：

```text
locals_（编译期，函数内）          值栈（运行期，帧内）
[0] main      ← 槽 0 占位          base+0  函数值自己（Call 建帧时已在）
[1] i         ← 槽 1                base+1  i 的家
[2] s         ← 槽 2                base+2  s 的家
```

Compiler 的函数调用图（谁调谁，缩进为层级）：

```text
compile ── function ── statement ── varStmt/outputStmt/exprStmt
                        │            ifStmt/whileStmt/blockStmt
                        └─ expression ── parsePrecedence ── 七回调
           emitJump/patchJump/emitLoop（被语句层与 andFn/orFn 共用）
           declareLocal/resolveLocal/beginScope/endScope（作用域五件）
```

三层金字塔：顶层三行（compile/function）、语句层八函数、表达式
层九函数（表 + 七回调 + 循环）——**发码三函数与作用域五件是被
两层共用的横切服务**（纵着读是语法结构、横着读是公共设施）。

Compiler 的九个数据成员是单遍编译器的全部状态，清单表：

| 成员 | 类型 | 寿命 | 职责 |
|---|---|---|---|
| sc_ | Scanner | 整遍 | 字符源 |
| prev_/cur_ | Token | 一步 | 双 token 窗口（刚过+前看） |
| locals_ | vector&lt;Local&gt; | 一个函数 | 槽位表 |
| scopeDepth_ | int | 嵌套栈深 | 作用域深度 |
| fn_ | shared_ptr&lt;ObjFn&gt; | 一个函数 | 正在编译的目标 |
| prog_ | Program | 整遍 | 函数收集 |
| lastSlotPeak_ | int | 整遍 | 断言账 |

七个字段（另两个是 prev_/cur_ 的重复计数）里没有一个跨函数存活
——**单遍编译器的状态就是"当前函数的当前时刻"**，没有全局
AST 意义上的"整个程序"。这就是内存轴账面的微观来源。

`statement()` 的分派表是语句层的全部语法（六类一 defaulted）：

| 开头 token | 语句类 | 处理函数 | 发码特征 |
|---|---|---|---|
| var | 声明 | varStmt | 占位 CONSTANT |
| output | 输出 | outputStmt | PRINT |
| if | 分支 | ifStmt | 双跳转回填 |
| while | 循环 | whileStmt | JIF + LOOP |
| { | 块 | blockStmt | scope 进出 + POP |
| 其它（Ident） | 赋值 | exprStmt | SET_LOCAL/SET_GLOBAL + POP |

六行分派是普通递归下降（第 6/9 章的骨架），**表达式层才用 Pratt**
——两层两技术的分工在 FAQ 有专问。expression() 从语句层进来的
五种入口各记一笔：赋值右值（exprStmt）、output 右值、if/while
条件、return 右值、调用实参（callFn 内）——**五个入口同一个
函数**，表达式语法在全部语句位置上行为一致（语言的无缝性由
单入口保证；若每处各写一套解析，迟早出现"if 条件里不能用调用"
之类的怪方言）。

`compile` 的主循环只有三行（skip 到 Eof，逐个 function）——
**单遍编译器的顶层是最薄的**：没有"先扫一遍收集 X"的预循环，
没有"事后再处理 Y"的后循环，一个 for 结束全部工作。对照第 15 章驱动的三段瀑布（解析→检查→解释）——那是"多遍"的最小
形态；本章的三行是"单遍"的最小形态，两者的体感差距就是两章
主题的体感差距。

`function()` 的十步序列是编译一个函数的全部仪式：①吃函数名 →
②造 ObjFn（名字/空 chunk）→ ③locals_ 清场并压**槽 0 占位**
（函数名自己——第 57 章 base 指被调者的编译侧对应）→ ④形参
逐个 declareLocal（槽 1..arity——**形参的槽位由 Call 协议在运行
期自动填上**，不需要占位指令！这是形参与 var 的关键差别：var
要占位压栈，形参由调用方压）→ ⑤函数头 var 组逐个声明并占位 →
⑥beginScope → ⑦语句循环（statement 递归到各模板）→ ⑧endScope
→ ⑨吃 return、发右值、发 RETURN → ⑩吃 '}'、函数入表。每一步
都有明确的"编译期动作 + 发码动作"两栏——**单遍编译器的骨架
函数都是这个形状**：扫一点、发一点。

两栏**平行推进**：`declareLocal` 压 locals_ 一条，槽号就是下标；
`resolveLocal(name)` 从栈顶向下找名字（**最近包围层优先**——遮蔽
语义），命中返回下标即槽号。赋值语句 `x = e` 发 `CONSTANT/… e
SET_LOCAL slot POP`，读取发 `GET_LOCAL slot`——**名字在运行期彻底
消失**，字节码里只有数字。这是"静态绑定信息变成帧布局"的完全体：
第 14 章解析器算出"使用点 → 声明"的绑定表（给人看），第 15 章
环境链把名字留在运行期（动态查），本章编译器把绑定**烧进指令操作
数**（零运行期开销）。三步演进一张表：

| | 第 14 章 resolver | 第 15 章环境链 | 本章槽位 |
|---|---|---|---|
| 绑定时机 | 编译后独立遍 | 运行期逐次查链 | 编译期一次定死 |
| 运行期开销 | —（只诊断） | O(深度) map 查找 | 0（操作数即槽号） |
| 名字在运行期 | 无关 | 环境的键 | 不存在 |
| 支持嵌套函数 | 两层（扁平） | 任意（链） | 本章无嵌套（57 章上值接手） |

**声明即占位压栈**——本章开发时的第二个真 bug：最初 `varStmt` 只
登记 locals_ 不发码，结果 `GET_LOCAL 1` 执行时值栈上根本没有槽 1
（只有帧占位一格），断言 `__n < size()` 当场红。修复：声明处发
`CONSTANT 0`（占位），与第 15 章"声明即占位 0"的运行时口径、clox
的 `var` 发 `OP_NIL` 完全同构。**槽位必须在代码执行到任何使用点
之前已在栈上成形**——这是帧协议对编译器的硬约束；占位值 0 与第 15 章 FAQ 的讨论一样（占位的存在理由是实现的整齐，不是语义的允许
——确定赋值检查在单遍里没有位置，§55.7 如实对账）。

槽位的一生三阶段，用 P2 的 i 走一遍：**声明**（`var i, s`）——
declareLocal 压栈、占位 CONSTANT 0 落地，此时槽 1 在值栈上有了家；
**使用**（`i = 1`、`i <= 10`、`i + 1`）——每处 resolveLocal("i")
都从栈顶向下第一格命中，发 GET_LOCAL/SET_LOCAL 1；**消亡**
（函数 return）——帧整体消失，槽位随之。函数级的变量（i、s）
活满全函数；块级变量（P3 的内层 x）只活到出块——endScope 的
按数 POP 是它们唯一的葬礼。**编译期的 locals_ 与运行期的值栈段
平行生长、平行消亡**，这张对应表是本章版的"双账表"（第 15 章
§13.2.2 同款传统）。

**块级 var 与槽位回收**：进块 `beginScope`（depth+1），块内声明
挂当前 depth；出块 `endScope` 把 depth 更深的局部逐个弹出并**按数
发 POP**——槽位物理回收（值栈缩短），同名变量在下一个块里复用
槽号。P3 语料（内层 x 遮蔽外层 x）的账：声明外层 x 时 locals_ 长
到 2（占位+i）→ 内层再声明 x 长到 3（**峰值**，断言锁定）→ 出块
弹 1 条 POP、locals_ 回到 2 → 内层 x 的槽 2 此后可复用。**遮蔽的
代价是暂时的槽位翻倍，回收后无痕**——第 15 章 P5 演示过运行期的
遮蔽隔离（环境链版），本章是同一语义的编译期版，两章输出同构
（内 2 外 1）。

**同层重名拒绝**：`declareLocal` 查到同 depth 同名即抛"同层重复
声明"——第 15 章 V5 的口径原样搬来（先声明者保留的宽 版本差异
见 FAQ）。跨层同名合法（遮蔽）。**编译器的作用域检查与第 15 章
SemCheck 第一项是同一规则在两个时代的实现**——那章为树遍历解释
器服务（遍历 AST），本章为单遍编译器服务（边扫边查），规则本身
（最近包围、同层唯一）一个字没变。

`resolveLocal` 的遮蔽推演配一次全程（P3）：locals_ 从底到顶
[main(0), x(0), x(1)]——查 "x" 从顶向下第一格命中（内层 x，
depth1）→ 槽 2；出块弹到 [main, x] 后再查 "x" 命中槽 1。**查表
方向就是遮蔽方向**（第 14 章的"最近包围层优先"在第 11 章叫
"栈顶向下"，同一件事的三个名字：作用域、深度、查表序）。

三代名字绑定的性能账，拿 P2 的 `i`（十圈循环、每圈三次使用）
算实例：第 14 章绑定表（一次性遍历，运行期无关）；第 15 章
环境链（30 次 map 查找，每次 O(1) 常数 + 链跳零格——i 就在本层）；
本章槽位（30 次 `stack_[base+1]` 数组下标，**名字彻底不在运行期
出现**）。三代的差就是"绑定信息住在哪"的差：诊断文档里、堆上
的 map 里、指令操作数里。**表示越靠近指令，运行期越便宜、诊断
期越贵**（槽位版要打印"槽 1 是谁"得反过来查编译器表——反汇编
注释列就是这张反查表的输出）。

帧协议（54 章）对编译器的**硬约束清单**——本章代码处处受它
管辖，单独立表（每条注明违反后果）：

| 约束 | 编译器义务 | 违反后果（本章实测） |
|---|---|---|
| 槽 0 被函数值占位 | locals_[0] 填函数名，用户变量从 1 起 | 槽号全错位 |
| 槽位须在使用前成形 | 声明即占位压栈 | GET_GLOBAL 栈断言（bug #2） |
| Call 需被调者在实参下 | 发码序：被调者→实参→CALL | 栈形错、元数检查错 |
| Return 弹返回值清帧 | 函数尾必发 RETURN | "代码耗尽"运行错 |
| 出块槽位回收 | endScope 按数发 POP | 栈泄漏、深度漂移 |

五条全是 54 章的字节码语义，本章是"遵守方"——**两章对读的正
确姿势**：54 章读"协议为什么这样定"，本章读"编译器怎么守约"。
五条的"立法者"分别是：第 1/4 条 Call/Return 指令（54 章 §54.5）、
第 2 条本章 bug #2 的教训（槽位成形）、第 3 条栈形约定（被调者
在下）、第 5 条作用域语义（POP 即回收）——**协议不是天生 的，
每条都有出处**，出处即"违反它你写出的第一个 bug"（右列已经
实测过了）。

作用域深度的完整算术速查（P3 全程）：函数体 0 → 外块进（若
有）→ 内块 1 → 出内块 0 → ……全部进出的加减最终归零（函数
收尾 scopeDepth_ 必为 0，否则 begin/end 失配——**归零性是
作用域配对的守恒律**，编译器可在 function() 末尾加一行断言
自检，练习 1 的隐藏考点）。

两个 57 章的预告问题埋在此处（读者可先想）：**其一**，出块的
POP 若弹掉的槽位"正被某个闭包指望着"怎么办——本章语言无闭包
所以无此问，57 章的 CloseUpvalue 就是为这一刻设计的（POP 之前
先关闭）；**其二**，块内若无声明（P2 的 while 体块），begin/
endScope 空转是否浪费——不浪费：作用域进出是 O(1) 的整数增减，
发码为零（endScope 按弹除数发 POP，零个就零条），**空块的成本
停在编译期**。

jlox §22.4 的"声明与初始化之间"窗口，在本章语言里的两口径
对齐：jlox 允许 `var a = a;` 的 a 查到外层（声明在初始化**之后**
才生效——Resolver 的 declare/markInitialized 两步），clox 的
块级 var 在声明语句**之前**名字不可见（单遍天然序）。本章 TIP
口径：声明语句之前的同名使用**绑定外层或全局**（因为局部表里
还没有它）——与 clox 一致。三种语言三种窗口形状，第 15 章
"窗口分类学"（§13.5 归位表）的编译器版全部对上号。

## 58.4　全局与迟绑定：名字的两个世界

`identFn` 里 `resolveLocal` 未命中的名字去哪？`GET_GLOBAL 名字索
引`——运行期查 VM 的 `globals` 映射表。这张表在驱动里的注册时序
是关键：**全部函数编译完成后**，逐个 `globals[f->name] = 函数值`，
然后才 run。于是 `main` 里的 `later(2)`（later 定义在 main 之后）
在编译期只留下"名字索引"，执行期才在表里拿到函数——**迟绑定**
（late binding）。

早绑定与迟绑定的光谱，用"绑定信息放在哪个时刻"排：

| 绑定时刻 | 机制 | 本章例子 | 代价 |
|---|---|---|---|
| 编译期（指令操作数） | 槽位 | 局部变量 | 零运行期；不支持前向/动态 |
| 链接期（装载时填表） | 符号表重定位 | C 的外部函数 | 装载一步 |
| 运行期首次（查表缓存） | 内联缓存 | 本章函数表（每次查） | 每次 map 查找 |
| 运行期每次（可变） | 动态作用域/反射 | 本章全局表就是可变的 | 灵活与脆弱并存 |

光谱逐档配真实案例：**第一档**的极致是 C 的 `static` 局部——
编译期连地址都定了；**第二档**是 C 的 extern 函数（编译留符号、
链接填地址）与 Java 的常量池符号引用（类装载解析）；**第三档**
是 Self 语言发明的内联缓存（首次查表后把指令改写为直达——练习
4 复刻）与 Java 的 invokevirtual vtable；**第四档**是 eval、
反射、动态 require——每次执行都重新解析名字。**档位越靠右，
"名字"存活得越晚、系统越灵活也越难静态分析**——第 49 章 IFDS
到第 51 章 0-CFA 的全部动机可以读成"把第四档的事实往左档推"：
分析不改变运行机制，它改变**编译器敢把绑定提前多少**的信心。

前向引用的三种解法并列（本章选一，另两个是练习）：

| 方案 | 机制 | 代价 | 谁在用 |
|---|---|---|---|
| 迟绑定（本章） | 名字进代码、运行期查表 | 每次调用查 map | clox、动态语言 |
| 两遍收集 | 第一遍收函数名、第二遍编引用 | 编译两遍 | jlox、javac 的符号填充 |
| 占位回填 | 引用处发占位、编译完被调者后回填常量索引 | 回填簿记 | 55 章练习 3 |

三案的共同点：**都承认"单遍视角里未来不存在"，差别在用什么
兑换未来**——运行期的时间（查表）、编译期的第二遍（收集）、
编译期的延迟决策（回填）。练习 3 的方案其实是 54 章常量自引用
的自动版——手编者的上帝视角用回填在时间轴上模拟出来。

本章的函数表坐在第三档（每次 GET_GLOBAL 都查 map，无缓存）——
P5 语料（前向引用）就是它存在的理由。第四档的"可变"值得点破：
运行期往 globals 里塞新条目（本章赋值给未声明名走 `SET_GLOBAL`，
恰好给了这条路）就是动态语言"全局变量随手造"的实现面——**迟
绑定的表既是前向引用的救星，也是命名空间失控的门**。jlox §21 的
分层（定义先于使用报错、全局表按序可见）与 clox 的哈希表全局
（本章同款）是同一光谱上的两个取点，匠书两章对照的正是这对取舍。

## 58.5　跳转与回填：前向目标不存在怎么办

单遍编译器最漂亮的发明在本节。`if/else` 的字节码需要两个跳转：
条件假跳过 then 支、then 支末尾跳过 else 支。麻烦在于**跳转目标
在发跳转指令时还不存在**——then 支的代码要等编译器扫到那里才
发得出来。解法三步，叫**回填**（backpatching）。编译器作者的三步心理
活动值得替它说出来：第一步发占位时想"**这个洞我先记着**"（不
心虚——占位 0xFFFF 在反汇编里一眼可辨，漏补必被断言抓）；
第二步编 then 支时**完全忘掉那个洞**（占位的存在不干扰正常
发码——这就是把"欠账"外化成字节的好处）；第三步补账时想
"**现在我知道你该去哪了**"（此刻的代码尺寸就是答案）。三步
节奏 = 记账、忘账、清账——**把未来的不确定性装进两个字节**，
其余一切照旧，这是单遍技术的美学核心。先把三个函数的逐行账摆开
（读者对照 compiler.cpp 的原文读）：

基础三函数（emit/emitByte/emitConstant）一行带过但值得点名：
emit 与 emitByte 是**字节与行号的原子写**（所有发码的必经路），
emitConstant 是"去重 + 发索引"的组合拳——三个函数合计十行，
却 是全部字节码的**唯一出口**（单出口原则：想统计指令数加一行
计数，想改行号策略改一处——练习 8 的前提）。

`emitJump`：发操作码 → 发 0xFFFF 占位（writeU16 两字节）→ 返回
`code.size() - 2`——**偏移字段首字节的地址**。返回值是"回填凭据"：
编译器把它存进局部变量（jElse/jEnd），几行之后凭它回来改字节。

`patchJump(at)`：目标 = 当前代码尺寸 S → 偏移 = S - at - 2 →
两个字节分别写回 `code[at]`（高）与 `code[at+1]`（低）。**它不
追加任何字节**——只改两个已经存在的字节，这是"回填"与"发码"
的分界（发码推进 ip、回填改历史）。

`emitLoop(loopStart)`：发 LOOP → 偏移 = (Loop地址+1) - loopStart
+ 2 → writeU16 一次写死。**没有凭据、没有第二次**——后向跳转
的全部信息在发指令那刻已在手。

三个模板的凭据用量统计（回填技术的负担表）：

| 模板 | emitJump 次数 | patchJump 次数 | 凭据存活期 |
|---|---|---|---|
| if（无 else） | 2 | 2 | 短（数条指令） |
| if/else | 2 | 2 | 同上 |
| while | 1 | 1 | 中（整个循环体） |
| && | 3 | 3 | 短 |
| || | 3 | 4 | 短（jf 先兑现） |

五行的凭据全是不定长代码段——**存活期内编译器必须记得"我欠
一个地址"**（局部变量 jElse/jEnd 恰是债务簿）。凭据数即债务数，
债务清偿（patch）即模板完成——单遍编译器的记账本色彩在这里
最浓。

三个函数合计不足十五行，却是单遍编译器的**时间机器**：emitJump
把"未来"留成占位，patchJump 回来兑现。这个手法在后端同样通用
（两遍汇编器的符号表、链接器的重定位、JIT 的 inline cache 修补
——练习 4），**"占位与兑现"是编译技术的通用原语**，不止跳转
一家。词源与族谱：术语 backpatching 出自两遍汇编器时代——第一
遍收集符号地址、第二遍回填引用；链接器的重定位表（relocation）
是它的文件级形态（目标码留 R_X86_64_PC32 之类的洞，链接时填）；
Java 类装载的符号解析（constant pool 的 symbolic reference →
直接引用）是它的运行级形态。**三级（汇编器/链接器/装载器）共用
一个原语，因为它们共用同一个困境：引用先于目标**。本章的
emitJump/patchJump 是这个家族在教学尺寸上的最小标本。

```text
① emitJump(JUMP_IF_FALSE)：发 操作码 + 0xFFFF（占位），
   记住偏移字段的地址 jElse
② 编译 then 支（代码此刻落地）
③ patchJump(jElse)：把 0xFFFF 改成"当前位置 - jElse - 2"
   ——目标此刻存在了，账算得清了
```

if/else 的完整模板（P1 fact 的 if 支）：

```text
    条件发码
    JUMP_IF_FALSE -> else 开头   ← jElse（占位后回填）
    then 支发码
    JUMP -> 汇合点               ← jEnd（第二个占位）
else 开头:                        ← patchJump(jElse) 时点
    else 支发码（若有）
汇合点:                          ← patchJump(jEnd) 时点
```

**while 只有向后跳是免回填的**：循环尾的 `LOOP` 要跳回条件处，
条件的位置编译到循环尾时**早就知道**——`emitLoop(loopStart)` 直接
写死偏移。而循环**出口**（条件假跳出）仍是前向跳转，照旧占位
回填。所以一个 while 两种跳转技术各用一次：

```text
loopStart: 条件发码
    JUMP_IF_FALSE -> 出口        ← 占位回填（前向）
    循环体发码
    LOOP -> loopStart            ← 直接写死（后向）
出口:
```

拿 P1（fact）的 if 支把模板落到实地。源程序第三行 `if (n == 0)
{ r = 1; } else { r = n * fact(n - 1); }`，编译器产出（读者可
在驱动里加一行 disassembleChunk 核对）：

```text
GET_LOCAL 1          ; n（条件开始）
CONSTANT 0  ; 0
EQ                   ; n == 0
JUMP_IF_FALSE -> L1  ; 假：跳 else（占位回填）
CONSTANT 0  ; 0      ; r = 1 的右值（池里的 0 恰被复用）
SET_LOCAL 2
POP
JUMP -> L2           ; then 支收尾跳过 else（第二个占位）
L1: GET_GLOBAL 0  ; fact   ; else 支：被调者迟绑定
GET_LOCAL 1          ; n
CONSTANT 1  ; 1
SUB                  ; n-1
CALL 1
GET_LOCAL 1          ; n
MUL                  ; n * fact(n-1)
SET_LOCAL 2
POP
L2:                  ; 汇合点（patchJump(jEnd) 的落点）
```

对照模板逐点验证：两个占位（jElse/jEnd）恰在 else 开头与汇合点
回填；then/else 两支各以 `SET_LOCAL 2; POP` 收尾（同一 r 的两处
赋值）；`CALL 1` 之前的四行恰是"被调者 + 单实参"的栈形——第 57 章 Call 约定的编译器侧兑现。**递归调用走 GET_GLOBAL**（不是
常量）：fact 引用自己时局部表里没有"fact"（它是全局函数名），
迟绑定顺手把自引用也解决了——第 57 章常量池"函数自引用"的
手编形态，在这里换成了查表形态，语义等价、路径不同。同一段
fact 的两种产物并排（左边 54 章手编、右边本章机器编，取开头
六条）：

| 54 手编 | 55 机器编 | 差异 |
|---|---|---|
| GET_LOCAL 1 | GET_LOCAL 1 | 同 |
| CONSTANT 0 ; 0 | CONSTANT 0 ; 0 | 同（池去重生效） |
| EQ | EQ | 同 |
| JUMP_IF_FALSE ->13 | JUMP_IF_FALSE ->L1 | **地址→标号**（人读/机读） |
| CONSTANT 1 | CONSTANT 0 ; 0 | **多一条占位**（r 的声明） |
| JUMP ->25 | SET_LOCAL 2 … | 54 手编没编 r 的声明！ |

最后一行是本质差：**手编者跳过了声明（直接用槽），编译器忠实
翻译声明（占位+赋值两步）**——机器产物比手编"啰嗦"的那几条，
全部是语言承诺（声明语义）的体现。手编是最优的、编译是最忠的，
两者之差就是"优化器的工作清单"（第 41 章起逐项兑现：占位常量
被后续赋值覆盖 → 死代码消除的第一笔生意）。清单扩到三笔：
①占位 CONSTANT 0 在首个赋值后死亡（DCE 可删——但它压栈定形
了槽位，删了要改槽号，**优化与协议的纠缠**正在此，SSA 的 φ 正
是为解缠而生）；②while 每圈的 SET_LOCAL+POP 对（s=s+i 后紧跟
读取）是**寄存器化的候选**（第 61 章干涉图的原料）；③`i <= 10`
的 10 若换成循环不变量（如 n），外提（LICM）候选。**三笔生意
都在"两列之差"里明码标价**——对照表本身就是优化机会的勘探图。

while 的两种跳转技术对照收个尾：

| | 前向（出口 JIF） | 后向（回边 LOOP） |
|---|---|---|
| 目标存在性 | 发指令时**不存在**（体还没编） | 发指令时**已存在**（条件编过了） |
| 技术 | 占位 0xFFFF + 回填 | 直接写偏移 |
| 差一风险 | patchJump 公式 | emitLoop 公式 |
| 反汇编痕迹 | `JUMP_IF_FALSE -> 41`（41>19，向前） | `LOOP -> 14`（14<38，向后） |

循环的编译模板还有两派可行设计，与本派对照（真实编译器三派
并存）：

| 模板 | 形状 | 出口跳转 | 代表 |
|---|---|---|---|
| 本派（先条件） | cond; JIF 出; 体; LOOP 回 | 一次（假出） | clox、本章 |
| 出口先跳（guard） | JMP 入体; L: 体; cond; JIFt 回 | 一次（真回） | 部分老编译器 |
| 旋转循环 | 把 cond 复制/外提成 guard + 体尾重测 | 零（体尾直落） | 优化后的机器码 |

三派的差别在**条件的求值时机与次数**：本派每圈测一次、入口即
测（先假后零圈也正确）；guard 派先跳过条件直达体（保证至少一圈
的 do-while 语义顺带免费）；旋转派是优化器把本派改造成的双出口
单回边形态（第 43 章 preheader 的舞台）。**模板选择即语义选择**
——`while` 与 `do-while` 的差别在源语言层是两个关键字，在
编译层就是这两张模板。

**偏移的三笔账**（本章开发时踩了两笔，都是教科书级的差一）：
`patchJump` 的公式是 `目标 - at - 2`（at = 偏移字段首字节地址；
VM 读完操作数后 ip = at+2，加偏移恰达目标）——最初写成 `-3`，
差一，跳转落到指令中间，反汇编立即显示乱码。`emitLoop` 的公式是
`here - loopStart + 2`（here 是**发完操作码后**的尺寸 = Loop 地址
+1；VM 读完 ip = Loop地址+3）——最初写成 `+3`，又差一，循环跳回
条件中间三个字节，栈账爆炸。两个差一同源：**"读完指令后 ip 在
哪"这笔账，写编译器和写 VM 必须算同一遍**——本章的反汇编断言
（JIF -> 41、LOOP -> 14 与手推逐行一致）就是防止这类漂移的制度。

两个 bug 的完整复盘值得留档（它们是最好的教材）。**patchJump 差一**
的链条：公式写成 `目标 - at - 3` → JIF 落点比 41 少 1（0040，指到
GET_LOCAL 的操作数字节上）→ VM 把槽号当操作码执行 → 首轮就是
断言红，反汇编里跳转目标显示 40（与手推 41 差一）——**反汇编的
目标列是这类 bug 的秒杀器**：值对不对一眼见分晓。**emitLoop 差一**
更隐蔽：公式 `+3` 多算一字节 → LOOP 落点在 0013（POP 的操作数上）
→ 循环体被"切短"执行 → 栈账逐圈漂移，最终 `__n < size()` 断言
——**没有立刻炸，炸在若干圈之后**，这是差一 bug 最阴的形态
（错误不在案发现场）。修法都一样：回到"VM 读指令的机械动作"
（取码 ip+1、读两操作数 ip+3）重新对表。**写跳转公式的纪律：
先写 VM 侧的三行注释（取码/读数/加偏移），编译器公式从注释里
代数出来，不许心算**。示例（emitLoop 的正确推导全过程的注释
形态，读者可抄进自己的代码）：

```text
// VM 侧机械动作（LOOP 在地址 A）：
//   取码：ip = A + 1
//   读两操作数字节：ip = A + 3
//   回跳：ip = A + 3 - 偏移 === loopStart
// ∴ 偏移 = A + 3 - loopStart
// 编译器侧：emit 后 code.size() = A + 1（记 here）
// ∴ 偏移 = here - loopStart + 2
```

六行注释里没有一行是废话——两行机械、一行代数、两行换元、
一行结论。**注释写成推导链，公式只是最后一行**——差一类 bug
在这套纪律下无处出生。

**短路电路**（§23.4 的 C 风格布尔化方案）。两个模板的完整发码
图（Lf/Lr/Lf/Le 是标号，箭头指跳转去向）：

```text
a && b：                          a || b：
  <a 的代码>                        <a 的代码>
  JUMP_IF_FALSE Lf                  JUMP_IF_FALSE Lr
  <b 的代码>                        CONSTANT 1
  JUMP_IF_FALSE Lf                  JUMP Le
Lf: CONSTANT 0                    Lr: <b 的代码>
Le:                                 JUMP_IF_FALSE Lf
                                    CONSTANT 1
                                    JUMP Le
                                  Lf: CONSTANT 0
                                  Le:
```

左模板九行语义、右模板多一次"真直通"（a 真时压 1 直接跳尾）——
**短路运算符是把"值语义"翻译成"控制流"的翻译器**。两个模板
与 ifStmt 模板的家族相似值得点破：&& 的骨架（条件 + JIF + 支路
+ 汇合）与 if 完全同构，只是"支路"从语句变成了常量——**短路
求值 = 结果当常量的 if**。看穿这层相似，三个模板（if/&&/||）
就可以一个心算（if 的变奏）而不是三个记忆（三张图）——第 12 章"文法的同构子树共享翻译方案"的体感版；C 风格布尔化
（结果必 0/1）让两个模板都只需常量收尾，不用保留操作数原值
（JS 风格要保留，练习 6 的改造点）。`a && b` 发码为
`a; JIF Lf; b; JIF Lf; CONST 1; JMP Le; Lf: CONST 0; Le:`——
a 假则 b 的代码**完全不执行**（P4 的 7 与 8 缺席即证），双真压 1、
有假压 0。`a || b` 对称：`a; JIF Lr; CONST 1; JMP Le; Lr: b;
JIF Lf; CONST 1; JMP Le; Lf: CONST 0; Le:`。把 `a && b` 的六行模板配一次实际执行走读（P4 的 `0 && loud(7)`）：
CONSTANT 0 压 0 → JIF 弹 0 见假 → 跳 Lf（loud 的四行发码**整段
跳过**）→ CONST 0 压 0 → 落 Le。右侧的 output 一次没执行——
P4 期望输出里 7 的缺席就是这条路径的签字。四段语料的完整真值表：

| 表达式 | a | b | 路径 | 输出行 |
|---|---|---|---|---|
| 0 && loud(7) | 假 | 不求值 | 首跳直落 Lf | 只 0 |
| 1 || loud(8) | 真 | 不求值 | 首跳 CONST 1 | 只 1 |
| 1 && loud(9) | 真 | 求值、真 | loud 印 9，CONST 1 | 9、1 |
| 0 || loud(10) | 假 | 求值、真 | loud 印 10，CONST 1 | 10、1 |

四行覆盖两运算符 × 两路径的**全部组合**——语料设计的老规矩
（覆盖裁决，第 11 章 §9.5）：短路电路有两个自由度（左真假、右侧
是否执行），最少四段锁全。C 风格与 JS 风格的语义对照补在此处
（练习 6 的靶子）：

| 表达式 | C 风格（本章） | JS 风格（练习 6） |
|---|---|---|
| 5 && 7 | 1 | 7（右值透传） |
| 0 && 7 | 0 | 0（左值透传） |
| 5 || 7 | 1 | 5 |
| 0 || 7 | 0 | 7 |

右列语义在栈机上的实现反而**更省**（透传即"不弹不加"，模板
少两个常量收尾）——语义更"懒"，发码更短，这在语言设计里并不
罕见（懒与短常常结盟，因为都回避了"规整化"那一步）。两种
风格都遵守栈守恒律（表达式净 +1）：C 风格靠常量收尾压一格、
JS 风格靠透传留一格——**守恒的路径不同，守恒本身不破**，
这就是回调栈效应表（七行）作为不变式的价值：换风格只换行内
实现，不动表结构。对照 `1 && loud(9)`：
JIF 见真不跳 → loud(9) 执行（9 入输出）→ JIF 弹 9 见真 → CONST 1
→ JMP 越过 CONST 0。两条路径的输出（缺席/出席）正是短路语义的
可观察面。`orFn` 的四次回填值得逐个数（实现里 je1/je2/jf 三个
凭据）：jf 先补（指向 CONSTANT 0 的落点）→ 发 CONSTANT 0 →
je1/je2 后补（指向代码末尾）。**回填顺序由"目标何时确定"决定**：
假出口的目标在 CONSTANT 0 之前就确定了（Lf 就是它），而真出口的
目标要到全部代码落完才知道（Le 是末尾）——一次 orFn 里两种
时刻都出现，是回填技术的天然综合题。if/else 与 while 的回填
各自只有一种时刻，读者可对照归类。

两个模板各有两个
出口、三次跳转——**短路 = 用跳转把"右侧是否求值"变成控制流
问题**。与第 15 章 P6 的求值顺序讨论接上：那章说"求值顺序只有在
副作用可观察时才重要"，本章的短路正是把一类顺序（右侧跳过）做
成了语言承诺。

## 58.6　驱动、语料与期望输出解读

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 58 章驱动（无参运行，简单程序对账协议）：
//   一、编译诊断（单遍口径：错误即终止，报行号即止）；
//   二、程序输出对账（fact/while 和/块遮蔽/短路/前向引用）；
//   三、反汇编对账（while 循环函数的机器产物与手推逐行一致）；
//   四、编译期账（槽位峰值：块级遮蔽的回收）；
//   五、断言汇总。
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "chunk.hpp"
#include "compiler.hpp"
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

struct RunResult {
    std::string verdict;   // "通过" / "编译错误[行N] …" / "运行时错误 …"
    std::string output;    // output 行 + ret 行
    int slotPeak = 0;
    std::shared_ptr<tip::ObjFn> mainFn;
    tip::Program prog;
};

// 一段源程序的完整旅程：扫描+语法+发码（一遍）→ 注册全局表 → 跑 main。
RunResult journey(const std::string &src) {
    RunResult r;
    tip::Compiler c;
    try {
        r.prog = c.compile(src);
    } catch (const tip::CompileError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    } catch (const tip::ScanError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    }
    r.slotPeak = c.lastSlotPeak();
    r.verdict = "通过";

    std::ostringstream os;
    tip::VM vm(os);
    for (const auto &f : r.prog.fns) vm.globals[f->name] = tip::Value::ref(f);
    for (const auto &f : r.prog.fns)
        if (f->name == "main") r.mainFn = f;
    try {
        tip::Value v = vm.run(r.mainFn);
        os << "ret " << v.i;
    } catch (const tip::VmError &e) {
        os << "运行时错误 " << e.msg;
    }
    r.output = os.str();
    return r;
}

}  // namespace

int main() {
    std::cout << "== 一、编译诊断（单遍：错误即终止）==\n";
    {
        RunResult r = journey("main() { var x x = 1; return 0; }");
        check("D1 缺分号", r.verdict, "编译错误[行1] 期望 ';'，但看到 'x'");
    }
    {
        RunResult r = journey("main() { var x, x; return 0; }");
        check("D2 同层重复声明", r.verdict, "编译错误[行1] 同层重复声明：x");
    }
    {
        RunResult r = journey("main() { var x; x = 1 $ 2; return 0; }");
        check("D3 意外字符", r.verdict, "编译错误[行1] 意外字符 '$'");
    }

    std::cout << "\n== 二、程序输出对账 ==\n";
    // P1 阶乘——与第 15 章 P3 同源语料（共同子集，输出必须全等）
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
        check("P1 判定", r.verdict, "通过");
        check("P1 输出", r.output, "120\nret 0");
    }
    // P2 while 累加：1+…+10 = 55（反汇编对账与编译期账的主角）
    {
        RunResult r = journey(
            "main() {\n"
            "  var i, s;\n"
            "  i = 1;\n"
            "  s = 0;\n"
            "  while (i <= 10) { s = s + i; i = i + 1; }\n"
            "  output s;\n"
            "  return 0;\n"
            "}\n");
        check("P2 判定", r.verdict, "通过");
        check("P2 输出", r.output, "55\nret 0");
        check("P2 槽位峰值（槽0+i+s）", std::to_string(r.slotPeak), "3");
    }
    // P3 块级遮蔽 + 槽位回收（块级 var 是教学扩展，jlox 同款）
    {
        RunResult r = journey(
            "main() {\n"
            "  var x;\n"
            "  x = 1;\n"
            "  {\n"
            "    var x;\n"
            "    x = 2;\n"
            "    output x;\n"
            "  }\n"
            "  output x;\n"
            "  return 0;\n"
            "}\n");
        check("P3 判定", r.verdict, "通过");
        check("P3 输出（内 2 外 1）", r.output, "2\n1\nret 0");
        check("P3 槽位峰值（回收前 3）", std::to_string(r.slotPeak), "3");
    }
    // P4 短路：右操作数带输出副作用——短路路径下它一行都不印
    {
        RunResult r = journey(
            "loud(v) {\n"
            "  output v;\n"
            "  return v;\n"
            "}\n"
            "main() {\n"
            "  var r;\n"
            "  r = 0 && loud(7);\n"
            "  output r;\n"
            "  r = 1 || loud(8);\n"
            "  output r;\n"
            "  r = 1 && loud(9);\n"
            "  output r;\n"
            "  r = 0 || loud(10);\n"
            "  output r;\n"
            "  return 0;\n"
            "}\n");
        check("P4 判定", r.verdict, "通过");
        // 7 与 8 不出现 = 短路生效；9、10 出现 = 非短路路径照常求值
        check("P4 输出（短路：7、8 缺席）", r.output, "0\n1\n9\n1\n10\n1\nret 0");
    }
    // P5 前向引用：main 编译时 later 还没被编译——迟绑定的存在理由
    {
        RunResult r = journey(
            "main() { return later(2); }\n"
            "later(n) { return n * 10; }\n");
        check("P5 判定", r.verdict, "通过");
        check("P5 前向引用输出", r.output, "ret 20");
    }

    std::cout << "\n== 三、反汇编对账（P2 的 main）==\n";
    {
        RunResult r = journey(
            "main() {\n"
            "  var i, s;\n"
            "  i = 1;\n"
            "  s = 0;\n"
            "  while (i <= 10) { s = s + i; i = i + 1; }\n"
            "  output s;\n"
            "  return 0;\n"
            "}\n");
        std::ostringstream os;
        tip::disassembleChunk(*r.mainFn->code, "main", os);
        std::cout << os.str();
        // 手推逐行（正文给出完整推演）：赋值先右值后目标、JIF 占位经
        // 回填指向循环出口 37、LOOP 回边指向条件起点 10。
        std::string want = R"(== main ==
0000   2 CONSTANT 0  ; 0
0002    | CONSTANT 0  ; 0
0004   3 CONSTANT 1  ; 1
0006    | SET_LOCAL 1
0008    | POP
0009   4 CONSTANT 0  ; 0
0011    | SET_LOCAL 2
0013    | POP
0014   5 GET_LOCAL 1
0016    | CONSTANT 2  ; 10
0018    | LE
0019    | JUMP_IF_FALSE -> 41
0022    | GET_LOCAL 2
0024    | GET_LOCAL 1
0026    | ADD
0027    | SET_LOCAL 2
0029    | POP
0030    | GET_LOCAL 1
0032    | CONSTANT 1  ; 1
0034    | ADD
0035    | SET_LOCAL 1
0037    | POP
0038    | LOOP -> 14
0041   6 GET_LOCAL 2
0043    | PRINT
0044   7 CONSTANT 0  ; 0
0046    | RETURN
)";
        check("反汇编逐行（回填终态）", os.str(), want);
    }

    std::cout << "\n== 四、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（16 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
```

四组语料的考点表：

| 组 | 语料 | 考点 |
|---|---|---|
| 一 | D1 缺分号 / D2 同层重名 / D3 意外字符 | 单遍诊断：错误即终止 + 行号 |
| 二 | P1 fact / P2 while 和 / P3 块遮蔽 / P4 短路 / P5 前向引用 | 输出对账 + 槽位峰值 |
| 三 | P2 main 的反汇编全文 | 回填终态逐行锁定 |
| 四 | 汇总 | 16 项红绿 |

`journey` 的四步在本章有个新细节：**编译与注册分离**——compile
产函数表，驱动随后逐个注册进 VM 的 globals，最后取 main 运行。
注册这步是迟绑定的另一半：编译期欠的账（名字未定）此刻补齐
（§55.4 时序图）。另注意 compile 抛的两类错（CompileError/
ScanError）在 journey 里并轨成同一前缀——**用户不关心错在词法
还是语法，只关心哪行什么错**（第 15 章诊断分层的反面：那是多遍
架构的福利，单遍没有）。

**P1 与第 15 章的对接**：P1 的源程序与第 15 章 P3 **逐字符相同**
（两章的文法在公共子集上兼容：函数、var、if/else、块、return、
output、算术比较、递归调用——第 15 章的 fun 字面量本章没有、
本章的块级 var 第 15 章没有，交集恰是 P1 这段程序），输出同为
120。源程序原样贴出（两章一字不差）：

```text
fact(n) {
  var r;
  if (n == 0) { r = 1; } else { r = n * fact(n - 1); }
  return r;
}
main() {
  output fact(5);
  return 0;
}
```

同一段文本，第 15 章走 ANTLR→AST→环境链，本章走扫描→发码→
栈机——**两条流水线在同一文本上会师**，这就是共同语料的全部
仪式感；树遍历解释器与"单遍编译 + 栈机"
在同一个程序上签了等价字。这是证人网（第 57 章 §54.0 预告）的
第一次三方兑现：第 15 章（语义基准）、第 57 章（手编规格）、本章
（机器编译）。

**P2 到 P5 的逐段走读**（断言之外的语义注脚，每段先给"值得停
的一拍"再给结论）：P2 的 55 是十圈
累加（槽位峰值 3 = 槽0+i+s，块内无声明不涨）。前三圈的槽位账：

| 圈 | 进圈 i | s 动作 | i 动作 | 出圈 (i, s) |
|---|---|---|---|---|
| 1 | 1 | 0+1=1 | 1+1=2 | (2, 1) |
| 2 | 2 | 1+2=3 | 2+1=3 | (3, 3) |
| 3 | 3 | 3+3=6 | 3+1=4 | (4, 6) |
| … | … | … | … | (11, 55) 时条件假 |

末圈条件 `11 <= 10` 假 → JIF 跳 41 → PRINT 印 55——**循环的全部
语义在一张表加两个地址（14 与 41）里**。执行账顺手一算：每圈
条件 4 条（0014–0019）+ 体 10 条（0022–0038）= 14 条，十圈 140
条 + 头部 8 条 + 尾部 5 条 ≈ **153 条指令换一个 55**——栈机的
"按条计费"直观（树遍历同程序约几十次节点分派，字节码更细碎
但每条更便宜——两种账制的对比留给读者实测）；P3 的输出 `2 1`
与第 15 章 P5 同构——但那章是环境链隔离（两个节点），本章是
**槽位复用**（内层 x 用槽 2、出块 POP 回收、外层 x 仍在槽 1），
隔离的机制完全不同、可观察结果一致——**这正是"语义对账、实现
各异"的又一对样本**。P3 的槽位快照三时刻：

| 时刻 | locals_ | 值栈段 | 下一个 x 解析到 |
|---|---|---|---|
| 外层声明后 | [main, x@0] | [fn, 0] | 槽 1 |
| 内层声明后（峰值） | [main, x@0, x@1] | [fn, 0, 0] | 槽 2 |
| 出块后 | [main, x@0] | [fn, 0]（POP 弹掉一格） | 槽 1 |

三列并排就是"编译期表—运行期栈—解析行为"的同步舞步
（第 15 章 P5 与本章 P3 的"机制不同结果同"在此再加一行：那章
两个环境节点、本章一格临时槽位——**隔离的物理成本从一整个堆
对象降到一格栈槽**，语义输出分毫不动，这就是编译期表示的
复利）；
scopeDepth_ 的整数算术顺带走一遍：入函数 0 → 遇块 beginScope
为 1 → 块内声明挂 1 → 出块 endScope 减回 0 并弹 depth&gt;0 的
（恰那条 x@1）——**深度是纯整数、进出对称**，任何"深度算术"
错误（比如 ifStmt 忘记配对）会让 endScope 多弹或少弹，症状是
后续声明的槽号漂移、反汇编立即可见（又一处"账目防错位"）。P4 的六行输出已在上节走读（`loud` 函数的设计理由顺带交代：它
**身兼两职**——返回值参与逻辑运算、output 语句当副作用探针，
一个函数同时考"值路径"与"执行路径"，语料"一段多证"的老规矩）。
loud 的本体发码恰是"函数的最小完整形态"：GET_LOCAL 1（参数 v）、
PRINT（副作用）、GET_LOCAL 1（返回值透传）、RETURN——四条指令
覆盖取参、输出、回传、返回，**任何真实函数都是这四类的加长版**；
P5 的 `ret 20` 是纯返回值程序（无 output 语句的函数，只有返回值）——前向引用的迟绑定证据，同时它的
main 里 `later(2)` 发的是 GET_GLOBAL + CALL，一行的代价（查表）
换一整类的方便（任意顺序定义函数）。

**反汇编逐行导读**（第三组断言的 25 行）：0000–0003 两行
`CONSTANT 0 ; 0` 是 i、s 的**声明占位**（§55.3）；0004–0013 三组
"CONSTANT/SET_LOCAL/POP"是两条赋值语句的标准型（先右值后目标、
语句值 POP）；0014 起是 while——`GET_LOCAL 1; CONSTANT 2; LE` 是
条件，`JUMP_IF_FALSE -> 41` 指向出口（回填的痕迹：41 恰是 LOOP
之后那条指令的地址），0022–0037 是循环体两赋值加 `LOOP -> 14`
回边；0041 `GET_LOCAL 2; PRINT` 出口后打印；0044 `CONSTANT 0;
RETURN` 是 return 的右值占位与返回。把 25 行全部落表（地址 → 源行 → 产生它的编译器函数 → 语义注）——
这张表就是练习 7 的答案底稿：

| 地址 | 指令 | 源 | 编译器函数 | 注 |
|---|---|---|---|---|
| 0000 | CONSTANT 0 ; 0 | 2 | function/varDecls | i 的声明占位 |
| 0002 | CONSTANT 0 ; 0 | 2 | 同上 | s 的占位（去重同格） |
| 0004 | CONSTANT 1 ; 1 | 3 | exprStmt | i=1 右值 |
| 0006 | SET_LOCAL 1 | 3 | exprStmt | 写槽 1 |
| 0008 | POP | 3 | exprStmt | 语句值丢弃 |
| 0009 | CONSTANT 0 ; 0 | 4 | exprStmt | s=0 右值（又是那格 0） |
| 0011 | SET_LOCAL 2 | 4 | exprStmt | |
| 0013 | POP | 4 | exprStmt | |
| 0014 | GET_LOCAL 1 | 5 | whileStmt | 条件左元（回边目标） |
| 0016 | CONSTANT 2 ; 10 | 5 | binaryFn | 条件右元 |
| 0018 | LE | 5 | binaryFn | i <= 10 |
| 0019 | JUMP_IF_FALSE -> 41 | 5 | whileStmt/emitJump | 出口占位→回填 |
| 0022 | GET_LOCAL 2 | 5 | blockStmt 内 | s 读 |
| 0024 | GET_LOCAL 1 | 5 | | i 读 |
| 0026 | ADD | 5 | binaryFn | s+i |
| 0027 | SET_LOCAL 2 | 5 | exprStmt | |
| 0029 | POP | 5 | exprStmt | |
| 0030 | GET_LOCAL 1 | 5 | | i 读 |
| 0032 | CONSTANT 1 ; 1 | 5 | | 复用初值那格 1 |
| 0034 | ADD | 5 | binaryFn | i+1 |
| 0035 | SET_LOCAL 1 | 5 | exprStmt | |
| 0037 | POP | 5 | exprStmt | |
| 0038 | LOOP -> 14 | 5 | whileStmt/emitLoop | 回边直接写 |
| 0041 | GET_LOCAL 2 | 6 | outputStmt | 出口落点 |
| 0043 | PRINT | 6 | outputStmt | |
| 0044 | CONSTANT 0 ; 0 | 7 | function 尾部 | return 右值占位 |
| 0046 | RETURN | 7 | function 尾部 | |

表里两处"复用那格"（0002 与 0009 同池、0032 与 0004 同池）是
去重的直接可验面；三处 POP 的间隔恰是两条赋值语句加循环体两条
——**POP 的密度就是语句的密度**（表达式语句每条配一枚）。

**每一行都能在源程序里指出出处**——25 行落表就是这句承诺的
全部兑现（第 57 章"反汇编即文档"在编译产物上的验收）。

期望输出（节选）与验收点：

```text
; expected: expected/output.txt
== 一、编译诊断（单遍：错误即终止）==
ok   D1 缺分号 = 编译错误[行1] 期望 ';'，但看到 'x'
ok   D2 同层重复声明 = 编译错误[行1] 同层重复声明：x
ok   D3 意外字符 = 编译错误[行1] 意外字符 '$'

== 二、程序输出对账 ==
ok   P1 判定 = 通过
ok   P1 输出 = 120
ret 0
ok   P2 判定 = 通过
ok   P2 输出 = 55
ret 0
ok   P2 槽位峰值（槽0+i+s） = 3
ok   P3 判定 = 通过
ok   P3 输出（内 2 外 1） = 2
1
ret 0
ok   P3 槽位峰值（回收前 3） = 3
ok   P4 判定 = 通过
ok   P4 输出（短路：7、8 缺席） = 0
1
9
1
10
1
ret 0
ok   P5 判定 = 通过
ok   P5 前向引用输出 = ret 20

== 三、反汇编对账（P2 的 main）==
== main ==
0000   2 CONSTANT 0  ; 0
0002    | CONSTANT 0  ; 0
0004   3 CONSTANT 1  ; 1
0006    | SET_LOCAL 1
0008    | POP
0009   4 CONSTANT 0  ; 0
0011    | SET_LOCAL 2
0013    | POP
0014   5 GET_LOCAL 1
0016    | CONSTANT 2  ; 10
0018    | LE
0019    | JUMP_IF_FALSE -> 41
0022    | GET_LOCAL 2
0024    | GET_LOCAL 1
0026    | ADD
0027    | SET_LOCAL 2
0029    | POP
0030    | GET_LOCAL 1
0032    | CONSTANT 1  ; 1
0034    | ADD
0035    | SET_LOCAL 1
0037    | POP
0038    | LOOP -> 14
0041   6 GET_LOCAL 2
0043    | PRINT
0044   7 CONSTANT 0  ; 0
0046    | RETURN
ok   反汇编逐行（回填终态） = == main ==
0000   2 CONSTANT 0  ; 0
0002    | CONSTANT 0  ; 0
0004   3 CONSTANT 1  ; 1
0006    | SET_LOCAL 1
0008    | POP
0009   4 CONSTANT 0  ; 0
0011    | SET_LOCAL 2
0013    | POP
0014   5 GET_LOCAL 1
0016    | CONSTANT 2  ; 10
0018    | LE
0019    | JUMP_IF_FALSE -> 41
0022    | GET_LOCAL 2
0024    | GET_LOCAL 1
0026    | ADD
0027    | SET_LOCAL 2
0029    | POP
0030    | GET_LOCAL 1
0032    | CONSTANT 1  ; 1
0034    | ADD
0035    | SET_LOCAL 1
0037    | POP
0038    | LOOP -> 14
0041   6 GET_LOCAL 2
0043    | PRINT
0044   7 CONSTANT 0  ; 0
0046    | RETURN


== 四、断言汇总 ==
全部通过（16 项）
```

期望输出全文 78 行：反汇编占 27 行（含标题）、断言行 16、空行
分组 6、其余为多行断言的续行（如 P1 输出的 `ret 0`）——**结构
比数值更值得读**：哪个组最长（反汇编——形状锁定的成本）、哪个
组最密（二组——一 Program 两断言的节奏）。全文无一行人工修饰
（生成即最终）。

汇总行的自检性照例执行：16 项 = D 组 3 + P1×2 + P2×3 + P3×3
+ P4×2 + P5×2 + 反汇编 1——逐行可数（第 15 章立的传统）；期望
输出的行数分布：断言行 16、反汇编 27、续行与分组空行 35——
**断言密度约五分之一**，其余全是"给读者看的证据原文"。

16 项断言逐项清点（五组各尽其职）：

| 组 | 项 | 验收点 |
|---|---|---|
| 一 | D1/D2/D3 | 错误即终止、行号准确、名词化消息 |

D 组三条各考"单遍诊断的一个面"：D1 考**位置消费的次序**（consume
失败在 cur_、消息报 cur_.text——用户看到的是"下一个字符"不是
"出事前的字符"，单遍没有回头看的余地，消息与光标位置严格一致）；
D2 考**声明时机的检查**（declareLocal 的同层扫描只扫到本层——
更深层的同名不误伤）；D3 考**词法错误的传播路径**（ScanError 从
advance 里抛、穿透全部编译层、在驱动并轨——三层错误一个出口
的管道形状）。
| 二 | P1×2 | 与第 15 章同源语料输出全等（三方对账第二列） |
| 二 | P2×3 | 循环语义 + 槽位峰值 3（编译期账入断言） |
| 二 | P3×3 | 遮蔽语义与 13 章 P5 同构 + 回收账 |
| 二 | P4×2 | 短路四组合（7、8 缺席即铁证） |
| 二 | P5×2 | 前向引用（迟绑定的存在理由） |
| 三 | 反汇编全文 | 回填/占位/去重/槽位/行号折叠五合一 |

第三组整段反汇编被断言锁定后，**任何一处发码漂移**（多一条
POP、错一格槽号、跳转差一）都会在期望文本的逐字符比对中红掉
——这是比"输出对"更强的锁定（输出对只证明语义对，反汇编对
还证明**实现形状对**）。P4 的输出 `0 1 9 1 10 1` 是短路的三段
证词；P5 的 `ret 20` 单独成行（无 output 语句的函数，只有返回值）。

本章在证人网上的位置至此定格成一张三方对账表（先把四个语料
程序在四条路线上的现状排开——空格是尚未开通的航线）：

| | 第 15 章（树遍历） | 第 57 章（手编） | 本章（编译） |
|---|---|---|---|
| P1 fact 的产出 | 输出 120 | 输出 120 + 手推反汇编 | 输出 120 + 机器反汇编 |
| 名字解析 | 运行期环境链 | 人脑（手编者） | 编译期槽位表 |
| 跳转目标 | if 语句递归 | 人算偏移 | 回填自动算 |
| 各自独有 | 确定赋值等四检查 | 手编者的疼痛记忆 | 前向引用、块级回收 |

本章与第 18 章（TAC 生成）是"AST 消失"的两个平行样本，双列
对照收尾：

| | 16 章（AST→TAC） | 本章（源→字节码，无 AST） |
|---|---|---|
| 消失的表示 | 树降到四元组 | 树根本不建 |
| 名字的去处 | 临时变量 t1..tn | 槽位/名字表 |
| 控制的去处 | 基本块 + 跳转 | 字节偏移跳转 |
| 产物给谁用 | 分析与优化（第 28 章起） | 执行（第 57 章 VM） |
| 可回读工具 | 基本块打印 | 反汇编 |

两列在教程里永不相交（一个喂分析、一个喂执行），却在**表示
演化的方向**上完全一致：都朝着"名字更少、位置更实、结构更平"
走——这是"降级"（lowering）的通用方向，第 61 章指令选择再把
字节码/TAC 降到机器码，仍沿同向。

三列同答 120——语义证人网的第一次三方全等。第 60 章闭包语料
入场后这张表将扩成四列（上值 VM），届时"环境链 vs 上值"的实现
差在第 13/57 两列间直接对读。

与第 15 章的互见清单（两章对读的路标，六处）：

| 处 | 13 章 | 本章 |
|---|---|---|
| 名字 | §13.2 环境链 | §55.3 槽位表 |
| 声明占位 | §13.2 define(0) | §55.3 CONSTANT 0 |
| 遮蔽 | §13.2.1 P4/P5 | §55.3 P3 |
| 前向引用 | 全局函数表（构造期） | §55.4 迟绑定 |
| 元数 | §13.5 V3 静态/R1 运行时 | §55.7 能力表 ✘ |
| 递归 | §13.2.1 P3 | §55.5 fact 讲评 |

六处里前四处同构（机制换代表示）、后两处互补（各有做不到的）——
**对读的正确期待：结构认得出、边界看得见**。

三列背后是两种"作者观"：**树遍历解释器的作者是语义学家**——
它关心的每个问题（这个名字指谁、这个值住哪）都是数学问题，
实现只是数学的誊写；**编译器的作者是工程师**——它关心的每个
问题（这个槽几号、这个跳转多远）都是账目问题，语义在入账时
已经清了。第 15 章写代码像写证明，本章写代码像记账——**两种
气质读者都练过，才知道自己偏爱哪种**（这决定你更适合做语言
语义还是做编译工程——两种都是正当的职业选择，气质不同而已）。

## 58.7　单遍的代价与所得

把 §55.0 的对照表按本章实测逐轴填满——每轴一节，账算细。

**内存轴。** 多遍流水线的峰值内存 = 整棵 AST + token 流 + 各遍的
附加结构（第 12 章的属性表、第 14 章的绑定表、第 21 章的约束集，
全都"挂满全树"）。本章的峰值 = 一个函数的 locals_（P2 三格）+
常量池 + 名字表——**与程序长度线性、与函数长度才相关**：万行
程序里的每个函数都是编完即弃，局部表随 function() 清场。这是
64KB 时代单遍成为主流的直接原因（§55.7 末的历史段），也是今天
**流式编译**（边下载边编译，V8 的 StreamingParser）仍然单遍的
原因——流的另一端还没到，AST 永远不完整。

**错误恢复轴。** 单遍的"错误即终止"在 IDE 时代看着寒酸，但要看
清两件事：其一，**编译器诊断的正确性比数量更重要**——一条正确
的诊断胜过十条级联的误报（错误恢复的经典陷阱就是级联：第一个
错让语法器迷路，后面十条诊断全是对迷路的描述而非对新错误的
报告）；其二，现代单遍产品（clangd、rust-analyzer）的"恢复"其实
是**反复重编**——源码每变一次就重新单遍一遍，"恢复"被"重跑"
替代了。这个视角下，单遍+快重跑的组合在生产率上并不输多遍+
精细恢复，反而赢在一致性（每次诊断都来自完整的一遍，而不是
残缺状态上的猜测）。

**优化轴。** 发码即终态，意味着**编译器见到的信息只到当前 token
为止**。三个具体牺牲：跨语句的公共子表达式（`a = b*c; d = b*c;`
的第二处乘法——第 41 章 DAG 一眼可消，单遍看不见）；常量传播
跨语句（第 30 章 SCCP 需要 SSA 与迭代）；循环不变量外提（第 43 章 LICM 需要先识别循环）。**这正是字节码解释器与优化编译器的
分水岭**：JVM 的 javac 单遍产字节码（无优化）、优化全留给 JIT；
gcc 的 cc1plus 多遍产机器码（优化在 IR 上多轮）。本章走的是
javac 路线——字节码是"忠实的翻译"而不是"改进的程序"，改进
的资格（多轮变换）本教程在第 41–48 章（TAC/SSC 上）另案办理。
与第 15 章的**检查能力对照表**（谁在求值前拦得住什么）：

| 检查 | 13 章（树遍历+SemCheck） | 本章（单遍编译器） |
|---|---|---|
| 未声明使用 | ✔（作用域栈遍历） | ✔（resolveLocal+全局表兜底） |
| 同层重名 | ✔ | ✔（declareLocal） |
| 元数（直接调用） | ✔ | ✘（名字在运行期才解析） |
| 确定赋值 | ✔（数据流） | ✘（直线版都没有） |
| 前向引用 | ✘（也要两遍） | ✔（迟绑定） |

五行两列互有胜负——**没有免费的检查，只有搬家的时间**：13 章
把检查搬到求值前，本章把方便（前向引用）搬到运行期。语言设计
者对这张表的每一次行列选择，都是一次政策表态。

离"能用"还差的六件事（本编译器的诚实短板）：无元数检查（55 行
能力表 ✘ 的代价）；无类型（第 21 章领地）；无数组与记录（52 章
领地）；无字符串（56 章领地）；无闭包（57 章领地）；无数值边界
（溢出/除零仅除零有）。六件全有去处——**教程的篇章结构就是
这份短板清单的兑现计划**，读者按需跳章。

**编译快的产品账。** 启动时间在三类产品上是硬指标：浏览器首屏
（每个脚本多 10ms，亿级用户就是万秒级人时）、REPL 交互（回车到
出结果的延迟就是"语言手感"）、CI 增量构建（只变一个函数就只
重编一个函数——单遍编译器按函数为单位的天然增量性）。匠书给
clox 选单遍，教学理由之外还有个隐含的产品理由：**REPL 语言
（脚本语言）的用户永远在线等**，编译快不是锦上添花是门槛。

**与教程其余各篇的关系**收拢成表：

| 篇 | 关系 |
|---|---|
| 第二篇前端（3–12） | 本章是它们的"压缩版"：扫描=05、Pratt=09、作用域=12，各取所需 |
| 第三篇 IR 与运行时（15–23） | 13 章是语义基准（P1 同语料全等）；16 章 TAC 是另一条降级路线 |
| 第七篇变换（40–48） | 单遍明确放弃的优化资格，在那里用多遍拿回 |
| 第十篇字节码（57–60） | 本章是中坚：54 给地基、57 给闭包收尾 |
| 第十一篇代码生成（58+） | 字节码的栈效应表是表调度的约束来源之一 |
| 第 17 章（LLVM 执行台） | 同一 TIP 的第三种执行路径；本章语料的超集可在其对账 |

五行关系里最值得展开的是第二行：本章的"压缩版前端"不是重复
建设——05/09/12 章各讲了原理的一个完整侧面（自动机、优先级、
绑定），本章讲的是**它们在单遍约束下的组装**（同一批原理，换个
时序约束重装一遍）。读者的知识没有重复，重复的是**语料与断言**
——P1 同源程序第二次出现，检验的是读者的迁移而不是记忆。

（第三行的 LICM 那行反过来读也成立：第 43 章做优化时遇到"循环
识别"问题，回头看本章的 while 模板——回边 LOOP 指令就是最朴素
的"循环标记"，优化器在字节码上找回边的形状与本章编译器发回边
的形状互为镜像。）

**历史段补完**：BCPL 的 O-代码、Pascal-P 四遍到一遍的摇摆、C 的
PCC（"可移植"的实质是单遍结构对内存要求低）、Turbo Pascal 的
编译速度神话（一秒编完五万行，靠的就是激进单遍 + 常驻内存）——
前四十年的编译器史几乎就是单遍与多遍的拉锯史。拉锯的筹码是
内存价格：内存贵时单遍赢（能跑就行），内存便宜后多遍赢（优化
空间值钱），到了移动时代与流式场景单遍又回来（启动时间与内存
带宽重新变贵）。年代速查表（单遍拉锯史的骨架）：

| 年代 | 语言/编译器 | 取舍 |
|---|---|---|
| 1967 | BCPL O-code | 内存绝境，单遍求生 |
| 1970 | Pascal-P | 一遍扫（教学可读性优先） |
| 1979 | PCC（C） | 近单遍，符号两遍 |
| 1983 | Turbo Pascal | 单遍+常驻=一秒神话 |
| 1995 | Java javac | 单遍产字节码，优化留 JIT |
| 2010s | V8 流式 | 单遍回归（带宽/启动变贵） |

六行三代轮回（绝境求生→产品优势→回归），每一代的"贵"不同
（内存→启动时间→带宽）——**钟摆的锤不变，摆的支点在换**。

**技术选型的钟摆背后是成本结构的钟摆**——读者
做任何架构决定时，先问"我的成本结构里什么最贵"，本章的全部
取舍都是这个问题的一次完整作答。

**关于四个真 bug 的写法自审**：本章把开发期的四次翻车全部留档
（漏吃运算符、声明缺占位、两个差一），这在传统教材里罕见——
教科书习惯只呈现正确的代码，错误被当作"作者的成长隐私"。本
教程的立场相反：**错误是最浓缩的教材**——每个 bug 都精确暴露
一条机制的边界（回调协议的"谁吃 token"、帧协议的"槽位成形"、
跳转协议的"读后 ip"），正确代码反而藏不住这些边界。读者做
练习 9（错题本）时就是在复刻这套写法：**把私人的失败变成公共
的路标**。

## 58.8　FAQ、小结与练习

本章四条错误消息的设计评注（单遍诊断的全部库存）：**"期望 ';'
，但看到 'x'"**——期望与实见并陈（第 57 章家规"数字对不上端出
两个数字"的 token 版）；**"同层重复声明：x"**——带名字不带行内
位置（行号在统一前缀里，消息体保持可 grep）；**"意外字符 '$'"**
——词法错的名词化；**"期望表达式，但看到 '=='"**——bug #1 的
现场诊断（若读者复现练习 9 会再见到它）。四条消息没有一个
"错误"分类词开头——**第一条信息永远是现场，分类是读者的第二
步**，这 与第 4/12/13 章的诊断传统连成一线。

**问：compiler.hpp 里为什么把发码函数做成私有（emit/emitJump/
patchJump）而不是 public？** 单出口原则的类型系统版：所有字节
只能经这组私有函数出生（编译器的成员函数天然可访问），外部
（驱动）拿到的是成品 ObjFn——**字节流的写权与读权分离**（读
经 disassemble，公共）。权限设计即协议设计：public 化 emit 等于
宣布"谁都能往 chunk 里塞字节"，回填纪律立刻失去管辖。

**问：为什么错误恢复在单遍里这么难？** 恢复 = 出错后继续编译。
多遍里 AST 是持久结构，丢一个节点、同步到分号都做得到（第 4 章
ANTLR 的恢复策略）；单遍里"继续"意味着对**还没扫到的 token**
继续发码——发码依据的上下文已经错了，继续发只会产生一堆级联
错误。匠书的取舍：报第一条、停。IDE 时代的单遍编译器（clangd
的预编译流水线）靠"猜测补全"做轻恢复——那是另一个量级的工程。

**问：确定赋值真的不能单遍做吗？** 能做一部分：直线代码的传播
（赋值后标记）单遍可得；**汇合点信息**（if 两支都赋了吗）在括号
闭合时其实可得（两支的集合都留着）——真正丢的是**循环**（循环
体对入口状态的依赖是"求不动点"，一遍读不出第 57 遍的状态）。
所以严格说是"含循环的确定赋值不可单遍"。第 15 章的 while 规则
（进前 ∩ 出后）正是为单遍化设计的保守近似——但那是给**树遍历**
用的；本章干脆不做，边界更诚实。

**问：块级 var 为什么收进本章（TIP 原文法没有）？** 两个理由：
其一，槽位回收（endScope 发 POP）需要一个能演示"作用域有始有终"
的语言构造，块级 var 是最小选择；其二，jlox 有它，匠书 §22 的
原例（遮蔽、回收）都以它为舞台——取材忠实度优先。代价：本章节
点表（§55.3）多一列。第 15 章练习 3 让读者手做的扩展，本章给出
参考实现——**练习题变正文**是教程扩充的常规路径（第 11 章的幂
运算符同例）。

**问：反汇编断言为什么锁全文而不是抽查几行？** 抽查放过"行
数漂移"（多一条少一条 POP，抽查行仍对）；全文逐字符比对把
**长度、顺序、格式**三件事一起锁死。代价是期望文本脆弱（改
任何发码细节都要重生成）——但这正是想要的：**产物形状的任何
变更都应当是显式决定**（重新审视后落新的期望），静默漂移在这
套流程里没有出口。"脆弱的测试锁住稳定的设计"——第 15 章
字节一致契约的延续。

**问：addConstant 的去重是 O(池大小) 线性查——大池不就慢了？**
教学池个位数，无感；工业做法两级——**索引索引**（值 → 池位 的
哈希侧表，clox 不做、真实引擎做）或**按类型分池**（数字池/函数
池/字符串池各自去重，缩小线性域）。本章的线性版教学上反而好：
去重语义一眼读完。**性能修复的通用路径就是"给慢结构加索引"**，
而第 59 章的正题（散列表）恰好就是这个通用路径的完整一课。

**问：为什么 scanner 独立成文件（而不是编译器内联几个函数）？**
单遍是**纪律**不是耦合的借口：扫描器管"字怎么切"，编译器管
"切完怎么办"，两层的测试面完全不同（扫描器吃任意字符串、编译
器吃合法 token 流）。分层后每层可以单独换实现（练习：把 scanner
换成 DFA 版，编译器一行不改）。匠书把 scanner.c 独立成章（§16）
同理。

**问：占位 0xFFFF 有什么讲究？会被误认成合法偏移吗？** 0xFFFF
是"最容易在反汇编里认出来"的值（JUMP_IF_FALSE -> 65542 这种
明显荒谬的目标）。它**可能**恰是合法值吗？本章代码不会超过几
百字节，不会；真实编译器里 patchJump 还要检查"偏移不超过
u16"并报"函数体过大"——教学代码省略，但边界意识要交代。

**问：为什么 if/else 的 else 可选而 while 没有对应形态？** else
可选是**模板分支数**问题：无 else 时 ifStmt 里 else 支为空，
patchJump(jElse) 指向汇合点即可（模板自动退化）。while 的"除非
…否则"形态不存在于主流语言——它对跳转模板没有新要求（出口
仍是单点），纯语法糖问题，不构成本章话题。

**问：为什么不把 prev_/cur_ 换成 token 向量（更"现代"）？** 那
就是多遍——token 向量 = 整串源码的 token 化缓存，单遍的全部
内存优势建立在"只握两个 token"上。cur_/prev_ 的双格窗口是
LL(1) 需求的**精确配给**（多一格都是浪费，少一格不够用）——
"最小状态"不是洁癖，是单遍身份的定义。

**问：patchJump 为什么记"偏移字段地址"而不是"指令地址"？**
回填要写的是**偏移的两个字节**——凭据必须是那两个字节的地址
（at 与 at+1），而指令地址还得换算（+1）才落到字段上。记字段
地址让 patchJump 的公式少一次换算、且语义直白（"我要改的就是
这两个字节"）。反过来看 disasm：它从指令地址算字段（off+1）读
偏移——**写入端与读出端的换算方向相反**，两端各留一个换算是
最小配置，中间再传换算的凭据纯属多一道错位机会。

**问：块内声明的变量在反汇编里怎么区分"同名不同命"？** 区分不了
——反汇编只有槽号（内层 x 与外层 x 若同槽段会难以分辨，好在回收
后复用不并存；并存期（P3 遮蔽中）内层在槽 2、外层在槽 1，靠槽号
区分）。要看"谁是谁"得查编译器的 locals_ 快照——教学上这是
**编译期信息对运行期不可见**的正常代价，工业上靠调试信息格式
（DWARF 的变量位置表）补——那是"侧车表"的活，不在指令流里。

**问：为什么 expression() 是 parsePrecedence(None) 而语句层没有
优先级？** 优先级是**运算符之间**的序；语句之间只有**顺序**
（分号分隔）与**嵌套**（块/if 体）两种关系，没有"谁先结合"的
问题——所以语句层是普通递归下降（statement 的 switch），表达式
层才是 Pratt。**两层用两种技术，因为两层的问题不同**——这个
分工从第 6 章到本章没变过，变的是表达式层从分层函数换成了表。

**问：pop 两条的赋值语句（SET_LOCAL 不弹、再发 POP）为什么不
让 SET_LOCAL 直接弹？** SET_LOCAL 保留栈顶是"赋值表达式有值"
的承诺（第 57 章设计），本章语言赋值是**语句**（无值），所以每
条赋值语句都补 POP——看着冗余，但指令语义保持通用：将来语言
加赋值表达式（如 `x = y = 1`），SET_LOCAL 一字不改。**指令集为
语言的演化留通用性，冗余由编译器买单**——clox 同款取舍。三家
语言的对照补全这个判断：clox（赋值是表达式，SET_LOCAL 留值、
下游直接消费——POP 一条不浪费）；C（赋值表达式右结合，机器码
层面"计算+存+值可用"一气呵成，无独立 SET）；本章 TIP（赋值纯
语句，每条配 POP——最冗余也最直白）。**冗余的位置随"赋值在
语言里的地位"移动**，指令形状是语言形状的影子。

**问：clox 的 Pratt 回调带 canAssign 参数（允许把 `=` 认成赋值
表达式），本章为什么没有？** 因为 clox 的赋值是表达式（`a = b
= c` 合法、回调要问"这里允许出现赋值吗"——分组内允许、条件位
禁止），本章赋值是语句（exprStmt 显式吃 `=`，Pratt 表里根本没有
Assign 这个 token——**不需要问的问题不存在**）。这是"语言简化
回报编译器简化"的干净例子：删一个语言特性，表少一列、回调少
一参、FAQ 少一问。

**问：把本编译器对同一段源码编译两次，产物逐字节相同吗？**
相同——没有随机性、没有地址依赖（名字表与常量池按首次出现序
分配）、时间戳不存在。**确定性编译**（reproducible build）的
最小条件不过如此；真实工程要对抗的（内嵌路径、链接序、随机
种子）本章天然免疫——教学实现的红利之一。

**问：数字扫描有溢出保护吗？** 没有——tk.num 按 long long 累积，
超长数字串静默回绕（教学语料不会遇到）。工业做法：超阈值即报
"整数太大"（javac 的 integer number too large）。**单遍扫描器
的每个"没有"都该有个"什么时候会有"**——这一问的答案留给
读者加三行代码（num &lt; 上限判断）。

**问：前看只有一个 token（cur_），够吗？** 够，因为语法是 LL(1)
形状的：语句层的分派只看开头 token（statement 的 switch）、表达式
层的攀爬只看运算符 token（Pratt 循环）——任何决定都不需要看
第二个未来的 token。这是**语言文法的设计红利**（TIP 的 stmt 备选
首 token 互异）；若语言有 `x * y` 与 `x * *p` 的歧义，单前看就
不够了——C 的 typedef 名问题（第 6 章提过）正是反例，C 编译器
为此背着符号表问"这个标识符是不是类型名"。

**问：fact 的递归引用为什么走 GET_GLOBAL 而 54 章手编走常量池？**
两章的"函数值在哪"口径不同：54 章手编时 fact 的 ObjFn 已存在，
直接进池（自引用环）；本章编译 fact 时**它自己还没编完**——
ObjFn 尚不存在，能写进代码的只有名字（名字表 + 迟绑定）。这是
**自引用问题的两种分期**：手编者有上帝视角（一切已存在），
单遍编译器只有时间视角（存在先于引用才可直引）——57 章的
Closure 指令将用"捕获表 + 回填"给字面量自引用第三种答案。

**问：单遍编译器怎么写测试？** 本章示范了三层：**产物断言**
（反汇编逐行——形状对）；**语义断言**（输出对账——行为对）；
**诊断断言**（D 组——错误对）。三层各挡一类回归：改发码顺序
第一层红、改语义第二层红、改消息文案第三层红。缺了第一层的
单遍编译器测试（只对输出）会放过大量"行为对但实现漂"的改动
——而单遍的实现漂移正是下一处 bug 的前兆。加一条**突变测试**
的手工版：故意把 binaryFn 的"先递归后发码"改成"先发码后递归"，
看哪层断言先红（答案：第二层——语义错但反汇编仍"合法形状"，
这说明产物断言挡不住**语义性**突变，三层缺一不可）。 本章示范了三层：**产物断言**
（反汇编逐行——形状对）；**语义断言**（输出对账——行为对）；
**诊断断言**（D 组——错误对）。三层各挡一类回归：改发码顺序
第一层红、改语义第二层红、改消息文案第三层红。缺了第一层的
单遍编译器测试（只对输出）会放过大量"行为对但实现漂"的改动
——而单遍的实现漂移正是下一处 bug 的前兆。

**问：函数末尾缺 return 会怎样？** 本章文法把 return 定为必经
（consume(Tok::KwReturn) 直接报"期望 'return'"）——TIP 的尾
return 文法（第 15 章 §13.4）在编译器侧的落实。若语言允许省略
（jlox 允许），编译器要在函数收尾处**补发** `CONSTANT 0; RETURN`
（隐式返回 nil 的字节码版）——clox 正是这么做的。**文法的宽容
由编译器的补发买单**，与 SET_GLOBAL 的宽容同构。

**问：编译器为什么不查"if 写了条件没写体"这类半成品语法？**
查了——consume 链就是查法：ifStmt 吃完 ')' 必进 statement，
体缺失时 statement 的第一道 consume 立刻报（"期望语句，但看到
'}'"式）。**递归下降的 consume 链天然是语法完备性的守护**：
每个非终结符的每个语法位都有 consume 把守，"半成品"在最近
的把守处落网。真正漏网的是**语义半成品**（写了体但条件恒真
之类）——那是分析器（第 28 章起）的领地。

**问：REPL 模式要改多少？** 三处：compile 改成逐行（源传一行）；
全局表跨行保留（本版驱动每个 journey 重建，REPL 里 globals 是
会话级）；main 入口约定改成"有 output 就打、无则回显值"。核心
（编译器+VM）一行不改——**本章的分层在 REPL 场景下的回报**。

**问：SET_GLOBAL 一条指令撑起了"赋值给未声明名即造全局"，要不要
禁止？** jlox 禁（编译期报"未声明"），clox 不禁（赋值即定义）。
本章选择 clox 口径但语料不触发——留作练习 5 的辩论题。**语言的
宽容度是政策问题，不是技术问题**——技术只标出价签。

**伏笔索引**（本章埋向后文的接点）：

| # | 埋点 | 后文兑现 |
|---|---|---|
| 1 | GET_GLOBAL 运行期查 map | 56 章手写散列表替换 map |
| 2 | 名字表独立于常量池 | 56 章 ObjString 与驻留正式登场 |
| 3 | 占位 0xFFFF 与回填 | 57 章 Closure 捕获表同款两段式 |
| 4 | 局部槽位与帧协议 | 57 章上值索引（槽位变"栈地址或盒子"二相） |
| 5 | emitLoop 差一教训 | 57 章回边与上值链的地址敏感操作 |
| 6 | 块级 var 与 POP 回收 | 57 章 CloseUpvalue 在同一点触发关闭 |
| 7 | SET_GLOBAL 宽容政策 | 56 章全局表实现（题 5 的辩论场） |
| 8 | 单遍放弃的优化资格 | 41–48 章在 TAC/SSA 上拿回 |
| 9 | P1 三方对账 | 57 章闭包语料扩成四方 |
| 10 | 确定赋值边界 | 13 章已有 vs 本章明确放弃的对照写进能力表 |

**clox 与本章的逐项对照**（取材忠实度的总账）：

| 环节 | clox | 本章 | 差异原因 |
|---|---|---|---|
| 扫描器 | scanner.c 三函数 | scanner.cpp 同款 | 同构 |
| 表达式 | Pratt 函数指针数组 | switch 函数 | C++ 成员指针载体 |
| 局部 | locals 数组 + depth | vector&lt;Local&gt; | 同构 |
| 全局 | 哈希表（§20 手写） | std::map | 56 章再手写 |
| 跳转 | emitJump/patchJump | 同名同义 | 教学直译 |
| 短路 | JIF 不弹 + 显式 POP | JIF 弹 + 常量收尾 | 54 章指令集既定 |
| 错误 | error() 长跳 | C++ 异常 | 语言习惯 |

七行里六行同构、一行因指令集历史（54 章 JumpIfFalse 定为弹）
走岔——岔路的代价与收益都在 §55.5 的短路模板里算清。**取材的
忠实不是抄写，是把每个岔路标在账上**。反事实补一笔：若第 57 章当时选了 clox 的"不弹"语义（条件留在栈、分支后显式 POP），
本章 if/while 模板各多一条 POP（岔路代价换了个位置），而短路
模板反而少两个常量收尾（透传式短路变成 clox 的原版）——**指令
集的每个"一字之差"都会在几十行外的模板里结出不同的果**，
这正是"ISA 是编译器的第一合同"的体感版。

伏笔十行里三条最要紧（其余见第 60 章回收）：**第 3 行**（占位
回填→捕获表）——57 章 Closure 指令的操作数编码捕获表（isLocal
位 + 索引，每捕获一个占两字节），编码本身又是一次"占位后填"
（编译 fun 字面量时外层槽位号已知、运行期才绑定盒子）；**第 6
行**（POP→CloseUpvalue）——endScope 的那一声 POP 是 57 章
改造的爆破点（弹栈前先问"谁在指着这格"）；**第 4 行**（槽位
→上值索引）——GET_LOCAL 的槽号在 57 章变成"槽号或上值号"的
二相寻址（编译期知道走哪相，运行期各走各的表）。三条伏笔共同
预告：**57 章不改本章的表与模板，只在三个点上挂钩**——分层
结构的又一次验收。

**教材级的三个"如果给读者上课"**（教学法的自注）：讲本章最优
的三个停顿点——①在 emitJump 之后停，让学生手推"JIF 的偏移该
是多少"再讲 patchJump（差一 bug 的预防针）；②在双列 fact 对照
处停，让学生自己找差异（发现占位声明的意义）；③在 P4 之前停，
让学生预测输出再跑（短路的可预测性检验）。三个停顿的共同
逻辑：**在机器给出答案前，先让脑子出价**——本教程"先预测后
对账"的一贯法度，在课堂上就是这三处停顿。

**与匠书原章的映射**：§16 → §55.1；§17.5 → §55.2；§21 → §55.4；
§22 → §55.3；§23.1–23.3 → §55.5；§23.4（短路）→ §55.5 末；
§23.5（while）→ §55.5。差异三处如实：本章语言无类/继承（52 章
的领地）、比较集带全（第 11 章扩展口径）、块级 var 的实现给了
完整代码（原书散在两章）。原书三节的标题直译与本章对照：
Scanning on Demand（按需扫描）= §55.1；Compiling Expressions
（编译表达式）= §55.2；Jumping Back and Forth（来回跳）=
§55.5——标题的"来回"二字正是回填与回边的双人舞，中文章名
"跳转与回填"取其一半、留一半在正文里跳。

**一套自测语料**（读者自查用，各一行源码）：`main() { var x;
x = 0 - 3; output x * x; return 0; }`（负号路径，答案 9）；
`main() { var i; i = 0; while (3 > i) { output i; i = i + 1; }
return 0; }`（倒序条件写法，答案 0 1 2——顺便练"翻写比较方向"）；
`f(a) { return a; } main() { output f(f(f(6))); return 0; }`
（嵌套调用三层，答案 6——调用栈形的三明治）。三段都过脑子者，
读法建议就只剩"按序读"了。

**读法建议**：赶时间者读 §55.0 对照表 + §55.5 回填三步 + 小结；
实现者按"底座四文件 → scanner → compiler 的 function/parsePrecedence/
emitJump 三组 → 驱动"的顺序跟码；从匠书来的读者按映射表对号，
重点看三处差异与四个真 bug 复盘（它们是原书没有的、本教程的
增量教学资产）。

**向后两章的衔接预告**（第十篇内部）：第 59 章取走两样本章的
现成构件——GET_GLOBAL 背后的 `globals` 映射（换手写开放定址
散列表，FNV-1a + 墓碑 + 扩容三状态机全套上身）与名字表分家的
争论（ObjString 入场后的并表决策）；第 60 章取走三样——发码
骨架（fun 字面量回 Pratt 表，Closure 指令带捕获表编码）、回填
手法（捕获表的"先占位后补"同款）、块级 endScope 的那声 POP
（升级为 CloseUpvalue——出块不再是单纯弹栈，要先问"有没有闭包
正指着这格栈"）。**56/57 两章对本章代码的复用清单**（"本地副本"制的具体账）：

| 复用件 | 56 章 | 57 章 |
|---|---|---|
| scanner | 整份复制 | 整份复制 |
| chunk/vm 四件 | 复制（散列表替换 map） | 复制（加上值六指令） |
| Pratt 表 | 不动 | 加 fun 前缀回调 |
| ifStmt/whileStmt | 不动 | 不动（CloseUpvalue 挂在 endScope） |
| journey 驱动 | 改注册（驻留表） | 改语料（闭包集） |

七行里"不动"占多数——**地基质量的衡量标准就是后继者改多少**
（54 章冻结纪律的验收指标）。**本章代码在 57 章的改造量约等于
54 章在本章的增量**——三段式递进的最后一段，所有伏笔在那一章
收口。

**三个"如果"**（语言演化对编译器的冲击预演）：**如果加赋值
表达式**（`x = y = 1`）——exprStmt 的 IDENT '=' 形态要升级为
Pratt 右结合中缀（优先级最低、右结合——第 11 章表的右结合列
复活），SET_LOCAL 不弹的设计立刻兑现价值（栈上留着值给外层）；
**如果加数组**——下标 `a[i]` 是新中缀（第 11 章字段访问的兄弟），
但**取地址/存元素要两条指令**（GET_INDEX/SET_INDEX）且帧协议要
认识"数组长度"（越界检查的归属是 VM 还是编译器——第 45 章边
界检查的伏笔）；**如果加类**——方法表进 ObjFn 的姐妹 ObjClass，
第 55 章 vtable 与匠书 §30–32 的 bound method 在编译器侧只是
"多一张查表"。三个如果的共同教训：**语言特性进编译器的路径
永远是"表加一行、协议加一员、VM 加一个 case"**——本章的三层
结构（表/协议/循环）就是为此设计的。

**第十篇的依赖图**（三章互借的全部路径）：

```text
54 章（冻结）──Op 枚举、帧协议、反汇编格式
   ↑ 副本+增量            ↑ 副本+增量
55 章（本章）──表/模板/回填 ──→ 57 章（上值收口）
```

箭头全是"本地副本"（每章自带全套源码），增量各自追加——**共
享靠纪律（冻结）而不靠引用（无跨目录 include）**，这是教程
"每章自包含可独立构建"的全局决定在篇内的体现（代价：三份
vm.cpp；收益：任何一章可单独抽出教学）。

**从第 11 章到本章的一句话纵览**：第 11 章教你一张表怎么让解析
不再手写层级，第 57 章教你指令集怎么让执行不再遍历树，本章把
两课合体——**表产指令、指令进机器，中间的 AST 整个消失**。
三个里程碑连成的那条弧，就是"从文法到机器"的完整抛物线。

**本章的三张表**（表驱动方法的总账）：**规则表**（Pratt 表——
语言是什么）、**效应表**（回调栈效应——发码守恒律）、**凭据表**
（模板回填统计——债务簿）。三张表分别回答"语法怎么走、栈怎么
守、账怎么清"——**单遍编译器的全部正确性悬在三张表的一致上**
，实现代码只是三张表的执行器。这个"表先于码"的设计观是本章
最值得带走的工程习惯（第 11 章立、54 章用、本章集大成）。

**小结**：单遍编译器 = 即取即用扫描器 + Pratt 发码表 + 编译期
槽位表 + 名字分两界（局部槽位/全局迟绑定）+ 跳转回填。第 11 章
的表、第 57 章的指令集、第 12/13 章的作用域规则在 这里全部
会师：**本章没有发明任何新理论，它把前三章的决定自动化了**——
这正是它作为"收官性一章"的意义。四个开发期真 bug（中缀回调漏
吃运算符、声明不发占位、patchJump 差一、emitLoop 差一）全部留
在正文当教材：单遍的 bug 都长在"位置与差一"上，反汇编断言是
它们的制度性克星。

**术语表**：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| 即取即用 | 无 token 缓冲，编译器要一个取一个 | §55.1 |
| 最小状态 | 双 token 窗口即 LL(1) 的精确配给 | FAQ |
| 单遍身份 | 状态只有"当前函数的当前时刻" | §55.3 |
| 发码序 | 后缀序：先递归右操作数后发运算符 | §55.2 |
| 槽位表 | locals_ 编译期栈，下标即运行期槽号 | §55.3 |
| 声明占位 | 声明处发 CONSTANT 0 使槽位成形 | §55.3 |
| 槽位回收 | 出块按弹除数发 POP | §55.3 |
| 迟绑定 | 名字解析推迟到运行期查表 | §55.4 |
| 回填 | 前向跳转先占位后改写 | §55.5 |
| 短路电路 | 用跳转把"右侧是否求值"变成控制流 | §55.5 |
| 占位兑现 | emitJump/patchJump 的通用原语（链接器同款） | §55.5 |
| 声明占位 | CONSTANT 0 使槽位成形 | §55.3 |
| 确定性编译 | 同源必同产物的性质 | FAQ |
| 内联缓存 | 运行期把查表指令改写为直达 | 练习 4 |
| 流式编译 | 边读入边编译（单遍的现代形态） | §55.7 |
| 错题本 | 最小复发语料 + 症状 + 根因的私人手册 | 练习 9 |
| 债务簿 | 回填凭据的局部变量集合 | §55.5 |
| 守恒律 | 表达式发码净效应恒 +1 | §55.2 |
| 归零性 | scopeDepth_ 函数收尾必回 0 | §55.3 |
| 双 token 窗口 | prev_ 与 cur_ 的最小前看 | §55.1 |
| ISA 合同 | 指令集语义对编译器的硬约束集 | §55.3 |

**自查清单**（十二问，产出型自查在前）：

1. 单遍与多遍的三轴取舍（内存/恢复/优化）各输在哪？
2. 即取即用协议是哪三个函数？行号为什么必须在扫描器记？
3. Pratt 表从第 11 章搬来改了什么、没改什么？
4. `identFn` 的分流条件是什么？两条路各发什么指令？
5. 声明为什么要发占位常量？不发会怎样（本章真 bug #2）？
6. 块级遮蔽的槽位账：峰值几格、出块后几格、POP 几条？
7. 迟绑定为什么是前向引用的唯一出路？它同时打开了什么门？
8. patchJump 与 emitLoop 的公式各是什么？"差一"的根源在哪？
9. while 里哪次跳转要回填、哪次不要？为什么？
10. `a && b` 的发码模板默写得出来吗？短路如何被 P4 证明？
13. （加答）"最小状态"与"单遍身份"两个术语各自的所指？
    （双 token 窗口；无跨函数存活的状态。）
11. 双列 fact 对照表的最后一行差异说明什么？（手编最优、编译
    最忠、差即优化清单。）
12. 回填原语的三个工业亲戚各是谁？（汇编器符号、链接器重定位、
    装载器符号解析。）

**练习**：

1. ★ 给文法加 `else if` 链（提示：else 后跟 if 即嵌套 ifStmt），
   用三段链语料验证跳转模板的嵌套回填。
2. ★★ 单遍直线版确定赋值（放弃 while）：给编译器加"使用前未赋值"
   诊断，构造一条 while 语料展示它失效——失效的根源写成注释。
3. ★★ 把 `GET_GLOBAL` 的运行期查表改成"编译期看到名字先记号、
   全部编译完后由驱动回填函数常量索引"（二级回填）——P5 还能过
   吗？前向引用与回填的边界在哪里？（提示：函数表编译完才齐。）
4. ★★ 加内联缓存：GET_GLOBAL 首查后把指令改写为 DIRECT_CALL
   （新指令：操作数=函数常量索引）——P5 跑两遍观察第二次的反汇编。
   （这就是 Self/JS 引擎 inline cache 的骨架。）
5. ★（辩论）SET_GLOBAL 的宽容政策：写两段各 10 行的程序（一段因
   宽容而方便、一段因宽容而出错），给出你的语言设计立场与理由。
6. ★★ P4 的 `loud(9)` 出现在输出里——把 `&&` 改成"返回操作数"
   语义（JS 风格），P4 的期望输出怎么变？发码模板要动几行？
7. ★★（审计）把 P2 反汇编的 25 行逐行标上源程序行号与产生它的
   编译器函数名（如 0019 ← ifStmt/whileStmt 的 emitJump）——
   这张表就是"编译器源码 ↔ 产物"的对照索引（答案底稿在 §55.6
   的表里，先做后对）。
8. ★★（度量）给 Compiler 加一个指令计数器（emit 处 +1），对 P2
   统计"源字符数 → 指令数"的压缩比；再手编同一程序（第 57 章
   方式）数指令数——两版应当完全相等（本题是三方对账的第三列
   数字化）。
9. ★★（审计续）把四个真 bug 各构造一个"最小复发语料"（去修
   复代码、跑语料、记录症状），存进自己的错题本——症状与根因
   的对照表就是单遍编译器的调试手册。

**读完本章的四个实操项目**（难度递增，各一到两个周末）：
①把 54+55 连成"REPL 计算器"（去函数化、只留表达式 + output，
交互读一行编一行跑一行）——练驱动层组装；②加 `do-while` 与
`for`（糖：初始化/条件/步进三段）——练语句模板与回填；③加
`print` 反汇编命令（REPL 里输入 :dis 打印上一行编译产物）——
练工具链；④单遍直线版确定赋值（FAQ 第二问的完整版）——练
"能做多少"的边界感。四个项目全用本教程的三层验证（产物/语义/
诊断）。

**里程碑清单**（读完本章你已能做什么——面试与实战两栏）：

| 能力 | 实战形态 |
|---|---|
| 手写词法器 | 任意小语言的 scanner 一小时内 |
| Pratt 发码表扩展 | 给语言加运算符（含短路类控制流语义） |
| 槽位/作用域编译期管理 | 块级语言变量实现的完整套路 |
| 回填技术 | 前向引用/两段式装载/内联缓存同族问题 |
| 反汇编驱动的调试 | 用产物对账定位"差一"与"错位" |
| 三层测试设计 | 产物/语义/诊断断言的分工 |

六行是"写过一个单遍编译器"的完整能力画像——比"读过"高一个
数量级，产出型自查就是验收仪式。

**产出型自查**（合上书写一遍）：默写 if/else 的双跳转模板
（六行带标号）与 while 的双技术模板（五行），再默写 `a && b`
的六行发码——三个模板都能默写者，本章毕业；写不出的那一个，
就是回炉小节的地址。最后的开放式一问留给读者带走：**如果要
你给自己的项目选一条执行路线（树遍历 / 单遍字节码 / 多遍 IR），
你先问自己的第一个问题应该是什么？**——本章 §55.7 已经给过
答案的形状（成本结构），但问法的个性化（你的用户在等什么、
你的语言会长大成什么）才是选型的真问题。带着这问进下一篇。

**致匠书**：原书第 18–26 章用八章铺出单遍编译的全路（扫描、
发码、全局、局部、跳转），密度是"每章一个可运行的增量"。本章
把它们压成一章、四百行、十六项断言——压缩的底气来自本教程的
前置铺垫（第 11 章已教表、第 57 章已教指令集与协议），**匠书
八章到本章一章的比率，就是"前置知识换篇幅"的汇率**。原书
另有三样本章没搬：字节码验证器的雏形讨论（§15.5 错误处理，
本教程在第 31/65 章有理论版）、`OP_PRINT` vs native 的取舍
（本章 FAQ）、以及原书著名的"分号恐惧"轶事（synchronizing at
statement boundaries 的动机故事，值得翻原书一读）。

### 词频小账（本章的词）

本章正文的高频关键词五枚：回填（28 次）、槽位（31）、迟绑定
（14）、占位（19）、断言（22）——五词覆盖了本章近三分之一的
技术表述。**一个章节的词频就是它的思维指纹**：第 11 章的指纹
是"优先级/表"，第 15 章是"环境链/闭包"，本章是"回填/槽位"——
读者复习时按指纹检索，比按节号检索快（记忆挂词不挂数）。

### 两版迭代器的暗对照（送细心读者）

细心读者会在反汇编里注意到：`LOOP -> 14` 而条件起点恰在 14——
但手推表里 whileStmt 的 loopStart 记录发生在 consume('(') **之前**
（代码尺寸 14 那一刻），两者恰好相等不是巧合而是**协议自洽**：
loopStart 记的是"条件首指令的地址"，条件首指令（GET_LOCAL 1）
确实落在 14。若 whileStmt 把 loopStart 记在 consume 之后（15），
回边就跳进 CONSTANT 的操作数字节——又一个差一的候补现场。
**这一格没有踩坑是因为公式纪律（三行注释）先于代码**——它
是"没发生的 bug"，教学上与发生的 bug 同样值钱。

### 本章时间线（一节开发史）

本章代码的实际开发顺序留档（与节的呈现序不同——呈现序按教学
逻辑、开发序按依赖逻辑）：底座复制（54 四件）→ 扫描器 → 
function/statement 骨架 → Pratt 表与回调 → 槽位与占位（bug #2
在此修）→ 跳转与回填（两个差一在此修）→ 短路 → 驱动与断言
→ 诊断语料 → 反汇编全文断言最后锁（改一次差一就得重推一遍
期望——所以它最后做）。**开发序的原则是"先通路后锁形"**：
语义先绿（输出对）、形状后绿（反汇编对）——中间态允许形状
漂移，锁定只在终点。这条时间线对读者自己的项目排期是直接
可抄的模板。

### 一份"最小可行编译器"的自查规范

读者若要把本章成果带出去（写进简历、搬进项目），用这份规范
自查"最小可行"的成色——六条，每条一票否决：

1. 断言三层齐（产物/语义/诊断缺一不可）；
2. 反汇编可读（外人拿到产物能读懂栈形）；
3. 四类决定全自动（偏移/槽位/索引/压栈序无一处人肉）；
4. 错误带行号且名词化（用户不用猜）；
5. 同源编译确定（两遍编译逐字节相同）；
6. 错题本起步（至少三个自己的最小复发语料）。

六条全部来自本章正文——规范本身是本章的复述，**"最小可行"
的标准不是功能量，是工程纪律的完整性**。

### 常见误区三则

**误区一："单遍编译器是玩具，学它不如直接学 LLVM。"** 恰恰相反
的三笔账：其一，LLVM 的 PassManager 是多遍框架，你若没亲手体验
过"一遍见底"的约束，就理解不了 IR 为什么那样设计（给多遍看
的形状）；其二，LLVM 前端（clang 的词法语法层）内部仍是流式
单遍风格——工业前端的地基与本章同型；其三，最快的 JIT 热身层
（解释器）几乎全是单遍字节码机——**单遍不是多遍的初级形态，
是多遍生态里的一个常驻物种**。学过本章再碰 LLVM，你才知道
自己在哪一层、为什么。

**误区二："回填是历史包袱，现代编译器都不用了。"** 三级反例：
链接器的重定位表（每个 .o 都在用）、Java 类装载的符号解析
（每次 JVM 启动都在跑）、JIT 的 inline cache 修补（每次热点
调用都在发生）。**只要"引用先于目标"存在，回填就存在**——
单遍只是这个时序困境的最小标本。

**误区三："本章语言太小，结论不能推广。"** 推广性的正确检验
是**机制而非规模**：槽位管理（Java 的局部变量表、JVM 规范第 4 章的 slot 编号）、迟绑定（动态链接）、回填（如上）——三个
机制在工业栈里各有一个同名同义的放大版。教学语言的小不是
缺失，是**把机制从规模里蒸馏出来**——蒸馏器就是本教程的
断言与对账制度。

### 遗产清单

本章给三方各留下一份遗产，清点后收章。

**给后续章的接口遗产**（第 56/57 章的施工面）：Op 枚举扩展区
（尾部追加纪律的示范）、名字表与常量池的双表结构（56 章并表
决策的素材）、endScope 的 POP 钩子点（57 章 CloseUpvalue 的挂
载位）、Pratt 回调的发码义务表（57 章 fun 前缀回调的模板）、
以及 journey 驱动的"编译-注册-运行"三段式（两章直接复用）。
五件接口全部**已经过本章断言的实测**——后继者接到的是运行中
的铁轨，不是图纸。

**给读者的能力遗产**（比照第 9/13/54 章的收法）：一张能发的表
（任何运算符进得去）、一本会记的账（栈效应与凭据）、一双敢信
的眼睛（反汇编读形状）、一套防差一的纪律（VM 三行注释推导法）、
一个错题本的方法论（最小复发语料）。五件都不新——它们分别是
第 11 章（表）、第 57 章（账与形状）、本章（纪律与错题本）的
累积——**教程走到这里，读者手里的工具箱第一次配齐"写编译器"
的全套**。

**给教程的方法论遗产**：本章首次把**开发期错误**作为正式教学
内容（四个真 bug 复盘 + 错题本练习），这个做法将延续到 56/57
章（它们各自的坑位在伏笔表里已经标好）；本章也首次示范了
**副本制共享**（54 章地基的三章复用账）与**三方对账**（13/54/
55 会师）——两条方法论都是第十篇的structural 特征，收官章
（66）的 survey 将把它们作为"匠书线"的组织方式记录。

遗产清点完毕，本章合卷。

---

**一句收束（面试版）**：如果有人问"你会写编译器吗"，本章之后
的诚实回答是——"写过单遍的：词法、Pratt 发码、槽位、回填、
栈机全套，四百行，带三层测试"——这句话的每个名词都对应你
亲手红过又绿过的断言。

**一句收束**：编译器没有魔法——它是四类算术（偏移、槽位、索引、
压栈序）在扫描现场的自动化；占位与回填给了它时间机器，迟绑定
给了它前向的自由，而反汇编断言替人类守住这一切的账。

（第 58 章完——第 59 章换值的家当（NaN 装箱与驻留），第 60 章
收官上值：帧消失后变量搬家。三连章的最后两块拼图，地基都在
你手里了。）

**四个 bug 的一句话总纲**：漏吃（协议之差）、缺占位（时序之
差）、两个差一（坐标之差）——**单遍的一切错误都是"差"**：
时间差（谁先谁后）、空间差（在哪一格）、语义差（谁的义务）。
带着这三个"差"去读任何编译器的 bug 报告，多半能对号入座。

**给收官章的一行素材**（66 章 survey 的预告）：单遍编译器——
"把名字变数字、把跳变偏移、把语法变栈账"的一遍式翻译，四个
真 bug 与三张表是它的全部教学资产。

**编译器作者的三件文具**：一张表（语法）、一本账（效应与凭据）、
一支红笔（断言与错题本）——三件都齐了，下一篇见。

**两句话的底气**（写给正在犹豫"我到底学会没有"的读者）：判断
标准不是"能默写多少"，而是给你一段**没见过的**小程序（比如三重
嵌套循环加函数调用），你能否在纸上写出它的反汇编前二十行——
**生成能力才是学会的签名**（默写只是再认的高级形态）。写不出
就回到 §55.6 的 25 行表，对着 P2 逐行问自己"这行为什么在这"，
问到能答为止。

**一个可以直接抄走的复习表**（考试周专用，五行）：

| 要背的公式/模板 | 一句话版 |
|---|---|
| patchJump | 偏移 = 目标 - 字段地址 - 2 |
| emitLoop | 偏移 = 当前尺寸 - loopStart + 2 |
| if 模板 | 条件、JIF占位、then、JMP占位、回填、else、回填 |
| && 模板 | a、JIF、b、JIF、压1、JMP、压0 |
| 槽位律 | 声明即占位压栈；出块按数 POP |

**给同路人的最后一句**：本章的每一个数字（120、55、2 1、ret 20）都值得你在
草稿纸上重新算一遍——算过的数字才是你的，读过的只是路过。

**章末三问的口头版**（跟同伴互考最快）：一问"回填为什么必须
存在"（前向目标不存在）；二问"占位 0 为什么不能省"（槽位成形
的帧协议硬约束）；三问"迟绑定付出了什么"（每次查表 + 诊断变
弱）。三问三答不超过一分钟，胜过重读三节。

**本章最后一行的实验**：把驱动里 P1 的 `fact(5)` 改成 `fact(10)`，先预测
（3628800？帧深 12？）再跑——预测全中者，本章的账本真的在你手里了。

（章末彩蛋：本章四个真 bug 的修复提交若在 git 里 grep fixme，一个也找不到——
因为它们修完就进了正文。错题本的最高境界是正文本身。
下一个数字是 56——值的家当就要换小两倍的口袋了。）
