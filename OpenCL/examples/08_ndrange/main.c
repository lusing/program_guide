/* 08_ndrange —— 执行模型：work-item / work-group / NDRange / global offset
 *
 * 三个内核分别坐实：
 *  A) 2D 网格里 get_global_id/get_local_id/get_group_id/get_num_groups 的关系
 *     （gid = group_id * local_size + local_id；gsize = num_groups * local_size）
 *  B) global offset：NDRange 带偏移启动时 get_global_offset 的值与 gid 的起点
 *  C) 边界守卫模式：global=12、local=4、逻辑 N=10 —— 越界的 2 个 item 必须
 *     被 `if (i < n)` 挡住，不能写 output（用哨兵值验证）
 */
#include "cl_utils.h"

static const char* K_SRC =
/* A: 每个工作项把自己的坐标元组写进 out */
"__kernel void coords(__global int* out, int w) {\n"
"    int gx = get_global_id(0), gy = get_global_id(1);\n"
"    int lx = get_local_id(0),  ly = get_local_id(1);\n"
"    int px = get_group_id(0),  py = get_group_id(1);\n"
"    int nx = get_num_groups(0), ny = get_num_groups(1);\n"
"    int sx = get_local_size(0), sy = get_local_size(1);\n"
"    int i = gy * w + gx;\n"
"    out[i*7+0]=gx; out[i*7+1]=gy; out[i*7+2]=lx; out[i*7+3]=ly;\n"
"    out[i*7+4]=px; out[i*7+5]=py; out[i*7+6]=nx*10+ny;\n"
"    (void)sx; (void)sy;\n"
"}\n"
/* B: 全局偏移 */
"__kernel void offset_probe(__global int* out, int w) {\n"
"    int gx = get_global_id(0), gy = get_global_id(1);\n"
"    int ox = get_global_offset(0), oy = get_global_offset(1);\n"
"    int lx = get_local_id(0), ly = get_local_id(1);\n"
"    int i = (gy - oy) * w + (gx - ox);\n"
"    out[i*4+0]=ox; out[i*4+1]=oy; out[i*4+2]=gx; out[i*4+3]=gy;\n"
"    (void)lx; (void)ly;\n"
"}\n"
/* C: 边界守卫 */
"__kernel void guarded(__global int* out, int n) {\n"
"    int i = get_global_id(0);\n"
"    if (i < n) out[i] = i * i;\n"
"}\n";

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
    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);

    /* ---- A: 4x4 网格，2x2 工作组 ---- */
    {
        cl_kernel k = clCreateKernel(prog, "coords", &err);
        CL_CHECK(err);
        const int W = 4, H = 4;
        cl_int hw = W;
        cl_mem b = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, W * H * 7 * sizeof(cl_int), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &b));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_int), &hw));
        size_t global[2] = {4, 4}, local[2] = {2, 2};
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, NULL, global, local, 0, NULL, NULL));

        cl_int* h = (cl_int*)malloc(W * H * 7 * sizeof(cl_int));
        CL_CHECK(clEnqueueReadBuffer(q, b, CL_TRUE, 0, W * H * 7 * sizeof(cl_int), h, 0, NULL, NULL));
        int ok = 1;
        for (int y = 0; y < H && ok; y++)
            for (int x = 0; x < W && ok; x++) {
                cl_int* c = h + (y * W + x) * 7;
                if (c[0] != x || c[1] != y || c[2] != x % 2 || c[3] != y % 2 ||
                    c[4] != x / 2 || c[5] != y / 2 || c[6] != 2 * 10 + 2)
                    ok = 0;
            }
        printf("coords  : gid/lid/group/num_groups %s\n", ok ? "consistent" : "WRONG");
        CHECK(ok, "coordinate relations");
        clReleaseMemObject(b);
        clReleaseKernel(k);
        free(h);
    }

    /* ---- B: 偏移 (1,2)，网格 3x2，local 3x2（无偏移坐标系用于索引） ---- */
    {
        cl_kernel k = clCreateKernel(prog, "offset_probe", &err);
        CL_CHECK(err);
        const int W = 3, H = 2;
        cl_int hw = W;
        cl_mem b = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, W * H * 4 * sizeof(cl_int), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &b));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_int), &hw));
        size_t global[2] = {3, 2}, local[2] = {3, 2}, offset[2] = {1, 2};
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 2, offset, global, local, 0, NULL, NULL));
        cl_int* h = (cl_int*)malloc(W * H * 4 * sizeof(cl_int));
        CL_CHECK(clEnqueueReadBuffer(q, b, CL_TRUE, 0, W * H * 4 * sizeof(cl_int), h, 0, NULL, NULL));
        int ok = 1;
        for (int y = 0; y < H && ok; y++)
            for (int x = 0; x < W && ok; x++) {
                cl_int* c = h + (y * W + x) * 4;
                if (c[0] != 1 || c[1] != 2 || c[2] != 1 + x || c[3] != 2 + y) ok = 0;
            }
        printf("offset : get_global_offset=(1,2), gid starts at (1,2) %s\n", ok ? "verified" : "WRONG");
        CHECK(ok, "global offset semantics");
        clReleaseMemObject(b);
        clReleaseKernel(k);
        free(h);
    }

    /* ---- C: 边界守卫（逻辑 N=10，实际启动 12 个 item） ---- */
    {
        cl_kernel k = clCreateKernel(prog, "guarded", &err);
        CL_CHECK(err);
        cl_int n = 10;
        cl_mem b = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY | CL_MEM_COPY_HOST_PTR,
                                  12 * sizeof(cl_int),
                                  (cl_int[12]){-7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7}, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &b));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_int), &n));
        size_t global = 12, local = 4;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &global, &local, 0, NULL, NULL));
        cl_int h[12];
        CL_CHECK(clEnqueueReadBuffer(q, b, CL_TRUE, 0, sizeof(h), h, 0, NULL, NULL));
        int ok = 1;
        for (int i = 0; i < 10; i++) if (h[i] != i * i) ok = 0;
        if (h[10] != -7 || h[11] != -7) ok = 0;   /* 越界 item 未写入 */
        printf("guard  : [0..9]=i*i, [10..11] untouched %s\n", ok ? "verified" : "WRONG");
        CHECK(ok, "boundary guard pattern");
        clReleaseMemObject(b);
        clReleaseKernel(k);
    }

    /* ---- D: NULL local size（交给运行时；要求整除或设备支持不规则分组） ---- */
    {
        cl_kernel k = clCreateKernel(prog, "guarded", &err);
        CL_CHECK(err);
        cl_int n = 10;
        cl_mem b = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, 10 * sizeof(cl_int), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &b));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_int), &n));
        size_t global = 16;   /* 16 >= 10，靠 guard 保护 */
        err = clEnqueueNDRangeKernel(q, k, 1, NULL, &global, NULL, 0, NULL, NULL);
        if (err != CL_SUCCESS) {
            printf("local=NULL with global=16 -> %s（该设备要求整除，正常）\n", clu_err_str(err));
        } else {
            cl_int h[10];
            CL_CHECK(clEnqueueReadBuffer(q, b, CL_TRUE, 0, sizeof(h), h, 0, NULL, NULL));
            int ok = 1;
            for (int i = 0; i < 10; i++) if (h[i] != i * i) ok = 0;
            CHECK(ok, "NULL local size path");
            printf("local=NULL : runtime picked a valid grouping\n");
        }
        clReleaseMemObject(b);
        clReleaseKernel(k);
    }

    clReleaseProgram(prog);
    clReleaseCommandQueue(q);
    clReleaseContext(ctx);
    printf("08 ndrange PASS\n");
    return 0;
}
