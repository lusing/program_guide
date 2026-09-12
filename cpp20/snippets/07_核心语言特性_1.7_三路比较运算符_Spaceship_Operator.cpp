#include <compare>

struct Point {
    int x, y;

    auto operator<=>(const Point&) const = default;
};

Point p1{1, 2}, p2{3, 4};
bool less = (p1 < p2);  // true

// 自定义比较
struct String {
    std::string s;

    auto operator<=>(const String& other) const {
        return s.compare(other.s) <=> 0;
    }
};
