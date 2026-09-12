#include <optional>
#include <ranges>

std::optional<int> find_value() {
    return 42;
}

// if 初始化
if (auto v = find_value(); v.has_value()) {
    std::cout << "Found: " << *v << "\n";
}

std::vector<int> data = {1, 2, 3, 4, 5};

// switch 初始化
switch (auto it = std::ranges::find(data, 3); it != data.end()) {
    case true:  std::cout << "Found\n"; break;
    case false: std::cout << "Not found\n"; break;
}
