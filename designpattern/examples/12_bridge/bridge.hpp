#pragma once
// 桥接：抽象（Shape）与实现（Renderer）两维各自独立演化。
// 附 pImpl 对照：同一"实现与抽象分离"思想的编译期版本。
#include <format>
#include <memory>
#include <string>
#include <utility>

namespace dp {

// Implementor：实现侧接口——"怎么画"。
struct Renderer {
    virtual ~Renderer() = default;
    [[nodiscard]] virtual std::string render_circle(double r) const = 0;
};

struct VectorRenderer final : Renderer {
    [[nodiscard]] std::string render_circle(double r) const override {
        return std::format("vector circle r={}", r);
    }
};

struct RasterRenderer final : Renderer {
    [[nodiscard]] std::string render_circle(double r) const override {
        return std::format("raster circle r={}", r);
    }
};

// Abstraction：抽象侧——持有"指向实现"的桥（这里是 const 引用）。
class BridgeCircle {
public:
    BridgeCircle(const Renderer& r, double radius) : r_(&r), radius_(radius) {}

    // 抽象操作把请求转给实现：形状逻辑（画的是圆）与渲染逻辑（怎么画）合流于此。
    [[nodiscard]] std::string draw() const { return r_->render_circle(radius_); }

    // 抽象维度可独立扩展：加一个"描边圆"只动这一层，不动任何 Renderer。
    [[nodiscard]] std::string draw_outlined() const {
        return "outline(" + r_->render_circle(radius_) + ")";
    }

private:
    const Renderer* r_;
    double radius_;
};

// ---- 现代对照：pImpl——桥接的编译期同构 ----
// "指向实现的指针"隔离接口与实现：头文件只留 unique_ptr<Impl>，
// 实现细节改动不需要重编使用方（编译防火墙）。
class Widget {
public:
    Widget();
    ~Widget();                                  // 析构必须在 Impl 完整类型处定义
    Widget(Widget&&) noexcept;
    Widget& operator=(Widget&&) noexcept;
    [[nodiscard]] std::string describe() const;

private:
    struct Impl;
    std::unique_ptr<Impl> p_;
};

// 单文件教学示例：Impl 的定义放在类外（真实工程里放在 .cpp 中）。
struct Widget::Impl {
    std::string detail = "impl-ready";   // 任意复杂实现细节，外界不可见
};

inline Widget::Widget() : p_(std::make_unique<Impl>()) {}
inline Widget::~Widget() = default;
inline Widget::Widget(Widget&&) noexcept = default;
inline Widget& Widget::operator=(Widget&&) noexcept = default;
inline std::string Widget::describe() const { return p_->detail; }

}  // namespace dp
