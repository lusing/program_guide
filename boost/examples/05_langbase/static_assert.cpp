// static_assert.cpp —— Boost.StaticAssert：编译期断言（已 100% 毕业）
// 对应文档：docs/05-langbase.md
// 2000 年的库，2011 年语言特性 static_assert 进 C++11。
// 留下来的唯一价值是"写给老标准的库"这个场景本身。
#include <boost/static_assert.hpp>
#include <cstdint>
#include <iostream>

template <typename T>
T safe_median(T a, T b, T c) {
    // BOOST_STATIC_ASSERT 在函数内/类内/名字空间内都能用（C++98 兼容）
    BOOST_STATIC_ASSERT_MSG(sizeof(T) >= 4, "median 需要至少 32 位宽度，防精度丢失");
    return a < b ? (b < c ? b : (a < c ? c : a))
                 : (a < c ? a : (b < c ? c : b));
}

// 名字空间级别的编译期检查（C++11 起直接写 static_assert）
static_assert(sizeof(std::int64_t) * CHAR_BIT == 64, "int64_t 必须 64 位");
BOOST_STATIC_ASSERT(sizeof(void*) >= 4);   // 老写法：无消息版本

int main() {
    std::cout << "median(3,1,2) = " << safe_median<std::int32_t>(3, 1, 2) << '\n';

    // 逆序演示：下面这行如果打开，编译立即失败，报错就在断言处
    // std::cout << safe_median<char>('a', 'b', 'c') << '\n';
    std::cout << "编译期防线就位\n";

    std::cout << "自检通过\n";
    return 0;
}
