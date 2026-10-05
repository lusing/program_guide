// file: src/trace.cpp
// 第 18 章配套：跟踪线性化实现（两遍：块级决策 → 按最终位置重贴目标）。
#include "trace.hpp"

#include <map>
#include <set>

namespace tip {

TracePlan buildTraces(const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    TracePlan plan;
    std::vector<bool> marked(n, false);
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    // Algorithm 8.3：队列按块号（确定性）；沿任一未标记后继延伸。
    for (size_t start = 0; start < n; ++start) {
        int b = static_cast<int>(start);
        if (marked[b]) continue;
        std::vector<int> trace;
        while (!marked[b]) {
            marked[b] = true;
            trace.push_back(b);
            int next = -1;
            for (int c : adj[b])
                if (!marked[c]) { next = c; break; }
            if (next < 0) break;
            b = next;
        }
        plan.traces.push_back(trace);
        plan.order.insert(plan.order.end(), trace.begin(), trace.end());
    }
    return plan;
}

LinearResult linearize(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                       const TracePlan &plan) {
    size_t n = blocks.size();
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    auto blockAt = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (blocks[k].begin == idx) return static_cast<int>(k);
        return -1;
    };
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return static_cast<int>(k);
        return -1;
    };
    // 每块的终结符信息（只在块尾一条）
    struct Term {
        bool isGoto = false, isCond = false;
        int trueBlock = -1;    // Goto：目标块；条件：真臂块
        int fallBlock = -1;    // 条件：原直落块（假臂）
    };
    std::vector<Term> term(n);
    for (size_t b = 0; b < n; ++b) {
        const Quad &q = code[blocks[b].end - 1];
        if (q.op == TOp::Goto) {
            term[b].isGoto = true;
            term[b].trueBlock = blockAt(q.target);
        } else if (q.op == TOp::IfGt || q.op == TOp::IfEq) {
            term[b].isCond = true;
            term[b].trueBlock = blockAt(q.target);
            term[b].fallBlock = blockOf(blocks[b].end);
        }
    }
    // 第一遍：块级决策（只看“新序里下一块是谁”，与位置无关）
    enum class Act { Keep, Delete, Flip, Fixup };
    std::vector<Act> act(n, Act::Keep);
    LinearResult res;
    for (size_t oi = 0; oi < plan.order.size(); ++oi) {
        int b = plan.order[oi];
        int next = oi + 1 < plan.order.size() ? plan.order[oi + 1] : -1;
        if (term[b].isGoto) {
            if (term[b].trueBlock == next && next >= 0) {
                act[b] = Act::Delete;
                ++res.gotosDeleted;
            }
        } else if (term[b].isCond) {
            if (term[b].fallBlock == next) {
                act[b] = Act::Keep;            // 假臂恰为下一块
            } else if (term[b].trueBlock == next) {
                act[b] = Act::Flip;            // 真臂是下一块：翻条件跳假臂
                ++res.flips;
            } else {
                act[b] = Act::Fixup;           // 两臂皆不顺直
                ++res.fixups;
            }
        }
    }
    // 第二遍：最终位置表（Delete 短 1、Fixup 长 1）→ 发射并重贴目标
    std::map<int, int> pos;
    int cursor = 0;
    for (int b : plan.order) {
        pos[b] = cursor;
        int len = blocks[b].end - blocks[b].begin;
        if (act[b] == Act::Delete) --len;
        if (act[b] == Act::Fixup) ++len;
        cursor += len;
    }
    auto newTarget = [&](int blk) { return blk >= 0 && pos.count(blk) ? pos[blk] : -1; };
    std::vector<Quad> out;
    for (size_t oi = 0; oi < plan.order.size(); ++oi) {
        int b = plan.order[oi];
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            Quad q = code[i];
            if (i == blocks[b].end - 1) {
                if (act[b] == Act::Delete) continue;
                if (q.op == TOp::Goto) {
                    q.target = newTarget(term[b].trueBlock);
                } else if (q.op == TOp::IfGt || q.op == TOp::IfEq) {
                    if (act[b] == Act::Flip) {
                        q.op = q.op == TOp::IfGt ? TOp::IfLe : TOp::IfNe;
                        q.target = newTarget(term[b].fallBlock);
                    } else {
                        q.target = newTarget(term[b].trueBlock);
                        if (act[b] == Act::Fixup) {
                            out.push_back(q);
                            Quad g{TOp::Goto, "", "", "", newTarget(term[b].fallBlock)};
                            out.push_back(g);
                            continue;
                        }
                    }
                }
            }
            out.push_back(q);
        }
    }
    res.code = std::move(out);
    return res;
}

}  // namespace tip
