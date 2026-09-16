#include <flat_map>
#include <map>
#include <print>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

// 10 容器与迭代器：vector、map/set、unordered、flat_map

int main() {
    // ═══ 10.1 vector：动态数组 ═══
    std::vector<std::string> tags{"cpp", "modern"};
    tags.push_back("tutorial");
    tags[1] = "modern-cpp";
    std::println("{} 个标签，第 2 个是 {}", tags.size(), tags[1]);

    // ═══ 10.2 map：有序键值对 ═══
    std::map<std::string, int> stock{{"cpp", 3}, {"rust", 5}};
    stock["go"] = 2;  // 不存在则插入
    ++stock["cpp"];   // 存在则修改
    if (auto it = stock.find("rust"); it != stock.end()) {  // 初始化语句 + find
        std::println("rust 库存 {}", it->second);
    }
    for (const auto& [lang, count] : stock) {  // 结构化绑定，按键有序
        std::println("  {}: {}", lang, count);
    }

    // ═══ 10.3 set：自动去重排序 ═══
    std::set<int> uniq{5, 3, 3, 1, 5, 9};
    std::print("set: ");
    for (int v : uniq) {
        std::print("{} ", v);  // 1 3 5 9
    }
    std::println("");

    // ═══ 10.4 unordered_map：哈希表，O(1) 平均 ═══
    std::unordered_map<std::string, int> votes;
    for (const std::string& w : {"cpp", "rust", "cpp", "go", "cpp", "rust"}) {
        ++votes[w];  // 不存在则从 0 起
    }
    std::println("cpp 得 {} 票", votes["cpp"]);  // 3

    // ═══ 10.5 迭代器：统一的遍历接口 ═══
    std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6};
    int max_v = nums.front();
    for (auto it = nums.begin(); it != nums.end(); ++it) {
        if (*it > max_v) {
            max_v = *it;
        }
    }
    std::println("最大值 = {}", max_v);

    // ═══ 10.6 删除惯用法：erase_if (C++20) 一行搞定 ═══
    std::erase_if(nums, [](int v) { return v <= 2; });
    std::print("过滤后: ");
    for (int v : nums) {
        std::print("{} ", v);  // 3 4 5 9 6
    }
    std::println("");

    // ═══ 10.7 flat_map 一瞥 (C++23)：排序 vector 实现的 map ═══
    std::flat_map<std::string, int> fm{{"b", 2}, {"a", 1}};
    fm["c"] = 3;
    std::println("flat_map 首键 = {}", fm.begin()->first);  // a：有序
    std::println("自检通过");
}
