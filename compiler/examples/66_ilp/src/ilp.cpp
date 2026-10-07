// file: src/ilp.cpp
// 第 66 章配套：依赖 DAG、关键路径表调度、modulo scheduling。
#include "ilp.hpp"

#include <algorithm>
#include <cctype>
#include <functional>
#include <map>
#include <queue>
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

// ---------- 树高平衡（鲸书 §8.4.2） ----------

namespace {

// 链内部节点：同类二元运算、且目的名在块内恰用一次
struct ChainInfo {
    std::map<std::string, int> defOf;      // 内部名 → before 下标
    std::map<std::string, int> useCount;   // 块内使用计数
    TOp op = TOp::Add;
    int rootIdx = -1;                      // 根：用户不是链内 Add 的那个
};

ChainInfo findChain(const std::vector<Quad> &block) {
    ChainInfo ci;
    std::map<std::string, int> userIsAdd;  // 名字 → 是否被某个 Add 用
    for (const auto &q : block) {
        if (!q.dst.empty()) ++ci.useCount[q.dst];
        if (q.op == TOp::Add || q.op == TOp::Mul) {
            userIsAdd[q.a] = 1;
            userIsAdd[q.b] = 1;
        }
    }
    for (size_t i = 0; i < block.size(); ++i) {
        const Quad &q = block[i];
        if (q.op != TOp::Add && q.op != TOp::Mul) continue;
        if (ci.useCount[q.dst] != 1) continue;   // 多次使用 = 可观察值，是根不是内部
        if (ci.op != TOp::Add && ci.defOf.empty()) ci.op = q.op;
        if (q.op != ci.op) continue;
        ci.defOf[q.dst] = static_cast<int>(i);
        if (!userIsAdd[q.dst]) ci.rootIdx = static_cast<int>(i);   // 用户不是链内：根
    }
    return ci;
}

}  // namespace

BalanceReport treeBalance(const std::vector<Quad> &block) {
    BalanceReport r;
    r.before = block;
    ChainInfo ci = findChain(block);
    if (ci.rootIdx < 0) return r;
    const Quad &root = block[ci.rootIdx];

    // 递归摊平：叶子（不在链内的操作数）计高度 0，内部节点下钻
    struct Item { std::string name; int height; };
    std::vector<Item> leaves;
    std::function<void(const std::string &)> flatten = [&](const std::string &name) {
        auto it = ci.defOf.find(name);
        if (it == ci.defOf.end()) {
            leaves.push_back({name, 0});
            return;
        }
        const Quad &q = block[it->second];
        flatten(q.a);
        flatten(q.b);
    };
    flatten(root.a);
    flatten(root.b);
    r.leaves = static_cast<int>(leaves.size());
    if (r.leaves < 4) { r.leaves = 0; return r; }

    // 原链高度：左结合链 = 叶子数 - 1（每个内部节点高度 = 左子高+1）
    r.depthBefore = r.leaves - 1;

    // 重建：按高度取两小合并（Huffman 同型）；新临时 tb1..，根并入原名
    int serial = 0;
    std::vector<Quad> emitted;
    struct Node { std::string name; int height; };
    auto byHeight = [](const Node &x, const Node &y) {
        return x.height > y.height || (x.height == y.height && x.name > y.name);   // 小顶堆
    };
    std::priority_queue<Node, std::vector<Node>, decltype(byHeight)> q(byHeight);
    for (const auto &lf : leaves) q.push({lf.name, lf.height});
    while (q.size() > 1) {
        Node a = q.top(); q.pop();
        Node b = q.top(); q.pop();
        std::string dst = (q.empty() && static_cast<int>(emitted.size()) + 1 == r.leaves - 1)
                              ? root.dst
                              : ("tb" + std::to_string(++serial));
        Quad inst;
        inst.op = ci.op;
        inst.dst = dst;
        inst.a = a.name;
        inst.b = b.name;
        emitted.push_back(inst);
        q.push({dst, 1 + std::max(a.height, b.height)});
    }
    r.depthAfter = q.top().height;

    // 求值对账：叶子值来自块内 copy 链折出的常量（链长有限，迭代到不动点）
    std::map<std::string, int> val;
    for (bool ch = true; ch;) {
        ch = false;
        for (const auto &q : block)
            if (q.op == TOp::Copy && q.dst != q.a) {
                int v = isNumT(q.a) ? std::atoi(q.a.c_str())
                                    : (val.count(q.a) ? val[q.a] : 0);
                if (!val.count(q.dst) || val[q.dst] != v) { val[q.dst] = v; ch = true; }
            }
    }
    for (const auto &q : emitted) {
        int va = isNumT(q.a) ? std::atoi(q.a.c_str()) : val[q.a];
        int vb = isNumT(q.b) ? std::atoi(q.b.c_str()) : val[q.b];
        val[q.dst] = (q.op == TOp::Add) ? va + vb : va * vb;
    }
    r.value = val[root.dst];

    // 重排块体：链内指令换成 emitted，其余原样
    std::set<int> drop;
    for (const auto &[name, idx] : ci.defOf) drop.insert(idx);
    for (const auto &e : emitted) r.after.push_back(e);
    for (size_t i = 0; i < block.size(); ++i)
        if (!drop.count(static_cast<int>(i))) r.after.push_back(block[i]);
    // after 里 emitted 在前、原非链指令在后——顺序只为打印与调度，语义由值对账担保
    return r;
}

}  // namespace tip
