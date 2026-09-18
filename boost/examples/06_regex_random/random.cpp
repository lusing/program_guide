// random.cpp —— Boost.Random：随机数工程的教科书（std::random 的直系）
// 对应文档：docs/06-regex-random.md
#include <boost/random.hpp>
#include <boost/random/random_device.hpp>   // 伞形头不含它，要单引
#include <random>
#include <iostream>
#include <map>

int main() {
    // 1) 引擎 + 分布 的两层架构（boost 确立的范式，std 照单全收）
    boost::random::mt19937 gen(42);                 // 固定种子 → 确定性输出
    boost::random::uniform_int_distribution<> die(1, 6);
    std::cout << "掷骰子 x5:";
    for (int i = 0; i < 5; ++i) std::cout << ' ' << die(gen);
    std::cout << '\n';

    // 2) 真随机数播种：random_device（std 同名同义）
    boost::random::random_device rd;
    boost::random::mt19937 gen2(rd());
    (void)gen2;

    // 3) 常用分布全家福
    boost::random::normal_distribution<> normal{170.0, 6.0};   // 身高 N(μ=170, σ=6)
    boost::random::bernoulli_distribution<> coin{0.5};
    std::map<int, int> height_hist;
    int heads = 0;
    for (int i = 0; i < 1000; ++i) {
        int h = static_cast<int>(normal(gen) / 10) * 10;
        ++height_hist[h];
        if (coin(gen)) ++heads;
    }
    std::cout << "1000 次抛硬币正面 = " << heads << "（约 500）\n";
    std::cout << "身高直方图（每 10cm 一档，取 160-180）：";
    for (int h = 160; h <= 180; h += 10) std::cout << h << ':' << height_hist[h] << ' ';
    std::cout << '\n';

    // 4) std 版对照：同种子同算法 → 同序列（mt19937 是数值确定的）
    std::mt19937 sgen(42);
    std::uniform_int_distribution<> sdie(1, 6);
    boost::random::mt19937 bgen(42);
    boost::random::uniform_int_distribution<> bdie(1, 6);
    std::cout << "std/boost 同种子序列一致? " << std::boolalpha
              << (sdie(sgen) == bdie(bgen)) << '\n';

    // 5) 坑位演示：忘了播种 vs 播种（rand() 时代 srand 忘调是经典 bug）
    boost::random::mt19937 unseeded1, unseeded2;
    std::cout << "不播种的两个引擎同序列? " << (unseeded1() == unseeded2())
              << "（默认构造 = 固定种子，注意！）\n";

    std::cout << "自检通过\n";
    return 0;
}
