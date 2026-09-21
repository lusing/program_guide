# 02 · Hello World

> 示例：[`examples/ch02_hello.adb`](../examples/ch02_hello.adb)
> 运行：`./run-all.sh 02`

```ada
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch02_Hello is
begin
   Put_Line ("Hello, Ada!");
   Put_Line ("GNAT 编译器 (GCC) — Windows / Linux 通用");
   Put_Line ("Ada 2012/2022 语言标准");
end Ch02_Hello;
```

**编译 & 运行：**
```powershell
# Windows
gnatmake -o examples\ch02_hello.exe examples\ch02_hello.adb
.\examples\ch02_hello.exe
```

```bash
# Linux / macOS
gnatmake -o ch02_hello examples/ch02_hello.adb
./ch02_hello
```

**要点：**
- `with Ada.Text_IO` — 引入标准输入输出包
- `use Ada.Text_IO` — 使包内容直接可见，无需前缀
- `procedure ... is ... begin ... end` — Ada 程序（过程）的基本结构

---
上一章：[01 全景与工具链](01-overview.md) ｜ 下一章：[03 类型](03-types.md) ｜ 返回：[README](../README.md)

