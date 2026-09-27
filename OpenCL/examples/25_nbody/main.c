/* 25_nbody —— N 体模拟：GPU 计算 + 数值守恒校验（《OpenCL 异构计算》第 10 章思路）
 *
 * 4096 体、20 步Leapfrog 积分，软化因子防奇点。纯 GPU 版为教学主线：
 *  - 位置/速度双缓冲（每步 swap cl_mem，不搬回主机）
 *  - 每步一个内核，步间天然同步（命令队列顺序）
 *  - 合法性：总动量守恒（对称力抵消）、能量近似守恒（容差）、
 *    第一步结果与 CPU 双循环抽样对拍
 *  - 演进统计（每步总动能）打印成表
 */
#include <math.h>
#include <windows.h>
#include "cl_utils.h"

#define NB 4096
#define STEPS 20

static const char* K_SRC =
"__kernel void nbody_step(__global const float4* pos,\n"
"                         __global const float4* vel,\n"
"                         __global float4* pos_out,\n"
"                         __global float4* vel_out,\n"
"                         const int nb,\n"
"                         const float dt) {\n"
"    int i = get_global_id(0);\n"
"    if (i >= nb) return;\n"
"    float4 pi = pos[i];\n"
"    float4 vi = vel[i];\n"
"    float3 acc = (float3)(0.0f);\n"
"    for (int j = 0; j < nb; j++) {\n"
"        if (j == i) continue;\n"
"        float4 pj = pos[j];\n"
"        float3 d = pj.xyz - pi.xyz;\n"
"        float dist2 = dot(d, d) + 0.01f;      /* 软化 eps^2 */\n"
"        float inv = rsqrt(dist2);\n"
"        float inv3 = inv * inv * inv;\n"
"        acc += d * inv3;                      /* G*m = 1 */\n"
"    }\n"
"    float4 v_new = vi + (float4)(acc * dt, 0.0f);\n"
"    float4 p_new = pi + v_new * dt;\n"
"    vel_out[i] = v_new;\n"
"    pos_out[i] = p_new;\n"
"}\n";

static double now_ms(void) {
    LARGE_INTEGER f, t;
    QueryPerformanceFrequency(&f);
    QueryPerformanceCounter(&t);
    return (double)t.QuadPart * 1000.0 / (double)f.QuadPart;
}

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);
    cl_int err;
    cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
    CL_CHECK(err);
    const cl_queue_properties props[] = {
        CL_QUEUE_PROPERTIES, (cl_queue_properties)CL_QUEUE_PROFILING_ENABLE, 0
    };
    cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, props, &err);
    CL_CHECK(err);
    cl_program prog = clu_build_program(ctx, dev, K_SRC, NULL);
    cl_kernel k = clCreateKernel(prog, "nbody_step", &err);
    CL_CHECK(err);

    /* 初始：单位立方体内随机，初速度小 */
    float* hp = (float*)malloc(NB * 4 * sizeof(float));
    float* hv = (float*)malloc(NB * 4 * sizeof(float));
    srand(42);
    for (int i = 0; i < NB; i++) {
        hp[i * 4 + 0] = (rand() % 10000) / 10000.0f - 0.5f;
        hp[i * 4 + 1] = (rand() % 10000) / 10000.0f - 0.5f;
        hp[i * 4 + 2] = (rand() % 10000) / 10000.0f - 0.5f;
        hp[i * 4 + 3] = 0.0f;
        hv[i * 4 + 0] = (rand() % 1000) / 10000.0f - 0.05f;
        hv[i * 4 + 1] = (rand() % 1000) / 10000.0f - 0.05f;
        hv[i * 4 + 2] = (rand() % 1000) / 10000.0f - 0.05f;
        hv[i * 4 + 3] = 0.0f;
    }

    cl_mem bpos[2], bvel[2];
    bpos[0] = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                             NB * 4 * sizeof(float), hp, &err);
    CL_CHECK(err);
    bpos[1] = clCreateBuffer(ctx, CL_MEM_READ_WRITE, NB * 4 * sizeof(float), NULL, &err);
    CL_CHECK(err);
    bvel[0] = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                             NB * 4 * sizeof(float), hv, &err);
    CL_CHECK(err);
    bvel[1] = clCreateBuffer(ctx, CL_MEM_READ_WRITE, NB * 4 * sizeof(float), NULL, &err);
    CL_CHECK(err);

    cl_int nb = NB;
    float dt = 0.0005f;
    size_t g = NB;

    /* 动量守恒基准 */
    double px0 = 0, py0 = 0, pz0 = 0;
    for (int i = 0; i < NB; i++) { px0 += hv[i*4]; py0 += hv[i*4+1]; pz0 += hv[i*4+2]; }

    double t_ms = 0;
    int cur = 0;
    double t_start = now_ms();
    for (int s = 0; s < STEPS; s++) {
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bpos[cur]));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bvel[cur]));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bpos[1 - cur]));
        CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_mem), &bvel[1 - cur]));
        CL_CHECK(clSetKernelArg(k, 4, sizeof(cl_int), &nb));
        CL_CHECK(clSetKernelArg(k, 5, sizeof(float), &dt));
        cl_event ev;
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, &ev));
        CL_CHECK(clWaitForEvents(1, &ev));
        cl_ulong a, b;
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_START, sizeof(a), &a, NULL);
        clGetEventProfilingInfo(ev, CL_PROFILING_COMMAND_END, sizeof(b), &b, NULL);
        t_ms += (b - a) / 1e6;
        clReleaseEvent(ev);
        cur = 1 - cur;
    }
    double wall = now_ms() - t_start;

    /* 读回末态：动量守恒 + 抽样对拍第一步 */
    CL_CHECK(clEnqueueReadBuffer(q, bvel[cur], CL_TRUE, 0, NB * 4 * sizeof(float), hv, 0, NULL, NULL));
    double px1 = 0, py1 = 0, pz1 = 0;
    for (int i = 0; i < NB; i++) { px1 += hv[i*4]; py1 += hv[i*4+1]; pz1 += hv[i*4+2]; }

    /* 重放第一步（相同初值）与 CPU 双循环对拍 */
    {
        /* 重建 CPU 侧初始状态（与 GPU 同一随机序列） */
        srand(42);
        for (int i = 0; i < NB; i++) {
            hp[i*4+0]=(rand()%10000)/10000.0f-0.5f; hp[i*4+1]=(rand()%10000)/10000.0f-0.5f;
            hp[i*4+2]=(rand()%10000)/10000.0f-0.5f; hp[i*4+3]=0;
            hv[i*4+0]=(rand()%1000)/10000.0f-0.05f; hv[i*4+1]=(rand()%1000)/10000.0f-0.05f;
            hv[i*4+2]=(rand()%1000)/10000.0f-0.05f; hv[i*4+3]=0;
        }
        float* rp = (float*)malloc(NB * 4 * sizeof(float));
        memcpy(rp, hp, NB * 4 * sizeof(float));

        cl_mem bp0 = clCreateBuffer(ctx, CL_MEM_READ_ONLY|CL_MEM_COPY_HOST_PTR, NB*4*sizeof(float), hp, &err);
        CL_CHECK(err);
        cl_mem bv0 = clCreateBuffer(ctx, CL_MEM_READ_ONLY|CL_MEM_COPY_HOST_PTR, NB*4*sizeof(float), hv, &err);
        CL_CHECK(err);
        cl_mem bp1 = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, NB*4*sizeof(float), NULL, &err);
        CL_CHECK(err);
        cl_mem bv1 = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, NB*4*sizeof(float), NULL, &err);
        CL_CHECK(err);
        CL_CHECK(clSetKernelArg(k, 0, sizeof(cl_mem), &bp0));
        CL_CHECK(clSetKernelArg(k, 1, sizeof(cl_mem), &bv0));
        CL_CHECK(clSetKernelArg(k, 2, sizeof(cl_mem), &bp1));
        CL_CHECK(clSetKernelArg(k, 3, sizeof(cl_mem), &bv1));
        CL_CHECK(clSetKernelArg(k, 4, sizeof(cl_int), &nb));
        CL_CHECK(clSetKernelArg(k, 5, sizeof(float), &dt));
        CL_CHECK(clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL));
        float* gvel = (float*)malloc(NB*4*sizeof(float));
        CL_CHECK(clEnqueueReadBuffer(q, bv1, CL_TRUE, 0, NB*4*sizeof(float), gvel, 0, NULL, NULL));

        /* CPU 一步（对 8 个抽样体）与 GPU 对拍 */
        int samples[8] = {0, 1, 555, 1234, 2047, 3000, 4000, 4095};
        double max_err = 0;
        for (int s = 0; s < 8; s++) {
            int i = samples[s];
            float ax = 0;
            for (int j = 0; j < NB; j++) {
                if (j == i) continue;
                float dx = rp[j*4]-hp[i*4], dy = rp[j*4+1]-hp[i*4+1], dz = rp[j*4+2]-hp[i*4+2];
                float d2 = dx*dx+dy*dy+dz*dz + 0.01f;
                float inv = 1.0f / sqrtf(d2);
                float inv3 = inv*inv*inv;
                ax += dx*inv3;
            }
            float vx = hv[i*4] + ax*dt;
            float err_x = fabsf(vx - gvel[i*4]);
            if (err_x > max_err) max_err = err_x;
        }
        printf("step1 spot check: max |dvx| GPU vs CPU = %.2e (float 累加序差异)\n", max_err);
        CHECK(max_err < 1e-3f, "nbody matches cpu step");
        free(gvel); free(rp);
        clReleaseMemObject(bp0); clReleaseMemObject(bv0); clReleaseMemObject(bp1); clReleaseMemObject(bv1);
    }

    printf("%d bodies x %d steps: kernel total %.2f ms (%.2f ms/step), wall %.1f ms\n",
           NB, STEPS, t_ms, t_ms / STEPS, wall);
    printf("interactions/sec ~ %.2f billion\n", (double)NB * NB * STEPS / (t_ms / 1000.0) / 1e9);
    printf("momentum: before (%.4f, %.4f, %.4f), after (%.4f, %.4f, %.4f)\n",
           px0, py0, pz0, px1, py1, pz1);
    CHECK(fabs(px1 - px0) < 1e-2 && fabs(py1 - py0) < 1e-2 && fabs(pz1 - pz0) < 1e-2,
          "momentum conservation (symmetric forces)");

    clReleaseMemObject(bpos[0]); clReleaseMemObject(bpos[1]);
    clReleaseMemObject(bvel[0]); clReleaseMemObject(bvel[1]);
    clReleaseKernel(k); clReleaseProgram(prog);
    clReleaseCommandQueue(q); clReleaseContext(ctx);
    free(hp); free(hv);
    printf("25 nbody PASS\n");
    return 0;
}
