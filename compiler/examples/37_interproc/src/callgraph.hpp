// 第 37 章配套：调用图 + 两档过程间常量传播对比。
// 调用图是过程间分析的载体；常量传播跨过函数边界时遇到的问题是：
// 被调函数在不同调用点收到不同实参，若把所有调用点的结果合并成一份
// "被调函数汇总"，每个调用点都只能拿到合并后的 ⊤。
// 两档对比：
//   上下文不敏感（调用点一律 ⊤）——基线；
//   内联展开——对无环调用图中的直线纯函数，在传递函数层把函数体展开求值。
#pragma once

#include <map>
#include <set>
#include <string>

#include "ast.hpp"
#include "cfg.hpp"
#include "constant.hpp"

namespace tip {

// 调用图：caller → callee 集合（同名多次调用折叠成一条边）。
struct CallGraph {
    std::map<std::string, std::set<std::string>> edges;
    bool acyclic = true;  // DFS 判定：有环则内联展开不终止，需回退 ⊤
};

CallGraph buildCallGraph(const ProgramA &program);
std::string printCallGraph(const CallGraph &cg);

// 两档过程间常量传播。状态按函数分桶：CFG 节点号只在函数内唯一，
// 跨函数共享 map<int, …> 会把不同函数的同号点混在一起。
//   inlineExpand=false：调用点一律 ⊤（基线）
//   inlineExpand=true ：直线纯被调函数内联展开；有环/不纯处回退 ⊤
std::map<std::string, ConstPointEnv> solveConstInterproc(
    const Cfg &cfg, const ProgramA &program, bool inlineExpand);

std::string printInterproc(const Cfg &cfg, const ProgramA &program,
                           const std::map<std::string, ConstPointEnv> &states);

}  // namespace tip
