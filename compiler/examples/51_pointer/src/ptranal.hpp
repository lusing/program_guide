// 第 51 章配套：指针分析双算法。
//   Andersen（包含式，subset constraints）：
//     pts(a) 之间是 ⊇ 关系，worklist 求最小不动点，精度高、最坏 O(n³)；
//   Steensgaard（合一式，unification）：
//     每条约束让代表元尽早合一，近线性、实现简单，但 pts 集只会更大。
//
// 与第 50 章一样分两层：AST → 与语法无关的约束 PtrCon；求解器只见约束。
#pragma once

#include <map>
#include <set>
#include <string>
#include <vector>

#include "ast.hpp"
#include "symtab.hpp"

namespace tip {

// 四类约束（地址常量 &z 与 null 都按 New 处理，site 名分别为 "&z"/"null"）：
//   New(a,s) : pts(a) ⊇ {s}        分配点/取址/空指针
//   Copy(a,b): pts(a) ⊇ pts(b)
//   Load(a,b): pts(a) ⊇ pts(*b)    若 v∈pts(b)，则 pts(a) ⊇ pts(v)
//   Store(a,b): pts(*a) ⊇ pts(b)   若 v∈pts(a)，则 pts(v) ⊇ pts(b)
struct PtrCon {
    enum K { New, Copy, Load, Store } k;
    std::string a, b;
};

struct PtrConstraints {
    std::vector<PtrCon> cons;
    std::set<std::string> sites;   // 全部抽象位置标签（分配点 + &z + null）
    std::set<std::string> vars;    // 程序中参与指针约束的变量（打印范围）
};

PtrConstraints buildPtrConstraints(const ProgramA &program,
                                   const Bindings &bindings);

struct PtrResult {
    // Andersen 结果：变量（及被引用的抽象堆位置）→ 位置集
    std::map<std::string, std::set<std::string>> andersen;
    // Steensgaard 结果：合一后的代表元 → 位置集；varRep 给出变量的代表元
    std::map<std::string, std::set<std::string>> steensgaard;
    std::map<std::string, std::string> varRep;
    long rises = 0;       // Andersen pts 集上升次数
    long unifies = 0;     // Steensgaard 成功合并次数
};

PtrResult solvePointer(const PtrConstraints &c);

std::string printPointer(const PtrConstraints &c, const PtrResult &r);

}  // namespace tip
