cl_bool supportsIL;
clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(supportsIL), &supportsIL, NULL);

if (supportsIL) {
    printf("Device supports IL programs (SPIR-V)\n");
}

// 获取支持的 IL 版本
char ilVersion[256];
clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(ilVersion), ilVersion, NULL);
printf("IL Version: %s\n", ilVersion);
