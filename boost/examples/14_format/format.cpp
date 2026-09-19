// format.cpp —— Boost.Format（2002）：printf 的类型安全重制
//（std::format 是平行进化——来自 fmt，不是这个库——但同样终结了它的历史使命）
// 对应文档：docs/14-format.md
#include <boost/format.hpp>
#include <format>
#include <iostream>
#include <string>

int main() {
    // 1) printf 风格但类型安全：%s 不再要求记类型
    std::string name = "ada";
    int score = 95;
    std::cout << boost::str(boost::format("学生 %1% 得分 %2%") % name % score) << '\n';

    // 2) 位置参数复用与重排（%1% 可以用多次）
    std::cout << boost::format("%1% %2% %1%") % "回声" % 7 << '\n';

    // 3) printf 式格式规格照用：宽度/精度/对齐
    std::cout << boost::format("[%8.3f] [%-8s]") % 3.14159 % "左" << '\n';

    // 4) 格式串复用（format 对象是个"填空器"）
    boost::format tmpl("x=%1%; y=%2%");
    std::cout << (tmpl % 1 % 2) << '\n';
    std::cout << (tmpl % 10 % 20) << '\n';

    // 5) 异常而非 UB：printf 参数不匹配是未定义行为，format 是异常
    try {
        boost::format f("只有 %1%");
        f % 1;
        f % 2;   // 超出占位符数 → 异常
    } catch (const std::exception& e) {
        std::cout << "多喂参数被抓住: " << (std::string(e.what()).substr(0, 12)) << "...\n";
    }

    // 6) std::format 对照（C++20，fmt 血统，编译期检查、更快）
    std::cout << std::format("学生 {} 得分 {}\n", name, score);
    std::cout << std::format("[{:8.3f}] [{:<8}]\n", 3.14159, "左");

    std::cout << "自检通过\n";
    return 0;
}
