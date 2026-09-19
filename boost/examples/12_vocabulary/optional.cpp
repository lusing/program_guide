// optional.cpp —— Boost.Optional（2003）：可能没有的值（std::optional 直系，
// 且 2014 年就有的单子操作 std 到 C++23 才补齐）
// 对应文档：docs/12-vocabulary.md
#include <boost/optional.hpp>
#include <iostream>
#include <optional>
#include <string>

boost::optional<int> parse_positive(int v) {
    if (v > 0) return v;
    return boost::none;
}

int main() {
    // 1) 构造与判空
    auto ok = parse_positive(42);
    auto bad = parse_positive(-1);
    std::cout << "有值? " << ok.is_initialized() << ' ' << bad.is_initialized() << '\n';
    std::cout << "值 = " << ok.value_or(0) << " / " << bad.value_or(0) << '\n';

    // 2) 领先 std 九年的单子操作（std::optional 到 C++23 才有）
    auto doubled = ok.map([](int x) { return x * 2; });        // 值存在才映射
    auto chained = doubled.flat_map([](int x) { return parse_positive(x); });
    std::cout << "map×2 = " << *chained << '\n';
    std::cout << "bad.map 不触发: " << bad.map([](int x) { return x * 100; }).value_or(-1) << '\n';

    // 3) 引用语义（std::optional<T&> 一直不允许，boost 允许）
    int target = 10;
    boost::optional<int&> ref = target;
    *ref = 20;
    std::cout << "引用语义改写: target = " << target << '\n';

    // 4) std 对照（C++17 毕业；C++23 起也有 and_then/transform）
    std::optional<int> sok = 42;
    std::cout << "std transform = "
              << sok.transform([](int x) { return x + 1; }).value_or(0) << '\n';

    // 5) in-place 构造（不必先构造 T 再拷）
    boost::optional<std::string> s{boost::in_place_init, 5, 'x'};
    std::cout << "in_place: " << *s << '\n';

    std::cout << "自检通过\n";
    return 0;
}
