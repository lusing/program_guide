// unordered.cpp —— Boost.Unordered：哈希容器的现代重制（std::unordered_* 之外的增量）
// 对应文档：docs/08-unordered.md
#include <boost/unordered/unordered_map.hpp>
#include <boost/unordered/unordered_set.hpp>
#include <iostream>
#include <string>
#include <unordered_map>

struct Point {
    int x, y;
    bool operator==(const Point& o) const { return x == o.x && y == o.y; }
};

// 自定义类型进哈希容器：std 要手写 hash 特化；boost 提供 hash_value 就行
std::size_t hash_value(const Point& p) {
    std::size_t seed = 0;
    boost::hash_combine(seed, p.x);
    boost::hash_combine(seed, p.y);
    return seed;
}

int main() {
    // 1) 基本面：与 std::unordered_map 同构
    boost::unordered_map<std::string, int> ages{{"ada", 36}, {"grace", 85}};
    ages["jean"] = 74;
    std::cout << "3 位: " << ages.size() << " ada=" << ages.at("ada") << '\n';

    // 2) 桶模型：元素按哈希落桶；负载因子超过上限自动 rehash 扩桶
    std::cout << "桶数 = " << ages.bucket_count()
              << "（3 个元素至少 3 桶）每个键的桶号 = "
              << ages.bucket("ada") << '/' << ages.bucket("jean")
              << " ada 桶内元素数 = " << ages.bucket_size(ages.bucket("ada")) << '\n';
    ages.reserve(100);          // 预约容量：一次 rehash 到位（避免逐个扩）
    std::cout << "reserve(100) 后桶数 = " << ages.bucket_count()
              << " 上限负载因子 = " << ages.max_load_factor() << '\n';
    ages.rehash(200);           // 直接指定最小桶数
    std::cout << "rehash(200) 后桶数 >= 200? " << std::boolalpha
              << (ages.bucket_count() >= 200) << '\n';

    // 3) 自定义类型 + boost::hash
    boost::unordered_set<Point> points;
    points.insert({1, 2});
    points.insert({1, 2});          // 重复插入无效
    points.insert({3, 4});
    std::cout << "点集大小 = " << points.size() << "（{1,2} 只进一次）\n";

    // 4) boost 独有增量：等价键的"重复插入"视图（std 没有）
    boost::unordered_multimap<std::string, int> mm;
    mm.insert({"k", 1});
    mm.insert({"k", 2});
    auto range = mm.equal_range("k");
    int count = 0;
    for (auto it = range.first; it != range.second; ++it) ++count;
    std::cout << "multimap 中 k 出现 " << count << " 次\n";

    // 5) std 对照：同样的用法
    std::unordered_map<std::string, int> std_ages{{"ada", 36}};
    std_ages["grace"] = 85;
    std::cout << "std 版大小 = " << std_ages.size() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
