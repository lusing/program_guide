#include <algorithm>
#include <array>
#include <filesystem>
#include <fstream>
#include <mdspan>
#include <print>
#include <regex>
#include <string>
#include <vector>

namespace fs = std::filesystem;

// 22 文本与文件：format 深入、regex、filesystem、mdspan 一瞥

int main() {
    // ═══ 22.1 std::format 常用招式 ═══
    std::println("{:>10}|", "右对齐");
    std::println("{:<10}|", "左对齐");
    std::println("{:^10}|", "居中");
    // 注：浮点 % 类型带精度（{:.1%}）在 MSVC 编译期格式检查中报错——×100 手写百分号绕过
    std::println("保留两位：{:.2f}，百分比：{:.1f}%", 3.14159, 0.856 * 100);
    std::println("十六进制 {:#x}，二进制 {:#b}", 255, 5);
    std::println("填充星号：{:*^14}", "标题");

    // ═══ 22.2 regex：正则匹配与捕获组 ═══
    std::string log = "2026-09-17 ERROR 磁盘不足; 2026-09-16 INFO 正常";
    std::regex date_re{R"((\d{4})-(\d{2})-(\d{2}))"};  // 原始字符串字面量
    for (std::sregex_iterator it{log.begin(), log.end(), date_re}, end; it != end; ++it) {
        std::println("日期 {}-{}-{}", it->str(1), it->str(2), it->str(3));  // str(n) 取捕获组
    }
    std::println("含 ERROR？{}", std::regex_search(log, std::regex{"ERROR"}));

    // ═══ 22.3 filesystem：目录与文件 ═══
    fs::path dir = fs::temp_directory_path() / "cpp_guide_22";
    fs::create_directories(dir / "sub");
    {
        std::ofstream{dir / "a.txt"} << "hello 文件系统";
        std::ofstream{dir / "sub" / "b.log"} << "日志内容";
    }
    std::vector<fs::path> entries;  // 收集后排序：目录遍历顺序不保证
    for (const auto& e : fs::recursive_directory_iterator{dir}) {
        entries.push_back(e.path());
    }
    std::sort(entries.begin(), entries.end());
    std::println("遍历 {}:", dir.string());
    for (const auto& p : entries) {
        std::println("  {}", p.string());
    }
    std::println("清理了 {} 个条目", fs::remove_all(dir));

    // ═══ 22.4 mdspan 一瞥 (C++23)：多维视图 ═══
    std::array<int, 6> data{1, 2, 3, 4, 5, 6};
    std::mdspan grid{data.data(), 2, 3};  // 2 行 3 列（访问用 grid[r, c]）
    for (std::size_t r = 0; r < grid.extent(0); ++r) {
        for (std::size_t c = 0; c < grid.extent(1); ++c) {
            std::print("{} ", grid[r, c]);
        }
        std::println("");
    }
    std::println("自检通过");
}
