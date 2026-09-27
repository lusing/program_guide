#include <memory>
#include <numbers>
#include <print>
#include <string>
#include <typeinfo>
#include <vector>

// 22 多态：虚函数、override 与动态分派

// ═══ 22.1 抽象基类：纯虚函数定契约 ═══
class Shape {
public:
    explicit Shape(std::string name) : name_{std::move(name)} {}
    virtual ~Shape() = default;   // 虚析构：多态删除的生死线（22.5 有实证）

    const std::string& name() const { return name_; }
    virtual double area() const = 0;      // 纯虚：本类不能实例化，只定契约
    virtual void describe() const {       // 虚函数调用另一个虚函数——同样动态分派
        std::println("{}：面积 {:.2f}", name_, area());
    }
    // 默认实参是编译期按【静态类型】绑定的——22.3 的陷阱就藏在这
    virtual double cost(double unit = 10) const { return unit * area(); }
    // 非虚函数：经基类指针调用永远执行基类版本（静态绑定）
    std::string kind() const { return "形状"; }

private:
    std::string name_;
};

class Circle : public Shape {
public:
    explicit Circle(double r) : Shape{"圆"}, r_{r} {}
    double area() const override { return std::numbers::pi * r_ * r_; }
    double cost(double unit = 100) const override {  // 换个默认实参——看谁生效
        return unit * area();
    }
    // 有意不加 override 的同名新函数（隐藏，不是覆写）：签名不同即静态绑定
    std::string kind(const char*) const { return "圆(带参重载)"; }

private:
    double r_;
};

class Rect : public Shape {
public:
    Rect(double w, double h) : Shape{"矩形"}, w_{w}, h_{h} {}
    double area() const override final {   // final：不许再被下游类覆写
        return w_ * h_;
    }
    void describe() const override {       // 覆写并复用基类行为
        std::print("（宽 {:.0f} 高 {:.0f}）", w_, h_);
        Shape::describe();                 // 显式调基类版本
    }

private:
    double w_;
    double h_;
};

// ═══ 22.5 虚析构实验用的带痕迹家族 ═══
class Animal {
public:
    virtual ~Animal() { std::println("  ~Animal()"); }
    virtual std::string speak() const { return "……"; }
};

class Dog : public Animal {
public:
    ~Dog() override { std::println("  ~Dog() 先跑——说明走的是动态分派"); }
    std::string speak() const override { return "汪！"; }
};

int main() {
    // ═══ 22.1 多态容器：基类 unique_ptr 统一持有异质对象 ═══
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(1.0));
    shapes.push_back(std::make_unique<Rect>(3.0, 4.0));
    for (const auto& s : shapes) {
        s->describe();             // 动态分派：各自版本的 area/describe
    }
    for (const auto& s : shapes) { // 经基类指针批量算成本——不同 area 各自生效
        std::println("cost = {:.2f}", s->cost());
    }

    // ═══ 22.2 绑定实验：虚函数动态绑定，非虚/隐藏函数静态绑定 ═══
    Shape& as_shape = *shapes[0];                // 静态类型 Shape&，动态类型 Circle
    std::println("经 Shape& 调非虚 kind()：{}", as_shape.kind());   // 永远是基类版本
    Circle unit{2.0};                            // 静态类型就是 Circle
    std::println("派生对象调隐藏重载 kind(\"x\")：{}", unit.kind("x"));
    std::println("同名遮蔽后想调基类版：{}", unit.Shape::kind());   // Base:: 穿透遮蔽

    // ═══ 22.3 默认实参陷阱：实参按静态类型取（10），函数体按动态类型跑 ═══
    std::println("经 Shape& 调 cost()（默认实参用基类的 10）：{:.2f}", as_shape.cost());
    std::println("经 Circle 对象调 cost()（默认实参才是 100）：{:.2f}", unit.cost());

    // ═══ 22.4 RTTI：dynamic_cast 带检查下转 + typeid 认类型 ═══
    if (auto* rect = dynamic_cast<Rect*>(shapes[1].get()); rect != nullptr) {
        std::println("shapes[1] 确实是矩形（dynamic_cast 下转成功）");
    }
    if (auto* not_circle = dynamic_cast<Circle*>(shapes[1].get()); not_circle == nullptr) {
        std::println("shapes[1] 转圆失败返回 nullptr（不是 UB，可判可查）");
    }
    const Shape& first = *shapes[0];   // 先落到具名引用再 typeid（直接写 *ptr 会被 clang 提醒副作用）
    std::println("shapes[0] 的动态类型是 Circle？{}", typeid(first) == typeid(Circle));

    // ═══ 22.5 虚析构：经基类指针删除，派生类析构必须跑到 ═══
    std::println("经 Animal* 删除 Dog（虚析构保证 ~Dog 先执行）：");
    {
        std::unique_ptr<Animal> pet = std::make_unique<Dog>();
    }

    // ═══ 22.6 切片：按值收基类会“削平”子类部分 ═══
    Dog dog;
    Animal& ref = dog;
    Animal sliced = dog;           // 拷贝 Animal 子对象，Dog 部分被丢掉
    std::println("引用说话：{}", ref.speak());     // 汪！（动态类型是 Dog）
    std::println("切片说话：{}", sliced.speak());  // ……（静态类型 Animal 的版本）
    std::println("（sliced 与 dog 到 main 结束才析构——见输出末尾的成对痕迹）");

    // ═══ 22.7 组合优于继承：能力用成员“装进来” ═══
    struct Style {
        std::string color = "#333333";
    };
    Style st;
    std::println("样式颜色 {}（组合：成员即能力，不需要继承）", st.color);
    std::println("自检通过");
}
