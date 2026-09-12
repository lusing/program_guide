# 使用 clang 编译 OpenCL C++ 到 SPIR-V
clang++ -cl-std=c++ -target spirv64 -c kernel.clcpp -o kernel.spv
