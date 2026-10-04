#ifndef DS_B_TREE_HPP
#define DS_B_TREE_HPP

#include <concepts>
#include <cstddef>
#include <optional>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// m 阶 B 树（默认 m=3，即 2-3 树）。
//
// 节点键数约定：除根外每个节点至少 ceil(m/2)-1 个键、至多 m-1 个键；
// 内部节点的孩子数 = 键数 + 1；所有叶子在同一深度。
// m=3 时非根节点 1..2 个键；m=4 时 1..3 个键（2-3-4 树）。
template <std::totally_ordered K>
class BTree {
public:
    explicit BTree(int order = 3) : root_(nullptr), order_(order) {
        if (order < 3) {
            throw std::invalid_argument("BTree: order must be >= 3");
        }
    }

    BTree(const BTree& other) : root_(clone(other.root_)), order_(other.order_) {}

    BTree(BTree&& other) noexcept : root_(other.root_), order_(other.order_) {
        other.root_ = nullptr;
    }

    BTree& operator=(const BTree& other) {
        if (this != &other) {
            destroy(root_);
            order_ = other.order_;
            root_ = clone(other.root_);
        }
        return *this;
    }

    BTree& operator=(BTree&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            order_ = other.order_;
            other.root_ = nullptr;
        }
        return *this;
    }

    ~BTree() { destroy(root_); }

    // 插入唯一键。重复键属于编程错误，抛 invalid_argument。
    void insert(const K& key) {
        if (!root_) {
            root_ = new Node{true, {}, {}};
            root_->keys.push_back(key);
            return;
        }
        auto split = insert_rec(root_, key);
        if (split) {
            // 根分裂：新根只有一个提升键、两个孩子
            Node* new_root = new Node{false, {}, {}};
            new_root->keys.push_back(split->promoted);
            new_root->children = {root_, split->right};
            root_ = new_root;
        }
    }

    // 沿树查找键是否存在。
    [[nodiscard]] bool contains(const K& key) const {
        const Node* node = root_;
        while (node) {
            size_t i = 0;
            while (i < node->keys.size() && node->keys[i] < key) {
                ++i;
            }
            if (i < node->keys.size() && !(key < node->keys[i]) && !(node->keys[i] < key)) {
                return true;
            }
            node = node->leaf ? nullptr : node->children[i];
        }
        return false;
    }

    // 全部键（中序遍历节点键，输出恰为升序）。
    [[nodiscard]] std::vector<K> all_keys() const {
        std::vector<K> out;
        collect(root_, out);
        return out;
    }

    // 根节点当前的键（用于观察各次分裂后根的形状）。
    [[nodiscard]] std::vector<K> root_keys() const {
        return root_ ? root_->keys : std::vector<K>{};
    }

private:
    struct Node {
        bool leaf;
        std::vector<K> keys;
        std::vector<Node*> children;  // 仅内部节点使用
    };

    struct Split {
        K promoted;
        Node* right;
    };

    Node* root_;
    int order_;

    // 在节点（及其子树）插入。若节点最终分裂，返回提升键与新右兄弟。
    std::optional<Split> insert_rec(Node* node, const K& key) {
        // 先在节点键中定位
        size_t pos = 0;
        while (pos < node->keys.size() && node->keys[pos] < key) {
            ++pos;
        }
        if (pos < node->keys.size() && !(key < node->keys[pos]) && !(node->keys[pos] < key)) {
            throw std::invalid_argument("BTree::insert: duplicate key");
        }

        if (node->leaf) {
            node->keys.insert(node->keys.begin() + static_cast<std::ptrdiff_t>(pos), key);
        } else {
            auto child_split = insert_rec(node->children[pos], key);
            if (!child_split) {
                return std::nullopt;
            }
            // 把子节点的提升键与右兄弟吸收进本节点
            node->keys.insert(node->keys.begin() + static_cast<std::ptrdiff_t>(pos),
                              child_split->promoted);
            node->children.insert(node->children.begin() + static_cast<std::ptrdiff_t>(pos + 1),
                                  child_split->right);
        }

        if (static_cast<int>(node->keys.size()) < order_) {
            return std::nullopt;  // 未超过 m-1：无需分裂
        }
        return split_node(node);
    }

    // 节点已有 m 个键，按中位数分裂。
    Split split_node(Node* node) {
        const int mid = order_ / 2;  // m=3→1；m=4→2
        Node* right = new Node{node->leaf, {}, {}};

        right->keys.assign(node->keys.begin() + static_cast<std::ptrdiff_t>(mid + 1),
                           node->keys.end());
        if (!node->leaf) {
            right->children.assign(node->children.begin() + static_cast<std::ptrdiff_t>(mid + 1),
                                   node->children.end());
            node->children.resize(static_cast<size_t>(mid + 1));
        }
        K promoted = std::move(node->keys[static_cast<size_t>(mid)]);
        node->keys.resize(static_cast<size_t>(mid));
        return {std::move(promoted), right};
    }

    static void collect(const Node* node, std::vector<K>& out) {
        if (!node) {
            return;
        }
        for (size_t i = 0; i < node->keys.size(); ++i) {
            if (!node->leaf) {
                collect(node->children[i], out);
            }
            out.push_back(node->keys[i]);
        }
        if (!node->leaf) {
            collect(node->children[node->keys.size()], out);
        }
    }

    static Node* clone(const Node* node) {
        if (!node) {
            return nullptr;
        }
        Node* copy = new Node{node->leaf, node->keys, {}};
        copy->children.reserve(node->children.size());
        for (const Node* child : node->children) {
            copy->children.push_back(clone(child));
        }
        return copy;
    }

    static void destroy(Node* node) {
        if (!node) {
            return;
        }
        for (Node* child : node->children) {
            destroy(child);
        }
        delete node;
    }
};

}  // namespace ds

#endif  // DS_B_TREE_HPP
