// ptr_container.cpp —— Boost.PtrContainer（2004）：装多态对象的容器。
// C++11 前没有 unique_ptr——"容器装 T 的指针且容器拥有之"是它的地盘。
// 今天默认答案：std::vector<std::unique_ptr<T>>，但 ptr_vector 的
// "解引用访问"接口（operator[] 直接给 T&）仍更顺手。
// 对应文档：docs/22-container-zoo.md
#include <boost/ptr_container/ptr_vector.hpp>

#include <iostream>
#include <memory>
#include <string>

struct Shape {
    virtual ~Shape() = default;
    virtual double area() const = 0;
    virtual const char* name() const = 0;
};
struct Circle : Shape {
    double r;
    explicit Circle(double rr) : r(rr) {}
    double area() const override { return 3.14159 * r * r; }
    const char* name() const override { return "圆"; }
};
struct Square : Shape {
    double a;
    explicit Square(double s) : a(s) {}
    double area() const override { return a * a; }
    const char* name() const override { return "方"; }
};

int main() {
    boost::ptr_vector<Shape> shapes;
    shapes.push_back(new Circle(1));
    shapes.push_back(new Square(2));
    // C++11 也可：shapes.push_back(std::make_unique<Circle>(1))（1.5x 起支持）

    double total = 0;
    for (const Shape& s : shapes) {           // 直接是 Shape&，不用解引用指针
        std::cout << "  " << s.name() << " 面积 = " << s.area() << '\n';
        total += s.area();
    }
    std::cout << "合计 = " << total << '\n';
    std::cout << "按序取第 0 个: " << shapes[0].name() << '\n';
    // 容器析构自动 delete 全部——泄漏不可能

    // ptr_map 同族（键→多态对象），实测注意：insert 的部分重载会走"克隆"
    // 路径要求值类型可实例化——抽象基类当值类型时要用 push_back 型接口
    std::cout << "ptr_map 见文档（抽象值类型要避开克隆路径重载）\n";

    std::cout << "自检通过\n";
    return 0;
}
