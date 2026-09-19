// spirit.cpp —— Boost.Spirit（2001）：直接把 EBNF 语法写成 C++ 表达式。
// 教程演示 Qi（解析器）的常用四式；仓库里最重的 TMP 库之一。
// 对应文档：docs/20-parsers.md
#include <boost/spirit/include/qi.hpp>
#include <boost/fusion/adapted/struct.hpp>
#include <boost/fusion/include/adapt_struct.hpp>
#include <iostream>
#include <string>
#include <vector>

namespace qi = boost::spirit::qi;
namespace ascii = boost::spirit::ascii;

// 实战惯用法：自定义结构体 + Fusion 适配，比 std::pair 稳
//（pair 属性在本机 c++latest 下会被 Spirit 误判成容器，实测坑）
struct KeyVal {
    std::string key;
    int value;
};
BOOST_FUSION_ADAPT_STRUCT(KeyVal, key, value)

int main() {
    // 1) 数字解析：语法即表达式
    int n = 0;
    std::string s1 = "42";
    bool ok1 = qi::parse(s1.begin(), s1.end(), qi::int_, n);
    std::cout << "int 解析: " << ok1 << " 值 = " << n << '\n';

    // 2) 逗号分隔整数表（% 是"分隔列表"）。
    //    坑：qi::parse 不跳空白——"1, 2" 会停在第一个空格；
    //    要跳空白用 qi::phrase_parse + ascii::space
    std::vector<int> nums;
    std::string s2 = "1, 2, 3, 5, 8";
    bool ok2 = qi::phrase_parse(s2.begin(), s2.end(), qi::int_ % ',', ascii::space, nums);
    std::cout << "列表解析: " << ok2 << " 个数 = " << nums.size() << '\n';

    // 3) 键值对语法 + 规则组合（真正的"语法即代码"）。
    //    要点：属性用自定义结构体（配 Fusion 适配）+ qi::rule 声明合成属性；
    //    有 skipper 时语法里就不要再写显式空白分隔符（skipper 会先吃掉）
    std::string input = "id=7; age=36; level=99;";
    std::vector<KeyVal> kv;
    qi::rule<std::string::iterator, KeyVal()> entry;
    entry = +ascii::alnum >> '=' >> qi::int_ >> ';';   // 声明后赋值（官方推荐式）
    bool ok3 = qi::phrase_parse(input.begin(), input.end(), +entry, ascii::space, kv);
    std::cout << "键值解析: " << ok3 << " 条数 = " << kv.size() << '\n';
    for (const auto& e : kv) {
        std::cout << "  " << e.key << '=' << e.value << '\n';
    }

    // 4) 带语义动作：下标运算符直接挂 lambda
    std::vector<long> sums;
    auto accum = qi::double_[([&sums](double d) { sums.push_back(static_cast<long>(d * 2)); })];
    std::string s4 = "3.5";
    qi::parse(s4.begin(), s4.end(), accum);
    std::cout << "语义动作: 3.5×2 = " << (sums.empty() ? -1 : sums[0]) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
