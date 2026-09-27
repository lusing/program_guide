#include <format>
#include <print>
#include <utility>

// 12 运算符重载：让类像内建类型一样运算

// ═══ 12.1 Money：算术 + 比较全家桶 ═══
class Money {
public:
    constexpr explicit Money(long long cents) : cents_{cents} {}

    [[nodiscard]] constexpr long long cents() const { return cents_; }

    // 复合赋值先写：自增自身、返回 *this 引用（链式赋值的基石）
    constexpr Money& operator+=(const Money& rhs) {
        cents_ += rhs.cents_;
        return *this;
    }
    // 二元 + 用 += 实现：拷贝左值、加上右值、按值返回新对象
    [[nodiscard]] constexpr Money operator+(const Money& rhs) const {
        Money copy{*this};
        copy += rhs;
        return copy;
    }
    // 一元负号：返回新对象，不改动自身
    [[nodiscard]] constexpr Money operator-() const { return Money{-cents_}; }

    // 比较：= default 的 <=> 连 == 一起生成（成员按声明序做字典序比较）
    auto operator<=>(const Money&) const = default;

    // 显式转 double：不让“Money → double”悄悄发生（隐式转换是bug温床）
    [[nodiscard]] constexpr explicit operator double() const { return cents_ / 100.0; }

private:
    long long cents_;   // 以“分”存储：整数算钱，绕开浮点误差
};

// 左操作数不是本类（double * Money）：只能写成非成员函数
[[nodiscard]] constexpr Money operator*(double k, const Money& m) {
    return Money{static_cast<long long>(k * static_cast<double>(m.cents()))};
}

// ═══ 12.2 给 std::print 教会 Money：特化 std::formatter ═══
template <>
struct std::formatter<Money> {
    constexpr auto parse(std::format_parse_context& ctx) { return ctx.begin(); }

    auto format(const Money& m, std::format_context& ctx) const {
        long long c = m.cents();
        const char* sign = c < 0 ? "-" : "";
        if (c < 0) c = -c;
        return std::format_to(ctx.out(), "{}{}.{:02d} 元", sign, c / 100, c % 100);
    }
};

// ═══ 12.3 Grid：下标运算符与 C++23 多参数 operator[] ═══
class Grid {
public:
    // 经典单参下标：返回引用才能“写穿”——g[0] = ... 直接改到内部数组
    [[nodiscard]] int& operator[](std::size_t i) { return cells_[i]; }
    [[nodiscard]] int operator[](std::size_t i) const { return cells_[i]; }

    // C++23：operator[] 可以收多个参数——矩阵用 m[row, col]（不是 m[row][col]）
    [[nodiscard]] int& operator[](std::size_t r, std::size_t c) { return cells_[r * 3 + c]; }
    [[nodiscard]] int operator[](std::size_t r, std::size_t c) const { return cells_[r * 3 + c]; }

private:
    int cells_[9]{};
};

int main() {
    // 算术：+ 由 += 实现，一元负号、数乘（自由函数版）
    constexpr Money price{1250};          // 12.50 元
    constexpr Money fee{495};             // 4.95 元
    Money total{price};
    total += fee;
    std::println("12.50 + 4.95 = {}", total);
    std::println("2 × 12.50 = {}", 2.0 * price);
    std::println("-12.50 = {}", -price);

    // 比较：<=> 默认生成，六个比较运算符一把全有
    std::println("price == fee? {}", price == fee);
    std::println("price > fee?  {}", price > fee);
    std::println("-price < fee? {}", -price < fee);

    // 显式转换：double(amount) 要写明，编译器不会偷偷转
    std::println("显式转 double：{:.2f}", static_cast<double>(total));

    // 下标运算符：单参经典 + C++23 双参
    Grid g;
    g[0] = 10;             // 非 const 版本返回 int&：写穿
    g[1, 2] = 99;          // C++23：多参数下标，(row=1, col=2)
    const Grid& cg = g;
    std::println("g[0] = {}，g[1,2] = {}，const 读 g[4] = {}", g[0], g[1, 2], cg[4]);

    std::println("自检通过");
}
