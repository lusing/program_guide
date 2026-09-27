/* 17_cpp_vecadd —— C++ 绑定（Khronos OpenCL-CLHPP 的 opencl.hpp）
 *
 * 头文件取自 examples/common/CL/opencl.hpp（vendor 进仓库，main 分支），
 * 教学要点：
 *  - RAII：Context/CommandQueue/Buffer/Kernel/Event 全部析构自动释放
 *  - 异常：cl::Error 携带 err() 错误码；开 CL_HPP_ENABLE_EXCEPTIONS 即可用
 *  - 模板化查询：device.getInfo<CL_DEVICE_NAME>()
 *  - vector<string> 程序源、Buffer 构造、NDRange、profiling
 * 与 C API 的逐条对照见 docs/17-cpp-bindings.md。
 */
#define CL_HPP_TARGET_OPENCL_VERSION 300
#define CL_HPP_MINIMUM_OPENCL_VERSION 120
#define CL_HPP_ENABLE_EXCEPTIONS
#include <CL/opencl.hpp>

#include <cmath>
#include <cstdio>
#include <string>
#include <vector>

static const char* K_SRC = R"CLC(
__kernel void saxpy(__global const float* x,
                    __global float* y,
                    const float a) {
    int i = get_global_id(0);
    if (i < 65536) y[i] = a * x[i] + y[i];
}
)CLC";

int main() {
    try {
        /* 平台/设备 */
        std::vector<cl::Platform> platforms;
        cl::Platform::get(&platforms);
        if (platforms.empty()) { fprintf(stderr, "no platform\n"); return 1; }

        cl::Device device;
        bool found = false;
        for (auto& p : platforms) {
            std::vector<cl::Device> devs;
            p.getDevices(CL_DEVICE_TYPE_GPU, &devs);
            if (!devs.empty()) { device = devs.front(); found = true; break; }
        }
        if (!found) {
            std::vector<cl::Device> devs;
            platforms.front().getDevices(CL_DEVICE_TYPE_DEFAULT, &devs);
            if (devs.empty()) { fprintf(stderr, "no device\n"); return 1; }
            device = devs.front();
        }
        std::printf("device : %s (%s)\n",
                    device.getInfo<CL_DEVICE_NAME>().c_str(),
                    device.getInfo<CL_DEVICE_VERSION>().c_str());

        /* 上下文 + 剖析队列（一行顶 C API 十行） */
        cl::Context context(device);
        cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);

        /* 程序（vector<string> 源；构造即 clCreateProgramWithSource） */
        cl::Program program(context, std::vector<std::string>{ K_SRC });
        try {
            program.build(device);
        } catch (const cl::Error&) {
            std::string log = program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device);
            fprintf(stderr, "build log:\n%s\n", log.c_str());
            throw;
        }

        cl::Kernel kernel(program, "saxpy");

        /* 数据 + 缓冲区 */
        const size_t N = 65536;
        std::vector<float> hx(N), hy(N), href(N);
        for (size_t i = 0; i < N; i++) {
            hx[i] = (float)(i % 1024) * 0.5f;
            hy[i] = (float)(i % 512) * -0.25f;
            href[i] = 3.0f * hx[i] + hy[i];
        }
        cl::Buffer bx(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                      N * sizeof(float), hx.data());
        cl::Buffer by(context, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                      N * sizeof(float), hy.data());

        kernel.setArg(0, bx);
        kernel.setArg(1, by);
        kernel.setArg(2, 3.0f);

        /* 执行 + 事件剖析 */
        cl::Event ev;
        queue.enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(N), cl::NullRange,
                                   nullptr, &ev);
        std::vector<float> hout(N);
        queue.enqueueReadBuffer(by, CL_TRUE, 0, N * sizeof(float), hout.data());

        cl_ulong t0 = ev.getProfilingInfo<CL_PROFILING_COMMAND_START>();
        cl_ulong t1 = ev.getProfilingInfo<CL_PROFILING_COMMAND_END>();
        std::printf("kernel : %.3f ms (profiling)\n", (double)(t1 - t0) / 1e6);

        int bad = 0;
        for (size_t i = 0; i < N; i++)
            if (std::fabs(hout[i] - href[i]) > 1e-4f) { bad++; break; }
        std::printf("saxpy  : %s (spot y[7]=%.2f expect %.2f)\n",
                    bad ? "WRONG" : "verified", hout[7], href[7]);
        if (bad) return 1;

        /* 子缓冲区（C++ 形态）+ map 辅助 */
        cl_buffer_region region{ 0, N / 2 * sizeof(float) };
        cl::Buffer bsub = by.createSubBuffer(CL_MEM_READ_WRITE,
                                             CL_BUFFER_CREATE_TYPE_REGION, &region);
        float* mapped = (float*)queue.enqueueMapBuffer(bsub, CL_TRUE, CL_MAP_READ,
                                                       0, N / 2 * sizeof(float));
        std::printf("map    : first %d values match (%.2f)\n", (int)(N / 2), mapped[0]);
        float expect0 = 3.0f * hx[0] + (float)((0 % 512)) * -0.25f;
        if (std::fabs(mapped[0] - expect0) > 1e-4f) return 1;
        queue.enqueueUnmapMemObject(bsub, mapped);
    } catch (const cl::Error& e) {
        fprintf(stderr, "cl::Error %s (%d) at %s\n", e.what(), e.err(), e.what());
        return 1;
    } catch (const std::exception& e) {
        fprintf(stderr, "std::exception: %s\n", e.what());
        return 1;
    }

    std::printf("17 cpp_vecadd PASS\n");
    return 0;
}
