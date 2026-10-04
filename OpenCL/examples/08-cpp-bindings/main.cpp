// examples/08-cpp-bindings - the same vector add as examples/02, through cl.hpp.
//
// kernels/vector_add.cl here is byte-identical to examples/02-vector-add's copy.
// That is the first thing this example demonstrates and it is easy to miss: the C++
// bindings are a HOST-side facility only. Nothing about the device language, the
// kernel source, the build options or the numerical result changes. `diff` the two
// kernel files to confirm.
//
// What does change is the error model and the object lifetime model, and the rest of
// this file is about measuring both rather than asserting them:
//
//   * Section 5 reads CL_PROGRAM_BUILD_OPTIONS back from three differently-
//     constructed programs. One of the three turns out to have been compiled at a
//     language level nobody asked for.
//
//   * Section 11 reads CL_MEM_REFERENCE_COUNT around a wrapper's construction and
//     destruction, which is the only way to see what RAII actually does and what the
//     second constructor argument of cl::Buffer(cl_mem, bool) really means.
//
//   * Section 12 loads examples/09's SPIR-V module through cl::Program's IL
//     constructor. It measures the build option that constructor hardcodes, and shows
//     with a deliberately corrupt module that a caller's own "if (err != CL_SUCCESS)"
//     after that constructor is unreachable. When OpenCL/build-spirv.ps1 has not run
//     there is no module to load and the section reports SKIPPED without affecting the
//     verdict.
//
//   * The catch handlers at the end show that cl::Error::what() returns the NAME OF
//     THE C ENTRY POINT that failed, not a sentence, and that cl::BuildError carries
//     the whole build log inside the exception.
//
// Build: OpenCL/build.ps1 passes /DCL_HPP_ENABLE_EXCEPTIONS
//        /DCL_HPP_TARGET_OPENCL_VERSION=300 /DCL_HPP_MINIMUM_OPENCL_VERSION=200.
//        The #ifndef block below repeats those so the file also compiles standalone.
//        Do NOT set CL_HPP_MINIMUM_OPENCL_VERSION to 120: with a 300 target that is
//        the one value cl.hpp cannot compile. See docs/07 section 7.2.
//
// Verification: 1024 elements against a CPU reference, monotonic profiling stamps,
// the three build-option strings, the reference-count sequence 1 -> 2 -> 1, and -
// when a SPIR-V module is present - 1024 more elements through the IL constructor.
// Contract: exit 0 + "[RESULT] PASS".

// The defaults the build script already passes, restated so a hand compile works.
// CL_TARGET_OPENCL_VERSION is pinned here rather than left to ocl_util.h because of
// the include order below, and ocl_util.h's own #ifndef guard respects it.
#ifndef CL_TARGET_OPENCL_VERSION
#define CL_TARGET_OPENCL_VERSION 300
#endif
#ifndef CL_HPP_ENABLE_EXCEPTIONS
#define CL_HPP_ENABLE_EXCEPTIONS
#endif
#ifndef CL_HPP_TARGET_OPENCL_VERSION
#define CL_HPP_TARGET_OPENCL_VERSION 300
#endif
#ifndef CL_HPP_MINIMUM_OPENCL_VERSION
#define CL_HPP_MINIMUM_OPENCL_VERSION 200
#endif

// cl.hpp FIRST, then anything that pulls in <CL/cl.h>. Reversing these two lines
// costs one warning that is not your code's fault:
//
//   cl.hpp(6856): warning C4996: 'clSetProgramReleaseCallback'
//
// cl_platform.h decides at line 128 whether the OpenCL 2.2 entry points are marked
// deprecated, based on whether CL_USE_DEPRECATED_OPENCL_2_2_APIS is defined at that
// moment. cl.hpp would define it at 496-498, but only if cl.hpp is the one that gets
// parsed first - cl_platform.h is behind an include guard, so the decision is not
// revisited. With cl.h first, the marker is frozen ON, cl.hpp then compiles its own
// setReleaseCallback wrapper at 6840, and that wrapper calls the now-deprecated C
// function. Measured as variants 7 and 14 of tools/cpp-header-probe; see docs/07
// section 7.3.
#include <CL/cl.hpp>

#include "ocl_util.h"   // verdict contract, ocl_report_device, ocl_round_up

#include <string>
#include <vector>
#include <fstream>

#define N 1024

// Select a device by name across EVERY platform, in the C++ API.
//
// The C version of this lives in ocl_util.h; rewriting it here is not duplication
// for its own sake. The original tutorial's C++ example did
//
//     cl::Platform platform = platforms[0];
//     platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);
//     cl::Device device = devices[0];
//
// and on this machine that selects the NVIDIA RTX 2060, not the Intel iGPU the
// tutorial is about. The bindings make the mistake easier to write, not harder:
// there is no error to check and no cl_int to notice, so the wrong device is
// selected silently and every number that follows belongs to a different GPU.
static bool pickDeviceByName(const char* hint, cl::Device& out, std::string& outName) {
    std::vector<cl::Platform> platforms;
    if (cl::Platform::get(&platforms) != CL_SUCCESS) return false;

    for (size_t p = 0; p < platforms.size(); p++) {
        std::vector<cl::Device> devices;
        // CL_DEVICE_TYPE_ALL, and getDevices tolerates CL_DEVICE_NOT_FOUND
        // internally (cl.hpp:2803) so a platform with no devices of a given type
        // just yields an empty vector instead of throwing.
        if (platforms[p].getDevices(CL_DEVICE_TYPE_ALL, &devices) != CL_SUCCESS) continue;

        for (size_t i = 0; i < devices.size(); i++) {
            // getInfo<PARAM>() is the templated form: the return type comes from a
            // traits table keyed on the parameter, so there is no size argument to
            // get wrong and no buffer to overrun. That is a real gain over
            // clGetDeviceInfo, where passing sizeof(cl_uint) for a size_t property
            // silently yields 0 (docs/05 section 5.3.1).
            std::string name = devices[i].getInfo<CL_DEVICE_NAME>();
            if (name.find(hint) != std::string::npos) {
                out = devices[i];
                outName = name;
                return true;
            }
        }
    }
    return false;
}

// Reference count of a RAW cl_mem, via the C API. Needed for section 11's second
// half, where the whole point is that no wrapper exists any more.
static cl_uint rawRefCount(cl_mem m) {
    cl_uint n = 0;
    clGetMemObjectInfo(m, CL_MEM_REFERENCE_COUNT, sizeof(n), &n, NULL);
    return n;
}

int main() {
    // Everything below is inside one try block. That is the shape the bindings are
    // designed for: no cl_int is checked anywhere, and the first failure unwinds to
    // here carrying both the code and the name of the call that produced it.
    try {
        // ---- 1. device ----------------------------------------------------
        cl::Device device;
        std::string deviceName;
        if (!pickDeviceByName(OCL_DEFAULT_DEVICE, device, deviceName)) {
            printf("[FAIL] no device matching \"%s\"\n", OCL_DEFAULT_DEVICE);
            printf("       Run examples/01-device-query to see what this machine has.\n");
            return ocl_report(0);
        }
        // The wrapper's operator() yields the underlying cl_device_id, so the C
        // helper from ocl_util.h works on it unchanged. The bindings are thin
        // enough that mixing the two APIs in one file is normal, not a smell.
        ocl_report_device(device());

        // ---- 2. context and queue ----------------------------------------
        // No clReleaseContext / clReleaseCommandQueue anywhere in this file. Both
        // destructors run at the end of the try block's scope.
        cl::Context context(device);
        cl::CommandQueue queue(context, device, CL_QUEUE_PROFILING_ENABLE);

        // ---- 3. host data -------------------------------------------------
        std::vector<float> a(N), b(N), c(N, -1.0f);
        for (int i = 0; i < N; i++) {
            a[i] = (float)i;
            b[i] = (float)(i * 2);
        }

        // ---- 4. buffers ---------------------------------------------------
        // CL_MEM_COPY_HOST_PTR takes the data at creation time, so there is no
        // clEnqueueWriteBuffer call at all - two of the three enqueues that
        // examples/02 needs are gone. The vector's storage is copied, not aliased,
        // so a and b stay free to change afterwards.
        cl::Buffer bufA(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                        a.size() * sizeof(float), a.data());
        cl::Buffer bufB(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                        b.size() * sizeof(float), b.data());
        cl::Buffer bufC(context, CL_MEM_WRITE_ONLY, c.size() * sizeof(float));

        // ---- 5. what language level does the binding compile at? ----------
        // Three programs from one source, three different CL_PROGRAM_BUILD_OPTIONS.
        // Reading the option string back is the only way to see this, because all
        // three succeed and produce identical numbers.
        char* raw = ocl_read_file("kernels/vector_add.cl");
        if (!raw) return ocl_report(0);
        std::string source(raw);
        free(raw);

        // (A) The single-string convenience constructor with build=true. cl.hpp
        //     hardcodes "-cl-std=CL2.0" for this path (cl.hpp:6312-6316) unless
        //     CL_HPP_CL_1_2_DEFAULT_BUILD is defined. Nobody asked for 2.0.
        std::string optsAuto;
        {
            cl::Program pA(context, source, /*build=*/true);
            optsAuto = pA.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(device);
            printf("[build options] ctor(string, build=true) : '%s'\n", optsAuto.c_str());
        }

        // (B) The Sources constructor has NO build parameter at all (cl.hpp:6367),
        //     so it cannot silently choose a level. A following build() with no
        //     arguments passes NULL through to clBuildProgram, and the driver's own
        //     default applies - OpenCL C 1.2 on both Intel devices here.
        cl::Program::Sources sources;
        sources.push_back(source);
        cl::Program program(context, sources);

        std::string optsPlain;
        program.build();
        optsPlain = program.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(device);
        printf("[build options] Sources ctor + build()   : '%s'\n", optsPlain.c_str());

        // (C) Explicit. This is what the rest of the tutorial does, and what you
        //     should do whenever the level matters.
        cl::Program program12(context, sources);
        program12.build("-cl-std=CL1.2");
        std::string opts12 = program12.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(device);
        printf("[build options] build(\"-cl-std=CL1.2\")    : '%s'\n", opts12.c_str());

        // The build log is available the same way, and unlike examples/02 there is
        // no two-call clGetProgramBuildInfo dance to get it.
        std::string log = program12.getBuildInfo<CL_PROGRAM_BUILD_LOG>(device);
        if (!log.empty() && log.find_first_not_of(" \t\r\n") != std::string::npos) {
            printf("[build log]\n%s\n", log.c_str());
        }

        // ---- 6. kernel ----------------------------------------------------
        cl::Kernel kernel(program12, "vector_add");

        // setArg takes the wrapper directly. There is no sizeof(cl_mem) to get
        // wrong, which removes the single most common clSetKernelArg mistake.
        kernel.setArg(0, bufA);
        kernel.setArg(1, bufB);
        kernel.setArg(2, bufC);
        kernel.setArg(3, (int)N);

        // ---- 7. work-group size, queried twice ---------------------------
        // docs/06 section 6.7.3: the device limit and the per-kernel limit are
        // different queries and the smaller one governs. On the RTX 2060 the device
        // says 1024 while every kernel says 256.
        size_t devMax = device.getInfo<CL_DEVICE_MAX_WORK_GROUP_SIZE>();
        size_t kernMax = kernel.getWorkGroupInfo<CL_KERNEL_WORK_GROUP_SIZE>(device);
        size_t limit = (kernMax < devMax) ? kernMax : devMax;
        size_t localSize = (limit < 64) ? limit : 64;
        size_t globalSize = ocl_round_up((size_t)N, localSize);
        printf("[launch] device max_wg=%zu, kernel max_wg=%zu -> local=%zu global=%zu\n",
               devMax, kernMax, localSize, globalSize);

        // ---- 8. execute ---------------------------------------------------
        cl::Event ev;
        queue.enqueueNDRangeKernel(kernel, cl::NullRange,
                                  cl::NDRange(globalSize), cl::NDRange(localSize),
                                  nullptr, &ev);
        queue.enqueueReadBuffer(bufC, CL_TRUE, 0, c.size() * sizeof(float), c.data());
        // enqueueReadBuffer was blocking (CL_TRUE) so no explicit wait is needed,
        // but the event still carries the kernel's profiling stamps.

        // ---- 9. verify ----------------------------------------------------
        int bad = 0;
        for (int i = 0; i < N; i++) {
            float ref = (float)i + (float)(i * 2);
            if (c[i] != ref) {
                if (bad < 5) printf("  mismatch i=%d got %f want %f\n", i, c[i], ref);
                bad++;
            }
        }
        printf("[verify] %d/%d elements correct\n", N - bad, N);

        // ---- 10. profiling -----------------------------------------------
        cl_ulong start = ev.getProfilingInfo<CL_PROFILING_COMMAND_START>();
        cl_ulong end   = ev.getProfilingInfo<CL_PROFILING_COMMAND_END>();
        int profOk = (start != 0) && (end != 0) && (start <= end);
        printf("[profiling] kernel execute %llu ns : %s\n",
               (unsigned long long)(end - start), profOk ? "monotonic" : "NOT monotonic");

        // ---- 11. what RAII actually does, measured ------------------------
        // CL_MEM_REFERENCE_COUNT is the observable. Everything else about wrapper
        // lifetimes is a claim; this is a number.
        int refOk = 1;

        cl_uint rc0 = bufC.getInfo<CL_MEM_REFERENCE_COUNT>();
        {
            // retainObject = TRUE: the wrapper calls clRetainMemObject, taking an
            // ADDITIONAL reference. The original tutorial's comment on this
            // argument - "true means take over ownership" - is backwards. Taking an
            // extra reference is the opposite of taking over: the caller still owns
            // its own and must still release it.
            cl::Buffer shared(bufC(), true);
            cl_uint rc1 = shared.getInfo<CL_MEM_REFERENCE_COUNT>();
            printf("[refcount] original=%u, after cl::Buffer(handle, true)=%u\n", rc0, rc1);
            if (!(rc0 == 1 && rc1 == 2)) refOk = 0;
        }
        cl_uint rc2 = bufC.getInfo<CL_MEM_REFERENCE_COUNT>();
        printf("[refcount] after the wrapper went out of scope=%u\n", rc2);
        if (rc2 != 1) refOk = 0;

        // retainObject = FALSE (the default): the wrapper ADOPTS the caller's
        // existing reference and will release it. This is the branch the GL
        // interop code in the original tutorial needed and mislabelled.
        cl_int cerr = CL_SUCCESS;
        cl_mem rawMem = clCreateBuffer(context(), CL_MEM_READ_WRITE,
                                       16 * sizeof(float), nullptr, &cerr);
        int adoptOk = 0;
        if (rawMem && cerr == CL_SUCCESS) {
            cl_uint before = rawRefCount(rawMem);
            {
                cl::Buffer adopted(rawMem, false);
                cl_uint inside = adopted.getInfo<CL_MEM_REFERENCE_COUNT>();
                printf("[refcount] raw cl_mem=%u, after cl::Buffer(handle, false)=%u\n",
                       before, inside);
                // Adopting does not create a reference, so the count is unchanged.
                if (before == 1 && inside == 1) adoptOk = 1;
            }
            // adopted's destructor released the only reference, so rawMem is dead.
            // The query failing IS the proof - a handle that had merely been
            // "wrapped" would still answer.
            cl_uint dead = 0;
            cl_int q = clGetMemObjectInfo(rawMem, CL_MEM_REFERENCE_COUNT,
                                          sizeof(dead), &dead, nullptr);
            printf("[refcount] querying the raw handle afterwards -> %d %s\n",
                   q, ocl_err_name(q));
            if (q != CL_INVALID_MEM_OBJECT) adoptOk = 0;
            // Deliberately NOT calling clReleaseMemObject(rawMem) here: the wrapper
            // already did. Releasing again would be a double free.
        } else {
            printf("[refcount] clCreateBuffer for the adopt test failed: %d %s\n",
                   cerr, ocl_err_name(cerr));
        }
        if (!adoptOk) refOk = 0;

        // ---- 12. the IL constructor, and whether the caller's check ever runs -
        // docs/08 rewrites the original tutorial's C++ SPIR-V example, and a rewrite
        // that was never compiled is worth less than the thing it replaced. This is
        // the corrected form, actually run.
        //
        // Two claims about cl::Program(context, IL, build, err) at cl.hpp:6460:
        //
        //   a) build=true hardcodes "-cl-std=CL2.0" (cl.hpp:6492) - the same default
        //      section 5 measured for source programs. CL_PROGRAM_BUILD_OPTIONS is
        //      read back so the claim rests on a returned string, not a line number.
        //
        //   b) a caller's own "if (err != CL_SUCCESS) throw" is unreachable.
        //      cl.hpp:6484 calls detail::errHandler BEFORE the constructor writes
        //      *err at 6502, and with exceptions enabled errHandler throws. The
        //      original tutorial had both, so the message it carefully composed is
        //      never the one anyone reads. Demonstrating that needs a module which
        //      genuinely fails, hence the corrupt copy below.
        //
        // The module is examples/09's, produced by OpenCL/build-spirv.ps1. When that
        // has not run there is nothing to load and this section says so without
        // touching the verdict: a missing offline toolchain is not a broken binding.
        int ilState = 0;   // 0 = not run, 1 = ok, -1 = failed
        {
            // The only cross-example path in this tutorial, and it is a path rather
            // than a second copy of the module on purpose: the claim is that the SAME
            // bytes load through the C++ binding as through the C API in examples/09,
            // and two copies could drift.
            const char* spvPath = "..\\09-spirv-il\\spv\\vector_add.spv";
            std::ifstream f(spvPath, std::ios::binary | std::ios::ate);
            if (!f.is_open()) {
                printf("[il-cpp] %s not found - run OpenCL\\build-spirv.ps1 first\n", spvPath);
                printf("[il-cpp] SKIPPED, not failed: no offline toolchain here\n");
            } else {
                std::streamsize sz = f.tellg();
                f.seekg(0, std::ios::beg);
                std::vector<char> il((size_t)sz);
                f.read(il.data(), sz);
                f.close();
                printf("[il-cpp] %s : %d bytes\n", spvPath, (int)il.size());
                ilState = 1;

                // getInfo<CL_DEVICE_IL_VERSION> returns std::string - the trait is
                // declared at cl.hpp:1506 - so testing .empty() is a correct check.
                // The C equivalent is not: docs/08 measures that size query returning
                // 1 for a device with no IL support at all, which makes the usual
                // "reject the device if the size is 0" idiom fail open.
                std::string ilVer = device.getInfo<CL_DEVICE_IL_VERSION>();
                printf("[il-cpp] CL_DEVICE_IL_VERSION = '%s' -> %s\n", ilVer.c_str(),
                       ilVer.empty() ? "no IL support" : "IL supported");

                // (b) first, because it needs the failure path. Only the magic word is
                // wrong, so nothing else about the module can explain the outcome.
                std::vector<char> corrupt = il;
                corrupt[0] = (char)0xFF;
                cl_int sentinel = 12345;
                printf("[il-cpp] constructing from a module with a corrupt magic...\n");
                try {
                    cl::Program bad(context, corrupt, true, &sentinel);
                    printf("[il-cpp]   constructor RETURNED, *err = %d %s\n",
                           sentinel, ocl_err_name(sentinel));
                    if (sentinel != CL_SUCCESS) {
                        printf("[il-cpp]   ...so a caller's if(err != CL_SUCCESS) WOULD run\n");
                    }
                } catch (const cl::Error& e) {
                    printf("[il-cpp]   threw cl::Error %d %s (%s)\n",
                           e.err(), ocl_err_name(e.err()), e.what());
                    printf("[il-cpp]   *err is still %d: it is written after errHandler,\n",
                           sentinel);
                    printf("[il-cpp]   so a caller's if(err != CL_SUCCESS) never runs\n");
                }

                // (a) The real module, through the same constructor.
                cl_int err2 = 0;
                cl::Program prog(context, il, true, &err2);
                printf("[il-cpp] good module: *err = %d %s\n", err2, ocl_err_name(err2));
                std::string ilOpts = prog.getBuildInfo<CL_PROGRAM_BUILD_OPTIONS>(device);
                printf("[il-cpp] CL_PROGRAM_BUILD_OPTIONS = '%s'\n", ilOpts.c_str());
                if (ilOpts.find("-cl-std=CL2.0") == std::string::npos) ilState = -1;

                cl::Kernel ilKernel(prog, "vector_add");
                cl_uint nargs = ilKernel.getInfo<CL_KERNEL_NUM_ARGS>();
                printf("[il-cpp] CL_KERNEL_NUM_ARGS = %u (the source declares 4)\n", nargs);
                if (nargs != 4) ilState = -1;

                // The buffers section 4 filled and section 8 already wrote, and the
                // geometry section 7 derived. Only the program object is new, so a
                // mismatch below cannot be blamed on the data or the launch shape.
                ilKernel.setArg(0, bufA);
                ilKernel.setArg(1, bufB);
                ilKernel.setArg(2, bufC);
                ilKernel.setArg(3, (int)N);
                queue.enqueueNDRangeKernel(ilKernel, cl::NullRange,
                                           cl::NDRange(globalSize), cl::NDRange(localSize));
                std::vector<float> c2(N, -1.0f);
                queue.enqueueReadBuffer(bufC, CL_TRUE, 0, c2.size() * sizeof(float), c2.data());
                int ilBad = 0;
                for (int i = 0; i < N; i++) {
                    if (c2[i] != (float)i + (float)(i * 2)) ilBad++;
                }
                printf("[il-cpp] %d/%d elements correct through the C++ binding\n",
                       N - ilBad, N);
                if (ilBad != 0) ilState = -1;
            }
        }

        // ---- 13. report ---------------------------------------------------
        int optsOk =
            (optsAuto.find("-cl-std=CL2.0") != std::string::npos) &&
            (optsPlain.find_first_not_of(" \t\r\n") == std::string::npos) &&
            (opts12.find("-cl-std=CL1.2") != std::string::npos);

        printf("\nassert all %d elements match CPU reference      : %s\n",
               N, bad == 0 ? "OK" : "FAILED");
        printf("assert profiling timestamps monotonic            : %s\n",
               profOk ? "OK" : "FAILED");
        printf("assert build options are 2.0 / empty / 1.2       : %s\n",
               optsOk ? "OK" : "FAILED");
        printf("assert reference counts follow retain vs adopt   : %s\n",
               refOk ? "OK" : "FAILED");
        printf("assert the IL constructor loads and runs         : %s\n",
               ilState == 1 ? "OK" : (ilState == 0 ? "SKIPPED (no spv/)" : "FAILED"));

        int pass = (bad == 0) && profOk && optsOk && refOk && (ilState != -1);
        return ocl_report(pass);

    } catch (const cl::BuildError& e) {
        // Thrown by Program::build and by the auto-building constructors. It is a
        // cl::Error subclass that additionally carries the per-device build log, so
        // the log arrives with the exception instead of needing a second query.
        // This replaces the fifteen-line clGetProgramBuildInfo block in
        // examples/02-vector-add.
        printf("[FAIL] cl::BuildError %d (%s)\n", e.err(), e.what());
        std::vector<std::pair<cl::Device, std::string>> logs = e.getBuildLog();
        for (size_t i = 0; i < logs.size(); i++) {
            printf("---- build log: %s ----\n%s\n",
                   logs[i].first.getInfo<CL_DEVICE_NAME>().c_str(),
                   logs[i].second.c_str());
        }
        return ocl_report(0);
    } catch (const cl::Error& e) {
        // what() is the stringified C entry point name - "clBuildProgram",
        // "clEnqueueNDRangeKernel" - not a sentence. It comes from
        // CL_HPP_ERR_STR_(x), which is #x (cl.hpp:782). Useful precisely because it
        // names the call, but it does not describe the problem; e.err() plus
        // ocl_err_name does.
        printf("[FAIL] cl::Error %d %s (thrown by %s)\n",
               e.err(), ocl_err_name(e.err()), e.what());
        return ocl_report(0);
    }
}
