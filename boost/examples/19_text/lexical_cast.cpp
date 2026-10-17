// lexical_cast.cpp —— Boost.LexicalCast（2000）：字符串 ↔ 数值的桥
//（数字场景被 C++17 std::from_chars/to_chars 及 stoi 族瓜分，但
//  泛型"any-to-string"仍是它的独门）
// 对应文档：docs/19-text.md
#include <boost/lexical_cast.hpp>
#include <iostream>
#include <string>

// 转换合同：源可流输出（operator<<）即可转出字符串——自定义类的门槛就这一条
struct demo_class {
    int v = 7;
};
inline std::ostream& operator<<(std::ostream& os, const demo_class& d) {
    return os << "demo_class#" << d.v;
}

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

    // 5) try_lexical_convert：不抛异常版（bool 返回值）——校验输入的首选
    int ok_val = 0;
    std::cout << "try_convert(\"42\")? "
              << boost::conversion::try_lexical_convert(std::string("42"), ok_val)
              << " try_convert(\"0x100\")? "
              << boost::conversion::try_lexical_convert(std::string("0x100"), ok_val)
              << "（0x 前缀不认）\n";
    // 由此一行写出"输入合法性校验"模板（书里的 num_valid）
    auto num_valid = []<typename T>(const char* s) {
        T tmp{};
        return boost::conversion::try_lexical_convert(std::string(s), tmp);
    };
    std::cout << "num_valid<int>(\"65535\")? " << num_valid.template operator()<int>("65535")
              << " num_valid<double>(\"3.14\")? "
              << num_valid.template operator()<double>("3.14")
              << " num_valid<int>(\"3.14\")? "
              << num_valid.template operator()<int>("3.14") << '\n';

    // 6) 转换合同三条（内部走流）：源可流输出 <<、目标可流输入 >> 且可
    //    默认构造/拷贝构造
    std::cout << "自定义类 → " << boost::lexical_cast<std::string>(demo_class{})
              << "（合同就是给个 operator<<）\n";

    // 7) bool 的边界：只认 "1"/"0"，不认 "true"/"false"（走流语义）
    bool b = boost::lexical_cast<bool>("1");
    std::cout << "bool 只认 1/0: lexical_cast<bool>(\"1\") = " << b << '\n';

    std::cout << "自检通过\n";
    return 0;
}
