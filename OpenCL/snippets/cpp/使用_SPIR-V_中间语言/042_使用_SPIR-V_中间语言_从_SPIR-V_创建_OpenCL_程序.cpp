#include <CL/cl2.hpp>
#include <fstream>
#include <vector>
#include <iostream>

cl::Program createProgramFromSPIRV(const cl::Context& context,
                                    const cl::Device& device,
                                    const std::string& spvFile) {
    // 读取 SPIR-V 文件
    std::ifstream file(spvFile, std::ios::binary | std::ios::ate);
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open SPIR-V file: " + spvFile);
    }

    size_t size = file.tellg();
    file.seekg(0, std::ios::beg);

    std::vector<char> spvBinary(size);
    file.read(spvBinary.data(), size);
    file.close();

    // 检查设备是否支持 IL
    std::string ilVersion;
    device.getInfo(CL_DEVICE_IL_VERSION, &ilVersion);
    if (ilVersion.empty()) {
        throw std::runtime_error("Device does not support IL programs");
    }

    std::cout << "Device IL Version: " << ilVersion << std::endl;

    // 从 IL 创建程序
    cl_int err;
    cl::Program program = cl::Program(context, spvBinary, true, &err);

    if (err != CL_SUCCESS) {
        throw cl::Error(err, "Failed to create program from IL");
    }

    // 构建程序
    program.build(device);

    return program;
}

// 完整使用示例
int main() {
    try {
        // 获取平台和设备
        std::vector<cl::Platform> platforms;
        cl::Platform::get(&platforms);
        cl::Platform platform = platforms[0];

        std::vector<cl::Device> devices;
        platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);
        cl::Device device = devices[0];

        cl::Context context(device);

        // 从 SPIR-V 加载程序
        cl::Program program = createProgramFromSPIRV(context, device, "kernel.spv");

        // 创建内核
        cl::Kernel kernel(program, "my_kernel");

        std::cout << "SPIR-V program loaded successfully!" << std::endl;

    } catch (cl::Error& err) {
        std::cerr << "OpenCL Error: " << err.what() << " (" << err.err() << ")" << std::endl;
        return -1;
    }

    return 0;
}
