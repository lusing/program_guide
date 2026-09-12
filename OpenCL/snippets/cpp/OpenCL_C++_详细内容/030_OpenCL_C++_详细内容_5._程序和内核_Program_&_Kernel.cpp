// 从源码创建程序
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

// 编译程序
program.build();

// 创建内核
cl::Kernel kernel(program, "vector_add");

// 设置内核参数
kernel.setArg(0, bufferA);
kernel.setArg(1, bufferB);
kernel.setArg(2, bufferC);

// 使用模板设置参数
cl::Kernel vectorAdd(program, "vector_add");
vectorAdd.setArg<cl::Buffer>(0, bufferA);
vectorAdd.setArg<cl::Buffer>(1, bufferB);
vectorAdd.setArg<cl::Buffer>(2, bufferC);
