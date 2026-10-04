#ifndef DS_ARRAY_STACK_HPP
#define DS_ARRAY_STACK_HPP

#include <cstddef>
#include <stdexcept>
#include <vector>

namespace ds {

// 顺序栈：元素住在连续数组（std::vector）尾部，栈顶就是最后一个元素。
// 入栈 = 尾插，出栈 = 尾删，两个操作都不动其他元素。
template <class T>
class ArrayStack {
    std::vector<T> data_;

public:
    ArrayStack() = default;

    void push(const T& value) { data_.push_back(value); }

    void pop() {
        if (data_.empty()) {
            throw std::runtime_error("ArrayStack::pop：栈为空");
        }
        data_.pop_back();
    }

    T& top() {
        if (data_.empty()) {
            throw std::runtime_error("ArrayStack::top：栈为空");
        }
        return data_.back();
    }

    const T& top() const {
        if (data_.empty()) {
            throw std::runtime_error("ArrayStack::top：栈为空");
        }
        return data_.back();
    }

    [[nodiscard]] bool empty() const noexcept { return data_.empty(); }
    [[nodiscard]] size_t size() const noexcept { return data_.size(); }
};

}  // namespace ds

#endif  // DS_ARRAY_STACK_HPP
