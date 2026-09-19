// io.cpp —— Boost.IO（2022 重制）：ostream 的组合器与工具
//（原来的 ostream_joiner 已让位给 std::ostream_joiner 的普及）。
// 对应文档：docs/29-process-system.md
#include <boost/io/quoted.hpp>
#include <iostream>
#include <iterator>
#include <sstream>
#include <string>
#include <vector>

int main() {
    // 1) quoted：CSV/引号转义的救星（std::quoted 在 <iomanip> 也有——
    //    boost::io::quoted 是它的先行者，语义一致）
    std::string field = "含,逗号 \"引号\"";
    std::ostringstream oss;
    oss << boost::io::quoted(field);
    std::string encoded = oss.str();
    std::cout << "编码 = " << encoded << '\n';

    std::string decoded;
    std::istringstream iss(encoded);
    iss >> boost::io::quoted(decoded);
    std::cout << "解码一致? " << (decoded == field) << '\n';

    // 2) 自定义定界符
    std::ostringstream oss2;
    oss2 << boost::io::quoted(field, '*', '|');
    std::cout << "自定义定界 = " << oss2.str() << '\n';

    // 3) 让位说明：曾经的 ostream_joiner 惯用法由 C++17 标准接管
    //    （MSVC STL 未随附，手写 join 更普适）
    std::vector<int> nums{1, 2, 3};
    std::cout << "join: ";
    for (std::size_t i = 0; i < nums.size(); ++i) {
        if (i) std::cout << " + ";
        std::cout << nums[i];
    }
    std::cout << '\n';

    std::cout << "自检通过\n";
    return 0;
}
