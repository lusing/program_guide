#include <algorithm>   // remove / find / partial_sort / nth_element / partition / equal_range …
#include <cctype>      // tolower
#include <cstddef>     // size_t
#include <cstring>     // strlen（条 16 的"C API"替身）
#include <deque>
#include <functional>  // less / less_equal
#include <iterator>    // istream_iterator / istreambuf_iterator / next
#include <memory>      // unique_ptr / make_unique
#include <list>
#include <map>
#include <numeric>     // accumulate（条 48：它在 <numeric>，不在 <algorithm>）
#include <print>
#include <set>
#include <sstream>
#include <string>
#include <type_traits>  // is_same_v
#include <utility>     // pair
#include <vector>

// 36 Effective STL 实战：50 条精要的现代验证
//
// 按 Meyers《Effective STL》逐条演示经典条款，并给出 C++23 视角的裁决：
// 有的条款 25 年后依旧成立，有的已被标准演进解决（auto_ptr/配接器/erase_if…）。
// 输出全部为确定值：不打印容量、sizeof、地址、耗时等实现相关数字。

namespace {

// 拼接工具：多处复用（条 43 精神的反面教材——能复用的小循环集中一处）
std::string show(const std::vector<int>& v) {
    std::string s;
    for (int x : v) {
        if (!s.empty()) s += ' ';
        s += std::to_string(x);
    }
    return s;
}

struct Base {
    virtual std::string name() const { return "Base"; }
    virtual ~Base() = default;
};
struct Derived : Base {
    std::string name() const override { return "Derived"; }
};

struct Widget7 {   // 条 7/33：给指针容器的资源账本装上计数器
    static inline int born = 0, dead = 0;
    std::string name;
    explicit Widget7(std::string n) : name{std::move(n)} { ++born; }
    ~Widget7() { ++dead; }
    bool stale() const { return name == "old"; }
};

struct Averager {  // 条 37：for_each 的函数子允许带状态（accumulate 的运算则不许）
    long sum = 0;
    int n = 0;
    void operator()(int v) { sum += v; ++n; }
    double value() const { return static_cast<double>(sum) / n; }
};

}  // namespace

int main() {
    // ═══ 36.1 条 3：容器里存的是拷贝——切片═══
    std::vector<Base> sliced;
    sliced.push_back(Derived{});   // 拷贝按 Base 的拷贝构造走 → 派生部分丢失
    std::println("条3 基类容器装派生对象 → name() = {}（派生部分被切掉）", sliced[0].name());

    // ═══ 36.2 条 4/5：empty() 与区间成员函数═══
    std::list<int> lst{1, 2};
    std::println("条4 empty() = {}（C++11 起所有容器 size() 也恒 O(1)——list 拿 splice 让的步）",
                 lst.empty());
    std::vector<int> src{1, 2, 3, 4, 5, 6, 7};
    std::vector<int> half;
    half.assign(src.begin() + 3, src.end());   // 一行抵一个逐元素循环
    std::println("条5 区间 assign 拷后半: [{}]", show(half));

    // ═══ 36.3 条 6：最烦人的解析，大括号修复═══
    // std::vector<int> data(std::istream_iterator<int>{in}, std::istream_iterator<int>());
    // —— 上面这行声明的是一个返回 vector<int> 的函数 data，不是容器对象！
    std::istringstream nums_in{"10 20 30"};
    std::istream_iterator<int> read{nums_in}, eof{};
    std::vector<int> parsed{read, eof};   // {} + 命名迭代器：两个修复一起上
    std::println("条6 大括号绕开“最烦人的解析”: {} 个 [{},{},{}]",
                 parsed.size(), parsed[0], parsed[1], parsed[2]);

    // ═══ 36.4 条 7/8/33：指针容器三兄弟 → unique_ptr 一站式═══
    {
        std::vector<std::unique_ptr<Widget7>> vault;
        for (const char* n : {"a", "old", "b", "old", "c"}) {
            vault.push_back(std::make_unique<Widget7>(n));
        }
        std::erase_if(vault, [](const std::unique_ptr<Widget7>& p) { return p->stale(); });
        std::println("条7/33 unique_ptr 容器 + erase_if: 持有 {} 个，构造 {} 次，已析构 {} 次",
                     vault.size(), Widget7::born, Widget7::dead);
    }
    std::println("条7 出作用域自动清场: 构造 {} 次 == 析构 {} 次 → 泄漏 0", Widget7::born, Widget7::dead);

    // ═══ 36.5 条 9/32：remove 不删除——erase-remove 与 std::erase_if═══
    std::vector<int> rm{1, 99, 3, 99, 5, 99, 7};
    auto new_end = std::remove(rm.begin(), rm.end(), 99);
    std::string kept;
    for (auto it = rm.begin(); it != new_end; ++it) {
        if (!kept.empty()) kept += ' ';
        kept += std::to_string(*it);
    }
    const auto zombies = static_cast<int>(std::distance(new_end, rm.end()));
    rm.erase(new_end, rm.end());   // erase-remove 惯用法：真删要靠容器的 erase 收尾
    std::println("条32 remove 后 size 仍 = 7，保留前缀 [{}]，僵尸 {} 个（值未指定）", kept, zombies);
    std::vector<int> rm2{1, 99, 3, 99, 5};
    const auto removed = std::erase_if(rm2, [](int v) { return v == 99; });
    std::println("条9/32 C++20 一行式: std::erase_if 删掉 {} 个 → [{}]", removed, show(rm2));

    // ═══ 36.6 条 14/17：reserve 防搬移，shrink_to_fit 收缩═══
    std::vector<int> reserved;
    reserved.reserve(1000);
    const int* anchor = reserved.data();
    for (int i = 0; i < 1000; ++i) reserved.push_back(i);
    std::println("条14 reserve 后连 push 1000 次，数据指针不动 = {}", reserved.data() == anchor);

    std::vector<int> naive;
    bool relocated = false;
    for (int i = 0; i < 1000; ++i) {
        const int* before = naive.data();
        naive.push_back(i);
        if (naive.data() != before) relocated = true;
    }
    std::println("条14 不 reserve：1000 次 push 中数据搬过家 = {}", relocated);
    naive.erase(naive.begin() + 10, naive.end());
    naive.shrink_to_fit();   // 条 17 的 swap 技巧在 C++11 转正为成员函数（非强制请求）
    std::println("条17 shrink_to_fit 后 capacity == size = {}", naive.capacity() == naive.size());

    // ═══ 36.7 条 16：data()/c_str() 送 C 风格 API═══
    auto legacy_sum = [](const int* p, std::size_t n) {
        long total = 0;
        for (std::size_t i = 0; i < n; ++i) total += p[i];
        return total;
    };
    std::vector<int> for_c{2, 4, 6};
    std::println("条16 v.data() 送 C 风格 API: sum = {}", legacy_sum(for_c.data(), for_c.size()));
    std::string s{"hi"};
    std::println("条16 s.c_str() 是 NUL 结尾的 C 串: strlen = {}；s.data() 只保证连续不保证 NUL",
                 std::strlen(s.c_str()));
    std::vector<int> empty_c;
    std::println("条16 空容器 data() 可调用但不可解引用 → 传参先判空 = {}", empty_c.empty());

    // ═══ 36.8 条 18：vector<bool> 是代理容器═══
    static_assert(!std::contiguous_iterator<std::vector<bool>::iterator>,
                  "vector<bool> 的迭代器不连续——它不存 bool，存的是打包的位");
    std::vector<bool> flags(6, false);
    static_assert(std::is_same_v<decltype(flags[0]), std::vector<bool>::reference>,
                  "operator[] 返回的是“像 bool 引用的代理对象”，不是 bool&");
    flags[2] = true;
    flags.flip();
    std::println("条18 flip 全体取反: flags[0] = {}, flags[2] = {}（真 bool 容器用 deque<bool>/vector<char>）",
                 flags[0], flags[2]);

    // ═══ 36.9 条 19/21/35：等价 vs 相等——忽略大小写 set 三连═══
    auto ci_char_less = [](char a, char b) {
        return std::tolower(static_cast<unsigned char>(a)) <    // char 先转 unsigned char 再进 tolower
               std::tolower(static_cast<unsigned char>(b));     // （负值 char 直接喂是 UB）
    };
    auto ci_less = [ci_char_less](const std::string& a, const std::string& b) {
        return std::lexicographical_compare(a.begin(), a.end(), b.begin(), b.end(), ci_char_less);
    };
    std::set<std::string, decltype(ci_less)> ci_names{ci_less};
    ci_names.insert("Persephone");
    ci_names.insert("persephone");   // 与第一个“等价”（≠“相等”）→ 被拒
    std::println("条19 忽略大小写 set 插两个拼写: size = {}", ci_names.size());
    std::println("条19 成员 find 按等价找 PERSEPHONE: 找到 = {}",
                 ci_names.find("PERSEPHONE") != ci_names.end());
    std::println("条19 算法 find 按相等找 PERSEPHONE: 找到 = {}（同一容器两种答案）",
                 std::find(ci_names.begin(), ci_names.end(), "PERSEPHONE") != ci_names.end());
    std::less_equal<int> bad_comp;
    std::less<int> good_comp;
    std::println("条21 严格弱序体检: less_equal(10,10) = {}（不合格）, less(10,10) = {}（合格）",
                 bad_comp(10, 10), good_comp(10, 10));

    // ═══ 36.10 条 20：指针 set 配解引用比较═══
    auto deref_less = [](const std::string* a, const std::string* b) { return *a < *b; };
    std::deque<std::string> stable_home{"pear", "apple", "fig"};   // deque 挪动时地址稳定
    std::set<const std::string*, decltype(deref_less)> by_value{deref_less};
    for (const std::string& fruit : stable_home) by_value.insert(&fruit);
    std::string fruit_line;
    for (const std::string* p : by_value) {
        if (!fruit_line.empty()) fruit_line += ' ';
        fruit_line += *p;
    }
    std::println("条20 指针 set 配解引用比较: [{}]（默认按指针值排，不是按内容）", fruit_line);

    // ═══ 36.11 条 22：set/map 的键只读——extract 拿节点改键再放回═══
    std::map<int, std::string> staff{{1, "ada"}, {2, "bob"}, {3, "eve"}};
    auto node = staff.extract(2);   // 节点整棵拔出，值不搬窝
    node.key() = 20;
    staff.insert(std::move(node));
    std::println("条22 extract 改键: 含 2 = {}, 含 20 = {}, 20 → {}",
                 staff.contains(2), staff.contains(20), staff.at(20));

    // ═══ 36.12 条 24：operator[] vs try_emplace / insert_or_assign═══
    std::map<int, std::string> quota;
    quota.emplace(1, "first");
    std::string payload{"second"};
    auto res = quota.try_emplace(1, std::move(payload));
    std::println("条24 try_emplace 撞已有键: inserted = {}, 已有值 = {}, 实参字符串仍完好 = {}",
                 res.second, res.first->second, !payload.empty());
    quota.insert_or_assign(1, std::string{"replaced"});
    std::println("条24 insert_or_assign 覆盖: quota[1] = {}", quota.at(1));

    // ═══ 36.13 条 28：reverse_iterator::base 的插入/删除偏移═══
    std::vector<int> seq{1, 2, 3, 4, 5};
    auto ri = std::find(seq.rbegin(), seq.rend(), 3);   // ri 指向 3
    seq.insert(ri.base(), 99);                          // 插入用 base() 本尊 → 1 2 3 99 4 5
    std::println("条28 在 ri 处插入 99: [{}]", show(seq));
    ri = std::find(seq.rbegin(), seq.rend(), 3);
    seq.erase(std::next(ri).base());                    // 删除要偏一格：next(ri).base() → 1 2 99 4 5
    std::println("条28 删掉 ri 所指的 3: [{}]（插删偏移口诀：插用 base，删偏一格）", show(seq));

    // ═══ 36.14 条 29：istreambuf_iterator 原样读流═══
    std::istringstream raw_in{"a b  c"};
    std::istreambuf_iterator<char> raw_read{raw_in}, raw_end{};
    std::string verbatim{raw_read, raw_end};   // 直读流缓冲区：空白一个不丢
    std::println("条29 istreambuf_iterator 原样读: [{}]", verbatim);
    std::istringstream word_in{"a b  c"};
    int word_count = 0;
    std::string w;
    while (word_in >> w) ++word_count;         // 格式化抽取默认跳空白
    std::println("条29 格式化视角只有 {} 个词（同一串输入，两种读法）", word_count);

    // ═══ 36.15 条 31：sort 家族选型——要多少排多少═══
    const std::vector<int> mix{9, 1, 8, 2, 7, 3, 6, 4, 5};
    std::vector<int> top3 = mix;
    std::partial_sort(top3.begin(), top3.begin() + 3, top3.end());
    std::println("条31 partial_sort 前 3 名且有序: {} {} {}", top3[0], top3[1], top3[2]);
    std::vector<int> mid = mix;
    std::nth_element(mid.begin(), mid.begin() + 4, mid.end());
    std::println("条31 nth_element 第 5 小 = {}, 前半截全部 < 5 = {}", mid[4],
                 std::all_of(mid.begin(), mid.begin() + 4, [](int v) { return v < 5; }));
    std::vector<int> part = mix;
    std::partition(part.begin(), part.end(), [](int v) { return v <= 4; });
    std::println("条31 partition 前 4 名全部 ≤ 4 = {}（不排序，只分区）",
                 std::all_of(part.begin(), part.begin() + 4, [](int v) { return v <= 4; }));

    // ═══ 36.16 条 23/34/44/45：排序 vector + 二分查找 + 成员函数优先═══
    const std::vector<int> sorted_v{1, 3, 5, 7, 9};
    auto [lo5, hi5] = std::equal_range(sorted_v.begin(), sorted_v.end(), 5);
    auto [lo6, hi6] = std::equal_range(sorted_v.begin(), sorted_v.end(), 6);
    std::println("条45 equal_range(5) 命中 {} 个; equal_range(6) 命中 0 个、插入点在第 {} 格",
                 std::distance(lo5, hi5), std::distance(sorted_v.begin(), lo6));
    std::println("条34 binary_search(6) = {}（这些算法要求有序区间——喂了未排序的不报错，直接算错）",
                 std::binary_search(sorted_v.begin(), sorted_v.end(), 6));
    std::set<int> index{sorted_v.begin(), sorted_v.end()};
    std::println("条44 关联容器用成员函数: contains(9) = {}（O(log n)；算法版 std::find 是 O(n)）",
                 index.contains(9));

    // ═══ 36.17 条 37/43/47：区间统计 + lambda 替代配接器天书═══
    const std::vector<std::string> words{"alpha", "beta", "gamma"};
    const auto total_len = std::accumulate(words.begin(), words.end(), std::size_t{0},
                                           [](std::size_t acc, const std::string& t) {
                                               return acc + t.size();
                                           });
    std::println("条37 accumulate 折自定义统计: 总长 = {}", total_len);
    const std::vector<double> parts{1.5, 2.5};
    std::println("条37 初始值定累加类型: accumulate(初值 0) = {}, accumulate(初值 0.0) = {}",
                 std::accumulate(parts.begin(), parts.end(), 0),
                 std::accumulate(parts.begin(), parts.end(), 0.0));
    const std::vector<int> data{2, 4, 6};
    const auto avg = std::for_each(data.begin(), data.end(), Averager{});
    std::println("条37 for_each 带状态返回: 平均 = {}", avg.value());
    int lo = 3, hi = 8;   // 非 const：const 整型带常量初值时 lambda 免捕获，再显式捕获反而是告警
    const auto first_mid = std::ranges::find_if(data, [lo, hi](int v) { return lo < v && v < hi; });
    std::println("条43 书里要 compose2 嵌套配接器的“找 ∈({},{}) 的数”→ lambda 两行: {}",
                 lo, hi, *first_mid);

    std::println("自检通过");
}
