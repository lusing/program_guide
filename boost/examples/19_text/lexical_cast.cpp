// lexical_cast.cpp —— Boost.LexicalCast（2000）：字符串 ↔ 数值的桥
//（数字场景被 C++17 std::from_chars/to_chars 及 stoi 族瓜分，但
//  泛型"any-to-string"仍是它的独门）
// 对应文档：docs/19-text.md
#include <boost/lexical_cast.hpp>
#include <iostream>
#include <string>

int main() {
    // 1) 数值 → 字符串（任意可流输出类型）
    std::string s = boost::lexical_cast<std::string>(3.14159);
    std::cout << "数值→串 = " << s << '\n';

    // 2) 字符串 → 数值（失败抛 bad_lexical_cast，不是 UB）
    int n = boost::lexical_cast<int>("42");
    std::cout << "串→int = " << n << '\n';
    try {
        boost::lexical_cast<int>("4.2");        // 不完整转换
    } catch (const boost::bad_lexical_cast&) {
        std::cout << "坏转换被抓住: bad_lexical_cast" << '\n';
    }

    // 3) 泛型代码里的 one-liner：T ↔ U 只要都能流进出
    double d = boost::lexical_cast<double>("2.71");
    std::cout << "串→double = " << d << '\n';

    // 4) std 对照：数字场景用 stoi/to_string/std::to_chars（更快）；
    //    但"模板 T 转字符串"这种泛型场景，lexical_cast 仍是最短答案
    std::cout << "std 版 = " << std::to_string(42) << "（非泛型，仅内置类型）\n";

    std::cout << "自检通过\n";
    return 0;
}
