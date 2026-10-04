#ifndef DS_SINGLY_LIST_HPP
#define DS_SINGLY_LIST_HPP

#include <concepts>
#include <cstddef>
#include <initializer_list>
#include <iterator>
#include <stdexcept>
#include <utility>

namespace ds {

// 单向链表：每个节点只持有“下一个节点”的地址，最后一个节点的 next 为空。
// 不变量：
//  1) 从 head_ 沿 next 走，恰好经过 size_ 个节点后遇到 nullptr；
//  2) size_ == 链上节点数；空表 head_ == nullptr 且 size_ == 0；
//  3) tail_（若有）是 next 为 nullptr 的那个节点。
template <std::copyable T>
class SinglyList {
    struct Node {
        T data;
        Node* next;
        Node(const T& v, Node* n) : data(v), next(n) {}
    };

public:
    class iterator {
        Node* p_ = nullptr;
    public:
        using iterator_category = std::forward_iterator_tag;
        using value_type = T;
        using difference_type = std::ptrdiff_t;
        using pointer = T*;
        using reference = T&;

        iterator() = default;
        explicit iterator(Node* p) : p_(p) {}

        reference operator*() const { return p_->data; }
        pointer operator->() const { return &p_->data; }

        iterator& operator++() {
            p_ = p_->next;
            return *this;
        }
        iterator operator++(int) {
            iterator old = *this;
            ++(*this);
            return old;
        }

        bool operator==(const iterator& other) const { return p_ == other.p_; }
    };

    SinglyList() = default;

    SinglyList(std::initializer_list<T> il) {
        for (const T& v : il) {
            push_back(v);
        }
    }

    SinglyList(const SinglyList& other) {
        append_copy(other);
    }

    SinglyList(SinglyList&& other) noexcept
        : head_(other.head_), tail_(other.tail_), size_(other.size_) {
        other.head_ = nullptr;
        other.tail_ = nullptr;
        other.size_ = 0;
    }

    SinglyList& operator=(const SinglyList& other) {
        if (this != &other) {
            clear();
            append_copy(other);
        }
        return *this;
    }

    SinglyList& operator=(SinglyList&& other) noexcept {
        if (this != &other) {
            clear();
            head_ = other.head_;
            tail_ = other.tail_;
            size_ = other.size_;
            other.head_ = nullptr;
            other.tail_ = nullptr;
            other.size_ = 0;
        }
        return *this;
    }

    ~SinglyList() { clear(); }

    [[nodiscard]] size_t size() const noexcept { return size_; }
    [[nodiscard]] bool empty() const noexcept { return size_ == 0; }

    const T& front() const {
        if (empty()) {
            throw std::runtime_error("front: 链表为空");
        }
        return head_->data;
    }

    void push_front(const T& v) {
        head_ = new Node(v, head_);
        if (tail_ == nullptr) {
            tail_ = head_;
        }
        ++size_;
    }

    void push_back(const T& v) {
        Node* node = new Node(v, nullptr);
        if (tail_ == nullptr) {
            head_ = tail_ = node;
        } else {
            tail_->next = node;
            tail_ = node;
        }
        ++size_;
    }

    void pop_front() {
        if (empty()) {
            throw std::runtime_error("pop_front: 链表为空");
        }
        Node* dead = head_;
        head_ = head_->next;
        if (head_ == nullptr) {
            tail_ = nullptr;
        }
        delete dead;
        --size_;
    }

    // 在位置 pos（0 <= pos <= size）插入；pos == size 即尾插。
    void insert(size_t pos, const T& v) {
        if (pos > size_) {
            throw std::out_of_range("insert: pos 超出 size");
        }
        if (pos == 0) {
            push_front(v);
            return;
        }
        Node* prev = node_at(pos - 1);
        prev->next = new Node(v, prev->next);
        if (prev == tail_) {
            tail_ = prev->next;
        }
        ++size_;
    }

    // 删除位置 pos（0 <= pos < size）。
    void erase(size_t pos) {
        if (pos >= size_) {
            throw std::out_of_range("erase: pos 超出范围");
        }
        if (pos == 0) {
            pop_front();
            return;
        }
        Node* prev = node_at(pos - 1);
        Node* dead = prev->next;
        prev->next = dead->next;
        if (dead == tail_) {
            tail_ = prev;
        }
        delete dead;
        --size_;
    }

    // 三指针就地反转：每个节点的 next 改指向前驱，首节点变尾节点。
    void reverse() noexcept {
        Node* prev = nullptr;
        Node* cur = head_;
        tail_ = head_;
        while (cur != nullptr) {
            Node* next = cur->next;
            cur->next = prev;
            prev = cur;
            cur = next;
        }
        head_ = prev;
    }

    iterator begin() { return iterator(head_); }
    iterator end() { return iterator(nullptr); }

    bool operator==(const SinglyList& other) const {
        if (size_ != other.size_) {
            return false;
        }
        Node* a = head_;
        Node* b = other.head_;
        while (a != nullptr) {
            if (!(a->data == b->data)) {
                return false;
            }
            a = a->next;
            b = b->next;
        }
        return true;
    }

private:
    Node* head_ = nullptr;
    Node* tail_ = nullptr;
    size_t size_ = 0;

    Node* node_at(size_t pos) const {
        Node* cur = head_;
        for (size_t i = 0; i < pos; ++i) {
            cur = cur->next;
        }
        return cur;
    }

    void clear() noexcept {
        while (head_ != nullptr) {
            Node* dead = head_;
            head_ = head_->next;
            delete dead;
        }
        tail_ = nullptr;
        size_ = 0;
    }

    void append_copy(const SinglyList& other) {
        for (Node* cur = other.head_; cur != nullptr; cur = cur->next) {
            push_back(cur->data);
        }
    }
};

}  // namespace ds

#endif  // DS_SINGLY_LIST_HPP
