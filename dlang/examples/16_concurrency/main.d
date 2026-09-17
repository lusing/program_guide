// 16 · 并发 I：std.concurrency 消息传递模型
// D 的座右铭："数据所有权随线程"——共享可变状态是默认禁止的，线程间靠消息通信
import std.concurrency, std.stdio, std.conv, std.algorithm,
       core.time : msecs;

// ── 消息类型：小而明确 ──────────────────────────────────────
struct Work { int id; string payload; }
struct Result { int id; long checksum; }

// 工人线程：收任务、发结果（receive 是阻塞的）
void worker(Tid owner) {
    bool running = true;
    while (running) {
        // receive 按类型分支——一条通道传多种消息
        receive(
            (Work w) {
                long sum;
                foreach (c; w.payload) sum += c;          // 简单校验和
                owner.send(Result(w.id, sum));
            },
            (string cmd) {                                 // 控制消息
                if (cmd == "quit") running = false;
            },
        );
    }
    owner.send("worker 已退出");
}

// 消息只能传：值拷贝 / immutable / shared——编译器把数据竞争拦在编译期
void strictWorker(Tid owner) {
    // 大坑：cast(immutable int[]) 产出的类型是 immutable(int)[]（只冻元素），
    // 和 immutable(int[])（全冻）是两个类型——receiveOnly 必须写一致的形状
    auto msg = receiveOnly!(immutable(int)[]);
    owner.send(msg.sum);
}

void main() {
    // ── spawn：起线程，拿 Tid（线程标识，可当"地址"用）────────
    Tid wid = spawn(&worker, thisTid);     // thisTid：自己的地址，让工人能回信

    // 发任务、收结果
    wid.send(Work(1, "hello"));
    wid.send(Work(2, "并发"));
    foreach (_; 0 .. 2) {
        auto r = receiveOnly!Result;
        writeln("结果 #", r.id, " 校验和 ", r.checksum);
    }
    wid.send("quit");
    writeln(receiveOnly!string);

    // ── receiveTimeout：限时等待，别死等 ─────────────────────
    auto slowpoke = spawn((Tid owner) {
        import core.thread : Thread;
        import core.time : msecs;
        Thread.sleep(200.msecs);
        owner.send("迟到的消息");
    }, thisTid);
    string lateMsg;
    auto got = receiveTimeout(50.msecs, (string s) { lateMsg = s; });   // 返回 bool：收到没有
    writeln("50ms 内收到？", got ? lateMsg : "没有");
    writeln(receiveOnly!string);                        // 200ms 后的迟到消息

    // ── immutable 数据自由共享 ────────────────────────────────
    auto tid = spawn(&strictWorker, thisTid);
    tid.send(cast(immutable int[])[1, 2, 3, 4]);        // 尾不可变数组：随便传
    writeln("immutable 求和 = ", receiveOnly!long);

    // ── 默认禁止共享：类型系统挡住数据竞争 ────────────────────
    int secret = 42;
    // spawn((Tid owner) { owner.send(secret); }, thisTid);
    // ↑ 打开注释：编译错！局部变量被闭包捕获 → "may not be shared"
    // 要么拷贝（值传递），要么 immutable，要么显式 shared
}

unittest {
    // 消息往返的最小验证
    auto echo = spawn((Tid owner, int n) {
        foreach (_; 0 .. n) owner.send(receiveOnly!int * 2);
    }, thisTid, 3);
    echo.send(5); echo.send(6); echo.send(7);
    assert(receiveOnly!int == 10);
    assert(receiveOnly!int == 12);
    assert(receiveOnly!int == 14);

    // receiveOnly 的类型即协议：发错类型直接抛
    auto t = spawn((Tid owner) { owner.send("文本"); }, thisTid);
    try { receiveOnly!int; assert(false); }
    catch (MessageMismatch) { /* 类型不符是运行时协议错误 */ }
}

