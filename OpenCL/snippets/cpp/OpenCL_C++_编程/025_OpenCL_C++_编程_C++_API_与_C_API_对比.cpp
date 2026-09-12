try {
    cl::Program program(context, kernelSource);
    program.build();
} catch (cl::Error& err) {
    std::cerr << "OpenCL Error: " << err.what() << std::endl;
}
