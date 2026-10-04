// file: src/vm.hpp
// 第 14 章配套：显式活动记录的 TAC 栈机器。
// 每个帧 = [返回地址 | 控制链 | 实参槽… | 局部变量槽…]（绿龙 §10.1 的布局）。
// TIP 的函数是平铺的（文法无嵌套声明），所以没有访问链——
// 嵌套语言要补的 access link / display 见正文 14.5 的自包含讨论。
#ifndef TIP_VM_HPP
#define TIP_VM_HPP

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "tacgen.hpp"

namespace tip {

struct Frame {
    std::string func;
    int retAddr = -1;              // 返回地址（TAC 下标；最外层为 -1）
    int controlLink = -1;          // 控制链：调用者的帧下标
    std::vector<std::string> slotName;
    std::vector<int> slot;
    int depth = 0;
};

struct VmRun {
    std::vector<int> outputs;
    std::vector<std::string> trace;   // 帧轨迹（进入对账契约）
};

class Vm {
public:
    // funcs: 函数名 → (声明, TAC)
    void define(const FunDecl &fn, std::vector<Quad> code);
    VmRun run(const std::vector<int> &inputs);

private:
    // 函数名 → (声明, TAC, 临时槽序)
    std::map<std::string,
             std::tuple<const FunDecl *, std::vector<Quad>, std::vector<std::string>>> funcs_;
    std::vector<Frame> stack_;
    std::vector<int> outputs_;
    std::vector<std::string> trace_;
    std::vector<int> inputs_;
    size_t nextInput_ = 0;

    int &slot(Frame &f, const std::string &name);
    int read(Frame &f, const std::string &a);
};

}  // namespace tip

#endif  // TIP_VM_HPP
