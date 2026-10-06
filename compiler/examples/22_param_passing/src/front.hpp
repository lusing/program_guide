// file: src/front.hpp
// 手写扫描器 + 递归下降前端的接口。
#ifndef TIP_PFRONT_HPP
#define TIP_PFRONT_HPP

#include "lang.hpp"

namespace plang {

// 解析整程序；语法错误抛 std::runtime_error（消息带行号——§10.5 的黄金句式雏形）。
Program parse(const std::string &src);

}  // namespace plang

#endif  // TIP_PFRONT_HPP
