// 第 18 章配套程序：约束收集 + Robinson 合一。
//   --check FILE    : 收集等式 -> 逐个合一 -> 打印每个变量的解
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
#include "constraints.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "symtab.hpp"
#include "unify.hpp"

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

// 收集一个类型结构中出现的全部变量编号。
void idsOf(const tip::Tp &t, std::set<int> &out) {
    if (const auto *v = dynamic_cast<tip::TyVar *>(t.get())) {
        out.insert(v->id);
        return;
    }
    if (const auto *p = dynamic_cast<tip::TyPtr *>(t.get()))
        idsOf(p->to, out);
    if (const auto *f = dynamic_cast<tip::TyFun *>(t.get())) {
        for (const tip::Tp &a : f->params) idsOf(a, out);
        idsOf(f->ret, out);
    }
    if (const auto *r = dynamic_cast<tip::TyRec *>(t.get()))
        for (const auto &kv : r->fields) idsOf(kv.second, out);
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
        tip::Collected c = tip::collect(*p.ast, p.bindings);

        tip::Subst s;
        try {
            for (const tip::Con &k : c.cons) tip::unify(k.a, k.b, s);
        } catch (const tip::TypeError &e) {
            std::cout << "type error: " << e.what() << '\n';
            return 3;
        }

        // 收集约束中出现的全部变量，按编号打印已确定的解。
        std::set<int> all;
        for (const tip::Con &k : c.cons) {
            idsOf(k.a, all);
            idsOf(k.b, all);
        }
        for (const auto &kv : c.decl) idsOf(kv.second, all);

        std::cout << "solution:\n";
        for (int id : all) {
            tip::Tp t = tip::normalize(s, std::make_shared<tip::TyVar>(id));
            if (dynamic_cast<tip::TyVar *>(t.get()) == nullptr)
                std::cout << "t" << id << " -> " << t->show() << '\n';
        }
        return 0;
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
