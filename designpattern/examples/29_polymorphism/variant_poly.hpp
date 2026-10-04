#pragma once
// 多态三副面孔之三：variant——封闭集合上的静态跳转表分派。
// 类型集合写死在 using 里；混合 Sq/Ci 用同一个 vector，visit 一跳到位。
#include <string>
#include <utility>
#include <variant>
#include <vector>

#include "virtual_poly.hpp"

namespace dp {

using AnyShape = std::variant<Sq, Ci>;

inline std::string render(const std::vector<AnyShape>& v) {
    std::string out;
    for (const auto& s : v) {
        std::visit([&](const auto& d) { d.draw(out); }, s);
    }
    return out;
}

}  // namespace dp
