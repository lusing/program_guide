// file: src/isel.hpp
// 第 54 章配套：指令选择（树覆盖 + Ershov 标号）与窥孔优化。
#ifndef TIP_ISEL_HPP
#define TIP_ISEL_HPP

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

struct TreeNode {
    char kind = 'v';       // 'c' 常量 / 'v' 变量名 / 'o' 运算
    int value = 0;
    std::string name;
    TOp op = TOp::Copy;
    std::unique_ptr<TreeNode> l, r;
    int ershov = 0;        // Ershov 标号：求值所需最少寄存器
    std::string result;    // munch 后的结果寄存器
};

struct Tree {
    std::string dst;
    TreeNode root;
};

// 重建表达式树（临时独占使用 → 融合），只对“根”（结果交给命名变量）建树。
std::vector<Tree> fuseTrees(const std::vector<Quad> &code, const Block &b);

int ershov(TreeNode &n);

struct Risc {
    std::string mnemonic, rd, rs;
    int target = -1;
};

std::vector<Risc> munchTree(TreeNode &n, std::vector<std::string> &notes);
std::string showRisc(const Risc &r);

std::pair<std::vector<Risc>, std::map<std::string, int>> peephole(std::vector<Risc> in);

std::vector<int> riscRun(const std::vector<Risc> &code);

}  // namespace tip

#endif  // TIP_ISEL_HPP
