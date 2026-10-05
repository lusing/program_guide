// file: src/vm.cpp
// 第 21 章配套：栈机器实现。
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
