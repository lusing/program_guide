#pragma once
// 策略：算法族各自封装、可互换——调用方 checkout 只认接口，不认具体折扣规则。
#include <cmath>
#include <concepts>
#include <functional>

namespace dp {

// Strategy：抽象折扣。
struct Discount {
    virtual ~Discount() = default;
    [[nodiscard]] virtual double apply(double origin) const = 0;
};

// ConcreteStrategy：三种折扣规则。
struct NoDiscount final : Discount {
    [[nodiscard]] double apply(double origin) const override { return origin; }
};

struct PercentDiscount final : Discount {
    explicit PercentDiscount(double pct) : pct_(pct) {}
    [[nodiscard]] double apply(double origin) const override {
        return origin * (1.0 - pct_ / 100.0);
    }

private:
    double pct_;                     // 有状态：策略对象携带自己的参数
};

struct ThresholdDiscount final : Discount {
    [[nodiscard]] double apply(double origin) const override {
        return origin >= 200.0 ? origin - 30.0 : origin;   // 满 200 减 30
    }
};

// Context：结算函数——只认 Discount&，具体算法运行期才绑定。
inline double checkout(const Discount& d, double origin) { return d.apply(origin); }

// ---- 现代线一：function 策略——闭包即算法 ----
using DiscountFn = std::function<double(double)>;

// ---- 现代线二：concepts 静态分发——编译期绑定，无虚表 ----
// 双形态 concept：类策略走 .apply(o)，闭包走 operator()——析取收编两形态。
// （单一 `{ f(o) }` 写法对类策略不成立：类没有 operator()。）
template <typename F>
concept DiscountLike =
    requires(const F& f, double o) { { f.apply(o) } -> std::convertible_to<double>; } ||
    requires(const F& f, double o) { { f(o) } -> std::convertible_to<double>; };

template <DiscountLike F>
[[nodiscard]] double checkout_fast(const F& f, double origin) {
    if constexpr (requires { f.apply(origin); }) return f.apply(origin);
    else return f(origin);           // 闭包：operator() 直调
}

}  // namespace dp
