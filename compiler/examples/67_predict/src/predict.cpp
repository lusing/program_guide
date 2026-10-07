// file: src/predict.cpp
// 第 67 章配套：二位饱和分支预测器、静态启发式、预取距离推演、
// 缓存对齐消冲突（虎书 §20.3 + §21.2–21.3）。
#include "predict.hpp"

#include <map>

namespace tip {

// ---------- 二位饱和计数器（2-bit saturating counter）----------
// 状态 0..3：0,1 = 预测不跳（not taken），2,3 = 预测跳（taken）。
// taken：+1 封顶 3；not taken：-1 触底 0。预测 = 状态 ≥ 2。
// 语义：连错两次才翻转预测（单次噪声不敏感）。

PredictReport twoBitPredict(const std::vector<BranchEvent> &trace) {
    PredictReport r;
    int state = 0;   // 初始：强不跳
    for (const auto &e : trace) {
        bool predicted = state >= 2;
        if (predicted == e.taken) ++r.hits;
        else ++r.misses;
        // 状态机推进
        if (e.taken) state = state < 3 ? state + 1 : 3;
        else state = state > 0 ? state - 1 : 0;
        r.stateLog.push_back(state);
    }
    r.total = static_cast<int>(trace.size());
    return r;
}

// ---------- 静态启发式：后向跳转预测 taken（循环启发式）----------
// 编译器不需要运行时历史：目标地址在本指令之前 ⇒ 大概率是循环回边 ⇒ 跳。
// 前向（if 的 then）≈ 五五开 ⇒ 预测不跳（顺序流）。
PredictReport staticHeuristic(const std::vector<BranchEvent> &trace) {
    PredictReport r;
    for (const auto &e : trace) {
        bool predicted = e.backward;   // 后向 → taken
        if (predicted == e.taken) ++r.hits;
        else ++r.misses;
    }
    r.total = static_cast<int>(trace.size());
    return r;
}

// ---------- 预取距离推演（虎书 21.3）----------
// 循环每迭代用时 T_cycle 周期、一次 miss 的延迟 T_latency 周期 ⇒
// 提前 d = ⌈T_latency / T_cycle⌉ 个迭代发起预取，数据恰在用时前到达。
// 返回每个 (T_cycle, T_latency) 组合的距离。

PrefetchPlan prefetchDistance(int tCycle, int tLatency, int iterations) {
    PrefetchPlan p;
    p.tCycle = tCycle;
    p.tLatency = tLatency;
    p.distance = (tLatency + tCycle - 1) / tCycle;   // ⌈⌉
    p.iterations = iterations;
    // 时间线：迭代 i 在时刻 i·T_cycle 用数；预取在 (i-d)·T_cycle 发出，
    // 到货 (i-d)·T_cycle + T_latency ≤ i·T_cycle ⟺ d ≥ T_latency/T_cycle ✓。
    for (int i = 0; i < iterations; ++i) {
        int useAt = i * tCycle;
        int issueIter = i - p.distance;
        int issueAt = issueIter * tCycle;
        int arriveAt = issueAt + tLatency;
        p.timeline.push_back({i, issueIter, issueAt, arriveAt,
                              arriveAt <= useAt ? "ok" : "late"});
    }
    return p;
}

// ---------- 缓存对齐消冲突（虎书 21.2）----------
// 直接映射缓存里，两个热数组列若相隔恰为缓存容量的整数倍，
// 互相踢出（冲突 miss）。把数组 B 的基址错开一个缓存行 ⇒ 冲突消失。
AlignReport alignSim(int n, int lineSize, int cacheLines, int pad) {
    AlignReport r;
    r.baseMisses = 0;
    r.padMisses = 0;
    // 访问模式：A[i] 与 B[i] 交替（模板计算风格），行主序逐 i。
    auto sim = [&](int bBase, int &misses) {
        std::map<int, int> tag;
        auto touch = [&](int addr) {
            int line = addr / lineSize;
            int slot = line % cacheLines;
            auto it = tag.find(slot);
            if (it == tag.end() || it->second != line) {
                tag[slot] = line;
                ++misses;
            }
        };
        for (int i = 0; i < n; ++i) {
            touch(i);                    // A[i]（A 基址 0）
            touch(bBase + i);            // B[i]（B 基址 = bBase）
        }
    };
    // 冲突布置：B 放在“恰一个缓存容量”之外（基址 = cacheLines*lineSize）
    // ⇒ B 的行映射到与 A 相同的槽——同相位互相踢出。
    int unalignedBase = cacheLines * lineSize;
    sim(unalignedBase, r.baseMisses);
    // 对齐：B 错开 pad 个单元（pad 取一个缓存行），相位错开、冲突消失
    sim(unalignedBase + pad, r.padMisses);
    return r;
}

}  // namespace tip
