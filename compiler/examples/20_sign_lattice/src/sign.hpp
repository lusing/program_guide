// 符号格（Sign lattice, spa 第 4 章）：把整数的具体值按"正负号"分五类。
//   ⊥（不可达/无信息） < −、0、+（三者互不可比） < ⊤（三者皆可能）
// 本章只给"域 + 序 + join"和抽象算术；多趟不动点在第 23 章补上。
#pragma once

#include <string>

namespace tip {

// 编码：⊥=-2, −=-1, 0=0, +=1, ⊤=2。
// 用整数编码只是存储便利；序关系不是整数大小，join 必须查 join 表。
constexpr int SBOT = -2;
constexpr int SMINUS = -1;
constexpr int SZERO = 0;
constexpr int SPLUS = 1;
constexpr int STOP = 2;

std::string signShow(int s);

// 符号格的三要素：判定相等、偏序、最小上界。
// 后面所有单调框架的算法只依赖这三个操作（及 top/bot 边界）。
struct SignLattice {
    int top = STOP;
    int bot = SBOT;

    bool eq(int a, int b) const { return a == b; }
    bool leq(int a, int b) const;
    int join(int a, int b) const;
};

// 抽象算术：每个操作都对应整数运算"按符号分类"后的最小上界。
// 例如 +:(+,−)→⊤，因为正整数加负整数可能是 −、0 或 +。
int sAdd(int a, int b);
int sSub(int a, int b);
int sMul(int a, int b);
int sDiv(int a, int b);  // 除数符号含 0 时按 ⊥ 处理（具体程序在此抛错/中止）

// 比较运算在 TIP 中产生 0/1：抽象结果恒为 {0,+}=⊤（⊥ 仍吸收）。
int sCompare(int a, int b);

}  // namespace tip
