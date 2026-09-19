// metaparse.cpp —— Boost.Metaparse（2018）：在**编译期**解析字符串字面量——
// 让编译器把 "42" 变成 integral_constant<int, 42>。
// 对应文档：docs/27-classic-tmp.md
#include <boost/metaparse/string.hpp>
#include <boost/metaparse/build_parser.hpp>
#include <boost/metaparse/int_.hpp>
#include <boost/metaparse/token.hpp>
#include <boost/metaparse/entire_input.hpp>
#include <iostream>
#include <type_traits>

using namespace boost::metaparse;

// 编译期整数解析器：token<int_>（吃掉整数与空白）+ 全输入必须消耗完
using int_parser = build_parser<entire_input<token<int_>>>;

int main() {
    // BOOST_METAPARSE_STRING("42") 把字面量变成编译期字符串序列，
    // 解析器在编译期把它变成 mpl::int_<42>
    using parsed = int_parser::apply<BOOST_METAPARSE_STRING("42")>::type;
    static_assert(parsed::value == 42);
    std::cout << "编译期解析 \"42\" → " << parsed::value << '\n';

    // 复杂场景（原设计动机）：编译期解析类型名列表/DSL，
    // 例如把 "int,double" 解析成类型序列——运行期零开销
    std::cout << "（DSL 字面量 → 编译期数据结构 = Metaparse 的主场）\n";
    std::cout << "自检通过\n";
    return 0;
}
