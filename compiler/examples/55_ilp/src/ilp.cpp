// file: src/ilp.cpp
// 第 55 章配套：依赖 DAG、关键路径表调度、modulo scheduling。
#include "ilp.hpp"

#include <algorithm>
#include <cctype>
#include <map>
#include <set>
#include <sstream>

namespace tip {

namespace {
bool isNumT(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarT(const std::string &s) { return !s.empty() && !isNumT(s); }
bool pureDefT(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

DepDAG depDag(const std::vector<Quad> &code, const Block &b) {
    DepDAG d;
    d.n = b.end - b.begin;
    d.succ.assign(d.n, {});
    d.pred.assign(d.n, {});
    d.kind.assign(d.n * d.n, "");
    // 最后写 / 先读表
    std::map<std::string, int> lastWrite;
    std::map<std::string, std::set<int>> readsSince;
    auto addEdge = [&](int from, int to, const char *k) {
        std::string key = k;
        if (d.succ[from].insert(to).second) {
            d.pred[to].insert(from);
            d.kind[from * d.n + to] = key;
        }
    };
    for (int i = b.begin; i < b.end; ++i) {
        int u = i - b.begin;
        const Quad &q = code[i];
        // RAW（真依赖）：读过 x 的每条指令依赖 x 的最后写
        for (const std::string *s : {&q.a, &q.b}) {
            if (!isVarT(*s)) continue;
            auto it = lastWrite.find(*s);
            if (it != lastWrite.end()) addEdge(it->second, u, "RAW");
            readsSince[*s].insert(u);
        }
        // WAW：本写依赖 x 的前一个写
        if (pureDefT(q) && isVarT(q.dst)) {
            auto it = lastWrite.find(q.dst);
            if (it != lastWrite.end()) addEdge(it->second, u, "WAW");
            // WAR：x 的后续写在读过它的指令之后——先读后写
            for (int r : readsSince[q.dst])
                if (r != u) addEdge(r, u, "WAR");
            lastWrite[q.dst] = u;
            readsSince[q.dst].clear();
        }
        // 内存（input/output）一律保守串行
        if (q.op == TOp::Input || q.op == TOp::Output || q.op == TOp::Ret)
            for (int j = b.begin; j < i; ++j)
                if (code[j].op == TOp::Input || code[j].op == TOp::Output ||
                    code[j].op == TOp::Ret)
                    addEdge(j - b.begin, u, "MEM");
    }
    // 关键路径（汇入深度）：h(u) = 1 + max h(pred)；无前驱 h=1
    d.height.assign(d.n, 1);
    for (int u = 0; u < d.n; ++u) {
        int best = 0;
        for (int p : d.pred[u]) best = std::max(best, d.height[p]);
        d.height[u] = best + 1;
    }
    return d;
}

Schedule listSchedule(const DepDAG &d, int width) {
    Schedule s;
    s.width = width;
    s.slot.assign(d.n, -1);
    std::set<int> done;
    int guard = 0;
    while (static_cast<int>(done.size()) < d.n) {
        if (++guard > 1000) break;
        std::vector<int> ready;
        for (int u = 0; u < d.n; ++u) {
            if (done.count(u)) continue;
            bool ok = true;
            for (int p : d.pred[u])
                if (!done.count(p)) { ok = false; break; }
            if (ok) ready.push_back(u);
        }
        // 关键路径优先：高度大者先发射
        std::sort(ready.begin(), ready.end(),
                  [&](int a, int b2) { return d.height[a] > d.height[b2]; });
        int fired = 0;
        for (int u : ready) {
            if (fired == width) break;
            s.slot[u] = s.cycles;
            ++fired;
            done.insert(u);
        }
        ++s.cycles;
    }
    s.order.clear();
    s.order.resize(s.cycles);
    for (int u = 0; u < d.n; ++u)
        if (s.slot[u] >= 0) s.order[s.slot[u]].push_back(u);
    return s;
}

// 重放校验：按调度序逐槽发射，确认每条指令发射时其前驱已发射。
bool scheduleReplay(const DepDAG &d, const Schedule &s) {
    std::vector<int> firedAt(d.n, -1);
    for (int c = 0; c < s.cycles; ++c)
        for (int u : s.order[c]) firedAt[u] = c;
    for (int u = 0; u < d.n; ++u)
        if (firedAt[u] < 0) return false;
    for (int u = 0; u < d.n; ++u)
        for (int p : d.pred[u])
            if (firedAt[p] > firedAt[u]) return false;
    return true;
}

ModuloReport moduloSchedule(const std::vector<Quad> &body, const std::string &ctr) {
    ModuloReport r;
    // 识别体形（经临时中转）：t = ctr + c ; ctr = t
    int stepLine = -1;
    for (size_t i = 0; i + 1 < body.size(); ++i)
        if (body[i].op == TOp::Add && body[i].a == ctr &&
            body[i + 1].op == TOp::Copy && body[i + 1].dst == ctr &&
            body[i + 1].a == body[i].dst)
            stepLine = static_cast<int>(i);
    if (stepLine < 0) {
        r.ii = -1;
        return r;
    }
    // 资源下界：每周期 1 运算槽、N-1 条独立工作 → II ≥ 工作量；
    // 递归依赖下界：ctr 链每圈 +1 → 距离 1、延迟 1 → II ≥ 1。
    int work = 0;
    for (const auto &q : body)
        if (pureDefT(q)) ++work;
    r.resourceBound = std::max(1, work - 1);   // 减去步进指令自身
    r.recurrenceBound = 1;
    r.ii = std::max(r.resourceBound, r.recurrenceBound);
    // 展开两圈的时序示意（每 II 一圈）
    std::ostringstream os;
    for (int iter = 0; iter < 2; ++iter)
        for (int c = 0; c < r.ii; ++c)
            os << "t" << (iter * r.ii + c) << " 圈" << iter << " 槽" << c << " ";
    r.unrolled = os.str();
    return r;
}

}  // namespace tip
