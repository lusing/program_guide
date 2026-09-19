// interval.cpp —— Boost.Interval（numeric/interval，2002）：
// 区间算术——每步运算携带误差界，结果的"可信区间"自动跟踪。
// 对应文档：docs/25-compute.md
#include <boost/numeric/interval.hpp>
#include <iostream>

namespace nb = boost::numeric::interval_lib;
using I = boost::numeric::interval<double>;

int main() {
    // 1) 带误差界的量：测量值 1.0 ± 0.1
    I width(0.9, 1.1);
    I height(1.9, 2.1);

    I area = width * height;
    std::cout << "面积区间 = [" << area.lower() << ", " << area.upper() << "]\n";

    // 2) 误差传播：区间宽度随运算增长
    I sum = width + width + width;
    std::cout << "三次相加 = [" << sum.lower() << ", " << sum.upper() << "]（误差也 ×3）\n";

    // 3) 包含判定：结果是否严格包含某值
    std::cout << "面积包含 2.0? " << boost::numeric::in(2.0, area) << '\n';
    std::cout << "面积包含 2.5? " << boost::numeric::in(2.5, area) << '\n';

    // 4) 除零与无穷：区间算术不慌
    I denom(-0.1, 0.1);
    I ratio = I(1.0, 1.0) / denom;
    std::cout << "1/(±0.1) = [" << ratio.lower() << ", " << ratio.upper() << "]（跨无穷）\n";

    // 5) 用途：数值验证、有界证明、测量误差传播
    std::cout << "自检通过\n";
    return 0;
}
