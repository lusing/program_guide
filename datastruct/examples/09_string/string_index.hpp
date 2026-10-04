#ifndef DS_STRING_INDEX_HPP
#define DS_STRING_INDEX_HPP

#include <algorithm>
#include <span>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#include "string_match.hpp"

namespace ds {

// 索引项：一个词以及它在正文中首次出现的位置。
struct WordPos {
    std::string word;
    size_t pos;
};

bool is_word_char(char c) {
    const unsigned char u = static_cast<unsigned char>(c);
    return (u >= 'a' && u <= 'z') || (u >= 'A' && u <= 'Z') ||
           (u >= '0' && u <= '9') || u == '_';
}

// 为正文建立单词索引：按 ASCII 单词字符切词，每个词只保留首次出现位置，
// 结果按词的字典序排序（于是可以二分查找）。
std::vector<WordPos> build_index(std::string_view text) {
    std::unordered_map<std::string, size_t> first;
    size_t i = 0;
    while (i < text.size()) {
        if (!is_word_char(text[i])) {
            ++i;
            continue;
        }
        const size_t start = i;
        while (i < text.size() && is_word_char(text[i])) {
            ++i;
        }
        std::string word{text.substr(start, i - start)};
        first.emplace(std::move(word), start);  // 已存在则不覆盖首次位置
    }
    std::vector<WordPos> idx;
    idx.reserve(first.size());
    for (auto& [word, pos] : first) {
        idx.push_back({std::move(word), pos});
    }
    std::ranges::sort(idx, {}, &WordPos::word);
    return idx;
}

// 在有序索引上二分查词；找不到返回 nullptr。
const WordPos* lookup(std::span<const WordPos> idx, std::string_view word) {
    const auto it = std::ranges::lower_bound(idx, word, {}, &WordPos::word);
    if (it != idx.end() && (*it).word == word) {
        return &(*it);
    }
    return nullptr;
}

}  // namespace ds

#endif  // DS_STRING_INDEX_HPP
