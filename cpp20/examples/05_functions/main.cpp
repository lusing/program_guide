#include <print>
#include <string>
#include <vector>

// 05 函数：参数传递、重载、默认实参、lambda

// ═══ 5.1 值传递：拿到的是副本，改不动原件 ═══
// x 在这里"改了却没用上"是**故意的**（下一节拿引用对比）。
// clang 会对这种写法报 -Wunused-but-set-parameter（GCC / MSVC 不报），
// 一个 (void)x 就说明清楚了：不是笔误。跨编译器校验要求零告警。
void double_it(int x) {
    x *= 2;   // 改的是副本，外面看不见
    (void)x;  // 表明"改完不用"是刻意演示，不是漏写
}

// ═══ 5.2 引用传递：真的改原件 ═══
void double_ref(int& x) {
    x *= 2;
}

// ═══ 5.3 const 引用：只读 + 不拷贝（大对象标配）═══
int total_length(const std::vector<std::string>& words) {
    int total = 0;
    for (const auto& w : words) {
        total += static_cast<int>(w.size());
    }
    return total;
}

// ═══ 5.4 默认实参与重载 ═══
void greet(const std::string& name, const std::string& greeting = "你好") {
    std::println("{}，{}！", greeting, name);
}
int twice(int v) { return v * 2; }
double twice(double v) { return v * 2; }  // 重载：同名不同参

// ═══ 5.5 [[nodiscard]]：返回值不许扔 ═══
[[nodiscard]] int square(int v) {
    return v * v;
}

int main() {
    int v = 21;
    double_it(v);   // 副本被翻倍，v 纹丝不动
    double_ref(v);  // 引用：v 真的变了
    std::println("v = {}", v);  // 42

    std::vector<std::string> words{"现代", "C++", "教程"};
    std::println("总字符数 = {}", total_length(words));

    greet("阿 C");            // 用默认问候
    greet("World", "Hello");  // 覆盖默认
    std::println("{} {}", twice(21), twice(1.5));

    // ═══ 5.6 lambda：就地写函数对象 ═══
    auto add = [](int a, int b) { return a + b; };
    int factor = 3;
    auto scale = [factor](int x) { return x * factor; };  // 按值捕获外部变量
    std::println("{} {}", add(2, 3), scale(7));

    std::println("square(9) = {}", square(9));  // 丢弃返回值会有 C4834 警告
    std::println("自检通过");
}
