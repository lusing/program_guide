// file: src/svn.hpp
// 第 41 章配套：超局部值编号（SVN）与支配者值编号（DVNT）（鲸书 §8.5.1 + §10.5.2）。
#ifndef TIP_SVN_HPP
#define TIP_SVN_HPP

#include <set>
#include <string>
#include <vector>

#include "ssa.hpp"

namespace tip {

// 三档值编号的成绩单
struct VnReport {
    int redundant = 0;        // 消掉的冗余赋值（复用已有值）
    int phiDeleted = 0;       // 删掉的 φ（无义或重复）
    int sweeps = 1;           // DVNT 扫描轮数（LVN/SVN 恒 1）
    std::vector<std::string> notes;   // 逐条流水（谁复用了谁）
};

struct VnResult {
    VnReport rep;
    SsaProgram prog;          // 删除 + 名字改写后的程序（解释器对账用）
};

// 第一档：块内值编号（LVN）——每块空表起步
VnResult runLVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds);

// 第二档：超局部值编号（SVN）——沿单前驱链携带作用域化散列表，多前驱块空表重来
VnResult runSVN(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                const std::vector<std::set<int>> &preds);

// 第三档：支配者值编号（DVNT）——沿支配树先序，φ 三判（无义/重复/新值），
// 后继 φ 实参随边改写；扫到不动点（上限 4 轮）
VnResult runDVNT(const SsaProgram &ssa, const std::vector<std::vector<int>> &adj,
                 const std::vector<std::set<int>> &preds, const DomInfo &di);

}  // namespace tip

#endif  // TIP_SVN_HPP
