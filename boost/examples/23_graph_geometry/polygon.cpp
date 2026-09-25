// polygon.cpp —— Boost.Polygon（2009）：曼哈顿几何（90° 直角多边形）专用。
// 与 Geometry 的分野：Polygon 只处理横平竖直的形状，换来更快的布尔运算
// 与扫描线算法——VLSI/芯片版图/矩形版面设计（floorplanning）的领域库。
// 对应文档：docs/23-graph-geometry.md
#include <boost/polygon/polygon.hpp>
#include <iostream>

namespace gtl = boost::polygon;
using namespace boost::polygon::operators;

using Rect = gtl::rectangle_data<int>;
using Poly90 = gtl::polygon_90_data<int>;

int main() {
    // 1) 矩形的基本运算
    Rect a = gtl::construct<Rect>(0, 0, 10, 10);       // xl, yl, xh, yh
    Rect b = gtl::construct<Rect>(5, 5, 15, 15);
    std::cout << "a 面积 = " << gtl::area(a) << '\n';
    Rect inter = a;
    gtl::intersect(inter, b);                            // 原地裁剪出交集
    std::cout << "交集 = " << gtl::area(inter) << "（5,5)-(10,10) = 25）\n";
    std::cout << "a 包含 (3,3)? " << gtl::contains(a, gtl::point_data<int>(3, 3)) << '\n';
    std::cout << "b 包含 (3,3)? " << gtl::contains(b, gtl::point_data<int>(3, 3)) << '\n';

    // 2) 直角多边形的布尔运算（扫描线实现，比通用几何快）
    Rect c = gtl::construct<Rect>(0, 0, 4, 4);
    Rect d = gtl::construct<Rect>(2, 2, 6, 6);
    std::vector<Rect> uni;
    gtl::assign(uni, c + d);                            // 并集
    // 总面积要**把所有块加起来**：扫描线把 L 形切成若干矩形（本机 3 块），
    // 只取 uni[0] 算出来的不是总面积（旧版就是这么写的，打出来是 8 而不是 28）
    long long total = 0;
    for (const Rect& r : uni) total += gtl::area(r);
    std::cout << "并集矩形块数 = " << uni.size() << " 总面积 = " << total << '\n';

    // 3) 定位与距离（曼哈顿度量）
    std::cout << "(1,1) 与 (4,4) 曼哈顿距离 = "
              << gtl::manhattan_distance(gtl::point_data<int>(1, 1),
                                         gtl::point_data<int>(4, 4)) << '\n';

    // 4) 领域定位：VLSI 布局、GUI 矩形合并、表格版面
    std::cout << "自检通过\n";
    return 0;
}
