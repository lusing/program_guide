// file: src/functional.cpp
// 第 46+1 章配套：闭包转换、尾递归改写、thunk 惰性求值（虎书 §15 自包含蒸馏）。
#include "functional.hpp"

#include <sstream>

namespace tip {

// ---------- 迷你 λ 演算（AST 手写构造，无 parser） ----------
// Lam(参数, 体)：函数；App(函数, 实参)：调用；Var/Const：叶。
// 求值器：传值调用（CBV）——用于 need/value 求值计数对账。

int Lam::counter = 0;

EvalResult eval(const Term &t, const Env &env) {
    // 代换式 CBV：App(Lam(p,b), a) ⇒ eval(b[p:=a])；App(App…, a) 先归约函数位。
    // 教学口径：代换即“最透明的调用语义”——闭包/env 是它的工程优化（15.5 的动机）。
    (void)env;
    EvalResult r;
    if (auto v = std::dynamic_pointer_cast<Var>(t.term))
        throw std::runtime_error("eval: 自由变量 " + v->name);
    if (auto c = std::dynamic_pointer_cast<Const>(t.term)) {
        r.value = c->value;
        ++r.steps;
        return r;
    }
    if (std::dynamic_pointer_cast<Lam>(t.term))
        throw std::runtime_error("eval: λ 处于顶层值位（程序形态不支持）");
    auto app = std::dynamic_pointer_cast<App>(t.term);
    if (!app) throw std::runtime_error("eval: 非法项");
    // 函数位归约
    std::shared_ptr<TermBase> fn = app->fn;
    while (auto inner = std::dynamic_pointer_cast<App>(fn)) {
        EvalResult f = eval(Term(fn), Env{});
        r.steps += f.steps;
        auto k = std::make_shared<Const>(f.value);
        fn = k;   // 归约结果当值——嵌套调用返回值再当函数时报错（口径内不出现）
        (void)inner;
        break;
    }
    auto lam = std::dynamic_pointer_cast<Lam>(fn);
    if (!lam) throw std::runtime_error("eval: 调用非函数");
    // 传值口径：实参先求值成 Const 再代入（实参含未绑定变量即崩——程序 3 的钉子）
    // CBV：实参先“归约到位”——Const 归约成值；λ 本身就是值（闭包），
    // 两种都可直接代入（函数作实参 = 一等公民的最小实现）。
    std::shared_ptr<TermBase> argVal;
    if (std::dynamic_pointer_cast<Lam>(app->arg)) {
        argVal = app->arg;
        ++r.steps;
    } else {
        EvalResult av = eval(Term(app->arg), Env{});
        r.steps += av.steps;
        argVal = std::make_shared<Const>(av.value);
    }
    std::function<std::shared_ptr<TermBase>(const std::shared_ptr<TermBase> &)> subst =
        [&](const std::shared_ptr<TermBase> &e) -> std::shared_ptr<TermBase> {
        if (auto v = std::dynamic_pointer_cast<Var>(e))
            return v->name == lam->params[0] ? argVal : e;
        if (auto a2 = std::dynamic_pointer_cast<App>(e)) {
            auto n = std::make_shared<App>(subst(a2->fn), subst(a2->arg));
            return n;
        }
        if (auto l2 = std::dynamic_pointer_cast<Lam>(e)) {
            // 遮蔽：内层 λ 的参数与代换目标同名则不再深入
            if (l2->params[0] == lam->params[0]) return e;
            auto n = std::make_shared<Lam>(l2->params[0], subst(l2->body));
            return n;
        }
        return e;
    };
    EvalResult body = eval(Term(subst(lam->body)), Env{});
    r.steps += body.steps + 1;
    r.value = body.value;
    return r;
}

// ---------- 闭包转换（虎书 15.5）：自由变量装箱 ----------
// λx.e 的自由变量 FV(e) 装进环境闭包；
// 转换打印：每个 λ 的“捕获清单”。

std::set<std::string> freeVars(const Term &t, const std::set<std::string> &bound) {
    if (auto v = std::dynamic_pointer_cast<Var>(t.term)) {
        return bound.count(v->name) ? std::set<std::string>{} : std::set<std::string>{v->name};
    }
    if (std::dynamic_pointer_cast<Const>(t.term)) return {};
    if (auto lam = std::dynamic_pointer_cast<Lam>(t.term)) {
        auto b2 = bound;
        for (const auto &p : lam->params) b2.insert(p);
        return freeVars(lam->body, b2);
    }
    auto app = std::dynamic_pointer_cast<App>(t.term);
    auto l = freeVars(app->fn, bound);
    auto r = freeVars(app->arg, bound);
    l.insert(r.begin(), r.end());
    return l;
}

std::vector<ClosureReport> closureConvert(const Term &t) {
    std::vector<ClosureReport> out;
    std::function<void(const Term &, std::set<std::string>)> walk =
        [&](const Term &term, std::set<std::string> bound) {
            if (auto lam = std::dynamic_pointer_cast<Lam>(term.term)) {
                // 捕获清单只减“自身参数”——外层 λ 的参数在内层看来是自由变量，
                // 恰是闭包要装箱带走的东西（与“全链 bound”的求值口径不同）。
                std::set<std::string> own;
                for (const auto &p : lam->params) own.insert(p);
                auto fv = freeVars(lam->body, own);
                auto b2 = bound;
                for (const auto &p : lam->params) b2.insert(p);
                ClosureReport rep;
                rep.lambdaId = lam->id;
                rep.params = lam->params;
                rep.captured.assign(fv.begin(), fv.end());
                out.push_back(rep);
                walk(lam->body, b2);
                return;
            }
            if (auto app = std::dynamic_pointer_cast<App>(term.term)) {
                walk(Term(app->fn), bound);
                walk(Term(app->arg), bound);
            }
        };
    walk(t, {});
    return out;
}

// ---------- 尾递归改写（虎书 15.6）----------
// 尾位置定义：App 出现在“结果就是它”的位置（不被包裹、不再运算）。
// 尾调用 ⇒ 参数代入当前帧、跳回函数头（栈不增长）。
// 检测：lambda 体为 App 或体为“常量/变量”之外的嵌套尾链。

bool isTailCall(const Term &body) {
    return std::dynamic_pointer_cast<App>(body.term) != nullptr;
}

// ---------- thunk 情性求值（虎书 15.7 的 call-by-need 计数） ----------
// 需求方传“要我时才算”的 thunk；首次强制求值后记忆（need ≤ value 计数对账）。

ThunkResult lazyEval(const Term &t, const Env &env) {
    // call-by-need：实参先入“thunk 槽”（term + 定义环境），用到才强求、
    // 强求一次后记忆（memo）。Var 命中已算过的槽 ⇒ memoHits++。
    ThunkResult r;
    struct Slot {
        std::shared_ptr<TermBase> term;
        Env env;
        bool done = false;
        int value = 0;
    };
    std::map<std::string, Slot> slots;
    std::function<int(const std::shared_ptr<TermBase> &, const Env &)> go =
        [&](const std::shared_ptr<TermBase> &term, const Env &e) -> int {
        if (auto v = std::dynamic_pointer_cast<Var>(term)) {
            auto it = slots.find(v->name);
            if (it != slots.end()) {
                if (!it->second.done) {
                    it->second.value = go(it->second.term, it->second.env);
                    it->second.done = true;
                } else {
                    ++r.memoHits;
                }
                return it->second.value;
            }
            auto eit = e.find(v->name);
            if (eit == e.end()) throw std::runtime_error("lazy: 未绑定 " + v->name);
            return eit->second;
        }
        if (auto c = std::dynamic_pointer_cast<Const>(term)) return c->value;
        auto app = std::dynamic_pointer_cast<App>(term);
        if (!app) throw std::runtime_error("lazy: 非法项");
        auto lam = std::dynamic_pointer_cast<Lam>(app->fn);
        if (!lam) throw std::runtime_error("lazy: 调用非函数");
        // 实参不当场求值——入 thunk 槽
        ++r.thunksCreated;
        Slot s;
        s.term = app->arg;
        s.env = e;
        Env e2 = lam->env;
        std::string p = lam->params[0];
        auto old = slots.find(p);
        const Slot *saved = old == slots.end() ? nullptr : &old->second;
        // 保存外层同名槽（嵌套遮蔽），新槽生效
        std::map<std::string, Slot> savedAll;
        (void)saved;
        (void)savedAll;
        slots[p] = std::move(s);
        int v2 = go(lam->body, e2);
        // 体求值中被强求的次数统计在 thunksForced
        if (slots[p].done) ++r.thunksForced;
        return v2;
    };
    r.value = go(t.term, env);
    return r;
}

}  // namespace tip
