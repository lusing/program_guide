// file: src/sdd.cpp
// 第 9 章配套：SDD 引擎实现与两个内置属性文法。
#include "sdd.hpp"

#include <cassert>
#include <iostream>
#include <sstream>

namespace tip {

// ---------- 依赖图求值 ----------
bool SddEngine::evaluate(TreeNode *root, std::map<std::string, size_t> &stats,
                          std::vector<AttrRef> *cycle) {
    // 1) 收集所有 (节点, 产生式) 实例，为每条规则登记目标与源
    struct EdgeWaiter {
        TreeNode *host;             // 按该产生式展开的节点
        const SemRule *rule;
    };
    std::vector<EdgeWaiter> waiters;
    std::vector<TreeNode *> order;
    std::vector<TreeNode *> stack = {root};
    while (!stack.empty()) {
        TreeNode *n = stack.back();
        stack.pop_back();
        n->seqId = static_cast<int>(order.size());
        order.push_back(n);
        if (n->prod >= 0) {
            for (const auto &r : g_.prods[n->prod].rules)
                waiters.push_back({n, &r});
        }
        for (auto &c : n->children) stack.push_back(c.get());
    }
    // 2) 建边：源属性实例 → 目标属性实例
    std::map<AttrRef, std::vector<AttrRef>> edgesTo;   // 目标 ← 源
    std::map<AttrRef, int> indeg;
    auto ref = [](TreeNode *host, int childIdx, const std::string &attr,
                  const TreeNode *owner) -> AttrRef {
        TreeNode *t = host;
        if (childIdx > 0) {
            assert(childIdx <= static_cast<int>(host->children.size()));
            t = host->children[childIdx - 1].get();
        }
        (void)owner;
        return {t, attr};
    };
    for (auto &w : waiters) {
        AttrRef dst = ref(w.host, w.rule->targetChild, w.rule->targetAttr, w.host);
        if (!indeg.count(dst)) indeg[dst] = 0;
        for (const auto &src : w.rule->sources) {
            AttrRef s = ref(w.host, src.first, src.second, w.host);
            edgesTo[s].push_back(dst);
            indeg[dst] += 1;
            if (!indeg.count(s)) indeg[s] = 0;
        }
    }
    // 3) Kahn 拓扑排序 + 依序求值
    std::vector<AttrRef> ready;
    for (const auto &kv : indeg)
        if (kv.second == 0) ready.push_back(kv.first);
    size_t done = 0;
    while (!ready.empty()) {
        AttrRef cur = ready.back();
        ready.pop_back();
        ++done;
        // 该属性若被某条规则定为目标，且全部源就绪，则计算
        for (auto &w : waiters) {
            AttrRef dst = ref(w.host, w.rule->targetChild, w.rule->targetAttr, w.host);
            if (!(dst < cur) && !(cur < dst)) {
                std::vector<std::string> vals;
                bool allPresent = true;
                for (const auto &src : w.rule->sources) {
                    AttrRef s = ref(w.host, src.first, src.second, w.host);
                    auto it = s.node->attrs.find(s.attr);
                    if (it == s.node->attrs.end()) { allPresent = false; break; }
                    vals.push_back(it->second);
                }
                if (allPresent) dst.node->attrs[dst.attr] = w.rule->compute(vals);
            }
        }
        for (const auto &nxt : edgesTo[cur]) {
            if (--indeg[nxt] == 0) ready.push_back(nxt);
        }
    }
    stats["attrs"] = indeg.size();
    stats["edges"] = 0;
    for (const auto &kv : edgesTo) stats["edges"] += kv.second.size();
    stats["topo"] = done;
    if (done < indeg.size()) {
        if (cycle) {
            for (const auto &kv : indeg)
                if (kv.second > 0) cycle->push_back(kv.first);
        }
        return false;   // 有环
    }
    return true;
}

void SddEngine::dump(const TreeNode *n, int depth) {
    std::ostringstream os;
    for (int i = 0; i < depth; ++i) os << "  ";
    os << n->symbol;
    if (!n->lexeme.empty()) os << "('" << n->lexeme << "')";
    for (const auto &kv : n->attrs) os << "  " << kv.first << "=" << kv.second;
    std::cout << os.str() << '\n';
    for (const auto &c : n->children) dump(c.get(), depth + 1);
}

// ---------- 表达式 SDD ----------
namespace {

std::unique_ptr<TreeNode> leaf(const std::string &sym, const std::string &lex) {
    auto n = std::make_unique<TreeNode>();
    n->symbol = sym;
    n->lexeme = lex;
    // 词法器“免费”提供的两个属性：紫龙的 digit.lexval 正是这类种子。
    n->attrs["lexval"] = lex;
    n->attrs["lexeme"] = lex;
    return n;
}

// token 序列 = (名, 词素)
struct ExprBuilder {
    const std::vector<std::pair<std::string, std::string>> &t;
    size_t i = 0;
    std::string error;

    explicit ExprBuilder(const std::vector<std::pair<std::string, std::string>> &toks) : t(toks) {}

    std::unique_ptr<TreeNode> node(const std::string &sym, int prod) {
        auto n = std::make_unique<TreeNode>();
        n->symbol = sym;
        n->prod = prod;
        return n;
    }
    bool eat(const std::string &sym, std::unique_ptr<TreeNode> &into) {
        if (i < t.size() && t[i].first == sym) {
            into = leaf(sym, t[i].second);
            ++i;
            return true;
        }
        return false;
    }
    // expr → term expr'  [0]
    std::unique_ptr<TreeNode> expr() {
        auto n = node("expr", 0);
        auto a = term();
        if (!a) return nullptr;
        auto b = exprP();
        if (!b) return nullptr;
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
        return n;
    }
    // expr' → PLUS term expr' [1] | ε [2]
    std::unique_ptr<TreeNode> exprP() {
        if (i < t.size() && t[i].first == "PLUS") {
            auto n = node("expr'", 1);
            std::unique_ptr<TreeNode> op;
            if (!eat("PLUS", op)) return nullptr;
            auto a = term();
            if (!a) return nullptr;
            auto b = exprP();
            if (!b) return nullptr;
            n->children.push_back(std::move(op));
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
            return n;
        }
        auto n = node("expr'", 2);
        return n;
    }
    // term → factor term'  [3]
    std::unique_ptr<TreeNode> term() {
        auto n = node("term", 3);
        auto a = factor();
        if (!a) return nullptr;
        auto b = termP();
        if (!b) return nullptr;
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
        return n;
    }
    // term' → STAR factor term' [4] | ε [5]
    std::unique_ptr<TreeNode> termP() {
        if (i < t.size() && t[i].first == "STAR") {
            auto n = node("term'", 4);
            std::unique_ptr<TreeNode> op;
            if (!eat("STAR", op)) return nullptr;
            auto a = factor();
            if (!a) return nullptr;
            auto b = termP();
            if (!b) return nullptr;
            n->children.push_back(std::move(op));
            n->children.push_back(std::move(a));
            n->children.push_back(std::move(b));
            return n;
        }
        auto n = node("term'", 5);
        return n;
    }
    // factor → INT [6]
    std::unique_ptr<TreeNode> factor() {
        if (i < t.size() && t[i].first == "INT") {
            auto n = node("factor", 6);
            std::unique_ptr<TreeNode> k;
            eat("INT", k);
            n->children.push_back(std::move(k));
            return n;
        }
        error = "factor 期待 INT，遇到 " + (i < t.size() ? t[i].first : std::string("$"));
        return nullptr;
    }
};
}  // namespace

std::unique_ptr<TreeNode> buildExprTree(
    const std::vector<std::pair<std::string, std::string>> &toks) {
    ExprBuilder b(toks);
    auto tree = b.expr();
    if (tree && b.i != toks.size()) return nullptr;
    return tree;
}

const SddGrammar &exprSdd() {
    static SddGrammar g = {
        {
            // 0: expr → term expr'
            {"expr", {"term", "expr'"}, {
                {2, "valInh", {{1, "val"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {2, "postInh", {{1, "post"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "val", {{2, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "post", {{2, "postSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 1: expr' → PLUS term expr'
            {"expr'", {"PLUS", "term", "expr'"}, {
                {3, "valInh",
                 {{0, "valInh"}, {2, "val"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) + std::stoi(v[1])); }},
                {3, "postInh",
                 {{0, "postInh"}, {2, "post"}},
                 [](const std::vector<std::string> &v) { return v[0] + " " + v[1]; }},
                {0, "valSyn", {{3, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{3, "postSyn"}},
                 [](const std::vector<std::string> &v) { return v[0] + " +"; }},
            }},
            // 2: expr' → ε
            {"expr'", {}, {
                {0, "valSyn", {{0, "valInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{0, "postInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 3: term → factor term'
            {"term", {"factor", "term'"}, {
                {2, "valInh", {{1, "val"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {2, "postInh", {{1, "post"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "val", {{2, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "post", {{2, "postSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 4: term' → STAR factor term'
            {"term'", {"STAR", "factor", "term'"}, {
                {3, "valInh",
                 {{0, "valInh"}, {2, "val"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) * std::stoi(v[1])); }},
                {3, "postInh",
                 {{0, "postInh"}, {2, "post"}},
                 [](const std::vector<std::string> &v) { return v[0] + " " + v[1]; }},
                {0, "valSyn", {{3, "valSyn"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{3, "postSyn"}},
                 [](const std::vector<std::string> &v) { return v[0] + " *"; }},
            }},
            // 5: term' → ε
            {"term'", {}, {
                {0, "valSyn", {{0, "valInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "postSyn", {{0, "postInh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 6: factor → INT
            {"factor", {"INT"}, {
                {0, "val", {{1, "lexval"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {0, "post", {{1, "lexeme"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
        },
    };
    return g;
}

// ---------- 声明偏移 SDD ----------
namespace {
struct DeclBuilder {
    const std::vector<std::pair<std::string, std::string>> &t;
    size_t i = 0;
    explicit DeclBuilder(const std::vector<std::pair<std::string, std::string>> &toks) : t(toks) {}

    std::unique_ptr<TreeNode> node(const std::string &sym, int prod) {
        auto n = std::make_unique<TreeNode>();
        n->symbol = sym;
        n->prod = prod;
        return n;
    }
    bool eat(const std::string &sym, std::unique_ptr<TreeNode> &into) {
        if (i < t.size() && t[i].first == sym) {
            into = leaf(sym, t[i].second);
            ++i;
            return true;
        }
        return false;
    }
    // decls → VAR idlist SEMI [0]
    std::unique_ptr<TreeNode> decls() {
        auto n = node("decls", 0);
        std::unique_ptr<TreeNode> kw, semi;
        if (!eat("VAR", kw)) return nullptr;
        auto list = idlist();
        if (!list) return nullptr;
        if (!eat("SEMI", semi)) return nullptr;
            n->children.push_back(std::move(kw));
            n->children.push_back(std::move(list));
            n->children.push_back(std::move(semi));
        return n;
    }
    // idlist → IDENT idlist' [1]
    std::unique_ptr<TreeNode> idlist() {
        auto n = node("idlist", 1);
        std::unique_ptr<TreeNode> id;
        if (!eat("IDENT", id)) return nullptr;
        auto rest = idlistP();
        if (!rest) return nullptr;
            n->children.push_back(std::move(id));
            n->children.push_back(std::move(rest));
        return n;
    }
    // idlist' → COMMA IDENT idlist' [2] | ε [3]
    std::unique_ptr<TreeNode> idlistP() {
        if (i < t.size() && t[i].first == "COMMA") {
            auto n = node("idlist'", 2);
            std::unique_ptr<TreeNode> comma;
            if (!eat("COMMA", comma)) return nullptr;
            std::unique_ptr<TreeNode> id;
            if (!eat("IDENT", id)) return nullptr;
            auto rest = idlistP();
            if (!rest) return nullptr;
            n->children.push_back(std::move(comma));
            n->children.push_back(std::move(id));
            n->children.push_back(std::move(rest));
            return n;
        }
        return node("idlist'", 3);
    }
};
}  // namespace

std::unique_ptr<TreeNode> buildDeclTree(
    const std::vector<std::pair<std::string, std::string>> &toks) {
    DeclBuilder b(toks);
    auto tree = b.decls();
    if (tree && b.i != toks.size()) return nullptr;
    return tree;
}

const SddGrammar &declSdd() {
    static SddGrammar g = {
        {
            // 0: decls → VAR idlist SEMI
            {"decls", {"VAR", "idlist", "SEMI"}, {
                {2, "inh", {}, [](const std::vector<std::string> &) { return "0"; }},
                {0, "size", {{2, "next"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 1: idlist → IDENT idlist'
            {"idlist", {"IDENT", "idlist'"}, {
                {1, "offset", {{0, "inh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {2, "inh",
                 {{0, "inh"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) + 4); }},
                {0, "next", {{2, "next"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 2: idlist' → COMMA IDENT idlist'
            {"idlist'", {"COMMA", "IDENT", "idlist'"}, {
                {2, "offset", {{0, "inh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
                {3, "inh",
                 {{0, "inh"}},
                 [](const std::vector<std::string> &v) { return std::to_string(std::stoi(v[0]) + 4); }},
                {0, "next", {{3, "next"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
            // 3: idlist' → ε
            {"idlist'", {}, {
                {0, "next", {{0, "inh"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            }},
        },
    };
    return g;
}

// ---------- 后缀求值（栈机） ----------
int evalPostfix(const std::string &post) {
    std::vector<int> st;
    std::istringstream in(post);
    std::string tok;
    while (in >> tok) {
        if (tok == "+" || tok == "*") {
            int b = st.back(); st.pop_back();
            int a = st.back(); st.pop_back();
            st.push_back(tok == "+" ? a + b : a * b);
        } else {
            st.push_back(std::stoi(tok));
        }
    }
    return st.back();
}

}  // namespace tip
