// compute.cpp —— Boost.Compute（2014）：OpenCL 的 C++ 高层封装。
// 本机实测：CUDA 13.3 的 OpenCL 头 + RTX 3060。
// 对应文档：docs/25-compute.md
// 实测坑：总头 boost/compute.hpp 会拉进 random_shuffle.hpp（用了
// C++17 已删除的 std::random_shuffle，c++latest 直接编不过）——
// 用细分头绕开
#include <boost/compute/system.hpp>
#include <boost/compute/context.hpp>
#include <boost/compute/command_queue.hpp>
#include <boost/compute/container/vector.hpp>
#include <boost/compute/algorithm/copy.hpp>
#include <boost/compute/algorithm/transform.hpp>
#include <boost/compute/algorithm/accumulate.hpp>
#include <boost/compute/algorithm/sort.hpp>
#include <boost/compute/lambda.hpp>
#include <iostream>
#include <vector>

namespace compute = boost::compute;

int main() {
    // 1) 找设备（GPU 优先）
    auto device = compute::system::default_device();
    std::cout << "设备 = " << device.name() << '\n';
    std::cout << "计算单元 = " << device.compute_units() << " 个\n";

    compute::context ctx(device);
    compute::command_queue queue(ctx, device);

    // 2) 主机数据 → 显存
    std::vector<float> host{1.0f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f};
    compute::vector<float> gpu(host.size(), ctx);
    compute::copy(host.begin(), host.end(), gpu.begin(), queue);

    // 3) GPU 内核：每个元素平方
    using compute::lambda::_1;
    compute::transform(gpu.begin(), gpu.end(), gpu.begin(), _1 * _1, queue);

    // 4) 归约求和（GPU 上算完再拷回）
    float sum = compute::accumulate(gpu.begin(), gpu.end(), 0.0f, queue);
    std::cout << "平方和 = " << sum << "（1²+2²+…+6² = 91）\n";

    // 5) STL 式算法在 GPU 上跑（sort）
    compute::vector<float> unsorted(host.size(), ctx);
    std::vector<float> h2{5.0f, 1.0f, 4.0f, 2.0f, 6.0f, 3.0f};
    compute::copy(h2.begin(), h2.end(), unsorted.begin(), queue);
    compute::sort(unsorted.begin(), unsorted.end(), queue);
    std::vector<float> sorted_back(host.size());
    compute::copy(unsorted.begin(), unsorted.end(), sorted_back.begin(), queue);
    std::cout << "GPU 排序首尾 = " << sorted_back.front() << '/' << sorted_back.back() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
