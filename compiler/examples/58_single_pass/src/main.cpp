// file: src/main.cpp
// 第 58 章驱动（无参运行，简单程序对账协议）：
//   一、编译诊断（单遍口径：错误即终止，报行号即止）；
//   二、程序输出对账（fact/while 和/块遮蔽/短路/前向引用）；
//   三、反汇编对账（while 循环函数的机器产物与手推逐行一致）；
//   四、编译期账（槽位峰值：块级遮蔽的回收）；
//   五、断言汇总。
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "chunk.hpp"
#include "compiler.hpp"
#include "vm.hpp"

namespace {

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

struct RunResult {
    std::string verdict;   // "通过" / "编译错误[行N] …" / "运行时错误 …"
    std::string output;    // output 行 + ret 行
    int slotPeak = 0;
    std::shared_ptr<tip::ObjFn> mainFn;
    tip::Program prog;
};

// 一段源程序的完整旅程：扫描+语法+发码（一遍）→ 注册全局表 → 跑 main。
RunResult journey(const std::string &src) {
    RunResult r;
    tip::Compiler c;
    try {
        r.prog = c.compile(src);
    } catch (const tip::CompileError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    } catch (const tip::ScanError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    }
    r.slotPeak = c.lastSlotPeak();
    r.verdict = "通过";

    std::ostringstream os;
    tip::VM vm(os);
    for (const auto &f : r.prog.fns) vm.globals[f->name] = tip::Value::ref(f);
    for (const auto &f : r.prog.fns)
        if (f->name == "main") r.mainFn = f;
    try {
        tip::Value v = vm.run(r.mainFn);
        os << "ret " << v.i;
    } catch (const tip::VmError &e) {
        os << "运行时错误 " << e.msg;
    }
    r.output = os.str();
    return r;
}

}  // namespace

int main() {
    std::cout << "== 一、编译诊断（单遍：错误即终止）==\n";
    {
        RunResult r = journey("main() { var x x = 1; return 0; }");
        check("D1 缺分号", r.verdict, "编译错误[行1] 期望 ';'，但看到 'x'");
    }
    {
        RunResult r = journey("main() { var x, x; return 0; }");
        check("D2 同层重复声明", r.verdict, "编译错误[行1] 同层重复声明：x");
    }
    {
        RunResult r = journey("main() { var x; x = 1 $ 2; return 0; }");
        check("D3 意外字符", r.verdict, "编译错误[行1] 意外字符 '$'");
    }

    std::cout << "\n== 二、程序输出对账 ==\n";
    // P1 阶乘——与第 15 章 P3 同源语料（共同子集，输出必须全等）
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
        check("P1 判定", r.verdict, "通过");
        check("P1 输出", r.output, "120\nret 0");
    }
    // P2 while 累加：1+…+10 = 55（反汇编对账与编译期账的主角）
    {
        RunResult r = journey(
            "main() {\n"
            "  var i, s;\n"
            "  i = 1;\n"
            "  s = 0;\n"
            "  while (i <= 10) { s = s + i; i = i + 1; }\n"
            "  output s;\n"
            "  return 0;\n"
            "}\n");
        check("P2 判定", r.verdict, "通过");
        check("P2 输出", r.output, "55\nret 0");
        check("P2 槽位峰值（槽0+i+s）", std::to_string(r.slotPeak), "3");
    }
    // P3 块级遮蔽 + 槽位回收（块级 var 是教学扩展，jlox 同款）
    {
        RunResult r = journey(
            "main() {\n"
            "  var x;\n"
            "  x = 1;\n"
            "  {\n"
            "    var x;\n"
            "    x = 2;\n"
            "    output x;\n"
            "  }\n"
            "  output x;\n"
            "  return 0;\n"
            "}\n");
        check("P3 判定", r.verdict, "通过");
        check("P3 输出（内 2 外 1）", r.output, "2\n1\nret 0");
        check("P3 槽位峰值（回收前 3）", std::to_string(r.slotPeak), "3");
    }
    // P4 短路：右操作数带输出副作用——短路路径下它一行都不印
    {
        RunResult r = journey(
            "loud(v) {\n"
            "  output v;\n"
            "  return v;\n"
            "}\n"
            "main() {\n"
            "  var r;\n"
            "  r = 0 && loud(7);\n"
            "  output r;\n"
            "  r = 1 || loud(8);\n"
            "  output r;\n"
            "  r = 1 && loud(9);\n"
            "  output r;\n"
            "  r = 0 || loud(10);\n"
            "  output r;\n"
            "  return 0;\n"
            "}\n");
        check("P4 判定", r.verdict, "通过");
        // 7 与 8 不出现 = 短路生效；9、10 出现 = 非短路路径照常求值
        check("P4 输出（短路：7、8 缺席）", r.output, "0\n1\n9\n1\n10\n1\nret 0");
    }
    // P5 前向引用：main 编译时 later 还没被编译——迟绑定的存在理由
    {
        RunResult r = journey(
            "main() { return later(2); }\n"
            "later(n) { return n * 10; }\n");
        check("P5 判定", r.verdict, "通过");
        check("P5 前向引用输出", r.output, "ret 20");
    }

    std::cout << "\n== 三、反汇编对账（P2 的 main）==\n";
    {
        RunResult r = journey(
            "main() {\n"
            "  var i, s;\n"
            "  i = 1;\n"
            "  s = 0;\n"
            "  while (i <= 10) { s = s + i; i = i + 1; }\n"
            "  output s;\n"
            "  return 0;\n"
            "}\n");
        std::ostringstream os;
        tip::disassembleChunk(*r.mainFn->code, "main", os);
        std::cout << os.str();
        // 手推逐行（正文给出完整推演）：赋值先右值后目标、JIF 占位经
        // 回填指向循环出口 37、LOOP 回边指向条件起点 10。
        std::string want = R"(== main ==
0000   2 CONSTANT 0  ; 0
0002    | CONSTANT 0  ; 0
0004   3 CONSTANT 1  ; 1
0006    | SET_LOCAL 1
0008    | POP
0009   4 CONSTANT 0  ; 0
0011    | SET_LOCAL 2
0013    | POP
0014   5 GET_LOCAL 1
0016    | CONSTANT 2  ; 10
0018    | LE
0019    | JUMP_IF_FALSE -> 41
0022    | GET_LOCAL 2
0024    | GET_LOCAL 1
0026    | ADD
0027    | SET_LOCAL 2
0029    | POP
0030    | GET_LOCAL 1
0032    | CONSTANT 1  ; 1
0034    | ADD
0035    | SET_LOCAL 1
0037    | POP
0038    | LOOP -> 14
0041   6 GET_LOCAL 2
0043    | PRINT
0044   7 CONSTANT 0  ; 0
0046    | RETURN
)";
        check("反汇编逐行（回填终态）", os.str(), want);
    }

    std::cout << "\n== 四、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（16 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
