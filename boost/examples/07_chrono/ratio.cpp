// ratio.cpp —— Boost.Ratio：编译期有理数（std::ratio 直系，chrono 的地基）
// 对应文档：docs/07-chrono.md
#include <boost/ratio.hpp>
#include <cstdint>
#include <iostream>

// 函数体里不能声明别名模板——ratio_string 的快捷方式放这里
template <class R>
using rs = boost::ratio_string<R, char>;

// 自定义字面值：给"字节单位"造后缀（数字单位的语法糖）。
// 注意写法：C++23 起 operator"" _kb（引号后带空格）已弃用（C5311），
// 必须写成 operator""_kb（无空格）——第 5 版书里的老写法在新标准下告警。
constexpr std::intmax_t operator""_kb(unsigned long long n) {
    return static_cast<std::intmax_t>(n) * 1024;   // 用 1024 的 KB
}
constexpr std::intmax_t operator""_gb(unsigned long long n) {
    return static_cast<std::intmax_t>(n) * 1024 * 1024 * 1024;
}

int main() {
    using boost::ratio;

    // ── 1) ratio 是编译期分数：num/den 自动约分 ──
    using half = ratio<1, 2>;
    using third = ratio<1, 3>;
    std::cout << "half = " << half::num << '/' << half::den << '\n';
    std::cout << "ratio<6,12> 约分 = " << ratio<6, 12>::num << '/' << ratio<6, 12>::den << '\n';

    // ── 2) 编译期四则：add/sub/multiply/divide ──
    using sum = boost::ratio_add<half, third>;         // 1/2 + 1/3 = 5/6
    std::cout << "1/2+1/3 = " << sum::num << '/' << sum::den << '\n';
    using prod = boost::ratio_multiply<half, third>;   // 1/2 * 1/3 = 1/6
    std::cout << "1/2*1/3 = " << prod::num << '/' << prod::den << '\n';

    // ── 3) 编译期比较 ──
    std::cout << "1/2 < 1/3 ? " << std::boolalpha
              << boost::ratio_less<half, third>::value << '\n';

    // ── 4) 真实用途：给 duration 定制单位 ──
    using fortnight = boost::ratio<14 * 24 * 3600, 1>;  // 两周（秒的 1209600 倍）
    static_assert(fortnight::num == 1209600);
    std::cout << "fortnight = " << fortnight::num << " 秒的倍数\n";

    // ── 5) SI 前缀成品表：atto..exa（十进制，1000 进位） ──
    std::cout << "kilo = " << boost::kilo::num << "  milli = 1/" << boost::milli::den << '\n';
    // 国际单位是 1000 进位；存储业的 1024 进位要自己定义（kibi/mebi/gibi）
    using kibi = ratio<1024>;
    using mebi = ratio<1024 * 1024>;
    using gibi = ratio<1024 * 1024 * 1024>;
    std::cout << "kilo < kibi? " << (boost::ratio_less<boost::kilo, kibi>::value)
              << "  mebi/mega = " << boost::ratio_divide<mebi, boost::mega>::num
              << '\n';

    // ── 6) ratio_string：单位的文字表示（symbol=缩写，prefix=全名） ──
    std::cout << "kilo: " << rs<boost::kilo>::symbol() << " / "
              << rs<boost::kilo>::prefix()
              << "  nano: " << rs<boost::nano>::symbol() << " / "
              << rs<boost::nano>::prefix()
              << "  自定义: " << rs<ratio<22, 7>>::prefix() << '\n';

    // ── 7) 字面值把单位变语法糖 ──
    std::cout << "2_gb = " << 2_gb << "  10_kb = " << 10_kb
              << "  2gb == 2048*1024kb? " << (2_gb == 2048LL * 1024_kb) << '\n';

    // 与 std::ratio 的关系：同一套东西，静态断言可互认
    static_assert(std::is_same<boost::ratio<1, 2>, std::ratio<1, 2>>::value,
                  "boost::ratio 与 std::ratio 同型");

    std::cout << "自检通过\n";
    return 0;
}
