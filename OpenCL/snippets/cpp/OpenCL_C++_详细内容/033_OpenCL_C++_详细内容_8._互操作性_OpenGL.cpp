#include <GL/gl.h>
#include <CL/cl_gl.h>

// 从 OpenGL 纹理创建 OpenCL 图像
GLuint texture;
glGenTextures(1, &texture);
// ... OpenGL 纹理创建代码 ...

cl_int err;
cl_mem clImage = clCreateFromGLTexture2D(context.get(), CL_MEM_READ_WRITE,
                                         GL_TEXTURE_2D, 0, texture, &err);
if (err != CL_SUCCESS) {
    std::cerr << "Failed to create OpenCL image from GL texture" << std::endl;
    return -1;
}

// 包装为 C++ 对象（注意：需要手动管理 cl_mem 的生命周期）
cl::Image2D glImage(clImage, true);  // true 表示接管所有权

// 在 OpenCL 和 OpenGL 之间共享数据
std::vector<cl::Memory> glObjects;
glObjects.push_back(glImage);
queue.enqueueAcquireGLObjects(&glObjects);
queue.enqueueNDRangeKernel(kernel, cl::NullRange, globalSize, localSize);
queue.enqueueReleaseGLObjects(&glObjects);
queue.finish();
