// 30 类型擦除：虚函数的"接口 + 值语义外壳"，却接受写不出名字的类型。
#include <cassert>
#include <functional>
#include <print>
#include <string>
#include <vector>

#include "erase.hpp"

namespace {

// 最小形状（与 29 章同构）：只实现 draw，没有 id()。
struct Sq {
    void draw(std::string& out) const {
        if (!out.empty()) out += ';';
        out += "sq";
    }
};
struct Ci {
    void draw(std::string& out) const {
        if (!out.empty()) out += ';';
        out += "ci";
    }
};

// 适配器：给没有 id() 的形状补齐合同——形状类零改动（这正是擦除的美德）。
struct SqA {
    Sq value;
    void draw(std::string& out) const { value.draw(out); }
    std::string id() const { return "Sq"; }
};
struct CiA {
    Ci value;
    void draw(std::string& out) const { value.draw(out); }
    std::string id() const { return "Ci"; }
};

// lambda 只有 operator()，没有 draw 成员——包装一层才装得进双接口合同。
struct LamA {
    std::function<void(std::string&)> fn;
    void draw(std::string& out) const { fn(out); }
    std::string id() const { return "lambda"; }
};

}  // namespace

int main() {
    using namespace dp;

    std::vector<AnyDrawable> bag;
    bag.emplace_back(SqA{});
    bag.emplace_back(CiA{});
    bag.emplace_back(LamA{[](std::string& o) {
        if (!o.empty()) o += ';';
        o += "lam";
    }});

    {   // 匿名局部类型：名字写不出来，虚函数版装不下（写不出基类列表），擦除装得下
        struct {
            void draw(std::string& out) const {
                if (!out.empty()) out += ';';
                out += "local";
            }
            std::string id() const { return "local"; }
        } local_shape;
        bag.push_back(local_shape);   // 模板构造函数照样把它擦进去
        assert(local_shape.id() == "local");
    }

    std::string out;
    for (const auto& d : bag) d.draw(out);
    assert(out == "sq;ci;lam;local");

    std::vector<std::string> ids;
    for (const auto& d : bag) ids.push_back(d.id());
    assert(ids[0] == "Sq" && ids[1] == "Ci" && ids[2] == "lambda" && ids[3] == "local");

    // move-only 外壳：拷贝被删，移动后原对象空壳（unique_ptr 所有权转移）
    AnyDrawable moved = std::move(bag[0]);
    std::string mout;
    moved.draw(mout);
    assert(mout == "sq");
    std::println("类型擦除: 四种类型（含匿名局部类型与 lambda 包装）统一 draw/id");
    std::println("自检通过");
}
