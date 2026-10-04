#include <cassert>
#include <cstddef>
#include <print>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include "huffman.hpp"
#include "lzw.hpp"

// 15 霍夫曼编码与 LZW：两种经典压缩思想的可校验实现

int main() {
    // ═══ 霍夫曼：Sahni 教材例题频率（a..f = 6,2,3,3,4,9）═══
    const std::pair<char, int> freqs[] = {
        {'a', 6}, {'b', 2}, {'c', 3}, {'d', 3}, {'e', 4}, {'f', 9},
    };
    const ds::Huffman huff(freqs);
    const std::vector<ds::HuffCode> table = huff.codes();
    assert(table.size() == 6);

    // 前缀自由：任意两个码字互不为对方前缀（逐对检查 15 对）
    auto is_prefix = [](std::string_view p, std::string_view s) {
        return s.size() >= p.size() && s.substr(0, p.size()) == p;
    };
    for (size_t i = 0; i < table.size(); ++i) {
        for (size_t j = i + 1; j < table.size(); ++j) {
            const std::string_view bi = table[i].bits;
            const std::string_view bj = table[j].bits;
            assert(!is_prefix(bi, bj));
            assert(!is_prefix(bj, bi));
        }
    }

    // 确定性：同频率表重建，码字表逐字符一致
    const ds::Huffman huff2(freqs);
    assert(huff2.codes() == table);

    std::println("霍夫曼码字（频率 a..f = 6,2,3,3,4,9，平局按输入编号）：");
    for (const ds::HuffCode& c : table) {
        std::println("  {} : {}", c.ch, c.bits);
    }

    // 编码 → 解码还原原文（每个字符频率都为正）
    const std::string text = "abcdefabcdef";
    const std::string bits = huff.encode(text);
    assert(!bits.empty());
    assert(huff.decode(bits) == text);
    std::println("霍夫曼编解码往返：原文 {} 字符，位串 {} 位，解码完全还原",
                 text.size(), bits.size());

    // 字母表外字符必须被拒绝
    bool huff_threw = false;
    try {
        (void)huff.encode("z");
    } catch (const std::invalid_argument&) {
        huff_threw = true;
    }
    assert(huff_threw);
    std::println("字母表外字符编码：抛异常");

    // ═══ LZW：固定串，首个新码恰为 256 ═══
    const std::string lz_text = "ababcbababaaaaaaa";
    const std::vector<int> encoded = ds::lzw_encode(lz_text);
    assert(encoded.size() >= 3);
    assert(encoded[0] == 'a');
    assert(encoded[1] == 'b');
    assert(encoded[2] == 256);  // "ab" 是第一个新串，编号 256

    std::println("LZW 编码 \"{}\"（{} 字节 → {} 个码）：", lz_text,
                 lz_text.size(), encoded.size());
    for (size_t i = 0; i < encoded.size(); ++i) {
        std::println("  [{}] {}", i, encoded[i]);
    }

    const std::string decoded = ds::lzw_decode(encoded);
    assert(decoded == lz_text);
    std::println("LZW 解码往返：完全还原（{} 字节）", decoded.size());

    // 空文本与空码序列
    assert(ds::lzw_encode("").empty());
    assert(ds::lzw_decode(std::span<const int>{}) == "");
    std::println("空文本：编码空、解码空");

    // 码超出当前词典（首码合法，第二码 9999 尚未登记）→ 抛异常
    static const int bad_codes[] = {97, 9999};
    bool lzw_threw = false;
    try {
        (void)ds::lzw_decode(bad_codes);
    } catch (const std::invalid_argument&) {
        lzw_threw = true;
    }
    assert(lzw_threw);
    std::println("非法 LZW 码：抛异常");

    std::println("自检通过");
}
