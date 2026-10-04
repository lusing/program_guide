#include "sign.hpp"

#include <array>

namespace tip {

Lattice<int> signLatticeDomain() {
    SignLattice s;
    return Lattice<int>{
        STOP, SBOT,
        [](int a, int b) { return a == b; },
        [=](int a, int b) { return s.leq(a, b); },
        [=](int a, int b) { return s.join(a, b); }};
}

std::string signShow(int s) {
    switch (s) {
        case SBOT: return "⊥";
        case SMINUS: return "−";
        case SZERO: return "0";
        case SPLUS: return "+";
        case STOP: return "⊤";
    }
    return "?";
}

bool SignLattice::leq(int a, int b) const {
    if (a == SBOT || b == STOP) return true;   // 底最小、顶最大
    if (b == SBOT || a == STOP) return a == b; // 越过底/顶的唯一可能是相等
    return a == b;                             // −、0、+ 三者互不可比
}

int SignLattice::join(int a, int b) const {
    if (a == b) return a;
    if (a == SBOT) return b;                   // ⊥ ⊔ x = x
    if (b == SBOT) return a;
    return STOP;                               // 其余组合（含 −/0/+ 两两）= ⊤
}

namespace {

// 加法符号表（行=左操作数 [−,0,+,⊤]，列=右操作数）。
constexpr std::array<std::array<int, 4>, 4> ADD_TABLE = {{
    //  −      0      +      ⊤
    {{SMINUS, SMINUS, STOP,  STOP }},  // −
    {{SMINUS, SZERO,  SPLUS, STOP }},  // 0
    {{STOP,   SPLUS,  SPLUS, STOP }},  // +
    {{STOP,   STOP,   STOP,  STOP }},  // ⊤
}};

// 乘法符号表：同号得 +，异号得 −，任何一边是 0 得 0。
constexpr std::array<std::array<int, 4>, 4> MUL_TABLE = {{
    //  −      0      +      ⊤
    {{SPLUS,  SZERO,  SMINUS, STOP }},  // −
    {{SZERO,  SZERO,  SZERO,  SZERO}},  // 0
    {{SMINUS, SZERO,  SPLUS,  STOP }},  // +
    {{STOP,   SZERO,  STOP,   STOP }},  // ⊤
}};

int idx(int s) { return s + 1; }  // −(-1)→0, 0→1, +(1)→2, ⊤(2)→3

}  // namespace

int sAdd(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    return ADD_TABLE[idx(a)][idx(b)];
}

int sSub(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    // a − b = a + (−b)：−、+ 互换，0/⊤ 不变。
    const int negB = b == SMINUS ? SPLUS : b == SPLUS ? SMINUS : b;
    return ADD_TABLE[idx(a)][idx(negB)];
}

int sMul(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    return MUL_TABLE[idx(a)][idx(b)];
}

int sDiv(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    if (b == SZERO) return SBOT;  // 除以确定的 0：该路径具体不可行（抛错中止）
    // 排除"除数可能为 0"的情形后，商的符号规律与乘法相同。
    if (b == STOP) {
        // 除数 ∈ {−,0,+}：0 排除，剩下 {−,+}；结果符号对 −/+ 分别讨论后取 join。
        return sAdd(sMul(a, SMINUS), sMul(a, SPLUS));
    }
    return MUL_TABLE[idx(a)][idx(b)];
}

int sCompare(int a, int b) {
    if (a == SBOT || b == SBOT) return SBOT;
    return STOP;  // 比较结果只可能是 0 或 1：{0,+} 在本格中即 ⊤
}

}  // namespace tip
