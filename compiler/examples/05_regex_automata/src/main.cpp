// file: src/main.cpp
// 第 5 章驱动：--check FILE 跑三组演示——
//   1) (a|b)*abb 的全流水线（对齐绿龙 Fig 3.11/3.12/3.15 的经典数字）；
//   2) TIP 各 token 模式的 NFA/DFA/最小 DFA 状态数；
//   3) 多模式最长匹配 scanner 对 FILE 切词（关键字走保留字策略）。
#include "re.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace {

std::string readFile(const std::string &path) {
    std::ifstream in(path);
    if (!in) throw std::runtime_error("打不开 " + path);
    std::ostringstream os;
    os << in.rdbuf();
    return os.str();
}

// 在 DFA 上做整串成员判定：读完且停在接受态。
bool accepts(const tip::DFA &d, const std::string &s) {
    int st = d.start;
    for (char c : s) {
        auto it = d.trans[st].find(c);
        if (it == d.trans[st].end()) return false;
        st = it->second;
    }
    return d.color[st] > 0;
}

void printTable(const tip::DFA &d, const std::set<char> &alpha) {
    std::cout << "state";
    for (char c : alpha) std::cout << ' ' << c;
    std::cout << '\n';
    for (int s = 0; s < d.states(); ++s) {
        std::cout << (s == d.start ? "->" : "  ") << s
                  << (d.color[s] > 0 ? "*" : " ");
        for (char c : alpha) {
            auto it = d.trans[s].find(c);
            if (it == d.trans[s].end()) std::cout << " .";
            else std::cout << ' ' << it->second;
        }
        std::cout << '\n';
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    const std::string src = readFile(argv[2]);

    // ---------- 演示一：(a|b)*abb 全流水线 ----------
    std::cout << "== demo: (a|b)*abb ==\n";
    auto re = tip::parseRE("(a|b)*abb");
    tip::NFA nfa = tip::thompson(*re);
    std::set<char> ab = {'a', 'b'};
    tip::DFA dfa = tip::subset(nfa, ab);
    tip::DFA mini = tip::minimize(dfa, ab);
    std::cout << "nfa_states=" << nfa.st.size()
              << " dfa_states=" << dfa.states()
              << " minimized=" << mini.states() << '\n';
    printTable(mini, ab);
    for (const char *s : {"abb", "aabb", "babb", "abba", "ab", "", "babbabb"})
        std::cout << "accepts \"" << s << "\": " << (accepts(mini, s) ? "yes" : "no") << '\n';

    // ---------- 演示一之二：Brzozowski 逆转两次（鲸书 §2.6.2）----------
    std::cout << "== demo: brzozowski ==\n";
    tip::DFA bz = tip::brzozowski(nfa, ab);
    std::cout << "partition(minimize)=" << mini.states()
              << " brzozowski=" << bz.states() << '\n';
    bool agree = true;
    for (const char *s : {"abb", "aabb", "babb", "abba", "ab", "", "babbabb"})
        if (accepts(mini, s) != accepts(bz, s)) agree = false;
    std::cout << "两法识别一致: " << (agree && mini.states() == bz.states() ? "yes" : "NO") << '\n';

    // ---------- 演示二：TIP token 模式的状态数 ----------
    std::cout << "== patterns ==\n";
    struct P { const char *name, *pat; std::set<char> alpha; };
    std::vector<P> pats = {
        {"IDENT", "(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)*", {}},
        {"NUMBER", "(0|1|2|3|4|5|6|7|8|9)(0|1|2|3|4|5|6|7|8|9)*", {}},
        {"LE", "<=", {'<', '='}},
        {"IFKW", "if", {'i', 'f'}},
    };
    for (auto &p : pats) {
        if (p.alpha.empty()) {
            for (char c = 'a'; c <= 'z'; ++c) p.alpha.insert(c);
            for (char c = '0'; c <= '9'; ++c) p.alpha.insert(c);
        }
        tip::NFA pn = tip::thompson(*tip::parseRE(p.pat));
        tip::DFA pd = tip::subset(pn, p.alpha);
        tip::DFA pm = tip::minimize(pd, p.alpha);
        std::cout << p.name << ": nfa=" << pn.st.size()
                  << " dfa=" << pd.states()
                  << " minimized=" << pm.states() << '\n';
    }

    // ---------- 演示三：多模式 scanner 切词 ----------
    std::cout << "== scanner ==\n";
    std::vector<tip::TokenRule> rules = {
        {"LE", "<="}, {"GE", ">="}, {"EQ", "=="}, {"LT", "<"}, {"GT", ">"},
        {"ASSIGN", "="}, {"PLUS", "+"}, {"MINUS", "-"}, {"STAR", "*"}, {"SLASH", "/"},
        {"LP", "\\("}, {"RP", "\\)"}, {"LB", "\\{"}, {"RB", "\\}"},
        {"SEMI", ";"}, {"COMMA", ","},
        {"NUMBER", "(0|1|2|3|4|5|6|7|8|9)(0|1|2|3|4|5|6|7|8|9)*"},
        {"IDENT", "(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)(a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z)*"},
    };
    std::set<char> alpha;
    for (char c = 'a'; c <= 'z'; ++c) alpha.insert(c);
    for (char c = '0'; c <= '9'; ++c) alpha.insert(c);
    for (char c : "<>=+-*/(){};,") alpha.insert(c);
    tip::Scanner sc(rules, alpha);
    std::cout << sc.stats() << '\n';
    // 关键字识别走“保留字策略”：先按 IDENT 切出，再查表升级（绿龙 3.2 节）。
    static const std::vector<std::string> kws = {
        "if", "else", "while", "return", "input", "output", "alloc", "record"};
    for (const std::string &tok : sc.lex(src)) {
        if (tok.rfind("IDENT('", 0) == 0 && tok.back() == ')') {
            std::string lexeme = tok.substr(7, tok.size() - 9);
            bool isKw = false;
            for (const auto &k : kws)
                if (k == lexeme) isKw = true;
            if (isKw) {
                std::cout << "KW('" << lexeme << "')\n";
                continue;
            }
        }
        std::cout << tok << '\n';
    }
    return 0;
}
