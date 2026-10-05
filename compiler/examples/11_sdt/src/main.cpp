// file: src/main.cpp
// 第 11 章驱动：--check FILE
//   FILE 以 var 开头 → 声明偏移 SDD；否则 → 表达式 SDD（值 + 后缀）。
//   末尾固定跑“循环依赖”小演示：紫龙 5.1.2 的 A/B 反例。
#include "sdd.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"

#include <fstream>
#include <iostream>
#include <vector>

namespace {

std::vector<std::pair<std::string, std::string>> lexTip(const std::string &path) {
    std::ifstream stream(path);
    if (!stream) throw std::runtime_error("打不开 " + path);
    antlr4::ANTLRInputStream input(stream);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    tokens.fill();
    std::vector<std::pair<std::string, std::string>> out;
    for (antlr4::Token *t : tokens.getTokens()) {
        if (t->getType() == antlr4::Token::EOF) continue;
        std::string name(lexer.getVocabulary().getSymbolicName(t->getType()));
        out.emplace_back(name, t->getText());
    }
    return out;
}

void stats(const std::map<std::string, size_t> &s) {
    std::cout << "== dependency ==\n";
    for (const auto &kv : s) std::cout << "  " << kv.first << " = " << kv.second << '\n';
}

// 收集树上全部 IDENT 叶子的 (词素, offset)
void collectIdents(const tip::TreeNode *n, std::vector<std::pair<std::string, std::string>> &out) {
    if (n->symbol == "IDENT") {
        out.push_back({n->lexeme, n->attrs.count("offset") ? n->attrs.at("offset") : "?"});
    }
    for (const auto &c : n->children) collectIdents(c.get(), out);
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto toks = lexTip(argv[2]);
    std::cout << "== tokens ==\n ";
    for (const auto &t : toks) std::cout << ' ' << t.first << "('" << t.second << "')";
    std::cout << "\n";

    if (!toks.empty() && toks[0].first == "VAR") {
        // ---------- 声明偏移 ----------
        auto tree = tip::buildDeclTree(toks);
        if (!tree) {
            std::cerr << "syntax error: 无法按声明文法解析\n";
            return 1;
        }
        tip::SddEngine eng(tip::declSdd());
        std::map<std::string, size_t> st;
        if (!eng.evaluate(tree.get(), st)) {
            std::cerr << "SDD 有循环依赖\n";
            return 1;
        }
        std::cout << "== annotated tree ==\n";
        tip::SddEngine::dump(tree.get());
        stats(st);
        std::cout << "== results ==\n";
        std::vector<std::pair<std::string, std::string>> ids;
        collectIdents(tree.get(), ids);
        for (const auto &id : ids)
            std::cout << "  " << id.first << " @ offset " << id.second << '\n';
        std::string size = tree->attrs.at("size");
        std::cout << "  size = " << size << " = 4 * " << ids.size()
                  << " : " << (std::stoi(size) == 4 * static_cast<int>(ids.size()) ? "yes" : "NO")
                  << '\n';
    } else {
        // ---------- 表达式：值 + 后缀 ----------
        auto tree = tip::buildExprTree(toks);
        if (!tree) {
            std::cerr << "syntax error: 无法按表达式文法解析\n";
            return 1;
        }
        tip::SddEngine eng(tip::exprSdd());
        std::map<std::string, size_t> st;
        if (!eng.evaluate(tree.get(), st)) {
            std::cerr << "SDD 有循环依赖\n";
            return 1;
        }
        std::cout << "== annotated tree ==\n";
        tip::SddEngine::dump(tree.get());
        stats(st);
        std::cout << "== results ==\n";
        std::string val = tree->attrs.at("val");
        std::string post = tree->attrs.at("post");
        std::cout << "  val  = " << val << '\n';
        std::cout << "  post = " << post << '\n';
        int pv = tip::evalPostfix(post);
        std::cout << "  evalPostfix(post) == val : "
                  << (pv == std::stoi(val) ? "yes" : "NO") << '\n';
    }

    // ---------- 循环依赖演示（紫龙 5.1.2 的 A/B 反例） ----------
    std::cout << "== circular demo ==\n";
    std::cout << "  A -> B ; A.s = B.i ; B.i = A.s + 1\n";
    tip::SddGrammar bad = {{
        {"A", {"B"}, {
            {0, "s", {{1, "i"}}, [](const std::vector<std::string> &v) { return v[0]; }},
            {1, "i", {{0, "s"}}, [](const std::vector<std::string> &v) { return v[0] + "+1"; }},
        }},
    }};
    auto a = std::make_unique<tip::TreeNode>();
    a->symbol = "A";
    a->prod = 0;
    auto b = std::make_unique<tip::TreeNode>();
    b->symbol = "B";
    a->children.push_back(std::move(b));
    tip::SddEngine eng2(bad);
    std::map<std::string, size_t> st2;
    std::vector<tip::AttrRef> cyc;
    bool ok = eng2.evaluate(a.get(), st2, &cyc);
    std::cout << "  acyclic = " << (ok ? "yes" : "no")
              << " (attrs=" << st2["attrs"] << " edges=" << st2["edges"]
              << " topo=" << st2["topo"] << ")\n";
    for (const auto &r : cyc)
        std::cout << "  stuck: " << r.node->symbol << "." << r.attr << '\n';
    return 0;
}
