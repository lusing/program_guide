// file: src/dag.hpp
// 第 34 章配套：基本块 DAG——局部公共子表达式、代数恒等式、死节点剔除、重发射。
// 结点 = 叶（常量/名字）或运算（op + 孩子指针）；名字标签表把名字绑到结点。
// 多个名字绑同一结点 = 公共子表达式的机器证据。
#ifndef TIP_DAG_HPP
#define TIP_DAG_HPP

#include <map>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

struct DagNode {
    bool isLeaf = true;
    std::string leaf;                 // 叶：常量串或变量名
    TOp op = TOp::Copy;               // 运算结点
    int kid0 = -1, kid1 = -1;         // 孩子下标
    std::vector<std::string> labels;  // 绑定的名字（首个为代表名）
};

struct DagResult {
    std::vector<DagNode> nodes;
    std::map<std::string, int> labelOf;    // 名字 → 结点（当前绑定）
    int algebraHits = 0;                   // 代数恒等式命中次数
    int cseHits = 0;                       // 结点复用（含多标签）次数
};

// 构造一个块的 DAG（块尾跳转/输出/返回的引用作为根登记）。
DagResult dagBuild(const std::vector<Quad> &code, const Block &b);

// 重发射：按拓扑序输出“够用”的指令——只发射有标签或被引用的结点；
// 额外标签用复制绑定。返回新指令序列（不含块尾跳转，跳转原样接回）。
std::vector<Quad> dagEmit(const DagResult &dag, const std::vector<Quad> &code,
                          const Block &b);

}  // namespace tip

#endif  // TIP_DAG_HPP
