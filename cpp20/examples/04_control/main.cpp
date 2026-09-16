#include <cassert>
#include <print>
#include <string>
#include <vector>

// 04 表达式与控制流：if/switch/循环/range-for
int main() {
    // ═══ 4.1 if 与初始化语句 ═══
    std::string lang = "现代 C++";
    if (auto pos = lang.find("C++"); pos != std::string::npos) {
        std::print("找到子串，位置 {}\n", pos);
    } else {
        std::print("没找到\n");
    }

    // ═══ 4.2 switch：fallthrough 必须显式 [[fallthrough]] ═══
    for (int level = 1; level <= 3; ++level) {
        switch (level) {
            case 3:
                std::print("高级 → ");
                [[fallthrough]];
            case 2:
                std::print("中级 → ");
                [[fallthrough]];
            case 1:
                std::print("入门\n");
                break;
            default:
                break;
        }
    }

    // ═══ 4.3 经典 for 与 while ═══
    int sum = 0;
    for (int i = 1; i <= 100; ++i) {
        sum += i;
    }
    int n = 1024, steps = 0;
    while (n > 1) {
        n /= 2;
        ++steps;
    }

    // ═══ 4.4 range-for：遍历一切容器 ═══
    std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6};
    int odd_count = 0;
    for (int v : nums) {
        if (v % 2 == 1) {
            ++odd_count;
        }
    }
    for (char ch : std::string("C++")) {  // string 也能逐字符
        std::print("[{}] ", ch);
    }
    std::println("");

    // ═══ 4.5 break 与 continue ═══
    int first_odd_gt3 = -1;
    for (int v : nums) {
        if (v % 2 == 0) continue;  // 跳过偶数
        if (v > 3) {
            first_odd_gt3 = v;
            break;  // 找到即停
        }
    }

    // ═══ 4.6 自检 ═══
    std::print("sum={} steps={} odd_count={} first_odd_gt3={}\n",
               sum, steps, odd_count, first_odd_gt3);
    assert(sum == 5050 && steps == 10);
    assert(odd_count == 5 && first_odd_gt3 == 5);
    std::println("自检通过");
}
