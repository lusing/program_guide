// 定义采样器（通常在内核外部或作为常量定义）
const sampler_t smpSampler = CLK_NORMALIZED_COORDS_FALSE |
                             CLK_ADDRESS_CLAMP_TO_EDGE |
                             CLK_FILTER_NEAREST;

__kernel void adjust_brightness(__read_only image2d_t input,
                                __write_only image2d_t output,
                                const float brightness) {
    int x = get_global_id(0);
    int y = get_global_id(1);

    // 获取图像尺寸
    int width = get_image_width(input);
    int height = get_image_height(input);

    if (x < width && y < height) {
        // 读取像素
        float4 color = read_imagef(input, smpSampler, (int2)(x, y));

        // 调整亮度
        color.xyz += brightness;

        // 写回
        write_imagef(output, (int2)(x, y), color);
    }
}
