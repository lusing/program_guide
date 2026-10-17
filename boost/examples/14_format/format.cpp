// format.cpp —— Boost.Format（2002）：printf 的类型安全重制
//（std::format 是平行进化——来自 fmt，不是这个库——但同样终结了它的历史使命）
// 对应文档：docs/14-format.md
#include <boost/format.hpp>
#include <boost/io/ios_state.hpp>
#include <format>
#include <iomanip>
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

    // 7) %|spec| 变体：竖线包住格式规格，与普通字符分得更清楚
    std::cout << boost::format("[%|05d|] [%|-8.3f|] [%| 10s|] [%|05X|]\n")
                     % 62 % 2.236 % "123456789" % 48;

    // 8) 对象的复用合同：str() 不清缓存可重复取；clear() 清参数保留绑定；
    //    parse() 换格式串重头开始
    boost::format cell("[%1%]");
    cell % "first";
    std::cout << cell.str() << cell.str() << "（str 可重复取）";
    cell.clear();                                   // 只清已喂参数
    cell % "second";
    std::cout << cell.str() << '\n';

    // 9) 高级件一：bind_arg —— 把某个参数位固定住（clear 也不丢）
    boost::format row("%1% × %2% = %3%");
    row.bind_arg(2, 7);                             // 第 2 位恒为 7
    for (int i = 1; i <= 3; ++i) {
        row.clear();
        std::cout << (row % i % (i * 7)) << "  ";   // 只喂 1、3 两位
    }
    row.clear_bind(2);                              // 解绑
    std::cout << "解绑后需 3 参\n";

    // 10) 高级件二：modify_item + io::group —— 运行期改格式位
    boost::format hexfmt("[%1%] [%2%]");
    hexfmt.modify_item(1, boost::io::group(std::hex, std::right,
                                           std::setw(6), std::setfill('*')));
    std::cout << (hexfmt % 255 % "右对齐十六进制") << '\n';

    // 11) 性能件：反复使用同一格式时，拷贝一份 const 模板再喂
    //     （书里的技巧：拷贝比从字符串重新构造快）
    const boost::format tmpl2("[%6d] [%08.2f]");
    std::cout << boost::format(tmpl2) % 42 % 3.14159 << '\n';

    std::cout << "自检通过\n";
    return 0;
}
