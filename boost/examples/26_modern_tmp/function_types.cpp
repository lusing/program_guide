// function_types.cpp —— Boost.FunctionTypes（2004）：解剖函数类型的手术刀
//（比 04 章 callable_traits 更底层：分解任意函数类型为构件）。
// 对应文档：docs/26-modern-tmp.md
#include <boost/function_types/function_type.hpp>
#include <boost/function_types/parameter_types.hpp>
#include <boost/function_types/result_type.hpp>
#include <boost/function_types/is_function.hpp>
#include <boost/function_types/is_member_function_pointer.hpp>
#include <boost/mp11.hpp>
#include <iostream>
#include <typeinfo>
#include <vector>

int free_fn(double, char);

int main() {
    using namespace boost::function_types;

    // 1) 判定
    using F = int(double, char);
    std::cout << "是函数类型? " << is_function<F>::value << '\n';

    // 2) 分解：参数类型序列 + 返回类型（Ret 是引用形态的封装，::type 取实体）
    using Args = parameter_types<F>;
    using Ret = result_type<F>;
    std::cout << "参数个数 = " << boost::mp11::mp_size<Args>::value << '\n';
    std::cout << "返回类型与 int 同? "
              << std::is_same_v<std::remove_reference_t<typename Ret::type>, int> << '\n';

    // 4) 成员函数指针的分解
    struct Dummy { void method(int); };
    using MFn = void (Dummy::*)(int);
    std::cout << "是成员函数指针? " << is_member_function_pointer<MFn>::value << '\n';

    std::cout << "自检通过\n";
    return 0;
}
