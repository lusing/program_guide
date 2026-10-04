#pragma once
// 解释器：为一种"小语言"定义文法，每个文法规则一个类，
// 表达式树 + eval 遍历 = 解释执行。本例：布尔表达式（and/or/not + 变量）。
#include <format>
#include <memory>
#include <span>
#include <string>

namespace dp {

// AbstractExpression：所有语法节点的统一求值接口。
struct BoolExpr {
    virtual ~BoolExpr() = default;
    [[nodiscard]] virtual bool eval(std::span<const bool> vars) const = 0;
    [[nodiscard]] virtual std::string name() const = 0;
};

// TerminalExpression：变量——查环境（vars 数组按位对应 v0, v1, ...）。
struct Var final : BoolExpr {
    explicit Var(size_t idx) : idx_(idx) {}
    [[nodiscard]] bool eval(std::span<const bool> vars) const override {
        return vars[idx_];
    }
    [[nodiscard]] std::string name() const override {
        return std::format("v{}", idx_);
    }

private:
    size_t idx_;
};

// NonterminalExpression：三种组合子，各对应一条文法规则。
struct And final : BoolExpr {
    And(std::unique_ptr<BoolExpr> l, std::unique_ptr<BoolExpr> r)
        : l_(std::move(l)), r_(std::move(r)) {}
    [[nodiscard]] bool eval(std::span<const bool> vars) const override {
        return l_->eval(vars) && r_->eval(vars);
    }
    [[nodiscard]] std::string name() const override {
        return "(" + l_->name() + " and " + r_->name() + ")";
    }

private:
    std::unique_ptr<BoolExpr> l_, r_;
};

struct Or final : BoolExpr {
    Or(std::unique_ptr<BoolExpr> l, std::unique_ptr<BoolExpr> r)
        : l_(std::move(l)), r_(std::move(r)) {}
    [[nodiscard]] bool eval(std::span<const bool> vars) const override {
        return l_->eval(vars) || r_->eval(vars);
    }
    [[nodiscard]] std::string name() const override {
        return "(" + l_->name() + " or " + r_->name() + ")";
    }

private:
    std::unique_ptr<BoolExpr> l_, r_;
};

struct Not final : BoolExpr {
    explicit Not(std::unique_ptr<BoolExpr> e) : e_(std::move(e)) {}
    [[nodiscard]] bool eval(std::span<const bool> vars) const override {
        return !e_->eval(vars);
    }
    [[nodiscard]] std::string name() const override { return "not " + e_->name(); }

private:
    std::unique_ptr<BoolExpr> e_;
};

}  // namespace dp
