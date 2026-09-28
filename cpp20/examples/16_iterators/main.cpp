#include <forward_list>
#include <iterator>
#include <list>
#include <map>
#include <print>
#include <set>
#include <sstream>
#include <string>
#include <vector>
#include <algorithm>   // copy / sort

// 16 迭代器深入：类目、适配器与辅助函数 —— 容器与算法之间的胶水

int main() {
    // ═══ 16.1 迭代器 = 泛型指针：手写一次 range-for 背后的循环 ═══
    std::vector<int> v{1, 2, 3, 4, 5, 6, 7, 8, 9};
    std::string out;
    for (auto it = v.begin(); it != v.end(); ++it) {   // range-for 就是这段的语法糖
        out += std::to_string(*it);
        if (std::next(it) != v.end()) out += ' ';
    }
    std::println("手写迭代器循环: {}", out);

    // ═══ 16.2 类目：C++20 概念在编译期验票 ═══
    static_assert(std::random_access_iterator<std::vector<int>::iterator>, "vector 是随机访问");
    static_assert(std::contiguous_iterator<std::vector<int>::iterator>, "vector 还是连续的");
    static_assert(std::bidirectional_iterator<std::list<int>::iterator>, "list 是双向");
    static_assert(std::forward_iterator<std::forward_list<int>::iterator>, "forward_list 是前向");
    static_assert(std::bidirectional_iterator<std::map<int, int>::iterator>, "map 是双向（不是随机访问）");
    // std::sort(v.begin(), v.end()) 对 list 编译错——随机访问类目不够；
    // list 得用自己的成员 sort()：
    std::list<int> lst{5, 3, 9, 1, 7};
    lst.sort();                                        // 链表自己的归并排序
    std::println("list 成员 sort: {} {} {} {} {}", lst.front(), *std::next(lst.begin()),
                 *std::next(lst.begin(), 2), *std::next(lst.begin(), 3), lst.back());

    // ═══ 16.3 辅助函数：next / prev / distance / advance ═══
    std::map<std::string, int> ages{{"ada", 36}, {"cpp", 43}, {"rust", 11}};
    auto second = std::next(ages.begin());             // 副本前进一格（不动原值）
    std::println("map 第 2 项: {} = {}", second->first, second->second);
    std::println("distance(begin, next(begin,2)) = {}", std::distance(ages.begin(), std::next(ages.begin(), 2)));
    std::vector<int>::iterator big = v.begin();
    std::advance(big, 7);                              // 原地前进（advance 改自己，next 给副本）
    std::println("advance 7 格再 prev 1 格: {}", *std::prev(big));

    // ═══ 16.4 反向迭代器：rbegin 指最后一个元素 ═══
    std::string rev;
    for (auto rit = v.rbegin(); rit != v.rend(); ++rit) {   // ++ 在这里是“后退”
        rev += std::to_string(*rit);
        if (std::next(rit) != v.rend()) rev += ' ';
    }
    std::println("反向遍历: {}", rev);

    // ═══ 16.5 插入迭代器：目标容器不用预分配 ═══
    std::vector<int> src{3, 1, 4, 1, 5, 9, 2, 6};
    std::vector<int> dst;                              // 空！
    std::copy(src.begin(), src.end(), std::back_inserter(dst));   // 写入=push_back
    std::println("back_inserter 拷贝 ({} 个): {}", dst.size(), dst.size() == src.size());

    std::list<int> rev_insert;
    std::copy(src.begin(), src.begin() + 4, std::front_inserter(rev_insert));   // 倒序！
    std::string fwd;
    for (int e : rev_insert) fwd += std::to_string(e) + ' ';
    std::println("front_inserter 前 4 个 → 倒过来: {}", fwd);

    std::set<int> uniq;                                // inserter + set = 拷贝即有序去重
    std::copy(src.begin(), src.end(), std::inserter(uniq, uniq.end()));
    std::string u;
    for (int e : uniq) u += std::to_string(e) + ' ';
    std::println("inserter 进 set (去重): {}", u);

    // ═══ 16.6 流迭代器：迭代器对当区间，流当容器 ═══
    std::istringstream input{"10 20 30 40"};           // 键盘替身（真实场景是 std::cin，见第 32 章）
    std::istream_iterator<int> read{input}, eof{};     // eof 是流末哨兵
    std::vector<int> nums{read, eof};                  // 迭代器对直接构造 vector
    int sum = 0;
    for (int n : nums) sum += n;
    std::println("流迭代器读入 {} 个，合计 = {}", nums.size(), sum);

    std::ostringstream sink;
    std::copy(nums.begin(), nums.end(), std::ostream_iterator<int>{sink, " "});
    std::println("ostream_iterator 写回流: [{}]", sink.str());   // 分隔符是后缀——尾巴也带

    // ═══ 16.7 move_iterator：解引用变右值，拷贝变搬空 ═══
    std::vector<std::string> words{"alpha", "beta", "gamma"};
    std::vector<std::string> taken{std::make_move_iterator(words.begin()),
                                    std::make_move_iterator(words.end())};
    std::println("搬走后源串为空: {} {} {}", words[0].empty(), words[1].empty(), words[2].empty());
    std::println("搬进新家: {} {} {}", taken[0], taken[1], taken[2]);

    std::println("自检通过");
}
