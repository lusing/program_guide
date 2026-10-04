#pragma once
// 多态三副面孔之一：虚函数——运行期分派的经典形态。
// 本卷同时定义 Sq/Ci 两个最小形状，concept/variant 两个 hpp 复用它们。
#include <memory>
#include <string>
#include <vector>

namespace dp {

// 抽象接口：draw 把自己的名字追加到 out（返回值传递，避免访问者式累计）。
struct Drawable {
    virtual ~Drawable() = default;
    virtual void draw(std::string& out) const = 0;
};

struct Sq final : Drawable {
    void draw(std::string& out) const override {
        if (!out.empty()) out += ';';
        out += "sq";
    }
};

struct Ci final : Drawable {
    void draw(std::string& out) const override {
        if (!out.empty()) out += ';';
        out += "ci";
    }
};

// 运行期多态：异构容器（unique_ptr<Drawable>），虚表分派。
inline std::string render(const std::vector<std::unique_ptr<Drawable>>& v) {
    std::string out;
    for (const auto& d : v) d->draw(out);
    return out;
}

}  // namespace dp
