#ifndef DS_CIRCULAR_LIST_HPP
#define DS_CIRCULAR_LIST_HPP

#include <concepts>
#include <cstddef>
#include <initializer_list>
#include <stdexcept>
#include <vector>

namespace ds {

// 循环单链表：尾节点的 next 不置空，而是指回头节点，全链成环。
// 只保存一个 tail_ 指针：头节点即 tail_->next，尾插、头取都能 O(1)。
// 不变量：
//  1) 空表 tail_ == nullptr；非空时 tail_->next 是头节点，从它沿 next
//     走 size_ 步回到 tail_（环上恰好 size_ 个不同节点）；
//  2) rotate() 把“头”沿环推进一格：tail_ 前进一个节点。
template <std::copyable T>
class CircularList {
    struct Node {
        T data;
        Node* next;
        Node(const T& v, Node* n) : data(v), next(n) {}
    };

public:
    CircularList() = default;

    CircularList(std::initializer_list<T> il) {
        for (const T& v : il) {
            push_back(v);
        }
    }

    CircularList(const CircularList& other) {
        if (other.tail_ != nullptr) {
            Node* src = other.tail_->next;
            for (size_t i = 0; i < other.size_; ++i) {
                push_back(src->data);
                src = src->next;
            }
        }
    }

    CircularList(CircularList&& other) noexcept
        : tail_(other.tail_), size_(other.size_) {
        other.tail_ = nullptr;
        other.size_ = 0;
    }

    CircularList& operator=(const CircularList& other) {
        if (this != &other) {
            break_ring_and_clear();
            if (other.tail_ != nullptr) {
                Node* src = other.tail_->next;
                for (size_t i = 0; i < other.size_; ++i) {
                    push_back(src->data);
                    src = src->next;
                }
            }
        }
        return *this;
    }

    CircularList& operator=(CircularList&& other) noexcept {
        if (this != &other) {
            break_ring_and_clear();
            tail_ = other.tail_;
            size_ = other.size_;
            other.tail_ = nullptr;
            other.size_ = 0;
        }
        return *this;
    }

    ~CircularList() {
        break_ring_and_clear();
    }

    [[nodiscard]] size_t size() const noexcept { return size_; }
    [[nodiscard]] bool empty() const noexcept { return size_ == 0; }

    const T& front() const {
        if (empty()) {
            throw std::runtime_error("front: 链表为空");
        }
        return tail_->next->data;
    }

    void push_back(const T& v) {
        if (tail_ == nullptr) {
            // 第一个节点自成环
            tail_ = new Node(v, nullptr);
            tail_->next = tail_;
        } else {
            tail_->next = new Node(v, tail_->next);
            tail_ = tail_->next;
        }
        ++size_;
    }

    // 旋转：当前头节点变成新的尾节点，即“头”沿环前进一格。
    void rotate() noexcept {
        if (tail_ != nullptr) {
            tail_ = tail_->next;
        }
    }

    // 教学断言与打印都需要观察内容：按头到尾的顺序导出。
    std::vector<T> to_vector() const {
        std::vector<T> out;
        if (tail_ != nullptr) {
            Node* cur = tail_->next;
            for (size_t i = 0; i < size_; ++i) {
                out.push_back(cur->data);
                cur = cur->next;
            }
        }
        return out;
    }

private:
    Node* tail_ = nullptr;
    size_t size_ = 0;

    // 环形结构不能直接 while (p != nullptr) 删除：先把环断开成普通链，
    // 再逐个释放，否则不是漏删就是死循环。
    void break_ring_and_clear() noexcept {
        if (tail_ == nullptr) {
            return;
        }
        Node* head = tail_->next;
        tail_->next = nullptr;  // 断环
        while (head != nullptr) {
            Node* dead = head;
            head = head->next;
            delete dead;
        }
        tail_ = nullptr;
        size_ = 0;
    }
};

}  // namespace ds

#endif  // DS_CIRCULAR_LIST_HPP
