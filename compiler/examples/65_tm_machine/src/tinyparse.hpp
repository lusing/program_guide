// file: src/tinyparse.hpp
// TINY 递归下降分析器（L 书 §4.4 的原路线——每语句一个过程）。
#ifndef TIP_TINYPARSE_HPP
#define TIP_TINYPARSE_HPP

#include "tinyscan.hpp"   // ScanTok
#include "tiny.hpp"

namespace tiny {

// 解析整程序；失败抛 ParseError（带行号）。
Program parse(const std::vector<ScanTok> &toks);

}  // namespace tiny

#endif  // TIP_TINYPARSE_HPP
