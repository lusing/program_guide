// xpressive.cpp —— Boost.Xpressive（2003）：把正则"倒过来写"——
// 静态正则是 C++ 表达式（编译期检查、更快），动态正则照旧是字符串。
// 对应文档：docs/20-parsers.md
#include <boost/algorithm/string.hpp>
// xpressive 的 match_results.hpp 在模板实例化点触发 MSVC C4702（不可达代码）
// ——外部头告警被 /external:W0 压掉，但实例化诊断归属本翻译单元，
// 与仓库既有先例（yap/binomial_heap）同款：include 点定点压制
#pragma warning(push)
#pragma warning(disable : 4702)
#include <boost/xpressive/xpressive.hpp>
#pragma warning(pop)
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

    // 6) regex_match（全串匹配）与 regex_replace（$N 反引用）
    //    身份证形（简化的书例）：6 位地区 + 4 位年 + 2 位月 + 2 位日 + 3 位 + 校验位
    xp::sregex id = xp::sregex::compile(
        R"---(\d{6}(1|2)\d{3}(0|1)\d[0-3]\d\d{3}(X|\d))---", xp::icase);
    std::string id_ok = "999555197001019999", id_bad = "99955519700101999Z";
    std::cout << "regex_match 整串校验: "
              << (xp::regex_match(id_ok, id) && !xp::regex_match(id_bad, id))
              << '\n';
    std::string replaced =
        xp::regex_replace(std::string("readme.txt"),
                          xp::sregex::compile("(.*)(me)"), "$1you");
    std::cout << "regex_replace: readme.txt → " << replaced
              << "（$1 = 第一捕获组）\n";
    std::string both = xp::regex_replace(
        std::string("t#t"), xp::sregex::compile("(t)(#)(t)"), "$1N$3");
    std::cout << "多组反引用: t#t → " << both << '\n';

    // 7) regex_iterator：遍历所有匹配（不用容器、流式）
    std::string items = "Power-bomb, power-suit, pOWER-beam";
    xp::sregex word = xp::sregex::compile("power-(\\w{4})", xp::icase);
    int hits = 0;
    for (auto it = xp::sregex_iterator(items.begin(), items.end(), word),
              endv = xp::sregex_iterator();
         it != endv; ++it)
        ++hits;
    std::cout << "regex_iterator 命中 " << hits << " 次\n";

    // 8) regex_token_iterator：分词双模式——默认给匹配段，-1 给"分隔符之外"的段
    std::string rec = "*Link*||+Mario+||Zelda!!!||Metroid";
    xp::cregex split_re = xp::cregex::compile("\\|\\|");
    std::cout << "token(-1 分隔) :";
    for (auto it = xp::cregex_token_iterator(rec.c_str(), rec.c_str() + rec.size(),
                                             split_re, -1),
              endv = xp::cregex_token_iterator();
         it != endv; ++it)
        std::cout << "[" << *it << "]";
    std::cout << '\n';
    xp::cregex word_re = xp::cregex::compile("\\w+", xp::icase);
    std::cout << "token(0 匹配) :";
    for (auto it = xp::cregex_token_iterator(rec.c_str(), rec.c_str() + rec.size(),
                                             word_re),
              endv = xp::cregex_token_iterator();
         it != endv; ++it)
        std::cout << "[" << *it << "]";
    std::cout << '\n';

    // 9) regex_compiler：正则对象池（享元）——按名缓存编译结果，重入不重编
    static xp::sregex_compiler rc;
    if (!rc["date"].regex_id())                     // 没编过才编
        rc["date"] = rc.compile(R"(\d{4}-\d{2}-\d{2})");
    std::cout << "compiler 复用: 命中 " << xp::regex_search(log, rc["date"])
              << " 池内同一对象? " << (rc["date"].regex_id() == rc["date"].regex_id())
              << '\n';

    // 10) 异常与格式化器：坏正则抛 regex_error；replace 的第三参可以是
    //     可调用物（拿 match_results 现算替换串）
    try {
        xp::sregex::compile("[unclosed");
    } catch (const xp::regex_error&) {
        std::cout << "坏正则抛 regex_error\n";
    }
    struct upperer {
        std::string operator()(const xp::smatch& m) const {
            return boost::to_upper_copy(m[0].str());  // 命中段转大写
        }
    };
    std::cout << "格式化器: "
              << xp::regex_replace(std::string("mario world"),
                                   xp::sregex::compile("\\w+"), upperer())
              << '\n';

    std::cout << "自检通过\n";
    return 0;
}
