#include "ptranal.hpp"

#include <deque>
#include <map>
#include <set>
#include <sstream>
#include <utility>

namespace tip {
namespace {

// 约束生成：只关心"指针世界"的四类语句/表达式。
struct PtrGen {
    const Bindings &bindings;
    const ProgramA &program;
    PtrConstraints out;
    int allocCount = 0;
    std::string current;
    std::map<std::string, const FunDecl *> decls;

    PtrGen(const Bindings &b, const ProgramA &p) : bindings(b), program(p) {
        for (const auto &f : program.funs) decls[f->name] = f.get();
    }

    std::string loc(const std::string &name) {
        return current == "main" ? name : current + "." + name;
    }

    std::string freshAlloc() { return "L" + std::to_string(++allocCount); }

    void noteVar(const std::string &v) {
        if (!v.empty() && v.rfind("L", 0) != 0 && v.rfind("&", 0) != 0 &&
            v != "null")
            out.vars.insert(v);
    }

    void add(PtrCon::K k, std::string a, std::string b) {
        noteVar(a);
        if (k != PtrCon::New) noteVar(b);
        out.cons.push_back(PtrCon{k, std::move(a), std::move(b)});
    }

    // 直接调用的实参→形参（仅变量实参；其余形态本章程序不使用）。
    void callArgs(const CallE *x, const std::string &callee) {
        const auto &params = decls.at(callee)->params;
        for (size_t i = 0; i < x->args.size() && i < params.size(); ++i)
            if (const auto *v = dynamic_cast<const VarRef *>(x->args[i].get()))
                add(PtrCon::Copy, callee + "." + params[i], loc(v->name));
    }

    void genExprs(const Expr *e) {
        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            if (const auto *fn = dynamic_cast<const VarRef *>(x->callee.get())) {
                auto it = bindings.uses.find(fn);
                if (it != bindings.uses.end() &&
                    it->second->kind == Symbol::Fun)
                    callArgs(x, it->second->name);
            }
            for (const auto &a : x->args) genExprs(a.get());
        } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
            genExprs(x->l.get());
            genExprs(x->r.get());
        } else if (const auto *x = dynamic_cast<const Deref *>(e)) {
            genExprs(x->e.get());
        } else if (const auto *x = dynamic_cast<const AllocE *>(e)) {
            genExprs(x->e.get());
        } else if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            genExprs(x->e.get());
        } else if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            for (const auto &[f, v] : x->fields) genExprs(v.get());
        }
    }

    void genStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            std::string lhs;
            bool through = false;        // 左值是 *p
            if (const auto *t = dynamic_cast<const VarRef *>(x->target.get())) {
                lhs = loc(t->name);
            } else if (const auto *t =
                           dynamic_cast<const Deref *>(x->target.get())) {
                if (const auto *v = dynamic_cast<const VarRef *>(t->e.get())) {
                    lhs = loc(v->name);
                    through = true;
                }
            }

            const Expr *rhs = x->value.get();
            if (!lhs.empty()) {
                if (!through) {
                    if (dynamic_cast<const AllocE *>(rhs)) {
                        std::string site = freshAlloc();
                        out.sites.insert(site);
                        add(PtrCon::New, lhs, site);
                    } else if (const auto *a =
                                   dynamic_cast<const AddrOf *>(rhs)) {
                        std::string site = "&" + a->name;
                        out.sites.insert(site);
                        add(PtrCon::New, lhs, site);
                    } else if (dynamic_cast<const NullE *>(rhs)) {
                        out.sites.insert("null");
                        add(PtrCon::New, lhs, "null");
                    } else if (const auto *v =
                                   dynamic_cast<const VarRef *>(rhs)) {
                        add(PtrCon::Copy, lhs, loc(v->name));
                    } else if (const auto *d =
                                   dynamic_cast<const Deref *>(rhs)) {
                        if (const auto *v =
                                dynamic_cast<const VarRef *>(d->e.get()))
                            add(PtrCon::Load, lhs, loc(v->name));
                    }
                } else if (const auto *v =
                               dynamic_cast<const VarRef *>(rhs)) {
                    add(PtrCon::Store, lhs, loc(v->name));
                }
            }
            genExprs(rhs);   // 子结构中的调用实参仍要接线
        } else if (const auto *x = dynamic_cast<const OutputS *>(s)) {
            genExprs(x->e.get());
        } else if (const auto *x = dynamic_cast<const IfS *>(s)) {
            genExprs(x->cond.get());
            genStmt(x->then.get());
            if (x->els) genStmt(x->els.get());
        } else if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            genExprs(x->cond.get());
            genStmt(x->body.get());
        } else if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) genStmt(st.get());
        }
    }

    PtrConstraints run(const ProgramA &program) {
        for (const auto &f : program.funs) {
            current = f->name;
            genStmt(f->body.get());
        }
        return std::move(out);
    }
};

// ---------------- Andersen：包含式 worklist ----------------
struct Andersen {
    std::map<std::string, std::set<std::string>> pts;
    long rises = 0;

    std::deque<std::pair<std::string, std::string>> wl;   // (变量, 新位置)
    // copyOut[src]：src 每长出位置 s，复制到这些目的（Store 动态加入的
    // 目的可能是抽象堆位置名）。
    std::map<std::string, std::set<std::string>> copyOut;
    std::map<std::string, std::vector<std::string>> loadOf;  // b → a 列表
    std::map<std::string, std::vector<std::string>> storeOf; // a → b 列表

    void add(const std::string &v, const std::string &s) {
        if (pts[v].insert(s).second) {
            ++rises;
            wl.emplace_back(v, s);
        }
    }

    explicit Andersen(const PtrConstraints &c) {
        // 地址链接：&z 与程序变量 z 是同一个抽象位置，双向 copy 边等价。
        // 必须在处理 New 种子前登记，后续传播自动双向到达。
        for (const PtrCon &k : c.cons)
            if (k.k == PtrCon::New && k.b.rfind("&", 0) == 0) {
                std::string z = k.b.substr(1);
                copyOut[z].insert(k.b);
                copyOut[k.b].insert(z);
            }

        for (const PtrCon &k : c.cons) {
            switch (k.k) {
                case PtrCon::New:
                    add(k.a, k.b);
                    break;
                case PtrCon::Copy:
                    copyOut[k.b].insert(k.a);
                    break;
                case PtrCon::Load:
                    loadOf[k.b].push_back(k.a);
                    break;
                case PtrCon::Store:
                    storeOf[k.a].push_back(k.b);
                    break;
            }
        }

        while (!wl.empty()) {
            auto [v, s] = wl.front();
            wl.pop_front();

            auto cit = copyOut.find(v);
            if (cit != copyOut.end())
                for (const std::string &d : cit->second) add(d, s);

            // Load a=*v：v 新指向 s → a ⊇ pts(s)。
            auto lit = loadOf.find(v);
            if (lit != loadOf.end())
                for (const std::string &a : lit->second) {
                    copyOut[s].insert(a);
                    auto sit = pts.find(s);
                    if (sit != pts.end())
                        for (const std::string &t : sit->second) add(a, t);
                }

            // Store *v=b：v 新指向 s → pts(s) ⊇ pts(b)。
            auto sit2 = storeOf.find(v);
            if (sit2 != storeOf.end())
                for (const std::string &b : sit2->second) {
                    copyOut[b].insert(s);
                    auto bit = pts.find(b);
                    if (bit != pts.end())
                        for (const std::string &t : bit->second) add(s, t);
                }
        }
    }
};

// ---------------- Steensgaard：近线性合一 ----------------
struct Steensgaard {
    struct Node {
        int parent;
        std::set<std::string> pts;
        int ptr = -1;      // 代表元字段：指向的代表元节点
    };
    std::vector<Node> nodes;
    std::map<std::string, int> id;
    long unifies = 0;

    int nodeOf(const std::string &name) {
        auto it = id.find(name);
        if (it != id.end()) return it->second;
        int n = static_cast<int>(nodes.size());
        nodes.push_back(Node{n, {}, -1});
        id[name] = n;
        return n;
    }

    int find(int x) {
        while (nodes[x].parent != x) {
            nodes[x].parent = nodes[nodes[x].parent].parent;
            x = nodes[x].parent;
        }
        return x;
    }

    // 确保代表元 rx 有一个指向节点，返回其代表元。
    int ensurePtr(int rx) {
        if (nodes[rx].ptr < 0) {
            int p = static_cast<int>(nodes.size());
            nodes.push_back(Node{p, {}, -1});
            nodes[rx].ptr = p;
        }
        return find(nodes[rx].ptr);
    }

    void unite(int x, int y) {
        int rx = find(x), ry = find(y);
        if (rx == ry) return;
        ++unifies;
        nodes[ry].parent = rx;
        nodes[rx].pts.insert(nodes[ry].pts.begin(), nodes[ry].pts.end());
        if (nodes[rx].ptr >= 0 && nodes[ry].ptr >= 0) {
            unite(nodes[rx].ptr, nodes[ry].ptr);
        } else if (nodes[ry].ptr >= 0) {
            nodes[rx].ptr = nodes[ry].ptr;
        }
        // unite 可能已改变 ptr 字段指向节点的代表关系，重新取代表元。
        if (nodes[rx].ptr >= 0)
            nodes[rx].ptr = find(nodes[rx].ptr);
    }

    explicit Steensgaard(const PtrConstraints &c) {
        // 地址链接：New(a,&z) 让 a 的指向节点就是程序变量 z 的节点，
        // 之后 Load/Store 经 ensurePtr 拿到的正是 z，而非凭空新建。
        for (const PtrCon &k : c.cons)
            if (k.k == PtrCon::New && k.b.rfind("&", 0) == 0) {
                int ra = find(nodeOf(k.a));
                int p = ensurePtr(ra);
                unite(p, nodeOf(k.b.substr(1)));
            }

        for (const PtrCon &k : c.cons) {
            switch (k.k) {
                case PtrCon::New:
                    nodes[find(nodeOf(k.a))].pts.insert(k.b);
                    break;
                case PtrCon::Copy:
                    unite(nodeOf(k.a), nodeOf(k.b));
                    break;
                case PtrCon::Load: {
                    int rb = find(nodeOf(k.b));
                    int p = ensurePtr(rb);
                    unite(nodeOf(k.a), p);
                    break;
                }
                case PtrCon::Store: {
                    int ra = find(nodeOf(k.a));
                    int p = ensurePtr(ra);
                    unite(p, nodeOf(k.b));
                    break;
                }
            }
        }
    }
};

}  // namespace

PtrConstraints buildPtrConstraints(const ProgramA &program,
                                   const Bindings &bindings) {
    PtrGen gen(bindings, program);
    return gen.run(program);
}

PtrResult solvePointer(const PtrConstraints &c) {
    PtrResult r;
    Andersen a(c);
    r.andersen = std::move(a.pts);
    r.rises = a.rises;

    Steensgaard s(c);
    r.unifies = s.unifies;
    for (const auto &[name, id] : s.id) {
        int rep = s.find(id);
        r.varRep[name] = std::to_string(rep);
        r.steensgaard[name] = s.nodes[rep].pts;
    }
    return r;
}

namespace {

void printSet(std::ostringstream &out, const std::set<std::string> &s) {
    out << "{";
    bool first = true;
    for (const std::string &t : s) {
        if (!first) out << ",";
        out << t;
        first = false;
    }
    out << "}";
}

}  // namespace

std::string printPointer(const PtrConstraints &c, const PtrResult &r) {
    std::ostringstream out;
    out << "== pointer analysis: Andersen vs Steensgaard ==\n";
    out << "-- ANDERSEN (inclusion-based) --\n";
    for (const std::string &v : c.vars) {
        out << "  " << v << ": ";
        auto it = r.andersen.find(v);
        printSet(out, it == r.andersen.end() ? std::set<std::string>{}
                                             : it->second);
        out << "\n";
    }
    out << "-- STEENSGAARD (unification-based) --\n";
    for (const std::string &v : c.vars) {
        out << "  " << v << ": ";
        auto it = r.steensgaard.find(v);
        printSet(out, it == r.steensgaard.end() ? std::set<std::string>{}
                                                : it->second);
        out << "\n";
    }
    out << "-- stats --\n";
    out << "andersen rises: " << r.rises
        << ", steensgaard unifications: " << r.unifies << "\n";
    return out.str();
}

}  // namespace tip
