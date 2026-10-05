// file: src/tacinterp.hpp
// 第 15 章配套：多函数 TAC 解释器（第 13 章证人版加调用栈）。
// 与 Vm 的分工：本件用哈希帧（名字→值）执行，
// Vm 用显式活动记录（编号槽）执行，两者 outputs 对账。
#ifndef TIP_TACINTERP_HPP
#define TIP_TACINTERP_HPP

#include <map>
#include <string>
#include <vector>

#include "tacgen.hpp"

namespace tip {

struct TacRun {
    std::vector<int> outputs;
    int steps = 0;
};

class TacInterp {
public:
    void define(const std::string &name, const std::vector<std::string> &params,
                std::vector<Quad> code);
    TacRun run(const std::vector<int> &inputs);

private:
    std::map<std::string, std::pair<std::vector<std::string>, std::vector<Quad>>> code_;
};

}  // namespace tip

#endif  // TIP_TACINTERP_HPP
