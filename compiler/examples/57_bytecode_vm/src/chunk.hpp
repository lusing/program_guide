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
