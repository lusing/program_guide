# 27 · 附录：编译测试、常用选项、编码规范与术语对照

> 本章不带示例：汇总全书的编译验证记录、常用 gnatmake 开关、编码规范
> 速记，以及老教材（Ada 83 时代）与现代 Ada 的术语对照表。

## 27.1 编译测试结果汇总

| 章 | 源文件 | 编译 | 运行 |
|------|--------|----------|----------|
| 02. Hello World | `ch02_hello.adb` | PASS | PASS |
| 03. 基本数据类型 | `ch03_types.adb` | PASS | PASS |
| 04. 控制结构 | `ch04_control.adb` | PASS | PASS |
| 05. 子程序 | `ch05_subprograms.adb` | PASS | PASS |
| 06. 数组与字符串 | `ch06_arrays.adb` | PASS | PASS |
| 07. 记录类型 | `ch07_records.adb` | PASS | PASS |
| 08. 判别类型 | `ch08_discriminants.adb` | PASS | PASS |
| 09. 访问类型 | `ch09_access.adb` | PASS | PASS |
| 10. 包与模块化 | `ch10_math_lib.{ads,adb}`, `ch10_packages.adb` | PASS | PASS |
| 11. 异常处理 | `ch11_exceptions.adb` | PASS | PASS |
| 12. 泛型编程 | `ch12_generics.adb` | PASS | PASS |
| 13. 泛型进阶 | `ch13_generics_deep.adb` | PASS | PASS |
| 14. 面向对象 | `ch14_oop.adb` | PASS | PASS |
| 15. 并发 Tasking | `ch15_tasking.adb` | PASS | PASS |
| 16. 受保护对象 | `ch16_protected.adb` | PASS | PASS |
| 17. select 会合家族 | `ch17_select.adb` | PASS | PASS |
| 18. 文件 I/O | `ch18_fileio.adb` | PASS | PASS |
| 19. 文件 I/O 全景 | `ch19_files.adb` | PASS | PASS |
| 20. C 互操作 | `ch20_c_interop.adb` (`-largs -lm`) | PASS | PASS |
| 21. 低级程序设计 | `ch21_lowlevel.adb` | PASS | PASS |
| 22. 定点与十进制 | `ch22_fixed.adb` | PASS | PASS |
| 23. 标准容器 | `ch23_containers.adb` | PASS | PASS |
| 24. 契约式编程 | `ch24_contracts.adb` (`-gnata`) | PASS | PASS |
| 25. SPARK | `ch25_spark.adb` (`-gnata`) | PASS | PASS |
| 26. 独立编译 | `ch26_separate.adb` + 5 个配套文件 | PASS | PASS |

**总计：25 个示例（02–26 章，章号 = 示例编号），31 个源文件，全部编译
通过，全部运行通过。**（26 章为多文件工程：主程序 + 2 个子单位 +
父包 + 子库单元对。）

### Linux 平台复验（2026-09-21，原 17 例）

在 **Linux x86_64, GNAT 16.2.1 (GCC 16.2.1)** 下用 `./run-all.sh` 全量复验，17 个示例**编译、运行全部通过**，运行输出与 Windows 环境一致。相对 Windows 仅有的差异：

| 事项 | 说明 |
|------|------|
| `ch20_c_interop` 链接 | 需附加 `-largs -lm`（Linux 的数学函数在独立 libm 中）；`run-all.sh` 已自动处理 |
| `ch24_contracts` / `ch25_spark` | 需 `-gnata`（与 Windows 相同）；`run-all.sh` 已自动处理 |
| 可执行文件名 | 无 `.exe` 后缀 |
| 环境搭建 | `sudo apt install gnat`（Debian/Ubuntu）等，见 01 章 |

### Windows 复验记录

| 日期 | 环境 | 记录 |
|------|------|------|
| 2026-09-22 | GNAT 16.2.0（章号 +1 重构后 17 例） | 17/17 通过；契约示例异常消息中的文件名随重编号同步 |
| 2026-09-25 | GNAT 16.2.0（19→27 章老教材扩充后 25 例） | 25/25 通过；含新增判别/访问/泛型进阶/select/文件全景/低级/定点/独立编译八章 |

### 26 章（2026-09-25）扩充来源

本次扩充当章对照了三本老教材并做现代化重写（Ada 2022 语法、GNAT 16.2
实测）：

| 新章 | 主要取材 | 保有的经典案例 |
|------|---------|---------------|
| 08 判别类型 | 何诚 ch10、刘炳文 ch10、张丽芬 ch4 | 几何图形面积（变体记录 + case 分发） |
| 09 访问类型 | 何诚 ch11、刘炳文 ch12 | BUILD_LIST 建表、"首项移尾"指针重排、二叉查找树 |
| 13 泛型进阶 | 何诚 ch14 | 任务通信的类属 FIFO 缓冲区、环形计数器 |
| 17 select 家族 | 何诚 ch12（§12.5–12.7）、张丽芬 ch8 | 有界缓冲哨兵、看门狗、会合式信号灯 |
| 19 文件全景 | 何诚 ch15、张丽芬 ch3 | 二路归并有序文件 |
| 21 低级程序设计 | 何诚 ch17、张丽芬 ch10 | ADC 寄存器位级建模（16#AD# 验证） |
| 22 定点实数 | 何诚 ch16 | 三阶切比雪夫数字滤波器定点实现 |
| 26 独立编译 | 何诚 ch9、刘炳文 ch13 | 体存根/子单位、层级库 |

---

## 27.2 常用编译选项

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

# 指定语言标准（如需 Ada 2022 专属特性：方括号容器聚合、
# delta 聚合等——本教程默认标准即可编译全部示例）
gnatmake -gnat2022 source.adb
```

> **提示**：`-largs` 之后的参数全部传给链接器，必须放在命令行末尾；
> 切换 `-gnata` 等编译开关后 gnatmake 不会自动重编已有单元，需加 `-f` 强制重编。

---

## 27.3 Ada 83 → 现代 Ada 术语对照

读老教材（何诚 1992 / 刘炳文 1993 / 张丽芬 1992，均以 ANSI/MIL-STD-1815A
即 Ada 83 为基准）时的"翻译表"：

| 老教材术语 | 现代术语 | 备注 |
|-----------|---------|------|
| 存取类型 / 访问数据类型 | 访问类型 (access type) | 指针；Ada 95 增 `access all`/`access constant` |
| 分配算符 | 分配符 `new` | |
| 类属 / 类属单元 | 泛型 (generic) | `generic` 关键字未变 |
| 类属例化 | 实例化 (instantiation) | `new Gen (实参)` |
| 例外 / 异常 | 异常 (exception) | `raise`/`handle` 机制未变 |
| 判别类型 | （带）判别式（的）记录 | discriminant 概念未变 |
| 汇合 | 会合 / 集合点 (rendezvous) | task + entry + accept |
| 选择语句（三变体） | select 语句 | 选择等待/条件入口调用/定时入口调用 |
| 上下文规范说明 / 上下文子句 | with 子句（上下文子句） | |
| 使用子句 | use 子句 | Ada 95 增 `use type` |
| 子单位 | 子单位 (subparate/separate) | 现代工程更多用子库单元 |
| 编译单位 | 编译单元 (compilation unit) | |
| 规范说明 | 规范 (specification) | 包规范 .ads / 体 .adb |
| 私有类型 / 受限私有类型 | private / limited private | 未变 |
| 杂注 | 编用 / pragma → aspect | Ada 2012 起推荐 aspect 形式（`with Size => 8` 替代 `pragma`/表示子句） |
| 表示规范说明 / 长度规范说明 | 表示子句 / 表示方面 | `Size`/`Address`/`Storage_Size` |
| 预定义语言属性 | 属性 (attribute) | `'First`/`'Last`/`'Image`… |
| 正文文件 / 顺序文件 / 随机存取文件 | Text_IO / Sequential_IO / Direct_IO | Ada 83 的 `INPUT_OUTPUT` 泛型一分为二；另有 Stream_IO |
| 实数类型（定点/浮点） | 定点/浮点未变 | 十进制定点是金融正解；Ada 2022 增 `delta` aspect |
| 转移语句 `goto` | 仍存在但禁用级别 | 现代规范一律避免 |
| `ASCII` 包 | `Ada.Characters.Latin_1` | Ada 95 起 |
| `CALENDAR` 包 | `Ada.Calendar` + `Ada.Real_Time` | 实时系统首选后者 |
| `NEW_LINE`/`PUT` 等直接可见 | 需 `with Ada.Text_IO` | 83 时代部分实现预置 |
| Meridian Ada Vantage 等 | GNAT (GCC) / GNAT Pro | 工具链世代更替 |

## 27.4 Ada 编码规范要点

1. **大小写不敏感** — `Put_Line` 与 `put_line` 等价，推荐使用下划线命名
2. **强类型** — 不同类型不能隐式转换，需显式类型转换
3. **语句以 `;` 结尾** — 每个语句以分号结束
4. **以 `end` 结尾** — 块、子程序、包、循环等都以 `end` 结尾，可带标识符
5. **`:=` 赋值** — 赋值使用 `:=`，比较使用 `=`
6. **注释** — 使用 `--` 单行注释
7. **`with`** — 引入外部包
8. **`use`** — 使包内容直接可见（圈进最小作用域；算符可见用 `use type`）

---
上一章：[26 独立编译](26-separate-compilation.md) ｜ 返回：[README](../README.md)
