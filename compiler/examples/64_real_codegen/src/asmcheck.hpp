// file: src/asmcheck.hpp
// 运行期调 gcc -S、按模式表对账的检查器（L 书 §8.6 的"现代对账"机器）。
#ifndef TIP_ASMCHECK_HPP
#define TIP_ASMCHECK_HPP

#include <map>
#include <string>
#include <vector>

namespace rc {

// 汇编模式：名字 + 正则（AT&T 语法，gcc/clang 的 mingw 目标）。
struct Pattern {
    std::string name, re;
};

// 一个函数在一档优化下的报告。
struct FuncReport {
    std::string func, opt;
    size_t insns = 0;                      // 指令行数（缩进行启发式）
    std::map<std::string, int> hits;       // 模式 → 出现次数
    std::vector<std::string> keyLines;     // 命中模式的首行样本（正文锚点用）
};

// 落盘 tmpdir → gcc -S {opt} -o out.s in.c → 读回 .s → 逐行匹配。
// gcc 不可用（退出码非零）时抛 runtime_error（check_example 会把它变成失败）。
std::vector<FuncReport> checkAll(const std::vector<std::string> &funcs,
                                 const std::vector<Pattern> &pats,
                                 const std::string &opt);

// 模式表：帧建立 / 帧相对寻址 / 取址 / 比例寻址 / 调用返回 / 栈操作。
std::vector<Pattern> defaultPatterns();

}  // namespace rc

#endif  // TIP_ASMCHECK_HPP
