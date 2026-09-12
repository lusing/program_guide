// 在关键操作后添加同步点（OpenCL 2.0+）
cl_event marker;
clEnqueueMarkerWithWaitList(cmdQueue, 0, NULL, &marker);
clWaitForEvents(1, &marker);
clReleaseEvent(marker);

// 或者使用 OpenCL 1.2 的 clEnqueueMarker（已弃用）
// clEnqueueMarker(cmdQueue, &marker);

// 强制执行所有排队的操作
clFinish(cmdQueue);
