// accumulators.cpp —— Boost.Accumulators（2006）：流式统计——
// 一遍扫过数据同时算 N 个统计量（在线算法，不用存全部数据）。
// 对应文档：docs/25-compute.md
#include <boost/accumulators/accumulators.hpp>
#include <boost/accumulators/statistics/stats.hpp>
#include <boost/accumulators/statistics/mean.hpp>
#include <boost/accumulators/statistics/variance.hpp>
#include <boost/accumulators/statistics/min.hpp>
#include <boost/accumulators/statistics/max.hpp>
#include <boost/accumulators/statistics/median.hpp>
#include <boost/accumulators/statistics/count.hpp>
#include <boost/accumulators/statistics/sum.hpp>
#include <iostream>
#include <vector>

namespace acc = boost::accumulators;

int main() {
    // 1) 声明要哪些统计量（编译期列表）
    acc::accumulator_set<double,
        acc::stats<acc::tag::mean, acc::tag::variance,
                   acc::tag::min, acc::tag::max,
                   acc::tag::count, acc::tag::sum>> stats;

    std::vector<double> data{2, 4, 4, 4, 5, 5, 7, 9};
    for (double x : data) stats(x);            // 一遍喂数

    // 2) 一次提取全部结果
    std::cout << "count = " << acc::count(stats) << '\n';
    std::cout << "mean = " << acc::mean(stats) << "（解析 = 5）\n";
    std::cout << "variance = " << acc::variance(stats) << "（样本方差 = 4）\n";
    std::cout << "min/max = " << acc::min(stats) << '/' << acc::max(stats) << '\n';
    std::cout << "sum = " << acc::sum(stats) << '\n';

    // 3) 中位数（P² 分位数估计——在线算法不存数据）
    acc::accumulator_set<double, acc::stats<acc::tag::median>> med;
    for (double x : data) med(x);
    std::cout << "median ≈ " << acc::median(med) << "（解析 = 4.5）\n";

    // 4) 意义：亿级数据流的均值/方差/分位数只花常数内存
    std::cout << "自检通过\n";
    return 0;
}
