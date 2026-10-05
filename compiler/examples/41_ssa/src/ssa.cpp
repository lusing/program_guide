// file: src/ssa.cpp
// 第 41 章配套：SSA 构造与解释实现。
#include "ssa.hpp"

#include <cctype>
#include <deque>
#include <functional>
#include <sstream>
#include <stdexcept>

namespace tip {

namespace {
bool isNumS(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarS(const std::string &s) { return !s.empty() && !isNumS(s); }
bool defInstrS(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

std::vector<std::set<int>> dominanceFrontiers(const std::vector<std::vector<int>> &adj,
                                              const DomInfo &di,
                                              const std::vector<std::set<int>> &preds) {
    size_t n = adj.size();
    std::vector<std::set<int>> df(n);
    // CHK：只看汇合点（前驱 ≥ 2）。runner 从每个前驱沿 idom 上行，
    // 直到碰到 idom[c]——沿途每站都把 c 记入 DF。
    for (size_t c = 0; c < n; ++c) {
        if (preds[c].size() < 2) continue;
        for (int p : preds[c]) {
            int runner = p;
            while (runner >= 0 && runner != di.idom[c]) {
                df[runner].insert(static_cast<int>(c));
                runner = di.idom[runner];
            }
        }
    }
    return df;
}

std::string show(const SsaInst &q) {
    std::ostringstream os;
    if (!q.phiArgs.empty()) {
        os << q.dst << " = phi(";
        for (size_t k = 0; k < q.phiArgs.size(); ++k)
            os << (k ? ", " : "") << q.phiArgs[k];
        os << ")";
        return os.str();
    }
    switch (q.op) {
    case TOp::Copy:   os << q.dst << " = " << q.a; break;
    case TOp::Add:    os << q.dst << " = " << q.a << " + " << q.b; break;
    case TOp::Sub:    os << q.dst << " = " << q.a << " - " << q.b; break;
    case TOp::Mul:    os << q.dst << " = " << q.a << " * " << q.b; break;
    case TOp::Div:    os << q.dst << " = " << q.a << " / " << q.b; break;
    case TOp::Gt:     os << q.dst << " = " << q.a << " > " << q.b; break;
    case TOp::Eq:     os << q.dst << " = " << q.a << " == " << q.b; break;
    case TOp::Output: os << "output " << q.a; break;
    case TOp::Ret:    os << "return " << q.a; break;
    case TOp::Goto:   os << "goto B" << q.target; break;
    case TOp::IfGt:   os << "if " << q.a << " > " << q.b << " goto B" << q.target; break;
    case TOp::IfEq:   os << "if " << q.a << " == " << q.b << " goto B" << q.target; break;
    case TOp::Input:  os << q.dst << " = input"; break;
    }
    return os.str();
}

SsaProgram buildSsa(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                    bool &singleDefOk) {
    size_t n = blocks.size();
    // 块邻接与前驱（定序）
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    std::vector<std::vector<int>> preds(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : adj[b]) preds[s].push_back(static_cast<int>(b));

    DomInfo di = dominators(adj);
    auto predsSet = predsOf(adj);
    std::vector<std::set<int>> df = dominanceFrontiers(adj, di, predsSet);

    // ---------- φ 插入 ----------
    // 变量 → 定值块集合；iterated DF 的不动点；φ 挂块头。
    std::map<std::string, std::set<int>> defBlocks;
    std::set<std::string> vars;
    for (const auto &q : code) {
        if (isVarS(q.dst)) vars.insert(q.dst);
        if (isVarS(q.a)) vars.insert(q.a);
        if (isVarS(q.b)) vars.insert(q.b);
    }
    for (int i = 0; i < static_cast<int>(code.size()); ++i)
        if (defInstrS(code[i]) && isVarS(code[i].dst))
            for (size_t b = 0; b < n; ++b)
                if (i >= blocks[b].begin && i < blocks[b].end)
                    defBlocks[code[i].dst].insert(static_cast<int>(b));
    std::map<std::pair<int, std::string>, bool> hasPhi;   // (块, 变量)
    for (const auto &v : vars) {
        std::deque<int> work(defBlocks[v].begin(), defBlocks[v].end());
        std::set<int> enqueued(work.begin(), work.end());
        while (!work.empty()) {
            int b = work.front();
            work.pop_front();
            for (int c : df[b]) {
                if (!hasPhi[{c, v}]) {
                    hasPhi[{c, v}] = true;
                    if (!enqueued.count(c)) {
                        enqueued.insert(c);
                        work.push_back(c);   // φ 本身是新定值，其 DF 也要传播
                    }
                }
            }
        }
    }

    // ---------- 改名（支配树先序 + 版本栈） ----------
    std::map<std::string, int> counter;          // 变量 → 下一版本号
    std::map<std::string, std::vector<std::string>> stack;   // 变量 → 版本名栈
    auto freshName = [&](const std::string &v) {
        int k = counter[v]++;
        std::string name = v + std::to_string(k);
        stack[v].push_back(name);
        return name;
    };
    auto curName = [&](const std::string &v) -> std::string {
        auto it = stack.find(v);
        if (it == stack.end() || it->second.empty()) return v + "u";   // u = 未定义（⊥）
        return it->second.back();
    };
    SsaProgram out;
    out.blocks.resize(n);
    out.preds = preds;

    // 先给每块的 φ 占位（目标名先定，实参改名时回填）
    std::map<std::pair<int, std::string>, size_t> phiSlot;
    for (size_t b = 0; b < n; ++b)
        for (const auto &v : vars)
            if (hasPhi[{static_cast<int>(b), v}]) {
                SsaInst phi;
                phi.dst = v + "#phi";   // 临时占位，改名时替换
                out.blocks[b].body.push_back(phi);
                phiSlot[{static_cast<int>(b), v}] = out.blocks[b].body.size() - 1;
            }

    std::function<void(int)> renameBlock = [&](int b) {
        std::vector<std::string> pushed;   // 本块压栈的名字（离开时弹出）
        // φ 目标先改名（φ 是本块第一条“定值”）
        for (const auto &v : vars)
            if (hasPhi[{b, v}]) {
                size_t slot = phiSlot.at({b, v});
                out.blocks[b].body[slot].dst = freshName(v);
                pushed.push_back(v);
            }
        auto renameUse = [&](std::string &x) {
            if (isVarS(x)) x = curName(x);
        };
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            SsaInst si;
            si.op = code[i].op;
            si.a = code[i].a;
            si.b = code[i].b;
            si.dst = code[i].dst;
            si.target = code[i].target;
            renameUse(si.a);
            renameUse(si.b);
            if (defInstrS(code[i]) && isVarS(si.dst)) {
                si.dst = freshName(si.dst);
                pushed.push_back(code[i].dst);
            }
            // 跳转目标换块号
            if (si.op == TOp::Goto || si.op == TOp::IfGt || si.op == TOp::IfEq)
                for (size_t k = 0; k < n; ++k)
                    if (si.target == blocks[k].begin) si.target = static_cast<int>(k);
            out.blocks[b].body.push_back(si);
        }
        // 给后继的 φ 填实参：沿本块在后继前驱表中的位置
        for (int s : adj[b])
            for (const auto &v : vars)
                if (hasPhi[{s, v}]) {
                    size_t slot = phiSlot.at({s, v});
                    size_t pos = 0;
                    for (size_t k = 0; k < preds[s].size(); ++k)
                        if (preds[s][k] == b) { pos = k; break; }
                    while (out.blocks[s].body[slot].phiArgs.size() < preds[s].size())
                        out.blocks[s].body[slot].phiArgs.push_back(v + "u");
                    out.blocks[s].body[slot].phiArgs[pos] = curName(v);
                }
        // 支配树孩子先序递归
        for (int c : di.children[b]) renameBlock(c);
        for (auto it = pushed.rbegin(); it != pushed.rend(); ++it)
            stack[*it].pop_back();
    };
    renameBlock(0);

    // ---------- 单定值自检 ----------
    singleDefOk = true;
    std::map<std::string, int> defs;
    for (const auto &blk : out.blocks)
        for (const auto &inst : blk.body) {
            if (!inst.dst.empty()) defs[inst.dst]++;
            for (const auto &arg : inst.phiArgs)
                if (arg.empty()) singleDefOk = false;
        }
    for (const auto &kv : defs)
        if (kv.second > 1) singleDefOk = false;
    return out;
}

std::vector<int> ssaRun(const SsaProgram &p) {
    std::vector<int> outputs;
    std::map<std::string, int> env;
    auto rd = [&](const std::string &s) -> int {
        if (isNumS(s)) return std::atoi(s.c_str());
        if (!s.empty() && s.back() == 'u')
            return 0;   // 未定值名（改名器的 ⊥ 记号）：按全 0 初值口径（第 70 章同款）
        auto it = env.find(s);
        if (it == env.end()) throw std::runtime_error("SSA 读未定义 " + s);
        return it->second;
    };
    int b = 0;
    int from = -1;
    int guard = 0;
    while (b >= 0 && b < static_cast<int>(p.blocks.size())) {
        if (++guard > 100000) throw std::runtime_error("SSA 解释超步数");
        const SsaBlock &blk = p.blocks[b];
        // φ：并行语义——先取全部实参再赋值（SSA 名字互不相同，顺序亦同，
        // 但按定义写成两段，正文 33.3 讲原因）
        std::vector<std::pair<std::string, int>> phiVals;
        for (const auto &inst : blk.body) {
            if (inst.phiArgs.empty()) continue;
            if (from < 0) continue;   // 入口块没有前驱，φ 不该有实参
            size_t pos = 0;
            for (size_t k = 0; k < p.preds[b].size(); ++k)
                if (p.preds[b][k] == from) { pos = k; break; }
            phiVals.push_back({inst.dst, rd(inst.phiArgs[pos])});
        }
        for (const auto &kv : phiVals) env[kv.first] = kv.second;
        int next = -1;
        int nextFrom = b;
        for (const auto &inst : blk.body) {
            if (!inst.phiArgs.empty()) continue;   // φ 已在入块时并行处理
            switch (inst.op) {
            case TOp::Copy:  env[inst.dst] = rd(inst.a); break;
            case TOp::Add:   env[inst.dst] = rd(inst.a) + rd(inst.b); break;
            case TOp::Sub:   env[inst.dst] = rd(inst.a) - rd(inst.b); break;
            case TOp::Mul:   env[inst.dst] = rd(inst.a) * rd(inst.b); break;
            case TOp::Div:   env[inst.dst] = rd(inst.a) / rd(inst.b); break;
            case TOp::Gt:    env[inst.dst] = rd(inst.a) > rd(inst.b) ? 1 : 0; break;
            case TOp::Eq:    env[inst.dst] = rd(inst.a) == rd(inst.b) ? 1 : 0; break;
            case TOp::Input: throw std::runtime_error("示例程序不含 input");
            case TOp::Output: outputs.push_back(rd(inst.a)); break;
            case TOp::Ret:    return outputs;
            case TOp::Goto:   next = inst.target; break;
            case TOp::IfGt:   next = rd(inst.a) > rd(inst.b) ? inst.target : -1; break;
            case TOp::IfEq:   next = rd(inst.a) == rd(inst.b) ? inst.target : -1; break;
            }
            if (next != -1) break;
        }
        if (next == -1) next = b + 1;
        b = next;
        from = nextFrom;
    }
    return outputs;
}

}  // namespace tip
