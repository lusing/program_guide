// Shared virtual memory, exercised two ways.
//
// Both kernels take an ordinary __global pointer argument. That is the whole point
// of SVM: the SAME pointer value is valid on the host and on the device, so there is
// no cl_mem object, no clCreateBuffer and no clEnqueueWriteBuffer anywhere in the host
// code.
//
// It is still NOT passed with clSetKernelArg. That call reads its value as a cl_mem
// handle, so handing it the raw pointer returns -38 CL_INVALID_MEM_OBJECT - an error
// naming a memory object in code that never created one. SVM pointers go through
// clSetKernelArgSVMPointer, which takes the pointer itself and no size.
//
// What differs between the two kernels is what the host is allowed to do WITHOUT
// asking the driver first, and that difference is the reason both exist:
//
//   svm_write  - used with COARSE-GRAINED SVM. The host must clEnqueueSVMMap before
//                touching the pointer and clEnqueueSVMUnmap afterwards. Overwriting
//                the buffer unconditionally means the test cannot pass by accident
//                from whatever the host left there.
//
//   svm_scale  - used with FINE-GRAINED buffer SVM. It READS what the host wrote
//                with no map call at all, which is exactly the guarantee
//                CL_MEM_SVM_FINE_GRAIN_BUFFER makes and coarse-grained does not. A
//                kernel that only wrote would pass on a coarse-grained allocation
//                too, so this one has to depend on the host's value being visible.
//
// Integer arithmetic only, so "correct" has one meaning and needs no tolerance.

__kernel void svm_write(__global unsigned int* p, unsigned int n, unsigned int seed)
{
    unsigned int i = get_global_id(0);
    if (i >= n) return;
    p[i] = i * seed + 1u;
}

__kernel void svm_scale(__global unsigned int* p, unsigned int n)
{
    unsigned int i = get_global_id(0);
    if (i >= n) return;
    p[i] = p[i] * 2u + 1u;
}

// Diagnostic, run only when svm_write's results did not arrive.
//
// One launch, two destinations: an SVM pointer and an ordinary cl_mem buffer, written
// with the same index in the same work-item. That is what makes it decisive. If the
// ordinary buffer comes back correct and the SVM one does not, the kernel demonstrably
// ran and it is specifically the SVM store that never became visible to the host. If
// neither came back, the launch itself did nothing and the SVM pointer is not the
// subject of the failure.
//
// Without this the two cases are indistinguishable, and "this device's SVM is broken"
// is exactly the claim that should not rest on an assumption.
__kernel void svm_cross_check(__global unsigned int* svm, __global unsigned int* regular, unsigned int n)
{
    unsigned int i = get_global_id(0);
    if (i >= n) return;
    regular[i] = 0xC0DE0000u + i;
    svm[i]     = 0xBEEF0000u + i;
}
