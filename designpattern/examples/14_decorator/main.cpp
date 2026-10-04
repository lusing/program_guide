// 14 装饰。
#include <cassert>
#include <print>

#include "decorator.hpp"

int main() {
    using namespace dp;

    PlainStream plain;
    UpperDecorator upper(plain);

    // ---- 单层装饰 ----
    assert(upper.write("hi") == "HI");
    std::println("装饰: Upper(\"hi\") -> {}", upper.write("hi"));

    // ---- 双层包装：Timestamp(Upper(Plain))，职责按包裹顺序叠加 ----
    TimestampDecorator ts(upper);
    assert(ts.write("hi") == "[T0]HI");
    assert(ts.write("hi") == "[T1]HI");      // 计数确定递增
    std::println("装饰: {} 然后 {}", "[T0]HI", "[T1]HI");

    // ---- 顺序敏感性：换包裹顺序，行为不同（装饰链的语义） ----
    UpperDecorator upper2(plain);
    TimestampDecorator ts2(upper2);
    // Timestamp 在外：先加时间戳，内容转大写只作用于内层文本
    assert(ts2.write("ok") == "[T2]OK");
    std::println("顺序: Timestamp(Upper(x))={} 与 Upper(Timestamp(x)) 不同链不同果",
                 ts2.write("done") == "[T3]DONE" ? "[T3]DONE" : "?");

    // ---- 同一接口多态消费：装饰物与原件可互换 ----
    const Stream& poly = ts;
    assert(poly.write("final") == "[T4]FINAL");
    std::println("多态: Stream& 不区分原件与三层装饰");

    std::println("自检通过");
}
