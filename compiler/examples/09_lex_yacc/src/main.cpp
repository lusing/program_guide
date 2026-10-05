// file: src/main.cpp
// 第 9 章驱动（无参运行，走"简单程序"对账协议）：
//   §2 mini-lex 最长匹配与先声明优先 → §3 值栈驱动求值 + 08 章表驱动对账 →
//   §5 嵌入动作改写等价 → §6 优先级声明消冲突（翻转实验）。
#include "demo.hpp"

#include <iostream>
#include <stdexcept>

namespace {

using tip::LexTok;
using tip::MiniLex;
using tip::MiniYacc;
using tip::YaccAssoc;

std::vector<std::pair<std::string, std::string>> toPairs(const std::vector<LexTok> &ts) {
    std::vector<std::pair<std::string, std::string>> out;
    for (const auto &t : ts) out.push_back({t.kind, t.text});
    return out;
}

void printTokStream(const MiniLex &lx, const std::string &src) {
    std::cout << "  ";
    for (const auto &t : lx.scan(src))
        std::cout << t.kind << "('" << t.text << "') ";
    std::cout << "\n";
}

// 一套优先级口径：null = 完全不声明；否则给 +,-,*,/ 声明级与结合性，
// '^' 与一元负号的级别由参数单独给——翻转实验的旋钮。
struct PrecCfg {
    bool none = false;
    int caretLevel = 3;
    YaccAssoc caretAssoc = YaccAssoc::Right;
    int uminus = 2;
};
MiniYacc makeCalc(tip::CalcEnv &env, const PrecCfg &cfg) {
    MiniYacc y(tip::calcRules(env, cfg.uminus), "prog",
               {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN"});
    if (cfg.none) return y;
    y.setPrec("+", 1, YaccAssoc::Left);
    y.setPrec("-", 1, YaccAssoc::Left);
    y.setPrec("*", 2, YaccAssoc::Left);
    y.setPrec("/", 2, YaccAssoc::Left);
    y.setPrec("^", cfg.caretLevel, cfg.caretAssoc);
    return y;
}

double evalOne(const MiniLex &lx, MiniYacc &y, tip::CalcEnv &env,
               const std::string &prog) {
    auto r = y.parse(toPairs(lx.scan(prog)), true);
    if (!r.accept) throw std::runtime_error("reject: " + prog);
    if (env.printed.empty()) throw std::runtime_error("no output: " + prog);
    double v = std::stod(env.printed.back());
    env.printed.clear();
    return v;
}

}  // namespace

int main() {
    // ---------- §2 mini-lex ----------
    std::cout << "== S2 mini-lex ==\n";
    MiniLex lx(tip::calcLexRules(), tip::calcAlphabet());
    std::cout << "[stats] " << lx.stats() << "\n";
    std::cout << "[longest match]\n";
    printTokStream(lx, "a<=b == c = d <e1 x9y 42");
    std::cout << "[tie: keyword first -> print is KW]\n";
    printTokStream(lx, "print printx");
    {
        // 翻转声明序：ID 在前，同长 "print" 判给 ID——先声明优先的直接证据。
        auto rules = tip::calcLexRules();
        std::vector<tip::TokenRule> flipped(rules.begin() + 1, rules.begin() + 3);
        flipped.push_back(rules[0]);
        for (size_t i = 3; i < rules.size(); ++i) flipped.push_back(rules[i]);
        MiniLex lx2(flipped, tip::calcAlphabet());
        std::cout << "[tie: ID first -> print is ID]\n";
        printTokStream(lx2, "print printx");
    }

    // ---------- §3 值栈驱动 ----------
    std::cout << "== S3 value-stack parse ==\n";
    tip::CalcEnv env;
    MiniYacc calc = makeCalc(env, PrecCfg{});   // 标准口径：+ - * / 左，^ 右，uminus<* ^
    const std::string corpus =
        "x = 2+3*4; print x; y = (2+3)*4; print y; z = 2^3^2; print z; "
        "w = -3^2; print w; v = 10-3-2; print v; u = 100/8/5; print u; "
        "t = 2*3+4*5; print t; s = -2--3; print s; "
        "a1 = 7; print a1; b = a1*2; print b; c = 2^2^3; print c; "
        "d = (1+2)^2; print d; e = -(-5); print e; f = 8/2*3; print f; "
        "g = 1+2*3^2; print g; h = 10-2*3; print h; i = 2^(1+2); print i; "
        "j = 6/2/3; print j;";
    auto run = calc.parse(toPairs(lx.scan(corpus)), true);
    if (!run.accept) {
        std::cout << "!! corpus rejected\n";
        return 1;
    }
    for (size_t k = 0; k < env.printed.size(); ++k)
        std::cout << "[eval " << k + 1 << "] " << env.printed[k] << "\n";

    // 归约日志：第一条语句 x = 2+3*4; 的完整归约序（手工推演的对照面）
    {
        auto first = calc.parse(toPairs(lx.scan("x = 2+3*4;")), true);
        std::cout << "[reduce log: x = 2+3*4;]\n";
        for (const auto &s : first.reduceLog) std::cout << "  " << s << "\n";
    }

    // 08 章表驱动对账：同一张 LALR 表，值栈驱动与裸驱动逐语料同 accept/同步数。
    {
        std::cout << "[oracle parity]\n";
        const char *progs[] = {
            "x = 2+3*4; print x;", "print (1+2)*3;", "x = -3^2; print x;",
            "x = ;", "print 2+;", "x = 2", "(x = 4);",
        };
        int agree = 0, total = 0;
        for (const char *p : progs) {
            auto toks = lx.scan(p);
            std::vector<std::string> words;
            for (const auto &t : toks) words.push_back(t.kind);
            auto mine = calc.parse(toPairs(toks), true);
            auto oracle = tip::tableParse(calc.grammar(), calc.table(), words);
            ++total;
            bool ok = mine.accept == oracle.accept && (!mine.accept || mine.steps == oracle.steps);
            agree += ok;
            std::cout << "  " << (ok ? "match  " : "DIFFER ") << "accept=" << mine.accept
                      << "/" << oracle.accept << " steps=" << mine.steps << "/" << oracle.steps
                      << "  [" << p << "]\n";
        }
        std::cout << "[oracle] " << agree << "/" << total << " matched\n";
        if (agree != total) return 1;
    }

    // ---------- §5 嵌入动作 = 空产生式改写 ----------
    std::cout << "== S5 embedded action rewrite ==\n";
    const std::string ecorpus = "x = 3*4; y = x+1;";
    tip::EmbedEnv envB, envC;
    auto [rulesB, added] = tip::rewriteEmbedded(tip::embedRulesA(envB), tip::embedActions(envB));
    std::cout << "[rewrite] embedded markers -> " << added << " epsilon rules\n";
    MiniYacc yB(rulesB, "prog2", {"ID", "NUM", "=", ";", "+", "*"});
    auto rB = yB.parse(toPairs(lx.scan(ecorpus)), true);
    MiniYacc yC(tip::embedRulesC(envC), "prog2", {"ID", "NUM", "=", ";", "+", "*"});
    auto rC = yC.parse(toPairs(lx.scan(ecorpus)), true);
    if (!rB.accept || !rC.accept) {
        std::cout << "!! embedded corpus rejected (B=" << rB.accept << " C=" << rC.accept << ")\n";
        for (const char *q : {"x = 3*4;", "y = x+1;", "x = 3;"}) {
            auto b1 = yB.parse(toPairs(lx.scan(q)), true);
            auto c1 = yC.parse(toPairs(lx.scan(q)), true);
            std::cout << "  [" << q << "] B accept=" << b1.accept << " steps=" << b1.steps
                      << " | C accept=" << c1.accept << " steps=" << c1.steps << "\n";
        }
        auto cb = yB.conflictStats();
        auto cc = yC.conflictStats();
        std::cout << "  B conf raw=" << cb.raw << " dshift=" << cb.defaultShift
                  << " | C conf raw=" << cc.raw << " dshift=" << cc.defaultShift << "\n";
        auto db = yB.parse(toPairs(lx.scan("x = 3;")), true);
        for (const auto &s : db.reduceLog) std::cout << "  B-reduce: " << s << "\n";
        return 1;
    }
    std::cout << "[auto  B] log:";
    for (const auto &s : envB.log) std::cout << " " << s;
    std::cout << "  x=" << envB.vars.at("x") << " y=" << envB.vars.at("y") << "\n";
    std::cout << "[hand  C] log:";
    for (const auto &s : envC.log) std::cout << " " << s;
    std::cout << "  x=" << envC.vars.at("x") << " y=" << envC.vars.at("y") << "\n";
    bool eq = envB.log == envC.log && envB.vars == envC.vars;
    std::cout << "[equiv] B == C : " << (eq ? 1 : 0) << "\n";
    if (!eq) return 1;

    // ---------- §6 优先级仲裁 ----------
    std::cout << "== S6 precedence arbitration ==\n";
    auto showConf = [](const char *tag, const MiniYacc &y) {
        const auto &c = y.conflictStats();
        std::cout << "[" << tag << "] raw=" << c.raw << " byPrec=" << c.byPrec
                  << " byAssoc=" << c.byAssoc << " defaultShift=" << c.defaultShift
                  << " ruleOrder=" << c.ruleOrder << " unresolved=" << c.unresolved << "\n";
    };
    tip::CalcEnv e1, e2, e3, e4;
    MiniYacc yNone = makeCalc(e1, PrecCfg{true, 3, YaccAssoc::Right, 0});
    MiniYacc yStd = makeCalc(e2, PrecCfg{});                        // ^3 右，uminus 2
    MiniYacc yUhigh = makeCalc(e3, PrecCfg{false, 3, YaccAssoc::Right, 4});   // uminus 4
    MiniYacc yCleft = makeCalc(e4, PrecCfg{false, 3, YaccAssoc::Left, 2});    // ^ 左
    showConf("no-decl ", yNone);
    showConf("standard", yStd);

    auto ev = [](MiniYacc &y, tip::CalcEnv &e, const char *prog) {
        MiniLex l(tip::calcLexRules(), tip::calcAlphabet());
        return evalOne(l, y, e, prog);
    };
    std::cout << "[10-3-2] no-decl=" << ev(yNone, e1, "print 10-3-2;")
              << "  standard=" << ev(yStd, e2, "print 10-3-2;") << "\n";
    std::cout << "[2^3^2 ] standard=" << ev(yStd, e2, "print 2^3^2;")
              << "  caret-left=" << ev(yCleft, e4, "print 2^3^2;") << "\n";
    std::cout << "[-3^2  ] standard=" << ev(yStd, e2, "print -3^2;")
              << "  uminus-high=" << ev(yUhigh, e3, "print -3^2;") << "\n";
    std::cout << "[2+3*4 ] no-decl=" << ev(yNone, e1, "print 2+3*4;")
              << "  standard=" << ev(yStd, e2, "print 2+3*4;") << "\n";
    return 0;
}
