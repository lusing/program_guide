#pragma once
// 解释器的 variant 形态：文法节点 = variant 备选项，求值/化简 = visit 函数。
// 与第 13 章 variant 组合同构；"化简规则"演示解释器模式的第二类操作。
#include <cstddef>
#include <memory>
#include <span>
#include <utility>
#include <variant>

namespace dp {

// 递归 variant 的拆环手法：备选项用 unique_ptr<未完整类型>——指针打断递归。
struct AndV;
struct OrV;
struct NotV;

struct VarV { size_t idx; };

using BExprV = std::variant<VarV,
                            std::unique_ptr<AndV>,
                            std::unique_ptr<OrV>,
                            std::unique_ptr<NotV>>;

// BExprV 完整之后才定义节点结构体（成员需要 unique_ptr<BExprV>）
struct AndV { std::unique_ptr<BExprV> l, r; };
struct OrV  { std::unique_ptr<BExprV> l, r; };
struct NotV { std::unique_ptr<BExprV> e; };

// ---- 组装辅助 ----
inline std::unique_ptr<BExprV> make_var(size_t i) {
    return std::make_unique<BExprV>(VarV{i});
}
inline std::unique_ptr<BExprV> make_and(std::unique_ptr<BExprV> l,
                                        std::unique_ptr<BExprV> r) {
    return std::make_unique<BExprV>(std::make_unique<AndV>(
        AndV{std::move(l), std::move(r)}));
}
inline std::unique_ptr<BExprV> make_or(std::unique_ptr<BExprV> l,
                                       std::unique_ptr<BExprV> r) {
    return std::make_unique<BExprV>(std::make_unique<OrV>(
        OrV{std::move(l), std::move(r)}));
}
inline std::unique_ptr<BExprV> make_not(std::unique_ptr<BExprV> e) {
    return std::make_unique<BExprV>(std::make_unique<NotV>(NotV{std::move(e)}));
}

// ---- eval：visit + if constexpr 按备选项分派（等价虚函数 eval）----
inline bool veval(const BExprV& e, std::span<const bool> vars) {
    return std::visit(
        [&](const auto& v) -> bool {
            using T = std::decay_t<decltype(v)>;
            if constexpr (std::is_same_v<T, VarV>) {
                return vars[v.idx];                    // 叶：查环境
            } else if constexpr (std::is_same_v<T, std::unique_ptr<AndV>>) {
                return veval(*v->l, vars) && veval(*v->r, vars);
            } else if constexpr (std::is_same_v<T, std::unique_ptr<OrV>>) {
                return veval(*v->l, vars) || veval(*v->r, vars);
            } else {
                return !veval(*v->e, vars);            // NotV
            }
        },
        e);
}

// ---- simplify：化简规则也是"一次遍历"——解释器模式加操作零成本 ----
// 本例规则：not not x -> x（双重否定剥掉）。文法无常量叶，规则集保持最小。
// 注意：visit 的第二参必须是 variant 本体（*e），不是 unique_ptr。
inline std::unique_ptr<BExprV> vsimplify(const BExprV& e) {
    return std::visit(
        [&](const auto& v) -> std::unique_ptr<BExprV> {
            using T = std::decay_t<decltype(v)>;
            if constexpr (std::is_same_v<T, VarV>) {
                return make_var(v.idx);                 // 叶：重建等价节点
            } else if constexpr (std::is_same_v<T, std::unique_ptr<NotV>>) {
                auto inner = vsimplify(*v->e);
                // 内层若还是 Not：剥掉双重否定，直接返回 Not 的操作数
                if (auto* p = std::get_if<std::unique_ptr<NotV>>(inner.get()))
                    return std::move((*p)->e);
                return make_not(std::move(inner));
            } else if constexpr (std::is_same_v<T, std::unique_ptr<AndV>>) {
                return make_and(vsimplify(*v->l), vsimplify(*v->r));
            } else {
                return make_or(vsimplify(*v->l), vsimplify(*v->r));
            }
        },
        e);
}

}  // namespace dp
