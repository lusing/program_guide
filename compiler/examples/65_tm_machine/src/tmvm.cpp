// file: src/tmvm.cpp
#include "tmvm.hpp"

#include <array>
#include <sstream>
#include <stdexcept>

namespace tmach {

TmResult tmRun(const std::vector<TmIns> &ins, const std::vector<long long> &input,
               std::ostream *trace, long long maxSteps) {
    if (ins.size() > IADDR_SPACE) throw std::runtime_error("程序超出指令存储");
    std::array<long long, 8> reg{};
    std::array<long long, DADDR_SPACE> dmem{};
    dmem[0] = DADDR_SPACE - 1;   // 书 §8.7.1 的启动约定：可用内存量写在 dMem[0]
    reg[7] = 0;
    size_t inPos = 0;
    TmResult res;

    auto dmemAt = [&](int a) -> long long & {
        if (a < 0 || a >= DADDR_SPACE) {
            res.err = TmResult::Err::DMemErr;
            res.pc = static_cast<int>(reg[7]);
            throw std::runtime_error("DMEM_ERR");
        }
        return dmem[a];
    };
    auto rd = [&](int r) -> long long { return reg[r]; };

    try {
        for (;;) {
            if (++res.steps > maxSteps) {
                res.err = TmResult::Err::IMemErr;   // 步数保险丝计入同一错误通道
                res.pc = static_cast<int>(reg[7]);
                throw std::runtime_error("步数超限（疑似死循环）");
            }
            int pc = static_cast<int>(reg[7]);
            if (pc < 0 || pc >= static_cast<int>(ins.size())) {
                res.err = TmResult::Err::IMemErr;
                res.pc = pc;
                throw std::runtime_error("IMEM_ERR");
            }
            TmIns cur = ins[pc];
            reg[7] = pc + 1;   // 取指即自增——跳转指令随后覆盖它
            int a = 0;
            if (!TmIns::isRO(cur.op)) a = cur.d + static_cast<int>(rd(cur.s));
            switch (cur.op) {
            case TmIns::Op::HALT:
                if (trace) *trace << res.steps << " " << pc << " HALT\n";
                return res;
            case TmIns::Op::IN:
                reg[cur.r] = inPos < input.size() ? input[inPos++] : 0;
                break;
            case TmIns::Op::OUT:
                res.out.push_back(std::to_string(reg[cur.r]));
                break;
            case TmIns::Op::ADD: reg[cur.r] = rd(cur.s) + rd(cur.t); break;
            case TmIns::Op::SUB: reg[cur.r] = rd(cur.s) - rd(cur.t); break;
            case TmIns::Op::MUL: reg[cur.r] = rd(cur.s) * rd(cur.t); break;
            case TmIns::Op::DIV:
                if (rd(cur.t) == 0) {
                    res.err = TmResult::Err::ZeroDiv;
                    res.pc = pc;
                    throw std::runtime_error("ZERO_DIV");
                }
                reg[cur.r] = rd(cur.s) / rd(cur.t);
                break;
            case TmIns::Op::LD: reg[cur.r] = dmemAt(a); break;
            case TmIns::Op::LDA: reg[cur.r] = a; break;
            case TmIns::Op::LDC: reg[cur.r] = cur.d; break;
            case TmIns::Op::ST: dmemAt(a) = rd(cur.r); break;
            case TmIns::Op::JLT: if (rd(cur.r) < 0) reg[7] = a; break;
            case TmIns::Op::JLE: if (rd(cur.r) <= 0) reg[7] = a; break;
            case TmIns::Op::JGE: if (rd(cur.r) >= 0) reg[7] = a; break;
            case TmIns::Op::JGT: if (rd(cur.r) > 0) reg[7] = a; break;
            case TmIns::Op::JEQ: if (rd(cur.r) == 0) reg[7] = a; break;
            case TmIns::Op::JNE: if (rd(cur.r) != 0) reg[7] = a; break;
            }
            if (trace) {
                std::ostringstream os;
                os << res.steps << " " << pc << " " << disasm(cur);
                for (int r = 0; r < 7; ++r) os << " " << reg[r];
                *trace << os.str() << "\n";
            }
        }
    } catch (const std::runtime_error &) {
        return res;   // 错误码已写进 res
    }
}

}  // namespace tmach
