// std::numbers (数学常量)
#include <numbers>
double pi = std::numbers::pi;
double e = std::numbers::e;

// std::bytes (字面量)
using namespace std::literals;
auto size = 4_GB;  // 4 * 1024 * 1024 * 1024

// consteval (立即函数)
consteval int square(int x) {
    return x * x;
}
constexpr int n = square(5); // 编译时计算

// std::bit_cast
#include <bit>
float f = 3.14f;
auto i = std::bit_cast<uint32_t>(f);

// std::start_lifetime_as (稀疏数组重启动态类型)
