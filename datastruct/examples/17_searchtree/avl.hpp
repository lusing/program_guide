#ifndef DS_AVL_HPP
#define DS_AVL_HPP

#include <algorithm>
#include <concepts>
#include <cstddef>
#include <optional>
#include <vector>

namespace ds {

// AVL 树：任何节点左右子树高度差不超过 1。每节点额外存高度（空树 0）。
template <std::totally_ordered K, std::copyable V>
class AVLTree {
    struct Node {
        K key;
        V value;
        Node* left;
        Node* right;
        int height;
    };

    Node* root_ = nullptr;

    static int h(const Node* n) { return n ? n->height : 0; }

    static int balance(const Node* n) {
        return n ? h(n->left) - h(n->right) : 0;
    }

    static void update(Node* n) {
        n->height = 1 + std::max(h(n->left), h(n->right));
    }

    static Node* make_node(const K& k, const V& v) {
        return new Node{k, v, nullptr, nullptr, 1};
    }

    // 右单旋（LL）：失衡节点左孩子上位。
    static Node* rotate_right(Node* y) {
        Node* x = y->left;
        Node* t2 = x->right;
        x->right = y;
        y->left = t2;
        update(y);
        update(x);
        return x;
    }

    // 左单旋（RR）。
    static Node* rotate_left(Node* x) {
        Node* y = x->right;
        Node* t2 = y->left;
        y->left = x;
        x->right = t2;
        update(x);
        update(y);
        return y;
    }

    // 插入后自底向上更新高度并按四情形恢复平衡。
    static Node* insert_node(Node* node, const K& k, const V& v) {
        if (!node) {
            return make_node(k, v);
        }
        if (k < node->key) {
            node->left = insert_node(node->left, k, v);
        } else if (node->key < k) {
            node->right = insert_node(node->right, k, v);
        } else {
            node->value = v;
            return node;
        }
        update(node);
        const int bf = balance(node);
        if (bf > 1) {
            if (k < node->left->key) {
                return rotate_right(node);          // LL
            }
            node->left = rotate_left(node->left);   // LR
            return rotate_right(node);
        }
        if (bf < -1) {
            if (node->right->key < k) {
                return rotate_left(node);           // RR
            }
            node->right = rotate_right(node->right);  // RL
            return rotate_left(node);
        }
        return node;
    }

    static Node* min_node(Node* node) {
        while (node->left) {
            node = node->left;
        }
        return node;
    }

    // 删除后同样自底向上恢复；删除场景下须看孩子的平衡因子决定单旋/双旋。
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
            Node* succ = min_node(node->right);
            node->key = succ->key;
            node->value = succ->value;
            bool ignored = false;
            node->right = erase_node(node->right, succ->key, ignored);
        }
        update(node);
        const int bf = balance(node);
        if (bf > 1) {
            if (balance(node->left) >= 0) {
                return rotate_right(node);              // LL
            }
            node->left = rotate_left(node->left);       // LR
            return rotate_right(node);
        }
        if (bf < -1) {
            if (balance(node->right) <= 0) {
                return rotate_left(node);               // RR
            }
            node->right = rotate_right(node->right);    // RL
            return rotate_left(node);
        }
        return node;
    }

    static Node* clone(Node* node) {
        if (!node) {
            return nullptr;
        }
        Node* c = make_node(node->key, node->value);
        c->height = node->height;
        c->left = clone(node->left);
        c->right = clone(node->right);
        return c;
    }

    // 显式栈释放（节点虽平衡，保持与其余实现一致的稳妥做法）。
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

public:
    AVLTree() = default;

    ~AVLTree() { destroy(root_); }

    AVLTree(const AVLTree& other) : root_(clone(other.root_)) {}

    AVLTree(AVLTree&& other) noexcept : root_(other.root_) {
        other.root_ = nullptr;
    }

    AVLTree& operator=(const AVLTree& other) {
        if (this != &other) {
            destroy(root_);
            root_ = clone(other.root_);
        }
        return *this;
    }

    AVLTree& operator=(AVLTree&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            other.root_ = nullptr;
        }
        return *this;
    }

    void insert(const K& k, const V& v) { root_ = insert_node(root_, k, v); }

    std::optional<V> search(const K& k) const {
        Node* cur = root_;
        while (cur) {
            if (k < cur->key) {
                cur = cur->left;
            } else if (cur->key < k) {
                cur = cur->right;
            } else {
                return cur->value;
            }
        }
        return std::nullopt;
    }

    bool erase(const K& k) {
        bool removed = false;
        root_ = erase_node(root_, k, removed);
        return removed;
    }

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

    // 前序的结构指纹：键 + 高度 + 平衡因子，供精确断言。
    struct Detail {
        K key;
        int height;
        int bf;
    };

    std::vector<Detail> preorder_detail() const {
        std::vector<Detail> out;
        std::vector<const Node*> st;
        if (root_) {
            st.push_back(root_);
        }
        while (!st.empty()) {
            const Node* n = st.back();
            st.pop_back();
            out.push_back({n->key, n->height, balance(n)});
            if (n->right) {
                st.push_back(n->right);
            }
            if (n->left) {
                st.push_back(n->left);
            }
        }
        return out;
    }

    int height() const { return h(root_); }
};

}  // namespace ds

#endif  // DS_AVL_HPP
