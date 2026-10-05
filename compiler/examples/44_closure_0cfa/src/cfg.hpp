// 控制流图（CFG, spa 第 2 章）：把函数体从树形语法展开为"程序点 + 边"的图。
// 数据流分析的载体是图而不是树：循环在图上是环，条件在图上是分叉。
#pragma once

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "ast.hpp"

namespace tip {

struct CfgNode {
    int id = 0;
    enum class Kind { Entry, Exit, Assign, Output, Branch, Return } kind;
    const Stmt *stmt = nullptr;  // Assign/Output/Branch 指向对应语句
};

struct FunCfg {
    std::string name;
    int entry = -1;
    int exitNode = -1;
    std::map<int, CfgNode> nodes;
    std::vector<std::pair<int, int>> edges;
};

struct Cfg {
    std::vector<FunCfg> funs;
};

Cfg buildCfg(const ProgramA &program);
std::string printCfg(const Cfg &cfg);

}  // namespace tip
