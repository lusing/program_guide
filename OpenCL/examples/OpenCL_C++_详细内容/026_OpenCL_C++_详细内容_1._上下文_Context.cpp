#define CL_HPP_ENABLE_EXCEPTIONS
#define CL_HPP_TARGET_OPENCL_VERSION 120
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#include <CL/cl.hpp>
#include <iostream>
#include <vector>

int main() {
    try {
        // 获取平台
        std::vector<cl::Platform> platforms;
        cl::Platform::get(&platforms);

        if (platforms.empty()) {
            std::cerr << "No OpenCL platforms found!" << std::endl;
            return -1;
        }

        // 选择第一个平台
        cl::Platform platform = platforms[0];
        std::cout << "Platform: " << platform.getInfo<CL_PLATFORM_NAME>() << std::endl;

        // 创建上下文
        std::vector<cl::Device> devices;
        platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);

        cl::Context context(devices);

        // 获取设备信息
        for (const auto& device : devices) {
            std::cout << "Device: " << device.getInfo<CL_DEVICE_NAME>() << std::endl;
            std::cout << "Max Compute Units: "
                      << device.getInfo<CL_DEVICE_MAX_COMPUTE_UNITS>() << std::endl;
        }
    } catch (cl::Error& err) {
        std::cerr << "OpenCL Error: " << err.what() << std::endl;
        return -1;
    }

    return 0;
}
