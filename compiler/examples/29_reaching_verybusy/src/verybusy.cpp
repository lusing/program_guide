// file: src/verybusy.cpp
// 第 29 章配套：非常忙表达式实现。
#include "verybusy.hpp"

#include <sstream>

namespace tip {

std::string exprKey(const Quad &q) {
    const char *op = nullptr;
    switch (q.op) {
    case TOp::Add: op = " + "; break;
    case TOp::Sub: op = " - "; break;
    case TOp::Mul: op = " * "; break;
    case TOp::Div: op = " / "; break;
    case TOp::Gt:  op = " > "; break;
    case TOp::Eq:  op = " == "; break;
    default: return "";
    }
    std::ostringstream os;
    os << q.a << op << q.b;
    return os.str();
}

namespace {
// 表达式键以空格分界操作数（“a + b”），整词判定才不误伤（t1 不得匹配 t12）。
bool sharesOperand(const std::string &key, const std::string &var) {
    if (key.rfind(var + " ", 0) == 0) return true;             // 左操作数
    size_t sp = key.rfind(" " + var);
    if (sp != std::string::npos &&
        sp + 1 + var.size() == key.size()) return true;        // 右操作数
    return key.find(" " + var + " ") != std::string::npos;     // 中缀位置（不出现，保险）
}
}  // namespace

VeryBusyInfo veryBusy(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    VeryBusyInfo vb;
    vb.in.assign(n, {});
    vb.out.assign(n, {});
    // 块内逐条传递（后向）：e_gen = 本块先被使用、后才被杀的表达式；
    // e_kill = 操作数被重定义所杀掉的表达式。
    auto transfer = [&](size_t b, std::set<std::string> s) {
        for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
            const Quad &q = code[i];
            // 先杀：本条重定义 dst → 含 dst（作为整操作数）的表达式出局
            if (!q.dst.empty()) {
                for (auto it = s.begin(); it != s.end();) {
                    if (sharesOperand(*it, q.dst)) it = s.erase(it);
                    else ++it;
                }
            }
            // 再生：本条若是表达式，键入集
            std::string k = exprKey(q);
            if (!k.empty()) s.insert(k);
        }
        return s;
    };
    // 后向 must：out[B] = ∩ in[S]，S 取遍 B 的后继块（begin == B 的 succ 下标）；
    // 无后继（出口块）约定 out = ∅——出口之后没有计算，没有“非常忙”可言。
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = n; b-- > 0;) {
            std::set<std::string> out;
            bool first = true;
            for (int s : blocks[b].succs) {
                size_t c = 0;
                for (size_t k = 0; k < n; ++k)
                    if (blocks[k].begin == s) { c = k; break; }
                if (first) { out = vb.in[c]; first = false; }
                else {
                    std::set<std::string> keep;
                    for (const auto &e : out)
                        if (vb.in[c].count(e)) keep.insert(e);
                    out = keep;
                }
            }
            std::set<std::string> in = transfer(b, out);
            if (in != vb.in[b] || out != vb.out[b]) {
                vb.in[b] = in;
                vb.out[b] = out;
                changed = true;
            }
        }
    }
    return vb;
}

}  // namespace tip
