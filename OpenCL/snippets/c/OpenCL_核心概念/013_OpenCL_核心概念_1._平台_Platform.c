// 获取平台数量
cl_uint numPlatforms;
clGetPlatformIDs(0, NULL, &numPlatforms);

// 获取平台 ID
cl_platform_id platform;
clGetPlatformIDs(1, &platform, NULL);

// 查询平台信息
char platformName[256];
clGetPlatformInfo(platform, CL_PLATFORM_NAME, sizeof(platformName), &platformName, NULL);
