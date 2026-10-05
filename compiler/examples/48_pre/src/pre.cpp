// file: src/pre.cpp
// 第 48 章配套：部分冗余消除（惰性代码移动，紫龙 9.5 六方程）。
// 六个集合（元素 = 表达式键）：
//   anticipated  后向 must：往后每条路都会在操作数改写前用到；
//   available    前向 must：从入口起每条路都已算好且未失效；
//   earliest     anticipated ∧ ¬available：第一次“必须开始考虑”的位置；
//   postponable  后向 must：从 earliest 起还能继续推迟的位置；
//   latest       推无可推：本块不算就再没机会/自己本来就要算；
//   used         后向 may：某条路上真被用了（决定临时值是否有归宿）。
// 变换：在 latest 处插入 t = e；其余被覆盖的计算点改写为 t 的复制。
#include "pre.hpp"

#include <cctype>
#include <sstream>

namespace tip {

namespace {
bool isNumP(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarP(const std::string &s) { return !s.empty() && !isNumP(s); }
bool sharesOpP(const std::string &key, const std::string &var) {
    if (key.rfind(var + " ", 0) == 0) return true;
    size_t sp = key.rfind(" " + var);
    if (sp != std::string::npos && sp + 1 + var.size() == key.size()) return true;
    return key.find(" " + var + " ") != std::string::npos;
}
}  // namespace

std::string exprKeyP(const Quad &q) {
    const char *op = nullptr;
    switch (q.op) {
    case TOp::Add: op = " + "; break;
    case TOp::Sub: op = " - "; break;
    case TOp::Mul: op = " * "; break;
    case TOp::Div: op = " / "; break;
    case TOp::Gt:  op = " > "; break;
    case TOp::Eq:  op = " == "; break;
    default: return "";
    }
    std::ostringstream os;
    os << q.a << op << q.b;
    return os.str();
}

PreInfo preAnalyse(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    PreInfo p;
    p.code = &code;
    p.blocks = &blocks;
    // 全域：所有表达式键
    FValS universe;
    for (const auto &q : code) {
        std::string e = exprKeyP(q);
        if (!e.empty()) universe.insert(e);
    }
    // 每块 e_gen / e_kill（gen：块内先算后杀的；kill：操作数被改写所杀）
    p.egen.assign(n, {});
    p.ekill.assign(n, {});
    for (size_t b = 0; b < n; ++b) {
        FValS s;
        for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
            const Quad &q = code[i];
            if (isVarP(q.dst)) {
                for (auto it = s.begin(); it != s.end();) {
                    if (sharesOpP(*it, q.dst)) it = s.erase(it);
                    else ++it;
                }
            }
            std::string e = exprKeyP(q);
            if (!e.empty()) s.insert(e);
        }
        p.egen[b] = s;
        FValS k;
        for (int i = blocks[b].begin; i < blocks[b].end; ++i)
            if (isVarP(code[i].dst))
                for (const auto &e : universe)
                    if (sharesOpP(e, code[i].dst)) k.insert(e);
        p.ekill[b] = k;
    }
    // 后继/前驱
    p.adj.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) p.adj[b].push_back(static_cast<int>(k));
    auto succBlocks = [&](size_t b, auto &&f) {
        for (int s : p.adj[b]) f(static_cast<size_t>(s));
    };
    // 前驱按“块号”反推（adj 里存的就是块号，别与 TAC 下标混比）
    std::vector<std::vector<int>> radj(n);
    for (size_t q = 0; q < n; ++q)
        for (int s : p.adj[q]) radj[s].push_back(static_cast<int>(q));
    auto predsOf = [&](size_t b) {
        std::vector<size_t> out;
        for (int q : radj[b]) out.push_back(static_cast<size_t>(q));
        return out;
    };
    auto inter = [](const FValS &a, const FValS &b2) {
        FValS out;
        for (const auto &x : a)
            if (b2.count(x)) out.insert(x);
        return out;
    };
    // ① anticipated（后向 must；出口 ∅）
    p.anticIn.assign(n, {});
    p.anticOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            FValS out;
            bool first = true;
            bool hasSucc = false;
            succBlocks(b, [&](size_t s) {
                hasSucc = true;
                out = first ? p.anticIn[s] : inter(out, p.anticIn[s]);
                first = false;
            });
            (void)hasSucc;
            FValS in = p.egen[b];
            for (const auto &e : out)
                if (!p.ekill[b].count(e)) in.insert(e);
            if (in != p.anticIn[b] || out != p.anticOut[b]) {
                p.anticIn[b] = in;
                p.anticOut[b] = out;
                ch = true;
            }
        }
    }
    // ② available（前向 must；入口 ∅）
    p.availIn.assign(n, {});
    p.availOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = 0; b < n; ++b) {
            FValS in;
            auto ps = predsOf(b);
            if (b == 0) in = FValS{};
            else if (!ps.empty()) {
                bool first = true;
                for (size_t q : ps) {
                    in = first ? p.availOut[q] : inter(in, p.availOut[q]);
                    first = false;
                }
            } else {
                in = universe;   // 不可达块前驱空：交全集（不影响后续）
            }
            FValS out = p.egen[b];
            for (const auto &e : in)
                if (!p.ekill[b].count(e)) out.insert(e);
            if (in != p.availIn[b] || out != p.availOut[b]) {
                p.availIn[b] = in;
                p.availOut[b] = out;
                ch = true;
            }
        }
    }
    // ③ earliest = anticipIn − availIn
    p.earliest.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        for (const auto &e : p.anticIn[b])
            if (!p.availIn[b].count(e)) p.earliest[b].insert(e);
    // ④ postponable（后向 must；出口 ∅）：in = (earliest ∪ out) − egen
    p.postIn.assign(n, {});
    p.postOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            FValS out;
            bool first = true;
            succBlocks(b, [&](size_t s) {
                out = first ? p.postIn[s] : inter(out, p.postIn[s]);
                first = false;
            });
            FValS in = p.earliest[b];
            for (const auto &e : out) in.insert(e);
            for (const auto &e : p.egen[b]) in.erase(e);
            if (in != p.postIn[b] || out != p.postOut[b]) {
                p.postIn[b] = in;
                p.postOut[b] = out;
                ch = true;
            }
        }
    }
    // ⑤ used（后向 may；出口 ∅）：in = egen ∪ (out − ekill)
    p.usedIn.assign(n, {});
    p.usedOut.assign(n, {});
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            FValS out;
            succBlocks(b, [&](size_t s) {
                out.insert(p.usedIn[s].begin(), p.usedIn[s].end());
            });
            FValS in = p.egen[b];
            for (const auto &e : out)
                if (!p.ekill[b].count(e)) in.insert(e);
            if (in != p.usedIn[b] || out != p.usedOut[b]) {
                p.usedIn[b] = in;
                p.usedOut[b] = out;
                ch = true;
            }
        }
    }
    // ⑥ latest = (earliest ∪ postOut) ∩ (egen ∪ ¬anticOut) ∩ usedIn 有用的部分
    p.latest.assign(n, {});
    for (size_t b = 0; b < n; ++b) {
        FValS cand = p.earliest[b];
        for (const auto &e : p.postOut[b]) cand.insert(e);
        for (auto it = cand.begin(); it != cand.end();) {
            bool genOrNoFuture = p.egen[b].count(*it) || !p.anticOut[b].count(*it);
            bool useful = p.usedIn[b].count(*it);
            if (!(genOrNoFuture && useful)) it = cand.erase(it);
            else ++it;
        }
        p.latest[b] = cand;
    }
    return p;
}

// ---------- 变换 ----------
std::pair<std::vector<Quad>, PreStats> preTransform(const std::vector<Quad> &code,
                                                    const std::vector<Block> &blocks,
                                                    const PreInfo &p) {
    // 教学版变换（保真范围：块内完全去重 + 跨块摆位报告）：
    //   对每个键 e 与每个“latest 块”：块内首次计算改写为 pe = e + dst = pe，
    //   块内后续重复计算一律改为复制——同块多次计算收敛为一次（真消除）；
    //   跨块的插入/删除由六方程的 latest 集合给出摆位方案，正文 36.6 详述，
    //   完整实现是练习三的主菜。
    PreStats st;
    size_t n = blocks.size();
    // 决定插入哪些（块, 表达式）：latest 且 egen 命中（本块本来就算）
    std::map<std::pair<size_t, std::string>, std::string> tempOf;
    int tmpN = 0;
    for (size_t b = 0; b < n; ++b)
        for (const auto &e : p.latest[b])
            if (p.egen[b].count(e))
                tempOf[{b, e}] = "pe" + std::to_string(++tmpN);
    // 标注：老行号 → 动作（0 不动 / 1 改写为 te=/复制）
    std::map<int, std::pair<int, std::string>> action;   // 行 → (kind, te)
    for (size_t b = 0; b < n; ++b)
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            std::string e = exprKeyP(code[i]);
            if (e.empty()) continue;
            auto it = tempOf.find({b, e});
            if (it == tempOf.end()) continue;
            bool first = true;
            for (int j = blocks[b].begin; j < i; ++j)
                if (exprKeyP(code[j]) == e) first = false;
            action[i] = {first ? 1 : 2, it->second};
        }
    // 重建：first 位改写 + 插入复制；其余改复制；跳转目标经 oldToNew 重贴
    std::vector<Quad> out;
    std::vector<int> oldToNew(code.size() + 1, -1);
    for (size_t i = 0; i < code.size(); ++i) {
        oldToNew[i] = static_cast<int>(out.size());
        auto it = action.find(static_cast<int>(i));
        if (it == action.end()) {
            out.push_back(code[i]);
            continue;
        }
        if (it->second.first == 1) {
            Quad model = code[i];
            out.push_back(Quad{model.op, it->second.second, model.a, model.b, -1});
            out.push_back(Quad{TOp::Copy, model.dst, it->second.second, "", -1});
            ++st.inserted;
        } else {
            out.push_back(Quad{TOp::Copy, code[i].dst, it->second.second, "", -1});
            ++st.replaced;
        }
    }
    oldToNew[code.size()] = static_cast<int>(out.size());
    for (auto &q : out)
        if (q.op == TOp::Goto || q.op == TOp::IfGt || q.op == TOp::IfEq)
            q.target = oldToNew[q.target];
    return {out, st};
}

}  // namespace tip
