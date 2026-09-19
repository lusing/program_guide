// stl_interfaces.cpp —— Boost.STLInterfaces（2019）：一行写出合规迭代器
// 对应文档：docs/15-ranges.md
// 只写 begin 处 4 个核心操作，其余（it+n、it1-it2、it[n]、比较全套……）
// 由 iterator_interface 补全——C++20 deduced-this 可用时连 CRTP 参数都省。
#include <boost/stl_interfaces/iterator_interface.hpp>
#include <boost/stl_interfaces/view_interface.hpp>
#include <algorithm>
#include <numeric>
#include <iostream>
#include <vector>

namespace stli = boost::stl_interfaces;

struct ptr_iter : stli::iterator_interface<
#if !BOOST_STL_INTERFACES_USE_DEDUCED_THIS
                      ptr_iter,
#endif
                      std::random_access_iterator_tag, int> {
    int* it_ = nullptr;
    ptr_iter() = default;
    ptr_iter(int* it) : it_(it) {}

    int& operator*() const { return *it_; }
    ptr_iter& operator+=(std::ptrdiff_t i) {
        it_ += i;
        return *this;
    }
    friend std::ptrdiff_t operator-(ptr_iter lhs, ptr_iter rhs) noexcept {
        return lhs.it_ - rhs.it_;
    }
};

// view_interface：给"持有 begin/end 的东西"补 size/empty/front/operator[]
template <typename R>
struct head_view : stli::view_interface<head_view<R>> {
    R* r_ = nullptr;
    head_view(R& r) : r_(&r) {}
    auto begin() { return ptr_iter(r_->data()); }
    auto end() { return ptr_iter(r_->data() + (r_->empty() ? 0 : 1)); }
};

int main() {
    std::vector<int> v{10, 20, 30, 40};

    // 迭代器的 +、-、[]、全套比较都是基类送的
    ptr_iter it(v.data());
    std::cout << "*it = " << *it << " it[2] = " << it[2]
              << " *(it+3) = " << *(it + 3) << '\n';
    ++it;
    std::cout << "++it 后 = " << *it << " 到末尾距离 = "
              << ptr_iter(v.data() + v.size()) - it << '\n';

    // 它真的满足 C++20 的 random_access_iterator 概念（STL 算法全接口可用）
    static_assert(std::random_access_iterator<ptr_iter>);
    std::cout << "满足 std::random_access_iterator 概念\n";

    // view 的 empty/front 由 view_interface 送
    head_view hv(v);
    std::cout << "view: empty=" << hv.empty() << " front=" << hv.front() << '\n';
    std::cout << "view 求和 = " << std::accumulate(hv.begin(), hv.end(), 0) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
