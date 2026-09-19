// tokenizer.cpp —— Boost.Tokenizer（2001）：按策略切分——比 split 更省内存
// （逐段产出，不建容器）
// 对应文档：docs/19-text.md
#include <boost/tokenizer.hpp>
#include <iostream>
#include <string>

int main() {
    std::string csv = "ada,lovelace;36,\"计算,数学\"";

    // 1) char_separator：精确控制分隔符与"保留谁"
    using tokenizer = boost::tokenizer<boost::char_separator<char>>;
    boost::char_separator<char> sep(",;");
    tokenizer toks(csv, sep);
    std::cout << "分词:";
    for (const auto& t : toks) std::cout << " [" << t << "]";
    std::cout << '\n';

    // 2) escaped_list_separator：CSV 语义——引号内的分隔符不算数
    using csv_tok = boost::tokenizer<boost::escaped_list_separator<char>>;
    csv_tok csv_rows(csv);
    std::cout << "CSV:";
    for (const auto& t : csv_rows) std::cout << " [" << t << "]";
    std::cout << '\n';

    // 3) offset_separator：定长切片（固定宽度记录文件）。
    //    构造要给迭代器对，不给 initializer_list（会被误配成 bool 参数）
    std::string fixed = "ada036grace085";
    const int lens[4] = {3, 3, 3, 3};
    boost::offset_separator offs(std::begin(lens), std::end(lens));
    boost::tokenizer<boost::offset_separator> fixed_toks(fixed, offs);
    std::cout << "定长:";
    for (const auto& t : fixed_toks) std::cout << " [" << t << "]";
    std::cout << "（尾段不足 3 也保留——partial 默认开）\n";

    // 4) 与 split 的分界：tokenizer 是迭代器（流式，无中间容器），
    //    split 一次性产出 vector——大文件/高频路径用 tokenizer
    std::cout << "自检通过\n";
    return 0;
}
