// 18 摊还分析（CLRS 第 17 章）。结构：18.1 二进制计数器（聚合法：总翻转
// ≤ 2n）/ 18.2 记账法（信用不变式模拟）/ 18.3 势能法（Φ=1 的个数，每次
// 摊还恰为 2）/ 18.4 动态表（倍增扩张 vs 收缩的两策略对比——1/4 阈值的
// 必要性）。
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
#include <vector>

// ═══ 18.1–18.3 二进制计数器：三法一台戏 ═══
// INCREMENT：翻转尾部连续 1 → 0，再把一个 0 → 1。单次最坏翻转 k 位，
// 但 n 次总计 ≤ 2n 位——「贵操作极少发生」。
struct Counter {
    std::vector<int> bit;      // bit[0] 是最低位
    long long flips = 0;       // 实际位翻转总数
    explicit Counter(int k) : bit(static_cast<std::size_t>(k), 0) {}

    void increment() {
        std::size_t i = 0;
        while (i < bit.size() && bit[i] == 1) {
            bit[i] = 0;                       // 1→0
            ++flips;
            ++i;
        }
        if (i < bit.size()) {
            bit[i] = 1;                       // 0→1
            ++flips;
        }
    }
};

static void counter_demo() {
    const int n = 16, k = 5;
    Counter c(k);
    // 势能法逐操作验证：amortized_i = actual_i + Φ(D_i) − Φ(D_{i-1})，Φ=1 的个数
    long long phi = 0;
    std::vector<int> amortized;
    for (int op = 1; op <= n; ++op) {
        const long long before = c.flips;
        c.increment();
        const long long actual = c.flips - before;
        long long newPhi = 0;
        for (int b : c.bit) { newPhi += b; }
        amortized.push_back(static_cast<int>(actual + newPhi - phi));
        phi = newPhi;
    }
    long long sumAmortized = 0;
    for (int a : amortized) { sumAmortized += a; }
    println("二进制计数器（n={} 次自增，{} 位）：", n, k);
    println("  聚合法：总位翻转 = {}（≤ 2n = {}）", c.flips, 2 * n);
    assert(c.flips <= 2 * n);
    println("  势能法（Φ = 1 的个数）：每次摊还代价 = 2（16 次全验，和 = {}）", sumAmortized);
    assert(sumAmortized == 2 * n);
    bool allTwo = true;
    for (int a : amortized) { if (a != 2) { allTwo = false; } }
    assert(allTwo);
    println("  计数终值 = {}（位图 {}{}{}{}{}）", 16,
            c.bit[4], c.bit[3], c.bit[2], c.bit[1], c.bit[0]);
}

// ═══ 18.4 动态表：扩张与收缩 ═══
// 扩张：满时容量翻倍（CLRS TABLE-INSERT）。总拷贝 ≤ 2n（倍增的几何级数）。
// 收缩：CLRS 用「< 容量/4 时减半」——若用 1/2 阈值会抖动（交替增删每次
// 都搬整表，摊还 O(n)）。两策略同操作序列对比。
struct DynTable {
    std::vector<int> data;
    std::size_t cap = 1, num = 0;
    long long copies = 0;
    int shrinkPolicy; // 0：1/4 阈值（正确）；1：1/2 阈值（抖动）

    explicit DynTable(int policy) : shrinkPolicy(policy) { data.resize(1); }

    void insert(int v) {
        if (num == cap) {                       // 满则倍增
            data.resize(2 * cap);
            copies += static_cast<long long>(num);
            cap *= 2;
        }
        data[num++] = v;
    }
    void erase() {
        if (num == 0) { return; }
        --num;
        const std::size_t quarter = cap / 4, half = cap / 2;
        const bool shrink = (shrinkPolicy == 0 && num == quarter && cap > 1)
                         || (shrinkPolicy == 1 && num == half && cap > 1);
        if (shrink) {
            data.resize(cap / 2);
            copies += static_cast<long long>(num);
            cap /= 2;
        }
    }
};

static void dynamic_table_demo() {
    // 扩张：16 次插入的总拷贝
    {
        DynTable t(0);
        for (int i = 1; i <= 16; ++i) { t.insert(i); }
        println("动态表扩张（连续插入 16 个）：总拷贝 {} 次（≤ 2n = 32，几何级数）",
                t.copies);
        assert(t.copies <= 2 * 16);
        assert(t.num == 16 && t.cap == 16);
    }
    // 收缩两策略对比：在同一序列上「在半满边界交替增删」
    {
        DynTable good(0), bad(1);
        for (int i = 0; i < 64; ++i) { good.insert(i); bad.insert(i); }
        const long long baseG = good.copies, baseB = bad.copies;
        // 触发点：容量 64、元素 33 附近交替增删 200 次
        for (int i = 0; i < 200; ++i) {
            good.insert(0); good.erase();
            bad.insert(0); bad.erase();
        }
        // good：num 在 33 徘徊（远高于 64/4=16，不收缩）
        // bad：num 到 32 时收缩到 32、再插入扩回 64……每次全表拷贝
        println("收缩策略对比（容量 64、元素 33 起交替增删 200 次）：");
        println("  1/4 阈值（CLRS）：额外拷贝 {} 次", good.copies - baseG);
        println("  1/2 阈值（抖动）：额外拷贝 {} 次（差 {} 倍）",
                bad.copies - baseB, (bad.copies - baseB) /
                std::max<long long>(1, good.copies - baseG));
        assert(good.copies - baseG < bad.copies - baseB);
    }
}

int main() {
    counter_demo();
    dynamic_table_demo();
    println("自检通过");
    return 0;
}
