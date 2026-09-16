using System;
using System.IO;

namespace PortableLib;

// 可移植类库：只依赖 netstandard2.0 的 API 面
// —— .NET Framework 4.6.1+ / Mono / Unity / 现代 .NET 都能消费
public static class Greeting
{
    // 可移植习惯 1：Path.Combine 拼路径，不手写 '\\' 或 '/'
    public static string BuildFilePath(string dir, string name) => Path.Combine(dir, name);

    // 可移植习惯 2：显式 UTF8，行尾交给 Environment.NewLine
    public static string Format(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("name 不能为空", nameof(name));
        }

        return "hello, " + name + Environment.NewLine;
    }

    // 条件编译：不同目标框架各取所需
#if NET
    public static string Runtime => ".NET (Core) 5+";
#elif NETFRAMEWORK
    public static string Runtime => ".NET Framework / Mono";
#else
    public static string Runtime => "纯 netstandard 实现";
#endif
}
