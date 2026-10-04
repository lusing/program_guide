#ifndef DS_SKIP_LIST_HPP
#define DS_SKIP_LIST_HPP

#include <array>
#include <concepts>
#include <cstddef>
#include <optional>
#include <random>
#include <utility>
#include <vector>

namespace ds {

// 跳表：在有序链表之上"掷硬币"加层。每层都是一条有序链表，
// 查找时从最高层往下走，一次跨越大量节点 —— 期望 O(log n)。
//
// 不变量：
//  1) 每层 forward 指针构成的链严格按 key 升序，且是最底层链的子序列；
//  2) 同一 key 至多一个节点（insert 对已存在键只改值）；
//  3) 每个节点的层数在插入时由固定种子的掷硬币决定，之后不再改变。
template <std::totally_ordered K, std::copyable V>
class SkipList {
public:
    static constexpr int max_level = 16;

    SkipList() : head_(new Node(K{}, V{}, max_level)) {}

    SkipList(const SkipList& other) : SkipList() {
        for (const Node* q = other.head_->forward[0]; q != nullptr; q = q->forward[0]) {
            clone_with_level(q->key, q->value, static_cast<int>(q->forward.size()));
        }
    }

    SkipList(SkipList&& other) noexcept
        : head_(other.head_), level_(other.level_), size_(other.size_) {
        other.head_ = new Node(K{}, V{}, max_level);
        other.level_ = 0;
        other.size_ = 0;
    }

    SkipList& operator=(const SkipList&) = delete;
    SkipList& operator=(SkipList&&) = delete;

    ~SkipList() {
        Node* p = head_;
        while (p != nullptr) {
            Node* nxt = p->forward[0];
            delete p;
            p = nxt;
        }
    }

    // 插入或更新（upsert）：键已存在时只改值，节点层数不变。
    void insert(const K& key, const V& value) {
        std::array<Node*, max_level> update{};
        update.fill(head_);  // 高于当前层数的位置，前驱就是哨兵
        Node* cur = head_;
        for (int lvl = level_; lvl >= 0; --lvl) {
            while (cur->forward[lvl] != nullptr && cur->forward[lvl]->key < key) {
                cur = cur->forward[lvl];
            }
            update[static_cast<size_t>(lvl)] = cur;
        }
        Node* below = cur->forward[0];
        if (below != nullptr && !(key < below->key)) {
            below->value = value;  // 键已存在
            return;
        }
        const int lvl = random_level();
        auto* node = new Node(key, value, lvl + 1);
        for (int i = 0; i <= lvl; ++i) {
            node->forward[i] = update[i]->forward[i];
            update[i]->forward[i] = node;
        }
        if (lvl > level_) {
            level_ = lvl;
        }
        ++size_;
    }

    [[nodiscard]] std::optional<V> get(const K& key) const {
        const Node* cur = head_;
        for (int lvl = level_; lvl >= 0; --lvl) {
            while (cur->forward[lvl] != nullptr && cur->forward[lvl]->key < key) {
                cur = cur->forward[lvl];
            }
        }
        const Node* cand = cur->forward[0];
        if (cand != nullptr && !(key < cand->key)) {
            return cand->value;
        }
        return std::nullopt;
    }

    bool erase(const K& key) {
        std::array<Node*, max_level> update{};
        Node* cur = head_;
        for (int lvl = level_; lvl >= 0; --lvl) {
            while (cur->forward[lvl] != nullptr && cur->forward[lvl]->key < key) {
                cur = cur->forward[lvl];
            }
            update[static_cast<size_t>(lvl)] = cur;
        }
        Node* victim = cur->forward[0];
        if (victim == nullptr || key < victim->key) {
            return false;
        }
        for (int i = 0; i <= level_; ++i) {
            if (update[i]->forward[i] != victim) {
                break;  // 更高层没有这个节点
            }
            update[i]->forward[i] = victim->forward[i];
        }
        delete victim;
        while (level_ > 0 && head_->forward[level_] == nullptr) {
            --level_;
        }
        --size_;
        return true;
    }

    [[nodiscard]] bool contains(const K& key) const {
        return get(key).has_value();
    }

    [[nodiscard]] std::vector<std::pair<K, V>> sorted_entries() const {
        std::vector<std::pair<K, V>> out;
        for (const Node* p = head_->forward[0]; p != nullptr; p = p->forward[0]) {
            out.emplace_back(p->key, p->value);
        }
        return out;
    }

    [[nodiscard]] size_t size() const noexcept { return size_; }
    [[nodiscard]] int level() const noexcept { return level_; }

    // 全部节点的层数之和 —— 用来在示例中观察"掷硬币"的确定性。
    [[nodiscard]] size_t total_levels() const {
        size_t sum = 0;
        for (const Node* p = head_->forward[0]; p != nullptr; p = p->forward[0]) {
            sum += p->forward.size();
        }
        return sum;
    }

private:
    struct Node {
        K key;
        V value;
        std::vector<Node*> forward;
        Node(const K& k, const V& v, int levels)
            : key(k), value(v), forward(static_cast<size_t>(levels), nullptr) {}
    };

    // 几何分布：连续掷出正面（0.5 概率）就加一层；与 n 无关，期望 2 层。
    int random_level() {
        int lvl = 0;
        while (lvl + 1 < max_level && rng_() % 2 == 0) {
            ++lvl;
        }
        return lvl;
    }

    // 拷贝构造专用：连同层数一起复制（不重新掷硬币）。
    void clone_with_level(const K& key, const V& value, int levels) {
        std::array<Node*, max_level> update{};
        update.fill(head_);  // 高于当前层数的位置，前驱就是哨兵
        for (int lvl = level_; lvl >= 0; --lvl) {
            Node* cur = head_;
            while (cur->forward[lvl] != nullptr) {
                cur = cur->forward[lvl];  // 按底层顺序复制：新键总是最大，走到该层尾
            }
            update[static_cast<size_t>(lvl)] = cur;
        }
        auto* node = new Node(key, value, levels);
        for (int i = 0; i < levels; ++i) {
            node->forward[i] = update[i]->forward[i];
            update[i]->forward[i] = node;
        }
        if (levels - 1 > level_) {
            level_ = levels - 1;
        }
        ++size_;
    }

    Node* head_;
    int level_ = 0;
    size_t size_ = 0;
    std::mt19937 rng_{5489};  // 固定种子：同序插入必产生同样的层
};

}  // namespace ds

#endif  // DS_SKIP_LIST_HPP
