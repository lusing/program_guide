# 02 · 第一个手写 IR

> 对应示例：`examples/02_first_ir/`（add.ll）

上一章你是"看"clang 生成的 IR；这一章开始"写"。手写 IR 是理解 LLVM 的最短路径——所有概念（值、类型、函数、基本块）都会在指尖过一遍。目标：一个能被 `lli` 直接执行的 `.ll` 文件，只用了 30 行。

## 2.1 .ll 文件的解剖

一个 `.ll` 文件（LLVM 称为一个 **Module**，模块）自上而下分三段：

```llvm
; ── ① 全局数据区：@ 开头的全局变量、常量、函数声明 ──
@.intfmt = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; ── ② 函数声明：只写签名，实现在模块外（C 库等） ──
declare i32 @printf(ptr, ...)

; ── ③ 函数定义：标签分块的花括号体 ──
define i32 @add(i32 %a, i32 %b) {
entry:
  %sum = add i32 %a, %b
  ret i32 %sum
}
```

命名规则一张表记全：

| 前缀 | 是什么 | 例 |
|---|---|---|
| `@` | 全局的东西（函数、全局变量、别名） | `@add`、`@.intfmt` |
| `%` | 局部的值（参数、指令结果、基本块标签） | `%a`、`%sum`、`%entry` |
| 无名 | 自动编号（从 0 递增） | `%0`、`%1`、`%2:` |

`@`/`%` 是名字的一部分，写 `add` 而不是 `@add` 是语法错误。

## 2.2 注释与字符串

```llvm
; 单行注释以分号开头，没有块注释

@.ok = private unnamed_addr constant [16 x i8] c"==== 02 ok ====\00", align 1
```

字符串要点（C 程序员的既视感是刻意的）：

- 类型是 `[N x i8]`——**字符串就是字节数组**，没有专门的字符串类型；
- `c"..."` 是字节数组字面量，**转义要手写**：换行 `\0A`、制表 `\09`、NUL `\00`、反斜杠 `\5C`；
- **长度 N 必须手数且精确**：`"==== 02 ok ===="` 是 15 个字符 + 1 个 NUL = `[16 x i8]`。数错了 `llvm-as` 直接报错（见 2.6）。

> **实测坑**：`c"abc\00"` 的类型是 `[4 x i8]`，喂给要 `ptr` 的函数没问题（全局数组退化成指针，第 3 章 GEP 详说）；但如果你想 `[3 x i8]` 装 4 个字节，编译器不会帮你圆谎。

## 2.3 函数：定义、调用、外部声明

```llvm
define i32 @add(i32 %a, i32 %b) {
entry:
  %sum = add i32 %a, %b
  ret i32 %sum
}
```

- `define` = 有函数体；`declare` = 只有签名（链接时找）。
- 返回类型写在最前面：`i32 @add`。没有 `void` 返回值差异问题——无返回就写 `define void @f()`。
- 每个函数体至少一个**基本块**（basic block），第一个块通常叫 `entry`。
- 调用语法是 `call 返回类型 @函数(参数类型 实参...)`：

```llvm
%r1 = call i32 @add(i32 3, i32 4)
```

### 调用 C 库函数

`printf` 是变参函数，声明里用 `...`，调用时要写**完整函数类型**：

```llvm
declare i32 @printf(ptr, ...)

%pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %r1)
;                    ^^^^^^^^^^^^ 变参函数的调用必须重写一遍带 ... 的类型
```

`lli` 执行时会从进程的 C 库里解析 `printf`/`puts` 的地址（MinGW 运行时），所以你在 IR 里"免费"获得了整个 C 库——这是第 11 章 JIT 章节的重要伏笔。

> **实测坑**：变参调用里参数类型必须和格式串匹配。`printf("%d", double值)` 在 IR 层不报错（`printf` 本来就吃 `...`），运行时输出乱码甚至崩溃——C 的坑原样继承给了 IR。

## 2.4 lli：IR 的解释执行器

```powershell
$uc = 'G:\scoop\apps\msys2\current\ucrt64\bin'
& "$uc\lli.exe" examples\02_first_ir\add.ll
```

（实测输出）：

```text
7
107
==== 02 ok ====
```

`lli` 的行为约定：**执行模块里的 `@main`，返回值作为进程退出码**。这给了我们一个免费的"断言"手段：

```llvm
define i32 @main() {
entry:
  %r = call i32 @add(i32 2, i32 2)
  %ok = icmp eq i32 %r, 4
  br i1 %ok, label %good, label %bad
good:
  ret i32 0
bad:
  ret i32 1          ; lli 退出码 1 → 验证脚本立刻发现
}
```

`lli` 内部其实是把 IR 即时编译（JIT）成本机代码再执行（第 11 章会拆开看它的心脏 ORC），所以跑 `fib(30)` 这种负载也是原生速度。

## 2.5 文本 IR ↔ 位码：llvm-as / llvm-dis

```powershell
& "$uc\llvm-as.exe"  add.ll -o add.bc     # 文本 → 位码（bitcode）
& "$uc\llvm-dis.exe" add.bc -o add.dis.ll  # 位码 → 文本（往返验证）
```

位码是 IR 的紧凑二进制序列化。用途：

- **中间产物缓存**：Rust/Swift 编译器在发行包里放 `.bc`，链接时再优化（LTO 的基础）；
- **跨语言交付**：`.bc` 可以进归档、走网络，对方 `lli` 直接跑。

> **实测坑**：位码**不跨大版本稳定**（LLVM 官方明确不保证 `.bc` 的向后兼容），跨机器传 IR 请传 `.ll` 文本。本教程的 build 脚本每次都做 as→dis 往返，就是在持续验证"文本是无损的持久形态"。

## 2.6 验证器：让编译器挑你的错

写 IR 最常见的报错来自 `llvm-as`（它内置验证）。故意写错体会一下——把 `add.ll` 里的 `[4 x i8]` 改成 `[3 x i8]`：

```powershell
& "$uc\llvm-as.exe" broken.ll -o broken.bc
```

（实测输出）：

```text
error: invalid module
broken.ll:3:53: error: array is not large enough to contain element #4
```

报错带行号列号，和任何编译器一个体验。更全面的验证器是 `opt -passes=verify`，它会做结构不变量检查（基本块必须以终结指令结尾、phi 的来源数必须等于前驱数……第 4 章会见到它发威）。

## 2.7 完整示例回顾

`examples/02_first_ir/add.ll` 全景（30 行）：

```llvm
@.intfmt = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@.ok     = private unnamed_addr constant [16 x i8] c"==== 02 ok ====\00", align 1

declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

define i32 @add(i32 %a, i32 %b) {
entry:
  %sum = add i32 %a, %b
  ret i32 %sum
}

define i32 @main() {
entry:
  %r1  = call i32 @add(i32 3, i32 4)
  %pf1 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %r1)
  %r2  = call i32 @add(i32 %r1, i32 100)
  %pf2 = call i32 (ptr, ...) @printf(ptr @.intfmt, i32 %r2)
  %pm  = call i32 @puts(ptr @.ok)
  ret i32 0
}
```

注意 `%pf1`/`%pm` 这些"结果没人用"的值——IR 允许，无害（优化时会当死代码删掉）。`unnamed_addr`、`private` 这些修饰词下一章讲。

### 老教程对照（避雷）

如果你读过 LLVM 官方旧版 Kaleidoscope 或 2015 年前的教材，会看到这样的写法：

```llvm
; 旧（LLVM ≤14）                    新（LLVM 15+，唯一正确写法）
%ap = getelementptr i32, i32* %p,   %ap = getelementptr i32, ptr %p,
      i64 1                                i64 1
call i32 (i8*, ...)                      call i32 (ptr, ...)
      @printf(i8* %fmt, ...)                   @printf(ptr %fmt, ...)
```

**类型化指针（`i32*`）在 LLVM 15 被删除，全平台只剩不透明指针 `ptr`**。本机 `G:\github\lang\llvm` 的 v10 源码、以及大量网络教程还是旧写法——读到 `i32*` 时脑内替换成 `ptr` 即可。这是新手上路第一大版本坑。

## 2.8 本章小结

- Module = 全局区 + 声明 + 定义；`@` 全局 `%` 局部。
- 字符串是 `[N x i8]` 字节数组，长度手数，`\00` 自补。
- 变参函数调用要重写带 `...` 的完整类型。
- `lli` 跑 `@main`、返回值即退出码；`llvm-as`/`llvm-dis` 是文本/位码互换。
- `.ll` 文本跨版本，`.bc` 不保证；`ptr` 是唯一的指针类型。

| 坑 | 解法 |
|---|---|
| 字符串长度数错 | `llvm-as` 报 element #N，按提示改 `[N x i8]` |
| 变参调用段错误 | 检查实参类型是否匹配格式串 |
| 旧教材 `i32*` | 一律脑内替换 `ptr` |
| `.bc` 跨版本打不开 | 持久化只用 `.ll` |

下一章把类型系统补全——结构体、数组、GEP 寻址，写完你就能在 IR 里表达任意 C 数据布局。
