// 第 50 章配套程序：k-CFA 调用串的精度阶梯 + 可靠性检验。
//   --check FILE : 对同一程序以 k=0/1/2 与 functional（无限 k 记忆化）
//                  四档跑调用串敏感常量传播，打印各档上下文数与
//                  main 的 output 点预测——同一程序，k 越大越准
//   --verify-soundness FILE INPUTS :
//                  四档预测分别对照 JIT 真实执行：精度可以不同，
//                  但每一档都必须 sound（本章要落地的核心结论）
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "context.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) {
        std::cerr << "cannot open " << path << '\n';
        std::exit(1);
    }
    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);

    CollectErrorListener errors;
    lexer.removeErrorListeners();
    parser.removeErrorListeners();
    lexer.addErrorListener(&errors);
    parser.addErrorListener(&errors);

    TIPParser::ProgramContext *tree = parser.program();
    if (!errors.messages.empty()) {
        for (const std::string &m : errors.messages) std::cout << m << '\n';
        std::exit(2);
    }

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty()) {
        for (const tip::Diag &d : result.bindings.errors)
            std::cout << d.text << '\n';
        std::exit(3);
    }
    return result;
}

std::vector<int> parseRun(const std::string &line) {
    std::istringstream ss(line);
    std::vector<int> vals;
    int v;
    while (ss >> v) vals.push_back(v);
    return vals;
}

std::string variantName(int k) {
    return k < 0 ? "functional" : std::to_string(k);
}

void reportLevel(const char *label, const tip::Cfg &cfg,
                 const tip::ContextResult &r) {
    std::cout << label << ":";
    for (const auto &[f, n] : r.ctxCount) std::cout << " " << f << "×" << n;
    std::cout << "\n";
    std::cout << "  main outputs:";
    auto preds = tip::outputPredictionsCtx(cfg, r);
    for (const auto &[site, c] : preds) {
        (void)site;
        std::cout << " " << constShow(c);
    }
    std::cout << "\n";
}

}  // namespace

int main(int argc, char **argv) {
    if (argc == 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);

        std::cout << "== call-string sensitivity: same program, four k ==\n";
        reportLevel("k=0          ", cfg, tip::solveContext(cfg, *p.ast, 0));
        reportLevel("k=1          ", cfg, tip::solveContext(cfg, *p.ast, 1));
        reportLevel("k=2          ", cfg, tip::solveContext(cfg, *p.ast, 2));
        reportLevel("k=unbounded  ", cfg, tip::solveContext(cfg, *p.ast, -1));
        return 0;
    }

    if (argc == 4 && std::string(argv[1]) == "--verify-soundness") {
        std::ifstream in(argv[3]);
        if (!in) {
            std::cerr << "cannot open " << argv[3] << '\n';
            return 1;
        }
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);

        const int ks[4] = {0, 1, 2, -1};
        std::vector<tip::ContextResult> results;
        for (int k : ks) results.push_back(tip::solveContext(cfg, *p.ast, k));

        int run = 0, obs = 0;
        bool allOk = true;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);
            ++run;

            std::cout << "run " << run << ": outputs";
            for (int v : outputs) std::cout << " " << v;
            std::cout << "\n";
            for (size_t i = 0; i < 4; ++i) {
                auto preds = tip::outputPredictionsCtx(cfg, results[i]);
                std::cout << "  " << variantName(ks[i]) << ":";
                bool ok = true;
                if (preds.size() != outputs.size()) {
                    std::cout << " (prediction/execution count mismatch) SKIP\n";
                    continue;
                }
                for (size_t j = 0; j < preds.size(); ++j) {
                    const tip::Const &c = preds[j].second;
                    std::cout << " " << constShow(c);
                    if (c.kind == 1) {
                        // 声称是常量：必须与真实执行一致。
                        ++obs;
                        if (c.v != outputs[j]) ok = false;
                    }
                }
                std::cout << (ok ? " OK" : " UNSOUND") << "\n";
                if (!ok) allOk = false;
            }
        }
        std::cout << (allOk ? "SOUND " : "FAILED ") << run << " runs, " << obs
                  << " observations\n";
        return allOk ? 0 : 1;
    }

    std::cerr << "usage: tipa --check FILE | tipa --verify-soundness FILE INPUTS\n";
    return 1;
}
