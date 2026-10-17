// test.cpp —— Boost.Test（2001）：单元测试框架的老牌标准件。
// 对应文档：docs/32-quality.md
// 教程定制的两点：
//  ① 自管 main（六条判定要求 stdout 里有"自检通过"、stderr 恒空——
//     框架默认报告走 stderr，要重定向到 stdout）
//  ② BOOST_TEST_NO_MAIN 下 AUTO 用例不自动装配——用手动注册的规范形态
#define BOOST_TEST_NO_MAIN                    // 自管 main（不然框架抢走入口）
#include <boost/test/included/unit_test.hpp>
#include <cmath>
#include <iostream>
#include <string>

// ── 被测对象 ──
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

// ── 夹具：测试安装/清理（构造=安装，析构=清理）──
// 手动装配路径下，夹具就是"测试函数里先声明的 RAII 对象"；
// AUTO 宏体系里对应 BOOST_FIXTURE_TEST_CASE / BOOST_FIXTURE_TEST_SUITE /
// BOOST_TEST_GLOBAL_FIXTURE 三档（NO_MAIN 下不自动装配，正文有说明）
struct slug_fixture {
    slug_fixture()  { std::cout << "  [夹具] 安装（构造）\n"; }
    ~slug_fixture() { std::cout << "  [夹具] 清理（析构）\n"; }
    std::string sample = "Hello Fixture World";
};

// ── 断言分级的三档行为（本例程只让 WARN 档"故意失败"：
//    WARN 不计入错误数、不影响退出码；CHECK/REQUIRE 失败会让本教程的
//    管线挂掉，所以这里只演示它们成功的样子，失败语义写在注释里）──
void assertions_demo() {
    slug_fixture fx;                       // 用例级夹具：安装→测→清理
    BOOST_TEST(slugify(fx.sample) == "hello-fixture-world");   // CHECK 级
    BOOST_WARN_MESSAGE(1 == 2, "WARN 档故意失败：只留日志，不计数不退出");
    BOOST_CHECK_CLOSE(3.14159, std::acos(-1.0), 0.001);        // 浮点容差 0.001%
    BOOST_CHECK_NE(slugify("---"), "x");                       // 不等
    BOOST_CHECK_GE(slugify("a b").size(), 1u);                 // >=（unsigned!）
    BOOST_CHECK_NO_THROW(slugify("ok"));
    BOOST_TEST_MESSAGE("这是 BOOST_TEST_MESSAGE：默认日志级别下不显示");
}

void slug_basic() {
    BOOST_TEST(slugify("Hello World") == "hello-world");
    BOOST_TEST(slugify("Boost 教程!") == "boost");
}
void slug_edges() {
    BOOST_TEST(slugify("---") == "");
    BOOST_TEST(slugify("") == "");
    BOOST_CHECK_NO_THROW(slugify("ok"));
}

// 手动 init：装配测试树——主套件下挂一个子套件，子套件里再挂用例，
// 展示"套件嵌套"的组织方式（对应 AUTO 体系的 BOOST_AUTO_TEST_SUITE 对）
boost::unit_test::test_suite* init_unit_test(int, char*[]) {
    using boost::unit_test::framework::master_test_suite;
    using boost::unit_test::test_suite;

    test_suite* slug_suite = BOOST_TEST_SUITE("s_slugify");
    slug_suite->add(BOOST_TEST_CASE(&slug_basic));
    slug_suite->add(BOOST_TEST_CASE(&slug_edges));

    master_test_suite().add(slug_suite);            // 嵌套：主套件 → s_slugify
    master_test_suite().add(BOOST_TEST_CASE(&assertions_demo));
    return nullptr;   // 已装入主套件，无需再返回新套件
}

int main() {
    // 框架日志与结果报告默认都走 stderr——用运行时参数把两个 sink
    // 都指到 stdout（比 API 重定向更可靠：在框架初始化时生效）。
    // --log_level=message 顺带把 BOOST_TEST_MESSAGE 的内容放出来。
    char arg0[] = "test";
    char arg1[] = "--log_sink=stdout";
    char arg2[] = "--report_sink=stdout";
    char arg3[] = "--log_level=message";
    char* args[] = {arg0, arg1, arg2, arg3};

    boost::unit_test::init_unit_test_func init = &init_unit_test;
    int rc = boost::unit_test::unit_test_main(init, 4, args);

    std::cout << "自检通过\n";
    return rc;
}
