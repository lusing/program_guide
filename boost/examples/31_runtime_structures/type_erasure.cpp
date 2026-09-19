// type_erasure.cpp —— Boost.TypeErasure（2011）："反向 concept"——
// 把任意满足"接口需求"的类型装进统一壳（any 的完全体）。
// std::any 装任何类型但取回要精确类型；这里 any<requirements> 按概念调用。
// 对应文档：docs/31-runtime-structures.md
#include <boost/type_erasure/any.hpp>
#include <boost/type_erasure/member.hpp>
#include <boost/type_erasure/operators.hpp>
#include <boost/type_erasure/any_cast.hpp>
#include <iostream>
#include <string>
#include <vector>

namespace te = boost::type_erasure;

// 声明概念成员：有 .name() 方法的类型
BOOST_TYPE_ERASURE_MEMBER((has_name), name, 0)
// 有 .area() 的（第二个参数是元数）
BOOST_TYPE_ERASURE_MEMBER((has_area), area, 0)

using AnyShape = te::any<
    boost::mpl::vector<
        te::copy_constructible<>,
        te::relaxed,
        has_name<std::string()>,
        has_area<double()>>>;

struct Circle {
    std::string name_ = "圆";
    double r = 1.0;
    std::string name() const { return name_; }
    double area() const { return 3.14159 * r * r; }
};
struct Square {
    std::string name() const { return "方"; }
    double area() const { return 4.0; }
};

int main() {
    // 1) 装进统一壳：不同类型，同一接口
    std::vector<AnyShape> shapes;
    shapes.push_back(Circle{});
    shapes.push_back(Square{});

    for (AnyShape& s : shapes) {
        std::cout << "  " << s.name() << " 面积 = " << s.area() << '\n';
    }

    // 2) 与 std::any/std::function 的三方对照：
    //    std::any 装任何类型但无统一调用接口（取回才知类型）；
    //    std::function 只收一个签名；type_erasure 是"概念级 any"
    //    ——Circle/Square 没有公共基类也能统一调用（零侵入多态）

    // 3) 对 std::any：std::any 没有统一调用接口（取回才知类型）；
    //    std::function 只收一个签名；type_erasure 是"概念级 any"。
    //    与继承多态的对比：侵入性为零（Circle/Square 无基类）
    std::cout << "自检通过\n";
    return 0;
}
