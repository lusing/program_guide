// NDRange 执行
cl::NDRange globalSize(1024);
cl::NDRange localSize(256);

queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize);

// 带事件的执行
cl::Event event;
queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize,
                           nullptr, &event);
event.wait();

// 使用 lambda 的事件回调
event.setCallback(CL_COMPLETE, [](cl_event, cl_int status, void* data) {
    if (status == CL_SUCCESS) {
        std::cout << "Kernel completed successfully!" << std::endl;
    }
}, nullptr);
