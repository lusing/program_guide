// 插件三：反串。
#include <string>
#include <string_view>

#include "plugin.hpp"

namespace {

struct ReverseCodec final : dp::Codec {
    std::string name() const override { return "reverse"; }
    std::string encode(std::string_view data) const override {
        return {data.rbegin(), data.rend()};
    }
};

const dp::RegisterOne<ReverseCodec> reg_reverse;   // main 之前完成注册

}  // namespace
