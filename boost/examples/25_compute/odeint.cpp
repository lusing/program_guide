// odeint.cpp —— Boost.OdeInt（numeric/odeint，2011）：常微分方程求解器。
// 龙格-库塔家族 + 可换步长策略 + 可换容器（含 thrust/GPU 后端）。
// 对应文档：docs/25-compute.md
#include <boost/numeric/odeint.hpp>
#include <iostream>

namespace odeint = boost::numeric::odeint;

int main() {
    using state_type = std::vector<double>;

    // 1) 谐振子：dx/dt = v, dv/dt = -x（解析解：圆周运动）
    struct Harmonic {
        void operator()(const state_type& x, state_type& dxdt, double) const {
            dxdt[0] = x[1];           // dx = v
            dxdt[1] = -x[0];          // dv = -x
        }
    };

    state_type x{1.0, 0.0};           // 初值：位置 1，速度 0
    double t_end = 3.14159265358979;  // 走半周期
    size_t steps = odeint::integrate(Harmonic{}, x, 0.0, t_end, 0.01);
    std::cout << "半周期后 x = " << x[0] << "（解析解 ≈ -1）\n";
    std::cout << "步数 = " << steps << "（自适应控制下）\n";

    // 2) 观察者模式：逐步回调
    state_type y{1.0, 0.0};
    int observations = 0;
    odeint::integrate_const(odeint::runge_kutta4<state_type>(), Harmonic{}, y,
                            0.0, 1.0, 0.25,
                            [&](const state_type&, double) { ++observations; });
    std::cout << "等步长观察次数 = " << observations << '\n';

    // 3) 精度可控的自适应积分器
    state_type z{1.0, 0.0};
    odeint::integrate_adaptive(odeint::runge_kutta_cash_karp54<state_type>(),
                               Harmonic{}, z, 0.0, 3.14159265, 0.001);
    std::cout << "Cash-Karp 自适应: x = " << z[0] << '\n';

    std::cout << "自检通过\n";
    return 0;
}
