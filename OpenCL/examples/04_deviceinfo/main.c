/* 04_deviceinfo —— clGetDeviceInfo 的四类查询形态 + cl_name_version 数组
 *
 * 演示：
 *  1) 标量查询（一次值）
 *  2) 字符串查询（两遍法：先问大小再取内容）
 *  3) cl_name_version 数组查询（CL_DEVICE_EXTENSIONS_WITH_VERSION /
 *     CL_DEVICE_OPENCL_C_ALL_VERSIONS / CL_DEVICE_OPENCL_C_FEATURES）
 *  注意：CL_DEVICE_OPENCL_C_FEATURES 按规范返回的就是 cl_name_version 数组，
 *  不是空格分隔字符串（实测两家驱动都如此）。
 */
#include "cl_utils.h"

typedef struct { unsigned ver; char name[64]; } NV;

static void version_to_str(unsigned v, char* buf, size_t n) {
    snprintf(buf, n, "%u.%u.%u", v >> 22, (v >> 12) & 0x3FF, v & 0xFFF);
}

/* 数组查询辅助：返回条目数（失败返回 0） */
static size_t query_nv_array(cl_device_id dev, cl_device_info info, NV* out, size_t max) {
    size_t bytes = 0;
    if (clGetDeviceInfo(dev, info, 0, NULL, &bytes) != CL_SUCCESS || bytes == 0) return 0;
    size_t count = bytes / sizeof(cl_name_version);
    if (count > max) count = max;
    cl_name_version* raw = (cl_name_version*)malloc(count * sizeof(cl_name_version));
    CHECK(raw != NULL, "alloc");
    CL_CHECK(clGetDeviceInfo(dev, info, count * sizeof(cl_name_version), raw, NULL));
    for (size_t i = 0; i < count; i++) {
        out[i].ver = raw[i].version;
        strncpy(out[i].name, raw[i].name, 63);
        out[i].name[63] = '\0';
    }
    free(raw);
    return count;
}

static void print_nv_array(const char* label, NV* arr, size_t count) {
    printf("  %-32s:", label);
    for (size_t i = 0; i < count; i++) {
        char vs[32];
        version_to_str(arr[i].ver, vs, sizeof(vs));
        printf(" %s@%s", arr[i].name, vs);
    }
    printf("\n");
}

int main(void) {
    cl_platform_id plat;
    cl_device_id dev;
    clu_pick_device(&plat, &dev, NULL);
    clu_print_device_brief(dev);

    /* --- 1) 标量查询 --- */
    cl_uint cu = 0, addr_bits = 0;
    size_t max_wg = 0;
    cl_ulong gmem = 0, cmem = 0;
    cl_device_mem_cache_type ctype = 0;
    cl_bool avail = 0, compiler = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_COMPUTE_UNITS, sizeof(cu), &cu, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_ADDRESS_BITS, sizeof(addr_bits), &addr_bits, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(max_wg), &max_wg, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_GLOBAL_MEM_SIZE, sizeof(gmem), &gmem, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE, sizeof(cmem), &cmem, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_GLOBAL_MEM_CACHE_TYPE, sizeof(ctype), &ctype, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_AVAILABLE, sizeof(avail), &avail, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_COMPILER_AVAILABLE, sizeof(compiler), &compiler, NULL));

    printf("  scalar queries:\n");
    printf("    compute units               : %u\n", cu);
    printf("    address bits                 : %u\n", addr_bits);
    printf("    max work-group size          : %zu\n", max_wg);
    printf("    global memory                : %llu MB\n", (unsigned long long)(gmem >> 20));
    printf("    max constant buffer          : %llu KB\n", (unsigned long long)(cmem >> 10));
    printf("    global mem cache type        : %s\n",
           ctype == CL_NONE ? "none" : ctype == CL_READ_ONLY_CACHE ? "read-only" : "read-write");
    printf("    available / compiler         : %d / %d\n", (int)avail, (int)compiler);

    /* work-item 尺寸：size_t[3] 数组 + 维度数 */
    cl_uint dims = 0;
    size_t wisz[3] = {0, 0, 0};
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS, sizeof(dims), &dims, NULL));
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_MAX_WORK_ITEM_SIZES, sizeof(wisz), wisz, NULL));
    printf("    max work-item sizes (%u dims) : %zu x %zu x %zu\n", dims, wisz[0], wisz[1], wisz[2]);

    /* --- 2) 字符串查询（两遍法） --- */
    size_t sz = 0;
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, 0, NULL, &sz));
    char* exts = (char*)malloc(sz);
    CHECK(exts != NULL, "alloc");
    CL_CHECK(clGetDeviceInfo(dev, CL_DEVICE_EXTENSIONS, sz, exts, NULL));
    size_t ext_count = 1;
    for (char* p = exts; *p; p++) if (*p == ' ') ext_count++;
    printf("  string query:\n");
    printf("    extensions (%zu names, %zu bytes incl. NUL)\n", ext_count, sz);
    free(exts);

    /* --- 3) cl_name_version 数组查询 --- */
    NV arr[80];
    size_t n = 0;
    printf("  cl_name_version arrays:\n");
    n = query_nv_array(dev, CL_DEVICE_OPENCL_C_ALL_VERSIONS, arr, 80);
    print_nv_array("OPENCL_C_ALL_VERSIONS", arr, n);
    size_t n_cver = n;

    n = query_nv_array(dev, CL_DEVICE_OPENCL_C_FEATURES, arr, 80);
    print_nv_array("OPENCL_C_FEATURES", arr, n);
    size_t n_feat = n;

    n = query_nv_array(dev, CL_DEVICE_EXTENSIONS_WITH_VERSION, arr, 80);
    print_nv_array("EXTENSIONS_WITH_VERSION(first 80)", arr, n);
    size_t n_ext = n;

    /* 厂商定制信息（cl_ext.h 里的 NVIDIA 查询，仅 NVIDIA 平台有） */
    char vendor[128] = {0};
    clGetDeviceInfo(dev, CL_DEVICE_VENDOR, sizeof(vendor), vendor, NULL);
    printf("  vendor                        : %s\n", vendor);

    /* 校验：数组形态查询与字符串形态查询数量一致（宽松断言：都非零） */
    CHECK(n_cver >= 1, "OPENCL_C_ALL_VERSIONS must be non-empty");
    CHECK(n_ext >= 1, "EXTENSIONS_WITH_VERSION must be non-empty");
    printf("04 deviceinfo PASS (C versions=%zu, features=%zu)\n", n_cver, n_feat);
    return 0;
}
