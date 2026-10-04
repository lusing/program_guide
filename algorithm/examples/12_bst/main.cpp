// 12 二叉搜索树（CLRS 第 12 章）。结构：12.1 建树与遍历（图 12.1 的树）/
// 12.2 搜索路径追踪 / 12.3 三种删除案例 / 12.4 中序后继链 /
// 12.5 随机构建 BST 的高度与平均深度实验（定理 12.4）。
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

int main() {
    build_and_walk();
    search_trace();
    deletion_cases();
    random_bst_experiment();
    println("自检通过");
    return 0;
}
