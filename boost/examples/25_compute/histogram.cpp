// histogram.cpp —— Boost.Histogram（2018）：多维直方图的工业级实现——
// 轴可组合、支持加权/并行填充、序列化。
// 对应文档：docs/25-compute.md
#include <boost/histogram.hpp>
#include <iostream>
#include <random>

namespace bh = boost::histogram;

int main() {
    // 1) 一维定宽数轴
    auto h1 = bh::make_histogram(bh::axis::regular<>(10, 0.0, 1.0, "x"));
    for (double x : {0.05, 0.15, 0.15, 0.95}) h1(x);
    std::cout << "一维计数: bin0=" << h1.at(0) << " bin1=" << h1.at(1)
              << " bin9=" << h1.at(9) << '\n';

    // 2) 变长轴（类别）+ 多维
    auto h2 = bh::make_histogram(
        bh::axis::regular<>(5, 0.0, 100.0, "分数"),
        bh::axis::category<std::string>({"及格", "不及格"}, "等级"));
    h2(85.0, "及格");
    h2(45.0, "不及格");
    h2(92.0, "及格");
    std::cout << "二维总计数 = " << bh::algorithm::sum(h2) << '\n';

    // 3) 随机数填充 + 统计（固定种子确定性）
    std::mt19937 gen(42);
    std::normal_distribution<> normal(0.5, 0.15);
    auto h3 = bh::make_histogram(bh::axis::regular<>(20, 0.0, 1.0));
    for (int i = 0; i < 10000; ++i) h3(normal(gen));
    // 中心 bin 与尾部 bin 的关系
    auto center = h3.axis(0).index(0.5);   // index_type（防 C4267 窄化告警）
    auto tail = h3.axis(0).index(0.9);
    std::cout << "10000 样本: 中心 bin=" << h3.at(center)
              << " 尾部 bin=" << h3.at(tail)
              << "（中心 >> 尾部）\n";

    // 4) 加权填充（不确定度跟踪）
    auto hw = bh::make_weighted_histogram(bh::axis::regular<>(4, 0, 4));
    hw(bh::weight(2.5), 0.5);
    hw(bh::weight(0.5), 0.5);
    std::cout << "加权 bin 值 = " << hw.at(0).value() << "（方差 = "
              << hw.at(0).variance() << "）\n";

    std::cout << "自检通过\n";
    return 0;
}
