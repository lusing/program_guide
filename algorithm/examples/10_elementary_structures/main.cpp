// 10 基本数据结构（CLRS 第 10 章）。结构：10.1 数组栈 + 循环队列 /
// 10.2 哨兵双链表 / 10.3 对象数组 + 自由表（CLRS 的三数组表示）/
// 10.4 有根树的两种数组表示与遍历。
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
#include <stack>
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

int main() {
    stack_queue_demo();
    linked_list_demo();
    tree_demo();
    println("自检通过");
    return 0;
}
