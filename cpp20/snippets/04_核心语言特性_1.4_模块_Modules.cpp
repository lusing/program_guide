// math.ixx (模块接口文件)
export module math;

export int add(int a, int b) {
    return a + b;
}

export double multiply(double a, double b) {
    return a * b;
}

// main.cpp
import math;
#include <iostream>

int main() {
    std::cout << add(2, 3) << "\n";
    std::cout << multiply(2.5, 4.0) << "\n";
}
