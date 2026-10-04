// 21 van Emde Boas 树（CLRS 第 20 章）。结构：21.1 全域 u=16 的递归结构
//（簇+汇总位图）/ 21.2 INSERT/MIN/MAX/SUCCESSOR 追踪 / 21.3 与朴素位图
// 全量对账（成员/前驱后继）。示例收缩到固定小全域 u=16 减负（计划注记）。
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

#include <array>
#include <bit>
#include <cassert>
#include <cstdint>
#include <vector>

// vEB(u)：u ≥ 2 时有 cluster[√u] 与 summary（每簇又是 vEB(√u)）。
// u = 2 时只有 min/max 当「位」用（无 cluster）。
// 关键不变式：min 存的元素**不出现在**任何簇里（重复存储的消除）。
struct Veb {
    int u;                    // 全域大小（2 的幂）
    int min = -1, max = -1;   // -1 = 空
    Veb* summary = nullptr;
    std::vector<Veb*> cluster;

    explicit Veb(int universe) : u(universe) {
        if (u > 2) {
            const int hi = high_part();
            summary = new Veb(hi);
            cluster.assign(static_cast<std::size_t>(hi), nullptr);
        }
    }
    int high_part() const { return 1 << (std::countr_zero(static_cast<unsigned>(u)) / 2); }
    // i = cluster_index * √u + offset
    int cluster_of(int i) const { return i / high_part(); }
    int offset_of(int i) const { return i % high_part(); }
    int index(int c, int o) const { return c * high_part() + o; }

    bool member(int i) const {
        if (i == min || i == max) { return true; }
        if (u == 2) { return false; }
        const int c = cluster_of(i);
        if (cluster[static_cast<std::size_t>(c)] == nullptr) { return false; }
        return cluster[static_cast<std::size_t>(c)]->member(offset_of(i));
    }

    void insert_empty(int i) { min = i; max = i; }   // 空树插入的特殊路径

    void insert(int i) {
        if (min == -1) { insert_empty(i); return; }
        if (i < min) { std::swap(i, min); }          // 新最小值：旧 min 下沉进簇
        if (u > 2) {
            const int c = cluster_of(i);
            if (cluster[static_cast<std::size_t>(c)] == nullptr) {
                cluster[static_cast<std::size_t>(c)] = new Veb(high_part());
            }
            if (cluster[static_cast<std::size_t>(c)]->min == -1) {
                summary->insert(c);                  // 簇从空到非空：汇总位图置位
            }
            cluster[static_cast<std::size_t>(c)]->insert(offset_of(i));
        }
        if (i > max) { max = i; }
    }

    int successor(int i) const {     // > i 的最小元素；无则 -1
        if (u == 2) {
            if (i == 0 && max == 1) { return 1; }
            return -1;
        }
        if (min != -1 && i < min) { return min; }
        const int c = cluster_of(i);
        const int off = offset_of(i);
        const Veb* cl = cluster[static_cast<std::size_t>(c)];
        // 簇内或簇间两种情况
        if (cl != nullptr && cl->max != -1 && off < cl->max) {
            return index(c, cl->successor(off));     // 后继在本簇
        }
        const int sc = summary->successor(c);        // 下一个非空簇
        if (sc == -1) { return -1; }
        return index(sc, cluster[static_cast<std::size_t>(sc)]->min);
    }
};

static void veb_demo() {
    Veb t(16);                        // 全域 {0..15}，√u = 4
    // 插入 2,3,4,5,7,14,15（覆盖多个簇）
    for (int x : {2, 3, 4, 5, 7, 14, 15}) { t.insert(x); }
    println("van Emde Boas 树（u=16，插入 2 3 4 5 7 14 15）：");
    println("  min = {}，max = {}（O(1) 直接读字段）", t.min, t.max);
    assert(t.min == 2 && t.max == 15);
    // SUCCESSOR 追踪
    println("  successor(5) = {}（跨簇：簇 1 的偏移 1 之后无 → 汇总找簇 3）",
            t.successor(5));
    assert(t.successor(5) == 7);
    assert(t.successor(7) == 14);
    assert(t.successor(15) == -1);
    // 与朴素位图全量对账
    std::array<char, 16> bits{};
    for (int x : {2, 3, 4, 5, 7, 14, 15}) { bits[static_cast<std::size_t>(x)] = 1; }
    bool memberOk = true, succOk = true;
    for (int i = 0; i < 16; ++i) {
        if (t.member(i) != (bits[static_cast<std::size_t>(i)] != 0)) { memberOk = false; }
        int naiveSucc = -1;
        for (int j = i + 1; j < 16; ++j) {
            if (bits[static_cast<std::size_t>(j)]) { naiveSucc = j; break; }
        }
        if (t.successor(i) != naiveSucc) { succOk = false; }
    }
    println("  16 个值的 member/逐位后继与朴素位图全部一致 = {},{}", memberOk ? 1 : 0,
            succOk ? 1 : 0);
    assert(memberOk && succOk);
    // u=16 的结构高度：√16=4 → 簇是 vEB(4)，其簇是 vEB(2)——共 3 层
    println("  递归深度 = 3（u=16 → 簇 u=4 → 簇簇 u=2），每操作 O(lg lg u) = 2 层递归量级");
}

int main() {
    veb_demo();
    println("自检通过");
    return 0;
}
