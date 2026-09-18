// lambda2.cpp —— Boost.Lambda2：用现代 C++ 重写的小型占位符库
// 对应文档：docs/04-function.md
// Boost.Lambda 的 2021 年重制版：同样的 _1+_2 语法，
// 但建立在 C++11 的机制上，代码量从几万行降到几百行。
#include <boost/lambda2/lambda2.hpp>
#include <algorithm>
#include <iostream>
#include <vector>

int main() {
    using namespace boost::lambda2;   // _1, _2, _3（这次的命名空间是 lambda2）

    std::vector<int> v{1, 2, 3, 4, 5};

    // 表达式模板：_1 % 2 == 0 整体是谓词对象
    auto even_count = std::count_if(v.begin(), v.end(), _1 % 2 == 0);
    std::cout << "偶数个数 = " << even_count << '\n';

    std::vector<int> out;
    std::transform(v.begin(), v.end(), std::back_inserter(out), _1 * _1 + 1);
    std::cout << "x^2+1:";
    for (int x : out) std::cout << ' ' << x;
    std::cout << '\n';

    // 双占位符：两个序列的对应元素运算
    std::vector<int> w{10, 20, 30, 40, 50};
    std::transform(v.begin(), v.end(), w.begin(), out.begin(), _1 * _2);
    std::cout << "点乘式对应相乘:";
    for (int x : out) std::cout << ' ' << x;
    std::cout << '\n';

    std::cout << "自检通过\n";
    return 0;
}
