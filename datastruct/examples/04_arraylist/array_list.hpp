#ifndef DS_ARRAY_LIST_HPP
#define DS_ARRAY_LIST_HPP

#include <concepts>
#include <cstddef>
#include <initializer_list>
#include <new>
#include <span>
#include <stdexcept>
#include <utility>

namespace ds {

// 顺序表：元素住在一整块连续内存里，第 i 个元素的位置 = 首地址 + i * sizeof(T)。
// 容量（cap_）与长度（size_）分离：容量是“已租下的房间数”，长度是“已入住的人数”。
// 内存按未初始化存储管理（placement new 逐个构造），因此 T 只需 copyable，
// 不必可默认构造。
template <std::copyable T>
class ArrayList {
public:
    ArrayList() = default;

    explicit ArrayList(size_t cap) {
        reserve(cap);
    }

    ArrayList(std::initializer_list<T> il) {
        reserve(il.size());
        for (const T& v : il) {
            push_back(v);
        }
    }

    ArrayList(const ArrayList& other) {
        reserve(other.size_);
        for (size_t i = 0; i < other.size_; ++i) {
            ::new (static_cast<void*>(data_ + i)) T(other.data_[i]);
            ++size_;
        }
    }

    ArrayList(ArrayList&& other) noexcept
        : data_(other.data_), size_(other.size_), cap_(other.cap_) {
        other.data_ = nullptr;
        other.size_ = 0;
        other.cap_ = 0;
    }

    // 拷贝赋值：拷贝并交换。先安全地造出副本，再交换；旧资源随副本析构归还。
    ArrayList& operator=(const ArrayList& other) {
        if (this != &other) {
            ArrayList tmp(other);
            swap(tmp);
        }
        return *this;
    }

    ArrayList& operator=(ArrayList&& other) noexcept {
        if (this != &other) {
            clear_();
            release_();
            data_ = other.data_;
            size_ = other.size_;
            cap_ = other.cap_;
            other.data_ = nullptr;
            other.size_ = 0;
            other.cap_ = 0;
        }
        return *this;
    }

    ~ArrayList() {
        clear_();
        release_();
    }

    [[nodiscard]] size_t size() const noexcept {
        return size_;
    }

    [[nodiscard]] bool empty() const noexcept {
        return size_ == 0;
    }

    [[nodiscard]] size_t capacity() const noexcept {
        return cap_;
    }

    // 预留至少 n 个元素的容量；不改变长度。旧元素迁移到新存储。
    void reserve(size_t n) {
        if (n <= cap_) {
            return;
        }
        T* nd = allocate_(n);
        size_t constructed = 0;
        try {
            for (size_t i = 0; i < size_; ++i) {
                // 能 noexcept 移动就移动，否则拷贝：拷贝路径下中途抛异常时
                // 旧存储原样无损，提供强异常保证。
                ::new (static_cast<void*>(nd + i)) T(std::move_if_noexcept(data_[i]));
                ++constructed;
            }
        } catch (...) {
            for (size_t i = 0; i < constructed; ++i) {
                nd[i].~T();
            }
            ::operator delete(nd);
            throw;
        }
        // 注意：这里只析构旧存储上的元素并归还旧存储，不能调用 clear_()——
        // 那会把逻辑长度 size_ 也清零，而长度在扩容前后不变。
        for (size_t i = 0; i < size_; ++i) {
            data_[i].~T();
        }
        ::operator delete(data_);
        data_ = nd;
        cap_ = n;
    }

    void push_back(const T& v) {
        if (size_ == cap_) {
            grow_(size_ + 1);
        }
        ::new (static_cast<void*>(data_ + size_)) T(v);
        ++size_;
    }

    // 在位置 pos 前插入 v，合法范围 0 <= pos <= size_（pos == size_ 即尾插）。
    void insert(size_t pos, const T& v) {
        if (pos > size_) {
            throw std::out_of_range("ArrayList::insert: pos > size");
        }
        if (size_ == cap_) {
            grow_(size_ + 1);
        }
        if (pos == size_) {
            ::new (static_cast<void*>(data_ + size_)) T(v);
        } else {
            // 先在尾部“复制出”最后一个元素把长度撑开，再从后往前逐个右移，
            // 最后把空位交给 v。全程只多构造一个对象，不碰未初始化存储。
            ::new (static_cast<void*>(data_ + size_)) T(data_[size_ - 1]);
            for (size_t i = size_; i > pos; --i) {
                data_[i] = std::move(data_[i - 1]);
            }
            data_[pos] = v;
        }
        ++size_;
    }

    void erase(size_t pos) {
        if (pos >= size_) {
            throw std::out_of_range("ArrayList::erase: pos >= size");
        }
        for (size_t i = pos; i + 1 < size_; ++i) {
            data_[i] = std::move(data_[i + 1]);
        }
        data_[size_ - 1].~T();
        --size_;
    }

    void pop_back() {
        if (size_ == 0) {
            throw std::out_of_range("ArrayList::pop_back: list empty");
        }
        data_[size_ - 1].~T();
        --size_;
    }

    T& operator[](size_t i) {
        if (i >= size_) {
            throw std::out_of_range("ArrayList::operator[]: index out of range");
        }
        return data_[i];
    }

    const T& operator[](size_t i) const {
        if (i >= size_) {
            throw std::out_of_range("ArrayList::operator[]: index out of range");
        }
        return data_[i];
    }

    T* begin() noexcept {
        return data_;
    }

    T* end() noexcept {
        return data_ + size_;
    }

    const T* begin() const noexcept {
        return data_;
    }

    const T* end() const noexcept {
        return data_ + size_;
    }

    bool operator==(const ArrayList& other) const {
        if (size_ != other.size_) {
            return false;
        }
        for (size_t i = 0; i < size_; ++i) {
            if (!(data_[i] == other.data_[i])) {
                return false;
            }
        }
        return true;
    }

    std::span<T> as_span() noexcept {
        return std::span<T>(data_, size_);
    }

    void swap(ArrayList& other) noexcept {
        T* td = data_;
        data_ = other.data_;
        other.data_ = td;
        size_t ts = size_;
        size_ = other.size_;
        other.size_ = ts;
        size_t tc = cap_;
        cap_ = other.cap_;
        other.cap_ = tc;
    }

private:
    T* data_ = nullptr;
    size_t size_ = 0;
    size_t cap_ = 0;

    static T* allocate_(size_t n) {
        return static_cast<T*>(::operator new(n * sizeof(T)));
    }

    void release_() {
        ::operator delete(data_);
        data_ = nullptr;
        cap_ = 0;
    }

    // 析构全部已构造元素；存储本身仍保留。
    void clear_() {
        for (size_t i = 0; i < size_; ++i) {
            data_[i].~T();
        }
        size_ = 0;
    }

    // 倍增扩容：1 → 2 → 4 → 8 ……保证能容纳 need 个元素。
    void grow_(size_t need) {
        size_t nc = cap_ == 0 ? 1 : cap_;
        while (nc < need) {
            nc *= 2;
        }
        reserve(nc);
    }
};

}  // namespace ds

#endif  // DS_ARRAY_LIST_HPP
