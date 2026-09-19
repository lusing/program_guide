// gil.cpp —— Boost.GIL（2005）：泛型图像库——类型安全的像素级手术刀。
// 本例纯内存操作（无文件 IO 依赖）：生成渐变图 + 统计 + 通道拆分。
// 对应文档：docs/25-compute.md
#include <boost/gil.hpp>
#include <iostream>

namespace gil = boost::gil;

int main() {
    // 1) 内存中造一张 RGB 图
    gil::rgb8_image_t img(8, 4);                       // 8 宽 × 4 高
    auto view = gil::view(img);

    // 2) 写像素：水平渐变红、垂直渐变蓝
    for (int y = 0; y < view.height(); ++y) {
        for (int x = 0; x < view.width(); ++x) {
            gil::at_c<0>(view(x, y)) = static_cast<std::uint8_t>(x * 32);      // R
            gil::at_c<1>(view(x, y)) = 0;                                       // G
            gil::at_c<2>(view(x, y)) = static_cast<std::uint8_t>(y * 60);      // B
        }
    }
    std::cout << "尺寸 = " << img.width() << "×" << img.height() << '\n';
    std::cout << "(7,3) 处 R=" << (int)gil::at_c<0>(view(7, 3))
              << " B=" << (int)gil::at_c<2>(view(7, 3)) << '\n';

    // 3) 通道视图：只看红色平面
    auto red_plane = gil::nth_channel_view(view, 0);
    long red_sum = 0;
    for (auto px : red_plane) red_sum += px;     // 视图直接按像素迭代
    std::cout << "红通道总和 = " << red_sum << "（(0+..+7)×32×4 行）\n";

    // 4) 灰度化（内置颜色转换）
    gil::gray8_image_t gray(img.dimensions());
    gil::copy_and_convert_pixels(gil::view(img), gil::view(gray));
    std::cout << "灰度 (0,0)=" << (int)gil::view(gray)(0, 0)
              << " (7,0)=" << (int)gil::view(gray)(7, 0) << '\n';

    // 5) 像素类型是编译期概念：rgb8 与 gray8 的视图不可混用——类型系统
    //    替你把关了"通道数不匹配"这类 bug
    std::cout << "自检通过\n";
    return 0;
}
