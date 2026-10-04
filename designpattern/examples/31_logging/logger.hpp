#pragma once
// 31 日志系统：策略模式（级别过滤）+ 观察者广播（多 sink）+ 装饰器（前缀）+ 工厂。
// 经典线用 Sink 抽象类；现代线把过滤做成模板策略、把 sink 做成 std::function。
#include <functional>
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace dp {

enum class Level { debug = 0, info = 1, warn = 2, error = 3 };

// ---- 经典线 ----

// Sink 接口：决定"日志写到哪里"。Logger 只认这个抽象，具体落点随意增删。
struct Sink {
    virtual ~Sink() = default;
    virtual void write(Level lvl, const std::string& msg) = 0;
};

// 计数 sink：按级别攒 "L<级别号>:<msg>"，供测试断言（确定性输出，不打时间戳）。
class CountSink final : public Sink {
public:
    void write(Level lvl, const std::string& msg) override {
        const int i = static_cast<int>(lvl);
        ++count_[i];
        last_[i] = "L" + std::to_string(i) + ":" + msg;
    }
    int count(Level lvl) const { return count_[static_cast<int>(lvl)]; }
    const std::string& last(Level lvl) const { return last_[static_cast<int>(lvl)]; }

private:
    int count_[4] = {};
    std::string last_[4];
};

// 丢弃 sink：级别开着但暂不输出时的占位（工厂的一种产品）。
class NullSink final : public Sink {
public:
    void write(Level, const std::string&) override {}
};

class Logger {
public:
    void set_level(Level l) { level_ = l; }
    void add_sink(std::shared_ptr<Sink> s) { sinks_.push_back(std::move(s)); }

    // 策略（级别过滤）+ 观察者（广播）在同一行里协作：先过滤，后扇出。
    void log(Level lvl, const std::string& msg) {
        if (lvl < level_) return;
        for (const auto& s : sinks_) s->write(lvl, msg);
    }

private:
    Level level_ = Level::debug;
    std::vector<std::shared_ptr<Sink>> sinks_;
};

// 装饰器：接口不变，行为叠加——前缀先拼，再交给内层 sink。
class PrefixSink final : public Sink {
public:
    PrefixSink(std::shared_ptr<Sink> inner, std::string prefix)
        : inner_(std::move(inner)), prefix_(std::move(prefix)) {}
    void write(Level lvl, const std::string& msg) override {
        inner_->write(lvl, prefix_ + msg);
    }

private:
    std::shared_ptr<Sink> inner_;
    std::string prefix_;
};

// 工厂：客户只见 Sink，不见具体类。
enum class SinkKind { count, null };

inline std::shared_ptr<Sink> make_sink(SinkKind kind) {
    switch (kind) {
        case SinkKind::count: return std::make_shared<CountSink>();
        case SinkKind::null:  return std::make_shared<NullSink>();
    }
    return nullptr;
}

inline std::shared_ptr<Sink> make_prefix_sink(std::shared_ptr<Sink> inner, std::string prefix) {
    return std::make_shared<PrefixSink>(std::move(inner), std::move(prefix));
}

// ---- 现代线 ----

// 过滤策略：可替换的谓词对象——换阈值、换规则都只是换这个类型。
struct LevelFilter {
    explicit LevelFilter(Level l) : level(l) {}
    bool operator()(Level msg) const { return msg >= level; }
    Level level;
};

// LoggerT<Filter>：过滤策略编译期注入；sink 是 std::function——不定义 Sink 类也能挂。
template <typename Filter = LevelFilter>
class LoggerT {
public:
    explicit LoggerT(Filter f = Filter{Level::debug}) : filter_(std::move(f)) {}
    void add_sink(std::function<void(Level, const std::string&)> fn) {
        sinks_.push_back(std::move(fn));
    }
    void log(Level lvl, const std::string& msg) {
        if (!filter_(lvl)) return;
        for (const auto& fn : sinks_) fn(lvl, msg);
    }

private:
    Filter filter_;
    std::vector<std::function<void(Level, const std::string&)>> sinks_;
};

using LoggerF = LoggerT<>;   // 默认策略 = 级别过滤

}  // namespace dp
