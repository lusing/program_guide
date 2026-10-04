#pragma once
// 组合的现代形态：std::variant 代替继承——树节点用值类型闭包表达，
// 递归访问用 std::visit + 重载集合。无虚表、无堆所有权（节点内直接嵌子节点）。
#include <algorithm>
#include <string>
#include <type_traits>
#include <utility>
#include <variant>
#include <vector>

namespace dp {

// 递归类型：std::variant 允许"包含自己"——通过前向声明的结构体模板惯用法。
// FileV 是叶子，FolderV 是容器，FolderV 内嵌 variant 节点即成树。
struct FolderV;

using NodeV = std::variant<int /*文件大小*/, std::unique_ptr<FolderV>>;

struct FolderV {
    std::vector<NodeV> children;
};

// size：variant 版递归求和——叶子装的是 int（大小），夹装的是子树指针。
// std::visit + if constexpr 按"当前装的是什么"分派，等价于虚函数 size()。
size_t vsize(const NodeV& n) {
    return std::visit(
        [](const auto& v) -> size_t {
            using T = std::decay_t<decltype(v)>;
            if constexpr (std::is_same_v<T, int>) {
                return static_cast<size_t>(v);            // 叶：直接返回
            } else {
                size_t total = 0;
                for (const auto& c : v->children) total += vsize(c);
                return total;                             // 夹：递归转发
            }
        },
        n);
}

// depth：variant 版树深——叶贡献 0，夹贡献 1 + max(子深)。
// 虚接口里加新操作要给每个类加虚函数；variant 版只需再写一个访问函数。
size_t vdepth(const NodeV& n) {
    return std::visit(
        [](const auto& v) -> size_t {
            using T = std::decay_t<decltype(v)>;
            if constexpr (std::is_same_v<T, int>) {
                return 0;
            } else {
                size_t best = 0;
                for (const auto& c : v->children) best = std::max(best, vdepth(c));
                return 1 + best;
            }
        },
        n);
}

// 组装辅助：造一个叶子节点 / 一个装了若干子的夹节点。
// 注意 NodeV 含 unique_ptr 备选项 → move-only，子节点只能"移"进夹节点，
// 所以 make_folder 用可变参模板逐个 push_back（initializer_list 会要求拷贝）。
inline NodeV make_file(int size) { return NodeV{std::in_place_type<int>, size}; }

template <typename... Ns>
NodeV make_folder(Ns&&... ns) {
    auto f = std::make_unique<FolderV>();
    (f->children.push_back(std::forward<Ns>(ns)), ...);
    return NodeV{std::move(f)};
}

}  // namespace dp
