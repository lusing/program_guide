// file: src/interp.cpp
// 四机制解释器实现。机制分派全部集中在 call() 的实参绑定段——正文走读的锚点。
#include "interp.hpp"

#include <sstream>
#include <stdexcept>

namespace plang {

namespace {

std::string fmt(double v) {
    std::ostringstream os;
    os << v;
    return os.str();
}

}  // namespace

const char *modeName(PassMode m) {
    switch (m) {
    case PassMode::Val: return "val";
    case PassMode::Ref: return "ref";
    case PassMode::ValRes: return "valres";
    case PassMode::Name: return "name";
    }
    return "?";
}

Interp::Interp(const Program &p, bool fullyStatic) : prog_(p), static_(fullyStatic) {}

const Fun &Interp::findFun(const std::string &name) const {
    for (const auto &f : prog_.funs)
        if (f->name == name) return *f;
    throw std::runtime_error("undefined function: " + name);
}

RunResult Interp::run(const std::string &entryFun) {
    RunResult r;
    res_ = &r;
    try {
        const Fun &main = findFun(entryFun);
        Frame dummy;   // 顶层调用的 caller 帧（空）
        call(main, {}, dummy);
        r.ok = true;
    } catch (const ReturnSignal &) {
        r.ok = true;   // 顶层 return 视为正常结束
    } catch (const RecursionRejected &e) {
        std::ostringstream os;
        os << "recursion rejected (static env): " << e.fun << " depth=" << e.depth;
        r.error = os.str();
    } catch (const std::exception &e) {
        r.error = e.what();
    }
    res_ = nullptr;
    return r;
}

// ---------- 表达式 ----------

double Interp::eval(const Expr &e, Frame &fr) {
    switch (e.kind) {
    case Expr::Kind::Num:
        return e.num;
    case Expr::Kind::Var: {
        auto it = fr.find(e.name);
        if (it == fr.end()) throw std::runtime_error("undefined variable: " + e.name);
        if (it->second.thunk) {   // name 传递：使用处重求值——Jensen 的心脏
            ++res_->thunkEvals;
            return eval(*it->second.thunk->expr, *it->second.thunk->env);
        }
        if (it->second.ref) return *it->second.ref;   // ref/valres 间接读
        return it->second.v;
    }
    case Expr::Kind::Index: {
        double i = eval(*e.lhs, fr);
        auto it = fr.find(e.name);
        if (it == fr.end() || !it->second.isArray)
            throw std::runtime_error("undefined array: " + e.name);
        long k = static_cast<long>(i);
        if (k < 0 || k >= static_cast<long>(it->second.arr.size()))
            throw std::runtime_error("index out of range: " + e.name +
                                     "[" + std::to_string(k) + "]");
        return it->second.arr[static_cast<size_t>(k)];
    }
    case Expr::Kind::Unary:
        return -eval(*e.lhs, fr);
    case Expr::Kind::Bin: {
        double a = eval(*e.lhs, fr), b = eval(*e.rhs, fr);
        if (e.op == "+") return a + b;
        if (e.op == "-") return a - b;
        if (e.op == "*") return a * b;
        if (e.op == "/") return a / b;
        if (e.op == "<") return a < b ? 1 : 0;
        if (e.op == "<=") return a <= b ? 1 : 0;
        if (e.op == ">") return a > b ? 1 : 0;
        if (e.op == ">=") return a >= b ? 1 : 0;
        if (e.op == "==") return a == b ? 1 : 0;
        if (e.op == "!=") return a != b ? 1 : 0;
        throw std::runtime_error("bad op: " + e.op);
    }
    case Expr::Kind::Call: {
        const Fun &f = findFun(e.name);
        return call(f, e.args, fr);
    }
    }
    throw std::runtime_error("bad expr");
}

double *Interp::evalLValue(const Expr &e, Frame &fr) {
    if (e.kind == Expr::Kind::Var) {
        auto it = fr.find(e.name);
        if (it == fr.end()) throw std::runtime_error("undefined variable: " + e.name);
        if (it->second.thunk)   // name 传递的赋值：穿透 thunk 写到调用方的格子
            return evalLValue(*it->second.thunk->expr, *it->second.thunk->env);
        if (it->second.ref) return it->second.ref;
        return &it->second.v;
    }
    if (e.kind == Expr::Kind::Index) {
        double i = eval(*e.lhs, fr);
        auto it = fr.find(e.name);
        if (it == fr.end() || !it->second.isArray)
            throw std::runtime_error("undefined array: " + e.name);
        long k = static_cast<long>(i);
        if (k < 0 || k >= static_cast<long>(it->second.arr.size()))
            throw std::runtime_error("index out of range: " + e.name +
                                     "[" + std::to_string(k) + "]");
        return &it->second.arr[static_cast<size_t>(k)];
    }
    throw std::runtime_error("not an lvalue");
}

// ---------- 语句 ----------

void Interp::execBlock(const std::vector<std::unique_ptr<Stmt>> &body, Frame &fr) {
    for (const auto &s : body) exec(*s, fr);
}

void Interp::exec(const Stmt &s, Frame &fr) {
    switch (s.kind) {
    case Stmt::Kind::VarDecl: {
        // 静态模式：声明只在首次落格（局部变量跨调用保留——§7.2 的 SAVE 语义）；
        // 栈模式：每次调用的新帧里全新落格。
        if (!static_ || fr.find(s.name) == fr.end()) fr[s.name] = Slot{};
        break;
    }
    case Stmt::Kind::ArrayDecl: {
        if (!static_ || fr.find(s.name) == fr.end()) {
            Slot sl;
            sl.isArray = true;
            sl.arr.assign(static_cast<size_t>(eval(*s.value, fr)), 0.0);
            fr[s.name] = std::move(sl);
        }
        break;
    }
    case Stmt::Kind::Assign: {
        double *cell;
        if (s.index) {
            // 数组元素目标：s.name 是数组名、s.index 存的是下标表达式（非 Index 节点）
            auto it = fr.find(s.name);
            if (it == fr.end() || !it->second.isArray)
                throw std::runtime_error("undefined array: " + s.name);
            double i = eval(*s.index, fr);
            long k = static_cast<long>(i);
            if (k < 0 || k >= static_cast<long>(it->second.arr.size()))
                throw std::runtime_error("index out of range: " + s.name +
                                         "[" + std::to_string(k) + "]");
            cell = &it->second.arr[static_cast<size_t>(k)];
        } else {
            cell = evalLValue(Expr{Expr::Kind::Var, 0, s.name, {}, {}, {}, {}}, fr);
        }
        // 先求值右部再写左部（a[i] = i + 1 两边都有 i 时次序可讲）
        double v = eval(*s.value, fr);
        *cell = v;
        break;
    }
    case Stmt::Kind::Print:
        res_->printed.push_back(fmt(eval(*s.value, fr)));
        break;
    case Stmt::Kind::If:
        if (eval(*s.cond, fr) != 0) execBlock(s.then, fr);
        else execBlock(s.other, fr);
        break;
    case Stmt::Kind::While:
        while (eval(*s.cond, fr) != 0) execBlock(s.body, fr);
        break;
    case Stmt::Kind::For: {
        double lo = eval(*s.from, fr), hi = eval(*s.to, fr);
        // i 是当前帧的格子；name 传递时它可能别名到调用方（Jensen 的通道）
        Expr var{Expr::Kind::Var, 0, s.name, {}, {}, {}, {}};
        for (double k = lo; k <= hi; k += 1) {
            *evalLValue(var, fr) = k;
            execBlock(s.body, fr);
        }
        break;
    }
    case Stmt::Kind::Return:
        throw ReturnSignal{eval(*s.value, fr)};
    case Stmt::Kind::CallStmt: {
        const Fun &f = findFun(s.name);
        call(f, s.args, fr);
        break;
    }
    }
}

// ---------- 调用：四机制的分派中心 ----------

double Interp::call(const Fun &f, const std::vector<std::unique_ptr<Expr>> &args, Frame &caller) {
    if (args.size() != f.params.size())
        throw std::runtime_error("arity mismatch: " + f.name + " 期望 " +
                                 std::to_string(f.params.size()) + " 实给 " +
                                 std::to_string(args.size()));
    // 完全静态模式：递归 = 第二份帧无处安放——调用环检测直接拒绝
    if (static_) {
        for (const auto &a : active_)
            if (a == f.name) throw RecursionRejected{f.name, static_cast<int>(active_.size())};
        active_.push_back(f.name);
    }

    // 帧的两种住法（§7.2 vs §7.3 的全部区别就在这四行）：
    //   静态模式：每函数一帧、住在 staticFrames_ 里、跨调用保留；
    //   栈模式：  每次调用一帧、随返回消亡（shared_ptr 撑到 return，thunk 捕获安全）。
    auto keepAlive = std::make_shared<Frame>();
    Frame &frame = static_ ? staticFrames_[f.name] : *keepAlive;

    // —— 形参绑定（正文走读锚点）：四机制的全部差别在这一个 switch ——
    for (size_t k = 0; k < args.size(); ++k) {
        const Param &pm = f.params[k];
        const Expr &a = *args[k];
        Slot &slot = frame[pm.name];
        slot.isArray = false;
        switch (pm.mode) {
        case PassMode::Val:
            slot.ref = nullptr;
            slot.out = nullptr;
            slot.thunk = nullptr;
            slot.v = eval(a, caller);
            break;
        case PassMode::Ref:
            // 实参必须是左值；表达式实参造临时格（FORTRAN 77 的官方姿势，§7.5.2）
            slot.thunk = nullptr;
            slot.out = nullptr;
            if (a.kind == Expr::Kind::Var || a.kind == Expr::Kind::Index) {
                slot.ref = evalLValue(a, caller);
            } else {
                temps_.push_back(eval(a, caller));
                slot.ref = &temps_.back();
                std::ostringstream os;
                os << f.name << " 第" << (k + 1) << "参 表达式实参 -> 临时格 #" << (temps_.size() - 1)
                   << " (值 " << temps_.back() << ")";
                res_->tempCells.push_back(os.str());
            }
            break;
        case PassMode::ValRes: {
            // 入口取地址、拷入 v；执行期读写全走 v（值语义）；出口按声明序把 v
            // 写回 out（实现口径注明：L 书 §7.5.3 指出写回顺序与地址重算时机未指定）
            slot.thunk = nullptr;
            slot.ref = nullptr;
            double *src = evalLValue(a, caller);
            slot.out = src;
            slot.v = *src;
            break;
        }
        case PassMode::Name: {
            // 延迟求值：实参表达式 + 调用方帧原样封存，使用处才解释（§7.5.4 thunk）
            auto th = std::make_shared<Thunk>();
            th->expr = &a;
            th->env = &caller;
            slot.ref = nullptr;
            slot.out = nullptr;
            slot.thunk = std::move(th);
            break;
        }
        }
    }

    double ret = 0;
    try {
        execBlock(f.body, frame);
    } catch (ReturnSignal &sig) {
        ret = sig.value;
    }
    // 值结果的出口写回（声明序）
    for (size_t k = 0; k < args.size(); ++k) {
        const Param &pm = f.params[k];
        if (pm.mode != PassMode::ValRes) continue;
        Slot &slot = frame[pm.name];
        *slot.out = slot.v;
    }

    if (static_) active_.pop_back();
    return ret;
}

}  // namespace plang
