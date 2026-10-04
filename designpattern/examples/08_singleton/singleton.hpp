#pragma once
// Meyers 单例：局部 static 由 C++11 保证只初始化一次且线程安全。
#include <string>
#include <unordered_map>

namespace dp {

class Config {
public:
    static Config& instance() {
        static Config inst;      // 首次执行到此才构造，且并发安全
        return inst;
    }

    void set(std::string k, std::string v) { kv_[std::move(k)] = std::move(v); }
    [[nodiscard]] std::string get(std::string_view k) const {
        auto it = kv_.find(std::string{k});
        return it == kv_.end() ? "" : it->second;
    }
    [[nodiscard]] size_t count() const { return kv_.size(); }

    Config(const Config&) = delete;
    Config& operator=(const Config&) = delete;

private:
    Config() = default;
    std::unordered_map<std::string, std::string> kv_;
};

}  // namespace dp
