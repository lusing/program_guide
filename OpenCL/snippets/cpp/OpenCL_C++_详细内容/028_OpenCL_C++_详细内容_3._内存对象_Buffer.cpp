// 创建缓冲区
std::vector<float> data(1024);
cl::Buffer buffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                  data.size() * sizeof(float), data.data());

// 创建子缓冲区（需要使用 buffer_region 结构）
cl_buffer_region region;
region.origin = offset;
region.size = size;
cl_int err;
cl::Buffer subBuffer(buffer.createSubBuffer(CL_MEM_READ_ONLY,
                                            CL_BUFFER_CREATE_TYPE_REGION,
                                            &region, &err));

// 使用 map 函数（RAII）
{
    cl::Buffer deviceBuffer(context, CL_MEM_READ_WRITE, size * sizeof(float));

    // 写入数据
    queue.enqueueWriteBuffer(deviceBuffer, CL_TRUE, 0, size * sizeof(float), hostData);

    // 读取数据
    queue.enqueueReadBuffer(deviceBuffer, CL_TRUE, 0, size * sizeof(float), hostResult);
}

// 使用 map
{
    cl::Buffer buffer(context, CL_MEM_WRITE_ONLY, size * sizeof(float));
    auto mapped_ptr = queue.enqueueMapBuffer(buffer, CL_TRUE, CL_MAP_WRITE, 0, size * sizeof(float));

    // 使用 mapped_ptr
    float* data = static_cast<float*>(mapped_ptr);
    for (size_t i = 0; i < size; i++) {
        data[i] = static_cast<float>(i);
    }

    // 解映射
    queue.enqueueUnmapMemObject(buffer, mapped_ptr);
}
