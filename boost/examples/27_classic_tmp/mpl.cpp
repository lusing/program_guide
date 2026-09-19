// mpl.cpp —— Boost.MPL（2003）：古典 TMP 的丰碑——C++03 上建起的
// 编译期 STL。已被 mp11/hana 取代，但海量老代码与 Boost 内部仍用它的词汇。
// 对应文档：docs/27-classic-tmp.md
#include <boost/mpl/vector.hpp>
#include <boost/mpl/transform.hpp>
#include <boost/mpl/copy_if.hpp>
#include <boost/mpl/size.hpp>
#include <boost/mpl/at.hpp>
#include <boost/mpl/int.hpp>
#include <boost/mpl/plus.hpp>
#include <boost/mpl/accumulate.hpp>
#include <boost/mpl/equal_to.hpp>
#include <type_traits>
#include <iostream>

namespace mpl = boost::mpl;

int main() {
    using V = mpl::vector<int, float, double, char>;

    // 1) transform（注意 ::type——古典元函数的尾巴，mp11 干掉了它）
    using Ptrs = mpl::transform<V, std::add_pointer<mpl::_1>>::type;
    static_assert(std::is_same_v<mpl::at_c<Ptrs, 0>::type, int*>);
    std::cout << "transform → int* OK（比 mp11 多个 ::type）\n";

    // 2) copy_if（占位符 mpl::_1 是当年"模板 lambda"的写法）
    using Floats = mpl::copy_if<V, std::is_floating_point<mpl::_1>>::type;
    std::cout << "浮点数 = " << mpl::size<Floats>::value << " 个\n";

    // 3) accumulate：折叠常量
    using Cnts = mpl::vector<mpl::int_<1>, mpl::int_<2>, mpl::int_<3>>;
    using Sum = mpl::accumulate<Cnts, mpl::int_<0>, mpl::plus<mpl::_1, mpl::_2>>::type;
    std::cout << "accumulate 求和 = " << Sum::value << '\n';

    // 4) size 与 at
    std::cout << "size = " << mpl::size<V>::value
              << " at<2> = " << typeid(mpl::at_c<V, 2>::type).name() << '\n';

    // 5) 历史定位：MPL 定义了整套词汇（sequence/algorithm/metafunction），
    //    mp11 是它的现代化简，hana 是它的价值观重构
    std::cout << "自检通过\n";
    return 0;
}
