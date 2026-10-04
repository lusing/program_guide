#ifndef DS_RED_BLACK_HPP
#define DS_RED_BLACK_HPP

#include <concepts>
#include <cstddef>
#include <optional>
#include <vector>

namespace ds {

// 红黑树（本实现仅插入 + 合法性检查）。性质：
// ① 节点红或黑；② 根黑；③ 空子树按黑处理；
// ④ 红节点的两个孩子必黑（无连续红）；⑤ 任一节点到叶的路径黑节点数相同。
template <std::totally_ordered K, std::copyable V>
class RedBlackTree {
    struct Node {
        K key;
        V value;
        Node* left;
        Node* right;
        Node* parent;
        bool red;
    };

    Node* root_ = nullptr;

    static Node* make_node(const K& k, const V& v) {
        return new Node{k, v, nullptr, nullptr, nullptr, true};
    }

    void rotate_left(Node* x) {
        Node* y = x->right;
        x->right = y->left;
        if (y->left) {
            y->left->parent = x;
        }
        y->parent = x->parent;
        if (!x->parent) {
            root_ = y;
        } else if (x == x->parent->left) {
            x->parent->left = y;
        } else {
            x->parent->right = y;
        }
        y->left = x;
        x->parent = y;
    }

    void rotate_right(Node* y) {
        Node* x = y->left;
        y->left = x->right;
        if (x->right) {
            x->right->parent = y;
        }
        x->parent = y->parent;
        if (!y->parent) {
            root_ = x;
        } else if (y == y->parent->left) {
            y->parent->left = x;
        } else {
            y->parent->right = x;
        }
        x->right = y;
        y->parent = x;
    }

    void insert_fixup(Node* z) {
        while (z->parent && z->parent->red) {
            Node* gp = z->parent->parent;
            if (z->parent == gp->left) {
                Node* uncle = gp->right;
                if (uncle && uncle->red) {
                    z->parent->red = false;
                    uncle->red = false;
                    gp->red = true;
                    z = gp;
                } else {
                    if (z == z->parent->right) {
                        z = z->parent;
                        rotate_left(z);
                        gp = z->parent;
                    }
                    z->parent->red = false;
                    gp->red = true;
                    rotate_right(gp);
                }
            } else {
                Node* uncle = gp->left;
                if (uncle && uncle->red) {
                    z->parent->red = false;
                    uncle->red = false;
                    gp->red = true;
                    z = gp;
                } else {
                    if (z == z->parent->left) {
                        z = z->parent;
                        rotate_right(z);
                        gp = z->parent;
                    }
                    z->parent->red = false;
                    gp->red = true;
                    rotate_left(gp);
                }
            }
        }
        root_->red = false;
    }

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

    // 返回路径黑高度（含本节点不含空子）；不一致或连续红返回 -1。
    static int black_height_checked(const Node* n, bool& ok) {
        if (!n) {
            return 0;
        }
        if (n->red && ((n->left && n->left->red) || (n->right && n->right->red))) {
            ok = false;
        }
        int lb = black_height_checked(n->left, ok);
        int rb = black_height_checked(n->right, ok);
        if (lb != rb) {
            ok = false;
        }
        return (n->red ? 0 : 1) + lb;
    }

public:
    RedBlackTree() = default;

    ~RedBlackTree() { destroy(root_); }

    RedBlackTree(const RedBlackTree&) = delete;
    RedBlackTree& operator=(const RedBlackTree&) = delete;
    RedBlackTree(RedBlackTree&& other) noexcept : root_(other.root_) {
        other.root_ = nullptr;
    }
    RedBlackTree& operator=(RedBlackTree&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            other.root_ = nullptr;
        }
        return *this;
    }

    void insert(const K& k, const V& v) {
        Node* parent = nullptr;
        Node* cur = root_;
        while (cur) {
            parent = cur;
            if (k < cur->key) {
                cur = cur->left;
            } else if (cur->key < k) {
                cur = cur->right;
            } else {
                cur->value = v;
                return;
            }
        }
        Node* z = make_node(k, v);
        z->parent = parent;
        if (!parent) {
            root_ = z;
        } else if (k < parent->key) {
            parent->left = z;
        } else {
            parent->right = z;
        }
        insert_fixup(z);
    }

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

    bool rb_legal() const {
        if (!root_) {
            return true;
        }
        if (root_->red) {
            return false;
        }
        bool ok = true;
        black_height_checked(root_, ok);
        return ok;
    }

    K root_key() const { return root_->key; }

    int black_height() const {
        bool ok = true;
        return black_height_checked(root_, ok);
    }

    struct Colored {
        K key;
        char color;  // 'R' / 'B'
    };

    // 前序带颜色，作为结构的可打印指纹。
    std::vector<Colored> preorder_colored() const {
        std::vector<Colored> out;
        std::vector<const Node*> st;
        if (root_) {
            st.push_back(root_);
        }
        while (!st.empty()) {
            const Node* n = st.back();
            st.pop_back();
            out.push_back({n->key, n->red ? 'R' : 'B'});
            if (n->right) {
                st.push_back(n->right);
            }
            if (n->left) {
                st.push_back(n->left);
            }
        }
        return out;
    }
};

}  // namespace ds

#endif  // DS_RED_BLACK_HPP
