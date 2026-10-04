#pragma once
// 访问者的 variant 形态：ShapeS = variant<CircleS, RectS, TriS>，
// 操作 = 一组 lambda 的 overload——一个函数写完一个"访问者"，无 accept 跳板。
// 代价：类型封闭——形状集合固定在 variant 参数列表里，加形状要改所有 visit 点。
#include <string>
#include <utility>
#include <variant>

namespace dp {

// overload 组合子：把多个 lambda 合成一个多重调用体（C++20 起 CTAD 免写推导指引）。
template <class... Ts>
struct overload : Ts... {
    using Ts::operator()...;
};

struct CircleS { double r; };
struct RectS { double w, h; };
struct TriS { double b, h; };

using ShapeS = std::variant<CircleS, RectS, TriS>;

// 面积：std::visit + overload 按"形状备选项"分派——对应 AreaVisitor 三个 visit。
inline double area_of(const ShapeS& s) {
    return std::visit(overload{
        [](const CircleS& c) { return 3.14159265358979 * c.r * c.r; },
        [](const RectS& r) { return r.w * r.h; },
        [](const TriS& t) { return t.b * t.h / 2.0; },
    }, s);
}

// JSON：同一批形状的第二种操作——同样只写一个函数。
inline std::string json_of(const ShapeS& s) {
    return std::visit(overload{
        [](const CircleS& c) {
            return R"({"t":"circle","r":)" + std::to_string(c.r) + "}";
        },
        [](const RectS& r) {
            return R"({"t":"rect","w":)" + std::to_string(r.w) +
                   R"(,"h":)" + std::to_string(r.h) + "}";
        },
        [](const TriS& t) {
            return R"({"t":"tri","b":)" + std::to_string(t.b) +
                   R"(,"h":)" + std::to_string(t.h) + "}";
        },
    }, s);
}

}  // namespace dp
