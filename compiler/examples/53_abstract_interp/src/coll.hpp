// 第 53 章配套：收集语义（collecting semantics）与 Galois 连接。
//
// 收集语义 C[[p]]：在每个程序点记录"所有可能执行到这里的环境"的集合，
// 是具体语义最直接的静态形态——它不丢失信息，因而通常不可计算/无限；
// 本章对有限条给定输入流做路径展开，得到它的一个有限切片。
//
// 在收集状态上定义抽象映射 α（按符号分类、join）与具体化 γ
//（枚举匹配符号的环境），并检验两个核心命题：
//   可靠性定理：α(C[[p]]) ⊑ A（A 为 CFG 上的单调符号分析）；
//   Galois 连接：S ⊆ γ(α(S))（有限代表域上的往返检验）。
#pragma once

#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

// 程序点 =（函数名, 函数内编号）。
using PP = std::pair<std::string, int>;
using TraceEnv = std::map<std::string, int>;
using CollState = std::map<PP, std::set<TraceEnv>>;

// 一条具体输入流 → 一次确定性执行；收集状态是多次执行的并。
struct CollectResult {
    CollState state;
    int runs = 0;
};
CollectResult collect(const Cfg &cfg, const ProgramA &program,
                      const std::vector<std::vector<int>> &inputStreams);

struct GaloisResult {
    // α(C[[p]])：每点 每变量 的符号（编码同 sign.hpp）
    std::map<PP, std::map<std::string, int>> alphaCollection;
    // 单调符号分析 A：每点 每变量 的符号
    std::map<PP, std::map<std::string, int>> analysis;
    bool theoremHolds = false;      // α(C[[p]]) ⊑ A 逐点成立
    int pointsCompared = 0;
    // 往返检验：收集到的环境中能被 γ(α(S)) 重现的比例
    int envsTotal = 0, envsRoundtrip = 0;
};

// 代表域用于 γ 的有限枚举（文档说明这是 Galois 连接的有限检验）。
GaloisResult runGalois(const Cfg &cfg, const ProgramA &program,
                       const CollectResult &collected,
                       const std::vector<int> &representatives);

std::string printCollect(const Cfg &cfg, const ProgramA &program,
                         const CollectResult &collected);
std::string printGalois(const GaloisResult &g);

}  // namespace tip
