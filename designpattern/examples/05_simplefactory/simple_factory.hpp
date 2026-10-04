#pragma once
// 简单工厂：一个函数按名字造对象。错误走 std::expected，不抛异常。
#include <expected>
#include <memory>
#include <string>
#include <string_view>

namespace dp {

struct Shape {
    virtual ~Shape() = default;
    [[nodiscard]] virtual std::string name() const = 0;
};

struct Circle final : Shape {
    [[nodiscard]] std::string name() const override { return "circle"; }
};

struct Square final : Shape {
    [[nodiscard]] std::string name() const override { return "square"; }
};

// 工厂本体：if-else 串。加一种形状 = 改一处 + 重新编译，这正是第 6 章要治的病。
inline std::expected<std::unique_ptr<Shape>, std::string> create_shape(
    std::string_view kind) {
    if (kind == "circle") return std::make_unique<Circle>();
    if (kind == "square") return std::make_unique<Square>();
    return std::unexpected(std::format("未知形状: {}", kind));
}

}  // namespace dp
