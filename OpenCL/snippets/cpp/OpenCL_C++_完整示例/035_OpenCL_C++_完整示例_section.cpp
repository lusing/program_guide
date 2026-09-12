#include <CL/cl2.hpp>
#include <iostream>
#include <vector>
#include <exception>

int main() {
    try {
        // 1. 获取平台和设备
        std::vector<cl::Platform> platforms;
        cl::Platform::get(&platforms);

        if (platforms.empty()) {
            std::cerr << "No OpenCL platforms found!" << std::endl;
            return -1;
        }

        cl::Platform platform = platforms[0];
        std::cout << "Using Platform: " << platform.getInfo<CL_PLATFORM_NAME>() << std::endl;

        std::vector<cl::Device> devices;
        platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);

        if (devices.empty()) {
            // 回退到 CPU
            platform.getDevices(CL_DEVICE_TYPE_CPU, &devices);
        }

        cl::Device device = devices[0];
        std::cout << "Using Device: " << device.getInfo<CL_DEVICE_NAME>() << std::endl;

        // 2. 创建上下文和命令队列
        cl::Context context(device);
        cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);

        // 3. 准备数据
        const size_t N = 1024;
        std::vector<float> hostA(N), hostB(N), hostC(N);

        for (size_t i = 0; i < N; i++) {
            hostA[i] = static_cast<float>(i);
            hostB[i] = static_cast<float>(i * 2.0f);
        }

        // 4. 创建缓冲区
        cl::Buffer bufferA(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                           N * sizeof(float), hostA.data());
        cl::Buffer bufferB(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                           N * sizeof(float), hostB.data());
        cl::Buffer bufferC(context, CL_MEM_WRITE_ONLY, N * sizeof(float));

        // 5. 创建程序和内核
        std::string kernelSource = R"(
            __kernel void vector_add(__global const float* a,
                                     __global const float* b,
                                     __global float* c) {
                int idx = get_global_id(0);
                c[idx] = a[idx] + b[idx];
            }
        )";

        cl::Program::Sources sources;
        sources.push_back({kernelSource.c_str(), kernelSource.length()});
        cl::Program program(context, sources);

        program.build(device);

        cl::Kernel kernel(program, "vector_add");

        // 6. 设置内核参数
        kernel.setArg(0, bufferA);
        kernel.setArg(1, bufferB);
        kernel.setArg(2, bufferC);

        // 7. 执行内核
        cl::Event event;
        queue.enqueueNDRangeKernel(kernel, cl::NullRange,
                                   cl::NDRange(N), cl::NDRange(256),
                                   nullptr, &event);

        event.wait();

        // 8. 获取结果
        queue.enqueueReadBuffer(bufferC, CL_TRUE, 0, N * sizeof(float), hostC.data());

        // 9. 验证结果
        int success = 1;
        for (size_t i = 0; i < N; i++) {
            if (hostC[i] != hostA[i] + hostB[i]) {
                success = 0;
                std::cerr << "Mismatch at index " << i << ": "
                          << hostA[i] << " + " << hostB[i]
                          << " != " << hostC[i] << std::endl;
                break;
            }
        }

        if (success) {
            std::cout << "Test PASSED!" << std::endl;
        }

        // 10. 性能分析
        cl_ulong start = event.getProfilingInfo<CL_PROFILING_COMMAND_START>();
        cl_ulong end = event.getProfilingInfo<CL_PROFILING_COMMAND_END>();
        double duration_ms = (end - start) * 1e-6;

        std::cout << "Execution time: " << duration_ms << " ms" << std::endl;

    } catch (cl::Error& err) {
        std::cerr << "OpenCL Error: " << err.what()
                  << " (Code: " << err.err() << ")" << std::endl;
        return -1;
    } catch (std::exception& err) {
        std::cerr << "Exception: " << err.what() << std::endl;
        return -1;
    }

    return 0;
}
