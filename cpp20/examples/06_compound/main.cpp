#include <array>
#include <print>
#include <span>
#include <string>
#include <string_view>
#include <vector>

// 06 复合类型：struct、enum class、string、string_view、span

// ═══ 6.1 struct：把相关数据打包 ═══
struct Book {
    std::string title;
    double price;
    int pages;
};

// ═══ 6.3 enum class：带作用域的枚举 ═══
enum class Format { paperback, hardcover, ebook };

// ═══ 6.6 span 求和工具：数组/vector 通吃 ═══
int sum_of(std::span<const int> values) {
    int total = 0;
    for (int v : values) {
        total += v;
    }
    return total;
}

int main() {
    // 6.1 指定初始化器 (C++20)：字段必须按声明顺序
    Book b{
        .title = "现代 C++ 实战",
        .price = 89.5,
        .pages = 420,
    };

    // ═══ 6.2 结构化绑定：一把拆出成员 ═══
    auto [title, price, pages] = b;
    std::println("{} / {:.1f} 元 / {} 页", title, price, pages);

    // 6.3 必须带作用域名访问
    Format f = Format::hardcover;
    std::println("格式编号 = {}", static_cast<int>(f));

    // ═══ 6.4 std::string：可变字符串 ═══
    std::string s = "C++";
    s += "20";
    s.push_back('!');
    std::println("{}（长度 {}）", s, s.size());
    std::println("包含 '20'？{}", s.contains("20"));  // contains (C++23)

    // ═══ 6.5 string_view：不拥有字符串的只读视图 ═══
    std::string_view sv = s;
    std::println("sv 前 4 个字符：{}", sv.substr(0, 4));

    // ═══ 6.6 span：一段内存的视图（C++20）═══
    std::array<int, 5> arr{1, 2, 3, 4, 5};
    std::vector<int> vec{10, 20, 30};
    std::println("sum(arr) = {}，sum(vec) = {}", sum_of(arr), sum_of(vec));
    std::span<int> middle = std::span{arr}.subspan(1, 3);  // 第 2–4 个
    middle[0] = 99;  // 非 const span 可写穿
    std::println("改写后 arr[1] = {}", arr[1]);
    std::println("自检通过");
}
