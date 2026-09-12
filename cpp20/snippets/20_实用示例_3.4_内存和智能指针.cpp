#include <memory>

// std::shared_ptr 支持数组
std::shared_ptr<int[]> arr(new int[10]);

// std::basic_string_view
std::string_view sv = "Hello World";
auto first = sv.substr(0, 5);
