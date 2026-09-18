// phoenix.cpp —— Boost.Phoenix：函数式 EDSL，Lambda 的完全体
// 对应文档：docs/04-function.md
// Phoenix 把"表达式"变成一等公民：if/for/let 全部能内联在表达式里，
// 惰性求值。C++ lambda 覆盖了它 90% 的日常用途，剩下的 10%
// （运行期组装逻辑）依然是独门绝技。
#include <boost/phoenix.hpp>
#include <algorithm>
#include <iostream>
#include <vector>

int main() {
    using namespace boost::phoenix;
    using namespace boost::phoenix::placeholders;
    using boost::phoenix::local_names::_a;   // let 表达式的局部槽位名
    using boost::phoenix::local_names::_b;
    namespace phx = boost::phoenix;

    std::vector<int> v{3, -1, 4, -5, 9, -2, 6};

    // 1) 普通占位符表达式（与 Lambda2 相似的部分）
    std::cout << "平方和 = "
              << std::accumulate(v.begin(), v.end(), 0, _1 + _2 * _2) << '\n';

    // 2) if_ 表达式：在算法谓词里内联分支
    int neg = 0;
    std::for_each(v.begin(), v.end(),
                  if_(_1 < 0)[++ref(neg)]);        // ref() 才能真正改到局部变量
    std::cout << "负数个数 = " << neg << '\n';

    // 3) let：表达式里的局部绑定 + 构造值
    auto hypot_sq = let(_a = _1, _b = _2)[_a * _a + _b * _b];
    std::cout << "3-4 直角三角形斜边平方 = " << hypot_sq(3, 4) << '\n';

    // 4) bind 函数 + 输出流组合
    //    注意坑：直接 bind(&std::string::size, _1) 会让 phoenix 的 result_of
    //    推导失败（noexcept 成员函数指针不在它的推导表里）——包一层自由函数最稳
    std::vector<std::string> names{"ada", "grace", "jean"};
    auto len = [](const std::string& s) { return s.size(); };
    std::for_each(names.begin(), names.end(),
                  std::cout << bind(len, _1) << ' ');
    std::cout << '\n';

    // 5) 构造值：表达式里直接构造容器/对象
    auto make_pair_ = construct<std::pair<int, int>>(_1, _2)(3, 7);
    std::cout << "construct pair = (" << make_pair_.first << ',' << make_pair_.second << ")\n";

    // 6) 真正的独门绝技：运行期组装
    //    装配两个独立动作成一个复合表达式（lambda 做不到：无法把
    //    多个独立 lambda "接"成一个再当值传）
    //    注意：if_[...].else_[...] 是语句版（不产值）；要产值得用 if_else
    int trace = 0;
    auto log_it = ++ref(trace);
    auto abs_it = if_else(_1 < 0, -_1, _1);
    std::vector<int> out;
    for (int x : v) {
        log_it();
        out.push_back(abs_it(x));
    }
    std::cout << "复合动作运行 " << trace << " 次, |x| 序列:";
    for (int x : out) std::cout << ' ' << x;
    std::cout << '\n';

    std::cout << "自检通过\n";
    return 0;
}
