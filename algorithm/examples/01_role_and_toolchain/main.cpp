// 01 算法的角色与本教程工具链（CLRS 第 1 章）。结构：01.1 特性宏探测表 /
// 01.2 IO 垫片 / 01.3 可移植随机 rand_below / 01.4 算法作为技术（比较计数）/
// 01.5 确定性输出纪律。 / 01.6 算法代码的工程标准（copy-and-swap 强异常安全、
// std::expected 错误处理、防御性编程三形态：断言 / 异常 / 返回值）。
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
#include <expected>
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

// ═══ 01.6 算法代码的工程标准 ═══
// 算法竞赛式的"能过就行"和工程式的"十年后还有人维护"是两种代码。
// 这一节讲三件在算法书里很少出现、但在真实项目里决定生死的事：
//   ① 资源管理：谁分配谁释放，异常时怎么办（RAII / copy-and-swap）
//   ② 错误处理：失败是异常、是 expected、还是返回码（std::expected）
//   ③ 防御性编程：断言 / 异常 / 返回值，三者各有适用区间

// ---------- ① copy-and-swap：写赋值运算符的唯一正确姿势 ----------

// 手写赋值运算符要同时处理四件事：释放旧资源、拷贝新资源、自赋值、异常安全。
// 顺序错了就漏：
//   先释放再拷贝 → 拷贝抛异常时对象已被掏空；
//   不管自赋值   → a = a 时 delete 掉自己再读已释放内存；
//   边改边拷     → 中途抛异常，成员处于半修改状态（连基本安全保证都违反）。
// copy-and-swap 把这三件事一次性消掉。
class Buffer {
public:
    explicit Buffer(std::string tag) : tag_(std::move(tag)) {}
    Buffer(const Buffer& other) : tag_(other.tag_) { ++copy_calls; }
    Buffer(Buffer&& other) noexcept : tag_(std::move(other.tag_)) { ++move_calls; }
    ~Buffer() = default;

    // copy-and-swap：参数**按值**收（先构造一份临时对象），再与 *this 交换。
    // 于是"怎么造新内存"全归拷贝构造管，operator= 只剩一次不失败的 swap。
    // 副作用：operator= 不能是 const（要改 *this），但可以是 noexcept。
    Buffer& operator=(Buffer other) noexcept {
        tag_.swap(other.tag_);
        return *this;
    }
    // 不需要、也不能再写 operator=(const Buffer&) = delete：
    // 按值收参的版本已经能接住 const 实参，再加一个重载反而**歧义**
    // （本例实测翻车：两个候选互不占优）。

    static inline long long copy_calls = 0;                       // 拷贝构造被调用的总次数
    static inline long long move_calls = 0;                       // 移动构造被调用的总次数
    const std::string& tag() const { return tag_; }

private:
    std::string tag_;
};

// ---------- ② std::expected：错误处理不进异常通道 ----------

// 算法里"输入不合法"是常态而非意外（二分的区间、图的邻接表……）。
// 用异常表达它是错配：调用点必须写 try/catch，成本高且容易忘。
// C++23 的 std::expected 把失败做成**返回值的一部分**，类型层面强制处理。
static std::expected<int, std::string> parse_int(std::string_view sv) {
    if (sv.empty()) { return std::unexpected("空输入"); }
    long long sign = 1;
    std::size_t i = 0;
    if (sv[0] == '+' || sv[0] == '-') {
        sign = (sv[0] == '-') ? -1 : 1;
        i = 1;
        if (sv.size() == 1) { return std::unexpected("只有符号没有数字"); }
    }
    long long v = 0;
    for (; i < sv.size(); ++i) {
        if (sv[i] < '0' || sv[i] > '9') {
            return std::unexpected(std::string("非法字符: ") + sv[i]);
        }
        v = v * 10 + (sv[i] - '0');
        if (v > 2147483647LL) { return std::unexpected("超出 int32 范围"); }
    }
    return static_cast<int>(sign * v);
}

static void engineering_standards_demo() {
    println("");
    println("=== 01.6 算法代码的工程标准 ===");

    // ---------- ① RAII + copy-and-swap ----------
    println("");
    println("  (1) RAII / copy-and-swap：赋值运算符的正确写法");
    {
        Buffer a{"alpha"};
        const Buffer b{"beta-longer-string"};        // 故意比 a 长 ⇒ 可能重分配
        a = b;                        // copy-and-swap：一次不失败的 swap
        assert(a.tag() == "beta-longer-string");
        println("      a = b 之后 a.tag() = {}（拷贝构造 {} 次、搬移构造 {} 次）",
                a.tag(), Buffer::copy_calls, Buffer::move_calls);
        // 自赋值：copy-and-swap 下**不需要**手写 if (this != &other)
        const Buffer& alias = a;
        a = alias;
        assert(a.tag() == "beta-longer-string");
        println("      a = a（自赋值）后 a.tag() = {}——未被破坏", a.tag());
        println("      作用域结束时析构自动执行，无任何手动 delete");
    }
    println("      手写版本的三个经典漏洞：");
    println("        (a) 先 delete 旧、再拷贝新 → 拷贝抛异常则对象已被掏空；");
    println("        (b) 漏掉 if (this != &other) → 自赋值时 delete 掉自己；");
    println("        (c) 边改边拷 → 中途抛异常，成员处于半修改状态。");
    println("      copy-and-swap 把三者一起消灭：operator= 只做一次 noexcept 的 swap。");
    println("      代价：多一次拷贝 + 一次交换（现代编译器下常常被优化掉）。");

    // ---------- ② std::expected ----------
    println("");
    println("  (2) std::expected：失败是返回值的一部分，不是异常");
    for (const std::string_view in : {"42", "-17", "+8", "abc", "", "99999999999"}) {
        const auto r = parse_int(in);
        if (r) {
            println("      parse_int({:<12}) = {}（成功）", std::string(in), *r);
        } else {
            println("      parse_int({:<12}) -> 失败：{}", std::string(in), r.error());
        }
    }
    assert(parse_int("42").value() == 42);
    assert(!parse_int("abc"));
    println("      好处：失败路径**无法被静默忽略**（可加 [[nodiscard]]）；");
    println("      且没有 try/catch 的运行时开销，也没有异常跨边界的栈展开代价。");
    println("      取值三式：.value()（失败则抛 bad_expected_access，调试用）、");
    println("      .value_or(x)（给默认）、*r / r.has_value()（先判再用）。");

    // ---------- ③ 防御性编程三形态 ----------
    println("");
    println("  (3) 防御性编程三形态：各管一段区间");
    // 形态 A：断言——「这不该发生」，是程序员之间的契约，违反即程序有 bug
    std::vector<int> buf;
    auto push = [&buf](int v) {
        assert(v >= 0 && "只接受非负——契约，违反即程序有 bug");
        buf.push_back(v);
    };
    push(3);
    push(5);
    println("      断言管「程序员违约」：push两次后 size = {}", buf.size());
    // 形态 B：异常——管「调用方违约」，来源是外部输入 / 网络 / 文件
    // 形态 C：返回值——管「正常业务分支」，如"没找到"
    constexpr std::size_t kNotFound = static_cast<std::size_t>(-1);
    auto find = [](const std::vector<int>& a, int x) -> std::size_t {
        for (std::size_t i = 0; i < a.size(); ++i) {
            if (a[i] == x) { return i; }
        }
        return kNotFound;                            // 正常分支：没找到
    };
    const std::vector<int> sorted{1, 3, 5, 7};
    const std::size_t f5 = find(sorted, 5);
    const std::size_t f4 = find(sorted, 4);
    println("      返回值管「正常分支」：找 5 得下标 {}，找 4 得 {}（= kNotFound）",
            f5, f4 == kNotFound);
    assert(f5 == 2 && f4 == kNotFound);
    println("      三者取舍：断言 = 程序员错（终止并留现场）、");
    println("      异常 = 调用方错（可恢复、可传播）、返回值 = 不是错（正常枚举）。");
    println("      最糟的混用是拿异常表达「没找到」——那本该是 optional 或下标；");
    println("      二分查找返回「没找到」是正常分支，不是异常（见第 04 章）。");
}

int main() {
    feature_table();
    io_shim_demo();
    portable_random_demo();
    algorithms_as_technology();
    determinism_demo();
    engineering_standards_demo();
    println("自检通过");
    return 0;
}
