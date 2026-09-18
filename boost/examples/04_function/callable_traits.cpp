// callable_traits.cpp —— Boost.CallableTraits：解剖任意可调用物的签名
// 对应文档：docs/04-function.md
// 写泛型代码时回答"这个 T 能不能调？返回什么？第 2 个参数是什么类型？"
#include <boost/callable_traits.hpp>
#include <iostream>
#include <string>

int free_fn(int, std::string);

struct Functor {
    double operator()(char, int) const { return 0; }
};

// 泛型代码里最常见的两个问题，callable_traits 一行一个：
template <typename F>
void describe(const char* label) {
    using args = boost::callable_traits::args_t<F>;        // 参数类型包
    using ret  = boost::callable_traits::return_type_t<F>; // 返回类型
    std::cout << label << ": 参数个数=" << std::tuple_size<args>::value
              << " 返回类型=" << typeid(ret).name()
              << " 第2参数=" << typeid(std::tuple_element_t<1, args>).name() << '\n';
}

int main() {
    describe<int(int, std::string)>("函数类型");
    describe<Functor>("仿函数");
    describe<decltype([](int a, double b) { return a + b; })>("lambda");

    // 还能拆解成员函数指针：args_t 自动把类指针排第一个
    using memfn = decltype(&Functor::operator());
    std::cout << "成员函数 is_const = " << std::boolalpha
              << boost::callable_traits::is_const_member_v<memfn> << '\n';

    std::cout << "自检通过\n";
    return 0;
}
