// 23 测试与调试：assert 自造单测、stacktrace
#include <cassert>
#include <cctype>
#include <functional>
#include <print>
#include <stacktrace>
#include <string>
#include <string_view>
#include <vector>

// ═══ 23.1 被测对象：一个纯函数 ═══
std::string slugify(std::string_view text) {
    std::string out;
    for (char ch : text) {
        auto uc = static_cast<unsigned char>(ch);
        if (std::isalnum(uc) != 0) {
            out.push_back(static_cast<char>(std::tolower(uc)));
        } else if (!out.empty() && out.back() != '-') {
            out.push_back('-');
        }
    }
    while (!out.empty() && out.back() == '-') {
        out.pop_back();
    }
    return out;
}

// ═══ 23.2 十行单测框架：名字 + 断言 lambda ═══
struct TestCase {
    std::string name;
    std::function<void()> run;
};

int run_tests() {
    std::vector<TestCase> tests{
        {"空串返回空", [] { assert(slugify("") == ""); }},
        {"标点转连字符", [] { assert(slugify("Hello, C++ World!") == "hello-c-world"); }},
        {"首尾不留连字符", [] { assert(slugify("--Hi--") == "hi"); }},
        {"非 ASCII 字节剔除", [] { assert(slugify("你好") == ""); }},
    };
    for (const auto& t : tests) {
        t.run();  // assert 失败会中止（真实框架会捕获并继续，见 docs）
        std::println("[PASS] {}", t.name);
    }
    return static_cast<int>(tests.size());
}

// ═══ 23.3 stacktrace：看出错时"从哪来" (C++23) ═══
int deep_c(int depth) {
    if (depth == 0) {
        auto st = std::stacktrace::current();
        std::println("调用栈帧数 = {}（≥3 才合理）", st.size());
        std::println("  第 1 帧大概长这样：{}", std::to_string(st[0]));
        return 42;
    }
    return deep_c(depth - 1);
}

int main() {
    int passed = run_tests();
    int result = deep_c(3);
    std::println("通过 {} 个用例，deep_c = {}", passed, result);
    std::println("自检通过");
}
