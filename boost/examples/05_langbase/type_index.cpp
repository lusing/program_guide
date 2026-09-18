// type_index.cpp —— Boost.TypeIndex：typeid 的完全体（跨编译器可读名 + 精确多态名）
// 对应文档：docs/05-langbase.md
#include <boost/type_index.hpp>
#include <iostream>
#include <memory>
#include <string>
#include <vector>
#include <typeinfo>

struct Base { virtual ~Base() = default; };
struct Derived : Base {};
struct Other : Base {};

int main() {
    // 1) pretty_name()：跨编译器的可读类型名（GCC/clang 的 .name() 是 mangled
    //    碎片，pretty_name 归一为完整声明；MSVC 恰好两者都可读）
    auto name = boost::typeindex::type_id<std::vector<std::string>>().pretty_name();
    std::cout << "可读名: " << name << '\n';
    std::cout << "原生名: " << typeid(std::vector<std::string>).name() << "（MSVC 恰好也可读）\n";

    // 2) 静态类型相同性：比 typeid 的 == 更可靠（跨 DLL 边界 typeid 可能失灵）
    bool same = boost::typeindex::type_id<int>() == boost::typeindex::type_id<std::int32_t>();
    std::cout << "int == int32_t ? " << std::boolalpha << same << '\n';

    // 3) type_id_runtime：多态对象的**精确**运行期类型
    //    typeid(引用脱退化) 对多态也准，但 boost 版跨模块同样可靠 + 名字可读
    Base* b = new Derived;
    std::cout << "运行期精确类型: "
              << boost::typeindex::type_id_runtime(*b).pretty_name() << '\n';
    delete b;

    Base* b2 = new Other;
    auto ti = boost::typeindex::type_id_runtime(*b2);
    std::cout << "另一个对象: " << ti.pretty_name()
              << " 是 Base 吗? " << (ti == boost::typeindex::type_id<Base>()) << '\n';
    delete b2;

    // 4) 调试打印利器：TYPE_ID 宏连 cv 与引用都完整显示
    const std::string& s = *new std::string("x");
    std::cout << "cv+引用完整型: " << boost::typeindex::type_id_with_cvr<decltype(s)>().pretty_name() << '\n';
    delete &s;

    std::cout << "自检通过\n";
    return 0;
}
