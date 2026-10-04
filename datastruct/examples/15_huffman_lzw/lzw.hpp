#ifndef DS_LZW_HPP
#define DS_LZW_HPP

#include <cstddef>
#include <span>
#include <stdexcept>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

namespace ds {

// LZW 压缩：字节流 → 整数码序列。
//
// 初始词典：0..255 各代表一个单字节字符串；于是第一个被创建的新串码为 256。
// 编码主循环：维护当前匹配串 w。读入下一字节 c：
//   - wc 在词典中 → w 增长为 wc；
//   - 否则输出 w 的码，把 wc 以"下一个码"登记进词典，w 重置为 c。
// 空文本输出空码序列。词典不设上限（真实实现通常封顶并停止登记，正文说明）。
[[nodiscard]] inline std::vector<int> lzw_encode(std::string_view text) {
    std::unordered_map<std::string, int> dict;
    dict.reserve(512);
    for (int i = 0; i < 256; ++i) {
        dict.emplace(std::string(1, static_cast<char>(i)), i);
    }
    int next_code = 256;

    std::vector<int> out;
    std::string w;
    for (char c : text) {
        std::string wc = w + c;
        if (dict.find(wc) != dict.end()) {
            w = std::move(wc);
        } else {
            out.push_back(dict.at(w));
            dict.emplace(std::move(wc), next_code++);
            w.assign(1, c);
        }
    }
    if (!w.empty()) {
        out.push_back(dict.at(w));
    }
    return out;
}

// LZW 解压：整数码序列 → 字节流。
//
// 初始词典与压缩端相同。第一个码必为 0..255 的单字节串。之后每读一个码 k：
//   - k 已在词典 → entry = 词典[k]；
//   - k 恰等于词典当前大小（KWIK 特例）→ entry = w + w[0]；
//     这对应压缩端刚为该串登记、压缩流立刻引用它的情形；
//   - k 更大 → 码流非法，抛 invalid_argument。
// 输出 entry，并把 w + entry[0] 登记进词典（与压缩端的 LZW 规则严格同步）。
[[nodiscard]] inline std::string lzw_decode(std::span<const int> codes) {
    if (codes.empty()) {
        return "";
    }

    std::vector<std::string> dict;
    dict.reserve(512);
    for (int i = 0; i < 256; ++i) {
        dict.emplace_back(1, static_cast<char>(i));
    }

    if (codes[0] < 0 || codes[0] >= 256) {
        throw std::invalid_argument("lzw_decode: 首码必须是单字节码 0..255");
    }
    std::string result = dict[static_cast<size_t>(codes[0])];
    std::string w = result;

    for (size_t i = 1; i < codes.size(); ++i) {
        const int k = codes[i];
        std::string entry;
        if (k >= 0 && static_cast<size_t>(k) < dict.size()) {
            entry = dict[static_cast<size_t>(k)];
        } else if (static_cast<size_t>(k) == dict.size()) {
            entry = w + w[0];
        } else {
            throw std::invalid_argument("lzw_decode: 码超出当前词典");
        }

        result += entry;
        dict.push_back(w + entry[0]);
        w = std::move(entry);
    }
    return result;
}

}  // namespace ds

#endif  // DS_LZW_HPP
