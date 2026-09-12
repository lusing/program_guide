// 在多个设备上并行处理
cl_uint numDevices;
clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, NULL, &numDevices);
cl_device_id* devices = (cl_device_id*)malloc(numDevices * sizeof(cl_device_id));
clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, numDevices, devices, NULL);

// 为每个设备创建上下文和队列
cl_context* contexts = (cl_context*)malloc(numDevices * sizeof(cl_context));
cl_command_queue* queues = (cl_command_queue*)malloc(numDevices * sizeof(cl_command_queue));

for (cl_uint i = 0; i < numDevices; i++) {
    contexts[i] = clCreateContext(NULL, 1, &devices[i], NULL, NULL, NULL);
    cl_queue_properties props[] = { 0 };  // 属性数组必须以 0 结尾
    queues[i] = clCreateCommandQueueWithProperties(contexts[i], devices[i], props, NULL);
}

// 分割数据并分配给不同设备
int itemsPerDevice = totalCount / numDevices;
for (cl_uint i = 0; i < numDevices; i++) {
    int offset = i * itemsPerDevice;
    int count = (i == numDevices - 1) ? totalCount - offset : itemsPerDevice;

    // 为每个设备创建独立的内核并执行
    cl_mem buffer = clCreateBuffer(contexts[i], CL_MEM_READ_WRITE,
                                   count * sizeof(float), NULL, NULL);
    clSetKernelArg(kernel, 0, sizeof(cl_mem), &buffer);
    // ...
}
