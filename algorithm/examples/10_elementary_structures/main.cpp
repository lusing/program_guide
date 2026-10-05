// 10 基本数据结构（CLRS 第 10 章）。结构：10.1 数组栈 + 循环队列 /
// 10.2 哨兵双链表 / 10.3 对象数组 + 自由表（CLRS 的三数组表示）/
// 10.4 有根树的两种数组表示与遍历 /
// 10.5 单链表上的经典算法（反转·倒数第 k·原地删除·归并·逆向输出）/
// 10.6 用两个栈实现队列（摊还 O(1)）与镜像的「两队列实现栈」/
// 10.7 数组上的经典问题（二维有序矩阵查找·原地替换空格）。
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
#include <cstdint>
#include <queue>
#include <stack>
#include <string>
#include <vector>

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

int main() {
    stack_queue_demo();
    linked_list_demo();
    tree_demo();
    singly_list_demo();
    two_stack_queue_demo();
    sorted_matrix_demo();
    replace_blank_demo();
    println("自检通过");
    return 0;
}
