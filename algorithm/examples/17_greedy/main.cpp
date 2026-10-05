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
#include <bit>
#include <cassert>
#include <cstdint>
#include <deque>
#include <functional>
#include <numeric>
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

// ═══ 17.4 交换论证：把分配问题归约为选 top-k 差值 ═══
// n 个朋友，第 i 个有属性 (Xᵢ, Yᵢ)；两种礼物属性 (A₁,B₁)、(A₂,B₂)，数量
// k₁、k₂（k₁+k₂ ≥ n，礼物可剩）。每人一件，最大化总开心值。
//   v₁(i) = A₁Xᵢ + B₁Yᵢ   拿礼物 1 的开心值
//   v₂(i) = A₂Xᵢ + B₂Yᵢ   拿礼物 2 的开心值
// **差值化归约**：令 Δᵢ = v₁(i) − v₂(i)，S = 「拿到礼物 1 的人」的集合，则
//   总开心值 = Σᵢ v₂(i) + Σ_{i∈S} Δᵢ
// ��� Σv₂ 与 S 无关是常数 ⟹ 「选 |S| ≤ k₁ 最大化 ΣΔᵢ」，即「排序取 top-k」。
struct Friend2 { long long x, y, v1, v2, delta; int id; };

static std::vector<Friend2> make_friends(const std::vector<std::pair<long long, long long>>& xy,
                                         long long a1, long long b1,
                                         long long a2, long long b2) {
    std::vector<Friend2> r;
    for (std::size_t i = 0; i < xy.size(); ++i) {
        Friend2 f{};
        f.x = xy[i].first;
        f.y = xy[i].second;
        f.v1 = a1 * f.x + b1 * f.y;
        f.v2 = a2 * f.x + b2 * f.y;
        f.delta = f.v1 - f.v2;
        f.id = static_cast<int>(i) + 1;
        r.push_back(f);
    }
    return r;
}

// 正确解：按 Δ 降序取前 t = min(k₁, 正 Δ 个数) 个
static long long solve_by_delta(std::vector<Friend2> fs, int k1, std::vector<int>& picked) {
    std::ranges::sort(fs, std::ranges::greater{}, &Friend2::delta);
    int t = 0;
    while (t < k1 && t < static_cast<int>(fs.size()) && fs[static_cast<std::size_t>(t)].delta > 0) {
        ++t;
    }
    long long ans = 0;
    picked.clear();
    for (std::size_t i = 0; i < fs.size(); ++i) {
        if (static_cast<int>(i) < t) { ans += fs[i].v1; picked.push_back(fs[i].id); }
        else { ans += fs[i].v2; }
    }
    return ans;
}

// **错误直觉**：先按 v₁ > v₂ 分组到 S₁/S₂，若 |S₁| > k₁ 就把 S₁ 里
// 「礼物 1 开心值最小」的搬到 S₂。这个搬移规则是错的——该搬 Δ 最小的。
static long long solve_wrong_by_v1(std::vector<Friend2> fs, int k1) {
    std::vector<Friend2> s1, s2;
    for (const auto& f : fs) { (f.v1 > f.v2 ? s1 : s2).push_back(f); }
    if (static_cast<int>(s1.size()) > k1) {
        // 按 v1 升序搬走前 (|S₁| − k₁) 个 —— 错误规则
        std::ranges::sort(s1, {}, &Friend2::v1);
        const std::size_t move = s1.size() - static_cast<std::size_t>(k1);
        for (std::size_t i = 0; i < move; ++i) { s2.push_back(s1[i]); }
        s1.erase(s1.begin(), s1.begin() + static_cast<std::ptrdiff_t>(move));
    }
    long long ans = 0;
    for (const auto& f : s1) { ans += f.v1; }
    for (const auto& f : s2) { ans += f.v2; }
    return ans;
}

static void delta_topk_demo() {
    // 样例：A₁=3, B₁=4, A₂=4, B₂=3，n=4, k₁=k₂=3
    // Δ = (A₁−A₂)X + (B₁−B₂)Y = −X + Y
    const std::vector<std::pair<long long, long long>> xy{{1, 4}, {3, 5}, {5, 3}, {2, 6}};
    std::vector<Friend2> fs = make_friends(xy, 3, 4, 4, 3);
    const int k1 = 3, k2 = 3;

    println("=== 17.4 交换论证：分配问题归约为选 top-k 差值 ===");
    print("  A₁=3 B₁=4 / A₂=4 B₂=3，k₁={} k₂={}；Δᵢ = v₁(i) − v₂(i) = (A₁−A₂)Xᵢ + (B₁−B₂)Yᵢ\n",
          k1, k2);
    println("  编号   X   Y    v₁    v₂    Δ");
    for (const auto& f : fs) {
        println("   p{}  {:3} {:3}  {:4}  {:4}  {:4}", f.id, f.x, f.y, f.v1, f.v2, f.delta);
    }
    const long long base = std::accumulate(fs.begin(), fs.end(), 0LL,
        [](long long acc, const Friend2& f) { return acc + f.v2; });
    println("  常数项 Σv₂ = {}（与 S 无关）", base);

    std::vector<int> picked;
    const long long best = solve_by_delta(fs, k1, picked);
    print("  按 Δ 降序取 top-{}：拿礼物 1 的是 p", k1);
    for (std::size_t i = 0; i < picked.size(); ++i) {
        print("{}{}", picked[i], i + 1 == picked.size() ? "" : "、");
    }
    println("，总开心值 = {} = Σv₂ + Σ_S Δ = {} + {}", best, base, best - base);
    assert(best == 107);

    // 暴力枚举全部合法分配（|S| ≤ k₁ 且 n−|S| ≤ k₂）对账
    {
        const std::size_t n = fs.size();
        long long brute = 0;
        bool first = true;
        for (std::uint64_t mask = 0; mask < (std::uint64_t{1} << n); ++mask) {
            const int cnt = std::popcount(mask);
            if (cnt > k1 || static_cast<int>(n) - cnt > k2) { continue; }
            long long v = 0;
            for (std::size_t i = 0; i < n; ++i) {
                v += ((mask >> i) & 1U) ? fs[i].v1 : fs[i].v2;
            }
            if (first || v > brute) { brute = v; first = false; }
        }
        assert(best == brute);
        println("  暴力枚举 2^{} 个分配的最大值 = {}（对账一致 = 1）", n, brute);
    }

    // 错误直觉的反例：v₁ 的大小顺序与 Δ 的大小顺序**不同构**（权重不同）
    // A₁=3 B₁=4 / A₂=4 B₂=3 ⟹ v₁ = 3X+4Y，Δ = Y−X
    // p_a = (1,10)：v₁ = 43, Δ = 9  ← v₁ 大、Δ 也大
    // p_b = (3, 4)：v₁ = 25, Δ = 1  ← v₁ 小、Δ 也小
    // 这组看不出差别；换一组让两个序**反向**：
    // p_c = (1, 5)：v₁ = 23, Δ = 4   （v₁ 较小，Δ 较大）
    // p_d = (3, 4)：v₁ = 25, Δ = 1   （v₁ 较大，Δ 较小）
    // 取 k₁ = 1：正确解应拿 Δ 大的 p_c（Δ=4）；按 v₁ 最小搬走却会把 p_c 搬走。
    const std::vector<std::pair<long long, long long>> xy2{{1, 5}, {3, 4}};
    const std::vector<Friend2> fs2 = make_friends(xy2, 3, 4, 4, 3);
    std::vector<int> pk2;
    const long long best2 = solve_by_delta(fs2, 1, pk2);
    const long long wrong2 = solve_wrong_by_v1(fs2, 1);
    println("  错误直觉反例：两人 (1,5) 与 (3,4)，k₁ = 1");
    println("    p1 = (1,5)：v₁ = {}，Δ = {}    p2 = (3,4)：v₁ = {}，Δ = {}",
            fs2[0].v1, fs2[0].delta, fs2[1].v1, fs2[1].delta);
    println("    正确（按 Δ 最大拿礼物 1 = p{}）总开心值 = {}；错误直觉（搬 v₁ 最小者 = p1）= {}",
            pk2.empty() ? 0 : pk2[0], best2, wrong2);
    assert(best2 > wrong2);
    println("    ⟹ 「搬 v₁ 最小者」搬错了人：v₁ 与 Δ 的权重不同（v₁ 中 X、Y 系数为 3、4；"
            "Δ 中为 −1、1），两个序不同构");
    // 「Δ 相同但 v₁ 不同」—— 偏序不同构的直接证据
    const std::vector<Friend2> fs3 = make_friends({{0, 3}, {3, 6}}, 3, 4, 4, 3);
    println("    佐证：(0,3) 与 (3,6) 的 Δ 都是 {}，但 v₁ 分别是 {} 与 {} ⟹ 谈 Δ 时不能看 v₁",
            fs3[0].delta, fs3[0].v1, fs3[1].v1);
    assert(fs3[0].delta == fs3[1].delta && fs3[0].v1 != fs3[1].v1);

    // else-if 漏处理：两侧同时超限
    const std::vector<Friend2> fs4 = make_friends({{1, 2}, {2, 3}, {3, 4}}, 3, 4, 4, 3);
    std::vector<int> pk4;
    const long long best4 = solve_by_delta(fs4, 1, pk4);
    println("  else-if 漏处理：3 人 Δ 全为正，k₁ = k₂ = 1（两侧同时超限）⟹ 正确答案 = {}（{} 人拿礼物 1）",
            best4, pk4.size());
    assert(pk4.size() == 1);
}

// ═══ 17.5 稳定匹配：Gale-Shapley 与拒绝不动点论证 ═══
// n 男 n 女，各自给出对异性的完整偏好序。求**男性最优**的稳定完美匹配。
// 内层判定必须 O(1)：用 rank[w][m]（w 对 m 的排名，越小越好）与当前
// 最差者的 rank 比较，配上男生提案游标 nextIdx[m]。用 BST 存婚约集会让
// 内层变 O(lg n)，总复杂度多带一个 lg n（Θ(n² lg n) vs Θ(n²)）。
struct StableMatching {
    int n = 0;
    std::vector<std::vector<int>> pref;   // pref[m] = m 眼中女生的顺序（存女生下标）
    std::vector<std::vector<int>> rank;   // rank[w][m] = w 眼中男生的排名
    std::vector<int> husband;             // husband[w] = w 的丈夫（-1 未订婚）
    std::vector<int> worstRank;           // w 当前最差丈夫的 rank（+∞ 视作未订婚）
    std::vector<int> nextIdx;             // 男生提案游标
    long long proposals = 0;
};

static void stable_marriage_demo() {
    const int n = 4;
    // 男 m 的偏好序（存女生下标，0..3）；女 w 的偏好序（存男生下标）
    // 这组数据会真的发生「顶替」：w2 先接受 m1，后被更喜欢的 m2 顶掉，m1 重新入队
    const std::vector<std::vector<int>> menPref{
        {3, 1, 0, 2},   // m0: w3 > w1 > w0 > w2
        {2, 1, 0, 3},   // m1: w2 > w1 > w0 > w3
        {2, 0, 1, 3},   // m2: w2 > w0 > w1 > w3
        {1, 0, 2, 3},   // m3: w1 > w0 > w2 > w3
    };
    const std::vector<std::vector<int>> womenPref{
        {0, 1, 2, 3},   // w0: m0 > m1 > m2 > m3
        {1, 3, 0, 2},   // w1: m1 > m3 > m0 > m2
        {3, 2, 1, 0},   // w2: m3 > m2 > m1 > m0
        {3, 1, 0, 2},   // w3: m3 > m1 > m0 > m2
    };
    // rank[w][m]：w 眼中 m 的排名（0 最好）
    std::vector<std::vector<int>> womenRankOfMan(static_cast<std::size_t>(n),
                                                 std::vector<int>(static_cast<std::size_t>(n), 0));
    for (int w = 0; w < n; ++w) {
        for (int r = 0; r < n; ++r) {
            womenRankOfMan[static_cast<std::size_t>(w)][static_cast<std::size_t>(womenPref[static_cast<std::size_t>(w)][static_cast<std::size_t>(r)])] = r;
        }
    }

    // Gale-Shapley：维护**自由男队列**。被喜欢的女生甩掉的男生要**重新入队**
    // 继续往下提案——这正是「每个男最多提 n 次、每次 O(1)」的由来。
    StableMatching s;
    s.n = n;
    s.pref = menPref;
    s.rank = womenRankOfMan;
    s.husband.assign(static_cast<std::size_t>(n), -1);
    s.worstRank.assign(static_cast<std::size_t>(n), 1 << 30);
    s.nextIdx.assign(static_cast<std::size_t>(n), 0);
    std::deque<int> freeMen;
    for (int m = 0; m < n; ++m) { freeMen.push_back(m); }
    while (!freeMen.empty()) {
        const int m = freeMen.front();
        freeMen.pop_front();
        const int w = menPref[static_cast<std::size_t>(m)]
                           [static_cast<std::size_t>(s.nextIdx[static_cast<std::size_t>(m)])];
        ++s.nextIdx[static_cast<std::size_t>(m)];
        ++s.proposals;
        const int rm = s.rank[static_cast<std::size_t>(w)][static_cast<std::size_t>(m)];
        if (rm < s.worstRank[static_cast<std::size_t>(w)]) {
            // w 更想要 m：与旧丈夫（若有）解除婚约，旧丈夫重新变成自由男
            if (s.husband[static_cast<std::size_t>(w)] != -1) {
                freeMen.push_back(s.husband[static_cast<std::size_t>(w)]);
            }
            s.husband[static_cast<std::size_t>(w)] = m;
            // 关键：这里必须**直接赋值**而不是取 max。worstRank 的语义是
            // 「当前丈夫的 rank」，而 max 累积的是「她历史上收到过的最差
            // rank」——被甩掉的旧丈夫不再占位，累积值会偏大，导致后来的
            // 更差的人被误判为「比当前丈夫好」而顶替之。
            s.worstRank[static_cast<std::size_t>(w)] = rm;
        } else {
            freeMen.push_back(m);   // 被拒，继续下一位
        }
    }

    // 收集匹配：wife[m] = m 的妻子
    std::vector<int> wife(static_cast<std::size_t>(n), -1);
    for (int w = 0; w < n; ++w) {
        assert(s.husband[static_cast<std::size_t>(w)] != -1);
        wife[static_cast<std::size_t>(s.husband[static_cast<std::size_t>(w)])] = w;
    }
    for (int m = 0; m < n; ++m) { assert(wife[static_cast<std::size_t>(m)] != -1); }

    println("=== 17.5 稳定匹配：Gale-Shapley（内层 O(1) ⟹ Θ(n²)）===");
    println("  n = {}，男生按提案顺序依次尝试", n);
    print("  男 m0..m{} 的偏好 = ", n - 1);
    for (int m = 0; m < n; ++m) {
        print("[");
        for (int k = 0; k < n; ++k) {
            print("w{}{}", menPref[static_cast<std::size_t>(m)][static_cast<std::size_t>(k)],
                  k + 1 == n ? "" : " ");
        }
        print("]{}", m + 1 == n ? "" : " ");
    }
    println("");
    print("  匹配（本例男方提议所得）: ");
    for (int m = 0; m < n; ++m) { print("m{}→w{} ", m, wife[static_cast<std::size_t>(m)]); }
    println("");
    println("  总提案次数 = {}（最坏 n² = {}，每次内层 O(1) ⟹ 总 Θ(n²)）",
            s.proposals, n * n);

    // 验证 1：完美匹配
    int matched = 0;
    for (int w = 0; w < n; ++w) { if (s.husband[static_cast<std::size_t>(w)] != -1) { ++matched; } }
    assert(matched == n);
    println("  引理「完美性」：匹配边数 = {} = n，全部人均已配对 = 1", matched);

    // 验证 2：稳定性（无阻塞对）
    const auto rankOf = [&](int w, int m) { return s.rank[static_cast<std::size_t>(w)][static_cast<std::size_t>(m)]; };
    // m 眼中 w 的名次（0 最好）。用「名次比大小」而不是「扫到就返回」——
    // 后者在 w1 == w2 时会误判成「更偏好」。
    const auto manRankOf = [&](int m, int w) {
        const auto& p = menPref[static_cast<std::size_t>(m)];
        for (int k = 0; k < n; ++k) {
            if (p[static_cast<std::size_t>(k)] == w) { return k; }
        }
        return n;
    };
    const auto manPrefers = [&](int m, int w1, int w2) {
        return manRankOf(m, w1) < manRankOf(m, w2);
    };
    int blocking = 0;
    for (int m = 0; m < n; ++m) {
        for (int w = 0; w < n; ++w) {
            if (w == wife[static_cast<std::size_t>(m)]) { continue; }
            // rankOf 的第二参是**男**下标：w 自己的丈夫是 husband[w]，
            // 不能写成 wife[w]（那是用女下标去查男排名表，越界/错位）。
            if (manPrefers(m, w, wife[static_cast<std::size_t>(m)])
                && rankOf(w, m) < rankOf(w, s.husband[static_cast<std::size_t>(w)])) {
                ++blocking;   // (m,w) 互相更偏好 ⟹ 阻塞对
            }
        }
    }
    assert(blocking == 0);
    println("  引理「稳定性」：遍历全部 {}×{} = {} 对（m, w），阻塞对（互相更偏好）数 = {}",
            n, n, n * n, blocking);

    // 验证 3：男性最优（每个男都拿到他能得到的最好搭档）
    // 枚举 n! 个完美匹配，找出所有稳定匹配，检查没有稳定匹配能让某个男更满意
    {
        std::vector<int> perm(static_cast<std::size_t>(n));
        std::iota(perm.begin(), perm.end(), 0);
        long long stableCount = 0;
        bool manOptimal = true;
        do {
            // perm[m] = m 的妻子。完美匹配稳定 ⟺ **不存在阻塞对**：没有一对
            // (m, w)（w ≠ perm[m]）使得 m 更偏好 w **且** w 更偏好 m。
            // 注意两个条件都要查——只查女方会把「男方单方面更偏好」误判为稳定。
            bool stable = true;
            for (int m = 0; m < n && stable; ++m) {
                const int wOwn = perm[static_cast<std::size_t>(m)];
                for (int w = 0; w < n; ++w) {
                    if (w == wOwn) { continue; }
                    // her = 这个匹配里配给 w 的男（w 在 perm 中的「丈夫」）
                    int her = -1;
                    for (int m2 = 0; m2 < n; ++m2) {
                        if (perm[static_cast<std::size_t>(m2)] == w) { her = m2; break; }
                    }
                    if (manPrefers(m, w, wOwn) && rankOf(w, m) < rankOf(w, her)) {
                        stable = false;
                        break;
                    }
                }
            }
            if (!stable) { continue; }
            ++stableCount;
            for (int m = 0; m < n; ++m) {
                const int wGs = wife[static_cast<std::size_t>(m)];   // GS 匹配里 m 的妻子
                if (manPrefers(m, perm[static_cast<std::size_t>(m)], wGs)) {
                    manOptimal = false;   // 存在稳定匹配让 m 更满意 ⟹ 非男性最优
                }
            }
        } while (std::next_permutation(perm.begin(), perm.end()));
        assert(manOptimal);
        println("  引理「男性最优」：枚举全部 n! = {} 个完美匹配，稳定匹配共 {} 个，"
                "其中没有任何一个能让某个男更满意 = {}", n, stableCount, manOptimal ? 1 : 0);
    }

    // 对账：Gale-Shapley（男提议）与「女提议」的男最优稳定匹配是同一个
    {
        // 女方提议版：女按偏好依次向男提案
        std::vector<int> wifeOf(static_cast<std::size_t>(n), -1);
        std::vector<int> worstRankM(static_cast<std::size_t>(n), 1 << 30);
        std::vector<int> nextW(static_cast<std::size_t>(n), 0);
        std::vector<int> freeWomen;
        // rankOfMan[m][w]：m 眼中 w 的排名
        std::vector<std::vector<int>> rankOfMan(static_cast<std::size_t>(n),
                                                std::vector<int>(static_cast<std::size_t>(n), 0));
        for (int m = 0; m < n; ++m) {
            for (int r = 0; r < n; ++r) {
                rankOfMan[static_cast<std::size_t>(m)][static_cast<std::size_t>(menPref[static_cast<std::size_t>(m)][static_cast<std::size_t>(r)])] = r;
            }
        }
        for (int w = 0; w < n; ++w) { freeWomen.push_back(w); }
        std::size_t head = 0;
        while (head < freeWomen.size()) {
            const int w = freeWomen[head++];
            const int m = womenPref[static_cast<std::size_t>(w)]
                               [static_cast<std::size_t>(nextW[static_cast<std::size_t>(w)])];
            ++nextW[static_cast<std::size_t>(w)];
            const int rw = rankOfMan[static_cast<std::size_t>(m)][static_cast<std::size_t>(w)];
            if (rw < worstRankM[static_cast<std::size_t>(m)]) {
                // m 更想要 w：旧女友（若有）重新变成自由女
                if (wifeOf[static_cast<std::size_t>(m)] != -1) {
                    freeWomen.push_back(wifeOf[static_cast<std::size_t>(m)]);
                }
                worstRankM[static_cast<std::size_t>(m)] = rw;
                wifeOf[static_cast<std::size_t>(m)] = w;
            } else {
                freeWomen.push_back(w);   // 被拒，继续下一位
            }
        }
        bool same = true;
        for (int m = 0; m < n; ++m) {
            if (wifeOf[static_cast<std::size_t>(m)] != wife[static_cast<std::size_t>(m)]) { same = false; }
        }
        print("  对账：女方提议版（= 女性最优稳定匹配）: ");
        for (int m = 0; m < n; ++m) { print("m{}→w{} ", m, wifeOf[static_cast<std::size_t>(m)]); }
        println("");
        println("  两版相同 = {}（本例不同 ⟹ 男最优与女最优是**两个不同的稳定匹配**，"
                "Gale-Shapley 只会算出男最优那个）", same ? 1 : 0);
        assert(!same);   // 2 个稳定匹配，男/女最优各取一个
    }
}

int main() {
    activity_demo();
    huffman_demo();
    matroid_demo();
    delta_topk_demo();
    stable_marriage_demo();
    println("自检通过");
    return 0;
}
