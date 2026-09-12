// constexpr 支持虚拟函数
class Base {
public:
    virtual constexpr int value() const { return 0; }
};

// constexpr std::vector 等容器
constexpr std::vector<int> create_vector() {
    std::vector<int> v;
    v.push_back(1);
    v.push_back(2);
    return v;
}

// constexpr 支持 new/delete
constexpr int* create_array() {
    int* arr = new int[5];
    for (int i = 0; i < 5; ++i) {
        arr[i] = i;
    }
    return arr;
}
