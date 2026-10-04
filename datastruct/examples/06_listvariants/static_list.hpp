#ifndef DS_STATIC_LIST_HPP
#define DS_STATIC_LIST_HPP

#include <array>
#include <concepts>
#include <cstddef>
#include <stdexcept>

namespace ds {

// 静态链表：不用一个真实指针，用整型下标"模拟指针"。
// 全部节点预先住在定长数组里（不随用随分配），空槽串成 freelist。
// 下标 -1 表示"空"（真实链表里的 nullptr）。
template <std::copyable T, std::size_t N>
    requires (N > 0) && std::default_initializable<T>
class StaticList {
public:
    struct Node {
        T value{};
        int next = -1;
    };

    StaticList() {
        for (std::size_t i = 0; i < N; ++i) {
            nodes_[i].next = static_cast<int>(i + 1);
        }
        nodes_[N - 1].next = -1;  // 末槽收尾，freelist = 0→1→…→N-1→-1
        free_head_ = 0;
    }

    // 表未空时的头槽号；空表返回 -1。
    [[nodiscard]] int head() const noexcept { return head_; }

    [[nodiscard]] int next(int node) const {
        check_node(node);
        return nodes_[static_cast<std::size_t>(node)].next;
    }

    T& value(int node) {
        check_node(node);
        return nodes_[static_cast<std::size_t>(node)].value;
    }

    const T& value(int node) const {
        check_node(node);
        return nodes_[static_cast<std::size_t>(node)].value;
    }

    [[nodiscard]] std::size_t size() const noexcept { return used_; }

    // 从 freelist 取一个槽写入 v 并返回槽号；无空槽返回 -1。
    // 关键约定：刚释放的槽排在 freelist 最前面，所以"释放后立刻再分配"
    // 必定拿回同一个槽号 —— 槽位被复用，而不是另开新槽。
    int alloc_node(const T& v) {
        if (free_head_ == -1) {
            return -1;
        }
        const int slot = free_head_;
        free_head_ = nodes_[static_cast<std::size_t>(slot)].next;
        nodes_[static_cast<std::size_t>(slot)].value = v;
        nodes_[static_cast<std::size_t>(slot)].next = -1;
        return slot;
    }

    // 把槽还回 freelist（头插，因此它是下一次 alloc 的首选）。
    void free_node(int slot) {
        check_node(slot);
        nodes_[static_cast<std::size_t>(slot)].next = free_head_;
        free_head_ = slot;
    }

    // 头插：新槽作为新的头节点。
    int push_front(const T& v) {
        const int slot = alloc_node(v);
        if (slot == -1) {
            throw std::length_error{"StaticList 已满"};
        }
        nodes_[static_cast<std::size_t>(slot)].next = head_;
        head_ = slot;
        ++used_;
        return slot;
    }

    // 摘下头节点并还槽。
    void pop_front() {
        if (head_ == -1) {
            throw std::runtime_error{"StaticList 为空"};
        }
        const int old = head_;
        head_ = nodes_[static_cast<std::size_t>(old)].next;
        free_node(old);
        --used_;
    }

    // 在 node 之后插入 v。
    int insert_after(int node, const T& v) {
        check_node(node);
        const int slot = alloc_node(v);
        if (slot == -1) {
            throw std::length_error{"StaticList 已满"};
        }
        nodes_[static_cast<std::size_t>(slot)].next =
            nodes_[static_cast<std::size_t>(node)].next;
        nodes_[static_cast<std::size_t>(node)].next = slot;
        ++used_;
        return slot;
    }

    // 删除 node 的后继并还槽。
    void erase_after(int node) {
        check_node(node);
        const int victim = nodes_[static_cast<std::size_t>(node)].next;
        if (victim == -1) {
            throw std::runtime_error{"该节点没有后继"};
        }
        nodes_[static_cast<std::size_t>(node)].next =
            nodes_[static_cast<std::size_t>(victim)].next;
        free_node(victim);
        --used_;
    }

private:
    void check_node(int node) const {
        if (node < 0 || static_cast<std::size_t>(node) >= N) {
            throw std::out_of_range{"槽号越界"};
        }
    }

    std::array<Node, N> nodes_{};
    int head_ = -1;
    int free_head_ = -1;
    std::size_t used_ = 0;
};

}  // namespace ds

#endif  // DS_STATIC_LIST_HPP
