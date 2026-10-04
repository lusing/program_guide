#ifndef DS_LINKED_QUEUE_HPP
#define DS_LINKED_QUEUE_HPP

#include <concepts>
#include <cstddef>
#include <stdexcept>
#include <utility>

namespace ds {

// 链式队列：节点散落在堆上，head_ 指向队头、tail_ 指向队尾。
// 入队挂到 tail_ 之后，出队摘下 head_；析构与拷贝逐个节点处理，无泄漏。
template <std::copyable T>
class LinkedQueue {
public:
    LinkedQueue() = default;

    LinkedQueue(const LinkedQueue& other) {
        copy_from(other);
    }

    LinkedQueue(LinkedQueue&& other) noexcept
        : head_(other.head_), tail_(other.tail_), count_(other.count_) {
        other.head_ = nullptr;
        other.tail_ = nullptr;
        other.count_ = 0;
    }

    LinkedQueue& operator=(const LinkedQueue& other) {
        if (this != &other) {
            clear();
            copy_from(other);
        }
        return *this;
    }

    LinkedQueue& operator=(LinkedQueue&& other) noexcept {
        if (this != &other) {
            clear();
            head_ = other.head_;
            tail_ = other.tail_;
            count_ = other.count_;
            other.head_ = nullptr;
            other.tail_ = nullptr;
            other.count_ = 0;
        }
        return *this;
    }

    ~LinkedQueue() {
        clear();
    }

    [[nodiscard]] bool empty() const noexcept { return count_ == 0; }
    [[nodiscard]] size_t size() const noexcept { return count_; }

    void enqueue(const T& v) {
        Node* node = new Node{v, nullptr};
        if (tail_ == nullptr) {
            head_ = node;
        } else {
            tail_->next = node;
        }
        tail_ = node;
        ++count_;
    }

    T dequeue() {
        if (head_ == nullptr) {
            throw std::runtime_error("LinkedQueue::dequeue: 队列为空");
        }
        Node* node = head_;
        T v = std::move(node->value);
        head_ = node->next;
        if (head_ == nullptr) {
            tail_ = nullptr;
        }
        delete node;
        --count_;
        return v;
    }

    const T& front() const {
        if (head_ == nullptr) {
            throw std::runtime_error("LinkedQueue::front: 队列为空");
        }
        return head_->value;
    }

private:
    struct Node {
        T value;
        Node* next;
    };

    void clear() noexcept {
        while (head_ != nullptr) {
            Node* node = head_;
            head_ = node->next;
            delete node;
        }
        tail_ = nullptr;
        count_ = 0;
    }

    void copy_from(const LinkedQueue& other) {
        for (Node* cur = other.head_; cur != nullptr; cur = cur->next) {
            enqueue(cur->value);
        }
    }

    Node* head_ = nullptr;
    Node* tail_ = nullptr;
    size_t count_ = 0;
};

}  // namespace ds

#endif  // DS_LINKED_QUEUE_HPP
