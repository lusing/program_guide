#include <CL/cl.h>
#include <stdio.h>

int main() {
    cl_uint numPlatforms;
    clGetPlatformIDs(0, NULL, &numPlatforms);

    cl_platform_id platform;
    clGetPlatformIDs(1, &platform, NULL);

    char version[256];
    clGetPlatformInfo(platform, CL_PLATFORM_VERSION, sizeof(version), &version, NULL);
    printf("OpenCL Version: %s\n", version);

    return 0;
}
