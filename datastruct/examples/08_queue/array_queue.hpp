#ifndef DS_ARRAY_QUEUE_HPP
#define DS_ARRAY_QUEUE_HPP

#include <concepts>
#include <cstddef>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 循环数组队列：队头下标 head_、下一入队位置 tail_ 在物理数组里循环移动；
// 元素个数 count_ 让"空"与"满"这两种 head_ == tail_ 的情形可以区分。
// 数组装满时按 2 倍扩容（扩容时把元素搬成从 0 开始的紧凑排列）。
template <std::copyable T>
class ArrayQueue {
public:
    ArrayQueue() : data_(4) {}
    explicit ArrayQueue(size_t cap) : data_(cap < 1 ? 1 : cap) {}

    ArrayQueue(const ArrayQueue&) = default;
    ArrayQueue(ArrayQueue&&) noexcept = default;
    ArrayQueue& operator=(const ArrayQueue&) = default;
    ArrayQueue& operator=(ArrayQueue&&) noexcept = default;
    ~ArrayQueue() = default;

    [[nodiscard]] bool empty() const noexcept { return count_ == 0; }
    [[nodiscard]] size_t size() const noexcept { return count_; }

    void enqueue(const T& v) {
        if (count_ == data_.size()) {
            grow();
        }
        data_[tail_] = v;
        tail_ = (tail_ + 1) % data_.size();
        ++count_;
    }

    T dequeue() {
        if (count_ == 0) {
            throw std::runtime_error("ArrayQueue::dequeue: 队列为空");
        }
        T v = std::move(data_[head_]);
        head_ = (head_ + 1) % data_.size();
        --count_;
        return v;
    }

    const T& front() const {
        if (count_ == 0) {
            throw std::runtime_error("ArrayQueue::front: 队列为空");
        }
        return data_[head_];
    }

private:
    void grow() {
        std::vector<T> bigger(data_.size() * 2);
        for (size_t i = 0; i < count_; ++i) {
            bigger[i] = std::move(data_[(head_ + i) % data_.size()]);
        }
        data_ = std::move(bigger);
        head_ = 0;
        tail_ = count_;
    }

    std::vector<T> data_;
    size_t head_ = 0;
    size_t tail_ = 0;
    size_t count_ = 0;
};

}  // namespace ds

#endif  // DS_ARRAY_QUEUE_HPP
