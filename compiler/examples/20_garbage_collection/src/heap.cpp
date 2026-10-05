// file: src/heap.cpp
// 第 20 章配套：堆的构造与三台收集器实现。
#include "heap.hpp"

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

}  // namespace tip
