// 第 27 章配套程序：类型分析总装（含 null），按表达式报告最终类型。
//   --check FILE    : collect -> unify -> 逐表达式打印类型，末尾打印函数类型
//   --emit-ir FILE  : 打印未优化的 LLVM 模块
//   --run FILE INPUTS: 每行输入真实执行一次
#include <fstream>
#include <iostream>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "constant.hpp"
#include "equations.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "sign.hpp"
#include "solve.hpp"
#include "soundness.hpp"
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
    std::vector<int> values;
    std::istringstream ss(line);
    int v;
    while (ss >> v) values.push_back(v);
    return values;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc >= 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);
        std::vector<tip::MonoEq> eqs = tip::signEquations(cfg);
        tip::PointEnv signStates = tip::solveFixpoint(cfg, *p.ast, eqs);
        tip::ConstPointEnv constStates = tip::solveConstFixpoint(cfg, *p.ast);

        std::cout << "SIGN (worklist least fixpoint):\n";
        std::cout << tip::printPointEnv(cfg, *p.ast, signStates);
        std::cout << "CONST (flat constant lattice, least fixpoint):\n";
        std::cout << tip::printConstEnv(cfg, *p.ast, constStates);
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
        std::vector<tip::MonoEq> eqs = tip::signEquations(cfg);
        tip::PointEnv signStates = tip::solveFixpoint(cfg, *p.ast, eqs);
        tip::ConstPointEnv constStates = tip::solveConstFixpoint(cfg, *p.ast);

        // output 语句 → 所在 CFG 节点（静态状态查询用）。
        std::map<const tip::Stmt *, int> nodeOf;
        for (const tip::FunCfg &fc : cfg.funs)
            for (const auto &[id, node] : fc.nodes)
                if (node.stmt) nodeOf[node.stmt] = id;

        int run = 0, obs = 0;
        bool allOk = true;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            tip::ConcreteRun concrete = tip::interpret(*p.ast, inputs);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);
            ++run;

            bool ok = outputs == concrete.values;
            for (size_t k = 0; k < outputs.size() && ok; ++k) {
                const tip::OutputS *site = concrete.sites[k];
                int nid = nodeOf.at(site);
                const tip::SignEnv &senv = signStates.at(nid);
                const tip::ConstEnv &cenv = constStates.at(nid);

                // 符号成员检验：具体值的符号必须 ⊑ 静态预测。
                int predicted = tip::evalExprSign(site->e.get(), senv);
                tip::SignLattice lat;
                if (predicted == tip::SBOT ||
                    !lat.leq(tip::signOfLiteral(outputs[k]), predicted)) {
                    std::cout << "run " << run << ": outputs " << outputs[k]
                              << " ; UNSOUND: sign at output\n";
                    ok = false;
                    break;
                }
                ++obs;
                // 常量相等检验：静态预测为确定常量处，JIT 值必须逐点相等。
                tip::Const cp = tip::evalConstExpr(site->e.get(), cenv);
                if (cp.kind == 1) {
                    if (cp.v != outputs[k]) {
                        std::cout << "run " << run << ": outputs " << outputs[k]
                                  << " ; UNSOUND: const predicted " << cp.v << '\n';
                        ok = false;
                        break;
                    }
                    ++obs;
                }
            }
            if (ok) {
                std::cout << "run " << run << ": outputs";
                for (size_t i = 0; i < outputs.size(); ++i)
                    std::cout << (i ? ", " : " ") << outputs[i];
                std::cout << " ; membership OK\n";
            } else {
                allOk = false;
            }
        }
        std::cout << (allOk ? "SOUND " : "FAILED ") << run << " runs, " << obs
                  << " observations\n";
        return allOk ? 0 : 1;
    }

    if (argc >= 3 && std::string(argv[1]) == "--emit-ir") {
        Parsed p = parseFile(argv[2]);
        tip::IRGen gen;
        gen.gen(*p.ast, p.bindings);
        if (!gen.verify()) {
            std::cerr << "generated module failed verification\n";
            return 1;
        }
        std::cout << gen.dump();
        return 0;
    }

    if (argc == 4 && std::string(argv[1]) == "--run") {
        std::ifstream in(argv[3]);
        if (!in) {
            std::cerr << "cannot open " << argv[3] << '\n';
            return 1;
        }
        int run = 0;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            Parsed p = parseFile(argv[2]);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);

            std::cout << "run " << ++run << ":";
            for (size_t i = 0; i < outputs.size(); ++i)
                std::cout << (i ? ", " : " ") << outputs[i];
            std::cout << '\n';
        }
        return 0;
    }

    std::cerr << "usage: tipa --check FILE | tipa --emit-ir FILE | tipa --run FILE INPUTS\n";
    return 1;
}
