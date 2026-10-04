#pragma once
// 单一职责：把"数据""算薪""报表"三种变更原因拆开。
// srp.hpp 里故意先给出一个"坏"版本作正文对照，真正参与断言的是好版本。
#include <format>
#include <string>

namespace dp {

struct Employee {
    std::string name;
    double base{};
    int hours{};
    double rate{};
};

// 财务域关心的只有"多少钱"，与展示无关。
inline double calculate_pay(const Employee& e) {
    return e.base + e.hours * e.rate;
}

// 报表域只做字符串拼装，不知道钱是怎么算出来的。
inline std::string format_report(const Employee& e, double pay) {
    return std::format("{} 应发 {}", e.name, pay);
}

}  // namespace dp
