# 编译（注意路径需要用引号包裹包含空格的路径）
gcc -o opencl_demo.exe opencl_helloworld.c -I"C:\Program Files (x86)\Intel\OpenCL SDK\include" -L"C:\Program Files (x86)\Intel\OpenCL SDK\lib\x64" -lOpenCL

# 运行
./opencl_demo.exe
