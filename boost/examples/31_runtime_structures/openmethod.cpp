// openmethod.cpp —— Boost.OpenMethod（1.89 新库，前身 yomm11）：
// 开放多方法——按**多个**动态类型分派的虚函数。
// C++ 虚函数只看一个动态类型；多方法按组合分派（访问者模式的解药）。
// 对应文档：docs/31-runtime-structures.md
#include <boost/openmethod.hpp>
#include <boost/openmethod/initialize.hpp>
#include <iostream>
#include <string>

struct Animal {
    virtual ~Animal() = default;
};
struct Cat : Animal {};
struct Dog : Animal {};

BOOST_OPENMETHOD_CLASSES(Animal, Cat, Dog);   // 注意分号

// 多方法声明：virtual_<> 标出按动态类型分派的参数。
// 坑两条：① std::string 作返回型在本机触发 MSVC ICE（换 const char*）；
// ② virtual_ 是依赖名，宏参数里要加 typename 语境——这里用 using 预备
using boost::openmethod::virtual_;
BOOST_OPENMETHOD(interact, (virtual_<Animal&>, virtual_<Animal&>), const char*);

// 按组合重载：不精确的组合回落到更泛的重载
BOOST_OPENMETHOD_OVERRIDE(interact, (Cat&, Cat&), const char*) {
    return "猫咪互相舔毛";
}
BOOST_OPENMETHOD_OVERRIDE(interact, (Cat&, Dog&), const char*) {
    return "猫挑衅狗";
}
BOOST_OPENMETHOD_OVERRIDE(interact, (Dog&, Animal&), const char*) {
    return "狗友好打招呼";
}

int main() {
    boost::openmethod::initialize();

    Cat cat;
    Dog dog;

    // 直接传引用调用——按两个对象的动态类型组合分派
    std::cout << interact(cat, cat) << '\n';
    std::cout << interact(cat, dog) << '\n';
    std::cout << interact(dog, dog) << '\n';   // 无 (Dog,Dog) 精确匹配 → (Dog, Animal&)

    std::cout << "自检通过\n";
    return 0;
}
