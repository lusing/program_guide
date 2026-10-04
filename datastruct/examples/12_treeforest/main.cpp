#include <cassert>
#include <print>
#include <vector>

#include "tree_forest.hpp"
#include "union_find2.hpp"

// 12 树与森林：长子-兄弟表示、森林↔二叉树转换、按秩合并+路径压缩并查集

int main() {
    using Forest = ds::Tree<char>;

    // ═══ 构造两棵树的森林：
    //      A 树：A 有孩子 B,C,D；C 有孩子 E
    //      F 树：F 有孩子 G
    Forest forest;
    forest.add_root('A');
    forest.add_child('A', 'B');
    forest.add_child('A', 'C');
    forest.add_child('A', 'D');
    forest.add_child('C', 'E');
    forest.add_root('F');
    forest.add_child('F', 'G');

    const std::vector<char> expected{'A', 'B', 'C', 'E', 'D', 'F', 'G'};
    assert(forest.preorder() == expected);
    std::println("森林先序：{}", forest.preorder());

    // ═══ 森林 → 二叉树。先序序列在转换前后相同（左=长子、右=兄弟）═══
    ds::BinTreeRep<char> bin = ds::to_binary_tree(forest);
    assert(bin.preorder() == expected);
    std::println("对应二叉树先序：{}（与森林先序一致）", bin.preorder());

    // ═══ 二叉树 → 森林，往返后先序不变 ═══
    Forest back = ds::from_binary_tree(bin);
    assert(back.preorder() == expected);
    std::println("二叉树转回森林先序：{}（往返一致）", back.preorder());

    // ═══ 找不到 parent 属于编程错误，必须抛异常 ═══
    bool threw = false;
    try {
        Forest other;
        other.add_root('X');
        other.add_child('Z', 'Y');
    } catch (const std::runtime_error&) {
        threw = true;
    }
    assert(threw);
    std::println("向不存在的节点挂孩子：抛异常");

    // ═══ 并查集：按秩合并的秩变化 0 → 1 → 1 → 2，全程单调 ═══
    ds::UnionFind2 uf(6);
    int max_rank = 0;
    auto merge = [&](int a, int b) {
        assert(uf.unite(a, b));
        int cur = uf.rank_of(a);
        assert(cur >= max_rank);  // 秩只增不减
        max_rank = cur;
    };
    merge(0, 1);  // 0+0 同秩：根秩 1
    assert(uf.find(0) == uf.find(1));
    merge(2, 3);  // 另一棵秩 1 的树
    merge(0, 2);  // 1+1 同秩：根秩 2
    assert(uf.find(3) == uf.find(0));
    assert(max_rank == 2);
    std::println("按秩合并：三次合并后最大秩为 {}（秩全程单调）", max_rank);

    // ═══ 路径压缩：5 的路径 5→4→0，find 后直接挂根 ═══
    assert(uf.unite(4, 5));  // 秩 0+0：根 4 秩 1
    assert(uf.unite(0, 4));  // 秩 2 吸收秩 1：4 挂到 0 下
    assert(uf.depth_of(5) == 2);
    assert(uf.find(5) == uf.find(0));
    assert(uf.depth_of(5) == 1);
    std::println("路径压缩：节点 5 的深度 2 → 1（直接挂根）");

    // ═══ 1000 次确定性混合操作：秩界 sanity；全量 find 后人人直挂根 ═══
    ds::UnionFind2 big(64);
    for (int k = 0; k < 1000; ++k) {
        big.unite(k % 64, (k * 7 + 3) % 64);
    }
    assert(big.rank_sanity());
    for (int i = 0; i < 64; ++i) {
        big.find(i);
    }
    for (int i = 0; i < 64; ++i) {
        assert(big.depth_of(i) <= 1);
    }
    std::println("1000 次混合操作：秩界 sanity 通过；路径压缩后深度均 ≤ 1");

    std::println("自检通过");
}
