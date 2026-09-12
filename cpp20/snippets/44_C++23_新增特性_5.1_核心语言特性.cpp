// constexpr new 和动态对象生命周期
constexpr auto make_vector() {
    auto* p = new int[5];
    for (int i = 0; i < 5; ++i) {
        p[i] = i * 2;
    }
    // 使用完成后需要手动释放（在常量表达式中）
    // 实际使用中通常结合 RAII
    return p;
}

// constexpr 支持 std::string
constexpr auto greet() {
    std::string s = "Hello, C++23!";
    return s;
}
