# 29 · 图形互操作：D3D11 路线与"扩展存在但用不了"的实测

> 对应示例 `examples/29_d3d11/main.cpp`。参照 OPE 第 10 章（OpenCL-OpenGL Interoperation）、OiA 第 15/16 章（OpenGL 互操作两讲）——Windows 上现代首选 D3D11 路线。

## 29.1 互操作要解决什么

渲染（D3D11/GL）与计算（OpenCL）共享同一块显存纹理，**免主机中转**：

```
D3D11 纹理 (GPU 显存)
   │  cl_khr_d3d11_sharing：CL 直接包装它
   ▼
OpenCL 内核直接读写 → 渲染管线直接采样 → 屏幕上就是计算结果
```

没有互操作时的替代是 staging 桥接（CL 读回主机 → D3D11 UpdateSubresource 上传），一次纹理往返 ~几毫秒，实时滤镜会肉痛。

## 29.2 D3D11 互操作的完整 API 舞步

1. **建 D3D11 设备**（离屏无窗口即可，互操作不需要交换链）；
2. **关联 CL 设备**：`clGetDeviceIDsFromD3D11KHR(platform, CL_D3D11_DEVICE_KHR, d3d11dev, ...)`；
3. **共享上下文**：属性挂 `CL_CONTEXT_D3D11_DEVICE_KHR`；
4. **包装纹理**：`clCreateFromD3D11Texture2DKHR(ctx, flags, tex, subresource, &err)`；
5. **acquire → 计算 → release**（帧内独占权交接）：

```c
cl_mem objs[1] = { shared };
clEnqueueAcquireD3D11ObjectsKHR(q, 1, objs, 0, NULL, NULL);
clEnqueueNDRangeKernel(q, k, ...);
clEnqueueReleaseD3D11ObjectsKHR(q, 1, objs, 0, NULL, NULL);
```

6. D3D11 侧照常渲染该纹理。

> ⚠️ 扩展函数（`clCreateFromD3D11Texture2DKHR` 等）**必须** `clGetExtensionFunctionAddressForPlatform` 动态获取——`cl_d3d11.h` 头只给声明不保证链接；枚举（`CL_CONTEXT_D3D11_DEVICE_KHR` 等）来自同一个头。

纹理要求速记：`D3D11_USAGE_DEFAULT`；格式映射（`R8G8B8A8_UNORM ↔ CL_RGBA/CL_UNORM_INT8`、`R32G32B32A32_FLOAT ↔ CL_RGBA/CL_FLOAT`）；bind 至少 SRV/RTV 之一。

## 29.3 本机实测：教科书级的"有能力通告、无实际功能"

探测三连（示例 29 与独立探针双重复核）：

```
interop probe: clGetDeviceIDsFromD3D11KHR = entry point found
interop probe: getdev(CL_D3D11_DEVICE_KHR) -> -59 (CL_INVALID_OPERATION), n=0
-> D3D11 interop NOT functional on this driver ...
```

事实链（RTX 3060，驱动 610.60 / CUDA 13.3）：

1. 扩展字符串通告 `cl_khr_d3d11_sharing`（还有 `cl_nv_d3d11_sharing`、`cl_khr_gl_sharing`）；
2. 扩展入口点全部能解析到；
3. `clGetDeviceIDsFromD3D11KHR` 对**自家显卡的 D3D11 设备**、DXGI adapter 两条来源都返回 `CL_INVALID_OPERATION`；
4. 换纹理格式（R8G8B8A8_UNORM / RGBA32F）、bind/misc 组合（含 `D3D11_RESOURCE_MISC_SHARED`）全部 `-59`——死在设备关联这步，纹理参数无关。

结论与社区长期报告一致：**NVIDIA 现代 Windows 驱动上 OpenCL↔D3D/GL 互操作实际不可用，扩展字符串是"幽灵通告"**。教学与工程启示：

- 互操作代码**必须先做能力探测再走主路径**（本示例的写法）；
- 想要 GPU 计算喂 D3D11 渲染：staging 桥接（下节）、CUDA-D3D 互操作（NVIDIA 生态内）、或 Compute Shader；
- GL 路线（OiA 15/16 章、OPE 第 10 章的完整代码）在 Windows/NVIDIA 上同样要探测后使用。

## 29.4 staging 桥接：任何驱动都能跑

示例 29 的实际验证路径：

```
CL 内核写 CL 图像 → clEnqueueReadImage 回主机
→ D3D11 UpdateSubresource 上纹理 → CopyResource 到 staging → Map 校验
```

实测：

```
D3D11 texture via staging bridge:
  corner (0,0)   : r=0.000 g=0.000 b=1.000
  center (64,64) : r=0.500 g=0.500 b=0.500
staging bridge verified (CL kernel -> host -> D3D11 -> Map)
```

CL 算出的渐变纹理完整落到 D3D11 侧。桥接要点：

- `DXGI_FORMAT_R32G32B32A32_FLOAT` 与 `CL_RGBA/CL_FLOAT` 一一对应（免量化）；unorm 8bit 则有 ~0.004 量化步长；
- staging 纹理 = `D3D11_USAGE_STAGING` + `CPU_ACCESS_READ` + bind=0，只有它能 Map；
- `UpdateSubresource` 的行距参数 = `W*16`（字节）。

## 29.5 选型表（Windows 2026 实测视角）

| 路线 | 实测状态 | 适用 |
|---|---|---|
| D3D11 互操作 | NVIDIA：通告但不可用（-59）；Intel CPU：无此扩展 | 探测后使用；AMD 待验 |
| staging 桥接 | ✓ 稳定 | 通用兜底，离线/低帧率场景够用 |
| CUDA-D3D 互操作 | NVIDIA 生态可用 | 绑定 NVIDIA |
| Compute Shader | ✓ | 计算量不大时最省事（免 API 切换） |
| Vulkan compute + 外部内存 | ✓ | 现代引擎路线（超出本教程） |

> 下一章：[30 设备架构与性能模型](30-perf-model.md)——合并访问、带宽实测与 SIMT。
