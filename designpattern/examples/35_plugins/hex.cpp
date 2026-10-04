// 插件一：hex 编码。整个插件 = 一个类型 + 一个静态哨兵，main 对它零知识。
#include <string>
#include <string_view>

#include "plugin.hpp"

namespace {

struct HexCodec final : dp::Codec {
    std::string name() const override { return "hex"; }
    std::string encode(std::string_view data) const override {
        static const char* kDigits = "0123456789abcdef";
        std::string out;
        out.reserve(data.size() * 2);
        for (const unsigned char ch : data) {
            out += kDigits[ch >> 4];
            out += kDigits[ch & 0x0F];
        }
        return out;
    }
};

const dp::RegisterOne<HexCodec> reg_hex;   // main 之前完成注册

}  // namespace
