cl_int err = clSomeFunction(params);
if (err != CL_SUCCESS) {
    printf("Error %d at %s:%d\n", err, __FILE__, __LINE__);
    return -1;
}
