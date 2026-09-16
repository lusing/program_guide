#include <array>
#include <cstddef>
#include <print>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

// 13 模板基础：把类型当参数

// ═══ 13.1 函数模板：T 代替具体类型 ═══
template <typename T>
T max_of(const T& a, const T& b) {
    return (a < b) ? b : a;
}

// ═══ 13.2 类模板：类型参数化的容器 ═══
template <typename T>
class Stack {
public:
    void push(T value) {
        items_.push_back(std::move(value));
    }
    T pop() {
        if (items_.empty()) {
            throw std::out_of_range("stack is empty");
        }
        T top = std::move(items_.back());
        items_.pop_back();
        return top;
    }
    [[nodiscard]] bool empty() const { return items_.empty(); }
    [[nodiscard]] std::size_t size() const { return items_.size(); }

private:
    std::vector<T> items_;
};

// ═══ 13.3 非类型模板参数：编译期的"值参数" ═══
template <typename T, std::size_t N>
double average(const std::array<T, N>& arr) {
    double sum = 0;
    for (const T& v : arr) {
        sum += v;
    }
    return sum / static_cast<double>(N);
}

int main() {
    std::println("{} {}", max_of(3, 9), max_of(2.5, 1.5));
    std::println("{}", max_of<double>(3, 2.5));  // 混合类型要显式指定

    Stack<int> ints;
    ints.push(1);
    ints.push(2);
    ints.push(3);
    std::println("size = {}，弹出 {}", ints.size(), ints.pop());

    Stack<std::string> words;  // 同一套代码，第二种类型
    words.push("模板");
    std::println("弹出 {}", words.pop());

    Stack copied{ints};  // CTAD：从拷贝构造推导出 Stack<int>
    std::println("拷贝的栈大小 = {}", copied.size());

    std::array<int, 4> nums{2, 4, 6, 8};
    std::println("平均 = {}", average(nums));  // N=4 自动推导
    std::println("自检通过");
}
