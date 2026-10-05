// 第 65 章配套程序：收集语义 → α/γ → 单调分析的可靠性总装。
//   --check FILE   : 读同目录 FILE.inputs（每行一条具体输入流），
//                    逐流展开路径得到收集语义 C 的有限切片，
//                    计算 α(C) 与单调符号分析 A，检验 α(C) ⊑ A，
//                    并在代表域 {-1,0,1} 上检验 S ⊆ γ(α(S))；
//                    末尾用 LLVM ORC JIT 真实执行每条流做交叉对照。
//   --emit-ir FILE : 打印未优化的 LLVM 模块
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
#include "coll.hpp"
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

std::vector<int> parseStream(const std::string &line) {
    std::vector<int> values;
    std::istringstream ss(line);
    int v;
    while (ss >> v) values.push_back(v);
    return values;
}

// 输入流清单：与程序同目录的 FILE.inputs，每行一条流；# 开头是注释。
std::vector<std::vector<int>> loadStreams(const std::string &path) {
    std::vector<std::vector<int>> streams;
    std::ifstream in(path);
    if (!in) return streams;
    std::string line;
    while (std::getline(in, line)) {
        size_t a = line.find_first_not_of(" \t\r\n");
        if (a == std::string::npos || line[a] == '#') continue;
        streams.push_back(parseStream(line));
    }
    return streams;
}

std::string showInts(const std::vector<int> &xs) {
    std::ostringstream out;
    for (size_t i = 0; i < xs.size(); ++i)
        out << (i ? " " : "") << xs[i];
    return out.str();
}

}  // namespace

int main(int argc, char **argv) {
    if (argc >= 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::Cfg cfg = tip::buildCfg(*p.ast);

        std::vector<std::vector<int>> streams =
            loadStreams(std::string(argv[2]) + ".inputs");
        if (streams.empty()) streams.push_back({});

        tip::CollectResult collected =
            tip::collect(cfg, *p.ast, streams);
        std::cout << tip::printCollect(cfg, *p.ast, collected);

        const std::vector<int> representatives{-1, 0, 1};
        tip::GaloisResult gal =
            tip::runGalois(cfg, *p.ast, collected, representatives);
        std::cout << tip::printGalois(gal);

        std::cout << "== concrete JIT cross-check (LLVM ORC) ==\n";
        for (const std::vector<int> &stream : streams) {
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), stream);
            std::cout << "  inputs [" << showInts(stream) << "] -> outputs ["
                      << showInts(outputs) << "]\n";
        }

        return gal.theoremHolds ? 0 : 1;
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

    std::cerr << "usage: tipa --check FILE | tipa --emit-ir FILE\n";
    return 1;
}
