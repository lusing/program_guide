export module math;

// 18 模块：模块接口单元——export 的名字才对 import 方可见

export int add(int a, int b) {
    return a + b;
}

export int sub(int a, int b) {
    return a - b;
}

export constexpr double pi = 3.14159265358979323846;
