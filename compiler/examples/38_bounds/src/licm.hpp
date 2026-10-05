// file: src/licm.hpp
// 第 37 章配套：循环不变式外提（LICM）与归纳变量家族。
//   循环来自第 33 章的自然循环；外提位置 = 唯一非循环前驱（preheader）的块尾。
//   判据用紫龙 9.1.7 的安全子集：
//     (1) 指令的 dst 在循环内是唯一定值；
//     (2) 操作数在循环内无定值（全部来自循环外或常量）；
//     (3) dst 在循环外无使用（t 系临时天然满足；变量需检查）——
//         这条回避了“支配所有出口”的图论判据，教学版更稳。
#ifndef TIP_LICM_HPP
#define TIP_LICM_HPP

#include <set>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "dom.hpp"
#include "dfs.hpp"

namespace tip {

struct LoopInfo {
    std::vector<NaturalLoop> loops;
    std::vector<std::vector<int>> adj;
    DomInfo di;
};

LoopInfo loopsOf(const std::vector<Quad> &code, const std::vector<Block> &blocks);

// 外提：返回 (新指令序列, 外提条数)。preheader 末尾插入（跳转目标零改动）。
std::pair<std::vector<Quad>, int> licm(const std::vector<Quad> &code,
                                       const std::vector<Block> &blocks,
                                       const LoopInfo &li);

// 归纳变量分析：找 (i, c) —— 循环内唯一自增 i = i + c、循环外有初值。
struct IndVar {
    std::string var;
    int incrLine;      // i = i + c 的行号
    int incr;          // c
};
std::vector<IndVar> indVars(const std::vector<Quad> &code,
                            const std::vector<Block> &blocks,
                            const NaturalLoop &loop);

}  // namespace tip

#endif  // TIP_LICM_HPP
