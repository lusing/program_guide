# 32 · 文件与 IO

> 对应示例：`examples/32_files_io`

> **本章你将学会**：File/Directory 便捷层、Path 拼接纪律、Stream 流式家族、编码的坑、IO 的异常与异步纪律。
> **前置章节**：[22 异常](22-exceptions.md)、[28 异步](28-async-await.md)。

## 1. 三层 API：按需取用

```text
便捷层  File / Directory / Path          一行搞定常用操作（内部开流关流）
流层    FileStream / StreamReader...      大文件、进度、自定义缓冲
系统层  Windows API（27 章 P/Invoke）     特殊需求
```

**从便捷层起步**，遇到"大文件/边读边处理/进度反馈"才下到流层。

## 2. File 与 Directory 速查

```csharp
await File.WriteAllTextAsync(path, "内容");            // 一行写
var text = await File.ReadAllTextAsync(path);          // 一行读（默认 UTF-8）
var lines = await File.ReadAllLinesAsync(path);        // 按行读成数组
File.AppendAllText(path, "追加");                       // 追加
var exists = File.Exists(path);
var size = new FileInfo(path).Length;

Directory.CreateDirectory(dir);                         // 不存在则建（存在不报错）
Directory.GetDirectories(dir);                          // 子目录
Directory.Delete(dir, recursive: true);                 // 删目录树
```

注意 **XxxAsync 版本在 UI/服务器代码里是默认选择**（28 章——IO 是异步的主场）；`File.ReadAllBytes` 同步读 1GB = 界面冻结 10 秒。

## 3. Path：拼路径的唯一正道

```csharp
Path.Combine(dir, "a", "b.txt")          // ✓ 分隔符/尾斜杠全自动
dir + "\\a\\b.txt"                       // ✘ 平台写死、尾斜杠翻车

Path.GetDirectoryName(path)              // 目录部分
Path.GetFileName(path)                   // 文件名（含扩展名）
Path.GetExtension(path)                  // ".txt"
Path.GetTempPath() / Path.GetTempFileName()
Path.GetFullPath(relativePath)           // 相对转绝对（基于当前目录）
```

**永远 Path.Combine**——跨平台（Linux 上 `\` 不是分隔符）、免"目录带不带尾斜杠"的心智负担。测试临时数据用 `Path.GetTempPath()` + 自建子目录（示例的做法：用完 `Delete(recursive: true)` 清场）。

## 4. Stream 家族：流式读写

小文件一行读完没问题；**大文件/网络流必须流式**（分块处理，内存恒定）：

```csharp
using (var fs = new FileStream(binary, FileMode.Create))
using (var writer = new BinaryWriter(fs))
{
    writer.Write(42);            // int → 4 字节
    writer.Write("你好");         // 长度前缀 + UTF-8 字节
    writer.Write(3.14);
}
using (var fs = new FileStream(binary, FileMode.Open))
using (var reader = new BinaryReader(fs))
{
    var i = reader.ReadInt32();  // 按写入顺序读回
}
```

装饰器分工：**FileStream**（字节层）→ **BinaryWriter/Reader**（基元类型的二进制编解码）或 **StreamReader/Writer**（文本 + 编码）或 **StreamWriter 的 BufferedStream**（缓冲装饰）。`using` 管释放（25 章）——流是典型的 IDisposable。文本大文件逐行流式：

```csharp
await foreach (var line in File.ReadLinesAsync(path))   // 一行一行来，不全量载入（28 章异步流）
    Process(line);
```

## 5. 编码：写明，别赌默认

```csharp
Encoding.UTF8.GetBytes("中")                       // 3 字节（string 内部 UTF-16 → 落盘 UTF-8）
Encoding.UTF8.GetByteCount("简体中文")              // 12
Encoding.GetEncoding("GB18030").GetByteCount("简体中文")   // 8
```

- `File.ReadAllText(path)` 默认 **UTF-8（无 BOM 检测）**——GBK 老文件读出乱码
- **GB18030/GBK 不是白送的**：`Encoding.RegisterProvider(CodePagesEncodingProvider.Instance)` 先注册（示例代码第一行）——WPF 教程 25 章的编码探测器（BOM → 严格 UTF-8 试解 → GB18030 回退）是完整实战
- 写文件**显式传 Encoding**：默认 UTF-8 无 BOM——要 BOM 用 `new UTF8Encoding(true)`

## 6. IO 的两条纪律

**异常纪律**：磁盘满、权限不够、文件被别的进程锁住——IO 是异常重灾区。**每个对外暴露的 IO 操作 try/catch 包好**（22 章：可预期的失败给返回值/消息，意外上抛）。删目录前 `Exists` 检查也防不了"检查完就被删"的竞态——TryXxx 形态（`Directory.Exists` + 容忍异常）更稳。

**路径安全**：拼接用户输入进路径 = 目录穿越攻击（`../../secrets`）。`Path.GetFullPath` 后校验是否仍在预期根目录内：

```csharp
var full = Path.GetFullPath(Path.Combine(rootDir, userInput));
if (!full.StartsWith(Path.GetFullPath(rootDir))) throw new UnauthorizedAccessException();
```

## 常见坑

**同步 IO 在 UI/服务线程**：`File.ReadAllText` 大文件冻结界面——异步 API 全家桶（XxxAsync/ReadLinesAsync）。

**相对路径依赖当前目录**：`File.Read("a.txt")` 的 a.txt 在"进程当前目录"（不一定是 exe 目录！）——`AppContext.BaseDirectory` 拼绝对路径才可靠。

**File.Exists 与"文件被锁"**：存在 ≠ 能读（别的进程独占打开）——Try 打开 + catch IOException 才是真检查。

**忘了 using**：FileStream 没释放 → 文件锁到进程退出、句柄泄漏。文件对话框/压缩包内部全是流——层层 using。

**GetTempFileName 的坑**：它**会创建**一个 0 字节文件并返回名——以为是纯取名字，结果留了一堆空文件。要目录用 GetTempPath + 自建。

## 实战建议

- 文本小文件三选一（ReadAllText/ReadAllLines/WriteAllText + Async 后缀）；二进制用 BinaryWriter 成对写读
- 大文件恒用流式（ReadLinesAsync / 分块 CopyToAsync）；"能不能一次读完"是内存预算问题——按上限设计
- 配置/数据目录三选一：exe 旁（绿色软件）、`%APPDATA%`（用户配置——WPF 记事本+的最近文件就这么存）、`%LOCALAPPDATA%`（缓存）
- 每层 IO 写好错误信息（哪个路径、什么操作、为何失败）——排查现场 IO 错误，信息就是生命
- 第 33 章 JSON 落盘、WPF 教程 22/25 章文本编码实战——本章是它们的地基

## 自测

1. **三层 IO API 各自的适用？** —— 便捷层一行操作；流层大文件/流式；系统层特殊需求。
2. **为什么必须 Path.Combine？** —— 跨平台分隔符 + 尾斜杠/边界自动处理。
3. **流式 vs 全量读的决策依据？** —— 内存预算：超过"一次读没问题"体量就分块流式。
4. **GB18030 用之前要做什么？** —— RegisterProvider(CodePagesEncodingProvider) 注册代码页编码。

---
上一章：[31 并行编程](31-parallel.md) ｜ 下一章：[33 序列化与 JSON](33-json.md) ｜ 返回：[README](../README.md)
