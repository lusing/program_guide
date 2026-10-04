#pragma once
// 注册表工厂：加形状 = 注册一行，工厂代码不再修改。
#include <expected>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <string_view>

#include "simple_factory.hpp"

namespace dp {

using ShapeMaker = std::function<std::unique_ptr<Shape>()>;

class ShapeRegistry {
public:
    static ShapeRegistry& instance() {
        static ShapeRegistry inst;   // magic static：线程安全的一次初始化（见第 8 章）
        return inst;
    }

    bool add(std::string kind, ShapeMaker maker) {
        return makers_.emplace(std::move(kind), std::move(maker)).second;
    }

    std::expected<std::unique_ptr<Shape>, std::string> make(std::string_view kind) {
        auto it = makers_.find(std::string{kind});
        if (it == makers_.end())
            return std::unexpected(std::format("未注册形状: {}", kind));
        return it->second();   // 调用注册时存下的构造器
    }

    [[nodiscard]] size_t size() const { return makers_.size(); }

private:
    ShapeRegistry() = default;
    std::map<std::string, ShapeMaker> makers_;
};

}  // namespace dp
