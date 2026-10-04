// 11 散列表（CLRS 第 11 章）。结构：11.1 链址法（图 11.3 数据 + 探查计数）/
// 11.2 开地址三法（线性/二次/双重）与表状态 / 11.3 装填因子实验（α→1 的
// 探查爆炸）/ 11.4 全域散列（碰撞对数 vs 朴素取模）。
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
#include <random>
#include <string>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 11.1 链址法 ═══
// 除法散列法：h(k) = k mod m（m 取不接近 2 的幂的素数最稳）。
// 图 11.3 的数据：m=9，依次插入 {5,28,19,15,20,33,12,17,10}。
struct ChainTable {
    std::vector<std::vector<int>> t;
    long long probes = 0;
    explicit ChainTable(std::size_t m) : t(m) {}
    std::size_t h(int k) const { return static_cast<std::size_t>(k) % t.size(); }
    void insert(int k) { t[h(k)].push_back(k); } // 头插亦可，这里尾插保持插入序
    bool search(int k) {
        auto& chain = t[h(k)];
        for (std::size_t i = 0; i < chain.size(); ++i) {
            ++probes;
            if (chain[i] == k) { return true; }
        }
        return false;
    }
    void remove(int k) {
        auto& chain = t[h(k)];
        for (std::size_t i = 0; i < chain.size(); ++i) {
            ++probes;
            if (chain[i] == k) { chain.erase(chain.begin() + static_cast<std::ptrdiff_t>(i)); return; }
        }
    }
};

static void chaining_demo() {
    ChainTable t(9);
    for (int k : {5, 28, 19, 15, 20, 33, 12, 17, 10}) { t.insert(k); }
    println("链址法（m=9，除法散列 k mod 9，图 11.3 数据）:");
    for (std::size_t i = 0; i < t.t.size(); ++i) {
        if (t.t[i].empty()) { continue; }
        print("  T[{}] →", i);
        for (int k : t.t[i]) { print(" {}", k); }
        println("");
    }
    // 装填因子 α = n/m = 9/9 = 1，链平均长 1，查找期望 1+α/2
    t.search(19);
    println("search(19)：h=1，链 {{28,19,10}} 探查 2 次（实测 {}）", t.probes);
    assert(t.probes == 2);
    t.remove(19);
    assert(!t.search(19) && t.search(10));
    println("delete(19) 后链 T[1] = {{28,10}}（同键域内查找/删除 Θ(1+α)）");
}

// ═══ 11.2 开地址法：三种探查序列 ═══
struct OpenTable {
    std::vector<int> slot;   // -1 = 空
    long long probes = 0;
    int method; // 0=线性 1=二次 2=双重
    explicit OpenTable(std::size_t m, int mth) : slot(m, -1), method(mth) {}

    std::size_t h(int k, std::size_t i) const {
        const std::size_t m = slot.size();
        switch (method) {
        case 0: return (static_cast<std::size_t>(k) + i) % m;               // 线性
        case 1: return (static_cast<std::size_t>(k) + i * i) % m;           // 二次
        default: {                                                          // 双重
            const std::size_t h1 = static_cast<std::size_t>(k) % m;
            const std::size_t h2 = 1 + static_cast<std::size_t>(k) % (m - 1);
            return (h1 + i * h2) % m;
        }
        }
    }

    bool insert(int k) {
        for (std::size_t i = 0; i < slot.size(); ++i) {
            const std::size_t j = h(k, i);
            ++probes;
            if (slot[j] == -1) { slot[j] = k; return true; }
        }
        return false; // 表满
    }

    bool search(int k) {
        for (std::size_t i = 0; i < slot.size(); ++i) {
            const std::size_t j = h(k, i);
            ++probes;
            if (slot[j] == -1) { return false; }
            if (slot[j] == k)  { return true; }
        }
        return false;
    }
};

static void open_addressing_demo() {
    const std::vector<int> keys{79, 69, 98, 72, 14, 50}; // CLRS 图 11.5 的键
    const char* names[] = {"线性探查", "二次探查", "双重散列"};
    for (int mth = 0; mth < 3; ++mth) {
        OpenTable t(13, mth);
        for (int k : keys) { assert(t.insert(k)); }
        println("{}（m=13，键 79 69 98 72 14 50）: 插入共探查 {} 次", names[mth], t.probes);
        print("  ");
        for (std::size_t j = 0; j < t.slot.size(); ++j) {
            print("{} ", t.slot[j]);
        }
        println("");
        for (int k : keys) { assert(t.search(k)); }
    }
}

// ═══ 11.3 装填因子实验 ═══
// 定理 11.6（均匀散列）：不成功查找期望探查 ≤ 1/(1−α)。
// 线性探查因一次聚集远差于此；双重散列最接近理论。
static void load_factor_demo() {
    // 二次探查要全覆盖需 m ≡ 3 (mod 4)（k+i² 才能访遍全部槽位）——
    // m=103 满足；线性/双重对 m 无此要求。
    const std::size_t m = 103;
    println("装填因子实验（m={}，先装 n 个键，再查找 n 个不在表中的键计探查）:", m);
    for (std::size_t n : {51, 72, 92}) { // α ≈ 0.50 / 0.70 / 0.89
        std::mt19937 rng{5489};
        std::vector<int> keys;
        for (std::size_t i = 0; i < n; ++i) {
            keys.push_back(static_cast<int>(rand_below(rng, 10000)) * 2); // 偶键
        }
        std::vector<int> misses;
        for (std::size_t i = 0; i < n; ++i) {
            misses.push_back(static_cast<int>(rand_below(rng, 10000)) * 2 + 1); // 奇键必不在
        }
        const double alpha = static_cast<double>(n) / static_cast<double>(m);
        const char* names[] = {"线性", "二次", "双重"};
        print("  α={:.2f}（n={}）：", alpha, n);
        for (int mth = 0; mth < 3; ++mth) {
            OpenTable t(m, mth);
            t.probes = 0;
            for (int k : keys) { assert(t.insert(k)); }
            const long long ins = t.probes;
            t.probes = 0;
            for (int k : misses) { assert(!t.search(k)); }
            print("{} 插入{:.1f}/查失{:.1f}  ", names[mth],
                  static_cast<double>(ins) / static_cast<double>(n),
                  static_cast<double>(t.probes) / static_cast<double>(n));
        }
        println("（均匀散列理论 ≤ 1/(1-α) = {:.2f}）", 1.0 / (1.0 - alpha));
    }
}

// ═══ 11.4 全域散列 ═══
// h_{a,b}(k) = ((a·k + b) mod p) mod m，p 为大于键域的素数。
// 定理 11.5：从类中均匀取 h，任两键碰撞概率 ≤ 1/m。
// 实测：随机 (a,b) 下，键对碰撞率 vs 朴素 h(k)=k mod m。
static void universal_demo() {
    const std::uint64_t p = 10007; // 大于键域的素数
    const std::uint64_t m = 13;
    std::vector<int> keys;
    std::mt19937 rng{5489};
    for (int i = 0; i < 100; ++i) { keys.push_back(static_cast<int>(rand_below(rng, 1000))); }

    long long uniCollide = 0, naiveCollide = 0, pairs = 0;
    for (std::size_t i = 0; i < keys.size(); ++i) {
        for (std::size_t j = i + 1; j < keys.size(); ++j) {
            ++pairs;
            // 随机选一组 (a,b)（固定种子流）
            const std::uint64_t a = rand_below(rng, static_cast<std::uint32_t>(p - 1)) + 1;
            const std::uint64_t b = rand_below(rng, static_cast<std::uint32_t>(p));
            const std::uint64_t ki = static_cast<std::uint64_t>(keys[i]);
            const std::uint64_t kj = static_cast<std::uint64_t>(keys[j]);
            if ((a * ki + b) % p % m == (a * kj + b) % p % m) { ++uniCollide; }
            if (ki % m == kj % m) { ++naiveCollide; } // 固定 h(k)=k mod m
        }
    }
    println("全域散列（p={}, m={}，100 键 {} 对，每对随机 (a,b)）:", p, m, pairs);
    println("  全域类碰撞率 = {:.4f}（理论 ≤ 1/m = {:.4f}）",
            static_cast<double>(uniCollide) / static_cast<double>(pairs),
            1.0 / static_cast<double>(m));
    println("  固定 k mod m 碰撞率 = {:.4f}（键取自 0..999，与 m=13 的公倍结构有关）",
            static_cast<double>(naiveCollide) / static_cast<double>(pairs));
    assert(static_cast<double>(uniCollide) / static_cast<double>(pairs) < 2.0 / static_cast<double>(m));
}

int main() {
    chaining_demo();
    open_addressing_demo();
    load_factor_demo();
    universal_demo();
    println("自检通过");
    return 0;
}
