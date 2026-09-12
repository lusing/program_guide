# 安装 LLVM/Clang（需要支持 OpenCL 的版本）
# 编译 OpenCL C 源码到 SPIR-V

clang -cl-std=CL2.0 -target spirv64 -c kernel.cl -o kernel.spv

# 或者使用 OpenCL 离线编译器
opencl-c-compiler -cl-std=CL2.0 -o kernel.spv kernel.cl
