// 06 工厂方法。
#include <cassert>
#include <memory>
#include <print>

#include "factory_method.hpp"

int main() {
    using namespace dp;

    // 同一份 use() 流程（模板方法），子类只回答"造什么 logger"
    FileLoggerCreator fc;
    fc.use();
    assert(fc.output() == "file<hi>");

    ConsoleLoggerCreator cc;
    cc.use();
    assert(cc.output() == "console<hi>");
    std::println("工厂方法: file={}, console={}", fc.output(), cc.output());

    // 工厂方法返回 unique_ptr<Logger>：所有权即刻移交，调用方按接口持有
    std::unique_ptr<Logger> owned = cc.create();
    owned->log("second");
    auto* as_console = static_cast<ConsoleLogger*>(owned.get());
    assert(as_console->last() == "console<second>");
    std::println("所有权: 调用方持有 {} 并继续使用", as_console->last());

    std::println("自检通过");
}
