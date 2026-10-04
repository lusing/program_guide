// 插件二：base64 编码（标准字母表，'=' 补位）。
#include <string>
#include <string_view>

#include "plugin.hpp"

namespace {

struct B64Codec final : dp::Codec {
    std::string name() const override { return "b64"; }
    std::string encode(std::string_view data) const override {
        static const char* kTab =
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        std::string out;
        out.reserve((data.size() + 2) / 3 * 4);
        std::size_t i = 0;
        while (i + 2 < data.size()) {                      // 3 字节 -> 4 字符
            const unsigned n = (static_cast<unsigned char>(data[i]) << 16) |
                               (static_cast<unsigned char>(data[i + 1]) << 8) |
                                static_cast<unsigned char>(data[i + 2]);
            out += kTab[(n >> 18) & 63];
            out += kTab[(n >> 12) & 63];
            out += kTab[(n >> 6) & 63];
            out += kTab[n & 63];
            i += 3;
        }
        const std::size_t rest = data.size() - i;
        if (rest == 1) {                                   // 剩 1 字节：2 字符 + '=='
            const unsigned n = static_cast<unsigned char>(data[i]) << 16;
            out += kTab[(n >> 18) & 63];
            out += kTab[(n >> 12) & 63];
            out += "==";
        } else if (rest == 2) {                            // 剩 2 字节：3 字符 + '='
            const unsigned n = (static_cast<unsigned char>(data[i]) << 16) |
                               (static_cast<unsigned char>(data[i + 1]) << 8);
            out += kTab[(n >> 18) & 63];
            out += kTab[(n >> 12) & 63];
            out += kTab[(n >> 6) & 63];
            out += '=';
        }
        return out;
    }
};

const dp::RegisterOne<B64Codec> reg_b64;   // main 之前完成注册

}  // namespace
