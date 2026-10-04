// examples/06-image-brightness - image2d_t, samplers, and a silent coordinate bug.
//
// The job is trivial: add 0.5 to the RGB of every pixel and clamp to [0,1]. What is
// NOT trivial is the sampler. A sampler decides whether read_imagef's coordinates are
// integer texel indices or normalized [0,1] fractions, and the two are not
// interchangeable. Passing pixel indices to a sampler configured for normalized
// coordinates does not fail, warn, or crash - the driver computes s = coord * width,
// so every coordinate except 0 saturates against CLAMP_TO_EDGE and a 4096-color
// gradient collapses to four values. Case B below reproduces that on purpose.
//
// Six cases run. Case B is EXPECTED TO PRODUCE A WRONG IMAGE and case E is EXPECTED
// TO BE REJECTED AT LAUNCH. The example passes only if each case does what it is
// documented to do.
//
// Contract: exit 0 + "[RESULT] PASS".
#include "ocl_util.h"

#define DELTA 0.5
#define EPS   1e-5

typedef struct {
    cl_int launchErr;
    int    pixels;         // w*h useful pixels
    int    wrong;          // pixels outside EPS of the CPU reference
    int    distinctColors; // distinct RGBA quadruples in the output
    double maxAbsErr;
    size_t globalX, globalY;
} ImageRun;

// Build the RGBA/float test pattern: R ramps across x, G ramps down y, B is a
// constant. Every channel lands on an exactly representable value, so any deviation
// in the result is a coordinate error rather than rounding noise.
static void makeTestImage(float* px, int w, int h) {
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            float* p = px + ((size_t)y * w + x) * 4;
            p[0] = (w > 1) ? (float)x / (float)(w - 1) : 0.0f;
            p[1] = (h > 1) ? (float)y / (float)(h - 1) : 0.0f;
            p[2] = 0.25f;
            p[3] = 1.0f;
        }
    }
}

// Run one brightness kernel over a w x h RGBA/CL_FLOAT image and read the result back.
//
// tile is the per-dimension local size. roundGws=1 rounds each global dimension up to
// a multiple of tile, which an OpenCL 1.2 device requires; roundGws=0 passes the raw
// image dimensions and demonstrates the -54 rejection.
static int runImage(cl_context context, cl_command_queue queue, cl_device_id device,
                    cl_program program, const char* kernelName,
                    const float* srcPixels, int w, int h, size_t tile,
                    int useHostSampler, int roundGws,
                    float* dstPixels, ImageRun* out) {
    out->launchErr = CL_SUCCESS;
    out->pixels = w * h;
    out->wrong = 0;
    out->distinctColors = 0;
    out->maxAbsErr = 0.0;
    out->globalX = 0;
    out->globalY = 0;

    cl_int err = CL_SUCCESS;
    cl_kernel kernel = clCreateKernel(program, kernelName, &err);
    if (!kernel) { printf("    [FAIL] clCreateKernel(%s) -> %s\n", kernelName, ocl_err_name(err)); return -1; }

    cl_image_format fmt;
    fmt.image_channel_order     = CL_RGBA;
    fmt.image_channel_data_type = CL_FLOAT;

    cl_image_desc desc;
    memset(&desc, 0, sizeof(desc));
    desc.image_type   = CL_MEM_OBJECT_IMAGE2D;
    desc.image_width  = (size_t)w;
    desc.image_height = (size_t)h;
    // row_pitch 0 asks the driver to pack the rows itself, which is what makes
    // CL_MEM_COPY_HOST_PTR accept a plain w*h*4 float array from the host.
    desc.image_row_pitch = 0;

    cl_mem imgSrc = clCreateImage(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                  &fmt, &desc, (void*)srcPixels, &err);
    if (!imgSrc) {
        printf("    [FAIL] clCreateImage(src %dx%d RGBA/CL_FLOAT) -> %s\n", w, h, ocl_err_name(err));
        clReleaseKernel(kernel);
        return -1;
    }
    cl_mem imgDst = clCreateImage(context, CL_MEM_WRITE_ONLY, &fmt, &desc, NULL, &err);
    if (!imgDst) {
        printf("    [FAIL] clCreateImage(dst) -> %s\n", ocl_err_name(err));
        clReleaseMemObject(imgSrc); clReleaseKernel(kernel);
        return -1;
    }

    // A sampler created on the host, so the address mode can vary at run time.
    // clCreateSampler is DEPRECATED since OpenCL 2.0 in favour of
    // clCreateSamplerWithProperties - cl.h files it under "Deprecated OpenCL 2.0
    // APIs" - but it is not removed, it is still present in OpenCL 3.0 and still
    // the clearest way to show the three settings; the replacement takes the same
    // three values as a property list. See docs/05-core-concepts.md section 5.4.1.
    cl_sampler sampler = NULL;
    if (useHostSampler) {
        // Suppressed on purpose: the deprecation is acknowledged above, and the build
        // output should stay readable.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4996)
#endif
        sampler = clCreateSampler(context, CL_FALSE, CL_ADDRESS_CLAMP_TO_EDGE,
                                  CL_FILTER_NEAREST, &err);
#if defined(_MSC_VER)
#pragma warning(pop)
#endif
        if (!sampler) {
            printf("    [FAIL] clCreateSampler -> %s\n", ocl_err_name(err));
            clReleaseMemObject(imgSrc); clReleaseMemObject(imgDst); clReleaseKernel(kernel);
            return -1;
        }
    }

    clSetKernelArg(kernel, 0, sizeof(cl_mem), &imgSrc);
    clSetKernelArg(kernel, 1, sizeof(cl_mem), &imgDst);
    int nextArg = 2;
    if (useHostSampler) {
        // sizeof(cl_sampler), the opaque handle - not the size of some sampler struct.
        clSetKernelArg(kernel, nextArg++, sizeof(cl_sampler), &sampler);
    }
    float delta = (float)DELTA;
    clSetKernelArg(kernel, nextArg++, sizeof(float), &delta);

    size_t local[2] = { tile, tile };
    size_t global[2];
    if (roundGws) {
        global[0] = ocl_round_up((size_t)w, tile);
        global[1] = ocl_round_up((size_t)h, tile);
    } else {
        global[0] = (size_t)w;
        global[1] = (size_t)h;
    }
    out->globalX = global[0];
    out->globalY = global[1];
    printf("    %s: %dx%d image, global={%zu,%zu} local={%zu,%zu}%s\n",
           kernelName, w, h, global[0], global[1], local[0], local[1],
           useHostSampler ? ", host cl_sampler" : ", const sampler_t in kernel");

    err = clEnqueueNDRangeKernel(queue, kernel, 2, NULL, global, local, 0, NULL, NULL);
    out->launchErr = err;
    if (err != CL_SUCCESS) {
        printf("    launch rejected -> %d %s\n", err, ocl_err_name(err));
        if (sampler) clReleaseSampler(sampler);
        clReleaseMemObject(imgSrc); clReleaseMemObject(imgDst); clReleaseKernel(kernel);
        return 0;   // a rejected launch is an informative outcome, not a harness error
    }

    size_t origin[3] = { 0, 0, 0 };
    size_t region[3] = { (size_t)w, (size_t)h, 1 };
    err = clEnqueueReadImage(queue, imgDst, CL_TRUE, origin, region, 0, 0, dstPixels, 0, NULL, NULL);
    if (err != CL_SUCCESS) {
        printf("    [FAIL] clEnqueueReadImage -> %s\n", ocl_err_name(err));
        if (sampler) clReleaseSampler(sampler);
        clReleaseMemObject(imgSrc); clReleaseMemObject(imgDst); clReleaseKernel(kernel);
        return -1;
    }

    // CPU reference: same clamp, computed in double so the comparison has no
    // rounding of its own to blame.
    int wrong = 0;
    double maxAbsErr = 0.0;
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            const float* s = srcPixels + ((size_t)y * w + x) * 4;
            const float* g = dstPixels + ((size_t)y * w + x) * 4;
            double want[4];
            want[0] = s[0] + DELTA; if (want[0] > 1.0) want[0] = 1.0;
            want[1] = s[1] + DELTA; if (want[1] > 1.0) want[1] = 1.0;
            want[2] = s[2] + DELTA; if (want[2] > 1.0) want[2] = 1.0;
            want[3] = s[3];
            for (int c = 0; c < 4; c++) {
                double diff = (double)g[c] - want[c];
                if (diff < 0) diff = -diff;
                if (diff > maxAbsErr) maxAbsErr = diff;
                if (diff > EPS) {
                    if (wrong < 3)
                        printf("    mismatch at (%d,%d) ch%d: got %f want %f\n", x, y, c, g[c], want[c]);
                    wrong++;
                    break;   // count the pixel once, not once per channel
                }
            }
        }
    }

    // Count the distinct colors in the output. This is the diagnostic that
    // identifies case B's failure mode precisely.
    //
    // With CLK_NORMALIZED_COORDS_TRUE the driver multiplies the coordinate by the
    // image dimension: s = coord.x * width. Handing it integer pixel coordinates
    // therefore gives s = x * 64, which CLAMP_TO_EDGE pins to texel 63 for every
    // x >= 1 - but x == 0 gives s == 0 and lands on texel 0. The result is not one
    // flat color but exactly FOUR: texel(0,0) at the origin, texel(0,63) down
    // column 0, texel(63,0) along row 0, and texel(63,63) everywhere else. A
    // 4096-pixel gradient collapsing to four values is the signature.
    int distinctColors = 0;
    for (int i = 0; i < w * h; i++) {
        const float* p = dstPixels + (size_t)i * 4;
        int seen = 0;
        for (int j = 0; j < i && !seen; j++) {
            const float* q = dstPixels + (size_t)j * 4;
            seen = (p[0] == q[0] && p[1] == q[1] && p[2] == q[2] && p[3] == q[3]);
        }
        if (!seen) distinctColors++;
    }

    out->wrong = wrong;
    out->maxAbsErr = maxAbsErr;
    out->distinctColors = distinctColors;
    printf("    %d/%d pixels correct, max abs err %.3e, %d distinct output colors\n",
           out->pixels - wrong, out->pixels, maxAbsErr, distinctColors);

    if (sampler) clReleaseSampler(sampler);
    clReleaseMemObject(imgSrc); clReleaseMemObject(imgDst); clReleaseKernel(kernel);
    return 0;
}

static const char* channelTypeName(cl_uint t) {
    switch (t) {
    case CL_SNORM_INT8:        return "SNORM_INT8";
    case CL_SNORM_INT16:       return "SNORM_INT16";
    case CL_UNORM_INT8:        return "UNORM_INT8";
    case CL_UNORM_INT16:       return "UNORM_INT16";
    case CL_UNORM_SHORT_565:   return "UNORM_SHORT_565";
    case CL_UNORM_SHORT_555:   return "UNORM_SHORT_555";
    case CL_UNORM_INT_101010:  return "UNORM_INT_101010";
    case CL_SIGNED_INT8:       return "SIGNED_INT8";
    case CL_SIGNED_INT16:      return "SIGNED_INT16";
    case CL_SIGNED_INT32:      return "SIGNED_INT32";
    case CL_UNSIGNED_INT8:     return "UNSIGNED_INT8";
    case CL_UNSIGNED_INT16:    return "UNSIGNED_INT16";
    case CL_UNSIGNED_INT32:    return "UNSIGNED_INT32";
    case CL_HALF_FLOAT:        return "HALF_FLOAT";
    case CL_FLOAT:             return "FLOAT";
    default:                   return "(other)";
    }
}

// The old tutorial listed "CL_RGBA, CL_ARGB, CL_BGRA 等通道顺序" as though any
// channel order you can name is usable. It is not: which ORDERS a device accepts
// is device-specific and only clGetSupportedImageFormats knows. Printing the
// histogram turns that claim into a measured fact rather than an argument from
// the specification.
//
// Returns NULL for anything cl.h does not define. The iGPU reports eight further
// orders beyond this list - vendor extension values with no portable name - and
// the caller prints those as raw hex, because "(other)" repeated nine times is
// not information.
static const char* channelOrderName(cl_uint o) {
    switch (o) {
    case CL_R:         return "R";
    case CL_A:         return "A";
    case CL_RG:        return "RG";
    case CL_RA:        return "RA";
    case CL_RGB:       return "RGB";
    case CL_RGBA:      return "RGBA";
    case CL_BGRA:      return "BGRA";
    case CL_ARGB:      return "ARGB";
    case CL_INTENSITY: return "INTENSITY";
    case CL_LUMINANCE: return "LUMINANCE";
    case CL_Rx:        return "Rx";
    case CL_RGx:       return "RGx";
    case CL_RGBx:      return "RGBx";
    case CL_DEPTH:     return "DEPTH";
    case CL_sRGB:      return "sRGB";
    case CL_sRGBx:     return "sRGBx";
    case CL_sRGBA:     return "sRGBA";
    case CL_sBGRA:     return "sBGRA";
    case CL_ABGR:      return "ABGR";
    default:           return NULL;
    }
}

// Print what this device actually supports for images, and confirm that the format
// this example needs is among the supported ones. Querying is not a formality:
// CL_RGBA/CL_FLOAT is required by the spec for 2D images, but the channel ORDER
// availability for exotic types varies, and CL_DEVICE_IMAGE_SUPPORT is CL_FALSE on
// some CPU implementations.
static int reportImageCaps(cl_context context, cl_device_id device) {
    cl_bool imgSupport = CL_FALSE;
    clGetDeviceInfo(device, CL_DEVICE_IMAGE_SUPPORT, sizeof(imgSupport), &imgSupport, NULL);

    size_t maxW = 0, maxH = 0;
    clGetDeviceInfo(device, CL_DEVICE_IMAGE2D_MAX_WIDTH,  sizeof(maxW), &maxW, NULL);
    clGetDeviceInfo(device, CL_DEVICE_IMAGE2D_MAX_HEIGHT, sizeof(maxH), &maxH, NULL);
    cl_uint maxSamplers = 0, maxReadArgs = 0, maxWriteArgs = 0;
    clGetDeviceInfo(device, CL_DEVICE_MAX_SAMPLERS,         sizeof(maxSamplers), &maxSamplers, NULL);
    clGetDeviceInfo(device, CL_DEVICE_MAX_READ_IMAGE_ARGS,  sizeof(maxReadArgs),  &maxReadArgs,  NULL);
    clGetDeviceInfo(device, CL_DEVICE_MAX_WRITE_IMAGE_ARGS, sizeof(maxWriteArgs), &maxWriteArgs, NULL);

    printf("[images] CL_DEVICE_IMAGE_SUPPORT      = %s\n", imgSupport ? "CL_TRUE" : "CL_FALSE");
    printf("[images] max image2d                  = %zu x %zu\n", maxW, maxH);
    printf("[images] max samplers / read / write  = %u / %u / %u\n",
           maxSamplers, maxReadArgs, maxWriteArgs);

    if (!imgSupport) return -1;

    cl_uint numFmt = 0;
    clGetSupportedImageFormats(context, CL_MEM_READ_ONLY, CL_MEM_OBJECT_IMAGE2D, 0, NULL, &numFmt);
    if (numFmt == 0) { printf("[images] no supported 2D formats reported\n"); return -1; }

    cl_image_format* fmts = (cl_image_format*)malloc((size_t)numFmt * sizeof(cl_image_format));
    if (!fmts) return -1;
    clGetSupportedImageFormats(context, CL_MEM_READ_ONLY, CL_MEM_OBJECT_IMAGE2D, numFmt, fmts, NULL);

    int haveRgbaFloat = 0, rgbaCount = 0;
    for (cl_uint i = 0; i < numFmt; i++) {
        if (fmts[i].image_channel_order != CL_RGBA) continue;
        rgbaCount++;
        if (fmts[i].image_channel_data_type == CL_FLOAT) haveRgbaFloat = 1;
    }
    printf("[images] supported 2D read formats    = %u total, %u of them CL_RGBA\n", numFmt, rgbaCount);

    // Channel-order histogram. Orders with count 0 are simply not printed, so
    // "CL_ARGB missing from this list" is itself the finding. The loop is O(n^2)
    // over at most a few hundred entries, which is free next to the driver call.
    printf("[images] channel orders supported     :");
    for (cl_uint i = 0; i < numFmt; i++) {
        cl_uint order = fmts[i].image_channel_order;
        int seenBefore = 0;
        for (cl_uint j = 0; j < i; j++)
            if (fmts[j].image_channel_order == order) { seenBefore = 1; break; }
        if (seenBefore) continue;
        cl_uint count = 0;
        for (cl_uint k = 0; k < numFmt; k++)
            if (fmts[k].image_channel_order == order) count++;
        const char* nm = channelOrderName(order);
        if (nm) printf(" %s(%u)", nm, count);
        else    printf(" 0x%X(%u)", order, count);
    }
    printf("\n");

    printf("[images] CL_RGBA channel data types   :");
    for (cl_uint i = 0; i < numFmt; i++)
        if (fmts[i].image_channel_order == CL_RGBA)
            printf(" %s", channelTypeName(fmts[i].image_channel_data_type));
    printf("\n");
    printf("[images] RGBA/CL_FLOAT supported      = %s\n", haveRgbaFloat ? "yes" : "NO");

    // The old tutorial named CL_ARGB as a common format to pick from. On this
    // device it is not supported at all - absence is hard to see in a histogram,
    // so state it.
    int haveArgb = 0;
    for (cl_uint i = 0; i < numFmt; i++)
        if (fmts[i].image_channel_order == CL_ARGB) { haveArgb = 1; break; }
    printf("[images] CL_ARGB supported            = %s\n", haveArgb ? "yes" : "NO");

    free(fmts);
    return haveRgbaFloat ? 0 : -1;
}

int main(void) {
    cl_device_id device = NULL;
    char deviceName[256] = {0};
    if (ocl_pick_device(OCL_DEFAULT_DEVICE, CL_DEVICE_TYPE_ALL, &device, deviceName, sizeof(deviceName)) != 0) {
        printf("[FAIL] no device matching \"%s\"; run 01-device-query first\n", OCL_DEFAULT_DEVICE);
        return ocl_report(0);
    }
    ocl_report_device(device);

    cl_int err = CL_SUCCESS;
    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    if (!context) { printf("[FAIL] clCreateContext -> %s\n", ocl_err_name(err)); return ocl_report(0); }
    cl_command_queue queue = clCreateCommandQueueWithProperties(context, device, NULL, &err);
    if (!queue) { printf("[FAIL] clCreateCommandQueue -> %s\n", ocl_err_name(err)); return ocl_report(0); }

    printf("\n");
    if (reportImageCaps(context, device) != 0) {
        clReleaseCommandQueue(queue); clReleaseContext(context);
        return ocl_report_skip("device does not support RGBA/CL_FLOAT 2D images");
    }

    char* source = ocl_read_file("kernels/brightness.cl");
    if (!source) { clReleaseCommandQueue(queue); clReleaseContext(context); return ocl_report(0); }
    size_t srcLen = strlen(source);
    cl_program program = clCreateProgramWithSource(context, 1, (const char**)&source, &srcLen, &err);
    if (!program) { printf("[FAIL] clCreateProgramWithSource -> %s\n", ocl_err_name(err)); return ocl_report(0); }
    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
    if (err != CL_SUCCESS) {
        size_t logSz = 0;
        clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
        char* log = (char*)malloc(logSz + 1);
        if (log) {
            clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
            log[logSz] = '\0';
            printf("[build log]\n%s\n", log);
            free(log);
        }
        printf("[FAIL] clBuildProgram -> %s\n", ocl_err_name(err));
        return ocl_report(0);
    }

    const int W = 64, H = 64;
    float* src = (float*)malloc((size_t)W * H * 4 * sizeof(float));
    float* dst = (float*)malloc((size_t)W * H * 4 * sizeof(float));
    if (!src || !dst) { printf("[FAIL] out of host memory\n"); return ocl_report(0); }
    makeTestImage(src, W, H);

    int failures = 0;

    // ---- Case A: integer coords, unnormalized sampler. The standard form. --
    printf("\n=== case A: brightness_pixel, %dx%d, tile 16 (expect pass) ===\n", W, H);
    printf("    CLK_NORMALIZED_COORDS_FALSE + int2 coord is the form almost every\n");
    printf("    image kernel wants: coordinates ARE texel indices.\n");
    {
        ImageRun r;
        if (runImage(context, queue, device, program, "brightness_pixel", src, W, H,
                     16, 0, 1, dst, &r) != 0 || r.launchErr != CL_SUCCESS) {
            printf("    UNEXPECTED: launch did not succeed\n"); failures++;
        } else if (r.wrong != 0) {
            printf("    UNEXPECTED: %d wrong pixels\n", r.wrong); failures++;
        } else {
            printf("    as documented: every pixel correct\n");
        }
    }

    // ---- Case B: integer coords handed to a NORMALIZED sampler. THE BUG. ---
    printf("\n=== case B: brightness_norm_intbug, %dx%d, tile 16 (expect a COLLAPSED, WRONG image) ===\n", W, H);
    printf("    COORDS_TRUE means the driver computes s = coord * width. Passing the\n");
    printf("    pixel index x therefore gives s = x*%d, which CLAMP_TO_EDGE pins to\n", W);
    printf("    texel %d for every x >= 1. Only x == 0 survives, at s == 0.\n", W - 1);
    {
        ImageRun r;
        if (runImage(context, queue, device, program, "brightness_norm_intbug", src, W, H,
                     16, 0, 1, dst, &r) != 0 || r.launchErr != CL_SUCCESS) {
            printf("    UNEXPECTED: launch did not succeed\n"); failures++;
        } else if (r.wrong == 0) {
            printf("    UNEXPECTED: the buggy sampler produced a correct image\n"); failures++;
        } else if (r.distinctColors > 8) {
            printf("    UNEXPECTED: wrong, but %d distinct colors - no saturation collapse\n",
                   r.distinctColors);
            failures++;
        } else {
            printf("    as documented: %d/%d pixels wrong and a %d-pixel gradient\n",
                   r.wrong, r.pixels, r.pixels);
            printf("    collapsed to %d distinct colors.\n", r.distinctColors);
            printf("    recovered source texels: (0,0)->%.2f,%.2f  (1,0)->%.2f,%.2f\n",
                   dst[0], dst[1], dst[4], dst[5]);
            printf("                           (0,1)->%.2f,%.2f  (1,1)->%.2f,%.2f\n",
                   dst[(size_t)W * 4 + 0], dst[(size_t)W * 4 + 1],
                   dst[(size_t)W * 4 + 4], dst[(size_t)W * 4 + 5]);
            printf("    Row 0 and column 0 differ from the rest, which is exactly what\n");
            printf("    the s = coord * width model predicts.\n");
        }
    }

    // ---- Case C: normalized coords done correctly. ------------------------
    printf("\n=== case C: brightness_norm_correct, %dx%d, tile 16 (expect pass) ===\n", W, H);
    printf("    Normalized addressing is legitimate; it just needs (x+0.5)/w. With\n");
    printf("    NEAREST filtering the driver computes floor(u*w), so the half-pixel\n");
    printf("    offset is what makes it land on texel x rather than x-1 or x+1.\n");
    {
        ImageRun r;
        if (runImage(context, queue, device, program, "brightness_norm_correct", src, W, H,
                     16, 0, 1, dst, &r) != 0 || r.launchErr != CL_SUCCESS) {
            printf("    UNEXPECTED: launch did not succeed\n"); failures++;
        } else if (r.wrong != 0) {
            printf("    UNEXPECTED: %d wrong pixels\n", r.wrong); failures++;
        } else {
            printf("    as documented: identical result to case A\n");
        }
    }

    // ---- Case D: sampler created on the host, passed as a kernel argument. --
    printf("\n=== case D: brightness_host_sampler, %dx%d, tile 16 (expect pass) ===\n", W, H);
    printf("    clCreateSampler + clSetKernelArg(sizeof(cl_sampler)) lets the address\n");
    printf("    mode be chosen at run time instead of baked into a const.\n");
    {
        ImageRun r;
        if (runImage(context, queue, device, program, "brightness_host_sampler", src, W, H,
                     16, 1, 1, dst, &r) != 0 || r.launchErr != CL_SUCCESS) {
            printf("    UNEXPECTED: launch did not succeed\n"); failures++;
        } else if (r.wrong != 0) {
            printf("    UNEXPECTED: %d wrong pixels\n", r.wrong); failures++;
        } else {
            printf("    as documented: identical result to case A\n");
        }
    }

    // ---- Case E: non-square image whose dimensions are not tile multiples. --
    printf("\n=== case E: brightness_pixel, 100x37, tile 16, global NOT rounded (expect rejection) ===\n");
    printf("    The divisibility rule is per DIMENSION: 100 %% 16 = %d and 37 %% 16 = %d.\n",
           100 % 16, 37 % 16);
    {
        const int EW = 100, EH = 37;
        float* esrc = (float*)malloc((size_t)EW * EH * 4 * sizeof(float));
        float* edst = (float*)malloc((size_t)EW * EH * 4 * sizeof(float));
        if (!esrc || !edst) { printf("    [FAIL] out of host memory\n"); failures++; }
        else {
            makeTestImage(esrc, EW, EH);
            ImageRun r;
            int hrc = runImage(context, queue, device, program, "brightness_pixel", esrc, EW, EH,
                               16, 0, 0, edst, &r);
            if (hrc != 0) {
                printf("    UNEXPECTED: harness error\n"); failures++;
            } else if (r.launchErr == CL_INVALID_WORK_GROUP_SIZE) {
                printf("    as documented: rejected with -54\n");
            } else if (r.launchErr == CL_SUCCESS) {
                printf("    NOTE: this device accepted a non-divisible global size, %d/%d correct\n",
                       r.pixels - r.wrong, r.pixels);
                if (r.wrong) { printf("    but the values were wrong\n"); failures++; }
            } else {
                printf("    UNEXPECTED error code %d %s\n", r.launchErr, ocl_err_name(r.launchErr));
                failures++;
            }

            printf("\n=== case F: brightness_pixel, 100x37, tile 16, global rounded (expect pass) ===\n");
            printf("    Rounding 100x37 up to 112x48 launches 1624 padding work-items. The\n");
            printf("    kernel's get_image_width/height guard keeps them out of the way.\n");
            hrc = runImage(context, queue, device, program, "brightness_pixel", esrc, EW, EH,
                           16, 0, 1, edst, &r);
            if (hrc != 0 || r.launchErr != CL_SUCCESS) {
                printf("    UNEXPECTED: launch did not succeed\n"); failures++;
            } else if (r.wrong != 0) {
                printf("    UNEXPECTED: %d wrong pixels\n", r.wrong); failures++;
            } else {
                printf("    as documented: %d/%d pixels correct at global {%zu,%zu}\n",
                       r.pixels - r.wrong, r.pixels, r.globalX, r.globalY);
            }
        }
        free(esrc); free(edst);
    }

    free(src); free(dst);
    clReleaseProgram(program);
    free(source);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    printf("\n=== summary ===\n");
    printf("device %s, delta %+.2f on a %dx%d RGBA/CL_FLOAT test image\n", deviceName, DELTA, W, H);
    printf("case A int coords + COORDS_FALSE   : pass - the form to use\n");
    printf("case B int coords + COORDS_TRUE    : gradient collapsed to 4 colors is the documented outcome\n");
    printf("case C (x+0.5)/w + COORDS_TRUE     : pass\n");
    printf("case D host cl_sampler             : pass\n");
    printf("case E 100x37 unrounded            : launch rejection is the documented outcome\n");
    printf("case F 100x37 rounded to 112x48    : pass\n");
    printf("unexpected outcomes                : %d\n", failures);

    return ocl_report(failures == 0);
}
