// file: src/functional.hpp
// 第 53 章配套：迷你 λ 演算、闭包转换、尾递归检测、thunk 惰性求值。
#ifndef TIP_FUNCTIONAL_HPP
#define TIP_FUNCTIONAL_HPP

#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace tip {

// ---------- 迷你 λ 项 ----------
struct TermBase {
    virtual ~TermBase() = default;
};
struct Var : TermBase {
    std::string name;
    explicit Var(std::string n) : name(std::move(n)) {}
};
struct Const : TermBase {
    int value;
    explicit Const(int v) : value(v) {}
};
struct Lam;
struct App : TermBase {
    std::shared_ptr<TermBase> fn, arg;
    App(std::shared_ptr<TermBase> f, std::shared_ptr<TermBase> a)
        : fn(std::move(f)), arg(std::move(a)) {}
};
struct Lam : TermBase {
    static int counter;
    int id;
    std::vector<std::string> params;   // 教学口径：单参数
    std::shared_ptr<TermBase> body;
    std::map<std::string, int> env;    // 闭包环境（求值时由调用方填）
    Lam(std::string p, std::shared_ptr<TermBase> b)
        : id(++counter), params{std::move(p)}, body(std::move(b)) {}
};

struct Term {
    std::shared_ptr<TermBase> term;
    Term(std::shared_ptr<TermBase> t) : term(std::move(t)) {}
};

// 工厂（可读性）：var("x") / konst(3) / lam("x", body) / app(f, a)
inline Term var(const std::string &n) { return Term(std::make_shared<Var>(n)); }
inline Term konst(int v) { return Term(std::make_shared<Const>(v)); }
inline Term lam(const std::string &p, Term b) {
    return Term(std::make_shared<Lam>(p, b.term));
}
inline Term app(Term f, Term a) {
    return Term(std::make_shared<App>(f.term, a.term));
}

using Env = std::map<std::string, int>;

struct EvalResult {
    int value = 0;
    int steps = 0;
};

// 传值调用求值器（与 lazyEval 对账的基准）。
EvalResult eval(const Term &t, const Env &env);

// ---------- 闭包转换（虎书 15.5）----------
std::set<std::string> freeVars(const Term &t, const std::set<std::string> &bound);

struct ClosureReport {
    int lambdaId;
    std::vector<std::string> params;
    std::vector<std::string> captured;   // 自由变量 = 环境装箱清单
};

std::vector<ClosureReport> closureConvert(const Term &t);

// ---------- 尾调用检测（虎书 15.6）----------
bool isTailCall(const Term &body);

// ---------- thunk 惰性求值（虎书 15.7）----------
struct ThunkResult {
    int value = 0;
    int thunksCreated = 0;
    int thunksForced = 0;
    int memoHits = 0;
};

ThunkResult lazyEval(const Term &t, const Env &env);

}  // namespace tip

#endif  // TIP_FUNCTIONAL_HPP
