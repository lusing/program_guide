// 使用事件管理异步操作
cl_event writeEvent, kernelEvent, readEvent;

// 异步写入数据
clEnqueueWriteBuffer(queue, buffer, CL_FALSE, 0, size, hostData,
                     0, NULL, &writeEvent);

// 依赖写入完成的内核执行
clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize,
                       &localSize, 1, &writeEvent, &kernelEvent);

// 依赖内核完成的读取
clEnqueueReadBuffer(queue, buffer, CL_FALSE, 0, size, hostResult,
                    1, &kernelEvent, &readEvent);

// 等待所有操作完成
clWaitForEvents(1, &readEvent);

// 清理
clReleaseEvent(writeEvent);
clReleaseEvent(kernelEvent);
clReleaseEvent(readEvent);
