// file: src/osr.cpp
// 第 41 章配套：操作符强度削减的实现
// （常量穿透 → Tarjan SCC 归纳变量识别 → 克隆新链 → LFTR → 根可达 DCE，
// 鲸书 §10.7.2）。
#include "osr.hpp"

#include <map>

namespace tip {

namespace {

bool isLiteral(const std::string &s) {
    if (s.empty()) return false;
    size_t k = (s[0] == '-' && s.size() > 1) ? 1 : 0;
    if (k >= s.size()) return false;
    for (; k < s.size(); ++k)
        if (!isdigit(static_cast<unsigned char>(s[k]))) return false;
    return true;
}

// 名字 → 定义（块号，体内下标）。未定义（字面量/占位）不在表里。
using DefMap = std::map<std::string, std::pair<int, int>>;

DefMap defMapOf(const SsaProgram &p) {
    DefMap d;
    for (size_t b = 0; b < p.blocks.size(); ++b)
        for (size_t i = 0; i < p.blocks[b].body.size(); ++i)
            d[p.blocks[b].body[i].dst] = {static_cast<int>(b), static_cast<int>(i)};
    return d;
}

// 一条指令的操作数（含 φ 实参）
std::vector<std::string> operandsOf(const SsaInst &inst) {
    if (!inst.phiArgs.empty()) return inst.phiArgs;
    std::vector<std::string> out;
    if (!inst.a.empty()) out.push_back(inst.a);
    if (!inst.b.empty()) out.push_back(inst.b);
    return out;
}

void rewriteOperands(SsaInst &inst, const std::map<std::string, std::string> &m) {
    auto f = [&](std::string &x) {
        auto it = m.find(x);
        if (it != m.end()) x = it->second;
    };
    if (!inst.phiArgs.empty()) {
        for (auto &arg : inst.phiArgs) f(arg);
        return;
    }
    f(inst.a);
    f(inst.b);
}

// 常量穿透：TACGen 为每个常量开临时槽（t71 = 4），候选与归纳链看到的是
// 临时名而非字面量。把"x = 字面量"的临时整条穿透（含 φ 实参与 copy 链），
// 让 Mul/Add 的操作数直接是字面量。DVNT 也能做这件事——这里只要直译版。
void materializeLiterals(SsaProgram &p) {
    std::map<std::string, std::string> lit;
    for (bool ch = true; ch;) {
        ch = false;
        for (auto &blk : p.blocks) {
            std::vector<SsaInst> live;
            for (auto inst : blk.body) {
                if (inst.op == TOp::Copy && inst.phiArgs.empty() && isLiteral(inst.a)) {
                    lit[inst.dst] = inst.a;   // 槽位退役，登记字面量
                    ch = true;
                    continue;
                }
                if (inst.op == TOp::Copy && inst.phiArgs.empty() && lit.count(inst.a)) {
                    lit[inst.dst] = lit[inst.a];   // copy 链继续穿透
                    ch = true;
                    continue;
                }
                live.push_back(inst);
            }
            blk.body = live;
        }
    }
    for (auto &blk : p.blocks)
        for (auto &inst : blk.body) rewriteOperands(inst, lit);
}

// 在块内终结符之前插入（无终结符则追加）
void insertBeforeTerm(std::vector<SsaInst> &body, SsaInst inst) {
    size_t at = body.size();
    for (size_t k = body.size(); k-- > 0;)
        if (body[k].op == TOp::Goto || body[k].op == TOp::IfGt || body[k].op == TOp::IfEq) {
            at = k;
            break;
        }
    body.insert(body.begin() + at, std::move(inst));
}

// ---------- Tarjan SCC（鲸书 Figure 10.13 的 DFS 骨架）----------
// 图：名字为节点，边 name → 其操作数的定义名（use 到 def）。
// DFS 弹 SCC 的次序保证：候选遇到时其操作数已分类（鲸书的巧思）。
struct SccFinder {
    const SsaProgram &p;
    const DefMap &def;
    std::map<std::string, int> num, low;
    std::map<std::string, bool> onStack, visited;
    std::vector<std::string> stack;
    std::vector<std::vector<std::string>> sccs;
    int nextNum = 0;

    SccFinder(const SsaProgram &prog, const DefMap &d) : p(prog), def(d) {}

    void run() {
        for (const auto &blk : p.blocks)
            for (const auto &inst : blk.body)
                if (!inst.dst.empty() && !visited.count(inst.dst)) dfs(inst.dst);
    }
    void dfs(const std::string &n) {
        num[n] = low[n] = nextNum++;
        visited[n] = true;
        stack.push_back(n);
        onStack[n] = true;
        auto it = def.find(n);
        if (it != def.end()) {
            const SsaInst &inst = p.blocks[it->second.first].body[it->second.second];
            for (const auto &o : operandsOf(inst)) {
                if (!def.count(o)) continue;   // 字面量/占位：无边
                if (!visited.count(o)) {
                    dfs(o);
                    low[n] = std::min(low[n], low[o]);
                } else if (onStack[o]) {
                    low[n] = std::min(low[n], num[o]);
                }
            }
        }
        if (low[n] == num[n]) {
            std::vector<std::string> scc;
            for (;;) {
                std::string x = stack.back();
                stack.pop_back();
                onStack[x] = false;
                scc.push_back(x);
                if (x == n) break;
            }
            sccs.push_back(std::move(scc));
        }
    }
};

// 归纳变量判定（ClassifyIV 的窄化版）：SCC 成环且每个成员的定义是
// φ / copy / 与字面量的加减（另一操作数在 SCC 内）。
bool classifyIv(const SsaProgram &p, const DefMap &def,
                const std::set<std::string> &scc) {
    if (scc.size() < 2) return false;   // 环至少两个节点（φ → 更新 → φ）
    bool hasPhi = false;
    for (const auto &n : scc) {
        const SsaInst &inst = p.blocks[def.at(n).first].body[def.at(n).second];
        if (!inst.phiArgs.empty()) { hasPhi = true; continue; }
        if (inst.op == TOp::Copy) continue;   // copy 自链内或链外均可
        if (inst.op == TOp::Add || inst.op == TOp::Sub) {
            bool litA = isLiteral(inst.a), litB = isLiteral(inst.b);
            if (litA == litB) return false;               // 必须恰一个字面量
            const std::string &other = litA ? inst.b : inst.a;
            if (!scc.count(other)) return false;          // 另一操作数要在链内
            continue;
        }
        return false;   // 乘/除/比较不是合法更新
    }
    return hasPhi;      // 我们的形态：链上必有 φ（header）
}

}  // namespace

OsrResult runOSR(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds) {
    OsrResult res;
    res.prog = ssa;
    SsaProgram &p = res.prog;

    // ---------- 0) 常量穿透 ----------
    materializeLiterals(p);
    DefMap def = defMapOf(p);

    // ---------- 1) SCC 与归纳变量 ----------
    SccFinder finder(p, def);
    finder.run();
    std::map<std::string, std::string> ivOf;               // 名 → 所属链（φ 名）
    std::map<std::string, std::set<std::string>> chainOf;  // φ 名 → 链成员
    for (const auto &scc : finder.sccs) {
        std::set<std::string> s(scc.begin(), scc.end());
        if (!classifyIv(p, def, s)) continue;
        std::string phi = *s.begin();
        for (const auto &n : s) {
            const SsaInst &inst = p.blocks[def.at(n).first].body[def.at(n).second];
            if (!inst.phiArgs.empty()) { phi = n; break; }
        }
        for (const auto &n : s) ivOf[n] = phi;
        chainOf[phi] = s;
        res.rep.ivs.push_back(phi);
    }

    // ---------- 2) 候选削减：x = iv × c（c 字面量）----------
    // 克隆三部件（Reduce/Apply 的直译）：初值乘一次（循环外）、header 新 φ、
    // latch 在 iv 更新后加 step×c。
    // 遍历用深拷贝快照：插入会落在（可能正是遍历中的）块里，绝不能边走边改。
    std::map<std::string, std::string> rewrite;                  // 旧名 → 新 φ 名
    std::map<std::string, std::pair<std::string, int>> newOf;    // 链 φ → (新 φ 名, c)
    {
        SsaProgram scan = p;
        for (const auto &blk : scan.blocks)
            for (const auto &inst : blk.body) {
                if (inst.op != TOp::Mul || !inst.phiArgs.empty()) continue;
                bool litA = isLiteral(inst.a), litB = isLiteral(inst.b);
                std::string ivName, cstr;
                if (litB && ivOf.count(inst.a) && !litA) { ivName = inst.a; cstr = inst.b; }
                else if (litA && ivOf.count(inst.b) && !litB) { ivName = inst.b; cstr = inst.a; }
                if (ivName.empty()) continue;
                std::string phi = ivOf[ivName];
                const auto &chain = chainOf[phi];
                auto pd = def.at(phi);
                const SsaInst &phiInst = p.blocks[pd.first].body[pd.second];
                // step 与更新位置：链内 Add/Sub 的字面量
                int step = 0;
                auto updDef = def.end();
                for (const auto &n : chain) {
                    const SsaInst &d = p.blocks[def.at(n).first].body[def.at(n).second];
                    if (d.op == TOp::Add || d.op == TOp::Sub) {
                        const std::string &lit = isLiteral(d.a) ? d.a : d.b;
                        step = (d.op == TOp::Sub) ? -std::stoi(lit) : std::stoi(lit);
                        updDef = def.find(n);
                    }
                }
                if (updDef == def.end()) continue;
                int c = std::stoi(cstr);
                std::string newName = inst.dst + "#sr";
                SsaInst init;                       // 初值：循环前乘一次（字面量则折）
                init.dst = newName + "0";
                if (isLiteral(phiInst.phiArgs[0])) {
                    init.op = TOp::Copy;
                    init.a = std::to_string(std::stoi(phiInst.phiArgs[0]) * c);
                } else {
                    init.op = TOp::Mul;
                    init.a = phiInst.phiArgs[0];
                    init.b = cstr;
                }
                SsaInst newPhi;                     // header 新 φ
                newPhi.dst = newName;
                newPhi.phiArgs = {init.dst, newName + "1"};
                SsaInst upd;                        // latch 新步长
                upd.op = TOp::Add;
                upd.dst = newName + "1";
                upd.a = newName;
                upd.b = std::to_string(step * c);
                int initBlock = 0;
                auto initDef = def.find(phiInst.phiArgs[0]);
                if (initDef != def.end()) initBlock = initDef->second.first;
                insertBeforeTerm(p.blocks[initBlock].body, init);
                auto &hb = p.blocks[pd.first].body;
                size_t phiEnd = 0;
                while (phiEnd < hb.size() && !hb[phiEnd].phiArgs.empty()) ++phiEnd;
                hb.insert(hb.begin() + phiEnd, newPhi);
                auto &lb = p.blocks[updDef->second.first].body;
                lb.insert(lb.begin() + updDef->second.second + 1, upd);
                rewrite[inst.dst] = newName;
                newOf[phi] = {newName, c};
                res.rep.reduced.push_back(inst.dst + " × " + cstr + " → " + newName +
                                          "（初值乘一次，步长 " + std::to_string(step * c) + "）");
                def = defMapOf(p);   // 插入挪位，全表重建
            }
        // 删除候选本体（按目的名精确匹配，避免下标漂移）
        for (auto &b : p.blocks) {
            std::vector<SsaInst> live;
            for (const auto &inst : b.body)
                if (rewrite.count(inst.dst) && inst.op == TOp::Mul) continue;
                else live.push_back(inst);
            b.body = live;
        }
    }
    for (auto &blk : p.blocks)
        for (auto &inst : blk.body) rewriteOperands(inst, rewrite);
    def = defMapOf(p);

    // ---------- 3) DCE：根可达标记清扫 ----------
    // 引用计数删不动死环（φ → 更新 → φ 互相引用）；从控制根（output/return/
    // 跳转）反向可达才留。纯定义不在可达集即删。
    // LFTR 的前置条件是"链只剩测试一个链外用途"——保守 φ 等死代码不清，
    // 这个条件永远数不对，所以先清一遍、换完测试再清一遍。
    auto dce = [&]() {
        std::set<std::string> live;
        std::vector<std::string> work;
        for (const auto &blk : p.blocks)
            for (const auto &inst : blk.body) {
                bool root = inst.op == TOp::Output || inst.op == TOp::Ret ||
                            inst.op == TOp::Goto || inst.op == TOp::IfGt ||
                            inst.op == TOp::IfEq;
                if (!root) continue;
                for (const auto &o : operandsOf(inst))
                    if (def.count(o) && !live.count(o)) { live.insert(o); work.push_back(o); }
            }
        while (!work.empty()) {
            std::string n = work.back();
            work.pop_back();
            auto it = def.find(n);
            if (it == def.end()) continue;
            for (const auto &o : operandsOf(p.blocks[it->second.first].body[it->second.second]))
                if (def.count(o) && !live.count(o)) { live.insert(o); work.push_back(o); }
        }
        for (auto &blk : p.blocks) {
            std::vector<SsaInst> keep;
            for (const auto &inst : blk.body) {
                bool ctrl = inst.op == TOp::Output || inst.op == TOp::Ret ||
                            inst.op == TOp::Goto || inst.op == TOp::IfGt ||
                            inst.op == TOp::IfEq;
                if (!ctrl && !inst.dst.empty() && !live.count(inst.dst)) {
                    ++res.rep.deadRemoved;
                    continue;
                }
                keep.push_back(inst);
            }
            blk.body = keep;
        }
        def = defMapOf(p);
    };
    dce();

    // ---------- 4) LFTR：链只剩测试这一个链外用途时，换测试 ----------
    for (const auto &kv : chainOf) {
        const std::string &phi = kv.first;
        const auto &chain = kv.second;
        auto nit = newOf.find(phi);
        if (nit == newOf.end()) continue;   // 本链没有削减产物，无从换测试
        std::vector<std::pair<int, int>> outside;   // (块, 指令) 链外使用点
        for (size_t b = 0; b < p.blocks.size(); ++b)
            for (size_t i = 0; i < p.blocks[b].body.size(); ++i) {
                const SsaInst &inst = p.blocks[b].body[i];
                if (chain.count(inst.dst)) continue;   // 链内定义不算
                bool usesChain = false;
                for (const auto &o : operandsOf(inst))
                    if (chain.count(o)) { usesChain = true; break; }
                if (usesChain) outside.push_back({static_cast<int>(b), static_cast<int>(i)});
            }
        if (outside.size() != 1) continue;
        int ub = outside[0].first, ui = outside[0].second;
        if (p.blocks[ub].body[ui].op != TOp::IfGt &&
            p.blocks[ub].body[ui].op != TOp::IfEq) continue;
        const std::string newName = nit->second.first;
        const int c = nit->second.second;
        // 拷贝取操作数——界侧插乘法可能挪动指令向量，禁止持有引用
        std::string opIv = chain.count(p.blocks[ub].body[ui].a) ? p.blocks[ub].body[ui].a
                                                                : p.blocks[ub].body[ui].b;
        std::string bound = chain.count(p.blocks[ub].body[ui].a) ? p.blocks[ub].body[ui].b
                                                                 : p.blocks[ub].body[ui].a;
        std::string scaled;
        if (isLiteral(bound)) {
            scaled = std::to_string(std::stoi(bound) * c);
        } else {
            std::string lim = bound + "*" + std::to_string(c);
            SsaInst mul;
            mul.op = TOp::Mul;
            mul.dst = lim;
            mul.a = bound;
            mul.b = std::to_string(c);
            auto bd = def.at(bound);
            insertBeforeTerm(p.blocks[bd.first].body, mul);
            def = defMapOf(p);
            scaled = lim;
        }
        res.rep.lftr.push_back(opIv + " 与 " + bound + " 的测试 → " + newName +
                               " 与 " + scaled + "（界 ×" + std::to_string(c) + "）");
        if (p.blocks[ub].body[ui].a == opIv) p.blocks[ub].body[ui].a = newName;
        else p.blocks[ub].body[ui].b = newName;
        if (p.blocks[ub].body[ui].a == bound) p.blocks[ub].body[ui].a = scaled;
        else p.blocks[ub].body[ui].b = scaled;
        def = defMapOf(p);
    }
    // ---------- 5) 再清一遍：换测试后旧链死透 ----------
    dce();

    // ---------- 统计：循环体内乘法 ----------
    // while 形态：header 块 + 其后继块计为一个循环的"体"（不含循环前的前驱块）。
    auto mulCount = [&](const SsaProgram &q, int header) {
        int cnt = 0;
        std::set<int> region{header};
        for (int s : adj[header]) region.insert(s);
        for (int b : region)
            for (const auto &inst : q.blocks[b].body)
                if (inst.op == TOp::Mul && inst.phiArgs.empty()) ++cnt;
        return cnt;
    };
    std::vector<int> headers;
    for (size_t b = 0; b < p.blocks.size(); ++b) {
        bool hasIf = false;
        for (const auto &inst : p.blocks[b].body)
            if (inst.op == TOp::IfGt || inst.op == TOp::IfEq) hasIf = true;
        if (hasIf && preds[b].size() >= 2) headers.push_back(static_cast<int>(b));
    }
    if (headers.size() >= 2) {
        res.rep.mulLoopBefore = mulCount(ssa, headers[0]);
        res.rep.mulLoopAfter = mulCount(p, headers[0]);
        res.rep.mulUntouched = mulCount(p, headers[1]);
    }
    return res;
}

}  // namespace tip
