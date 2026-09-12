// 创建命令队列（OpenCL 1.x 和 2.x）
// 注意：此函数在 OpenCL 3.0 中被移除，仅用于向后兼容
cl_command_queue queue = clCreateCommandQueue(context, device, 0, &err);

// 创建命令队列（OpenCL 2.0+ 推荐，OpenCL 3.0 必需）
cl_queue_properties props[] = { CL_QUEUE_PROPERTIES, 0, 0 };
cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, props, &err);

// 释放命令队列
clReleaseCommandQueue(queue);
