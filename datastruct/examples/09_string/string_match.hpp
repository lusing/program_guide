#ifndef DS_STRING_MATCH_HPP
#define DS_STRING_MATCH_HPP

#include <string_view>
#include <vector>

namespace ds {

inline constexpr size_t npos = std::string_view::npos;

// 朴素模式匹配（Brute Force）：从 text[pos] 起逐个起点对齐 pat。
// 找到返回首次匹配的起点；找不到返回 npos。
// 空模式约定与 std::string_view::find 一致：返回 min(pos, text.size())。
size_t bf_find(std::string_view text, std::string_view pat, size_t pos = 0) {
    const size_t n = text.size();
    const size_t m = pat.size();
    if (m == 0) {
        return pos < n ? pos : n;
    }
    if (pos > n || m > n - pos) {
        return npos;
    }
    const size_t last = n - m;  // 最后一个合法起点
    for (size_t i = pos; i <= last; ++i) {
        size_t j = 0;
        while (j < m && text[i + j] == pat[j]) {
            ++j;
        }
        if (j == m) {
            return i;
        }
    }
    return npos;
}

// 构造 KMP 的部分匹配表 pi：pi[i] = pat[0..i] 最长相等真前缀/真后缀长度。
std::vector<size_t> build_pi(std::string_view pat) {
    const size_t m = pat.size();
    std::vector<size_t> pi(m, 0);
    if (m <= 1) {
        return pi;
    }
    for (size_t i = 1; i < m; ++i) {
        size_t j = pi[i - 1];
        while (j > 0 && pat[i] != pat[j]) {
            j = pi[j - 1];
        }
        if (pat[i] == pat[j]) {
            ++j;
        }
        pi[i] = j;
    }
    return pi;
}

// KMP 匹配：借助 pi，失配时模式游标按 pi 回退，正文游标永不后退。
size_t kmp_find(std::string_view text, std::string_view pat, size_t pos = 0) {
    const size_t n = text.size();
    const size_t m = pat.size();
    if (m == 0) {
        return pos < n ? pos : n;
    }
    if (pos > n || m > n - pos) {
        return npos;
    }
    const std::vector<size_t> pi = build_pi(pat);
    size_t i = pos;  // 正文游标，只增不减
    size_t j = 0;    // 模式游标
    while (i < n) {
        if (text[i] == pat[j]) {
            ++i;
            ++j;
            if (j == m) {
                return i - m;
            }
        } else if (j > 0) {
            j = pi[j - 1];
        } else {
            ++i;
        }
    }
    return npos;
}

}  // namespace ds

#endif  // DS_STRING_MATCH_HPP
