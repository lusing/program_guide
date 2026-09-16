#include <memory>
#include <numbers>
#include <print>
#include <string>
#include <vector>

// 16 继承与多态：虚函数、override、抽象类、组合

// ═══ 16.1 抽象基类：纯虚函数定契约 ═══
class Shape {
public:
    explicit Shape(std::string name) : name_{std::move(name)} {}
    virtual ~Shape() = default;  // 虚析构：多态删除的生死线

    const std::string& name() const { return name_; }
    virtual double area() const = 0;  // 纯虚：本类不能实例化
    virtual void describe() const {   // 虚：子类可覆写
        std::println("{}：面积 {:.2f}", name_, area());
    }

private:
    std::string name_;
};

class Circle : public Shape {
public:
    explicit Circle(double r) : Shape{"圆"}, r_{r} {}
    double area() const override {  // override：拼错会编译报错
        return std::numbers::pi * r_ * r_;
    }

private:
    double r_;
};

class Rect : public Shape {
public:
    Rect(double w, double h) : Shape{"矩形"}, w_{w}, h_{h} {}
    double area() const override { return w_ * h_; }
    void describe() const override {  // 覆写并复用基类行为
        std::print("（宽 {:.0f} 高 {:.0f}）", w_, h_);
        Shape::describe();  // 显式调基类版本
    }

private:
    double w_;
    double h_;
};

// ═══ 16.3 切片演示用的具体基类 ═══
class Animal {
public:
    virtual std::string speak() const { return "……"; }
    virtual ~Animal() = default;
};

class Dog : public Animal {
public:
    std::string speak() const override { return "汪！"; }
};

int main() {
    // ═══ 16.1 多态容器：基类 unique_ptr 统一持有 ═══
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(1.0));
    shapes.push_back(std::make_unique<Rect>(3.0, 4.0));
    for (const auto& s : shapes) {
        s->describe();  // 动态分派：各自版本的 area/describe
    }

    // ═══ 16.2 dynamic_cast：带检查的下转 ═══
    Rect* rect = dynamic_cast<Rect*>(shapes[1].get());
    if (rect != nullptr) {
        std::println("确实是个矩形");
    }

    // ═══ 16.3 切片：按值收基类会"削平"子类部分 ═══
    Dog dog;
    Animal& ref = dog;
    Animal sliced = dog;  // 拷贝了 Animal 子对象，Dog 部分被丢掉
    std::println("引用说话：{}", ref.speak());     // 汪！（动态类型是 Dog）
    std::println("切片说话：{}", sliced.speak());  // ……（静态类型 Animal 的版本）

    // ═══ 16.4 组合优于继承：能力用成员"装进来" ═══
    struct Style {
        std::string color = "#333333";
    };
    Style st;
    std::println("样式颜色 {}（组合：成员即能力，不需要继承）", st.color);
    std::println("自检通过");
}
