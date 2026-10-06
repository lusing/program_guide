// file: src/tmvm.hpp
// TM 模拟器（L 书 §8.7 的取指-执行循环 + 三错误码 + trace）。
#ifndef TIP_TMVM_HPP
#define TIP_TMVM_HPP

#include <iosfwd>
#include <string>
#include <vector>

#include "tmasm.hpp"

namespace tmach {

constexpr int IADDR_SPACE = 1024;   // 指令存储大小
constexpr int DADDR_SPACE = 512;    // 数据存储大小

struct TmResult {
    enum class Err { None, IMemErr, DMemErr, ZeroDiv } err = Err::None;
    long long steps = 0;                 // 取指次数
    std::vector<std::string> out;        // OUT 的输出（一行一值）
    // 错误现场（正文讲解账用）
    int pc = -1;
};

// 取指-执行循环。boot 语义（书 §8.7.1）：寄存器清零、dMem[0]=DADDR_SPACE-1、PC=0。
// IN 从 input 队列取值（空则取 0——教学口径：真实模拟器读标准输入）。
// trace 非空时每步打一行：`step pc OP r0 r1 r2 r3 r4 r5 r6`（执行后现场）。
TmResult tmRun(const std::vector<TmIns> &ins, const std::vector<long long> &input,
               std::ostream *trace = nullptr, long long maxSteps = 200000);

}  // namespace tmach

#endif  // TIP_TMVM_HPP
