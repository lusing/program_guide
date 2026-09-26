# 23 · 进程与原生互操作：Process、P/Invoke 与反射

> 对应示例：`examples/23_interop`

## 1. 子进程：Process 与重定向

```csharp
var psi = new ProcessStartInfo
{
    FileName = "dotnet",
    Arguments = "--version",
    RedirectStandardOutput = true,
    RedirectStandardError = true,
    UseShellExecute = false,      // 重定向的前提：不用 shell 启动
};
using var p = Process.Start(psi)!;
var stdout = await p.StandardOutput.ReadToEndAsync();   // ① 先读光输出
await p.WaitForExitAsync();                              // ② 再等退出
Console.WriteLine($"{stdout.Trim()}, exit={p.ExitCode}");
```

①②的顺序是**死锁纪律**：子进程的输出走 OS 管道，缓冲区有限——你先 `WaitForExit`，子进程写满缓冲区就阻塞在 write 上，永远退不了，你也永远等不到。先读（`ReadToEndAsync` 两个流可并行 await），后等。

`using` 不是仪式感：进程对象背后是**内核对象句柄**（OS 资源，不是托管内存，GC 不管），不用要等句柄表被迫回收。`ExitCode` 是子进程 `Main` 的返回值——脚本世界里这就是进程间最古老的通信协议。

## 2. P/Invoke：调用非托管 DLL

```csharp
static partial class WinNative
{
    [LibraryImport("kernel32")]
    internal static partial uint GetCurrentProcessId();
}

static partial class PosixNative
{
    [LibraryImport("libc")]
    internal static partial int getpid();
}
```

`[LibraryImport]`（.NET 7+）是源生成器版 P/Invoke：封送代码编译期生成，AOT/裁剪友好，取代老 `[DllImport]`（后者 marshalling 靠运行时反射，仍是合法写法，老代码到处是）。规则：

- 类型必须** blittable**（int、uint、byte、double、IntPtr 等内存布局双方一致的类型），直接传；`string` 这类托管类型要声明封送——`[LibraryImport("x", StringMarshalling = StringMarshalling.Utf8)]`。
- 方法必须 `partial`，外层类必须 `partial`——生成器要往里写代码；生成的封送代码用指针，csproj 要加 `<AllowUnsafeBlocks>true</AllowUnsafeBlocks>`（否则 SYSLIB1062）。
- 库名跨平台不同：Windows `kernel32`，Linux/macOS `libc`——`OperatingSystem.IsWindows()` 分支，或 `NativeLibrary`/`SetDllImportResolver` 按平台解析。
- 函数声明写错的报错方式是**运行时 EntryNotFoundException**，编译器不替你查 DLL 的导出表——签名照着官方文档逐字核对。

内存纪律：非托管内存（`Marshal.AllocHGlobal`、原生回调给的指针）**GC 不认识**，谁分配谁释放；句柄用 `SafeHandle` 包，别裸传 `IntPtr`。

## 3. DLL 地狱与 .NET 的解药

Windows 原生 DLL 时代的心病：程序依赖 `m_i` 在 DLL 数据段的**偏移量**，新版本 DLL 在前面加了一个变量，老程序还按旧偏移量访问——读到别人的内存。函数入口地址同理。换新版 DLL 程序崩，不换有安全洞，这就是 **DLL Hell**。

.NET 程序集（DLL）的解法是**自描述**：类型、成员、版本全在文件自己的元数据里，按名字而不是偏移量绑定——重排成员不破坏兼容；再配 GAC/并行多版本共存，同一台机器跑多个版本互不干扰。但"托管版 DLL 地狱"以新形态活着：**NuGet 依赖版本打架**（A 要 Newtonsoft 12、B 要 13）——解药是版本区间约束与中央版本管理（`Directory.Packages.props`），这是工程问题，第 19 章的可移植性话题延伸。

## 4. 反射：没有编译期引用也能调

```csharp
var asm = Assembly.GetExecutingAssembly();
var t = asm.GetType("Plugin")!;
var instance = Activator.CreateInstance(t)!;
var result = (int)t.GetMethod("Compute")!.Invoke(instance, [21])!;
```

教科书场景是**插件系统**：主程序编译时不认识插件类型，运行时 `Assembly.LoadFrom(path)` 加载、按约查找类型、`Activator` 造实例、`Invoke` 调方法——第 10 章用反射动态调 DLL 是同一件事的 2016 版。代价与纪律：

- **性能**：每次 Invoke 都有查找与装箱开销，不能进热路径。
- **AOT/裁剪不友好**：裁剪器看不见字符串里的类型名，反射的目标可能被裁掉——需要 `[DynamicallyAccessedMembers]` 标注（发布 AOT 时编译器会逼你写）。
- **更现代的插件边界是接口**：插件与主程序共享一个接口程序集，`LoadFrom` 后 `(IPlugin)instance` 强转调用——类型安全，比裸 `Invoke` 抗演化；依赖注入（第 16 章）就是这个思路的框架化。

只是"读取类型信息"（序列化器、源生成器做的事）而不执行，用 `MetadataLoadContext`，不加载程序集、不跑静态构造。

## 5. 坑位清单

1. **重定向下忘了 `UseShellExecute = false`** → `InvalidOperationException`；`cmd /c`、`start` 这类 shell 内建命令在 `UseShellExecute = true` 下才可用，两者互斥。
2. **先 WaitForExit 后读输出** → 死锁（§1 的顺序纪律）；输出大且交错时，stdout/stderr 两个流要并发读。
3. **FileName 带参数**：`FileName = "dotnet run"` 是错的，`Arguments` 单独给；路径带空格要引号，参数拼接先读文档再手写。
4. **LibraryImport 忘写 partial** → 编译错（这是它比 DllImport 好的地方：错误提前）。
5. **字符串封送没声明**：`[LibraryImport]` 默认不封送 string（编译错提醒你选 `StringMarshalling`）；`char*` 世界还有 ANSI/UTF-16 之别，Windows API 多为 UTF-16。
6. **路径拼接 `LoadFrom` 插件**：`Assembly.LoadFrom` 有加载上下文语义，依赖解析顺序和默认上下文不同——插件目录的依赖 DLL 解析不到是高频坑，考虑 `AssemblyDependencyResolver`。
7. **裁剪/AOT 发布下裸反射** → 运行时 `MissingMethodException`，标注或改接口方案。
