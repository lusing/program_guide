// 17 · 并发 II：std.parallelism 数据并行 + core.atomic 原子操作
// 与 16 章对照：16 章"线程 + 消息"解决通信问题；本章"线程池 + 任务"解决吞吐问题
import std.stdio, std.parallelism, std.algorithm, std.range, std.array,
       core.atomic, core.thread;

// 任务版并行：task 提交、later 消费（不阻塞主线程的提交侧）
long slowHash(int x) {
    long h = x;
    foreach (_; 0 .. 1000) h = h * 31 + 7;
    return h;
}

// 归约函数必须是"干净的"命名函数：内联 lambda 会捕获上下文（dual-context，已弃用）
long addL(long a, long b) { return a + b; }

void main() {
    writeln("CPU 核数：", totalCPUs, "，线程池大小：", taskPool.size);

    // ── parallel foreach：一行并行（数据并行的最短路径）───────
    auto data = new int[1000];
    foreach (i, ref x; parallel(data))
        x = cast(int)(i * i);                 // 坑：i 是 size_t，赋给 int 要 cast
    assert(data[999] == 999 * 999);
    writeln("parallel foreach OK：data[999] = ", data[999]);

    // ── taskPool.reduce：并行归约（自动分块求和）──────────────
    auto big = 10_000.iota.array;
    auto total = taskPool.reduce!addL(0L, big);
    writeln("并行求和 = ", total, "（", big.sum == total ? "对" : "错", "）");

    // taskPool 的 map/each 也有（amap 的近亲：parallel 版 map）
    auto hashes = taskPool.map!slowHash(iota(1, 20)).array;
    writeln("并行 hash 前 3：", hashes[0 .. 3]);

    // ── task/yieldForce：手动任务 ─────────────────────────────
    auto t1 = task!slowHash(123);             // 创建任务
    t1.executeInNewThread();                  // 甩到新线程跑
    writeln("主线程不等它，先干别的…");
    auto result1 = t1.yieldForce();           // 等结果（等待时让出 CPU；老教程的 force 已没有）
    writeln("task 结果 = ", result1);
    assert(result1 == slowHash(123));

    // ── atomic：线程池里的计数器必须原子 ─────────────────────
    shared int counter = 0;
    foreach (_; parallel(1000.iota))          // 1000 个并行体
        atomicOp!"+="(counter, 1);            // 原子自增（不是 counter++！）
    writeln("原子计数 = ", atomicLoad(counter));   // 1000

    // CAS：无锁算法的基石
    shared int slot = 0;
    int expected = 0;
    if (cas(&slot, expected, 99))             // 若 slot==0 则换成 99
        writeln("CAS 成功：slot = ", atomicLoad(slot));

    // Thread：最底层（一般用不上，知道就行）
    auto th = new Thread({
        // 纯计算，无消息机制——需要通信请回 16 章
    });
    th.start();
    th.join();
    writeln("裸 Thread OK");
}

unittest {
    // parallel foreach 的确定性验证
    auto xs = new double[500];
    foreach (i, ref x; parallel(xs)) x = i / 2.0;
    assert(xs[4] == 2.0);

    // 并行求和 == 串行求和
    auto data = 1000.iota.array;
    auto par = taskPool.reduce!addL(0L, data);
    long seq;
    foreach (x; data) seq += x;
    assert(par == seq && seq == 1000 * 999 / 2);

    // 原子操作正确性
    shared int c = 0;
    foreach (_; parallel(100.iota)) atomicOp!"+="(c, 2);
    assert(atomicLoad(c) == 200);

    shared int v = 5;
    int seen = 5;
    assert(!cas(&v, seen, 0) == false);       // 第一次 CAS 成功
    assert(atomicLoad(v) == 0);
}

