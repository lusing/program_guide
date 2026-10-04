#pragma once
// 访问者：把"对一批异构对象做什么操作"从对象类里抽出来——新操作加 Visitor 子类即可。
// 双重分派：shape.accept(v) 先按 Shape 动态分派，再 v.visit(shape) 按 Visitor 动态分派。
#include <string>

namespace dp {

struct Circle;
struct Rect;
struct Tri;

// Visitor：每种形状一个 visit 重载——新增操作 = 新写一个 Visitor 子类。
struct Visitor {
    virtual ~Visitor() = default;
    virtual void visit(const Circle&) const = 0;
    virtual void visit(const Rect&) const = 0;
    virtual void visit(const Tri&) const = 0;
};

// Shape：accept 是第二分派的跳板——"我知道我是谁，替你选对的重载"。
struct Shape {
    virtual ~Shape() = default;
    virtual void accept(Visitor& v) const = 0;
};

struct Circle final : Shape {
    explicit Circle(double r) : r(r) {}
    void accept(Visitor& v) const override { v.visit(*this); }   // this 是 Circle*
    double r;
};

struct Rect final : Shape {
    Rect(double w, double h) : w(w), h(h) {}
    void accept(Visitor& v) const override { v.visit(*this); }
    double w, h;
};

struct Tri final : Shape {
    Tri(double b, double h) : b(b), h(h) {}
    void accept(Visitor& v) const override { v.visit(*this); }
    double b, h;
};

// ConcreteVisitor 一：求面积和——累计在访问者成员里，形状类毫不知情。
struct AreaVisitor final : Visitor {
    void visit(const Circle& c) const override { total += 3.14159265358979 * c.r * c.r; }
    void visit(const Rect& r) const override { total += r.w * r.h; }
    void visit(const Tri& t) const override { total += t.b * t.h / 2.0; }
    mutable double total = 0.0;      // const visit 累计：逻辑 const 物理可变
};

// ConcreteVisitor 二：JSON 导出——同一批形状，第二种操作零改动。
struct JsonVisitor final : Visitor {
    void visit(const Circle& c) const override {
        out += R"({"t":"circle","r":)" + std::to_string(c.r) + "}";
    }
    void visit(const Rect& r) const override {
        out += R"({"t":"rect","w":)" + std::to_string(r.w) + R"(,"h":)" + std::to_string(r.h) + "}";
    }
    void visit(const Tri& t) const override {
        out += R"({"t":"tri","b":)" + std::to_string(t.b) + R"(,"h":)" + std::to_string(t.h) + "}";
    }
    mutable std::string out;         // 拼接结果（const visit 内累计，同 AreaVisitor）
};

}  // namespace dp
