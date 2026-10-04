// 17 贪心算法（CLRS 第 16 章）。结构：17.1 活动选择（贪心 vs DP 对账，
// 图 16.1 数据）/ 17.2 Huffman（图 16.3 频率，前缀码与平均码长）/
// 17.3 拟阵：单位时间任务调度（图 16.19? 用 16.5 节数据，贪得总收益 230）。
#ifdef ALGO_NO_PRINT
#include <cstdio>
#include <format>
template <class... A> void print(std::format_string<A...> f, A&&... a) {
    std::printf("%s", std::format(f, std::forward<A>(a)...).c_str()); }
template <class... A> void println(std::format_string<A...> f, A&&... a) {
    std::printf("%s\n", std::format(f, std::forward<A>(a)...).c_str()); }
#else
#include <print>
using std::print;
using std::println;
#endif

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <functional>
#include <queue>
#include <string>
#include <vector>

// ═══ 17.1 活动选择问题 ═══
// n 个活动各有 [sᵢ, fᵢ)，选两两不冲突的最大子集。
// CLRS 图 16.1 的 11 个活动（已按 f 排序）。
static const std::vector<int> kS{1, 3, 0, 5, 3, 5, 6, 8, 8, 2, 12};
static const std::vector<int> kF{4, 5, 6, 7, 9, 9, 10, 11, 12, 14, 16};

// 贪心：按最早结束选（CLRS RECURSIVE-ACTIVITY-SELECTOR 的迭代版）
static std::vector<int> greedy_activity() {
    std::vector<int> pick;
    int lastEnd = 0;                       // 虚拟活动 [0,0)
    for (std::size_t i = 0; i < kS.size(); ++i) {
        if (kS[i] >= lastEnd) {
            pick.push_back(static_cast<int>(i));
            lastEnd = kF[i];
        }
    }
    return pick;
}

// DP 对账：c[i,j] = S_ij 的最大兼容活动数（CLRS 16.1 的 DP，暴力 O(n³)）
static int dp_activity(int start, int end) {
    int best = 0;
    for (std::size_t i = 0; i < kS.size(); ++i) {
        if (kS[i] >= start && kF[i] <= end) {
            best = std::max(best, 1 + dp_activity(kF[i], end));
        }
    }
    return best;
}

static void activity_demo() {
    const auto pick = greedy_activity();
    print("活动选择（图 16.1 的 11 个活动，按最早结束贪心）：选中 ");
    for (int i : pick) { print("a{} ", i + 1); }
    println("（共 {} 个）", pick.size());
    assert((pick == std::vector<int>{0, 3, 7, 10}));   // a1 a4 a8 a11
    // 与 DP 对账：贪心选出的数量 = DP 最优值
    const int dpBest = dp_activity(0, 100);
    println("  贪心选中 {} = DP 最优 {}（贪心对活动选择问题可证最优）", pick.size(), dpBest);
    assert(static_cast<int>(pick.size()) == dpBest);
}

// ═══ 17.2 Huffman 编码 ═══
// 图 16.3 的频率：a45 b13 c12 d16 e9 f5（总 100）
struct HuffNode {
    int freq;
    char ch;                    // 内部节点 ch = 0
    int left = -1, right = -1;  // arena 下标
};

static void huffman_demo() {
    const std::vector<std::pair<char, int>> sym{{'a', 45}, {'b', 13}, {'c', 12},
                                                {'d', 16}, {'e', 9}, {'f', 5}};
    std::vector<HuffNode> t;
    // 小顶堆按频率取最小（std::priority_queue 的 Compare 语义：a>b 是大顶，
    // 这里给 greater 反转成小顶）
    using Q = std::pair<int, int>;                    // (freq, 节点下标)
    std::priority_queue<Q, std::vector<Q>, std::greater<Q>> pq;
    for (auto [ch, f] : sym) {
        t.push_back({f, ch});
        pq.push({f, static_cast<int>(t.size()) - 1});
    }
    while (pq.size() > 1) {
        const auto [f1, i1] = pq.top(); pq.pop();
        const auto [f2, i2] = pq.top(); pq.pop();
        t.push_back({f1 + f2, 0, i1, i2});
        pq.push({f1 + f2, static_cast<int>(t.size()) - 1});
    }
    const int rootI = pq.top().second;

    // DFS 生成编码（0 左 1 右）
    std::vector<std::string> codes(128);
    std::function<void(int, std::string)> dfs =
        [&](int i, std::string code) {
            if (t[static_cast<std::size_t>(i)].ch != 0) {
                codes[static_cast<std::size_t>(t[static_cast<std::size_t>(i)].ch)] = code;
                return;
            }
            dfs(t[static_cast<std::size_t>(i)].left, code + "0");
            dfs(t[static_cast<std::size_t>(i)].right, code + "1");
        };
    dfs(rootI, "");

    println("Huffman（频率 a45 b13 c12 d16 e9 f5）：");
    long long total = 0, bits = 0;
    for (auto [ch, f] : sym) {
        print("  {}: {} ", ch, codes[static_cast<std::size_t>(ch)]);
        total += f;
        bits += static_cast<long long>(f) * static_cast<long long>(codes[static_cast<std::size_t>(ch)].size());
    }
    println("");
    println("  平均码长 = {}/{} = {:.2f} 位/符号（定长 3 位，压缩比 {:.0f}%）",
            bits, total, static_cast<double>(bits) / total,
            100.0 - static_cast<double>(bits) / total / 3.0 * 100.0);
    assert(total == 100 && bits == 224);

    // 前缀性质验证：任何码不是其他码的前缀
    bool prefixFree = true;
    for (auto [ch1, f1] : sym) {
        for (auto [ch2, f2] : sym) {
            if (ch1 == ch2) { continue; }
            const auto& c1 = codes[static_cast<std::size_t>(ch1)];
            const auto& c2 = codes[static_cast<std::size_t>(ch2)];
            if (c2.size() >= c1.size() && c2.substr(0, c1.size()) == c1) { prefixFree = false; }
        }
    }
    println("  前缀性质（任一码不是其他码的前缀）= {}", prefixFree ? 1 : 0);
    assert(prefixFree);
}

// ═══ 17.3 拟阵：单位时间任务调度（CLRS 16.5）═══
// 任务 aᵢ：期限 dᵢ、收益 wᵢ，每时间槽干一件，逾期无收益，最大化总收益。
// 独立集判定：「按期限贪心排得下」；拟阵上的贪心（按 w 降序尝试加入）
// 可证最优（定理 16.12）。
struct Task { int deadline, weight, id; };

static bool schedulable(std::vector<Task> set) {
    // 独立判定：按期限排序，逐个放进最早可用槽，看是否都能在期限内
    std::ranges::sort(set, {}, &Task::deadline);
    int slot = 0;
    for (auto&& t : set) {
        ++slot;
        if (slot > t.deadline) { return false; }
    }
    return true;
}

static void matroid_demo() {
    // CLRS 16.5 的 7 个任务：(期限, 收益) = (4,70)(2,60)(4,50)(3,40)(1,30)(4,20)(6,10)
    std::vector<Task> tasks{{4, 70, 1}, {2, 60, 2}, {4, 50, 3}, {3, 40, 4},
                            {1, 30, 5}, {4, 20, 6}, {6, 10, 7}};
    std::ranges::sort(tasks, std::ranges::greater{}, &Task::weight); // 按 w 降序尝试
    std::vector<Task> chosen;
    for (auto&& t : tasks) {
        auto trial = chosen;
        trial.push_back(t);
        if (schedulable(trial)) { chosen = trial; }    // 拟阵贪心：能加就加
    }
    long long total = 0;
    print("拟阵任务调度（按收益降序贪心）：选中 ");
    for (auto&& t : chosen) {
        print("a{} ", t.id);
        total += t.weight;
    }
    println("（总收益 {}）", total);
    assert(total == 230);   // a1+a2+a3+a4+a7 = 70+60+50+40+10
}

int main() {
    activity_demo();
    huffman_demo();
    matroid_demo();
    println("自检通过");
    return 0;
}
