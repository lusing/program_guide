# 07 · 缓冲区：创建标志、读写、映射、子缓冲区、矩形读写

> 对应示例 `examples/07_buffer_ops/main.c`。参照 OPE 第 3 章（本主题最细的书）、OiA 3.2/3.5 节。

## 7.1 创建：六种标志组合出三种初始化姿势

```c
/* a) 快照式：驱动拷一份，此后主机随便改（最常用） */
cl_mem bc = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                           size, host_ptr, &err);

/* b) 借用式：驱动尽量直接用这块主机内存（缓存一致性归驱动管） */
cl_mem bu = clCreateBuffer(ctx, CL_MEM_READ_WRITE | CL_MEM_USE_HOST_PTR, size, host_ptr, &err);

/* c) 先建后写：占位 */
cl_mem b0 = clCreateBuffer(ctx, CL_MEM_WRITE_ONLY, size, NULL, &err);
clEnqueueWriteBuffer(q, b0, CL_FALSE, 0, size, src, 0, NULL, &ev);
```

标志速查（可按位或）：

| 标志 | 语义 |
|---|---|
| `CL_MEM_READ_WRITE` / `READ_ONLY` / `WRITE_ONLY` | 访问提示（内核里违规访问属未定义行为） |
| `CL_MEM_COPY_HOST_PTR` | 创建时拷贝主机数据 |
| `CL_MEM_USE_HOST_PTR` | 复用主机内存 |
| `CL_MEM_ALLOC_HOST_PTR` | 分配"主机可访问"的设备内存（配合 map 吃性能红利） |
| `CL_MEM_HOST_READ_ONLY` / `HOST_WRITE_ONLY` / `HOST_NO_ACCESS` | 限制主机方向访问 |

示例 07 用数值坐实了快照语义：COPY 后改主机副本，设备数据不变。

`clGetMemObjectInfo` 可回查：`CL_MEM_FLAGS`、`CL_MEM_SIZE`、`CL_MEM_OFFSET`（子缓冲区）、`CL_MEM_TYPE`、`CL_MEM_CONTEXT`。

## 7.2 读写：阻塞与非阻塞

```c
cl_event ev;
clEnqueueWriteBuffer(q, buf, CL_FALSE, offset, size, host, 0, NULL, &ev);
clWaitForEvents(1, &ev);
clEnqueueReadBuffer(q, buf, CL_TRUE, offset, size, host, 0, NULL, NULL);   /* CL_TRUE 阻塞 */
```

- `CL_TRUE`：函数返回即数据可用（内部帮你同步）；
- `CL_FALSE`：命令入队即返回，主机缓冲在事件完成前**不许动**——大块传输用非阻塞可以与主机计算重叠（13 章流水线）。

## 7.3 映射（map）：最被低估的传输方式

```c
float* mapped = clEnqueueMapBuffer(q, buf, CL_TRUE, CL_MAP_WRITE_INVALIDATE_REGION,
                                   0, size, 0, NULL, NULL, &err);
for (i...) mapped[i] = ...;                    /* 像普通指针一样写 */
clEnqueueUnmapMemObject(q, buf, mapped, 0, NULL, NULL);
```

map 把设备内存（或它的主机镜像）映射进主机地址空间，**unmap 才真正落账**。对 `CL_MEM_ALLOC_HOST_PTR`/`USE_HOST_PTR` 缓冲，map/unmap 可以做到接近零拷贝。三种 map 标志：`CL_MAP_READ`、`CL_MAP_WRITE`（写前同步读）、`CL_MAP_WRITE_INVALIDATE_REGION`（整区覆写，省一次同步，最快）。

## 7.4 拷贝与填充

```c
clEnqueueCopyBuffer(q, src, dst, 0, 0, size, 0, NULL, NULL);       /* 设备内对拷，不过主机 */
clEnqueueFillBuffer(q, buf, &pattern, sizeof(pattern), off, len, ...); /* pattern 重复填充 */
```

示例实测 fill 只覆盖 `[offset, offset+size)`，界外数据原样。

## 7.5 子缓冲区：共享底层存储的"窗口"

```c
cl_buffer_region region = { origin_bytes, size_bytes };
cl_mem sub = clCreateSubBuffer(parent, CL_MEM_READ_WRITE,
                               CL_BUFFER_CREATE_TYPE_REGION, &region, &err);
```

**对齐要求**：`origin` 必须对齐 `CL_DEVICE_MEM_BASE_ADDR_ALIGN`（本机 NVIDIA 实测 **4096 位 = 512 字节**）。不对齐返回 `CL_MISALIGNED_SUB_BUFFER_OFFSET`。通过子缓冲区写、从父缓冲区读——同一块存储（示例 07 验证）。典型用途：多设备各领一段（26 章）。

> 查询 `CL_MEM_BASE_ADDR_ALIGN` 的单位是**位**，除以 8 才是字节——又是一个单位坑。

## 7.6 矩形读写：BufferRect 的"行单位"大坑

`clEnqueue{Read,Write}BufferRect` 在"线性设备内存"与"带行距（pitch）的 2D/3D 主机内存"之间搬面片：

```c
size_t buffer_origin[3] = {0, 0, 0};        /* 设备端起点 */
size_t host_origin[3]    = {0, 1, 0};       /* 主机端：第 1 行开始 */
size_t region[3]         = {8*4, 8, 1};     /* 宽（字节）、行数、片数 */
clEnqueueWriteBufferRect(q, buf, CL_TRUE, buffer_origin, host_origin, region,
                         8*4, 0,        /* 设备端行距（字节），0=紧凑 */
                         9*4, 0,        /* 主机端行距 */
                         host2d, 0, NULL, NULL);
```

> ⚠️ **本教程实测最大的 API 坑**：origin 的三个分量中，`[0]` 是字节偏移，但 `[1]`/`[2]` 的单位是**行/片**——运行时会拿它们乘以 row/slice pitch。写成 `host_origin = {0, 36, 0}`（想表达"第 36 字节"）实际会从 `36 × row_pitch` 处读，**静默读到主机数组越界处，驱动还返回 CL_SUCCESS**。正确写法是"第 1 行"= `{0, 1, 0}`。region[0] 才是字节。

正确行为（示例实测，9×9 外框搬中间 8×8）：

```
rect row0: 100 101 ... 107        /* 设备第 0 行 = 主机第 1 行 */
07 buffer_ops PASS
```

## 7.7 内存对象的其他成员

- `clEnqueueCopyBufferRect`：矩形对拷；
- `clSetMemObjectDestructorCallback`：销毁回调；
- `clRetainMemObject`/`clReleaseMemObject`：引用计数。

## 7.8 坑位清单（实测）

1. **BufferRect origin 单位**（上文，静默越界）；
2. 读取长度超过主机目的数组 = 栈/堆破坏（示例开发时真实翻车：256 个 float 读进 64 个的数组，后续代码全部行为异常）；
3. 子缓冲区 origin 对齐（位 vs 字节）；
4. `CL_MEM_USE_HOST_PTR` + 主机持续写 = 竞争，没有同步语义；
5. 非阻塞写后立刻改主机源缓冲 = 数据竞争，等事件。

> 下一章：[08 执行模型](08-ndrange.md)——NDRange、work-group、全局偏移与边界守卫。
