// file: src/ra.hpp
// 第 48 章配套：活跃分析 → 干涉图 → Chaitin–Briggs 图着色。
//   块级 in/out（后向 may）+ 块内逐指令活跃（活跃区间边源）；
//   干涉边：定义点处“同时活跃”的变量对（move 的源例外——合并候选）；
//   着色：simplify 栈（度 < k 入栈）+ select（弹出时挑邻居未占色）；
//   无法着色即溢出候选——本章如实报告，改写留作练习。
#ifndef TIP_RA_HPP
#define TIP_RA_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

// 块级活跃（第 26 章同式），另给每块的 liveOut。
struct LiveInfo {
    std::vector<std::set<std::string>> in, out;
};

LiveInfo liveness(const std::vector<Quad> &code, const std::vector<Block> &blocks);

// 干涉图：邻接表 + 度。边 (x,y)：x 定义处 y 活跃（或反），
// move（Copy）的源与目的例外。
struct InterfGraph {
    std::map<std::string, std::set<std::string>> adj;
    std::set<std::pair<std::string, std::string>> edges;   // 规范序 (a<b)
    std::vector<std::pair<std::string, std::string>> moveEdges;   // 合并候选
};

InterfGraph buildInterf(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                        const LiveInfo &lv);

// 图着色（k 色）。ok=false 表示有溢出候选（spilled 列出）。
struct ColorResult {
    bool ok;
    std::map<std::string, int> color;      // 变量 → 色（0..k-1）
    std::vector<std::string> stackOrder;   // simplify 出栈序
    std::vector<std::string> spilled;      // 溢出候选
    int coalesced = 0;                     // Briggs 安全合并次数
};

ColorResult colorGraph(const InterfGraph &g, int k);

// 校验：相邻异色、色域合法。返回 true 即合法着色。
bool colorValid(const InterfGraph &g, const std::map<std::string, int> &color, int k);

}  // namespace tip

#endif  // TIP_RA_HPP
