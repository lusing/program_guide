// 08 单例。
#include <cassert>
#include <print>
#include <string>

#include "once_singleton.hpp"
#include "singleton.hpp"

int main() {
    using namespace dp;

    // ---- Meyers 单例：全局唯一 + 惰性构造 ----
    Config& a = Config::instance();
    Config& b = Config::instance();
    bool same = (&a == &b);                  // 只取布尔结论，不打印地址
    assert(same);
    a.set("theme", "dark");
    assert(b.get("theme") == "dark");        // 一个写，另一个立刻看见：同一对象
    a.set("lang", "zh");
    assert(a.count() == 2);
    std::println("单例: 两次 instance() 是同一对象={}", same ? "是" : "否");

    // 拷贝在编译期就被禁用（拷贝构造 =delete），想复制只能传引用。
    // Config c = a;   // 编译错误：delete 了拷贝构造

    // ---- call_once 版：带构造参数的单例 ----
    NamedPool& p1 = NamedPool::instance("main-pool");
    NamedPool& p2 = NamedPool::instance("another-name");   // 参数被忽略
    assert(&p1 == &p2);
    assert(p1.name() == "main-pool");        // 首调用者的参数生效
    std::println("call_once: 实例名={}, 二次传参被丢弃",
                 p1.name());

    std::println("自检通过");
}
