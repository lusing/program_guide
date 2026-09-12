// 创建上下文
cl_context context = clCreateContext(NULL, numDevices, devices, NULL, NULL, &err);

// 创建带属性的上下文
cl_context_properties props[] = {
    CL_CONTEXT_PLATFORM, (cl_context_properties)platform,
    0
};
cl_context context = clCreateContext(props, numDevices, devices, NULL, NULL, &err);

// 释放上下文
clReleaseContext(context);
