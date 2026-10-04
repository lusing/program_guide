#pragma once
// 多态三副面孔之二：concepts——编译期分派（duck typing 的静态版）。
// 同一 render 合同，但 span<const D> 是同质的：混合 Sq/Ci 必须分两次实例化调用。
#include <concepts>
#include <span>
#include <string>

#include "virtual_poly.hpp"

namespace dp {

template <typename D>
concept DrawableLike = requires(const D& d, std::string& out) {
    d.draw(out);
};

// 每个具体类型 D 实例化一份 render——"sq" 与 "ci" 各得一份机器码。
template <DrawableLike D>
inline std::string render(std::span<const D> v) {
    std::string out;
    for (const auto& d : v) d.draw(out);
    return out;
}

// 编译期混排：类型集合作为参数包在调用点展开——同一份输出合同 "sq;ci"。
// 运行期容器做不到的事（异构），参数包在编译期做到了；代价是集合写死在调用表达式里。
template <DrawableLike... Ds>
inline std::string render_pack(const Ds&... ds) {
    std::string out;
    (ds.draw(out), ...);
    return out;
}

}  // namespace dp
