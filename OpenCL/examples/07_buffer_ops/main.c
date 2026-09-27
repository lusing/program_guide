/* 07_buffer_ops —— 缓冲区操作全家桶：创建标志、读写、映射、拷贝、填充、子缓冲、矩形读写
 *
 * 每个 API 的语义用数值校验坐实：
 *  - CL_MEM_COPY_HOST_PTR vs CL_MEM_USE_HOST_PTR vs 先建后写
 *  - 阻塞/非阻塞读写（非阻塞 + 事件等待）
 *  - map/unmap（零拷贝式访问）
 *  - clEnqueueCopyBuffer / clEnqueueFillBuffer
 *  - 子缓冲区（对齐要求 + CL_MEM_OFFSET/SIZE 查询）
 *  - clEnqueueRead/WriteBufferRect（2D 面片在带行距的主机内存与线性设备内存间搬运）
 */
#include "cl_utils.h"

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);
    cl_int err;
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
    CL_CHECK(err);
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, NULL, &err);
    CL_CHECK(err);

    const size_t N = 64;
    float hinit[64], hout[64];

    /* --- 1) 三种初始化姿势 --- */
    for (size_t i = 0; i < N; i++) hinit[i] = (float)i;

    /* a) COPY_HOST_PTR：驱动复制一份，主机内存此后随便改 */
    float tmp[64];
    memcpy(tmp, hinit, sizeof(tmp));
    cl_mem bc = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                               sizeof(tmp), tmp, &err);
    CL_CHECK(err);
    tmp[0] = -999.0f;                       /* 改主机副本不影响设备 */
    memset(hout, 0, sizeof(hout));
    CL_CHECK(clEnqueueReadBuffer(q, bc, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
    CHECK(hout[0] == 0.0f, "COPY_HOST_PTR snapshot semantics");

    /* b) USE_HOST_PTR：驱动尽量直接用这块主机内存（缓存一致性由驱动负责）
          —— 对齐/性能有讲究，教学里少用 */
    cl_mem bu = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR,
                               sizeof(tmp), tmp, &err);
    CL_CHECK(err);
    cl_mem_flags flags = 0; size_t bsize = 0;
    CL_CHECK(clGetMemObjectInfo(bu, CL_MEM_FLAGS, sizeof(flags), &flags, NULL));
    CL_CHECK(clGetMemObjectInfo(bu, CL_MEM_SIZE, sizeof(bsize), &bsize, NULL));
    CHECK(bsize == sizeof(tmp) && (flags & CL_MEM_USE_HOST_PTR), "mem info of USE_HOST_PTR");

    /* --- 2) 非阻塞写 + 事件等待 --- */
    float hsrc[64];
    for (size_t i = 0; i < N; i++) hsrc[i] = (float)(i * 10);
    cl_event ev = NULL;
    CL_CHECK(clEnqueueWriteBuffer(q, bu, CL_FALSE, 0, sizeof(hsrc), hsrc, 0, NULL, &ev));
    CL_CHECK(clWaitForEvents(1, &ev));
    clReleaseEvent(ev);
    memset(hout, 0, sizeof(hout));
    CL_CHECK(clEnqueueReadBuffer(q, bu, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
    CHECK(hout[1] == 10.0f && hout[63] == 630.0f, "async write via event");

    /* --- 3) map/unmap --- */
    float* mapped = (float*)clEnqueueMapBuffer(q, bc, CL_TRUE, CL_MAP_WRITE_INVALIDATE_REGION,
                                               0, sizeof(hinit), 0, NULL, NULL, &err);
    CL_CHECK(err);
    CHECK(mapped != NULL, "map");
    for (size_t i = 0; i < N; i++) mapped[i] = hinit[i] * 2.0f;
    CL_CHECK(clEnqueueUnmapMemObject(q, bc, mapped, 0, NULL, NULL));
    memset(hout, 0, sizeof(hout));
    CL_CHECK(clEnqueueReadBuffer(q, bc, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
    CHECK(hout[7] == 14.0f, "map write visible after unmap");

    /* --- 4) copy / fill --- */
    CL_CHECK(clEnqueueCopyBuffer(q, bc, bu, 0, 0, N * sizeof(float), 0, NULL, NULL));
    float pattern = -1.5f;
    CL_CHECK(clEnqueueFillBuffer(q, bc, &pattern, sizeof(pattern),
                                 8 * sizeof(float), 8 * sizeof(float), 0, NULL, NULL));
    CL_CHECK(clEnqueueReadBuffer(q, bc, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
    CHECK(hout[7] == 14.0f && hout[8] == -1.5f && hout[15] == -1.5f && hout[16] == 32.0f,
          "fill pattern covers [8,16)");
    CL_CHECK(clEnqueueReadBuffer(q, bu, CL_TRUE, 0, sizeof(hout), hout, 0, NULL, NULL));
    CHECK(hout[7] == 14.0f, "copyBuffer result");

    /* --- 5) 子缓冲区 --- */
    /* 子缓冲区 origin 需要对齐 CL_DEVICE_MEM_BASE_ADDR_ALIGN（位为单位）。
       NVIDIA 一般 4096B（=32768 位）；float[64] 只有 256B，所以把缓冲区做大一点。 */
    cl_uint align_bits = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MEM_BASE_ADDR_ALIGN, sizeof(align_bits), &align_bits, NULL));
    size_t align_bytes = (size_t)align_bits / 8;
    printf("mem base addr align: %u bits (%zu bytes)\n", align_bits, align_bytes);

    const size_t BIG = 4096;                 /* 16KB 的 float 缓冲 */
    float* hbig = (float*)malloc(BIG * sizeof(float));
    for (size_t i = 0; i < BIG; i++) hbig[i] = (float)i;
    cl_mem bbig = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                 BIG * sizeof(float), hbig, &err);
    CL_CHECK(err);
    cl_buffer_region region;
    region.origin = align_bytes;             /* 对齐的偏移 */
    region.size = 1024;
    cl_mem bsub = clCreateSubBuffer(bbig, CL_MEM_READ_WRITE,
                                    CL_BUFFER_CREATE_TYPE_REGION, &region, &err);
    if (err == CL_MISALIGNED_SUB_BUFFER_OFFSET) {
        printf("sub-buffer misaligned (align=%zu), retry with origin=0\n", align_bytes);
        region.origin = 0;
        bsub = clCreateSubBuffer(bbig, CL_MEM_READ_WRITE,
                                 CL_BUFFER_CREATE_TYPE_REGION, &region, &err);
    }
    CL_CHECK(err);
    size_t soff = 1, ssize = 1;
    CL_CHECK(clGetMemObjectInfo(bsub, CL_MEM_OFFSET, sizeof(soff), &soff, NULL));
    CL_CHECK(clGetMemObjectInfo(bsub, CL_MEM_SIZE, sizeof(ssize), &ssize, NULL));
    printf("sub-buffer: offset=%zu size=%zu (region.origin=%zu)\n", soff, ssize, region.origin);

    /* 通过子缓冲区写，读父缓冲区验证看到同一块存储 */
    float hsub[256];
    for (int i = 0; i < 256; i++) hsub[i] = 1000.0f + i;
    CL_CHECK(clEnqueueWriteBuffer(q, bsub, CL_TRUE, 0, sizeof(hsub), hsub, 0, NULL, NULL));
    /* 注意：cl_buffer_region.origin 的单位是字节，读父缓冲区时不要重复乘 sizeof；
       且读取长度不能超过目的数组（这里只读前 64 个 float 验证） */
    CL_CHECK(clEnqueueReadBuffer(q, bbig, CL_TRUE, region.origin,
                                 64 * sizeof(float), hout, 0, NULL, NULL));
    CHECK(hout[0] == 1000.0f && hout[63] == 1063.0f, "sub-buffer aliases parent storage");

    /* --- 6) 矩形（2D 面片）读写 --- */
    /* 设备端：线性 8x8 float（64 个）。
       主机端：9x9 带 row_pitch 的外框，只搬中间 8x8。
       ⚠️ 实测大坑：origin 的 y/z 分量单位是“行/片”（会乘以 row/slice pitch），
       不是字节！写成 {0, 36, 0}（字节）会静默读到主机数组越界处，驱动还返回
       CL_SUCCESS——正确写法是 {0, 1, 0} 表示从第 1 行开始。 */
    const size_t W = 8, H = 8, HPITCH = 9;
    float host2d[9 * 9];
    for (size_t y = 0; y < 9; y++)
        for (size_t x = 0; x < 9; x++)
            host2d[y * HPITCH + x] = (float)(y * 100 + x);
    const size_t buf_origin[3] = {0, 0, 0};
    const size_t host_origin[3] = {0, 1, 0};              /* y=1：第 1 行（行单位） */
    const size_t region_sz[3] = {W * sizeof(float), H, 1};
    CL_CHECK(clEnqueueWriteBufferRect(q, bbig, CL_TRUE,
                                      buf_origin, host_origin, region_sz,
                                      W * sizeof(float), 0,          /* 设备端行距=紧凑 */
                                      HPITCH * sizeof(float), 0,      /* 主机端行距 9 floats */
                                      host2d, 0, NULL, NULL));
    /* 设备端第 0 行应等于主机第 1 行：100..107 */
    CL_CHECK(clEnqueueReadBuffer(q, bbig, CL_TRUE, 0, W * sizeof(float), hout, 0, NULL, NULL));
    printf("rect row0: %.0f %.0f ... %.0f\n", hout[0], hout[1], hout[7]);
    CHECK(hout[0] == 100.0f && hout[7] == 107.0f, "BufferRect row 0");
    /* 设备端第 3 行 = 主机第 4 行：400..407 */
    CL_CHECK(clEnqueueReadBuffer(q, bbig, CL_TRUE, 3 * W * sizeof(float), W * sizeof(float), hout, 0, NULL, NULL));
    CHECK(hout[0] == 400.0f && hout[7] == 407.0f, "BufferRect row 3");

    clReleaseMemObject(bsub);
    clReleaseMemObject(bbig);
    clReleaseMemObject(bc);
    clReleaseMemObject(bu);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    free(hbig);
    printf("07 buffer_ops PASS\n");
    return 0;
}
