// file: src/main.cpp
// 第 57 章驱动（无参运行，简单程序对账协议）：
//   一、逃逸闭包计数器：与第 13 章 P1 同源输出（1 2 1），帧回收后
//      计数仍正确；盒子账 2 对照 13 章环境节点 7；
//   二、嵌套捕获三层：adder(1)(2)(3) = 6（与 13 章 P2 同源）；
//   三、循环各捕各的：每圈新块作用域新槽位，输出 0 1 2（共享反例
//      会是 2 2 2——§25.6 关键裁决）；
//   四、共享上值：writer/reader 两个闭包同一变量一改俱改；
//   五、结构断言：close 后开放表空、两闭包同一上值对象；
//   六、断言汇总。
#include <functional>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>

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
    std::string verdict;
    std::string output;
    int boxes = 0;          // 堆盒子数（对照 13 章环境节点）
    int openAtEnd = -1;     // 运行结束时的开放上值数（-1 = 未跑）
};

RunResult journey(const std::string &src) {
    RunResult r;
    tip::Compiler c;
    tip::Program prog;
    try {
        prog = c.compile(src);
    } catch (const tip::CompileError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    } catch (const tip::ScanError &e) {
        r.verdict = "编译错误[行" + std::to_string(e.line) + "] " + e.msg;
        return r;
    }
    r.verdict = "通过";

    std::ostringstream os;
    tip::VM vm(os);
    for (const auto &f : prog.fns) {
        // 注册进全局表：函数包一层无捕获闭包（Call 只认闭包）
        auto clo = std::make_shared<tip::ObjClosure>();
        clo->fn = f;
        vm.globals[f->name] = tip::Value::ref(clo);
    }
    std::shared_ptr<tip::ObjFn> mainFn;
    for (const auto &f : prog.fns)
        if (f->name == "main") mainFn = f;
    try {
        tip::Value v = vm.run(mainFn);
        os << "ret " << v.i;
    } catch (const tip::VmError &e) {
        os << "运行时错误 " << e.msg;
    }
    r.output = os.str();
    r.boxes = vm.boxesCreated();
    r.openAtEnd = vm.openUpvalueCount();
    return r;
}

}  // namespace

int main() {
    std::cout << "== 一、逃逸闭包计数器（与第 13 章 P1 同源）==\n";
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
        check("P1 输出（13 章全等）", r.output, "1\n2\n1\nret 0");
        check("P1 盒子数（对照 13 章 7 环境节点）", std::to_string(r.boxes), "2");
        check("P1 结束后开放表", std::to_string(r.openAtEnd), "0");
    }

    std::cout << "\n== 二、嵌套捕获三层（与第 13 章 P2 同源）==\n";
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
        check("P2 输出", r.output, "6\nret 0");
        // x 在 adder 帧（被两层字面量传递）、y 在中层帧：两个盒子
        check("P2 盒子数（x 与 y 各一）", std::to_string(r.boxes), "2");
    }

    std::cout << "\n== 三、循环各捕各的（§25.6 关键裁决）==\n";
    {
        RunResult r = journey(
            "main() {\n"
            "  var i;\n"
            "  i = 0;\n"
            "  while (i < 3) {\n"
            "    var x;\n"
            "    x = i;\n"
            "    output (fun () { return x; })();\n"
            "    i = i + 1;\n"
            "  }\n"
            "  return 0;\n"
            "}\n");
        check("P3 判定", r.verdict, "通过");
        // 每圈 x 都是新块作用域的新槽位：close 时各搬各的盒子
        check("P3 输出（各捕各的 = 0 1 2）", r.output, "0\n1\n2\nret 0");
        check("P3 盒子数（每圈一个）", std::to_string(r.boxes), "3");
    }

    std::cout << "\n== 四、共享上值（一改俱改）==\n";
    {
        // TIP 文法 return 只在函数尾——用 set*5 让同一闭包既写又读：
        // rw(1) 写 v+=5 → 15；rw(0) 写 v+=0 → 仍 15（同一盒子的连续读写）
        RunResult r = journey(
            "maker() {\n"
            "  var v;\n"
            "  v = 10;\n"
            "  return fun (set) {\n"
            "    v = v + set * 5;\n"
            "    return v;\n"
            "  };\n"
            "}\n"
            "main() {\n"
            "  var rw, a;\n"
            "  rw = maker();\n"
            "  a = rw(1);\n"      // 写：v = 15
            "  output a;\n"
            "  output rw(0);\n"   // 再写 +0：仍是同一个 v → 15
            "  return 0;\n"
            "}\n");
        check("P4 判定", r.verdict, "通过");
        check("P4 输出（写读同盒）", r.output, "15\n15\nret 0");
        check("P4 盒子数（v 只一盒）", std::to_string(r.boxes), "1");
    }

    std::cout << "\n== 五、结构断言 ==\n";
    {
        // 反汇编：counter 返回的 CLOSURE 带捕获表 [槽1]
        tip::Compiler c;
        // counter 考函数头捕获（RETURN 运行期关闭）；补一段块级捕获
        //（CLOSE_UPVALUE 指令位）——两类关闭路径都要在反汇编里可见
        tip::Program prog = c.compile(
            "counter() {\n"
            "  var c;\n"
            "  c = 0;\n"
            "  return fun (n) { c = c + n; return c; };\n"
            "}\n"
            "main() {\n"
            "  var i;\n"
            "  i = 0;\n"
            "  while (i < 1) {\n"
            "    var x;\n"
            "    x = i;\n"
            "    output (fun () { return x; })();\n"
            "    i = i + 1;\n"
            "  }\n"
            "  return 0;\n"
            "}\n");
        std::ostringstream os;
        // 递归反汇编：字面量函数住在常量池里，不下钻就看不见它们
        std::function<void(const tip::ObjFn &)> walk = [&](const tip::ObjFn &f) {
            tip::disassembleChunk(*f.code, f.name, os);
            for (const tip::Value &v : f.code->consts)
                if (v.isObj())
                    if (auto *inner = dynamic_cast<const tip::ObjFn *>(v.obj.get()))
                        walk(*inner);
        };
        for (const auto &f : prog.fns) walk(*f);
        std::string all = os.str();
        bool hasClosure = all.find("CLOSURE") != std::string::npos;
        bool hasCapture = all.find("捕获[槽1]") != std::string::npos;
        bool hasClose = all.find("CLOSE_UPVALUE") != std::string::npos;
        bool hasGetUp = all.find("GET_UPVALUE") != std::string::npos;
        check("反汇编含 CLOSURE", hasClosure ? "有" : "无", "有");
        check("捕获表 [槽1] 可读", hasCapture ? "有" : "无", "有");
        check("CLOSE_UPVALUE 出现（出块关闭）", hasClose ? "有" : "无", "有");
        check("GET_UPVALUE 出现（体内读捕获）", hasGetUp ? "有" : "无", "有");
    }

    std::cout << "\n== 六、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（15 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
