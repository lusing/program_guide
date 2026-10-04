// The same computation as vector_add.cl, written in OpenCL C++ instead of OpenCL C.
//
// This file exists to answer one question with a measurement: does the C++ route
// produce a different module? It is compiled with "-cl-std=CLC++" and compared
// instruction-by-instruction against the "-cl-std=CL1.2" build of vector_add.cl.
// build-spirv.ps1 runs that comparison and fails if the answer changes.
//
// The template and the struct with a static member are not decoration. They are the
// constructs that "-cl-std=CL1.2" rejects outright - clang reports
// "unknown type name 'template'" - so if this file compiles at all, the language
// level really did move. A C++ file containing nothing but C would prove nothing.
//
// Semantics are deliberately identical to vector_add.cl, four arguments in the same
// order, so tools/spirv-route-probe can run it against the same reference data and
// the same expected result. If it computed something else, a numeric mismatch would
// be ambiguous between "the C++ route is broken" and "the probe's reference is".
template <typename T>
struct Adder {
    static T apply(T x, T y) { return x + y; }
};

kernel void vector_add(global const float* a, global const float* b,
                       global float* c, int n) {
    int i = get_global_id(0);
    if (i < n) c[i] = Adder<float>::apply(a[i], b[i]);
}
