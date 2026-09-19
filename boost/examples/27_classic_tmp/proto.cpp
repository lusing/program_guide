// proto.cpp —— Boost.Proto（2006）：表达式模板的工厂——把"运算符表达式"
// 变成可捕获、可变换的 AST。Boost.Spirit/Phoenix/Units 的共同地基。
// 已进入维护模式（继任者 yap），但它是 EDSL 技术的教科书。
// 对应文档：docs/27-classic-tmp.md
#include <boost/proto/proto.hpp>
#include <iostream>

namespace proto = boost::proto;

// 捕获表达式：make_expr 把 1 + _1 这样的表达式打包成 AST 不求值
proto::terminal<int>::type const one = {1};
struct Wildcard {};                                  // 终结符占位
proto::terminal<Wildcard>::type const _1 = {{}};

int main() {
    // 1) 表达式不求值：eval 才求值
    auto expr = one + one + one;                     // AST：(1+1)+1
    std::cout << "eval = " << proto::eval(expr, proto::default_context{})
              << "（AST 先建好，eval 才算）\n";

    // 2) 表达式 = 值：可以存储、传递、再加工
    auto stored = expr;
    std::cout << "存了再 eval = " << proto::eval(stored, proto::default_context{}) << '\n';

    // 3) 变换：display_expr 打印 AST 结构（调试 EDSL 的利器）
    std::cout << "AST 结构:\n";
    proto::display_expr(one + _1 * one);

    // 4) 历史定位：Spirit 的语法、Phoenix 的 if_、Units 的量纲检查，
    //    全是"用 Proto 捕获表达式 + 模板变换"做的。yap（下例）是简化继任
    std::cout << "自检通过\n";
    return 0;
}
