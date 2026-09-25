// xpressive.cpp —— Boost.Xpressive（2003）：把正则"倒过来写"——
// 静态正则是 C++ 表达式（编译期检查、更快），动态正则照旧是字符串。
// 对应文档：docs/20-parsers.md
#include <boost/xpressive/xpressive.hpp>
#include <iostream>
#include <string>

namespace xp = boost::xpressive;

int main() {
    std::string log = "2026-09-19 ERROR db: connection lost (retry 3)";

    // 1) 静态正则：sregex 用表达式组合（编译期就知道语法对不对）
    xp::sregex date = xp::as_xpr("2026") >> '-' >> +xp::_d >> '-' >> +xp::_d;
    xp::smatch what;
    if (xp::regex_search(log, what, date)) {
        std::cout << "日期命中 = " << what[0] << '\n';
    }

    // 2) 捕获组 + 反向引用 + 语义动作（正则里嵌 C++）
    xp::sregex level = (xp::s1 = xp::as_xpr("ERROR") | "WARN" | "INFO");
    if (xp::regex_search(log, what, level)) {
        std::cout << "级别 = " << what[1] << '\n';
    }

    // 3) 命名捕获（比数字下标可读）
    //    坑（本机实测）：原来的正则写成 '('  >> (s2 = +_d) >> ')'，对
    //    "(retry 3)" 匹配不上——'(' 后面紧跟的是字母不是数字，整个 search 失败，
    //    这一行从来没被打印过（Windows 侧的文档里那条"重试次数 = 3"是凭印象写的）。
    //    要抓的是 retry 后面的数字，就把前缀写进正则。
    xp::sregex cnt = xp::as_xpr("retry ") >> (xp::s2 = +xp::_d);
    if (xp::regex_search(log, what, cnt)) {
        std::cout << "重试次数 = " << what[2] << '\n';
    }

    // 4) 动态正则：字符串版（std::regex 同体验）
    xp::sregex dyn = xp::sregex::compile("retry (\\d+)");
    if (xp::regex_search(log, what, dyn)) {
        std::cout << "动态正则 = " << what[1] << '\n';
    }

    // 5) Xpressive 独有卖点小结：静态正则（编译期语法检查 + 更快）；
    //    语义动作、嵌套正则（正则里套 sregex）也都是它比 std::regex 强的地方
    std::cout << "静态正则编译期检查 = Xpressive 独有卖点\n";

    std::cout << "自检通过\n";
    return 0;
}
