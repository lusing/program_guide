// 36 表达式求值器：parse -> eval / eval_cached 全链路 + 语法错误与未定义变量。
#include <cassert>
#include <print>
#include <string>
#include <utility>
#include <vector>

#include "eval.hpp"

int main() {
    using namespace dp;

    const std::vector<std::pair<std::string, double>> env{{"x", 3.0}, {"y", 4.0}};

    // parse("2*x + y")：递归下降建树，eval 得 10
    auto ast = parse("2*x + y");
    assert(ast.has_value());
    auto r = eval(*ast, env);
    assert(r.has_value());
    assert(*r == 10.0);                    // 2*3 + 4，双精度精确值
    std::println("求值线: 2*x + y 在 x=3,y=4 上 = 10");

    // 空格容忍 + 括号优先级
    auto ast2 = parse("( x + 1 ) * y");
    assert(ast2.has_value());
    auto r2 = eval(*ast2, env);
    assert(r2.has_value());
    assert(*r2 == 16.0);                   // (3+1)*4
    std::println("结构线: ( x + 1 ) * y = 16，括号与空格均按合同处理");

    // 语法错误："2+*" 走 expected 错误路径
    auto bad = parse("2+*");
    assert(!bad.has_value());
    assert(bad.error().find("unexpected") != std::string::npos);
    std::println("错误线: 2+* 被拒，error 含 unexpected 位置信息");

    // 未定义变量：求值期错误（语法正确、语义越界）
    auto ast3 = parse("z + 1");
    assert(ast3.has_value());
    auto r3 = eval(*ast3, env);
    assert(r3.has_value() == false);
    assert(r3.error().find("undefined variable: z") != std::string::npos);
    std::println("错误线: 未定义变量 z 报 undefined variable，错误可断言");

    // 备忘录：重复出现的 x 第二次走缓存，hits 计数
    auto ast4 = parse("x * x + y");        // x 出现两次
    assert(ast4.has_value());
    Memo memo;
    auto r4 = eval_cached(*ast4, env, memo);
    assert(r4.has_value());
    assert(*r4 == 13.0);                   // 3*3 + 4
    assert(memo.hits == 1);                // 第二个 x 命中缓存一次
    std::println("缓存线: x*x+y 求值 13，memo 命中 1 次");

    // 对照：不带缓存的同一表达式结果一致
    auto r5 = eval(*ast4, env);
    assert(r5.has_value() && *r5 == 13.0);
    std::println("对拍线: eval 与 eval_cached 结果一致");

    std::println("自检通过");
}
