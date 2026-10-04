// Image kernels: image2d_t, sampler_t, read_imagef / write_imagef.
//
// Images are not buffers with extra steps. Three differences matter in practice:
//
//   1. Access goes through a SAMPLER, which decides whether coordinates are integer
//      texel indices or normalized [0,1] fractions, what happens outside the image,
//      and how to filter. Getting the coordinate convention wrong does not crash -
//      it silently reads the wrong texel.
//
//   2. The channel layout and data type are fixed at creation time by
//      cl_image_format, and the read/write builtins must match it. read_imagef is
//      for float formats; read_imageui is for unsigned integer formats. Mixing them
//      is a compile error or garbage, depending on the driver.
//
//   3. Out-of-range access is DEFINED, not undefined. read_imagef clamps or repeats
//      per the sampler's address mode, and write_imagef discards writes outside the
//      image. That makes rounding the global size up to a multiple of the local
//      size harmless here, where in a buffer kernel the same padding would need an
//      explicit guard.
//
// A const sampler_t must be initialised with a compile-time constant expression, so
// the flags are literals below rather than kernel arguments. To choose the sampler at
// run time, create one on the host and pass it as an argument - see
// brightness_host_sampler.

const sampler_t SAMP_PIXEL = CLK_NORMALIZED_COORDS_FALSE
                           | CLK_ADDRESS_CLAMP_TO_EDGE
                           | CLK_FILTER_NEAREST;

const sampler_t SAMP_NORM  = CLK_NORMALIZED_COORDS_TRUE
                           | CLK_ADDRESS_CLAMP_TO_EDGE
                           | CLK_FILTER_NEAREST;

// The standard form: integer texel coordinates, unnormalized sampler.
__kernel void brightness_pixel(__read_only image2d_t src,
                               __write_only image2d_t dst,
                               const float delta) {
    int2 coord = (int2)(get_global_id(0), get_global_id(1));
    if (coord.x >= get_image_width(src) || coord.y >= get_image_height(src)) return;

    float4 c = read_imagef(src, SAMP_PIXEL, coord);
    c.xyz = clamp(c.xyz + (float3)delta, (float3)0.0f, (float3)1.0f);
    write_imagef(dst, coord, c);
}

// The bug this example exists to show: integer pixel coordinates handed to a sampler
// configured for CLK_NORMALIZED_COORDS_TRUE. Normalized mode means the driver
// computes s = coord.x * width, so coord.x = 5 becomes s = 320 on a 64-wide image
// and CLAMP_TO_EDGE pins it to texel 63. Only coord.x == 0 escapes, at s == 0. The
// gradient therefore collapses to four distinct colors - texel (0,0), (0,63), (63,0)
// and (63,63) - and nothing anywhere reports an error.
__kernel void brightness_norm_intbug(__read_only image2d_t src,
                                     __write_only image2d_t dst,
                                     const float delta) {
    int2 coord = (int2)(get_global_id(0), get_global_id(1));
    if (coord.x >= get_image_width(src) || coord.y >= get_image_height(src)) return;

    float2 asNormalized = (float2)((float)coord.x, (float)coord.y);
    float4 c = read_imagef(src, SAMP_NORM, asNormalized);
    c.xyz = clamp(c.xyz + (float3)delta, (float3)0.0f, (float3)1.0f);
    write_imagef(dst, coord, c);
}

// Normalized addressing done correctly. The half-pixel offset is the part that is
// easy to omit: with NEAREST filtering the driver computes floor(u * width), so
// u = (x + 0.5) / width gives floor(x + 0.5) = x. Without the offset, u = x / width
// lands exactly on a texel boundary and the rounding direction decides whether you
// get texel x or texel x-1.
__kernel void brightness_norm_correct(__read_only image2d_t src,
                                      __write_only image2d_t dst,
                                      const float delta) {
    int2 coord = (int2)(get_global_id(0), get_global_id(1));
    int w = get_image_width(src);
    int h = get_image_height(src);
    if (coord.x >= w || coord.y >= h) return;

    float2 uv = (float2)(((float)coord.x + 0.5f) / (float)w,
                         ((float)coord.y + 0.5f) / (float)h);
    float4 c = read_imagef(src, SAMP_NORM, uv);
    c.xyz = clamp(c.xyz + (float3)delta, (float3)0.0f, (float3)1.0f);
    write_imagef(dst, coord, c);
}

// Same computation, sampler supplied by the host at run time. A sampler_t kernel
// parameter is set with clSetKernelArg(k, i, sizeof(cl_sampler), &sampler) - note
// the size is of the opaque HANDLE, not of a struct.
__kernel void brightness_host_sampler(__read_only image2d_t src,
                                      __write_only image2d_t dst,
                                      sampler_t samp,
                                      const float delta) {
    int2 coord = (int2)(get_global_id(0), get_global_id(1));
    if (coord.x >= get_image_width(src) || coord.y >= get_image_height(src)) return;

    float4 c = read_imagef(src, samp, coord);
    c.xyz = clamp(c.xyz + (float3)delta, (float3)0.0f, (float3)1.0f);
    write_imagef(dst, coord, c);
}
