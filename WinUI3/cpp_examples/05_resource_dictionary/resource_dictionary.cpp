#include <cstdint>
#include <iostream>
#include <string>
#include <unordered_map>

namespace winui3_guide::resource_dictionary {

struct Color {
    std::uint8_t r{};
    std::uint8_t g{};
    std::uint8_t b{};
};

class ThemeResources {
public:
    ThemeResources()
    {
        colors_.emplace("PrimaryColor", Color{0x00, 0x78, 0xD4});
        colors_.emplace("AccentColor", Color{0xFF, 0xB9, 0x00});
    }

    [[nodiscard]] Color color(const std::string& key) const
    {
        return colors_.at(key);
    }

private:
    std::unordered_map<std::string, Color> colors_;
};

} // namespace winui3_guide::resource_dictionary

int main()
{
    const winui3_guide::resource_dictionary::ThemeResources resources;
    const auto c = resources.color("PrimaryColor");
    std::cout << "PrimaryColor: ("
              << static_cast<int>(c.r) << ", "
              << static_cast<int>(c.g) << ", "
              << static_cast<int>(c.b) << ")\n";
    return 0;
}
