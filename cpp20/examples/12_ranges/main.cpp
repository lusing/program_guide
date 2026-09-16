#include <algorithm>
#include <functional>
#include <print>
#include <ranges>
#include <string>
#include <vector>

// 12 Ranges：惰性视图管道

struct Student {
    std::string name;
    int score;
};

int main() {
    std::vector<Student> students{
        {"alice", 92}, {"bob", 78}, {"carol", 86}, {"dave", 64}, {"eve", 95},
    };

    // ═══ 12.1 管道：filter → transform → 收集 ═══
    auto passed = students
        | std::views::filter([](const Student& s) { return s.score >= 80; })
        | std::views::transform([](const Student& s) {
              return s.name + ":" + std::to_string(s.score);
          })
        | std::ranges::to<std::vector>();  // (C++23) 一行收集
    for (const auto& line : passed) {
        std::println("  {}", line);
    }

    // ═══ 12.2 惰性：手动消费，拿够即停 ═══
    int visited = 0;
    auto passing = students | std::views::filter([&visited](const Student& s) {
        ++visited;  // 打点：谓词每跑一次记一次
        return s.score >= 60;
    });
    std::vector<std::string> first_two;
    for (const Student& s : passing) {
        first_two.push_back(s.name);
        if (first_two.size() == 2) break;  // 拿够 2 个就停：后面 3 个根本不看
    }
    std::println("手动取 2 个，实际只访问了 {} 个元素", visited);  // 2

    // 对比：同样取 2 个走 ranges::to——MSVC 会先估尺寸把 filter 抽干
    int drained = 0;
    auto wasted = students
        | std::views::filter([&drained](const Student& s) {
              ++drained;
              return s.score >= 60;
          })
        | std::views::take(2)
        | std::ranges::to<std::vector>();
    std::println("ranges::to 取 2 个（结果 {} 个），却访问了 {} 个元素——工具链实测坑",
                 wasted.size(), drained);  // 5：to 先估尺寸，惰性白搭

    // ═══ 12.3 iota / take / drop / reverse：生成与裁剪 ═══
    std::print("平方: ");
    for (int v : std::views::iota(1, 6) | std::views::transform([](int i) { return i * i; })) {
        std::print("{} ", v);  // 1 4 9 16 25
    }
    std::println("");
    std::print("后两个倒序: ");
    for (const auto& s : students | std::views::drop(3) | std::views::reverse) {
        std::print("{} ", s.name);  // eve dave
    }
    std::println("");

    // ═══ 12.4 ranges 算法 + 投影 ═══
    std::ranges::sort(students, std::greater{}, &Student::score);  // 按分数降序
    std::print("排名: ");
    for (const auto& name : students | std::views::transform(&Student::name)) {
        std::print("{} ", name);
    }
    std::println("");
    std::println("自检通过");
}
