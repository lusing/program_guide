// 第 66 章配套：全教程九类（十一行）分析的 Galois 视角总表。
// 每行回答四个问题：抽象域是什么、不动点沿哪个方向迭代、对什么敏感
//（对什么不敏感）、可靠性的陈述是哪一句话。收官章用它把 30 章压回
// 一页：换域 = 换分析，换方向 = 换用途，换敏感维 = 换精度与代价。
#pragma once

#include <string>
#include <vector>

namespace tip {

struct SurveyRow {
    std::string name;     // 分析名
    std::string chapters; // 覆盖章节
    std::string domain;   // 抽象域
    std::string direction;// 迭代方向 / 求解方式
    std::string sensitivity; // 敏感维（流/路径/上下文/不敏感）
    std::string soundness;   // 可靠性的一句话陈述
};

const std::vector<SurveyRow> &surveyRows();

// 固定文本总表：--check 打印，期望文件逐字节对账。
std::string printSurvey();

}  // namespace tip
