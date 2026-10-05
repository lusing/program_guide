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

}  // namespace tip

#endif  // TIP_HEAP_HPP
