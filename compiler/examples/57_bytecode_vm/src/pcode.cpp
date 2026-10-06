// file: src/pcode.cpp
#include "pcode.hpp"

#include <stdexcept>

namespace pcode {

std::vector<Ins> exprCorpus() {
    // 书内原例的 P-码（§8.1.3 首例）：
    //   ldc 2 ; lod a ; mpi ; lod b ; ldc 3 ; sbi ; adi
    return {
        {"ldc", 2, ""},
        {"lod", 0, "a"},
        {"mpi"},
        {"lod", 0, "b"},
        {"ldc", 3, ""},
        {"sbi"},
        {"adi"},
    };
}

std::vector<Ins> assignCorpus() {
    // x := y + 1（书内赋值例）：lda x 压地址、算值、sro 存回。
    return {
        {"lda", 0, "x"},
        {"lod", 0, "y"},
        {"ldc", 1, ""},
        {"adi"},
        {"sro"},
    };
}

std::string show(const Ins &i) {
    std::string s = i.op;
    if (i.op == std::string("ldc")) s += " " + std::to_string(static_cast<int>(i.num));
    else if (i.sym && *i.sym) s += std::string(" ") + i.sym;
    return s;
}

double PMachine::run(const std::vector<Ins> &code) {
    stack_.clear();
    std::string pendingAddr;   // lda 压的"地址"（教学版：变量名）
    for (const Ins &i : code) {
        if (i.op == std::string("ldc")) {
            stack_.push_back(i.num);
        } else if (i.op == std::string("lod")) {
            auto it = vars_.find(i.sym);
            if (it == vars_.end()) throw std::runtime_error("undefined var: " + std::string(i.sym));
            stack_.push_back(it->second);
        } else if (i.op == std::string("lda")) {
            pendingAddr = i.sym;   // 地址入栈（教学版单槽——栈效应与真实版一致）
        } else if (i.op == std::string("sro")) {
            if (stack_.size() < 1 || pendingAddr.empty())
                throw std::runtime_error("sro: 栈下溢");
            vars_[pendingAddr] = stack_.back();
            stack_.pop_back();
            pendingAddr.clear();
        } else {
            // 弹二压一的算术族：adi/sbi/mpi/dvi
            if (stack_.size() < 2) throw std::runtime_error("算术: 栈下溢");
            double b = stack_.back();
            stack_.pop_back();
            double a = stack_.back();
            stack_.pop_back();
            if (i.op == std::string("adi")) stack_.push_back(a + b);
            else if (i.op == std::string("sbi")) stack_.push_back(a - b);
            else if (i.op == std::string("mpi")) stack_.push_back(a * b);
            else if (i.op == std::string("dvi")) stack_.push_back(a / b);
            else throw std::runtime_error("unknown op: " + std::string(i.op));
        }
    }
    // 表达式语料终态栈深 1（值留下）；赋值语料 sro 存回后终态栈深 0——两者都合法。
    if (stack_.size() > 1) throw std::runtime_error("结束时栈深应为 0 或 1");
    return stack_.empty() ? 0 : stack_.back();
}

}  // namespace pcode
