// file: src/bounds.hpp
// 第 38 章配套：guard 插入、边界检查消除（虎书 §18.4）与循环展开报告（§18.5）。
// TIP 没有数组——用除零 guard 当教学替身（与 a[i] 越界检查同构：
// 都是"异常条件驱动的条件跳转"，都能用归纳变量推理消除/外提）。
#ifndef TIP_BOUNDS_HPP
#define TIP_BOUNDS_HPP

#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "licm.hpp"

namespace tip {

// 为每条 Div 插入 guard：`if 分母 == 0 goto fail`（目标负数编码，待消除器回填）。
std::vector<Quad> insertGuards(const std::vector<Quad> &code);

struct BoundsResult {
    std::vector<Quad> code;
    int invariantHoisted = 0;   // 规则 (a)：分母循环不变 ⇒ guard 可外提（计删）
    int ivEliminated = 0;       // 规则 (b)：分母是单调归纳变量 ⇒ guard 可删
};

// 消除/外提：循环内的 guard 按两规则处置；保留者回填到末尾 fail 序列。
BoundsResult eliminateGuards(const std::vector<Quad> &guarded,
                             const std::vector<Block> &blocks,
                             const LoopInfo &li);

struct UnrollResult {
    int unrolled = 0;
};

// 循环展开（教学口径：正文手工推演 + 练习实现）。
UnrollResult unroll2(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                     const LoopInfo &li);

}  // namespace tip

#endif  // TIP_BOUNDS_HPP
