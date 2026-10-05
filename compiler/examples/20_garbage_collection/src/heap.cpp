// file: src/heap.cpp
// 第 20 章配套：堆的构造与三台收集器实现。
#include "heap.hpp"

#include <algorithm>
#include <deque>
#include <set>

#include <algorithm>
#include <deque>

namespace tip {

int Heap::alloc(const std::string &name, int nslots) {
    objs_.push_back(Obj{name, std::vector<int>(nslots, -1)});
    return static_cast<int>(objs_.size()) - 1;
}

void Heap::set(int obj, int slot, int target) {
    objs_[obj].slot[slot] = target;
}

void Heap::dropRoot(int id) {
    roots_.erase(std::remove(roots_.begin(), roots_.end(), id), roots_.end());
}

// 内置演示图：
//   可达：A→{B,C}, B→{D}, C→{D}（D 被 B、C 共享）
//   不可达自环：E→E
//   不可达二环：F→G→F
//   不可达但指向可达者：H→B（垃圾救不了自己）
// 根：a=A, b=B
Heap Heap::demo() {
    Heap h;
    int A = h.alloc("A", 2), B = h.alloc("B", 1), C = h.alloc("C", 1), D = h.alloc("D", 0);
    int E = h.alloc("E", 1), F = h.alloc("F", 1), G = h.alloc("G", 1), H = h.alloc("H", 1);
    h.set(A, 0, B);
    h.set(A, 1, C);
    h.set(B, 0, D);
    h.set(C, 0, D);
    h.set(E, 0, E);   // 自环
    h.set(F, 0, G);
    h.set(G, 0, F);   // 二环
    h.set(H, 0, B);   // 垃圾指向可达者
    h.addRoot(A);
    h.addRoot(B);
    (void)C;
    (void)D;
    (void)E;
    (void)F;
    (void)G;
    (void)H;
    return h;
}

// ---------- 引用计数 ----------
// “计数清零即回收”在这里以报告形式呈现：统计每对象的入度，
// 并与真可达性（借用 markSweep 的标记阶段结果）对照。
RefCountReport refCount(const Heap &h) {
    RefCountReport r;
    for (int i = 0; i < h.size(); ++i) r.count[i] = 0;
    for (int root : h.roots()) r.count[root] += 1;   // 根引用也计数
    for (int i = 0; i < h.size(); ++i)
        for (int t : h.o(i).slot)
            if (t >= 0) r.count[t] += 1;
    // 真可达集合（独立的标记遍历，不改动 h）
    std::vector<bool> reach(h.size(), false);
    std::deque<int> work(h.roots().begin(), h.roots().end());
    while (!work.empty()) {
        int cur = work.front();
        work.pop_front();
        if (reach[cur]) continue;
        reach[cur] = true;
        for (int t : h.o(cur).slot)
            if (t >= 0 && !reach[t]) work.push_back(t);
    }
    for (int i = 0; i < h.size(); ++i)
        if (!reach[i] && r.count[i] > 0)
            r.nonZeroButUnreachable.push_back(i);
    return r;
}

// ---------- 标记清除（Algorithm 7.12） ----------
// 标记阶段：Unscanned 工作表——第 28 章工作表算法的原生态现身；
// 清扫阶段：整堆扫一遍，未标记者入 freed，标记位复位（为下一轮做准备）。
MarkSweepReport markSweep(Heap &h) {
    MarkSweepReport r;
    std::vector<bool> reached(h.size(), false);
    std::deque<int> unscanned;
    for (int root : h.roots())
        if (!reached[root]) {
            reached[root] = true;
            unscanned.push_back(root);
        }
    while (!unscanned.empty()) {
        int o = unscanned.front();
        unscanned.pop_front();
        for (int t : h.o(o).slot) {
            if (t >= 0 && !reached[t]) {
                reached[t] = true;
                unscanned.push_back(t);
            }
        }
    }
    for (int i = 0; i < h.size(); ++i)
        if (reached[i]) r.survived.push_back(i);
        else r.freed.push_back(i);
    return r;
}

// ---------- Cheney 复制 ----------
// 从根出发广度优先：scan 与 free 两根指针在“到空间”上赛跑；
// 每个对象只拷贝一次（forwarding 表挡驾），拷贝时留下转发地址。
CheneyReport cheney(const Heap &h) {
    CheneyReport r;
    std::map<int, int> fwd;
    std::deque<int> scanQueue;   // 已拷贝、待扫描（新编号即队列位置）
    auto copyOf = [&](int old) -> int {
        auto it = fwd.find(old);
        if (it != fwd.end()) return it->second;
        int fresh = static_cast<int>(r.newLayout.size());
        r.newLayout.push_back({old, h.o(old).slot});
        r.copyOrder.push_back(old);
        fwd[old] = fresh;
        return fresh;
    };
    for (int root : h.roots()) copyOf(root);
    size_t scan = 0;
    while (scan < r.newLayout.size()) {
        auto &entry = r.newLayout[scan];
        for (int &t : entry.second)
            if (t >= 0) t = copyOf(t);
        ++scan;
    }
    r.forwarding = fwd;
    return r;
}

// ---------- 补一：三色抽象（匠书 §26.3） ----------
TriColorReport triColor(const Heap &h) {
    TriColorReport r;
    r.invariantViolations = 0;
    int n = h.size();
    enum Color { White, Gray, Black };
    std::vector<Color> color(size_t(n), White);
    std::vector<int> black;
    // 黑不指白检查：对每个黑对象，引用目标不得为白
    auto checkInvariant = [&]() {
        for (int b : black)
            for (int t : h.o(b).slot)
                if (t >= 0 && color[size_t(t)] == White) return false;
        return true;
    };
    // 第 0 步：根染灰（初始化步）
    {
        TriColorStep s;
        for (int root : h.roots()) color[size_t(root)] = Gray;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == Gray) s.gray.push_back(i);
        s.picked = -1;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == White) s.white.push_back(i);
        s.invariantHeld = true;  // 尚无黑对象
        r.steps.push_back(s);
    }
    // 主循环：每步取一个灰对象变黑、其白子染灰
    for (;;) {
        int pick = -1;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == Gray) { pick = i; break; }
        if (pick < 0) break;
        TriColorStep s;
        color[size_t(pick)] = Black;
        black.push_back(pick);
        for (int t : h.o(pick).slot)
            if (t >= 0 && color[size_t(t)] == White) color[size_t(t)] = Gray;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == Gray) s.gray.push_back(i);
        s.picked = pick;
        for (int i = 0; i < n; ++i)
            if (color[size_t(i)] == White) s.white.push_back(i);
        s.invariantHeld = checkInvariant();
        if (!s.invariantHeld) ++r.invariantViolations;
        r.steps.push_back(s);
    }
    for (int i = 0; i < n; ++i)
        if (color[size_t(i)] == White) r.finalWhite.push_back(i);
    return r;
}

// ---------- 补二：弱引用与字符串池（匠书 §26.4） ----------
WeakPoolReport weakPoolDemo(Heap &h, const std::vector<std::string> &poolNames) {
    WeakPoolReport r;
    r.pooledBefore = static_cast<int>(poolNames.size());
    // 标记（只从根出发——池不在根集）
    std::vector<char> alive(size_t(h.size()), 0);
    std::vector<int> work;
    for (int root : h.roots()) { alive[size_t(root)] = 1; work.push_back(root); }
    while (!work.empty()) {
        int cur = work.back(); work.pop_back();
        for (int t : h.o(cur).slot)
            if (t >= 0 && !alive[size_t(t)]) { alive[size_t(t)] = 1; work.push_back(t); }
    }
    // 弱表清除：池中名字对应的对象若死，从池摘除（名字匹配演示堆对象）
    std::set<std::string> poolSet(poolNames.begin(), poolNames.end());
    for (int i = 0; i < h.size(); ++i) {
        if (!alive[size_t(i)] && poolSet.count(h.o(i).name))
            r.evicted.push_back(h.o(i).name);
    }
    std::sort(r.evicted.begin(), r.evicted.end());
    r.pooledAfter = r.pooledBefore - static_cast<int>(r.evicted.size());
    int dead = 0;
    for (int i = 0; i < h.size(); ++i)
        if (!alive[size_t(i)]) ++dead;
    r.freedObjects = dead;
    // 若池当强根：死串全被误保活
    int rescued = 0;
    for (int i = 0; i < h.size(); ++i)
        if (!alive[size_t(i)] && poolSet.count(h.o(i).name)) ++rescued;
    r.leakWouldHappenIfStrong = rescued;
    return r;
}

// ---------- 补三：LISP2 标记压紧（匠书 §26 练习引申） ----------
Lisp2Report lisp2(Heap &h) {
    Lisp2Report r;
    int n = h.size();
    // 标记
    std::vector<char> alive(size_t(n), 0);
    std::vector<int> work;
    for (int root : h.roots()) { alive[size_t(root)] = 1; work.push_back(root); }
    while (!work.empty()) {
        int cur = work.back(); work.pop_back();
        for (int t : h.o(cur).slot)
            if (t >= 0 && !alive[size_t(t)]) { alive[size_t(t)] = 1; work.push_back(t); }
    }
    // 第一遍：first（写指针）扫滑道，给活对象按地址升序派新址
    std::map<int, int> addr;   // 旧编号 → 新编号
    int first = 0;
    for (int i = 0; i < n; ++i)
        if (alive[size_t(i)]) addr[i] = first++;
    // 第二遍：last（读指针）改写引用——所有活对象的槽指向新址
    std::vector<std::pair<int, std::vector<int>>> layout;
    for (int i = 0; i < n; ++i) {
        if (!alive[size_t(i)]) continue;
        std::vector<int> slots = h.o(i).slot;
        for (int &t : slots)
            if (t >= 0) t = addr.at(t);
        layout.push_back({addr.at(i), slots});
    }
    // 根与引用全部改写后重排完成；数洞（含尾块）
    int holes = 1;  // 尾块
    char prevDead = 1;
    for (int i = 0; i < n; ++i) {
        if (alive[size_t(i)]) { prevDead = 0; }
        else {
            if (!prevDead) ++holes;
            prevDead = 1;
        }
    }
    r.holesBefore = holes;
    r.holesAfter = 1;  // 压紧后：活对象前缀 + 一个尾大块
    r.moved = addr;
    r.newLayout = layout;
    return r;
}

}  // namespace tip
