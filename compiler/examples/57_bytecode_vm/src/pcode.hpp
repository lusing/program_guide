// file: src/pcode.hpp
// P-码（L 书 §8.1.3）：70 年代 Pascal 编译器的标准目标码——隐式操作数栈的中间码，
// 本章字节码（clox 风格）的曾祖父。三条教学线：
//   1. 同一表达式的 P-码与本章 chunk 字节码逐条对照（栈效应同构）；
//   2. ~60 行 P-机器解释循环把它跑起来，与 chunk-VM 等价程序对账；
//   3. pcode 是"合成属性"的属性文法产物（字符串拼接式代码生成，L 书表 8-1）。
#ifndef TIP_PCODE_HPP
#define TIP_PCODE_HPP

#include <map>
#include <string>
#include <vector>

namespace pcode {

// 简化 P-码指令集（书 §8.1.3 的抽象版）：op 名 + 可选数值/符号操作数。
struct Ins {
    const char *op = "";     // ldc/lod/lda/adi/sbi/mpi/dvi/sro
    double num = 0;          // ldc 的常量
    const char *sym = "";    // lod/lda 的变量名（教学版用字符串，真实实现用帧偏移）
};

// 语料一的 P-码：2*a + (b-3)（书内原例）
std::vector<Ins> exprCorpus();
// 语料二的 P-码：x := y + 1（书内原例——lda 压地址 + sro 存回）
std::vector<Ins> assignCorpus();

// 一行反汇编（对照表与正文引用的锚文本）。
std::string show(const Ins &i);

// P-机器：隐式值栈的解释循环。栈效应——
//   ldc/lod 压一；adi/sbi/mpi/dvi 弹二压一；lda 压"地址"；sro 弹值弹地址、存变量。
class PMachine {
public:
    void var(const std::string &name, double v) { vars_[name] = v; }
    double get(const std::string &name) { return vars_[name]; }
    double run(const std::vector<Ins> &code);

private:
    std::vector<double> stack_;          // 值栈（lda 压的是 vars_ 的"地址下标"）
    std::map<std::string, double> vars_;
};

}  // namespace pcode

#endif  // TIP_PCODE_HPP
