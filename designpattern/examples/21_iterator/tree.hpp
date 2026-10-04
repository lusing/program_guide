#pragma once
// 迭代器：把"怎么遍历"从容器里拆出来——树容器 + 栈式中序迭代器。
// 迭代器与容器分离：容器管存储，迭代器管遍历状态，两者可独立演化。
#include <cassert>
#include <concepts>
#include <iterator>
#include <memory>
#include <vector>

namespace dp {

template <class T>
struct TreeNode {
    T v;
    TreeNode* l = nullptr;
    TreeNode* r = nullptr;
};

template <class T>
class Tree {
public:
    void insert(const T& val) { root_ = insert_(root_, val); ++size_; }

    ~Tree() { destroy(root_); }
    Tree() = default;                       // 显式补回：声明拷贝删除会抑制隐式默认构造
    Tree(const Tree&) = delete;
    Tree& operator=(const Tree&) = delete;

    [[nodiscard]] size_t size() const { return size_; }

    // ---- 中序迭代器：栈式递归展开（显式栈代替调用栈） ----
    class inorder_iterator {
    public:
        using value_type = T;
        using difference_type = std::ptrdiff_t;
        using reference = const T&;
        using pointer = const T*;
        using iterator_concept = std::forward_iterator_tag;

        explicit inorder_iterator(TreeNode<T>* root) {
            push_left(root);            // 初始：最左路径全部入栈
        }

        reference operator*() const { return stack_.back()->v; }
        pointer operator->() const { return &stack_.back()->v; }

        inorder_iterator& operator++() {
            auto* node = stack_.back();
            stack_.pop_back();
            if (node->r) push_left(node->r);   // 右子树的最左路径入栈
            return *this;
        }
        inorder_iterator operator++(int) {
            auto tmp = *this;
            ++*this;
            return tmp;
        }

        bool operator==(const inorder_iterator&) const = default;

        // 与哨兵比较：栈空即遍历完——哨兵无状态，状态全在迭代器里
        bool operator==(std::default_sentinel_t) const { return stack_.empty(); }

    private:
        void push_left(TreeNode<T>* n) {
            for (; n; n = n->l) stack_.push_back(n);
        }
        std::vector<TreeNode<T>*> stack_;
    };

    using iterator = inorder_iterator;

    [[nodiscard]] inorder_iterator begin() const { return inorder_iterator(root_); }
    [[nodiscard]] std::default_sentinel_t end() const {
        return std::default_sentinel;      // 栈空即结束——哨兵不持状态
    }

private:
    static TreeNode<T>* insert_(TreeNode<T>* n, const T& val) {
        if (!n) return new TreeNode<T>{val};
        if (val < n->v)
            n->l = insert_(n->l, val);
        else if (n->v < val)
            n->r = insert_(n->r, val);
        return n;                            // 相等：不重复插
    }
    static void destroy(TreeNode<T>* n) {
        if (!n) return;
        destroy(n->l);
        destroy(n->r);
        delete n;
    }

    TreeNode<T>* root_ = nullptr;
    size_t size_ = 0;
};

}  // namespace dp
