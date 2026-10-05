// file: src/lr1.hpp
// 第 8 章配套：规范 LR(1) 造表与 LALR 同心合并（鲸书 §3.4.2 + §3.6.2）。
#ifndef TIP_LR1_HPP
#define TIP_LR1_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 文法 ----------
// 产生式 0 恒为增广开始产生式 S'→S；rhs 空串表示 ε。
struct Grammar {
    std::vector<std::pair<std::string, std::vector<std::string>>> prods;
    std::set<std::string> terms;     // 终结符（含 "$"）
    std::set<std::string> nonterms;  // 非终结符
    std::string start = "S'";
};

// FIRST(符号串)。终结符出现即止；非终结符含 ε 则继续看下一个。
std::set<std::string> firstOfSeq(const Grammar &g, const std::vector<std::string> &seq,
                                 const std::string &tail = "");

// FOLLOW 集（SLR 的归约许可证，鲸书 §3.4.2 之 SLR 视角）
std::map<std::string, std::set<std::string>> followSets(const Grammar &g);

// ---------- LR 项 ----------
struct Item {
    int prod = 0;         // 产生式编号
    int dot = 0;          // 圆点位置 0..|rhs|
    std::string la;       // lookahead；空串 = LR(0)/SLR 口径
    friend bool operator<(const Item &a, const Item &b) {
        if (a.prod != b.prod) return a.prod < b.prod;
        if (a.dot != b.dot) return a.dot < b.dot;
        return a.la < b.la;
    }
    friend bool operator==(const Item &a, const Item &b) {
        return a.prod == b.prod && a.dot == b.dot && a.la == b.la;
    }
};

// 项的核心（去掉 lookahead）——同心合并的"心"
using Core = std::set<std::pair<int, int>>;

// ---------- 表 ----------
struct Action {
    enum Kind { Err, Shift, Reduce, Acc } kind = Err;
    int target = -1;   // Shift: 目标状态；Reduce: 产生式号
    friend bool operator==(const Action &x, const Action &y) {
        return x.kind == y.kind && x.target == y.target;
    }
};

struct Table {
    std::string kind;                                   // "SLR(1)" / "LR(1)" / "LALR(1)"
    std::vector<std::set<Item>> states;                 // 规范族（SLR/LALR 为合并后状态）
    std::map<int, std::map<std::string, Action>> action; // 状态 -> 终结符 -> 动作
    std::map<int, std::map<std::string, int>> gotos;     // 状态 -> 非终结符 -> 状态
    std::vector<std::pair<int, std::string>> conflicts;  // (状态, 终结符)
    // LR(1) 独有：每个 LR(0) 核心分裂出的 LR(1) 状态（讲"精确 lookahead 分裂状态"用）
    std::map<Core, std::vector<int>> splits;
};

// SLR 造表：LR(0) 项集族 + FOLLOW 发归约许可证（第 7 章口径，此处作对照）
Table buildSLR(const Grammar &g);

// 规范 LR(1) 造表：项带 lookahead [A→α·β, a]，CLOSURE 用 FIRST(βa) 传播
Table buildLR1(const Grammar &g);

// LALR(1)：规范族按核心合并、lookahead 求并（同心合并）
Table buildLALR(const Grammar &g, const Table &lr1);

// ---------- 表驱动分析器 ----------
struct ParseResult {
    bool accept = false;
    int steps = 0;
};

ParseResult tableParse(const Grammar &g, const Table &t, const std::vector<std::string> &words);

}  // namespace tip

#endif  // TIP_LR1_HPP
