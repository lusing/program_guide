// 性能分析
cl::Event kernelEvent;
queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize,
                           nullptr, &kernelEvent);
kernelEvent.wait();

// 获取事件时间
cl_ulong start = kernelEvent.getProfilingInfo<CL_PROFILING_COMMAND_START>();
cl_ulong end = kernelEvent.getProfilingInfo<CL_PROFILING_COMMAND_END>();
double duration_ns = end - start;
double duration_ms = duration_ns * 1e-6;

std::cout << "Kernel execution time: " << duration_ms << " ms" << std::endl;
