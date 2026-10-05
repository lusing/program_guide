// file: src/apps.cpp
// 第 34 章配套：复制传播与代码提升的实现。
#include "apps.hpp"

#include <cctype>

namespace tip {

namespace {
bool isNumA(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVar(const std::string &s) { return !s.empty() && !isNumA(s); }

}  // namespace

CopyPropResult copyProp(std::vector<Quad> &code, const ReachInfo &ri,
                        const std::vector<Block> &blocks) {
    CopyPropResult r;
    // 第一遍：使用点替换——ud 链唯一且那条定值是 copy x = s 时，用 s 替换 x。
    for (size_t i = 0; i < code.size(); ++i) {
        Quad &q = code[i];
        bool usesA = q.op == TOp::Add || q.op == TOp::Sub || q.op == TOp::Mul ||
                     q.op == TOp::Div || q.op == TOp::Gt || q.op == TOp::Eq ||
                     q.op == TOp::IfGt || q.op == TOp::IfEq ||
                     q.op == TOp::Output || q.op == TOp::Ret;
        bool usesB = q.op == TOp::Add || q.op == TOp::Sub || q.op == TOp::Mul ||
                     q.op == TOp::Div || q.op == TOp::Gt || q.op == TOp::Eq ||
                     q.op == TOp::IfGt || q.op == TOp::IfEq;
        if (q.op == TOp::Copy) usesA = false;   // copy 的源不替换，防 x = x 自喂
        if (usesA && isVar(q.a)) {
            std::set<int> chain = udChain(ri, blocks, static_cast<int>(i), q.a);
            if (chain.size() == 1) {
                const Quad &d = code[*chain.begin()];
                if (d.op == TOp::Copy && isVar(d.a) && d.a != q.a) {
                    q.a = d.a;
                    ++r.replaced;
                }
            }
        }
        if (usesB && isVar(q.b)) {
            std::set<int> chain = udChain(ri, blocks, static_cast<int>(i), q.b);
            if (chain.size() == 1) {
                const Quad &d = code[*chain.begin()];
                if (d.op == TOp::Copy && isVar(d.a) && d.a != q.b) {
                    q.b = d.a;
                    ++r.replaced;
                }
            }
        }
    }
    // 第二遍：删除死 copy。判定用变量级保守口径：
    // 变量→变量 copy，且其左值不再出现在任何操作数里。
    std::set<std::string> usedVars;
    for (const auto &q : code) {
        if (isVar(q.a) && !(q.op == TOp::Copy)) usedVars.insert(q.a);
        if (q.op == TOp::Copy && isVar(q.a)) usedVars.insert(q.a);   // copy 也算“使用”了源
        if (isVar(q.b)) usedVars.insert(q.b);
    }
    std::vector<bool> keep(code.size(), true);
    for (size_t i = 0; i < code.size(); ++i) {
        if (code[i].op == TOp::Copy && isVar(code[i].a) &&
            !usedVars.count(code[i].dst)) {
            keep[i] = false;
            ++r.deleted;
        }
    }
    // 重映射：被删指令的“入跳”落到其后第一条保留指令；哨兵挂新末尾。
    std::vector<int> oldToNew(code.size() + 1, -1);
    int n2 = 0;
    for (size_t i = 0; i < code.size(); ++i)
        if (keep[i]) oldToNew[i] = n2++;
    oldToNew[code.size()] = n2;
    for (size_t i = code.size(); i-- > 0;)
        if (oldToNew[i] == -1) oldToNew[i] = oldToNew[i + 1];
    std::vector<Quad> rebuilt;
    for (size_t i = 0; i < code.size(); ++i)
        if (keep[i]) rebuilt.push_back(code[i]);
    for (auto &q : rebuilt) {
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
            q.target = oldToNew[q.target];
    }
    code = std::move(rebuilt);
    return r;
}

HoistResult hoist(std::vector<Quad> &code, const VeryBusyInfo &vb,
                  const std::vector<Block> &blocks) {
    HoistResult r;
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < blocks.size(); ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return k;
        return blocks.size();
    };
    // 从某条路径出发，跳过“纯跳转块”（if 模板的 goto 弹簧），
    // 找到第一个真实计算指令；返回其下标，找不到返回 -1。
    auto firstComputation = [&](int start) -> int {
        int guard = 0;
        size_t k = blockOf(start);
        while (k < blocks.size() && guard++ < 100) {
            for (int i = blocks[k].begin; i < blocks[k].end; ++i) {
                if (exprKey(code[i]).empty()) continue;
                return i;   // 首个表达式计算（跳转指令 exprKey 为空，天然跳过）
            }
            // 本块全是跳转/非计算：沿唯一后继走
            if (blocks[k].succs.size() != 1) return -1;
            int s = *blocks[k].succs.begin();
            k = blockOf(s);
        }
        return -1;
    };
    for (size_t b = 0; b < blocks.size(); ++b) {
        if (blocks[b].succs.size() != 2) continue;
        // 判据用“块出口”的非常忙（out[B]）：提升点在分支之前、
        // B 内定值之后——正是 out[B] 描述的位置（in[B] 会被 B 自己的
        // 操作数定值合法地排除，见正文 26.5 的讨论）。
        for (const std::string &e : vb.out[b]) {
            std::vector<int> sites;
            bool ok = true;
            for (int s : blocks[b].succs) {
                int site = firstComputation(s);
                if (site < 0 || exprKey(code[site]) != e) { ok = false; break; }
                sites.push_back(site);
            }
            if (!ok || sites.size() != 2) continue;
            int insertAt = blocks[b].end - 1;   // 条件跳转之前
            std::string tH = "th" + std::to_string(r.hoisted + 1);
            Quad nq = code[sites[0]];
            nq.dst = tH;
            code.insert(code.begin() + insertAt, nq);
            // 插入点之后的跳转目标整体 +1；两处使用改写为复制。
            for (auto &q : code)
                if ((q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq) &&
                    q.target > insertAt)
                    ++q.target;
            for (int site : sites)
                code[site + 1] = Quad{TOp::Copy, code[site + 1].dst, tH, "", -1};
            ++r.hoisted;
            r.inserted = r.hoisted;
            r.detail.push_back(e + " -> " + tH);
            return r;   // 结构化模板每次至多一处候选，见正文 26.6 的说明
        }
    }
    return r;
}

}  // namespace tip
