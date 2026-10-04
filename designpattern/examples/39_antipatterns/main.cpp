// 39 反模式三幕：症状（模式用错了）→ 改法（收敛成更简单的形态）。
// 每幕改法都有 assert——反模式章的"反"要落在可验证的改后行为上。
#include <cassert>
#include <memory>
#include <print>
#include <string>
#include <utility>

// ============================== 第一幕：工厂反例 ==============================
// 症状：两种按钮的创建硬上一套 AbstractFactory——6 个类型干一件 if 的事。
namespace bad {
struct Button { virtual std::string render() const = 0; virtual ~Button() = default; };
struct DarkButton final : Button { std::string render() const override { return "[btn]"; } };
struct LightButton final : Button { std::string render() const override { return "(btn)"; } };
struct Factory { virtual std::unique_ptr<Button> make() const = 0; virtual ~Factory() = default; };
struct DarkFactory final : Factory { std::unique_ptr<Button> make() const override { return std::make_unique<DarkButton>(); } };
struct LightFactory final : Factory { std::unique_ptr<Button> make() const override { return std::make_unique<LightButton>(); } };
}  // namespace bad

// ============================== 第二幕：装饰反例 ==============================
// 症状：两层字符串加工硬上装饰器体系——接口 + 2 个装饰类 + 装配代码。

// ============================== 第三幕：单例反例 ==============================
// 症状：Config 用全局单例，第一个"测试"改值，第二个"测试"读到污染。
namespace bad2 {
struct Config { int port = 8080; };
inline Config& instance() { static Config c; return c; }   // 全局态：进程级活账本
}

int main() {
    // ---- 第一幕：症状——6 类型工厂体系；改法——一个 lambda ----
    {
        const bad::DarkFactory f;
        const std::string rendered = f.make()->render();
        // 症状观察：功能正确，但为两种取值建了 6 个类型（类数 = 取值数 × 2 + 接口）
        assert(rendered == "[btn]");

        // 改法：创建逻辑收敛为一个 lambda（策略语义没有变）
        auto make_button = [](bool dark) { return dark ? std::string("[btn]") : std::string("(btn)"); };
        assert(make_button(true) == "[btn]");
        assert(make_button(false) == "(btn)");
        std::println("第一幕 症状: 6 个类型支撑两种按钮的创建");
        std::println("第一幕 改法: 一个 lambda，断言两种取值各就各位");
    }

    // ---- 第二幕：症状——装饰器体系；改法——函数组合两行 ----
    {
        auto trim = [](std::string s) {
            const std::size_t b = s.find_first_not_of(' ');
            const std::size_t e = s.find_last_not_of(' ');
            return b == std::string::npos ? std::string{} : s.substr(b, e - b + 1);
        };
        auto upper = [](std::string s) {
            for (char& c : s) if (c >= 'a' && c <= 'z') c = static_cast<char>(c - 32);
            return s;
        };
        // 症状观察：为 trim+upper 组合建 TrimDecorator/UpperDecorator/装配序列是空转——
        // 装饰器的价值在"运行期叠放不定"，编译期固定的组合没有这个需求。
        const std::string once = upper(trim(std::string("  hi ")));
        assert(once == "HI");

        // 改法：组合写成一个具名转换（必要时模板组合子，仍然两行）
        auto tidy = [trim, upper](std::string s) { return upper(trim(std::move(s))); };
        assert(tidy("  hi ") == "HI");
        assert(tidy(" x ") == "X");
        std::println("第二幕 症状: 编译期固定的两层加工拟用装饰器体系");
        std::println("第二幕 改法: 两行函数组合，断言两种输入全对");
    }

    // ---- 第三幕：症状——单例全局态串台；改法——注入 Config& ----
    {
        // 症状实证：两个"测试"共用单例，前一个改值、后一个读到污染
        bad2::instance().port = 9999;                       // "测试一"改了全局
        const bool polluted = bad2::instance().port != 8080; // "测试二"期望默认值
        assert(polluted);   // 污染真实发生（症状成立，非改法，仅演示）

        // 改法：把配置作为参数注入——两份配置互不干扰，测试可以各造各的
        struct Config { int port = 8080; };
        auto healthy_test = [](const Config& c) { return c.port; };
        const Config a{};            // 默认 8080
        const Config b{9999};        // 各造各的
        assert(healthy_test(a) == 8080);
        assert(healthy_test(b) == 9999);
        std::println("第三幕 症状: 单例跨用例串台（实测 polluted=true）");
        std::println("第三幕 改法: 注入 Config&，两份配置互不污染");
    }

    std::println("自检通过");
}
