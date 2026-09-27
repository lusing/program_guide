# 13 · 事件系统：命令事件、wait list、用户事件、回调

> 对应示例 `examples/13_events/main.c`。参照 OPE 第 6 章（Events and Synchronization，本主题最系统的书）、OiA 7.1/7.2、HCL 第 5 章（事件一节）。

## 13.1 事件的三种身份

1. **命令事件**：`clEnqueue*` 最后一个可选参数返回的 `cl_event`，跟踪这条命令的执行；
2. **用户事件**：`clCreateUserEvent` 由主机手动控制，用来"闸门"一组命令；
3. **回调载体**：`clSetEventCallback` 在命令到达指定状态时通知主机。

事件状态机（`clGetEventInfo` 的 `CL_EVENT_COMMAND_EXECUTION_STATUS`，头文件实测值）：

```
CL_QUEUED(3) -> CL_SUBMITTED(2) -> CL_RUNNING(1) -> CL_COMPLETE(0)
```

> 与很多教程印象相反，这几个枚举**不是负数**（负数是"命令异常终止时的错误码"）。实测两个有意思的行为：
> - 提交后立刻查询，内核可能已经 COMPLETE（0）——小内核太快；
> - **被用户事件闸住的命令状态 = 3（QUEUED）**——NVIDIA 驱动对"等待前置条件"的命令也报 QUEUED，而不是给出更细的区分。

## 13.2 wait list：命令间依赖的标准写法

任何 `clEnqueue*` 都有 `num_events_in_wait_list + event_wait_list` 参数——**命令等谁、产出什么事件**：

```c
cl_event evW, evK, evR;
clEnqueueWriteBuffer(q, bx, CL_FALSE, 0, size, hx, 0, NULL, &evW);        /* 不等谁 */
clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 1, &evW, &evK);           /* 等 evW */
clEnqueueReadBuffer(q, by, CL_FALSE, 0, size, hy, 1, &evK, &evR);         /* 等 evK */
clWaitForEvents(1, &evR);   /* 主机只等最后一个 */
```

这就是"写→算→读"三段流水线的骨架（示例 13 全程非阻塞，主机只在最后 join 一次）。顺序队列里事件依赖是冗余但无害的；**乱序队列（5 章）里它是必需品**。

规则：

- wait list 里的事件必须来自**同一上下文**；
- 事件用完 `clReleaseEvent`（每个 enqueue 返回的事件都是引用计数对象）。

## 13.3 用户事件：主机当闸门

```c
cl_event user = clCreateUserEvent(ctx, &err);
clEnqueueNDRangeKernel(q, k, 1, NULL, &g, NULL, 1, &user, &evK);  /* 等 user */
/* ... 此时内核绝不启动（实测状态 = 3，非 COMPLETE） ... */
clSetUserEventStatus(user, CL_COMPLETE);    /* 放行；也可传负数 = 出错传染 */
```

实测：`kernel gated on user event, status now: 3 (not 0 = CL_COMPLETE)`——闸住期间状态不为 0，`setStatus(CL_COMPLETE)` 后结果正确。

用途：等主机侧资源（磁盘、网络、别的 GPU 流水线）就绪再放行设备。**错误传染**：`clSetUserEventStatus(user, -1)` 会让等它的命令以错误结束（`CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST`）。

## 13.4 回调：命令完成通知主机

```c
static void CL_CALLBACK on_done(cl_event ev, cl_int status, void* user) {
    printf("kernel event status=%d tag=%s\n", status, (const char*)user);
}
clSetEventCallback(evK, CL_COMPLETE, on_done, (void*)"kernel-done");
clFinish(q);   /* 回调由驱动线程异步触发，给点时间 */
```

实测输出顺序（注意第一行出现在 device 行之前——回调线程与主线程交错）：

```
  [callback thread] kernel event status=0 tag=kernel-done
callback fired: yes
```

三条纪律：回调在**驱动线程**执行（别碰非线程安全状态、别在里面调 OpenCL 阻塞 API）；只保证在指定状态之后触发一次；别把业务逻辑压在回调上（事件等待才是主力）。

## 13.5 事件携带的信息

```c
cl_int st;
clGetEventInfo(ev, CL_EVENT_COMMAND_EXECUTION_STATUS, sizeof(st), &st, NULL);
cl_command_type ct;
clGetEventInfo(ev, CL_EVENT_COMMAND_TYPE, sizeof(ct), &ct, NULL);   /* 命令种类 */
```

实测：内核事件的命令类型 `4592 = 0x11F0 = CL_COMMAND_NDRANGE_KERNEL`。剖析信息（4 个时间戳）是另一组查询，14 章专讲。

## 13.6 其余工具

| API | 用途 |
|---|---|
| `clWaitForEvents(n, evs)` | 主机等一组事件 |
| `clEnqueueMarkerWithWaitList(q, n, evs, &ev)` | "等 evs 全完成"打包成一个新事件 |
| `clEnqueueBarrierWithWaitList(q, n, evs, NULL)` | 同上 + 拦住队列后续命令 |
| `clReleaseEvent` / `clRetainEvent` | 引用计数 |

> 下一章：[14 性能剖析](14-profiling.md)——事件时间戳与带宽实测。
