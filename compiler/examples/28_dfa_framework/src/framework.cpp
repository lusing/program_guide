// file: src/framework.cpp
// 第 28 章配套：通用引擎实现。
#include "framework.hpp"

namespace tip {

FVal blockTransfer(const Instance &inst, const std::vector<Quad> &code,
                   const Block &b, FVal v) {
    if (inst.dir == Dir::Forward) {
        for (int i = b.begin; i < b.end; ++i) v = inst.transfer(i, code[i], v);
    } else {
        for (int i = b.end - 1; i >= b.begin; --i) v = inst.transfer(i, code[i], v);
    }
    return v;
}

// 前向：in[B] = meet out[前驱]（首块再 meet 边界）；out[B] = F_B(in[B])
// 后向：out[B] = meet in[后继]（无后继即边界）；in[B] = F_B(out[B])
FrameResult solve(const Instance &inst, const std::vector<Quad> &code,
                  const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    FrameResult r;
    r.in.assign(n, inst.initTop);
    r.out.assign(n, inst.initTop);
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 0; b < n; ++b) {
            if (inst.dir == Dir::Forward) {
                FVal edge;
                bool hasPred = false;
                for (size_t q = 0; q < n; ++q)
                    for (int s : blocks[q].succs)
                        if (s == blocks[b].begin) {
                            edge = hasPred ? inst.meetFn(edge, r.out[q]) : r.out[q];
                            hasPred = true;
                        }
                if (b == 0) edge = hasPred ? inst.meetFn(edge, inst.boundary) : inst.boundary;
                FVal out = blockTransfer(inst, code, blocks[b], edge);
                if (edge != r.in[b] || out != r.out[b]) {
                    r.in[b] = edge;
                    r.out[b] = out;
                    changed = true;
                }
            } else {
                FVal edge;
                bool hasSucc = false;
                for (int s : blocks[b].succs)
                    for (size_t k = 0; k < n; ++k)
                        if (blocks[k].begin == s) {
                            edge = hasSucc ? inst.meetFn(edge, r.in[k]) : r.in[k];
                            hasSucc = true;
                        }
                if (!hasSucc) edge = inst.boundary;
                FVal in = blockTransfer(inst, code, blocks[b], edge);
                if (edge != r.out[b] || in != r.in[b]) {
                    r.out[b] = edge;
                    r.in[b] = in;
                    changed = true;
                }
            }
        }
    }
    return r;
}

}  // namespace tip
