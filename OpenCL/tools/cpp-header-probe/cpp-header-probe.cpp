// tools/cpp-header-probe - what does <CL/cl.hpp> actually accept on this machine?
//
// The OpenCL C++ bindings are a single header with no library of their own, so
// every question about them is a HOST COMPILE question: which macro combination
// makes cl.exe exit 0, and which makes it explode. There is no runtime behaviour
// to observe for most of what chapter 07 claims, which is why this probe exists
// instead of another example.
//
// One source file, seventeen variants selected by /DVARIANT=n. build.ps1 compiles the
// file once per variant and compares the exit code against a table of
// expectations. Seven variants are expected to FAIL, and that is the point: a probe
// that reported success for everything would prove nothing about which macro
// settings are load-bearing.
//
// The six questions the variant set is built to answer:
//
//   Q1. Do <CL/cl2.hpp> and <CL/opencl.hpp> exist here?            -> V5, V6
//   Q2. Is the old macro name __CL_ENABLE_EXCEPTIONS the problem?   -> V2, V3, V4
//   Q3. What exactly does turning exceptions off cost you?          -> V9, V10
//   Q4. Which CL_HPP_MINIMUM_OPENCL_VERSION values are usable?      -> V7, V11, V12
//   Q5. Where does the C4996 in a clean examples/08 build come from? -> V7, V13-V15
//   Q6. Is clSetEventCallback deprecated, and whose warning is that? -> V16, V17
//
// Q2 is the one that gets answered wrong most often. V2 shows the old name is
// still HONOURED - it maps straight to CL_HPP_ENABLE_EXCEPTIONS with a deprecation
// pragma. V2 against V3 then flips the outcome using the SAME old name and nothing
// but a different CL_TARGET_OPENCL_VERSION, and V3 against V4 fails identically
// under the old name and the new one. The macro name is a red herring; the pair of
// version macros is what decides.
//
// Q5 needs a two-by-two because the warning has TWO necessary causes and either one
// alone is enough to silence it: cl.hpp must compile its deprecated 2.2 wrapper
// (MINIMUM <= 220), and cl_platform.h must have already frozen the deprecation
// marker on, which happens only if <CL/cl.h> was parsed before <CL/cl.hpp>. V14 has
// both and warns. V7 drops the second, V13 and V15 drop the first, and none of the
// three warns. Reporting only "MINIMUM=300 fixes it" would leave the include order
// - the thing examples/08 actually does wrong - undiscovered.
//
// Q6 exists because chapter 07 RETRACTS a claim, and a retraction needs better
// evidence than the claim it replaces. "clSetEventCallback is deprecated in 3.0" is
// settled by reading cl.h:1479-1485, but "your callback call is not what warns" is
// only settled by compiling that call - once with cl.hpp first, once with cl.h
// first - and observing that the warning tracks the include order and not the call.
//
// Pure ASCII: MSVC's C4819 and the /utf-8 flag make non-ASCII comments work, but
// the cp936 console mangles the error text this probe is here to collect.
#include <stdio.h>
#include <vector>

// ---------------------------------------------------------------------------
// Per-variant macro and include selection.
//
// These are written out longhand rather than driven by parameters because the
// exact set of defined macros IS the thing under test. Anything that normalises
// them would hide the difference between "you defined the wrong name" and "you
// defined the right names with the wrong values".
// ---------------------------------------------------------------------------
#if VARIANT == 1
    // All four macros agree on 1.2. The narrowest supported configuration.
    #define CL_TARGET_OPENCL_VERSION 120
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 120
    #define CL_HPP_MINIMUM_OPENCL_VERSION 120
    #include <CL/cl.hpp>
#elif VARIANT == 2
    // The pre-2.0 macro name, and NOTHING else. cl.hpp:403-405 maps it to
    // CL_HPP_ENABLE_EXCEPTIONS with a deprecation pragma, and cl.hpp:436-438 then
    // defaults CL_HPP_TARGET_OPENCL_VERSION to 300 - which matches the 300 here.
    #define CL_TARGET_OPENCL_VERSION 300
    #define __CL_ENABLE_EXCEPTIONS
    #include <CL/cl.hpp>
#elif VARIANT == 3
    // Identical to V2 except the C target is pinned to 120. cl.hpp does NOT raise
    // it (cl.hpp:452-461 only emits a pragma), so cl.h hides every 2.x/3.x token
    // while cl.hpp still compiles its 3.0 code paths.
    #define CL_TARGET_OPENCL_VERSION 120
    #define __CL_ENABLE_EXCEPTIONS
    #include <CL/cl.hpp>
#elif VARIANT == 4
    // Control for V3: the MODERN macro name with the SAME version mismatch. If
    // this fails too, the old name was never the problem.
    #define CL_TARGET_OPENCL_VERSION 120
    #define CL_HPP_ENABLE_EXCEPTIONS
    #include <CL/cl.hpp>
#elif VARIANT == 5
    // The name the OpenCL 2.x C++ bindings were shipped under. Not present in
    // either SDK on this machine.
    #include <CL/cl2.hpp>
#elif VARIANT == 6
    // The current Khronos name. Also not present - but note that CUDA's cl.hpp
    // calls itself opencl.hpp throughout its own diagnostics, so the content is
    // there under the old filename.
    #include <CL/opencl.hpp>
#elif VARIANT == 7
    // The configuration OpenCL/build.ps1 uses for examples/08-cpp-bindings.
    // CL_HPP_MINIMUM_OPENCL_VERSION is written out explicitly even though
    // cl.hpp:463-464 would default it to the same 200, because 200 is the only
    // value that pairs cleanly with a 300 target and a reader should not have to
    // know the default to see that. Setting it to 120 does not compile - see V11.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 200
    #include <CL/cl.hpp>
#elif VARIANT == 8
    // cl.hpp:477-479 rejects a minimum above the target with a hard #error, so
    // this never reaches the compiler proper.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 120
    #define CL_HPP_MINIMUM_OPENCL_VERSION 300
    #include <CL/cl.hpp>
#elif VARIANT == 9
    // Exceptions OFF, but the body still catches cl::Error. cl::Error is declared
    // inside #if defined(CL_HPP_ENABLE_EXCEPTIONS) (cl.hpp:739-785), so without
    // the macro the type does not exist at all.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 200
    #define PROBE_FORCE_CATCH 1
    #include <CL/cl.hpp>
#elif VARIANT == 10
    // Exceptions OFF and the body written in the error-code style. This is the
    // other half of V9: cl.hpp is fully usable without exceptions, every wrapper
    // call just returns cl_int like its C counterpart.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 200
    #include <CL/cl.hpp>
#elif VARIANT == 11
    // An upstream guard mismatch in cl.hpp, and the reason build.ps1 must not set
    // CL_HPP_MINIMUM_OPENCL_VERSION=120.
    //
    //   definition, cl.hpp:2089   TARGET >= 120 && MINIMUM < 120   -> 300,120: FALSE
    //   six call sites, 7184+     TARGET >= 200 && MINIMUM < 200   -> 300,120: TRUE
    //
    // detail::getContextPlatformVersion is therefore called six times and defined
    // zero times, giving 12 errors (C2039 + C3861 per call). MINIMUM=120 is the
    // single value that falls in the gap between the two guards.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 120
    #include <CL/cl.hpp>
#elif VARIANT == 12
    // Control for V11: MINIMUM=110 satisfies BOTH guards (< 120 and < 200), so the
    // helper is defined and the calls resolve. This is what proves the breakage is
    // specific to exactly 120 rather than to "any minimum below 200".
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 110
    #include <CL/cl.hpp>
#elif VARIANT == 13
    // Same as V7 except MINIMUM is raised to 300. cl.hpp:496-498 then stops defining
    // CL_USE_DEPRECATED_OPENCL_2_2_APIS, so the setReleaseCallback wrapper at
    // cl.hpp:6840-6862 is not compiled at all.
    //
    // Note what this variant does NOT prove on its own: V7 also produces no C4996,
    // so "no warning" here has two candidate causes and V13 alone cannot separate
    // them. V14 and V15 do. See the comment on V14 for the actual mechanism.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 300
    #include <CL/cl.hpp>
#elif VARIANT == 14
    // Reproduces the one warning a clean build of examples/08-cpp-bindings emits:
    //   cl.hpp(6856): warning C4996: 'clSetProgramReleaseCallback'
    //
    // The cause is INCLUDE ORDER, not MINIMUM, and it takes two headers disagreeing:
    //
    //   1. <CL/cl.h> arrives first, so cl_platform.h is parsed now. At line 128 it
    //      asks whether CL_USE_DEPRECATED_OPENCL_2_2_APIS is defined. It is not yet,
    //      so lines 132-133 give CL_API_PREFIX__VERSION_2_2_DEPRECATED the
    //      DEPRECATED form. cl_platform.h is behind __CL_PLATFORM_H (lines 17-18),
    //      so that decision is frozen for the rest of the translation unit.
    //   2. <CL/cl.hpp> then defines CL_USE_DEPRECATED_OPENCL_2_2_APIS at 496-498 -
    //      too late to change step 1 - and compiles the setReleaseCallback wrapper
    //      at 6840. That wrapper calls the still-deprecated C function: C4996.
    //
    // examples/08 does exactly this by accident: main.cpp includes ocl_util.h, which
    // includes <CL/cl.h> at ocl_util.h:27, one line before <CL/cl.hpp>.
    //
    // Against V7 (same macros, cl.hpp first) this isolates include order. The
    // warning is cl.hpp's own code calling a function cl.h marked deprecated; the
    // user's source is not involved.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 200
    #include <CL/cl.h>
    #include <CL/cl.hpp>
#elif VARIANT == 15
    // The other half of the 2x2: cl.h first, as in V14, but MINIMUM=300. The
    // deprecation marker is still frozen on by step 1 above, yet no warning appears,
    // because MINIMUM=300 stops cl.hpp from compiling the wrapper that would call
    // the marked function. This is what proves MINIMUM=300 is an order-independent
    // fix rather than another way of happening to dodge the problem.
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 300
    #include <CL/cl.h>
    #include <CL/cl.hpp>
#elif VARIANT == 16
    // Is clSetEventCallback deprecated under OpenCL 3.0? Chapter 07 RETRACTS a claim
    // that it is, and a retraction deserves the strongest evidence available.
    // cl.h:1479-1485 declares it with CL_API_SUFFIX__VERSION_1_1 and no _DEPRECATED,
    // and cl::Event::setCallback wraps it under "TARGET >= 110" (cl.hpp:3721,
    // declared 3726-3729) - but reading a header is not compiling one. This variant
    // makes the call, in the exact shape the original tutorial uses, and asserts
    // that no C4996 appears anywhere in the translation unit.
    //
    // cl.hpp first, so the setReleaseCallback wrapper cannot contribute a C4996 of
    // its own (V7/V14). Any deprecation warning this variant produced would have to
    // come from the setCallback call itself.
    #define PROBE_USE_SETCALLBACK 1
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 200
    #include <CL/cl.hpp>
#elif VARIANT == 17
    // V16 with cl.h first. The user's setCallback call is byte-identical to V16's;
    // only the include order differs. Whatever warning appears here therefore cannot
    // be attributed to the callback call, which is the cleanest available separation
    // of "cl.hpp's own wrapper" from "your code".
    //
    // A second include-order effect was expected here and did NOT materialise, which
    // is worth recording because it looks like it should. cl.hpp:561-563 defines
    // CL_CALLBACK as empty, while cl_platform.h:33-35 defines it as __stdcall on
    // Windows - so it seemed that whichever header was parsed first would decide the
    // calling convention in setCallback's parameter type, and that a captureless
    // (cdecl) lambda would then fail to convert on x86. Measured: CL_CALLBACK expands
    // to __stdcall in BOTH orders, on x86 and x64 alike, because cl.hpp includes
    // <CL/opencl.h> at line 525 - before its own fallback at 561. The fallback never
    // fires when the C headers are reachable, and they always are. Separately, MSVC
    // on x86 accepts the lambda-to-__stdcall-pointer conversion anyway (a standalone
    // two-line test compiles clean), so the callback shape the original tutorial uses
    // is safe on both architectures. Include order changes the C4996 and nothing else.
    #define PROBE_USE_SETCALLBACK 1
    #define CL_TARGET_OPENCL_VERSION 300
    #define CL_HPP_ENABLE_EXCEPTIONS
    #define CL_HPP_TARGET_OPENCL_VERSION 300
    #define CL_HPP_MINIMUM_OPENCL_VERSION 200
    #include <CL/cl.h>
    #include <CL/cl.hpp>
#else
    #error "VARIANT must be 1..17"
#endif

#ifdef PROBE_USE_SETCALLBACK
// CL_CALLBACK's expansion is printed rather than assumed. The plausible guess is that
// include order decides it - cl.hpp:561-563 defines it as empty, cl_platform.h:33-35
// defines it as __stdcall - and that guess is wrong, because cl.hpp includes
// <CL/opencl.h> at line 525, ahead of its own fallback. build.ps1 requires the exact
// string below on BOTH V16 and V17, so "include order does not change the calling
// convention" is an assertion that can fail rather than a sentence in a comment.
#define PROBE_STR2(x) #x
#define PROBE_STR(x) PROBE_STR2(x)
#pragma message("CL_CALLBACK = " PROBE_STR(CL_CALLBACK))

// Compiled by V16 and V17, never called. Its only job is to make the compiler look
// at cl::Event::setCallback so that "no C4996" is a statement about that call rather
// than about a call nobody made.
//
// Not called on purpose: this probe measures what the compiler ACCEPTS, and a live
// call on a default-constructed cl::Event would hand a null cl_event to the driver,
// come back CL_INVALID_EVENT, and turn a compile-level result into a spurious
// non-zero exit code. /W3 does not warn about an unreferenced static function
// (that is C4505, level 4), so leaving it uncalled costs nothing.
static cl_int probe_setCallback(cl::Event& ev) {
    return ev.setCallback(CL_COMPLETE, [](cl_event, cl_int, void*) { }, nullptr);
}
#endif

// ---------------------------------------------------------------------------
// The body. Deliberately trivial: this probe measures whether the HEADER compiles
// under a macro set, not whether OpenCL works. Enumerating platforms is the
// smallest call that touches the bindings and also proves the link succeeded.
// ---------------------------------------------------------------------------
static int probe_body(void) {
    std::vector<cl::Platform> platforms;

#if defined(PROBE_FORCE_CATCH) || defined(CL_HPP_ENABLE_EXCEPTIONS)
    // With exceptions on, every binding call is void-or-value and failures arrive
    // as a thrown cl::Error carrying both the code and a string naming the entry
    // point that produced it.
    try {
        cl::Platform::get(&platforms);
    } catch (const cl::Error& e) {
        printf("[probe] cl::Error %d (%s)\n", e.err(), e.what());
        return 1;
    }
#else
    // Without exceptions the same call returns the cl_int, so the error handling is
    // exactly as explicit as it was in the C API - nothing is hidden, nothing is
    // thrown, and no stack unwinding machinery is pulled into the binary.
    cl_int err = cl::Platform::get(&platforms);
    if (err != CL_SUCCESS) {
        printf("[probe] cl::Platform::get -> %d\n", err);
        return 1;
    }
#endif

    printf("[probe] VARIANT=%d compiled, linked and ran: %zu platform(s)\n",
           VARIANT, platforms.size());
    for (size_t i = 0; i < platforms.size(); i++) {
        printf("[probe]   platform[%zu] = %s\n", i,
               platforms[i].getInfo<CL_PLATFORM_NAME>().c_str());
    }
    return 0;
}

int main(void) {
    return probe_body();
}
