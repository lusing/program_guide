#pragma once
// 抽象工厂：一族产品（按钮+边框）配套生产，族内不许混搭。
#include <concepts>
#include <memory>
#include <string>

namespace dp {

struct Button {
    virtual ~Button() = default;
    [[nodiscard]] virtual std::string render() const = 0;
};

struct Border {
    virtual ~Border() = default;
    [[nodiscard]] virtual std::string render() const = 0;
};

struct WinButton final : Button {
    [[nodiscard]] std::string render() const override { return "win-button"; }
};

struct WinBorder final : Border {
    [[nodiscard]] std::string render() const override { return "win-border"; }
};

struct LinuxButton final : Button {
    [[nodiscard]] std::string render() const override { return "linux-button"; }
};

struct LinuxBorder final : Border {
    [[nodiscard]] std::string render() const override { return "linux-border"; }
};

class WidgetFactory {
public:
    virtual ~WidgetFactory() = default;
    [[nodiscard]] virtual std::unique_ptr<Button> make_button() const = 0;
    [[nodiscard]] virtual std::unique_ptr<Border> make_border() const = 0;
};

class WinFactory final : public WidgetFactory {
public:
    [[nodiscard]] std::unique_ptr<Button> make_button() const override {
        return std::make_unique<WinButton>();
    }
    [[nodiscard]] std::unique_ptr<Border> make_border() const override {
        return std::make_unique<WinBorder>();
    }
};

class LinuxFactory final : public WidgetFactory {
public:
    [[nodiscard]] std::unique_ptr<Button> make_button() const override {
        return std::make_unique<LinuxButton>();
    }
    [[nodiscard]] std::unique_ptr<Border> make_border() const override {
        return std::make_unique<LinuxBorder>();
    }
};

// concepts 约束：任何想当"控件工厂"的类型必须同时能产按钮和边框，
// 少一样在实例化点就报错——比运行期 nullptr 好查得多。
template <typename F>
concept WidgetFactoryLike = requires(const F& f) {
    { f.make_button() } -> std::convertible_to<std::unique_ptr<Button>>;
    { f.make_border() } -> std::convertible_to<std::unique_ptr<Border>>;
};

// 对话框只依赖抽象工厂：按钮和边框必然来自同一族。
inline std::string draw_dialog(const WidgetFactory& f) {
    return f.make_button()->render() + "+" + f.make_border()->render();
}

}  // namespace dp
