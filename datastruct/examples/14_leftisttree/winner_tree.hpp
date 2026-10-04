#ifndef DS_WINNER_TREE_HPP
#define DS_WINNER_TREE_HPP

#include <climits>
#include <cstddef>
#include <span>
#include <vector>

namespace ds {

// 用最小赢者树（min winner tree）把 k 个有序段归并成一个有序序列。
//
// 赢者树是完全二叉树：叶子是 k 个"选手"（每个有序段的当前元素），
// 每个内部节点记录一场比赛的赢者（值较小者；平局按段号）。
// 取走全局赢者后，只让该选手所在叶子沿祖先路径重新比赛（RePlay），
// 其余比赛结果不变。耗尽的选手以 INT_MAX 占位，自动不再获胜。
inline std::vector<int> kway_merge(std::span<const std::vector<int>> runs) {
    const int k = static_cast<int>(runs.size());
    int leaf_count = 1;
    while (leaf_count < k) {
        leaf_count <<= 1;  // 补成 2 的幂，不足的叶子是"永不获胜"的虚选手
    }

    std::vector<size_t> pos(static_cast<size_t>(k), 0);

    struct Player {
        int value;
        int run;  // -1 表示虚选手/已耗尽
    };
    std::vector<Player> tree(static_cast<size_t>(2 * leaf_count), {INT_MAX, -1});

    auto current = [&](int run) -> Player {
        if (pos[run] < runs[run].size()) {
            return {runs[run][pos[run]], run};
        }
        return {INT_MAX, -1};  // 该段已耗尽
    };

    // 一场比赛：值小者胜，平局段号小者胜（保证输出确定）
    auto match = [](const Player& a, const Player& b) -> Player {
        if (a.value < b.value || (a.value == b.value && a.run < b.run)) {
            return a;
        }
        return b;
    };

    for (int i = 0; i < leaf_count; ++i) {
        tree[static_cast<size_t>(leaf_count + i)] =
            (i < k) ? current(i) : Player{INT_MAX, -1};
    }
    for (int p = leaf_count - 1; p >= 1; --p) {
        tree[static_cast<size_t>(p)] =
            match(tree[static_cast<size_t>(2 * p)],
                  tree[static_cast<size_t>(2 * p + 1)]);
    }

    size_t total = 0;
    for (const auto& r : runs) {
        total += r.size();
    }
    std::vector<int> result;
    result.reserve(total);

    for (size_t step = 0; step < total; ++step) {
        const Player winner = tree[1];
        result.push_back(winner.value);

        // 该选手推进到段内下一元素，叶子更新
        const int run = winner.run;
        ++pos[run];
        tree[static_cast<size_t>(leaf_count + run)] = current(run);

        // RePlay：只沿该叶到根的路径重赛
        for (int p = (leaf_count + run) / 2; p >= 1; p /= 2) {
            tree[static_cast<size_t>(p)] =
                match(tree[static_cast<size_t>(2 * p)],
                      tree[static_cast<size_t>(2 * p + 1)]);
        }
    }

    return result;
}

}  // namespace ds

#endif  // DS_WINNER_TREE_HPP
