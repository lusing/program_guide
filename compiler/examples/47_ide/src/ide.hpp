// 第 47 章配套：IDE 框架（Sagiv–Reps–Horwitz）求解过程间常量传播。
// IFDS 只能回答"某事实是否可达"；IDE 让可达性携带值：每条路径边附带
// 一个边函数（edge function）λ:L→L，把起点处的值映射到终点处的值。
// 本章的值格 L 是三层常量格：BOT（尚无信息）/ 常量 c / TOP（非常量）。
// 边函数只有三种构造子：恒等 id、常函数 const v、复合 compose——
// 这是一套能多项式时间制表的"最小函数语言"，正文会讲它的表达力边界
//（x=y+1 无法精确表达，只能退为 TOP）。
#pragma once

#include <map>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

// 全局程序点：(函数名, 函数内 CFG 节点号)。
using PP = std::pair<std::string, int>;

struct IdeResult {
    // 每个点的环境：变量名 → 常量值；nullopt 表示已知"非常量"(TOP)。
    // BOT（尚无信息）的变量不进 map，打印时单独显示。
    std::map<PP, std::map<std::string, std::optional<int>>> env;
    long joins = 0;    // 逐点 join 使值上升的次数
    long updates = 0;  // 边函数在非 BOT 值上被求值并下推的次数
};

// 对整个程序跑 IDE 制表（实例固定为常量传播）。
IdeResult solveIde(const Cfg &cfg, const ProgramA &program);

std::string printIde(const Cfg &cfg, const ProgramA &program,
                     const IdeResult &r);

}  // namespace tip
