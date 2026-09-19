// contract.cpp —— Boost.Contract（1990s 提案 → 2018 成库）：
// DbC（按契约设计）的 C++ 实现——前置/后置/不变量三件套。
// C++26 contracts（P2900）落地前的生产答案。
// 对应文档：docs/32-quality.md
// C4701：contract 内部头在新 MSVC 下的固有告警，定点压制
#pragma warning(push)
#pragma warning(disable : 4701)
#include <boost/contract.hpp>
#pragma warning(pop)
#include <iostream>
#include <vector>

// 契约三件套的完整形态。
// 关键：契约对象必须显式声明为 boost::contract::check——写 auto 会拿到
// 中间的 specify 类型，契约不激活，运行期直接断言
// "missing_check_object_declaration"（实测 fail-fast 现场）
double divide(double a, double b) {
    double result = 0;
    boost::contract::check c = boost::contract::function()
                 .precondition([&] { BOOST_CONTRACT_ASSERT(b != 0.0); })
                 .postcondition([&] { BOOST_CONTRACT_ASSERT(result * b == a); });

    return result = a / b;
}

// 不变量：类的不变式
class Counter {
public:
    Counter() : n_(0) {}

    void increment() {
        boost::contract::old_ptr<int> old_n = BOOST_CONTRACT_OLDOF(n_);   // 旧值捕获
        boost::contract::check c = boost::contract::public_function(this)
                     .precondition([&] { BOOST_CONTRACT_ASSERT(n_ < 100); })
                     .postcondition([&] { BOOST_CONTRACT_ASSERT(n() == *old_n + 1); });
        ++n_;
    }
    int n() const { return n_; }

private:
    int n_;
    friend class boost::contract::access;
    void invariant() const { BOOST_CONTRACT_ASSERT(n_ >= 0); }
};

int main() {
    // 1) 正常路径：契约静默通过
    std::cout << "10/4 = " << divide(10, 4) << '\n';

    // 2) 前置条件失败：断言违例（这里不真触发——文档说明行为即可）
    // divide(1, 0) 会抛 boost::contract::assertion_failure

    // 3) 类不变量 + 后置（old 值检查）
    Counter cnt;
    cnt.increment();
    cnt.increment();
    std::cout << "计数 = " << cnt.n() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
