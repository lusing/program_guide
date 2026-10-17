// minmax_clamp.cpp —— Boost.Algorithm 的一般算法部（书 ch8）：
// minmax 家族 + clamp + hex——都是 std 稀缺的小件
// 对应文档：docs/19-text.md
#include <boost/algorithm/clamp.hpp>
#include <boost/algorithm/hex.hpp>
#include <boost/algorithm/minmax.hpp>
#include <boost/algorithm/minmax_element.hpp>
#include <iostream>
#include <iterator>
#include <vector>

int main() {
    // ── 1) minmax：一次拿两个（std::minmax 的前身，返回 boost::tuple）──
    auto pair = boost::minmax(3, 7);
    std::cout << "minmax(3,7) = " << pair.get<0>() << ',' << pair.get<1>()
              << "（返回 tuple：小在前大在后）\n";
    // 有比较谓词版；std 版（C++11）返回 std::pair、还多 initializer_list 形态
    auto sp = std::minmax(3, 7);
    std::cout << "std::minmax = " << sp.first << ',' << sp.second << '\n';

    // ── 2) minmax_element：一趟扫描同时拿最小最大（std::minmax_element 毕业）──
    std::vector<int> v{3, 5, 2, 2, 10, 9, 10, 8};
    auto both = boost::minmax_element(v.begin(), v.end());
    std::cout << "minmax_element: min=" << *both.first << " max=" << *both.second << '\n';
    // 全家族处理"并列第一"的取法：first_/last_ 前缀四组合
    auto fm = boost::first_min_element(v.begin(), v.end());   // 第一个最小
    auto lm = boost::last_min_element(v.begin(), v.end());    // 最后一个最小
    std::cout << "first_min 位 = " << (fm - v.begin())
              << " last_min 位 = " << (lm - v.begin()) << '\n';
    auto fmlm = boost::first_min_last_max_element(v.begin(), v.end());
    std::cout << "first_min_last_max: 位 = " << (fmlm.first - v.begin()) << '/'
              << (fmlm.second - v.begin()) << "（2 与最后一个 10）\n";

    // ── 3) clamp：夹进闭区间（std::clamp C++17 毕业）──
    std::cout << "clamp: (5∈[1,10])=" << boost::algorithm::clamp(5, 1, 10)
              << " (5<[1])=" << boost::algorithm::clamp(5, 10, 15)
              << " (5>[4])=" << boost::algorithm::clamp(5, 0, 4) << '\n';
    // clamp_range：整段夹（transform 风格，写出迭代器）
    std::vector<int> src{2, 4, 6, 8, 10};
    std::cout << "clamp_range(3..9): ";
    boost::algorithm::clamp_range(src, std::ostream_iterator<int>(std::cout, ","),
                                  3, 9);
    std::cout << '\n';

    // ── 4) hex/unhex：十六进制编解码（网络/协议常用）──
    std::cout << "hex(\"123\") = ";
    boost::algorithm::hex("123", std::ostream_iterator<char>(std::cout));
    std::cout << "  hex_lower = ";
    boost::algorithm::hex_lower("+-*/", std::ostream_iterator<char>(std::cout));
    std::cout << '\n';
    std::string decoded;
    boost::algorithm::unhex("414243", std::back_inserter(decoded));
    std::cout << "unhex(414243) = " << decoded << '\n';
    // 坏输入抛异常：not_enough_input / non_hex_input（都是 boost::exception 子类）
    bool threw = false;
    try {
        boost::algorithm::unhex("xyz", std::ostream_iterator<char>(std::cout));
    } catch (const boost::exception&) {
        threw = true;
    }
    std::cout << "坏输入抛 boost::exception? " << threw << '\n';

    std::cout << "自检通过\n";
    return 0;
}
