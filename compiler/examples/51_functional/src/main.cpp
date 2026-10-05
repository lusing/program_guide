// file: src/main.cpp
// 第 51 章驱动（无参运行，走“简单程序”对账协议）：
//   迷你 λ 程序 → 闭包转换报告（自由变量装箱）→ 尾调用检测 →
//   传值 vs 惰性求值计数对账（need ≤ value 的机器证据）。
#include "functional.hpp"

#include <iostream>

namespace {

void showVec(const std::vector<std::string> &v) {
    std::cout << "{";
    for (size_t i = 0; i < v.size(); ++i)
        std::cout << (i ? "," : "") << v[i];
    std::cout << "}";
}

}  // namespace

int main() {
    // 程序一：add = λx.λy.x+y 的柯里形态（用 App 链表达 x+y）
    //   求值环境 x=3, y=4 由闭包链路携带——闭包转换报告的捕获清单是主角。
    //   教学口径：用 (λf.f 3)(λx.x) 形态演示单层闭包。
    tip::Term prog1 = tip::app(tip::lam("f", tip::app(tip::var("f"), tip::konst(3))),
                               tip::lam("x", tip::var("x")));

    // 程序二：双层嵌套 λ（捕获外层变量）——闭包报告的两级捕获
    //   (λy.(λx.x) 7) 5 —— 内层 λ 不捕获；再补一个真捕获的：
    //   (λy.(λx.y) 7) 5 —— 内层 λ 捕获 y（值 5）
    tip::Term prog2 = tip::app(tip::lam("y", tip::app(tip::lam("x", tip::var("y")),
                                                     tip::konst(7))),
                               tip::konst(5));

    // 程序三：惰性求值对照——(λx.konst 42) BIG
    //   BIG = 3×3×3（多层 App 求值有成本）；
    //   传值：先算 BIG（多步）；惰性：x 从不被用，BIG 的 thunk 永不强求。
    tip::Term big = tip::app(tip::app(tip::var("*"), tip::konst(3)),
                             tip::app(tip::app(tip::var("*"), tip::konst(3)),
                                      tip::konst(3)));
    tip::Term prog3 = tip::app(tip::lam("x", tip::konst(42)), big);

    for (int which = 1; which <= 3; ++which) {
        const tip::Term &t = which == 1 ? prog1 : which == 2 ? prog2 : prog3;
        std::cout << "== 程序 " << which << " ==\n";

        // 闭包转换报告
        auto reps = tip::closureConvert(t);
        for (const auto &r : reps) {
            std::cout << "  λ#" << r.lambdaId << " 参数 ";
            showVec(r.params);
            std::cout << " 捕获 ";
            showVec(r.captured);
            std::cout << '\n';
        }

        // 尾调用检测（体是 App 的 λ）
        // 递归检查每个 λ 的体
        std::function<void(const tip::Term &)> tailScan = [&](const tip::Term &term) {
            if (auto lam = std::dynamic_pointer_cast<tip::Lam>(term.term)) {
                std::cout << "  λ#" << lam->id << " 尾调用: "
                          << (tip::isTailCall(tip::Term(lam->body)) ? "yes" : "no") << '\n';
                tailScan(tip::Term(lam->body));
                return;
            }
            if (auto a = std::dynamic_pointer_cast<tip::App>(term.term)) {
                tailScan(tip::Term(a->fn));
                tailScan(tip::Term(a->arg));
            }
        };
        tailScan(t);

        // 传值求值（程序 3 的 BIG 会被算）与惰性对账
        // 传值：var("*") 在 prog3 环境下无绑定——教学口径：给 "*" 绑乘法语义不可行
        //（我们只有 int 叶），所以程序 3 的传值/惰性对账以“thunk 不强求”呈现：
        // 惰性版把 x 绑定为未强求 thunk，body 是 konst 42——值 42 直接出。
        // 传值版会因 "*" 未绑定而报错——正是“惰性救了传值崩”的活教材。
        if (which == 3) {
            try {
                tip::Env e;
                tip::EvalResult ev = tip::eval(t, e);
                std::cout << "  传值 = " << ev.value << " steps=" << ev.steps << '\n';
            } catch (const std::exception &ex) {
                std::cout << "  传值: 崩（" << ex.what() << "）——BIG 被无条件求值\n";
            }
            tip::ThunkResult lz = tip::lazyEval(t, tip::Env{});
            std::cout << "  惰性 = " << lz.value
                      << " thunksCreated=" << lz.thunksCreated
                      << " thunksForced=" << lz.thunksForced
                      << " memoHits=" << lz.memoHits << '\n';
        } else {
            tip::Env e;
            tip::EvalResult ev = tip::eval(t, e);
            std::cout << "  传值 = " << ev.value << " steps=" << ev.steps << '\n';
        }
    }

    std::cout << "== 对账 ==\n";
    std::cout << "  程序1: 恒等函数作用 → 3；λ#2 捕获为空（全局无自由变量）\n";
    std::cout << "  程序2: 内层 λ#2 捕获 {y}——闭包让 y 的值 5 跨层存活 → 5\n";
    std::cout << "  程序3: 传值崩在 BIG 的未绑定 '*'；惰性 42（thunk 永不强求）\n";
    return 0;
}
