// header.h
class MyClass {
public:
    MyClass();
    ~MyClass();
    void do_something();
private:
    struct Impl;
    std::unique_ptr<Impl> pimpl;  // 隐藏实现细节
};

// source.cpp
struct MyClass::Impl {
    void do_something() {
        // 实现细节
    }
};

MyClass::MyClass() : pimpl(std::make_unique<Impl>()) {}
MyClass::~MyClass() = default;
void MyClass::do_something() { pimpl->do_something(); }
