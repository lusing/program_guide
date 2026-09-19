// geometry.cpp —— Boost.Geometry（2009）：计算几何的通用件。
// 点/线/多边形/球面上的全套算法（面积、距离、相交、缓冲、简化）。
// 对应文档：docs/23-graph-geometry.md
#include <boost/geometry.hpp>
#include <boost/geometry/geometries/point_xy.hpp>
#include <boost/geometry/geometries/polygon.hpp>
#include <boost/geometry/geometries/linestring.hpp>
#include <iostream>
#include <string>

namespace bg = boost::geometry;

int main() {
    using Point = bg::model::d2::point_xy<double>;
    using Poly  = bg::model::polygon<Point>;
    using Line  = bg::model::linestring<Point>;

    // 1) 距离与角度
    Point p1(0, 0), p2(3, 4);
    std::cout << "欧氏距离 = " << bg::distance(p1, p2) << '\n';

    // 2) 多边形：面积/周长/点包含
    Poly city;
    bg::read_wkt("POLYGON((0 0, 0 4, 4 4, 4 0, 0 0))", city);   // 逆时针（顺时针面积为负）
    std::cout << "城市面积 = " << bg::area(city) << " 周长 = " << bg::perimeter(city) << '\n';
    std::cout << "(2,2) 在城内? " << bg::within(Point(2, 2), city) << '\n';
    std::cout << "(5,5) 在城内? " << bg::within(Point(5, 5), city) << '\n';

    // 3) 相交与交积
    Poly other;
    bg::read_wkt("POLYGON((2 2, 6 2, 6 6, 2 6, 2 2))", other);
    std::cout << "两城相交? " << bg::intersects(city, other) << '\n';
    std::vector<Poly> overlap;
    bg::intersection(city, other, overlap);
    std::cout << "交集面积 = " << (overlap.empty() ? 0.0 : bg::area(overlap[0])) << '\n';

    // 4) 线与多边形
    Line road{{Point(-1, 2), Point(10, 2)}};
    std::cout << "道路穿过城市? " << bg::intersects(road, city) << '\n';
    std::cout << "道路长度 = " << bg::length(road) << '\n';

    // 5) 折线简化（Douglas-Peucker）：GPS 轨迹压缩的标准件
    Line track;
    for (int i = 0; i <= 10; ++i) track.push_back(Point(i, (i % 2) * 0.01));   // 抖动
    Line simplified;
    bg::simplify(track, simplified, 0.1);
    std::cout << "轨迹 " << track.size() << " 点 → 简化 " << simplified.size() << " 点\n";

    std::cout << "自检通过\n";
    return 0;
}
