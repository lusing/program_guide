// 第 38 章配套程序：widening ∇ / narrowing Δ + 区间预测的可靠性检验。
//   --check FILE           : 打印 ∇ 迭代轨迹与 Δ 收窄前后的关键点区间
//   --verify-soundness FILE INPUTS : 每行输入 JIT 真执行，
//                            断言具体输出落在（收窄后的）预测区间内
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "symtab.hpp"
#include "widen.hpp"

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
    std::vector<int> values;
    std::istringstream ss(line);
    int v;
    while (ss >> v) values.push_back(v);
    return values;
}

}  // namespace

int main(int argc, char **argv) {
    const int maxRounds = 50;

    if (argc == 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);

        tip::WidenedResult w = tip::solveWidenedInterval(cfg, *p.ast, maxRounds);
        std::map<int, tip::IvEnv> narrowed =
            tip::narrowPass(cfg, *p.ast, w.out);

        std::cout << "== interval lattice, widening (cap " << maxRounds
                  << " rounds) then narrowing ==\n";
        std::cout << "widening point: loop head node " << w.headNode << "\n";
        for (const std::string &line : w.trace) std::cout << line << "\n";
        std::cout << (w.converged ? "CONVERGED" : "DID NOT CONVERGE")
                  << " after " << w.rounds << " rounds (with widening)\n";

        // 关键点对照：循环头与第一个 output 点，∇ 解 vs Δ 之后。
        std::set<std::string> vars(p.ast->funs[0]->vars.begin(),
                                   p.ast->funs[0]->vars.end());
        int outputNode = -1;
        for (const auto &[id, node] : cfg.funs[0].nodes)
            if (dynamic_cast<const tip::OutputS *>(node.stmt) && outputNode < 0)
                outputNode = id;
        std::cout << "after WIDEN : head " << tip::printIvEnv(w.out[w.headNode], vars)
                  << "  output " << tip::printIvEnv(w.out[outputNode], vars) << "\n";
        std::cout << "after NARROW: head " << tip::printIvEnv(narrowed[w.headNode], vars)
                  << "  output " << tip::printIvEnv(narrowed[outputNode], vars) << "\n";
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

        tip::WidenedResult w = tip::solveWidenedInterval(cfg, *p.ast, maxRounds);
        std::map<int, tip::IvEnv> narrowed = tip::narrowPass(cfg, *p.ast, w.out);

        // output 语句 → CFG 节点（区间预测按节点状态查询）。
        std::map<const tip::Stmt *, int> nodeOf;
        for (const auto &[id, node] : cfg.funs[0].nodes)
            if (node.stmt) nodeOf[node.stmt] = id;

        // 按 AST 语句顺序收集 output 语句（与 JIT 输出顺序一一对应）。
        std::vector<const tip::OutputS *> sites;
        struct Walk {
            static void go(const tip::Stmt *s,
                           std::vector<const tip::OutputS *> &out) {
                if (const auto *b = dynamic_cast<const tip::BlockS *>(s)) {
                    for (const auto &x : b->ss) go(x.get(), out);
                } else if (const auto *i =
                               dynamic_cast<const tip::IfS *>(s)) {
                    go(i->then.get(), out);
                    if (i->els) go(i->els.get(), out);
                } else if (const auto *w =
                               dynamic_cast<const tip::WhileS *>(s)) {
                    go(w->body.get(), out);
                } else if (const auto *o =
                               dynamic_cast<const tip::OutputS *>(s)) {
                    out.push_back(o);
                }
            }
        };
        Walk::go(p.ast->funs[0]->body.get(), sites);

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

            bool ok = true;
            for (size_t k = 0; k < outputs.size() && ok; ++k) {
                const tip::OutputS *site = sites[k];
                int nid = nodeOf.at(site);
                // 预测区间：在该 output 点的状态下抽象求值输出表达式。
                tip::Iv predicted =
                    tip::evalIv(site->e.get(), narrowed.at(nid));
                std::cout << "run " << run << ": outputs " << outputs[k]
                          << " ; predicted " << tip::ivText(predicted);
                if (predicted.lo > predicted.hi || outputs[k] < predicted.lo ||
                    outputs[k] > predicted.hi) {
                    std::cout << " ; UNSOUND\n";
                    ok = false;
                } else {
                    std::cout << " ; membership OK\n";
                    ++obs;
                }
            }
            if (!ok) allOk = false;
        }
        std::cout << (allOk ? "SOUND " : "FAILED ") << run << " runs, " << obs
                  << " observations\n";
        return allOk ? 0 : 1;
    }

    std::cerr << "usage: tipa --check FILE | tipa --verify-soundness FILE INPUTS\n";
    return 1;
}
