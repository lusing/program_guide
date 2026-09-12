// 旧代码
class Legacy {
    T* ptr;
public:
    Legacy() : ptr(new T) {}
    ~Legacy() { delete ptr; }
};

// 新代码
class Modern {
    std::unique_ptr<T> ptr;
public:
    Modern() : ptr(std::make_unique<T>()) {}
    // 析构函数自动生成
};
