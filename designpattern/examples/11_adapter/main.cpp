// 11 适配器。
#include <cassert>
#include <print>

#include "object_adapter.hpp"
#include "template_adapter.hpp"

int main() {
    using namespace dp;

    // ---- 对象适配器：包装一个已有的 LegacyStack 实例 ----
    LegacyStack legacy;
    StackAdapter adapter(legacy);
    assert(adapter.empty());

    adapter.push(1);
    adapter.push(2);
    adapter.push(3);
    assert(!adapter.empty());
    std::println("对象适配器: push×3 后 empty={}", adapter.empty() ? "是" : "否");

    // LIFO 顺序验证：3、2、1
    assert(adapter.pop() == 3);
    assert(adapter.pop() == 2);
    assert(adapter.pop() == 1);
    assert(adapter.empty());
    std::println("对象适配器: pop 顺序 3->2->1 LIFO 正确");

    // ---- 类适配器：多继承版，同样满足 Target 接口 ----
    StackClassAdapter cadapter;
    cadapter.push(10);
    cadapter.push(20);
    assert(cadapter.pop() == 20);
    assert(cadapter.pop() == 10);
    assert(cadapter.empty());
    std::println("类适配器: pop 顺序 20->10 LIFO 正确");

    // 多态消费：两种适配器都能交给"只要 StackLike"的代码
    StackLike& poly = adapter;
    poly.push(99);
    assert(poly.pop() == 99);
    std::println("多态: StackLike& 消费对象/类两种适配器均可用");

    std::println("自检通过");
}
