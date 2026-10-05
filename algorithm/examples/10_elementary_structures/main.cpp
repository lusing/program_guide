// 10 基本数据结构（CLRS 第 10 章）。结构：10.1 数组栈 + 循环队列 /
// 10.2 哨兵双链表 / 10.3 对象数组 + 自由表（CLRS 的三数组表示）/
// 10.4 有根树的两种数组表示与遍历 /
// 10.5 单链表上的经典算法（反转·倒数第 k·原地删除·归并·逆向输出）/
// 10.6 用两个栈实现队列（摊还 O(1)）与镜像的「两队列实现栈」/
// 10.7 数组上的经典问题（二维有序矩阵查找·原地替换空格）/
// 10.10 占用数组：花园种花（下标即坑号的集合表示 + 等差数列）/
// 10.11 RPN 求值与终态周期序列（首次出现表 vs Floyd 判圈）。
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
#include <cassert>
#include <cmath>
#include <cstdint>
#include <queue>
#include <random>
#include <stack>
#include <string>
#include <vector>

// 可移植随机（docs/01 的纪律：不用 uniform_int_distribution）
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 10.1 数组栈与循环队列 ═══
// 栈：S.top 指向栈顶（0 基：top = 元素个数）。下溢/上溢都用 assert 拦。
struct ArrayStack {
    std::vector<int> data;
    bool empty() const { return data.empty(); }
    void push(int x) { data.push_back(x); }
    int pop() {
        assert(!empty() && "underflow");
        const int x = data.back();
        data.pop_back();
        return x;
    }
};

// 循环队列（CLRS 图 10.2/10.3）：head 指向队头，tail 指向下一空位。
// 满/空的区分：留一个空位（size = capacity − 1 可用），或像 CLRS 用
// 计数器——这里用计数器版，逻辑更直白。
struct CircularQueue {
    std::vector<int> slot;
    std::size_t head = 0, tail = 0, count = 0;
    explicit CircularQueue(std::size_t cap) : slot(cap, 0) {}
    bool empty() const { return count == 0; }
    bool full() const { return count == slot.size(); }
    void enqueue(int x) {
        assert(!full());
        slot[tail] = x;
        tail = (tail + 1) % slot.size();
        ++count;
    }
    int dequeue() {
        assert(!empty());
        const int x = slot[head];
        head = (head + 1) % slot.size();
        --count;
        return x;
    }
};

static void stack_queue_demo() {
    ArrayStack s;
    for (int x : {1, 2, 3}) { s.push(x); }
    // 注意：不要把两次 pop() 写进同一个 println 的实参——实参求值顺序
    // 未指定（MSVC 实测从右往左），输出会反序（见本章坑位清单第 1 条）
    const int p2 = s.pop();
    const int p1 = s.pop();
    println("栈：push 1 2 3 后弹出 {} {}（LIFO）", p2, p1);
    assert(p2 == 3 && p1 == 2 && s.pop() == 1 && s.empty());

    CircularQueue q(4);
    for (int x : {4, 9, 16}) { q.enqueue(x); }
    const int d1 = q.dequeue();
    println("循环队列（容量 4）：enqueue 4 9 16 → dequeue {}，head={}/tail={}",
            d1, q.head, q.tail);
    q.enqueue(25);
    q.enqueue(36); // tail 环绕回 0
    const int d2 = q.dequeue(), d3 = q.dequeue(), d4 = q.dequeue(), d5 = q.dequeue();
    println("  再 enqueue 25 36（tail 环绕到 0）→ 依次出队：{} {} {} {}",
            d2, d3, d4, d5);
    assert((std::vector<int>{d1, d2, d3, d4, d5} ==
            std::vector<int>{4, 9, 16, 25, 36}));
    assert(q.empty());
}

// ═══ 10.2 哨兵双链表 ═══
// CLRS 10.2 的哨兵 nil.next 是头、nil.prev 是尾——空判断统一成
// 「是否等于 nil」，删掉所有分支。0 基 C++ 版用 index=-1 表示哨兵。
// 用「对象数组 + 下标当指针」实现（见 10.3），一举两得。
constexpr std::size_t NIL = SIZE_MAX;

struct ListEngine {
    std::vector<int> key;
    std::vector<std::size_t> next, prev;
    std::size_t nil; // 哨兵下标
    std::size_t freeHead; // 自由表头（10.3 节）

    explicit ListEngine(std::size_t cap)
        : key(cap + 1, 0), next(cap + 1, NIL), prev(cap + 1, NIL),
          nil(cap), freeHead(0) {
        // 自由表：0..cap-1 串成单链；哨兵在 cap，自环
        for (std::size_t i = 0; i + 1 < cap; ++i) { next[i] = i + 1; }
        next[cap - 1] = NIL;
        next[nil] = nil;
        prev[nil] = nil;
    }

    std::size_t allocate_object() {
        assert(freeHead != NIL && "out of space");
        const std::size_t x = freeHead;
        freeHead = next[x];
        return x;
    }

    void free_object(std::size_t x) {
        next[x] = freeHead;
        freeHead = x;
    }

    void list_insert(std::size_t x) { // 插到链头
        next[x] = next[nil];
        prev[next[nil]] = x;
        next[nil] = x;
        prev[x] = nil;
    }

    void list_delete(std::size_t x) {
        next[prev[x]] = next[x];
        prev[next[x]] = prev[x];
    }

    std::size_t list_search(int k) const {
        std::size_t x = next[nil];
        while (x != nil && key[x] != k) { x = next[x]; }
        return x; // nil = 没找到
    }

    std::vector<int> to_vector() const {
        std::vector<int> out;
        std::size_t x = next[nil];
        while (x != nil) { out.push_back(key[x]); x = next[x]; }
        return out;
    }
};

static void linked_list_demo() {
    ListEngine e(8);
    const auto a = e.allocate_object(); e.key[a] = 9;  e.list_insert(a);
    const auto b = e.allocate_object(); e.key[b] = 16; e.list_insert(b);
    const auto c = e.allocate_object(); e.key[c] = 4;  e.list_insert(c);
    const auto v = e.to_vector();
    println("哨兵双链表：insert 9,16,4（头插）→ 遍历:");
    print("  ");
    for (int x : v) { print("{} ", x); }
    println("");
    assert((v == std::vector<int>{4, 16, 9}));
    // O(1) 删除：给节点下标即可
    e.list_delete(b);
    e.free_object(b);
    println("  delete(16)（O(1)——给下标即删）→ 遍历: 4 9（search(16) 返回哨兵）");
    assert(e.list_search(16) == e.nil);
    assert(e.list_search(9) == a);
    // 回收后再分配：自由表复用槽位
    const auto d = e.allocate_object();
    assert(d == b); // LIFO 的自由表：刚释放的槽位最先复用
    e.key[d] = 25;
    e.list_insert(d);
    println("  free_object(16) 后再 allocate → 复用槽 {}，insert 25 → 遍历: 25 4 9",
            d);
    assert((e.to_vector() == std::vector<int>{25, 4, 9}));
}

// ═══ 10.4 有根树：两种数组表示 ═══
// (a) 二叉树：left/right/parent 三数组（CLRS 图 10.9）
// (b) 任意分支树：first_child / next_sibling 两数组（左孩子右兄弟）
struct BinaryTreeRep {
    std::vector<int> key;
    std::vector<std::ptrdiff_t> left, right; // −1 表示空
    std::size_t root = 0;

    explicit BinaryTreeRep(std::vector<int> keys,
                           std::vector<std::ptrdiff_t> l,
                           std::vector<std::ptrdiff_t> r)
        : key(std::move(keys)), left(std::move(l)), right(std::move(r)) {}
};

static void tree_demo() {
    // 手工搭一棵（注释里行尾不能是反斜杠——会触发续行告警 -Wcomment）：
    //        A(0)
    //       /    ‖
    //    B(1)    C(2)
    //    / ‖       ‖
    // D(3) E(4)    F(5)
    BinaryTreeRep t(
        {1, 2, 3, 4, 5, 6},
        {1, 3, -1, -1, -1, -1},
        {2, 4, 5, -1, -1, -1});

    // 中序遍历（递归）——BST 的中序是有序列表（第 12 章的主角）
    std::vector<int> order;
    auto inorder = [&](this auto&& self, std::ptrdiff_t i) -> void {
        if (i == -1) { return; }
        self(t.left[static_cast<std::size_t>(i)]);
        order.push_back(t.key[static_cast<std::size_t>(i)]);
        self(t.right[static_cast<std::size_t>(i)]);
    };
    inorder(static_cast<std::ptrdiff_t>(t.root));
    print("二叉树（数组三件套）中序遍历: ");
    for (int x : order) { print("{} ", x); }
    println("");
    assert((order == std::vector<int>{4, 2, 5, 1, 3, 6}));

    // 先序遍历（显式栈——10.4 之外加餐：递归消除的标准姿势）
    std::vector<int> pre;
    std::vector<std::ptrdiff_t> stk{static_cast<std::ptrdiff_t>(t.root)};
    while (!stk.empty()) {
        const auto i = stk.back();
        stk.pop_back();
        if (i == -1) { continue; }
        pre.push_back(t.key[static_cast<std::size_t>(i)]);
        stk.push_back(t.right[static_cast<std::size_t>(i)]);
        stk.push_back(t.left[static_cast<std::size_t>(i)]);
    }
    print("先序遍历（显式栈）: ");
    for (int x : pre) { print("{} ", x); }
    println("");
    assert((pre == std::vector<int>{1, 2, 4, 5, 3, 6}));

    // 左孩子右兄弟：同一棵树的两数组表示
    std::vector<std::ptrdiff_t> fc{1, 3, -1, -1, -1, -1}; // first-child
    std::vector<std::ptrdiff_t> ns{-1, 2, -1, 4, -1, 5};  // next-sibling
    // 修正：C(2) 的孩子是 F(5)；E(4) 的兄弟…按图：D(3)、E(4) 是 B(1) 的孩子
    fc[2] = 5; // C 的孩子 F
    // D 的 next-sibling 是 E(4)；F 无兄弟
    ns[3] = 4;
    ns[5] = -1;
    // 深度优先遍历（左孩子右兄弟版）
    std::vector<int> dfs;
    auto walk = [&](this auto&& self, std::ptrdiff_t i) -> void {
        for (std::ptrdiff_t c = fc[static_cast<std::size_t>(i)]; c != -1;
             c = ns[static_cast<std::size_t>(c)]) {
            dfs.push_back(t.key[static_cast<std::size_t>(c)]);
            self(c);
        }
    };
    dfs.push_back(1);
    walk(0);
    print("左孩子右兄弟表示的 DFS: ");
    for (int x : dfs) { print("{} ", x); }
    println("");
    assert((dfs == std::vector<int>{1, 2, 4, 5, 3, 6}));
}

// ═══ 10.5 单链表上的经典算法 ═══
// 承接 10.3 的「下标当指针」纪律：链表结点用 key[]/next[] 两个平行数组表示，
// NIL 表尾。这样既能写真·指针的算法，又不必手写 delete。
// 本节五个算法覆盖链表的三种基本手法：
//   ① 前后指针（反转：prev/cur/next 三件套）
//   ② 快慢指针（倒数第 k：走 n−k 步与走 k 步的差距）
//   ③ 替身删除（拿不到前驱时，覆盖后继的值再删后继）
//   ④ 归并（CLRS 的 MERGE 搬到链表上，仍是 Θ(n)）
struct SinglyList {
    std::vector<int> key;
    std::vector<std::size_t> next;
    std::size_t head = NIL;

    std::size_t push_back(int v) {
        const std::size_t x = key.size();
        key.push_back(v);
        next.push_back(NIL);
        if (head == NIL) {
            head = x;
        } else {
            std::size_t t = head;
            while (next[t] != NIL) { t = next[t]; }
            next[t] = x;
        }
        return x;
    }
    std::vector<int> to_vector() const {
        std::vector<int> out;
        for (std::size_t x = head; x != NIL; x = next[x]) { out.push_back(key[x]); }
        return out;
    }
};

// ① 反转链表：prev/cur/next 三件套。保存 next 是为了能立刻把 prev 接上。
static void reverse_list(SinglyList& L) {
    std::size_t prev = NIL;
    std::size_t cur = L.head;
    while (cur != NIL) {
        const std::size_t nxt = L.next[cur];   // 先记下后继
        L.next[cur] = prev;                    // 反转这一根
        prev = cur;
        cur = nxt;
    }
    L.head = prev;                             // 原来的尾成了新头
}

// ② 倒数第 k 个结点：双指针相隔 k 步，尾结点与「走 k 步」者同时停。
// 前提 k ≥ 1 且 k ≤ 结点总数；否则无解（返回 NIL）——先问清 k 的合法范围
// 是这类题真正的考点。
static std::size_t kth_from_end(const SinglyList& L, std::size_t k,
                                std::size_t& steps) {
    steps = 0;
    if (k == 0) { return NIL; }
    std::size_t fast = L.head;
    std::size_t slow = L.head;
    for (std::size_t i = 0; i + 1 < k; ++i) {  // fast 先走 k−1 步
        if (fast == NIL) { return NIL; }
        fast = L.next[fast];
    }
    if (fast == NIL) { return NIL; }
    while (L.next[fast] != NIL) {
        fast = L.next[fast];
        slow = L.next[slow];
        ++steps;
    }
    return slow;
}

// ③ 替身删除：题目只给「待删结点」而不给前驱时，无法改动前驱的 next，
// 于是把后继的值搬过来覆盖自己，再把后继摘掉——O(1) 且不需要前驱。
// 必须说出口的假设：待删结点**不是尾结点**（尾结点没有后继可搬）。
static void delete_without_predecessor(SinglyList& L, std::size_t x,
                                       bool& used_substitute) {
    if (L.next[x] != NIL) {                    // 有后继：替身删除
        const std::size_t nxt = L.next[x];
        L.key[x] = L.key[nxt];
        L.next[x] = L.next[nxt];
        L.next[nxt] = NIL;                     // 逻辑摘除（数组是静态的，无需真删）
        used_substitute = true;
        return;
    }
    used_substitute = false;                    // 尾结点：没有替身，只能退化 O(n)
    std::size_t p = L.head;
    while (L.next[p] != NIL && L.next[p] != x) { p = L.next[p]; }
    L.next[p] = NIL;
}

// ④ 归并两个有序链表：CLRS §2.3 的 MERGE 换成「下标」版本。
//
// 坑点（本章新增，实测翻车过）：归并若直接改 next，会撞上**下标空间**问题。
// 两个独立 SinglyList 的下标都从 0 开始，`a.next[i]` 无法表达「指向 b 的
// 第 j 个结点」——顺序序列里混着两套下标，重接时必然串链。两条出路：
//   (a) 归并到一个**共享节点池**（下面的 merge_in_place）：下标全局唯一，
//       可以只改 next、不复制结点，这才是真正的原地归并；
//   (b) 输出到新表（merge_by_value）：每个元素 push_back 一次，O(n) 空间，
//       但代码短、不可能出错——链表原地省下的空间和它带来的心智负担是同价码。
struct NodePool {
    std::vector<int> key;
    std::vector<std::size_t> next;
    std::size_t head = NIL;
    std::size_t append(int v, std::size_t after) {   // after == NIL 表示建新链
        const std::size_t x = key.size();
        key.push_back(v);
        next.push_back(NIL);
        if (after != NIL) {
            next[after] = x;
        } else {
            head = x;            // 链头由第一个 append 确定
        }
        return x;
    }
    std::vector<int> to_vector() const {
        std::vector<int> out;
        for (std::size_t x = head; x != NIL; x = next[x]) { out.push_back(key[x]); }
        return out;
    }
};

// (a) 原地归并：a、b 已躺在同一个池子里（各自是一条有序链）。
//     做法是「先算出归并后的下标序列，再一次性重接 next」——下标全局唯一，
//     所以重接不会串链。归并顺序与 MERGE 伪代码完全一致。
static std::size_t merge_in_place(NodePool& pool, std::size_t a,
                                  std::size_t b) {
    std::vector<std::size_t> order;             // 归并后的下标序列
    std::size_t x = a;
    std::size_t y = b;
    while (x != NIL && y != NIL) {
        if (pool.key[x] <= pool.key[y]) { order.push_back(x); x = pool.next[x]; }
        else { order.push_back(y); y = pool.next[y]; }
    }
    while (x != NIL) { order.push_back(x); x = pool.next[x]; }   // 鲁棒性：一边先空
    while (y != NIL) { order.push_back(y); y = pool.next[y]; }   // 鲁棒性：另一边也不空
    for (std::size_t i = 0; i + 1 < order.size(); ++i) {
        pool.next[order[i]] = order[i + 1];
    }
    if (order.empty()) { return NIL; }           // 两侧皆空
    pool.next[order.back()] = NIL;               // 关键：收尾，否则残留 next 成环
    return order.front();
}

// (b) 归并到新表：每元素一次 append，代价 O(n) 空间但绝不串链。
static NodePool merge_by_value(const NodePool& a, const NodePool& b) {
    NodePool out;
    std::size_t tail = NIL;                      // 已建链的最后一个结点
    const auto emit = [&](const NodePool& src, std::size_t node) {
        tail = out.append(src.key[node], tail);
    };
    std::size_t x = a.head;
    std::size_t y = b.head;
    while (x != NIL && y != NIL) {
        if (a.key[x] <= a.key[y]) { emit(a, x); x = a.next[x]; }
        else { emit(b, y); y = b.next[y]; }
    }
    const NodePool& rest = (x != NIL) ? a : b;  // 鲁棒性：把余下的接上
    std::size_t r = (x != NIL) ? x : y;         // 关键：是**剩余指针**，不是 rest.head
    while (r != NIL) { emit(rest, r); r = rest.next[r]; }
    return out;
}

// ⑤ 逆向输出：显式栈版鲁棒（栈在堆上，长度无所谓），递归版代码短但
// 吃调用栈——用实测深度把「短」的代价量化出来。
static std::string reverse_output_by_stack(const SinglyList& L) {
    std::stack<int> stk;
    for (std::size_t x = L.head; x != NIL; x = L.next[x]) { stk.push(L.key[x]); }
    std::string out;
    while (!stk.empty()) {
        out += std::to_string(stk.top());
        stk.pop();
        if (!stk.empty()) { out += ' '; }
    }
    return out;
}

static long long reverse_output_recursive(const SinglyList& L, std::string& out,
                                          long long depth, long long limit) {
    if (L.head == NIL) { return depth; }
    if (depth >= limit) { return depth; }       // 深度闸门：防止长链爆栈
    ++depth;
    SinglyList rest;
    // 构造去掉头结点的「视图」：直接用下标推进，不复制数据
    rest.head = L.next[L.head];
    rest.key = L.key;
    rest.next = L.next;
    depth = reverse_output_recursive(rest, out, depth, limit);
    if (!out.empty()) { out += ' '; }
    out += std::to_string(L.key[L.head]);
    return depth;
}

static std::string show(const std::vector<int>& v) {
    std::string s;
    for (std::size_t i = 0; i < v.size(); ++i) {
        if (i != 0) { s += ' '; }
        s += std::to_string(v[i]);
    }
    return s;
}

static void singly_list_demo() {
    println("");
    println("=== 10.5 单链表上的经典算法 ===");
    SinglyList L;
    for (int v : {1, 2, 3, 4, 5}) { L.push_back(v); }
    println("原链表 {}", show(L.to_vector()));

    // ① 反转
    SinglyList R = L;
    reverse_list(R);
    println("① 反转：{} → {}", show(L.to_vector()), show(R.to_vector()));
    assert((R.to_vector() == std::vector<int>{5, 4, 3, 2, 1}));
    SinglyList empty_list;
    reverse_list(empty_list);
    assert(empty_list.head == NIL);             // 鲁棒性：空链表反转不崩

    // ② 倒数第 k 个
    std::size_t steps = 0;
    const std::size_t k3 = kth_from_end(L, 3, steps);
    println("② 倒数第 3 个 = {}（快慢指针相对走了 {} 步）", L.key[k3], steps);
    assert(L.key[k3] == 3);
    std::size_t bad = 0;
    assert(kth_from_end(L, 0, bad) == NIL);     // k=0 非法
    assert(kth_from_end(L, 6, bad) == NIL);     // k>n 非法
    assert(kth_from_end(empty_list, 1, bad) == NIL);
    println("   非法输入 k=0 / k=6 / 空链表 → 统一返回「无解」，不读越界");

    // ③ 替身删除
    SinglyList D = L;
    bool sub = false;
    delete_without_predecessor(D, 1, sub);      // 删掉值 2（无前驱可用）
    println("③ 只给待删结点（值 2）就删除 → {}（替身删除 = {}）",
            show(D.to_vector()), sub);
    assert((D.to_vector() == std::vector<int>{1, 3, 4, 5}));
    SinglyList T = L;
    std::size_t tail = T.head;
    while (T.next[tail] != NIL) { tail = T.next[tail]; }
    delete_without_predecessor(T, tail, sub);   // 尾结点：无替身可搬
    println("   尾结点无后继 → 退化为 O(n) 从头找前驱：{}（替身删除 = {}）",
            show(T.to_vector()), sub);
    assert((T.to_vector() == std::vector<int>{1, 2, 3, 4}));

    // ④ 归并（同一个节点池里的两条有序链）
    NodePool pool;
    const std::size_t head_a = pool.append(1, NIL);
    std::size_t t_a = head_a;
    t_a = pool.append(3, t_a);
    t_a = pool.append(5, t_a);
    t_a = pool.append(7, t_a);
    const std::size_t head_b = pool.append(2, NIL);
    std::size_t t_b = head_b;
    t_b = pool.append(4, t_b);
    t_b = pool.append(6, t_b);
    t_b = pool.append(8, t_b);
    (void)t_a;
    (void)t_b;
    println("④ 归并 1 3 5 7 与 2 4 6 8（同一节点池，共 {} 个结点）", pool.key.size());
    pool.head = merge_in_place(pool, head_a, head_b);
    const std::string merged = show(pool.to_vector());
    println("   原地归并（只改 next，零新结点）= {}", merged);
    assert((pool.to_vector() == std::vector<int>{1, 2, 3, 4, 5, 6, 7, 8}));
    assert(pool.key.size() == 8);                // 归并没有分配任何新结点

    // 同一份输入走「归并到新表」路线，结果必须一致
    NodePool q1;
    const std::size_t q1a = q1.append(1, NIL);
    std::size_t q1t = q1a;
    q1t = q1.append(3, q1t);
    q1t = q1.append(5, q1t);
    q1t = q1.append(7, q1t);
    (void)q1t;
    NodePool q2;
    const std::size_t q2b = q2.append(2, NIL);
    std::size_t q2t = q2b;
    q2t = q2.append(4, q2t);
    q2t = q2.append(6, q2t);
    q2t = q2.append(8, q2t);
    (void)q2t;
    const NodePool by_value = merge_by_value(q1, q2);
    println("   归并到新表 = {}（多花 {} 个结点，结果一致 = {}）",
            show(by_value.to_vector()), by_value.key.size(),
            by_value.to_vector() == pool.to_vector());
    assert(by_value.to_vector() == pool.to_vector());

    // 鲁棒性：一侧为空 / 两侧皆空
    NodePool one;
    const std::size_t only = one.append(42, NIL);
    NodePool blank;
    assert(merge_in_place(one, only, blank.head) == only);
    assert(merge_in_place(one, blank.head, only) == only);
    assert(merge_in_place(blank, blank.head, blank.head) == NIL);
    println("   一侧为空 / 两侧皆空：都正确返回另一侧（不崩、不成环）");

    // ⑤ 逆向输出
    const std::string by_stack = reverse_output_by_stack(L);
    std::string by_rec{};
    const long long depth = reverse_output_recursive(L, by_rec, 0, 1000);
    println("⑤ 逆向输出：显式栈「{}」 vs 递归「{}」（递归深度 {}）",
            by_stack, by_rec, depth);
    assert(by_stack == by_rec);
    assert(by_stack == "5 4 3 2 1");
}

// ═══ 10.6 用两个栈实现队列 ═══
// 不变式：in_ 负责收新元素；只有当 out_ 空了，才把 in_ 整摞倒进 out_。
// 倒一次之后，最早入队的元素就压在 out_ 的栈顶。
// 摊还代价：每个元素最多被倒一次，n 次操作的摊还代价是 O(1)
// （CLRS 第 18 章记账法的教科书例子；这里用 pours() 把倒栈次数打出来对账）。
template <class T>
class QueueWithTwoStacks {
public:
    void append_tail(const T& v) { in_.push(v); }

    T delete_head() {
        if (out_.empty()) {
            while (!in_.empty()) {              // 只在必要时倒一次
                out_.push(in_.top());
                in_.pop();
                ++moves_;                       // 搬一个元素记一次（记账法口径）
            }
        }
        assert(!out_.empty());                  // 空队列出队是调用者的错误
        const T v = out_.top();
        out_.pop();
        return v;
    }
    bool empty() const { return in_.empty() && out_.empty(); }
    std::size_t in_size() const { return in_.size(); }
    std::size_t out_size() const { return out_.size(); }
    long long moves() const { return moves_; }   // 元素被搬运的总次数

private:
    std::stack<T> in_{};
    std::stack<T> out_{};
    long long moves_ = 0;                         // 每次倒栈搬一个元素记一次
};

// 镜像题：两个队列实现栈。出栈时把 q1 的前 n−1 个搬到 q2，剩下的队首就是
// 栈顶——代价 O(n)，**没有**摊还 O(1) 的好性质（每次出栈都要搬）。
template <class T>
class StackWithTwoQueues {
public:
    void push(const T& v) { q1_.push(v); }

    T pop() {
        assert(!q1_.empty());
        while (q1_.size() > 1) {
            q2_.push(q1_.front());
            q1_.pop();
            ++moves_;
        }
        const T v = q1_.front();
        q1_.pop();
        std::swap(q1_, q2_);
        return v;
    }
    long long moves() const { return moves_; }

private:
    std::queue<T> q1_{};
    std::queue<T> q2_{};
    long long moves_ = 0;
};

static void two_stack_queue_demo() {
    println("");
    println("=== 10.6 用两个栈实现队列 ===");
    QueueWithTwoStacks<char> q;
    q.append_tail('a');
    q.append_tail('b');
    q.append_tail('c');
    println("入队 a b c：in_ 深 {}、out_ 深 {}（还没倒过）",
            q.in_size(), q.out_size());
    const char c1 = q.delete_head();
    println("出队 → {}（倒了一次：in_ 深 {}、out_ 深 {}）",
            c1, q.in_size(), q.out_size());
    const char c2 = q.delete_head();
    println("出队 → {}（out_ 非空，直接弹）", c2);
    q.append_tail('d');
    println("入队 d：     in_ 深 {}、out_ 深 {}", q.in_size(), q.out_size());
    const char c3 = q.delete_head();
    println("出队 → {}（out_ 还有货，不需要再倒）", c3);
    const char c4 = q.delete_head();
    println("出队 → {}（out_ 空了 → 又倒一次）", c4);
    println("空了吗：{}；n=4 次操作的元素搬运总次数 = {}（每个元素至多搬一次 → 摊还 O(1)）",
            q.empty(), q.moves());
    assert(c1 == 'a' && c2 == 'b' && c3 == 'c' && c4 == 'd');
    assert(q.empty());
    assert(q.moves() == 4);                      // 第一次倒 3 个，第二次倒 1 个

    println("");
    println("镜像题：两个队列实现栈");
    StackWithTwoQueues<char> st;
    st.push('a');
    st.push('b');
    st.push('c');
    const char s1 = st.pop();
    println("压入 a b c，弹出 → {}", s1);
    st.push('d');
    const char s2 = st.pop();
    const char s3 = st.pop();
    const char s4 = st.pop();
    println("压入 d，弹出 → {}，弹出 → {}，弹出 → {}", s2, s3, s4);
    println("元素搬运共 {} 次（每次出栈都要搬，无法摊还到 O(1)）", st.moves());
    assert(s1 == 'c' && s2 == 'd' && s3 == 'b' && s4 == 'a');
}

// ═══ 10.7 数组上的两个经典问题 ═══
// 10.7(a) 行主序矩阵：每行、每列都递增时的查找。
// 关键洞察：只有**右上角**（或左下角）具备「一刀切」性质——
//   v > target：v 是本列最小的，整列都不可能是 target → 剔除该列
//   v < target：v 是本行最大的，整行都不可能是 target → 剔除该行
// 从中间选会把待查区切成两块且**重叠**；从左上角选（如 1）时，比它大的
// 目标既可能在右也可能在下，一行一列都剔不掉。
static bool find_in_sorted_matrix(const std::vector<int>& m, std::size_t rows,
                                  std::size_t cols, int target,
                                  long long& compares) {
    std::size_t r = 0;
    std::size_t c = cols - 1;                   // 右上角起步
    while (r < rows && c < cols) {              // c 无符号：用 c < cols 表达 c >= 0
        const int v = m[r * cols + c];
        ++compares;
        if (v == target) { return true; }
        if (v > target) { --c; } else { ++r; }
    }
    return false;
}

static void sorted_matrix_demo() {
    println("");
    println("=== 10.7(a) 行主序有序矩阵的查找 ===");
    const std::vector<int> m{1, 2, 8, 9,
                             2, 4, 9, 12,
                             4, 7, 10, 13,
                             6, 8, 11, 15};
    println("4x4 矩阵（行、列都递增）：");
    for (std::size_t r = 0; r < 4; ++r) {
        print("   ");
        for (std::size_t c = 0; c < 4; ++c) { print("{:3}", m[r * 4 + c]); }
        println("");
    }
    long long cmp = 0;
    const bool hit = find_in_sorted_matrix(m, 4, 4, 7, cmp);
    println("查找 7：找到 = {}，比较 {} 次（步数上界 rows+cols−1 = 7）",
            hit, cmp);
    assert(hit && cmp == 5);
    long long cmp5 = 0;
    assert(!find_in_sorted_matrix(m, 4, 4, 5, cmp5));
    println("查找 5（不在矩阵中）：比较 {} 次就走完", cmp5);
    assert(cmp5 == 7);
    println("结论：最坏 O(rows+cols)，且**不依赖** m+n 元素全查——比"
            "「行内二分 + 行内找」的下界还小");
}

// 10.7(b) 原地替换空格：空格 → \"%20\"，字符串会**变长**。
// 从前向后做，每个空格都要把它后面 O(n) 个字符整体右移两格，总代价 O(n²)；
// 从后向前做，每个字符只写一次，总代价 O(n)。用移动次数把差距量化出来。
static void replace_blank_forward(std::string& s, long long& moves) {
    for (std::size_t i = 0; i < s.size(); ++i) {
        if (s[i] != ' ') { continue; }
        s.push_back(' ');                       // 先腾出两格
        s.push_back(' ');
        for (std::size_t j = s.size() - 1; j > i + 2; --j) {
            s[j] = s[j - 2];                    // 整段右移两格
            ++moves;
        }
        s[i] = '%';
        s[i + 1] = '2';
        s[i + 2] = '0';
    }
}

static void replace_blank_backward(std::string& s, long long& moves) {
    const std::size_t original = s.size();
    std::size_t blanks = 0;
    for (const char ch : s) { if (ch == ' ') { ++blanks; } }
    s.resize(original + blanks * 2);            // 一次扩容到位
    std::size_t read = original;               // 读指针（从原串末尾往前）
    std::size_t write = s.size();              // 写指针（从新串末尾往前）
    while (read > 0) {
        --read;
        if (s[read] != ' ') {
            --write;
            s[write] = s[read];
            ++moves;
        } else {
            s[--write] = '0';
            s[--write] = '2';
            s[--write] = '%';
            moves += 3;
        }
    }
}

static void replace_blank_demo() {
    println("");
    println("=== 10.7(b) 原地替换空格 ===");
    const std::string src{"We are happy."};
    std::string a = src;
    long long mv_a = 0;
    replace_blank_forward(a, mv_a);
    std::string b = src;
    long long mv_b = 0;
    replace_blank_backward(b, mv_b);
    println("原串 \"{}\"（{} 字符，2 个空格）", src, src.size());
    println("从前往后 O(n^2)：\"{}\"，字符移动 {} 次", a, mv_a);
    println("从后往前 O(n)：  \"{}\"，字符移动 {} 次", b, mv_b);
    assert(a == b);
    assert(a == "We%20are%20happy.");

    println("规模实验（串形如 \"x x x ... x\"）：");
    println("    k   从前往后   从后往前   倍数");
    for (int k : {2, 4, 8, 16, 32, 64}) {
        std::string t;
        for (int i = 0; i < k + 1; ++i) {
            if (i != 0) { t.push_back(' '); }
            t.push_back('x');
        }
        std::string t1 = t;
        long long m1 = 0;
        replace_blank_forward(t1, m1);
        std::string t2 = t;
        long long m2 = 0;
        replace_blank_backward(t2, m2);
        assert(t1 == t2);
        println("{:5}   {:9}   {:9}   {:.1f}", k, m1, m2,
                static_cast<double>(m1) / static_cast<double>(m2));
    }
}

// ═══ 10.8 表达式：中缀 / 前缀 / 后缀的互转与求值 ═══
//
// 二元表达式树：二元运算符为父节点，左右孩子为两个运算数。三种遍历与三种
// 表达式**一一对应**：
//     前序（根-左-右） = 前缀式
//     中序（左-根-右） = 中缀式
//     后序（左-右-根） = 后缀式（逆波兰式 RPN）
// 三者各访问每个节点一次，都 Θ(n)。
//
// ★ 关键结论（决定了一道题该给什么输入）：
//   **前缀式与后缀式无需括号即可唯一确定运算顺序** ⟹ 可由前缀/后缀
//   **唯一重建表达式树**（逆序扫描 + 栈）；
//   而**无括号的中缀式有歧义**（"x*y+z"既可读成 x*(y+z) 也可读成
//   (x*y)+z）⟹ 不能仅凭无括号中缀式建树。
//
// ── 一元负号的统一化 ──
// 一元 -u 让「孩子数」从 2 变成 1，会打乱所有二元规则的统一性。标准做法：
// 把一元 -u **归一成 0-u**，于是整个系统只需一套二元规则。归一化在**词法
// 分析阶段**做：`-` 若出现在串首、或前一 token 是运算符 / 左括号，
// 就是一元负号，插入一个 0。

// 节点：kind 区分原子(0) / 一元(1) / 二元(2)；原子用 text 承载字面量
// （**原样透传**，不转 double——避免 -45.78 变成 -45.780000 或丢精度）。
struct ExprNode {
    std::string text;
    int kind = 0;                     // 0 = 原子, 1 = 一元, 2 = 二元
    std::ptrdiff_t l = -1, r = -1;
};

class ExprForest {
public:
    std::vector<ExprNode> node;

    std::ptrdiff_t add_atom(const std::string& t) {
        node.push_back({t, 0, -1, -1});
        return static_cast<std::ptrdiff_t>(node.size()) - 1;
    }
    std::ptrdiff_t add_unary(const std::string& t, std::ptrdiff_t a) {
        node.push_back({t, 1, a, -1});
        return static_cast<std::ptrdiff_t>(node.size()) - 1;
    }
    std::ptrdiff_t add_binary(const std::string& t, std::ptrdiff_t a,
                              std::ptrdiff_t b) {
        node.push_back({t, 2, a, b});
        return static_cast<std::ptrdiff_t>(node.size()) - 1;
    }
    // 把 src 的整棵树深拷贝进本森林，返回新根下标。求导时需要**复用原式**
    // 的子树（如商法则的分母 v^2），不能只存指针。
    std::ptrdiff_t graft(const ExprForest& src, std::ptrdiff_t i) {
        if (i == -1) { return -1; }
        const ExprNode& nd = src.node[static_cast<std::size_t>(i)];
        const std::ptrdiff_t l = graft(src, nd.l);
        const std::ptrdiff_t r = graft(src, nd.r);
        node.push_back({nd.text, nd.kind, l, r});
        return static_cast<std::ptrdiff_t>(node.size()) - 1;
    }
};

// 优先级（数字越大越紧）。`ln` 是本节唯一的一元函数；`^` 最紧。
static int priority(const std::string& op) {
    if (op == "^") { return 6; }
    if (op == "ln") { return 5; }
    if (op == "*" || op == "/") { return 4; }
    if (op == "+" || op == "-") { return 3; }
    return 0;                                    // 原子
}
static bool isOperator(const std::string& t) { return priority(t) != 0; }

// 词法分析 + **一元负号归一化**：切成 token 流，遇一元 minus 补一个 0。
static std::vector<std::string> tokenize(const std::string& s) {
    std::vector<std::string> out;
    const std::size_t n = s.size();
    for (std::size_t i = 0; i < n;) {
        const char ch = s[i];
        if (ch == ' ') { ++i; continue; }
        if (ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '^'
            || ch == '(' || ch == ')') {
            // 一元负号判据：`-` 出现在串首，或前一个 token 是运算符 / 左括号
            const bool atStart = out.empty();
            const std::string prev = atStart ? std::string() : out.back();
            const bool afterOperandish = prev == "+" || prev == "-" || prev == "*"
                || prev == "/" || prev == "^" || prev == "(";
            if (ch == '-' && (atStart || afterOperandish)) {
                out.push_back("0");// ★ 归一：一元 -u ⟹ 0-u
            }
            out.emplace_back(1, ch);
            ++i;
            continue;
        }
        if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
            // 函数名 ln（后面必跟左括号）；其余单字母是变量
            if (ch == 'l' && i + 1 < n && s[i + 1] == 'n'
                && i + 2 < n && s[i + 2] == '(') {
                out.push_back("ln");
                i += 2;
                continue;
            }
            out.emplace_back(1, ch);
            ++i;
            continue;
        }
        std::size_t j = i;              // 数字（含小数点）
        while (j < n && ((s[j] >= '0' && s[j] <= '9') || s[j] == '.')) { ++j; }
        out.push_back(s.substr(i, j - i));
        i = j;
    }
    return out;
}

// 中缀 → 表达式树：**Shunting-yard**（运算符栈 + 运算数栈）。
// 遇原子：进数栈；遇运算符：先把栈顶优先级 ≥ 当前（且左结合）的运算符
// **弹栈消解**再 push；遇 `(` 直接 push；遇 `)` 弹到 `(` 为止。
// 消解时弹 a、弹 b，以该运算符为根合并 —— 注意**弹栈顺序先右后左**。
static std::ptrdiff_t build_from_infix(const std::vector<std::string>& tok,
                                       ExprForest& f) {
    std::vector<std::ptrdiff_t> val;
    std::vector<std::string> op;
    auto reduce = [&]() {
        const std::string o = op.back();
        op.pop_back();
        if (o == "ln") {                    // 一元：只有一个操作数
            const auto a = val.back(); val.pop_back();
            val.push_back(f.add_unary(o, a));
            return;
        }
        const auto b = val.back(); val.pop_back();   // 先弹出的是右孩子
        const auto a = val.back(); val.pop_back();
        val.push_back(f.add_binary(o, a, b));
    };
    for (const std::string& t : tok) {
        if (t == "(") {
            op.push_back(t);
        } else if (t == ")") {
            while (!op.empty() && op.back() != "(") { reduce(); }
            if (!op.empty()) { op.pop_back(); }        // 弹掉 `(`
            if (!op.empty() && op.back() == "ln") { reduce(); }  // ln(...)
        } else if (isOperator(t)) {
            // 左结合 ⟹ 优先级**相等也弹**（关键：(a-b)-c 不能弹成 a-(b-c)）
            while (!op.empty() && op.back() != "("
                   && priority(op.back()) >= priority(t)) {
                reduce();
            }
            op.push_back(t);
        } else {
            val.push_back(f.add_atom(t));
        }
    }
    while (!op.empty()) { reduce(); }
    return val.back();
}

// 前向声明：带括号的中序输出在10.9 定义（括号规则那一节），这里先借用它
// 来展示「同一棵树，中序遍历加不加括号是两种信息量」。
static void emit_infix(const ExprForest& f, std::ptrdiff_t i, int parentPri,
                       bool isRightChild, std::string& out);

// 三种遍历 → 三种表达式。各 Θ(n)。
static void preorder(const ExprForest& f, std::ptrdiff_t i, std::string& out) {
    if (i == -1) { return; }
    if (!out.empty()) { out += ' '; }
    out += f.node[static_cast<std::size_t>(i)].text;
    preorder(f, f.node[static_cast<std::size_t>(i)].l, out);
    preorder(f, f.node[static_cast<std::size_t>(i)].r, out);
}
static void inorder(const ExprForest& f, std::ptrdiff_t i, std::string& out) {
    if (i == -1) { return; }
    const ExprNode& nd = f.node[static_cast<std::size_t>(i)];
    if (nd.kind == 2) {
        inorder(f, nd.l, out);
        if (!out.empty()) { out += ' '; }
        out += nd.text;
        inorder(f, nd.r, out);
    } else {
        if (!out.empty()) { out += ' '; }
        out += nd.text;                     // 原子 / 一元运算符：函数名自带括号
    }
}
static void postorder(const ExprForest& f, std::ptrdiff_t i, std::string& out) {
    if (i == -1) { return; }
    const ExprNode& nd = f.node[static_cast<std::size_t>(i)];
    postorder(f, nd.l, out);
    postorder(f, nd.r, out);
    if (!out.empty()) { out += ' '; }
    out += nd.text;
}

// 前缀式 → 表达式树：**逆序扫描 + 栈**。
// 前缀是「根-左-右」，从右往左读就变成「右-左-根」—— 右子树先完整读完，
// 于是可以「弹两棵已建好的子树、自底向上合并」。扫完栈顶即根。
// **必须逆序**：正序扫描时左右子树都还没读完，无从合并。
//
// ★ 弹栈顺序与 Shunting-yard **恰好相反**，这是本节最容易写反的一行：
//   · Shunting-yard（中缀建树）从左往右扫，先弹的是**右**操作数（最近入栈）；
//   · 本函数从右往左扫，先弹的是**左**子树（离当前运算符更近的那个）。
// 记法：右往左扫时，「先读到的是右儿子」但「先弹的是左儿子」。
static std::ptrdiff_t build_from_prefix(const std::vector<std::string>& tok,
                                        ExprForest& f) {
    std::vector<std::ptrdiff_t> stk;
    for (std::size_t i = tok.size(); i-- > 0;) {
        const std::string& t = tok[i];
        if (!isOperator(t)) {
            stk.push_back(f.add_atom(t));
        } else if (t == "ln") {
            const auto a = stk.back(); stk.pop_back();
            stk.push_back(f.add_unary(t, a));
        } else {
            const auto l = stk.back(); stk.pop_back();   // ★ 先弹的是左子树
            const auto r = stk.back(); stk.pop_back();   // 后弹的是右子树
            stk.push_back(f.add_binary(t, l, r));
        }
    }
    return stk.empty() ? -1 : stk.back();
}

// 后缀式求值：单栈，遇原子 push，遇运算符弹所需个数、算完 push。Θ(n)。
static double eval_rpn(const std::vector<std::string>& tok) {
    std::vector<double> stk;
    for (const std::string& t : tok) {
        if (!isOperator(t)) {
            stk.push_back(std::stod(t));
        } else if (t == "ln") {
            stk.back() = std::log(stk.back());
        } else {
            const double b = stk.back(); stk.pop_back();
            const double a = stk.back(); stk.pop_back();
            if (t == "+") { stk.push_back(a + b); }
            else if (t == "-") { stk.push_back(a - b); }
            else if (t == "*") { stk.push_back(a * b); }
            else if (t == "/") { stk.push_back(a / b); }
            else { stk.push_back(std::pow(a, b)); }
        }
    }
    return stk.back();
}

static void expression_demo() {
    println("");
    println("=== 10.8 表达式：中缀 / 前缀 / 后缀的互转与求值 ===");
    struct Case { const char* infix; const char* prefix; };
    const Case cases[] = {
        {"x + y",       "+ x y"},
        {"x * y + z",   "+ * x y z"},
        {"(x * y) + z", "+ * x y z"},
        {"x * (y + z)", "* x + y z"},
        {"x - y - z",   "- - x y z"},
    };
    println("三种遍历 ⟷ 三种表达式（一一对应，各 Θ(n)）：");
    for (const Case& c : cases) {
        const std::vector<std::string> tok = tokenize(c.infix);
        ExprForest f;
        const auto root = build_from_infix(tok, f);
        std::string pre, in, post;
        preorder(f, root, pre);
        inorder(f, root, in);
        postorder(f, root, post);
        println("  中缀输入 {:<12} → 前缀 {:<12} 后缀 {}", c.infix, pre, post);
        assert(pre == c.prefix);
    }
    println("");
    println("  注意第 2、3 行：输入的中缀**不同**（有无括号），但因代数上");
    println("  x*y+z 本就该加括号，前缀相同；第 4 行才是真正不同的结构。");

    // ★ 无括号中缀式的歧义：**同一个中缀串**对应两棵不同的树
    {
        ExprForest f1;
        const auto z1 = f1.add_atom("z");
        const auto y1 = f1.add_atom("y");
        const auto s1 = f1.add_binary("+", y1, z1);
        const auto x1 = f1.add_atom("x");
        const auto t1 = f1.add_binary("*", x1, s1);       // 树 A = x*(y+z)
        ExprForest f2;
        const auto z2 = f2.add_atom("z");
        const auto x2 = f2.add_atom("x");
        const auto y2 = f2.add_atom("y");
        const auto p2 = f2.add_binary("*", x2, y2);
        const auto t2 = f2.add_binary("+", p2, z2);       // 树 B = (x*y)+z
        std::string pre1, pre2, bare1, bare2;
        preorder(f1, t1, pre1);
        preorder(f2, t2, pre2);
        inorder(f1, t1, bare1);
        inorder(f2, t2, bare2);
        println("");
        println("★ 无括号中缀式的歧义（为什么中缀不能唯一重建树）：");
        println("    树 A = x*(y+z)   去括号中序 = {}   先序 = {}", bare1, pre1);
        println("    树 B = (x*y)+z   去括号中序 = {}   先序 = {}", bare2, pre2);
        println("    两棵树的**去括号中序串完全相同**（x * y + z），而先序**不同**——");
        println("    ⟹ 前缀/后缀式能唯一确定运算顺序，中缀式不能（除非给优先级");
        println("       或加括号）。这正是「前缀式可唯一重建、中缀式不可逆」。");
        assert(bare1 == bare2);
        assert(bare1 == "x * y + z");
        assert(pre1 != pre2);
        assert(pre1 == "* x + y z");
        assert(pre2 == "+ * x y z");
    }

    // ★ 前缀式 → 树 → 三种表达式（重建的唯一性）
    {
        const std::vector<std::string> pre{"*", "x", "-", "y", "z"};
        ExprForest f;
        const auto root = build_from_prefix(pre, f);
        std::string p, in, post, paren;
        preorder(f, root, p);
        inorder(f, root, in);
        postorder(f, root, post);
        emit_infix(f, root, 0, false, paren);
        println("");
        println("前缀式 → 树（逆序扫描 + 栈）→ 三种表达式：");
        println("    前缀输入: * x - y z");
        println("    重建后先序: {}（与输入逐字相同 ⟹ 重建唯一）", p);
        println("    重建后中序: {}", in);
        println("    重建后后序: {}", post);
        println("    中序**加括号**后: {}", paren);
        println("    ⟹ 中序遍历本身不恢复括号，必须靠优先级规则「补」回来（见 10.9）。");
        assert(p == "* x - y z");
        assert(in == "x * y - z");
        assert(post == "x y z - *");
        assert(paren == "x * (y - z)");
        // 逆序扫描时「先弹的是左子树」——与 Shunting-yard 相反（见函数注释）
        assert(f.node[static_cast<std::size_t>(root)].text == "*");
        assert(f.node[static_cast<std::size_t>(root)].r
               == static_cast<std::ptrdiff_t>(2));   // 右孩子是 `- y z`
    }

    // 一元负号归一化：`-x*y` ⟹ `0-x*y`，从而只需一套二元规则
    {
        const std::vector<std::string> tok = tokenize("-x*y");
        std::string s;
        for (const std::string& t : tok) { s += (s.empty() ? "" : " ") + t; }
        ExprForest f;
        const auto root = build_from_infix(tok, f);
        std::string pre;
        preorder(f, root, pre);
        println("");
        println("一元负号归一化（`-u` ⟹ `0-u`，只需一套二元规则）：");
        println("    输入 -x*y 的 token 流: {}", s);
        println("    建树后先序: {}", pre);
        println("    ⟹ 树里只有二元 `-` 节点，一元的处理逻辑完全消失。");
        println("    （归一后 -x*y 成了 0-(x*y)：与 (0-x)*y 数值相同，");
        println("      但树形由优先级决定——补的0 是二元 `-` 的左孩子。）");
        assert(pre == "- 0 * x y");
        assert(f.node[static_cast<std::size_t>(root)].kind == 2);
        assert(f.node[static_cast<std::size_t>(root)].text == "-");
        // 负常量同理：-45.78 ⟹ 0-45.78，字面量原样透传
        const std::vector<std::string> neg = tokenize("-45.78");
        std::string ns;
        for (const std::string& t : neg) { ns += (ns.empty() ? "" : " ") + t; }
        println("    负常量 -45.78 的 token 流: {}（字面量原样保留，不转 double）", ns);
        assert(ns == "0 - 45.78");
    }

    // 后缀求值（单栈）
    {
        println("");
        println("后缀式求值（单栈，Θ(n)）：");
        struct EV { const char* postfix; double want; };
        const EV evs[] = {
            {"3 4 +", 7.0},
            {"3 4 2 * + 5 -", 6.0},        // (3 + 4*2) - 5 = 6
            {"5 2 ^", 25.0},
            {"2 3 ^ 4 +", 12.0},
            {"8 5 /", 1.6},
            {"2 3 + 4 *", 20.0},
        };
        for (const EV& e : evs) {
            std::vector<std::string> tok;
            for (char c : std::string(e.postfix)) {
                if (c != ' ') { tok.emplace_back(1, c); }
            }
            const double v = eval_rpn(tok);
            println("    {:<18} = {:<8g}（期望 {:g}）", e.postfix, v, e.want);
            assert(v == e.want);
        }
    }

    println("");
    println("  Θ(n) 与栈深：三种表达式各访问每节点一次 ⟹ 互转都是 Θ(n)；");
    println("  后缀求值的栈深度 = 表达式嵌套深度，与串长无关。");
}

// ═══ 10.9 表达式树求导：结构归纳与优先级括号规则 ═══
//
// 求导公式（本节的核心内容，必须写准）：
//     (u+v)' = u' + v'
//     (u-v)' = u' - v'
//     (uv)'  = u'v + uv'← 乘积法则
//     (u/v)' = (u'v - uv') / v^2  ← 商法则，写成 v^2（不是 v*v）
//     ln(u)' = u' / u← 分子是导数、分母是原式
//     x' = 1,  c' = 0（c 为常数）
//
// 输出中缀式时的**括号规则是本节的核心**。设父节点优先级 p、孩子子树
// 根的优先级 c：
//   · 左孩子：子树根**不是原子**且 c <  p ⟹ 加括号
//   · 右孩子：子树根**不是原子**且 c ≤ p ⟹ 加括号（是 ≤ 不是 <！）
//
// ★ 为什么右孩子用「≤」：+ - * / 都是**左结合**运算。
//   a-(b-c) 的括号**必须保留** —— 去掉就成 a-b-c = (a-b)-c，值变了。
//   而 (a-b)-c 写成 a-b-c 恰好是对的⟹ 左孩子同优先级**不能**加括号。
// 所以「前严格、后相等」不是笔误，是左结合在括号规则上的镜像。

// 求导：递归生成新树（**不化简**，允许 0*x、1*x）。Θ(n)——
// 每个原节点生成常数个新节点（乘法法则最多 5 个）。
static std::ptrdiff_t differentiate(const ExprForest& f, std::ptrdiff_t i,
                                    ExprForest& out) {
    if (i == -1) { return -1; }
    const ExprNode& nd = f.node[static_cast<std::size_t>(i)];
    if (nd.kind == 0) {                          // 叶子：x'=1，常数'=0
        return out.add_atom(nd.text == "x" ? "1" : "0");
    }
    if (nd.kind == 1) {                          // 一元：ln(u)' = u'/u
        const auto num = differentiate(f, nd.l, out);      // u'
        const auto den = out.graft(f, nd.l);              // u（原式，不求导）
        return out.add_binary("/", num, den);
    }
    // 二元：先递归求两个孩子（结构归纳假设：它们正确）
    const std::string& op = nd.text;
    if (op == "+" || op == "-") {
        const auto a = differentiate(f, nd.l, out);        // u'
        const auto b = differentiate(f, nd.r, out);        // v'
        return out.add_binary(op, a, b);
    }
    if (op == "*") {                             // u'v + uv'
        const auto up = differentiate(f, nd.l, out);
        const auto v = out.graft(f, nd.r);
        const auto term1 = out.add_binary("*", up, v);      // u'·v
        const auto u = out.graft(f, nd.l);
        const auto vp = differentiate(f, nd.r, out);
        const auto term2 = out.add_binary("*", u, vp);      // u·v'
        return out.add_binary("+", term1, term2);
    }
    if (op == "/") {                             // (u'v - uv') / v^2
        const auto up = differentiate(f, nd.l, out);
        const auto v1 = out.graft(f, nd.r);
        const auto t1 = out.add_binary("*", up, v1);       // u'·v
        const auto u1 = out.graft(f, nd.l);
        const auto vp = differentiate(f, nd.r, out);
        const auto t2 = out.add_binary("*", u1, vp);       // u·v'
        const auto num = out.add_binary("-", t1, t2);
        const auto v2 = out.graft(f, nd.r);
        const auto two = out.add_atom("2");
        const auto den = out.add_binary("^", v2, two);     // v^2，不是 v*v
        return out.add_binary("/", num, den);
    }
    if (op == "ln") {                             // 兜底：kind==1 已处理
        const auto a = differentiate(f, nd.l, out);
        return out.add_unary("ln", a);
    }
    // 未知运算符：原样透传，不静默出错
    const auto a = differentiate(f, nd.l, out);
    const auto b = differentiate(f, nd.r, out);
    return out.add_binary(op, a, b);
}

// 树 → 中缀式，按优先级加括号。**流式 append + 预留容量**，
// 不用 `s = s + ...` 反复拼接（那是 Θ(n²)）。
static void emit_infix(const ExprForest& f, std::ptrdiff_t i, int parentPri,
                       bool isRightChild, std::string& out) {
    if (i == -1) { return; }
    const ExprNode& nd = f.node[static_cast<std::size_t>(i)];
    const int p = priority(nd.text);
    const bool atomic = (nd.kind == 0);
    // ★ 括号规则：左孩子判严格小于、右孩子判小于等于（左结合）
    const bool need = !atomic && (isRightChild ? (p <= parentPri) : (p < parentPri));
    if (need) { out += '('; }
    if (nd.kind == 2) {
        emit_infix(f, nd.l, p, false, out);
        out += ' ';
        out += nd.text;
        out += ' ';
        emit_infix(f, nd.r, p, true, out);
    } else if (nd.kind == 1) {
        out += nd.text;
        out += '(';
        emit_infix(f, nd.l, 0, false, out);
        out += ')';
    } else {
        out += nd.text;
    }
    if (need) { out += ')'; }
}

static std::string derivative_to_string(const std::string& infix) {
    const std::vector<std::string> tok = tokenize(infix);
    ExprForest f;
    const auto root = build_from_infix(tok, f);
    ExprForest d;
    const auto droot = differentiate(f, root, d);   // ★ 必须用返回的根下标
    std::string out;
    out.reserve(256);                 // 预留容量 ⟹ append 不重分配 ⟹ Θ(n + L)
    emit_infix(d, droot, 0, false, out);
    return out;
}

static void derivative_demo() {
    println("");
    println("=== 10.9 表达式树求导：结构归纳与优先级括号规则 ===");
    struct Case { const char* expr; const char* want; };
    const Case cases[] = {
        {"x*x",    "1 * x + x * 1"},
        {"x+x",    "1 + 1"},
        {"x-x",    "1 - 1"},
        {"x/x",    "(1 * x - x * 1) / x ^ 2"},
        {"x/3",    "(1 * 3 - x * 0) / 3 ^ 2"},
        {"x+x*x",  "1 + (1 * x + x * 1)"},
        {"ln(x)",  "1 / x"},
        {"-x",     "0 - 1"},
    };
    println("求导（不化简，允许 0*x、1*x；幂写成 v^2）：");
    for (const Case& c : cases) {
        const std::string got = derivative_to_string(c.expr);
        println("  {:<8} ⟹ {:<30}", c.expr, got);
        assert(got == c.want);
    }

    // ★ 括号规则的钥匙：x*x/x
    println("");
    println("★ 括号规则的钥匙 x*x/x（根是 `/`，左孩子是同优先级的 `*`）：");
    {
        const std::string got = derivative_to_string("x*x/x");
        println("  x*x/x  ⟹ {}", got);
        assert(got == "((1 * x + x * 1) * x - x * x * 1) / x ^ 2");
        println("    根 `/`（p=4），左孩子子树根是 `*`（c=4，同优先级）——");
        println("    左孩子判**严格小于** ⟹ 不加括号 ⟹ `(...) * x` 而非 `(...) * (x)`。");
        println("    右孩子是 x^2（c=6 > 4）⟹ 也不加括号。");
        println("    若左孩子也用 ≤，会多出一层无谓括号（值虽同，形态不对）。");
    }

    // ★ 右孩子为什么必须用 ≤：a-(b-c) 必须保留括号
    println("");
    println("★ 右孩子为什么必须用「≤」（左结合的镜像）：");
    {
        const Case rightAssoc[] = {
            {"x-(x-x)", "1 - (1 - 1)"},
            {"x-(x*x)", "1 - (1 * x + x * 1)"},
            {"x*(x+x)", "1 * (x + x) + x * (1 + 1)"},
        };
        for (const Case& c : rightAssoc) {
            const std::string got = derivative_to_string(c.expr);
            println("  {:<10} ⟹ {:<30}（括号必须保留）", c.expr, got);
            assert(got == c.want);
        }
        println("    若右孩子也只用「<」，x-(x-x) 会输出成 1-1-1 =");
        println("    (1-1)-1 = -1，而正确值是 1-(1-1) = 1 —— 值直接错了。");
        println("    左孩子同优先级**不能**加括号：(x-x)-x 输出 x-x-x 恰好正确。");
    }

    // ln 的求导：分子是导数、分母是原式
    println("");
    println("ln(u)' = u'/u（分子是**导数**、分母是**原式**，别写反）：");
    {
        const std::string g1 = derivative_to_string("ln(x)");
        const std::string g2 = derivative_to_string("ln(x*x)");
        const std::string g3 = derivative_to_string("ln(2*x)");
        println("  {:<10} ⟹ {:<22}（u=x, u'=1 ⟹ 1/x）", "ln(x)", g1);
        println("  {:<10} ⟹ {:<22}（u=x*x, u'=1*x+x*1）", "ln(x*x)", g2);
        println("  {:<10} ⟹ {:<22}（u=2*x, u'=0*x+2*1）", "ln(2*x)", g3);
        assert(g1 == "1 / x");
        assert(g2 == "(1 * x + x * 1) / (x * x)");
        assert(g3 == "(0 * x + 2 * 1) / (2 * x)");
        println("    ⟹ 分母是**原式 u**（未求导）；u 的根若是 `*`（c=4 ≤ 4）");
        println("       则右孩子必须加括号 —— 这正是 ≤ 规则的第二个用武之地。");
    }

    // 结构归纳的三个层次
    println("");
    println("正确性（结构归纳，对树的每个节点分三种情形）：");
    println("  叶子  ：x'=1、c'=0，符合导数定义。");
    println("  一元  ：ln(u)' = u'/u，由归纳假设 u' 正确即得。");
    println("  二元  ：按 + − * / 四个法则组合两个孩子（归纳假设保证孩子正确）。");
    println("  输出  ：括号规则只做「保持语义」的机械变换 ⟹ 中缀式与树等价。");

    // 输出规模：流式 vs 反复拼接
    println("");
    println("输出拼接方式（连乘 x*x*... 不化简时导数会膨胀）：");
    {
        std::string expr = "x";
        for (int i = 1; i < 8; ++i) { expr = "(" + expr + "*x)"; }
        const std::string got = derivative_to_string(expr);
        println("  输入串长度 {}，导数串长度 {}", expr.size(), got.size());
        println("  流式 append（先 reserve(256)）Θ(n + L)；");
        println("  反复 `out = out + ...`（每次重新分配）Θ(n · L)。");
        println("  ⟹ 输出长度 L 本身可能指数增长（不化简的固有代价，见坑位），");
        println("     但**拼接方式**不该再给它加一层平方。");
    }
}

// ═══ 10.10 占用数组：花园种花 ═══
// F 个坑一字排开；第 j 种花从坑 L[j] 起每隔 I[j]−1 坑一株，即占据等差数列
// L[j], L[j]+I[j], L[j]+2I[j], …。用一个 vector<char> 当「占用位图」：
// 下标 = 坑号−1，值 = 是否被占。这是集合最朴素的表示——成员检测 O(1)，
// 最后数一遍 0 的个数即可。
static int flower_garden_empty(int f, const std::vector<int>& starts,
                               const std::vector<int>& intervals) {
    std::vector<char> occupied(static_cast<std::size_t>(f), 0);
    for (std::size_t j = 0; j < starts.size(); ++j) {
        for (int p = starts[j]; p <= f; p += intervals[j]) {
            occupied[static_cast<std::size_t>(p - 1)] = 1;   // 坑号 1 基
        }
    }
    int empty = 0;
    for (char x : occupied) { empty += (x == 0); }
    return empty;
}

// 逐坑核对版：坑 i 被花 j 占据 ⟺ (i − L[j]) mod I[j] == 0。
// （写成 (i−1) mod I[j] == (L[j]−1) mod I[j] 也对——右边必须是 L[j]−1，
// 写成 L[j] 就整体错位一格，一株都种不上。）
static int flower_garden_check(int f, const std::vector<int>& starts,
                               const std::vector<int>& intervals) {
    int empty = 0;
    for (int i = 1; i <= f; ++i) {
        bool planted = false;
        for (std::size_t j = 0; j < starts.size(); ++j) {
            if (i >= starts[j] &&
                (i - starts[j]) % intervals[j] == 0) { planted = true; break; }
        }
        if (!planted) { ++empty; }
    }
    return empty;
}

static void flower_garden_demo() {
    println("美丽的花园（1-4）：占用数组 + 等差数列：");
    const std::vector<int> l{1, 3, 1}, iv{3, 7, 4};
    const int empty = flower_garden_empty(30, l, iv);
    const int check = flower_garden_check(30, l, iv);
    println("  F=30，玫瑰 L1/I3、秋海棠 L3/I7、雏菊 L1/I4");
    println("  占用数组版空坑 {}，逐坑核对版 {}（答案 13）", empty, check);
    assert(empty == 13 && check == 13);

    std::mt19937 rng{5489};
    int mismatches = 0;
    for (int t = 0; t < 2000; ++t) {
        const int f = 1 + static_cast<int>(rand_below(rng, 200));
        const int k = 1 + static_cast<int>(rand_below(rng, 6));
        std::vector<int> ls, is;
        for (int j = 0; j < k; ++j) {
            ls.push_back(1 + static_cast<int>(rand_below(rng,
                                    static_cast<std::uint32_t>(f))));
            is.push_back(1 + static_cast<int>(rand_below(rng, 10)));
        }
        if (flower_garden_empty(f, ls, is) !=
            flower_garden_check(f, ls, is)) { ++mismatches; }
    }
    println("  随机 {} 例两版对账：不一致 {} 例", 2000, mismatches);
    assert(mismatches == 0);
}

// ═══ 10.11 后缀表达式（RPN）与终态周期序列 ═══
// 函数 f: {0…N} → {0…N} 以后缀式给出；从 n 出发不断迭代 f，轨道有限
// ⟹ 必落入一个循环，求该循环（周期部分）的长度。

// 按空格切词。
static std::vector<std::string> split_tokens(const std::string& s) {
    std::vector<std::string> tokens;
    std::size_t i = 0;
    while (i < s.size()) {
        while (i < s.size() && s[i] == ' ') { ++i; }
        const std::size_t j = i;
        while (i < s.size() && s[i] != ' ') { ++i; }
        if (i > j) { tokens.push_back(s.substr(j, i - j)); }
    }
    return tokens;
}

// RPN 求值：栈式计算。中间积可能超过 64 位（如取模前连乘多项），用
// __int128 兜底；返回值因末尾 %N 而落在 0..N−1。
static long long rpn_calculate(long long N, long long x,
                               const std::vector<std::string>& tokens) {
    // 唯一的 % 在末尾，取模前的中间值用 unsigned long long：N ≤ 1.1·10⁶
    // 时三因子连乘约 1.3·10¹⁸，装得下；表达式项数更多时需换大整数。
    std::vector<unsigned long long> st;
    for (const std::string& t : tokens) {
        if (t == "+" || t == "*" || t == "%") {
            const unsigned long long op2 = st.back(); st.pop_back();
            const unsigned long long op1 = st.back(); st.pop_back();
            unsigned long long r = 0;
            if (t == "+") { r = op1 + op2; }
            else if (t == "*") { r = op1 * op2; }
            else { r = op1 % op2; }
            st.push_back(r);
        } else if (t == "x") {
            st.push_back(static_cast<unsigned long long>(x));
        } else if (t == "N") {
            st.push_back(static_cast<unsigned long long>(N));
        } else {
            st.push_back(static_cast<unsigned long long>(std::stoll(t)));
        }
    }
    return static_cast<long long>(st.back());
}

// 周期算法一（首次出现表）：first[v] = 值 v 第一次出现的迭代序号，-1 为
// 未见。重复时周期 = 当前序号 − 首次序号。O(N+1) 时间与空间。
template <class F>
static int period_by_first_occurrence(long long N, long long start, const F& f) {
    std::vector<int> first(static_cast<std::size_t>(N) + 1, -1);
    long long x = start;
    int k = 0;
    while (first[static_cast<std::size_t>(x)] == -1) {
        first[static_cast<std::size_t>(x)] = k++;
        x = f(x);
    }
    return k - first[static_cast<std::size_t>(x)];
}

// 周期算法二（Floyd 判圈，对账用）：快慢指针同步前进，相遇后再用其中
// 一个指针走一圈计数。O(1) 额外空间，不依赖任何下标表。
template <class F>
static int period_by_floyd(long long start, const F& f) {
    long long tortoise = f(start);
    long long hare = f(f(start));
    while (tortoise != hare) {
        tortoise = f(tortoise);
        hare = f(f(hare));
    }
    int period = 1;
    hare = f(tortoise);
    while (tortoise != hare) {
        hare = f(hare);
        ++period;
    }
    return period;
}

static void periodic_sequence_demo() {
    println("=== 10.11 后缀表达式（RPN）与终态周期序列 ===");
    struct Case {
        long long N, n;
        std::string rpn;
        int answer;
    };
    const std::vector<Case> cases = {
        {10, 1, "x N %", 1},
        {11, 1, "x x 1 + * N %", 3},
        {1728, 1, "x x 1 + * x 2 + * N %", 6},
        {1728, 1, "x x 1 + x 2 + * * N %", 6},
        {100003, 1, "x x 123 + * x 12345 + * N %", 369}};
    for (const Case& c : cases) {
        const std::vector<std::string> tokens = split_tokens(c.rpn);
        auto f = [&](long long x) { return rpn_calculate(c.N, x, tokens); };
        const int p1 = period_by_first_occurrence(c.N, c.n, f);
        const int p2 = period_by_floyd(c.n, f);
        println("  N={} n={} RPN=\"{}\"：首次出现表 {}，Floyd {}（答案 {}）",
                c.N, c.n, c.rpn, p1, p2, c.answer);
        assert(p1 == c.answer && p2 == c.answer);
    }
    // 样例 2 的轨道展示：1 → 2 → 6 → 9 → 2…
    {
        const std::vector<std::string> tokens = split_tokens("x x 1 + * N %");
        print("  样例2 轨道展示：1");
        long long x = 1;
        for (int k = 0; k < 4; ++k) {
            x = rpn_calculate(11, x, tokens);
            print(" → {}", x);
        }
        println(" …（2,6,9 周而复始 ⟹ 周期 3）");
    }
    std::mt19937 rng{5489};
    // 随机仿射 RPN：(x*a + b) % N，两种周期算法对账。
    int rpn_trials = 3000, rpn_bad = 0;
    for (int t = 0; t < rpn_trials; ++t) {
        const long long N = 1 + static_cast<long long>(rand_below(rng, 2000));
        const long long start = static_cast<long long>(rand_below(
            rng, static_cast<std::uint32_t>(N)));
        const long long a = static_cast<long long>(rand_below(
            rng, static_cast<std::uint32_t>(N)));
        const long long b = static_cast<long long>(rand_below(
            rng, static_cast<std::uint32_t>(N)));
        const std::string rpn =
            "x " + std::to_string(a) + " * " + std::to_string(b) + " + N %";
        const std::vector<std::string> tokens = split_tokens(rpn);
        auto f = [&](long long x) { return rpn_calculate(N, x, tokens); };
        if (period_by_first_occurrence(N, start, f) !=
            period_by_floyd(start, f)) { ++rpn_bad; }
    }
    println("  随机 {} 个仿射 RPN 案例：首次表 vs Floyd 不一致 {} 例",
            rpn_trials, rpn_bad);
    assert(rpn_bad == 0);
    // 随机映射表：完全任意的 f，两种周期算法对账（不含 RPN，纯判圈）。
    int map_trials = 1000, map_bad = 0;
    for (int t = 0; t < map_trials; ++t) {
        const long long N = 1 + static_cast<long long>(rand_below(rng, 2000));
        std::vector<long long> table(static_cast<std::size_t>(N));
        for (long long& y : table) {
            y = static_cast<long long>(rand_below(
                rng, static_cast<std::uint32_t>(N)));
        }
        auto f = [&](long long x) { return table[static_cast<std::size_t>(x)]; };
        const long long start = static_cast<long long>(rand_below(
            rng, static_cast<std::uint32_t>(N)));
        if (period_by_first_occurrence(N, start, f) !=
            period_by_floyd(start, f)) { ++map_bad; }
    }
    println("  随机 {} 个任意映射：首次表 vs Floyd 不一致 {} 例",
            map_trials, map_bad);
    assert(map_bad == 0);
}

int main() {
    stack_queue_demo();
    linked_list_demo();
    tree_demo();
    singly_list_demo();
    two_stack_queue_demo();
    sorted_matrix_demo();
    replace_blank_demo();
    expression_demo();
    derivative_demo();
    flower_garden_demo();
    periodic_sequence_demo();
    println("自检通过");
    return 0;
}