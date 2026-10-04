// 20 斐波那契堆（CLRS 第 19 章）。结构：20.1 可合并堆与摊还代价表 /
// 20.2 根表插入与 extract-min 的合并（consolidate）追踪 / 20.3 decrease-key
// 的剪切与级联剪切 / 20.4 摊还账本实测（实际工作 vs 摊还预算）。
// 摊还界（n 为堆大小）：INSERT/减少键 O(1)，EXTRACT-MIN O(lg n)。
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
#include <limits>
#include <random>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

struct FibHeap {
    struct Node {
        int key;
        int id = -1;             // 供调用方追踪句柄存活（账本演示用）
        int degree = 0;
        bool mark = false;
        Node* parent = nullptr;
        Node* child = nullptr;
        Node* left = nullptr;   // 环形双链（根表或兄弟表）
        Node* right = nullptr;
        explicit Node(int k) : key(k) { left = this; right = this; }
    };
    Node* min = nullptr;      // 指向根表最小
    int lastDeletedId = -1;    // 最近一次 extract-min 删除节点的 id（存值不存指针——防 use-after-free）
    long long n = 0;          // 节点数
    // 摊还账本
    long long actualWork = 0; // 所有指针操作/比较的粗略计数
    long long cuts = 0;
    long long cascadeSteps = 0;
    long long consolidateLinks = 0;

    void add_to_list(Node*& list, Node* x) const {
        if (list == nullptr) { list = x; x->left = x; x->right = x; return; }
        x->left = list->left;
        x->right = list;
        list->left->right = x;
        list->left = x;
    }
    void remove_from_list(Node* x) const {
        x->left->right = x->right;
        x->right->left = x->left;
        if (x->right == x) { /* 独节点由调用方处理 */ }
    }

    Node* insert(int k) {
        Node* x = new Node(k);
        add_to_list(min, x);
        ++actualWork;
        if (k < min->key) { min = x; }
        ++n;
        return x;
    }

    int minimum() const { return min->key; }

    // 把 x 挂为 y 的孩子
    void fib_heap_link(Node* y, Node* x) {
        remove_from_list(y);
        y->parent = x;
        y->mark = false;
        add_to_list(x->child, y);
        ++x->degree;
        ++consolidateLinks;
        ++actualWork;
    }

    int extract_min() {
        Node* z = min;
        assert(z != nullptr);
        // 孩子全部提升到根表
        if (z->child != nullptr) {
            std::vector<Node*> kids;
            Node* c = z->child;
            Node* cur = c;
            do {
                kids.push_back(cur);
                cur = cur->right;
            } while (cur != c);
            for (Node* k : kids) {
                k->parent = nullptr;
                remove_from_list(k);
                add_to_list(min, k);      // 提升到根表（z 仍在表中，随后被删）
                ++actualWork;
            }
        }
        remove_from_list(z);
        if (z == z->right && z->child == nullptr) {
            min = nullptr;                       // 堆空
        } else {
            min = z->right;
            consolidate();
        }
        const int k = z->key;
        lastDeletedId = z->id;
        delete z;
        --n;
        return k;
    }

    void consolidate() {
        const std::size_t maxD = 64;
        std::vector<Node*> A(maxD, nullptr);
        // 收集根表
        std::vector<Node*> roots;
        Node* cur = min;
        if (cur != nullptr) {
            do {
                roots.push_back(cur);
                cur = cur->right;
            } while (cur != min);
        }
        for (Node* w : roots) {
            Node* x = w;
            int d = x->degree;
            while (A[static_cast<std::size_t>(d)] != nullptr) {
                Node* y = A[static_cast<std::size_t>(d)];
                if (y->key < x->key) { std::swap(x, y); }
                fib_heap_link(y, x);
                A[static_cast<std::size_t>(d)] = nullptr;
                ++d;
            }
            A[static_cast<std::size_t>(d)] = x;
            ++actualWork;
        }
        // 重建根表与 min
        min = nullptr;
        for (Node* x : A) {
            if (x != nullptr) {
                x->left = x;
                x->right = x;
                add_to_list(min, x);
                if (x->key < min->key) { min = x; }
                ++actualWork;
            }
        }
    }

    void cut(Node* x, Node* y) {
        // 从 y 的孩子表摘下 x，提升到根表
        if (x->right == x) {
            y->child = nullptr;
        } else {
            y->child = x->right;
            remove_from_list(x);
        }
        --y->degree;
        x->parent = nullptr;
        x->mark = false;
        add_to_list(min, x);
        ++cuts;
        ++actualWork;
    }

    // 级联剪切（CLRS CASCADING-CUT 的循环版）：y 已失一个孩子；
    // 若 y 未标记则标记止损；否则把 y 也剪上根表，继续处理其父。
    void cascading_cut(Node* y) {
        Node* z = y->parent;
        while (z != nullptr) {
            if (!y->mark) {
                y->mark = true;
                ++actualWork;
                return;
            }
            Node* zParent = z->parent;   // cut 之后 z 的 parent 可能变，先记下
            cut(y, z);
            ++cascadeSteps;
            y = z;
            z = zParent;
        }
    }

    bool decrease_key(Node* x, int k) {
        assert(k <= x->key);
        x->key = k;
        Node* y = x->parent;
        if (y != nullptr && x->key < y->key) {
            cut(x, y);
            cascading_cut(y);
        }
        if (x->key < min->key) { min = x; }
        ++actualWork;
        return true;
    }
};

static void fib_basics_demo() {
    FibHeap h;
    std::vector<FibHeap::Node*> handle;
    // 图 19.4? 用 CLRS 23? 20.1 简单演示：插入 7 个键后 extract-min 顺序
    for (int k : {23, 7, 3, 18, 52, 38, 39}) { handle.push_back(h.insert(k)); }
    println("斐波那契堆基础（插入 23 7 3 18 52 38 39）：min = {}", h.minimum());
    assert(h.minimum() == 3);
    h.decrease_key(handle[4], 2);       // 52 → 2
    assert(h.minimum() == 2);
    println("decrease-key(52→2) 后 min = {}（新键上浮到根表）", h.minimum());
    int prev = std::numeric_limits<int>::min();
    print("连续 extract-min 弹出序: ");
    while (h.n > 0) {
        const int v = h.extract_min();
        print("{} ", v);
        assert(v >= prev);
        prev = v;
    }
    println("（升序确认）");
}

// 摊还账本实测：交错操作让 cut/cascading-cut 真正发生——
// 先插满，提取 1/4（强制 consolidate 长出树），再对混在树里的节点降键，
// 最后分两波清空。
static void amortized_ledger_demo() {
    FibHeap h;
    std::mt19937 rng{5489};
    const int m = 4000;
    std::vector<FibHeap::Node*> handles;
    std::vector<char> alive(static_cast<std::size_t>(m), 1);
    for (int i = 0; i < m; ++i) {
        FibHeap::Node* x = h.insert(static_cast<int>(rand_below(rng, 1u << 30)));
        x->id = i;
        handles.push_back(x);
    }
    for (int i = 0; i < m / 4; ++i) {                     // 长出树结构
        h.extract_min();
        alive[static_cast<std::size_t>(h.lastDeletedId)] = 0;
    }
    long long dkCount = 0;
    for (int round = 0; round < 3; ++round) {
        for (int i = 0; i < m; i += 2) {
            FibHeap::Node* x = handles[static_cast<std::size_t>(i)];
            if (!alive[static_cast<std::size_t>(i)] || x->key < (1 << 20)) { continue; }
            // 大幅降键：新值降到 2^20 以下，几乎必然小于任何父键 → 触发 cut；
            // 同一父亲的多个孩子接连被剪 → 触发 cascading-cut
            const int nk = static_cast<int>(rand_below(rng, 1u << 20));
            if (nk >= x->key) { continue; }
            h.decrease_key(x, nk);
            ++dkCount;
        }
        for (int i = 0; i < m / 8; ++i) {                  // 再提取一批，逼出更多级联
            h.extract_min();
            alive[static_cast<std::size_t>(h.lastDeletedId)] = 0;
        }
    }
    while (h.n > 0) {
        h.extract_min();
        alive[static_cast<std::size_t>(h.lastDeletedId)] = 0;
    }

    const long long work = h.actualWork;
    const long long budget = static_cast<long long>(m) + dkCount     // 插入/降键摊还 O(1)
        + static_cast<long long>(m) * 20;                            // extract 共 ~m 次，摊还 O(lg n)
    // 摊还的 O(1) 是「至多常数次指针操作」——每根指针拨动都计 1 时，
    // 合理的实现常数约 2~4；预算放 5 倍仍属摊还意义的 O(·)
    println("摊还账本（m={}：{} 插 + 交错 {} 次降键与提取后清空）：", m, m, dkCount);
    println("  实际工作计数 = {}，摊还预算×实现常数5 = {}（比值 {:.3f}）",
            work, 5 * budget, static_cast<double>(work) / static_cast<double>(budget));
    assert(work <= 5 * budget);
    println("  cut 次数 = {}，级联剪切步数 = {}（平均 {:.2f} 步/降键——摊还后仍 O(1)）",
            h.cuts, h.cascadeSteps,
            static_cast<double>(h.cascadeSteps) / static_cast<double>(dkCount));
    assert(h.cascadeSteps > 0);
    println("  合并链接次数 = {}（集中在 extract-min：{:.2f} 次/取 ≈ lg n 量级）",
            h.consolidateLinks,
            static_cast<double>(h.consolidateLinks) / static_cast<double>(m));
}

int main() {
    fib_basics_demo();
    amortized_ledger_demo();
    println("自检通过");
    return 0;
}
