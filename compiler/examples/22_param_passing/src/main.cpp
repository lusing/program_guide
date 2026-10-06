// file: src/main.cpp
// 第 22 章驱动（无参运行，走"简单程序"对账协议）：
//   S1 完全静态环境（保留性 + 递归拒绝）→ S2 值传递 → S3 引用传递（含临时格）→
//   S4 值结果（p(a,a) 别名 + 写回序）→ S5 名字传递（p(a,a) + swap 槽位错乱 + Jensen）→
//   S6 四机制总账（同一 p(a,a) 四个答案并排）。
#include "front.hpp"
#include "interp.hpp"

#include <iostream>

namespace {

using plang::PassMode;

// 四机制共用骨架：p 双参自增，实参都是同一个变量 a
std::string pProgram(PassMode m) {
    std::string mode = plang::modeName(m);
    return "fun p(" + mode + " x, " + mode + " y) { x = x + 1; y = y + 1; }\n"
           "fun main() { var a; a = 1; p(a, a); print a; }\n";
}

plang::RunResult runProgram(const std::string &src, bool staticEnv = false) {
    plang::Program p = plang::parse(src);
    plang::Interp it(p, staticEnv);
    return it.run("main");
}

void show(const char *tag, const plang::RunResult &r) {
    std::cout << "[" << tag << "] ok=" << r.ok;
    if (!r.error.empty()) std::cout << " err=" << r.error;
    std::cout << " out=";
    for (const auto &s : r.printed) std::cout << " " << s;
    std::cout << "\n";
}

}  // namespace

int main() {
    // ---------- S1 完全静态运行时环境（§7.2） ----------
    std::cout << "== S1 fully static env ==\n";
    {
        // 局部变量跨调用保留：count 的 c 在两次调用间不清零——"活动记录即全局变量"
        const char *counter =
            "fun count(val step) { var c; c = c + step; return c; }\n"
            "fun main() { var x; x = count(1); x = count(1); x = count(1); print x; }\n";
        show("static  ", runProgram(counter, true));    // 期待 3
        show("stacked ", runProgram(counter, false));   // 期待 1（每次调用新帧）
        // 递归禁令：第二份帧无处安放
        const char *fact =
            "fun fact(val n) { if n <= 1 { return 1; } return n * fact(n - 1); }\n"
            "fun main() { print fact(3); }\n";
        show("rec-static", runProgram(fact, true));     // 期待拒绝
        show("rec-stack ", runProgram(fact, false));    // 期待 6
    }

    // ---------- S2 值传递（§7.5.1） ----------
    std::cout << "== S2 call by value ==\n";
    {
        // inc2 反例（L 书原文程序）：改形参不影响外界——"被初始化了的局部变量"
        const char *inc2 =
            "fun inc2(val x) { x = x + 1; x = x + 1; }\n"
            "fun main() { var y; y = 5; inc2(y); print y; }\n";
        show("inc2-val", runProgram(inc2));   // 期待 5
    }

    // ---------- S3 引用传递（§7.5.2） ----------
    std::cout << "== S3 call by reference ==\n";
    {
        const char *inc2r =
            "fun inc2(ref x) { x = x + 1; x = x + 1; }\n"
            "fun main() { var y; y = 5; inc2(y); print y; }\n";
        show("inc2-ref", runProgram(inc2r));  // 期待 7
        // 表达式实参的临时格：副作用落在临时格、外界无恙
        const char *tmp =
            "fun g(ref z) { z = z + 1; }\n"
            "fun main() { var m; m = 42; g(2 + 3); g(4 + 1); print m; }\n";
        auto r = runProgram(tmp);
        show("expr-arg", r);                  // 期待 42
        for (const auto &t : r.tempCells) std::cout << "    " << t << "\n";
    }

    // ---------- S4 值结果传递（§7.5.3） ----------
    std::cout << "== S4 call by value-result ==\n";
    {
        // 别名分辨器：p(a,a) 下值结果得 2、引用得 3（L 书原文例）
        show("p(a,a) valres", runProgram(pProgram(PassMode::ValRes)));   // 期待 2
        // 写回序（实现口径：声明序 x 先 y 后）：x+1 与 y+10 写同格，后写者胜
        const char *order =
            "fun q(valres x, valres y) { x = x + 1; y = y + 10; }\n"
            "fun main() { var a; a = 1; q(a, a); print a; }\n";
        show("writeback-order", runProgram(order));   // 期待 11（若反序则 2）
    }

    // ---------- S5 名字传递（§7.5.4） ----------
    std::cout << "== S5 call by name ==\n";
    {
        show("p(a,a) name", runProgram(pProgram(PassMode::Name)));   // 期待 3（与引用同形）
        // 经典 swap 反例：名字传递写错槽位（Knuth 的 swap(i, a[i])）
        const char *swapRef =
            "fun swap(ref x, ref y) { var t; t = x; x = y; y = t; }\n"
            "fun main() { var i; array a[6]; i = 2; a[2] = 5; swap(i, a[i]);"
            " print i; print a[2]; print a[5]; }\n";
        show("swap-ref", runProgram(swapRef));     // 期待 5 2 0（正确交换）
        const char *swapName =
            "fun swapn(name x, name y) { var t; t = x; x = y; y = t; }\n"
            "fun main() { var i; array a[6]; i = 2; a[2] = 5; swapn(i, a[i]);"
            " print i; print a[2]; print a[5]; }\n";
        show("swap-name", runProgram(swapName));   // 期待 5 5 2（a[a[i]] 写错槽）
        // Jensen 装置：i 与 term 都是名字传递——被调方改写 i、每次取 term 都重求值
        const char *jensen =
            "fun sum(name i, val n, name term) { var s; s = 0;"
            " for i = 0 to n - 1 do { s = s + term; } return s; }\n"
            "fun main() { var i; var s; array a[3]; a[0] = 1; a[1] = 2; a[2] = 3;"
            " s = sum(i, 3, a[i] * 2); print s; print i; }\n";
        auto r = runProgram(jensen);
        show("jensen", r);                          // 期待 12 与 2（i 终值 = 末次赋值）
        std::cout << "    thunk evals = " << r.thunkEvals << " (i 与 term 的重求值次数)\n";
    }

    // ---------- S6 四机制总账 ----------
    std::cout << "== S6 four modes on p(a,a) ==\n";
    {
        // 同一程序骨架、四个答案并排——别名是唯一分辨器
        for (PassMode m : {PassMode::Val, PassMode::ValRes, PassMode::Ref, PassMode::Name}) {
            auto r = runProgram(pProgram(m));
            std::cout << "  " << plang::modeName(m) << ": a =";
            for (const auto &s : r.printed) std::cout << " " << s;
            std::cout << "\n";
        }
    }
    return 0;
}
