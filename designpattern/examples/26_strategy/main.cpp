// 26 策略。
#include <cassert>
#include <print>

#include "strategy.hpp"

int main() {
    using namespace dp;

    // ---- 三种折扣，同一定价入口 ----
    const NoDiscount none;
    const PercentDiscount p20(20.0);            // 打 8 折
    const ThresholdDiscount thresh;             // 满 200 减 30

    // 100 元：不打折/8折80/不达门槛原价
    assert(checkout(none, 100.0) == 100.0);
    assert(checkout(p20, 100.0) == 80.0);
    assert(checkout(thresh, 100.0) == 100.0);   // 不达 200 门槛
    std::println("策略: 100 元 -> 100 / 80 / 100（门槛不触发）");

    // 260 元：8折 208；满 200 减 30 -> 230
    assert(checkout(p20, 260.0) == 208.0);
    assert(checkout(thresh, 260.0) == 230.0);
    std::println("策略: 260 元 -> 8折 208 / 满减 230");

    // ---- function 版：闭包即策略，逐点同值 ----
    const DiscountFn fn_none = [](double o) { return o; };
    const DiscountFn fn_p20 = [](double o) { return o * 0.80; };
    const DiscountFn fn_thresh = [](double o) { return o >= 200.0 ? o - 30.0 : o; };

    assert(fn_none(100.0) == checkout(none, 100.0));
    assert(fn_p20(100.0) == checkout(p20, 100.0));
    assert(fn_p20(260.0) == checkout(p20, 260.0));
    assert(fn_thresh(100.0) == checkout(thresh, 100.0));
    assert(fn_thresh(260.0) == checkout(thresh, 260.0));
    std::println("function: 五个点与虚函数版逐点同值");

    // ---- concepts 静态分发：编译期绑定同一闭包 ----
    static_assert(DiscountLike<PercentDiscount>);          // 类策略也满足 concept
    static_assert(DiscountLike<decltype(fn_p20)>);         // 闭包同样满足
    assert(checkout_fast(fn_p20, 260.0) == 208.0);
    assert(checkout_fast(fn_thresh, 260.0) == 230.0);
    std::println("concepts: checkout_fast 静态分发结果一致（无虚表）");

    std::println("自检通过");
}
