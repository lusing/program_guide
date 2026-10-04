#ifndef DS_BST_HPP
#define DS_BST_HPP

#include <concepts>
#include <cstddef>
#include <optional>
#include <vector>

namespace ds {

// 二叉搜索树（无平衡）。键满足：左子树键 < 本键 < 右子树键。
// 重复插入同键时更新值，不新增节点。
template <std::totally_ordered K, std::copyable V>
class BSTree {
protected:
    struct Node {
        K key;
        V value;
        Node* left;
        Node* right;
    };

    Node* root_ = nullptr;

    static Node* make_node(const K& k, const V& v) {
        return new Node{k, v, nullptr, nullptr};
    }

    // 深拷贝：逐节点重建，结构与入参完全相同。
    static Node* clone(const Node* node) {
        if (!node) {
            return nullptr;
        }
        Node* c = make_node(node->key, node->value);
        c->left = clone(node->left);
        c->right = clone(node->right);
        return c;
    }

    // 显式栈释放，避免退化成链时递归析构撑爆栈。
    static void destroy(Node* root) {
        std::vector<Node*> st;
        Node* cur = root;
        while (cur || !st.empty()) {
            while (cur) {
                st.push_back(cur);
                cur = cur->left;
            }
            cur = st.back();
            st.pop_back();
            Node* right = cur->right;
            delete cur;
            cur = right;
        }
    }

    static const Node* find_node(const Node* node, const K& k) {
        while (node) {
            if (k < node->key) {
                node = node->left;
            } else if (node->key < k) {
                node = node->right;
            } else {
                return node;
            }
        }
        return nullptr;
    }

    // 删除的递归实现：返回删后（子）树根。
    // removed 仅在真正删掉一个节点时置真，并保持真值传递。
    static Node* erase_node(Node* node, const K& k, bool& removed) {
        if (!node) {
            return nullptr;
        }
        if (k < node->key) {
            node->left = erase_node(node->left, k, removed);
        } else if (node->key < k) {
            node->right = erase_node(node->right, k, removed);
        } else {
            removed = true;
            if (!node->left) {
                Node* r = node->right;
                delete node;
                return r;
            }
            if (!node->right) {
                Node* l = node->left;
                delete node;
                return l;
            }
            // 双子：取右子树最小键（后继）顶替，再删除该后继。
            Node* succ = node->right;
            while (succ->left) {
                succ = succ->left;
            }
            node->key = succ->key;
            node->value = succ->value;
            bool ignored = false;
            node->right = erase_node(node->right, succ->key, ignored);
        }
        return node;
    }

public:
    BSTree() = default;

    ~BSTree() { destroy(root_); }

    BSTree(const BSTree& other) : root_(clone(other.root_)) {}

    BSTree(BSTree&& other) noexcept : root_(other.root_) {
        other.root_ = nullptr;
    }

    BSTree& operator=(const BSTree& other) {
        if (this != &other) {
            destroy(root_);
            root_ = clone(other.root_);
        }
        return *this;
    }

    BSTree& operator=(BSTree&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            other.root_ = nullptr;
        }
        return *this;
    }

    void insert(const K& k, const V& v) {
        if (!root_) {
            root_ = make_node(k, v);
            return;
        }
        Node* cur = root_;
        for (;;) {
            if (k < cur->key) {
                if (!cur->left) {
                    cur->left = make_node(k, v);
                    return;
                }
                cur = cur->left;
            } else if (cur->key < k) {
                if (!cur->right) {
                    cur->right = make_node(k, v);
                    return;
                }
                cur = cur->right;
            } else {
                cur->value = v;  // 键已存在：更新值
                return;
            }
        }
    }

    std::optional<V> search(const K& k) const {
        const Node* n = find_node(root_, k);
        return n ? std::optional<V>(n->value) : std::nullopt;
    }

    bool erase(const K& k) {
        bool removed = false;
        root_ = erase_node(root_, k, removed);
        return removed;
    }

    bool contains(const K& k) const { return find_node(root_, k) != nullptr; }

    bool empty() const { return root_ == nullptr; }

    // 中序收集即按键升序。
    std::vector<K> keys_sorted() const {
        std::vector<K> keys;
        std::vector<const Node*> st;
        const Node* cur = root_;
        while (cur || !st.empty()) {
            while (cur) {
                st.push_back(cur);
                cur = cur->left;
            }
            cur = st.back();
            st.pop_back();
            keys.push_back(cur->key);
            cur = cur->right;
        }
        return keys;
    }
};

}  // namespace ds

#endif  // DS_BST_HPP
