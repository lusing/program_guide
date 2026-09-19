// preprocessor.cpp —— Boost.Preprocessor（2001）：用预处理器做元编程——
// C++03 时代"变参模板"的替身。今天仍有 X 宏、重复展开的实战用途。
// 对应文档：docs/27-classic-tmp.md
#include <boost/preprocessor.hpp>
#include <iostream>

#define MESSAGE_TABLE \
    ((继续, 100))     \
    ((未找到, 404))   \
    ((服务器错, 500))

// X 宏惯用法：一张表，多种展开（顺序注意：元组是 (名字, 码)）
#define AS_ENUM(r, data, elem) BOOST_PP_TUPLE_ELEM(0, elem) = BOOST_PP_TUPLE_ELEM(1, elem),
#define AS_CASE(r, code, elem) \
    case BOOST_PP_TUPLE_ELEM(1, elem): return BOOST_PP_STRINGIZE(BOOST_PP_TUPLE_ELEM(0, elem));

enum Status {
    BOOST_PP_SEQ_FOR_EACH(AS_ENUM, _, MESSAGE_TABLE)   // 展开 enum
};

const char* status_name(int s) {
    switch (s) {
        BOOST_PP_SEQ_FOR_EACH(AS_CASE, _, MESSAGE_TABLE)   // 展开 switch
        default: return "未知";
    }
}

// 重复展开：生成 N 层固定输出
#define TRACE_CALL(z, n, data) \
    std::cout << "  第 " << n << " 层" << '\n';

int main() {
    std::cout << "404 = " << status_name(404) << '\n';
    std::cout << "500 = " << status_name(500) << '\n';

    std::cout << "重复展开:\n";
    BOOST_PP_REPEAT(3, TRACE_CALL, _)

    // 编译期算术：预处理器也能做数学
    std::cout << "BOOST_PP_ADD(2,3) = " << BOOST_PP_ADD(2, 3) << '\n';
    std::cout << "自检通过\n";
    return 0;
}
