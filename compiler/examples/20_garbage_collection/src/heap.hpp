// file: src/heap.hpp
// 第 20 章配套：模拟堆与三台收集器（引用计数 / 标记清除 / Cheney 复制）。
// 对象 = 名字 + 槽位数（槽存对象编号，-1 空）——刻意最小，
// 让“可达性”成为唯一主角。
#ifndef TIP_HEAP_HPP
#define TIP_HEAP_HPP

#include <map>
#include <string>
#include <vector>

namespace tip {

struct Obj {
    std::string name;
    std::vector<int> slot;   // 槽：指向对象编号；-1 = 空
};

class Heap {
public:
    int alloc(const std::string &name, int nslots);
    void set(int obj, int slot, int target);
    const Obj &o(int id) const { return objs_[id]; }
    int size() const { return static_cast<int>(objs_.size()); }
    const std::vector<int> &roots() const { return roots_; }
    void addRoot(int id) { roots_.push_back(id); }
    void dropRoot(int id);
    // 重新加载内置演示图（供三种收集器各自从同一初始状态出发）
    static Heap demo();

private:
    std::vector<Obj> objs_;
    std::vector<int> roots_;
};

// ---------- 收集器一：引用计数（紫龙 7.5.3） ----------
// 计数按“当前堆+根的引用”推演；报告存活计数与它漏掉的环。
struct RefCountReport {
    std::map<int, int> count;        // 对象 → 入度计数（按根+堆边计算）
    std::vector<int> nonZeroButUnreachable;
};

RefCountReport refCount(const Heap &h);

// ---------- 收集器二：标记清除（紫龙 Algorithm 7.12） ----------
struct MarkSweepReport {
    std::vector<int> survived, freed;
};

MarkSweepReport markSweep(Heap &h);

// ---------- 收集器三：Cheney 半空间复制（紫龙 7.6.5） ----------
struct CheneyReport {
    std::vector<int> copyOrder;         // 拷贝次序（BFS）
    std::map<int, int> forwarding;      // 旧编号 → 新编号
    std::vector<std::pair<int, std::vector<int>>> newLayout;   // 新堆
};

CheneyReport cheney(const Heap &h);

// ---------- 补一（匠书 §26.3）：三色抽象与三色不变式 ----------
// 白 = 未访问；灰 = 自身已访问、子节点未扫完；黑 = 自身与子节点全扫完。
// 不变式：黑不指白（任何黑对象的引用目标不为白）——增量收集
// （并发标记）的正确性根基：只要不变式保持，随时暂停都不丢活对象。
struct TriColorStep {
    std::vector<int> gray;   // 本步前灰集
    int picked;              // 本步变黑的对象（-1 = 本步只初始化/收尾）
    std::vector<int> white;  // 本步后白集
    bool invariantHeld;      // 本步后"黑不指白"是否仍成立
};

struct TriColorReport {
    std::vector<TriColorStep> steps;   // 每步快照（含初始化步）
    std::vector<int> finalWhite;       // 终态白集 = 垃圾（与 markSweep 一致）
    int invariantViolations;           // 全程违反次数（演示里应为 0）
};

TriColorReport triColor(const Heap &h);

// ---------- 补二（匠书 §26.4）：弱引用与字符串池 ----------
// 驻留池是缓存不是语义：GC 的根集不含池，标记后清扫前清弱表——
// 死串从池中摘除（下次 intern 重建即可，行为不变）。
struct WeakPoolReport {
    int pooledBefore;            // 回收前池大小
    std::vector<std::string> evicted;  // 被摘除的死串（按名字序）
    int pooledAfter;             // 回收后池大小
    int freedObjects;            // 本次回收的对象数（弱表清除前后对照）
    bool leakWouldHappenIfStrong;  // 若池当强根：多少死串会被误保活
};

WeakPoolReport weakPoolDemo(Heap &h, const std::vector<std::string> &poolNames);

// ---------- 补三（匠书 §26 练习引申）：LISP2 标记压紧 ----------
// 三指针滑动：mark 后 first/last/free 一趟归位、改写全部引用。
// 压紧后地址单调、碎片归一——与 Cheney 的"拷贝压紧"对照：
// 原地 vs 搬家、两次遍历 vs 一次 BFS。
struct Lisp2Report {
    std::map<int, int> moved;         // 旧编号 → 新编号（活对象）
    std::vector<std::pair<int, std::vector<int>>> newLayout;
    int holesBefore;                  // 压紧前空闲块数（含尾块）
    int holesAfter;                   // 压紧后空闲块数（应恰 1）
};

Lisp2Report lisp2(Heap &h);

}  // namespace tip

#endif  // TIP_HEAP_HPP
