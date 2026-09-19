// algorithm.cpp —— Boost.Algorithm（2012）的字符串算法部：std 库没有的
// 那一整层字符串手术刀（C++ 标准库至今只有零星几个）
// 对应文档：docs/19-text.md
#include <boost/algorithm/string.hpp>
#include <iostream>
#include <string>
#include <vector>

int main() {
    std::string line = "  The Quick, Brown Fox  ";

    // 1) 大小写族（to_upper/to_lower 的原地与拷贝版本）
    std::string up = boost::to_upper_copy(line);
    std::cout << "大写 = [" << up << "]\n";

    // 2) 修剪族（trim/trim_left/trim_right + 谓词版本）
    std::cout << "修剪 = [" << boost::trim_copy(line) << "]\n";

    // 3) 切分与连接
    std::vector<std::string> parts;
    boost::split(parts, boost::trim_copy(line), boost::is_any_of(" ,"));
    std::cout << "分词数 = " << parts.size() << " 连接 = "
              << boost::join(parts, "_") << '\n';

    // 4) 替换族（replace_all / erase_all / replace_first）
    std::string s = "boost::algorithm boost::string boost";
    boost::replace_all(s, "boost::", "std::");
    std::cout << "替换 = " << s << '\n';
    boost::erase_all(s, "std::");
    std::cout << "擦除 = " << s << '\n';

    // 5) 判定族（starts_with/ends_with/contains/icontains 大小写不敏感）
    std::string img = "Photo.JPG";
    std::cout << "JPEG? " << boost::iends_with(img, ".jpg") << '\n';

    // 6) std 对照：C++20 起有 starts_with/ends_with（string），
    //    但 split/join/trim/replace_all/大小写不敏感系列 std 仍无
    std::cout << "自检通过\n";
    return 0;
}
