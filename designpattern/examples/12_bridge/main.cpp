// 12 桥接。
#include <cassert>
#include <print>

#include "bridge.hpp"

int main() {
    using namespace dp;

    // ---- 两维正交：同一个抽象（圆）× 两种实现（渲染器） ----
    VectorRenderer vec;
    RasterRenderer ras;

    BridgeCircle cv(vec, 2.0);
    BridgeCircle cr(ras, 2.0);

    assert(cv.draw() == "vector circle r=2");
    assert(cr.draw() == "raster circle r=2");
    std::println("桥接: {} / {}", cv.draw(), cr.draw());

    // ---- 实现维度独立扩展：抽一层不动 ----
    // （假设加了 SvgRenderer，BridgeCircle 无需任何改动即可配合——2×2→2×3）
    std::println("抽象扩展: {}", cv.draw_outlined());

    // ---- 现代对照：pImpl 行为一致 ----
    Widget w;
    assert(w.describe() == "impl-ready");
    std::println("pImpl: {}（实现藏在指针后）", w.describe());

    // pImpl 可移动（unique_ptr 天然支持），桥接指针同样可换绑
    Widget w2 = std::move(w);
    assert(w2.describe() == "impl-ready");
    std::println("pImpl: 移动后仍 {}", w2.describe());

    std::println("自检通过");
}
