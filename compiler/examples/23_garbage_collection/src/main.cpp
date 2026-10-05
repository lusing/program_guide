// file: src/main.cpp
// 第 23 章驱动（无参运行，走"简单程序"对账协议）：
//   演示图 → 引用计数报告 → 标记清除 → Cheney 复制 → 两行对账
//   →（匠书增量）三色抽象逐步 → 弱引用字符串池 → LISP2 压紧。
#include "heap.hpp"

#include <algorithm>
#include <iostream>
#include <vector>

namespace {

void dumpGraph(const tip::Heap &h) {
    std::cout << "== objects ==\n";
    for (int i = 0; i < h.size(); ++i) {
        std::cout << "  " << i << ": " << h.o(i).name << " [";
        for (size_t k = 0; k < h.o(i).slot.size(); ++k) {
            int t = h.o(i).slot[k];
            std::cout << (k ? " " : "") << (t < 0 ? "-" : h.o(t).name);
        }
        std::cout << "]\n";
    }
    std::cout << "== roots ==\n";
    for (int r : h.roots()) std::cout << "  -> " << h.o(r).name << '\n';
}

}  // namespace

int main() {
    tip::Heap h = tip::Heap::demo();
    dumpGraph(h);

    std::cout << "== reference counting ==\n";
    tip::RefCountReport rc = tip::refCount(h);
    for (int i = 0; i < h.size(); ++i)
        std::cout << "  " << h.o(i).name << ": count=" << rc.count.at(i) << '\n';
    std::cout << "  non-zero but unreachable:";
    for (int i : rc.nonZeroButUnreachable) std::cout << ' ' << h.o(i).name;
    std::cout << "  （环：计数永不为零，泄漏）\n";
    int rcFreed = 0;
    for (int i = 0; i < h.size(); ++i)
        if (rc.count.at(i) == 0) ++rcFreed;
    std::cout << "  rc_freed = " << rcFreed << "（只有 H 计数归零；环上三个永远漏掉）\n";

    std::cout << "== mark-and-sweep ==\n";
    tip::Heap h2 = tip::Heap::demo();
    tip::MarkSweepReport ms = tip::markSweep(h2);
    std::cout << "  survived:";
    for (int i : ms.survived) std::cout << ' ' << h2.o(i).name;
    std::cout << "\n  freed:";
    for (int i : ms.freed) std::cout << ' ' << h2.o(i).name;
    std::cout << "\n  ms_freed = " << ms.freed.size() << '\n';

    std::cout << "== cheney copying ==\n";
    tip::CheneyReport cr = tip::cheney(h);
    std::cout << "  copy order:";
    for (int i : cr.copyOrder) std::cout << ' ' << h.o(i).name;
    std::cout << '\n';
    for (const auto &entry : cr.newLayout) {
        std::cout << "  new" << cr.forwarding.at(entry.first) << " = " << h.o(entry.first).name
                  << " [";
        for (size_t k = 0; k < entry.second.size(); ++k) {
            int t = entry.second[k];
            std::cout << (k ? " " : "") << (t < 0 ? "-" : "new" + std::to_string(t));
        }
        std::cout << "]\n";
    }
    std::cout << "  cheney_copied = " << cr.copyOrder.size() << '\n';

    std::cout << "== 对账 ==\n";
    std::cout << "  survivors(ms) == copied(cheney) : "
              << (ms.survived.size() == cr.copyOrder.size() ? "yes" : "NO") << '\n';
    std::cout << "  rc_freed = " << rcFreed << " < ms_freed = " << ms.freed.size()
              << "：差额正是环\n";

    // ================= 匠书增量（批次四十七） =================
    std::cout << "== tri-color abstraction（§26.3）==\n";
    tip::TriColorReport tc = tip::triColor(h);
    for (size_t k = 0; k < tc.steps.size(); ++k) {
        const tip::TriColorStep &s = tc.steps[k];
        std::cout << "  step " << k << ": gray={";
        for (size_t j = 0; j < s.gray.size(); ++j)
            std::cout << (j ? "," : "") << h.o(s.gray[j]).name;
        std::cout << "} ";
        if (s.picked >= 0)
            std::cout << "blacken=" << h.o(s.picked).name << " ";
        std::cout << "white={";
        for (size_t j = 0; j < s.white.size(); ++j)
            std::cout << (j ? "," : "") << h.o(s.white[j]).name;
        std::cout << "} invariant="
                  << (s.invariantHeld ? "held" : "VIOLATED") << '\n';
    }
    std::cout << "  final white = 终态白集（垃圾）:";
    for (int i : tc.finalWhite) std::cout << ' ' << h.o(i).name;
    std::cout << "\n  violations = " << tc.invariantViolations << "（黑不指白全程保持）\n";
    // 三色终白集应与 markSweep 的 freed 一致
    {
        std::vector<int> a = tc.finalWhite, b = ms.freed;
        std::sort(a.begin(), a.end());
        bool same = a == b;
        std::cout << "  final_white == ms_freed : " << (same ? "yes" : "NO") << '\n';
    }

    std::cout << "== weak references & string pool（§26.4）==\n";
    // 池里放五个名字：两个活（被根可达引用）、三个死——池不是根
    tip::Heap h3 = tip::Heap::demo();
    tip::WeakPoolReport wp = tip::weakPoolDemo(
        h3, {"A", "B", "C", "D", "H"});  // 池含死对象名（C/D/H 由对账确定）
    std::cout << "  pooled_before = " << wp.pooledBefore << '\n';
    std::cout << "  evicted（弱表清除的死串）:";
    for (const auto &n : wp.evicted) std::cout << ' ' << n;
    std::cout << "\n  pooled_after = " << wp.pooledAfter << '\n';
    std::cout << "  freed_objects = " << wp.freedObjects << '\n';
    std::cout << "  若池当强根将误保活 = " << wp.leakWouldHappenIfStrong << " 个（缓存变语义根）\n";

    std::cout << "== LISP2 mark-compact（练习引申）==\n";
    tip::Heap h4 = tip::Heap::demo();
    tip::Lisp2Report l2 = tip::lisp2(h4);
    std::cout << "  moved:";
    for (const auto &old2new : l2.moved)
        std::cout << ' ' << h4.o(old2new.first).name << "->" << old2new.second;
    std::cout << '\n';
    for (const auto &entry : l2.newLayout) {
        std::cout << "  cell" << entry.first << " = [";
        for (size_t k = 0; k < entry.second.size(); ++k) {
            int t = entry.second[k];
            std::cout << (k ? " " : "") << (t < 0 ? "-" : "cell" + std::to_string(t));
        }
        std::cout << "]\n";
    }
    std::cout << "  holes_before = " << l2.holesBefore
              << "（清除视角的碎片）→ holes_after = " << l2.holesAfter << "（活对象成前缀）\n";
    // LISP2 活对象数应与 markSweep survived 一致
    std::cout << "  lisp2_alive == ms_survived : "
              << (l2.moved.size() == ms.survived.size() ? "yes" : "NO") << '\n';
    return 0;
}
