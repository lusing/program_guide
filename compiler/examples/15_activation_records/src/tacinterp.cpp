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
