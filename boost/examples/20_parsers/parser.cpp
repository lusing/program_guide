// parser.cpp —— Boost.Parser（2024）：Spirit.Qi 的现代重制（C++20 版）。
// 作者（Zach Laine）把 Spirit 十几年的经验教训推倒重来：
// 更好的错误信息、更简单的动作绑定、concept 约束的接口。
// 对应文档：docs/20-parsers.md
#include <boost/parser/parser.hpp>
#include <iostream>
#include <string>
#include <vector>

namespace bp = boost::parser;

int main() {
    // 1) 基础：parser 表达式 + parse 入口（std::string_view 直接吃）
    auto ints = bp::int_ % ',';
    std::vector<int> v;
    auto r1 = bp::parse("1, 2, 3", ints, bp::ws, v);
    std::cout << "列表: " << r1 << " 个数 = " << v.size() << '\n';

    // 2) 属性自动组合：两个 int_ 相邻解析成 tuple<int,int>
    auto pair = bp::int_ >> bp::int_;
    std::tuple<int, int> t{0, 0};
    bool r2 = bp::parse("3 4", pair, bp::ws, t);
    std::cout << "元组: " << r2 << " = (" << std::get<0>(t) << ',' << std::get<1>(t) << ")\n";

    // 3) 带动作：解析时回调——动作收到的是"上下文"，属性用 _attr(ctx) 取。
    //    lambda 外面加括号：否则 [[ 开头会被解析成属性语法（C2760）
    int sum = 0;
    auto summed = bp::int_[([&sum](auto const& ctx) { sum += boost::parser::_attr(ctx); })] % ',';
    bp::parse("10,20,30", summed, bp::ws);
    std::cout << "动作求和 = " << sum << '\n';

    // 4) 期望运算符 >（expect）：比 >> 严格——失败带精确位置诊断。
    //    注意：expect 失败时默认错误处理器会往 stderr 打一行人话（这正是
    //    它的卖点）；本教程判定要求 stderr 恒空，所以例程只走成功路径
    auto strict = bp::int_ > ',' > bp::int_;
    auto r4 = bp::parse("5,6", strict, bp::ws);
    std::cout << "严格模式接受 \"5,6\"? " << static_cast<bool>(r4) << '\n';
    // bp::parse("5 6", strict, bp::ws) 会失败并在 stderr 报
    // "1:2: error: Expected ',' here:" ——真实项目里这就是排错信息

    std::cout << "自检通过\n";
    return 0;
}
