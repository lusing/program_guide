// clinfo-probe: enumerate every OpenCL platform and device on this machine and
// print the capability metadata that every claim in docs/ is based on.
//
// This is the "device metadata" verification channel. It proves what the driver
// SAYS the device can do - version strings, IL support, SVM bitmask, work-group
// limits, extension list. It proves nothing about runtime behaviour; that is what
// examples/ and tools/cl-build-probe are for.
//
// All printed output is ASCII on purpose: the Windows console here is cp936, so
// Chinese output arrives garbled and cannot be pasted into README.md as evidence.
#define CL_TARGET_OPENCL_VERSION 300
#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void strInfo(cl_device_id d, cl_device_info q, const char* label) {
    char buf[2048] = {0};
    if (clGetDeviceInfo(d, q, sizeof(buf), buf, NULL) == CL_SUCCESS && buf[0])
        printf("    %-34s %s\n", label, buf);
    else
        printf("    %-34s (unavailable)\n", label);
}

// CL_DEVICE_MAX_WORK_GROUP_SIZE returns size_t, NOT cl_uint.
//
// This is a real trap and the reason this helper exists separately from uintInfo:
// pass a 4-byte cl_uint for an 8-byte size_t and the driver rejects the call with
// CL_INVALID_VALUE, leaving the variable at its initialiser. You then print a
// confident "max work group size: 0" that is pure fiction. An earlier revision of
// this probe had exactly that bug. Query into size_t and print with %zu.
static void sizeInfo(cl_device_id d, cl_device_info q, const char* label) {
    size_t v = 0;
    if (clGetDeviceInfo(d, q, sizeof(v), &v, NULL) == CL_SUCCESS)
        printf("    %-34s %zu\n", label, v);
    else
        printf("    %-34s (unavailable)\n", label);
}

static void ulongInfo(cl_device_id d, cl_device_info q, const char* label) {
    cl_ulong v = 0;
    if (clGetDeviceInfo(d, q, sizeof(v), &v, NULL) == CL_SUCCESS)
        printf("    %-34s %llu (%.1f MiB)\n", label, (unsigned long long)v, (double)v / 1048576.0);
    else
        printf("    %-34s (unavailable)\n", label);
}

// Same as ulongInfo but with a human-readable binary unit. Local memory is tens to
// hundreds of KiB on every device here, and the tiling limits in docs/06 are argued
// from that number, so printing it as "(0.0 MiB)" would throw away the only digits
// that matter. The same formatter is reused for max_constant_buffer_size, which on
// the Intel iGPU is 3.2 GB - a fixed KiB scale printed that as "3322070 KiB".
// Below 1 MiB the output is byte-for-byte what it always was.
static void ulongInfoKiB(cl_device_id d, cl_device_info q, const char* label) {
    cl_ulong v = 0;
    if (clGetDeviceInfo(d, q, sizeof(v), &v, NULL) == CL_SUCCESS) {
        if (v < 1024ULL * 1024ULL)
            printf("    %-34s %llu (%.0f KiB)\n", label, (unsigned long long)v, (double)v / 1024.0);
        else
            printf("    %-34s %llu (%.1f MiB)\n", label, (unsigned long long)v,
                   (double)v / (1024.0 * 1024.0));
    } else {
        printf("    %-34s (unavailable)\n", label);
    }
}

static void uintInfo(cl_device_id d, cl_device_info q, const char* label) {
    cl_uint v = 0;
    if (clGetDeviceInfo(d, q, sizeof(v), &v, NULL) == CL_SUCCESS)
        printf("    %-34s %u\n", label, v);
    else
        printf("    %-34s (unavailable)\n", label);
}

static void boolInfo(cl_device_id d, cl_device_info q, const char* label) {
    cl_bool v = CL_FALSE;
    if (clGetDeviceInfo(d, q, sizeof(v), &v, NULL) == CL_SUCCESS)
        printf("    %-34s %s\n", label, v ? "CL_TRUE" : "CL_FALSE");
    else
        printf("    %-34s (unavailable)\n", label);
}

// Decode an OpenCL 3.0 array-of-cl_name_version property, e.g.
// CL_DEVICE_OPENCL_C_ALL_VERSIONS. Two-call idiom: first for the byte count, then
// for the data, so the entry count is derived rather than assumed.
//
// This query exists because the legacy CL_DEVICE_OPENCL_C_VERSION string turned out
// to be useless as a predictor on this machine: the iGPU says "OpenCL C 1.2" and
// then compiles a 2.0 builtin happily under -cl-std=CL3.0, while the CPU device says
// "OpenCL C 3.0" and rejects that same builtin unless -cl-std is passed explicitly.
// The array is the authoritative replacement, and printing it side by side with the
// string is what makes the divergence visible instead of merely asserted.
static void nameVersionList(cl_device_id d, cl_device_info q, const char* label) {
    size_t bytes = 0;
    if (clGetDeviceInfo(d, q, 0, NULL, &bytes) != CL_SUCCESS || bytes == 0) {
        printf("    %-34s (unavailable)\n", label);
        return;
    }
    cl_name_version* v = (cl_name_version*)malloc(bytes);
    if (!v) { printf("    %-34s (out of memory)\n", label); return; }

    if (clGetDeviceInfo(d, q, bytes, v, NULL) == CL_SUCCESS) {
        size_t n = bytes / sizeof(cl_name_version);

        // ALL_VERSIONS carries the same name ("OpenCL C") on every entry, so printing
        // it per entry is noise. FEATURES carries a distinct name per entry
        // (__opencl_c_fp64, __opencl_c_subgroups, ...) and there the name IS the
        // datum: fourteen identical "3.0"s would tell the reader nothing. One
        // comparison pass decides which of the two shapes to print.
        int sameName = 1;
        for (size_t i = 1; i < n && sameName; i++)
            if (strcmp(v[i].name, v[0].name) != 0) sameName = 0;

        if (sameName) {
            printf("    %-34s %s:", label, v[0].name);
            for (size_t i = 0; i < n; i++)
                printf(" %u.%u", CL_VERSION_MAJOR(v[i].version), CL_VERSION_MINOR(v[i].version));
            printf("  (%zu entries)\n", n);
        } else {
            printf("    %-34s (%zu entries)\n", label, n);
            for (size_t i = 0; i < n; i++)
                printf("      %-38s %u.%u\n", v[i].name,
                       CL_VERSION_MAJOR(v[i].version), CL_VERSION_MINOR(v[i].version));
        }
    } else {
        printf("    %-34s (query failed)\n", label);
    }
    free(v);
}

// CL_DEVICE_NUMERIC_VERSION packs major/minor/patch into one cl_uint with the bit
// widths from cl.h:921-923. Printing the raw number would force every reader to do
// that shift by hand, and the shift is exactly where a mistake hides.
static void numericVersionInfo(cl_device_id d, const char* label) {
    cl_version v = 0;
    if (clGetDeviceInfo(d, CL_DEVICE_NUMERIC_VERSION, sizeof(v), &v, NULL) == CL_SUCCESS)
        printf("    %-34s %u.%u.%u  (raw 0x%08X)\n", label,
               CL_VERSION_MAJOR(v), CL_VERSION_MINOR(v), CL_VERSION_PATCH(v), (unsigned)v);
    else
        printf("    %-34s (unavailable)\n", label);
}

static const char* devTypeName(cl_device_type t) {
    switch (t) {
        case CL_DEVICE_TYPE_CPU:         return "CPU";
        case CL_DEVICE_TYPE_GPU:         return "GPU";
        case CL_DEVICE_TYPE_ACCELERATOR: return "ACCELERATOR";
        case CL_DEVICE_TYPE_DEFAULT:     return "DEFAULT";
        default:                         return "OTHER/CUSTOM";
    }
}

// Extensions worth calling out in the tutorial, filtered out of the full list so
// the output stays readable. Everything else is summarised by count only.
static const char* const kInteresting[] = {
    "cl_khr_il_program", "cl_khr_spirv_no_integer_wrap_decoration",
    "cl_khr_subgroups", "cl_khr_subgroup_ballot", "cl_khr_subgroup_shuffle",
    "cl_khr_fp64", "cl_khr_fp16", "cl_khr_int64_base_atomics",
    "cl_khr_3d_image_writes", "cl_khr_byte_addressable_store",
    "cl_khr_create_command_queue", "cl_khr_priority_hints",
    "cl_khr_command_buffer", "cl_khr_external_memory",
    "cl_khr_d3d11_sharing", "cl_khr_dx9_media_sharing", "cl_khr_egl_image",
    "cl_khr_gl_depth_images",
    "cl_intel_subgroups", "cl_intel_required_subgroup_size",
    "cl_intel_subgroups_short", "cl_intel_planar_image",
    "cl_intel_packed_yuv", "cl_intel_planar_yuv",
    "cl_intel_va_api_media_sharing", "cl_intel_sharing_format_query",
    "cl_intel_device_side_avc_motion_estimation",
    NULL
};

int main(void) {
    cl_uint numPlatforms = 0;
    cl_int err = clGetPlatformIDs(0, NULL, &numPlatforms);
    printf("clGetPlatformIDs(count) -> %d, numPlatforms = %u\n", err, numPlatforms);
    if (err != CL_SUCCESS || numPlatforms == 0) {
        printf("!! no OpenCL platform found (missing ICD loader, or no driver registered)\n");
        printf("[RESULT] FAIL\n");
        return 1;
    }

    cl_platform_id* platforms = (cl_platform_id*)malloc(numPlatforms * sizeof(cl_platform_id));
    clGetPlatformIDs(numPlatforms, platforms, NULL);

    int deviceCount = 0;
    int gpuWithIl = 0, gpuWithoutIl = 0, oclC3Devices = 0;

    for (cl_uint p = 0; p < numPlatforms; p++) {
        char v[256] = {0}, n[256] = {0}, vend[256] = {0}, prof[256] = {0};
        clGetPlatformInfo(platforms[p], CL_PLATFORM_VERSION, sizeof(v), v, NULL);
        clGetPlatformInfo(platforms[p], CL_PLATFORM_NAME, sizeof(n), n, NULL);
        clGetPlatformInfo(platforms[p], CL_PLATFORM_VENDOR, sizeof(vend), vend, NULL);
        // FULL_PROFILE or EMBEDDED_PROFILE. This is the real answer to "is there an
        // OpenCL ES?" - there is no such product, only this profile string.
        clGetPlatformInfo(platforms[p], CL_PLATFORM_PROFILE, sizeof(prof), prof, NULL);
        printf("\n=== Platform %u: %s ===\n", p, n);
        printf("    %-34s %s\n", "CL_PLATFORM_VERSION", v);
        printf("    %-34s %s\n", "CL_PLATFORM_VENDOR", vend);
        printf("    %-34s %s\n", "CL_PLATFORM_PROFILE", prof);

        cl_uint numDev = 0;
        if (clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_ALL, 0, NULL, &numDev) != CL_SUCCESS || numDev == 0) {
            printf("    (no devices)\n");
            continue;
        }
        cl_device_id* devs = (cl_device_id*)malloc(numDev * sizeof(cl_device_id));
        clGetDeviceIDs(platforms[p], CL_DEVICE_TYPE_ALL, numDev, devs, NULL);

        for (cl_uint i = 0; i < numDev; i++) {
            cl_device_type t = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_TYPE, sizeof(t), &t, NULL);
            char dn[256] = {0};
            clGetDeviceInfo(devs[i], CL_DEVICE_NAME, sizeof(dn), dn, NULL);
            printf("\n  --- Platform %u Device %u: %s [%s] ---\n", p, i, dn, devTypeName(t));
            deviceCount++;

            strInfo(devs[i], CL_DEVICE_VERSION, "CL_DEVICE_VERSION");
            strInfo(devs[i], CL_DEVICE_OPENCL_C_VERSION, "CL_DEVICE_OPENCL_C_VERSION");
            strInfo(devs[i], CL_DRIVER_VERSION, "CL_DRIVER_VERSION");

            // The distinction that governs the whole tutorial: CL_DEVICE_VERSION may
            // say "OpenCL 3.0" while CL_DEVICE_OPENCL_C_VERSION says only 1.2. 3.0 made
            // every 2.x feature optional, so the language level - not the platform
            // version - decides which kernels you may write.
            char ocver[128] = {0};
            if (clGetDeviceInfo(devs[i], CL_DEVICE_OPENCL_C_VERSION, sizeof(ocver), ocver, NULL) == CL_SUCCESS
                && strstr(ocver, "3.0")) {
                oclC3Devices++;
            }

            // Printed directly under the legacy string on purpose. The string is what
            // almost every tutorial tells you to read, and on this machine it is wrong
            // in both directions (see the nameVersionList comment above). Putting the
            // authoritative OpenCL 3.0 queries next to it lets docs/06 quote the two
            // side by side instead of asking the reader to take the claim on faith.
            nameVersionList(devs[i], CL_DEVICE_OPENCL_C_ALL_VERSIONS, "opencl_c_all_versions");
            nameVersionList(devs[i], CL_DEVICE_OPENCL_C_FEATURES, "opencl_c_features");

            uintInfo(devs[i], CL_DEVICE_MAX_COMPUTE_UNITS, "max_compute_units");
            sizeInfo(devs[i], CL_DEVICE_MAX_WORK_GROUP_SIZE, "max_work_group_size");
            uintInfo(devs[i], CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS, "max_work_item_dimensions");
            {
                size_t wis[3] = {0, 0, 0};
                if (clGetDeviceInfo(devs[i], CL_DEVICE_MAX_WORK_ITEM_SIZES, sizeof(wis), wis, NULL) == CL_SUCCESS)
                    printf("    %-34s %zu x %zu x %zu\n", "max_work_item_sizes", wis[0], wis[1], wis[2]);
            }
            ulongInfo(devs[i], CL_DEVICE_GLOBAL_MEM_SIZE, "global_mem_size");
            ulongInfoKiB(devs[i], CL_DEVICE_LOCAL_MEM_SIZE, "local_mem_size");
            ulongInfo(devs[i], CL_DEVICE_MAX_MEM_ALLOC_SIZE, "max_mem_alloc_size");
            uintInfo(devs[i], CL_DEVICE_ADDRESS_BITS, "address_bits");
            boolInfo(devs[i], CL_DEVICE_IMAGE_SUPPORT, "image_support");
            boolInfo(devs[i], CL_DEVICE_COMPILER_AVAILABLE, "compiler_available");
            boolInfo(devs[i], CL_DEVICE_LINKER_AVAILABLE, "linker_available");
            {
                cl_device_local_mem_type lmt = 0;
                if (clGetDeviceInfo(devs[i], CL_DEVICE_LOCAL_MEM_TYPE, sizeof(lmt), &lmt, NULL) == CL_SUCCESS)
                    printf("    %-34s %s\n", "local_mem_type",
                           lmt == CL_LOCAL ? "CL_LOCAL" : (lmt == CL_GLOBAL ? "CL_GLOBAL" : "NONE"));
            }

            // CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE. The old tutorial spelled this
            // CL_DEVICE_CONSTANT_BUFFER_SIZE, which is not a macro in cl.h at all -
            // code using that name does not compile. Printing the real value here
            // makes the correction checkable instead of merely asserted.
            ulongInfoKiB(devs[i], CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE, "max_constant_buffer_size");
            uintInfo(devs[i], CL_DEVICE_MAX_CONSTANT_ARGS, "max_constant_args");

            // Sub-buffer origins must be aligned to this, in BITS. Dividing by 8 is
            // the caller's job and forgetting it makes every clCreateSubBuffer fail
            // with -30 for no obvious reason.
            uintInfo(devs[i], CL_DEVICE_MEM_BASE_ADDR_ALIGN, "mem_base_addr_align_bits");

            // Whether this device offers out-of-order queues and profiling at all.
            // examples/07 branches on exactly these two bits.
            {
                cl_command_queue_properties qp = 0;
                if (clGetDeviceInfo(devs[i], CL_DEVICE_QUEUE_PROPERTIES, sizeof(qp), &qp, NULL) == CL_SUCCESS)
                    printf("    %-34s 0x%llX (out_of_order=%d profiling=%d)\n",
                           "queue_properties", (unsigned long long)qp,
                           (int)((qp & CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE) != 0),
                           (int)((qp & CL_QUEUE_PROFILING_ENABLE) != 0));
            }

            // OpenCL 3.0 turned 2.x features optional, so each must be queried.
            // The raw packed value is printed next to the decoded one because the
            // packing (10/10/12 bits, cl.h:921-923) is the sort of thing readers are
            // told about but never shown.
            numericVersionInfo(devs[i], "numeric_version");

            cl_device_svm_capabilities svm = 0;
            if (clGetDeviceInfo(devs[i], CL_DEVICE_SVM_CAPABILITIES, sizeof(svm), &svm, NULL) == CL_SUCCESS)
                printf("    %-34s 0x%llX (coarse=%d fine=%d fine_system=%d atomics=%d)\n",
                       "svm_capabilities", (unsigned long long)svm,
                       (int)((svm & CL_DEVICE_SVM_COARSE_GRAIN_BUFFER) != 0),
                       (int)((svm & CL_DEVICE_SVM_FINE_GRAIN_BUFFER) != 0),
                       (int)((svm & CL_DEVICE_SVM_FINE_GRAIN_SYSTEM) != 0),
                       (int)((svm & CL_DEVICE_SVM_ATOMICS) != 0));
            else
                printf("    %-34s (query unsupported)\n", "svm_capabilities");

            // CL_DEVICE_IL_VERSION is a STRING, not a cl_bool.
            //
            // The original tutorial queried it into a cl_bool and then tested the value,
            // which is doubly wrong: the driver rejects the size mismatch, and even a
            // successful read would give you the first byte of a string, not a flag.
            // The correct test is "is the returned string non-empty".
            size_t ilVerSz = 0;
            if (clGetDeviceInfo(devs[i], CL_DEVICE_IL_VERSION, 0, NULL, &ilVerSz) == CL_SUCCESS && ilVerSz > 1) {
                char* il = (char*)malloc(ilVerSz);
                clGetDeviceInfo(devs[i], CL_DEVICE_IL_VERSION, ilVerSz, il, NULL);
                printf("    %-34s %s\n", "il_version", il);
                if (t == CL_DEVICE_TYPE_GPU) gpuWithIl++;
                free(il);
            } else {
                printf("    %-34s (empty => no SPIR-V, clCreateProgramWithIL unusable)\n", "il_version");
                if (t == CL_DEVICE_TYPE_GPU) gpuWithoutIl++;
            }

            size_t extSz = 0;
            clGetDeviceInfo(devs[i], CL_DEVICE_EXTENSIONS, 0, NULL, &extSz);
            if (extSz > 1) {
                char* ext = (char*)malloc(extSz);
                clGetDeviceInfo(devs[i], CL_DEVICE_EXTENSIONS, extSz, ext, NULL);
                printf("    extensions (filtered):\n");
                int shown = 0;
                for (int k = 0; kInteresting[k]; k++)
                    if (strstr(ext, kInteresting[k])) { printf("      + %s\n", kInteresting[k]); shown++; }
                if (shown == 0) printf("      (none of the tracked extensions present)\n");
                int cnt = 0;
                for (char* tok = strtok(ext, " "); tok; tok = strtok(NULL, " ")) cnt++;
                printf("    %-34s %d\n", "total_extension_count", cnt);
                free(ext);
            }
        }
        free(devs);
    }

    printf("\n=== summary ===\n");
    printf("    %-34s %u\n", "platforms", numPlatforms);
    printf("    %-34s %d\n", "devices", deviceCount);
    printf("    %-34s %d\n", "devices_with_opencl_c_3_0", oclC3Devices);
    printf("    %-34s %d\n", "gpus_with_il_support", gpuWithIl);
    printf("    %-34s %d\n", "gpus_without_il_support", gpuWithoutIl);

    free(platforms);

    // Same contract as every example: exit 0 + [RESULT] PASS when the probe itself
    // succeeded, so build.ps1 can gate on it uniformly.
    if (deviceCount == 0) { printf("[RESULT] FAIL\n"); return 1; }
    printf("[RESULT] PASS\n");
    return 0;
}
