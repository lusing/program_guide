#include <format>
#include <chrono>

using namespace std::chrono;

// C++23 改进的格式化
auto now = system_clock::now();
auto tp = floor<seconds>(now);
std::string s = std::format("{:%Y-%m-%d %H:%M:%S}", tp);

// 宽字符串格式化
std::wstring ws = std::format(L"Hello, {}!", L"World");
