// parameter.cpp —— Boost.Parameter：命名参数（22 个参数只要传 3 个的那种 API）
// 对应文档：docs/04-function.md
#include <boost/parameter.hpp>
#include <iostream>
#include <string>
#include <map>

BOOST_PARAMETER_NAME(title)     // 定义参数关键字 _title
BOOST_PARAMETER_NAME(width)
BOOST_PARAMETER_NAME(color)

// 函数签名声明"我接受这些命名参数，各自有默认值，顺序随便"
// 语法注意：多个可选参数共用一个 (optional ...) 组，缺省值里逗号要加括号
// C4003（PP 序列判空的固有告警）和 C4100（宏生成的转发参数未引用）
// 都是宏展开噪声，不是代码问题
#pragma warning(push)
#pragma warning(disable : 4003 4100)
BOOST_PARAMETER_FUNCTION(
    (void), render,
    tag,                                   // 关键字前缀
    (optional
        (title, *, std::string("untitled"))
        (width, *, 80)
        (color, *, (std::string("black"))))
) {
    std::cout << "render title=" << title << " width=" << width
              << " color=" << color << '\n';
}
#pragma warning(pop)

int main() {
    // 顺序无关 + 任意省略——1990 年代 Python 风格 API 在 C++03 的实现
    render();
    render(_width = 120);
    render(_color = "red", _title = "chart");   // 顺序乱给也行

    // 对比 C++20 指定初始化器：同样达到"命名+默认"效果，但有两个限制——
    // ① 必须按成员声明顺序写（下面交换 color/width 的顺序就是编译错误），
    // ② 参数得先聚合成一个 struct；Boost.Parameter 两条都不用
    struct RenderOpts {
        std::string title = "untitled";
        int width = 80;
        std::string color = "black";
    };
    RenderOpts o2{.width = 40, .color = "blue"};   // C++20：字段名调用（按序）
    std::cout << "C++20 指定初始化 title=" << o2.title << " width=" << o2.width
              << " color=" << o2.color << '\n';

    std::cout << "自检通过\n";
    return 0;
}
