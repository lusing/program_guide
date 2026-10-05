// file: src/licm.cpp
// 第 37 章配套：LICM 与归纳变量实现。
#include "licm.hpp"

#include <cctype>
#include <cstdlib>

namespace tip {

namespace {
bool isNumL(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarL(const std::string &s) { return !s.empty() && !isNumL(s); }
bool pureDef(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

LoopInfo loopsOf(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    (void)code;   // 循环结构只看块图
    size_t n = blocks.size();
    LoopInfo li;
    li.adj.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) li.adj[b].push_back(static_cast<int>(k));
    li.di = dominators(li.adj);
    DfsInfo df = dfsClassify(li.adj);
    li.loops = naturalLoops(li.adj, df, li.di);
    return li;
}

std::pair<std::vector<Quad>, int> licm(const std::vector<Quad> &code,
                                       const std::vector<Block> &blocks,
                                       const LoopInfo &li) {
    size_t n = blocks.size();
    auto blockOf = [&](int idx) {
        for (size_t k = 0; k < n; ++k)
            if (idx >= blocks[k].begin && idx < blocks[k].end) return static_cast<int>(k);
        return -1;
    };
    std::vector<bool> removed(code.size(), false);
    int hoisted = 0;
    for (const auto &L : li.loops) {
        // 循环内定值的变量集合 + 循环内指令区间
        std::set<std::string> definedInLoop;
        std::set<int> loopLines;
        for (int b : L.body)
            for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
                loopLines.insert(i);
                if (pureDef(code[i])) definedInLoop.insert(code[i].dst);
            }
        // 循环外的使用（dst 循环外被读 → 保守不提）
        auto usedOutside = [&](const std::string &v) {
            for (int i = 0; i < static_cast<int>(code.size()); ++i) {
                if (loopLines.count(i)) continue;
                const Quad &q = code[i];
                if (q.a == v || q.b == v) return true;
            }
            return false;
        };
        // preheader：header 的非循环前驱（while 模板保证唯一）
        int preheader = -1;
        for (size_t q = 0; q < n; ++q) {
            if (L.body.count(static_cast<int>(q))) continue;
            for (int s : li.adj[q])
                if (s == L.header) { preheader = static_cast<int>(q); break; }
            if (preheader >= 0) break;
        }
        if (preheader < 0) continue;
        // 单遍扫描循环体：满足三条件即标提
        std::vector<int> toHoist;
        for (int i : loopLines) {
            const Quad &q = code[i];
            if (!pureDef(q)) continue;
            bool opOk = true;
            for (const std::string *s : {&q.a, &q.b}) {
                if (!isVarL(*s)) continue;
                if (definedInLoop.count(*s)) { opOk = false; break; }
            }
            if (!opOk) continue;
            int defCount = 0;
            for (int j : loopLines)
                if (pureDef(code[j]) && code[j].dst == q.dst) ++defCount;
            if (defCount != 1) continue;
            if (q.dst[0] != 't' && usedOutside(q.dst)) continue;   // 变量被循环外使用则不提
            toHoist.push_back(i);
        }
        if (toHoist.empty()) continue;
        // preheader 尾（块尾跳转之前）插入；被提指令在原位删除
        int insertAt = blocks[preheader].end;
        for (int k = insertAt - 1; k >= blocks[preheader].begin; --k)
            if (code[k].op == TOp::Goto || code[k].op == TOp::IfGt ||
                code[k].op == TOp::IfEq) {
                insertAt = k;
                break;
            }
        // 行号策略：先收集后统一重排——用稳定重建而非原地搬移
        std::vector<Quad> hoistedQuads;
        for (int i : toHoist) {
            hoistedQuads.push_back(code[i]);
            removed[i] = true;
            ++hoisted;
        }
        (void)insertAt;
        // 重建（两段拼装，目标重贴）：因 preheader 内插入不改变块边界
        // 与任何跳转目标（插入点在块内、目标都指向块首），
        // 这里直接以“先提走再在 preheader 尾补”的方式重排行号。
        std::vector<Quad> rebuilt;
        // 两遍：先算满 oldToNew（含前瞻目标），再重贴跳转目标
        std::vector<int> oldToNew(code.size() + 1, -1);
        {
            int k = 0;
            for (size_t i = 0; i < code.size(); ++i)
                if (!removed[i]) oldToNew[i] = k++;
            oldToNew[code.size()] = k;
            for (size_t i = code.size(); i-- > 0;)
                if (oldToNew[i] == -1) oldToNew[i] = oldToNew[i + 1];
        }
        for (size_t i = 0; i < code.size(); ++i)
            if (!removed[i]) {
                Quad q = code[i];
                if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
                    q.target = oldToNew[q.target];
                rebuilt.push_back(q);
            }
        // preheader 尾 = 块 end 首条保留指令的新位置（preheader 行不会被提走）
        int ph = oldToNew[blocks[preheader].end];
        // 插入点之后的跳转目标整体 +n
        for (auto &q : rebuilt)
            if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
                if (q.target >= ph) q.target += static_cast<int>(hoistedQuads.size());
        rebuilt.insert(rebuilt.begin() + ph, hoistedQuads.begin(), hoistedQuads.end());
        return {rebuilt, hoisted};
    }
    (void)blockOf;
    return {code, 0};
}

std::vector<IndVar> indVars(const std::vector<Quad> &code,
                            const std::vector<Block> &blocks,
                            const NaturalLoop &loop) {
    std::vector<IndVar> out;
    std::set<std::string> defined;
    for (int b : loop.body)
        for (int i = blocks[b].begin; i < blocks[b].end; ++i)
            if (pureDef(code[i])) defined.insert(code[i].dst);
    // 基本归纳变量：TAC 形态是两连“t = i + c ; i = t”（增量经临时中转）。
    // 识别：Add(t, i, c) 且同块随后 Copy(i, t)，且 i 在循环内无其它定值。
    // 常量解析：b 是字面量直接用；是临时则追它的唯一 Copy 定值（t8 = 1 形态）
    auto constOf = [&](const std::string &s) -> int {
        if (isNumL(s)) return std::atoi(s.c_str());
        for (const auto &q : code)
            if (q.op == TOp::Copy && q.dst == s && isNumL(q.a))
                return std::atoi(q.a.c_str());
        return 0;
    };
    auto isConst = [&](const std::string &s) {
        if (isNumL(s)) return true;
        for (const auto &q : code)
            if (q.op == TOp::Copy && q.dst == s && isNumL(q.a)) return true;
        return false;
    };
    for (int b : loop.body)
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            const Quad &q = code[i];
            if (q.op != TOp::Add && q.op != TOp::Sub) continue;
            if (!isConst(q.b)) continue;
            if (q.a.empty() || q.a[0] == 't') continue;   // 左操作数应是变量
            // 找紧随的 i = t
            bool chained = false;
            for (int j = i + 1; j < blocks[b].end; ++j)
                if (code[j].op == TOp::Copy && code[j].dst == q.a && code[j].a == q.dst) {
                    chained = true;
                    break;
                }
            if (!chained) continue;
            // i 在循环内恰好一次定值（就是那 Copy）
            int count = 0;
            for (int b2 : loop.body)
                for (int k2 = blocks[b2].begin; k2 < blocks[b2].end; ++k2)
                    if (pureDef(code[k2]) && code[k2].dst == q.a) ++count;
            if (count != 1) continue;
            int c = constOf(q.b);
            if (q.op == TOp::Sub) c = -c;
            out.push_back(IndVar{q.a, i, c});
        }
    return out;
}

}  // namespace tip
