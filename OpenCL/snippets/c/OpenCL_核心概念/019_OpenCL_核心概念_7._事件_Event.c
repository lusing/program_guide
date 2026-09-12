// 创建事件
cl_event event;
clEnqueueNDRangeKernel(queue, kernel, workDim, NULL, globalWorkSize,
                       localWorkSize, 0, NULL, &event);

// 等待事件完成
clWaitForEvents(1, &event);

// 获取事件信息
cl_ulong startTime, endTime;
clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(startTime), &startTime, NULL);
clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END, sizeof(endTime), &endTime, NULL);
double duration = (endTime - startTime) * 1e-9; // 纳秒转秒

// 释放事件
clReleaseEvent(event);
