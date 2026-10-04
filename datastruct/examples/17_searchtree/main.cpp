#include <cassert>
#include <print>
#include <vector>

#include "avl.hpp"
#include "bst.hpp"
#include "red_black.hpp"

// 17 搜索树：BST 增删查、AVL 四情形、红黑树插入合法性

int main() {
    // ═══ BST：插入、查找、三种删除情形 ═══
    {
        ds::BSTree<int, int> t;
        for (int k : {5, 3, 8, 1, 4}) {
            t.insert(k, k * k);
        }
        assert(t.search(4) == 16);
        assert(t.search(9) == std::nullopt);
        assert(t.keys_sorted() == std::vector<int>({1, 3, 4, 5, 8}));

        assert(t.erase(1));                  // 叶子
        assert(t.keys_sorted() == std::vector<int>({3, 4, 5, 8}));
        assert(t.erase(3));                  // 单子（3 的右孩子 4 顶替为后继）
        assert(t.keys_sorted() == std::vector<int>({4, 5, 8}));
        assert(t.erase(5));                  // 双子：后继 8 顶替
        assert(t.keys_sorted() == std::vector<int>({4, 8}));
        assert(t.erase(4));
        assert(t.erase(8));
        assert(t.empty());
        assert(!t.erase(7));                 // 空树删不存在：false
        std::println("BST：插入/查找/叶子·单子·双子三种删除后次序全部正确");
    }

    // 重复键更新值而非新增
    {
        ds::BSTree<int, int> t;
        t.insert(1, 100);
        t.insert(1, 200);
        assert(t.search(1) == 200);
        assert(t.keys_sorted() == std::vector<int>({1}));
        std::println("BST：重复键更新值（不新增节点）");
    }

    // ═══ AVL：四种失衡情形，结构精确断言 ═══
    {
        // LL：插 3,2,1
        ds::AVLTree<int, int> ll;
        for (int k : {3, 2, 1}) ll.insert(k, k);
        auto d = ll.preorder_detail();
        assert(d.size() == 3);
        assert(d[0].key == 2 && d[0].height == 2 && d[0].bf == 0);
        assert(d[1].key == 1 && d[1].height == 1 && d[1].bf == 0);
        assert(d[2].key == 3 && d[2].height == 1 && d[2].bf == 0);

        // RR：插 1,2,3
        ds::AVLTree<int, int> rr;
        for (int k : {1, 2, 3}) rr.insert(k, k);
        d = rr.preorder_detail();
        assert(d[0].key == 2 && d[0].height == 2);
        assert(d[1].key == 1 && d[2].key == 3);

        // LR：插 3,1,2
        ds::AVLTree<int, int> lr;
        for (int k : {3, 1, 2}) lr.insert(k, k);
        d = lr.preorder_detail();
        assert(d[0].key == 2 && d[1].key == 1 && d[2].key == 3);

        // RL：插 1,3,2
        ds::AVLTree<int, int> rl;
        for (int k : {1, 3, 2}) rl.insert(k, k);
        d = rl.preorder_detail();
        assert(d[0].key == 2 && d[1].key == 1 && d[2].key == 3);

        std::println("AVL：LL/RR/LR/RL 四情形旋转后根均为 2、子 1·3、平衡因子全 0");
    }

    // 大量插入与删除后仍处处平衡
    {
        ds::AVLTree<int, int> t;
        for (int k = 1; k <= 7; ++k) t.insert(k, k);
        assert(t.keys_sorted() == std::vector<int>({1, 2, 3, 4, 5, 6, 7}));
        for (auto d : t.preorder_detail()) {
            assert(-1 <= d.bf && d.bf <= 1);
        }
        assert(t.erase(3));
        assert(t.erase(6));
        assert(t.keys_sorted() == std::vector<int>({1, 2, 4, 5, 7}));
        for (auto d : t.preorder_detail()) {
            assert(-1 <= d.bf && d.bf <= 1);
        }
        std::println("AVL：1..7 插入并删除 3·6 后，全部节点平衡因子不超 1");
    }

    // ═══ 红黑树：1..7 插入后合法，根键与黑高确定 ═══
    {
        ds::RedBlackTree<int, int> t;
        for (int k = 1; k <= 7; ++k) t.insert(k, k);
        assert(t.rb_legal());
        assert(t.search(5) == 5);
        assert(t.root_key() == 2);
        assert(t.black_height() == 2);
        std::println("红黑树 1..7：性质全合法，根键 {}，黑高 {}",
                     t.root_key(), t.black_height());
        std::vector<ds::RedBlackTree<int, int>::Colored> pre = t.preorder_colored();
        std::print("  前序（含颜色）：");
        for (size_t i = 0; i < pre.size(); ++i) {
            if (i) std::print(" ");
            std::print("{}{}", pre[i].key, pre[i].color);
        }
        std::println("");
    }

    // 1..100：仍合法，且黑高受对数界约束
    {
        ds::RedBlackTree<int, int> t;
        for (int k = 1; k <= 100; ++k) t.insert(k, k);
        assert(t.rb_legal());
        const int bh = t.black_height();
        assert(bh >= 4);
        std::println("红黑树 1..100：性质全合法，黑高 {}（约为 log₂100 的一半量级）", bh);
    }

    std::println("自检通过");
}
