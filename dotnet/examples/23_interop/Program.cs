using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;

// ---------- 子进程：重定向 + 退出码 ----------
// 死锁纪律：先读光输出，再 WaitForExit（缓冲区满则子进程写阻塞）
var psi = new ProcessStartInfo
{
    FileName = "dotnet",
    Arguments = "--version",
    RedirectStandardOutput = true,
    RedirectStandardError = true,
    UseShellExecute = false,          // 重定向的开关条件
};
using var p = Process.Start(psi)!;
var stdout = await p.StandardOutput.ReadToEndAsync();
await p.WaitForExitAsync();
Console.WriteLine($"process: dotnet={stdout.Trim()}, exit={p.ExitCode}");

// ---------- P/Invoke：跨平台二选一 ----------
if (OperatingSystem.IsWindows())
{
    Console.WriteLine($"pinvoke: pid={WinNative.GetCurrentProcessId()} (kernel32)");
}
else
{
    Console.WriteLine($"pinvoke: pid={PosixNative.getpid()} (libc)");
}

// ---------- 反射：没有引用也能调 ----------
var asm = Assembly.GetExecutingAssembly();
var pluginType = asm.GetType("Plugin")!;
var instance = Activator.CreateInstance(pluginType)!;
var computed = (int)pluginType.GetMethod("Compute")!.Invoke(instance, [21])!;
Console.WriteLine($"reflection: 21 -> {computed}");

static partial class WinNative
{
    [LibraryImport("kernel32")]                 // 源生成器版 P/Invoke（.NET 7+ 首选）
    internal static partial uint GetCurrentProcessId();
}

static partial class PosixNative
{
    [LibraryImport("libc")]
    internal static partial int getpid();
}

public class Plugin
{
    public int Compute(int x) => x * 2;
}
