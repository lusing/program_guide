# 19 · ⭐多线程

> 对应示例：`examples/19_threads/`

FB 内置 Win32/pthreads 的薄封装：`ThreadCreate/ThreadWait` + `Mutex*` + `Cond*`。没有语言级并发（无 async、无通道语法），就是最朴素的**共享内存 + 锁 + 条件变量**模型——和 C 一个世界。

## 19.1 线程的创建与等待

```freebasic
Sub worker(ByVal ud As Any Ptr)        ' 线程入口签名固定
    Dim As Integer Ptr p = CPtr(Integer Ptr, ud)
    ...
End Sub

Dim As Any Ptr t = ThreadCreate(@worker, @data)   ' 立即返回
ThreadWait(t)                                     ' join：等它跑完
```

- 入口签名**必须是** `Sub(ByVal As Any Ptr)`，参数靠 `Any Ptr` 传一切（多参数就传 UDT 指针）。
- **win64 下别加 `Cdecl`**——加了 `ThreadCreate(@f)` 反而报"Passing different pointer types"警告（实测）。
- 返回值：线程函数没法直接返回值——结果写进出参指向的内存。

## 19.2 互斥锁

```freebasic
Dim Shared As Any Ptr mtx = MutexCreate()

MutexLock(mtx)
counter += 1                          ' 临界区：越短越好
MutexUnlock(mtx)

MutexDestroy(mtx)                     ' 收尾销毁
```

共享数据（`Dim Shared` 或全局）**只要被多线程碰，就必须锁**——哪怕只是一行 `+=`。示例里两线程各加 1 万次，带锁稳定 20000；不带锁就是经典的丢失更新（本教程不演示坏版本——它偶尔对，更危险）。

## 19.3 条件变量：等待与通知

```freebasic
cond = CondCreate()

' 等待方（持有锁的状态下调用）
MutexLock(mtx)
While Not ready
    CondWait(cond, mtx)               ' 原子地"放锁+睡眠"，醒来时重新持锁
Wend
MutexUnlock(mtx)

' 通知方
MutexLock(mtx)
ready = True
CondSignal(cond)                      ' 唤醒一个（CondBroadcast 唤醒全部）
MutexUnlock(mtx)
```

`CondWait` 必须在**循环**里（`While` 不是 `If`）——防虚假唤醒与被抢。示例实现了一个单槽 `Channel`（send/recv/close 三件套），生产者发 1..50 的平方、消费者求和，结果 `42925 = 50·51·101/6` 精确断言——这就是并发正确性的可验证形态。

## 19.4 传参与共享数据的设计

```freebasic
Type JobCtx
    mtx As Any Ptr
    results(1 To 8) As Double
    n As Integer
End Type
' 线程里 CPtr(JobCtx Ptr, ud) 拿回全部上下文
```

- 入口只给一个指针——**把"参数+结果+锁"打包成 UDT** 传地址，是最不乱的方式。
- `Dim Shared` 全局 + 全局锁也可，示例两种都演了。

## 19.5 编译与运行时

- fbc 自带线程安全运行库处理：默认链接即可用线程（实测 1.10.1 win64 无需 `-mt`；遇运行库重入问题时 `-mt` 是后手）。
- `-exx` 的数组边界检查是线程内生效的——线程里越界同样当场中止。
- 调试竞态没有银弹：设计上减少共享、临界区最小化、能用消息传递（Channel 模式）就别共享内存。

## 19.6 坑位清单（1.10.1 实测）

1. 线程入口 `Cdecl` 在 win64 **反而告警**——省掉它（`-w all` 零警告是本教程纪律）。
2. 变量名撞后端保留符号：`ch` 触发 warning 47（reserved global/backend symbol）——改名 `chan`。短名如 `ch/cx/dx` 都小心。
3. `CondWait` 必须套在 `While` 循环里（虚假唤醒）；且调用时**必须已持有**配对的锁。
4. `ThreadCreate` 失败返回 0（线程过多时）——严谨场景判空。
5. 无 join 就退出的主线程 = 进程直接结束，其他线程无论干到哪都被砍——`ThreadWait` 一个都不能少。
