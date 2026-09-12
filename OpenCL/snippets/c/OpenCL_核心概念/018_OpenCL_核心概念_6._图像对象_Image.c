// 创建 2D 图像
cl_image_format format = { CL_RGBA, CL_FLOAT };
cl_image_desc desc = { CL_MEM_OBJECT_IMAGE2D, width, height, 0, 0, 0, 0, 0, 0 };
cl_mem image = clCreateImage(context, CL_MEM_READ_ONLY, &format, &desc, NULL, &err);

// 释放图像
clReleaseMemObject(image);
