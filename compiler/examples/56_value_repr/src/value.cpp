// file: src/value.cpp
#include "value.hpp"

#include <sstream>

namespace tip {

std::string showValue(Value v) {
    if (isNumber(v)) {
        std::ostringstream os;
        os << asNumber(v);
        return os.str();
    }
    if (isBool(v)) return (v == (kQnan | kTagTrue)) ? "true" : "false";
    if (isNil(v)) return "nil";
    if (isObj(v)) {
        if (auto *s = dynamic_cast<ObjString *>(asObj(v)))
            return '"' + s->text + '"';
        return "<obj>";
    }
    return "<invalid>";
}

uint32_t fnv1a(const std::string &s) {
    // FNV-1a：偏移基数与素数是规范定的，不是选出来的（§19.3）
    uint32_t hash = 2166136261u;             // 0x811c9dc5
    for (unsigned char c : s) {
        hash ^= c;
        hash *= 16777619u;                   // 0x01000193
    }
    return hash;
}

std::unique_ptr<ObjString> makeString(std::string text) {
    auto s = std::make_unique<ObjString>();
    s->text = std::move(text);
    s->hash = fnv1a(s->text);
    return s;
}

}  // namespace tip
