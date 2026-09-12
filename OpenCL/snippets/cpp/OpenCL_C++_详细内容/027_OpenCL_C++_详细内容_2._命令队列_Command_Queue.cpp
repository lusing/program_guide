// 创建命令队列
cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);

// 使用 lambda 的事件回调
cl::Event event;
queue.enqueueNDRangeKernel(kernel, cl::NullRange, cl::NDRange(1024), cl::NullRange,
                           nullptr, &event);

event.setCallback(CL_COMPLETE, [](cl_event, cl_int, void*) {
    std::cout << "Kernel execution completed!" << std::endl;
}, nullptr);
