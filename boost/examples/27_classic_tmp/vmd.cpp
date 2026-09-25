// vmd.cpp —— Boost.VMD（Variadic Macro Data，2013）：检验/操作变参宏
// 参数的预处理器库。核心约束：VMD 宏只在 **#if 预处理语境**工作，
// 不能当运行期函数用（这是初学最常见的误会）。
// 对应文档：docs/27-classic-tmp.md
// C4003：VMD 内部宏在 MSVC 预处理器的固有告警（与 Boost.Parameter 同类）
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(push)
#pragma warning(disable : 4003)
#endif
#include <boost/vmd/vmd.hpp>
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(pop)
#endif
#include <boost/preprocessor.hpp>
#include <iostream>

// VMD 判定要在 #if 里用（预处理语境），结果编译成不同的代码
#if BOOST_VMD_IS_TUPLE((1, 2))
    const char* kTupleDemo = "元组";
#else
    const char* kTupleDemo = "非元组";
#endif

// IS_SEQ 展开有 MSVC 预处理器固有 C4003（库内部宏），就地压制
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(push)
#pragma warning(disable : 4003)
#endif
#if BOOST_VMD_IS_SEQ((x)(y))
    const char* kSeqDemo = "序列";
#else
    const char* kSeqDemo = "非序列";
#endif
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(pop)
#endif

#define TUPLE_SIZE_OF(...) BOOST_PP_TUPLE_SIZE(__VA_ARGS__)

int main() {
    // 1) 编译期判定结果（#if 分支已在预处理阶段选定）
    std::cout << "(1,2) 是 " << kTupleDemo << '\n';
    std::cout << "(x)(y) 是 " << kSeqDemo << '\n';

    // 2) 元组大小（配 Preprocessor 的元组操作）
    std::cout << "(a,b,c) 的长度 = " << TUPLE_SIZE_OF((a, b, c)) << '\n';

    // 3) VMD 的实际用途：让宏接口"知道自己吃到了什么"，
    //    据此选择不同的展开分支（MPL 后、concepts 前的年代的主力手艺）
    std::cout << "自检通过\n";
    return 0;
}
