// file: src/reach.hpp
// 第 26 章配套之一：到达定值（reaching definitions）——四大经典之三。
// 域 = 定值集合（TAC 行号）；方向 = 前向；合并 = 并（may）。
// in[B] = ∪ out[P]（前驱）；out[B] = gen[B] ∪ (in[B] - kill[B])。
#ifndef TIP_REACH_HPP
#define TIP_REACH_HPP

#include <map>
#include <set>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 每块的 gen/kill 与不动点解。定值用“行号:变量”标识。
struct ReachInfo {
    std::vector<std::set<int>> in, out;          // 每块的 IN/OUT 定值行号集
    std::vector<std::set<int>> gen, kill;        // gen：块内“冒出来”的定值
    std::map<int, std::string> defVar;           // 行号 → 被定值的变量
};

// 迭代到不动点（第 23 章工作表骨架的又一实例化：这里用轮转直到稳定）。
ReachInfo reaching(const std::vector<Quad> &code, const std::vector<Block> &blocks);

// ud 链：指令 i 处变量 v 的使用，能到达它的定值行号集。
std::set<int> udChain(const ReachInfo &ri, const std::vector<Block> &blocks,
                      int i, const std::string &v);

}  // namespace tip

#endif  // TIP_REACH_HPP
