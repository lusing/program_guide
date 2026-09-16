#include <algorithm>
#include <functional>
#include <numeric>
#include <print>
#include <string>
#include <vector>

// 11 算法与 lambda：谓词、捕获、std::function

int main() {
    std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6, 5, 3};

    // ═══ 11.1 sort：默认与自定义比较器 ═══
    std::vector<int> a = nums;
    std::sort(a.begin(), a.end());
    std::print("升序: ");
    for (int v : a) {
        std::print("{} ", v);
    }
    std::println("");

    std::vector<std::string> words{"pineapple", "fig", "banana", "kiwi"};
    std::sort(words.begin(), words.end(),
              [](const std::string& x, const std::string& y) {
                  return x.size() < y.size();  // 短的排前面
              });
    std::print("按长度: ");
    for (const auto& w : words) {
        std::print("{} ", w);  // fig kiwi banana pineapple
    }
    std::println("");

    // ═══ 11.2 查找与计数：谓词是核心 ═══
    auto it = std::find_if(nums.begin(), nums.end(), [](int v) { return v > 8; });
    std::println("第一个 >8 的数 = {}", *it);  // 9
    std::println("偶数 {} 个", std::count_if(nums.begin(), nums.end(),
                                             [](int v) { return v % 2 == 0; }));
    std::println("全是正数？{}",
                 std::all_of(nums.begin(), nums.end(), [](int v) { return v > 0; }));

    // ═══ 11.3 accumulate 与 transform ═══
    int sum = std::accumulate(nums.begin(), nums.end(), 0);
    std::vector<int> doubled(nums.size());
    std::transform(nums.begin(), nums.end(), doubled.begin(),
                   [](int v) { return v * 2; });
    std::println("sum = {}，doubled.back() = {}", sum, doubled.back());

    // ═══ 11.4 捕获：lambda 的记忆 ═══
    int threshold = 4;
    auto by_value = [threshold](int v) { return v > threshold; };  // 值捕获：快照
    auto by_ref = [&threshold](int v) { return v > threshold; };  // 引用捕获：实时
    threshold = 6;  // 改给引用捕获看
    std::println("值捕获 >4：{} 个；引用捕获 >6：{} 个",
                 std::count_if(nums.begin(), nums.end(), by_value),
                 std::count_if(nums.begin(), nums.end(), by_ref));

    // ═══ 11.5 泛型 lambda 与 std::function ═══
    auto show = [](const auto& x) { std::println("值 = {}", x); };
    show(42);
    show(3.5);
    show(std::string("文本"));
    std::function<int(int)> f = [](int v) { return v * v; };
    f = [sum](int v) { return v + sum; };  // std::function 可重新绑定
    std::println("f(3) = {}", f(3));
    std::println("自检通过");
}
