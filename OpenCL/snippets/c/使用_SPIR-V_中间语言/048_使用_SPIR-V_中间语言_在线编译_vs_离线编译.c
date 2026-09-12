// 在线编译（运行时）
cl_program program = clCreateProgramWithSource(context, 1, &source, NULL, &err);
clBuildProgram(program, 1, &device, "-cl-std=CL2.0", NULL, NULL);

// 离线编译（SPIR-V）
cl_program program = clCreateProgramWithIL(context, spirvBinary, spirvSize, &err);
clBuildProgram(program, 1, &device, NULL, NULL, NULL);
