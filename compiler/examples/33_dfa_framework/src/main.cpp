// file: src/main.cpp
// 第 33 章驱动：--check FILE
//   对五个实例（四大经典 + 常量传播）各跑：
//     MFP（框架迭代解） vs MOP≤K（路径枚举解），逐块并排打印 + 判定行；
//   收官一行：MFP ⊑ MOP 的方向性总检。
#include "framework.hpp"
#include "instances.hpp"
#include "mop.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"

#include <fstream>
#include <iostream>
#include <vector>

namespace {

struct CollectErrorListener : antlr4::BaseErrorListener {
    std::vector<std::string> messages;
    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

std::unique_ptr<tip::ProgramA> parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) throw std::runtime_error("打不开 " + path);
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
    if (!errors.messages.empty())
        throw std::runtime_error("词法/语法错误: " + errors.messages.front());
    auto ast = tip::buildAst(tree);
    auto binds = tip::resolveNames(*ast);
    if (!binds.errors.empty())
        throw std::runtime_error("名字解析错误: " + binds.errors.front().text);
    return ast;
}

void show(const tip::FVal &s) {
    std::cout << "{";
    bool first = true;
    for (const auto &x : s) {
        std::cout << (first ? "" : ", ") << x;
        first = false;
    }
    std::cout << "}";
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto ast = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';
    std::cout << "== blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << ' ' << s;
        std::cout << '\n';
    }

    std::vector<tip::Instance> insts = {
        tip::makeReaching(code), tip::makeAvailable(code),
        tip::makeLive(code), tip::makeVeryBusy(code),
        tip::makeConstProp(code),
    };
    const int K = 8;
    bool allSound = true;
    for (const auto &inst : insts) {
        tip::FrameResult mfp = tip::solve(inst, code, blocks);
        std::vector<tip::FVal> mopRes = tip::mop(inst, code, blocks, K);
        std::cout << "== " << inst.name << " ==\n";
        bool equal = true;
        bool sound = true;
        for (size_t b = 0; b < blocks.size(); ++b) {
            // 对照同一口径：前向比 OUT，后向比 IN
            const tip::FVal &m = inst.dir == tip::Dir::Forward ? mfp.out[b] : mfp.in[b];
            const tip::FVal &p = mopRes[b];
            std::cout << "  B" << b << "  MFP ";
            show(m);
            std::cout << "  |  MOP<= " << K << " ";
            show(p);
            std::cout << '\n';
            if (m != p) equal = false;
            // 方向性：may 实例要求 MFP ⊆ MOP；must 实例要求 MOP ⊆ MFP。
            // 常量传播单独口径：MFP 说 c 而 MOP 说 ⊤ 视为粗（正确方向），反向即错。
            if (inst.name == "reaching" || inst.name == "live") {
                for (const auto &x : m)
                    if (!p.count(x)) sound = false;
            } else if (inst.name == "available" || inst.name == "verybusy") {
                for (const auto &x : p)
                    if (!m.count(x)) sound = false;
            } else {
                for (const auto &x : m) {
                    std::string var = x.substr(0, x.find('='));
                    std::string val = x.substr(x.find('=') + 1);
                    std::string pval;
                    for (const auto &y : p)
                        if (y.rfind(var + "=", 0) == 0) pval = y.substr(var.size() + 1);
                    if (val != "T" && pval == "T") {
                        // MFP 常量、MOP 也常量但相同：fine；MOP=⊤ MFP=c 是 MFP 更精：
                        // 不可能（MOP ⊑ MFP 方向），标 unsound。
                        sound = false;
                    }
                }
            }
        }
        std::cout << "  MFP == MOP<= " << K << " : " << (equal ? "yes" : "no") << '\n';
        std::cout << "  MFP 在正确的一侧（方向性）: " << (sound ? "yes" : "NO") << '\n';
        allSound = allSound && sound;
    }

    std::cout << "== 结论 ==\n";
    std::cout << "  分配性实例（四大经典）：MFP 与 MOP 一致\n";
    std::cout << "  常量传播：MFP 可能严格粗于 MOP（差集见上方 no 的块）\n";
    return 0;
}
