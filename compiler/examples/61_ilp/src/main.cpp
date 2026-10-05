// file: src/main.cpp
// 第 61 章驱动：--check FILE
//   TAC → 逐块依赖 DAG（三类数据依赖 + 内存保守边）→
//   宽度 1/2 两档表调度（关键路径优先）→ 重放校验 →
//   循环体的 modulo scheduling 报告（II 双下界）。
#include "ilp.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "tacgen.hpp"
#include "tacblocks.hpp"

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

    bool allOk = true;
    for (const auto &b : blocks) {
        tip::DepDAG d = tip::depDag(code, b);
        std::cout << "== 依赖 DAG B" << b.id << " ==\n";
        for (int u = 0; u < d.n; ++u)
            for (int v : d.succ[u])
                std::cout << "  " << u << " -> " << v << " (" << d.kind[u * d.n + v] << ")\n";
        std::cout << "  关键路径高度:";
        for (int u = 0; u < d.n; ++u) std::cout << ' ' << u << ":" << d.height[u];
        std::cout << '\n';
        for (int width = 1; width <= 2; ++width) {
            tip::Schedule s = tip::listSchedule(d, width);
            std::cout << "  表调度 w=" << width << ": cycles=" << s.cycles << " |";
            for (int c = 0; c < s.cycles; ++c) {
                std::cout << " [";
                for (size_t k = 0; k < s.order[c].size(); ++k)
                    std::cout << (k ? "," : "") << s.order[c][k];
                std::cout << "]";
            }
            bool ok = tip::scheduleReplay(d, s);
            std::cout << " 重放校验: " << (ok ? "ok" : "BROKEN") << '\n';
            allOk = allOk && ok;
        }
    }

    // modulo：找“含 i = i + 1 步进”的块当循环体（while 模板保证它成块）
    {
        const tip::Block *body = nullptr;
        for (const auto &b : blocks)
            for (int i = b.begin; i + 1 < b.end; ++i)
                if (code[i].op == tip::TOp::Add && code[i].a == "i" &&
                    code[i + 1].op == tip::TOp::Copy && code[i + 1].dst == "i") {
                    body = &b;
                    break;
                }
        if (body) {
            std::vector<tip::Quad> quads(code.begin() + body->begin,
                                         code.begin() + body->end);
            tip::ModuloReport mr = tip::moduloSchedule(quads, "i");
            std::cout << "== modulo scheduling ==\n";
            std::cout << "  资源下界 = " << mr.resourceBound
                      << " 递归下界 = " << mr.recurrenceBound
                      << " => II = " << mr.ii << '\n';
            std::cout << "  时序示意: " << mr.unrolled << '\n';
        } else {
            std::cout << "== modulo scheduling ==\n";
            std::cout << "  未识别出计数器步进（i = i + 1）——按报告模式给出下界演示\n";
        }
    }
    if (false) {
        const tip::Block &big = blocks.front();
        std::vector<tip::Quad> body2(code.begin() + big.begin, code.begin() + big.end);
        tip::ModuloReport mr = tip::moduloSchedule(body2, "i");
        std::cout << "== modulo scheduling ==\n";
        if (mr.ii < 0) {
            std::cout << "  未识别出计数器步进（i = i + 1）——按报告模式给出下界演示\n";
        } else {
            std::cout << "  资源下界 = " << mr.resourceBound
                      << " 递归下界 = " << mr.recurrenceBound << " => II = " << mr.ii << '\n';
        }
    }

    // ---------- 树高平衡（鲸书 §8.4.2）：喂给调度器的形状 ----------
    for (const auto &b : blocks) {
        std::vector<tip::Quad> body(code.begin() + b.begin, code.begin() + b.end);
        tip::BalanceReport br = tip::treeBalance(body);
        if (br.leaves < 4) continue;
        std::cout << "== 树高平衡 B" << b.id << "（" << br.leaves << " 叶链）==\n";
        std::cout << "  原链深度 " << br.depthBefore << " → 平衡后 " << br.depthAfter
                  << "，值 = " << br.value << "（前后一致）\n";
        // 调度对照取纯链子图（叶子视为就绪）：剥掉常量物化的 copy 噪声
        std::vector<tip::Quad> chain0, chain1;
        for (const auto &q : br.before)
            if (q.op == tip::TOp::Add) chain0.push_back(q);
        for (const auto &q : br.after)
            if (q.op == tip::TOp::Add) chain1.push_back(q);
        tip::Block pb{};
        pb.id = b.id;
        pb.begin = 0;
        pb.end = static_cast<int>(chain0.size());
        tip::DepDAG d0 = tip::depDag(chain0, pb);
        tip::Schedule s0 = tip::listSchedule(d0, 2);
        pb.end = static_cast<int>(chain1.size());
        tip::DepDAG d1 = tip::depDag(chain1, pb);
        tip::Schedule s1 = tip::listSchedule(d1, 2);
        std::cout << "  双发射调度周期（纯链）：链形 " << s0.cycles << " → 平衡 " << s1.cycles << '\n';
        std::cout << "  平衡后块体:\n";
        for (const auto &q : br.after) std::cout << "    " << tip::show(q) << '\n';
        allOk = allOk && br.depthAfter < br.depthBefore && s1.cycles < s0.cycles;
        break;
    }

    std::cout << "== 对账 ==\n";
    tip::TacRun run = tip::tacInterp(code, {3, 2});   // 两个 input 喂 3、2
    std::cout << "  outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << "\n  (调度只重排发射槽，不改程序语义；解释器照常执行原 TAC)\n";
    return allOk ? 0 : 1;
}
