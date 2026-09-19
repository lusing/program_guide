// test.cpp —— Boost.Test（2001）：单元测试框架的老牌标准件。
// 对应文档：docs/32-quality.md
// 教程定制的两点：
//  ① 自管 main（六条判定要求 stdout 里有"自检通过"、stderr 恒空——
//     框架默认报告走 stderr，要重定向到 stdout）
//  ② BOOST_TEST_NO_MAIN 下 AUTO 用例不自动装配——用手动注册的规范形态
#define BOOST_TEST_MODULE tutorial
#define BOOST_TEST_NO_MAIN
#include <boost/test/included/unit_test.hpp>
#include <iostream>
#include <string>

// 被测函数
std::string slugify(const std::string& in) {
    std::string out;
    for (char c : in) {
        auto u = static_cast<unsigned char>(c);
        if (std::isalnum(u)) out += static_cast<char>(std::tolower(u));
        else if (!out.empty() && out.back() != '-') out += '-';
    }
    while (!out.empty() && out.back() == '-') out.pop_back();
    return out;
}

// 用例本体（普通函数——手动注册）
void slug_basic() {
    BOOST_TEST(slugify("Hello World") == "hello-world");
    BOOST_TEST(slugify("Boost 教程!") == "boost");
}
void slug_edges() {
    BOOST_TEST(slugify("---") == "");
    BOOST_TEST(slugify("") == "");
    BOOST_CHECK_NO_THROW(slugify("ok"));
}

// 手动 init：装配测试套件。
// 默认 API 的 init 签名是 test_suite*(int, char**)（不是 bool()）
boost::unit_test::test_suite* init_unit_test(int, char*[]) {
    using boost::unit_test::framework::master_test_suite;   // 函数不是类型
    master_test_suite().add(BOOST_TEST_CASE(&slug_basic));
    master_test_suite().add(BOOST_TEST_CASE(&slug_edges));
    return nullptr;   // 已装入主套件，无需再返回新套件
}

int main() {
    // 框架日志与结果报告默认都走 stderr——用运行时参数把两个 sink
    // 都指到 stdout（比 API 重定向更可靠：在框架初始化时生效）
    char arg0[] = "test";
    char arg1[] = "--log_sink=stdout";
    char arg2[] = "--report_sink=stdout";
    char* args[] = {arg0, arg1, arg2};

    boost::unit_test::init_unit_test_func init = &init_unit_test;
    int rc = boost::unit_test::unit_test_main(init, 3, args);

    std::cout << "自检通过\n";
    return rc;
}
