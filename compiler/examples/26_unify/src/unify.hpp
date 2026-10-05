// Robinson 合一：求解第 25 章收集的类型等式。
// Substitution 把类型变量编号映射到类型；apply 沿映射反复走到非变量。
// 合一失败抛 TypeError，由 main 转成"类型错误"诊断（退出码 3）。
#pragma once

#include <map>
#include <stdexcept>
#include <string>

#include "type.hpp"

namespace tip {

class TypeError : public std::runtime_error {
public:
    explicit TypeError(const std::string &msg) : std::runtime_error(msg) {}
};

using Subst = std::map<int, Tp>;

// 反复代换直到 t 不是映射中的变量；变量间的别名也会被走穿。
Tp apply(const Subst &s, Tp t);

// 深度归一：顶层与结构内部的变量全部展开，重建为只含未约束变量的类型。
// --check 打印最终类型时使用，避免出现 ptr(t5) 这样的嵌套别名。
Tp normalize(const Subst &s, Tp t);

// 把等式 a = b 的信息并入 s；失败抛 TypeError。
void unify(Tp a, Tp b, Subst &s);

}  // namespace tip
