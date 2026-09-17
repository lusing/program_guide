# 18 · 文件与 IO

> 对应示例：`examples/18_files/`

## 18.1 两层 API：std.file vs std.stdio.File

| | std.file | std.stdio.File |
|---|---|---|
| 粒度 | 整文件/目录级 | 流式（句柄） |
| 典型 | readText/copy/mkdir/dirEntries | byLine/writef/大文件 |
| 内存 | 全量进内存 | 逐块 |

```d
import std.file, std.stdio, std.path;

// 整文件层
auto text = readText("a.txt");              // UTF-8 校验 + 全读
std.file.write("b.txt", "内容");            // 整写（覆盖）
std.file.copy("a.txt", "b.txt");
getSize("b.txt"); exists("a.txt"); isFile("a.txt"); isDir("sub");

// 流式层
{
    File f = File("log.txt", "w");          // File 是 struct：出作用域自动 close（RAII）
    f.writefln("条目 %02d：值 %.2f", 1, 1.5);
}
foreach (line; File("a.txt", "r").byLine)   // 逐行，不整读
    writeln(line);
```

## 18.2 目录与遍历

```d
mkdirRecurse("dir/sub/deep");               // 递归建目录（mkdir 只建一层）
rmdirRecurse("dir");                        // 连目录树一起删（危险，想清楚再按）

foreach (de; dirEntries("dir", SpanMode.depth))    // 深度优先
    writeln(de.name, de.isDir ? "/" : "");
foreach (de; dirEntries("dir", SpanMode.breadth))  // 广度优先
    ...;
// SpanMode.shallow：只当前层

// 过滤 + 算法（dirEntries 是区间，无缝接 14 章全家）
auto txts = dirEntries(dir, SpanMode.depth)
    .filter!(de => de.isFile && de.name.extension == ".txt")
    .array;
```

## 18.3 路径：std.path（纯字符串操作，不碰磁盘）

```d
buildPath("G:", "code", "guide", "README.md");   // 平台感知拼接（Windows 产 \）
p.baseName;      // "README.md"
p.dirName;       // "G:\code\guide"
p.extension;     // ".md"（带点；没有返回空）
p.setExtension(".bak");
absolutePath("x.txt");
tempDir();       // 系统临时目录
```

## 18.4 环境变量与进程信息

```d
import std.process;
environment.get("PATH");
environment["HOME"] = "...";       // 设置
thisProcessID();                   // PID
```

## 18.5 ⚠ 符号冲突：本章头号坑

**同时 import std.file 和 std.stdio 时，`write` 撞车**：

```text
Error: `write` matches conflicting symbols:
    std.stdio.write!(string, string).write
    std.file.write!string.write
```

解法（本示例的写法）：冲突处用**限定名** `std.file.write(...)` / `std.stdio.write(...)`。同理可能撞的还有 `copy`（std.file vs std.algorithm）——大项目里按模块选择性导入（`import std.path : buildPath, baseName;`）能少踩很多。

## 18.6 坑位清单

1. **std.file.write vs std.stdio.write 冲突**：两个模块都 import 后裸调 `write` 直接编译错——限定名或选择性导入（18.5）。
2. **`dirEntries` 的 `de.name` 带路径**（相对或绝对，取决于你传入的根）；Windows 分隔符是 `\`——跨平台比较用 `baseName`/`extension` 别硬编码斜杠。
3. **`readText` 假定 UTF-8**（BOM 可有）：GBK 等编码要先读字节再按编码转（std.utf 只管 UTF 家族）。
4. `File.byLine` 的 `line` 是**复用缓冲**：循环里想留着就 `line.idup`。
5. `rmdirRecurse` 删的是**整棵树**且不可撤销——测试代码里用它清理前先确认路径变量没拼错（示例用 buildPath(tempDir, ...) 隔离）。
6. File 写完是否 flush？作用域结束 close 时会——但在异常路径上想保数据，关键点手动 `f.flush()`。

---
