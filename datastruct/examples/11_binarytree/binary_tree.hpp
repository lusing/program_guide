#ifndef DS_BINARY_TREE_HPP
#define DS_BINARY_TREE_HPP

#include <algorithm>
#include <concepts>
#include <cstddef>
#include <queue>
#include <span>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 二叉树：每个节点至多两个孩子，左右有别。
// 本章只做"构造 + 观察"：树一旦由前序+中序重建出来便不再修改，
// 因此值语义（拷贝/移动/析构）是资源管理的全部重点。
template <std::copyable T>
class BinaryTree {
private:
    struct Node {
        T data;
        Node* left;
        Node* right;
    };

    Node* root_ = nullptr;

    // —— 递归小工具：所有遍历都只是"在节点处按不同次序做三件事" ——

    static Node* clone(const Node* n) {
        if (n == nullptr) {
            return nullptr;
        }
        return new Node{n->data, clone(n->left), clone(n->right)};
    }

    static void destroy(Node* n) noexcept {
        if (n == nullptr) {
            return;
        }
        destroy(n->left);
        destroy(n->right);
        delete n;
    }

    static void preorder_into(const Node* n, std::vector<T>& out) {
        if (n == nullptr) {
            return;
        }
        out.push_back(n->data);
        preorder_into(n->left, out);
        preorder_into(n->right, out);
    }

    static void inorder_into(const Node* n, std::vector<T>& out) {
        if (n == nullptr) {
            return;
        }
        inorder_into(n->left, out);
        out.push_back(n->data);
        inorder_into(n->right, out);
    }

    static void postorder_into(const Node* n, std::vector<T>& out) {
        if (n == nullptr) {
            return;
        }
        postorder_into(n->left, out);
        postorder_into(n->right, out);
        out.push_back(n->data);
    }

    static int count_nodes(const Node* n) noexcept {
        if (n == nullptr) {
            return 0;
        }
        return 1 + count_nodes(n->left) + count_nodes(n->right);
    }

    static int height_of(const Node* n) noexcept {
        if (n == nullptr) {
            return 0;
        }
        return 1 + std::max(height_of(n->left), height_of(n->right));
    }

    static int count_leaves(const Node* n) noexcept {
        if (n == nullptr) {
            return 0;
        }
        if (n->left == nullptr && n->right == nullptr) {
            return 1;
        }
        return count_leaves(n->left) + count_leaves(n->right);
    }

    // 由前序、中序区间递归重建。约定两段等长、元素互不重复。
    // 前序首元素即根；在中序中找到根，左侧是左子树、右侧是右子树，
    // 再按切出的长度把前序剩余部分切成两段 —— 递归处理。
    static Node* build(std::span<const T> pre, std::span<const T> in) {
        if (pre.empty()) {
            return nullptr;
        }
        const auto root_pos = std::find(in.begin(), in.end(), pre[0]);
        if (root_pos == in.end()) {
            throw std::invalid_argument("from_pre_in: root not found in inorder");
        }
        const size_t left_n = static_cast<size_t>(root_pos - in.begin());
        Node* left = build(pre.subspan(1, left_n), in.first(left_n));
        Node* right = build(pre.subspan(1 + left_n), in.subspan(left_n + 1));
        return new Node{pre[0], left, right};
    }

public:
    BinaryTree() = default;

    static BinaryTree from_pre_in(std::span<const T> pre, std::span<const T> in) {
        if (pre.size() != in.size()) {
            throw std::invalid_argument("from_pre_in: preorder/inorder size mismatch");
        }
        BinaryTree tree;
        tree.root_ = build(pre, in);
        return tree;
    }

    // —— 遍历 ——

    [[nodiscard]] std::vector<T> preorder() const {
        std::vector<T> out;
        preorder_into(root_, out);
        return out;
    }

    [[nodiscard]] std::vector<T> inorder() const {
        std::vector<T> out;
        inorder_into(root_, out);
        return out;
    }

    [[nodiscard]] std::vector<T> postorder() const {
        std::vector<T> post;
        postorder_into(root_, post);
        return post;
    }

    // 后序的非递归版：栈里放 (节点, 孩子是否已处理)。
    // 首次入栈标记 false；弹栈时若标记 false，换标记 true 压回，
    // 再依次压右孩子、左孩子 —— 保证离开节点时两个子树都已输出。
    [[nodiscard]] std::vector<T> postorder_iter() const {
        std::vector<T> out;
        std::vector<std::pair<Node*, bool>> stack;
        if (root_ != nullptr) {
            stack.emplace_back(root_, false);
        }
        while (!stack.empty()) {
            auto [n, processed] = stack.back();
            stack.pop_back();
            if (!processed) {
                stack.emplace_back(n, true);
                if (n->right != nullptr) {
                    stack.emplace_back(n->right, false);
                }
                if (n->left != nullptr) {
                    stack.emplace_back(n->left, false);
                }
            } else {
                out.push_back(n->data);
            }
        }
        return out;
    }

    // 层序遍历：先进先出队列 —— 根先入队，出队时把左右孩子依次排入。
    [[nodiscard]] std::vector<T> levelorder() const {
        std::vector<T> out;
        std::queue<Node*> q;
        if (root_ != nullptr) {
            q.push(root_);
        }
        while (!q.empty()) {
            Node* n = q.front();
            q.pop();
            out.push_back(n->data);
            if (n->left != nullptr) {
                q.push(n->left);
            }
            if (n->right != nullptr) {
                q.push(n->right);
            }
        }
        return out;
    }

    // —— 观察 ——

    [[nodiscard]] int size() const noexcept {
        return count_nodes(root_);
    }

    [[nodiscard]] int height() const noexcept {
        return height_of(root_);
    }

    [[nodiscard]] int leaves() const noexcept {
        return count_leaves(root_);
    }

    // —— 值语义五件套 ——

    BinaryTree(const BinaryTree& other) : root_(clone(other.root_)) {}

    BinaryTree(BinaryTree&& other) noexcept : root_(other.root_) {
        other.root_ = nullptr;
    }

    BinaryTree& operator=(const BinaryTree& other) {
        if (this != &other) {
            destroy(root_);
            root_ = clone(other.root_);
        }
        return *this;
    }

    BinaryTree& operator=(BinaryTree&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            other.root_ = nullptr;
        }
        return *this;
    }

    ~BinaryTree() {
        destroy(root_);
    }
};

}  // namespace ds

#endif  // DS_BINARY_TREE_HPP
