# 02 · 第一个程序

> 对应示例：`examples/02_hello/`

## 2.1 三十秒上手

```d
import std.stdio;

void main() {
    writeln("你好，D 语言！");
}
```

编译运行一把梭：

```bash
dmd -run main.d           # 编译 + 立即运行（不落盘可执行文件）
dmd main.d                # 产 main.exe / main.obj（Linux / macOS：main 可执行文件 + main.o）
dmd -w -unittest -run main.d   # 本教程标准验证命令（-w：警告当错误；-unittest：带单测）
```

`import std.stdio;` 引入标准库 IO 模块。D 的模块系统：一个 `.d` 文件 = 一个模块（21 章细讲），**没有头文件**——直接 import 源文件。

## 2.2 输出三件套

```d
writeln("编号：", 42, "，π ≈ ", 3.14159);      // 多参数，自动加换行
writefln("整数 %d，十六进制 0x%x", 255, 255);   // C 风格格式串
write("不换行", "...");                        // 手动控制
```

常用占位符（19 章全集）：

| 占位符 | 含义 | 例 |
|---|---|---|
| `%s` | 万能：任何类型按默认格式 | `255`、`true`、`[1, 2]` |
| `%d` / `%x` / `%o` / `%b` | 十/十六/八/二进制（整数） | `ff` |
| `%.2f` / `%e` / `%g` | 定点/科学/自适应浮点 | `3.14` |
| `%10s` / `%-10s` | 宽度 10：右对齐/左对齐 | |
| `%(...)  %)` | 数组逐元素格式（19 章） | `1, 2, 3` |

**占位符与实参匹配是运行期检查**（抛 `FormatException`），不是编译期——别指望编译器帮你抓 `%d` 配字符串。

## 2.3 pragma(msg)：编译期打日志

```d
pragma(msg, "编译期消息：hello");    // 编译时输出到控制台，不进运行时
```

CI/模板调试神器——配合 CTFE（12 章）可以编译期打印计算结果。

## 2.4 unittest：语言内建的测试

```d
unittest {
    assert(1 + 1 == 2);
}
```

不需要装任何测试框架。**但注意运行语义**：

| 编译方式 | 运行时行为 |
|---|---|
| `dmd -unittest -run main.d` | **只跑 unittest，跑完直接退出，main 不执行** |
| `dmd main.d` + 运行 | 只跑 main（unittest 没编进去） |
| `dub test`（工程） | dub 生成测试入口跑全部模块的单测 |

这是本教程 build.ps1 / build.sh 分两层验证的原因：一层 `-unittest -run` 验证测试，一层常规编译验证 main。

## 2.5 编译模式

| dmd 标志 | 效果 | 用途 |
|---|---|---|
| （默认） | 无优化，断言/契约全开 | 开发 |
| `-O -release` | 优化 + **剥离断言/契约** | 发布 |
| `-O -release -inline` | 再加内联 | 发布 |
| `-g` | 调试符号（Windows 产 PDB，Linux / macOS 产 DWARF） | 调试 |
| `-betterC` | 无运行时模式（22 章） | 嵌入式/C 互操作 |
| `-w` / `-wi` | 警告当错误 / 警告仅提示 | 本教程用 -w |
| `-cov` | 覆盖率统计（23 章） | 测试 |
| `-i` | 自动编译 import 到的模块（21 章） | 多文件 |
| `-m64` | 64 位（Windows 默认已是） | |

## 2.6 坑位清单

1. **`-unittest` 编译的程序不执行 main**——想跑 main 再编译一次不带 `-unittest` 的版本（本教程所有示例如此验证）。网上老教程说"unittest 在 main 前自动运行"，2.113 实测不是。
2. **PowerShell 的 `-of` 静默坑**：`dmd main.d -of=app.exe`（不加引号）在 PowerShell 里会产出**名为 `.exe` 的文件或干脆没有产物**且退出码 0。必须整体引号 `'-of=app.exe'` 或 `'-ofapp.exe'`；cmd/批处理无此问题。这是 PowerShell 参数解析与 dmd 组合的坑，报错完全静默。
3. **obj 文件落 CWD**：`dmd main.d` 在当前目录留 `main.obj`（Linux / macOS：`main.o`）——用 `-od目录` 指到别处（build.ps1 / build.sh 已处理）。
4. 源文件 **UTF-8 无 BOM**：带 BOM 的 UTF-8 会让 dmd 拒绝编译。
5. `dmd -run` 传程序参数要 `--` 分隔：`dmd -run main.d -- these are args`。
6. **macOS 的 `-g` 不产 dSYM**：调试信息直接进 Mach-O（`dwarfdump --uuid app` 能验到 UUID），`lldb ./app` 可断点；别按 Xcode 习惯去找 `app.dSYM`。

---
