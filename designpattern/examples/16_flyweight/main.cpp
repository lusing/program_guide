// 16 享元。
#include <cassert>
#include <print>
#include <string>

#include "flyweight.hpp"

int main() {
    using namespace dp;

    // ---- 内蕴共享：同字同型只入池一份 ----
    GlyphFactory f;
    const Glyph& g1 = f.get('a', 1);
    const Glyph& g2 = f.get('a', 1);
    const Glyph& g3 = f.get('b', 1);

    bool same = (&g1 == &g2);            // 只取布尔结论，不打印地址
    assert(same);
    assert(&g1 != &g3);
    assert(f.pool_size() == 2);
    std::println("享元: 'a' 两次 get 同对象={}，池大小={}", same ? "是" : "否",
                 f.pool_size());

    // ---- 100 字符渲染，池只装不同 (ch,font) 组合 ----
    GlyphFactory f2;
    std::string text;                     // 'a'..'z' 循环 → 26 种内蕴组合
    for (int i = 0; i < 100; ++i) text += static_cast<char>('a' + i % 26);

    std::string out;
    size_t n = render_text(text, 1, f2, out);
    assert(n == 100);
    assert(f2.pool_size() <= 26);
    std::println("享元: 渲染 {} 字符，池大小 {}（未为 100 个字位各造对象）", n,
                 f2.pool_size());

    // ---- 外蕴状态在输出里逐位出现，共享的只有内蕴 ----
    std::string small;
    render_text("aba", 1, f2, small);
    std::println("外蕴: {}", small.substr(0, small.size() - 1));
    assert(f2.pool_size() <= 26);         // "aba" 没有新增池项（'a','b' 已在）

    std::println("自检通过");
}
