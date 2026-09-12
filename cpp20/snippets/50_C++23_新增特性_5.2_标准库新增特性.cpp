// Unicode 文本处理（提案中的特性）
// #include <text>

// std::text t = "Hello, 世界";
// std::text t2 = t | std::views::uppercase;

// 当前替代方案：使用 std::u8string 和 ICU 库
std::u8string utf8_text = u8"Hello, 世界";
