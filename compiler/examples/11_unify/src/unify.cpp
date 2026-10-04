#include "unify.hpp"

#include <algorithm>

namespace tip {
namespace {

// 沿替换反复走到非变量。文件内统一用这个名字，避免与 std::apply 冲突。
Tp applySubst(const Subst &s, Tp t) {
    while (const auto *v = dynamic_cast<const TyVar *>(t.get())) {
        auto it = s.find(v->id);
        if (it == s.end()) break;
        t = it->second;
    }
    return t;
}

// occurs 检查：结构 t（先展开别名）中是否出现编号 id 的变量。
bool containsVar(const Subst &s, int id, Tp t) {
    t = applySubst(s, t);
    if (const auto *v = dynamic_cast<TyVar *>(t.get())) return v->id == id;
    if (const auto *p = dynamic_cast<TyPtr *>(t.get()))
        return containsVar(s, id, p->to);
    if (const auto *f = dynamic_cast<TyFun *>(t.get())) {
        for (const Tp &a : f->params)
            if (containsVar(s, id, a)) return true;
        return containsVar(s, id, f->ret);
    }
    if (const auto *r = dynamic_cast<TyRec *>(t.get()))
        for (const auto &kv : r->fields)
            if (containsVar(s, id, kv.second)) return true;
    return false;
}

void doUnify(Tp aa, Tp bb, Subst &s) {
    Tp a = applySubst(s, aa), b = applySubst(s, bb);
    auto *va = dynamic_cast<TyVar *>(a.get());
    auto *vb = dynamic_cast<TyVar *>(b.get());

    // 同一变量：恒等，成功。
    if (va && vb && va->id == vb->id) return;

    if (va) {
        if (containsVar(s, va->id, b))
            throw TypeError("occurs check: t" + std::to_string(va->id) +
                            " occurs in " + b->show());
        s[va->id] = b;
        return;
    }
    if (vb) {
        // 交换参数，复用上面的变量绑定分支。
        doUnify(b, a, s);
        return;
    }

    // 两侧都是构造类型：构造子必须相同。
    if (typeid(*a) != typeid(*b))
        throw TypeError("type mismatch: " + a->show() + " vs " + b->show());

    if (const auto *p = dynamic_cast<TyPtr *>(a.get())) {
        doUnify(p->to, dynamic_cast<TyPtr *>(b.get())->to, s);
    } else if (const auto *f = dynamic_cast<TyFun *>(a.get())) {
        auto *g = dynamic_cast<TyFun *>(b.get());
        if (f->params.size() != g->params.size())
            throw TypeError("arity mismatch: " + a->show() + " vs " + b->show());
        for (size_t i = 0; i < f->params.size(); ++i)
            doUnify(f->params[i], g->params[i], s);
        doUnify(f->ret, g->ret, s);
    } else if (const auto *r = dynamic_cast<TyRec *>(a.get())) {
        auto *q = dynamic_cast<TyRec *>(b.get());
        if (r->fields.size() != q->fields.size())
            throw TypeError("record shape: " + a->show() + " vs " + b->show());
        for (const auto &kv : r->fields) {
            auto it = std::find_if(q->fields.begin(), q->fields.end(),
                                   [&](const auto &x) { return x.first == kv.first; });
            if (it == q->fields.end())
                throw TypeError("no field '" + kv.first + "' in " + q->show());
            doUnify(kv.second, it->second, s);
        }
    }
}

// 递归重建：结构内部每个分量先展开别名再重建。
Tp rebuild(const Subst &s, Tp t) {
    t = applySubst(s, t);
    if (dynamic_cast<TyInt *>(t.get()) || dynamic_cast<TyVar *>(t.get()))
        return t;
    if (const auto *p = dynamic_cast<TyPtr *>(t.get()))
        return std::make_shared<TyPtr>(rebuild(s, p->to));
    if (const auto *f = dynamic_cast<TyFun *>(t.get())) {
        std::vector<Tp> ps;
        for (const Tp &a : f->params) ps.push_back(rebuild(s, a));
        return std::make_shared<TyFun>(std::move(ps), rebuild(s, f->ret));
    }
    if (const auto *r = dynamic_cast<TyRec *>(t.get())) {
        std::vector<std::pair<std::string, Tp>> fs;
        for (const auto &kv : r->fields) fs.emplace_back(kv.first, rebuild(s, kv.second));
        return std::make_shared<TyRec>(std::move(fs));
    }
    return t;
}

}  // namespace

Tp apply(const Subst &s, Tp t) { return applySubst(s, t); }

Tp normalize(const Subst &s, Tp t) { return rebuild(s, t); }

void unify(Tp a, Tp b, Subst &s) { doUnify(a, b, s); }

}  // namespace tip
