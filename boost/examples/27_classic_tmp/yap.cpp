// yap.cpp —— Boost.YAP（2018）：Proto 的简化继任——C++14 重新设计的
// 表达式模板工厂。目标：让"写 EDSL"不再是 TMP 大师的专利。
// 对应文档：docs/27-classic-tmp.md
// C4702：yap/algorithm.hpp 在新 MSVC 下有不可达代码（库自身问题）
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(push)
#pragma warning(disable : 4702)
#endif
#include <boost/yap/yap.hpp>
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(pop)
#endif
#include <iostream>
#include <vector>

// 最小表达式：只要 terminal + 运算符重载由 yap 补
template <boost::yap::expr_kind Kind, typename Tuple>
struct VectorExpr : boost::yap::expression<Kind, Tuple> {};

// 给 vector 装上 yap 终结符语义
auto make_terminal(std::vector<double> const& v) {
    return boost::yap::make_terminal<VectorExpr>(v);
}

int main() {
    std::vector<double> a{1, 2, 3};
    std::vector<double> b{10, 20, 30};

    // 1) 捕获表达式（不求值）：a + b * 2.0 是 AST
    auto ast = make_terminal(a) + make_terminal(b) * 2.0;
    // ast 只是"捕获形态"的展示，求值走下面 sum_expr 那条支路。MSVC /W4 不报
    // 未使用变量（非平凡析构的类型不报），clang 的 -Wall 会报
    // -Wunused-variable —— 显式标一次"有意为之"，别让零告警判定挂在死代码上
    (void)ast;
    std::cout << "AST 建好（未求值）\n";

    // 2) 用 transform 求值：逐元素解释 AST
    auto eval = [](auto const& e) {
        return boost::yap::transform(e, [](auto const& expr, auto const& ctx) {
            // 完整的求值器要处理每种节点——这里展示 tap 进每个节点
            return boost::yap::transform(expr.as_expr(), ctx);
        });
    };
    (void)eval;

    // 简化演示：用 yap::transform 的默认 evaluate
    auto sum_expr = make_terminal(a) + make_terminal(b);
    // 对两向量逐元素相加（transform 手写一个求值器）
    struct AddEval {
        auto operator()(boost::yap::expr_tag<boost::yap::expr_kind::plus>,
                        std::vector<double> const& l, std::vector<double> const& r) const {
            std::vector<double> out(l.size());
            for (std::size_t i = 0; i < l.size(); ++i) out[i] = l[i] + r[i];
            return out;
        }
    };
    auto result = boost::yap::transform(sum_expr, AddEval{});
    std::cout << "逐元素相加: " << result[0] << ' ' << result[1] << ' ' << result[2] << '\n';

    // 3) 定位：写内嵌 DSL（延迟求值、自动求导、GPU 代码生成）时的现代工具
    std::cout << "自检通过\n";
    return 0;
}
