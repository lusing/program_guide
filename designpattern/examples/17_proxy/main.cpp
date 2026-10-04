// 17 代理。
#include <cassert>
#include <print>

#include "proxy.hpp"

int main() {
    using namespace dp;

    // ---- 虚代理：构造零成本，首次 draw 才加载 ----
    assert(RealImage::constructed_count() == 0);

    LazyImageProxy img("photo.png");
    assert(RealImage::constructed_count() == 0);      // 代理构造没碰真身
    assert(img.name() == "photo.png");                // 便宜操作直通，也不加载
    std::println("代理: 代理构造+name() 后 RealImage 构造数=0");

    img.draw();                                       // 首次 draw：加载 + 绘制
    assert(RealImage::constructed_count() == 1);
    assert(RealImage::last_drawn() == "photo.png");
    std::println("代理: 首次 draw 后 RealImage 构造数=1");

    img.draw();                                       // 二次 draw：不再构造
    assert(RealImage::constructed_count() == 1);
    std::println("代理: 二次 draw 构造数仍=1（懒加载只付一次）");

    // ---- 多态消费：代理可当 Image 用（同接口替身） ----
    Image& poly = img;
    poly.draw();
    assert(RealImage::constructed_count() == 1);
    std::println("多态: Image& 消费代理，行为与本体一致");

    // ---- 现代对照：optional 惰性同构（值语义，免堆分配） ----
    int before = RealImage::constructed_count();
    OptImage oimg("lazy.jpg");
    oimg.draw();
    assert(RealImage::constructed_count() == before + 1);
    std::println("现代: optional 惰性版首次 draw 同样触发且仅触发一次加载");

    std::println("自检通过");
}
