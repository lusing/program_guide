// file: src/ll1.hpp
// 第 6 章配套：FIRST/FOLLOW 的不动点计算、LL(1) 表构造与冲突检测。
#ifndef TIP_LL1_HPP
#define TIP_LL1_HPP

#include "llgrammar.hpp"

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

inline const std::string EPS = "ε";   // FIRST 集里的空串标记
inline const std::string DOLLAR = "$";

struct LL1 {
    const LLGrammar &g;
    std::map<std::string, std::set<std::string>> first;    // 非终结符 → FIRST
    std::map<std::string, std::set<std::string>> follow;   // 非终结符 → FOLLOW
    // (非终结符, 终结符或$) → 产生式下标（0 起）。多定义时保留胜者并记入 conflicts。
    std::map<std::pair<std::string, std::string>, int> table;
    // 冲突清单：(格子, 候选产生式下标们, 胜者)
    struct Conflict {
        std::string A, a;
        std::vector<int> candidates;
        int winner;
    };
    std::vector<Conflict> conflicts;

    explicit LL1(const LLGrammar &g);

    // FIRST(序列)：逐项吸收，遇 ε 项继续，全 ε 则含 ε。
    std::set<std::string> firstOf(const std::vector<std::string> &beta) const;

    void computeFirst();    // 规则迭代到不动点（工作表思想的又一现身）
    void computeFollow();
    void buildTable(bool resolveClosestElse);
};

// 表驱动预测分析器（绿龙 Fig 5.23 的程序化）。
// 副本改动：ParseResult → LLParseResult（避开 08 章副本的同名结构）。
struct LLParseResult {
    bool ok = false;
    std::vector<int> usedProds;      // 最左推导所用的产生式序列
    std::string error;               // 失败时的诊断（供 expected/errors 对账）
    size_t consumed = 0;             // 失败时已消耗的 token 数
};

LLParseResult predict(const LL1 &ll, const std::vector<std::string> &input);

}  // namespace tip

#endif  // TIP_LL1_HPP
