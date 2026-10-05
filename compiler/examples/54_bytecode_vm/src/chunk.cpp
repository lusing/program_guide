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
