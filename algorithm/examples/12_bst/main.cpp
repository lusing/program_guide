// 12 二叉搜索树（CLRS 第 12 章）。结构：12.1 建树与遍历（图 12.1 的树）/
// 12.2 搜索路径追踪 / 12.3 三种删除案例 / 12.4 中序后继链 /
// 12.5 随机构建 BST 的高度与平均深度实验（定理 12.4）/
// 12.6 由前序+中序重建二叉树（分治 + 哈希表把 O(n²) 降到 O(n)）/
// 12.7 子树判定（两棵任意形状的树，递归比较）。
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
#include <span>
#include <unordered_map>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// 节点用 arena 数组（第 10 章的三数组纪律），下标当指针，NIL = SIZE_MAX
constexpr std::size_t NIL = SIZE_MAX;

struct Bst {
    std::vector<int> key;
    std::vector<std::size_t> left, right, parent;
    std::size_t root = NIL;

    std::size_t make_node(int k, std::size_t p) {
        key.push_back(k);
        left.push_back(NIL);
        right.push_back(NIL);
        parent.push_back(p);
        return key.size() - 1;
    }

    // 12.2 TREE-INSERT：从根下行，比当前小走左、大走右
    void insert(int k) {
        if (root == NIL) { root = make_node(k, NIL); return; }
        std::size_t x = root;
        while (true) {
            if (k < key[x]) {
                if (left[x] == NIL) { left[x] = make_node(k, x); return; }
                x = left[x];
            } else {
                if (right[x] == NIL) { right[x] = make_node(k, x); return; }
                x = right[x];
            }
        }
    }

    std::size_t search(int k) const {
        std::size_t x = root;
        while (x != NIL && key[x] != k) {
            x = (k < key[x]) ? left[x] : right[x];
        }
        return x;
    }

    std::size_t minimum(std::size_t x) const {
        while (left[x] != NIL) { x = left[x]; }
        return x;
    }

    // 12.2 TREE-SUCCESSOR：有右子树取右最小；否则向上找「第一个左拐」祖先
    std::size_t successor(std::size_t x) const {
        if (right[x] != NIL) { return minimum(right[x]); }
        std::size_t y = parent[x];
        while (y != NIL && x == right[y]) { x = y; y = parent[y]; }
        return y;
    }

    // 12.3 TRANSPLANT：用子树 v 替换子树 u
    void transplant(std::size_t u, std::size_t v) {
        if (parent[u] == NIL)         { root = v; }
        else if (u == left[parent[u]])  { left[parent[u]] = v; }
        else                            { right[parent[u]] = v; }
        if (v != NIL)                 { parent[v] = parent[u]; }
    }

    // 12.3 TREE-DELETE 三种情况
    void erase(std::size_t z) {
        if (left[z] == NIL) {
            transplant(z, right[z]);                       // 情况 1/2：无左子
        } else if (right[z] == NIL) {
            transplant(z, left[z]);                        // 情况 2：无右子
        } else {
            const std::size_t y = minimum(right[z]);       // 情况 3：双子
            if (parent[y] != z) {
                transplant(y, right[y]);
                right[y] = right[z];
                parent[right[y]] = y;
            }
            transplant(z, y);
            left[y] = left[z];
            parent[left[z]] = y;
        }
    }

    std::vector<int> inorder() const {
        std::vector<int> out;
        // 中序 = 依次取 minimum + successor 链（练习 12.2-3 的迭代遍历）
        if (root == NIL) { return out; }
        std::size_t x = minimum(root);
        while (x != NIL) {
            out.push_back(key[x]);
            x = successor(x);
        }
        return out;
    }

    std::size_t height(std::size_t x) const {
        if (x == NIL) { return 0; }
        return 1 + std::max(height(left[x]), height(right[x]));
    }

    long long total_depth(std::size_t x, long long d) const {
        if (x == NIL) { return 0; }
        return d + total_depth(left[x], d + 1) + total_depth(right[x], d + 1);
    }
};

static void build_and_walk() {
    Bst t;
    // 按图 12.1 的结构插出同一棵树（先 15，再 6/18，逐层补齐）
    for (int k : {15, 6, 18, 3, 7, 17, 20, 2, 4, 13, 9}) { t.insert(k); }
    const auto io = t.inorder();
    print("图 12.1 的 BST 中序遍历: ");
    for (int v : io) { print("{} ", v); }
    println("");
    assert((io == std::vector<int>{2, 3, 4, 6, 7, 9, 13, 15, 17, 18, 20}));
    println("树高 = {}（11 节点，⌈lg 11⌉+1 = 5，退化链则 11）", t.height(t.root));
    assert(t.height(t.root) == 5);
}

static void search_trace() {
    Bst t;
    for (int k : {15, 6, 18, 3, 7, 17, 20, 2, 4, 13, 9}) { t.insert(k); }
    print("search(13) 路径: ");
    std::size_t x = t.root;
    while (t.key[x] != 13) {
        print("{} ", t.key[x]);
        x = (13 < t.key[x]) ? t.left[x] : t.right[x];
    }
    print("{}（命中）", t.key[x]);
    println("");
    assert(t.search(13) == x);
    assert(t.search(14) == NIL);
    println("search(14) 返回 NIL（走到叶 13 的右空指针）");
}

static void deletion_cases() {
    // 情况 1：叶节点；情况 2：单孩子；情况 3：双孩子（后继顶替）
    {
        Bst t;
        for (int k : {15, 6, 18, 3, 7, 17, 20, 2, 4, 13, 9}) { t.insert(k); }
        const auto before = t.inorder();
        t.erase(t.search(4));                    // 情况 1：4 是叶
        auto after = t.inorder();
        assert(before.size() == after.size() + 1);
        println("删除叶 4（情况 1）：父节点 3 的右指针置 NIL");
    }
    {
        Bst t;
        for (int k : {15, 6, 18, 3, 7, 17, 20, 2, 4, 13, 9}) { t.insert(k); }
        t.erase(t.search(7));                    // 情况 2：7 只有右孩子 9
        const auto after = t.inorder();
        assert(std::ranges::find(after, 7) == after.end());
        assert(std::ranges::find(after, 9) != after.end());
        println("删除单孩子节点 7（情况 2）：孩子 9 直接顶位");
    }
    {
        Bst t;
        for (int k : {15, 6, 18, 3, 7, 17, 20, 2, 4, 13, 9}) { t.insert(k); }
        t.erase(t.search(15));                   // 情况 3：根 15 双子，后继 17
        assert(t.key[t.root] == 17);
        const auto after = t.inorder();
        assert((after == std::vector<int>{2, 3, 4, 6, 7, 9, 13, 17, 18, 20}));
        println("删除双子节点 15（情况 3）：后继 17 顶上根（右子树最小）");
    }
    // 中序后继链（练习 12.2-3：用 successor 遍历替代递归）
    Bst t;
    for (int k : {15, 6, 18, 3, 7, 17, 20, 2, 4, 13, 9}) { t.insert(k); }
    std::size_t x = t.minimum(t.root);
    print("minimum 起步的后继链: ");
    for (int i = 0; i < 5 && x != NIL; ++i) {
        print("{} ", t.key[x]);
        x = t.successor(x);
    }
    println("...（即有序序列）");
    assert(t.key[t.minimum(t.root)] == 2);
}

static void random_bst_experiment() {
    // 定理 12.4：随机插入 n 个键，期望高度 = O(lg n)（精确常数 ~4.311·ln n）
    const int n = 1023;
    std::mt19937 rng{5489};
    long long sumHeight = 0, sumDepth = 0;
    const int trials = 50;
    for (int t = 0; t < trials; ++t) {
        Bst bst;
        std::vector<int> keys(n);
        for (int i = 0; i < n; ++i) { keys[static_cast<std::size_t>(i)] = i; }
        for (int i = n - 1; i > 0; --i) {
            std::swap(keys[static_cast<std::size_t>(i)],
                      keys[static_cast<std::size_t>(rand_below(rng, static_cast<std::uint32_t>(i) + 1))]);
        }
        for (int k : keys) { bst.insert(k); }
        assert(bst.inorder().size() == static_cast<std::size_t>(n));
        sumHeight += static_cast<long long>(bst.height(bst.root));
        sumDepth += bst.total_depth(bst.root, 1);
    }
    // ln 1023 = 6.9307；期望高度 ~ 4.311·ln n ≈ 29.9；平均深度 ~ 2·ln n ≈ 13.9
    println("随机构建 BST：n={} × {} 个固定种子排列：", n, trials);
    println("  平均树高 {}（理论 ~4.311·ln n = {:.1f}）",
            sumHeight / trials, 4.311 * 6.9307);
    println("  平均节点深度 {:.2f}（理论 ~2·ln n = {:.1f}）",
            static_cast<double>(sumDepth) / trials / n, 2.0 * 6.9307);
    assert(sumHeight / trials < 60);
}

// ═══ 12.6 由前序 + 中序重建二叉树 ═══
// 前提：节点键值**互不相同**（否则中序里同一个值出现多次，无法定位根）。
// 递归骨架（教科书版 O(n²)）：
//   前序 = 根 | 左 | 右   → 第一个元素永远是根
//   中序 = 左 | 根 | 右   → 根的下标 p 决定了左子树有 p 个节点
// 于是左右子树的**规模**都确定了，两个序列可以同时切片，递归重建。
// 每一层递归至少消费 1 个节点，所以递归深度 = n，朴素版在链状输入上
// 栈深 O(n)——和 12.5 的退化 BST 是同一个灾难。
//
// 优化：把「在中序里找根的下标」从每次 O(n) 的线性扫描换成 O(1) 哈希
// 查表，总代价立刻从 O(n²) 降到 O(n)。示例对同一份输入两种版本都跑，
// 并用「下标查找次数」把差距量化出来。
struct RebuildTree {
    std::vector<int> key;
    std::vector<std::size_t> left, right;
    std::size_t root = NIL;
    long long lookups = 0;                      // 「在中序里定位根」的次数

    std::size_t make(int v) {
        key.push_back(v);
        left.push_back(NIL);
        right.push_back(NIL);
        return key.size() - 1;
    }
};

// 朴素版：每次用 ranges::find 在当前中序窗口里线性找根 → 总计 Θ(n²)
//
// 参数约定（两个坐标系别混！）：
//   pre  —— 当前子树的前序**窗口**（已切到子树那一段）
//   in   —— 当前子树的中序**窗口**
//   base —— in 窗口在**原始中序数组**里的起始偏移。只有哈希版需要它，
//           因为 pos 表是按原始下标建的。
static std::size_t rebuild_naive(std::span<const int> pre, std::span<const int> in,
                                 RebuildTree& out) {
    if (pre.empty()) { return NIL; }
    out.lookups += 1;
    // 在**窗口内**定位根：p 是窗口内的相对下标
    const std::size_t p = static_cast<std::size_t>(
        std::ranges::find(in, pre.front()) - in.begin());
    const std::size_t root = out.make(pre.front());
    const std::size_t left_size = p;            // 窗口内左子树有 p 个节点
    out.left[root] = rebuild_naive(pre.subspan(1, left_size),
                                   in.subspan(0, left_size), out);
    out.right[root] = rebuild_naive(pre.subspan(1 + left_size),
                                    in.subspan(left_size + 1), out);
    return root;
}

// 哈希加速版：pos[v] 给出 v 在**原始中序**里的下标；用 base 把绝对下标
// 换算回窗口内的相对下标（p_rel = p_abs − base）。定位 O(1)，总计 O(n)。
static std::size_t rebuild_fast(std::span<const int> pre, std::span<const int> in,
                                std::size_t base,
                                const std::unordered_map<int, std::size_t>& pos,
                                RebuildTree& out) {
    if (pre.empty()) { return NIL; }
    out.lookups += 1;
    const std::size_t p_abs = pos.at(pre.front());   // O(1)：一次哈希查表
    assert(p_abs >= base && p_abs < base + in.size());   // 键必须落在本窗口内
    const std::size_t p = p_abs - base;             // 换算成窗口内相对下标
    const std::size_t root = out.make(pre.front());
    const std::size_t left_size = p;
    out.left[root] = rebuild_fast(pre.subspan(1, left_size),
                                  in.subspan(0, left_size), base, pos, out);
    out.right[root] = rebuild_fast(pre.subspan(1 + left_size),
                                   in.subspan(left_size + 1),
                                   base + left_size + 1, pos, out);
    return root;
}

// 校验重建结果的三个遍历都等于原序列
static void collect(const RebuildTree& t, std::size_t x, int order,
                    std::vector<int>& out) {
    if (x == NIL) { return; }
    if (order == 0) { out.push_back(t.key[x]); }
    collect(t, t.left[x], order, out);
    if (order == 1) { out.push_back(t.key[x]); }
    collect(t, t.right[x], order, out);
    if (order == 2) { out.push_back(t.key[x]); }
}

static void rebuild_demo() {
    println("");
    println("=== 12.6 由前序 + 中序重建二叉树 ===");
    const std::vector<int> pre{3, 9, 20, 15, 7};
    const std::vector<int> in{9, 3, 15, 20, 7};
    print("前序 "); for (int v : pre) { print("{} ", v); }
    println("");
    print("中序 "); for (int v : in) { print("{} ", v); }
    println("");

    // 朴素版
    RebuildTree naive;
    naive.root = rebuild_naive(pre, in, naive);
    println("朴素版（在中序里线性找根）：重建完成，定位根 {} 次", naive.lookups);
    assert(naive.lookups == static_cast<long long>(pre.size()));

    // 哈希加速版：先建「区间起点 → 键 → 中序下标」的表
    std::unordered_map<int, std::size_t> global;
    for (std::size_t i = 0; i < in.size(); ++i) { global[in[i]] = i; }
    RebuildTree fast;
    fast.root = rebuild_fast(pre, in, 0, global, fast);
    println("哈希加速版（pos 表 O(1) 定位）：定位根 {} 次", fast.lookups);
    assert(fast.lookups == static_cast<long long>(pre.size()));
    println("两者「定位根」的次数相同，但朴素版每次要线性扫 Θ(n)：n 小时无差别，");
    println("n 大时差距是平方级（见下方规模实验）。");

    // 校验：三个遍历都应还原
    std::vector<int> got_pre{}, got_in{}, got_post{};
    collect(fast, fast.root, 0, got_pre);
    collect(fast, fast.root, 1, got_in);
    collect(fast, fast.root, 2, got_post);
    print("重建后 前序 "); for (int v : got_pre) { print("{} ", v); }
    println("");
    print("重建后 中序 "); for (int v : got_in) { print("{} ", v); }
    println("");
    print("重建后 后序 "); for (int v : got_post) { print("{} ", v); }
    println("");
    assert(got_pre == pre);
    assert(got_in == in);

    // 为什么必须是「前序 + 中序」而不是「前序 + 后序」？
    // 前序+后序都无法确定左右子树怎么分：两个节点时 {1,2} 的前序后序
    // 都是 [1,2]，但「1 是 2 的左孩子」与「1 是 2 的右孩子」是**两棵
    // 不同的树**——而中序能唯一切分左右，所以它才是必需的那一半。
    println("对照：前序+后序不能重建——两个节点 [1,2] 的前序/后序都是 [1,2]，");
    println("      却对应两棵不同的树（1 在左 / 1 在右）；中序能唯一切分左右。");

    // 规模实验：n 越大两种写法的总代价差距越明显。
    // 计数口径：「在中序里定位根」的总比较次数。
    //   朴素版：每层递归在长度 L 的中序里线性扫，平均扫 L/2 → 合计 ≈ n²/4；
    //   哈希版：每层一次查表 → 合计恰为 n。
    // 这里只做**解析计数**（不真跑 n² 次比较），n 取三个量级看比值。
    println("规模实验（只计「定位根」的总比较次数，不真跑）：");
    println("      n   朴素 Θ(n²)/4   哈希 n   倍数");
    for (long long n : {100LL, 1000LL, 10000LL}) {
        const long long naive_cost = n * n / 4;
        println("{:7}   {:13}   {:6}   {:6.1f}", n, naive_cost, n,
                static_cast<double>(naive_cost) / static_cast<double>(n));
    }
    println("结论：朴素版随 n 平方增长，哈希版线性——n=10⁴ 时已差 2500 倍。");
}

// ═══ 12.7 子树判定 ═══
// 问题：B 是否 A 的子树（**不要求**是 BST，只是形状 + 键值都相同）？
// 递归基线只有两条：两边都空 → 是；只有一边空 → 不是。
// 键值不等立刻否掉，否则递归下去。
// 陷阱（对照 12.3 情况 3）：不要拿「前驱/后继」那套——子树判定与 BST
// 性质无关，是**形状**比较；用最小/最大键去剪枝是多余的复杂度。
static bool is_subtree(const RebuildTree& a, std::size_t x,
                       const RebuildTree& b, std::size_t y) {
    if (x == NIL && y == NIL) { return true; }     // 基线 1：都空
    if (x == NIL || y == NIL) { return false; }    // 基线 2：单边空
    if (a.key[x] != b.key[y]) { return false; }    // 键值不等
    return is_subtree(a, a.left[x], b, b.left[y])   // 递归左
        && is_subtree(a, a.right[x], b, b.right[y]);// 递归右
}

// 驱动：在 a 的**每个**节点上尝试一次匹配（b 的根不必是 a 的根）。
// 剪枝：先比键值，键不相等立刻跳过整棵子树——否则退化成 O(n·m)。
static bool contains_subtree(const RebuildTree& a, std::size_t x,
                             const RebuildTree& b) {
    if (x == NIL) { return false; }
    if (a.key[x] == b.key[b.root] && is_subtree(a, x, b, b.root)) { return true; }
    return contains_subtree(a, a.left[x], b) || contains_subtree(a, a.right[x], b);
}

static void subtree_demo() {
    println("");
    println("=== 12.7 子树判定（形状 + 键值全等）===");
    // A 是一棵普通二叉树（BST 判定是第 12 章正文的事，这里只比形状）：
    //
    //            3
    //           / ' ' '.
    //          9       20
    //                 /  ' ' '.
    //                15      7
    //
    // 搭树的写法纪律：make() 会 push_back 触发 vector 扩容，所以**不要**
    // 写 `A.left[A.root] = A.make(9)` —— 右侧 make 扩容后，左侧的 A.root
    // 是在扩容前读的下标（顺序未指定 + 潜在悬垂）。正确写法是先把 make
    // 的返回值落到局部变量，再拿它当下标。
    RebuildTree A;
    const std::size_t a3 = A.make(3);
    const std::size_t a9 = A.make(9);
    const std::size_t a20 = A.make(20);
    const std::size_t a15 = A.make(15);
    const std::size_t a7 = A.make(7);
    A.root = a3;
    A.left[a3] = a9;
    A.right[a3] = a20;
    A.left[a20] = a15;
    A.right[a20] = a7;

    // B 恰好就是 A 的右子树 [20, 15, 7]
    RebuildTree B;
    const std::size_t b20 = B.make(20);
    const std::size_t b15 = B.make(15);
    const std::size_t b7 = B.make(7);
    B.root = b20;
    B.left[b20] = b15;
    B.right[b20] = b7;
    println("B = [20, 15, 7]（正是 A 的右子树）→ A 含 B = {}",
            contains_subtree(A, A.root, B));
    assert(contains_subtree(A, A.root, B));

    // C 形状相同但键值不同（20 → 21）
    RebuildTree C;
    const std::size_t c21 = C.make(21);
    const std::size_t c15 = C.make(15);
    const std::size_t c7 = C.make(7);
    C.root = c21;
    C.left[c21] = c15;
    C.right[c21] = c7;
    println("C = [21, 15, 7]（根键不同）      → A 含 C = {}",
            contains_subtree(A, A.root, C));
    assert(!contains_subtree(A, A.root, C));

    // D 形状不同（少一层）
    RebuildTree D;
    const std::size_t d20 = D.make(20);
    const std::size_t d15 = D.make(15);
    D.root = d20;
    D.left[d20] = d15;
    println("D = [20, 15]（少一孩子）         → A 含 D = {}",
            contains_subtree(A, A.root, D));
    assert(!contains_subtree(A, A.root, D));

    // E 取 A 里真实存在的子树：15 的右子树就是单节点 7，
    // 而 15 自身（A 右孩子的左孩子）没有孩子——所以 E 只能是 [7]。
    // 想演示「深处的单侧子树」，用 [7] 最干净。
    RebuildTree E;
    E.root = E.make(7);
    println("E = [7]（A 右孩子的右孩子）      → A 含 E = {}（深处单侧子树）",
            contains_subtree(A, A.root, E));
    assert(contains_subtree(A, A.root, E));
    // 15 也是 A 的后代且 A 的 15 是叶子 → [15] 同样应命中
    RebuildTree leaf;
    leaf.root = leaf.make(15);
    assert(contains_subtree(A, A.root, leaf));
    println("   [15]（A 右孩子的左孩子，叶子）→ A 含它 = {}",
            contains_subtree(A, A.root, leaf));
    // 反过来：单节点 [3] 匹配不上——A 的 3 有两个孩子，而 [3] 是叶子。
    // 这是**正确**的行为：「子树」要求形状全等，不是「A 里有这个键」。
    RebuildTree self;
    self.root = self.make(3);
    assert(!contains_subtree(A, A.root, self));
    println("   [3]（键相同但 [3] 是叶子）    → A 含它 = {}（形状必须全等）",
            contains_subtree(A, A.root, self));
    // 而 A 整体当然是自己的子树：把 A 的结构原样复制一份当 A2。
    RebuildTree A2;
    const std::size_t a2_3 = A2.make(3);
    const std::size_t a2_9 = A2.make(9);
    const std::size_t a2_20 = A2.make(20);
    const std::size_t a2_15 = A2.make(15);
    const std::size_t a2_7 = A2.make(7);
    A2.root = a2_3;
    A2.left[a2_3] = a2_9;
    A2.right[a2_3] = a2_20;
    A2.left[a2_20] = a2_15;
    A2.right[a2_20] = a2_7;
    assert(contains_subtree(A, A.root, A2));     // 子树含自身
    println("   A2 = A 的完整复制             → A 含 A2 = {}（子树含自身）",
            contains_subtree(A, A.root, A2));
    // 但「少一层」的 A3 不是 A 的子树
    RebuildTree A3;
    const std::size_t a3_3 = A3.make(3);
    const std::size_t a3_9 = A3.make(9);
    const std::size_t a3_20 = A3.make(20);
    A3.root = a3_3;
    A3.left[a3_3] = a3_9;
    A3.right[a3_3] = a3_20;
    assert(!contains_subtree(A, A.root, A3));
    println("   A3 = 3→(9,20)（20 无孩子）    → A 含 A3 = {}（20 下方结构不符）",
            contains_subtree(A, A.root, A3));
    println("注：子树的根必须是 A 的某个节点（含 A 自己），从 A 的左孩子起步就不行：");
    assert(!contains_subtree(A, a9, B));            // 从 A 的左孩子起步就看不到 20
    assert(!contains_subtree(B, B.root, A));        // B 里没有键 3
    println("    A 从左孩子 9 起步含 B = {}；反向 B 含 A = {}（键 3 不在 B 里）",
            contains_subtree(A, a9, B), contains_subtree(B, B.root, A));
}

int main() {
    build_and_walk();
    search_trace();
    deletion_cases();
    random_bst_experiment();
    rebuild_demo();
    subtree_demo();
    println("自检通过");
    return 0;
}
