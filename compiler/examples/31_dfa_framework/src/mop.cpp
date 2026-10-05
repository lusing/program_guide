// file: src/mop.cpp
// 第 31 章配套：MOP 暴力实现——路径枚举 + 逐路径复合 + meet。
#include "mop.hpp"

#include <functional>

namespace tip {

std::vector<FVal> mop(const Instance &inst, const std::vector<Quad> &code,
                      const std::vector<Block> &blocks, int K) {
    size_t n = blocks.size();
    std::vector<FVal> res(n, inst.initTop);
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return k;
        return n;
    };
    if (inst.dir == Dir::Forward) {
        // 前向：MOP 的 out[b] = meet over 路径(entry→b) F_path(边界)。
        std::vector<bool> seen(n, false);
        std::function<void(size_t, const FVal &, int)> dfs =
            [&](size_t b, const FVal &v, int depth) {
                if (depth > K) return;
                FVal out = blockTransfer(inst, code, blocks[b], v);
                if (seen[b]) res[b] = inst.meetFn(res[b], out);
                else { res[b] = out; seen[b] = true; }
                for (int s : blocks[b].succs) {
                    size_t k = blockOf(s);
                    if (k < n) dfs(k, out, depth + 1);
                }
            };
        dfs(0, inst.boundary, 0);
        return res;
    }
    // 后向：MOP 的 in[b] = meet over 路径(b→exit) 逆复合(边界)。
    // 递归式：in[b] = F_b( meet over 后继 s 的 in[s] )，出口/截断处取边界。
    std::function<FVal(size_t, int, std::vector<bool> &)> valIn =
        [&](size_t cur, int depth, std::vector<bool> &onPath) -> FVal {
        FVal out;
        bool first = true;
        if (blocks[cur].succs.empty() || depth >= K) {
            out = inst.boundary;
        } else {
            for (int s : blocks[cur].succs) {
                size_t k = blockOf(s);
                if (k >= n || onPath[k]) continue;   // 环上同块不重入（深度外路径）
                onPath[k] = true;
                FVal sv = valIn(k, depth + 1, onPath);
                onPath[k] = false;
                out = first ? sv : inst.meetFn(out, sv);
                first = false;
            }
            if (first) out = inst.boundary;
        }
        return blockTransfer(inst, code, blocks[cur], out);
    };
    for (size_t b = 0; b < n; ++b) {
        std::vector<bool> onPath(n, false);
        onPath[b] = true;
        res[b] = valIn(b, 0, onPath);
    }
    return res;
}

}  // namespace tip
