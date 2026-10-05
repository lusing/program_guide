// 类型的表示：具体类型构造子 + 可合一的类型变量。
// 从本章起，分析不再直接"算出"答案，而是先搭类型结构、生成约束、
// 再由第 23 章的合一求解。类型对象以 shared_ptr 共享：同一个类型变量
// 会被约束的两侧、嵌套结构多处引用，不能用 unique_ptr。
#pragma once

#include <memory>
#include <string>
#include <vector>

namespace tip {

struct Type;
using Tp = std::shared_ptr<Type>;

struct Type {
    virtual std::string show() const = 0;
    virtual ~Type() = default;
};

struct TyInt : Type {
    std::string show() const override { return "int"; }
};

struct TyPtr : Type {
    Tp to;
    explicit TyPtr(Tp t) : to(std::move(t)) {}
    std::string show() const override { return "ptr(" + to->show() + ")"; }
};

struct TyFun : Type {
    std::vector<Tp> params;
    Tp ret;
    TyFun(std::vector<Tp> ps, Tp r) : params(std::move(ps)), ret(std::move(r)) {}
    std::string show() const override {
        std::string s = "(";
        for (size_t i = 0; i < params.size(); ++i) {
            if (i) s += ", ";
            s += params[i]->show();
        }
        s += ") -> " + ret->show();
        return s;
    }
};

struct TyRec : Type {
    std::vector<std::pair<std::string, Tp>> fields;
    explicit TyRec(std::vector<std::pair<std::string, Tp>> fs)
        : fields(std::move(fs)) {}
    std::string show() const override {
        std::string s = "{";
        for (size_t i = 0; i < fields.size(); ++i) {
            if (i) s += ", ";
            s += fields[i].first + ": " + fields[i].second->show();
        }
        return s + "}";
    }
};

struct TyNull : Type {
    std::string show() const override { return "null"; }
};

struct TyVar : Type {
    int id;
    explicit TyVar(int i) : id(i) {}
    std::string show() const override { return "t" + std::to_string(id); }
    // 新鲜变量编号：进程内单调递增，从 1 开始。
    static int fresh() {
        static int counter = 0;
        return ++counter;
    }
};

// 便利构造。
inline Tp tint() { return std::make_shared<TyInt>(); }
inline Tp tvar() { return std::make_shared<TyVar>(TyVar::fresh()); }

}  // namespace tip
