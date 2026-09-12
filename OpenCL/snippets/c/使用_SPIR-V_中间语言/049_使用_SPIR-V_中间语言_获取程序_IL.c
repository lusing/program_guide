// 从已编译的程序获取 SPIR-V
size_t ilSize;
clGetProgramInfo(program, CL_PROGRAM_IL, 0, NULL, &ilSize);

unsigned char* ilBinary = (unsigned char*)malloc(ilSize);
clGetProgramInfo(program, CL_PROGRAM_IL, ilSize, ilBinary, NULL);

// 保存到文件
FILE* fp = fopen("output.spv", "wb");
fwrite(ilBinary, 1, ilSize, fp);
fclose(fp);
free(ilBinary);
