// 29 多态三副面孔。
#include <cassert>
#include <memory>
#include <print>
#include <string>
#include <utility>
#include <vector>

#include "concept_poly.hpp"
#include "variant_poly.hpp"
#include "virtual_poly.hpp"

int main() {
    using namespace dp;

    // ---- 虚函数版：异构容器一次 render ----
    std::vector<std::unique_ptr<Drawable>> shapes;
    shapes.push_back(std::make_unique<Sq>());
    shapes.push_back(std::make_unique<Ci>());
    assert(render(shapes) == "sq;ci");
    assert(shapes.size() == 2);
    std::println("虚函数: 异构容器一次 render -> sq;ci");

    // ---- concepts 版：同质 span，混合类型须分两次实例化调用 ----
    const Sq s1{}, s2{};
    const Ci c1{}, c2{};
    const std::vector<Sq> sqs{s1, s2};
    const std::vector<Ci> cis{c1, c2};
    std::string out = render(std::span{sqs});     // 实例化 render<Sq>
    out += render(std::span{cis});                // 实例化 render<Ci>，再拼
    assert(out == "sq;sqci;ci");                  // 分段各自接续：段间分隔符客户自理
    std::println("concepts: render<Sq>/render<Ci> 两份实例化，分段拼接");

    // 混排：类型集合写死在调用点时，参数包在编译期展开——输出合同与虚函数版逐字符一致
    assert(render_pack(Sq{}, Ci{}) == "sq;ci");
    std::println("concepts: render_pack 编译期混排 -> sq;ci");

    // ---- variant 版：同质 AnyShape 容器，visit 一跳分派 ----
    const std::vector<AnyShape> anys{Sq{}, Ci{}};
    assert(render(anys) == "sq;ci");
    assert(anys.size() == 2);
    std::println("variant: 封闭集合混合容器一次 render -> sq;ci");

    std::println("自检通过");
}
