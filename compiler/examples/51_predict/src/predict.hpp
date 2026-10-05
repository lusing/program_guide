// file: src/predict.hpp
// 第 51 章配套：分支预测与存储预取的模拟（虎书 §20.3 + §21.2–21.3）。
#ifndef TIP_PREDICT_HPP
#define TIP_PREDICT_HPP

#include <string>
#include <vector>

namespace tip {

// 分支事件：taken = 实际跳不跳；backward = 目标在本指令之前（回边）
struct BranchEvent {
    bool taken;
    bool backward;
};

struct PredictReport {
    int total = 0;
    int hits = 0;
    int misses = 0;
    std::vector<int> stateLog;   // 二位机逐事件后的状态（0..3）
};

// 二位饱和预测器
PredictReport twoBitPredict(const std::vector<BranchEvent> &trace);

// 静态启发式（后向 taken / 前向 not-taken）
PredictReport staticHeuristic(const std::vector<BranchEvent> &trace);

struct PrefetchStep {
    int iter;         // 用数的迭代号
    int issueIter;    // 发预取的迭代号（iter − distance；< 0 = 开场即发）
    int issueAt;      // 发出时刻（周期）
    int arriveAt;     // 到货时刻
    std::string verdict;   // "ok" / "late"
};

struct PrefetchPlan {
    int tCycle = 1;
    int tLatency = 10;
    int distance = 0;
    int iterations = 0;
    std::vector<PrefetchStep> timeline;
};

// 预取距离推演：d = ⌈T_latency / T_cycle⌉
PrefetchPlan prefetchDistance(int tCycle, int tLatency, int iterations);

struct AlignReport {
    int baseMisses = 0;   // 未错开（同相位冲突）
    int padMisses = 0;    // 错开 pad 后
};

// 交替访问 A[i]/B[i] 的直接映射冲突演示：pad 错开相位消 miss
AlignReport alignSim(int n, int lineSize, int cacheLines, int pad);

}  // namespace tip

#endif  // TIP_PREDICT_HPP
