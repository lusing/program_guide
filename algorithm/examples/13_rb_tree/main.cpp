// 13 红黑树（CLRS 第 13 章）。结构：13.1 性质与验证器 / 13.2 旋转与哨兵 /
// 13.3 插入修复（图 13.4 序列）/ 13.4 删除修复 / 13.5 有序输入的 RB vs BST
// 高度对照 / 13.6 随机操作压力对账。
// 实现要点：用 CLRS 原书的「真实哨兵节点」方案——nil 槽位有真实的
// color/parent 字段并随旋转/移植更新，删除修复才能与伪代码逐行对应。
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

constexpr std::size_t NIL = 0; // 槽位 0 是哨兵：真实节点从 1 起

enum Color : std::uint8_t { RED, BLACK };

struct RbTree {
    std::vector<int> key;
    std::vector<std::size_t> left, right, parent;
    std::vector<Color> color;
    std::size_t root = NIL;

    RbTree() {
        key.assign(1, 0);                 // 哨兵槽
        left.assign(1, NIL);
        right.assign(1, NIL);
        parent.assign(1, NIL);
        color.assign(1, BLACK);           // 性质 3：nil 是黑的
    }

    std::size_t alloc(int k, Color c, std::size_t p) {
        key.push_back(k);
        left.push_back(NIL);
        right.push_back(NIL);
        parent.push_back(p);
        color.push_back(c);
        return key.size() - 1;
    }

    // ── 旋转（哨兵方案：parent 赋值无需判空——写进哨兵恰好是它要的语义）──
    void rotate_left(std::size_t x) {
        const std::size_t y = right[x];
        right[x] = left[y];
        parent[left[y]] = x;                       // 含哨兵也无妨
        parent[y] = parent[x];
        if (parent[x] == NIL)            { root = y; }
        else if (x == left[parent[x]])   { left[parent[x]] = y; }
        else                             { right[parent[x]] = y; }
        left[y] = x;
        parent[x] = y;
    }

    void rotate_right(std::size_t x) {
        const std::size_t y = left[x];
        left[x] = right[y];
        parent[right[y]] = x;
        parent[y] = parent[x];
        if (parent[x] == NIL)            { root = y; }
        else if (x == left[parent[x]])   { left[parent[x]] = y; }
        else                             { right[parent[x]] = y; }
        right[y] = x;
        parent[x] = y;
    }

    void insert(int k) {
        std::size_t y = NIL, x = root;
        while (x != NIL) {
            y = x;
            x = (k < key[x]) ? left[x] : right[x];
        }
        const std::size_t z = alloc(k, RED, y);
        if (y == NIL)        { root = z; }
        else if (k < key[y]) { left[y] = z; }
        else                 { right[y] = z; }
        insert_fixup(z);
    }

    // 插入修复三情况（z 红且父红时循环）：
    // 1 叔红：父/叔变黑、祖变红，问题上推
    // 2 叔黑且 z 是内侧孩子：旋成情况 3
    // 3 叔黑且 z 是外侧孩子：两次旋转内联解决
    void insert_fixup(std::size_t z) {
        while (color[parent[z]] == RED) {
            const std::size_t p = parent[z], g = parent[p];
            if (p == left[g]) {
                const std::size_t u = right[g];
                if (color[u] == RED) {
                    color[p] = BLACK; color[u] = BLACK; color[g] = RED;
                    z = g;
                } else {
                    if (z == right[p]) { rotate_left(p); z = p; }
                    color[parent[z]] = BLACK;
                    color[parent[parent[z]]] = RED;
                    rotate_right(parent[parent[z]]);
                }
            } else {
                const std::size_t u = left[g];
                if (color[u] == RED) {
                    color[p] = BLACK; color[u] = BLACK; color[g] = RED;
                    z = g;
                } else {
                    if (z == left[p]) { rotate_right(p); z = p; }
                    color[parent[z]] = BLACK;
                    color[parent[parent[z]]] = RED;
                    rotate_left(parent[parent[z]]);
                }
            }
        }
        color[root] = BLACK;
    }

    void transplant(std::size_t u, std::size_t v) {
        if (parent[u] == NIL)          { root = v; }
        else if (u == left[parent[u]]) { left[parent[u]] = v; }
        else                           { right[parent[u]] = v; }
        parent[v] = parent[u];         // v 可以是哨兵——它的 parent 就该被更新
    }

    std::size_t minimum(std::size_t x) const {
        while (left[x] != NIL) { x = left[x]; }
        return x;
    }

    void erase(int k) {
        const std::size_t z = search(k);
        assert(z != NIL);
        std::size_t y = z;
        Color yOrig = color[y];
        std::size_t x = NIL;
        if (left[z] == NIL) {
            x = right[z];
            transplant(z, right[z]);
        } else if (right[z] == NIL) {
            x = left[z];
            transplant(z, left[z]);
        } else {
            y = minimum(right[z]);
            yOrig = color[y];
            x = right[y];
            if (parent[y] != z) {
                transplant(y, right[y]);
                right[y] = right[z];
                parent[right[y]] = y;
            } else {
                parent[x] = y;   // CLRS 的 x.p = y——专为哨兵而设：删除修复要沿它上行
            }
            transplant(z, y);
            left[y] = left[z];
            parent[left[z]] = y;
            color[y] = color[z];
        }
        if (yOrig == BLACK) { delete_fixup(x); }
    }

    // 删除修复四情况（x「黑重不足」，可能是哨兵）：
    // 1 兄弟红：转成兄弟黑再继续
    // 2 兄弟黑且双侄全黑：兄变红，黑重不足上推到父
    // 3 兄弟黑、远侄黑、近侄红：旋成情况 4
    // 4 兄弟黑、远侄红：一次旋转终结
    void delete_fixup(std::size_t x) {
        while (x != root && color[x] == BLACK) {
            const std::size_t p = parent[x];
            if (x == left[p]) {
                std::size_t w = right[p];
                if (color[w] == RED) {
                    color[w] = BLACK; color[p] = RED;
                    rotate_left(p);
                    w = right[p];
                }
                if (color[left[w]] == BLACK && color[right[w]] == BLACK) {
                    color[w] = RED;
                    x = p;
                } else {
                    if (color[right[w]] == BLACK) {
                        color[left[w]] = BLACK;
                        color[w] = RED;
                        rotate_right(w);
                        w = right[p];
                    }
                    color[w] = color[p];
                    color[p] = BLACK;
                    color[right[w]] = BLACK;
                    rotate_left(p);
                    x = root;
                }
            } else {
                std::size_t w = left[p];
                if (color[w] == RED) {
                    color[w] = BLACK; color[p] = RED;
                    rotate_right(p);
                    w = left[p];
                }
                if (color[left[w]] == BLACK && color[right[w]] == BLACK) {
                    color[w] = RED;
                    x = p;
                } else {
                    if (color[left[w]] == BLACK) {
                        color[right[w]] = BLACK;
                        color[w] = RED;
                        rotate_left(w);
                        w = left[p];
                    }
                    color[w] = color[p];
                    color[p] = BLACK;
                    color[left[w]] = BLACK;
                    rotate_right(p);
                    x = root;
                }
            }
        }
        color[x] = BLACK;
    }

    std::size_t search(int k) const {
        std::size_t x = root;
        while (x != NIL && key[x] != k) { x = (k < key[x]) ? left[x] : right[x]; }
        return x;
    }

    // ── 验证器：BST 序 + 四条红黑性质 ──
    // 返回子树黑高（-1 表示违法），size 通过引用累计
    long long check(std::size_t x, std::size_t& cnt) const {
        if (x == NIL) { return 1; }                        // 哨兵贡献 1 黑
        ++cnt;
        if (color[x] == RED &&
            (color[left[x]] == RED || color[right[x]] == RED)) { return -1; }
        const long long lh = check(left[x], cnt);
        const long long rh = check(right[x], cnt);
        if (lh < 0 || rh < 0 || lh != rh) { return -1; }
        if (left[x] != NIL && key[left[x]] >= key[x]) { return -1; }
        if (right[x] != NIL && key[right[x]] <= key[x]) { return -1; }
        return lh + (color[x] == BLACK ? 1 : 0);
    }

    bool valid() const {
        if (root == NIL) { return true; }
        if (color[root] != BLACK) { return false; }
        std::size_t cnt = 0;
        return check(root, cnt) > 0;
    }

    std::size_t height(std::size_t x) const {
        if (x == NIL) { return 0; }
        return 1 + std::max(height(left[x]), height(right[x]));
    }

    std::vector<int> inorder(std::size_t x, std::vector<int>& out) const {
        if (x != NIL) {
            inorder(left[x], out);
            out.push_back(key[x]);
            inorder(right[x], out);
        }
        return out;
    }
    std::vector<int> inorder() const {
        std::vector<int> out;
        return inorder(root, out);
    }
};

static void print_level(const RbTree& t, const std::string& title) {
    println("{}:", title);
    std::vector<std::size_t> cur{t.root};
    while (!cur.empty()) {
        std::vector<std::size_t> nxt;
        print("  ");
        for (std::size_t n : cur) {
            print("{}{} ", t.key[n], t.color[n] == RED ? "R" : "B");
            if (t.left[n] != NIL) { nxt.push_back(t.left[n]); }
            if (t.right[n] != NIL) { nxt.push_back(t.right[n]); }
        }
        println("");
        cur = nxt;
    }
}

static void insert_trace_demo() {
    RbTree t;
    for (int k : {41, 38, 31, 12, 19, 8}) { // CLRS 图 13.4 的序列
        t.insert(k);
        assert(t.valid());
    }
    print_level(t, "插入 41 38 31 12 19 8（图 13.4 序列）后的红黑树（key+颜色）");
    const auto io = t.inorder();
    assert((io == std::vector<int>{8, 12, 19, 31, 38, 41}));
    println("黑高一致/BST 序断言通过；树高 = {}（界 2·lg(n+1) = {}）",
            t.height(t.root), 2 * 3);
    assert(t.height(t.root) <= 2 * 3);
}

static void delete_demo() {
    RbTree t;
    for (int k : {41, 38, 31, 12, 19, 8, 55, 60}) { t.insert(k); }
    assert(t.valid());
    println("删除演示（每次删除后全量验证四条性质与中序）：");
    for (int k : {8, 41, 19, 55}) {
        t.erase(k);
        assert(t.valid());
        const auto io = t.inorder();
        assert(std::ranges::find(io, k) == io.end());
        assert(std::ranges::is_sorted(io));
        println("  删 {} 后：中序仍有序、黑高一致（OK）", k);
    }
    assert((t.inorder() == std::vector<int>{12, 31, 38, 60}));
}

static void height_comparison() {
    const int n = 255;
    RbTree rb;
    for (int i = 1; i <= n; ++i) { rb.insert(i); }
    assert(rb.valid());
    println("有序插入 1..{}：红黑树高 = {}（界 2·lg(n+1) = {}），朴素 BST 高 = {}（退化链）",
            n, rb.height(rb.root), 2 * 8, n);
    assert(rb.height(rb.root) <= 2 * 8);
    assert(rb.inorder().size() == static_cast<std::size_t>(n));
}

static void stress_test() {
    RbTree t;
    std::mt19937 rng{5489};
    const int m = 2000;
    std::vector<char> present(static_cast<std::size_t>(m) + 1, 0);
    for (int op = 0; op < 20000; ++op) {
        const int k = static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(m))) + 1;
        const std::uint32_t act = rand_below(rng, 3);
        if (act == 0) {
            if (!present[static_cast<std::size_t>(k)]) {
                t.insert(k);
                present[static_cast<std::size_t>(k)] = 1;
            }
        } else if (act == 1) {
            if (t.search(k) != NIL) {
                t.erase(k);
                present[static_cast<std::size_t>(k)] = 0;
            }
        } else {
            assert((t.search(k) != NIL) == (present[static_cast<std::size_t>(k)] != 0));
        }
        if (op % 1000 == 0) { assert(t.valid()); }
    }
    assert(t.valid());
    std::vector<int> expect;
    for (int k = 1; k <= m; ++k) {
        if (present[static_cast<std::size_t>(k)]) { expect.push_back(k); }
    }
    assert(t.inorder() == expect);
    println("压力测试：20000 次随机插入/删除/查找（固定种子，键域 1..2000）");
    println("  每 1000 步全量验证四条性质；终态 {} 个键与真值集合逐元素一致 = 1",
            expect.size());
}

int main() {
    insert_trace_demo();
    delete_demo();
    height_comparison();
    stress_test();
    println("自检通过");
    return 0;
}
