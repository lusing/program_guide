// file: src/main.cpp
// 第 10 章驱动（无参运行，走"简单程序"对账协议）：
//   S2 检测点对照（LL vs LR，None 模式）→ S3 级联账（TokenDel vs Panic）→
//   S4 error 记号恢复（归约续行）→ S5 恐慌抢救求值 → S6 短语级步数有界。
#include "demo.hpp"
#include "recover.hpp"

#include <iostream>

namespace {

using tip::LexTok;
using tip::MiniLex;
using tip::MiniYacc;

std::vector<std::pair<std::string, std::string>> toPairs(const std::vector<LexTok> &ts) {
    std::vector<std::pair<std::string, std::string>> out;
    for (const auto &t : ts) out.push_back({t.kind, t.text});
    return out;
}
std::vector<std::string> toKinds(const std::vector<LexTok> &ts) {
    std::vector<std::string> out;
    for (const auto &t : ts) out.push_back(t.kind);
    return out;
}

MiniYacc makeCalc(tip::CalcEnv &env) {
    MiniYacc y(tip::calcRules(env, 2), "prog",
               {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN"});
    y.setPrec("+", 1, tip::YaccAssoc::Left);
    y.setPrec("-", 1, tip::YaccAssoc::Left);
    y.setPrec("*", 2, tip::YaccAssoc::Left);
    y.setPrec("/", 2, tip::YaccAssoc::Left);
    y.setPrec("^", 3, tip::YaccAssoc::Right);
    return y;
}

}  // namespace

int main() {
    MiniLex lx(tip::calcLexRules(), tip::calcAlphabet());
    std::cout << "[lex] " << lx.stats() << "\n";

    // ---------- S2 检测点对照：LL 与 LR 谁先看见错误 ----------
    std::cout << "== S2 detection points ==\n";
    tip::LLGrammar llg = tip::calcLL();   // LL1 持文法引用——临时量会被悬垂
    tip::LL1 ll(llg);
    ll.computeFirst();
    ll.computeFollow();
    ll.buildTable(true);
    tip::CalcEnv env0;
    MiniYacc lr = makeCalc(env0);
    const char *bad[] = {
        "x = ;", "print 2+;", "x = 2", "(x = 4);", "x = (2+;",
        "x = )2(; ", "x = 2+*3;", "print;", "x = 2 3;", "print 4 5;",
    };
    int le = 0, tie = 0, total = 0;
    for (const char *p : bad) {
        auto llr = llParse(ll, toKinds(lx.scan(p)), tip::LLRecover::None);
        auto lrr = lr.parseRecover(toPairs(lx.scan(p)), MiniYacc::Recover::None);
        ++total;
        bool lrFirst = lrr.detectPos < llr.detectPos;
        bool same = lrr.detectPos == llr.detectPos;
        le += lrFirst;
        tie += same;
        std::cout << "  ll@" << (llr.detectPos < 0 ? -1 : llr.detectPos)
                  << " lr@" << lrr.detectPos << (same ? "  ==" : (lrFirst ? "  LR<" : "  LL<"))
                  << "  [" << p << "]\n";
    }
    std::cout << "[stats] total=" << total << " equal=" << tie << " lr-earlier=" << le
              << " ll-earlier=" << (total - tie - le) << "\n";

    // ---------- S3 级联账：朴素删除制造假错误，恐慌模式只报真错误 ----------
    std::cout << "== S3 cascade ==\n";
    const std::string cascade = "x = 1; y = 2 z = 3; w = 4;";
    {
        tip::CalcEnv e1;
        MiniYacc y1 = makeCalc(e1);
        auto del = y1.parseRecover(toPairs(lx.scan(cascade)), MiniYacc::Recover::TokenDel);
        std::cout << "[LR TokenDel] diags=" << del.diags.size()
                  << " accept=" << del.accept << "\n";
        for (const auto &d : del.diags)
            std::cout << "    @" << d.first << " " << d.second << "\n";
        tip::CalcEnv e2;
        MiniYacc y2 = makeCalc(e2);
        auto pan = y2.parseRecover(toPairs(lx.scan(cascade)), MiniYacc::Recover::Panic);
        std::cout << "[LR Panic   ] diags=" << pan.diags.size()
                  << " accept=" << pan.accept << "\n";
        for (const auto &d : pan.diags)
            std::cout << "    @" << d.first << " " << d.second << "\n";
        auto lldel = llParse(ll, toKinds(lx.scan(cascade)), tip::LLRecover::TokenDel);
        auto llpan = llParse(ll, toKinds(lx.scan(cascade)), tip::LLRecover::Panic);
        std::cout << "[LL TokenDel] diags=" << lldel.diags.size()
                  << " accept=" << lldel.accept << "\n";
        std::cout << "[LL Panic   ] diags=" << llpan.diags.size()
                  << " accept=" << llpan.accept << "\n";
    }

    // ---------- S4 error 记号：恢复后续行，归约日志保留后半 ----------
    std::cout << "== S4 error production ==\n";
    {
        tip::CalcEnv e;
        MiniYacc ye(tip::calcRulesErr(e), "prog",
                    {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN", "error"});
        ye.setPrec("+", 1, tip::YaccAssoc::Left);
        ye.setPrec("-", 1, tip::YaccAssoc::Left);
        ye.setPrec("*", 2, tip::YaccAssoc::Left);
        ye.setPrec("/", 2, tip::YaccAssoc::Left);
        ye.setPrec("^", 3, tip::YaccAssoc::Right);
        const std::string corpus = "x = 1; y = print 2; z = 3; print z;";
        auto run = ye.parseRecover(toPairs(lx.scan(corpus)), MiniYacc::Recover::ErrorProd);
        std::cout << "[accept] " << run.accept << " diags=" << run.diags.size() << "\n";
        for (const auto &d : run.diags)
            std::cout << "    @" << d.first << " " << d.second << "\n";
        std::cout << "[reductions after recovery]\n";
        bool seenErr = false;
        for (const auto &s : run.reduceLog) {
            if (s.find("error") != std::string::npos) seenErr = true;
            if (seenErr) std::cout << "    " << s << "\n";
        }
        std::cout << "[printed]";
        for (const auto &p : e.printed) std::cout << " " << p;
        std::cout << "\n";
        // 对照：前缀语料（q = 0; 打头，让尾部同样以 prog → prog stmt 滚雪球）
        tip::CalcEnv e2;
        MiniYacc y2(tip::calcRulesErr(e2), "prog",
                    {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "^", "LPAREN", "RPAREN", "error"});
        auto tail = y2.parseRecover(toPairs(lx.scan("q = 0; z = 3; print z;")), MiniYacc::Recover::None);
        std::vector<std::string> tailLog(tail.reduceLog.end() - 6, tail.reduceLog.end());
        // 取 run.reduceLog 的最后 6 条比对（error 语句之后的 z/print 两条语句）
        bool tailEq = run.reduceLog.size() >= 6;
        if (tailEq) {
            std::vector<std::string> runTail(run.reduceLog.end() - 6, run.reduceLog.end());
            tailEq = runTail == tailLog;
        }
        std::cout << "[tail match] " << (tailEq ? 1 : 0) << "\n";
    }

    // ---------- S5 恐慌抢救：恢复后无错部分照常求值 ----------
    std::cout << "== S5 panic salvage ==\n";
    {
        tip::CalcEnv e;
        MiniYacc y = makeCalc(e);
        const std::string corpus = "x = 1; y = 2 z = 3; w = 4; print x; print w;";
        auto run = y.parseRecover(toPairs(lx.scan(corpus)), MiniYacc::Recover::Panic);
        std::cout << "[accept] " << run.accept << " diags=" << run.diags.size() << "\n";
        std::cout << "[printed]";
        for (const auto &p : e.printed) std::cout << " " << p;
        std::cout << "\n";
        // 对照：手工期望——x=1 与 w=4 应当照常打印（y 语句被恢复吞掉）
        tip::CalcEnv e2;
        MiniYacc y2 = makeCalc(e2);
        auto clean = y2.parseRecover(toPairs(lx.scan("x = 1; print x; w = 4; print w;")),
                                     MiniYacc::Recover::None);
        (void)clean;
        std::cout << "[expect match] " << (e.printed == e2.printed ? 1 : 0) << "\n";
    }

    // ---------- S6 短语级：局部修复的步数有界 ----------
    std::cout << "== S6 phrase bounded ==\n";
    {
        auto jitter = llParse(ll, toKinds(lx.scan("print ((();")), tip::LLRecover::Phrase);
        std::cout << "[phrase on 'print ((();'] diags=" << jitter.diags.size()
                  << " steps=" << jitter.steps << " accept=" << jitter.accept << "\n";
        auto deep = llParse(ll, toKinds(lx.scan("x = (((((((1; print x;")), tip::LLRecover::Phrase);
        std::cout << "[phrase on deep parens] diags=" << deep.diags.size()
                  << " steps=" << deep.steps << " accept=" << deep.accept << "\n";
        std::cout << "[bounded] " << (jitter.steps < 200 && deep.steps < 200 ? 1 : 0) << "\n";
    }
    return 0;
}
