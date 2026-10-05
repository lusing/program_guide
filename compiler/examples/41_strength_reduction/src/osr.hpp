// file: src/osr.hpp
// 第 41 章配套：操作符强度削减（OSR）与线性函数测试替换（LFTR）（鲸书 §10.7.2）。
#ifndef TIP_OSR_HPP
#define TIP_OSR_HPP

#include <set>
#include <string>
#include <vector>

#include "ssa.hpp"

namespace tip {

struct OsrReport {
    std::vector<std::string> ivs;       // 识别出的归纳变量 SCC（φ 名作代表）
    std::vector<std::string> reduced;   // 削减记录（旧名 ×c → 新名）
    std::vector<std::string> lftr;      // 测试替换记录
    int mulLoopBefore = 0;              // 第一个循环体内的乘法数（削减前）
    int mulLoopAfter = 0;               // 削减 + LFTR + DCE 后
    int mulUntouched = 0;               // 非候选乘法（j 非字面量）——必须原样保留
    int deadRemoved = 0;                // DCE 清走的死指令
};

struct OsrResult {
    OsrReport rep;
    SsaProgram prog;
};

// SSA 图上的 OSR：
//   1) Tarjan SCC 找归纳变量（合法更新：φ / copy / ±字面量）；
//   2) 候选 x = iv × c（c 字面量）克隆出新的加法归纳变量；
//   3) LFTR：iv 只剩测试用途时把测试换成新变量的同界测试；
//   4) DCE 扫掉死透的旧链。
OsrResult runOSR(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds);

}  // namespace tip

#endif  // TIP_OSR_HPP
