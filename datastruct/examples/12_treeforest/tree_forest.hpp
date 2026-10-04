#ifndef DS_TREE_FOREST_HPP
#define DS_TREE_FOREST_HPP

#include <concepts>
#include <cstddef>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 树/森林：长子-兄弟（first-child / next-sibling）表示。
//
// 一个 Node 只挂两条线索：first_child 指向第一个孩子，next_sibling 指向
// 右边的兄弟。根节点也可以有 next_sibling —— 它指向森林里的下一棵树的根。
// 于是"一棵树"与"一片森林"在表示上统一：单根即一棵树，根串成链即森林。
template <std::copyable T>
class Tree {
public:
    struct Node {
        T data;
        Node* first_child = nullptr;
        Node* next_sibling = nullptr;
    };

    Tree() = default;

    // 接管一条已按长子-兄弟规则构造好的节点链（转换函数使用）。
    static Tree adopt_root(Node* root) {
        Tree t;
        t.root_ = root;
        return t;
    }

    ~Tree() { destroy(root_); }

    Tree(const Tree& other) : root_(clone(other.root_)) {}

    Tree(Tree&& other) noexcept : root_(other.root_) { other.root_ = nullptr; }

    Tree& operator=(const Tree& other) {
        if (this != &other) {
            Node* p = clone(other.root_);
            destroy(root_);
            root_ = p;
        }
        return *this;
    }

    Tree& operator=(Tree&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            other.root_ = nullptr;
        }
        return *this;
    }

    // 向森林再添一棵树（根）。新根接到根链末端，保证先添的树排在前面。
    void add_root(const T& value) {
        Node* node = new Node{value};
        if (root_ == nullptr) {
            root_ = node;
        } else {
            Node* tail = root_;
            while (tail->next_sibling != nullptr) {
                tail = tail->next_sibling;
            }
            tail->next_sibling = node;
        }
    }

    // 把 child 挂为 parent 的孩子。按值在全森林中查找 parent；
    // 找不到属于编程错误，抛异常。新孩子接到已有孩子链末端，
    // 于是孩子次序与 add_child 的调用次序一致 —— 输出确定。
    void add_child(const T& parent, const T& child) {
        Node* p = find(root_, parent);
        if (p == nullptr) {
            throw std::runtime_error{"Tree::add_child: parent not found"};
        }
        Node* node = new Node{child};
        if (p->first_child == nullptr) {
            p->first_child = node;
        } else {
            Node* tail = p->first_child;
            while (tail->next_sibling != nullptr) {
                tail = tail->next_sibling;
            }
            tail->next_sibling = node;
        }
    }

    // 先序：先访问根，再依次先序遍历每棵子树；森林就逐棵树进行。
    [[nodiscard]] std::vector<T> preorder() const {
        std::vector<T> out;
        preorder_(root_, out);
        return out;
    }

    [[nodiscard]] Node* root() const noexcept { return root_; }

private:
    static Node* clone(const Node* n) {
        if (n == nullptr) {
            return nullptr;
        }
        Node* p = new Node{n->data};
        p->first_child = clone(n->first_child);
        p->next_sibling = clone(n->next_sibling);
        return p;
    }

    static void destroy(Node* n) {
        while (n != nullptr) {
            destroy(n->first_child);
            Node* next = n->next_sibling;  // 先记下兄弟再释放，避免悬空
            delete n;
            n = next;
        }
    }

    static Node* find(Node* n, const T& value) {
        while (n != nullptr) {
            if (n->data == value) {
                return n;
            }
            if (Node* hit = find(n->first_child, value)) {
                return hit;
            }
            n = n->next_sibling;
        }
        return nullptr;
    }

    static void preorder_(const Node* n, std::vector<T>& out) {
        while (n != nullptr) {
            out.push_back(n->data);
            preorder_(n->first_child, out);  // 先走完孩子
            n = n->next_sibling;            // 再走右边的兄弟/下一棵树
        }
    }

    Node* root_ = nullptr;
};

// 森林转换所用的二叉树表示（最小定义，不依赖第 11 章的 BinaryTree）。
// 左孩子 = 原节点的第一个孩子；右孩子 = 原节点右边的兄弟。
template <std::copyable T>
class BinTreeRep {
public:
    struct BNode {
        T data;
        BNode* left = nullptr;
        BNode* right = nullptr;
    };

    BinTreeRep() = default;

    explicit BinTreeRep(BNode* root) : root_(root) {}

    ~BinTreeRep() { destroy(root_); }

    BinTreeRep(const BinTreeRep& other) : root_(clone(other.root_)) {}

    BinTreeRep(BinTreeRep&& other) noexcept : root_(other.root_) {
        other.root_ = nullptr;
    }

    BinTreeRep& operator=(const BinTreeRep& other) {
        if (this != &other) {
            BNode* p = clone(other.root_);
            destroy(root_);
            root_ = p;
        }
        return *this;
    }

    BinTreeRep& operator=(BinTreeRep&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            other.root_ = nullptr;
        }
        return *this;
    }

    [[nodiscard]] std::vector<T> preorder() const {
        std::vector<T> out;
        preorder_(root_, out);
        return out;
    }

    [[nodiscard]] BNode* root() const noexcept { return root_; }

private:
    static BNode* clone(const BNode* n) {
        if (n == nullptr) {
            return nullptr;
        }
        BNode* p = new BNode{n->data};
        p->left = clone(n->left);
        p->right = clone(n->right);
        return p;
    }

    static void destroy(BNode* n) {
        if (n == nullptr) {
            return;
        }
        destroy(n->left);
        destroy(n->right);
        delete n;
    }

    static void preorder_(const BNode* n, std::vector<T>& out) {
        if (n == nullptr) {
            return;
        }
        out.push_back(n->data);
        preorder_(n->left, out);
        preorder_(n->right, out);
    }

    BNode* root_ = nullptr;
};

// 森林 → 二叉树：逐节点照两条映射规则构造
//   左子 ← first_child，右子 ← next_sibling（根链上的下一棵树也经右子进入）。
template <std::copyable T>
BinTreeRep<T> to_binary_tree(const Tree<T>& forest) {
    using BNode = typename BinTreeRep<T>::BNode;
    auto convert = [](auto&& self, const typename Tree<T>::Node* n) -> BNode* {
        if (n == nullptr) {
            return nullptr;
        }
        BNode* b = new BNode{n->data};
        b->left = self(self, n->first_child);
        b->right = self(self, n->next_sibling);
        return b;
    };
    return BinTreeRep<T>{convert(convert, forest.root())};
}

// 二叉树 → 森林：同一组映射的逆操作
//   left 还原成第一个孩子，right 还原成兄弟。结构同形，映射直接反过来。
template <std::copyable T>
Tree<T> from_binary_tree(const BinTreeRep<T>& bin) {
    auto invert = [](auto&& self, const typename BinTreeRep<T>::BNode* b) ->
                  typename Tree<T>::Node* {
        if (b == nullptr) {
            return nullptr;
        }
        auto* n = new typename Tree<T>::Node{b->data};
        n->first_child = self(self, b->left);
        n->next_sibling = self(self, b->right);
        return n;
    };
    return Tree<T>::adopt_root(invert(invert, bin.root()));
}

}  // namespace ds

#endif  // DS_TREE_FOREST_HPP
