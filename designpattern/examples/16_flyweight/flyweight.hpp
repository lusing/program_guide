#pragma once
// 享元：共享大量细粒度对象的相同部分（内蕴状态），变化部分（外蕴状态）
// 由使用现场传入——用"指针共享"换"对象数量"。
#include <format>
#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <utility>

namespace dp {

// Flyweight：内蕴状态（字符 + 字型）——所有"同字同型"的字位共享这一份。
struct Glyph {
    char ch;
    int font;
    [[nodiscard]] std::string describe() const {
        return std::format("glyph({},{})", ch, font);
    }
};

// FlyweightFactory：按 (ch, font) 查表，没有才造——池只增不减、键唯一。
// get() 标 const：取字位在语义上是只读操作，池是"缓存位"（mutable）。
class GlyphFactory {
public:
    const Glyph& get(char ch, int font) const {
        auto key = std::make_pair(ch, font);
        auto it = pool_.find(key);
        if (it == pool_.end()) {
            it = pool_.emplace(key, std::make_unique<Glyph>(Glyph{ch, font})).first;
        }
        return *it->second;
    }

    [[nodiscard]] size_t pool_size() const { return pool_.size(); }

private:
    // unique_ptr 值保证 &glyph 引用稳定（map 重排也不移动对象）
    mutable std::map<std::pair<char, int>, std::unique_ptr<Glyph>> pool_;
};

// 渲染：内蕴共享（从池取），外蕴状态（位置 i）在使用现场逐个出现——
// 这是享元的代价与约定：外部必须自己管好"这份享元出现在哪"。
inline size_t render_text(std::string_view text, int font, const GlyphFactory& f,
                          std::string& out) {
    for (size_t i = 0; i < text.size(); ++i) {
        const Glyph& g = f.get(text[i], font);   // 共享读：不进池
        out += g.describe() + "@" + std::to_string(i) + " ";
    }
    return text.size();
}

}  // namespace dp
