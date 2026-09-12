#include <format>
#include <iostream>

// 类似 Python 的 format
std::string s1 = std::format("Hello, {}!", "World");
std::string s2 = std::format("a={}, b={}", 1, 2);
std::string s3 = std::format("pi ~= {:.2f}", 3.14159);

// 可定位参数
std::string s4 = std::format("{1} {0}", "world", "Hello");

// 对齐和填充
std::string s5 = std::format("{:>10}", "right");   // 右对齐
std::string s6 = std::format("{:*^10}", "center"); // 居中填充

std::cout << s1 << "\n";
