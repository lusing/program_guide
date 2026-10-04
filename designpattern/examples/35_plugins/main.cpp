// 35 自注册插件框架：main 不 include 任何插件实现，只按名字用。
#include <cassert>
#include <print>
#include <string>

#include "plugin.hpp"

int main() {
    using namespace dp;

    // 走到 main 时三个插件已在册——各插件 cpp 的静态哨兵在动态初始化阶段完成注册
    auto* hex = Registry::instance().find("hex");
    assert(hex != nullptr);
    assert(Registry::instance().size() == 3);
    std::println("注册线: main 之前 3 个插件已在册（hex/b64/reverse）");

    // 按名字取件、按合同编码——输出全部固定可断言
    assert(encode_with("hex", "hi") == "6869");
    assert(encode_with("b64", "hi") == "aGk=");
    assert(encode_with("reverse", "hi") == "ih");
    std::println("编码线: hex=6869 / b64=aGk= / reverse=ih 三路各自正确");

    // 未知名：门面返回 "err"（而不是 nullptr 泄漏给客户）
    assert(encode_with("nope", "hi") == "err");
    std::println("容错线: 未知名返回 err，客户零空指针");

    // 重名拒绝：再注册同名插件返回 false，注册表不受污染
    struct Dup final : Codec {
        std::string name() const override { return "hex"; }
        std::string encode(std::string_view) const override { return "dup"; }
    };
    const bool added = Registry::instance().add(std::make_unique<Dup>());
    assert(!added);
    assert(Registry::instance().size() == 3);
    assert(encode_with("hex", "hi") == "6869");   // 原插件未被顶替
    std::println("防重线: 重名注册被拒，原插件保持原位");

    std::println("自检通过");
}
