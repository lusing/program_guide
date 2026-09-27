# 05 · 上下文与命令队列：生命周期、属性、同步原语

> 对应示例 `examples/05_context_queue/main.c`。参照 OiA 2.4/2.7 节。

## 5.1 上下文（Context）：一切对象的作用域

上下文把"一组设备 + 内存对象 + 队列"圈进同一个地址空间。两类创建方式：

```c
/* A. 指定设备列表（最常用） */
cl_context ctx = clCreateContext(props, 1, &device, NULL, NULL, &err);

/* B. 从平台按类型批量拿 */
cl_context ctx = clCreateContextFromType(props, CL_DEVICE_TYPE_GPU, NULL, NULL, &err);
```

`props` 是"名字-值-…-0"结尾的属性数组，教学上也建议显式写上平台：

```c
cl_context_properties props[] = {
    CL_CONTEXT_PLATFORM, (cl_context_properties)platform,
    0
};
```

属性数组还是图形互操作的挂钩点——`CL_CONTEXT_D3D11_DEVICE_KHR`（29 章）、`CL_CONTEXT_GL_CONTEXT_KHR`（老 GL 路线）都从这里塞进去。

**回调**：第 5 参数可挂一个 `clCreateContext` 的错误/删除通知回调（教学程序传 NULL）。

## 5.2 引用计数：眼见为实

OpenCL 对象用引用计数管理生命周期（创建 = 1）：

```c
cl_uint rc0, rc1, rc2;
clGetContextInfo(ctx, CL_CONTEXT_REFERENCE_COUNT, sizeof(rc0), &rc0, NULL);
clRetainContext(ctx);   clGetContextInfo(..., &rc1, ...);   /* rc1 = rc0 + 1 */
clReleaseContext(ctx);  clGetContextInfo(..., &rc2, ...);   /* rc2 = rc0     */
```

示例 05 实测输出：

```
refcount: create=1 retain=2 release=1
```

规则速记：

- 每次 `clRetain*` 必须有配对的 `clRelease*`；
- `clCreateBuffer` 等子对象**不会**增加上下文计数（内部保证），但你拿到的 `cl_mem` 自己有计数；
- 最后一次 `clReleaseContext` 触发销毁——之后所有从它派生的对象都成悬垂句柄。

上下文还能反查设备列表：`CL_CONTEXT_DEVICES` 返回 `cl_device_id` 数组（两遍法）。**一个上下文可以挂多台设备**（26 章对比单/多上下文两种多设备方案）。

## 5.3 命令队列（Command Queue）

队列是"主机向设备下单"的唯一通道。现代写法只有一种构造函数：

```c
cl_command_queue q = clCreateCommandQueueWithProperties(ctx, device, props, &err);
```

`props = NULL` → 顺序队列（in-order）：命令按提交顺序依次执行，**这是默认心智模型**。要乱序（out-of-order，命令间靠事件显式声明依赖）与剖析：

```c
const cl_queue_properties props[] = {
    CL_QUEUE_PROPERTIES,
    (cl_queue_properties)(CL_QUEUE_PROFILING_ENABLE | CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE),
    0
};
```

> ⚠️ `CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE` 要设备支持（`CL_DEVICE_QUEUE_PROPERTIES` 查询；本机两家都支持，但乱序队列的正确使用要求你给每条命令配 wait list——13 章）。**剖析计时必须在创建队列时开属性**，事后无法补开（14 章的反面实验：普通队列上 `clGetEventProfilingInfo` 返回 `CL_PROFILING_INFO_NOT_AVAILABLE`）。

队列自身可查询（`clGetCommandQueueInfo`）：`CL_QUEUE_CONTEXT`、`CL_QUEUE_DEVICE`、`CL_QUEUE_PROPERTIES`——示例 05 用它验证属性确实生效：

```
queue props: plain=0 prof=2 (profiling bit=1)
```

## 5.4 同步三板斧

| 手段 | 语义 | 开销 |
|---|---|---|
| `clFinish(q)` | 阻塞主机直到队列**全部**命令完成 | 最粗，教学/收尾用 |
| `clWaitForEvents(n, evs)` | 只等指定事件（13 章） | 精确，配非阻塞命令 |
| `clEnqueueMarkerWithWaitList` | 在队列里插一个"等清单为空"的标记事件 | 设备侧同步点 |

示例 05 的用法（内核后插 marker，主机再等 marker + 兜底 clFinish）：

```c
clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 0, NULL, NULL);
cl_event marker;
clEnqueueMarkerWithWaitList(q, 0, NULL, &marker);
clWaitForEvents(1, &marker);
clReleaseEvent(marker);
clFinish(q);
```

> `clEnqueueBarrierWithWaitList` 是 marker 的强化版（barrier 之后的命令必须等它，marker 不拦后续命令）。`clEnqueueBarrier`/`clEnqueueMarker`/`clWaitForEvents` 的 1.x 老组合在 1.2 起被这两个 WithWaitList 版本取代。

## 5.5 什么时候会踩队列的坑

1. **读回前不保证完成**：非阻塞 `clEnqueueReadBuffer(CL_FALSE)` 后立刻用主机数据——必须等事件或 `clFinish`。
2. **跨设备没有隐式同步**：26 章多设备示例里，两台设备各自队列，靠主机 join。
3. **回调不是主线程**：`clSetEventCallback` 的函数在驱动线程执行（13 章演示），别在回调里碰不安全状态。
4. **队列销毁前命令不丢**：`clReleaseCommandQueue` 会等队列清空（但别依赖这个做同步，可读性为零）。

> 下一章：[06 程序与内核](06-programs.md)——build 选项、编译日志、多段源码。
