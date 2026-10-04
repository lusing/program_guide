// examples/10-multi-device - one computation, sharded across every device this
// machine has, with each device in its OWN context.
//
// Every earlier example picked one device by name and stayed on it. This one uses
// all three that exist here - an NVIDIA discrete GPU, an Intel integrated GPU and
// an Intel CPU runtime - at the same time, and it is the only example in the
// tutorial whose subject is the machinery BETWEEN devices rather than the work done
// on one.
//
// Seven things are measured here that cannot be measured with a single device:
//
//   1. A cl_kernel belongs to its context and cannot be borrowed. Step 4 takes the
//      kernel built in slot 0's context and tries to use it with slot 1's buffer
//      and slot 1's queue. Both attempts are expected to FAIL, and the example
//      prints the error code each one actually produced rather than assuming which
//      of the specification's several candidates it will be. This is the reason the
//      per-device state below is a struct owning its own program and kernel,
//      instead of three queues hanging off one context.
//
//   2. Whether one context can span platforms is NOT assumed - and asking the
//      question in-process turned out to be unsafe. Step 5 calls clCreateContext
//      with every device, twice (bare, and naming CL_CONTEXT_PLATFORM), from a CHILD
//      process. On this machine both attempts fault with 0xC0000005 rather than
//      returning CL_INVALID_DEVICE, so there is no error code to check and an
//      example that made the call itself would simply vanish. The child's exit code
//      is the measurement.
//
//   3. An equal split is the wrong split. Step 7 re-sizes the shards proportionally
//      to the throughput each device actually demonstrated in step 6, and the two
//      wall-clock times are printed side by side. Sizing shards by device COUNT
//      rather than by measured RATE leaves the whole run waiting on the slowest
//      device, and the only way to see that is to do both.
//
//   4. Profiling timestamps from DIFFERENT devices may not share an epoch, so
//      subtracting one device's start from another's end can be meaningless. Step 8
//      tests this instead of trusting it. Every wall-clock number used for the
//      speed comparison comes from the host's QueryPerformanceCounter, which has no
//      such ambiguity.
//
//   5. A shard plan has to be checked for coverage before it is run. plan_check
//      verifies that the shards tile all N elements with no gap and no overlap, and
//      it is not hypothetical: an earlier version of the calibrated planner grew one
//      device's count after the bases had already been assigned, which orphaned 2560
//      elements at the end of the array. The poisoned output caught it eventually,
//      but reported it as a data mismatch rather than as the planning error it was.
//
//   6. Whether the devices actually ran at the same time is settled by an A/B, not
//      by arithmetic. Step 7b re-runs the IDENTICAL calibrated plan with each device
//      drained before the next is submitted; the only difference from step 7 is one
//      clFinish inside the submission loop, so the ratio between the two wall clocks
//      is the overlap. The obvious shortcuts do not work: item 4 rules out comparing
//      timestamps across devices, and comparing a wall clock against a sum of device
//      spans is not decisive either, because host-side overhead lands in the same
//      number. Both modes are run several times and their spreads compared against
//      each other, so a ratio that sits inside run-to-run noise is reported as noise
//      instead of as a speedup.
//
//   7. A device's throughput does not reliably survive leaving the round it was
//      measured in. Step 9 prints the fastest device's rate from the round where it
//      had the whole machine to itself next to its rate from a round where the three
//      devices took turns. Those two have been observed agreeing to within a percent
//      and differing by several times, in both directions, across launches of the same
//      unchanged binary - so the note under them adapts to whichever came out instead
//      of asserting a fixed relationship. What is portable is the ratio between two
//      devices measured INSIDE one round; what is not is an absolute Melem/s carried
//      from one round to another. The gap is reported, not explained: attributing it
//      would mean testing clock residency, power limits and driver queueing
//      separately, which is not this example's subject.
//
// The kernel is integer-only on purpose - see kernels/mix.cl. Three vendor
// compilers produce three binaries, and all three outputs are compared bit for bit
// against ONE C reference, which is only a meaningful test if the arithmetic has a
// single conforming answer.
//
// Contract: exit 0 + "[RESULT] PASS", or "[RESULT] SKIP" if this machine has fewer
// than two OpenCL devices - the subject of the example would then be absent rather
// than broken, and calling that a failure would train readers to ignore red.
#include "ocl_util.h"

// Host wall clock. Included AFTER ocl_util.h so cl_platform.h's guards are already
// in place, and with NOMINMAX because windows.h otherwise defines min and max as
// macros.
//
// <time.h>'s clock() was deliberately not used: on MSVC it reports WALL time while
// on every POSIX host it reports CPU time, and a tutorial that quietly depended on
// that difference would measure the wrong thing the moment it was built elsewhere.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#define N       (1u << 21)      // 2,097,152 elements, 8 MiB per buffer
#define ROUNDS  32              // must match the loop bound in kernels/mix.cl
#define MAXDEV  16
#define POISON  0xFFFFFFFFu     // an element nobody wrote has to be recognisable

// Quiet rounds run before the one whose transcript is printed. The same work on the
// same device measured 2.17 ms in one run of this example and 3.63 ms in another, so
// a ratio built from a single pair of samples would be decoration. Every figure step
// 9 reports therefore carries the spread of all WARMUP+1 rounds next to it.
#define WARMUP  2

// Everything that is per-device. A Slot owns its context and everything derived
// from that context, because step 4 demonstrates that nothing derived from one
// context may be used with another.
typedef struct {
    cl_device_id     dev;
    char             name[256];
    char             platform[256];
    cl_device_type   type;
    cl_context       ctx;
    cl_command_queue queue;
    cl_program       prog;
    cl_kernel        kern;
    cl_mem           in;
    cl_mem           out;
    size_t           local;     // min(CL_KERNEL_WORK_GROUP_SIZE, device maximum)
    int              valid;

    // Filled in per round by plan_equal / plan_calibrated.
    unsigned int     base;      // first GLOBAL index this slot owns
    unsigned int     count;     // how many elements this slot owns

    // Filled in per round by round_run.
    double           rateElemsPerNs;
    cl_ulong         kernStart;
    cl_ulong         kernEnd;
    cl_ulong         queued;
} Slot;

// The result of one timing mode across all of its rounds.
//
// best/worst rather than "the round that happened to be printed": this machine has
// been seen to run the identical serial baseline at 1.36 ms in one launch of this
// program and 6.70 ms in another, with a slowest sample of 18.2 ms inside that same
// launch. Quoting one arbitrary sample let the example's verdict flip sign between
// runs, so every comparison in step 9 is now between ranges.
typedef struct {
    double best;    // fastest kernel+readback wall seen for this mode
    double worst;   // slowest
    double up;      // upload time of the fastest round (outside the timed region)
    int    ok;      // every round of this mode verified against the CPU reference
} Round;

static double nowNs(void) {
    static LARGE_INTEGER freq = {{0}};
    LARGE_INTEGER c;
    if (freq.QuadPart == 0) QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&c);
    return (double)c.QuadPart * 1e9 / (double)freq.QuadPart;
}

// The C reference: byte-for-byte the same arithmetic as kernels/mix.cl. If the two
// ever diverge, every round reports mismatches on every device at once, which is
// the failure shape that points at the reference rather than at a driver.
static unsigned int mix32(unsigned int x) {
    for (int r = 0; r < ROUNDS; r++) {
        x ^= x >> 16;
        x *= 0x7feb352du;
        x ^= x >> 15;
        x *= 0x846ca68bu;
        x ^= x >> 16;
        x += (unsigned int)r;
    }
    return x;
}

static cl_ulong prof(cl_event ev, cl_profiling_info what) {
    cl_ulong t = 0;
    if (!ev) return 0;
    if (clGetEventProfilingInfo(ev, what, sizeof(t), &t, NULL) != CL_SUCCESS) return 0;
    return t;
}

static const char* typeName(cl_device_type t) {
    if (t & CL_DEVICE_TYPE_GPU) return "GPU";
    if (t & CL_DEVICE_TYPE_CPU) return "CPU";
    if (t & CL_DEVICE_TYPE_ACCELERATOR) return "ACCELERATOR";
    return "OTHER";
}

// Keep the FIRST error rather than OR-ing codes together. cl_int is signed, so
// `err |= clSetKernelArg(...)` produces a number that names no error at all and
// prints as "(other)", which is worse than useless when debugging a launch.
static cl_int firstErr(cl_int acc, cl_int e) {
    return (acc == CL_SUCCESS) ? e : acc;
}

// ---- device enumeration -------------------------------------------------
//
// Every other example calls ocl_pick_device with a name hint. This one cannot: its
// subject is the SET of devices, so it takes whatever the machine offers and
// reports it. That also keeps the example honest on a machine with one device (it
// SKIPs) and on a machine with five.
static int enumerate_devices(Slot* s, int max) {
    cl_uint numPlat = 0;
    if (clGetPlatformIDs(0, NULL, &numPlat) != CL_SUCCESS || numPlat == 0) return 0;

    cl_platform_id* plats = (cl_platform_id*)malloc(numPlat * sizeof(cl_platform_id));
    if (!plats) return 0;
    clGetPlatformIDs(numPlat, plats, NULL);

    int n = 0;
    for (cl_uint p = 0; p < numPlat; p++) {
        char pname[256] = {0};
        clGetPlatformInfo(plats[p], CL_PLATFORM_NAME, sizeof(pname), pname, NULL);

        cl_uint nd = 0;
        if (clGetDeviceIDs(plats[p], CL_DEVICE_TYPE_ALL, 0, NULL, &nd) != CL_SUCCESS || nd == 0) {
            printf("[enum] platform %u '%s': no devices\n", p, pname);
            continue;
        }
        cl_device_id* tmp = (cl_device_id*)malloc(nd * sizeof(cl_device_id));
        if (!tmp) continue;
        clGetDeviceIDs(plats[p], CL_DEVICE_TYPE_ALL, nd, tmp, NULL);

        for (cl_uint i = 0; i < nd && n < max; i++) {
            memset(&s[n], 0, sizeof(Slot));
            s[n].dev = tmp[i];
            strncpy(s[n].platform, pname, sizeof(s[n].platform) - 1);
            clGetDeviceInfo(tmp[i], CL_DEVICE_NAME, sizeof(s[n].name), s[n].name, NULL);
            clGetDeviceInfo(tmp[i], CL_DEVICE_TYPE, sizeof(s[n].type), &s[n].type, NULL);
            n++;
        }
        free(tmp);
    }
    free(plats);
    return n;
}

// ---- per-device setup ---------------------------------------------------
//
// One context per device. The same source text is compiled separately for each, so
// it goes through three different vendor compilers; the build log is printed for
// every one of them because they do not all stay silent.
static int slot_setup(Slot* s, const char* src) {
    cl_int err = CL_SUCCESS;

    s->ctx = clCreateContext(NULL, 1, &s->dev, NULL, NULL, &err);
    if (!s->ctx || err != CL_SUCCESS) {
        printf("[setup] %s: clCreateContext -> %d %s\n", s->name, err, ocl_err_name(err));
        return 0;
    }

    cl_queue_properties props[] = { CL_QUEUE_PROPERTIES, CL_QUEUE_PROFILING_ENABLE, 0 };
    s->queue = clCreateCommandQueueWithProperties(s->ctx, s->dev, props, &err);
    if (!s->queue || err != CL_SUCCESS) {
        printf("[setup] %s: queue -> %d %s\n", s->name, err, ocl_err_name(err));
        return 0;
    }

    s->prog = clCreateProgramWithSource(s->ctx, 1, &src, NULL, &err);
    if (!s->prog || err != CL_SUCCESS) {
        printf("[setup] %s: clCreateProgramWithSource -> %d %s\n", s->name, err, ocl_err_name(err));
        return 0;
    }

    err = clBuildProgram(s->prog, 1, &s->dev, NULL, NULL, NULL);
    {
        size_t logSz = 0;
        clGetProgramBuildInfo(s->prog, s->dev, CL_PROGRAM_BUILD_LOG, 0, NULL, &logSz);
        if (logSz > 1) {
            char* log = (char*)malloc(logSz + 1);
            if (log) {
                clGetProgramBuildInfo(s->prog, s->dev, CL_PROGRAM_BUILD_LOG, logSz, log, NULL);
                log[logSz] = '\0';
                printf("[build log] %s:\n%s\n", s->name, log);
                free(log);
            }
        }
    }
    if (err != CL_SUCCESS) {
        printf("[setup] %s: clBuildProgram -> %d %s\n", s->name, err, ocl_err_name(err));
        return 0;
    }

    s->kern = clCreateKernel(s->prog, "mix", &err);
    if (!s->kern || err != CL_SUCCESS) {
        printf("[setup] %s: clCreateKernel -> %d %s\n", s->name, err, ocl_err_name(err));
        return 0;
    }

    // CL_KERNEL_WORK_GROUP_SIZE, not CL_DEVICE_MAX_WORK_GROUP_SIZE. On the RTX 2060
    // the device says 1024 while every kernel on it says 256, so sizing the launch
    // from the device number yields -54 CL_INVALID_WORK_GROUP_SIZE. The device value
    // is still queried and the smaller of the two used, because on the Intel devices
    // a kernel that uses __local can come back lower than the device cap.
    size_t kernWG = 0, devWG = 0;
    clGetKernelWorkGroupInfo(s->kern, s->dev, CL_KERNEL_WORK_GROUP_SIZE, sizeof(kernWG), &kernWG, NULL);
    clGetDeviceInfo(s->dev, CL_DEVICE_MAX_WORK_GROUP_SIZE, sizeof(devWG), &devWG, NULL);
    s->local = kernWG ? kernWG : 64;
    if (devWG && devWG < s->local) s->local = devWG;

    // Sized at the full N for EVERY slot rather than at the shard it will usually
    // receive, because the serial round gives all of N to one device and the
    // calibrated round can hand most of N to whichever device measured fastest.
    // Reallocating per round would put allocation inside the timed region.
    s->in  = clCreateBuffer(s->ctx, CL_MEM_READ_ONLY,  (size_t)N * sizeof(unsigned int), NULL, &err);
    if (!s->in) { printf("[setup] %s: buffer in -> %d %s\n", s->name, err, ocl_err_name(err)); return 0; }
    s->out = clCreateBuffer(s->ctx, CL_MEM_WRITE_ONLY, (size_t)N * sizeof(unsigned int), NULL, &err);
    if (!s->out) { printf("[setup] %s: buffer out -> %d %s\n", s->name, err, ocl_err_name(err)); return 0; }

    s->valid = 1;
    printf("[setup] %s [%s] local=%zu (kernel %zu / device %zu)\n",
           s->name, typeName(s->type), s->local, kernWG, devWG);
    return 1;
}

static void slot_teardown(Slot* s) {
    if (!s->valid) return;
    if (s->in)    clReleaseMemObject(s->in);
    if (s->out)   clReleaseMemObject(s->out);
    if (s->kern)  clReleaseKernel(s->kern);
    if (s->prog)  clReleaseProgram(s->prog);
    if (s->queue) clReleaseCommandQueue(s->queue);
    if (s->ctx)   clReleaseContext(s->ctx);
    s->valid = 0;
}

// ---- sharding -----------------------------------------------------------

// Bases are derived from the FINAL counts, as a prefix sum, and never assigned
// before them.
//
// That ordering is not a style preference. An earlier version of plan_calibrated
// assigned each base as it went and then added the rounding leftover to whichever
// device had measured fastest - which was slot 0, not the last slot. Growing slot
// 0's count without recomputing the bases pushed its range into slot 1's and left
// the tail of the array unowned: 2560 elements that no device ever wrote. The
// poisoned host array caught it (see round_run), but the failure surfaced as a
// data mismatch three devices away from the line that caused it.
static void assign_bases(Slot* s, int n) {
    unsigned int b = 0;
    for (int i = 0; i < n; i++) {
        s[i].base = b;
        b += s[i].count;
    }
}

// Coverage check. Cheap, and it turns "some device produced wrong numbers" into
// "the plan itself does not tile the array", which is a different and much easier
// thing to fix.
static int plan_check(Slot* s, int n, const char* label) {
    unsigned int total = 0;
    for (int i = 0; i < n; i++) {
        if (i > 0 && s[i].base != s[i - 1].base + s[i - 1].count) {
            printf("  [plan %s] GAP/OVERLAP before slot %d: previous ends at %u, this starts at %u\n",
                   label, i, s[i - 1].base + s[i - 1].count, s[i].base);
            return 0;
        }
        total += s[i].count;
    }
    if (total != N) {
        printf("  [plan %s] counts sum to %u, expected %u\n", label, total, N);
        return 0;
    }
    printf("  [plan %s] %d shards tile all %u elements, no gap and no overlap\n", label, n, N);
    return 1;
}

// Equal split. Each count is rounded DOWN to that slot's local size so the launch
// needs no rounding at all; the last slot absorbs whatever is left and does get
// rounded up, which its kernel guard covers.
//
// A slot whose share rounds down to zero simply receives nothing and sits the round
// out. Forcing it to take one work-group instead would make the total exceed N.
static void plan_equal(Slot* s, int n) {
    unsigned int per = N / (unsigned int)n;
    unsigned int used = 0;
    for (int i = 0; i < n; i++) {
        if (i == n - 1) {
            s[i].count = N - used;
        } else {
            unsigned int c = per;
            c -= c % (unsigned int)s[i].local;
            s[i].count = c;
        }
        used += s[i].count;
    }
    assign_bases(s, n);
}

// Proportional split, using the rate each slot demonstrated in the previous round.
// Counts are rounded down to the local size and the leftover goes to the fastest
// slot, which is the one least hurt by a few extra elements.
//
// "Fastest" here means fastest as measured, and that measurement is only as good as
// the round it came from: in an equal split the fastest device gets a shard small
// enough that launch latency dominates its kernel time, so its rate is overstated
// and it is handed more than its share. round_run flags those shards when it sees
// them. The split below is still a large improvement on the equal one - moving work
// off the slowest device matters far more than getting the fastest device's share
// exactly right - but it is a first calibration, not a converged one.
static void plan_calibrated(Slot* s, int n) {
    double total = 0.0;
    int fastest = 0;
    for (int i = 0; i < n; i++) {
        if (s[i].rateElemsPerNs > s[fastest].rateElemsPerNs) fastest = i;
        total += s[i].rateElemsPerNs;
    }
    if (total <= 0.0) { plan_equal(s, n); return; }

    unsigned int used = 0;
    for (int i = 0; i < n; i++) {
        unsigned int c = (unsigned int)((double)N * s[i].rateElemsPerNs / total);
        c -= c % (unsigned int)s[i].local;
        s[i].count = c;
        used += c;
    }
    s[fastest].count += (N - used);
    assign_bases(s, n);
}

// ---- one round ----------------------------------------------------------
//
// By default this submits every shard WITHOUT waiting between devices, then
// finishes all of them. Finishing inside the submission loop would serialise the
// run, and the timing would measure one device at a time while claiming to
// measure concurrency.
//
// drainEach does exactly that serialising, deliberately, as a CONTROL. "Did the
// devices overlap?" cannot be answered from profiling timestamps on this machine
// (step 8: the vendors do not share an epoch), and comparing a wall clock against
// a sum of device spans is not decisive either - host-side overhead lands in the
// same number. So the same plan is run twice, once concurrently and once drained,
// and the ratio between the two walls IS the measurement.
//
// The host array is re-poisoned first. Without that, a shard nobody wrote would
// still compare equal because the previous round left correct values sitting there
// - the same trap examples/07 documents for missing wait-lists.
//
// Returns 1 if every element of c[] matched ref[] afterwards.
static int round_run(Slot* s, int n, const unsigned int* a, unsigned int* c,
                     const unsigned int* ref, const char* label,
                     int drainEach, int verbose,
                     double* outWallNs, double* outUploadNs) {
    for (unsigned int i = 0; i < N; i++) c[i] = POISON;

    // Upload the shards OUTSIDE the timed region. Shards move between rounds so the
    // transfer cannot be hoisted out of the round entirely, but it can be separated:
    // mixing 24 MiB of PCIe and shared-memory traffic into the compute figure would
    // produce a number that describes the bus rather than the devices. The transfer
    // is timed on its own account so it is reported, not hidden.
    double u0 = nowNs();
    for (int i = 0; i < n; i++) {
        if (!s[i].count) continue;
        cl_int e = clEnqueueWriteBuffer(s[i].queue, s[i].in, CL_FALSE, 0,
                                        (size_t)s[i].count * sizeof(unsigned int),
                                        a + s[i].base, 0, NULL, NULL);
        if (e != CL_SUCCESS) {
            printf("[FAIL] %s: upload -> %d %s\n", s[i].name, e, ocl_err_name(e));
            return 0;
        }
    }
    for (int i = 0; i < n; i++) if (s[i].count) clFinish(s[i].queue);
    double u1 = nowNs();
    if (outUploadNs) *outUploadNs = u1 - u0;

    cl_event evKern[MAXDEV] = {0}, evRead[MAXDEV] = {0};
    int submitted = 1;

    double t0 = nowNs();
    for (int i = 0; i < n && submitted; i++) {
        if (!s[i].count) continue;

        cl_int err = CL_SUCCESS;
        err = firstErr(err, clSetKernelArg(s[i].kern, 0, sizeof(cl_mem), &s[i].in));
        err = firstErr(err, clSetKernelArg(s[i].kern, 1, sizeof(cl_mem), &s[i].out));
        err = firstErr(err, clSetKernelArg(s[i].kern, 2, sizeof(unsigned int), &s[i].base));
        err = firstErr(err, clSetKernelArg(s[i].kern, 3, sizeof(unsigned int), &s[i].count));
        if (err != CL_SUCCESS) {
            printf("[FAIL] %s: clSetKernelArg -> %d %s\n", s[i].name, err, ocl_err_name(err));
            submitted = 0;
            break;
        }

        size_t g = ocl_round_up((size_t)s[i].count, s[i].local);
        err = clEnqueueNDRangeKernel(s[i].queue, s[i].kern, 1, NULL, &g, &s[i].local,
                                     0, NULL, &evKern[i]);
        if (err != CL_SUCCESS) {
            printf("[FAIL] %s: clEnqueueNDRangeKernel -> %d %s (global=%zu local=%zu count=%u)\n",
                   s[i].name, err, ocl_err_name(err), g, s[i].local, s[i].count);
            submitted = 0;
            break;
        }

        // Read straight into the right slice of the host array. That IS the
        // "reassemble the shards" step: there is no second pass and no index
        // arithmetic afterwards, so a wrong base shows up as a wrong element.
        err = clEnqueueReadBuffer(s[i].queue, s[i].out, CL_FALSE, 0,
                                  (size_t)s[i].count * sizeof(unsigned int),
                                  c + s[i].base, 0, NULL, &evRead[i]);
        if (err != CL_SUCCESS) {
            printf("[FAIL] %s: clEnqueueReadBuffer -> %d %s\n", s[i].name, err, ocl_err_name(err));
            submitted = 0;
            break;
        }

        // Only in the control round. Waiting here is what makes the round serial;
        // the concurrent round must leave every device in flight when the loop ends.
        if (drainEach) clFinish(s[i].queue);
    }
    for (int i = 0; i < n; i++) if (s[i].count) clFinish(s[i].queue);
    double t1 = nowNs();
    if (outWallNs) *outWallNs = t1 - t0;

    for (int i = 0; i < n; i++) {
        if (!s[i].count) continue;
        s[i].queued    = prof(evKern[i], CL_PROFILING_COMMAND_QUEUED);
        s[i].kernStart = prof(evKern[i], CL_PROFILING_COMMAND_START);
        s[i].kernEnd   = prof(evKern[i], CL_PROFILING_COMMAND_END);
        double ns = (s[i].kernEnd > s[i].kernStart) ? (double)(s[i].kernEnd - s[i].kernStart) : 0.0;
        s[i].rateElemsPerNs = ns > 0.0 ? (double)s[i].count / ns : 0.0;
    }

    if (verbose) {
        printf("\n[%s] upload %.3f ms (untimed below) | kernel+readback wall %.3f ms\n",
               label, (u1 - u0) / 1e6, (t1 - t0) / 1e6);
        double sumExec = 0.0;
        for (int i = 0; i < n; i++) {
            if (!s[i].count) { printf("    %-28s (no shard this round)\n", s[i].name); continue; }
            double execNs = (double)(s[i].kernEnd - s[i].kernStart);
            sumExec += execNs;
            printf("    %-28s base=%-9u count=%-9u kernel %8.3f ms  %8.2f Melem/s%s\n",
                   s[i].name, s[i].base, s[i].count, execNs / 1e6,
                   execNs > 0.0 ? (double)s[i].count / execNs * 1e3 : 0.0,
                   // A shard this short is mostly launch latency, so the rate below is
                   // not a throughput measurement. plan_calibrated consumes these rates,
                   // which is why the caveat is printed next to the number rather than
                   // left for a reader to infer from it.
                   execNs < 100000.0 ? "   <-- too short to calibrate from" : "");
        }
        printf("    %-28s sum of kernel times %8.3f ms vs wall %.3f ms\n",
               "", sumExec / 1e6, (t1 - t0) / 1e6);
    }

    int bad = 0, poisoned = 0;
    for (unsigned int i = 0; i < N; i++) {
        if (c[i] == POISON) { poisoned++; if (poisoned <= 3) printf("  unwritten i=%u\n", i); continue; }
        if (c[i] != ref[i]) { bad++; if (bad <= 5) printf("  mismatch i=%u got %08x want %08x\n", i, c[i], ref[i]); }
    }
    // A quiet round still reports a failed verification. Suppressing the success
    // transcript is a readability choice; suppressing a wrong answer would be a lie.
    if (verbose)
        printf("    verify %u/%u correct, %d unwritten, %d mismatched\n", N - bad - poisoned, N, poisoned, bad);
    else if (bad || poisoned)
        printf("    [%s] verify FAILED: %d unwritten, %d mismatched\n", label, poisoned, bad);

    for (int i = 0; i < n; i++) {
        if (evKern[i]) clReleaseEvent(evKern[i]);
        if (evRead[i]) clReleaseEvent(evRead[i]);
    }
    return submitted && bad == 0 && poisoned == 0;
}

// ---- one timing mode, warmed up ------------------------------------------
//
// Runs WARMUP quiet rounds and then one round whose transcript is printed, and
// records the fastest and slowest wall across all of them.
//
// The printed transcript is the LAST round; the figures step 9 reports are the
// FASTEST. They need not match and that is deliberate: the fastest sample is the
// one least contaminated by whatever else the machine was doing, and the slowest is
// what tells a reader how much weight the fast one can bear. Printing the last
// round rather than the best one keeps the transcript next to the live device state
// it came from, which is the version a reader reproducing this will see first.
//
// Verification is AND-ed over every round including the quiet ones. A warm-up that
// produced a wrong answer must fail the example even though its transcript was
// suppressed - which is why round_run still prints mismatches when not verbose.
static void round_repeat(Slot* s, int n, const unsigned int* a, unsigned int* c,
                         const unsigned int* ref, const char* label, int drainEach,
                         Round* out) {
    out->best = out->worst = out->up = 0.0;
    out->ok = 1;

    for (int rep = 0; rep <= WARMUP; rep++) {
        int last = (rep == WARMUP);
        double w = 0, u = 0;
        out->ok &= round_run(s, n, a, c, ref, label, drainEach, last, &w, &u);
        if (w <= 0.0) continue;                   // a round that never got timed
        if (out->best == 0.0 || w < out->best) { out->best = w; out->up = u; }
        if (w > out->worst) out->worst = w;
    }
}

// ---- step 5, in a child process -----------------------------------------
//
// clCreateContext with devices from more than one platform does NOT reliably
// return an error. Run in-process it took the whole example down with an access
// violation, which is why this lives behind a command-line switch: the OpenCL ICD
// loader picks a vendor from the arguments it is given and then hands that vendor
// device handles belonging to other vendors' drivers. Nothing in the API contract
// says the vendor has to survive that.
//
// So the call is made in a fork of this same binary. If it faults, the parent
// still has its result, and the fault itself becomes the datum - reported as the
// child's exit code, which is a measurement rather than a lost afternoon.
static int probe_child(const char* mode) {
    setvbuf(stdout, NULL, _IONBF, 0);

    Slot tmp[MAXDEV];
    int found = enumerate_devices(tmp, MAXDEV);
    if (found < 2) { printf("  [child] fewer than two devices, nothing to try\n"); return 0; }

    char* src = ocl_read_file("kernels/mix.cl");
    if (!src) { printf("  [child] cannot read kernels/mix.cl\n"); return 1; }

    cl_device_id ids[MAXDEV];
    for (int i = 0; i < found; i++) ids[i] = tmp[i].dev;

    cl_context_properties props[3] = {0, 0, 0};
    cl_context_properties* pprop = NULL;
    if (strcmp(mode, "platform") == 0) {
        cl_platform_id pl = NULL;
        clGetDeviceInfo(ids[0], CL_DEVICE_PLATFORM, sizeof(pl), &pl, NULL);
        props[0] = CL_CONTEXT_PLATFORM;
        props[1] = (cl_context_properties)pl;
        props[2] = 0;
        pprop = props;
    }

    printf("  [child] clCreateContext(%d devices%s) -- if this line is the last one, the call faulted\n",
           found, pprop ? ", CL_CONTEXT_PLATFORM = devices[0]'s platform" : ", no properties");

    cl_int err = CL_SUCCESS;
    cl_context multi = clCreateContext(pprop, (cl_uint)found, ids, NULL, NULL, &err);
    printf("  [child] returned %s, err %d %s\n", multi ? "SUCCEEDED" : "NULL", err, ocl_err_name(err));

    if (multi) {
        cl_program mp = clCreateProgramWithSource(multi, 1, (const char**)&src, NULL, &err);
        printf("  [child] clCreateProgramWithSource -> %s, err %d %s\n",
               mp ? "SUCCEEDED" : "NULL", err, ocl_err_name(err));
        if (mp) {
            cl_int be = clBuildProgram(mp, (cl_uint)found, ids, NULL, NULL, NULL);
            printf("  [child] clBuildProgram for all %d -> %d %s\n", found, be, ocl_err_name(be));
            if (be == CL_SUCCESS) {
                cl_kernel mk = clCreateKernel(mp, "mix", &err);
                printf("  [child] clCreateKernel -> %s, err %d %s\n",
                       mk ? "SUCCEEDED" : "NULL", err, ocl_err_name(err));
                if (mk) clReleaseKernel(mk);
            }
            clReleaseProgram(mp);
        }
        clReleaseContext(multi);
    }

    free(src);
    return 0;
}

// Spawn this same executable with --probe-cross-context <mode> and return the
// child's exit code. stdout is inherited so the child's lines interleave with the
// parent's in the order they happened rather than arriving in one block at the end.
static int run_child(const char* mode) {
    char exe[MAX_PATH] = {0};
    if (!GetModuleFileNameA(NULL, exe, sizeof(exe))) {
        printf("  [child] GetModuleFileName failed (%lu)\n", (unsigned long)GetLastError());
        return -1;
    }

    char cmd[MAX_PATH + 64];
    snprintf(cmd, sizeof(cmd), "\"%s\" --probe-cross-context %s", exe, mode);

    STARTUPINFOA si;
    memset(&si, 0, sizeof(si));
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdInput  = GetStdHandle(STD_INPUT_HANDLE);
    si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
    si.hStdError  = GetStdHandle(STD_ERROR_HANDLE);

    PROCESS_INFORMATION pi;
    memset(&pi, 0, sizeof(pi));

    // lpCurrentDirectory NULL, so the child inherits the example's own directory
    // and its relative "kernels/mix.cl" resolves the same way the parent's did.
    if (!CreateProcessA(exe, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
        printf("  [child] CreateProcess failed (%lu)\n", (unsigned long)GetLastError());
        return -1;
    }
    WaitForSingleObject(pi.hProcess, 120000);
    DWORD code = 0;
    GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return (int)code;
}

int main(int argc, char** argv) {
    if (argc > 2 && strcmp(argv[1], "--probe-cross-context") == 0)
        return probe_child(argv[2]);

    Slot slots[MAXDEV];

    // Unbuffered. This example asks three different vendors' drivers to reject
    // calls they are entitled to reject, and a driver that goes further and
    // crashes takes the buffered stdout with it - which is exactly when the last
    // few lines are the only evidence of what was being attempted.
    setvbuf(stdout, NULL, _IONBF, 0);

    printf("=== step 1: enumerate every device on every platform ===\n");
    int found = enumerate_devices(slots, MAXDEV);
    for (int i = 0; i < found; i++)
        printf("  [%d] %-30s %-4s platform '%s'\n", i, slots[i].name, typeName(slots[i].type), slots[i].platform);

    if (found < 2) {
        char msg[160];
        snprintf(msg, sizeof(msg),
                 "only %d OpenCL device(s) on this machine; there is nothing to shard across", found);
        return ocl_report_skip(msg);
    }

    // ---- 2. source, host data, reference --------------------------------
    printf("\n=== step 2: load the kernel source and build the CPU reference ===\n");
    char* src = ocl_read_file("kernels/mix.cl");
    if (!src) return ocl_report(0);

    unsigned int* a   = (unsigned int*)malloc((size_t)N * sizeof(unsigned int));
    unsigned int* c   = (unsigned int*)malloc((size_t)N * sizeof(unsigned int));
    unsigned int* ref = (unsigned int*)malloc((size_t)N * sizeof(unsigned int));
    if (!a || !c || !ref) {
        printf("[FAIL] host allocation of %u elements\n", N);
        free(a); free(c); free(ref); free(src);
        return ocl_report(0);
    }

    // Not a ramp and not all-zero. A pattern with structure in the low bits means a
    // shard that landed at the wrong offset produces visibly wrong values rather
    // than values that happen to sit near the right ones.
    for (unsigned int i = 0; i < N; i++) {
        a[i] = (i * 2654435761u) ^ (i >> 3);
        ref[i] = mix32(a[i] ^ i);
    }
    printf("  N = %u elements (%zu MiB per buffer), %d hash rounds\n",
           N, (size_t)N * sizeof(unsigned int) / (1024 * 1024), ROUNDS);

    // ---- 3. one context per device --------------------------------------
    printf("\n=== step 3: a separate context, program and kernel per device ===\n");
    int n = 0;
    for (int i = 0; i < found; i++) {
        if (slot_setup(&slots[i], src)) {
            if (i != n) slots[n] = slots[i];
            n++;
        } else {
            printf("[setup] %s: dropped, this device takes no shard\n", slots[i].name);
            slot_teardown(&slots[i]);
        }
    }
    if (n < 2) {
        for (int i = 0; i < n; i++) slot_teardown(&slots[i]);
        free(a); free(c); free(ref); free(src);
        return ocl_report_skip("fewer than two devices completed setup");
    }

    // ---- 4. a kernel cannot be borrowed across contexts ------------------
    //
    // Both attempts below are EXPECTED to fail. What is printed is the code each one
    // actually returned, because the specification offers several candidates and
    // which one a driver picks is its business. The assertion is therefore "not
    // CL_SUCCESS", never "equals some particular code": pinning a code would turn a
    // driver update into a tutorial bug.
    printf("\n=== step 4: use slot 0's kernel with slot 1's resources (must fail) ===\n");
    cl_int eArg = clSetKernelArg(slots[0].kern, 0, sizeof(cl_mem), &slots[1].out);
    printf("  clSetKernelArg(kernel[0], buffer[1])      -> %d %s\n", eArg, ocl_err_name(eArg));

    size_t g4 = slots[1].local;
    cl_int eNdr = clEnqueueNDRangeKernel(slots[1].queue, slots[0].kern, 1, NULL,
                                         &g4, &slots[1].local, 0, NULL, NULL);
    printf("  clEnqueueNDRangeKernel(queue[1], kern[0]) -> %d %s\n", eNdr, ocl_err_name(eNdr));

    int crossCtxOk = (eArg != CL_SUCCESS) && (eNdr != CL_SUCCESS);
    printf("  assert both rejected: %s\n", crossCtxOk ? "OK" : "FAILED");
    if (!crossCtxOk) {
        printf("  [NOTE] this driver accepted a cross-context kernel. The per-device contexts\n");
        printf("         below would then be a choice rather than a requirement - re-read docs/09.\n");
    }

    // ---- 5. can one context span platforms? ------------------------------
    //
    // Measured in a child process, twice: once with no properties and once naming
    // CL_CONTEXT_PLATFORM. The first version of this step made the call in-process
    // and it faulted, which is itself the answer - see probe_child above.
    //
    // Deliberately carries NO assertion. Whether a cross-platform context is
    // accepted, rejected with an error, or fatal is a property of this ICD loader
    // and these three drivers, not a contract this example should enforce. A
    // machine whose loader rejects it cleanly would fail an assert here while
    // behaving strictly better.
    printf("\n=== step 5: attempt ONE context holding all %d devices (in a child process) ===\n", n);
    {
        printf("  -- probe A: no properties --\n");
        int rc1 = run_child("bare");
        printf("  [parent] child exit code %d (0x%08X)\n", rc1, (unsigned int)rc1);

        printf("  -- probe B: CL_CONTEXT_PLATFORM = devices[0]'s platform --\n");
        int rc2 = run_child("platform");
        printf("  [parent] child exit code %d (0x%08X)\n", rc2, (unsigned int)rc2);

        // 0xC0000005 is STATUS_ACCESS_VIOLATION. Reaching this branch means the call
        // never returned anything at all, so there is no cl_int to report - which is
        // exactly why an example that makes this call in-process cannot tell the
        // reader what happened.
        if ((unsigned int)rc1 == 0xC0000005u || (unsigned int)rc2 == 0xC0000005u) {
            printf("  [NOTE] the call FAULTED rather than returning CL_INVALID_DEVICE. There is no\n");
            printf("         error code to check, so the only safe way to ask this question is from\n");
            printf("         a process you can afford to lose.\n");
        }

        printf("  [NOTE] every platform on this machine exposes exactly ONE device, so a\n");
        printf("         multi-device context whose devices share a platform cannot be tested\n");
        printf("         here at all. Both probes above are about the cross-platform case.\n");
        printf("  [NOTE] either outcome leaves the rest of this example unchanged: the slots\n");
        printf("         keep their own contexts, so step 4's demonstration does not depend on\n");
        printf("         whether a shared context happens to be survivable.\n");
    }

    // ---- 6. serial baseline, then an equal split -------------------------
    printf("\n=== step 6: serial baseline on slot 0, then an equal split across %d ===\n", n);
    Round rSerial = {0}, rEqual = {0}, rCalib = {0}, rDrain = {0};
    int plansOk = 1;

    slots[0].count = N;
    for (int i = 1; i < n; i++) slots[i].count = 0;
    assign_bases(slots, n);
    plansOk &= plan_check(slots, n, "serial");
    round_repeat(slots, n, a, c, ref, "serial: all N on slot 0", 0, &rSerial);

    // Slot 0's rate from the one round where it had the machine to itself and ran
    // back to back with no gap. Saved here because every later round overwrites it,
    // and step 9 prints it next to the same device's rate from the control round -
    // where the two do not agree. See the note there.
    double soloRate = slots[0].rateElemsPerNs;

    plan_equal(slots, n);
    plansOk &= plan_check(slots, n, "equal");
    round_repeat(slots, n, a, c, ref, "equal split", 0, &rEqual);

    // ---- 7. re-split proportionally to measured throughput ---------------
    printf("\n=== step 7: split proportionally to the rate each device just measured ===\n");
    plan_calibrated(slots, n);
    plansOk &= plan_check(slots, n, "calibrated");
    round_repeat(slots, n, a, c, ref, "calibrated split", 0, &rCalib);

    // Snapshot the QUEUED stamps from the CONCURRENT round before the control round
    // overwrites them. step 8's whole argument is that these were taken inside one
    // submission loop with no blocking call between them, and the drained round
    // below deliberately breaks that property.
    cl_ulong queuedConcurrent[MAXDEV] = {0};
    for (int i = 0; i < n; i++) queuedConcurrent[i] = slots[i].queued;

    // ---- 7b. the same plan, drained one device at a time -----------------
    //
    // This is the control that makes step 9's overlap claim a measurement instead
    // of an inference. Identical buffers, identical shard boundaries, identical
    // kernel arguments - the only difference is that each device is waited for
    // before the next is submitted. Whatever the concurrent round gains over this
    // one is overlap; whatever it does not gain, it did not get.
    //
    // It also produces the uncontended per-device rates: three devices hammering
    // the same host memory at once slows each of them down, and the drained round
    // is the only place here where a rate belongs to one device alone. That is why
    // step 9's throughput table is labelled with the round it came from.
    printf("\n=== step 7b: CONTROL - same plan, but each device drained before the next ===\n");
    round_repeat(slots, n, a, c, ref, "serialised control", 1, &rDrain);

    // ---- 8. do profiling stamps from different devices share an epoch? ----
    //
    // The specification leaves the epoch unspecified. If it is per-device rather
    // than per-host, then max(end) - min(start) ACROSS devices - the obvious way to
    // compute how much a parallel run overlapped - subtracts two unrelated time
    // bases and means nothing. The spread of the QUEUED stamps from one round is a
    // direct test: they were all enqueued inside a single loop with no blocking call
    // between them, so anything wider than about a second is a difference in time
    // base, not in scheduling.
    printf("\n=== step 8: are cross-device profiling timestamps comparable? ===\n");
    {
        cl_ulong lo = 0, hi = 0;
        printf("  (stamps below are from the CONCURRENT calibrated round, step 7)\n");
        for (int i = 0; i < n; i++) {
            if (!queuedConcurrent[i]) continue;
            // The seconds column is what makes the raw number interpretable. A stamp
            // of 1.79e18 ns is 56 years, which is a plausible "since 1970"; one of
            // 1.3e14 ns is 36 hours, which is a plausible "since boot". Two vendors,
            // two different origins, and the API specifies neither.
            printf("  %-28s QUEUED = %-22llu (%.0f s)\n", slots[i].name,
                   (unsigned long long)queuedConcurrent[i], (double)queuedConcurrent[i] / 1e9);
            if (!lo || queuedConcurrent[i] < lo) lo = queuedConcurrent[i];
            if (queuedConcurrent[i] > hi) hi = queuedConcurrent[i];
        }
        unsigned long long spread = (unsigned long long)(hi - lo);
        printf("  spread across devices: %llu ns (%.3f s)\n", spread, (double)spread / 1e9);
        if (spread < 1000000000ull) {
            printf("  comparable: cross-device timestamp arithmetic is meaningful on this machine\n");
        } else {
            printf("  NOT comparable: the devices do not share an epoch, so every wall-clock figure\n");
            printf("  above comes from the host's QueryPerformanceCounter instead. Per-device\n");
            printf("  DURATIONS (end - start on the same device) stay valid; only differences\n");
            printf("  ACROSS devices are meaningless.\n");
        }
    }

    // ---- 9. what the four timings say ------------------------------------
    printf("\n=== step 9: timings ===\n");
    if (rSerial.best <= 0.0 || rEqual.best <= 0.0 || rCalib.best <= 0.0 || rDrain.best <= 0.0) {
        // A round that failed before it could be timed leaves no wall at all, and
        // every ratio below would then print as inf or nan. The verification asserts
        // at the end say which round it was; there is nothing to compare here.
        printf("  [NOTE] at least one mode never produced a timing, so the comparison below\n");
        printf("         is unavailable. See the [FAIL] lines above for which one.\n");
    } else {
        printf("  each mode ran %d times; the figure quoted is its FASTEST round and the bracket\n", WARMUP + 1);
        printf("  its slowest. The transcripts above are the last rounds, so they need not match.\n");
        printf("                          upload     fastest      slowest     ratio (fastest)\n");
        printf("  serial on slot 0      %7.3f ms  %10.3f ms  %10.3f ms  %s\n",
               rSerial.up / 1e6, rSerial.best / 1e6, rSerial.worst / 1e6, "(baseline)");
        printf("  equal split x %d       %7.3f ms  %10.3f ms  %10.3f ms  %.2fx vs serial\n",
               n, rEqual.up / 1e6, rEqual.best / 1e6, rEqual.worst / 1e6,
               rSerial.best / rEqual.best);
        printf("  calibrated split x %d  %7.3f ms  %10.3f ms  %10.3f ms  %.2fx vs serial, %.2fx vs equal\n",
               n, rCalib.up / 1e6, rCalib.best / 1e6, rCalib.worst / 1e6,
               rSerial.best / rCalib.best, rEqual.best / rCalib.best);
        printf("  same plan, drained    %7.3f ms  %10.3f ms  %10.3f ms  %.2fx vs calibrated\n",
               rDrain.up / 1e6, rDrain.best / 1e6, rDrain.worst / 1e6,
               rDrain.best / rCalib.best);

        // Rates come from each device's own profiling pair, which step 8 established
        // is the only cross-device-safe use of them. They are read out of the CONTROL
        // round because that is the only round in which the devices take turns; in the
        // concurrent round all three are reading and writing the same host array at
        // once. Taking turns turns out not to be the same as running alone - see the
        // comparison printed under the table.
        int fastest = 0, slowest = 0;
        for (int i = 0; i < n; i++) {
            if (slots[i].rateElemsPerNs > slots[fastest].rateElemsPerNs) fastest = i;
            if (slots[i].rateElemsPerNs < slots[slowest].rateElemsPerNs) slowest = i;
        }
        double slowdown = slots[fastest].rateElemsPerNs /
                          (slots[slowest].rateElemsPerNs > 0 ? slots[slowest].rateElemsPerNs : 1);

        printf("\n  relative throughput (control round, devices taking turns):\n");
        for (int i = 0; i < n; i++) {
            double rel = slots[fastest].rateElemsPerNs / (slots[i].rateElemsPerNs > 0 ? slots[i].rateElemsPerNs : 1);
            printf("    %-28s %8.2f Melem/s   %6.1fx slower than the fastest\n",
                   slots[i].name, slots[i].rateElemsPerNs * 1e3, rel);
        }

        // The same device in the round where it really was alone, printed because it
        // does not match the table above and a tutorial that showed only one of the
        // two numbers would let the reader carry the wrong one away.
        //
        // The gap is reported as a magnitude with no direction attached, because
        // across runs of this example it has come out BOTH ways: one run had the solo
        // rate five times the taking-turns rate, the next had it a third of it. What
        // is stable is that the two disagree by a large factor, so no absolute Melem/s
        // figure in this example is portable. Attributing the gap would mean testing
        // clock residency, power limits and driver queueing separately, which is not
        // this example's subject.
        printf("    %-28s %8.2f Melem/s   <- same device, alone, in the serial round\n",
               slots[0].name, soloRate * 1e3);
        if (soloRate > 0.0 && slots[0].rateElemsPerNs > 0.0) {
            double gap = soloRate > slots[0].rateElemsPerNs
                             ? soloRate / slots[0].rateElemsPerNs
                             : slots[0].rateElemsPerNs / soloRate;
            // Both branches have to be written, because both happen. Claiming a large
            // disagreement on a run where the two agree within a percent would make the
            // note contradict the number printed directly above it.
            if (gap > 1.25) {
                printf("    [NOTE] those two differ by %.1fx. Other runs of this example have put\n", gap);
                printf("           the gap the other way round, so compare devices WITHIN a round;\n");
                printf("           an absolute Melem/s does not survive leaving the round it came from.\n");
            } else {
                printf("    [NOTE] those two agree to within %.0f%% on this run. They have not always:\n",
                       (gap - 1.0) * 100.0);
                printf("           other runs of this example have shown them several times apart, in\n");
                printf("           both directions. Compare devices WITHIN a round, not across them.\n");
            }
        }

        // Overlap, MEASURED. step 8 showed the vendors do not share a profiling
        // epoch, so no cross-device timestamp arithmetic can answer this; comparing
        // a wall clock against a sum of device spans cannot either, because host-side
        // overhead lands in the same number. What can answer it is the identical plan
        // run twice, once concurrently and once drained, differing in one line of
        // host code - and then a check that the two modes' ranges do not overlap,
        // because a ratio drawn from overlapping ranges is noise with a decimal point.
        double gain = rDrain.best / rCalib.best;
        printf("\n  overlap, measured (identical plan: concurrent round vs drained control):\n");
        printf("    concurrent  fastest %7.3f ms   slowest %7.3f ms\n",
               rCalib.best / 1e6, rCalib.worst / 1e6);
        printf("    drained     fastest %7.3f ms   slowest %7.3f ms\n",
               rDrain.best / 1e6, rDrain.worst / 1e6);
        printf("    -> %.2fx at the fastest samples\n", gain);
        if (rCalib.worst < rDrain.best) {
            printf("       every concurrent sample beat every drained one, so the shards DID run\n");
            printf("       concurrently and that ratio is outside run-to-run noise.\n");
        } else if (rDrain.worst < rCalib.best) {
            printf("       every drained sample beat every concurrent one: running the devices at\n");
            printf("       the same time made this workload SLOWER, which is what contending for\n");
            printf("       one host memory bus looks like.\n");
        } else {
            printf("       [NOTE] the two ranges OVERLAP, so on this run the difference between\n");
            printf("              concurrent and drained is inside run-to-run noise. The honest\n");
            printf("              reading is \"no overlap gain measurable here\", not \"%.2fx\".\n", gain);
        }

        // Decided by the FASTEST samples with a dead band, with the range overlap
        // reported alongside as a reliability caveat rather than as the rule.
        //
        // Two earlier versions got this wrong in opposite directions. The first
        // compared one wall against another and printed a winner; the same binary then
        // printed the opposite winner on the next run, because this machine's serial
        // baseline has been measured anywhere between 1.36 ms and 18.2 ms. The second
        // demanded that the ranges not overlap, which sounds rigorous and is not: every
        // mode pays a cold first round, so one slow sample - a sample the mode itself
        // would not repeat - was enough to force INCONCLUSIVE over fastest samples that
        // sat 40% apart.
        //
        // Fastest-against-fastest is the fair comparison here: both modes get the same
        // number of rounds and the same estimator, and the minimum is the sample least
        // contaminated by whatever else the machine was doing. The dead band keeps a
        // 3% difference from being announced as a winner.
        //
        // ONE printf per sentence, with every argument in the same call. Splitting a
        // sentence across several printf calls and putting the arguments on the last
        // one leaves the earlier specifiers reading whatever happened to be on the
        // stack, which is how this line came to print "0.000 ms vs nan ms, i.e. 0.00x"
        // while the table above it showed the same two timings perfectly.
        int separated = (rCalib.worst < rSerial.best) || (rSerial.worst < rCalib.best);
        printf("\n  range check: split %.3f-%.3f ms vs serial %.3f-%.3f ms -> %s\n",
               rCalib.best / 1e6, rCalib.worst / 1e6, rSerial.best / 1e6, rSerial.worst / 1e6,
               separated ? "SEPARATED, the fastest samples are not a lucky draw"
                         : "OVERLAP, so treat the ratio below as indicative only");

        double vGain = rSerial.best / rCalib.best;
        if (vGain > 1.10) {
            printf("  verdict: splitting BEAT running everything on the fastest device, by %.2fx at\n"
                   "           the fastest samples (%.3f ms against %.3f ms).\n",
                   vGain, rCalib.best / 1e6, rSerial.best / 1e6);
        } else if (vGain < 0.90) {
            printf("  verdict: splitting did NOT beat running everything on the fastest device\n"
                   "           (%.3f ms against %.3f ms at the fastest samples, i.e. %.2fx). A shard\n"
                   "           handed to a device %.0fx slower delays the join by more than it\n"
                   "           relieves the fast one, whether or not the three actually overlapped -\n"
                   "           the overlap block above says which. Sharding pays when the devices\n"
                   "           are comparable, or when the fast device is limited by something\n"
                   "           other than raw throughput.\n",
                   rCalib.best / 1e6, rSerial.best / 1e6, vGain, slowdown);
        } else {
            printf("  verdict: no difference worth claiming - %.2fx at the fastest samples is inside\n"
                   "           the 10%% band this example refuses to call a winner.\n", vGain);
        }
    }
    printf("  [NOTE] no speedup is asserted by this example, in either direction. The numbers\n");
    printf("         above ARE the measurement; docs/09 reports what they came out as and why.\n");

    // ---- 10. release -----------------------------------------------------
    for (int i = 0; i < n; i++) slot_teardown(&slots[i]);
    free(a); free(c); free(ref); free(src);

    // Each round's ok covers all WARMUP+1 runs of that mode, not just the one whose
    // transcript was printed. The drained control is asserted as well: it executes
    // the same sharded plan, so a wrong answer there is just as fatal as one in the
    // concurrent round, and suppressing its transcript must not suppress its check.
    printf("\nassert slot 0's kernel is rejected by slot 1's context : %s\n", crossCtxOk ? "OK" : "FAILED");
    printf("assert all three shard plans tile N exactly            : %s\n", plansOk    ? "OK" : "FAILED");
    printf("assert serial round matches the CPU reference          : %s\n", rSerial.ok ? "OK" : "FAILED");
    printf("assert equal round matches the CPU reference           : %s\n", rEqual.ok  ? "OK" : "FAILED");
    printf("assert calibrated round matches the CPU reference      : %s\n", rCalib.ok  ? "OK" : "FAILED");
    printf("assert drained control matches the CPU reference       : %s\n", rDrain.ok  ? "OK" : "FAILED");
    return ocl_report(crossCtxOk && plansOk && rSerial.ok && rEqual.ok && rCalib.ok && rDrain.ok);
}
