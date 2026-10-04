#ifndef DS_DOUBLY_LIST_HPP
#define DS_DOUBLY_LIST_HPP

#include <concepts>
#include <cstddef>
#include <initializer_list>
#include <iterator>
#include <stdexcept>

namespace ds {

// 双向链表：节点同时持有前驱 prev 与后继 next；头节点 prev 为空，尾节点 next 为空。
// 不变量：
//  1) 从 head_ 沿 next 到 nullptr 经过 size_ 个节点；从 tail_ 沿 prev 同样回到 head_；
//  2) 对任意非头节点 x：x->prev->next == x；对任意非尾节点 x：x->next->prev == x；
//  3) 空表 head_ == tail_ == nullptr。
template <std::copyable T>
class DoublyList {
    struct Node {
        T data;
        Node* prev;
        Node* next;
        Node(const T& v) : data(v), prev(nullptr), next(nullptr) {}
    };

public:
    class iterator {
        Node* p_ = nullptr;
    public:
        using iterator_category = std::bidirectional_iterator_tag;
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
        iterator& operator--() {
            p_ = p_->prev;
            return *this;
        }
        iterator operator--(int) {
            iterator old = *this;
            --(*this);
            return old;
        }

        bool operator==(const iterator& other) const { return p_ == other.p_; }
    };

    DoublyList() = default;

    DoublyList(std::initializer_list<T> il) {
        for (const T& v : il) {
            push_back(v);
        }
    }

    DoublyList(const DoublyList& other) {
        append_copy(other);
    }

    DoublyList(DoublyList&& other) noexcept
        : head_(other.head_), tail_(other.tail_), size_(other.size_) {
        other.head_ = nullptr;
        other.tail_ = nullptr;
        other.size_ = 0;
    }

    DoublyList& operator=(const DoublyList& other) {
        if (this != &other) {
            clear();
            append_copy(other);
        }
        return *this;
    }

    DoublyList& operator=(DoublyList&& other) noexcept {
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

    ~DoublyList() { clear(); }

    [[nodiscard]] size_t size() const noexcept { return size_; }
    [[nodiscard]] bool empty() const noexcept { return size_ == 0; }

    const T& front() const {
        if (empty()) {
            throw std::runtime_error("front: 链表为空");
        }
        return head_->data;
    }
    const T& back() const {
        if (empty()) {
            throw std::runtime_error("back: 链表为空");
        }
        return tail_->data;
    }

    void push_front(const T& v) {
        Node* node = new Node(v);
        node->next = head_;
        if (head_ != nullptr) {
            head_->prev = node;
        } else {
            tail_ = node;
        }
        head_ = node;
        ++size_;
    }

    void push_back(const T& v) {
        Node* node = new Node(v);
        node->prev = tail_;
        if (tail_ != nullptr) {
            tail_->next = node;
        } else {
            head_ = node;
        }
        tail_ = node;
        ++size_;
    }

    void pop_front() {
        if (empty()) {
            throw std::runtime_error("pop_front: 链表为空");
        }
        Node* dead = head_;
        head_ = head_->next;
        if (head_ != nullptr) {
            head_->prev = nullptr;
        } else {
            tail_ = nullptr;
        }
        delete dead;
        --size_;
    }

    void pop_back() {
        if (empty()) {
            throw std::runtime_error("pop_back: 链表为空");
        }
        Node* dead = tail_;
        tail_ = tail_->prev;
        if (tail_ != nullptr) {
            tail_->next = nullptr;
        } else {
            head_ = nullptr;
        }
        delete dead;
        --size_;
    }

    // 在位置 pos 插入；插在原 pos 元素之前，pos == size 即尾插。
    void insert(size_t pos, const T& v) {
        if (pos > size_) {
            throw std::out_of_range("insert: pos 超出 size");
        }
        if (pos == 0) {
            push_front(v);
            return;
        }
        if (pos == size_) {
            push_back(v);
            return;
        }
        Node* after = node_at(pos);
        Node* node = new Node(v);
        node->prev = after->prev;
        node->next = after;
        after->prev->next = node;
        after->prev = node;
        ++size_;
    }

    void erase(size_t pos) {
        if (pos >= size_) {
            throw std::out_of_range("erase: pos 超出范围");
        }
        if (pos == 0) {
            pop_front();
            return;
        }
        if (pos == size_ - 1) {
            pop_back();
            return;
        }
        Node* dead = node_at(pos);
        dead->prev->next = dead->next;
        dead->next->prev = dead->prev;
        delete dead;
        --size_;
    }

    iterator begin() { return iterator(head_); }
    iterator end() { return iterator(nullptr); }
    iterator rbegin() { return iterator(tail_); }
    iterator rend() { return iterator(nullptr); }

    bool operator==(const DoublyList& other) const {
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

    void append_copy(const DoublyList& other) {
        for (Node* cur = other.head_; cur != nullptr; cur = cur->next) {
            push_back(cur->data);
        }
    }
};

// 合并两个升序双链，返回新表；不修改输入（遍历但不改动）。
// 平局时先取 a 的元素，输出因此完全确定。
template <std::copyable T>
DoublyList<T> merge_sorted(DoublyList<T>& a, DoublyList<T>& b) {
    DoublyList<T> result;
    typename DoublyList<T>::iterator ia = a.begin();
    typename DoublyList<T>::iterator ib = b.begin();
    const typename DoublyList<T>::iterator ea = a.end();
    const typename DoublyList<T>::iterator eb = b.end();
    while (ia != ea && ib != eb) {
        if (*ib < *ia) {
            result.push_back(*ib);
            ++ib;
        } else {
            result.push_back(*ia);
            ++ia;
        }
    }
    while (ia != ea) {
        result.push_back(*ia);
        ++ia;
    }
    while (ib != eb) {
        result.push_back(*ib);
        ++ib;
    }
    return result;
}

}  // namespace ds

#endif  // DS_DOUBLY_LIST_HPP
