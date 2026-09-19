// flyweight.cpp —— Boost.Flyweight（2004）：享元模式库化——
// 大量重复的不可变对象（字符串、颜色、棋子）共享唯一实例。
// 对应文档：docs/22-container-zoo.md
#include <boost/flyweight.hpp>
#include <boost/flyweight/no_tracking.hpp>
#include <iostream>
#include <string>
#include <set>

using boost::flyweight;
using boost::flyweights::flyweight;
using boost::flyweights::no_tracking;

struct Tree {
    int x, y;
    flyweight<std::string> species;     // 一万棵树共享 "松树" 的一个实例
};

int main() {
    // 1) 相同内容 → 同一底层实例
    flyweight<std::string> a(std::string("橡树"));
    flyweight<std::string> b(std::string("橡树"));
    std::cout << "同串共享底层? " << (&a.get() == &b.get()) << '\n';

    // 2) 与 std::set 互通：key 等价性靠内容
    std::set<flyweight<std::string>> forest;
    for (int i = 0; i < 1000; ++i) {
        forest.insert(flyweight<std::string>("杉树" + std::to_string(i % 5)));   // 1000 次插入 5 个真实例
    }
    std::cout << "set 大小 = " << forest.size() << "（真正分配的字符串只有 5 个）\n";

    // 3) 结构体里的享元：一森林一树种名
    Tree t1{10, 20, flyweight<std::string>(std::string("松树"))};
    Tree t2{30, 40, flyweight<std::string>(std::string("松树"))};
    std::cout << "两棵树共享树种名? " << (&t1.species.get() == &t2.species.get()) << '\n';

    // 4) 透明性：flyweight<T> 用起来就像 T
    std::string s = t1.species;         // 隐式转回 string
    std::cout << "透明取用 = " << s << '\n';

    std::cout << "自检通过\n";
    return 0;
}
