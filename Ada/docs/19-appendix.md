# 19 · 附录：编译测试、常用选项与编码规范

> 本章不带示例：汇总全书的编译验证记录、常用 gnatmake 开关与编码规范速记。

## 19.1 编译测试结果汇总

| 章 | 源文件 | 编译 | 运行 |
|------|--------|----------|----------|
| 02. Hello World | `ch02_hello.adb` | PASS | PASS |
| 03. 基本数据类型 | `ch03_types.adb` | PASS | PASS |
| 04. 控制结构 | `ch04_control.adb` | PASS | PASS |
| 05. 子程序 | `ch05_subprograms.adb` | PASS | PASS |
| 06. 数组与字符串 | `ch06_arrays.adb` | PASS | PASS |
| 07. 记录类型 | `ch07_records.adb` | PASS | PASS |
| 08. 包 | `ch08_math_lib.{ads,adb}`, `ch08_packages.adb` | PASS | PASS |
| 09. 异常处理 | `ch09_exceptions.adb` | PASS | PASS |
| 10. 泛型编程 | `ch10_generics.adb` | PASS | PASS |
| 11. 面向对象 | `ch11_oop.adb` | PASS | PASS |
| 12. 并发编程 | `ch12_tasking.adb` | PASS | PASS |
| 13. 文件 I/O | `ch13_fileio.adb` | PASS | PASS |
| 14. C 互操作 | `ch14_c_interop.adb` | PASS | PASS |
| 15. 标准容器 | `ch15_containers.adb` | PASS | PASS |
| 16. 受保护对象 | `ch16_protected.adb` | PASS | PASS |
| 17. 契约式编程 | `ch17_contracts.adb` (`-gnata`) | PASS | PASS |
| 18. SPARK 形式化验证 | `ch18_spark.adb` (`-gnata`) | PASS | PASS |

**总计：17 个示例（02–18 章，章号 = 示例编号），20 个源文件，全部编译通过，全部运行通过。**

### Linux 平台复验（2026-09-21）

在 **Linux x86_64, GNAT 16.2.1 (GCC 16.2.1)** 下用 `./run-all.sh` 全量复验，17 个示例**编译、运行全部通过**，运行输出与 Windows 环境一致。相对 Windows 仅有的差异：

| 事项 | 说明 |
|------|------|
| `ch14_c_interop` 链接 | 需附加 `-largs -lm`（Linux 的数学函数在独立 libm 中）；`run-all.sh` 已自动处理 |
| `ch17_contracts` / `ch18_spark` | 需 `-gnata`（与 Windows 相同）；`run-all.sh` 已自动处理 |
| 可执行文件名 | 无 `.exe` 后缀 |
| 环境搭建 | `sudo apt install gnat`（Debian/Ubuntu）等，见 01 章 |

### Windows 复验（2026-09-22，章号对齐重构后）

示例按「章号 = 示例编号」整体 +1 重编号（`ch01_hello` → `ch02_hello` … `ch17_spark` → `ch18_spark`，包 `Ch07_Math_Lib` → `Ch08_Math_Lib`）后，在 **Windows x86_64, GNAT 16.2.0 (MSYS2 UCRT64)** 下用 `./run-all.sh`（Git Bash + `GNATMAKE` 环境变量）全量复验，17 个示例**编译、运行全部通过**，输出与此前一致（契约示例的异常消息中的文件名随重编号同步更新为 `ch17_contracts.adb`）。

---

---

## 19.2 常用编译选项

```powershell
# 基本编译
gnatmake source.adb

# 指定输出文件名
gnatmake -o output.exe source.adb

# 启用所有警告
gnatmake -gnatwa source.adb

# 启用详细编译信息
gnatmake -gnatv source.adb

# 生成调试信息
gnatmake -g source.adb

# 优化编译
gnatmake -O2 source.adb

# 检查语法（不生成可执行文件）
gnatmake -gnatc source.adb
```

```bash
# Linux / macOS：命令相同，仅输出文件不加 .exe
gnatmake -o output source.adb

# 链接 C 数学库（导入 sqrtf/sin/cos 等 libm 函数时必需）
gnatmake -o output source.adb -largs -lm

# 启用断言（契约 Pre/Post/Predicate/Assert）
gnatmake -gnata source.adb
```

> **提示**：`-largs` 之后的参数全部传给链接器，必须放在命令行末尾；
> 切换 `-gnata` 等编译开关后 gnatmake 不会自动重编已有单元，需加 `-f` 强制重编。

---

---

## 19.3 Ada 编码规范要点

1. **大小写不敏感** — `Put_Line` 与 `put_line` 等价，推荐使用下划线命名
2. **强类型** — 不同类型不能隐式转换，需显式类型转换
3. **语句以 `;` 结尾** — 每个语句以分号结束
4. **以 `end` 结尾** — 块、子程序、包、循环等都以 `end` 结尾，可带标识符
5. **`:=` 赋值** — 赋值使用 `:=`，比较使用 `=`
6. **注释** — 使用 `--` 单行注释
7. **`with`** — 引入外部包
8. **`use`** — 使包内容直接可见（谨慎使用）

---
上一章：[18 SPARK](18-spark.md) ｜ 返回：[README](../README.md)

