// file: src/main.cpp
// 第 65 章驱动（无参运行，走"简单程序"对账协议）：
//   S1 四语料 × 档 0 跑通（值对账）→ S2 四档指令数单调账 → S3 gcd 前 12 步 trace →
//   S4 手编 .tm 的三错误码 → S5 档 3 与档 0 输出全等（语义不变证人）。
#include "cgen.hpp"
#include "tmasm.hpp"
#include "tinyparse.hpp"
#include "tinyscan.hpp"
#include "tmvm.hpp"

#include <iostream>
#include <sstream>

namespace {

struct Corpus {
    const char *name;
    const char *src;
    std::vector<std::vector<long long>> inputs;   // 每组输入一次运行
};

const std::vector<Corpus> &corpora() {
    static const std::vector<Corpus> v = {
        {"fact",
         "read n; fact := 1;\n"
         "repeat fact := fact * n; n := n - 1 until n = 0;\n"
         "write fact",
         {{5}}},
        {"gcd",
         "read u; read v;\n"
         "repeat temp := v; v := u - u / v * v; u := temp until v = 0;\n"
         "write u",
         {{36, 24}, {1071, 462}}},
        {"branch",
         "read x;\n"
         "if x < 10 then y := x * 2 else y := x - 10 + 100 end;\n"
         "write y; write x + y",
         {{7}, {25}}},
        {"nest",
         "read a; read b;\n"
         "if a < b then m := a else m := b end;\n"
         "repeat d := d + 1 until d = m;\n"
         "write d * 2",
         {{3, 9}, {9, 4}}},
    };
    return v;
}

// 编译→汇编→运行 一条龙；返回 (指令数, TmResult)。
struct RunOut {
    size_t insns = 0;
    tmach::TmResult res;
};
RunOut runTier(const Corpus &c, tiny::Cgen::Tier tier, const std::vector<long long> &input) {
    tiny::Program p = tiny::parse(tiny::scan(c.src));
    tiny::Cgen g;
    std::string tm = g.gen(p, tier);
    tmach::Assembler as;
    std::vector<tmach::TmIns> ins = as.assemble(tm);
    RunOut r;
    r.insns = ins.size();
    r.res = tmach::tmRun(ins, input);
    return r;
}

std::string outs(const std::vector<std::string> &v) {
    std::string s;
    for (const auto &x : v) s += x + " ";
    return s.empty() ? s : s.substr(0, s.size() - 1);
}

}  // namespace

int main() {
    auto tierName = [](tiny::Cgen::Tier t) {
        switch (t) {
        case tiny::Cgen::Tier::None: return "None ";
        case tiny::Cgen::Tier::Temps: return "Temps";
        case tiny::Cgen::Tier::Vars: return "Vars ";
        case tiny::Cgen::Tier::Test: return "Test ";
        }
        return "?";
    };
    std::vector<tiny::Cgen::Tier> tiers = {
        tiny::Cgen::Tier::None, tiny::Cgen::Tier::Temps, tiny::Cgen::Tier::Vars,
        tiny::Cgen::Tier::Test};

    // ---------- S1 档 0 跑通 ----------
    std::cout << "== S1 tier-None runs ==\n";
    for (const auto &c : corpora()) {
        for (const auto &in : c.inputs) {
            RunOut r = runTier(c, tiny::Cgen::Tier::None, in);
            std::cout << "[" << c.name << " in=";
            for (long long x : in) std::cout << x << ",";
            std::cout << "\b] steps=" << r.res.steps << " out=" << outs(r.res.out) << "\n";
        }
    }

    // ---------- S2 四档指令数 ----------
    std::cout << "== S2 tier instruction counts ==\n";
    bool mono = true;
    for (const auto &c : corpora()) {
        std::cout << "[" << c.name << "]";
        size_t prev = SIZE_MAX;
        for (auto t : tiers) {
            tiny::Program p = tiny::parse(tiny::scan(c.src));
            tiny::Cgen g;
            std::string tm = g.gen(p, t);
            size_t n = static_cast<size_t>(g.emitted());
            size_t mem = 0;   // 内存指令 LD/ST（不含 LDA/LDC）——档 2 的收益指标
            for (size_t pos = 0; pos + 1 < tm.size(); ++pos) {
                if ((tm.compare(pos, 4, " LD ") == 0) || (tm.compare(pos, 4, " ST ") == 0)) ++mem;
            }
            std::cout << " " << tierName(t) << "=" << n << "/mem" << mem;
            if (n > prev) mono = false;
            prev = n;
        }
        std::cout << "\n";
    }
    std::cout << "[monotone] " << (mono ? 1 : 0) << "\n";

    // ---------- S3 trace：gcd 档 0 前 12 步 ----------
    std::cout << "== S3 trace gcd(None) first 12 steps ==\n";
    {
        tiny::Program p = tiny::parse(tiny::scan(corpora()[1].src));
        tiny::Cgen g;
        std::string tm = g.gen(p, tiny::Cgen::Tier::None);
        tmach::Assembler as;
        auto ins = as.assemble(tm);
        std::ostringstream tr;
        tmach::tmRun(ins, {36, 24}, &tr);
        std::istringstream lines(tr.str());
        std::string l;
        for (int k = 0; k < 12 && std::getline(lines, l); ++k) std::cout << "    " << l << "\n";
    }

    // ---------- S4 手编 .tm 的三错误码 ----------
    std::cout << "== S4 hand .tm error codes ==\n";
    {
        tmach::Assembler as;
        struct H {
            const char *name, *src;
        };
        for (const H &h : std::vector<H>{
                 {"dmemerr", "LDC 0,5(0)\nST 0,600(0)\nHALT 0,0,0\n"},
                 {"zerodiv", "LDC 0,1(0)\nLDC 1,0(0)\nDIV 0,0,1\nHALT 0,0,0\n"},
                 {"imemerr", "LDA 7,50(7)\nHALT 0,0,0\n"},
             }) {
            auto ins = as.assemble(h.src);
            auto r = tmach::tmRun(ins, {});
            const char *err = r.err == tmach::TmResult::Err::DMemErr ? "DMEM_ERR"
                            : r.err == tmach::TmResult::Err::ZeroDiv ? "ZERO_DIV"
                            : r.err == tmach::TmResult::Err::IMemErr ? "IMEM_ERR"
                                                                      : "None";
            std::cout << "[" << h.name << "] err=" << err << " steps=" << r.steps
                      << " pc=" << r.pc << "\n";
        }
    }

    // ---------- S5 档 3 与档 0 输出全等 ----------
    std::cout << "== S5 tier-Test == tier-None outputs ==\n";
    int runs = 0, equal = 0;
    for (const auto &c : corpora()) {
        for (const auto &in : c.inputs) {
            RunOut r0 = runTier(c, tiny::Cgen::Tier::None, in);
            RunOut r3 = runTier(c, tiny::Cgen::Tier::Test, in);
            ++runs;
            bool ok = (r0.res.out == r3.res.out && !r0.res.out.empty());
            equal += ok ? 1 : 0;
            if (!ok)
                std::cout << "  MISMATCH " << c.name << " none=" << outs(r0.res.out)
                          << " test=" << outs(r3.res.out) << "\n";
        }
    }
    std::cout << "[equal] " << equal << "/" << runs << "\n";

    // ---------- S6 驻留变量报告（档 2 的侧通道） ----------
    std::cout << "== S6 resident vars (tier Vars) ==\n";
    for (const auto &c : corpora()) {
        tiny::Program p = tiny::parse(tiny::scan(c.src));
        tiny::Cgen g;
        g.gen(p, tiny::Cgen::Tier::Vars);
        std::cout << "[" << c.name << "]";
        for (const auto &vr : g.residentVars())
            std::cout << " " << vr.first << "->r" << vr.second;
        std::cout << (g.residentVars().empty() ? " (none)" : "") << "\n";
    }
    return 0;
}
