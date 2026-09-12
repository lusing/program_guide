struct Empty {
    void foo() {}
};

// C++23 允许空类型成员不占用地址
struct S {
    [[no_unique_address]] Empty e1;
    [[no_unique_address]] Empty e2;
    int value;
};

static_assert(sizeof(S) == sizeof(int));  // C++23 可能成立
