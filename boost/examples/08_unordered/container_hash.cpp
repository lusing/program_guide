// container_hash.cpp —— Boost.ContainerHash：给"一切"算哈希（std::hash 的泛化）
// 对应文档：docs/08-unordered.md
#include <boost/container_hash/hash.hpp>
#include <iostream>
#include <list>
#include <string>
#include <tuple>
#include <vector>

int main() {
    boost::hash<int> hi;
    boost::hash<std::string> hs;

    // 1) 内建类型与 string：开箱即用（std::hash 也有）
    std::cout << "hash(42) = " << hi(42) << '\n';
    std::cout << "hash(boost) 与 hash(boost) 相等? "
              << std::boolalpha << (hs("boost") == hs("boost")) << '\n';

    // 2) std::hash 做不到的：容器、元组、range 的哈希
    boost::hash<std::vector<int>> hv;
    boost::hash<std::list<std::string>> hl;
    boost::hash<std::tuple<int, std::string, double>> ht;
    std::cout << "vector 哈希 = " << hv({1, 2, 3}) << '\n';
    std::cout << "list 哈希非零? " << (hl({"a", "b"}) != 0) << '\n';
    std::cout << "tuple 哈希非零? " << (ht(std::make_tuple(1, "x", 2.5)) != 0) << '\n';

    // 3) hash_combine：组合哈希的原子操作（自定义类型的标准姿势）
    std::size_t seed = 0;
    boost::hash_combine(seed, 42);
    boost::hash_combine(seed, std::string("answer"));
    std::cout << "组合哈希非零? " << (seed != 0) << '\n';

    // 4) hash_range：整段区间
    std::vector<int> v{10, 20, 30};
    std::cout << "range 哈希 = " << boost::hash_range(v.begin(), v.end()) << '\n';

    // 5) std::hash 对照：只有标量/string/指针等的特化，无组合机制
    std::hash<std::string> shs;
    std::cout << "std::hash(string) = " << shs("boost") << '\n';

    std::cout << "自检通过\n";
    return 0;
}
