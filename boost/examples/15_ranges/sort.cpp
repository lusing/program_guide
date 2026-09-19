// sort.cpp —— Boost.Sort：超越 std::sort 的排序军火库
// 对应文档：docs/15-ranges.md
// spreadsort（整数/浮点基数排序）、pdqsort（分支友好的快排变体）、
// block_indirect_sort（并行排序）。
#include <boost/sort/sort.hpp>
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

struct Record {
    std::uint32_t key;
    std::string name;
    bool operator<(const Record& o) const { return key < o.key; }   // integer_sort 的兜底比较
};

int main() {
    // 1) integer_sort：整键排序——比 std::sort 快 2-5 倍（O(n·k/log n)）
    //    注意：spreadsort 是命名空间，函数是 spreadsort::integer_sort 等
    std::vector<std::uint32_t> keys{42u, 7u, 1990u, 3u, 999999u, 128u};
    boost::sort::spreadsort::integer_sort(keys.begin(), keys.end());
    std::cout << "integer_sort:";
    for (auto k : keys) std::cout << ' ' << k;
    std::cout << '\n';

    // 2) float_sort：浮点基数排序（把 float 位模式映射成可基数排序的整数）
    std::vector<float> fs{3.5f, 1.25f, 2.75f, 0.5f};
    boost::sort::spreadsort::float_sort(fs.begin(), fs.end());
    std::cout << "float_sort: ";
    for (float f : fs) std::cout << f << ' ';
    std::cout << '\n';

    // 3) string_sort：字符串基数排序
    std::vector<std::string> words{"pear", "apple", "fig", "banana"};
    boost::sort::spreadsort::string_sort(words.begin(), words.end());
    std::cout << "string_sort: ";
    for (auto& w : words) std::cout << w << ' ';
    std::cout << '\n';

    // 4) 对结构体按键排序：提供"取出键"的位移钩子
    std::vector<Record> recs{{50, "e"}, {10, "a"}, {30, "c"}, {20, "b"}};
    boost::sort::spreadsort::integer_sort(
        recs.begin(), recs.end(),
        [](Record const& r, unsigned offset) { return r.key >> offset; });  // 位移钩子
    std::cout << "按 key: ";
    for (auto& r : recs) std::cout << r.key << r.name << ' ';
    std::cout << '\n';

    // 5) pdqsort：单线程通用排序的"现代快排"（std::sort 的强力平替）
    std::vector<int> ints{5, 3, 9, 1, 7};
    boost::sort::pdqsort(ints.begin(), ints.end());
    std::cout << "pdqsort: ";
    for (int x : ints) std::cout << x << ' ';
    std::cout << '\n';

    std::cout << "自检通过\n";
    return 0;
}
