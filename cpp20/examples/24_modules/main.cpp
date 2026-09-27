// 24 编译单元与模块：import 代替 #include
// 编译流程（两步，build.ps1 已自动处理）：
//   1) cl /std:c++latest /interface /c math.ixx        → math.obj + math.ifc
//   2) cl /std:c++latest main.cpp math.obj             → 链接成 exe
import math;

#include <print>

int main() {
    // ═══ 24.3 import：拿到模块导出的名字 ═══
    std::println("math::add(2, 3) = {}", add(2, 3));
    std::println("math::sub(7, 4) = {}", sub(7, 4));
    std::println("math::pi = {:.5f}", pi);

    // ═══ 24.5 命名空间：模块给“边界”，命名空间给“姓氏” ═══
    std::println("math::sqrt2 = {}", math::sqrt2);
    std::println("math::square(5) = {}", math::square(5));
    std::println("math::inner::pow4(2) = {}", math::inner::pow4(2));
    std::println("自检通过");
}
