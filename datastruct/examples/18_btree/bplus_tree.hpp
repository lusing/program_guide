#ifndef DS_BPLUS_TREE_HPP
#define DS_BPLUS_TREE_HPP

#include <cstddef>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// B+ 树（教学版，阶固定为 4：叶子至多 3 个数据键，内部至多 3 个路由键）。
//
// 与 B 树的关键差别：所有数据都在叶子，内部键只是路由副本；
// 叶子自左向右用 next 指针串成链表，支持范围扫描。
class BPlusTree {
public:
    BPlusTree() : root_(nullptr) {}

    BPlusTree(const BPlusTree& other) {
        root_ = clone(other.root_);
        relink_leaves(root_);  // 深拷贝后重建叶子链
    }

    BPlusTree(BPlusTree&& other) noexcept : root_(other.root_) {
        other.root_ = nullptr;
    }

    BPlusTree& operator=(const BPlusTree& other) {
        if (this != &other) {
            destroy(root_);
            root_ = clone(other.root_);
            relink_leaves(root_);
        }
        return *this;
    }

    BPlusTree& operator=(BPlusTree&& other) noexcept {
        if (this != &other) {
            destroy(root_);
            root_ = other.root_;
            other.root_ = nullptr;
        }
        return *this;
    }

    ~BPlusTree() { destroy(root_); }

    // 插入唯一键，重复键抛 invalid_argument。
    void insert(int key) {
        if (!root_) {
            root_ = new Node{true, {}, {}, nullptr};
            root_->keys.push_back(key);
            return;
        }
        // 记录从根到叶的路径，便于自底向上吸收分裂
        std::vector<Node*> path;
        Node* node = root_;
        while (!node->leaf) {
            path.push_back(node);
            size_t i = 0;
            while (i < node->keys.size() && node->keys[i] <= key) {
                ++i;
            }
            node = node->children[i];
        }

        size_t pos = 0;
        while (pos < node->keys.size() && node->keys[pos] < key) {
            ++pos;
        }
        if (pos < node->keys.size() && node->keys[pos] == key) {
            throw std::invalid_argument("BPlusTree::insert: duplicate key");
        }
        node->keys.insert(node->keys.begin() + static_cast<std::ptrdiff_t>(pos), key);

        if (static_cast<int>(node->keys.size()) <= MAX_KEYS) {
            return;  // 未溢出
        }

        // 叶分裂：[a,b | c,d]，右叶首键 c 复制上推
        Node* right = split_leaf(node);
        int promoted = right->keys.front();

        // 沿路径自底向上吸收分裂
        for (auto it = path.rbegin(); it != path.rend(); ++it) {
            Node* parent = *it;
            size_t i = 0;
            while (i < parent->keys.size() && parent->keys[i] < promoted) {
                ++i;
            }
            parent->keys.insert(parent->keys.begin() + static_cast<std::ptrdiff_t>(i), promoted);
            parent->children.insert(parent->children.begin() + static_cast<std::ptrdiff_t>(i + 1),
                                   right);
            if (static_cast<int>(parent->keys.size()) <= MAX_KEYS) {
                return;
            }
            // 内部节点也分裂：中间键真正上推（不留在右节点）
            auto [up_key, up_right] = split_internal(parent);
            promoted = up_key;
            right = up_right;
        }

        // 一路分裂到根：新根
        Node* new_root = new Node{false, {}, {}, nullptr};
        new_root->keys.push_back(promoted);
        new_root->children = {root_, right};
        root_ = new_root;
    }

    [[nodiscard]] bool contains(int key) const {
        const Node* leaf = find_leaf(key);
        if (!leaf) {
            return false;
        }
        for (int k : leaf->keys) {
            if (k == key) {
                return true;
            }
        }
        return false;
    }

    // 闭区间 [lo, hi] 范围查询：定位 lo 所在叶，沿叶链扫描到 hi。
    [[nodiscard]] std::vector<int> range(int lo, int hi) const {
        std::vector<int> out;
        if (lo > hi) {
            return out;
        }
        const Node* leaf = find_leaf(lo);
        while (leaf) {
            for (int k : leaf->keys) {
                if (k < lo) {
                    continue;
                }
                if (k > hi) {
                    return out;
                }
                out.push_back(k);
            }
            leaf = leaf->next;
        }
        return out;
    }

private:
    static constexpr int MAX_KEYS = 3;  // 每节点最多 3 键

    struct Node {
        bool leaf;
        std::vector<int> keys;
        std::vector<Node*> children;  // 内部节点
        Node* next = nullptr;        // 叶链
    };

    Node* root_;

    const Node* find_leaf(int key) const {
        const Node* node = root_;
        if (!node) {
            return nullptr;
        }
        while (!node->leaf) {
            size_t i = 0;
            // 路由规则：相等键也要向右走——数据副本在右子树
            while (i < node->keys.size() && node->keys[i] <= key) {
                ++i;
            }
            node = node->children[i];
        }
        return node;
    }

    static Node* split_leaf(Node* node) {
        Node* right = new Node{true, {}, {}, nullptr};
        // 4 键对半：左 2 右 2
        right->keys.assign(node->keys.begin() + 2, node->keys.end());
        node->keys.resize(2);
        right->next = node->next;
        node->next = right;
        return right;
    }

    static std::pair<int, Node*> split_internal(Node* node) {
        Node* right = new Node{false, {}, {}, nullptr};
        // 4 个路由键：下标 [0,1] 留左，keys[2] 上推，[3] 进右
        const int promoted = node->keys[2];
        right->keys = {node->keys[3]};
        right->children.assign(node->children.begin() + 3, node->children.end());
        node->keys.resize(2);
        node->children.resize(3);
        return {promoted, right};
    }

    static Node* clone(const Node* node) {
        if (!node) {
            return nullptr;
        }
        Node* copy = new Node{node->leaf, {}, {}, nullptr};
        copy->keys = node->keys;
        copy->next = nullptr;  // 由 relink_leaves 统一重建，不复制指针
        for (const Node* child : node->children) {
            copy->children.push_back(clone(child));
        }
        return copy;
    }

    // 中序收集叶子并重新串链。
    static void relink_leaves(Node* node) {
        if (!node) {
            return;
        }
        std::vector<Node*> leaves;
        gather_leaves(node, leaves);
        for (size_t i = 0; i < leaves.size(); ++i) {
            leaves[i]->next = (i + 1 < leaves.size()) ? leaves[i + 1] : nullptr;
        }
    }

    static void gather_leaves(Node* node, std::vector<Node*>& leaves) {
        if (node->leaf) {
            leaves.push_back(node);
            return;
        }
        for (Node* child : node->children) {
            gather_leaves(child, leaves);
        }
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

#endif  // DS_BPLUS_TREE_HPP
