// 31 日志系统：级别过滤（策略）+ 多 sink 广播（观察者）+ 前缀装饰 + 工厂 + 现代模板线。
#include <cassert>
#include <memory>
#include <print>
#include <string>

#include "logger.hpp"

int main() {
    using namespace dp;

    // ---- 经典线：级别过滤 + 双 sink 广播 ----
    auto a = std::make_shared<CountSink>();
    auto b = std::make_shared<CountSink>();
    Logger log;
    log.add_sink(a);
    log.add_sink(b);
    log.set_level(Level::info);            // 阈值：info 及以上才放行

    log.log(Level::debug, "dropped");      // 低于阈值：两个 sink 都收不到
    assert(a->count(Level::debug) == 0 && b->count(Level::debug) == 0);

    log.log(Level::info, "hello");
    log.log(Level::warn, "careful");
    log.log(Level::error, "boom");
    assert(a->count(Level::info) == 1 && a->count(Level::warn) == 1 && a->count(Level::error) == 1);
    assert(b->count(Level::error) == 1);   // 广播：第二个 sink 同样收到
    assert(a->last(Level::error) == "L3:boom");
    std::println("经典线: 阈值过滤 + 双 sink 广播（debug 被丢，其余各收一条）");

    // ---- 工厂 + 装饰：前缀 sink 叠在 count sink 外面 ----
    auto inner = std::make_shared<CountSink>();
    Logger log2;
    log2.add_sink(make_prefix_sink(inner, "[app] "));
    log2.set_level(Level::warn);
    log2.log(Level::info, "filtered");     // 被阈值拦下
    log2.log(Level::error, "fatal");
    assert(inner->count(Level::info) == 0);
    assert(inner->count(Level::error) == 1);
    assert(inner->last(Level::error) == "L3:[app] fatal");   // 装饰先加前缀，内层再格式化
    std::println("装饰线: PrefixSink 前缀叠加，格式化仍归内层");

    // 工厂产品：客户拿到的是 shared_ptr<Sink>，具体类名不出现
    std::shared_ptr<Sink> made = make_sink(SinkKind::null);
    assert(made != nullptr);
    Logger log3;
    log3.add_sink(made);
    log3.log(Level::error, "nowhere");     // 静默丢弃：不崩、不输出
    std::println("工厂线: make_sink 返回 Sink 抽象，客户零具体类知识");

    // ---- 现代线：过滤策略编译期注入 + std::function sink ----
    LoggerF flog{LevelFilter{Level::warn}};
    int passed = 0;
    std::string captured;
    flog.add_sink([&passed](Level, const std::string&) { ++passed; });
    flog.add_sink([&captured](Level, const std::string& msg) { captured = msg; });
    flog.log(Level::info, "filtered out");
    flog.log(Level::error, "passes");
    assert(passed == 1);
    assert(captured == "passes");          // 两个 function sink 与类 sink 行为一致
    std::println("现代线: 模板策略 + std::function sink，无 Sink 类同样工作");

    std::println("自检通过");
}
