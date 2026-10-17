// tuple.cpp —— Boost.Tuple：异构定长容器（std::tuple 的直系祖先，2002）
// 对应文档：docs/05-langbase.md
#include <boost/tuple/tuple.hpp>
#include <boost/tuple/tuple_comparison.hpp>
#include <boost/tuple/tuple_io.hpp>
#include <type_traits>
#include <iostream>
#include <string>

int main() {
    // 1) 构造与取值：get<N>() 是自由函数（std::tuple 相同）
    boost::tuple<int, std::string, double> item{1, "ada", 3.14};
    std::cout << "id=" << boost::get<0>(item)
              << " name=" << boost::get<1>(item)
              << " score=" << boost::get<2>(item) << '\n';

    // 2) make_tuple + tie：解包的祖师爷
    auto t = boost::make_tuple(7, std::string("x"));
    int a; std::string b;
    boost::tie(a, b) = t;                 // 一行解包（C++17 结构化绑定是它的续集）
    std::cout << "tie 解包: " << a << ',' << b << '\n';

    // 3) 比较运算：字典序（tie 实现的经典应用——结构体比较一行搞定）
    auto k1 = boost::make_tuple(1, std::string("a"));
    auto k2 = boost::make_tuple(1, std::string("b"));
    std::cout << "k1 < k2 ? " << std::boolalpha << (k1 < k2) << '\n';

    // 4) 对应的 std 版（C++11 毕业）+ C++17 结构化绑定
    std::tuple<int, std::string, double> s{2, "grace", 2.71};
    auto [id, name, score] = s;
    std::cout << "结构化绑定: " << id << ',' << name << ',' << score << '\n';

    // 5) std 独有而 boost 版没有的：tuple_size/tuple_element 元编程接口
    std::cout << "std::tuple_size = " << std::tuple_size_v<decltype(s)> << '\n';
    // boost 版的元接口叫 length/element（在 boost::tuples 名字空间）
    std::cout << "boost 版 length = " << boost::tuples::length<decltype(item)>::value
              << " 第 1 个元素类型是 string? "
              << std::is_same<boost::tuples::element<1, decltype(item)>::type,
                              std::string>::value << '\n';

    // 6) ignore 占位：只收一部分
    int first;
    boost::tie(first, boost::tuples::ignore, boost::tuples::ignore) = item;
    std::cout << "ignore 解包只收第一个 = " << first << '\n';
    // 【坑】交换陷阱：tie(a,b) = tie(b,a) 是"两次顺序赋值"不是交换——
    // 最后两个变量拿到同一个值。交换要写 tie(a,b) = make_tuple(b,a)。
    int x1 = 10, x2 = 20;
    boost::tie(x1, x2) = boost::make_tuple(x2, x1);   // 正确写法
    std::cout << "make_tuple 版交换 = " << x1 << ',' << x2 << '\n';

    // 7) 内部结构：cons 链表（head+tail 递归）+ null_type 哨兵——
    //    tuple<int,string,double> 概念上就是
    //    cons<int, cons<string, cons<double, null_type>>>
    auto& tail = item.get_tail();             // 尾部还是个（短一号的）链表头
    std::cout << "cons 链: 首元素 = " << item.get_head()
              << " 剥一层后首元素 = " << tail.get_head()
              << "（null_type 是递归终点哨兵）" << '\n';

    // 8) 流 I/O：默认括号空格格式（要含 tuple_io.hpp）
    std::cout << "默认输出: " << item << '\n';

    std::cout << "自检通过\n";
    return 0;
}
