// 创建缓冲区
cl_mem buffer = clCreateBuffer(context,
                                CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                size * sizeof(float), hostPtr, &err);

// 创建子缓冲区（用于访问缓冲区的一部分）
cl_buffer_region region = { offset * sizeof(float), count * sizeof(float) };
cl_mem subBuffer = clCreateSubBuffer(buffer, CL_MEM_READ_WRITE,
                                     CL_BUFFER_CREATE_TYPE_REGION, &region, &err);

// 释放缓冲区
clReleaseMemObject(buffer);
