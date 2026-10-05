// file: src/main.cpp
// 第 13 章驱动（无参运行，简单程序对账协议）：
//   一、静态检查（求值前）：四类违规程序被拒 + 诊断行号；
//   二、解释执行：闭包计数器、嵌套捕获、递归（if/else 两支都赋值才过检）、
//      遮蔽、立即调用——输出逐行对账；
//   三、环境链观测：Environment 节点创建数与手推一致；
//   四、运行时兜底：闭包元数不符在运行时被抓（静态查不到的那类）；
//   五、断言汇总。
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "interp.hpp"

namespace {

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    std::string syntaxError;
};

// 语法错误收集（第 12 章同款）：ANTLR 默认打印并容错继续，坏树不能进
// 后续阶段——收集到即判"语法错误"，不再 buildAst。
class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line, size_t column,
                     const std::string &msg, std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

Parsed parseProgram(const std::string &src) {
    Parsed r;
    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);
    CollectErrorListener errs;
    parser.removeErrorListeners();
    parser.addErrorListener(&errs);
    if (errs.messages.empty()) r.ast = tip::buildAst(parser.program());
    if (!errs.messages.empty()) r.syntaxError = errs.messages.front();
    return r;
}

// 一段程序的完整旅程：解析 → 静态检查 →（过检才）解释。
// 返回三元组的字符串化：检查结论 / 输出+返回 / 环境节点数。
struct RunResult {
    std::string verdict;  // "拒绝" + 诊断行 / "通过"
    std::string output;   // 解释输出（含返回行）
    int envs = 0;
};

RunResult journey(const std::string &src) {
    RunResult r;
    Parsed p = parseProgram(src);
    if (!p.ast) {
        r.verdict = "语法错误：" + p.syntaxError;
        return r;
    }
    tip::SemCheck sem;
    std::vector<tip::Diag> diags = sem.run(*p.ast);
    if (!diags.empty()) {
        std::ostringstream os;
        os << "拒绝（" << diags.size() << " 条）：";
        for (const auto &d : diags) os << "[行" << d.line << "] " << d.msg << "；";
        r.verdict = os.str();
        return r;
    }
    r.verdict = "通过";
    tip::Interpreter interp(*p.ast);
    std::ostringstream os;
    try {
        tip::Value v = interp.run("main", {}, os);
        os << "=> 返回 " << v.i;
    } catch (const tip::InterpError &e) {
        os << "运行时错误[行" << e.line << "] " << e.msg;
    }
    r.output = os.str();
    r.envs = interp.envCreated();
    return r;
}

}  // namespace

int main() {
    std::cout << "== 一、静态检查（求值前）==\n";
    // V1 确定赋值：声明到首次赋值之间读取（匠书 var a = a 窗口的 TIP 对应物）
    {
        RunResult r = journey(
            "main() { var x; output x; return 0; }");
        check("V1 使用前未赋值", r.verdict,
              "拒绝（1 条）：[行1] 使用前未赋值：x；");
    }
    // V2 确定赋值的流敏感：if 一支赋值——汇合交集为空
    {
        RunResult r = journey(
            "main() { var x; if (input() > 0) { x = 1; } output x; return 0; }");
        check("V2 分支部分赋值", r.verdict,
              "拒绝（1 条）：[行1] 使用前未赋值：x；");
    }
    // V3 元数：直接调用全局函数，静态可查
    {
        RunResult r = journey(
            "f(a, b) { return a; }\nmain() { output f(1); return 0; }");
        check("V3 直接调用元数", r.verdict,
              "拒绝（1 条）：[行2] 元数不符：f 期望 2 实得 1；");
    }
    // V4 未声明（第 12 章口径在本章作用域化版本里复现）
    {
        RunResult r = journey("main() { output y; return 0; }");
        check("V4 未声明", r.verdict, "拒绝（1 条）：[行1] 未声明：y；");
    }
    // V5 同层重复声明（参数与变量同层）
    {
        RunResult r = journey("f(x) { var x; return x; }\nmain() { return f(1); }");
        check("V5 同层重复声明", r.verdict,
              "拒绝（1 条）：[行1] 同层重复声明：x；");
    }

    std::cout << "\n== 二、解释执行（过检后才运行）==\n";
    // P1 闭包计数器：两个闭包各持各的环境；同一闭包跨调用保状态
    {
        RunResult r = journey(
            "counter() {\n"
            "  var c;\n"
            "  c = 0;\n"
            "  return fun (n) { c = c + n; return c; };\n"
            "}\n"
            "main() {\n"
            "  var inc1, inc2;\n"
            "  inc1 = counter();\n"
            "  inc2 = counter();\n"
            "  output inc1(1);\n"
            "  output inc1(1);\n"
            "  output inc2(1);\n"
            "  return 0;\n"
            "}\n");
        check("P1 判定", r.verdict, "通过");
        check("P1 输出", r.output, "1\n2\n1\n=> 返回 0");
        check("P1 环境节点数", std::to_string(r.envs), "7");
    }
    // P2 嵌套捕获三层 + 调用链
    {
        RunResult r = journey(
            "adder(x) {\n"
            "  return fun (y) { return fun (z) { return x + y + z; }; };\n"
            "}\n"
            "main() {\n"
            "  var p;\n"
            "  p = adder(1)(2)(3);\n"
            "  output p;\n"
            "  return 0;\n"
            "}\n");
        check("P2 判定", r.verdict, "通过");
        check("P2 输出", r.output, "6\n=> 返回 0");
    }
    // P3 递归 + if/else 两支都赋值（V2 的合法对照）
    {
        RunResult r = journey(
            "fact(n) {\n"
            "  var r;\n"
            "  if (n == 0) { r = 1; } else { r = n * fact(n - 1); }\n"
            "  return r;\n"
            "}\n"
            "main() {\n"
            "  output fact(5);\n"
            "  return 0;\n"
            "}\n");
        check("P3 判定", r.verdict, "通过");
        check("P3 输出", r.output, "120\n=> 返回 0");
    }
    // P4 局部遮蔽全局函数名（名字在不同时刻指向不同实体）
    {
        RunResult r = journey(
            "f(x) { return x + 1; }\n"
            "main() {\n"
            "  var f;\n"
            "  f = 3;\n"
            "  output f;\n"
            "  return 0;\n"
            "}\n");
        check("P4 判定", r.verdict, "通过");
        check("P4 输出", r.output, "3\n=> 返回 0");
    }
    // P5 立即调用 + 形参遮蔽外层变量（遮蔽合法的活证）
    {
        RunResult r = journey(
            "main() {\n"
            "  var x;\n"
            "  x = 1;\n"
            "  output (fun (x) { return x + 10; })(5);\n"
            "  output x;\n"
            "  return 0;\n"
            "}\n");
        check("P5 判定", r.verdict, "通过");
        check("P5 输出", r.output, "15\n1\n=> 返回 0");
    }
    // P6 while 循环（含计数闭包改写外层值；TIP 比较只有 > 与 ==，条件用 3 > i）
    {
        RunResult r = journey(
            "main() {\n"
            "  var i, s, bump;\n"
            "  i = 0;\n"
            "  s = 0;\n"
            "  bump = fun () { i = i + 1; return i; };\n"
            "  while (3 > i) { s = s + bump(); }\n"
            "  output s;\n"
            "  output i;\n"
            "  return 0;\n"
            "}\n");
        check("P6 判定", r.verdict, "通过");
        check("P6 输出", r.output, "6\n3\n=> 返回 0");
    }

    std::cout << "\n== 三、运行时兜底 ==\n";
    // 闭包调用的元数静态查不到（被调者的值运行时才定）——运行时兜底
    {
        RunResult r = journey(
            "main() {\n"
            "  var g;\n"
            "  g = fun (a) { return a; };\n"
            "  output g(1, 2);\n"
            "  return 0;\n"
            "}\n");
        check("R1 判定", r.verdict, "通过");
        check("R1 运行时元数", r.output, "运行时错误[行4] 元数不符（运行时）：期望 1 实得 2");
    }

    std::cout << "\n== 四、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（21 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
