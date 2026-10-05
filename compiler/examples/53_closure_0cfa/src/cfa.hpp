// 第 53 章配套：0-CFA（零阶控制流分析）——为高阶调用回答
// "这个调用点可能调到哪些函数"。
//
// 设计分两层，正文会完整讲解：
//   1. 约束生成：把程序翻译成"与语法无关"的约束数据 CfaConstraints；
//   2. 不动点求解：solve0Cfa 只见约束，在"位置 → 函数集"的缓存上
//      做 cubic worklist；每当调用点的函数集长出新函数，
//      动态长出形参绑定与返回绑定（"鸡与蛋"由不动点解开）。
#pragma once

#include <map>
#include <set>
#include <string>
#include <tuple>
#include <vector>

#include "ast.hpp"
#include "symtab.hpp"

namespace tip {

struct CfaConstraints {
    // 程序中全部函数名（抽象 λ 标签集合）。
    std::set<std::string> lambda;

    // 抽象位置（abstract location）的命名约定：
    //   形参/局部变量 → "fun.x"（生成器与求解器共同遵守）；
    //   表达式结果位置 → "%N"（生成器顺序编号，仅用于串联约束）。
    //
    // 两类基础边（三元组 (kind, a, b)）：
    //   ("val",  loc, fun) : 位置 loc 的缓存 ⊇ {fun}（函数名出现处）；
    //   ("copy", dst, src) : 位置 dst 的缓存 ⊇ 位置 src 的缓存（变量间流动）。
    std::vector<std::tuple<std::string, std::string, std::string>> edges;

    // 间接调用：函数值位置 calleeLoc 每"长出"一个函数 fun，
    // 就按命名约定激活一次绑定：
    //   fun 的第 i 个形参位置 ⊇ 第 i 个实参位置；
    //   调用结果位置        ⊇ fun 的返回表达式位置。
    struct CallEdge {
        std::string site;                  // 调用点标签 "fun:n"
        std::string calleeLoc;
        std::vector<std::string> argLocs;
        std::string resultLoc;
    };
    std::vector<CallEdge> calls;

    std::map<std::string, std::string> retLoc;    // 函数名 → 返回表达式结果位置
    std::map<std::string, std::string> siteText;  // 调用点标签 → 表达式文本
    // 形参名表（函数签名的一部分）：求解器据此拼形参位置 "fun.param"，
    // 无需接触 AST。
    std::map<std::string, std::vector<std::string>> params;
};

// 遍历 AST + 名字绑定，生成 0-CFA 约束。
CfaConstraints buildCfaConstraints(const ProgramA &program,
                                   const Bindings &bindings);

struct CfaResult {
    std::map<std::string, std::set<std::string>> cache;  // 位置 → 函数集
    std::map<std::string, std::set<std::string>> sites;  // 调用点 → 函数集
    long activations = 0;   // 新（调用点, 目标函数）配对数
    long rises = 0;         // 缓存集合并使集合真上升的次数
};

CfaResult solve0Cfa(const CfaConstraints &c);

std::string printCfa(const CfaConstraints &c, const CfaResult &r);

}  // namespace tip
