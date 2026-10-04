// 01 算法的角色与本教程工具链（CLRS 第 1 章）。结构：01.1 特性宏探测表 /
// 01.2 IO 垫片 / 01.3 可移植随机 rand_below / 01.4 算法作为技术（比较计数）/
// 01.5 确定性输出纪律。
#ifdef ALGO_NO_PRINT // MinGW libstdc++ 缺 std::__open_terminal 符号时的降级（build.ps1 探针注入）
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
#include <random>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

// 预处理器的事实（defined/__has_include）不能直接写在表达式里——
// 必须先用 #if 梯子折算成 0/1 宏，再进 C++ 世界。这是「编译期能力探测」
// 的标准姿势，后面章节的示例都复用这一段。
//
// 关键一步：先 #include <version>。libstdc++ 把特性宏拆散在各个头文件里
// （include <algorithm> 只带出它自己的宏）；MSVC STL 则是任意标准头带出
// 全集。想让三通道看到同一张表，必须显式请出 <version> 这个「全家福」头。
#include <version>
#ifdef __cpp_lib_print
#define ALGO_HAS_PRINT_LIB 1
#else
#define ALGO_HAS_PRINT_LIB 0
#endif
#ifdef __cpp_lib_expected
#define ALGO_HAS_EXPECTED 1
#else
#define ALGO_HAS_EXPECTED 0
#endif
#ifdef __cpp_lib_generator
#define ALGO_HAS_GENERATOR 1
#else
#define ALGO_HAS_GENERATOR 0
#endif
#ifdef __cpp_lib_ranges_zip
#define ALGO_HAS_RANGES_ZIP 1
#else
#define ALGO_HAS_RANGES_ZIP 0
#endif
#ifdef __cpp_lib_ranges_chunk_by
#define ALGO_HAS_RANGES_CHUNK_BY 1
#else
#define ALGO_HAS_RANGES_CHUNK_BY 0
#endif
#ifdef __cpp_lib_ranges_to_container
#define ALGO_HAS_RANGES_TO 1
#else
#define ALGO_HAS_RANGES_TO 0
#endif
#ifdef __cpp_explicit_this_parameter
#define ALGO_HAS_EXPLICIT_THIS 1
#else
#define ALGO_HAS_EXPLICIT_THIS 0
#endif

// ═══ 01.1 特性宏探测表 ═══
// 表里只放「三通道都有」的特性——这是本教程的可用集边界；任何一行不一致
// 都会让 build.ps1 的逐字节对账失败，所以这张表本身就是纪律的执行方式。
// 三通道不一致的特性（如 std::mdspan：MSVC STL 有、libstdc++ 15 无）
// 直接进禁用清单，不进运行时输出——差异记录在 docs/01 的静态对照表里。
// 注意：绝不打印编译器名/版本号/宏的数值——那可能逐通道不同（例如
// __cpp_lib_ranges_zip 的值一边 202207、一边 202110），只打 0/1 布尔。
static void feature_table() {
    struct Row { std::string_view name; int have; };
    const Row rows[] = {
        {"__cpp_lib_print (std::print，g++ 经垫片)", ALGO_HAS_PRINT_LIB},
        {"__cpp_lib_expected (std::expected)",       ALGO_HAS_EXPECTED},
        {"__cpp_lib_generator (std::generator)",     ALGO_HAS_GENERATOR},
        {"__cpp_lib_ranges_zip",                     ALGO_HAS_RANGES_ZIP},
        {"__cpp_lib_ranges_chunk_by",                ALGO_HAS_RANGES_CHUNK_BY},
        {"__cpp_lib_ranges_to_container",            ALGO_HAS_RANGES_TO},
        {"__cpp_explicit_this_parameter (显式对象形参)", ALGO_HAS_EXPLICIT_THIS},
    };
    for (auto&& r : rows) {
        println("{} = {}", r.name, r.have);
    }
    println("禁用清单（三通道不一致）: mdspan / flat_map / stacktrace / std::execution / modules");
}

// ═══ 01.2 IO 垫片与 UTF-8 保真 ═══
// 垫片在 ALGO_NO_PRINT 下用 std::format + printf 复刻 std::print 的字节流。
// 这一段在两条路径下输出必须完全一致（否则 g++ 通道对账必挂）。
static void io_shim_demo() {
    println("中文输出保真：算法 导论 C++23");
    println("定点浮点 {{:.6f}}: {:.6f}", 1.0 / 3.0);
}

// ═══ 01.3 可移植随机：rand_below ═══
// std::mt19937 的输出由标准逐位规定（三实现相同），但
// std::uniform_int_distribution 的「分布算法」未规定（MSVC 与 libstdc++
// 序列不同）——所以本教程一律自写 rand_below。
// Lemire 乘法-移位法：无模偏倚，一次乘法 + 一次移位。
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    assert(n != 0);
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n; // [0, n·2^32)
    return static_cast<std::uint32_t>(m >> 32);              // [0, n)
}

static void portable_random_demo() {
    std::mt19937 rng{5489}; // 固定种子（对齐 datastruct 教程惯例）
    print("rand_below(rng,100) 前 8 个: ");
    for (int i = 0; i < 8; ++i) {
        print("{} ", rand_below(rng, 100));
    }
    println("");
    // 直方图：固定 6000 次抽样，每个桶约 1000（波动幅度也是确定的）
    std::mt19937 rng2{5489};
    int bucket[6] = {0, 0, 0, 0, 0, 0};
    for (int i = 0; i < 6000; ++i) { ++bucket[rand_below(rng2, 6)]; }
    println("6000 次 rand_below(rng,6) 直方图: {} {} {} {} {} {}",
            bucket[0], bucket[1], bucket[2], bucket[3], bucket[4], bucket[5]);
}

// ═══ 01.4 算法作为技术：插入排序 vs 归并排序 ═══
// CLRS §1.2 的核心论证：插入排序 ~n²，归并排序 ~n·lg n。我们不打印
// 「耗时」（跨机器/跨通道不可复现），而是打印「比较次数」——它是纯逻辑
// 计数，三通道逐字节一致（确定性纪律的示范）。
struct Counters { long long compares = 0; };

static void insertion_sort(std::span<int> a, Counters& c) {
    for (std::size_t j = 1; j < a.size(); ++j) {
        int key = a[j];
        std::size_t i = j;
        while (i > 0 && (++c.compares, a[i - 1] > key)) {
            a[i] = a[i - 1];
            --i;
        }
        a[i] = key;
    }
}

// 归并排序：两子数组都非空时每比较一次归并一个元素，
// 所以 merge 的比较次数 ≤ (左长度 + 右长度 - 1)。
static void merge_sort_impl(std::span<int> a, std::span<int> buf, Counters& c) {
    if (a.size() < 2) { return; }
    std::size_t mid = a.size() / 2;
    merge_sort_impl(a.first(mid), buf.first(mid), c);
    merge_sort_impl(a.subspan(mid), buf.subspan(mid), c);
    std::copy(a.begin(), a.end(), buf.begin());
    std::size_t i = 0, j = mid, k = 0;
    while (i < mid && j < a.size()) {
        if (++c.compares, buf[i] <= buf[j]) { a[k++] = buf[i++]; }
        else                               { a[k++] = buf[j++]; }
    }
    while (i < mid)      { a[k++] = buf[i++]; }
    while (j < a.size()) { a[k++] = buf[j++]; }
}

static void merge_sort(std::span<int> a, Counters& c) {
    std::vector<int> buf(a.size());
    merge_sort_impl(a, buf, c);
}

static void algorithms_as_technology() {
    const int n = 2048; // 2 的幂，lg n = 11，无取整歧义
    std::vector<int> worst(n);
    for (int i = 0; i < n; ++i) { worst[i] = n - i; } // 逆序 = 插入排序最坏情况

    auto v1 = worst;
    Counters c1{};
    insertion_sort(v1, c1);
    assert(std::ranges::is_sorted(v1));

    auto v2 = worst;
    Counters c2{};
    merge_sort(v2, c2);
    assert(std::ranges::is_sorted(v2));
    assert(v1 == v2);

    const int lgn = std::bit_width(static_cast<unsigned>(n)) - 1; // ⌊lg 2048⌋ = 11
    const long long insertion_worst = static_cast<long long>(n) * (n - 1) / 2;
    println("n={}（lg n={}）：插入排序最坏比较 {}（理论 n(n-1)/2={}）",
            n, lgn, c1.compares, insertion_worst);
    println("n={}：归并排序比较 {}（~n·lg n={}）", n, c2.compares,
            static_cast<long long>(n) * lgn);
    println("比值 插入/归并 = {:.2f}",
            static_cast<double>(c1.compares) / static_cast<double>(c2.compares));
    assert(c1.compares == insertion_worst);
}

// ═══ 01.5 确定性输出纪律 ═══
static void determinism_demo() {
    // 1) 浮点不打印裸值，打定点 + 容差布尔
    const double x = 0.1 + 0.2;
    println("0.1+0.2 = {:.6f}（不打印裸浮点）", x);
    println("0.1+0.2==0.3 直接判等 = {}，容差判等 |x-0.3|<1e-9 = {}",
            x == 0.3, x - 0.3 < 1e-9 && 0.3 - x < 1e-9);
    // 2) 性能对比只打操作计数器，不打耗时
    Counters c{};
    std::vector<int> tiny{5, 2, 4, 6, 1, 3};
    insertion_sort(tiny, c);
    println("CLRS 图 2.2 数组排序后: {} {} {} {} {} {}（比较 {} 次）",
            tiny[0], tiny[1], tiny[2], tiny[3], tiny[4], tiny[5], c.compares);
    assert(tiny == std::vector<int>({1, 2, 3, 4, 5, 6}));
}

int main() {
    feature_table();
    io_shim_demo();
    portable_random_demo();
    algorithms_as_technology();
    determinism_demo();
    println("自检通过");
    return 0;
}
