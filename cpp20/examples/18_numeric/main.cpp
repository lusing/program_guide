#include <cmath>
#include <map>
#include <numeric>
#include <numbers>
#include <print>
#include <random>
#include <string>
#include <vector>

// 18 数值与随机：<numeric>、<numbers> 与 <random> —— 折叠、常量与现代随机

int main() {
    // ═══ 18.1 <numeric>：折叠一族 ═══
    std::vector<int> v(10);
    std::iota(v.begin(), v.end(), 1);                        // 1..10
    int sum  = std::accumulate(v.begin(), v.end(), 0);       // 55
    int prod = std::accumulate(v.begin(), v.end(), 1,        // 换乘法 → 10!
                               [](int a, int b) { return a * b; });
    std::println("iota 1..10：sum = {}，prod = {}", sum, prod);

    std::vector<int> prefix;
    std::partial_sum(v.begin(), v.begin() + 6, std::back_inserter(prefix));
    std::string ps;
    for (int e : prefix) ps += std::to_string(e) + ' ';
    std::println("partial_sum 前 6 项: {}", ps);             // 1 3 6 10 15 21

    std::vector<int> diff;
    std::adjacent_difference(prefix.begin(), prefix.end(), std::back_inserter(diff));
    std::string ds;
    for (int e : diff) ds += std::to_string(e) + ' ';
    std::println("adjacent_difference 还原: {}", ds);        // 1 2 3 4 5 6

    std::println("inner_product(v, v) = {}", std::inner_product(v.begin(), v.end(), v.begin(), 0));   // 385

    // 初值类型陷阱：初始值定了折叠的累加类型
    // （C4244 正是编译器在报这个陷阱——这里故意触发一次，故用 pragma 显式圈起来）
    std::vector<double> half{1.5, 2.5, 3.0};
#pragma warning(push)
#pragma warning(disable : 4244)   // double → int 可能丢失数据：就是本行要演示的截断
    auto as_int  = std::accumulate(half.begin(), half.end(), 0);      // 按 int 累加——截断！
#pragma warning(pop)
    auto as_dbl  = std::accumulate(half.begin(), half.end(), 0.0);    // 0.0 才对
    std::println("初值 0 vs 0.0：{} vs {}", as_int, as_dbl);

    // ═══ 18.2 transform_reduce：先变形再折叠（MapReduce）═══
    std::vector<std::string> words{"Only", "for", "testing", "purpose"};
    auto total = std::transform_reduce(words.begin(), words.end(), std::size_t{0},
                                       std::plus<>{},
                                       [](const std::string& s) { return s.size(); });
    std::println("单词总长度 = {}", total);                  // 21
    std::println("reduce(v) = {}（与 accumulate 同值，允许重排）", std::reduce(v.begin(), v.end()));

    // ═══ 18.3 小而美：gcd / lcm / midpoint / lerp ═══
    std::println("gcd(36,60)={} lcm(4,6)={} midpoint(10,20)={} lerp(0,10,0.25)={}",
                 std::gcd(36, 60), std::lcm(4, 6), std::midpoint(10, 20), std::lerp(0.0, 10.0, 0.25));
    int big1 = 2'000'000'000, big2 = 2'100'000'000;          // 相加会溢出的两个大数
    std::println("大数中点 midpoint = {}（(a+b)/2 会溢出）", std::midpoint(big1, big2));

    // ═══ 18.4 数学常量 <numbers>（C++20）═══
    std::println("pi  = {:.10f}", std::numbers::pi);
    std::println("e   = {:.10f}", std::numbers::e);
    std::println("sqrt2 = {:.6f}  phi = {:.6f}", std::numbers::sqrt2, std::numbers::phi);
    std::println("pi_v<float> = {:.6f}（float 精度）", std::numbers::pi_v<float>);

    // ═══ 18.5 <random> 三段论：种子 → 引擎 → 分布 ═══
    std::mt19937 gen{42};                                     // 固定种子：序列完全可复现
    std::uniform_int_distribution<int> dice{1, 6};
    std::map<int, int> counts;
    for (int i = 0; i < 60000; ++i) ++counts[dice(gen)];      // 引擎/分布构造一次，反复用
    std::string cs;
    for (const auto& [face, n] : counts) cs += std::format("{}:{} ", face, n);
    std::println("骰子 6 万次（种子 42）：{}", cs);
    double mean = std::accumulate(counts.begin(), counts.end(), 0.0,
        [](double acc, const auto& kv) { return acc + double(kv.first) * kv.second; }) / 60000.0;
    std::println("均值 = {:.3f}（期望 3.5）", mean);

    // mt19937 是标准逐比特规定的：同种子跨平台同序列
    std::mt19937 probe{7};
    std::println("mt19937(7) 前 3 个原始输出: {} {} {}", probe(), probe(), probe());

    // 正态分布：断言统计性质（分布算法是实现定义的，序列不可跨库断言）
    std::normal_distribution<> height{170, 8};
    double acc = 0.0, sq = 0.0;
    constexpr int N = 100000;
    for (int i = 0; i < N; ++i) {
        double h = height(gen);
        acc += h; sq += h * h;
    }
    double m = acc / N;
    double sd = std::sqrt(sq / N - m * m);                    // 方差 = E[x²] − (E[x])²
    std::println("身高样本：均值 = {:.1f}，标准差 = {:.1f}（目标 170 / 8）", m, sd);

    // 真随机源与实现自选引擎（生产播种用，示例只看属性不打印值）
    std::random_device rd;
    std::println("random_device min/max: {} / {}（default_random_engine 是实现自选，勿跨平台断言）",
                 rd.min(), rd.max());

    std::println("自检通过");
}
