#include <iostream>
#include <print>

// 02 第一个程序：main、std::print 与 iostream
int main() {
    // ═══ 2.1 最小的程序：main 与返回值 ═══
    std::println("你好，C++23！");  // println 自动换行

    // ═══ 2.2 std::print / std::println：占位符格式化 ═══
    std::print("姓名：{}，年龄：{}\n", "阿 C", 25);
    std::print("编号 {:03}，PI ≈ {:.2f}\n", 7, 3.14159);
    std::print("{:*^24}\n", "居中标题");  // 填充对齐

    // ═══ 2.3 老朋友 iostream：<< 链式输出 ═══
    std::cout << "iostream 也能输出："
              << "int " << 42 << "，double " << 3.14 << "\n";

    // ═══ 2.4 退出码：0 表示成功 ═══
    return 0;  // 脚本/CI 按退出码判断成败
}
