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
#include <array>
#include <cassert>
#include <cstdint>
#include <random>
#include <string>
#include <string_view>
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

// ═══ 11.5 定长字符串的进位制编码：Θ(len·N) ⟶ Θ(len) ═══
//
// 本节回答第 11 章开头那个问题的具体解法：「键域巨大但实际键只有 n 个」
// 且**键本身是短字符串**时，怎么做字典。
//
// ── 核心观察：定长字符串是「进位制整数」──
// 字符集大小 B，把每个字符动态编号成 0..B-1，则长度恰为 N 的字符串与
// 区间 [0, B^N) 中的整数**一一对应**：
//     v = c_0·B^{N-1} + c_1·B^{N-2} + ... + c_{N-1}
// 编码相同 ⟺ 字符串相同。于是「字符串去重」变成「整数去重」，
// 而整数可以直接当散列表的键（int 身份的 hash，O(1)）。
//
// ── 两段技术 ──
//   ① **无损定长编码**：m ≤ 32 时每字符 2 bit（ACGT→00,01,10,11），
//      整串塞进 uint64_t���2m ≤ 64 bit），单射，散列表计数即得克隆数。
//   ② **滚动递推**：需要「长度为 N 的不同子串计数」时，
//      v_{i+1} = (v_i - c_i·B^{N-1})·B + c_{i+N}
//      每步 Θ(1) ⟹ 全串扫描 Θ(len)。配合位图去重。
//
// ── 两条纪律 ──
//   · **字符要动态编号**（只统计实际出现的字符），不要硬编码 a=0,b=1；
//   · **先判 B^N 是否放得下**再定方案，否则位图直接 OOM。

// ── ① 2 bit/字符的无损编码（ACGT 定长串）──
// 动态编号：只给**实际出现**的字符发号（按字符值升序），
// 这样 B 最小、编码空间最省。返回该串用的进制 B。
static int dna_dynamic_code(const std::string& s, std::array<int, 256>& code) {
    bool present[256] = {};
    for (char ch : s) { present[static_cast<unsigned char>(ch)] = true; }
    int B = 0;
    for (int u = 0; u < 256; ++u) {
        if (present[u]) { code[u] = B; ++B; }
    }
    return B;
}

// m 个字符、每字符 2 bit ⟹ 2m bit 的无损编码。m ≤ 32 时装得进 uint64_t。
static std::uint64_t encode_2bit(std::string_view s) {
    assert(s.size() <= 32);
    std::uint64_t v = 0;
    for (char ch : s) {
        std::uint64_t d = 0;
        switch (ch) {
        case 'A': d = 0; break;
        case 'C': d = 1; break;
        case 'G': d = 2; break;
        default:  d = 3; break;   // 'T'
        }
        v = (v << 2) | d;// 左移 2 位再并入
    }
    return v;
}

// ── ② 滚动递推（通用字符集、任意 N）──
struct RollingCode {
    std::vector<int> code;      // 字符 → 编号（动态，只含实际出现的）
    std::size_t B = 0;// 进制
    std::uint64_t v = 0;        // 当前窗口编码
    std::uint64_t powTop = 0;   // B^{N-1}，进位制的最高位权
    int width = 0;              // 窗口长度 N

    // 传text 与窗口长度 N。**先做溢出检查**：B^N 装不下就别用位图方案。
    RollingCode(std::string_view text, int n) {
        // 第一遍：只统计**实际出现**的字符种数（动态编号，别硬编码）
        std::vector<unsigned char> present(256, 0);
        for (char ch : text) { present[static_cast<unsigned char>(ch)] = 1; }
        code.assign(256, 0);
        std::size_t sigma = 0;
        for (std::size_t u = 0; u < present.size(); ++u) {
            if (present[u]) { code[u] = static_cast<int>(sigma); ++sigma; }
        }
        B = sigma;
        width = n;
        // powTop = B^{N-1}，连乘时**提前探测溢出**（不真算出来再判断）
        powTop = 1;
        for (int i = 0; i + 1 < n; ++i) {
            if (powTop > UINT64_MAX / B) { powTop = 0; break; }   // B^N 放不下
            powTop *= B;
        }
    }
    // B^N 能否装进 uint64_t（位图方案的前提）
    bool fits() const { return powTop != 0 || width == 1; }

    void start(std::string_view text) {
        v = 0;
        for (int i = 0; i < width; ++i) {
            v = v * B + code[static_cast<unsigned char>(text[static_cast<std::size_t>(i)])];
        }
    }
    // 滚动一步：去掉最左字符、补入最右字符。Θ(1)
    // 递推式 v_{i+1} = (v_i - c_i·B^{N-1})·B + c_{i+N}
    // 注意补入的是 **c_{i+N}**（新窗口最右端），不是 c_{i+N-1}——
    // 后者会原地不动地重复算第一个窗口（本示例实测翻车：daa 滚成 0）。
    void roll(std::string_view text, std::size_t i) {
        const auto ci = static_cast<std::uint64_t>(code[static_cast<unsigned char>(text[i])]);
        const auto cn = static_cast<std::uint64_t>(code[static_cast<unsigned char>(
            text[i + static_cast<std::size_t>(width)])]);
        v = (v - ci * powTop) * B + cn;
    }
};

// 位图：确定性去重（无哈希碰撞），空间 Θ(B^N/8) 字节。
struct Bitmap {
    std::vector<std::uint64_t> word;
    std::uint64_t count = 0;
    explicit Bitmap(std::size_t bits) : word((bits + 63) / 64, 0) {}
    // 返回 true 表示这是**首次**置位（⟹ 计数 +1）
    bool set(std::uint64_t v) {
        std::uint64_t& w = word[v >> 6];
        const std::uint64_t bit = std::uint64_t{1} << (v & 63);
        if (w & bit) { return false; }
        w |= bit;
        ++count;
        return true;
    }
};

static void radix_code_demo() {
    println("");
    println("=== 11.5 定长字符串的进位制编码：Θ(len·N) ⟶ Θ(len) ===");

    // ── ① 2 bit/字符：DNA 克隆计数 ──
    println("");
    println("① 2 bit/字符的无损编码（ACGT 定长，m ≤ 32 装得进 uint64_t）：");
    const std::vector<std::string> clones{
        "ACGT", "ACGT", "TGCA", "ACGT", "GGCC", "TGCA", "ACGT", "GGCC"};
    std::array<int, 256> code4{};
    const int B4 = dna_dynamic_code("ACGTGGCC", code4);
    print("    动态编号（只统计实际出现的字符，按字符值升序）: ");
    // 坑：for (char ch : "ACGT") 会把字符串字面量的结尾 '\0' 也迭代进去，
    // 打出 NUL 控制字符——输出校验直接判死。用 string_view 只拿 4 个真字符。
    for (char ch : std::string_view{"ACGT"}) {
        print("{}={} ", ch, code4[static_cast<unsigned char>(ch)]);
    }
    println("");
    println("    ⟹ 该串用了 {} 个字符，B = {}，编码空间 B^m = {}^{}",
            B4, B4, B4, clones[0].size());
    print("    编码: ");
    for (const std::string& s : clones) { print("{} ", encode_2bit(s)); }
    println("");
    // 单射性：编码相同⟺ DNA 相同
    assert(encode_2bit("ACGT") == encode_2bit("ACGT"));
    assert(encode_2bit("ACGT") != encode_2bit("TGCA"));
    assert(encode_2bit("AACC") != encode_2bit("ACAC"));   // 定长才无歧义
    println("    单射性：ACGT→{}，AACC→{}，ACAC→{}（定长 ⟹ 编码与串一一对应）",
            encode_2bit("ACGT"), encode_2bit("AACC"), encode_2bit("ACAC"));

    // 散列表计数：cnt[编码]++
    std::vector<std::pair<std::uint64_t, int>> table;   // (编码, 出现次数)
    for (const std::string& s : clones) {
        const std::uint64_t v = encode_2bit(s);
        bool found = false;
        for (auto& [key, cnt] : table) {
            if (key == v) { ++cnt; found = true; break; }
        }
        if (!found) { table.emplace_back(v, 1); }
    }
    print("    不同串 {} 个，计数（编码×出现次数）: ", table.size());
    for (const auto& [v, c] : table) { print("{}×{} ", v, c); }
    println("");
    //「恰好有 i 个副本的人数」
    const int m = static_cast<int>(clones.size());
    std::vector<int> bucket(static_cast<std::size_t>(m), 0);
    for (const auto& [v, c] : table) { ++bucket[static_cast<std::size_t>(c) - 1]; }
    print("    恰好有 i 个副本的人数: ");
    for (int i = 1; i <= m; ++i) { print("{} ", bucket[static_cast<std::size_t>(i - 1)]); }
    println("");
    println("    读法：4 个副本的 1 人、2 个副本的 2 人、1 个副本的 1 人");
    assert(bucket[1] == 2&& bucket[3] == 1);

    // ── ② 滚动递推：长度为 N 的不同子串计数 ──
    println("");
    println("② 进位制滚动编码 + 位图（长度为 N 的不同子串计数，Θ(len)）：");
    struct Case { int n; const char* text; int expect; };
    const Case cases[] = {
        {3, "daababac", 5},
        {2, "aaaa", 1},
        {1, "abcd", 4},
        {3, "abcdef", 4},
    };
    println("    {:>2} {:<10} {:>4} {:>8} {:>10}", "N", "text", "len", "不同子串", "位图字节");
    for (const Case& c : cases) {
        const std::string text = c.text;
        const auto len = static_cast<int>(text.size());
        assert(c.n <= len);
        RollingCode rc(text, c.n);
        assert(rc.fits());// 本组数据 B^N 都很小
        Bitmap bm(rc.powTop * rc.B);// B^N 位
        rc.start(text);
        bm.set(rc.v);
        assert(bm.count == 1);          // 第一个窗口必是新位
        for (int i = 0; i + c.n < len; ++i) {
            rc.roll(text, static_cast<std::size_t>(i));
            bm.set(rc.v);
        }
        println("    {:>2} {:<10} {:>4} {:>8} {:>10}", c.n, c.text, len,
                static_cast<long long>(bm.count), bm.word.size() * 8);
        assert(bm.count == static_cast<std::uint64_t>(c.expect));
    }
    println("    递推式 v_{{i+1}} = (v_i - c_i·B^{{N-1}})·B + c_{{i+N}}——每步 3 条整数运算");

    // 与朴素 set<string> 对账，并量化代价差
    {
        const std::string text = "daababac";
        const int n = 3;
        // 朴素：枚举所有长度 n 的子串，排序 + unique 求不同子串数。
        // 注意 unique 会把尾部元素**移动成空串**并只返回新逻辑末尾，
        // vector 的 size 不变——所以要在副本上做，且用返回的迭代器算计数。
        std::vector<std::string> subs;
        for (std::size_t i = 0; i + static_cast<std::size_t>(n) <= text.size(); ++i) {
            subs.push_back(text.substr(i, static_cast<std::size_t>(n)));
        }
        std::vector<std::string> sorted = subs;
        std::ranges::sort(sorted);
        const auto last = std::ranges::unique(sorted);
        sorted.erase(last.begin(), sorted.end());       // 真正截断
        const std::size_t naiveDistinct = sorted.size();
        RollingCode rc(text, n);
        Bitmap bm(rc.powTop * rc.B);
        rc.start(text);
        bm.set(rc.v);
        for (int i = 0; i + n < static_cast<int>(text.size()); ++i) {
            rc.roll(text, static_cast<std::size_t>(i));
            bm.set(rc.v);
        }
        println("");
        println("    对账：文本 daababac、N=3");
        println("      朴素（排序 + 去重）：{} 个不同子串，每次比较要逐字符比 O(N) 次",
                naiveDistinct);
        println("      滚动编码 + 位图：{} 个 ⟹ 一致 = {}",
                static_cast<long long>(bm.count),
                bm.count == naiveDistinct);
        print("      朴素枚举的不同子串: ");
        for (const std::string& s : sorted) { print("{} ", s); }
        println("");
        assert(bm.count == naiveDistinct);
        assert(sorted.size() == 5);
    }

    // ── 确定性 vs Monte Carlo ──
    println("");
    println("确定性 vs Monte Carlo（去重方案的三档）：");
    println("    位图 vector<uint64>  —— 确定性：无碰撞，代价是 Θ(B^N/8) 字节");
    println("    unordered_set<u64>  —— 期望 O(len)，但依赖哈希（int 身份映射几乎无碰撞）");
    println("    取 64 位混合哈希     —— Monte Carlo：有极小碰撞概率，会漏计");

    // ── 溢出检查：B^N 放不下就别用位图 ──
    {
        const std::string text = "ACGTACGTACGTACGTACGT";   // B=4, len=20
        RollingCode ok(text, 10);// 4^10 = 2^20，位图 128KB
        println("");
        println("溢出检查（先判 B^N 是否放得下，再定方案）：");
        println("    文本长 {}、B = {}、N = 10 ⟹ B^N = 4^10 = 2^20 = {} bit = {} KB",
                text.size(), ok.B, ok.powTop * ok.B, (ok.powTop * ok.B) / 8 / 1024);
        assert(ok.fits());
        // N 大到 B^N 溢出uint64（本例4^32 = 2^64 恰好越过）
        RollingCode big(text, 33);
        println("    N = 33 时 B^N = 4^33 = 2^66 > 2^64 ⟹ fits() = {} ⟹ 必须换方案",
                big.fits() ? "true" : "false");
        println("    （可行替代：unordered_set<u64> 存滚动编码，或截断哈希。）");
        assert(!big.fits());
    }
}

int main() {
    chaining_demo();
    open_addressing_demo();
    load_factor_demo();
    universal_demo();
    radix_code_demo();
    println("自检通过");
    return 0;
}
