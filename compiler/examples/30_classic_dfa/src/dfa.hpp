// 四大经典数据流分析（spa 2 章传统内容，用第 28 章框架统一实现）：
//   活跃变量（后向 may）、到达定值（前向 may）、
//   可用表达式（前向 must）、非常忙表达式（后向 must）。
// 四者共用幂集格，差异只在三个参数：方向（前/后）、合并（∪ may/∩ must）、
// gen/kill 与边界条件。runDfa 按 spec 参数一次性驱动。
#pragma once

#include <functional>
#include <map>
#include <set>
#include <string>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

using FactSet = std::set<std::string>;

struct DfaSpec {
    std::string name;
    bool forward;  // true: 信息沿边正向传播；false: 逆向
    bool may;      // true: 合并取并(may)；false: 交(must)
    // gen/kill 以语句为单位：返回该语句在相应方向上产生/杀死的因子。
    std::function<FactSet(const Stmt *)> gen;
    std::function<FactSet(const Stmt *)> kill;
    // must 分析在入口/出口边界取全集还是空集，由 initFull 指定。
    bool initFull = false;
};

// 结果：程序点 → 该点沿分析方向"流出"状态（transfer 之后）。
// 打印时按点给出集合内容。
std::map<int, FactSet> runDfa(const Cfg &cfg, const DfaSpec &spec);

std::string printDfa(const Cfg &cfg, const std::map<int, FactSet> &result,
                     const DfaSpec &spec);

// gen/kill 语句分类的公共实现（四分析共用）。
std::set<std::string> exprVars(const Expr *e);      // 右值中出现的变量
std::string assignTargetName(const Stmt *s);        // 赋值目标（标量）或 ""
std::set<std::string> exprSubTerms(const Expr *e);  // 表达式的子式文本（t op u 按名）
// 语句所"计算"的表达式（赋值右值/输出/返回/分支条件）；不计算的语句返回空。
const Expr *stmtExpr(const Stmt *s);

}  // namespace tip
