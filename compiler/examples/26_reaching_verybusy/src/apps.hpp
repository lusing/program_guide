// file: src/apps.hpp
// 第 26 章配套之三：两个应用变换。
//   copyProp：复制传播（到达定值/ud 链驱动）+ 死 copy 删除；
//   hoist   ：代码提升（非常忙驱动）——把分支两侧重复的“分支后立刻要”
//             的表达式提到条件跳转之前。
// 两者都改写 TAC 并重映射跳转目标；验收由驱动用 TAC 解释器对账。
#ifndef TIP_APPS_HPP
#define TIP_APPS_HPP

#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "reach.hpp"
#include "verybusy.hpp"

namespace tip {

struct CopyPropResult {
    int replaced = 0;
    int deleted = 0;
};

struct HoistResult {
    int inserted = 0;   // 同时兼作临时计数器
    int hoisted = 0;
    std::vector<std::string> detail;
};

CopyPropResult copyProp(std::vector<Quad> &code, const ReachInfo &ri,
                        const std::vector<Block> &blocks);
HoistResult hoist(std::vector<Quad> &code, const VeryBusyInfo &vb,
                  const std::vector<Block> &blocks);

}  // namespace tip

#endif  // TIP_APPS_HPP
