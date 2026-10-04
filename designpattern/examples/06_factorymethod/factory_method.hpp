#pragma once
// 工厂方法：把"实例化哪一种 Logger"延迟到子类决定。
#include <memory>
#include <string>
#include <string_view>

namespace dp {

struct Logger {
    virtual ~Logger() = default;
    virtual void log(std::string_view msg) = 0;
};

class FileLogger final : public Logger {
public:
    void log(std::string_view msg) override { last_ = std::format("file<{}>", msg); }
    [[nodiscard]] const std::string& last() const { return last_; }
private:
    std::string last_;
};

class ConsoleLogger final : public Logger {
public:
    void log(std::string_view msg) override { last_ = std::format("console<{}>", msg); }
    [[nodiscard]] const std::string& last() const { return last_; }
private:
    std::string last_;
};

// Creator：use() 是模板方法——框架定流程，子类只回答"造什么"。
class LoggerCreator {
public:
    virtual ~LoggerCreator() = default;
    virtual std::unique_ptr<Logger> create() const = 0;

    // 注意：不能在构造函数里调用 create()——那时子类部分尚未出生，虚分派
    // 还在基类（GoF 原书在工厂方法一章专门警告过的坑）。所有工厂方法调用
    // 都放在 use() 这样的普通成员函数里。
    void use() const {
        auto logger = create();      // 工厂方法：制造
        logger->log("hi");           // 使用
        report(*logger);
    }

protected:
    virtual void report(const Logger& l) const = 0;   // 钩子：子类报告用过的 logger
};

class FileLoggerCreator final : public LoggerCreator {
public:
    std::unique_ptr<Logger> create() const override { return std::make_unique<FileLogger>(); }

protected:
    void report(const Logger& l) const override {
        output_ = static_cast<const FileLogger&>(l).last();
    }

public:
    const std::string& output() const { return output_; }   // 仅供测试观察
private:
    mutable std::string output_;
};

class ConsoleLoggerCreator final : public LoggerCreator {
public:
    std::unique_ptr<Logger> create() const override { return std::make_unique<ConsoleLogger>(); }

protected:
    void report(const Logger& l) const override {
        output_ = static_cast<const ConsoleLogger&>(l).last();
    }

public:
    const std::string& output() const { return output_; }
private:
    mutable std::string output_;
};

}  // namespace dp
