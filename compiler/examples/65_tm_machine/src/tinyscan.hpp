// file: src/tinyscan.hpp
// TINY 扫描器（L 书 §2.5 的手写路线：保留字表 + 标识符/数字 + 最长 ':='）。
#ifndef TIP_TINYSCAN_HPP
#define TIP_TINYSCAN_HPP

#include <string>
#include <vector>

#include "tiny.hpp"

namespace tiny {

struct ScanTok {
    Tok kind;
    std::string text;   // Num 的原文 / Id 的名字
    long long num = 0;  // Num
    int line = 1;
};

// 注释 { ... } 嵌套不计（书里单层）；无法成词抛 ParseError。
std::vector<ScanTok> scan(const std::string &src);

const char *tokName(Tok t);

}  // namespace tiny

#endif  // TIP_TINYSCAN_HPP
