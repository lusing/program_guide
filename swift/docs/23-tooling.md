# 23 · 工具链与互操作

> 对应示例：`examples/23_tooling/`

## 23.1 C 互操作 I：import 即用（WinSDK / ucrt）

Swift 在 Windows 上自带两个"免声明"C 接口模块（实测 6.3.3 可用）：

```swift
import WinSDK   // 全套 Win32 API（工具链自动配好 SDK 路径与链接）
import ucrt     // C 运行时（sqrt/printf/strlen 家族）

let pid = GetCurrentProcessId()          // Win32：进程号
let tick = GetTickCount64()              // Win32：系统滴答（UInt64）
let root2 = sqrt(2.0)                    // CRT：C 函数当 Swift 函数用
```

`import` 之后 C 函数、常量（`MAX_PATH == 260`）、类型（`WCHAR`/`HANDLE`/`DWORD`）
直接可用——模块里已经做好了 Swift 声明与链接参数。**这是消费侧的互操作**：写
`extern` 声明的苦活由 SDK overlay 代办。

缓冲区往返的完整仪式（拿系统目录）：

```swift
func systemDirectory() -> String {
    var buffer = [WCHAR](repeating: 0, count: 260)     // WCHAR = UTF-16 单元
    let length = GetSystemDirectoryW(&buffer, 260)     // & 数组 = 传指针
    guard length > 0 else { return "?" }
    return String(decoding: buffer.prefix(Int(length)), as: UTF16.self)
}
```

三步：`&` 把数组变指针传入 → API 返回写入长度 → 按有效长度解码成 String（UTF-16
是 Windows 宽字符的编码）。

**C 类型映射表**（示例实测打印）：

| C | Swift | 大小 |
|---|---|---|
| `int8_t` / `char` | `CChar` = Int8 | 1 |
| `int32_t` / `int` | `CInt` = Int32 | 4 |
| `int64_t` | `CLongLong` = Int64 | 8 |
| `float` | `CFloat` = Float32 | 4 |
| `wchar_t` | `WCHAR` = UInt16 | 2 |
| `void*` | `OpaquePointer?` | 8 |

## 23.2 C 互操作 II：声明自己的 C 函数

SDK 没覆盖的 DLL，用 extern 声明接入：

```swift
@_silgen_name("Add")   // 或 classic: extern "C" 的声明走 module map
```

更工程化的路径是 C 目标（`.target(name: "CShim", provider: .system(...))`）+ module
map——教程不展开（WinSDK/ucrt 已覆盖教学需求），知道"声明 + 链接参数"两件事即可。

## 23.3 swift-format：格式化与 lint

```bash
# 检查（CI 用）：违规即非零退出；--strict 连 warning 也算失败
swift format lint --configuration .swift-format --strict --recursive <dir>

# 自动修复（类似 zig fmt / gofmt）
swift format format --configuration .swift-format --recursive --in-place <dir>
```

本仓库的 `.swift-format` 配置把缩进钉为 **4 空格**——swift-format 无配置时默认
2 空格（02 章实测的坑），Apple 代码风格是 4，教学代码跟 Apple。工作流：改完代码
`format --in-place` 一把再 lint——本教程每批示例都这么过的闸。

## 23.4 静态链接与独立分发

默认产物动态链接 Swift 运行时（`swiftCore.dll` 一族），离开开发机跑不起来。三条
路：

```bash
# ① 静态链标准库（最简单——exe 自包含）
swiftc -static-stdlib main.swift -o app.exe

# ② 随包携带 DLL：把 <安装根>\Runtimes\usr\bin 与 exe 放一起（PATH 或同目录）

# ③ SPM 下：swift build -c release 后处理产物（copy-runtime / 官方打包工具链）
```

教学场景首选 ①/②（23 章示例运行验证依赖脚本的 PATH 配方——build.ps1 顶部三件套
就是干这个的）。

## 23.5 调试与诊断

```bash
swift build -c debug        # 默认即 debug：含符号与断言（precondition 全开）
lldb -- .build/debug/Ch03Basics.exe   # LLDB 直接调（break/run/print）
```

- `precondition`/`assert` 只在 debug 生效，`-c release` 里 precondition 保留、
  assert 消失（12 章分层的编译开关面）；
- 崩溃时 Windows 下 swift 运行时会打简短栈（16 章泄漏实验见过）；
- LLDB 调 Swift 完整可用（断点/表达式/po）——教程示例小，print + precondition
  自检已够（每章"输出即断言"的设计就是为无调试器验证）。

## 23.6 编译模式与优化

```bash
swift build -c release          # -O 全局优化
swift build -c release -Xswiftc -cross-module-optimization   # WMO 跨模块内联
```

Release 与 Debug 可能差 10 倍性能（数值密集代码更甚）。性能评估永远以 Release 为
准；Debug 的角色是断言与快速迭代。

## 23.7 钉版心法：本教程的实测复盘

本教程钉死 6.3.3 并在 build.ps1 固化环境配方，动机是三个实测事实（01 章有完整
故事）：

1. scoop 的 6.4.0 包缺整个 `Runtimes\usr\bin`——程序一跑就 0xC0000135；
2. scoop 用户级 `SDKROOT` 指向 `current` junction——升 6.4 后 6.3.3 编译器混到
   6.4 SDK，报 `module compiled with Swift 6.4 cannot be imported`；
3. 6.4 默认的新 swiftbuild 构建系统解析不了 scoop 压平的 `Toolchains\usr` 目录。

**可迁移的纪律**（任何工具链通用）：

- 验证脚本钉**版本化真实路径**，不碰 `current`/`latest` 类别名；
- 环境三件套（SDKROOT + 编译器 bin + 运行时 bin）写进脚本顶部常量，升级 = 改一处；
- 升级前先跑"冒烟链"（hello + 一个带测试的示例），全绿才切——本教程 Task 1 的
  02_hello 就是这个角色。

## 23.8 坑位清单（含实测）

1. **`GetSystemDirectoryW` 写的是 UTF-16 数组**：解码用
   `String(decoding: buffer.prefix(n), as: UTF16.self)`——`String(decodingCString:)`
   的 CString 版本只吃 `UnsafePointer<CChar>`（窄字符），宽字符走 decoding 家族。
2. **`&buffer` 传指针要求数组 var**：`let` 数组取不了 inout——C 缓冲区模式固定为
   `var + & + count`。
3. **`swift format lint` 不带 `--recursive` 不吃目录**（23 章实测报 usage 错误）；
   配置文件必须走 `--configuration`（写成位置参数会被当源文件 lint）。
4. **`-static-stdlib` 与 `-c release` 正交**：一个管链接形态一个管优化——分发
   通常两个都要。
5. **WCHAR 数组初始化 `repeating: 0`** 的 0 是 UInt16 字面量——写 `repeating: "0"`
   （字符）类型不匹配，编译器报错但文案绕（C 背景容易手滑）。
6. **ucrt 的 `sqrt` 与 Foundation 的 `sqrt` 重名时**：显式 `sqrt(x)` 在 import 双方
   时可能歧义——用模块限定（`ucrt.sqrt(x)`）或像示例一样包一层自己的函数名。

上一章：[22 · Swift Package Manager](22-spm.md) ｜ 下一章：[24 · 实战：迷你 grep](24-minigrep.md) ｜ 返回：[README](../README.md)
