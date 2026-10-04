#include <cassert>
#include <print>
#include <string>
#include <vector>

#include "binary_tree.hpp"

// 11 二叉树：由前序+中序重建，验证五种遍历与值语义

namespace {

std::string join(const std::vector<char>& v) {
    std::string s;
    for (char c : v) {
        s.push_back(c);
    }
    return s;
}

}  // namespace

int main() {
    // ═══ 前序 ABDECFG、中序 DBEAFCG 唯一确定一棵 7 节点二叉树 ═══
    const std::vector<char> pre{'A', 'B', 'D', 'E', 'C', 'F', 'G'};
    const std::vector<char> in{'D', 'B', 'E', 'A', 'F', 'C', 'G'};
    const ds::BinaryTree<char> tree = ds::BinaryTree<char>::from_pre_in(pre, in);

    assert(join(tree.preorder()) == "ABDECFG");
    assert(join(tree.inorder()) == "DBEAFCG");
    assert(join(tree.postorder()) == "DEBFGCA");
    assert(tree.postorder_iter() == tree.postorder());  // 非递归版与递归版一致
    assert(join(tree.levelorder()) == "ABCDEFG");
    assert(tree.size() == 7);
    assert(tree.height() == 3);
    assert(tree.leaves() == 4);  // D,E,F,G 四叶（计划写的 3 有误：重建出的是完美二叉树）

    std::println("重建成功：前序 {}，中序 {}", join(tree.preorder()), join(tree.inorder()));
    std::println("后序（递归/非递归一致）：{}", join(tree.postorder()));
    std::println("层序 {}；节点 {}，高度 {}，叶子 {}",
                 join(tree.levelorder()), tree.size(), tree.height(), tree.leaves());

    // ═══ 拷贝独立：副本改赋另一棵树，原件不受影响 ═══
    ds::BinaryTree<char> copy = tree;
    assert(copy.size() == tree.size());
    const ds::BinaryTree<char> other =
        ds::BinaryTree<char>::from_pre_in(std::vector<char>{'X', 'Y'},
                                         std::vector<char>{'Y', 'X'});
    copy = other;
    assert(join(copy.preorder()) == "XY");
    assert(join(tree.preorder()) == "ABDECFG");  // 原件完好
    std::println("拷贝赋值后副本为 XY，原件仍为 {}（互不影响）", join(tree.preorder()));

    // ═══ 移动语义：资源转移后源对象为空 ═══
    ds::BinaryTree<char> will_move = tree;
    ds::BinaryTree<char> moved = std::move(will_move);
    assert(moved.size() == 7);
    assert(will_move.size() == 0);
    std::println("移动后：新对象节点 {}，源对象节点 {}", moved.size(), will_move.size());

    std::println("自检通过");
}
