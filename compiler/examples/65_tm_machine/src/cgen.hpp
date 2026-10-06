// file: src/cgen.hpp
// TINY → TM 代码生成器（L 书 §8.8 的 cGen/genStmt/genExp + §8.10 四档优化）。
#ifndef TIP_CGEN_HPP
#define TIP_CGEN_HPP

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "tiny.hpp"

namespace tiny {

class Cgen {
public:
    // 档位累进：None ⊂ Temps ⊂ Vars ⊂ Test（8.10.1 → 8.10.2 → 8.10.3 逐档叠加）。
    enum class Tier { None, Temps, Vars, Test };

    // 产 .tm 文本（经 tmasm 汇编后上 tmvm 跑——文本即接口）。
    std::string gen(const Program &p, Tier tier);

    // 侧通道（指令数账、变量驻留表——正文对账用）
    long long emitted() const { return static_cast<long long>(code_.size()); }
    const std::vector<std::pair<std::string, int>> &residentVars() const { return resident_; }

private:
    std::vector<std::string> code_;
    struct VarInfo {
        int memLoc = -1;
        long long weight = 0;
        int reg = -1;   // -1 = inMem
    };
    std::map<std::string, VarInfo> vars_;
    std::vector<std::pair<std::string, int>> resident_;
    int tmpOffset_ = 0;    // 压负弹正（内存临时栈）
    int tmpDepth_ = 0;     // 当前表达式临时深度（寄存器临时分配）
    bool optTemps_ = false, optVars_ = false, optTest_ = false;
    Tok lastRelop_ = Tok::Lt;   // tier3 直转的条件记忆

    // 发码与回填
    void emitRO(const char *op, int r, int s, int t, const std::string &cmt);
    void emitRM(const char *op, int r, int d, int s, const std::string &cmt);
    void emitRMAbs(const char *op, int r, int addr, const std::string &cmt);
    int emitSkip();
    void backpatch(int at, const std::string &line);

    // 寄存器约定：AC=0 AC1=1 临时=2..4 MP=5 GP=6 PC=7
    static constexpr int AC = 0, AC1 = 1, MP = 5, GP = 6, PC = 7;

    VarInfo &var(const std::string &name);
    void countWeights(const Program &p);
    void assignResidentRegs();

    void genStmt(const Stmt &s);
    void genSeq(const std::vector<std::unique_ptr<Stmt>> &ss);
    void genExp(const Exp &e);
    void genLeafInto(const Exp &e, int r, const char *why);
    void saveTemp(const char *why);
    void loadTemp(const char *why);
    int tempRegFor(int depth) const;
    void emitCond(const Exp &cond);          // 条件计算（含布尔化/直转分档）
    void emitJumpIfFalse(int addr, const std::string &why);
    void emitJumpIfTrue(int addr, const std::string &why);
};

}  // namespace tiny

#endif  // TIP_CGEN_HPP
