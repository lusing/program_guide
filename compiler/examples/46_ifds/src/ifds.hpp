// 第 46 章配套：IFDS 框架（Reps–Horwitz–Sagiv）求解可能未初始化分析。
// IFDS 把分析问题表达成"有限事实集 D 上的可分配（distributive）流函数"，
// 再用 path-edge tabulation 在过程间超级图上求精确的 merge-over-valid-paths。
// 关键：流函数只在单点事实上定义，集合语义由逐点并集得到——
//   F(S) = ⨆_{d∈S∪{0}} f(d)
// 可分配性 f(a∪b)=f(a)∪f(b) 让这种分解不失真。
#pragma once

#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

// 事实：零事实 0（恒真、可达性载体）或变量名（该变量可能未初始化）。
struct Fact {
    bool zero = false;
    std::string name;

    bool operator==(const Fact &o) const {
        return zero == o.zero && name == o.name;
    }
    bool operator<(const Fact &o) const {
        if (zero != o.zero) return zero > o.zero;  // 0 排在前（仅为稳定序）
        return name < o.name;
    }
};
Fact fZero();
Fact fName(std::string n);
std::string factShow(const Fact &f);

// 全局程序点：(函数名, 函数内 CFG 节点号)。
using PP = std::pair<std::string, int>;

// 路径边：(start 标号点) → (end 标号点)，表示存在一条过程内有效路径
// 从 entry 的事实 f1 走到 n 的事实 f2。
struct PathEdge {
    PP start;
    Fact f1;
    PP end;
    Fact f2;

    bool operator<(const PathEdge &o) const {
        if (start != o.start) return start < o.start;
        if (!(f1 == o.f1)) return f1 < o.f1;
        if (end != o.end) return end < o.end;
        return f2 < o.f2;
    }
};

struct IfdsResult {
    std::set<PathEdge> pathEdges;
    std::map<PP, std::set<Fact>> reach;  // 每个点到达的事实（path edge 末端）
    std::vector<std::string> warnings;
};

// 对整个程序跑 IFDS tabulation（实例固定为可能未初始化）。
IfdsResult solveIfds(const Cfg &cfg, const ProgramA &program);

std::string printIfds(const Cfg &cfg, const IfdsResult &r);

}  // namespace tip
