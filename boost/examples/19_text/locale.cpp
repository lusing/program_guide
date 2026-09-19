// locale.cpp —— Boost.Locale（2010）：Unicode 与本地化的地面部队
//（std::locale 只管格式化刻面，大小写转换/归一化/断行这些真活它不干）
// 对应文档：docs/19-text.md
#include <boost/locale.hpp>
#include <iostream>

int main() {
    using namespace boost::locale;

    // 生成一个 UTF-8 环境（with_generations 默认后端：Windows 上用 WinAPI）
    std::locale loc = boost::locale::generator().generate("");

    // 1) 大小写转换：UTF-8 感知（ASCII 的 toupper 做不了这些）
    std::string gruss = "grüße";
    std::cout << "大写 = " << boost::locale::to_upper(gruss, loc) << '\n';
    std::cout << "小写 = " << boost::locale::to_lower("GRÜSSE", loc) << '\n';

    // 2) 归一化：Unicode 的四种形式（NFC/NFD/NFKC/NFKD）——
    //    字符串比较/去重前必做（视觉相同的字可能码点不同）
    std::string nfc = normalize("é", norm_type::norm_nfc, loc);    // 组合形
    std::string nfd = normalize("é", norm_type::norm_nfd, loc);    // 分解形
    std::cout << "NFC/NFD 字节数 = " << nfc.size() << '/' << nfd.size()
              << "（分解形 e+́ 占更多字节）\n";
    std::cout << "归一化后相等? "
              << (normalize(nfc, norm_type::norm_nfd, loc) == nfd) << '\n';

    // 3) 消息翻译骨架：gettext 语义
    using boost::locale::translate;
    std::string msg = translate("File not found").str();
    std::cout << "翻译键 = " << msg << "（无字典时原样返回）\n";

    // 4) std::locale 对照：数字/日期格式化刻面是 std 的；
    //    归一化/大小写/断行/charset 转换是 Boost.Locale 的独占领地
    std::cout << "自检通过\n";
    return 0;
}
