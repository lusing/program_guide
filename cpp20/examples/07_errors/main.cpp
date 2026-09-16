#include <cassert>
#include <charconv>
#include <expected>
#include <optional>
#include <print>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

// 07 错误处理：异常、optional、expected、断言

// ═══ 7.1 异常：留给"真正的意外" ═══
double safe_divide(double a, double b) {
    if (b == 0.0) {
        throw std::invalid_argument("除数为零");
    }
    return a / b;
}

// ═══ 7.2 optional："可能没有"放进类型 ═══
std::optional<int> first_even(const std::vector<int>& xs) {
    for (int v : xs) {
        if (v % 2 == 0) {
            return v;
        }
    }
    return std::nullopt;  // 明确的"没有"
}

// ═══ 7.3 expected<T, E>："值或错误"都在类型里 (C++23) ═══
std::expected<int, std::string> parse_int(std::string_view text) {
    int value = 0;
    auto [ptr, ec] = std::from_chars(text.data(), text.data() + text.size(), value);
    if (ec != std::errc{} || ptr != text.data() + text.size()) {
        return std::unexpected("不是合法整数: " + std::string(text));
    }
    return value;
}

// ═══ 7.4 链式组合：monadic 风格，不抛不嵌套 (C++23) ═══
std::expected<double, std::string> parse_ratio(std::string_view a, std::string_view b) {
    return parse_int(a).and_then([b](int x) {
        return parse_int(b).and_then([x](int y) -> std::expected<double, std::string> {
            if (y == 0) {
                return std::unexpected("除数为零");
            }
            return static_cast<double>(x) / y;
        });
    });
}

int main() {
    // 异常：catch 住看信息
    try {
        std::println("10 / 3 = {}", safe_divide(10, 3));
        std::println("10 / 0 = {}", safe_divide(10, 0));  // 抛！
    } catch (const std::exception& e) {
        std::println("捕获异常：{}", e.what());
    }

    // optional：has_value / value_or
    std::vector<int> xs{3, 7, 8, 5};
    std::println("第一个偶数 = {}", first_even(xs).value_or(-1));
    std::println("空表兜底 = {}", first_even({}).value_or(-1));

    // expected：成功与失败两条路
    auto ok = parse_int("42");
    auto bad = parse_int("4x");
    std::println("parse(42) = {}", ok.value());
    if (!bad) {
        std::println("parse(4x) 失败：{}", bad.error());
    }

    // 链式组合
    auto r1 = parse_ratio("10", "4");
    auto r2 = parse_ratio("10", "0");
    auto r3 = parse_ratio("1o", "4");
    std::println("ratio(10,4) = {}", r1.value());  // 2.5
    std::println("ratio(10,0) 失败：{}", r2.error());
    std::println("ratio(1o,4) 失败：{}", r3.error());
    assert(r1.value() == 2.5);

    // ═══ 7.5 断言：开发期抓 bug 的地板 ═══
    int amount = 100;
    assert(amount > 0 && "金额必须为正");  // Release (NDEBUG) 下会被编译掉
    std::println("自检通过");
}
