// 28 访问者。
#include <cassert>
#include <cmath>
#include <memory>
#include <print>
#include <string>
#include <vector>

#include "variant_visitor.hpp"
#include "visitor.hpp"

int main() {
    using namespace dp;

    // ---- 一批异构形状 ----
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(2.0));    // 面积 4π
    shapes.push_back(std::make_unique<Rect>(3.0, 4.0)); // 12
    shapes.push_back(std::make_unique<Tri>(5.0, 6.0));  // 15

    // ---- AreaVisitor：累计和与手算一致 ----
    AreaVisitor av;
    for (const auto& s : shapes) s->accept(av);
    const double expected = 4.0 * 3.14159265358979 + 12.0 + 15.0;
    assert(std::abs(av.total - expected) < 1e-9);
    std::println("访问者: AreaVisitor 累计 = 4π+12+15（与手算一致）");

    // ---- JsonVisitor：同一批形状，第二种操作零改动 ----
    JsonVisitor jv;
    for (const auto& s : shapes) s->accept(jv);
    assert(jv.out.find("\"circle\"") != std::string::npos);
    assert(jv.out.find("\"rect\"") != std::string::npos);
    assert(jv.out.find("\"tri\"") != std::string::npos);
    std::println("访问者: JsonVisitor 串含 circle/rect/tri 三类标记");

    // ---- variant 版：同形状集合，两种操作同结果 ----
    std::vector<ShapeS> vshapes = {CircleS{2.0}, RectS{3.0, 4.0}, TriS{5.0, 6.0}};
    double vtotal = 0.0;
    std::string vjson;
    for (const auto& s : vshapes) {
        vtotal += area_of(s);
        vjson += json_of(s);
    }
    assert(std::abs(vtotal - expected) < 1e-9);          // 与经典版同 total
    assert(vjson.find("\"circle\"") != std::string::npos);
    assert(vjson.find("\"tri\"") != std::string::npos);
    std::println("variant: 同 total、同 JSON 标记（无 accept/visit 跳板）");

    std::println("自检通过");
}
