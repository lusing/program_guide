// 15 · 内存管理：GC、@nogc 与手动内存
// D 默认 GC 管理堆——但"默认"不等于"只能"
import std.stdio, std.typecons, core.memory,
       core.stdc.stdlib : malloc, free, calloc, realloc;

// ── GC 的日常：new 即分配，无需释放 ─────────────────────────
class Session {
    string id;
    this(string id) { this.id = id; }
    ~this() { /* GC 回收时执行（时机不确定，别依赖它管外部资源！） */ }
}

// ── @nogc：编译器保证"这个函数不碰 GC" ──────────────────────
// 实时系统/嵌入式/热路径的护栏：任何 GC 分配（new、数组拼接、闭包逃逸）→ 编译错
@nogc int sumNoGc(scope const(int)[] xs) {
    int total = 0;
    foreach (x; xs) total += x;
    return total;
    // return xs.map!(x => x).array;  // ← 打开这行直接编译错：array 会分配
}

// ── 手动内存：malloc + 切片包装（@nogc 世界的数据结构）───────
struct RawBuffer {
    double* data;
    size_t n;

    static RawBuffer make(size_t n) {
        auto p = cast(double*)malloc(double.sizeof * n);
        //enforce(p !is null, "malloc 失败");
        return RawBuffer(p, n);
    }

    @nogc double[] slice() return { return data[0 .. n]; }   // 指针 → 切片

    ~this() {
        if (data !is null) free(data);       // RAII：作用域结束释放
        data = null;
    }

    // 手动内存禁拷贝（否则 double free）——置空源 postblit
    this(this) { assert(false, "RawBuffer 禁止拷贝，用 move 或 ref"); }
}

// ── RefCounted：类 RAII 的引用计数包装 ──────────────────────
struct FileBlob {
    ubyte[] bytes;
    this(ubyte[] bytes) { this.bytes = bytes; }   // RefCounted 构造实参转给 payload
}

void main() {
    // GC 日常
    auto s = new Session("alpha");          // GC 分配，不用 delete（delete 已废弃！）
    writeln("会话：", s.id);
    auto arr = new int[](1_000_000);        // 大数组也走 GC（默认初始化为 0）
    arr[999_999] = 7;
    writeln("百万元素数组 OK，末位 = ", arr[999_999]);

    // GC 控制：手动触发/统计
    GC.collect();                            // 显式收一次（通常不需要）
    auto stats = GC.stats();
    writeln("GC 已用堆 ≈ ", stats.usedSize / 1024, " KB");
    // GC.disable(); GC.enable();            // 暂停/恢复（慎用）

    // @nogc
    writeln(sumNoGc([1, 2, 3, 4]));

    // 手动内存 + RAII
    {
        auto buf = RawBuffer.make(4);
        buf.slice()[0] = 3.14;
        writeln("RawBuffer[0] = ", buf.slice()[0], "，长度 ", buf.slice().length);
    }                                        // 这里 free

    // RefCounted：值语义 + 自动释放
    auto blob = RefCounted!FileBlob(cast(ubyte[])[1, 2, 3]);   // 字面量默认 int[]，要 cast
    {
        auto blob2 = blob;                   // 计数 +1
        writeln("引用计数共享：", blob2.refCountedPayload.bytes.length);
    }                                        // 计数 -1，不释放
    writeln("blob 仍可用：", blob.refCountedPayload.bytes);   // 释放

    // scoped!：把类钉在栈上（绕过 GC 分配，作用域结束自动析构）
    auto scopedSession = scoped!Session("beta");
    writeln("scoped 会话：", scopedSession.id);

    // 内存策略速查（正文表格）：
    // 临时对象/无所谓   → GC（new）
    // 热路径/实时       → @nogc + struct + malloc/栈
    // 共享所有权        → RefCounted!T
    // 栈上类            → scoped!T
}

unittest {
    // GC 分配一百万个再丢弃，验证能回收（不崩不泄漏到断言）
    foreach (_; 0 .. 100) { auto junk = new int[](10_000); junk[0] = 1; }
    GC.collect();
    assert(GC.stats().usedSize > 0);

    // @nogc 函数在测试里照样可用
    assert(sumNoGc([1, 2, 3]) == 6);
    int[4] stackArr = [10, 20, 30, 40];
    assert(sumNoGc(stackArr[]) == 100);
}
