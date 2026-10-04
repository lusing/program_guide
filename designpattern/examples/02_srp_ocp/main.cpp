// 02 单一职责 + 开闭原则。
#include <cassert>
#include <memory>
#include <print>
#include <utility>
#include <vector>

#include "ocp.hpp"
#include "srp.hpp"

int main() {
    using namespace dp;

    // ---- SRP：三个职责拆成两个自由函数 ----
    Employee e{"alice", 3000.0, 80, 25.0};
    double pay = calculate_pay(e);                       // 财务域
    std::string line = format_report(e, pay);            // 报表域
    assert(pay == 3000.0 + 80 * 25.0);
    assert(line == "alice 应发 5000");
    std::println("SRP: {}", line);

    // ---- OCP 经典线：total_area 对新形状封闭 ----
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(1.0));     // pi
    shapes.push_back(std::make_unique<Rect>(2.0, 3.0));  // 6
    double sum = total_area(shapes);
    assert(sum > 9.1415926 && sum < 9.1415927);          // pi+6
    std::println("OCP 经典: total_area = {:.6f}", sum);

    // 新形状 Tri 直接加入，total_area 一行不改 —— 编译通过即 OCP 达成。
    class Tri final : public Shape {
    public:
        double area() const override { return 1.0; }
    };
    shapes.push_back(std::make_unique<Tri>());
    assert(total_area(shapes) > 10.1415926 && total_area(shapes) < 10.1415927);

    // ---- OCP 现代线：concepts 版，不要求继承 ----
    struct Hex {
        double side;
        double area() const { return 2.598 * side * side; }
    };
    std::vector<Rect> rects{Rect{2.0, 3.0}};
    std::vector<Hex> hexes{Hex{1.0}};                    // 与 Shape 零继承关系
    assert(total_area2(rects) == 6.0);
    assert(total_area2(hexes) == 2.598);
    std::println("OCP 现代: total_area2(rects)={}, total_area2(hexes)={}",
                 total_area2(rects), total_area2(hexes));

    std::println("自检通过");
}
