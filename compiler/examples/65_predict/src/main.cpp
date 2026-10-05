// file: src/main.cpp
// 第 65 章驱动（无参运行，走“简单程序”对账协议）：
//   循环 trace + 分支 trace → 二位预测器逐事件 → 静态启发式 →
//   预取距离推演（两组延迟）→ 对齐消冲突 miss 对比。
#include "predict.hpp"

#include <iostream>

namespace {

// 循环 trace：5 次迭代 = 回边 taken×4 + 出口 not-taken×1，再跑 3 轮循环
std::vector<tip::BranchEvent> loopTrace(int iters, int rounds) {
    std::vector<tip::BranchEvent> t;
    for (int r = 0; r < rounds; ++r)
        for (int i = 0; i < iters; ++i)
            t.push_back({i + 1 < iters, true});
    return t;
}

// 分支 trace：不可预测的 if（数据驱动，taken 交替随机但无规律——用 0101 模拟）
std::vector<tip::BranchEvent> branchTrace(int n) {
    std::vector<tip::BranchEvent> t;
    for (int i = 0; i < n; ++i)
        t.push_back({i % 2 == 0, false});   // 前向：if 的 then
    return t;
}

}  // namespace

int main() {
    auto loop = loopTrace(5, 3);
    auto branch = branchTrace(10);

    std::cout << "== trace ==\n";
    std::cout << "  循环回边（taken×4 + not×1）×3 轮 = " << loop.size() << " 事件\n";
    std::cout << "  前向分支 0101…×10 = " << branch.size() << " 事件\n";

    std::cout << "== 二位饱和预测器（循环）==\n";
    tip::PredictReport p1 = tip::twoBitPredict(loop);
    std::cout << "  状态序列:";
    for (int s : p1.stateLog) std::cout << ' ' << s;
    std::cout << "\n  hits=" << p1.hits << " misses=" << p1.misses
              << " 命中率=" << (p1.total ? 100 * p1.hits / p1.total : 0) << "%\n";

    std::cout << "== 二位饱和预测器（乱序分支）==\n";
    tip::PredictReport p2 = tip::twoBitPredict(branch);
    std::cout << "  状态序列:";
    for (int s : p2.stateLog) std::cout << ' ' << s;
    std::cout << "\n  hits=" << p2.hits << " misses=" << p2.misses
              << " 命中率=" << (p2.total ? 100 * p2.hits / p2.total : 0) << "%\n";

    std::cout << "== 静态启发式（后向 taken / 前向 not）==\n";
    tip::PredictReport s1 = tip::staticHeuristic(loop);
    tip::PredictReport s2 = tip::staticHeuristic(branch);
    std::cout << "  循环: hits=" << s1.hits << " misses=" << s1.misses
              << "（回边全对，出口全错）\n";
    std::cout << "  分支: hits=" << s2.hits << " misses=" << s2.misses
              << "（五五开）\n";

    std::cout << "== 预取距离推演 ==\n";
    tip::PrefetchPlan f1 = tip::prefetchDistance(2, 10, 6);
    std::cout << "  T_cycle=2 T_latency=10 ⇒ d=" << f1.distance << '\n';
    for (const auto &st : f1.timeline)
        std::cout << "    用数@迭代" << st.iter << "（t=" << st.issueIter + f1.distance << "*2="
                  << (st.iter) * f1.tCycle << "） 预取@迭代" << st.issueIter
                  << "（t=" << st.issueAt << "） 到货 t=" << st.arriveAt
                  << " " << st.verdict << '\n';
    tip::PrefetchPlan f2 = tip::prefetchDistance(5, 10, 4);
    std::cout << "  T_cycle=5 T_latency=10 ⇒ d=" << f2.distance
              << "（慢循环：预取更从容）\n";

    std::cout << "== 对齐消冲突（直接映射）==\n";
    // 16 单元数组、行 4、槽 8：B 放在容量 32 之外（基址 32 = 8 行 × 4）
    // ⇒ B 的行与 A 的行映射同槽，同相位互相踢出；pad=4（一行）错开。
    tip::AlignReport ar = tip::alignSim(16, 4, 8, 4);
    std::cout << "  交替访问 A[i]/B[i]，B 基址 32（同相位）: misses=" << ar.baseMisses << '\n';
    std::cout << "  B 基址 36（pad=4 错开）: misses=" << ar.padMisses << '\n';

    std::cout << "== 对账 ==\n";
    bool ok1 = p1.hits > p2.hits;                       // 循环比乱序好预测
    bool ok2 = s1.hits >= 4 * 3;                        // 启发式抓循环回边
    bool ok3 = f1.distance == 5 && f2.distance == 2;    // ⌈⌉ 公式
    bool ok4 = ar.padMisses < ar.baseMisses;            // 错开消冲突
    std::cout << "  循环命中率 > 乱序: " << (ok1 ? "yes" : "NO") << '\n';
    std::cout << "  启发式抓回边: " << (ok2 ? "yes" : "NO") << '\n';
    std::cout << "  距离公式 ⌈10/2⌉=5 ⌈10/5⌉=2: " << (ok3 ? "yes" : "NO") << '\n';
    std::cout << "  对齐 miss 下降: " << (ok4 ? "yes" : "NO") << '\n';
    return (ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
