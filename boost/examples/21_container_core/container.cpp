// container.cpp —— Boost.Container（2012）：std 容器的"先行+补完"双面人。
// std::flat_map（C++23）/static_vector→std::inplace_vector（C++26）从这里毕业；
// small_vector/stable_vector/hive 则是 std 没有的独门货。
// 对应文档：docs/21-container-core.md
#include <boost/container/container_fwd.hpp>
#include <boost/container/flat_map.hpp>
#include <boost/container/small_vector.hpp>
#include <boost/container/static_vector.hpp>
#include <boost/container/stable_vector.hpp>
#include <boost/container/devector.hpp>
#include <iostream>
#include <map>
#include <string>

int main() {
    // 1) flat_map：有序 map 的缓存友好实现（底层连续数组）。
    //    std::flat_map 是它的 C++23 直系毕业
    boost::container::flat_map<std::string, int> fm;
    fm["banana"] = 2; fm["apple"] = 1; fm["cherry"] = 3;
    std::cout << "flat_map: " << fm["apple"] << ' ' << fm.at("banana")
              << "（有序遍历首键 = " << fm.begin()->first << "）\n";

    // 2) small_vector：栈上预置 N 个元素，超了才上堆——函数局部小数组的
    //    默认选择（std::vector 永远上堆）
    boost::container::small_vector<int, 8> sv;
    for (int i = 1; i <= 10; ++i) sv.push_back(i);
    std::cout << "small_vector: 前 8 个在栈上, 共 " << sv.size() << " 个\n";

    // 3) static_vector：定容、永不上堆（C++26 std::inplace_vector 直系）
    boost::container::static_vector<int, 4> fixed;
    fixed.push_back(1); fixed.push_back(2); fixed.push_back(3); fixed.push_back(4);
    std::cout << "static_vector: 满 " << fixed.size() << '/' << fixed.capacity() << '\n';

    // 4) stable_vector：元素地址永不变（节点式），但保留随机访问
    boost::container::stable_vector<int> stv{10, 20, 30};
    stv.insert(stv.begin(), 5);
    std::cout << "stable_vector: " << stv[0] << ' ' << stv[1] << ' ' << stv[2]
              << ' ' << stv[3] << "（插入后旧元素地址不变）\n";

    // 5) devector：两端高效 + 中间连续（vector 和 deque 的合体）
    boost::container::devector<int> dv;
    dv.push_back(2); dv.push_back(3);
    dv.push_front(1);
    std::cout << "devector: " << dv[0] << dv[1] << dv[2] << "（首插不搬移）\n";

    // 6) std 对照：std::map 是节点式红黑树——查找跳缓存；
    //    flat_map 有序数组二分——读多写少的配置表快 3-10 倍
    std::map<std::string, int> ref{{"apple", 1}};
    std::cout << "std::map 大小 = " << ref.size() << "（对照用）\n";

    std::cout << "自检通过\n";
    return 0;
}
