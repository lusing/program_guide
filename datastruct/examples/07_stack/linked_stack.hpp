#ifndef DS_LINKED_STACK_HPP
#define DS_LINKED_STACK_HPP

#include <cstddef>
#include <stdexcept>
#include <utility>

namespace ds {

// 链式栈：节点散落在堆上，新节点从顶部插入，栈顶指针始终指向最新节点。
// 资源自管（RAII）：拷贝深复制、移动窃取、析构逐节点回收，无裸泄漏。
template <class T>
class LinkedStack {
    struct Node {
        T value;
        Node* next;
    };

    Node* top_ = nullptr;
    size_t size_ = 0;

public:
    LinkedStack() = default;

    LinkedStack(const LinkedStack& other) : size_(other.size_) {
        Node** dst = &top_;
        for (Node* src = other.top_; src != nullptr; src = src->next) {
            auto* node = new Node{src->value, nullptr};
            *dst = node;
            dst = &node->next;
        }
    }

    LinkedStack(LinkedStack&& other) noexcept
        : top_(other.top_), size_(other.size_) {
        other.top_ = nullptr;
        other.size_ = 0;
    }

    LinkedStack& operator=(const LinkedStack& other) {
        if (this != &other) {
            LinkedStack tmp(other);
            swap(tmp);
        }
        return *this;
    }

    LinkedStack& operator=(LinkedStack&& other) noexcept {
        if (this != &other) {
            clear();
            top_ = other.top_;
            size_ = other.size_;
            other.top_ = nullptr;
            other.size_ = 0;
        }
        return *this;
    }

    ~LinkedStack() { clear(); }

    void swap(LinkedStack& other) noexcept {
        std::swap(top_, other.top_);
        std::swap(size_, other.size_);
    }

    void push(const T& value) {
        top_ = new Node{value, top_};
        ++size_;
    }

    void pop() {
        if (top_ == nullptr) {
            throw std::runtime_error("LinkedStack::pop：栈为空");
        }
        Node* dead = top_;
        top_ = top_->next;
        delete dead;
        --size_;
    }

    T& top() {
        if (top_ == nullptr) {
            throw std::runtime_error("LinkedStack::top：栈为空");
        }
        return top_->value;
    }

    const T& top() const {
        if (top_ == nullptr) {
            throw std::runtime_error("LinkedStack::top：栈为空");
        }
        return top_->value;
    }

    [[nodiscard]] bool empty() const noexcept { return size_ == 0; }
    [[nodiscard]] size_t size() const noexcept { return size_; }

private:
    void clear() {
        while (top_ != nullptr) {
            Node* dead = top_;
            top_ = top_->next;
            delete dead;
        }
        size_ = 0;
    }
};

}  // namespace ds

#endif  // DS_LINKED_STACK_HPP
