#pragma once
// 开闭原则：新增形状不改旧代码。
#include <concepts>
#include <memory>
#include <ranges>
#include <span>

namespace dp {

// 经典线：抽象基类 + 虚函数。新形状 = 新子类，total_area 一行不动。
class Shape {
public:
    virtual ~Shape() = default;
    [[nodiscard]] virtual double area() const = 0;
};

class Circle final : public Shape {
public:
    explicit Circle(double r) : r_(r) {}
    [[nodiscard]] double area() const override { return 3.14159265358979 * r_ * r_; }
private:
    double r_;
};

class Rect final : public Shape {
public:
    Rect(double w, double h) : w_(w), h_(h) {}
    [[nodiscard]] double area() const override { return w_ * h_; }
private:
    double w_, h_;
};

inline double total_area(std::span<const std::unique_ptr<Shape>> shapes) {
    double sum = 0.0;
    for (const auto& s : shapes) sum += s->area();
    return sum;
}

// 现代线：concepts + range 版。ShapeLike 只约束"有 area()"，不要求继承，
// 连 span 都不用手工构造——任何元素满足 ShapeLike 的范围都能传。
template <typename S>
concept ShapeLike = requires(const S& s) {
    { s.area() } -> std::convertible_to<double>;
};

template <std::ranges::input_range R>
    requires ShapeLike<std::ranges::range_value_t<R>>
double total_area2(const R& shapes) {
    double sum = 0.0;
    for (const auto& s : shapes) sum += s.area();
    return sum;
}

}  // namespace dp
