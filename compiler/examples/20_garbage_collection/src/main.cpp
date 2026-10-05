// file: src/main.cpp
// 第 20 章驱动（无参运行，走“简单程序”对账协议）：
//   演示图 → 引用计数报告 → 标记清除 → Cheney 复制 → 两行对账。
#include "heap.hpp"

#include <iostream>

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
    return 0;
}
