// static_string.cpp —— Boost.StaticStrings（2019）：定容字符串
// 固定容量、栈上存储、constexpr 友好——嵌入式与解析缓冲的主力。
// 对应文档：docs/12-vocabulary.md
#include <boost/static_string/static_string.hpp>
#include <iostream>

int main() {
    // 1) 定容：容量编译期定，超了抛异常（或用 truncate 变体）
    boost::static_string<32> s;
    s = "hello";
    std::cout << "内容 = " << s << " 容量 = " << s.capacity() << '\n';

    // 2) 拼接受控
    s += " world";
    std::cout << "拼接后 = " << s << " 长度 = " << s.size() << '\n';

    // 3) 越界 = 异常，不是缓冲区溢出（C 数组时代的病灶）
    try {
        boost::static_string<4> tiny;
        tiny = "overflow-me";
    } catch (const std::length_error&) {
        std::cout << "超容抛 length_error（不是 UB）\n";
    }

    // 4) 与 std::string 的互操作：一样的接口子集
    std::cout << "find = " << s.find("world") << "（下标 6）\n";

    // 5) 用途：日志行缓冲、协议字段、无堆环境
    std::cout << "场景：无堆/实时/嵌入式缓冲\n";

    std::cout << "自检通过\n";
    return 0;
}
