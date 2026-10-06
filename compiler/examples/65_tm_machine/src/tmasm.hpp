// file: src/tmasm.hpp
// TM 两遍汇编器（L 书 §8.7/附录 C 的 .tm 文本格式）。
#ifndef TIP_TMASM_HPP
#define TIP_TMASM_HPP

#include <string>
#include <vector>

namespace tmach {

// 一条 TM 指令：RO 用 (r,s,t)；RM 用 (r,d,s)。
struct TmIns {
    enum class Op {
        HALT, IN, OUT, ADD, SUB, MUL, DIV,           // RO：op r,s,t
        LD, LDA, LDC, ST, JLT, JLE, JGE, JGT, JEQ, JNE,   // RM：op r,d(s)
    };
    Op op = Op::HALT;
    int r = 0, d = 0, s = 0, t = 0;   // RO 用 (r,s,t)；RM 用 (r,d(s))

    static const char *name(Op o);
    static bool isRO(Op o) { return o <= Op::DIV; }
};

// .tm 文本格式（一章内自定义的干净版）：
//   ; 整行注释
//   label: OP r,d(s)        ; 行尾注释
//   OP r,s,t
// 第一遍收集标号地址；第二遍编码（标号只能出现在跳转的 d 位——`Jxx r,label(7)`）。
// 语法错抛 std::runtime_error（消息带行号）。
class Assembler {
public:
    std::vector<TmIns> assemble(const std::string &tmText);
};

// 反汇编一行（trace/正文展示用）。
std::string disasm(const TmIns &i);

}  // namespace tmach

#endif  // TIP_TMASM_HPP
