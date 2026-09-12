// 创建 2D 图像
cl::Image2D image2D(context, CL_MEM_READ_ONLY,
                    cl::ImageFormat(CL_RGBA, CL_FLOAT),
                    width, height, 0, nullptr);

// 创建 3D 图像
cl::Image3D image3D(context, CL_MEM_READ_WRITE,
                    cl::ImageFormat(CL_RGBA, CL_UNORM_INT8),
                    width, height, depth, 0, 0, nullptr);

// 使用图像读写
queue.enqueueWriteImage(image2D, CL_TRUE, origin, region,
                        row_pitch, slice_pitch, hostData);
