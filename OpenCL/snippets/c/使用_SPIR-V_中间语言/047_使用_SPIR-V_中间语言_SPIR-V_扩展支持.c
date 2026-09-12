// 检查 SPIR-V 扩展
char extensions[4096];
clGetDeviceInfo(device, CL_DEVICE_EXTENSIONS, sizeof(extensions), extensions, NULL);

// 常见 SPIR-V 扩展
if (strstr(extensions, "cl_khr_il_program")) {
    printf("Supports cl_khr_il_program (OpenCL 1.2 SPIR-V)\n");
}
if (strstr(extensions, "cl_khr_spirv_no_integer_wrap_decoration")) {
    printf("Supports SPIR-V no integer wrap decoration\n");
}
