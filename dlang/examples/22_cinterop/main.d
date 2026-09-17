// 22 · C 互操作、内联汇编与 BetterC
// 主题：extern(C) 声明、给 C 库传回调、ABI 对齐、DMD 内建汇编、-betterC 无运行时模式
import std.stdio;

// ── extern(C)：按 C ABI 声明符号（这里直接链系统 libc 的 qsort/printf）──
extern (C) {
    // 变参 C 函数声明为 D 变参形式
    int printf(const(char)* fmt, ...);

    // qsort(base, nmemb, size, compar)
    alias compar_fn = extern (C) int function(const(void)*, const(void)*);
    void qsort(void* base, size_t nmemb, size_t size, compar_fn compar);

    size_t strlen(const(char)* s);
}

// extern(C) 的 D 函数：C 兼容 ABI，可作为回调传给 C（无名字修饰）
extern (C) int intCmp(const(void)* a, const(void)* b) {
    int x = *cast(const(int)*)a;
    int y = *cast(const(int)*)b;
    return (x > y) - (x < y);
}

// extern(C++) 一提：与 C++ 的名字修饰对接（按 Itanium/MSVC ABI）
extern (C++) void cppSideHello() {
    writeln("extern(C++) 函数（本进程内自调）");
}

// ── 结构体布局：对齐与 C 一致 ────────────────────────────────
// 大坑：align(1) 写在 struct 上只改"结构体自身"对齐（成员仍各自对齐 → 10 字节）；
// 要逐成员 align(1) 才是真打包（网络协议头常用）
struct PackedHeader {
    align (1) ubyte  magic;
    align (1) uint   length;
    align (1) ushort flags;
}
static assert(PackedHeader.sizeof == 7);   // 紧凑：7 字节（默认对齐会是 12）

version (LittleEndian) {           // 内建版本条件（目标字节序）
    static assert(PackedHeader.sizeof == 7);
}

// ── 内联汇编：DMD 在 x86-64 上的 asm 语法 ────────────────────
long readTsc() {
    long t;
    asm nothrow @nogc {
        rdtsc;              // 读时间戳计数器 → EDX:EAX
        shl RAX, 32;
        mov t, RAX;         // 取高 32 位拼接（演示用）
    }
    return t;
}

int asmAdd(int a, int b) {
    asm nothrow @nogc {
        mov EAX, a;
        add EAX, b;
        // 结果留在 EAX = 返回值
    }
}

void main() {
    // printf：经典 C 变参（写 stdout 要自己加 \n）
    printf("printf: %d + %d = %d\n", 20, 22, asmAdd(20, 22));
    printf("strlen: %llu\n", cast(ulong)strlen("hello"));

    // qsort + D 写的 C 回调
    int[6] arr = [42, 7, 19, 73, 8, 3];
    qsort(arr.ptr, arr.length, int.sizeof, &intCmp);
    writeln("qsort 后：", arr);

    // ABI 与对齐
    PackedHeader h = { magic: 0xAB, length: 0x00010203, flags: 0x0405 };
    writeln("紧凑头 ", PackedHeader.sizeof, " 字节：");
    foreach (b; (cast(ubyte*)&h)[0 .. PackedHeader.sizeof])
        writef("%02X ", b);
    writeln();
    static assert(int.sizeof == 4 && long.alignof == 8);   // 平台 ABI 常量

    // 内联汇编
    writeln("rdtsc 高位：", readTsc() & 0xFFFF);
    writeln("asmAdd(1, 2) = ", asmAdd(1, 2));

    cppSideHello();

    // 与 C 的完整互操作矩阵（文档细讲）：
    // D 调 C   → extern(C) 声明 + 链 .lib/.a
    // C 调 D   → extern(C) 导出函数；入口用 -betterC 或运行时自举
    // C++ 调 D → extern(C++)（类模板不互通，函数够用）
    // 结构体   → 字段类型避开 D 专有（dynamic array/slice 等）
}

unittest {
    assert(asmAdd(20, 22) == 42);
    assert(asmAdd(-5, 5) == 0);

    int[5] xs = [5, 4, 3, 2, 1];
    qsort(xs.ptr, xs.length, int.sizeof, &intCmp);
    assert(xs == [1, 2, 3, 4, 5]);

    assert(PackedHeader.sizeof == 7);
    PackedHeader h = { 0xAB, 0x00010203, 0x0405 };
    auto bytes = (cast(ubyte*)&h)[0 .. PackedHeader.sizeof];
    assert(bytes[0] == 0xAB);

    assert(cast(int)strlen("abcd") == 4);
}
