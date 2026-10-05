// 约束收集：按程序结构生成"类型等式"，求解留给第 23 章。
// 每个表达式 E 持有一个类型变量 τ(E)；每个声明（形参/var）共享一个
// 类型变量；函数名绑定到它的函数类型。约束记录 why 以便 --check 讲解。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "symtab.hpp"
#include "type.hpp"

namespace tip {

struct Con {
    Tp a, b;
    std::string why;
};

struct Collected {
    std::vector<Con> cons;
    std::map<const Expr *, Tp> node;      // τ(E)
    std::map<const Symbol *, Tp> decl;   // 声明（形参/var/函数）的类型
};

// 遍历整个程序生成约束；bindings 提供使用点到声明的绑定（第 12 章）。
Collected collect(const ProgramA &program, const Bindings &bindings);

}  // namespace tip
