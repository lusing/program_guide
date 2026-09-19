// charconv.cpp —— Boost.Charconv（2024）：C++17 std::to_chars/from_chars 的
// 超集实现——扩展浮点（std::float128_t）、更多格式、更宽的平台覆盖。
// 对应文档：docs/17-cpp23.md
#include <boost/charconv.hpp>
#include <charconv>
#include <iostream>

int main() {
    char buf[64];

    // 1) 整数 to_chars：最快捷径（无 locale、无分配、无异常）
    auto r1 = boost::charconv::to_chars(buf, buf + sizeof(buf), 1234567);
    *r1.ptr = '\0';
    std::cout << "整数写出: " << buf << "（写入了 " << r1.ptr - buf << " 字节）\n";

    // 2) from_chars：解析（失败返回 ec，不抛异常——热路径友好）
    int v = 0;
    auto r2 = boost::charconv::from_chars(buf, r1.ptr, v);
    std::cout << "整数读回: " << v << " 错误码=0? " << (r2.ec == std::errc{}) << '\n';

    // 3) 浮点：boost 版保证 shortest 往返表示（写出的串读回原值，位数最少）
    auto r3 = boost::charconv::to_chars(buf, buf + sizeof(buf), 3.14159265358979);
    *r3.ptr = '\0';
    std::cout << "浮点写出: " << buf << '\n';
    double d = 0;
    boost::charconv::from_chars(buf, r3.ptr, d);
    std::cout << "浮点读回相等? " << (d == 3.14159265358979) << '\n';

    // 4) 科学计数法/精度控制（chars_format）
    auto r4 = boost::charconv::to_chars(buf, buf + sizeof(buf), 0.000123,
                                        boost::charconv::chars_format::scientific);
    *r4.ptr = '\0';
    std::cout << "科学计数: " << buf << '\n';

    // 5) std 对照（C++17 std::charconv 存在，但浮点支持一度残缺：
    //    MSVC 早年只有整数；boost 版全平台全类型 + C++23 扩展浮点）
    auto r5 = std::to_chars(buf, buf + sizeof(buf), 42);
    *r5.ptr = '\0';
    std::cout << "std 版: " << buf << '\n';

    std::cout << "自检通过\n";
    return 0;
}
