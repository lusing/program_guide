// file: src/mop.hpp
// 第 29 章配套：MOP（全路径 meet）的暴力对照。
#ifndef TIP_MOP_HPP
#define TIP_MOP_HPP

#include "framework.hpp"

namespace tip {

// 深度 K（途经块数上限）内枚举全部路径的逐路径复合再 meet。
// 返回值与 solve 同口径：前向给每块 OUT、后向给每块 IN。
// 无环图上 K 足够大即为精确 MOP；有环时是深度受限的下近似。
std::vector<FVal> mop(const Instance &inst, const std::vector<Quad> &code,
                      const std::vector<Block> &blocks, int K);

}  // namespace tip

#endif  // TIP_MOP_HPP
