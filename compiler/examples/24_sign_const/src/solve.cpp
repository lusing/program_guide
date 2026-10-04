#include "solve.hpp"

#include <deque>
#include <map>
#include <set>
#include <vector>

namespace tip {

namespace {

std::map<int, std::vector<int>> neighborMap(const FunCfg &f, bool successors) {
    std::map<int, std::vector<int>> r;
    for (const auto &[from, to] : f.edges) {
        if (successors) r[from].push_back(to);
        else r[to].push_back(from);
    }
    return r;
}

}  // namespace

PointEnv solveFixpoint(const Cfg &cfg, const ProgramA &program,
                       const std::vector<MonoEq> &eqs) {
    (void)eqs;
    PointEnv cur;
    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();

        const auto succs = neighborMap(fc, true);
        const auto preds = neighborMap(fc, false);

        // 初始值：除入口边界外全部 ⊥（空环境）。
        std::deque<int> wl{fc.entry};
        std::set<int> in{fc.entry};
        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            in.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            SignEnv nv;
            if (node.kind == CfgNode::Kind::Entry) {
                nv = entryEnv(*decl);  // 边界条件不随前驱变化
            } else {
                SignEnv before;
                auto pit2 = preds.find(p);
                if (pit2 != preds.end())
                    for (int q : pit2->second)
                        if (auto it = cur.find(q); it != cur.end())
                            before = joinEnv(before, it->second);
                nv = transferNode(node, before);
            }

            auto old = cur.find(p);
            if (old == cur.end() || old->second != nv) {
                cur[p] = nv;  // 单调框架保证 nv ⊒ 旧值
                auto sit = succs.find(p);
                if (sit != succs.end())
                    for (int s : sit->second)
                        if (!in.count(s)) {
                            wl.push_back(s);
                            in.insert(s);
                        }
            }
        }
    }
    return cur;
}

}  // namespace tip
