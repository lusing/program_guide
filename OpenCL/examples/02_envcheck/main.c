/* 02_envcheck —— 机器上的 OpenCL 环境自检（迷你 clinfo）
 *
 * 枚举全部平台/设备，打印装机判定所需的关键信息：
 * 版本、驱动、OpenCL C 版本、IL(SPIR-V) 支持、关键能力与扩展。
 * 装好驱动和 SDK 后先跑它确认环境可用。
 */
#include "cl_utils.h"

static int has_ext(const char* list, const char* name) {
    return strstr(list, name) != NULL;
}

int main(void) {
    cl_uint nplat = 0;
    CL_CHECK(clGetPlatformIDs(0, NULL, &nplat));
    CHECK(nplat > 0, "no OpenCL platform: install GPU driver first");
    cl_platform_id plats[8];
    CL_CHECK(clGetPlatformIDs(nplat > 8 ? 8 : nplat, plats, NULL));
    printf("found %u platform(s)\n\n", nplat);

    for (cl_uint i = 0; i < nplat && i < 8; i++) {
        char name[256] = {0}, vendor[128] = {0}, ver[64] = {0}, prof[32] = {0};
        char exts[4096] = {0};
        clGetPlatformInfo(plats[i], CL_PLATFORM_NAME, sizeof(name), name, NULL);
        clGetPlatformInfo(plats[i], CL_PLATFORM_VENDOR, sizeof(vendor), vendor, NULL);
        clGetPlatformInfo(plats[i], CL_PLATFORM_VERSION, sizeof(ver), ver, NULL);
        clGetPlatformInfo(plats[i], CL_PLATFORM_PROFILE, sizeof(prof), prof, NULL);
        clGetPlatformInfo(plats[i], CL_PLATFORM_EXTENSIONS, sizeof(exts), exts, NULL);
        printf("[platform %u] %s\n  vendor=%s version=%s profile=%s\n", i, name, vendor, ver, prof);
        printf("  platform extensions: %s\n", exts);

        cl_uint ndev = 0;
        if (clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_ALL, 0, NULL, &ndev) != CL_SUCCESS || ndev == 0) {
            printf("  (no device)\n\n");
            continue;
        }
        cl_device_id devs[8];
        CL_CHECK(clGetDeviceIDs(plats[i], CL_DEVICE_TYPE_ALL, ndev > 8 ? 8 : ndev, devs, NULL));

        for (cl_uint d = 0; d < ndev && d < 8; d++) {
            cl_device_id dev = devs[d];
            char dn[256] = {0}, dv[64] = {0}, dvv[64] = {0}, dext[8192] = {0}, il[256] = {0};
            cl_device_type type = 0;
            clGetDeviceInfo(dev, CL_DEVICE_NAME, sizeof(dn), dn, NULL);
            clGetDeviceInfo(dev, CL_DEVICE_VERSION, sizeof(dv), dv, NULL);
            clGetDeviceInfo(dev, CL_DRIVER_VERSION, sizeof(dvv), dvv, NULL);
            clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, sizeof(dext), dext, NULL);
            clGetDeviceInfo(dev, CL_DEVICE_TYPE, sizeof(type), &type, NULL);
            const char* ts = (type & CL_DEVICE_TYPE_GPU) ? "GPU"
                           : (type & CL_DEVICE_TYPE_CPU) ? "CPU" : "ACCELERATOR/other";
            printf("  <device %u> %s  [%s]\n", d, dn, ts);
            printf("    version=%s driver=%s\n", dv, dvv);

            char cver[64] = {0};
            clGetDeviceInfo(dev, CL_DEVICE_OPENCL_C_VERSION, sizeof(cver), cver, NULL);
            printf("    OpenCL C : %s\n", cver);

            /* CL_DEVICE_IL_VERSION 是字符串；长度为 1（只剩 NUL）表示不支持 IL/SPIR-V */
            clGetDeviceInfo(dev, CL_DEVICE_IL_VERSION, sizeof(il), il, NULL);
            printf("    IL/SPIR-V: %s\n", il[0] ? il : "(none)");

            cl_uint cu = 0; cl_ulong gmem = 0; cl_ulong lmem = 0;
            clGetDeviceInfo(dev, CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(cu), &cu, NULL);
            clGetDeviceInfo(dev, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(gmem), &gmem, NULL);
            clGetDeviceInfo(dev, CL_DEVICE_LOCAL_MEM_SIZE, sizeof(lmem), &lmem, NULL);
            printf("    compute units=%u  global mem=%llu MB  local mem=%llu KB\n",
                   cu, (unsigned long long)(gmem >> 20), (unsigned long long)(lmem >> 10));

            printf("    fp64=%d fp16=%d il_program=%d subgroups=%d d3d11=%d gl=%d\n",
                   has_ext(dext, "cl_khr_fp64"), has_ext(dext, "cl_khr_fp16"),
                   has_ext(dext, "cl_khr_il_program"), has_ext(dext, "cl_khr_subgroups"),
                   has_ext(dext, "cl_khr_d3d11_sharing"), has_ext(dext, "cl_khr_gl_sharing"));
        }
        printf("\n");
    }
    printf("02 envcheck PASS\n");
    return 0;
}
