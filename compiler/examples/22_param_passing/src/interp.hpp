// file: src/interp.hpp
// 第 22 章正题：四机制解释器 + 完全静态环境模式（L 书 §7.2/§7.5 的机器化身）。
#ifndef TIP_PINTERP_HPP
#define TIP_PINTERP_HPP

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "lang.hpp"

namespace plang {

// 求值中的非局部退出（return）——第 15 章 ReturnSignal 的同款手法。
struct ReturnSignal {
    double value;
};

// 递归禁令（完全静态模式的诊断）。
struct RecursionRejected {
    std::string fun;
    int depth;
};

struct RunResult {
    bool ok = false;
    std::string error;                    // 语义错误（含行号尽量给）
    std::vector<std::string> printed;     // print 的输出流
    // 机器证人的侧通道：
    long thunkEvals = 0;                  // name 实参的重求值次数
    std::vector<std::string> tempCells;   // ref/valres 表达式实参的临时格记录
};

class Interp {
public:
    // fullyStatic = true：完全静态运行时环境（§7.2）——每函数一帧、跨调用保留、
    // 递归被调用环检测拒绝。false：标准栈环境（每调用一帧）。
    explicit Interp(const Program &p, bool fullyStatic);

    RunResult run(const std::string &entryFun);

private:
    struct Thunk;
    // 槽 = 名字的全部运行期形态。四种机制各占一角：
    //   val/valres 的值都住 v；ref 的别名指 ref；valres 的写回落点指 out（执行期
    //   不读它——值结果的"值"语义靠这个字段与 ref 分开）；name 的延迟体住 thunk。
    struct Slot {
        double v = 0;
        double *ref = nullptr;            // 仅 Ref：执行期别名
        double *out = nullptr;            // 仅 ValRes：出口写回落点
        std::shared_ptr<Thunk> thunk;     // 仅 Name
        std::vector<double> arr;          // 数组
        bool isArray = false;
    };
    struct Thunk {
        const Expr *expr = nullptr;       // 实参表达式（调用方环境里解释）
        std::map<std::string, Slot> *env = nullptr;   // 捕获的调用方帧
    };
    using Frame = std::map<std::string, Slot>;

    const Fun &findFun(const std::string &name) const;
    double eval(const Expr &e, Frame &fr);
    double *evalLValue(const Expr &e, Frame &fr);   // Var/Index 的格子地址
    void exec(const Stmt &s, Frame &fr);
    void execBlock(const std::vector<std::unique_ptr<Stmt>> &body, Frame &fr);
    double call(const Fun &f, const std::vector<std::unique_ptr<Expr>> &args, Frame &caller);

    const Program &prog_;
    bool static_ = false;
    std::map<std::string, Frame> staticFrames_;   // 完全静态模式的函数帧库
    std::vector<std::string> active_;             // 递归检测：调用链上的函数名
    RunResult *res_ = nullptr;
    std::vector<double> temps_;                   // 表达式实参的临时格仓
};

}  // namespace plang

#endif  // TIP_PINTERP_HPP
