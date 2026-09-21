# 22 · C 互操作、内联汇编与 BetterC

> 对应示例：`examples/22_cinterop/`（含 `betterc.d` 的 -betterC 编译）

## 22.1 extern(C)：声明即互通

```d
extern (C) {
    int printf(const(char)* fmt, ...);          // C 变参 → D 变参形式声明
    void qsort(void* base, size_t nmemb, size_t size,
               extern (C) int function(const(void)*, const(void)*) compar);
    size_t strlen(const(char)* s);
}
printf("printf: %d\n", 42);                     // 直接调用系统 libc
```

extern(C) = "这个符号按 C ABI（无名字修饰）"——Windows 上 DMD 链 UCRT/MSVC 运行库，Linux 上链 glibc，macOS 上链 libSystem（`otool -L` 只见 `/usr/lib/libSystem.B.dylib`），声明 libc 函数**三个平台都不需要额外链接任何东西**。

## 22.2 D 函数给 C 当回调

```d
extern (C) int intCmp(const(void)* a, const(void)* b) {   // C ABI 的 D 实现
    int x = *cast(const(int)*)a, y = *cast(const(int)*)b;
    return (x > y) - (x < y);
}

int[6] arr = [42, 7, 19, 73, 8, 3];
qsort(arr.ptr, arr.length, int.sizeof, &intCmp);   // D 回调喂 C 函数
```

extern(C++) 同理（按 Itanium/MSVC 名字修饰对接 C++，函数级够用，模板类不互通）。

## 22.3 结构体布局：对齐要与 C 对齐

```d
struct PackedHeader {          // 网络协议头：逐成员 align(1) 才是真打包
    align (1) ubyte  magic;
    align (1) uint   length;
    align (1) ushort flags;
}
static assert(PackedHeader.sizeof == 7);
```

**大坑**：`align(1) struct X {...}` 只改结构体**自身**对齐（成员照旧各自对齐，实测 10 字节）——要 packed 必须逐成员标。`version (LittleEndian)` 等内建版本条件处理平台差异。

## 22.4 内联汇编：DMD 的 asm 语法

```d
long readTsc() {
    long t;
    asm nothrow @nogc {
        rdtsc;                // 读时间戳计数器 → EDX:EAX
        shl RAX, 32;
        mov t, RAX;
    }
    return t;
}

int asmAdd(int a, int b) {
    asm nothrow @nogc {
        mov EAX, a;
        add EAX, b;           // 结果留在 EAX = 返回值
    }
}
```

- DMD x86-64 支持 Intel 语法内联汇编（**LDC/GDC 不支持**——跨编译器代码用 GDC/LLVM 的内建函数替代）。
- `asm` 块要标 `nothrow @nogc` 才能在受限上下文用。
- 寄存器名直接写；D 变量名可直接 mov。

## 22.5 ⭐ BetterC：D 当"更好的 C"

```d
// betterc.d —— dmd -w -betterC betterc.d
import core.stdc.stdio : printf;
import core.stdc.stdlib : malloc, free;

extern (C) int fib(int n) { return n < 2 ? n : fib(n-1) + fib(n-2); }

extern (C) int main() {                 // 必须 extern(C) int main！
    printf("BetterC: fib(20) = %d\n", fib(20));
    return 0;
}
```

`-betterC` 移除：GC、异常、TypeInfo、模块静态构造器——留下的：模板、CTFE、mixin、`scope`、内联汇编、RAII（struct 析构）。C 编译器语法检查 + D 元编程，嵌入式的最爱。

## 22.6 互操作矩阵

| 方向 | 做法 |
|---|---|
| D 调 C 库 | extern(C) 声明 + 把 .lib/.a 加进链接（`dmd ... mylib.lib`） |
| C 调 D | extern(C) 导出函数；main 所在侧用 -betterC 或 C main 启动后调 `rt_init`（进阶） |
| C++ 调 D | extern(C++) |
| 数据结构 | 只用两边都有的类型：定长数组/指针/对齐结构体；别把 D 切片/class 直接传给 C |

## 22.7 坑位清单

1. **-betterC 下 `void main()` 链接失败**：报 `_d_run_main` 未解析——必须 `extern (C) int main()`（D 的默认 main 会生成运行时启动桩）。
2. **`align(1) struct` ≠ packed**（22.3 的 10≠7 实测）——逐成员 align(1)。
3. C 变参函数声明 `(...)` 时**实参类型不检查**（就是 C 语义）：printf 传错类型是运行期未定义——核心场景包一层类型安全的 D 函数。
4. `&函数名` 取 C ABI 函数指针用 `&`（裸名字也行，& 更明确）；比较函数返回值是 `int`——`(x > y) - (x < y)` 的三态惯用法别写反。
5. D 的 `string`/`int[]` **不能直接**传 C：传 `s.ptr`（以 `\0` 结尾要自己保证——D 字符串字面量自带 `\0`，拼接结果不带）。
6. asm 块的 D 变量访问：编译器自动处理栈槽——但**浮点返回**要留在 XMM0，规则同 C ABI（本章整型示例刚好够用）。

---
