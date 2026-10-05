// file: src/alloc.hpp
// 第 59 章配套：局部寄存器分配与 SSA 弦图着色（鲸书 §13.3 + §13.5.2）。
#ifndef TIP_ALLOC_HPP
#define TIP_ALLOC_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 局部分配的输入：一个直线块 ----------
struct LocalInst {
    std::string dst;                 // 空 = 纯使用（如 output）
    std::vector<std::string> uses;
};

// 自顶向下（频率计数）：整块独占寄存器，排不上的住内存。
// 返回访存次数（内存值的每次使用 = 1 load，每次定义 = 1 store）。
struct LocalReport {
    int memoryTraffic = 0;
    std::vector<std::string> resident;   // 住上寄存器的名字（按优先序）
};
LocalReport topDownLocal(const std::vector<LocalInst> &block, int k);

// 自底向上（farthest-use 驱逐）：逐指令现场装/卸，驱逐"下次使用最远"者。
// 脏值驱逐先 store；内存值使用先 load。
LocalReport bottomUpLocal(const std::vector<LocalInst> &block, int k);

// ---------- SSA 干涉图与着色 ----------

using EdgeSet = std::set<std::pair<std::string, std::string>>;

struct Graph {
    std::set<std::string> nodes;
    EdgeSet edges;                                   // 无向，端点按字典序
    std::map<std::string, std::set<std::string>> adj;
    void addEdge(const std::string &x, const std::string &y);
};

// SSA 程序（块 + φ）→ 干涉图：def 与"定义点之后活跃"者连边；
// φ 目的不与自己的实参连边（它们天然可以共享寄存器）。
// 输入用"指令即结构"的极简形状：phiArgs 非空为 φ。
struct SsaInstLite {
    std::string dst;
    std::vector<std::string> uses;      // 非定义用途（φ 则为实参表）
    bool isPhi = false;
};
struct SsaBlockLite {
    std::vector<SsaInstLite> body;      // φ 在最前
    std::vector<int> succs;
    std::vector<int> preds;             // 与 φ 实参次序一致
};
// 活跃分析（后向到不动点；φ 实参算作对应前驱块末尾的 use）
std::vector<std::set<std::string>> ssaLiveness(const std::vector<SsaBlockLite> &blocks);

Graph buildInterference(const std::vector<SsaBlockLite> &blocks);

// 最大势搜索（MCS）：弦图线性识别 + 给出完美消除序（PEO）。
// 返回节点序列（按编号升序；逆序即 PEO）。
std::vector<std::string> mcsOrder(const Graph &g);

// PEO 合法性校验：序中每个点的"靠后邻居"成团。
bool isPerfectElimination(const Graph &g, const std::vector<std::string> &order);

// 依 PEO 贪心着色 = 弦图最优着色（色数 = 团数）。
std::map<std::string, int> chordalColor(const Graph &g, const std::vector<std::string> &peo);

// PEO 口径的最大团数：max_v (1 + |靠后邻居|)
int peoCliqueNumber(const Graph &g, const std::vector<std::string> &peo);

// Chaitin–Briggs：simplify（度<k 压栈）+ select（后进先出挑色）。
// 返回空 map 表示 k 太小发生溢出。
std::map<std::string, int> briggsColor(const Graph &g, int k);

// 着色合法性：相邻异色且颜色在 [0,k)
bool coloringValid(const Graph &g, const std::map<std::string, int> &color, int k);

}  // namespace tip

#endif  // TIP_ALLOC_HPP
