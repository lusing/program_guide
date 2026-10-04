// 27 模板方法。
#include <cassert>
#include <print>
#include <string>

#include "crtp_method.hpp"
#include "template_method.hpp"

int main() {
    using namespace dp;

    // ---- 虚函数版：剧本固定，步骤各异 ----
    const Chess chess;
    const Go go;

    assert(chess.run() == "init chess;turn 1;turn 2;turn 3;check;end;");
    std::println("模板: Chess::run 剧本 = init->turn1..3->check(hook)->end");

    assert(go.run() == "init go;turn 1;turn 2;turn 3;end;");   // hook 吃默认空实现
    std::println("模板: Go::run 钩子默认空，剧本其余与 Chess 同构");

    // ---- CRTP 版：同一剧本，静态分派，输出逐字节一致 ----
    const ChessCRTP chess_s;
    const GoCRTP go_s;

    assert(chess_s.run() == chess.run());
    assert(go_s.run() == go.run());
    std::println("CRTP: 两盘棋输出与虚函数版逐字节一致（无虚表）");

    std::println("自检通过");
}
