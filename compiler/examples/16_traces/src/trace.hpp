// file: src/trace.hpp
// 第 16 章配套：贪心跟踪（trace）线性化与顺直链消跳转（虎书 §8.2 Algorithm 8.3）。
// 本示例的 TAC 副本在 13 章指令族上加了 IfLe / IfNe 两个否定条件跳转——
// 翻转 CJUMP 的真假臂必须能写出条件的否定（虎书 “negate the condition”）。
#ifndef TIP_TRACE_HPP
#define TIP_TRACE_HPP

#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 本地指令族扩展：IfLe = a <= b，IfNe = a != b（仅本章使用）。
// 通过给 Quad 的 op 用 TOp 值 + 一个说明表达成；show/interp 在 main 里按章内口径处理。

// 贪心跟踪：把块集划分成若干条 trace（每块恰属一条）。
//   队列取首块开一条 trace；沿“任一未标记后继”延伸；后继全标记则收尾。
struct TracePlan {
    std::vector<std::vector<int>> traces;   // 每条 trace 的块号序列
    std::vector<int> order;                 // 线性化块序（traces 拼接）
};

TracePlan buildTraces(const std::vector<Block> &blocks);

struct LinearResult {
    std::vector<Quad> code;
    int gotosDeleted = 0;   // 无条件跳转被顺直链吞掉
    int flips = 0;          // 条件翻转（真假臂对调，用否定运算）
    int fixups = 0;         // 两臂都不顺直：补显式 goto
};

// 线性化 + 终结符重写：
//   Goto 的目标恰为下一块起点 ⇒ 删；
//   条件跳转的“假臂”（原顺序直落块）恰为下一块 ⇒ 保持；
//   真臂恰为下一块 ⇒ 翻转条件、跳假臂；
//   两臂都不顺直 ⇒ 条件跳转后补显式 goto 假臂。
LinearResult linearize(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                       const TracePlan &plan);

}  // namespace tip

#endif  // TIP_TRACE_HPP
