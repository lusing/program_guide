// throw_exception.cpp —— Boost.ThrowException：noexcept 世界里的异常发射器
// 对应文档：docs/11-error.md
// 一句话：给"当前可能没有异常的上下文"（析构函数/回调边界）一个统一的
// 抛出点，库作者借此支持 BOOST_NO_EXCEPTIONS 的嵌入式构建。
#include <boost/throw_exception.hpp>
#include <boost/exception/diagnostic_information.hpp>
#include <iostream>
#include <stdexcept>
#include <vector>

// 库作者姿势：所有内部抛出都走 boost::throw_exception，而不是直接 throw
template <typename T>
T checked_at(const std::vector<T>& v, std::size_t i) {
    if (i >= v.size()) {
        boost::throw_exception(std::out_of_range("checked_at: 下标越界"));
    }
    return v[i];
}

int main() {
    std::vector<int> v{1, 2, 3};

    // 1) 正常使用：与 throw 相同的可观察行为
    try {
        checked_at(v, 99);
    } catch (const std::out_of_range& e) {
        std::cout << "捕获: " << e.what() << '\n';
    }

    // 2) 附带诊断信息（boost::exception 混入）：
    //    注意 boost::throw_exception(直接函数形式)只混入类型；文件/行号
    //    要用 BOOST_THROW_EXCEPTION 宏（见 exception.cpp 的例程）
    try {
        checked_at(v, 100);
    } catch (const boost::exception& e) {
        std::string diag = boost::diagnostic_information(e);
        std::cout << "诊断信息含异常类型名? "
                  << (diag.find("out_of_range") != std::string::npos) << '\n';
    }

    // 3) noexcept 边界的意义：库代码里从析构/回调往外抛的统一出口——
    //    关掉异常的构建（BOOST_NO_EXCEPTIONS）里它变成 abort/用户钩子，
    //    直接 throw 则做不到这种可配置性
    std::cout << "统一出口对 noexcept/嵌入式构建的意义见上\n";

    std::cout << "自检通过\n";
    return 0;
}
