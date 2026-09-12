struct A {
    operator int() const { return 42; }
};

void f(int);

// C++23 允许更多隐式转换场景
f(A{});  // 更宽松的转换支持
