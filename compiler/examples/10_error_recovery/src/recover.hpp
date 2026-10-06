// 第 10 章正题之一：LL(1) 表驱动分析器的三种错误处置（L 书 §4.5.2 口径）。
//   None    —— 报错即停（对照组）；
//   TokenDel—— 朴素删除：删掉当前 token 重试（级联假错误的制造机）；
//   Panic   —— 恐慌模式：栈顶终结符不匹配则弹栈（假定缺失），
//              非终结符无表项则丢输入至 FOLLOW(A) 再弹 A（同步集恢复）。
#ifndef TIP_RECOVER_HPP
#define TIP_RECOVER_HPP

#include <string>
#include <vector>

#include "ll1.hpp"

namespace tip {

enum class LLRecover { None, TokenDel, Panic, Phrase };

struct Diag {
    int pos;             // 错误检测点的 token 下标（0 起）
    std::string msg;     // 人话诊断
};

struct LLResult {
    bool accept = false;
    int steps = 0;
    std::vector<Diag> diags;
    int detectPos = -1;  // 首个错误的 token 下标（LL/LR 对照表的 LL 侧数据）
};

// input 为终结符种类序列（不含尾部 $；函数内部补）。
LLResult llParse(const LL1 &ll, const std::vector<std::string> &input, LLRecover mode);

}  // namespace tip

#endif  // TIP_RECOVER_HPP
