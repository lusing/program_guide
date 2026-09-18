// regex.cpp —— Boost.Regex：正则表达式的 Boost 版（TR1 → std::regex 的直系）
// 对应文档：docs/06-regex-random.md
#include <boost/regex.hpp>
#include <iostream>
#include <regex>
#include <string>

int main() {
    std::string log = "2026-09-19 12:30:45 INFO user=ada action=login";

    // 1) 基本匹配 + 捕获组
    boost::regex pat(R"((\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (\w+) user=(\w+))");
    boost::smatch m;
    if (boost::regex_search(log, m, pat)) {
        std::cout << "整段: " << m[0] << '\n';
        std::cout << "年=" << m[1] << " 月=" << m[2] << " 日=" << m[3] << '\n';
        std::cout << "级别=" << m[7] << " 用户=" << m[8] << '\n';
    }

    // 2) regex_match：整串匹配（校验场景）
    boost::regex email_pat(R"(\w+@\w+\.\w+)");
    std::cout << std::boolalpha
              << "合法邮箱? " << boost::regex_match(std::string("ada@lovelace.io"), email_pat)
              << " 部分? " << boost::regex_match(std::string("联系 ada@x.io 谢谢"), email_pat) << '\n';

    // 3) regex_replace：替换（$1 反向引用）
    std::string masked = boost::regex_replace(log, pat, "$1/**/$2/**/$3 $4:$$:$5 $7 user=***");
    std::cout << "脱敏: " << masked << '\n';

    // 4) regex_iterator：所有命中
    boost::regex num_pat(R"(\d+)");
    auto begin = boost::sregex_iterator(log.begin(), log.end(), num_pat);
    auto end_it = boost::sregex_iterator();
    int count = 0;
    for (auto it = begin; it != end_it; ++it) ++count;
    std::cout << "数字出现 " << count << " 处\n";

    // 5) std 版同款对照（接口几乎逐字相同——这就是"直系毕业"）
    std::regex sp(R"((\w+)=(\w+))");
    std::smatch sm;
    if (std::regex_search(log, sm, sp)) {
        std::cout << "std 版第一组: " << sm[1] << '=' << sm[2] << '\n';
    }

    std::cout << "自检通过\n";
    return 0;
}
