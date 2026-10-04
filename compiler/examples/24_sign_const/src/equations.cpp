#include "equations.hpp"

#include <map>
#include <sstream>
#include <vector>

#include "ast.hpp"
#include "pretty.hpp"

namespace tip {
namespace {

std::map<int, std::vector<int>> predecessorMap(const FunCfg &f) {
    std::map<int, std::vector<int>> preds;
    for (const auto &[from, to] : f.edges) preds[to].push_back(from);
    return preds;
}

// join 项的文本：单前驱直接用该点，多前驱写 join(...)。
std::string joinText(const std::vector<int> &deps) {
    if (deps.size() == 1) return "v" + std::to_string(deps[0]);
    std::string r = "join(";
    for (size_t i = 0; i < deps.size(); ++i) {
        if (i) r += ",";
        r += "v" + std::to_string(deps[i]);
    }
    return r + ")";
}

}  // namespace

std::vector<MonoEq> signEquations(const Cfg &cfg) {
    std::vector<MonoEq> all;
    for (const FunCfg &fc : cfg.funs) {
        const auto preds = predecessorMap(fc);
        for (const auto &[id, node] : fc.nodes) {
            MonoEq e;
            e.point = id;
            auto pit = preds.find(id);
            if (pit != preds.end()) e.deps = pit->second;

            std::ostringstream out;
            if (node.kind == CfgNode::Kind::Entry) {
                out << "entry boundary (params = ⊤)";
            } else {
                out << joinText(e.deps);
                if (node.kind == CfgNode::Kind::Assign && node.stmt) {
                    const auto *a = dynamic_cast<const AssignS *>(node.stmt);
                    if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
                        out << "[" << t->name << " := " << printExpr(a->value.get()) << "]";
                }
            }
            e.expr = out.str();
            all.push_back(std::move(e));
        }
    }
    return all;
}

std::string printEquations(const Cfg &cfg, const std::vector<MonoEq> &eqs) {
    std::ostringstream out;
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const MonoEq &e : eqs) {
            bool inFun = false;
            if (const auto it = fc.nodes.find(e.point); it != fc.nodes.end()) inFun = true;
            if (!inFun) continue;
            out << "v" << e.point << " = " << e.expr << '\n';
        }
    }
    return out.str();
}

}  // namespace tip
