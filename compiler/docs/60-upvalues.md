# 第 60 章　上值：虚拟机里的闭包

> 取材：匠书（Crafting Interpreters）§25.1–25.6（闭包的 clox 实现：
> 编译期捕获表与 resolveUpvalue 递归、运行期开放上值表、
> closeUpvalues 与"指针搬家"）。全部材料在本章自包含蒸馏，
> 不需要翻原书。
> 本章示例：`examples/60_upvalues`（无 ANTLR，简单程序对账协议）。

## 60.0　帧没了，变量还得活着

第十篇的三连章在此收官。第 57 章立了帧协议，第 58 章把源程序编成
字节码，本章回答三连章的最后一个问题：**闭包逃逸之后，变量住在
哪**。

问题的形状先立起来。局部变量住在值栈的帧段里（第 57 章
§54.5），函数返回即整帧清空——这是栈机效率的全部来源。可是
`counter()` 返回一个 `fun (n) { c = c + n; return c; }`，这个字面量
**引用了 counter 帧里的 c**；字面量活得比 counter 的帧久（main 里
反复调用它）——帧都拆了，c 住哪？三种付费方案第 15 章排过谱
（整链常驻 / 编译期装箱 / 上值）——本章兑现最精细的一档：
**上值（upvalue）——运行期按需捕获、单变量粒度搬家**。

三种方案的账在本章终于可以实测了（P1 断言）：同一计数器程序，
第 15 章环境链造 **7 个环境节点**（整层拖走），本章上值只造
**2 个堆盒子**（两个 counter() 各一个 c 盒）——**捕获什么搬什么，
无关变量零负担**。输出逐行全等（`1 2 1`）：实现天差地别、语义
由对账统一——第 15 章立下的证人网在第十篇的终点完成四路会师
（13 树遍历 / 54 手编 / 55 编译 / 57 上值）。

```text
57.1 编译期：FnCtx 链与捕获表（谁捕获谁，编译时就定好）
57.2 运行期 I：开放上值表（指栈格的"暂住证"）
57.3 运行期 II：close 与指针搬家（栈格要弹了，上值进盒）
57.4 三方裁决：循环各捕各的（§25.6）
57.5 四方对照：环境链 / 装箱单 / 上值 / 访问链
57.6 驱动、语料与期望输出解读
57.7 FAQ、小结与练习
```

**两分钟速览**：上值两态——**开放**（location 指值栈一格，变量还
住在帧里）与**关闭**（值搬进自己的 closed 盒子，location 改指自家
——"指针搬家"）。编译期：`resolveUpvalue` 沿 FnCtx 链向外找名字，
命中即记入捕获表 `{isLocal, index}`（同格共享去重）；运行期：
CLOSURE 指令按表捕获（查开放表防重开盒）、GET/SET_UPVALUE 经
闭包的 ups 数组间接读写；**关闭时机两处**——块级变量出块
（编译器发 CLOSE_UPVALUE）与函数返回（VM 在 Return 里先关后拆）。
五个断言组：P1 计数器 13 章全等 + 盒子 2 对 7、P2 三层嵌套传递、
P3 循环各捕各的 0 1 2（共享反例是 2 2 2）、P4 一改俱改、结构断言
（捕获表/关闭指令进反汇编）。

先看底座增量——本章的 scanner/chunk/vm/compiler 四件是第 58 章
的**本地副本加改造**（第十篇副本制的最后一次实践）：

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
    KwVar, KwReturn, KwOutput, KwIf, KwElse, KwWhile, KwFun,
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
        else if (s == "fun") tk.t = Tok::KwFun;
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
    // ——比较补全与逻辑非——
    Not,        // 弹一压其逻辑反（0↔1）
    Ne, Ge, Le, // 不等/不小于/不大于
    Lt,         // 小于（57 章补齐比较集——55 章语料未及、switch 漏 case 的实测坑）
    // ——第 60 章追加（上值三件套）——
    GetUpvalue,  // u8 上值索引：压 *upval->location（开放=栈格/关闭=盒子）
    SetUpvalue,  // u8 上值索引：写 *upval->location（不弹，赋值有值）
    Closure,     // u8 函数常量 + u8 捕获数 + 每捕获 2B(isLocal, index)
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

// 捕获表条目（§25.2）：isLocal=真 → 捕外层栈槽（编译期槽号）；
// 假 → 捕外层上值（穿层传递，索引是外层捕获表下标）。
struct UpvalDesc {
    bool isLocal = false;
    uint8_t index = 0;
};

// 函数对象：名字 + 元数 + 代码体（共享 Chunk 所有权，常量池可互相引用）
struct ObjFn : Obj {
    std::string name;
    int arity = 0;
    std::shared_ptr<struct Chunk> code;
    std::vector<UpvalDesc> upvals;  // 编译期捕获表（Closure 指令的底稿）
};
// 原生函数：C++ 直调旁路（§24.4 input 桩）
struct ObjNative : Obj {
    std::string name;
    int arity = 0;
    Value (*fn)(std::vector<Value> args);
};

// ——第 60 章：上值与闭包（§25）——
// 上值对象：开放时 location 指向值栈的一格；关闭后值搬进 closed、
// location 改指自己家（"指针搬家"的全部秘密）。
struct ObjUpvalue : Obj {
    Value *location = nullptr;
    Value closed{};
};

// 闭包 = 函数 + 运行期捕获表（每格一个 ObjUpvalue 的共享指针）
struct ObjClosure : Obj {
    std::shared_ptr<ObjFn> fn;
    std::vector<std::shared_ptr<ObjUpvalue>> ups;
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
        case Op::Lt: return "LT";
        case Op::GetUpvalue: return "GET_UPVALUE";
        case Op::SetUpvalue: return "SET_UPVALUE";
        case Op::Closure: return "CLOSURE";
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
        case Op::GetUpvalue: case Op::SetUpvalue: {
            os << opName(op) << " " << int(c.code[off + 1]) << "\n";
            return 2;
        }
        case Op::Closure: {
            uint8_t k = c.code[off + 1];
            uint8_t n = c.code[off + 2];
            os << opName(op) << " " << int(k);
            if (auto *f = dynamic_cast<const ObjFn *>(c.consts[k].obj.get())) {
                os << "  ; " << f->name << "/" << f->arity;
                for (int i = 0; i < n; ++i) {
                    const UpvalDesc &u = f->upvals[size_t(i)];
                    os << (i ? ", " : "  捕获[") << (u.isLocal ? "槽" : "上值")
                       << int(u.index);
                }
                if (n) os << "]";
            }
            os << "\n";
            return 3 + 2 * n;
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



**三连章的角色定型**（一句话各评）：54 章**立**（协议与地基——
它的价值在"被依赖"，自身代码最少断言最少）；55 章**转**（源
码到字节码的翻译——价值在自动化）；57 章**逃**（帧约束的
突破——价值在语义完备）。立-转-逃三字诀是三连章的教学魂：
**先立规矩、再把规矩自动化、最后在规矩内做到极限**——任何
系统的三代演进都适用（数据库的 schema/ORM/分布式事务、网络
的协议/栈/QUIC……），三连章是这个演进律在 4000 行代码里的
完整演示。


**三连章的衔接句式存档**（每章末尾章的"下一章预告"串起来读）：
54→55"把手编交给机器"、55→56"值换小口袋"、56→57"帧消失变量
搬家"、57→(20/52/66)"机制全齐、总装在即"——四句连读是三连章
的目录诗——**章尾预告是隐性目录**，教程五轮扩充一直保持
这个文体（每章末一段、串起来是全书的另一条线）。

### 60.0.1　第十篇三连章的合卷视角

54→55→57 三章是一个有机体，合卷时把三张总表叠起来看：

| 章 | 冻结了什么 | 消费了什么 | 新增了什么 |
|---|---|---|---|
| 54 | Op 枚举、帧协议、反汇编格式 | （立地基） | 栈机本体 |
| 55 | 表/模板/回填的编译器形状 | 54 全部协议 | 单遍发码 |
| 57 | （收官，无下游） | 54+55 全部 + 56 值（可选） | 上值三指令 |

三行读出副本制的经济学：**冻结越早、下游越多**——54 章的两个
冻结（枚举、帧协议）被复制了两次、各养活一章；55 章的模板形状
被 57 原样沿用（ifStmt/whileStmt 一行没改）。反例也有：Lt 坑
正是"55 章该冻结而没冻结"的东西（比较集）在 57 章爆的雷——
**该冻结的清单本身就是架构能力的考场**（练习 9 请读者给 55 章
补一张"比较集契约表"当防复发）。

三连章的断言密度递变也值得合卷记录：54 章 7 项（全行为）、
55 章 16 项（行为+产物）、57 章 15 项（行为+产物+结构）——
**实现越深、断言越硬**（结构断言的比例随章上升），收官章的
survey 将把这个观察写成教程方法论的一条。

### 60.0.2　从匠书到本章的路径回顾

匠书用 clox 的 §14–§25 十二章铺出字节码线；教程把它压缩成
三章并各配一条前置线（54←第 15 章帧语义、55←第 11 章 Pratt 表、
57←第 15 章闭包语义）。压缩的底气前面算过（55 章末：八章→
一章的汇率）；三连章读完的读者现在手里有：一台能跑闭包递归
循环的栈机（vm.cpp 约 300 行）、一个能把源程序编成它字节码的
单遍编译器（约 450 行）、一张四方对照的闭包实现地图——
**clox 的全部核心 + jlox 的语义基准 + 教程自己的对账网**。
这是五轮扩充（龙虎鲸匠）给读者的最大单笔装备升级。


### 60.0.3　P1 的四路会师现场

把四路同源语料的输出并排（本章期望文件与第 13/54/55 章的对应
断言行）：

```text
第 15 章 P1（树遍历）  ok P1 输出 = 1 2 1（21 项断言之列）
第 57 章（手编语境）   表达式/调用帧的机制由本章语料复用
第 58 章 P1（编译）    ok P1 输出 = 120（fact 语料的三方列）
第 60 章 P1（上值）    ok P1 输出（13 章全等） = 1 2 1
```

四行的含义：**同一段 counter 源程序**，13 章用环境链跑出 1 2 1、
57 章用编译+栈机+上值跑出 1 2 1——两条实现路径各自的全部中间
机制（ANTLR/AST/Resolver/环境链 vs 扫描/发码/CLOSURE/盒子）
都在输出上不可见。**语义证人网的价值不在证明"哪条对"，而在
证明"全都对且相互知道对方对"**——重构任何一条路径（比如把
上值换成 V8 上下文），断言网立刻报告哪条线还在轨。收官章将
把这张网画成总图（survey 的"执行路径"行）。


### 60.0.4　"帧没了"的另一种解法存在吗

（读者可能想到的第三条路，值得一问一答收进正文。）既然问题是
"帧回收殃及被捕获变量"——**让帧别回收**行不行？行，且真实存在：
CPython 的帧对象在闭包存活时确实不回收（帧堆分配、引用计数
保活）——这是"整层常驻"的 Python 版，代价是每个帧都是堆对象
（哪怕无闭包的调用也付堆分配的钱——直到 3.11 的内联帧优化才
把无闭包调用拉回栈态）。**"让问题不发生"与"解决问题"都合法**，
分野还是那张四方表：CPython 选环境链系（帧即环境）、Lua/clox
选上值系、静态语言选装箱单系——三个生态的选择各自与其整体
架构自洽（CPython 一切对象皆堆、Lua 嵌入式省内存、静态语言
有编译期信息可用）。**没有最好的方案，只有与宿主最配的方案**
——这句话在本教程出现了第五次，前四次分别在解析器、GC、
值表示、单遍/多遍处。


### 60.0.5　本章的三份前修清单（最小行李）

自包含性声明：第 15 章 §13.2–13.3（环境链与闭包语义——P1/P2
语料的语义基准）、第 57 章全部（指令集与帧协议——本章 VM 的
地基）、第 58 章全部（编译器与回填——本章副本的母本）。第 59 章**不是**前置（值表示正交，FAQ 第一问）；第 21 章可选（访问链
只在 §57.5 对照表出场）。四件行李外的知识本章自足——包括
fun 字面量的文法（第 15 章扩展的编译器版，正文自带）。


### 60.0.6　一个预先的回答：为什么叫"上"

upvalue 的 up 指的是**词法向上的外层**（up the scope chain）——
变量在"上面"的函数里，故 captured from above。中文译名里
"上值"是直译、"外层变量捕获值"是意译、Lua 社区常直接说
upvalue 不译。教程用"上值"并在首次出现处给英文——两个音节
的术语比八个字的描述在正文里耐磨（本章出现 40+ 次）。术语的
经济性与准确性同样重要——**好术语让讨论提速，坏术语让每个
使用处都要重新解释**（"闭包"本身就是好术语的典范：两个字
装下了"封闭+包裹"两层机制）。


### 60.0.7　匠书线四新章的合卷表（9/13/54/55/56/57）

匠书轮六个新章至此全部落成，合卷一张：

| 章 | 主角 | 底座 | 断言 | 与匠书 |
|---|---|---|---|---|
| 09 | Pratt 表 | 06 章分层 | 63 | §6.3+§17.5 |
| 13 | 环境链+四检查 | 12 章 AST/ANTLR | 21 | §7–11 |
| 54 | 栈机+帧 | —（立地基） | 7 | §14/15/18/24 |
| 55 | 单遍编译+回填 | 54 副本 | 16 | §16/17/24–26 |
| 56 | NaN 装箱+驻留+散列 | —（独立） | 37 | §18/19/20/30 |
| 57 | 上值 | 55 副本 | 15 | §25 |

六行读出三个结构事实：**底座复用四次**（12/54 各两次）；**断言
总数 159**（六新章合计）；**原书取材覆盖 §6–§25 加 §30**——
匠书两部解释器的核心机制（解析、求值、环境、闭包、编译、表示、
调用、上值）在教程里各有一章自己的家。合卷表将进收官章的
survey（66 章素材行）。


### 60.0.8　P1 语料的四行逐行（源到字节码到盒子）

counter 语料四行主角各自的编译产物与运行期对象（一章总纲图）：

```text
源行                          编译产物                     运行期对象
var c;                        CONSTANT 0（占位）           栈格 @base+1
c = 0;                        CONSTANT 0; SET_LOCAL 1; POP  格写 0
return fun(n){...};           CLOSURE 0 ; %fun/1 捕获[槽1]  盒 A（开放→关）
main: inc1 = counter();       GET_GLOBAL counter; CALL 0    盒 A 脱离帧
```

四行从上到下是"变量的家从栈格到盒子"的全过程——**每行三个
形态（源/码/对象）并排**，本章所有机制都活在这张表的四行里。
读者若把这张表抄在卡片上随身带，比背十个术语定义都管用。


### 60.0.9　四路会师的语义声明（给收官章的引用件）

本节是四路对账的正式声明（收官章 survey 直接引用）：**语料
counter（P1）与 adder（P2）在第 15 章与第 60 章的实现下输出
逐字符全等**；两实现的中间机制完全不同（环境链 vs 编译+上值）；
第 54/55 章为 57 竿路（手编规格与编译器），其语料（fact/while）
另与第 13/15/16 章构成执行路径对账。**教程的语义在证人网中
流动而不是寄存在任何单一实现里**——这是五轮扩充一以贯之的
架构决定，其完整图景由收官章的总表呈现。


### 60.0.10　一句话开场白（给跳读者的）

只读一段也该读这段：**闭包逃逸后，被捕获的局部变量离开栈、
住进堆上的盒子**——搬家发生在变量原属的栈格要消失的那一刻
（出块或函数返回），由"开放上值"（还指栈格）翻转为"关闭上值"
（指自家盒子）完成；编译器沿词法链递归登记每个函数要捕谁
（捕获表），运行期 CLOSURE 指令按表造盒（同格查重共享）。
整套机制的全部代码不到 120 行——**小机制、深语义、强对账**
，是它当选三连章收官的原因。

## 60.1　编译期：FnCtx 链与捕获表

```cpp
// file: src/compiler.hpp
// file: src/compiler.hpp
// 第 60 章：单遍编译器 + 函数字面量与上值（匠书 §25.1–25.5）。
// 相对第 58 章的改造：单函数状态升级为 **FnCtx 链**（嵌套函数各有
// 上下文、经 parent 链解析上值）；Local 加 isCaptured；出块对被捕获
// 槽位先发 CLOSE_UPVALUE 再 POP；新增 fun 前缀回调发 CLOSURE。
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

struct Program {
    std::vector<std::shared_ptr<ObjFn>> fns;  // 顶层函数（驱动注册用）
};

class Compiler {
  public:
    Program compile(const std::string &src);
    int lastSlotPeak() const { return lastSlotPeak_; }

  private:
    // —— 函数上下文链：嵌套函数各一层，parent 指向外层（§25.2）——
    struct Local {
        std::string name;
        int depth;
        bool isCaptured = false;  // 被内嵌函数捕获 → 出块前要 CLOSE
    };
    struct FnCtx {
        std::shared_ptr<ObjFn> fn;     // 编译产物
        std::vector<Local> locals;     // 槽位表（下标即槽号）
        int scopeDepth = 0;
        FnCtx *parent = nullptr;       // 词法外层（上值解析的路）
        bool named = true;             // 顶层函数 or 字面量
    };

    // Pratt 表（私有静态）
    struct CRule;
    static CRule ruleFor(Tok t);

    Token advance();
    bool check(Tok t) const;
    bool match(Tok t);
    Token consume(Tok t, const char *msg);

    void beginScope();
    void endScope();
    int resolveLocal(FnCtx *ctx, const std::string &name) const;
    int resolveUpvalue(FnCtx *ctx, const std::string &name);  // 递归穿层
    int addUpvalue(FnCtx *ctx, bool isLocal, uint8_t index);  // 去重
    void declareLocal(const std::string &name, int line);

    void function(bool named);   // 顶层函数与 fun 字面量共用（§25.1）
    void statement();
    void blockStmt();
    void varStmt();
    void exprStmt();
    void ifStmt();
    void whileStmt();
    void outputStmt();

    void expression();
    void parsePrecedence(int minPrec);
    void numberFn();
    void identFn();
    void groupingFn();
    void unaryFn();
    void funFn();               // fun 前缀回调：编身体 + 发 CLOSURE
    void binaryFn();
    void andFn();
    void orFn();
    void callFn();

    void emit(Op op);
    void emitByte(uint8_t b);
    void emitConstant(const Value &v);
    int emitJump(Op op);
    void patchJump(int at);
    void emitLoop(int loopStart);

    int line() const { return prev_.line; }

    Scanner sc_;
    Token prev_{}, cur_{};
    FnCtx *ctx_ = nullptr;                  // 当前函数上下文
    std::vector<std::unique_ptr<FnCtx>> ownedCtx_;  // 所有权
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

// ---------- Pratt 规则表 ----------
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
        case Tok::KwFun:  return {&C::funFn, nullptr, Prec::None};  // §25.1
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
    cur_ = sc_.scanToken();
    return prev_;
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

// ---------- 作用域与上值 ----------
void Compiler::beginScope() { ++ctx_->scopeDepth; }
void Compiler::endScope() {
    --ctx_->scopeDepth;
    int pop = 0;
    while (!ctx_->locals.empty() && ctx_->locals.back().depth > ctx_->scopeDepth) {
        // 被捕获的槽位：先 CLOSE_UPVALUE（值搬进盒子），再 POP（槽让位）
        if (ctx_->locals.back().isCaptured) emit(Op::CloseUpvalue);
        ctx_->locals.pop_back();
        ++pop;
    }
    for (; pop > 0; --pop) emit(Op::Pop);
}
int Compiler::resolveLocal(FnCtx *ctx, const std::string &name) const {
    for (int i = int(ctx->locals.size()) - 1; i >= 0; --i)
        if (ctx->locals[size_t(i)].name == name) return i;
    return -1;
}
int Compiler::resolveUpvalue(FnCtx *ctx, const std::string &name) {
    if (!ctx->parent) return -1;
    // 先在外层的局部里找：命中 → 本函数捕"外层栈槽"（isLocal 真）
    int local = resolveLocal(ctx->parent, name);
    if (local >= 0) {
        ctx->parent->locals[size_t(local)].isCaptured = true;
        return addUpvalue(ctx, /*isLocal=*/true, uint8_t(local));
    }
    // 外层也没有 → 递归穿更外层：命中 → 捕"外层的上值"（传递）
    int up = resolveUpvalue(ctx->parent, name);
    if (up >= 0) return addUpvalue(ctx, /*isLocal=*/false, uint8_t(up));
    return -1;
}
int Compiler::addUpvalue(FnCtx *ctx, bool isLocal, uint8_t index) {
    // 去重：同一变量捕获两次只占一格——两个闭包共享同一上值的基础
    for (size_t i = 0; i < ctx->fn->upvals.size(); ++i)
        if (ctx->fn->upvals[i].isLocal == isLocal && ctx->fn->upvals[i].index == index)
            return int(i);
    ctx->fn->upvals.push_back(UpvalDesc{isLocal, index});
    return int(ctx->fn->upvals.size()) - 1;
}
void Compiler::declareLocal(const std::string &name, int line) {
    for (int i = int(ctx_->locals.size()) - 1; i >= 0; --i) {
        const Local &l = ctx_->locals[size_t(i)];
        if (l.depth != ctx_->scopeDepth) break;
        if (l.name == name)
            throw CompileError{"同层重复声明：" + name, line};
    }
    ctx_->locals.push_back(Local{name, ctx_->scopeDepth, false});
    if (int(ctx_->locals.size()) > lastSlotPeak_)
        lastSlotPeak_ = int(ctx_->locals.size());
}

// ---------- 发码 ----------
void Compiler::emit(Op op) { ctx_->fn->code->write(op, line()); }
void Compiler::emitByte(uint8_t b) { ctx_->fn->code->writeByte(b, line()); }
void Compiler::emitConstant(const Value &v) {
    emit(Op::Constant);
    emitByte(uint8_t(ctx_->fn->code->addConstant(v)));
}
int Compiler::emitJump(Op op) {
    emit(op);
    ctx_->fn->code->writeU16(0xFFFF, line());
    return int(ctx_->fn->code->code.size()) - 2;
}
void Compiler::patchJump(int at) {
    size_t target = ctx_->fn->code->code.size();
    uint16_t off = uint16_t(target - at - 2);
    ctx_->fn->code->code[at] = uint8_t(off >> 8);
    ctx_->fn->code->code[at + 1] = uint8_t(off & 0xFF);
}
void Compiler::emitLoop(int loopStart) {
    emit(Op::Loop);
    size_t here = ctx_->fn->code->code.size();
    ctx_->fn->code->writeU16(uint16_t(here - loopStart + 2), line());
}

// ---------- 程序与函数 ----------
Program Compiler::compile(const std::string &src) {
    sc_ = Scanner(src);
    advance();
    while (!check(Tok::Eof)) function(/*named=*/true);
    return std::move(prog_);
}

// 顶层函数与 fun 字面量的公共身体——两类函数一视同仁（§25.1）。
// named=true：吃函数名，产物进 prog_（驱动注册进全局表）。
// named=false（funFn 回调进入）：匿名，产物进外层常量池并由
//   调用处发 CLOSURE（携带捕获表）。
void Compiler::function(bool named) {
    std::string name = named ? consume(Tok::Ident, "期望函数名").text : "%fun";

    FnCtx *outer = ctx_;
    auto owned = std::make_unique<FnCtx>();
    FnCtx *ctx = owned.get();
    ownedCtx_.push_back(std::move(owned));
    ctx->parent = outer;
    ctx->named = named;
    ctx->fn = std::make_shared<ObjFn>();
    ctx->fn->name = name;
    ctx->fn->code = std::make_shared<Chunk>();
    ctx->locals.push_back(Local{name, 0, false});  // 槽 0：函数自己占位
    ctx_ = ctx;

    consume(Tok::LParen, "期望 '('");
    if (!check(Tok::RParen)) {
        for (;;) {
            Token p = consume(Tok::Ident, "期望形参名");
            declareLocal(p.text, p.line);
            ++ctx->fn->arity;
            if (!match(Tok::Comma)) break;
        }
    }
    consume(Tok::RParen, "期望 ')'");
    consume(Tok::LBrace, "期望 '{'");

    if (match(Tok::KwVar)) {  // 函数头 var 声明（占位压栈，55 章同款）
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

    if (named) {
        prog_.fns.push_back(ctx->fn);
    } else {
        // 字面量：在外层常量池登记函数，随后发 CLOSURE：
        //   u8 常量索引 + u8 捕获数 + 每捕获两字节（isLocal?1:0, 索引）
        int k = outer->fn->code->addConstant(Value::ref(ctx->fn));
        FnCtx *o = outer;  // 发码走外层上下文
        o->fn->code->write(Op::Closure, line());
        o->fn->code->writeByte(uint8_t(k), line());
        o->fn->code->writeByte(uint8_t(ctx->fn->upvals.size()), line());
        for (const UpvalDesc &u : ctx->fn->upvals) {
            o->fn->code->writeByte(u.isLocal ? 1 : 0, line());
            o->fn->code->writeByte(u.index, line());
        }
    }
    ctx_ = outer;  // 回到外层继续
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
    beginScope();
    while (!check(Tok::RBrace) && !check(Tok::Eof)) statement();
    endScope();  // 被捕获槽位在此 CLOSE（§25.5 的爆破点）
    consume(Tok::RBrace, "期望 '}'");
}

void Compiler::varStmt() {
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
    int slot = resolveLocal(ctx_, name.text);
    if (slot >= 0) {
        emit(Op::SetLocal);
        emitByte(uint8_t(slot));
    } else {
        int up = resolveUpvalue(ctx_, name.text);  // 闭包也能写捕获（计数器！）
        if (up >= 0) {
            emit(Op::SetUpvalue);
            emitByte(uint8_t(up));
        } else {
            emit(Op::SetGlobal);
            emitByte(uint8_t(ctx_->fn->code->addName(name.text)));
        }
    }
    emit(Op::Pop);
    consume(Tok::Semi, "期望 ';'");
}

void Compiler::ifStmt() {
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jElse = emitJump(Op::JumpIfFalse);
    statement();
    int jEnd = emitJump(Op::Jump);
    patchJump(jElse);
    if (match(Tok::KwElse)) statement();
    patchJump(jEnd);
}

void Compiler::whileStmt() {
    int loopStart = int(ctx_->fn->code->code.size());
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jExit = emitJump(Op::JumpIfFalse);
    statement();
    emitLoop(loopStart);
    patchJump(jExit);
}

void Compiler::outputStmt() {
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Print);
}

// ---------- 表达式层 ----------
void Compiler::expression() { parsePrecedence(int(Prec::None)); }

void Compiler::parsePrecedence(int minPrec) {
    advance();
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
    // 名字的三个世界：本函数局部 → 栈槽；外层捕获 → 上值；全局 → 迟绑定
    int slot = resolveLocal(ctx_, prev_.text);
    if (slot >= 0) {
        emit(Op::GetLocal);
        emitByte(uint8_t(slot));
        return;
    }
    int up = resolveUpvalue(ctx_, prev_.text);
    if (up >= 0) {
        emit(Op::GetUpvalue);
        emitByte(uint8_t(up));
        return;
    }
    emit(Op::GetGlobal);
    emitByte(uint8_t(ctx_->fn->code->addName(prev_.text)));
}

void Compiler::groupingFn() {
    expression();
    consume(Tok::RParen, "期望 ')'");
}

void Compiler::unaryFn() {
    parsePrecedence(int(Prec::Unary));
    emit(Op::Negate);
}

void Compiler::funFn() {
    // fun (params) { body return e; } ——函数字面量（第 15 章教学扩展
    // 的编译器版）。整个身体的编译在 function(false) 里完成，回来时
    // CLOSURE（连同捕获表）已发在外层代码里。
    function(/*named=*/false);
}

void Compiler::binaryFn() {
    advance();
    Tok op = prev_.t;
    CRule r = ruleFor(op);
    parsePrecedence(int(r.prec) + 1);
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
        case Tok::Lt: emit(Op::Lt); break;
        default: break;
    }
}

void Compiler::andFn() {
    advance();
    int jf1 = emitJump(Op::JumpIfFalse);
    parsePrecedence(int(Prec::AndAnd) + 1);
    int jf2 = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je = emitJump(Op::Jump);
    patchJump(jf1);
    patchJump(jf2);
    emitConstant(Value::num(0));
    patchJump(je);
}

void Compiler::orFn() {
    advance();
    int jr = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je1 = emitJump(Op::Jump);
    patchJump(jr);
    parsePrecedence(int(Prec::OrOr) + 1);
    int jf = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je2 = emitJump(Op::Jump);
    patchJump(jf);
    emitConstant(Value::num(0));
    patchJump(je1);
    patchJump(je2);
}

void Compiler::callFn() {
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

第 58 章的 Compiler 是单函数状态（一套 locals/fn/scopeDepth）——
嵌套函数一来，每个函数需要**自己的**局部表与代码目标，于是状态
升级为 **FnCtx 链**：每个函数一个上下文，`parent` 指向词法外层。
fun 字面量的编译（`funFn` → `function(false)`）就是"压新 ctx、编
身体、弹回外层"——与第 15 章 `checkFunBody` 压作用域栈完全同构，
只是那份在诊断遍、这份在发码遍。

**名字解析的三岔路**（`identFn`）是本章编译器的灵魂：

```text
resolveLocal(ctx)  命中 → GET_LOCAL  槽位（本函数）
resolveUpvalue(ctx) 命中 → GET_UPVALUE 索引（外层）
都不命中           → GET_GLOBAL 名字（迟绑定）
```

第 58 章是二岔（局部/全局），本章加的是中间那一岔——**词法外层
的局部**。`resolveUpvalue` 的递归值得逐行读：先看直接外层的局部
表（命中 → 本函数捕"外层**栈槽**"，isLocal 真，并把外层那个局部
标记 isCaptured——出块要关的伏笔）；外层没有 → **递归再外层**
（命中 → 本函数捕"外层的**上值**"，isLocal 假——穿层传递：爷爷
的变量经父亲的手递给孩子，不新开盒）。递归的每一层都往**途经
函数**的捕获表里添一行——这正是匠书 §25.2 的"中间函数被过路
捕获"：`adder(x) { return fun (y) { return fun (z) { return x+y+z; }; }; }`
里 x 要过两层才到 z 的身体，中间那层 fun(y) 的捕获表里躺着一个
isLocal 假的 x——**它自己不用 x，但它是 x 的邮路**。

**捕获表去重**（`addUpvalue`）是共享语义的编译期基石：同一变量
被同一函数捕获两次只占一格——运行期 CLOSURE 按表捕获时，同一格
两次 captureUpvalue 会命中开放表返回**同一个**上值对象（§57.2），
"两个闭包共享一个变量"从编译期到运行期一条线贯通。

**isCaptured 标记与 endScope 的改造**：被捕获的块级变量出块时，
不能再只是 POP（值没了、上值还指着这格——悬垂！）——先发
`CLOSE_UPVALUE`（搬家），再 POP（让位）。endScope 的循环里那行
`if (isCaptured) emit(Op::CloseUpvalue)` 是第 58 章爆破点
（伏笔表第 6 行）的兑现：**关闭挂在槽位回收的同一时刻**，时序
由作用域的语法结构保证——块右括号那一刻，编译器"知道"该关谁。

**adder 的捕获表逐层实录**（P2 语料，把三张表并排——读者应能在
不看代码的情况下复述这张表的每一格）：

| 函数 | 捕获表 | 每格来源 |
|---|---|---|
| adder | （空） | x 是自己的形参——槽 1，不捕获 |
| fun(y) | [ {isLocal:真, index:1} ] | x 在 adder 的槽 1 → 捕"外层栈槽" |
| fun(z) | [ {isLocal:假, index:0}, {isLocal:真, index:1} ] | x：外层(fun y)的上值 0（传递）；y：外层的槽 1 |

三张表的三条线各值得跟一遍。**x 的路线**（两跳）：fun(z) 的
resolveUpvalue("x") → 先查 fun(y) 的局部（没有——y 才是它的局部）
→ 递归查 adder 的局部（命中槽 1）→ **给 fun(y) 的表加 {真,1}**
（邮路）并返回 fun(y) 的上值号 0 → 回到 fun(z) 这层，拿到的是
"外层的上值 0" → 加 {假,0}。**一次查找，两张表各添一行**——
这就是递归的"途经即登记"。**y 的路线**（一跳）：fun(z) 查
fun(y) 的局部直接命中槽 1 → {真,1}。**z 的路线**（零跳）：自己
的形参，GET_LOCAL 槽 1，根本不进捕获表。

运行期对应：main 调 adder(1) → 帧里 x=1；adder 执行到 CLOSURE
（fun y 的）→ 捕 {真,1} → captureUpvalue(&栈格 x) → 新盒 A（开放，
指 adder 帧的 x 格）；adder 返回 → closeUpvalues(base) → 盒 A 关闭
（值 1 进盒）；main 调第二层 CLOSURE（fun z 的）→ 捕 {假,0} →
**与 fun(y) 闭包共享盒 A**（不新开）+ 捕 {真,1} → 新盒 B（指 fun(y)
帧的 y 格）；fun(y) 调用结束 → 盒 B 关闭（值 2 进盒）。于是求
`x+y+z` 时：GET_UPVALUE 0（盒 A，值 1）+ GET_UPVALUE 1（盒 B，
值 2）+ GET_LOCAL 1（栈上 z=3）= 6——**三个变量的三个家：关盒、
关盒、栈格**，同一条加法指令看不见差别（间接层的意义恰在于此）。

P2 的盒子断言（恰 2）就是 A 与 B——**捕获粒度 = 被捕变量数**，
与嵌套深度无关（x 深两 hop 也只一份）。若读者在纸上画 adder 的
链式调用 `adder(1)(2)(3)` 的盒子图，画出来应当是：main 栈上无盒、
堆上两个盒（A 值 1、B 值 2）——与第 15 章 P2 的环境链图（E1/E2/E3
三个节点）并排，同一程序两种内存布局，这就是四方对照表的像素级
对照。

**resolveUpvalue 的六个为什么**（逐行读代码时该自问的问题与答案）：

一，为什么先查局部再递归？——**就近原则**：外层同名遮蔽更外层
（作用域栈序），先查直接外层保证最近包围者胜出（第 14 章 resolve
的同语义在编译器链上的复刻）。

二，为什么命中局部时要标记 isCaptured？——**提前通知出块者**：
endScope 需要知道这格有人指着（先关后弹），标记在捕获**发生时**
打上而不是出块时回查——单遍编译器没有回查的自由，一切信息
**当下结清**。

三，为什么递归返回的是"上值号"而不是变量名？——上值号是**本层
捕获表的下标**，外层的名字在它那层已经翻译完了（成它的槽号或它
的上值号）——**每层只处理自己的词汇，翻译逐层传递**（与第 14 章绑定表"使用点→声明"的直达不同：那条链是遍历后的全局视图，
这条链是编译流中的即时接力）。

四，为什么 addUpvalue 要去重？——两个理由的复合：编译期，同一
变量两处使用若占两格，捕获表膨胀（u8 上限 256 也会真爆）；运行
期，两格会捕获两次——开放表查地址会命中同格返回同一盒（碰巧
对），但关闭后重开（P3 每圈同格）就**各造各的盒**——共享语义
崩坏。去重在源头保证一格一盒的对应。

五，为什么 u8 上限 256 没有断言？——教学语料最多 3 格；工业
clox 同上限（它的捕获数组定长），真实引擎用动态数组。上限问题
在第 58 章常量池处讨论过（EXTENDED_ARG 方案），捕获表同族不再
展开——**知道边界在哪、语料离边界多远**即可。

六，为什么函数字面量不查全局表？——查了也没用：全局不在帧里、
没有"要搬的家"，GET_GLOBAL 直接查表就是全部（FAQ"永生不搬"）。
三岔路的分界本质是**变量的家在哪**：本函数帧（槽）、外层帧
（上值）、无帧（全局表）——**寻址方案跟着家的位置走**。

**CLOSURE 指令的编码**（`function(false)` 尾部）：u8 函数常量索引
+ u8 捕获数 + 每捕获两字节（isLocal?1:0, 索引）。捕获表在编译期
是 ObjFn::upvals（反汇编的底稿），运行期由 CLOSURE 指令**展开**
成 ObjClosure::ups（每格一个上值对象的共享指针）——**编译期
的"账本"与运行期的"实物"经一条指令对应**，反汇编里
`CLOSURE 2 ; %fun/0 捕获[槽1]` 一行可读（结构断言锁定）。



**开场一幅总图**：compiler.cpp 的函数依赖在 55 章金字塔上加了一
层——function(false) 从叶（被 funFn 调）也可以当根（编译整程序），
金字塔变成了"可重入的双向结构"：同一段身体代码，从 compile 进
是顶层函数、从 parsePrecedence 进是字面量——**入口决定身份**，
与第 15 章"顶层函数与字面量一视同仁"的 callClosure 对称表互为
镜像。读者若在这段代码里迷路，先问"我现在在哪个 FnCtx"——
链上的位置就是全部的定向坐标。


**六处的行号地图**（供 diff 时定位）：FnCtx 构造在 function
头部（约 130 行处）；三岔路 identFn（约 330 行）与 exprStmt
（约 260 行）；endScope 新增（约 100 行）；funFn 一行（约 365
行）；CLOSURE 发码段（function 尾部约 180 行）。五个行号区间
互不重叠——**改造的物理分布本身就是模块健康度的指标**（散
而浅 = 好接口的接受改造方式；聚而深 = 该重构了）。


**六处之外的一个"负事实"**：本章**没有**改 ifStmt/whileStmt/
binaryFn/andFn/orFn/callFn 的任何一行——跳转模板、短路电路、
调用形状全部原样。这个负事实的可信度由第 58 章反汇编断言的
跨章复用背书（P2 的 while 反汇编在本章同源语料下逐字节同构）
——**副本制不怕复制 500 行，怕的是说不清"什么没变"**。六处
加法 + 一张"未动清单"，才是完整的改造说明——工业 diff 审查
的惯例（列出有意不改的部分）在此处有了教学版。


**FnCtx 的五个字段**（数据成员清单——与 55 章 Compiler 九成员
表对照）：fn（编译目标）、locals（含 isCaptured 的槽位表）、
scopeDepth、parent（词法链）、named（顶层/字面量）。五字段里
parent 是本章唯一的结构性新增——**一个指针把单遍状态升级成
词法树行走状态**，这就是"嵌套函数"在编译器数据结构上的全部
代价。对照第 15 章 SemCheck 的 scopes_ 栈（向量模拟嵌套）：
链与栈是同一嵌套的两种表示——栈赢在随机访问（诊断要跳层）、
链赢在自然递归（resolveUpvalue 恰是递归形状）——**表示选择
跟着主要操作走**（读栈多的用栈、递归遍历的用链），数据结构
选型的家规第 N 次。


**编译器文件行数账**（55→57 的实体增量）：55 版 450 行 → 57
版 470 行——净增 20 行里 FnCtx 结构 15 行、resolveUpvalue/
addUpvalue 减去被删的旧 resolveLocal 位置……实际新增约 90 行
（FnCtx 链三函数 + funFn + CLOSURE 发码 + 三岔路改造）、
删除约 70 行（旧单函数状态的相关重复）。**净 20 行是假象，
改动 160 行才是真相**——行数 diff 与语义 diff 的差距在重构
类提交里常态如此（这也是为什么"改了多少行"从来不是工作量
的度量——**改动的面积才是**）。


**调试本章代码的三个断点推荐**（用 gdb/IDE 的读者）：①
resolveUpvalue 的递归入口（adder 语料看三表逐层登记的过程——
两个栈帧各添一行）；②captureUpvalue 的查重命中点（P4 第二个
闭包捕获时返回旧盒——一改俱改的起点）；③closeUpvalues 的
搬家行（counter 返回时盒 A 进值——先关后拆的现场）。三个
断点各截获本章一个关键机制的"发生瞬间"——**断点是时间机器，
对时序敏感的章（本章与 55 章）比 print 更能保真**。


**编译期与运行期的对表**（本章机制的最终对账——每行左编译右
运行，读者可折叠背）：

| 编译期动作 | 运行期对应 |
|---|---|
| resolveUpvalue 命中局部 | CLOSURE 展开时 captureUpvalue(栈格) |
| resolveUpvalue 穿层命中 | CLOSURE 展开时直递外层盒 |
| addUpvalue 去重 | 同变量共享一盒（一改俱改） |
| isCaptured 标记 | endScope 的 CLOSE_UPVALUE 指令 |
| funFn 触发 function(false) | CLOSURE 指令本身 |
| identFn 三岔 | GET_LOCAL/GET_UPVALUE/GET_GLOBAL |
| exprStmt 三岔 | SET_LOCAL/SET_UPVALUE/SET_GLOBAL |

七行是"同一次编译的两种时间视图"——左列全部发生在扫描瞬间、
右列全部发生在执行时刻，**中间只隔着一张捕获表**（编译的果、
运行的因）。这张表若与 55 章的"四决定自动化表"并排，就是
单遍编译器两章的完整因果链。


**compiler.hpp 的改动四行**（头文件 diff 的极小性）：FnCtx
前置声明 + 成员 ctx_/ownedCtx_ 两行 + resolveUpvalue/addUpvalue
两个声明 + funFn 声明——**头文件是接口的账本**，四行说明本章
的接口增量极小（实现增量 90 行、接口增量 4 行——好接口的
扩张率特征：实现长接口短）。对比第 58 章 compiler.hpp 的
全量新立（40+ 行）：**接口在首章定型后应当越来越稳**——
这是"冻结"在头文件层面的可观测形态。


**与 51 章（函数式编译）的最后一面对账**：51 章的闭包转换把
捕获变量**装箱**（编译期清单——静态语言的玩法），本章上值把
捕获变量**按需搬家**（运行期——动态语言的玩法）。两者的语义
证人同为 13 章 P1（1 2 1）——**三种时机（编译期/创建期/关闭
期）全部在教程里有过实现**，这正是四方对照表（§57.5）能立
起来的原因：每列都不只是引文，是**做过并断言过的实现**。
教程对"对照表"的要求与对断言的一样：格子里的话要么有代码
要么有引用，不许凭印象。


**一个真实的数量对照**（闭合三连章的量）：54 章 727 行码、
55 章 1527、57 章 1611——三章合计约 3900 行（含副本重复），
去重后**独立机制约 2000 行**（栈机+编译器+上值各约 600/700/
700 的独立增量）。对照 clox 全书（约 3000 行 C 含 GC/字符串/
全部）——教程版本多出的 1000 行是**注释与教学命名**——
密度差本身就是教学码与工程码的风格账（工程码的注释率 10%、
教学码 30%——各有正当性，混用才错）。


**读者自验清单**（编译器六处是否真懂——闭卷可验）：①funFn
到 function(false) 的调用链上，谁是 prev_ 谁是 cur_？（prev_=fun
关键字——回调从它进；cur_=左括号。）；②function(false) 编译
完身体后回到哪行发 CLOSURE？（外层 ctx 的 o->fn->code——
跨层发码那五行。）；③捕获 {真,1} 与 {假,0} 各自的"1"和"0"
是什么编号？（外层槽号；外层捕获表下标。）④addUpvalue 去重
比较哪两字段？（isLocal 与 index 都等。）⑤isCaptured 标在谁
身上？（外层函数的 Local 记录。）⑥endScope 对被捕获槽发几条
指令？（CLOSE 一条 + POP 一条。）六问全对——本章编译器毕业。


**速查卡（裁下来贴显示器）——本章编译器 8 行**：

```text
三岔读：本函数局部 → GET_LOCAL 槽
        外层（递归穿链） → GET_UPVALUE 号
        都不是 → GET_GLOBAL 名
三岔写：SET_LOCAL / SET_UPVALUE / SET_GLOBAL 同型
捕获登记：resolveUpvalue 途经即记 {isLocal, index}
出块：被捕获者先 CLOSE_UPVALUE 再 POP
字面量：funFn → function(false) → 外层发 CLOSURE(表)
```

六条规则覆盖本章编译器的全部新行为——比读源码快、比背正文
准（速查卡是正文的**压缩证据**，教程每"重"章配一张：13 章
环境三操作、55 章三公式、56 章掩码卡、本章这张——四卡连贴
就是匠书线的显示器风景）。


**本章源码的阅读顺序终版**（写给第一次打开 57_upvalues/src
的读者，20 分钟路线）：scanner.hpp（找 KwFun 一行）→ chunk.hpp
（找 UpvalDesc/ObjUpvalue/ObjClosure 三结构 + 枚举尾三指令）→
compiler.hpp（FnCtx 五字段）→ compiler.cpp 的 function（双态
入口）→ resolveUpvalue（递归 12 行）→ endScope（两行新增）→
vm.cpp 的 Closure case（18 行）→ closeUpvalues（10 行）→
main.cpp 的 journey（注册壳三行）。九站每站一两分钟——**先
数据结构后函数、先新后旧**的路线让 20 分钟建立全景（对照
54/55 章的"读码顺序"两处，三连章各有路线图——合起来是 1200
行代码的完整导览）。


**速览表**（六处改造的检查表——给"改完想自查"的读者）：

| # | 改造 | 自查一行 |
|---|---|---|
| 1 | FnCtx 链 | parent 指向词法外层（非调用方）？ |
| 2 | 三岔读 | 局部→槽 / 外层→上值 / 全局→名？ |
| 3 | 三岔写 | 与读对称（SET 三型）？ |
| 4 | endScope | isCaptured 先 CLOSE 再 POP？ |
| 5 | funFn | 走 function(false) 一行？ |
| 6 | CLOSURE 发码 | 外层代码 + 表编码 3+2n？ |

六行自查 30 秒过一遍——**改完即查是防"顺手改错"的最后一道
闸**（错题本的预防版）。


**最后一组互文**（55 章"四决定自动化表"的本章续）：55 章把
54 章手编四决定自动化；本章把 13 章语义四件事工程化——环境
链（→开放表+盒）、闭包捕获（→捕获表）、块作用域（→endScope
关闭）、共享语义（→查重共享）。**两张表对角互文**：一张是
"手编→编译"、一张是"语义→机制"——四维矩阵（54 手编、55
编译、13 语义、57 机制）的四角齐了，任何一角的读者都能找到
自己相邻两角的对照——这个四角矩阵是三连章留给收官章的最终
结构图。

**终检表**（本章交稿前的最后清单——也是给读者的"自己写完
一章后"模板）：断言 15 与汇总 15 三向一致 ✓；期望 33 行实跑
生成 ✓；四个真坑全复盘入正文 ✓；四速档读法齐 ✓；速查卡入
正文 ✓；与匠书映射表齐 ✓；伏笔五条全回收 ✓；三样交付物
向收官章移交 ✓——**八项终检是六新章的交稿模板**（13/55/56
章各自执行过同款），收官章将把八项写进方法论清单。


**终版速查卡之卡背**（速查卡的"何时查"说明）：卡是查的不是
背的——写代码时忘了三岔路的分支条件（查第 1-2 行）、读别人
的上值实现时对不上术语（查卡对照）、面试前的十分钟复习（全
卡过一遍）。**卡的三个使用时机对应三种记忆状态**（用中忘/
读中混/考前虚）——卡片式知识的优势恰在不求全时而用时在场
（正文的线性结构做不到这一点——这就是为什么重章要"正文+
卡"双形态）。

### 60.1.1　compiler.cpp 全景走读（发码遍的地图）

第 58 章读者已认识 scanner/statement/ifStmt 这些老朋友——本章只
讲**变化的六处**，按源码出场序：

**其一，FnCtx 的构造与回收**（function 开头十行）：outer 存外层、
unique_ptr 落进 ownedCtx_（所有权树——嵌套函数的生命期由编译
器对象统一持有，词法链 parent 与所有权树同构，**指针只读不释放**
是教学实现的安全默认）。

**其二，locals_ 到 ctx_->locals_ 的全量改名**——不是机械替换：
每一处 `.locals` 的访问者从"当前函数"变成"ctx_ 指向的函数"，
第 58 章的单一事实变成了链上的一环。改名是表象，**状态的归宿
从编译器搬家到上下文**才是实质——第 58 章 FAQ"单遍身份是状态
只有当前函数"在本章升级为"当前函数 + 它的祖先链"（状态仍是
有限的、随词法深度线性）。

**其三，identFn 的三岔路**（§57.1 已详）与 **exprStmt 的三岔路**
（赋值版本：SET_LOCAL / SET_UPVALUE / SET_GLOBAL）——读写对称，
各三岔。注意 SET_UPVALUE 不弹栈（赋值表达式有值的 55 章口径
在上值版的原样延续——**指令语义跨章冻结**的又一处体现）。

**其四，endScope 的两行新增**（isCaptured 检查 + CLOSE_UPVALUE）
——伏笔表第 6 行的兑现点，语义在 §57.3 已讲，这里补一行实现
注释：CLOSE_UPVALUE 发在**弹栈 POP 之前**（先搬家后让位——与
Return 的先关后拆同一时序律，一处两现）。

**其五，funFn 一行**（`function(false)`）——第 15 章"函数与
字面量一视同仁"的编译器版：同一套身体、同一个函数、只差 named
布尔（顶层进表 / 字面量发 CLOSURE）。第 15 章 callClosure 的
对称表在此有了发码侧的镜像。

**其六，CLOSURE 发码段**（function(false) 尾部）——直接写
o->fn->code 而不走 emit 帮手（因为发码目标是**外层**的 chunk，
emit 绑定 ctx_——这里的绕行是"跨层发码"的全部需要，五行走完）。

六处加起来 diff 不到百行——**副本制的增量美学**：第 58 章 450
行编译器，本章新增量约四分之一，其余原样。对照工业的 branch
diff 审查：读懂这六处 = 读懂本章编译器的全部新逻辑。

### 60.1.2　与第 15 章环境链的字面互文

把两章的同名机制排成对照表（读起来几乎像同一章的两种写法）：

| 机制 | 13 章（树遍历） | 本章（字节码） |
|---|---|---|
| 嵌套函数的上下文 | checkFunBody 压作用域栈 | FnCtx 链 push/pop |
| 名字三岔 | resolve→绑定表/环境链/全局 | resolveLocal/Upvalue/Global |
| 捕获判定 | collectCaptured 先收集后诊断 | resolveUpvalue 命中即登记 |
| 捕获的物化 | Environment 节点（创建闭包时） | ObjUpvalue 盒子（CLOSURE 时） |
| 变量的家 | 环节点的 map 格 | 栈格（开放）或盒（关闭） |
| 帧回收的影响 | 无（环境是堆对象） | 关闭搬家（先关后拆） |

六行互文是"同一语义、两种实现"的又一次全息对照——读者若把
第 15 章的 SemCheck 换成 Compiler、Environment 换成上值，两张
架构图可以重叠着读。教程两线（树遍历线/字节码线）至此完全
平行闭合——收官章的 survey 表将以"P1 四路全等"记录这次闭合。


### 60.1.3　一个容易写错的语料与文法的边界

P4 的第一版（坑二）暴露了文法边界在语料设计期的另一面：**写
语料的人默认自己语言的直觉**（中途回 return 是多数语言的常识），
而 TIP 的尾 return 是第 15 章就立下的家规。两课：其一，**共同
语料库（13 章 P1/P2）是防跑偏的锚**——它们当年就在尾 return
文法下写就，逐字符复用天然合规；其二，**新语料过编译器之前先
过文法自查**（return 只在尾、比较集全、无数组无记录）——语料
的"类型检查"就是对照文法数一遍产生式。教程五组语料里 P3/P4
都是新写，P4 踩坑正因为跳过了这道自查——错题本的第六段
（迁移）对语料写作同样成立。


### 60.1.4　isCaptured 为什么不用回填而用登记

第 58 章的主角是回填（占位与兑现），读者会问：isCaptured 能否
也回填——出块时回头查"这格被捕了吗"？**不能，单遍没有回头**：
出块时字面量已在几十条指令前编译完，捕获事实若当下不记、
过后无处可查（除非为每个槽位维护"被捕历史"表——那就是把
isCaptured 换了个存法，仍是登记制）。**登记制的哲学：信息在
产生的那一刻落到它的最终家**——捕获事实产生于 resolveUpvalue
命中、落到 Local::isCaptured、消费于 endScope——三点一线，
零回头。对比回填的哲学（目标尚不存在、先欠后还）：两者是
"信息可用性"的两种时间形状，第 58 章与本章各领一种——**单遍
编译器同时是这两种时间管理的合订本**。


### 60.1.5　捕获表的三种消费视角

同一张 upvals 表被三方读：**编译器**（addUpvalue 写、去重时读）
；**反汇编**（CLOSURE 注释列"捕获[槽1]"——表是注释的数据源）
；**运行期**（CLOSURE 指令按表展开）。三方共享一张静态表是
"单一事实源"（single source of truth）在指令编码里的形态——
若反汇编自己另算捕获（比如从函数体扫描引用），Lt 坑的翻版
（两表失同步）就在这里等着。**教程的 15 项断言里第五组四个
"有"，锁的正是这张表在三方间的一致呈现**。

## 60.2　运行期 I：开放上值表

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
    ObjClosure *closure = nullptr;  // 57 章：上值经闭包解析（脚本帧也有壳）
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
    // —— 57 章上值账 ——
    int openUpvalueCount() const { return int(openUpvalues_.size()); }
    int boxesCreated() const { return boxesCreated_; }  // 堆盒子数（对照 13 章环境节点）

  private:
    uint8_t readByte();                // 取操作数并推进 ip
    uint16_t readU16();
    Value pop();
    void push(Value v);
    Value &peek(int down);
    // 上值三函数（§25.3）
    std::shared_ptr<ObjUpvalue> captureUpvalue(Value *slot);
    void closeUpvalues(size_t lastValidIndex);  // 关闭指向 lastValid..栈顶 的上值

    std::vector<Value> stack_;
    std::vector<Frame> frames_;
    std::vector<std::shared_ptr<ObjUpvalue>> openUpvalues_;  // 按栈址降序
    int boxesCreated_ = 0;
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

#include <algorithm>
#include <iostream>

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
    openUpvalues_.clear();
    boxesCreated_ = 0;

    // 脚本帧：函数包一层无捕获闭包——帧协议对脚本与函数统一（57 章）
    auto shell = std::make_shared<ObjClosure>();
    shell->fn = fn;
    push(Value::ref(shell));
    frames_.push_back(Frame{fn.get(), shell.get(), 0, 0});
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
                ObjClosure *clo = dynamic_cast<ObjClosure *>(callee.obj.get());
                if (!clo) throw VmError{"被调者不可调用"};
                if (int(argc) != clo->fn->arity)
                    throw VmError{"元数不符：" + clo->fn->name};
                if (int(frames_.size()) >= kFramesMax)
                    throw VmError{"帧栈溢出（递归过深）"};
                frames_.push_back(
                    Frame{clo->fn.get(), clo, 0, stack_.size() - size_t(argc) - 1});
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
            case Op::Lt: {
                Value b = pop(), a = pop();
                push(Value::num(a.i < b.i ? 1 : 0));
                break;
            }
            case Op::CloseUpvalue: {
                // §25.5：栈顶那格要被弹了——指着它的上值全体搬家
                closeUpvalues(stack_.size() - 1);
                break;
            }
            case Op::GetUpvalue: {
                uint8_t k = readByte();
                push(*frames_.back().closure->ups[k]->location);
                break;
            }
            case Op::SetUpvalue: {
                uint8_t k = readByte();
                *frames_.back().closure->ups[k]->location = peek(0);  // 不弹：赋值有值
                break;
            }
            case Op::Closure: {
                uint8_t k = readByte();
                uint8_t n = readByte();
                auto clo = std::make_shared<ObjClosure>();
                clo->fn = std::dynamic_pointer_cast<ObjFn>(
                    frames_.back().fn->code->consts[k].obj);
                clo->ups.reserve(n);
                for (int i = 0; i < n; ++i) {
                    bool isLocal = readByte() != 0;
                    uint8_t idx = readByte();
                    if (isLocal)
                        // 捕外层栈槽：captureUpvalue 查开放表（同格共享）
                        clo->ups.push_back(captureUpvalue(&stack_[frames_.back().base + idx]));
                    else
                        // 穿层传递：与外层闭包共享同一个上值对象
                        clo->ups.push_back(frames_.back().closure->ups[idx]);
                }
                push(Value::ref(clo));
                break;
            }
            case Op::Return: {
                // 帧要拆了：先搬家——指着本帧槽位的上值全部关闭（§25.4）
                closeUpvalues(frames_.back().base);
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
#ifdef IPTRACE
        std::cerr << "ip" << frames_.back().ip << ":d" << stack_.size() << " ";
#endif
    }
}

// ---------- 上值三函数（§25.3） ----------
std::shared_ptr<ObjUpvalue> VM::captureUpvalue(Value *slot) {
    // 先查开放表：同一格被两个闭包捕获 → 共享同一个上值（一改俱改）
    for (const auto &u : openUpvalues_)
        if (u->location == slot) return u;
    auto u = std::make_shared<ObjUpvalue>();
    u->location = slot;  // 开放：指栈格
    ++boxesCreated_;
    // 按栈址降序插入（栈顶在前——close 时从前往后扫即从栈顶向下）
    auto it = openUpvalues_.begin();
    while (it != openUpvalues_.end() && (*it)->location > slot) ++it;
    openUpvalues_.insert(it, u);
    return u;
}

void VM::closeUpvalues(size_t lastValidIndex) {
    // 关闭所有 location 指向 stack_[lastValidIndex .. 栈顶] 的上值：
    // 值搬进盒子、location 改指自己家（"指针搬家"）。
    Value *firstValid = &stack_[lastValidIndex];
    for (auto &u : openUpvalues_) {
        if (u->location >= firstValid) {
            u->closed = *u->location;
            u->location = &u->closed;
        }
    }
    openUpvalues_.erase(
        std::remove_if(openUpvalues_.begin(), openUpvalues_.end(),
                       [](const std::shared_ptr<ObjUpvalue> &u) {
                           return u->location == &u->closed;
                       }),
        openUpvalues_.end());
}

}  // namespace tip
```

**上值对象的两态**是全部设计的支点：开放时 `location` 指值栈的
一格（变量还住在帧里——上值只是一张"暂住证"）；关闭时值搬进
自己的 `closed` 成员、`location` 改指**自己家**——**指针搬家**
（匠书 §25.4 的"对象闭包"技巧）。妙处在搬家后 GET/SET_UPVALUE
的代码**一个字都不用改**：它们只写 `*location`——开放时写栈格、
关闭时写盒子，**间接层消化了地址变更**。这是"加一层间接解决
一切"的教科书级应用（第 59 章 FAQ 的位间接、本章的指针间接，
同一家族）。

**开放表与共享**：VM 持 `openUpvalues_`（按栈址降序），capture
时先查表——同一格被第二个闭包捕获时返回**同一个**上值对象：
P4 的写读闭包（同一 v 的一改俱改）就是这条查表路径的语义兑现；
若各造各的盒，两个闭包会各持一份拷贝、一改不再俱改。开放表
的排序（栈顶在前）为 §57.3 的批量关闭服务。

**CLOSURE 指令的运行期**：读常量索引取出 ObjFn、按编码逐条捕获
——isLocal 真 → captureUpvalue(栈格)；假 → **与外层闭包共享
上值对象**（`frames_.back().closure->ups[idx]`，不是新盒）——
穿层传递的运行期一半：爷爷的盒子直接塞进孙子的 ups，全程一份。
（编译期的"邮路"（§57.1）与运行期的"直递"在此对上——中间函数
的捕获表负责把索引翻译对，盒子从头到尾只有一个。）

**P1 计数器的全程内存画像**（把 §57.0 的 2 对 7 逐事件展开——
本章最值得手推的一张账）：

| 事件 | 值栈（片段） | 堆上盒子 | 开放表 |
|---|---|---|---|
| main 调 counter() 第一次 | …[counter闭包, c格] | — | — |
| counter 执行到 return 的 CLOSURE | …[c=0, 新闭包值] | 盒A（开放，指 c 格） | [A] |
| counter 返回（先关后拆） | …[inc1=闭包] | A 关闭（盒内 0） | [] |
| inc1(1) 调用 | …[inc1, n=1] | A（关） | [] |
| 体内 c = c+n：SET_UPVALUE | （写 A 盒：0+1） | A 盒内 1 | [] |
| inc1 返回 1 → output | … | A 盒内 1 | [] |
| 第二次 counter() 同型 | … | 盒 B（关，盒内 0） | [] |
| inc2(1) | … | B 盒内 1 | [] |

八行账读出三件事：**盒子只在 CLOSURE 执行时开**（每个 counter()
一次——与调用次数无关）；**关闭发生在函数返回那一刻**（c 是函数
头变量，死期即返回）；**此后 inc1 的每次调用读写的是关着的盒 A**
（间接层对 GET/SET 完全透明）。对照第 15 章的同事件账（E1 节点
从 counter 返回起靠 shared_ptr 活着、每次 inc1 调用还要建 N1 调用
环境爬链）：上值版**调用时零新建**（帧照建但上值不重建——P1
断言的盒子 2 恒定不随调用数增长）、访问 O(1)（间接一次）——
两个 O 的差距在小语料看不见，在百万次回调的场景就是手感。

**关闭时序的两张快照**（先关后拆的生死对照，counter 返回时刻）：

```text
【先关后拆（正解）】                【先拆后关（错误假设）】
栈: [.., counter帧, c=0]           栈: [.., counter帧, c=0]
① closeUpvalues(base):             ① resize(base): c 格被清
   盒A.closed = 0  ← 值还活着         盒A.closed = 垃圾 ← 读到残值
   盒A.location = &closed             盒A.location = &closed
② resize(base): 帧拆、c 格回收     ② 关闭：搬进盒的是垃圾
③ inc1 此后读 A.closed = 0 ✓      ③ inc1 读到垃圾 ✗（可能"碰巧"
                                      对——最难查的一类错）
```

右列的"碰巧对"值得多写一行：resize 清掉的格子在后续压栈中会被
**新值覆盖**——若 inc1 恰好在那之前没读过 A，垃圾未及消费、错误
不显——**时序错误的最阴形态：不确定的静默**。本章把"先关后拆"
写进 Return 的第 0 步并在正文三处重复，因为它值得三处重复。

**帧协议的扩展**：Frame 加 closure 字段（脚本帧也包一层无捕获
壳——协议统一）；Call 只认 ObjClosure（第 58 章的"函数值"在此
全部闭包化——匠书原设计：**函数与闭包不分家**，无捕获函数就是
捕获表为空的闭包，一套调用路径）。


### 60.2.3　闭包相等性的终注

第 15 章 §13.3 留过"闭包相等性含糊"的讨论（可变性破坏值语义）；
上值机制给了一个精确的终注：**两个闭包值相等当且仅当它们是
同一个 ObjClosure**（指针身份）——因为闭包的身体可共享（同一
ObjFn）、捕获可共享（同一盒子），但"闭包"这个值本身是创建事件
（P1 的 inc1 与 inc2 身体同、捕获不同代——值必不等）。判定走
第 59 章的位相等（装箱宇宙里指针即位型）——三章知识在一条
`==` 上会齐。**语言若要提供闭包的结构相等**（递归比较身体与
捕获），那是库层函数不是值层运算——大多数语言不做，因为循环
捕获（互指闭包）会让结构相等不终止。

## 60.3　运行期 II：close 与指针搬家

关闭发生在两处，分别对应变量的两种死期：

**块级死期（endScope）**：编译器发的 CLOSE_UPVALUE 指令——操作
数隐含"栈顶那格"。VM `closeUpvalues(stack_.size()-1)`：把开放表
里所有 location ≥ 该格的上值**批量搬家**（值进盒、指针改向、
出开放表）。为什么是"批量 ≥"而不是"恰好那格"？因为可能有多
个上值指着同一个收缩界之上的格（比如块里两个被捕获变量）——
**关闭按栈地址划线，不按变量点名**。这是开放表按地址排序的
回报：一次线性扫描完成全部搬家。

**函数死期（Return）**：VM 在拆帧**之前**调 `closeUpvalues(base)`
——凡是 location 指向本帧段（≥ base）的上值全体搬家。函数头
变量（counter 的 c）走这条路径：它们不出块（depth 0），死期就是
函数返回。**先关后拆的次序是生死攸关的**——先拆帧（resize）
再关闭的话，栈格里的值已经被清掉，搬进盒子的是垃圾。第 57 章
"Return 六步序列"在本章多了一步：**关闭是第 0 步**。

`closeUpvalues` 的实现三行核心：`u->closed = *u->location`（值
搬家）、`u->location = &u->closed`（指针改指自家）、从开放表剔除。
三条断言分别签字：P1 结束后开放表空（counter 的两个 c 盒都关了）、
P3 每圈一个盒（块级变量每圈各自关闭——下节的主角）、P4 一盒
（共享者只关一次）。



**先给五块一个索引图**（行数按本章文件实况）：

```text
vm.cpp（约 300 行）
├─ 块一 run() 开卷复位 …… 3 行
├─ 块二 Closure case …… 18 行（含注释）
├─ 块三 Get/SetUpvalue …… 8 行
├─ 块四 Call 闭包化 …… 6 行 diff
└─ 块五 上值两函数 …… 35 行
```

五块合计约 70 行新增对 230 行存量——**改造率不足三成**，且全部
新增是"挂件"（不改既有 case 的语义，除了 Return 头部插一步）。
这就是 54 章冻结纪律在两章后的复利：地基稳，改造就只能是加法。


**块五的一个易错点预注**：closeUpvalues 的 remove_if 谓词用
自指判定（location == &closed），但它**必须在搬家的 for 循环
之后再跑**——若边搬边删（循环里 erase），迭代器失效当场崩。
两段式（先全搬、后全删）是"修改与遍历分离"的最小实践——
数据结构操作的老规矩，在别的章（56 章扩容先建新表后搬家）
已现过两次，此处第三现：**同族手法在不同数据结构间迁移**，
比记住某一处的写法更有迁移价值。


**块四的一个对照细节**：第 57 章 Call 的被调者判定链是
ObjNative→ObjFn 两 cast；本章变 ObjNative→ObjClosure——裸
ObjFn 从值宇宙**退役**（只活在常量池与编译期）。退役不是删除：
ObjFn 仍是代码的载体（chunk 的所有者），只是不再作为**可调用
值**出现——"函数值 = 闭包"从 54 章的预言（§54.5 伏笔 2）到
本章的完成时。读者对照两章 Call case 的 diff，这条退役轨迹
一行可见。


**一个性能小注**（诚实账）：GET_UPVALUE 的间接寻址在现代 CPU
上是一次指针追逐（可能 cache miss——盒子散在堆上）——比
GET_LOCAL 的帧内直接寻址（栈顶缓存热）慢一两个数量级（若
miss）。V8 的上下文对象部分缓解（同层捕获聚在一个对象——
一次 miss 全层命中）；上值方案接受它（捕获访问本来就该比局部
访问贵——**语义的价格表**：局部 < 捕获 < 全局，恰好与三级
寻址的成本一致——语言的抽象层级与机器的存储层级在这个价格
表上对齐了，这不是设计出来的，是三层语义各自的最自然实现
恰好如此）。


**块二的 clox 对照**（同一段的 C 风格 vs 本章 C++）——
clox 的 captureUpvalue 里手写链表插入（prev 指针追踪），本章
用 vector+迭代器定位；clox 的盒子从 freeList 取（手工内存），
本章 make_shared。**同算法、异宿主**——把 clox 那三十行 C 读
懂后看本章 C++ 版，应当有"同一篇文章的两种书法"之感——读者
能同时读两种版本，意味着机制的理解已经脱离了语言细节（考
上值理解的试金石：你能不能用第三种语言（比如 Rust）再写一遍
开放表？——练习 11 的隐藏版）。


**一个复用机会的备注**：本章的开放表（有序、按址划线、批量
关闭）与第 59 章的散列表（有序性、探测链、批量重建）共享一个
数据结构主题——"**维护序的集合**"。两章各写了一个变体（链
式序的向量 vs 桶序的数组），读者若把两章的集合操作并排笔记
（插入保序/划线操作/批量重构），就得到了一张"有序集合操作
速查"——比单独记两个实现更能应对第三种变体（比如 LRU 的
按时间序表——同一操作集的第四应用）。


**trace_ 与上值的协同**（本章复用 54 章调试账的一个注）：
depthTrace 记栈深——上值机制**不动栈深**（盒子在堆），所以
trace 图上看不到上值活动——这正是设计意图（上值对栈账透明）。
若要追上值活动，得加第二个 trace（盒子创建/关闭事件表）——
练习 10 的三计数器就是它的断言化。**每种账只追它要追的量**，
账目分离是可观测性的设计原则（54 章栈账、本章盒账、55 章
指令账——三账并行互不干扰）。


**本章 VM 的测试覆盖说明**（诚实账）：15 项断言覆盖了机制的
主干路径，**未覆盖**的角落如实列——捕获上限溢出（u8 截断）、
同帧大量捕获（性能角落）、上值与原生函数的组合（native 不建
帧所以无捕获——语义上"原生函数闭不了包"，这是个真实的语言
设计事实，JS 的 bind 是库层补的）、CLOSE_UPVALUE 指令被手编
错用的防御（FAQ 已答：属验证器层）。四个角落各值一道练习
或一条 FAQ——**覆盖说明与断言清单同等重要**（知道没测什么
比多测几条更防回归）。


**读者自验清单**（VM 五块版）：①CLOSURE 的 isLocal 真分支调
谁？（captureUpvalue，传 &stack_[base+idx]。）②假分支拷什么？
（外层闭包的 ups[idx]——共享指针直拷。）③GET_UPVALUE 解几层
间接？（两层：closure→ups[k]→location→值。）④Return 关闭的
参数？（frames_.back().base——帧界。）⑤closeUpvalues 的删除
谓词？（location == &closed——自指即已搬家。）五问对四即可
（第 3 问的双层间接最易漏——多数人只数一层）。


**一个"删了会怎样"的思想实验**（巩固 captureUpvalue 的查重）：
若删掉查重四行（每次新盒），P4 会怎样？——两个闭包各持一盒：
rw(1) 写自己的盒 A'（15），rw(0) 写**另一个**盒 B'（从 v 的
初始 10 加 0 = 10）——输出变 **15 10**、盒子 2。P4 断言双红
（输出与盒数）——查重缺失的完整症状画像。**删一行、双红、
症状可预言**——这就是断言网建全后 debug 的形态：先读断言
名预测症状，再找对应机制（反过来就是 Lt 坑的定位法）。


**vm.cpp 的章节贡献清单**（本文件在四新章的累计新增——收官
章 survey 的文件级素材）：54 章全立（约 190 行）、55 章加全局
表与六指令 case（约 60 行）、57 章加上值五块（约 70 行）——
一个文件三轮生长、每轮只加不改（除 Return 插一步）——**
只加不改的文件史是架构质量的年轮**（读 git log --follow 的
vm.cpp 能看到三圈年轮）。


**年轮的读法补充**（git 考古的实操）：`git log --oneline --
examples/60_upvalues/src/vm.cpp` 看到的是本章一轮；对 55 章
的同一文件看两轮（55 立与 57 复制的再改造会显示为新增——
副本制在 git 里是"新文件"而非"分支"）——**副本制牺牲了
git 的共同历史**（同一段代码的历史分叉）、换取每章独立可构
建——这笔取舍教程选了后者（教学优先），工程里通常选前者
（git 分支/子模块）——又一个语境决定选型的样本。

### 60.2.1　vm.cpp 新逻辑的逐行走读

本章 vm.cpp 相对第 58 章副本的全部增量集中在五块（读者拿两份
文件 diff 着读，五块各十分钟）：

**块一，run() 的开卷三行**（openUpvalues_/boxesCreated_ 清零）——
结构账的复位。上值表跨 run 残留是最经典的脏状态（第二次 run
的关闭会碰到已死的盒子指针——教学驱动每程序新 VM 规避了它，
但清零写在这里是**防御的默认**，不该依赖调用者自律）。

**块二，Closure 指令的循环体**——每捕获两字节读码 + 二岔：
isLocal 真 → captureUpvalue(&stack_[base+idx])——注意取的是
**当前帧的栈格地址**（base+idx：第 58 章槽号语义在上值捕获里
的复用）；假 → frames_.back().closure->ups[idx]——**共享指针
直拷**（与外层闭包同盒——穿层传递的运行期落点）。二岔之外的
共性：都往新闭包的 ups 里塞 shared_ptr<ObjUpvalue>——盒子由
shared_ptr 自动保活（闭包活则盒活，闭包死则盒随亡——**引用
计数当上了小 GC**，第 23 章的正式 GC 会接管更多对象，但上值
盒的生命期恰好是引用计数最擅长的形状：无环、少改）。

**块三，GetUpvalue/SetUpvalue 两 case**——各两行，都写
`*ups[k]->location`：间接的全部代价就是这一次解引用，开放关闭
两态对这两行完全透明（§57.2 已讲）。值得看的反而是 SetUpvalue
的注释"不弹：赋值有值"——第 58 章的指令契约跨章不动。

**块四，Call 的闭包化**——被调者从 ObjFn 换成 ObjClosure（arity
查 clo->fn->arity、帧字段加 closure）。脚本与函数统一包壳（run
开卷的 shell）——**值宇宙里不再有裸函数**：全局表里注册的也是
壳（驱动里三行）、递归引用经壳、Call 只认壳。第 57 章"函数与
闭包不分家"的预言至此完全兑现——分家的只是"捕获表空与非空"。

**块五，closeUpvalues/captureUpvalue 两函数**（§57.2/57.3 主体）
——注意 captureUpvalue 的插入循环是**线性找位**（教学表个位数，
工业用带头节点的有序单链表，clox 同款——按需再优化）；
closeUpvalues 的 remove_if 谓词 `u->location == &u->closed` 是
"已搬家"的判定——**对象自指当状态标记**（比加 bool 字段更
内聚，因为自指恰是搬家的全部含义）。


**剧本的三种结局**（同一开头的三种后续——补全剧本）：结局一
（P1 型）：CLOSURE 后函数返回 → 盒关（值定格）→ 闭包逃逸、
此后读写走关盒——**最常见结局**；结局二（P3 型）：CLOSURE 与
使用同圈内完成、出块即关——**立即调用型**；结局三（P4 型）：
同格再 CLOSURE（第二个闭包）→ 查重共享同一盒 → 两闭包轮流
读写——**共享型**。三结局覆盖闭包生命周期的全部形态（逃逸/
即用/共享），P1/P3/P4 三语料各演一种——**语料即剧本选段**。


**剧本的时间戳补充**（把三结局的发生时刻标在闭包生命线上）：

```text
闭包生命线：创建 ——(开放期)—— 关闭 ——(关闭期)—— 回收
P1 戳：CLOSURE   返回前可读写   返回时关    inc1 死时盒随亡
P3 戳：CLOSURE   圈内(极短)     出块关      圈末即终
P4 戳：两 CLOSURE 开放期共享     第一闭包的调用可写   ……
```

三行戳记把"开放期长度"这个隐藏维度显影：**P3 的开放期接近
零（创建即关闭）、P1 的开放期 = 外层函数体执行时长**——开放
期的长短决定"指栈格"优化（免间接）能省多少——Lua 5.4 的
实现真有这条优化路径的雏形（短的开放期直接走栈）。教程不做，
但读者知道这个维度的存在，就读懂了实现空间还有一格。


**剧本的注释版**（15 行剧本逐行批注——教学版字幕）：

第 1 行"帧 counter base=1"——帧协议从 54 章原样来；第 2 行
"读 k、n"——变长指令的操作数对（3+2n 的来历）；第 3 行
"captureUpvalue(&stack_[2])"——槽号 1 加 base 1（编译期槽号
到运行期地址的换算在此一行）；第 4 行"查开放表（空）"——
P1 首捕获必空（P4 的第二次才有命中）；第 5 行"新建盒 A"——
代就此诞生；第 6 行"入开放表"——保序插入（P1 单盒无序可保）；
第 7-8 行"构造闭包、压栈"——值宇宙迎来新成员；第 9-10 行
"SET_LOCAL、POP"——counter 把闭包存进 c 槽（返回值路径）；
第 11 行"RETURN 先关"——本章的时序铁律现场。11 条字幕对应
剧本 15 行——**每行机器动作都有人类的why**，剧本才算教具。


**剧本与反汇编的互文**（两份文本对照阅读法）：第五组断言打印
的反汇编 CLOSURE 行 `CLOSURE 0 ; %fun/1 捕获[槽1]` 与剧本第
2-3 行**逐字段对应**（k=0 ↔ 读 k、n=1 ↔ 读 n、槽1 ↔
&stack_[base+1]）——**反汇编是剧本的静态快照、剧本是反汇编
的动态展开**。教学上这两份文本配套出（一静一动），读者先读
静态（猜过程）再读动态（验证）——先预测后对账在"文本对"上
的第三次应用（前两次：输出对账、反汇编对账）。


**剧本教学法的适用边界**（教学法自审）：剧本适合**单事件深
过程**（一次 CLOSURE 的 15 步）；不适合**多事件浅交互**（P3
的三圈——用帧账表）也不适合**状态全景**（四方对照——用表）。
三种内容三种形态（剧本/账表/对照表）在本章各得其所——**
为内容选形态而非为形态造内容**，本章的排版学终审。

### 60.2.2　一次 CLOSURE 指令的完整执行（15 行剧本）

拿 P1 的 `return fun (n) { c = c + n; return c; };` 里的 CLOSURE
执行过程写成一帧一行的剧本（ip 相对、d 栈深、A 盒）：

```text
帧：counter（base=1，槽1=c=0）       值栈：[main, counter壳, c:0, 新闭包…?]
ip 到 CLOSURE k=2 n=1：读 k、读 n（各 1 字节）
读捕获 1：isLocal=1 idx=1 → captureUpvalue(&stack_[1+1])
  查开放表（空）→ 新建盒 A{location=&stack_[2], closed=?}
  A 入开放表（按址降序）→ 返回 A
新 ObjClosure{fn=%fun, ups=[A]}
push(闭包值) → 栈：[main, counter壳, c:0, 闭包]
（随后 SET_LOCAL 1 → c 格 = 闭包；POP；RETURN→先关：A 关闭（0 进盒））
```

九行剧本覆盖：操作数解码、两岔捕获（此处走 isLocal 岔）、开放
表交互、闭包构造、压栈。**CLOSURE 是本章唯一的"多字节变长
指令"**（3+2n）——反汇编长度表（第 57 章）在此多了一行，回填
公式不受影响（CLOSURE 不跳转）。

### 60.3.1　closeUpvalues 的三行核心与一个不变式

`u->closed = *u->location; u->location = &u->closed;` 两行完成
搬家，第三行（出表）完成户籍。三行背后是开放表的**不变式**：
表中每个上值的 location 都指向值栈活格（≥ 栈底、< 栈顶上界）。
关闭破坏不变式 → 即刻出表；capture 依赖不变式 → 新盒必指活格。
**不变式是数据结构的合同**——P1 的"结束后开放表空"断言锁的
就是它在程序末态的成立（合同全程有效，末态是可观测的一个切面）。


### 60.3.2　开放表排序的一个细节推演

captureUpvalue 的插入循环按 location 降序——推演一次 P3 圈 2：
此刻开放表空（A 已关出表），新盒 B 直接插入——排序退化为无操作。
真正用到排序的场景要多盒并存：块内两个被捕获变量 x@2、y@3，
捕获序若 y 先 x 后，表 = [Y(3), X(2)]（降序）；出块关闭划线在 2
（POP 的是 x）——关闭"≥2"的全体 = X 与 Y 都关？不对——y 的
POP 在 x 之后，划线应只关 ≥ 该次 POP 的格。看 endScope 发码序：
**每个被捕获槽位各发一条 CLOSE_UPVALUE + POP**（不是合并一发）
——x 先：CLOSE 关 ≥&stack_[2]（此刻栈顶是 x@2？若 y@3 还在栈上
则也 ≥2 被关——提前关了 y！）。等等——endScope 的弹出序是从
locals 尾（最深）弹起：y 比 x 深（后声明）→ **y 先 CLOSE 先 POP**
→ x 后。划线依次 3、2——降序表恰好保证从表头（最深格）开始关，
每关一批出表一批。**排序与弹出序的对偶**不是巧合：两者都遵从
"栈顶先死"的栈序——本章实现的这一处与 clox 的 head-of-list
设计同构，是"数据布局模仿生命周期"的小典范。练习 7 的双捕获
语料正是检验这一点（断言两盒按序关闭、开放表中途恰一）。


### 60.3.3　closeUpvalues 的两种调用形态对照

同一名函数的两种进门（块级/函数级），参数语义微妙不同：

| 调用点 | 参数 | 划线含义 |
|---|---|---|
| CLOSE_UPVALUE 指令 | stack_.size()-1 | 正要 POP 的那格——关"它及以上" |
| Return 第 0 步 | frames_.back().base | 帧界——关"整帧段" |

两个参数都是**地址下界**，差别在谁划的线：指令的线是编译器
划的（槽位回收点）、Return 的线是帧协议划的（段界）。一个
实现服务两个划线人——参数化点恰好落在"界"上，是接口设计
最舒服的形状（传值即语义、无分支）。


### 60.3.4　"先关后拆"的三处回响

同一条时序律在本章出现三次：endScope 先 CLOSE 后 POP、Return
先 closeUpvalues 后 resize、（广义地）函数返回后值栈段才可复用。
三处的共性：**栈格的死讯必须先于栈格的消亡传到所有引用者**。
操作系统关闭文件要 flush、析构要通知观察者、GC 要 finalizer
窗口——跨层同型。教程把一条工程律在不同抽象层各讲一遍，
是因为**规律只有挂到具体场景上才记得住**——读者将来在任何
层遇到"引用者与资源同亡"的设计题，先关后拆都是第一反应。


### 60.3.5　盒子的四问面试（一盒定乾坤）

若本章只留一道面试题：`fun make(){ var v; v=0; return fun(n){
v = v + n; return v; }; }`——`a=make(); b=make(); a(1); a(1);
b(1);` 输出什么、堆上几个盒？标准答案：`2 2 1`（a 独立累积、
b 新代从零）、盒 2（每个 make 调用一只）。变式三连：把 v 提到
全局（0 盒——全局不捕获）；make 里两个被捕获变量（2 盒/调用）；
循环里 make 三次（3 盒）。**四问答对者，上值的语义账与内存账
双清**——本章 15 项断言的考点浓缩在这五分钟里。


### 60.4.3　"各捕各的"在三种语言里的写法对照

同一语义（循环每圈新绑定）在三门语言的最短写法并排——给要在
真实代码里用它的读者一张速查：

| 语言 | 写法 | 机制 |
|---|---|---|
| 本章 TIP | 块内 var（默认即块级） | 上值每圈新盒 |
| JS（ES2015+） | for (let i…) | 同左（let 即块级） |
| JS（老） | 立即函数包装传参 | IIFE 手动新作用域 |
| Python | 闭包默认捕获（陷阱区） | Python 循环变量**函数级共享**——坑同 var；默认参 f=(lambda i=i: …) 才隔离 |

第四行是 Python 的著名陷阱（lambda 在循环里全拿到终值——与
JS var 同型，因为 Python 的循环变量在**函数**作用域）——
**"循环新绑定"不是语言设计的默认共识，是 let/块级语言的选择**
——四个格子恰好覆盖"默认对/默认错/手动对/默认错"四种立场。
读者写循环+闭包前的三秒检查：循环变量的作用域粒度 + 默认
捕获语义——P3 的裁决力在真实世界的复刻。


### 60.4.4　从 P3 到并发的预演（一段前瞻）

P3 的"每圈新代"在并发语境有直系亲戚：async 循环里每个 await
回调捕获循环变量（JS 的异步 for、Go 的 goroutine 闭包）——
**共享代（var 式）与独立代（let 式）的语义差在并发下从"输出
不同"升级为"竞态 vs 隔离"**。教程不进并发，但读者应知道
P3 裁决的工业权重：当代几十类并发 bug 的根源之一就是"循环
闭包捕获了共享代"。本章的 0 1 2 断言，在并发世界对应的是
"每个任务看到自己的 i"——**作用域粒度是隔离性的最小单元**。


### 60.4.5　教学法的最后一问：为什么不画状态机图

读者可能注意到全章没有一张"上值状态机"图（开放⇄关闭两态）
——因为两态图会**隐藏时序**（转换的触发点才是本章难点，态
本身简单）。教程选择了"事件表 + 剧本 + 快照"三种时序表示
（§57.2.2 剧本、§57.2 帧账表、M2 的关闭时序图）——**为时序
选时序友好的图**，不为一切内容套同一种图。教学表示法与
数据表示法同律：**表示跟着内容的结构走**（本教程排版学的
最后一条家规，收官章会汇总全部家规）。


### 60.4.6　P3 语料的两个合法变体（教学口径说明）

变体一：把 `(fun(){...})()` 拆成 `var f; f = fun(){...}; output
f();`——多一个槽位（f），盒子数不变（3）——**存不存变量不
影响捕获代数**；变体二：循环变量 i 也被捕获（output 里加读
i）——盒子变 6（x 三代 + i 一代——i 是函数级，一盒到底）——
**函数级变量在循环里是单代**（这正是 P3 反例的机制面）。两
变体都可以合法地进练习（题 1 的素材），但**正文语料取最小
形态**（立即调用、只捕 x）——语料的可扩展性留给练习是教程
的分工惯例（正文最小、练习加分）。


### 60.4.7　"代"概念的正式定义（收进正文的最小理论）

前文多处用了"代"（generation），给个正式定义收束：**一个
变量声明的每一次运行期实例化构成一代**——函数级变量每调用
一代（counter 两次调用两代 c）、块级变量每圈一代（P3 的 x）；
捕获的身份是"格+代"（§57.5.2 移植须知），上值盒是代的物化
（一盒一代）。**共享 = 同代的多_closure_ 引用**（P4）、**隔离
= 不同代**（P3）——P3/P4 背靠背的语料设计在"代"这个词下
成为一句话：**同代共享、异代隔离**。这个词 borrowed from
GC 的分代术语（20 章补的 generational 正是"按年龄分组对象"）
——两处"代"的共同直觉：**时间维度上的实例分组**。


### 60.4.8　P3 反例的完整语料（存档用）

正例在期望文件里，反例（JS var 语义版）存档于此供练习 1 使用
——把 P3 的 `var x` 从块内移到函数头（一行之差）：

```text
main() {
  var i, x;             ← x 提到函数级（唯一改动）
  i = 0;
  while (i < 3) {
    x = i;
    output (fun () { return x; })();
    i = i + 1;
  }
  return 0;
}
```

预期输出 **2 2 2**（共享终值）、盒子 **1**（单代）——两个数字
与正例的 0 1 2 / 3 恰好全反。**一行之差、两象皆反**——这是
"正反同源"原则的最纯样本，也是练习 1 的现成答案（改完跑
通即完成）。


### 60.4.9　代数视角的补充（把 P3/P4 放进同一式子）

用"代"的记号把两语料写成一个判别式：**捕获共享 ⇔ 同格同代**
。P4：v@槽1@代1 被两个闭包捕——同格同代 → 共享 ✓；P3：x@槽2
@代1/代2/代3——同格异代 → 不共享 ✓；P1：c@槽1@代1（inc1）
与 c@槽1@代2（inc2）——同格异代 → 不共享 ✓；JS var 反例：i
@槽k@代1 被三闭包捕——同格同代 → 共享（终值）。**四个语料
一个式子全判**——判别式是"格+代"表示法的力量展示（比叙述
性解释快一个数量级），也再次说明 §57.4.7 给"代"下正式定义
的必要性：**没有精确词汇就没有判别式**。


### 60.4.10　裁决的最终表述（一句话定理）

把 P3/P4/反例/判别式全部收进一句话：**捕获的共享性由"格+代"
决定——同格同代共享一盒、同格异代各开各盒；块的每次进入开
新代、函数的每次调用开新代；代是声明的运行期实例化，盒是代
的堆上物化。**——四十字定理、四个语料作证（§57.4.9 式子）、
15 项断言里的 7 项直接或间接锁它。教程把"定理"用在很小的
地方（这里与 31 章框架定理的用法同型——**能被断言检验的
表述才配称定理**，不管大小）。

## 60.4　三方裁决：循环各捕各的

匠书 §25.6 的著名反例在本章落地为 P3。循环体里造闭包：

```text
while (i < 3) {
  var x;                 ← 块级：每圈是新槽位
  x = i;
  output (fun () { return x; })();   ← 立即调用：输出本圈的 x
  i = i + 1;
}
```

输出的裁决：**0 1 2**（各捕各的）——因为 `var x` 是块级声明，
每圈进块压**新槽**、字面量捕获**那一圈**的槽、出块 CLOSE 把值
搬进**那一圈**的盒子（P3 断言盒子数恰 3）。反例的形态：若 x 是
函数级（像 JS 的 `var` 提升到函数头），三圈共用一个槽、三个闭包
共享一个上值——输出 **2 2 2**（循环结束时 x 的终值）。**两种
语言设计、两种输出，分岔点全在"变量的作用域粒度"**——上值
机制忠实地执行任何一种，裁决权在文法（第 15 章 P5 块级遮蔽的
运行期版终审）。JS 的 `let` 修复（ES2015）就是把 `var` 的函数级
改成块级——这个五亿开发者踩过的坑，本章用三条断言钉死。

（为什么用"立即调用"而不是把闭包存起来循环后调？TIP 没有数组，
存三个闭包需要三个变量——立即调用是最小语料；语义等价：捕获与
关闭都发生在圈内，圈外调用只是把"读盒子"延后，盒子内容不变。）

**这个坑的产业史**值得完整讲一遍——它是"文法一改、全家受益或
全家遭殃"的最著名案例。JS 的 `var` 是函数级作用域（1995 年
10 天设计期的仓促选择），循环里造回调必然共享一个绑定——
`for (var i=0; i<3; i++) callbacks.push(()=>i)` 之后三个回调全返回
3，与 P3 的反例形态完全同型。社区十年间的三种应付：IIFE 包装
（`(function(j){ ... })(i)` 手动造块——本质是**人肉把函数级改成
块级**，本章 P3 的立即调用恰好就是这招的教学版）；`forEach` 的
回调参数天然每次新绑定（换 API 绕过文法）；ES3 时代还有人用
`with` 语句造假作用域（最黑的一种）。ES2015 的 `let` 从文法根上
修复：每圈迭代**新绑定新槽**——正是本章 P3 的语义。三个历史
形态对应本章的三种技术：IIFE = 手动块作用域（P3 的 while 体块）、
let = 编译器自动块作用域（本章默认）、var = 函数级单槽（P3 反例）。
**语言设计的债，最终都由使用者的 workaround 偿还**——直到文法
还债为止。读者以后在任何语言里写循环 + 回调，第一反应应当是：
这个循环变量的作用域粒度是什么？——这一问就是 P3 的全部。

**断言的双锁设计**（P3 为什么锁两个值）：`0 1 2` 锁**输出语义**、
`盒子数 3` 锁**实现形态**。只锁前者，一个"每圈复制值进闭包"的
错误实现（值语义）也能过（输出同）——但它在 P4（写读共享）就会
翻车。只锁后者，输出错了盒子对了也可能过（比如捕获 i 而非 x，
盒子恰 3 但输出 1 2 3）。**两个断言各堵一条歧路，合起来才把
"块级 + 引用语义 + 每圈新槽"三个性质同时钉死**——语料设计的
老法则（一段多证）在实现敏感场景的强化版：**语义断言 + 结构
断言成对出现**，缺一侧的实现漂移都能溜过。



**三圈之外的第四圈假想**（把裁决推到极限）：若循环跑一万圈，
盒子一万只、每只存一个 0..9999 的 int——内存账 = 8 字节/盒 ×
一万（盒对象本体还要算开销）。这是"各捕各的"的真实代价：
**隔离不是免费的，每代一只盒**。V8 对这种场景有个著名优化
（逃逸分析：闭包不逃逸出圈就复用盒子/栈分配），静态引擎能做
（编译期证明不逃逸）、动态引擎靠运行时试探——**隔离的安全
与合并的省内存是一对永恒张力**，P3 的 3 只盒子是张力的最小
显影。读者写真实代码时的直觉：循环内造闭包存集合，是这门
语言里最贵的循环体之一（每圈一只盒 + 每闭包一个对象）——
知道贵在哪，比笼统"闭包慢"有用一万倍。


**断言排布的深意**：P3 的两个断言（输出 0 1 2、盒子 3）之后，
紧接着 P4 回到单盒——**裁决（多盒）与共享（单盒）背靠背**，
防止读者把"各捕各的"过度泛化成"闭包总是各造各盒"。P3/P4 的
组合拳：同格同代共享（P4）、同格异代不共享（P3）——**共享的
粒度是"代"不是"地址"**，这一句话是两段语料合起来才教得清的
知识，单出任何一段都会教偏。


**逐圈账的教学法近亲**：这种"逐事件行×逐对象列"的账表在第 15 章（P1 逐帧表）、54 章（栈深账）、55 章（前三圈循环账）
都已用过——四张账表是同一家族（时间×对象的状态矩阵）。
家族名可叫**推演表**——教程对"过程性知识"的标准表示。读者
自己做项目时的对应物：协议交互的时序图、并发调度的 trace
表、GC 的对象生死账——**凡过程皆可推演表**，这个习惯比任何
单张表更值钱。

### 60.4.1　P3 的逐圈账（盒子视角的三圈全录）

P3 的三个盒子不是同时存在的——**每圈生一个、当圈就关一个**。
三圈全录（只看 x 相关的栈与盒）：

| 圈 | 进块 | 捕获 | 立即调用读 | 出块 CLOSE | 圈后开放表 |
|---|---|---|---|---|---|
| 1 | x 格@2 压（值 0） | 新盒 A 指格 2 | 经 A 读格 2 = 0 ✓ | A 关（0 进盒），POP | 空 |
| 2 | x 格@2 复压（值 1） | 新盒 B 指格 2（A 已关，地址虽同是**新代**） | 经 B 读 = 1 ✓ | B 关（1 进盒） | 空 |
| 3 | 格@2 复压（值 2） | 新盒 C | 读 = 2 ✓ | C 关（2 进盒） | 空 |

表的三行读出三个"新"字：**每圈新槽**（同一物理格，POP 后复用
——代际由声明序定）、**每圈新盒**（开放表按代不按地址——FAQ
第二问的详版）、**当圈即关**（立即调用后出块，盒子从不跨圈开放）。
三盒最终都躺在堆上（值 0/1/2 各一）——**P3 语料结束后的内存里，
三个数字各住一个盒**：这就是"各捕各的"在内存里的终态照片。

对照第 15 章 P5（立即调用 + 形参遮蔽）的环境版：那章的隔离靠
"调用环境一层"（每调用一个节点），本章的隔离靠"块作用域一代"
（每圈一个盒子）——**隔离的来源不同（调用 vs 声明），可观察
结果同构（各读各的）**，又一对"语义对账、实现各异"的样本。

### 60.4.2　为什么说这是"终审"

块作用域的三个证明层次在本教程依次出现过：**第 15 章 P5**
（树遍历：形参遮蔽外层——作用域栈的最近包围胜出）；**第 58 章
P3**（编译器：块内 var 新槽、出块回收——槽位账的隔离）；**本章
P3**（上值：每圈新代盒子——逃逸后的隔离）。三层各证明一件事：
解析层（名字找到谁）、存储层（槽位分不分）、生存层（逃逸后分不
分）。**闭包是作用域的终极考试**——前两层的隔离若在第三层失效
（共享了一个盒子），前功尽弃；P3 的 0 1 2 是三层全过的证书。
JS 的 var/let 之争恰是"第三层失效"的历史现场（函数级 var 在
第一二层也没隔离）——文法、槽位、盒子三层的对应关系，读者
现在可以完整讲出了。


### 60.5.5　对照表的使用法（怎么"读"一张对照表）

四方表不是用来背的，是用来**查的**——三个查询姿势：设计新
实现时按列查（"上值列的捕获粒度是什么"→ 变量级）；排错时按
行查（"共享语义哪行能解释一改俱改"→ 谁搬家行）；学习迁移时
按格查（"装箱单的静态信息量为什么全"→ 编译期能算捕获集）。
**行列格三种查询对应三种思维**（设计/诊断/迁移）——表的价值
乘以查询姿势数。教程的对照表家规：**每张表都要在正文里演示
至少一种查询**（本表在 §57.5.1 谱系定点处演示过列查、在 P4
断言处演示过行查）。


### 60.5.6　对照表的第五行读法（静态信息量的深读）

"静态信息量"行值得单独深读——它是四方差异的理论根源：**环境
链几乎为零**（运行期才知道谁捕谁）、**装箱单全静态**（编译期
算完捕获集——静态语言的类型系统恰好提供这个能力）、**上值
半静态**（捕获集编译期、代与盒运行期）、**访问链零**（不捕）。
信息量决定三件事：能做什么优化（装箱单能栈分配不逃逸的盒
——escape analysis 的前提）、诊断能多准（静态信息撑起精确
错误消息）、语言能多动态（信息越少越自由）。**静态信息是
编译器的视力**——四种视力水平对应四种语言生态位，这张表
其实是语言生态的视力表。


### 60.5.7　对照表的施工说明（这张表怎么造的）

给想仿制对照表的读者一句方法说明：四列不是一次填的——先立
两列（13 章环境链 vs 本章上值——写两章时的自然对比），第三
列（53 章装箱单）在写本章 §57.0 时想起"51 章做过编译期版"
而补入，第四列（19 章访问链）在 §57.5 落笔时为完整而补查。
**对照表是长出来的不是画出来的**——每列必须有一个"真做过"
的实现或一章"真读过"的正文（不许凭科普印象填格）。教程的
四列全部满足（四实现/四正文）——这是它敢印出来的资格。

## 60.5　四方对照：环境链 / 装箱单 / 上值 / 访问链

教程至此把"闭包变量的家"讲了四遍，四方对照总表收官：

| | 环境链（13 章） | 装箱单（53 章 cited） | 上值（本章） | 访问链（19 章 cited） |
|---|---|---|---|---|
| 捕获粒度 | 整层环境 | 编译期捕获集装箱 | 单变量按需 | 不捕获（链上现查） |
| 谁搬家 | 没人搬（共享节点） | 编译期装箱进堆 | 运行期 close 搬 | 没人搬（帧上链） |
| 无关变量 | 也被拖着常驻 | 不装（精确清单） | 不捕（精确） | 也被拖着（整帧） |
| 帧回收后 | 链节点靠计数活着 | 盒子独立 | 盒子独立 | 帧没了就没了 |
| 静态信息量 | 几乎为零 | 全静态 | 半静态（捕获表） | 零 |
| 堆对象/计数器 | 7 个环境节点 | —（53 章口径） | **2 个盒子**（实测） | 0 |

第三行的"无关变量"是上值对环境链的核心胜势：counter 里哪怕再
声明十个无关变量，环境链全拖走（节点里都有）、上值一个不碰——
**P1 的 7 对 2 是这个差别在最小语料上的显影**。第二列的装箱单
（第 56 章函数式篇的闭包转换）与上值同精度，分野在**时机**：
编译期装箱（不跑也知道要装谁——静态语言）vs 运行期按需（跑了
才捕——动态语言的灵活，代价是 CLOSURE 指令与开放表）。第四列
访问链是**不逃逸世界**的方案：闭包不存在（或都随帧死），链上
现查——第 57 章 FAQ 说过"上值是帧没了之后的访问链"，此表即其
全貌。

**工业世界的第五列**：真实引擎并不严格选边——V8 的**上下文
对象**（Context）是环境链与上值的杂交：每层函数一个堆对象装
**该层全部被捕获变量**（编译期算出捕获集、整层装箱——装箱单
的粒度），对象间连链（链式——环境链的形状），访问经槽号
（静态——上值的编译期账）。三者的杂交动机是工程折中：单变量
盒子（上值）在**多变量同捕**时盒子数爆炸（10 个变量 10 盒 vs
1 个上下文）；整层环境（13 章）在**单变量捕获**时拖家带口。
V8 按"每层被捕获集合"装箱，两端取优。教学线选纯上值（匠书
原味）是因为它的机制最透明（两态对象 + 指针搬家的每一步都
可手推）——**学最透明的，工程里再认识杂交的**，这个顺序不可
颠倒（先学 V8 上下文会被分配/去优化细节淹没，而上下文的核心
恰恰是上值教的那两件事：静态捕获集 + 堆上的家）。

四方对照表至此可以扩成"闭包实现的谱系图"：粒度轴（变量 →
层内集合 → 整层）×时机轴（编译期 → 创建期 → 关闭期）——六个
象限各有真实居民：上值（变量 × 关闭期）、装箱单（集合 × 编译期）、
V8 上下文（集合 × 创建期）、环境链（整层 × 创建期）、访问链
（不捕获）、Lua 的 upvalue（=本章上值，Lua 5.0 的历史命名——
upvalue 这个词本身出自 Lua 家族，匠书沿用）。**读完本章的读者
应该能在这张谱系图上给任何新引擎定点**——比记住任何一个实现
更重要。


### 60.5.1　Lua 的命名与 Scheme 的古老先例

upvalue 一词出自 Lua（5.0 引入、Roberto Ierusalimschy 团队）——
Lua 的闭包实现与 clox 几乎同构（开放 upvalue 链、close 搬家），
匠书明言 clox 的设计参考了它。更早的先例：**Scheme 的实现史**
（Clinger 的 Rabbit、Kelsey 的 Orbit）里"assignment convert"
（赋值转换：被捕获的变量改箱——assign 变成对箱的读写）正是
装箱单路线的学术名；而**Hedgehog/Larceny 的 display** 是访问链
的 Scheme 版。三条学术血脉（函数式学派的赋值转换、嵌入学派的
upvalue、编译学派的 display）在工业语言里各成一系——本章四方
对照表本质上是这三系加环境链（教学系）的坐标。读者带这张
谱系读任何实现论文（比如 V8 的 context 论文），标题里的每个
词都能在此找到座位。



**三行直觉的实测化**（练习 10 预告）：给 VM 加三个计数器
（CLOSURE 次数、GET_UPVALUE 次数、闭包 Call 次数），P1 跑完
读数应为 2/3/3（两次创建、三次访问、三次调用）——三个数与
内存账（盒 2）合成一张"上值方案的完整账单"。把它贴到第 15 章 P1 的环境账（节点 7、爬链 3×2 跳）旁边——**同一程序两张
账单**，四方对照表从概念表变成了实测表。收官章的 survey 若
有篇幅，这两张账并排就是第十篇的最佳插图。

### 60.5.2　性能直觉：上值方案的隐性账户

四方对照表比的是内存（盒子数），速度账补三行直觉：**捕获开销**
（CLOSURE 指令 O(捕获数)，环境链版创建闭包 O(1)——上值的创建
更贵）；**访问开销**（GET_UPVALUE 一次间接 O(1)，环境链版爬链
O(词法深度)——上值的访问更便宜）；**调用开销**（上值版闭包
调用零额外、CPython 帧版每调用建帧对象——上值的调用最净）。
三行合计的结论：**创建一次痛 vs 每次访问都痛**——闭包调用
频繁的场景（回调风暴）上值完胜，一次性创建大量不调用的闭包
（配置对象风）环境链反超。Lua 面向嵌入（回调多）选上值、
CPython 面向对象生态（方法即闭包但访问少）选帧——**生态的
调用频率分布决定表示的胜负**，性能选型的元法则又一次生效。


### 60.5.3　写给自己引擎作者的三条移植须知

（若读者把上值搬进自己的语言/VM。）**其一，槽位代数要先算清**：
块级作用域下同格异代（P3）是常态不是边角——捕获的身份要用
"格+代"而不是格；clox 用开放表的即时性隐式解决了代（出表即
死代），你的实现若延迟关闭（比如到 GC 时才关）就必须显式记代。
**其二，CALL 的闭包化要一次到位**：54 章的 ObjFn 直调路径在
57 章全部收编进 ObjClosure——半途的混合（有的调用认函数、
有的认闭包）是调用协议分裂的开始。**其三，结构账（盒数/开放
表）从第一天就埋**：它是后期性能回归与语义回归（共享错、代际
错）的唯一秒杀器——本章 P1/P3/P4 的断言价值证明这个投入的
回报率。


### 60.5.4　本章在教程全结构中的坐标

第十篇收官，全教程还剩：两补章（20/52 的匠书增量）、收官章
（66）。本章在"语义地图"上的位置：**闭包叙事的终点**（13 章
开题 → 51 章编译转换 → 本章运行期）、**运行时叙事的终点**
（17 帧布局 → 19 访问链 → 20 堆 → 54 栈机帧 → 本章逃逸帧）、
**表示叙事的中继**（56 章 → 本章可选汇合 → 66 章总图）。三条
叙事线在本章交汇后交给收官章总装——**收官章的 survey 表每行
都该能指回本章某一节**，这也是本章写这么满的原因：它是总装
前的最后一站备货。


### 60.6.5　期望输出全文的结构统计

全文 33 行：断言行 15、程序输出续行 8（P1 的三行值等跨行）、
空行分组 7、汇总 1、（第五组无输出只有断言行）。**续行占比
24%** 是四项语料多行值的形态——对账文件的"锯齿状"轮廓
（断言短行与值长块交替）是输出型断言协议的特征签名，四个
新章（13/55/56/57）的期望文件都有同款轮廓——读者扫读时可
按锯齿定位组界。


### 60.6.6　断言分组的心理学（为何按此顺序）

五组顺序：全等锚（P1）→ 穿层（P2）→ 裁决（P3）→ 共享（P4）→
结构（五）。设计逻辑：**先给读者已知的东西**（13 章同源——
信任建立）→ 再给新知识的两档（穿层=机制深、裁决=语义险）→
最后收结构账（可观测末态）。对比"由浅入深"的常规排法，本
排法多了一层**信任优先**：第一组就出示第三方证词（13 章输出），
让读者带着"这实现应该对"的先验进入难点组——**排组的说服力
设计**，讲义写作的暗技巧。


### 60.6.7　本章期望文件逐行注（全部 33 行的导读）

断言 15 行的分布前面已列；补三处易看漏的细节：P1 盒子行
`2` 的对照对象（13 章的 7）写在断言名里——**断言名是断言
的一半**（名字交代考点的语境）；P3 的期望 `0 1 2` 后面跟
盒子 `3`——两个数字背靠背（输出序与内存量的并排）；第五节
四个"有"的最后一行是 GET_UPVALUE——它出现在**下钻后的**
%fun 反汇编里（第一版静默失败的坑就在这行的期望上）。**33
行里没有一行是装饰**——期望文件的每行都该能指认考点，这是
断言文件与打印输出的分界。


### 60.6.8　从本章看"教程语料库"的全貌

五轮扩充累计的同源语料网络（收官章 survey 的底稿——本章视角
的清点）：**counter/adder**（13↔57 双实现）、**fact**（13↔54
手编↔55 编译↔15 LLVM↔16 TAC 五路）、**while 累加**（55↔57）、
**块遮蔽**（13 P5↔55 P3）、**短路**（55 P4 独有——54 章练习
5 的 while 手编可加第六路）。五个语料族、每族 2–5 个实现成员
——**语料库是教程最独特的资产**（书可以抄机制，抄不了这张
跨章互证网）。新读者入门的最佳路径也许不是按章序读，而是
按语料族读（把 fact 的五路实现并排读一遍——教程的另一种
打开方式，收官章的"出发方向"节会正式推荐它）。


### 60.6.9　第五组结构断言的可读性契约

四个"有"断言锁的不只是**存在性**还是**可读性**——反汇编的
CLOSURE 行带捕获表注释（`捕获[槽1]`）、GET_UPVALUE 自解释
（操作数即上值号）——**产物文本要能让不读源码的人推断机制**
（第 57 章"反汇编即文档"的本章验收）。若实现把捕获表藏进
不可读的编码（比如位打包），断言名就得改（"有但不可读"——
教学不收）。**可读性是教学 VM 的第一性能指标**——工业 VM
的第四第五位指标在这里拿第一位，语境决定排序的又一例。


### 60.6.10　本章与收官章（66）的接口约定

给收官章交三样：**素材行**（57.7.1 第一段——survey 表的上值
行）、**语料族**（counter/adder 两族的四路会师记录——出发
方向节的 fact 族并排读推荐）、**方法论条目**（"结构断言随
实现深度上升"的观察 + 副本制的改造率指标——收官章方法论
清单的两条）。**每章向收官章交三样**是匠书轮的隐性合同——
收官不是另写一篇总结，是把各章的交付物总装（survey 表 /
每章一句话 / 延伸阅读地图）。


### 60.6.11　失败案例的档案价值（本章两坑之外）

除 Lt 与 return 两坑，开发中还有三个"差点坑"（被断言拦在
合并前）如实存档：①第一次写 closeUpvalues 时在 for 循环里
直接 erase（迭代器失效——编译通过、P1 崩，改两段式）；②
壳闭包最初只在脚本帧建、全局注册没建（P1 报"被调者不可调用"
——统一壳的三行驱动代码补上）；③开放表插入方向写反（升序
降序搞混——P4 共享失效，排序注释写清后修）。**三差点 + 两
实坑 = 本章的全部事故**——五案与 55 章的四案、54 章的两案
构成三连章的完整事故档案（收官章方法论素材：**事故数与机制
新度正相关、与断言密度负相关**——三连章的实证支持）。


### 60.6.12　（合卷）第 60 章的三个身份

本章同时是三样东西：**机制章**（上值——正文主体）、**合卷章**
（三连章收官——0.1/0.7/7.7 三处合卷视角）、**桥梁章**（对
收官章的三样交付——0.9/7.10）。三身份的写作张力真实存在
（机制要深、合卷要广、交付要精），解法是**分节让位**：§57.1–
57.4 纯机制、§57.0/57.5 偏合卷、§57.6/57.7 混合——读者按需
取节（四速档读法的分节依据）。一章多役是收官前一章的常态
（倒数第二章总是最挤的房间）。


### 60.6.13　本章期望文件与断言代码的三向一致

期望 33 行 ↔ main.cpp 的 15 个 check 调用 ↔ 汇总行"15 项"——
三处的 15 必须一致（第 15 章立的汇总自检律的第三次执行：
13 章 21、55 章 16、57 章 15）。制作流程保证一致：期望由二
进制实跑重定向生成（33 行为实况）、check 调用数在写码时定、
汇总行在收尾时按 check 计数**手填后与 grep -c "^ok" 复核**——
55 章的计数事故（填 15 实为 16）催生的复核步骤，本章执行。
**三向一致是断言文件的自洁指标**——红绿之外的第二种健康度。


### 60.6.14　本章开发的时间账（工程实录）

实录用时：机制实现约 2 小时（底座复制 20 分 + chunk/scanner
30 分 + compiler 40 分 + vm 30 分）；调试约 40 分（Lt 25 分——
含跨章追根、return 5 分、下钻 10 分）；文档与断言打磨约与
实现等长——**实现:调试:文档 ≈ 2:0.7:2**，与三连章的普遍
比例一致（54 章约 2:0.3:2、55 章约 2:1:2——55 的调试最重
因回填差一）。三账里最容易被砍的文档账恰好与实现等重——
**砍文档 = 砍一半工程**，这是教程用五轮扩充反复验证的比例
真相（也是它每章都写这么满的原因：不是话多，是账就这么长）。



**（考档的计时建议）**：15 行断言逐行说考点约 8 分钟、四组
程序徒手推演约 12 分钟——合计 20 分钟恰为一节小课的容量。
若在读书会/实验室组会做本章的考档环节，两人互考（一人持
期望文件提问、一人不看回答）效果最佳——**考档的社会化形态
是本章练习 13 的讲稿仪式的对偶**（一个考自己、一个考别人）。

### 60.6.15　（收）期望输出的最后一读

合上教程前最后一遍读这 33 行的正确姿势：**逐行说考点、逐组
讲机制**——15 行断言每行能说出它锁哪条规律（讲不出=回炉该
节）、四组程序输出能徒手推演（推不出=回炉剧本与账表）。
这最后一遍读约 20 分钟，是本章四速档之外的**第五档：考档**
——前四档给你知识，考档给你**确信**。教程的全部机器证人
制度（159 项断言、六新章）最终都服务于这 20 分钟的确定性
体验——**知道并且知道自己知道**，这 33 行就是这份确信的
物理形式。

## 60.6　驱动、语料与期望输出解读

```cpp
// file: src/main.cpp
// file: src/main.cpp
// 第 60 章驱动（无参运行，简单程序对账协议）：
//   一、逃逸闭包计数器：与第 15 章 P1 同源输出（1 2 1），帧回收后
//      计数仍正确；盒子账 2 对照 13 章环境节点 7；
//   二、嵌套捕获三层：adder(1)(2)(3) = 6（与 13 章 P2 同源）；
//   三、循环各捕各的：每圈新块作用域新槽位，输出 0 1 2（共享反例
//      会是 2 2 2——§25.6 关键裁决）；
//   四、共享上值：writer/reader 两个闭包同一变量一改俱改；
//   五、结构断言：close 后开放表空、两闭包同一上值对象；
//   六、断言汇总。
#include <functional>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>

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
    std::string verdict;
    std::string output;
    int boxes = 0;          // 堆盒子数（对照 13 章环境节点）
    int openAtEnd = -1;     // 运行结束时的开放上值数（-1 = 未跑）
};

RunResult journey(const std::string &src) {
    RunResult r;
    tip::Compiler c;
    tip::Program prog;
    try {
        prog = c.compile(src);
    } catch (const tip::CompileError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    } catch (const tip::ScanError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    }
    r.verdict = "通过";

    std::ostringstream os;
    tip::VM vm(os);
    for (const auto &f : prog.fns) {
        // 注册进全局表：函数包一层无捕获闭包（Call 只认闭包）
        auto clo = std::make_shared<tip::ObjClosure>();
        clo->fn = f;
        vm.globals[f->name] = tip::Value::ref(clo);
    }
    std::shared_ptr<tip::ObjFn> mainFn;
    for (const auto &f : prog.fns)
        if (f->name == "main") mainFn = f;
    try {
        tip::Value v = vm.run(mainFn);
        os << "ret " << v.i;
    } catch (const tip::VmError &e) {
        os << "运行时错误 " << e.msg;
    }
    r.output = os.str();
    r.boxes = vm.boxesCreated();
    r.openAtEnd = vm.openUpvalueCount();
    return r;
}

}  // namespace

int main() {
    std::cout << "== 一、逃逸闭包计数器（与第 15 章 P1 同源）==\n";
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
        check("P1 输出（13 章全等）", r.output, "1\n2\n1\nret 0");
        check("P1 盒子数（对照 13 章 7 环境节点）", std::to_string(r.boxes), "2");
        check("P1 结束后开放表", std::to_string(r.openAtEnd), "0");
    }

    std::cout << "\n== 二、嵌套捕获三层（与第 15 章 P2 同源）==\n";
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
        check("P2 输出", r.output, "6\nret 0");
        // x 在 adder 帧（被两层字面量传递）、y 在中层帧：两个盒子
        check("P2 盒子数（x 与 y 各一）", std::to_string(r.boxes), "2");
    }

    std::cout << "\n== 三、循环各捕各的（§25.6 关键裁决）==\n";
    {
        RunResult r = journey(
            "main() {\n"
            "  var i;\n"
            "  i = 0;\n"
            "  while (i < 3) {\n"
            "    var x;\n"
            "    x = i;\n"
            "    output (fun () { return x; })();\n"
            "    i = i + 1;\n"
            "  }\n"
            "  return 0;\n"
            "}\n");
        check("P3 判定", r.verdict, "通过");
        // 每圈 x 都是新块作用域的新槽位：close 时各搬各的盒子
        check("P3 输出（各捕各的 = 0 1 2）", r.output, "0\n1\n2\nret 0");
        check("P3 盒子数（每圈一个）", std::to_string(r.boxes), "3");
    }

    std::cout << "\n== 四、共享上值（一改俱改）==\n";
    {
        // TIP 文法 return 只在函数尾——用 set*5 让同一闭包既写又读：
        // rw(1) 写 v+=5 → 15；rw(0) 写 v+=0 → 仍 15（同一盒子的连续读写）
        RunResult r = journey(
            "maker() {\n"
            "  var v;\n"
            "  v = 10;\n"
            "  return fun (set) {\n"
            "    v = v + set * 5;\n"
            "    return v;\n"
            "  };\n"
            "}\n"
            "main() {\n"
            "  var rw, a;\n"
            "  rw = maker();\n"
            "  a = rw(1);\n"      // 写：v = 15
            "  output a;\n"
            "  output rw(0);\n"   // 再写 +0：仍是同一个 v → 15
            "  return 0;\n"
            "}\n");
        check("P4 判定", r.verdict, "通过");
        check("P4 输出（写读同盒）", r.output, "15\n15\nret 0");
        check("P4 盒子数（v 只一盒）", std::to_string(r.boxes), "1");
    }

    std::cout << "\n== 五、结构断言 ==\n";
    {
        // 反汇编：counter 返回的 CLOSURE 带捕获表 [槽1]
        tip::Compiler c;
        // counter 考函数头捕获（RETURN 运行期关闭）；补一段块级捕获
        //（CLOSE_UPVALUE 指令位）——两类关闭路径都要在反汇编里可见
        tip::Program prog = c.compile(
            "counter() {\n"
            "  var c;\n"
            "  c = 0;\n"
            "  return fun (n) { c = c + n; return c; };\n"
            "}\n"
            "main() {\n"
            "  var i;\n"
            "  i = 0;\n"
            "  while (i < 1) {\n"
            "    var x;\n"
            "    x = i;\n"
            "    output (fun () { return x; })();\n"
            "    i = i + 1;\n"
            "  }\n"
            "  return 0;\n"
            "}\n");
        std::ostringstream os;
        // 递归反汇编：字面量函数住在常量池里，不下钻就看不见它们
        std::function<void(const tip::ObjFn &)> walk = [&](const tip::ObjFn &f) {
            tip::disassembleChunk(*f.code, f.name, os);
            for (const tip::Value &v : f.code->consts)
                if (v.isObj())
                    if (auto *inner = dynamic_cast<const tip::ObjFn *>(v.obj.get()))
                        walk(*inner);
        };
        for (const auto &f : prog.fns) walk(*f);
        std::string all = os.str();
        bool hasClosure = all.find("CLOSURE") != std::string::npos;
        bool hasCapture = all.find("捕获[槽1]") != std::string::npos;
        bool hasClose = all.find("CLOSE_UPVALUE") != std::string::npos;
        bool hasGetUp = all.find("GET_UPVALUE") != std::string::npos;
        check("反汇编含 CLOSURE", hasClosure ? "有" : "无", "有");
        check("捕获表 [槽1] 可读", hasCapture ? "有" : "无", "有");
        check("CLOSE_UPVALUE 出现（出块关闭）", hasClose ? "有" : "无", "有");
        check("GET_UPVALUE 出现（体内读捕获）", hasGetUp ? "有" : "无", "有");
    }

    std::cout << "\n== 六、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（15 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
```

五组语料的考点表：

| 组 | 语料 | 考点 |
|---|---|---|
| 一 | P1 计数器 | 13 章全等（1 2 1）+ 盒子 2 对 7 + 开放表清零 |
| 二 | P2 adder 三层 | 穿层传递（x 过两层、y 过一层）+ 盒子恰 2 |
| 三 | P3 循环块捕获 | 各捕各的 0 1 2 + 每圈一盒（§25.6 裁决） |
| 四 | P4 写读同盒 | 一改俱改 + 单盒（开放表共享） |
| 五 | 结构断言 | CLOSURE/捕获表/CLOSE/GET 进反汇编（递归下钻） |

两个语料设计的自注：**P1 与第 15 章 P1 逐字符同源**（四路会师的
锚点语料）；**第五节的递归反汇编**——字面量函数住在常量池里，
不下钻就看不见它们的 GET_UPVALUE（开发期真坑：第一版只反汇编
顶层函数，结构断言静默失败——**遍历范围决定看见什么**，第 57 章 FAQ 的老话在反汇编驱动上的复发）。

**开发期真坑两枚**（第 58 章错题本传统的延续）：

**坑一（Lt 缺失）**：第 58 章 binaryFn 的 switch 没有 `case
Tok::Lt`——比较集带全的表却漏了 `<` 的发码（第 58 章语料恰好
只用 `<=`/`==`/`>`，坑潜伏到本章 P3 的 `i < 3` 才爆）。症状是
教科书级双联症：条件恒真（Le 没发、栈顶是常量 3 非零）+ 栈每圈
漏一（GET_LOCAL 压的 i 没人弹）——**一条漏发的指令，两个看似
无关的故障**。修法：枚举补 Lt、四文件全链路（枚举/opName/VM/
编译器 switch）一次补齐。教训：**switch 的 default 不该静默**
（编译器 switch 若对未匹配 token 报错，此坑在第 58 章就炸出来
了——防御位的缺席让坑潜伏了两章）。

**坑二（return 位置）**：P4 第一版语料写了函数体中途回 return
（TIP 文法 return 只在尾）——第 15 章 §13.4 的文法课在语料写作
时又踩了一遍。修法不是改文法，是改语料（`v = v + set * 5` 用
乘法折叠分支）——**语料要迁就文法的形状，正如测试要迁就语义
的边界**。

```text
; expected: expected/output.txt
== 一、逃逸闭包计数器（与第 15 章 P1 同源）==
ok   P1 判定 = 通过
ok   P1 输出（13 章全等） = 1
2
1
ret 0
ok   P1 盒子数（对照 13 章 7 环境节点） = 2
ok   P1 结束后开放表 = 0

== 二、嵌套捕获三层（与第 15 章 P2 同源）==
ok   P2 判定 = 通过
ok   P2 输出 = 6
ret 0
ok   P2 盒子数（x 与 y 各一） = 2

== 三、循环各捕各的（§25.6 关键裁决）==
ok   P3 判定 = 通过
ok   P3 输出（各捕各的 = 0 1 2） = 0
1
2
ret 0
ok   P3 盒子数（每圈一个） = 3

== 四、共享上值（一改俱改）==
ok   P4 判定 = 通过
ok   P4 输出（写读同盒） = 15
15
ret 0
ok   P4 盒子数（v 只一盒） = 1

== 五、结构断言 ==
ok   反汇编含 CLOSURE = 有
ok   捕获表 [槽1] 可读 = 有
ok   CLOSE_UPVALUE 出现（出块关闭） = 有
ok   GET_UPVALUE 出现（体内读捕获） = 有

== 六、断言汇总 ==
全部通过（15 项）
```

15 项断言全过。逐组要点：P1 的三连（输出全等、盒子 2、开放表 0）
是本章的题眼断言；P3 的 `0 1 2` 与盒子 3 并排锁死"各捕各的"；
P4 的两行 15 是共享的活证；第五节四个"有"把捕获表的可读性
（CLOSURE 注释列）锁进反汇编契约。



**语料的成对设计原则**在本章的五组里达到最密：P1/P2 同源对
账（锚）、P3/P4 裁决对（多盒/单盒）、第五组结构对（反汇编锁
编译期表）。成对的价值在防"单边教学"——只讲共享不讲代际
（或反之）都会造成系统性误解。**教程的语料写作守则至此可以
明文化：每个机制配一个正例一个反例（或边界例），正反必须
同源（只差一行）**——P3 反例（JS var 版）与正例恰差一个关键
字（var 声明位置），这是设计出来的，不是巧合。


**journey 函数的四步**（55 章三步 + 本章一步）：编译 → **闭包
注册**（本章新增：函数包壳进全局表）→ 跑 main → 收结构账。
第四步的 boxes/openAtEnd 是本章对账协议的扩展——**语义证人
（输出）+ 结构证人（内存形状）双轨**，从第 15 章（环境节点 7）
开始的"结构账入断言"传统在上值章达到最密（15 项里 5 项结构）。

### 60.6.1　main.cpp 走读与语料设计

驱动的三件本章新事：**闭包注册**（全局表里的函数也要包壳——
Call 只认闭包，三行 for 里的 make_shared 壳）；**盒子账的透出**
（RunResult 带 boxes/openAtEnd——VM 的私有账经 journey 转成断言
素材）；**递归反汇编**（§57.6 坑二的正解——walk 函数下钻常量池，
`std::function` 自引用三行）。

五组语料的**对称性设计**：P1/P2 与第 15 章 P1/P2 逐字符同源
（对账锚）；P3/P4 是本章原创（裁决与共享）；第五组是结构断言
（反汇编契约）。五组恰好覆盖上值的五面：逃逸、穿层、代际、
共享、可读性——**每面一组、每组多证**（P1 四断言：判定/输出/
盒子/开放表）。读者自扩语料时保持这个节奏：先问考哪一面，
再写最小程序。

**期望输出的读法**（逐组）：第一组四行是全章题眼——`1 2 1`
与 13 章逐字符同（四路会师）、`2` 对 13 章 `7`（粒度胜差的
数字）、`0`（合同末态）；第二组 `6` 与 `2`（值对、穿层不增盒）；
第三组 `0 1 2` 与 `3`（代际的输出面与内存面）；第四组双 `15`
（共享的行为面）与 `1`（共享的结构面）；第五组四个"有"（反汇编
契约）。**15 项里 7 项是数字断言、4 项文本断言、4 项结构断言**
——三层的比例与前两章（54 全行为、55 行为+产物）继续向结构
侧倾斜：实现章的断言越来越"硬"。


**复盘的复盘**（为什么要花一整节写一个 bug）：错题本方法论
的辩护词——传统教材隐藏错误史，读者学到的是"成品长什么样"；
错题本教材展示错误史，读者学到的是"**过程怎么走**"。两者
的差距在真实工程里巨大（工程 90% 的时间在处理非成品状态）。
Lt 坑的六段式复盘里最有价值的是第五段（防复发）与第六段
（迁移）——**一个 bug 的价值不在它修好了，在它变成了制度**
（default: throw）与规律（表间同步义务）。教程五轮扩充累计
写入十一个真坑复盘——它们是比正文更稀缺的教学资产。


**Lt 坑的跨教程档案号**：本章正文给它的编号是"坑一"，放进
五轮扩充的全档案是 **C-11**（Crafting 轮第 2 坑、累计第 11
坑——前序：龙 3、虎 2、鲸 5、匠已 1）——编号的意义是让
"坑"成为**可检索的一等公民**（收官章的坑谱统计需要编号）。
读者自己的错题本同样建议编号（日期+序号即可）——**可检索
的教训才是资产，散落的教训只是情绪**。

### 60.6.2　Lt 坑的完整复盘（错题本范式的一号样本）

这个坑值得作为**错题本的模板**完整建档：

- **症状**：P3 无限循环（输出 0,1,2,…递增不停）+ 值栈溢出
  （256 上限炸）——两个看似无关的故障。
- **定位**：反汇编逐行对照——条件区 GET_LOCAL/CONSTANT 之间
  **少了一条指令**（LT 没发）；栈账逐格——GET_LOCAL 压的 i
  没人弹（每圈漏一）。
- **根因**：第 58 章 binaryFn 的 switch 漏写 `case Tok::Lt`，
  default 静默 break——比较集"带全"的表（ruleFor 里有 Lt）与
  发码 switch 的 case 集**不同步**，语料只用过 <=/==/>，潜伏
  两章。
- **修复**：枚举补 Op::Lt（57 章副本）+ opName/VM case/编译器
  case 四处一次补齐——**指令是四文件契约，漏一处就不是加一行**。
- **防复发**：练习 6 的 default: throw（未匹配即编译错）；更本
  重的防法是**指令枚举与 token 枚举的对表断言**（编译期生成
  对照表，漏 case 在编译编译器时就炸）。
- **迁移**：任何"两张表该同步却各自维护"的系统（opcode↔助记符、
  错误码↔消息、路由↔处理函数）都埋着同款坑——**表驱动架构的
  阴影面是表间同步义务**，防御位（default 报错）是阴影面的灯。

六段式（症状/定位/根因/修复/防复发/迁移）就是错题本的标准条目
格式——比"记住别漏 case"有效两个数量级，因为它把一次事故
蒸馏成了一条可检索的工程规律。

### 60.6.3　与匠书 §25 的逐节映射

| 原书节 | 本章 |
|---|---|
| 25.1 Closing over the closure problem | §57.0 |
| 25.2 Upvalue objects（编译期表） | §57.1 |
| 25.3 Upvalues in the VM（开放表/捕获） | §57.2 |
| 25.4 Closing upvalues（先关后拆） | §57.3 |
| 25.5 Closing the loop（块级关闭） | §57.3/57.4 |
| 25.6 The key invariant（各捕各的） | §57.4 |

六节全映射。差异两处如实：本章无 clox 的 ObjUpvalue 复用自由表
（教学直接 shared_ptr，原书有 freeList——GC 章的伏笔）；本章
捕获表去重显式写 addUpvalue（原书同构、行文更简）。原书 §25.6
标题 The key invariant 指的是"每个局部变量每次实例化恰一个上值"
——本章 P3 的代际表（§57.4.1）就是这条不变式的语料化。

## 60.7　FAQ、小结与练习


**问：CLOSE_UPVALUE 与 POP 的配对由编译器保证——VM 侧要不要
防"发了 CLOSE 却没 POP"这类坏字节码？** 要防但分层：VM 的
防御位防"运行可达的错"（栈空、元数），字节码形状的错（多 CLOSE
少 POP）属**装载期校验**范畴（54 章验证器讨论）——运行时逐条
查太贵、教学 VM 不做，但"该做在哪一层"的答案要留：验证器
按效应表推每点栈深与上值状态（CLOSE 后开放表该少谁），
JVM verifier 同款。**知道防御该住哪层，比随处乱防高级**——
分层防御是编译工具链的秩序，不是成本问题。


**问：上值能被"手动关闭"吗（语言层 API）？** clox/Lua 都没有
暴露——关闭是**实现细节**，语言语义只保证"闭包存活则变量
存活"（何时搬盒子是实现自由）。若语言暴露 close（比如某
嵌入式 DSL 的省内存指令），就引入了"关闭后原帧内变量失效"
的语义坑（同一变量两个真身）——**实现细节上升为语言承诺**
是 API 设计的经典错误方向。教学实现不暴露、正文不讲"如何
暴露"——这一问只答"为什么不"。


**问：上值机制的"一句话历史"怎么讲？**（面试或讲课场景。）
函数闭包的自由变量存储问题（1970s Lisp 机器直接堆分配一切
→）Scheme 的赋值转换（1980s——编译期装箱）→ Lua 5.0 的
upvalue（2003——运行期按需，工业定型）→ V8 上下文（2008——
层粒度折中）→ 教程四方对照（每格一个已实现方案）。五个节点
三分钟——**历史线就是方案谱系的展开线**，讲历史比讲定义
更容易被记住（因为历史有因果，定义只有断言）。

**问：开放表为什么要按栈地址排序？** 批量关闭的划线需要：close
时从栈顶向下扫到界线即停（排序使"界线之上的全体"连续分布）。
不排序也能正确（全表过滤），只是每次关闭全表扫——排序是
**为高频操作（close）优化数据布局**，与第 59 章开放定址的
"数组连续"同理。

**问：一个变量能既在开放表又被第二个闭包捕获吗？** 能且正是
共享的实现——captureUpvalue 查表命中即返回旧对象（P4）。但注意
"同一格"的判定是**栈地址**（`u->location == slot`）：块级变量
每圈占同一格（POP 后复用），第二圈的捕获是**新盒子**（旧盒已
关、地址虽同但开放表里已没有它）——P3 的盒子数 3 由此而来。
**地址相等 ≠ 同一变量代**，开放表的身份是"这格现在的暂住证"。

**问：为什么不让 ObjUpvalue 直接持有 Value（值语义）？** 开放的
上值必须与栈格**共享存储**（闭包写要反映到帧里、帧内读写要反映
到闭包——counter 的 c 在返回前就是普通栈变量），指针间接是共享
的最小实现；关闭后"改指自家"保持接口不变。值语义版（拷贝进出）
会在开放期丢掉共享——第 15 章共享式捕获的语义要求（P1 的 2 而非
1 1）否决了它。

**问：闭包能捕获全局吗？** 不需要——全局不在任何帧里、永不死，
GET_GLOBAL 直接查表（第 58 章迟绑定原样）。捕获表里只有栈格与
上值两种索引，全局根本不进表——**永生的东西不需要搬家**。

**问：上值能捕获上值的上值吗（三层以上）？** 能——递归 resolveUpvalue
的每一层都添一行 isLocal 假的传递条目，运行期 CLOSURE 层层直递
同一个盒子。P2 已是三层（x 过两层）；理论无上限，但每层函数的
捕获表都多一行"过路费"——**深嵌套的捕获路径长度 = 词法深度**，
这是回调金字塔在闭包实现上的真实成本（V8 用上下文对象整层共享
来摊平它——环境链与上值的折中产物）。



**问：为什么 P1 断言"结束后开放表空"而不是"恒空"？** 恒空是
错的——执行**中**开放表非空（counter 返回前的 A、adder 第二层
CLOSURE 时的 y 格上值都是开放态）。"末态空"断言的语义是**合同
的终局检查**：所有该关的都关了（没有泄漏的开放指针指着死栈格）。
若想断言中间态，得在 VM 里加钩子（比如 captureUpvalue 处回调）——
教学断言只取可自然观测的末态，中间态靠逐帧推演（§57.2.2 的
剧本）传递给读者——**断言锁边界、推演管过程**，两层分工。


**问：本章的 shared_ptr 盒会不会有循环引用？** 闭包→盒的引用
无环（盒不引闭包），唯一潜在环在"闭包捕获自己"（函数字面量
捕自己的局部——但局部不是闭包，不成环）；真正的环在**闭包
经全局表引用闭包**（递归 + 捕获的组合）——全局表持闭包、闭包
不持全局表，仍无环。**上值的引用图天然 DAG**，shared_ptr 即可
——这是上值方案对引用计数的第二份礼物（第一份是第 57.2 的
"闭包死盒随亡"）。若你的语言允许闭包直接存在自己的捕获变量
里（把闭包塞进自己捕获的数组——TIP 无数组，JS 可以），环就
出现了——那时才需要真 GC（20 章的正题在 JS 生态的真正入口）。


**问：本章代码里最值得抄走的三段是哪三段？**（给"抄作业"
读者的指路。）①resolveUpvalue 递归（途经登记+去重——任何
名字解析穿层的场合可复用，改两行就能做模块系统的重导出）；
②closeUpvalues 的划线关闭（按址批量、两段式搬删——事件
订阅的批量取消、观察者的批量通知同构）；③CLOSURE 指令的
"编译期表 → 运行期对象数组"展开模式（一切"静态描述运行时
实例化"的场合：类元数据→对象、路由表→处理器、指令模板→
机器码）。三段各带一个迁移场景——**抄代码的最高形式是抄
模式**。

**问：上值与 56 章的值表示如何汇合？**（两章的接口）56 章装箱
Value 是 uint64_t、ObjString 等对象藏尾数；本章 Value 还是 55 章
的联合版。汇合点在 57 章副本的"可选升级"：ObjUpvalue/ObjClosure
作为 Obj 子类天然可装箱（指针藏尾数），GET_UPVALUE 的 `push
(*location)` 里 location 指向装箱格——位型即类型，判定走位运算。
**两章正交**：表示管"值怎么存"、上值管"变量住哪"——汇合只是
把两件独立正确的事装进同一个 VM（练习 8 的改造点）。教程分行
讲述是为了每章一个主角，工程里它们就是同一次 VM 重构的两个
commit。

**问：GC 时代上值盒怎么办？**（20 章伏笔的正读）盒由 shared_ptr
保活（本章），真 GC 接管后：盒是堆对象 → 进标记清除的图；闭包
的 ups 是盒的引用边；**盒不再被任何闭包引用即死**（可达性判定
与引用计数此处一致——盒无环）。原书 §26 的 GC 恰好以上值为
教程对象做标记遍历——匠书把 GC 章排在闭包章之后的深意：**GC
的第一个真实客户就是上值**。本教程 GC 已在 20 章（先行讲过），
读者现在回看那章的"对象图"，上值盒应当能在脑中自动对号。


**问：如果没有闭包逃逸，本章的机制一行为零吗？** 差不为零
但恒为零开销：无捕获程序里 CLOSURE 仍执行（捕获数 0——循环
体零圈、造一个壳闭包）、GET/SET_UPVALUE 不出现、开放表恒空
——**机制在场、动作缺席**（飞机的安全带不因无人扣而拆除）。
这保证了 55 章的全部语料在 57 章副本下输出不变（副本制向后
兼容的机制基础——55 章语料实际就是 57 章 VM 的回归测试集，
10 项断言免费扩成 25 项）。

**问：为什么本章不实现 ObjUpvalue 自由表（原书有）？** clox 的
自由表是 C 手工内存管理的必然（free 后复用防碎片）；C++ 版
shared_ptr 自动归还堆——**语言替你做了自由表的事**。原书部件
在 C++ 里的对应物"消失"，不是缺失是下沉——识别哪些部件被宿主
语言吸收，是把书读薄的一半功夫（另一半是识别哪些没有对应物，
如宏陷阱被 inline 函数吸收、双 pass 回填没有——那是真知识）。


**问：上值索引 u8 上限 256 会不会太小？** 捕获表按**函数**计
（不是按程序）——单函数捕 256+ 个外层变量的代码在真实世界
接近不存在（人类可读函数的局部变量中位数约 5–10）。clox 同
上限、Lua 上限 255 且报"too many upvalues"——**上限是设计者
对代码形态的假设**，违反假设的程序得到明确错误（而非静默截断
——Lua 报错的做法是对的，本章实现直接截断是教学省略，如实
记入"与原书差异"）。


**问：本章的机制能扩展到"捕获参数化"吗（比如按需捕获的惰性
变体）？** 能设想（捕获推迟到首次读写——再省一点无访问闭包
的盒子），但代价是 GET/SET_UPVALUE 要带"可能未捕获"分支
（快路径变慢）——**为罕见场景（造了不用的闭包）税常见路径
（每次访问）**，负收益。clox/Lua/V8 都不做，此问的价值在
展示"能做但账算不平"的决策形态——教程第三次出现（前两次：
56 章墓碑定期清理、55 章 SET_GLOBAL 宽容）。

**问：递归函数自己算自己的上值吗？** 不——递归调用走 GetGlobal
（第 58 章 FAQ：名字不在局部表），全局无帧无捕获。但**递归函数
内部的字面量捕获递归函数的局部**是合法且常见的（递归造闭包树：
`f(n) { var a; a = n; return fun(){ return a; }; }` 递归 f 三层
= 三个盒）——递归与捕获正交，各走各路。

**问：能捕获形参吗？** 能——形参就是槽 1..arity 的局部（第 58 章：形参与 var 同栈），resolveUpvalue 命中形参槽照捕不误（P2 的
x、y 都是形参捕获）。**形参捕后帧回收时同样先关后拆**（Return
的关闭按地址划线、不分形参还是 var）——"参数按值传递"在捕获
存在时有个有趣的推论：捕获的是**槽的代理**不是值的拷贝（P4
的一改俱改若换成"读时拷贝"就会变成 15/10 两个答案——语义
在共享与拷贝间二选一，教程选共享与 JS/Lua/Scheme 一致）。


**三句话的展开版**（给讲师的 15 分钟串讲稿）：第一句讲对象
（两态一张图：开放指栈、关闭指家，GET/SET 只认 *location——
间接层消化迁移）；第二句讲编译（捕获表怎么来：递归穿层、
途经登记、去重保共享、isCaptured 通知出块）；第三句讲生死
（块尾一条指令、返回一步在前、先关后拆保住值）。三句各配
一个断言组（P4 共享、P2 穿层、P1 终态）——**章法与讲法
同构**：本章的结构就是这门课的最佳教案。


**收束一行**：上值教的是"**家可以搬、门牌不变**"——GET_UPVALUE
永远读 *location，location 从栈格换到盒子，地址换了、语义的
门牌没换——间接层是搬家的合法手续。读者把这个意象带进任何
"存储位置会变"的系统（迁移、热更新、分布式重分片），都是
同一个设计问题的上值版。


**终注**（排版学之外的一句）：本章把"闭包"这个词从第 15 章
的语义概念（身体+环境指针）走到了第 60 章的工程实体（身体+
捕获表+盒子网）——**一个概念的两次成像**（语义像与工程像）
，教程用两章完成的这件事，正是"学语言"与"学实现"的分界
课程。读者现在两像都有——可以去看任何一门真语言了。

**小结**：上值 = 开放（指栈格的暂住证）+ 关闭（值进盒、指针改指
自家）两态，搬家消化地址变更、间接层保证 GET/SET 代码不变。编译
期 FnCtx 链 + resolveUpvalue 递归把捕获决定成表（isLocal 二相：
捕外层栈槽/穿层传递），isCaptured 标记让出块先关后弹；运行期
开放表查重实现共享、CLOSURE 按表展开、关闭在块尾（指令）与函数
返回（先关后拆）两处触发。P1 的盒子 2 对 13 章节点 7 是"按需
捕获"对"整层拖走"的实测胜差；P3 的 0 1 2 是块级作用域的终审；
四方对照表收束了教程的闭包叙事。两枚开发坑（Lt 潜伏、return
位置）延续错题本传统——**switch 静默 default 是坑的温床**。


**术语表补遗**（首版之外的六个）：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| 代（generation） | 同格的 очередной 实例化（P3 每圈一代） | §57.4 |
| 单一事实源 | 捕获表被编译/反汇编/运行三方共读 | §57.1 |
| 登记制 | 信息产生时即落最终家（对照回填制） | §57.1 |
| 结构证人 | 盒数/开放表等内存形状断言 | §57.6 |
| 先关后拆 | 资源消亡先通知引用者的时序律 | §57.3 |
| 正反同源 | 机制的正例与反例只差一行 | §57.6 |


**术语表终补**（最后三行——三连章共用词的归位）：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| 副本制 | 每章自带全套源码的共享方式 | §57.0 |
| 改造率 | 新增行数/存量行数（模块健康度指标） | §57.2 |
| 断点是时间机器 | 时序敏感代码的首选调试工具 | §57.1 |

**术语表**：

| 术语 | 一句话定义 | 首见 |
|---|---|---|
| 上值 | 被捕获变量的运行期代理（两态对象） | §57.0 |
| 开放 | location 指值栈一格（变量还住帧里） | §57.2 |
| 关闭 | 值搬进 closed、location 改指自家 | §57.3 |
| 指针搬家 | 关闭动作的三行核心 | §57.3 |
| 捕获表 | FnCtx/ObjFn 的 upvals（isLocal+index） | §57.1 |
| 穿层传递 | isLocal 假条目：爷爷的盒子直递孙辈 | §57.1 |
| 邮路 | 中间函数捕获表里的过路条目 | §57.1 |
| 开放表 | VM 的开放上值集合（按栈址降序） | §57.2 |
| 先关后拆 | Return 的第 0 步 | §57.3 |
| 各捕各的 | 块级变量每圈新槽新盒（0 1 2） | §57.4 |


**自查补遗三问**：①adder 三表的第二行是谁添的？（递归途经
fun(y) 时给 fun(y) 添的 {真,1}——邮路当场建设。）；②P3 若把
立即调用改成存进三个变量圈后调用，输出与盒子数变吗？（不变
——关闭在圈内已发生，延后读盒不变内容。）；③Lt 坑的防复发
default: throw 为什么加在编译器而不加在 VM？（错在发码——
运行时看到的已是"合法"字节码，防御必须住在上游。）


**终章自查的运行方式建议**（不同于前章的问答）：本章自查
最好**结对进行**——一人持 13 章一份持本章，互相给对方讲
"闭包怎么工作"（各按自己章的机制），讲到对方点头为止——
**能讲赢另一实现的持有者，才是真懂了自己的实现**（跨实现
互讲是理解的最严考试，费曼技巧的对抗版）。

**自查清单**：

1. 逃逸闭包读局部变量的三条付费方案各是什么粒度？
2. 捕获表条目的两字段各指什么？isLocal 假时 index 是谁的索引？
3. resolveUpvalue 递归在哪两种情况下终止？
4. 中间函数不用 x，为什么捕获表里还有 x？（邮路。）
5. 开放上值与关闭上值的 location 各指向哪？GET_UPVALUE 读哪个？
6. captureUpvalue 查表的判定条件是什么？为什么按地址不按名字？
7. 关闭的两个触发点各由谁负责发信号？次序为什么生死攸关？
8. P3 为什么每圈一个盒？JS 的 var 版会输出什么？
9. P1 的 2 对 7 差在哪？上值对无关变量收钱吗？
10. Lt 坑的双联症是什么？根治法是什么？（switch 静默 default。）


**练习的三个梯度**（做题前先看）：题 1/5 是语料级（写程序、
贴对照）；题 2/4/6/7 是机制级（改实现、数盒子、防坑）；题 3/8
是设计级（极端语料、跨章汇合）。建议顺序 5→1→4→2→7→3→6→8
（从对账到机制到设计——与读法建议的三个读者层对应）。做完
题 6 的读者注意把 default: throw 的 diff 保留——那是你下一个
编译器项目的第一行防御。


**练习 8-11 补编**（原七题外的四题）：

8. ★★ 56 章汇合：把 57 副本的 Value 换成 56 章装箱版（ObjUpvalue
   指向装箱格 uint64_t）——15 项断言全绿即两章正交性的实证。
9. ★★ 给 55 章补"比较集契约表"（六运算符↔六指令↔六 case 的
   三列对照）当防复发——Lt 坑的制度化堵漏。
10. ★★ 三计数器实测：CLOSURE/GET_UPVALUE/闭包 Call 计数，
    P1 读数 2/3/3、P2 读数 2/3/3（结构不同账相同——好一题）。
11. ★★★ 第三语言重写：用 Rust 写开放表与关闭（ownership 恰
    好表达"盒子的唯一家"）——写出来说明理解已脱离 C++ 载体。


**练习 14–15 补编**（终版两题）：

12. ★（一小时项目）把 P1/P2/P3/P4 四段语料合并成一个"上值
    演示程序"（一个 main 顺序演示四种行为），断言扩到 20 项
    ——练语料整合（合并时注意变量名冲突与输出序）。
13. ★（收尾仪式）给自己写一份"上值 15 分钟"讲稿（听众：学过
    13 章没学过本章的同学），配 57.0.8 那张四行三态表当板书
    ——能讲清 = 能毕业（费曼检验的正式版）。

**练习**：

1. ★ 给语言加 `let`/`var` 双关键字（块级/函数级），P3 的两个版本
   都能写——各捕各的与共享的 0 1 2 / 2 2 2 各出一条断言。
2. ★★ 给 VM 加"上值读计数"（GetUpvalue 次数统计），P2 里 x 的
   读取要过几层间接？（一层——盒子直递，间接层数是 1 不是 3，
   这是上值对环境链的另一个胜项。）
3. ★★★ 实现"上值_of 上值"的极端语料：五层嵌套捕获最外层变量，
   断言盒子数仍为 1、中间四层的捕获表各有一行邮路。
4. ★★ 把第 15 章的环境账（7 节点）在本章 VM 里模拟：给 counter
   的无关变量加到五个，盒子数还是 2 吗？（是——上值对无关变量
   零收费的最强版证词。）
5. ★（对照）把 P1 的字节码反汇编贴在第 15 章 P1 逐帧表旁边——
   两种实现每一步的"变量访问动作"各是什么？（查链 vs 间接寻址。）
6. ★★（错题本）给 binaryFn 的 switch 加 `default: throw`（未匹配
   token 即编译错误），重跑 55/57 全部语料——哪些 OTHER 突然
   报错？（该没有——但这个防御位让 Lt 类坑从潜伏变即爆。）
7. ★★（审计）CLOSE_UPVALUE 的 VM 实现为什么是"≥ 界线批量"而
   不是"恰好一格"？构造双捕获块语料证明批量性。

---

（第 60 章完——第十篇三连章落幕：栈机、编译器、上值三件套齐了。
匠书线的新章至此全部落成，剩余两批是补章与收官。）


### 60.6.4　本章断言与原书练习的对照

原书 §25 的练习有四道经典（补捕获上限检查、实现 composite
闭包、读 Lua 论文、给 GC 铺路），本章的七道练习与其错位互补：
原书练实现细节（上限/组合），本章练对账与审计（盒子账、代际、
双捕获序、错题本 default）。**教程练习系的取向一贯：对账优先
于功能**——因为功能有原书当参考答案，而对账网是教程自己的
资产。读者两头做，正好把"会实现"与"会验证"都拿到手。


**给读者的最后一道开卷题**（不答自阅）：把本章 P1 的字节码
（用第五组 walk 的方式全量打印）逐条标注"这条指令属于 54/55/57
哪章的机制"——预期比例约 6:3:1（54 的栈机指令占大头、55 的
编译形状居中、57 的上值指令最少但全在关键位）。标完这张双色
（或三色）反汇编，第十篇三章在一条 20 行字节码里的**沉淀比**
就一目了然——新机制不是均匀铺开的，是在老机制的关节处
（创建、调用、返回）下钩子。


### 60.7.3　本章时间线（合卷的开发史）

开发序如实记：底座复制（55 九件）→ chunk 增量（枚举三指令 +
UpvalDesc/两对象）→ scanner 加 fun → compiler 重构 FnCtx 链
（一次成型）→ vm 五块 → P1 一次过（机制正确）→ **P3 翻车**
（Lt 坑——55 章潜伏债）→ 补 Lt 四处 → **P4 翻车**（return
位置——语料笔误）→ 改语料 → 第五节静默失败（反汇编没下钻）
→ walk 递归 → 全绿。**四个真坑按"债的年龄"排序**：两章前
的（Lt）、一章前的（无）、当章的（return、下钻）——**越晚翻
车的坑越便宜**（Lt 若在 55 章爆，要在 16 项断言里找；在 57
爆，P3 一个语料就定位）——**让坑早爆**是断言网的建设方向，
也是"语料覆盖比较集全"这类小勤快的复利。


### 60.7.4　致匠书（线终注）

匠书两部解释器的教学设计在本轮扩充里被"压进"了教程的六个
新章——jlox 的语义线进了 9/13、clox 的工程线进了 54/55/56/57。
压进的方式不是翻译而是**嫁接**：Pratt 表接在第 6 章分层法上、
环境链接在 12 章绑定表上、上值接在 13 章闭包语义上——每个
匠书机制都长在教程已有的枝上而不是另起一棵树。这个方式
恰好复刻了匠书自己的精神（两解释器共享一门 Lox），也算以
书之道还施彼身。线终注一句话：**Robert Nystrom 写了一本
"怎么造"的书，教程把它读成了一章"为什么这样造"的证据链**
——两种读法都合法，后者的产出是对账网。


### 60.7.5　常见误区两则

**误区一："上值是为了性能"**——上值不是为了快，是为了**省**
（无关变量不拖走）与**对**（逃逸语义的正确实现）；它的访问比
环境链快是副产品。若只求快，整帧不回收（CPython 式）在无逃逸
负载下反而最快（零搬家零盒子）。**上值是"逃逸语义 + 内存
经济"的平衡解**，单说性能会把设计动机读歪。

**误区二："闭包=匿名函数"**——闭包是**值**（身体+捕获），
匿名函数只是**语法**（无名字的表达式）。有名字的函数也可以
是闭包（本章 counter 返回的有名变量 inc1 持有的就是闭包值）；
匿名函数若不捕获任何变量甚至不是闭包（捕获表空——54 章的
"函数与闭包不分家"精确表述：闭包是函数值的运行时完备形态，
捕获空集是特例）。**把值与语法分开**——这个区分在第 15 章
（FunLit vs Closure）已立、此处终结。


### 60.7.6　家规汇总预告（本章用到过的）

本教程行文家规在本章出现过的实例清单（收官章总汇的样张）：
名词化诊断（Lt 复盘的消息设计）、先预测后对账（四路会师的
读者姿势）、正反同源（P3/P4 语料）、结构账入断言（盒子 2）、
表示跟着内容走（§57.4.5 的图选）、单一事实源（捕获表三方）、
防御住上游层（default: throw 在编译器）——**七条家规、每条
本章至少一次实例**。家规不是规则清单而是写作时的反射——
它们是前五轮扩充中反复被验证的表达纪律，本章自觉全部执行。


### 60.7.7　下一章预告（20 章补）

匠书轮还剩两批：**20 章补三色与弱引用**（GC 章加匠书 §26 的
三色抽象、弱引用字符串池、LISP2 压紧、分代注记——本章 FAQ
"GC 时代上值盒怎么办"的正面回答在那批）与 **52 章补方法即
闭包**（对象章加 bound method、this 捕获、super 链——匠书
§31–32 的 OO 闭包观）。两批都是"补进已有章"的增量模式
（不新建章）——与本章的"新章收官"模式相衔接，收官批（49）
再总装。**读者此刻的装备已足以读懂那两批的全部正文**——
三色不变式（31 章数据流的前身）、bound method（本章闭包的
this 特例）都是已学机制的变奏。


### 60.7.8　本章之最（三个"最"收束）

**最难的点**：resolveUpvalue 的途经登记（一次查找两张表各添
一行——递归的副作用容易漏看）；**最美的点**：指针搬家（两行
代码消化地址迁移，GET/SET 零改动——间接层的设计之美）；**最
贵的点**：P3 的代际（每代一盒——隔离的内存价格）。三最各配
一个断言（P2 穿层、P4 共享、P3 盒数）——**每"最"都锁死在
机器证人手里**，这就是本教程对"理解"的操作定义：能被断言
复述的知识才算教过。


### 60.7.9　结语前的三行感谢式总结（给三个来源）

**给匠书**：§25 的设计（两态上值+捕获表）被证明可以在教学
VM 上 120 行复刻——设计的优雅经得起缩放检验；**给第 15 章**：
环境链版先行为上值版立了语义证人——先学慢的再学快的，理解
顺序与实现顺序相反（教学的最优路径）；**给断言网**：15 项
里 5 项结构断言（盒子/开放表/反汇编）——**没有它们，P3 的
0 1 2 只能证明"这个实现恰好对"，有了它们才证明"机制按设计
工作"**。三个来源各领一句——教程的每一章都是这样三方合著
的（书给设计、前章给语义、断言给证明）。


### 60.7.10　最后的实验（动手收卷）

合卷实验三连（半小时内可完成）：①把 P1 的 counter 内加五个
无关变量（var a,b,c,d,e 不用）——盒子数仍 2（无关零收费的
亲手证）；②把 P1 输出语句换成三连 inc1(1)（共五次调用）——
盒子仍 2、输出 1 2 3 4 5（盒数与调用次数无关）；③删掉 P1
的第二次 counter() 调用——盒子 1（代数=调用数）。三个实验
各改一行、各验一条规律——**改一行验一条**是实验设计的最
小主义，也是本教程语料设计的元方法。


### 60.7.11　（终）一章读法的四速档

**30 分钟档**：两分钟速览 + §57.3 时序图 + P3 + 小结三句话——
知道闭包怎么活。**2 小时档**：加读 §57.1/57.2 全部 + FAQ——
知道机制每一步。**半天档**：再加两走读（编译器六处、VM 五块）
+ 15 项断言逐项手推——能改能修。**一天档**：全部 + 练习
1/2/4/6/7 + 错题本三差点复现——能造自己的。四档对应四种
读者身份（路过者/学习者/维护者/建造者）——**教程为四种人
都留了门**（速览给路过、正文给学习、走读给维护、练习给建造）
——这个四门结构是六新章（9/13/54/55/56/57）的共同户型。


### 60.7.12　（终终）交卷行

本章向教程交卷：机制（上值 120 行）、证人（15 断言含 5 结构）、
语料（counter/adder 四路会师）、坑档（两实三差点）、四速档
读法、四张速查卡之末卡——六样交付物清点完毕，第 60 章、
第十篇、匠书轮六新章，三重合卷。**下一站：20 章补三色与弱
引用（GC 章的匠书增量）。**


### 60.7.13　写在本章最后的参考文献路由

想继续深挖的读者三条路：**实现路线**——Lua 5.0 论文
（Ierusalimschy 等，The Implementation of Lua 5.0，upvalue
的原始文献）与 clox 源码（craftinginterpreters.com 仓库，
§25 对应 chunk.h/vm.c）；**对照路线**——V8 的 context 说明
（v8.dev 博客的 pointer compression 系列含上下文设计）与
CPython 的 ceval.c（帧即环境的活体）；**理论路线**——
Clinger 的 Rabbit 论文（赋值转换的学术源头）与 Will Clinger
编辑的 Scheme 实现综述。三条路各一条主文献——**读完本章再
读它们是"验证学习"（你已有预判力），跳过本章直接读是"被动
学习"**——顺序的差是收获的差。


**（补）三方合著的署名格式**：本章每节的知识来源可用三元组
标注——(匠书 §x.y, 教程第 n 章先例, 本章断言 k)——例如
§57.3 的先关后拆 = (§25.4, 54 章 Return 六步, P1 断言 4)。
三元组是"知识出处"的完整坐标（书/前章/证人）——**教程的
每一句机制描述都有三元组**（有的显式标注、有的隐含在节注）
——这是"自包含蒸馏"的操作定义：不翻原书 ≠ 不注明出处，
而是出处与证明都在本地。

### 60.7.1　遗产与伏笔清账

**给收官章的账**（66 章 survey 的素材行）：上值——"开放指栈、
关闭进盒、指针搬家消化地址变更；编译期捕获表 isLocal 二相、
运行期开放表查重共享；P1 盒子 2 对 13 章节点 7 的粒度实测"。
四路会师（13/54/55/57 同源语料全等）作为匠书线的收官证词。

**伏笔回收表**（本章兑现的前章伏笔，对照 55 章伏笔索引）：
第 57 章 CloseUpvalue 冻结占位（本章启用）；55 章第 3 行（占位
回填→捕获表编码——CLOSURE 的两段式恰是同构）；55 章第 6 行
（endScope 的 POP 爆破点——先关后弹）；55 章第 4 行（槽位→
上值索引二相）；13 章伏笔 1/2（环境账对照、闭包定义对读）。
**五条伏笔全部兑现、无一悬空**——教程伏笔管理的完账证明。

**三句话带走**：**上值两态开放关闭，搬家只改指针不改代码；
捕获表 isLocal 二相，穿层传递共享一盒；关闭在块尾与返回两处，
先关后拆是时序铁律**。三句话连同四方对照表，是本章留给读者
的全部随身行李——下一个闭包实现（无论读 V8 还是写自己的）
都能对号入座。

### 60.7.2　读法与自查补遗

**读法**：赶时间者读两分钟速览 + §57.3 时序图 + §57.4 P3——
八分钟拿到模型；实现者必读 §57.1.1（编译器六处 diff）与
§57.2.1（VM 五块走读）——两节就是"改造第 58 章副本"的施工图；
从匠书来的读者按 §57.6.3 映射对号，重点读差异两处（自由表
下沉、去重显式）与 Lt 坑复盘（原书没有的增量教学资产）。

**补两道产出型自查**（合卷题）：①默写 adder 三函数的捕获表
（三行两列，不看正文）；②画出 counter 全程的"栈格↔盒子"时间
线（八事件轴：两次 counter、三次 inc、两次关闭、一次终态）——
两题都过者，上值已在你手里，而不只是在书里。

**（第 60 章正式合卷。第十篇三连章全部落成；匠书轮六新章
全部落成。剩余：两补章批（20 三色弱引用、52 方法即闭包）与
收官批 66——三批后，五轮扩充的全部 66 章全绿交付。）**

**（合卷附言）**：三连章至此在文字、代码、断言、坑档、速查卡五个
层面全部合卷——下一个数字是 20（三色与弱引用，GC 章的匠书增量），
然后是 52 与 66。匠书轮的六新章已在本行之前全部落定。

**（最后一行的最后一行）**：如果你只从本章带走一件东西，带走
那张四行三态表（§57.0.8）——它装得下本章，也装得下你将来
遇到的每一个"家会搬、门牌不变"的系统。
