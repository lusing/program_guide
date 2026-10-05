// file: src/ilp.hpp
// 第 64 章配套：块内依赖 DAG、关键路径表调度、modulo scheduling 报告。
#ifndef TIP_ILP_HPP
#define TIP_ILP_HPP

#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 依赖 DAG（节点 = 块内指令下标 0..n-1）
struct DepDAG {
    int n = 0;
    std::vector<std::set<int>> succ, pred;
    std::vector<std::string> kind;   // n*n 表："RAW"/"WAW"/"WAR"/"MEM"
    std::vector<int> height;         // 关键路径（汇入深度）
};

DepDAG depDag(const std::vector<Quad> &code, const Block &b);

struct Schedule {
    int width = 1;
    int cycles = 0;
    std::vector<int> slot;                    // 指令 → 发射周期
    std::vector<std::vector<int>> order;      // 周期 → 该周期发射的指令
};

Schedule listSchedule(const DepDAG &d, int width);

// 重放校验：调度序满足全部依赖。
bool scheduleReplay(const DepDAG &d, const Schedule &s);

struct ModuloReport {
    int ii = -1;               // 启动间距（-1 = 未识别出循环体形）
    int resourceBound = 0;
    int recurrenceBound = 0;
    std::string unrolled;
};

ModuloReport moduloSchedule(const std::vector<Quad> &body, const std::string &ctr);

// ---------- 树高平衡（鲸书 §8.4.2） ----------
// 块内同一条交换结合算子链（内部名恰用一次）重建为近似平衡树：
// 叶子进按高度排序的优先队列，反复取两小合并（Huffman 同型）。
// 左结合链 a+b+…+h 高 7 → 平衡树高 3，双发射加法器的周期数随之减半。
struct BalanceReport {
    std::vector<Quad> before, after;       // 重排前后的块体
    int depthBefore = 0, depthAfter = 0;   // 表达式树高
    int value = 0;                         // 表达式值（前后一致的对账证人）
    int leaves = 0;                        // 链的叶子数
};

// 找块内最长的同类二元链并平衡之；没有 ≥4 叶子的链时 leaves=0 表示未命中。
BalanceReport treeBalance(const std::vector<Quad> &block);

}  // namespace tip

#endif  // TIP_ILP_HPP
