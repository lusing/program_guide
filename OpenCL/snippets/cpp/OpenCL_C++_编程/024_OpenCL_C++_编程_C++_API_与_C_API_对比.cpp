// C 风格
cl_context context = clCreateContext(...);
clEnqueueNDRangeKernel(queue, kernel, ...);
clReleaseContext(context);

// C++ 风格
cl::Context context(...);
queue.enqueueNDRangeKernel(kernel, ...);
// 自动析构释放资源
