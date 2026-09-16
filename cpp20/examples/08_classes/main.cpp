#include <cmath>
#include <compare>
#include <print>
#include <string>

// 08 类与 RAII：封装、构造析构、三路比较、运算符

class Vec2 {
public:
    Vec2(double x, double y) : x_{x}, y_{y} {}

    // ═══ 8.2 const 成员函数：只读接口 ═══
    double x() const { return x_; }
    double y() const { return y_; }
    double length() const { return std::sqrt(x_ * x_ + y_ * y_); }

    // ═══ 8.4 运算符重载：让类像内建类型 ═══
    Vec2 operator+(const Vec2& rhs) const { return {x_ + rhs.x_, y_ + rhs.y_}; }
    Vec2 operator*(double k) const { return {x_ * k, y_ * k}; }
    bool operator==(const Vec2&) const = default;  // C++20：默认相等

    // ═══ 8.5 三路比较 <=> (C++20)：一次定义全部关系 ═══
    std::partial_ordering operator<=>(const Vec2& o) const {
        if (auto c = x_ <=> o.x_; c != 0) {
            return c;
        }
        return y_ <=> o.y_;
    }

    // ═══ 8.7 deducing this (C++23)：显式对象形参 ═══
    Vec2& negate(this Vec2& self) {
        self.x_ = -self.x_;
        self.y_ = -self.y_;
        return self;
    }

private:
    double x_;
    double y_;
};

// ═══ 8.3 RAII：资源获取即初始化——析构就是"自动还" ═══
class Session {
public:
    explicit Session(std::string name) : name_{std::move(name)} {
        std::println("[{}] 进入会话", name_);
    }
    ~Session() {  // 作用域结束自动调用——异常也拦不住它
        std::println("[{}] 离开会话", name_);
    }
    Session(const Session&) = delete;  // 拷贝/移动见第 15 章
    Session& operator=(const Session&) = delete;

private:
    std::string name_;
};

// ═══ 8.6 inline 静态成员：类内直接初始化 ═══
class Counter {
public:
    static int next() { return ++count_; }

private:
    inline static int count_ = 0;  // C++17 起：不再需要类外定义
};

int main() {
    // ═══ 8.1 构造、成员访问 ═══
    Vec2 a{3.0, 4.0};
    Vec2 b{1.0, 1.0};
    Vec2 c = a + b;  // (4, 5)
    std::println("c = ({}, {})，|c| = {:.3f}", c.x(), c.y(), c.length());
    std::println("c * 2 = ({}, {})", (c * 2).x(), (c * 2).y());

    // 比较：== 与 <=> 都能用
    std::println("a == b? {}", a == b);
    std::println("a > b? {}", (a <=> b) > 0);

    // RAII：块结束自动清理（逆序析构）
    {
        Session s1{"外层"};
        {
            Session s2{"内层"};
            std::println("  工作中……");
        }  // s2 先析构
    }  // s1 后析构

    // 静态成员计数
    std::println("Counter: {} {} {}", Counter::next(), Counter::next(), Counter::next());

    // deducing this：显式对象形参
    Vec2 d = c;
    d.negate();
    std::println("d = ({}, {})", d.x(), d.y());
    std::println("自检通过");
}
