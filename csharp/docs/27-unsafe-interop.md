# 27 · unsafe 与互操作

> 对应示例：`examples/27_unsafe`（csproj 多了 `<AllowUnsafeBlocks>true</AllowUnsafeBlocks>`）

> **本章你将学会**：unsafe 块与指针基础、fixed 钉住、P/Invoke 调用系统 API、结构体内存布局、函数指针。
> **前置章节**：[26 Span](26-span.md)、[25 GC](25-gc.md)。

## 1. unsafe 的定位：最后的 1%

托管世界拦着你碰裸内存（GC 会搬对象、类型系统防乱来）——**这是保护也是墙**。unsafe 打开一个洞：指针、手工内存操作、直接调 C。代价：你自担内存安全（越界、悬空、竞态都不再有编译器/运行时兜底）。

**先背判断：99% 的需求到不了 unsafe**——Span/Memory（第 26 章）覆盖了绝大部分高性能场景。unsafe 的真实领地：对接 C/C++ 库、极致热路径（图像/加密内核）、位级协议。打开它的工程要显式 `<AllowUnsafeBlocks>true</AllowUnsafeBlocks>`——让"这个项目有指针"成为看得见的决策。

## 2. unsafe 块：取地址与解引用

```csharp
unsafe
{
    int value = 42;
    int* p = &value;          // 取栈变量的地址
    Console.WriteLine(*p);    // 解引用：地址上的内容（42）
    *p = 100;                 // 通过指针写——value 变 100
}
```

四则：`&x` 取地址、`*p` 解引用、`p->Field`（指针访问成员）、`p[i]`（指针当下标）。**指针算术按所类型步进**：`int*` 的 `p + 1` 实际前进 4 字节（`sizeof(int)`）——数组遍历的基石。

## 3. fixed：钉住托管对象

GC 随时可能**搬动**堆上对象（压缩回收）——直接取托管数组的指针，下一秒 GC 一搬就悬空。`fixed` 在作用域内**钉住**对象：

```csharp
var data = new int[] { 1, 2, 3, 4 };
unsafe
{
    fixed (int* p = data)            // 钉住期间 GC 不搬
    {
        int sum = 0;
        for (int* q = p; q < p + data.Length; q++)
            sum += *q;               // 指针遍历
    }
}   // 解钉
```

fixed 要点：**作用域越短越好**（钉住妨碍 GC 压缩）；可同时钉多个 `fixed (int* a = x, b = y)`；string 也能 fixed（拿 char*）。栈变量（第 2 节）不需要 fixed——栈不搬。

## 4. P/Invoke：调用操作系统的 C 函数

声明 extern + DllImport，托管代码直接调 DLL 导出函数：

```csharp
static class Native
{
    [DllImport("kernel32")]
    public static extern uint GetCurrentThreadId();

    [DllImport("kernel32", CharSet = CharSet.Unicode)]           // 字符串编解码方式
    public static extern uint GetSystemDirectory(StringBuilder sb, uint length);
}
```

三件事要对齐：**参数类型的封送**（blittable 类型直接过；string/StringBuilder 有专门规则——CharSet 声明编码）、**调用约定**（现代 Win32 默认 StdCall，DLLImport 自处理）、**错误处理**（C API 的返回码自己查，没有异常）。真正的互操作坑场在结构体：

```csharp
[StructLayout(LayoutKind.Sequential)]    // 字段按声明顺序线性排布（C 的默认）
public struct WinPoint { public int X; public int Y; }

Marshal.SizeOf<WinPoint>()               // 8 字节——与 C 端 sizeof 对齐
```

`[StructLayout]` 决定内存布局（Sequential 顺序 / Explicit 显式偏移 + FieldOffset）；`Marshal` 类是封送工具箱（StructureToPtr/PtrToStringUTF8/…）。位宽、对齐、字符集三处对不齐 = 数据悄悄坏掉——互操作 bug 的头号产地。

## 5. 函数指针：delegate* 

```csharp
unsafe
{
    // delegate*<int, int, int> fp = &SomeStaticMethod;   // 指向静态方法的非托管函数指针
}
```

**C# 9 的函数指针**（delegate*）是"非托管函数指针"：比委托（13 章）少分配、少间接，用于**把托管方法递给非托管回调**（C 库要函数指针的场景）或原生调度表。日常业务不碰；它出现在这里是为了完整你的心智地图——委托（托管、可多播）→ 函数指针（非托管、裸地址）。

## 6. 现代互操作的梯队（按优先级）

| 梯队 | 手段 | 场景 |
|---|---|---|
| 1 | **现成绑定库**（NuGet 的 P/Invoke 包） | Windows API 常用函数大多有人包好了 |
| 2 | **DllImport 手写** | 小众 API/自家 C 库 |
| 3 | **LibraryImport 源生成**（.NET 7+） | DllImport 的 AOT 友好版（封送代码编译期生成） |
| 4 | C++/CLI 或原生组件 | 复杂对象模型互操作 |

第 24 章的教训在互操作同样成立：DllImport 走运行时封送生成，AOT/裁剪场景换 `[LibraryImport]`（源生成封送）。

## 常见坑

**忘了 fixed 就取托管地址**：编译器直接拒绝（托管取指针必须 fixed）——语言层面防住了，但要懂为什么。

**fixed 块里调用会触发 GC 的代码**：钉住对象让 GC 分代计划变差；长 fixed 块 = 内存碎片化加速器——块越短越好。

**封送字符串忘了 CharSet**：默认 ANSI——Windows 的 Unicode API 收到乱码。Win32 现代函数几乎都 `CharSet.Unicode` + `ExactSpelling`（W 后缀函数）。

**结构体布局对不齐**：字段顺序/位宽/对齐差异 → C 端读到的数据错位。互操作结构体：逐字段 `Marshal.OffsetOf` 验证 + 两端 sizeof 对账。

**指针算术越界**：没有任何护栏——unsafe 代码 review 要逐行；Span 版本（带边界检查）能替代时绝不用裸指针。

## 实战建议

- 决策链背下来：**Span 能做 → Span；绑定库有 → 用库；非 unsafe 不可 → 圈定最小范围**
- 每个 unsafe 方法写"为什么非它不可"的注释——半年后的你和 review 的同事需要
- 互操作结构体配单元测试：Marshal.SizeOf 与预期字节数断言——平台/编译器变化时立刻报警
- P/Invoke 声明集中一个 NativeMethods 类（StyleCop 的 SA1200 惯例），错误码包装成异常——调用方不该看见裸 uint 返回
- 真想系统学：官方"互操作"文档 + 《.NET 内存管理》相关章节；本仓库 win32 教程是 Windows API 的另一半世界

## 自测

1. **unsafe 的真实适用场景三则？** —— C 库对接、极致热路径、位级协议；99% 需求 Span 覆盖。
2. **fixed 为什么必须？代价？** —— GC 会搬对象，钉住才敢取指针；代价是妨碍 GC 压缩，块要短。
3. **P/Invoke 三处对齐？** —— 参数封送（类型/字符集）、调用约定、错误处理（自己查返回码）。
4. **函数指针与委托的分工？** —— 非托管回调/裸地址场景用 delegate*；托管世界（多播/事件）用委托。

---
上一章：[26 Span 与高性能内存](26-span.md) ｜ 下一章：[28 async/await](28-async-await.md)
