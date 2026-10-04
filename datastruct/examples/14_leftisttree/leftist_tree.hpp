#ifndef DS_LEFTIST_TREE_HPP
#define DS_LEFTIST_TREE_HPP

#include <climits>
#include <concepts>
#include <cstddef>
#include <functional>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 高度优先左高树（height-biased leftist tree, HBLT）。
//
// s 值定义：空树 s = 0；非空节点 s(x) = 1 + min(s(左), s(右))，
// 即从 x 到一个空孩子的最短路径长度。
// 左高性质：每个节点 s(左) >= s(右)。
// 优先级性质：由 Compare 定序，根优先级不低于任一孩子（std::less 即最小树）。
template <std::totally_ordered T, class Compare = std::less<T>>
class LeftistTree {
private:
    struct Node {
        T value;
        Node* left;
        Node* right;
        int s;
    };

    Node* root_ = nullptr;
    size_t size_ = 0;
    Compare comp_{};

    static int s_of(Node* n) {
        return n ? n->s : 0;
    }

    // 合并两棵左高树（递归只沿"右路径"下行）：
    // ① 保证 a 的根优先级不低于 b 的根（否则交换）；
    // ② 把 a 的右子树与 b 合并；
    // ③ 若交换后右子树 s 更大，左右互换，恢复左高性质；
    // ④ 重算 s。
    Node* meld_nodes(Node* a, Node* b) {
        if (a == nullptr) {
            return b;
        }
        if (b == nullptr) {
            return a;
        }
        if (comp_(b->value, a->value)) {
            std::swap(a, b);
        }
        a->right = meld_nodes(a->right, b);
        if (s_of(a->left) < s_of(a->right)) {
            std::swap(a->left, a->right);
        }
        a->s = 1 + s_of(a->right);  // 左高成立时 min 必为右子树
        return a;
    }

    // 迭代深拷贝：栈里放 (源节点, 新节点)，避免沿长左链递归
    static Node* clone(Node* other) {
        if (other == nullptr) {
            return nullptr;
        }
        Node* new_root = new Node{other->value, nullptr, nullptr, other->s};
        std::vector<std::pair<Node*, Node*>> st{{other, new_root}};
        while (!st.empty()) {
            auto [src, dst] = st.back();
            st.pop_back();
            if (src->left != nullptr) {
                dst->left = new Node{src->left->value, nullptr, nullptr, src->left->s};
                st.emplace_back(src->left, dst->left);
            }
            if (src->right != nullptr) {
                dst->right = new Node{src->right->value, nullptr, nullptr, src->right->s};
                st.emplace_back(src->right, dst->right);
            }
        }
        return new_root;
    }

    // 迭代析构：显式栈收集节点，防止链状树的递归析构撑爆栈
    void destroy() noexcept {
        if (root_ == nullptr) {
            return;
        }
        std::vector<Node*> st{root_};
        while (!st.empty()) {
            Node* n = st.back();
            st.pop_back();
            if (n->left != nullptr) {
                st.push_back(n->left);
            }
            if (n->right != nullptr) {
                st.push_back(n->right);
            }
            delete n;
        }
        root_ = nullptr;
        size_ = 0;
    }

    // 迭代核对全树：左高性质、s 值定义、优先级性质
    bool property_ok(Node* start) const {
        std::vector<Node*> st;
        if (start != nullptr) {
            st.push_back(start);
        }
        while (!st.empty()) {
            Node* n = st.back();
            st.pop_back();
            if (s_of(n->left) < s_of(n->right)) {
                return false;  // 违反左高
            }
            if (n->s != 1 + s_of(n->right)) {
                return false;  // s 值不符合定义
            }
            if (n->left != nullptr) {
                if (comp_(n->left->value, n->value)) {
                    return false;  // 孩子优先级反超
                }
                st.push_back(n->left);
            }
            if (n->right != nullptr) {
                if (comp_(n->right->value, n->value)) {
                    return false;
                }
                st.push_back(n->right);
            }
        }
        return true;
    }

public:
    LeftistTree() = default;

    explicit LeftistTree(const Compare& comp) : comp_(comp) {}

    LeftistTree(const LeftistTree& other)
        : root_(clone(other.root_)), size_(other.size_), comp_(other.comp_) {}

    LeftistTree(LeftistTree&& other) noexcept
        : root_(other.root_), size_(other.size_),
          comp_(std::move(other.comp_)) {
        other.root_ = nullptr;
        other.size_ = 0;
    }

    LeftistTree& operator=(const LeftistTree& other) {
        if (this != &other) {
            destroy();
            root_ = clone(other.root_);
            size_ = other.size_;
            comp_ = other.comp_;
        }
        return *this;
    }

    LeftistTree& operator=(LeftistTree&& other) noexcept {
        if (this != &other) {
            destroy();
            root_ = other.root_;
            size_ = other.size_;
            comp_ = std::move(other.comp_);
            other.root_ = nullptr;
            other.size_ = 0;
        }
        return *this;
    }

    ~LeftistTree() {
        destroy();
    }

    // 把 other 的全部节点并入本树；other 被掏空（节点所有权转移）。
    void meld(LeftistTree& other) {
        if (this == &other) {
            return;
        }
        root_ = meld_nodes(root_, other.root_);
        size_ += other.size_;
        other.root_ = nullptr;
        other.size_ = 0;
    }

    void push(const T& value) {
        Node* n = new Node{value, nullptr, nullptr, 1};
        root_ = meld_nodes(root_, n);
        ++size_;
    }

    const T& top() const {
        if (root_ == nullptr) {
            throw std::runtime_error("LeftistTree::top: tree is empty");
        }
        return root_->value;
    }

    void pop() {
        if (root_ == nullptr) {
            throw std::runtime_error("LeftistTree::pop: tree is empty");
        }
        Node* old = root_;
        root_ = meld_nodes(old->left, old->right);
        --size_;
        delete old;
    }

    int root_s() const {
        return s_of(root_);
    }

    size_t size() const {
        return size_;
    }

    bool empty() const {
        return root_ == nullptr;
    }

    // 全树逐条核对：左高性质、s 值定义、优先级性质。
    bool property_ok() const {
        return property_ok(root_);
    }
};

}  // namespace ds

#endif  // DS_LEFTIST_TREE_HPP
