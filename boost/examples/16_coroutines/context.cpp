// context.cpp —— Boost.Context（2009）：一切协程的地基——栈切换本身
// 对应文档：docs/16-coroutines.md
// 汇编级实现 fcontext_t（make_fcontext/jump_fcontext）：把寄存器现场
// 存取一遍，执行流就"跳"到了另一段栈。coroutine/fiber 全家都盖在它上面。
// 本例走官方 C++ 封装 continuation（callcc/resume），裸 API 见文档叙述。
#include <boost/context/continuation.hpp>
#include <iostream>

int main() {
    int checkpoint = 0;
    boost::context::continuation c = boost::context::callcc(
        [&checkpoint](boost::context::continuation&& main) {
            checkpoint = 1;                    // ① 已经在新栈上执行
            main = std::move(main).resume();   // ② 切回主栈
            checkpoint = 3;                    // ④ 被再次恢复，继续执行
            return std::move(main);            // ⑤ 结束，控制权永远回主栈
        });
    checkpoint = 2;                            // ③ 主栈继续干活
    c = std::move(c).resume();                 // 恢复协程 → ④⑤

    std::cout << "checkpoint 顺序走完 = " << checkpoint << "（3 表示全部执行）\n";
    std::cout << "协程已结束（continuation 为空）? " << static_cast<bool>(c) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
