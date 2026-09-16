#include <cstdint>
#include <numbers>
#include <print>

// 03 类型与变量：基本类型、字面量、auto、初始化、constexpr
int main() {
    // ═══ 3.1 基本类型与固定宽度整数 ═══
    int pages = 420;
    double price = 89.5;
    char grade = 'A';
    bool published = true;
    std::print("int {} 字节，double {} 字节，char {} 字节\n",
               sizeof(int), sizeof(double), sizeof(char));
    std::int32_t exact = 1'000'000;      // 固定宽度：不猜平台
    std::int64_t big = 9'000'000'000LL;  // LL 后缀：字面量也得是 64 位
    std::print("pages={} price={} grade={} published={} exact={} big={}\n",
               pages, price, grade, published, exact, big);

    // ═══ 3.2 整数字面量：进制与分隔符 ═══
    auto bin = 0b1010;  // 二进制 10
    auto hex = 0xFF;    // 十六进制 255
    auto grouped = 1'234'567;
    std::print("bin={} hex={} grouped={}\n", bin, hex, grouped);

    // ═══ 3.3 auto：让编译器推导 ═══
    auto count = 42;    // int
    auto ratio = 0.5;   // double（不是 float！）
    auto letter = 'Z';  // char
    std::print("{} {} {}\n", count, ratio, letter);

    // ═══ 3.4 初始化三种写法与 narrowing ═══
    int a = 10;    // 拷贝初始化
    int b(10);     // 直接初始化
    int c{10};     // 列表初始化：不允许窄化
    double d = 3;  // 隐式转换：可以，但 {} 会拦
    // int bad{3.14};  // 编译错误：double → int 是 narrowing——{} 帮你把关
    std::print("{} {} {} {}\n", a, b, c, d);

    // ═══ 3.5 constexpr：编译期就定下来的值 ═══
    constexpr double tau = 2.0 * std::numbers::pi;  // <numbers> (C++20)
    constexpr int months = 12;
    int weekly[months]{};  // C 数组长度须是编译期常量（数组详见第 06 章）
    weekly[0] = 1;
    static_assert(months == 12);  // 编译期断言：免费的单测

    std::print("tau≈{:.4f}，首周 {}\n", tau, weekly[0]);
    std::println("自检通过");
}
