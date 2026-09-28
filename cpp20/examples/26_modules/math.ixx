export module math;

// 26 模块：模块接口单元——export 的名字才对 import 方可见

export int add(int a, int b) {
    return a + b;
}
export int sub(int a, int b) {
    return a - b;
}
export constexpr double pi = 3.14159265358979323846;

// ═══ 26.5 命名空间与模块：正交的两套组织机制 ═══
export namespace math {                  // export namespace：整块导出
    constexpr double sqrt2 = 1.414213562373095;              // math::sqrt2
    auto square(const auto& x) { return x * x; }             // math::square
    namespace inner {                                        // 嵌套命名空间
        auto pow4(const auto& x) { return square(square(x)); }  // math::inner::pow4
    }
}
