#include "cfa.hpp"

#include <deque>
#include <set>
#include <sstream>
#include <utility>

#include "pretty.hpp"

namespace tip {
namespace {

// 约束生成器：给每个表达式分配一个结果位置，并递归收集约束。
struct ConstraintGen {
    const Bindings &bindings;
    CfaConstraints c;
    int locCounter = 0;
    std::map<std::string, int> siteCounter;
    std::string current;   // 当前所在函数名

    explicit ConstraintGen(const Bindings &b) : bindings(b) {}

    std::string freshLoc() { return "%" + std::to_string(++locCounter); }
    std::string varLoc(const std::string &fun, const std::string &name) {
        return fun + "." + name;
    }

    // 表达式 → 结果位置；沿途发出约束。
    std::string genExpr(const Expr *e) {
        std::string loc = freshLoc();

        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            auto it = bindings.uses.find(x);
            if (it != bindings.uses.end()) {
                const Symbol *sym = it->second;
                if (sym->kind == Symbol::Fun) {
                    // 函数名作为值出现：loc ⊇ {name}。
                    c.edges.emplace_back("val", loc, sym->name);
                } else {
                    // 参数/局部变量：loc ⊇ "fun.name" 的缓存。
                    c.edges.emplace_back(
                        "copy", loc, varLoc(sym->fun->name, sym->name));
                }
            }
        } else if (const auto *x = dynamic_cast<const CallE *>(e)) {
            std::string fn = genExpr(x->callee.get());
            std::vector<std::string> args;
            for (const auto &a : x->args) args.push_back(genExpr(a.get()));

            int n = ++siteCounter[current];
            std::string site = current + ":" + std::to_string(n);
            c.siteText[site] = printExpr(e);
            c.calls.push_back(
                CfaConstraints::CallEdge{site, fn, std::move(args), loc});
        } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
            // 良态 TIP 中算术/比较不产生函数值；子表达式仍须走一遍，
            // 因为其中可能出现函数引用（如作为实参的一部分）。
            genExpr(x->l.get());
            genExpr(x->r.get());
        } else if (const auto *x = dynamic_cast<const Deref *>(e)) {
            genExpr(x->e.get());
        } else if (const auto *x = dynamic_cast<const AllocE *>(e)) {
            genExpr(x->e.get());
        } else if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            genExpr(x->e.get());
        } else if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            for (const auto &[f, v] : x->fields) genExpr(v.get());
        }
        // IntLit / InputE / NullE：无函数值，也无子表达式。
        return loc;
    }

    void genStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            std::string rhs = genExpr(x->value.get());
            // 只有"直接变量赋值"会绑定函数值；字段/指针左值在良态
            // TIP 中不承载函数，忽略（其 RHS 已走过）。
            if (const auto *t = dynamic_cast<const VarRef *>(x->target.get()))
                c.edges.emplace_back("copy", varLoc(current, t->name), rhs);
        } else if (const auto *x = dynamic_cast<const OutputS *>(s)) {
            genExpr(x->e.get());
        } else if (const auto *x = dynamic_cast<const IfS *>(s)) {
            genExpr(x->cond.get());
            genStmt(x->then.get());
            if (x->els) genStmt(x->els.get());
        } else if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            genExpr(x->cond.get());
            genStmt(x->body.get());
        } else if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) genStmt(st.get());
        }
        // 函数的 return 语句由 FunDecl 层统一处理（它要登记 retLoc）。
    }

    CfaConstraints run(const ProgramA &program) {
        for (const auto &f : program.funs) c.lambda.insert(f->name);

        for (const auto &f : program.funs) {
            current = f->name;
            c.params[f->name] = f->params;
            genStmt(f->body.get());
            c.retLoc[f->name] = genExpr(f->ret->e.get());
        }
        return std::move(c);
    }
};

}  // namespace

CfaConstraints buildCfaConstraints(const ProgramA &program,
                                   const Bindings &bindings) {
    ConstraintGen gen(bindings);
    return gen.run(program);
}

CfaResult solve0Cfa(const CfaConstraints &c) {
    CfaResult r;

    // copyOut[src]：src 每长出一个函数，都要复制到这些目的位置。
    std::map<std::string, std::set<std::string>> copyOut;
    // callAt[loc]：监听该位置的调用边索引；位置长出函数即尝试激活。
    std::map<std::string, std::vector<size_t>> callAt;
    // 已激活的（调用边, 函数）配对——同一路径只绑定一次。
    std::set<std::pair<size_t, std::string>> activated;

    std::deque<std::pair<std::string, std::string>> wl;  // (位置, 新函数)

    auto add = [&](const std::string &loc, const std::string &fun) {
        if (r.cache[loc].insert(fun).second) {
            ++r.rises;
            wl.emplace_back(loc, fun);
        }
    };

    // 先登记所有静态边：copy 边建监听关系；val 边直接入队。
    // 顺序无关——copy 监听先就位，val 引发的传播在出队时统一处理。
    for (const auto &[kind, a, b] : c.edges) {
        if (kind == "val") {
            add(a, b);
        } else {  // "copy": a ⊇ b
            copyOut[b].insert(a);
        }
    }
    for (size_t i = 0; i < c.calls.size(); ++i)
        callAt[c.calls[i].calleeLoc].push_back(i);

    while (!wl.empty()) {
        auto [loc, fun] = wl.front();
        wl.pop_front();

        // copy 传播：src 长出 fun → 所有 dst 长出 fun。
        auto cit = copyOut.find(loc);
        if (cit != copyOut.end())
            for (const std::string &dst : cit->second) add(dst, fun);

        // 调用激活：loc 长出 fun → 按命名约定长出参数/返回 copy 边。
        auto kit = callAt.find(loc);
        if (kit == callAt.end()) continue;
        for (size_t ci : kit->second) {
            if (!activated.emplace(ci, fun).second) continue;
            ++r.activations;
            const CfaConstraints::CallEdge &call = c.calls[ci];
            r.sites[call.site].insert(fun);

            // 参数绑定（仅在形参个数范围内）：形参位置 "fun.p" ⊇ 实参位置。
            // 实参可能在激活前就已带着函数值，登记监听后把存量补推一遍。
            auto pit = c.params.find(fun);
            if (pit != c.params.end())
                for (size_t i = 0;
                     i < call.argLocs.size() && i < pit->second.size(); ++i) {
                    const std::string &arg = call.argLocs[i];
                    std::string param = fun + "." + pit->second[i];
                    copyOut[arg].insert(param);
                auto ait = r.cache.find(arg);
                if (ait != r.cache.end())
                    for (const std::string &g : ait->second) add(param, g);
            }

            auto rit = c.retLoc.find(fun);
            if (rit != c.retLoc.end()) {
                copyOut[rit->second].insert(call.resultLoc);
                auto eit = r.cache.find(rit->second);
                if (eit != r.cache.end())
                    for (const std::string &g : eit->second)
                        add(call.resultLoc, g);
            }
        }
    }
    return r;
}

std::string printCfa(const CfaConstraints &c, const CfaResult &r) {
    std::ostringstream out;
    out << "== 0-CFA control-flow analysis ==\n";
    out << "-- resolved call sites --\n";
    for (const auto &call : c.calls) {
        out << "  " << call.site << " " << c.siteText.at(call.site) << ": {";
        auto it = r.sites.find(call.site);
        bool first = true;
        if (it != r.sites.end())
            for (const std::string &f : it->second) {
                if (!first) out << ",";
                out << f;
                first = false;
            }
        out << "}\n";
    }

    out << "-- abstract caches (named locations) --\n";
    for (const auto &[loc, funs] : r.cache) {
        if (loc.rfind("%", 0) == 0 || funs.empty()) continue;
        out << "  " << loc << ": {";
        bool first = true;
        for (const std::string &f : funs) {
            if (!first) out << ",";
            out << f;
            first = false;
        }
        out << "}\n";
    }

    out << "-- stats --\n";
    out << "cache rises: " << r.rises
        << ", call activations: " << r.activations << "\n";
    return out.str();
}

}  // namespace tip
