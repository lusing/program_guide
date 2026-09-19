# Swift 编程指南（6.3.3，重写中）

面向**会编程（C/C++/Rust 背景最佳）、初学 Swift** 的读者：从零教到 Swift 6 语言模式 +
严格并发 + SPM 工程化。24 章正文与示例按批交付中（完成后再更新本页章节索引）。

> ⚠️ 工具链注意：scoop 的 swift **6.4.0 包损坏**（缺整个 `Runtimes\usr\bin`，程序一运行即
> 0xC0000135 崩溃，SPM 亦不可用）；本教程实测基于**完整可用的 6.3.3 包**，脚本已钉死路径。

## 目录结构

```text
swift/
├── README.md       本文件
├── Package.swift   根包（每章示例一个可执行目标 + swift-testing 测试目标）
├── .swift-format   格式化配置（4 空格缩进——swift-format 无配置时默认 2 空格）
├── docs/           24 章教程（01 → 24 顺序阅读，按批交付）
├── examples/       示例目录（章号 = 目录号；22/24 为嵌套独立包）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
└── run-all.sh      Git Bash 等价验证入口
```

## 构建工具链

- Swift **6.3.3**：`G:\scoop\apps\swift\6.3.3\Toolchains\6.3.3+NoAsserts\usr\bin\swift.exe`
  （脚本自动设置 SDKROOT 与运行时 PATH，用户无需手动配环境）
- 需 Visual Studio 2022+ 的 MSVC 与 Windows SDK（链接用）

## 验证命令

```powershell
cd G:\code\guide\swift
pwsh -ExecutionPolicy Bypass -File build.ps1 -All              # 全部示例：format+build+test+run
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 02_hello # 单个示例四层验证
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean            # 清理 .build
```

```bash
./run-all.sh            # Git Bash 入口，等价
./run-all.sh 02_hello   # 单个示例
```

## 相关教程

系统语言对照：[cpp20](../cpp20/README.md)、[rust](../rust/README.md)、[go](../go/README.md)、
[zig](../zig/README.md)；Apple 平台开发见 [iosdev](../iosdev)、[macosdev](../macosdev)。
