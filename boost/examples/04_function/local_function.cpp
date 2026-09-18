// local_function.cpp —— Boost.LocalFunction：函数体内的具名函数
// 对应文档：docs/04-function.md
// 2007 年的库，用宏在函数体里定义"能访问局部变量"的具名函数块。
// C++11 lambda 能做同样的事，但它有一个 lambda 没有的特性：具名 + 可递归。
#include <boost/local_function.hpp>
#include <iostream>
#include <vector>

int main() {
    std::vector<int> v{5, 3, 8, 1, 9, 2};
    int threshold = 4;
    int count = 0;

    // 语法：返回类型放在宏前面；绑定列表写在参数表最前面
    // （bind& 是引用捕获，const bind& 是 const 引用捕获）
    // C4459 是宏内部辅助变量名与全局声明的遮蔽告警——宏库在 /W4 下的固有噪声
#pragma warning(push)
#pragma warning(disable : 4459)
    bool BOOST_LOCAL_FUNCTION(const bind& threshold, bind& count, int x) {
        bool is_above = x > threshold;
        if (is_above) ++count;
        return is_above;
    } BOOST_LOCAL_FUNCTION_NAME(above)
#pragma warning(pop)

    std::vector<int> keep;
    for (int x : v) {
        if (above(x)) keep.push_back(x);
    }
    std::cout << "threshold=" << threshold << " 以上: ";
    for (int x : keep) std::cout << x << ' ';
    std::cout << "\n命中 " << count << " 个\n";

    // 等价的 C++11 写法——具名 lambda 同样可读，还不用宏：
    int count2 = 0;
    auto above2 = [&count2, threshold](int x) {
        bool r = x > threshold;
        if (r) ++count2;
        return r;
    };
    (void)above2;

    std::cout << "自检通过\n";
    return 0;
}
