// file: src/framework.hpp
// 第 33 章配套：通用数据流框架——半格 + 单调转移函数 + 方向。
// 一个实例 = 一张“值怎么 meet、每条指令怎么转、边界是什么”的表；
// 引擎对任何实例求 MFP（迭代到不动点）。
// 值统一为字符串集合：定值号 "i:var"、表达式键 "a + b"、变量名、常量项 "x=5"。
#ifndef TIP_FRAMEWORK_HPP
#define TIP_FRAMEWORK_HPP

#include <functional>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

using FVal = std::set<std::string>;

enum class Dir { Forward, Backward };

struct Instance {
    std::string name;
    Dir dir;
    std::function<FVal(const FVal &, const FVal &)> meetFn;
    FVal boundary;    // 入口（前向）/出口（后向）
    FVal initTop;     // 迭代初值：may 用 ∅，must 用全集
    // 转移：行号 + 指令 + 流入值 → 流出值（按方向的语义复合）
    std::function<FVal(int, const Quad &, const FVal &)> transfer;
};

struct FrameResult {
    std::vector<FVal> in, out;
};

FrameResult solve(const Instance &inst, const std::vector<Quad> &code,
                  const std::vector<Block> &blocks);
FVal blockTransfer(const Instance &inst, const std::vector<Quad> &code,
                   const Block &b, FVal v);

}  // namespace tip

#endif  // TIP_FRAMEWORK_HPP
