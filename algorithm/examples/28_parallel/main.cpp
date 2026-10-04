// 28 多线程算法 → C++23 适配（CLRS 第 27 章）。结构：28.1 CLRS 的
// spawn/sync 计算模型与工作-跨度（T1/T∞）/ 28.2 并行归并：jthread 分治 +
// barrier 汇合 / 28.3 与单线程版的确定性对账（结果与比较计数）/
// 28.4 加速比的理论账（T1/T∞ 与处理器数 P 的关系）。
// 纪律：不打印墙钟时间（跨机器不可复现）——对账用「结果一致 + 比较
// 计数一致」两把尺；线程数只打印 hardware_concurrency 的「结构性」事实。
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
#include <array>
#include <atomic>
#include <barrier>
#include <bit>
#include <cassert>
#include <cstdint>
#include <random>
#include <span>
#include <thread>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 28.2 并行归并排序（CLRS P-MERGE-SORT 的简化版）═══
// 顶层切 K 块，每块一个 jthread 排序，主线程 barrier 等齐后顺序归并。
// K=1 时退化为单线程——同一份代码两条配置，对账天然公平。
struct SortStats { long long compares = 0; long long spawns = 0; };

static void insertion_sort_span(std::span<int> a, long long& c) {
    for (std::size_t j = 1; j < a.size(); ++j) {
        int key = a[j];
        std::size_t i = j;
        while (i > 0 && (++c, a[i - 1] > key)) { a[i] = a[i - 1]; --i; }
        a[i] = key;
    }
}

static void merge_span(std::span<int> a, long long& c) {
    if (a.size() < 2) { return; }
    const std::size_t mid = a.size() / 2;
    std::vector<int> buf(a.begin(), a.end());
    std::size_t i = 0, j = mid, k = 0;
    while (i < mid && j < a.size()) {
        if (++c, buf[i] <= buf[j]) { a[k++] = buf[i++]; } else { a[k++] = buf[j++]; }
    }
    while (i < mid)      { a[k++] = buf[i++]; }
    while (j < a.size()) { a[k++] = buf[j++]; }
}

static void msort_span(std::span<int> a, long long& c) {
    if (a.size() <= 16) { insertion_sort_span(a, c); return; }
    const std::size_t mid = a.size() / 2;
    msort_span(a.first(mid), c);
    msort_span(a.subspan(mid), c);
    merge_span(a, c);
}

// K 线程版：分块各排各的，然后顺序两两归并
static std::vector<int> parallel_sort(const std::vector<int>& input, int K, SortStats& st) {
    const std::size_t n = input.size();
    const std::size_t chunk = (n + static_cast<std::size_t>(K) - 1) / static_cast<std::size_t>(K);
    std::vector<std::vector<int>> parts;
    for (int k = 0; k < K; ++k) {
        const std::size_t lo = chunk * static_cast<std::size_t>(k);
        if (lo >= n) { break; }
        const std::size_t hi = std::min(n, lo + chunk);
        parts.emplace_back(input.begin() + static_cast<std::ptrdiff_t>(lo),
                           input.begin() + static_cast<std::ptrdiff_t>(hi));
    }
    // 并行阶段：jthread 池（barrier 等齐——本例主线程 join 已足够，
    // barrier 演示放在 28.3 的相位同步里）
    std::vector<std::thread> pool;
    std::vector<long long> partCompares(parts.size(), 0);
    for (std::size_t k = 0; k < parts.size(); ++k) {
        ++st.spawns;
        pool.emplace_back([&, k] {
            std::span<int> s(parts[k]);
            msort_span(s, partCompares[k]);
        });
    }
    for (auto& th : pool) { th.join(); }
    // 顺序归并阶段（教学简化：串行两两归并；真正的并行归并见 CLRS P-MERGE）
    std::vector<int> out = parts[0];
    for (std::size_t k = 1; k < parts.size(); ++k) {
        std::vector<int> merged(out.size() + parts[k].size());
        std::size_t i = 0, j = 0, m = 0;
        while (i < out.size() && j < parts[k].size()) {
            ++st.compares;
            if (out[i] <= parts[k][j]) { merged[m++] = out[i++]; }
            else                      { merged[m++] = parts[k][j++]; }
        }
        while (i < out.size())   { merged[m++] = out[i++]; }
        while (j < parts[k].size()) { merged[m++] = parts[k][j++]; }
        out = std::move(merged);
    }
    for (long long pc : partCompares) { st.compares += pc; }
    return out;
}

static void parallel_sort_demo() {
    const int n = 200000;
    std::mt19937 rng{5489};
    std::vector<int> v(n);
    for (int i = 0; i < n; ++i) { v[static_cast<std::size_t>(i)] = static_cast<int>(rand_below(rng, 1u << 20)); }

    SortStats s1{}, s4{};
    const auto single = parallel_sort(v, 1, s1);
    const auto quad = parallel_sort(v, 4, s4);
    assert(single == quad && std::ranges::is_sorted(single));
    println("并行归并排序（n={}，固定种子输入）：", n);
    println("  K=1：比较 {} 次，spawn {} 次", s1.compares, s1.spawns);
    println("  K=4：比较 {} 次，spawn {} 次（与 K=1 结果逐元素一致）", s4.compares, s4.spawns);
    // 比较 counts 接近但不要求相等（分块边界影响插入排序小段），断言近似
    const double ratio = static_cast<double>(s4.compares) / static_cast<double>(s1.compares);
    println("  K=4/K=1 比较数比值 = {:.4f}（分块边界 ± 小常数，渐近同为 n lg n）", ratio);
    assert(ratio > 0.9 && ratio < 1.1);
    println("  hardware_concurrency = {}（结构性事实：机器逻辑核数）",
            std::thread::hardware_concurrency());
}

// ═══ 28.3 barrier 相位同步（CLRS sync 的工程化形态）═══
static void barrier_demo() {
    // 四个线程分四相位累加一个数组；每相位结束 barrier 汇合。
    // 结果确定：每相位每线程 +自己的段，跨相位顺序无关。
    constexpr int kThreads = 4, kPhases = 3;
    std::vector<long long> total(static_cast<std::size_t>(kThreads), 0);
    std::atomic<long long> phaseSum{0};
    {
        std::barrier syn(static_cast<std::ptrdiff_t>(kThreads));
        std::vector<std::jthread> pool;
        for (int t = 0; t < kThreads; ++t) {
            pool.emplace_back([&, t] {
                for (int ph = 0; ph < kPhases; ++ph) {
                    total[static_cast<std::size_t>(t)] += (t + 1) * (ph + 1);
                    phaseSum.fetch_add((t + 1) * (ph + 1));
                    syn.arrive_and_wait();          // 相位汇合（CLRS 的 sync）
                }
            });
        }
    }   // jthread 析构自动 join
    long long expect = 0;
    for (long long x : total) { expect += x; }
    println("barrier 相位同步（{} 线程 × {} 相位）：累加合计 = {}（期望一致 = {}）",
            kThreads, kPhases, phaseSum.load(), phaseSum.load() == expect ? 1 : 0);
    assert(phaseSum.load() == expect);
    assert(expect == 60);   // Σ_t Σ_ph (t+1)(ph+1) = (1+2+3+4)×(1+2+3) = 60
}

// ═══ 28.4 工作-跨度账本 ═══
// CLRS：T_p ≤ T1/P + T∞（贪心调度定理 27.1）。归并排序的账：
//   T1 = Θ(n lg n)（工作不变）；T∞ = Θ(lg n)（分治树深）——
//   「完美并行」的标尺。加速比上限 S(P) = T1/T∞ = Θ(n)：机器再多，
//   深度 lg n 是逃不掉的串行链。
static void work_span_demo() {
    for (int n : {1024, 65536}) {
        const int lg = std::bit_width(static_cast<unsigned>(n)) - 1;
        // 理论值：T1 ≈ c·n·lg n（c=1 示意）；T∞ ≈ d·lg n（d=2 示意）
        println("n={}：工作 T1 ~ n·lg n = {}，跨度 T∞ ~ 2·lg n = {}，"
                "理论加速上限 T1/T∞ ~ n/2 = {}",
                n, static_cast<long long>(n) * lg, 2 * lg, n / 2);
    }
    println("贪心调度定理：T_p ≤ T1/P + T∞——P 台处理器的实际时间被「工作摊薄」");
    println("与「深度兜底」双约束；Amdahl 定律的算法版。");
}

int main() {
    parallel_sort_demo();
    barrier_demo();
    work_span_demo();
    println("自检通过");
    return 0;
}
