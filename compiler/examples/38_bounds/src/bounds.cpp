// file: src/bounds.cpp
// 第 38 章配套：边界检查消除与循环展开（虎书 §18.4–18.5）。
#include "bounds.hpp"


namespace tip {

namespace {
bool pureDefB(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

// TIP 无数组——本章用记录访问 a.f 的 Lower 检查当替身：
// tacgen 里字段访问留待 42 章，所以我们改用 input 前置检查的形态。
// 更直接的教学替身：除零检查。`x = a / b` 前插 `if b == 0 goto fail`
// 与数组 `a[i]` 前插 `if i >= n goto fail` 同构：
// 都由"越界/异常条件"驱动的 guard，都可以用同一套归纳变量推理消除。
// bounds.cpp 的插入器：为每条 Div 生成 guard（确定性编号）。

std::vector<Quad> insertGuards(const std::vector<Quad> &code) {
    // 两遍：先记 Div 位（guard 插在它们前面），再重建——
    // 目标平移量 = 目标位置之前的 guard 数（老纪律：动指令必重贴）。
    std::vector<int> guardBefore(code.size() + 1, 0);
    int g = 0;
    for (size_t i = 0; i < code.size(); ++i) {
        if (code[i].op == TOp::Div) ++g;
        guardBefore[i + 1] = g;
    }
    std::vector<Quad> out;
    for (size_t i = 0; i < code.size(); ++i) {
        if (code[i].op == TOp::Div) {
            Quad guard{TOp::IfEq, "", code[i].b, "0", -1};
            guard.target = -2 - guardBefore[i];   // 负数编码：guard 槽位（待消除/回填）
            out.push_back(guard);
        }
        Quad q = code[i];
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
            q.target += guardBefore[q.target];
        out.push_back(q);
    }
    return out;
}

BoundsResult eliminateGuards(const std::vector<Quad> &guarded,
                             const std::vector<Block> &blocks,
                             const LoopInfo &li) {
    BoundsResult r;
    // 对每个循环：找归纳变量 i（i = i + c，c 常量、循环内唯一定值）
    // 与"分母与 i 的仿射关系"。教学子集：分母就是 i 本身或循环不变量。
    // 消除规则（虎书 18.4 的精神）：
    //   (a) 分母循环不变 ⇒ guard 外提到 preheader（LICM 判据）；
    //   (b) 分母 = 归纳变量 i，且循环条件形如 k > i（i 从初值只增不减）⇒
    //       guard 只需在循环前查一次 i 初值 ≠ 0——若步长 c 满足
    //       "i ≠ 0 后每步 +1 不可能跨回 0"（整数 c=1 单调），全程安全。
    // 本章实现 (a) 与 (b) 的单变量情形；报告两类命中数。
    std::vector<bool> removed(guarded.size(), false);
    r.code = guarded;
    for (const auto &L : li.loops) {
        auto ivs = indVars(guarded, blocks, L);
        std::set<std::string> definedInLoop;
        std::set<int> loopLines;
        for (int b : L.body)
            for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
                loopLines.insert(i);
                if (pureDefB(guarded[i])) definedInLoop.insert(guarded[i].dst);
            }
        for (int i : loopLines) {
            const Quad &q = guarded[i];
            if (q.op != TOp::IfEq || q.target >= -1) continue;   // 只看 guard 槽
            const std::string &denom = q.a;
            if (!definedInLoop.count(denom)) {
                ++r.invariantHoisted;   // 规则 (a)：分母循环不变（此处直接计为可外提/删除）
                removed[i] = true;
            } else {
                // 规则 (b)：分母是归纳变量且循环头条件是 k > i（单调递增）⇒
                // guard 可降级为循环前查一次——教学版直接删除并计数
                for (const auto &iv : ivs)
                    if (iv.var == denom && iv.incr > 0) {
                        ++r.ivEliminated;
                        removed[i] = true;
                    }
            }
        }
    }
    // 未在循环里的 guard（直线 Div）：保留（直线代码没有"多次执行摊薄"收益，
    // 教学口径不消除）——但把负目标回填为程序末尾。
    // 目标回填：guard 槽 -2-k → 末尾 return -1 序列的位置。
    // 简化：所有保留的 guard 目标指向最后一条指令（return 处）。
    std::vector<Quad> rebuilt;
    std::vector<int> oldToNew(guarded.size() + 1, -1);
    for (size_t i = 0; i < guarded.size(); ++i)
        if (!removed[i]) oldToNew[i] = static_cast<int>(rebuilt.size()), rebuilt.push_back(guarded[i]);
    oldToNew[guarded.size()] = static_cast<int>(rebuilt.size());
    for (size_t i = guarded.size(); i-- > 0;)
        if (oldToNew[i] == -1) oldToNew[i] = oldToNew[i + 1];
    for (auto &q : rebuilt) {
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq) {
            if (q.target < -1) q.target = static_cast<int>(rebuilt.size()) - 1;   // → return
            else q.target = oldToNew[q.target];
        }
    }
    // 末尾补 fail 序列：g0 = -1 ; return g0（guard 命中即返回 -1）
    if (r.invariantHoisted + r.ivEliminated <
        static_cast<int>(guarded.size()) - static_cast<int>(rebuilt.size()) + 1) {
        // 仍有 guard 保留时才需要 fail 尾巴
    }
    bool anyGuard = false;
    for (const auto &q : rebuilt)
        if (q.op == TOp::IfEq && q.a != "" && q.b == "0" && q.target == static_cast<int>(rebuilt.size()) - 1)
            anyGuard = true;
    if (anyGuard) {
        rebuilt.push_back(Quad{TOp::Copy, "gf", "-1", "", -1});
        rebuilt.push_back(Quad{TOp::Ret, "", "gf", "", -1});
        // 重贴：guard 目标本就指 rebuilt.size()-1（补尾前的 return 位置）——
        // 补尾后 return 移位，guard 需指 fail 首条。统一再修一轮：
        int failAt = static_cast<int>(rebuilt.size()) - 2;
        for (auto &q : rebuilt)
            if (q.op == TOp::IfEq && q.b == "0" && q.target == failAt + 1)
                q.target = failAt;
    }
    r.code = std::move(rebuilt);
    return r;
}

UnrollResult unroll2(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                     const LoopInfo &li) {
    UnrollResult r;
    (void)code;
    (void)blocks;
    (void)li;
    // 教学口径：循环展开以"概念演示"呈现——37 章的 while 模板把体复制两份、
    // 步长翻倍、循环头改半频，涉及块结构手术；正文 38.5 给完整手工推演，
    // 机器实现留作练习（步骤/输出对账线现成）。
    r.unrolled = 0;
    return r;
}

}  // namespace tip
