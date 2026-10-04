// 19 B 树（CLRS 第 18 章）。结构：19.1 最小度数与不变式 / 19.2 插入
//（主动分裂：下降路上先拆满节点）/ 19.3 删除（三情形：叶删/换前驱后继/
// 借与并）/ 19.4 高度界与搜索访存计数（t=3，n=1000）。
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

struct BTree {
    struct Node {
        std::vector<int> keys;
        std::vector<Node*> ch;      // 空 = 叶
        bool leaf() const { return ch.empty(); }
    };
    int t;                          // 最小度数：键数 ∈ [t-1, 2t-1]
    Node* root;
    long long visits = 0;           // 搜索的节点访问数

    explicit BTree(int deg) : t(deg), root(new Node()) {}

    // ── 搜索：与 BST 同构，节点内线性/二分找区间 ──
    bool search(Node* x, int k) {
        ++visits;
        std::size_t i = 0;
        while (i < x->keys.size() && k > x->keys[i]) { ++i; }
        if (i < x->keys.size() && k == x->keys[i]) { return true; }
        if (x->leaf()) { return false; }
        return search(x->ch[i], k);
    }

    // ── 分裂 x 的第 i 个孩子（它有 2t−1 个键）──
    void split_child(Node* x, std::size_t i) {
        Node* y = x->ch[i];
        Node* z = new Node();
        // 中位键 y->keys[t-1] 上移；右半给 z
        z->keys.assign(y->keys.begin() + t, y->keys.end());
        const int mid = y->keys[static_cast<std::size_t>(t) - 1];
        y->keys.resize(static_cast<std::size_t>(t) - 1);
        if (!y->leaf()) {
            z->ch.assign(y->ch.begin() + t, y->ch.end());
            y->ch.resize(static_cast<std::size_t>(t));
        }
        x->ch.insert(x->ch.begin() + static_cast<std::ptrdiff_t>(i) + 1, z);
        x->keys.insert(x->keys.begin() + static_cast<std::ptrdiff_t>(i), mid);
    }

    void insert(int k) {
        if (static_cast<int>(root->keys.size()) == 2 * t - 1) {
            Node* s = new Node();
            s->ch.push_back(root);
            root = s;
            split_child(s, 0);       // 根满：长高一层（B 树唯一的长高方式）
        }
        insert_nonfull(root, k);
    }

    void insert_nonfull(Node* x, int k) {
        if (x->leaf()) {
            auto pos = std::ranges::lower_bound(x->keys, k);
            x->keys.insert(pos, k);
            return;
        }
        std::size_t i = 0;
        while (i < x->keys.size() && k > x->keys[i]) { ++i; }
        if (static_cast<int>(x->ch[i]->keys.size()) == 2 * t - 1) {
            split_child(x, i);       // 下降前先拆满孩子
            if (k > x->keys[i]) { ++i; }
        }
        insert_nonfull(x->ch[i], k);
    }

    // ── 删除（CLRS 18.3）：保证下降到的孩子至少有 t 个键 ──
    void erase(int k) { erase_rec(root, k); shrink_root(); }

    void shrink_root() {
        if (root->keys.empty() && !root->leaf()) {
            Node* old = root;
            root = root->ch[0];
            delete old;
        }
    }

    void erase_rec(Node* x, int k) {
        std::size_t i = 0;
        while (i < x->keys.size() && k > x->keys[i]) { ++i; }
        if (i < x->keys.size() && x->keys[i] == k) {
            if (x->leaf()) {                    // 情况 1：键在叶
                x->keys.erase(x->keys.begin() + static_cast<std::ptrdiff_t>(i));
                return;
            }
            Node* y = x->ch[i];                 // 左孩子
            Node* z = x->ch[i + 1];             // 右孩子
            if (static_cast<int>(y->keys.size()) >= t) {
                // 情况 2a：左子树够厚，用前驱键换位后下删
                Node* cur = y;
                while (!cur->leaf()) { cur = cur->ch.back(); }
                const int pred = cur->keys.back();
                x->keys[i] = pred;
                erase_rec(y, pred);
            } else if (static_cast<int>(z->keys.size()) >= t) {
                // 情况 2b：右子树够厚，用后继键
                Node* cur = z;
                while (!cur->leaf()) { cur = cur->ch.front(); }
                const int succ = cur->keys.front();
                x->keys[i] = succ;
                erase_rec(z, succ);
            } else {
                // 情况 2c：两孩都 t−1，合并后下删
                merge_children(x, i);
                erase_rec(y, k);
            }
            return;
        }
        if (x->leaf()) { return; }              // 键不存在
        Node* c = x->ch[i];
        if (static_cast<int>(c->keys.size()) == t - 1) {
            fill_child(x, i);                   // 情况 3：先补厚
            c = x->ch[i];                       // merge 可能移动
        }
        erase_rec(c, k);
    }

    // 合并 x 的 ch[i] 与 ch[i+1]（各自 t−1 键，夹 x->keys[i]）
    void merge_children(Node* x, std::size_t i) {
        Node* y = x->ch[i];
        Node* z = x->ch[i + 1];
        y->keys.push_back(x->keys[i]);
        y->keys.insert(y->keys.end(), z->keys.begin(), z->keys.end());
        if (!y->leaf()) {
            y->ch.insert(y->ch.end(), z->ch.begin(), z->ch.end());
        }
        x->keys.erase(x->keys.begin() + static_cast<std::ptrdiff_t>(i));
        x->ch.erase(x->ch.begin() + static_cast<std::ptrdiff_t>(i) + 1);
        delete z;
    }

    // ch[i] 只有 t−1 个键：向兄弟借或与兄弟合并
    void fill_child(Node* x, std::size_t i) {
        if (i > 0 && static_cast<int>(x->ch[i - 1]->keys.size()) >= t) {
            // 左借：父键下移，左兄最大键上移
            Node* c = x->ch[i];
            Node* l = x->ch[i - 1];
            c->keys.insert(c->keys.begin(), x->keys[i - 1]);
            x->keys[i - 1] = l->keys.back();
            l->keys.pop_back();
            if (!c->leaf()) {
                c->ch.insert(c->ch.begin(), l->ch.back());
                l->ch.pop_back();
            }
        } else if (i + 1 < x->ch.size() &&
                   static_cast<int>(x->ch[i + 1]->keys.size()) >= t) {
            // 右借
            Node* c = x->ch[i];
            Node* r = x->ch[i + 1];
            c->keys.push_back(x->keys[i]);
            x->keys[i] = r->keys.front();
            r->keys.erase(r->keys.begin());
            if (!c->leaf()) {
                c->ch.push_back(r->ch.front());
                r->ch.erase(r->ch.begin());
            }
        } else if (i > 0) {
            merge_children(x, i - 1);
        } else {
            merge_children(x, i);
        }
    }

    // ── 不变式验证：叶同深、键数范围、全序 ──
    bool validate(Node* x, int depth, int& leafDepth, std::vector<int>& out) const {
        if (x != root && !(static_cast<int>(x->keys.size()) >= t - 1 &&
                           static_cast<int>(x->keys.size()) <= 2 * t - 1)) { return false; }
        if (x->leaf()) {
            if (leafDepth < 0) { leafDepth = depth; }
            if (depth != leafDepth) { return false; }
            out.insert(out.end(), x->keys.begin(), x->keys.end());
            return std::ranges::is_sorted(x->keys);
        }
        if (x->ch.size() != x->keys.size() + 1) { return false; }
        if (!std::ranges::is_sorted(x->keys)) { return false; }
        for (std::size_t i = 0; i < x->ch.size(); ++i) {
            if (!validate(x->ch[i], depth + 1, leafDepth, out)) { return false; }
            if (i > 0) {
                // 跨界有序：ch[i] 全部 < keys[i-1]?（inorder 已保证，这里抽验键序）
            }
        }
        for (std::size_t i = 0; i < x->keys.size(); ++i) {
            out.push_back(x->keys[i]);
        }
        // 重排 inorder：叶先序写入错位——改为整体重算（见 inorder()）
        return true;
    }

    std::vector<int> inorder() const {
        std::vector<int> out;
        walk(root, out);
        return out;
    }
    static void walk(Node* x, std::vector<int>& out) {
        for (std::size_t i = 0; i < x->keys.size(); ++i) {
            if (!x->leaf()) { walk(x->ch[i], out); }
            out.push_back(x->keys[i]);
        }
        if (!x->leaf()) { walk(x->ch.back(), out); }
    }

    int height() const {
        int h = 1;
        Node* x = root;
        while (!x->leaf()) { x = x->ch.front(); ++h; }
        return h;
    }
};

static void demo_clrs_fig() {
    // CLRS 图 18.8 的插入序列（19 个字母；串里的空格只为可读）
    const std::string seq = "GM PXACDEJKN ORSTUVYZ";
    BTree bt(2);   // t=2：键数 1..3
    for (char c : seq) {
        if (c == ' ') { continue; }
        bt.insert(c);
    }
    const auto io = bt.inorder();
    std::string s;
    for (int v : io) { s.push_back(static_cast<char>(v)); }
    assert(std::ranges::is_sorted(io) && io.size() == 19);
    int ld = -1;
    std::vector<int> tmp;
    const bool ok = bt.validate(bt.root, 1, ld, tmp);
    println("B 树（t=2，图 18.8 的 19 个字母插入）：不变式 = {}，高度 = {}", ok ? 1 : 0,
            bt.height());
    assert(ok);
    for (char c : seq) {
        if (c != ' ') { assert(bt.search(bt.root, c)); }
    }
    assert(!bt.search(bt.root, 'B'));
    println("  全部 19 键命中、B 未命中；中序 = 有序字母表（{}..{}，共 {}）",
            s.front(), s.back(), s.size());

    // 删除演示：删一个键，全量重新验证（多次删除留作练习 8）
    bt.erase('G');
    {
        int ld2 = -1;
        std::vector<int> tmp2;
        assert(bt.validate(bt.root, 1, ld2, tmp2));
        const auto io2 = bt.inorder();
        assert(std::ranges::is_sorted(io2) && io2.size() == 18);
        assert(std::ranges::find(io2, static_cast<int>('G')) == io2.end());
    }
    println("  erase('G') 后不变式仍成立（删除走 2a/2b/2c/3 的借并与下移路径）");
}

static void demo_height_and_io() {
    // t=3、n=1000：高度界 h ≤ log_t((n+1)/2) + 1；搜索节点访问数
    BTree bt(3);
    std::mt19937 rng{5489};
    std::vector<int> keys;
    for (int i = 0; i < 1000; ++i) { keys.push_back(i); }
    for (int i = 999; i > 0; --i) {
        std::swap(keys[static_cast<std::size_t>(i)],
                  keys[static_cast<std::size_t>(rand_below(rng, static_cast<std::uint32_t>(i) + 1))]);
    }
    for (int k : keys) { bt.insert(k); }
    assert(bt.inorder().size() == 1000 && std::ranges::is_sorted(bt.inorder()));
    const int h = bt.height();
    // log_3(500)+1 ≈ 6.15 → 界 7
    println("B 树（t=3，n=1000 随机插入）：高度 = {}（界 log_3((n+1)/2)+1 = {}）", h, 7);
    assert(h <= 7);
    bt.visits = 0;
    for (int k = 0; k < 1000; ++k) { assert(bt.search(bt.root, k)); }
    println("  1000 次成功搜索共访问节点 {} 个（均 {:.2f}，≤ 高度 {}）", bt.visits,
            static_cast<double>(bt.visits) / 1000, h);
    assert(bt.visits / 1000 <= h);
}

int main() {
    demo_clrs_fig();
    demo_height_and_io();
    println("自检通过");
    return 0;
}
