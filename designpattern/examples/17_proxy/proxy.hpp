#pragma once
// 代理：替身与本体同接口，访问先过代理——把"访问时机/权限/成本"控制
// 收进替身层。本例：虚代理（懒加载）。
#include <memory>
#include <optional>
#include <string>
#include <string_view>

namespace dp {

// Subject：代理与本体共同的接口。
struct Image {
    virtual ~Image() = default;
    virtual void draw() const = 0;
    [[nodiscard]] virtual std::string name() const = 0;
};

// RealSubject：真身——构造即"昂贵"（教学里用静态计数模拟加载成本）。
class RealImage final : public Image {
public:
    explicit RealImage(std::string name) : name_(std::move(name)) { ++constructed; }

    void draw() const override { last_drawn_ = name_; }
    [[nodiscard]] std::string name() const override { return name_; }
    [[nodiscard]] static int constructed_count() { return constructed; }
    [[nodiscard]] static const std::string& last_drawn() { return last_drawn_; }

    inline static int constructed = 0;               // 教学观测：构造次数

private:
    std::string name_;
    inline static std::string last_drawn_;
};

// Proxy（经典版）：构造时绝不碰真身；首次 draw 才加载。
// mutable：const 的 draw() 内部允许"惰性装配"这个实现细节发生。
class LazyImageProxy final : public Image {
public:
    explicit LazyImageProxy(std::string name) : name_(std::move(name)) {}

    void draw() const override {
        ensure_loaded();                              // 首次才付加载成本
        real_->draw();
    }
    [[nodiscard]] std::string name() const override { return name_; }  // 便宜操作直通

private:
    void ensure_loaded() const {
        if (!real_) real_ = std::make_unique<RealImage>(name_);
    }

    std::string name_;
    mutable std::unique_ptr<RealImage> real_;         // mutable：惰性装配位
};

// 现代对照：std::optional 惰性——同构、但持有值本体（免堆分配）。
class OptImage {
public:
    explicit OptImage(std::string name) : name_(std::move(name)) {}
    void draw() {
        if (!real_) real_.emplace(name_);             // emplace 原地构造
        real_->draw();
    }
    [[nodiscard]] std::string name() const { return name_; }

private:
    std::string name_;
    std::optional<RealImage> real_;
};

}  // namespace dp
