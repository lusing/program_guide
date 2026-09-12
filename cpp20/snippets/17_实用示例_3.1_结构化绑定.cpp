#include <tuple>
#include <map>

// 返回多个值
std::tuple<int, int, int> get_dimensions() {
    return {1920, 1080, 32};
}

auto [width, height, depth] = get_dimensions();

// 遍历 map
std::map<std::string, int> m = {{"a", 1}, {"b", 2}};
for (const auto& [key, value] : m) {
    std::cout << key << ": " << value << "\n";
}
