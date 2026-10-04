#include "interval.hpp"

#include <algorithm>
#include <sstream>
#include <vector>

namespace tip {
namespace {

// 端点饱和加/减/乘：越过哨兵一律钳到 ±∞。
int satAdd(long long a, long long b) {
    long long r = a + b;
    if (r > INT_MAX) return INT_MAX;
    if (r < INT_MIN) return INT_MIN;
    return static_cast<int>(r);
}
int satMul(long long a, long long b) {
    long long r = a * b;
    if (r > INT_MAX) return INT_MAX;
    if (r < INT_MIN) return INT_MIN;
    return static_cast<int>(r);
}
// "未知符号"端的保守处理：与 ±∞ 相乘的有限端按同号无穷估计。
int mulLo(int a, int b) {
    if (a == 0 || b == 0) return 0;
    if (a == INT_MIN || b == INT_MIN) return INT_MIN;
    if (a == INT_MAX || b == INT_MAX) return (a > 0) == (b > 0) ? INT_MAX : INT_MIN;
    return satMul(a, b);
}
int mulHi(int a, int b) {
    if (a == 0 || b == 0) return 0;
    if (a == INT_MIN || b == INT_MIN) return (a > 0) == (b > 0) ? INT_MAX : INT_MIN;
    if (a == INT_MAX || b == INT_MAX) return INT_MAX;
    return satMul(a, b);
}

std::string envText(const IvEnv &env, const std::set<std::string> &keys) {
    std::ostringstream out;
    bool first = true;
    for (const std::string &k : keys) {
        if (!first) out << " ";
        out << k << "=" << ivText(env.count(k) ? env.at(k) : Iv{1, 0});
        first = false;
    }
    return out.str();
}

}  // namespace

Lattice<Iv> ivLattice() {
    return Lattice<Iv>{
        Iv{INT_MIN, INT_MAX},  // 顶：全区间（什么信息都没有）
        Iv{1, 0},              // 底：lo>hi 编码 ⊥（不可达）
        [](const Iv &a, const Iv &b) { return a.lo == b.lo && a.hi == b.hi; },
        [](const Iv &a, const Iv &b) {
            if (a.lo > a.hi) return true;   // ⊥ ⊑ 一切
            if (b.lo > b.hi) return false;
            return a.lo >= b.lo && a.hi <= b.hi;  // 区间包含 = 信息更准
        },
        [](const Iv &a, const Iv &b) {
            if (a.lo > a.hi) return b;
            if (b.lo > b.hi) return a;
            return Iv{std::min(a.lo, b.lo), std::max(a.hi, b.hi)};  // 包络
        }};
}

std::string ivText(const Iv &v) {
    if (v.lo > v.hi) return "bottom";
    std::ostringstream out;
    out << "[";
    if (v.lo == INT_MIN)
        out << "-inf";
    else
        out << v.lo;
    out << ",";
    if (v.hi == INT_MAX)
        out << "+inf";
    else
        out << v.hi;
    out << "]";
    return out.str();
}

Iv evalIv(const Expr *e, const IvEnv &env) {
    Lattice<Iv> lat = ivLattice();
    if (const auto *x = dynamic_cast<const IntLit *>(e)) {
        return Iv{x->v, x->v};
    }
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = env.find(x->name);
        if (it == env.end()) return lat.bot();  // 没有区间信息 → ⊥（不可达路径近似）
        return it->second;
    }
    if (dynamic_cast<const InputE *>(e)) {
        return Iv{INT_MIN, INT_MAX};  // 任意整数
    }
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        Iv l = evalIv(x->l.get(), env);
        Iv r = evalIv(x->r.get(), env);
        if (l.lo > l.hi || r.lo > r.hi) return lat.bot();
        // 除法：除数区间含 0 时商可爆掉，保守取全区间；
        // 不含 0 且分子两端有限时按端点组合取截断商的包络。
        if (x->op == BOp::Div) {
            if (l.lo > l.hi || r.lo > r.hi) return lat.bot();
            if (r.lo <= 0 && r.hi >= 0) return Iv{INT_MIN, INT_MAX};
            if (l.lo > INT_MIN && l.hi < INT_MAX) {
                // 除数端点为哨兵 ±∞ 时按真实可表示值参与除法：
                // 有限分子除以 |±2^31| 截断为 0，恰与"商趋于 0"一致。
                long long nums[2] = {l.lo, l.hi};
                long long dens[2] = {r.lo, r.hi};
                int lo = INT_MAX, hi = INT_MIN;
                for (long long n : nums)
                    for (long long d : dens) {
                        long long v = n / d;  // d 非零：区间已排除 0
                        int iv = v > INT_MAX ? INT_MAX
                                            : (v < INT_MIN ? INT_MIN : (int)v);
                        lo = std::min(lo, iv);
                        hi = std::max(hi, iv);
                    }
                return Iv{lo, hi};
            }
            return Iv{INT_MIN, INT_MAX};
        }
        if (x->op == BOp::Add)
            return Iv{satAdd(l.lo, r.lo), satAdd(l.hi, r.hi)};
        if (x->op == BOp::Sub)
            return Iv{satAdd(l.lo, -static_cast<long long>(r.hi)),
                      satAdd(l.hi, -static_cast<long long>(r.lo))};
        if (x->op == BOp::Mul) {
            int los[4] = {mulLo(l.lo, r.lo), mulLo(l.lo, r.hi),
                          mulLo(l.hi, r.lo), mulLo(l.hi, r.hi)};
            int his[4] = {mulHi(l.lo, r.lo), mulHi(l.lo, r.hi),
                          mulHi(l.hi, r.lo), mulHi(l.hi, r.hi)};
            return Iv{*std::min_element(los, los + 4),
                      *std::max_element(his, his + 4)};
        }
        return Iv{INT_MIN, INT_MAX};  // 比较/其余：只给真假信息，这里不精炼
    }
    return Iv{INT_MIN, INT_MAX};
}

NaiveResult runNaiveInterval(const Cfg &cfg, const ProgramA &program,
                             int maxRounds) {
    Lattice<Iv> lat = ivLattice();
    NaiveResult res;

    // 找循环头：第一条 while 语句所在节点（演示程序单函数单循环）。
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes)
            if (dynamic_cast<const WhileS *>(node.stmt) && res.headNode < 0)
                res.headNode = id;

    const FunCfg &fc = cfg.funs[0];
    std::map<int, std::vector<int>> preds;
    for (const auto &[a, b] : fc.edges) preds[b].push_back(a);

    // 声明的变量集合（循环头打印环境用）。
    std::set<std::string> vars(program.funs[0]->vars.begin(),
                               program.funs[0]->vars.end());

    // 朴素迭代：round-robin 按节点号顺序重算每个点，封顶 maxRounds 轮。
    std::map<int, IvEnv> out;
    for (int round = 0; round < maxRounds; ++round) {
        bool changed = false;
        for (const auto &[id, node] : fc.nodes) {
            IvEnv in;
            auto pit = preds.find(id);
            if (pit != preds.end()) {
                for (int q : pit->second) {
                    const IvEnv &qs = out[q];
                    for (const auto &[k, v] : qs)
                        in[k] = lat.join(in.count(k) ? in[k] : lat.bot(), v);
                }
            }
            // entry 边界：参数视为全区间（此处演示程序无参）。
            for (const std::string &p : program.funs[0]->params)
                in[p] = lat.join(in.count(p) ? in[p] : lat.bot(),
                                 Iv{INT_MIN, INT_MAX});

            IvEnv o = in;
            if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
                if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
                    o[t->name] = evalIv(a->value.get(), in);
            if (out.count(id) == 0 || !(out[id] == o)) {
                out[id] = o;
                changed = true;
            }
        }
        res.rounds = round + 1;
        if (res.headNode >= 0) {
            std::ostringstream line;
            line << "iter " << round << ": "
                 << envText(out.count(res.headNode) ? out[res.headNode] : IvEnv{},
                            vars);
            res.trace.push_back(line.str());
        }
        if (!changed) {
            res.converged = true;
            break;
        }
    }
    return res;
}

}  // namespace tip
