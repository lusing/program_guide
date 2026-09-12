// 该示例来自模块章节。为便于单文件编译验证，这里用普通函数等价演示 add/multiply 的调用方式。
int add(int a, int b) {
    return a + b;
}

double multiply(double a, double b) {
    return a * b;
}

#include <iostream>

int main() {
    std::cout << add(2, 3) << "\n";
    std::cout << multiply(2.5, 4.0) << "\n";
}
