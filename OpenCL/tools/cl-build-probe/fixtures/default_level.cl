// What OpenCL C level does the driver ACTUALLY compile at when -cl-std is omitted?
//
// CL_DEVICE_OPENCL_C_VERSION cannot answer this. On this machine the iGPU reports
// "OpenCL C 1.2" and the CPU device reports "OpenCL C 3.0", yet BOTH reject
// work_group_barrier at default build options while NVIDIA - which also reports
// 1.2 - accepts it. The reported string therefore predicts neither the floor nor
// the ceiling, and the only way to know the default is to ask the compiler.
//
// Asking is done by making the build succeed only when a predefined macro equals
// the value passed in on the command line, then sweeping values until one passes:
//
//   cl-build-probe default_level.cl level_probe UHD "-DEXPECT=300 -DEXPECT_C=120"
//
// Two macros, because they are not the same thing and conflating them is the trap:
//
//   __OPENCL_VERSION__     legacy, defined since OpenCL C 1.0, deprecated in 2.0.
//                          Reports the DEVICE's OpenCL version, not the language
//                          level in force. Measured 300 on both Intel devices under
//                          ALL FOUR option sets including an explicit -cl-std=CL1.2,
//                          so it cannot be used to detect the level there at all.
//   __OPENCL_C_VERSION__   defined from OpenCL C 2.0 onward in the specification,
//                          but all three drivers here define it at every level -
//                          including 1.2, where it reads 120. This is the macro that
//                          tracks -cl-std, and therefore the one that gates whether
//                          a 2.0 builtin such as work_group_barrier exists.
//
// Measured with this fixture, __OPENCL_VERSION__ / __OPENCL_C_VERSION__:
//
//   no -cl-std      UHD 300/120   i7 300/120   NVIDIA 300/300
//   -cl-std=CL1.2   UHD 300/120   i7 300/120   NVIDIA 120/120
//   -cl-std=CL2.0   UHD 300/200   i7 300/200   NVIDIA 200/200
//   -cl-std=CL3.0   UHD 300/300   i7 300/300   NVIDIA 300/300
//
// That last column is why NVIDIA accepts work_group_barrier by default and the
// Intel devices reject it: NVIDIA's default language level really is 3.0.
//
// EXPECT_C == 0 means "expect __OPENCL_C_VERSION__ to be undefined". No driver on
// this machine ever leaves it undefined - all three define it even at 1.2 - but the
// branch stays, because the reason it is needed is a preprocessor rule rather than a
// driver quirk: an undefined macro inside #if silently evaluates to 0, so comparing
// it against 0 would report a false pass instead of an error. Any driver that does
// omit the macro at 1.2 would be indistinguishable from one that defines it as 0
// without the explicit defined() test.
//
// Note for anyone extending this: stringifying a macro into the #error text does
// NOT work. clang on all three of these drivers prints the raw tokens
// (STR(__OPENCL_VERSION__) arrives in the log unexpanded), so the message cannot
// carry the value. Hence the sweep instead of a self-reporting diagnostic.
#define EXPECT_C_UNDEFINED 0

#ifndef EXPECT
#define EXPECT 0
#endif
#ifndef EXPECT_C
#define EXPECT_C EXPECT_C_UNDEFINED
#endif

#if __OPENCL_VERSION__ != EXPECT
#error "__OPENCL_VERSION__ does not match EXPECT"
#endif

#if !defined(__OPENCL_C_VERSION__)
#if EXPECT_C != EXPECT_C_UNDEFINED
#error "__OPENCL_C_VERSION__ is undefined but a value was expected"
#endif
#elif __OPENCL_C_VERSION__ != EXPECT_C
#error "__OPENCL_C_VERSION__ does not match EXPECT_C"
#endif

__kernel void level_probe(__global float* out) {
    out[get_global_id(0)] = (float)__OPENCL_VERSION__;
}
