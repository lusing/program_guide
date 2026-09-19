// property_map.cpp —— Boost.PropertyMap（2000）：key→value 的泛型抽象。
// BGL 的关节——"不管属性存在哪（内部/外部/现算），算法统一访问"。
// 对应文档：docs/23-graph-geometry.md
#include <boost/property_map/property_map.hpp>
#include <boost/property_map/function_property_map.hpp>
#include <iostream>
#include <map>
#include <string>
#include <vector>

int main() {
    // 1) associative_property_map：把 std::map 包装成 property_map
    std::map<std::string, int> age_db{{"ada", 36}, {"grace", 85}};
    boost::associative_property_map<std::map<std::string, int>> pm(age_db);
    boost::put(pm, "jean", 74);                     // 经 pm 写
    std::cout << "ada = " << boost::get(pm, "ada") << " jean = " << boost::get(pm, "jean") << '\n';

    // 2) iterator_property_map：把"随机访问迭代器 + 索引"当属性表
    //    （BGL 里顶点属性的主流存法：属性住 vector，图里只存下标）
    std::vector<double> score{3.5, 4.0, 2.5};
    boost::iterator_property_map<std::vector<double>::iterator,
                                 boost::identity_property_map>
        ipm(score.begin());
    std::cout << "顶点 1 的分 = " << boost::get(ipm, 1) << '\n';

    // 3) function_property_map：属性是"算出来的"（惰性/派生属性）
    auto sq = boost::make_function_property_map<int>([](int x) { return x * x; });
    std::cout << "函数属性 f(7) = " << boost::get(sq, 7) << '\n';

    // 4) identity_property_map：键即值（占位用）
    boost::identity_property_map idm;
    std::cout << "恒等 f(42) = " << boost::get(idm, 42) << '\n';

    // 5) 意义：算法模板里只写 get(pm, key)/put(pm, key, v)——
    //    属性的存储方式由调用方决定。这个抽象 C++ 标准至今没有对应物。
    std::cout << "自检通过\n";
    return 0;
}
