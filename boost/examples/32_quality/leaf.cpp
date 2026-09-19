// leaf.cpp —— Boost.LEAF（2019）：低开销的错误负载传播——
// "错误对象不随异常走，错误上下文按需收集"。
// 对照 Outcome（17 章）：LEAF 面向异常路径，Outcome 面向返回值。
// 对应文档：docs/32-quality.md
#include <boost/leaf.hpp>
#include <iostream>
#include <string>

namespace leaf = boost::leaf;

// 错误负载：多个小组件，沿途各层各贴一张
struct e_file { std::string value; };
struct e_line { int value; };

// 深层函数只管抛（负载零侵入——它什么都不知道）
int parse_config() {
    throw std::runtime_error("解析失败");
}

int main() {
    // 1) 抛出点之外贴上下文：on_error 返回 RAII 守卫，挂到错误上
    int rc = leaf::try_catch(
        []() -> int {
            auto load = leaf::on_error(e_file{"config.ini"}, e_line{42});
            return parse_config();            // 异常发生时守卫把负载带走
        },
        [](std::runtime_error const& e, e_file const& f, e_line const& l) {
            std::cout << "捕获: " << e.what() << " 文件=" << f.value
                      << " 行=" << l.value << '\n';
            return 0;
        },
        []() {                       // try_catch 的兜底是无参 handler
            std::cout << "负载不全\n";
            return -1;
        });
    std::cout << "全负载 rc = " << rc << '\n';

    // 2) 只贴一部分：handler 要求的负载不全 → 走兜底
    int rc2 = leaf::try_catch(
        []() -> int {
            auto load = leaf::on_error(e_file{"other.ini"});   // 少了 e_line
            return parse_config();
        },
        [](std::runtime_error const& e, e_file const& f, e_line const& l) {
            (void)e; (void)f; (void)l;
            return 0;                                            // 不会进这里
        },
        []() {
            std::cout << "负载不全走兜底（符合预期）\n";
            return -1;
        });
    std::cout << "半负载 rc = " << rc2 << '\n';

    std::cout << "自检通过\n";
    return 0;
}
