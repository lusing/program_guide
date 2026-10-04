// file: src/lr.hpp
// 第 7 章配套：LR(0) 项集族、SLR 造表（绿龙 Algorithm 6.1）、
// 移进-归约驱动器（绿龙 Fig 6.2/6.4 的模型）。
#ifndef TIP_LR_HPP
#define TIP_LR_HPP

#include "grammar.hpp"

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

inline const std::string LR_DOLLAR = "$";

// LR(0) 项 = (产生式下标, 点位)。绿龙：两个整数就够存一个项。
struct Item {
    int prod, dot;
    bool operator<(const Item &o) const {
        return prod != o.prod ? prod < o.prod : dot < o.dot;
    }
    bool operator==(const Item &o) const {
        return prod == o.prod && dot == o.dot;
    }
};

enum class Act { Err, Shift, Reduce, Accept };

struct Action {
    Act kind = Act::Err;
    int target = -1;   // Shift: 目标状态；Reduce: 产生式下标
};

struct Conflict {
    int state;
    std::string look;
    std::string kind;   // "shift-reduce" / "reduce-reduce"
    int shiftTarget = -1;
    std::vector<int> reduceProds;
    std::string resolution;
};

class SLR {
public:
    const Grammar &g;
    std::vector<Production> aug;                 // aug[0] = 增广开始产生式
    std::vector<std::set<Item>> states;          // 规范 LR(0) 项集族
    std::map<std::pair<int, std::string>, int> gotof;   // GOTO(状态, 符号)
    std::map<std::pair<int, std::string>, Action> action;
    std::map<std::string, std::set<std::string>> follow;
    std::vector<Conflict> conflicts;

    explicit SLR(const Grammar &g);

    std::string showItem(const Item &it) const;         // expr -> expr · PLUS term
    std::set<Item> closure(std::set<Item> i) const;     // 绿龙 Fig 6.5
    std::set<Item> goTo(const std::set<Item> &i, const std::string &X) const;   // 移点+闭包
    void buildItems();                                   // 绿龙 Fig 6.6 ITEMS
    void buildTable(bool preferShift);                   // 绿龙 Algorithm 6.1

    // 移进-归约驱动。输出 moves 到 os；返回 (成功?, 诊断)。
    struct RunResult { bool ok; std::string error; };
    RunResult run(const std::vector<std::string> &input,
                  std::ostringstream &os) const;
    std::string stackText(const std::vector<int> &s,
                          const std::vector<std::string> &sym) const;
    std::string inputText(const std::vector<std::string> &input, size_t ip) const;
};

}  // namespace tip

#endif  // TIP_LR_HPP
