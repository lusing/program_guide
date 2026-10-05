// file: src/verybusy.hpp
// 第 27 章配套之二：非常忙表达式（very busy expressions）——四大经典之四。
// 域 = 表达式集合（规范化键 "a + b"）；方向 = 后向；合并 = 交（must）。
// 表达式 e 在点 p 非常忙 ⟺ 从 p 出发的**每条**路径都会
// 在操作数被重定义之前求值 e。
#ifndef TIP_VERYBUSY_HPP
#define TIP_VERYBUSY_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

std::string exprKey(const Quad &q);   // "a + b" / "a > b" / 复制与其它返回 ""

struct VeryBusyInfo {
    std::vector<std::set<std::string>> in, out;
};

VeryBusyInfo veryBusy(const std::vector<Quad> &code, const std::vector<Block> &blocks);

}  // namespace tip

#endif  // TIP_VERYBUSY_HPP
