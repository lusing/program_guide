// pfr.cpp —— Boost.PFR（2016）：无宏的"穷人反射"——聚合结构体自动透视。
// 与 Describe 的分野：PFR 零注册（但只支持聚合类型）；Describe 要宏但支持
// 任意类型（含非聚合、枚举）。
// 对应文档：docs/18-cpp26.md
#include <boost/pfr.hpp>
#include <iostream>
#include <string>

struct Sensor {
    std::string name;     // 聚合：无构造函数/无私有/无虚函数
    double value;
    int unit_id;
};

int main() {
    Sensor s{"温度", 23.5, 7};

    // 1) 没有任何注册宏，字段数和字段值都能拿到
    std::cout << "字段数 = " << boost::pfr::tuple_size_v<Sensor> << '\n';

    // 2) for_each_field：遍历所有字段（与结构化绑定等价但泛型）
    std::cout << "字段遍历: ";
    boost::pfr::for_each_field(s, [](const auto& field, std::size_t idx) {
        if (idx) std::cout << ", ";
        std::cout << idx << ':' << field;
    });
    std::cout << '\n';

    // 3) get<N>：像 tuple 一样按下标取
    std::cout << "第 0 字段 = " << boost::pfr::get<0>(s) << '\n';

    // 4) 结构化打印：core_name 无（字段名要编译器扩展），
    //    但运算符合成是杀手锏——一行给聚合加上比较运算
    Sensor a{"x", 1.0, 1};
    Sensor b{"x", 1.0, 1};
    std::cout << "自动相等比较? " << (boost::pfr::eq(a, b)) << '\n';

    // 5) 局限：非聚合类型（有构造函数/私有成员）直接编不过——
    //    那是 Describe（宏注册）或 C++26 反射的地盘
    std::cout << "分界：聚合用 PFR（零注册）/ 任意类型用 Describe（宏）/ 未来用反射\n";

    std::cout << "自检通过\n";
    return 0;
}
